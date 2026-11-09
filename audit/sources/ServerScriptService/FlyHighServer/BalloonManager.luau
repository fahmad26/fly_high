local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local RS=game:GetService("ReplicatedStorage")
local PhysicsService=game:GetService("PhysicsService")
local Config=require(RS.FlyHigh.Modules.FlyHighConfig)
local U=require(script.Parent.ServerUtils)
local Themes=require(RS.FlyHigh.Modules.BalloonThemes)
local Space=require(script.Parent.FlightSpace)
local remotes=RS.FlyHigh.Remotes
local Manager={activeFlights={}}
_G.FlyHighBalloonManager=Manager
pcall(function() PhysicsService:RegisterCollisionGroup("FlyHighBalloons") end)
PhysicsService:CollisionGroupSetCollidable("FlyHighBalloons","FlyHighBalloons",true)
local function sync(fd)
 -- Sample altitude rather than assembly velocity: freefall moves with PivotTo.
 local now=os.clock()
 if fd.isGameOver or fd.isVictory then
  fd.verticalSpeedKmPerSec=0 fd.velocitySampleAt=now fd.velocitySampleY=fd.root.Position.Y
 elseif fd.velocitySampleAt and now-fd.velocitySampleAt>=.05 then
  fd.verticalSpeedKmPerSec=(fd.root.Position.Y-fd.velocitySampleY)/Config.STUDS_PER_KM/(now-fd.velocitySampleAt)
  fd.velocitySampleAt=now fd.velocitySampleY=fd.root.Position.Y
 elseif not fd.velocitySampleAt then
  fd.verticalSpeedKmPerSec=0 fd.velocitySampleAt=now fd.velocitySampleY=fd.root.Position.Y
 end
 for _,p in ipairs(fd.players) do
  if p.Parent==Players then
   remotes.FlightStateSyncEvent:FireClient(p,{
    altitudeKm=fd.altitudeKm,verticalSpeedKmPerSec=fd.verticalSpeedKmPerSec or 0,holes=fd.holes,invulnTime=fd.invulnTime,shieldTime=fd.shieldTime,
    autoGas=fd.autoGas==true,groundedRemaining=fd.groundedSince and math.max(0,Config.GROUNDED_TIMEOUT_SEC-(os.clock()-fd.groundedSince)) or nil,
    isGasActive=fd.isGasActive,isFreefalling=fd.isFreefalling,isGameOver=fd.isGameOver,isVictory=fd.isVictory,
    usedEmergencyKit=fd.usedKits[p.UserId] or false})
  end
 end
end
local function renderHoles(fd)
 for i=1,Config.MAX_HOLES do
  local h=fd.balloon.HoleSlots:FindFirstChild("Hole"..i)
  h.Transparency=fd.holeSet[i] and 0 or 1
  for _,p in h:GetDescendants()do if p:IsA("BasePart")then p.Transparency=h.Transparency end end
  h.PatchPrompt.Enabled=fd.holeSet[i]==true and fd.holes<Config.MAX_HOLES and not fd.isVictory and not fd.isGameOver
 end
end
function Manager.EndFlight(fd,victory)
 if fd.isGameOver or fd.isVictory then return end
 fd.isVictory=victory==true fd.isGameOver=not victory
 for p,item in pairs(fd.boarding or {})do if item.root.Parent then item.root.Anchored=item.anchored end p:SetAttribute("BoardingFlight",nil)end fd.boarding=nil
 fd.pilot=nil fd.pilotSteer=Vector3.zero fd.isGasActive=false fd.autoGas=false
 fd.balloon:SetAttribute("AutoGas",false)
 fd.jumpDropRemaining=0
 _G.FlyHighTetherManager.CleanupBalloon(fd.balloon)
 _G.FlyHighWeaponManager.CleanupBalloon(fd.balloon)
 for _,p in ipairs(fd.players) do
  p:SetAttribute("IsMaster",false) p:SetAttribute("InFlight",false) p:SetAttribute("CrewRole",nil)
  if victory and U.Alive(p,fd) then _G.FlyHighDataManager.AddSummit(p) end
 end
 if victory then
  local palace=workspace.CloudPalace
  local dock=palace.CloudHavenDock
  local keep=palace.CastleKeep
  -- Move the complete assembly and crew through a clear side approach above the flight ceiling.
  local passengers={}
  for _,p in ipairs(fd.players) do
   if U.Alive(p,fd) then
    local hrp=p.Character.HumanoidRootPart
    U.Unseat(p)
    passengers[p]={root=hrp,offset=fd.root.CFrame:ToObjectSpace(hrp.CFrame),anchored=hrp.Anchored}
    hrp.Anchored=true
   end
  end
  fd.root.Anchored=true
  task.spawn(function()
   local origin=fd.root.CFrame
   local points={
    Vector3.new(origin.X,origin.Y,120),
    Vector3.new(dock.Position.X,dock.Position.Y+1.7,120),
    dock.Position+Vector3.new(0,1.7,0)}
   for _,point in ipairs(points) do
    local start=fd.root.CFrame
    local elapsed=0
    while elapsed<0.8 and fd.balloon.Parent do
     elapsed+=RunService.Heartbeat:Wait()
     local alpha=math.clamp(elapsed/0.8,0,1)
     local cf=start:Lerp(CFrame.new(point),alpha*alpha*(3-2*alpha))
     fd.balloon:PivotTo(cf)
     for _,data in pairs(passengers) do if data.root.Parent then data.root.CFrame=cf*data.offset end end
    end
   end
   for i,p in ipairs(fd.players) do
    local data=passengers[p]
    if data and data.root.Parent then
     local arrival=dock.Position+Vector3.new((i-(#fd.players+1)/2)*4,5,-8)
     local lookAt=Vector3.new(keep.Position.X,arrival.Y,keep.Position.Z)
     data.root.CFrame=CFrame.lookAt(arrival,lookAt)
     data.root.Anchored=data.anchored data.root.AssemblyLinearVelocity=Vector3.zero
     p:SetAttribute("PalaceArrival",nil)
     p:SetAttribute("PalaceArrival",arrival)
    end
   end
  end)
 else
  for _,p in ipairs(fd.players) do if U.Alive(p,fd) then p.Character:FindFirstChildOfClass("Humanoid").Health=0 end end
 end
 renderHoles(fd) sync(fd)
 task.delay(victory and 20 or 4,function() if fd.balloon.Parent then fd.balloon:Destroy() end end)
end
function Manager.LaunchBalloon(players,master,spawnPos,podName)
 if not _G.FlyHighDataManager or not _G.FlyHighWeaponManager or not _G.FlyHighTetherManager then return nil end
 if #players<1 or #players>Config.MAX_PLAYERS_PER_POD or not table.find(players,master) then return nil end
 if _G.FlyHighDataManager.IsWeaponLoadoutSaving(master) then return nil end
 for _,p in ipairs(players) do
  if not U.Alive(p) or U.Flight(p,true) or not p:GetAttribute("DataReady") then return nil end
 end
 local start=Space.SpawnPosition(spawnPos or Vector3.new(0,0,-2))
 if Space.Blocker(start,Manager.activeFlights) then return nil end
 local theme=Themes.Get(podName)
 local variants=RS.FlyHigh.Templates:FindFirstChild("BalloonVariants")
 local template=variants and variants:FindFirstChild(theme.Template) or RS.FlyHigh.Templates.HotAirBalloon
 local b=template:Clone()
 b:SetAttribute("BalloonThemeId",theme.Id)
 b:SetAttribute("BalloonThemeName",theme.Name)
 b:SetAttribute("SourcePod",podName or "Pod_A")
 b.Name="Balloon_"..master.Name
  b.ModelStreamingMode=Enum.ModelStreamingMode.Persistent
  b:PivotTo(CFrame.new(start)) b.Parent=workspace
 for _,part in ipairs(b:GetDescendants()) do if part:IsA("BasePart") then part.CollisionGroup="FlyHighBalloons" end end
 local root=b.PrimaryPart
 root:SetNetworkOwner(nil)
 local fd={balloon=b,root=root,alignPos=root.AlignPosition,alignOri=root.AlignOrientation,
  burnerFlame=b.Burner.BurnerNozzle.BurnerFlame,burnerLight=b.Burner.BurnerLight,sirenLight=b.EmergencySiren.SirenLight,
  groundY=Config.GROUND_Y,players=table.clone(players),master=master,characters={},dead={},connections={},
  pilot=nil,pilotSteer=Vector3.zero,isGasActive=false,autoGas=false,groundedSince=os.clock(),contacts=setmetatable({},{__mode="k"}),altitudeKm=0,hasLiftedOff=false,
  holes=0,holeSet={},invulnTime=0,shieldTime=0,isFreefalling=false,isGameOver=false,isVictory=false,
  usedKits={},targetPosition=start,engineerTilt=Vector3.zero,boardingUntil=os.clock()+20,boarding={},boardingDeadline=os.clock()+20}
 fd.alignPos.Position=start fd.alignOri.CFrame=CFrame.identity
 b:SetAttribute("AutoGas",false)
 -- Only the invisible envelope proxy is a shot target; cosmetic parts do not block weapons.
 b.Envelope.CanQuery=true
 table.insert(Manager.activeFlights,fd)
 for i,p in ipairs(players) do
  fd.characters[p]=p.Character
  p:SetAttribute("CurrentPod",nil) p:SetAttribute("IsMaster",p==master) p:SetAttribute("InFlight",true)
  p:SetAttribute("FlightGhost",false) p:SetAttribute("UsedEmergencyKitThisFlight",false)
  local ref=p:FindFirstChild("FlightBalloon") or Instance.new("ObjectValue",p)
  ref.Name="FlightBalloon" ref.Value=b
  local hrp=p.Character.HumanoidRootPart
  fd.boarding[p]={root=hrp,anchored=hrp.Anchored,token=game:GetService("HttpService"):GenerateGUID(false),offset=Vector3.new((i-2)*5,4,0)}
  hrp.Anchored=true p:SetAttribute("BoardingFlight",true)
  table.insert(fd.connections,p.Character:FindFirstChildOfClass("Humanoid").Died:Connect(function()
   fd.dead[p]=true p:SetAttribute("FlightGhost",true) p:SetAttribute("CrewRole",nil)
   if fd.pilot==p then fd.pilot=nil fd.isGasActive=false fd.pilotSteer=Vector3.zero end
   _G.FlyHighTetherManager.CleanupPlayer(p)
   _G.FlyHighWeaponManager.CleanupPlayer(p)
  end))
 end
 local helm=b.HelmSeat
 helm.HeadsUpDisplay=false
 helm.CanTouch=false -- Acquire steering through the prompt, not incidental contact.
 helm.HelmPrompt.Triggered:Connect(function(p)
  if U.CrewNear(p,b,helm,7) and U.CanStartRole(p) and not helm.Occupant then
   helm:Sit(p.Character:FindFirstChildOfClass("Humanoid"))
  end
 end)
 helm:GetPropertyChangedSignal("Occupant"):Connect(function()
  local hum=helm.Occupant
  local p=hum and Players:GetPlayerFromCharacter(hum.Parent)
  local oldPilot=fd.pilot
  local role=p and U.Role(p,true)
  if p and table.find(fd.players,p) and U.Alive(p,fd) and not fd.boarding and not fd.isGameOver and not fd.isVictory and (not role or role=="Pilot") then
   fd.pilot=p p:SetAttribute("CrewRole","Pilot")
  else
   fd.pilot=nil
   if hum then
    -- Defer removal until Roblox has finished creating the seat joint/state.
    -- Removing it synchronously inside Occupant leaves a stale SeatPart.
    task.delay(.1,function()
     if not helm.Parent or helm.Occupant~=hum then return end
     helm.Disabled=true
     if p then U.Unseat(p) remotes.FlightActionEvent:FireClient(p,"ReleaseRejectedHelm",b)
     else hum.Sit=false end
     task.delay(.75,function()if helm.Parent then helm.Disabled=false end end)
    end)
   end
  end
  if oldPilot and oldPilot~=fd.pilot and oldPilot:GetAttribute("CrewRole")=="Pilot" then oldPilot:SetAttribute("CrewRole",nil) end
  fd.isGasActive=false fd.pilotSteer=Vector3.zero
  helm.HelmPrompt.Enabled=fd.pilot==nil
 end)
 _G.FlyHighWeaponManager.SetupWeaponRacks(b,_G.FlyHighDataManager.GetWeaponLoadout(master))
 _G.FlyHighTetherManager.SetupBalloonTethers(b,#players)
 task.spawn(function()
  while b.Parent and fd.boarding and not fd.isGameOver do
   for p,item in pairs(fd.boarding)do if p.Parent==Players then remotes.FlightActionEvent:FireClient(p,"PrepareBoarding",b,item.token)end end
   task.wait(.5)
  end
 end)
 b.Destroying:Connect(function()
  for p,item in pairs(fd.boarding or {})do if item.root.Parent then item.root.Anchored=item.anchored end p:SetAttribute("BoardingFlight",nil)end fd.boarding=nil
  _G.FlyHighTetherManager.CleanupBalloon(b) _G.FlyHighWeaponManager.CleanupBalloon(b)
  for _,c in ipairs(fd.connections) do c:Disconnect() end
  for _,p in ipairs(fd.players) do
   if not U.Flight(p) or U.Flight(p)==fd then
    p:SetAttribute("InFlight",false) p:SetAttribute("FlightGhost",false) p:SetAttribute("IsMaster",false)
   end
  end
  local i=table.find(Manager.activeFlights,fd)
  if i then table.remove(Manager.activeFlights,i) end
 end)
 sync(fd)
 return fd
end
function Manager.ApplyPuncture(fd,cause)
 local deliberate=cause=="Collision" or cause=="SelfShot"
 if fd.isGameOver or fd.isVictory or (not deliberate and fd.altitudeKm<Config.SAFE_TAKEOFF_KM) or fd.invulnTime>0 or fd.shieldTime>0 or fd.holes>=Config.MAX_HOLES then return false end
 for i=1,Config.MAX_HOLES do if not fd.holeSet[i] then fd.holeSet[i]=true break end end
 fd.holes+=1 fd.invulnTime=Config.PASSIVE_INVULN_DURATION fd.isFreefalling=fd.holes==Config.MAX_HOLES
 if fd.isFreefalling then fd.targetPosition=fd.root.Position end
 renderHoles(fd) return true
end
function Manager.RepairHole(fd,n)
 if fd.isGameOver or fd.isVictory or fd.holes>=Config.MAX_HOLES or not fd.holeSet[n] then return false end
 fd.holeSet[n]=nil fd.holes-=1 renderHoles(fd) return true
end
function Manager.ResolveCollisions(fd,proposed)
 local clamped=Space.ClampMovement(fd,proposed,Manager.activeFlights)
  if (proposed-clamped).Magnitude>.01 then
   for _,other in ipairs(Manager.activeFlights)do
    if other~=fd and other.balloon.Parent then
     local d=fd.root.Position-other.root.Position
     local near=math.abs(d.Y)<Config.BALLOON_CLEARANCE_HEIGHT and Vector2.new(d.X,d.Z).Magnitude<Config.BALLOON_CLEARANCE_DISTANCE+1
     if near and not fd.contacts[other.balloon]then
      fd.contacts[other.balloon]=true other.contacts[fd.balloon]=true
      Manager.ApplyPuncture(fd,"Collision")Manager.ApplyPuncture(other,"Collision")
     end
    end
   end
  end
  for other in pairs(fd.contacts)do
   local otherRoot=other.PrimaryPart
   local d=otherRoot and (otherRoot.Position-fd.root.Position)
   if not other.Parent or not d or math.abs(d.Y)>Config.BALLOON_CLEARANCE_HEIGHT+4 or Vector2.new(d.X,d.Z).Magnitude>Config.BALLOON_CLEARANCE_DISTANCE+6 then fd.contacts[other]=nil end
  end
 return clamped
end

local kitRate=U.RateLimiter(0.25)
function Manager.UseEmergencyKit(p)
 local fd=U.Flight(p)
 if not fd or not U.Alive(p,fd) or fd.usedKits[p.UserId] or fd.shieldTime>0 then return false end
 if fd.isFreefalling and (fd.altitudeKm<=0 or fd.root.Position.Y<=fd.groundY+0.1) then return false end
 if not _G.FlyHighDataManager.ModifyEmergencyKits(p,-1) then return false end
 fd.usedKits[p.UserId]=true p:SetAttribute("UsedEmergencyKitThisFlight",true)
 fd.holes=0 fd.holeSet={} fd.isFreefalling=false fd.jumpDropRemaining=0
 fd.shieldTime=Config.CLUTCH_SAVE_INVULN_DURATION fd.invulnTime=fd.shieldTime
 fd.targetPosition=fd.root.Position fd.alignPos.Position=fd.targetPosition fd.root.AssemblyLinearVelocity=Vector3.zero
 fd.verticalSpeedKmPerSec=0 fd.velocitySampleAt=os.clock()fd.velocitySampleY=fd.root.Position.Y
 renderHoles(fd) sync(fd) return true
end
remotes.EmergencyKitEvent.OnServerEvent:Connect(function(p) if kitRate(p) then Manager.UseEmergencyKit(p) end end)
local pilotRate=U.RateLimiter(0.07)
remotes.PilotControlEvent.OnServerEvent:Connect(function(p,steer,gas)
 local fd=U.Flight(p)
 if not fd or fd.pilot~=p or not U.Alive(p,fd) or not U.FiniteVector(steer) or type(gas)~="boolean" or not pilotRate(p) then return end
 local v=Vector3.new(steer.X,0,steer.Z)
 fd.pilotSteer=v.Magnitude>1 and v.Unit or v fd.isGasActive=gas fd.lastControl=os.clock()
end)
local actionRate=U.RateLimiter(.2)
function Manager.FlightAction(p,action,value)
 local fd=U.Flight(p)
 if not fd or not U.Alive(p,fd)then return false end
 if action=="BoardReady"then
  local item=fd.boarding and fd.boarding[p]
  if not item or value~=item.token or p.Character~=fd.characters[p]then return false end
  item.ready=true
  local all=true for _,x in pairs(fd.boarding)do if not x.ready then all=false end end
  if all and not fd.boardingSettling then
   fd.boardingSettling=true
   for crew,x in pairs(fd.boarding)do crew.Character:PivotTo(fd.root.CFrame*CFrame.new(x.offset))x.root.AssemblyLinearVelocity=Vector3.zero end
   task.delay(.3,function()
    if not fd.boarding or not fd.balloon.Parent or fd.isGameOver then return end
    for crew,x in pairs(fd.boarding)do if x.root.Parent then crew.Character:PivotTo(fd.root.CFrame*CFrame.new(x.offset))x.root.Anchored=x.anchored x.root.AssemblyLinearVelocity=fd.root.AssemblyLinearVelocity end crew:SetAttribute("BoardingFlight",nil)end
    fd.boarding=nil fd.boardingUntil=os.clock()+3
   end)
  end
  return true
 end
 if fd.boarding then return false end
 if action=="ReleaseHelm"then
  if fd.pilot~=p or fd.balloon.HelmSeat.Occupant~=p.Character:FindFirstChildOfClass("Humanoid")then return false end
  local seat=fd.balloon.HelmSeat
  U.Unseat(p)seat.Disabled=true
  p.Character.HumanoidRootPart.CFrame=seat.CFrame*CFrame.new(4,2,0)
  p.Character:FindFirstChildOfClass("Humanoid"):ChangeState(Enum.HumanoidStateType.GettingUp)
  fd.pilot=nil fd.isGasActive=false fd.pilotSteer=Vector3.zero
  p:SetAttribute("CrewRole",nil)
  task.delay(.75,function()if seat.Parent then seat.Disabled=false end end)
  return true
 elseif action=="AutoGas"then
  local hum=p.Character and p.Character:FindFirstChildOfClass("Humanoid")
  if type(value)~="boolean"or fd.pilot~=p or not hum or fd.balloon.HelmSeat.Occupant~=hum or hum.SeatPart~=fd.balloon.HelmSeat then return false end
  fd.autoGas=value fd.balloon:SetAttribute("AutoGas",value)sync(fd)return true
 end
 return false
end
remotes.FlightActionEvent.OnServerEvent:Connect(function(p,action,value)
 if actionRate(p)then Manager.FlightAction(p,action,value)end
end)

Players.PlayerRemoving:Connect(function(p)
 local fd=U.Flight(p)if not fd then return end fd.dead[p]=true
 local item=fd.boarding and fd.boarding[p]
 if item then
  if item.root.Parent then item.root.Anchored=item.anchored end fd.boarding[p]=nil
  local crew,nextItem=next(fd.boarding)
  if not crew then Manager.EndFlight(fd,false)
  elseif nextItem.ready then Manager.FlightAction(crew,"BoardReady",nextItem.token)end
 end
end)
RunService.Heartbeat:Connect(function(dt)
 for _,fd in ipairs(table.clone(Manager.activeFlights)) do
  if fd.isGameOver or fd.isVictory then continue end
  if fd.boarding then
   if os.clock()>fd.boardingDeadline then Manager.EndFlight(fd,false)end
   continue
  end
  local alive=0
  for _,p in ipairs(fd.players) do
   if U.Alive(p,fd) then
    local hrp=p.Character.HumanoidRootPart
    if os.clock()>(fd.boardingUntil or 0) and (fd.root.Position.Y-hrp.Position.Y>35 or (hrp.Position-fd.root.Position).Magnitude>90) then
     p.Character:FindFirstChildOfClass("Humanoid").Health=0
    else alive+=1 end
   end
  end
  if alive==0 then Manager.EndFlight(fd,false) continue end
  if not fd.pilot or not U.Alive(fd.pilot,fd) or os.clock()-(fd.lastControl or 0)>0.6 then fd.isGasActive=false fd.pilotSteer=Vector3.zero end
  local burning=fd.isGasActive or fd.autoGas==true
  if os.clock()>=(fd.nextGroundCheck or 0)then
   fd.nextGroundCheck=os.clock()+.2 fd.grounded=Space.IsGrounded(fd,Manager.activeFlights)
  end
  if fd.grounded then
   fd.groundedSince=fd.groundedSince or os.clock()
   if os.clock()-fd.groundedSince>=Config.GROUNDED_TIMEOUT_SEC then Manager.EndFlight(fd,false)continue end
  else fd.groundedSince=nil end
  fd.invulnTime=math.max(0,fd.invulnTime-dt) fd.shieldTime=math.max(0,fd.shieldTime-dt)
  local alerting=os.clock()<(fd.hazardUntil or 0)
  fd.sirenLight.Brightness=(fd.invulnTime>0 or alerting) and (math.floor(os.clock()*8)%2==0 and 4 or 0) or 0
  local effect=Config.HOLE_EFFECTS[fd.holes]
  local base=Config.MAX_ALTITUDE_KM/Config.BASE_FLIGHT_DURATION_SEC
  local speed
  if fd.holes==5 then speed=-Config.FREEFALL_KM_PER_SEC
  elseif burning then speed=effect.can_ascend and base*effect.ascend_rate or (fd.holes==2 and 0 or -base*0.4*effect.descend_mult*0.5)
  else speed=-base*0.4*effect.descend_mult end
  local burnerBoost=burning and fd.holes<5
  if fd.burnerBoost~=burnerBoost then
   fd.burnerBoost=burnerBoost
   fd.burnerFlame.Rate=burnerBoost and 66 or 32
   fd.burnerFlame.Speed=burnerBoost and NumberRange.new(12,16) or NumberRange.new(8,12)
   fd.burnerLight.Brightness=burnerBoost and 4 or 1.5
  end
  local maxY=Config.GROUND_Y+Config.MAX_ALTITUDE_KM*Config.STUDS_PER_KM
  local jumpStep=0
  if fd.holes<5 then
   jumpStep=math.min(fd.jumpDropRemaining or 0,Config.JUMP_DESCENT_STUDS_PER_SEC*math.min(dt,.1))
   fd.jumpDropRemaining=math.max(0,(fd.jumpDropRemaining or 0)-jumpStep)
  else fd.jumpDropRemaining=0 end
  local y=math.clamp(fd.targetPosition.Y+speed*Config.STUDS_PER_KM*math.min(dt,0.1)-jumpStep,Config.GROUND_Y,maxY)
  local steer=fd.pilotSteer
  local now = os.clock()
  if now<(fd.reverseUntil or 0) then steer=-steer end
  local push = Vector3.zero
  if fd.wind and now < (fd.windUntil or 0) then
   local ramp = fd.windSince and (now - fd.windSince) / 0.45 or 1
   local fade = (fd.windUntil - now) / 0.5
   push = fd.wind * math.clamp(math.min(ramp, fade), 0, 1)
  end
  fd.targetPosition=Vector3.new(math.clamp(fd.targetPosition.X+(steer.X*30+push.X)*dt,-Config.CORRIDOR_CENTER_LIMIT,Config.CORRIDOR_CENTER_LIMIT),
   y,math.clamp(fd.targetPosition.Z+(steer.Z*30+push.Z)*dt,-Config.CORRIDOR_CENTER_LIMIT,Config.CORRIDOR_CENTER_LIMIT))
  local clamped=Manager.ResolveCollisions(fd,fd.targetPosition)
  fd.targetPosition=clamped
  if fd.holes==5 then
   -- Carry standing/tethered crew with the rapid descent so the platform cannot outrun gravity.
   local delta=clamped-fd.root.Position
   for _,crew in ipairs(fd.players)do
    if U.Alive(crew,fd)then
     local hrp=crew.Character.HumanoidRootPart
     local tether=_G.FlyHighTetherManager.activeTethers[crew.UserId]
     local relative=fd.balloon.BasketFloor.CFrame:PointToObjectSpace(hrp.Position)
     local overBasket=math.abs(relative.X)<=16 and math.abs(relative.Z)<=16 and relative.Y>=-2 and relative.Y<=25
     if hrp.AssemblyRootPart~=fd.root and (overBasket or(tether and not tether.winch))then
      hrp.CFrame+=delta hrp.AssemblyLinearVelocity=Vector3.zero
     end
    end
   end
   fd.balloon:PivotTo(fd.balloon:GetPivot()+delta)
   fd.root.AssemblyLinearVelocity=Vector3.zero
   fd.targetPosition=Vector3.new(clamped.X,fd.root.Position.Y,clamped.Z)
  end
  fd.alignPos.Position=fd.targetPosition
  fd.altitudeKm=math.clamp((fd.root.Position.Y-Config.GROUND_Y)/Config.STUDS_PER_KM,0,Config.MAX_ALTITUDE_KM)
  if fd.altitudeKm>1 then fd.hasLiftedOff=true end
  local tilt=fd.engineerTilt or Vector3.zero
  fd.alignOri.CFrame=CFrame.Angles(math.clamp(steer.Z*0.08+tilt.X,-0.18,0.18),0,math.clamp(-steer.X*0.08+tilt.Z,-0.18,0.18))
  if fd.holes==5 and fd.root.Position.Y<=Config.GROUND_Y+0.15 then Manager.EndFlight(fd,false) continue end
  if fd.root.Position.Y>=maxY-0.2 then fd.altitudeKm=Config.MAX_ALTITUDE_KM Manager.EndFlight(fd,true) continue end
  if os.clock()-(fd.lastSyncTime or 0)>=0.1 then
   fd.lastSyncTime=os.clock()
   for _,p in ipairs(fd.players) do if U.Alive(p,fd) then _G.FlyHighDataManager.UpdateAltitude(p,fd.altitudeKm) end end
   sync(fd)
  end
 end
end)
