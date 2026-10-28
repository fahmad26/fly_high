local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local RS=game:GetService("ReplicatedStorage")
local PhysicsService=game:GetService("PhysicsService")
local Config=require(RS.FlyHigh.Modules.FlyHighConfig)
local U=require(script.Parent.ServerUtils)
local Themes=require(RS.FlyHigh.Modules.BalloonThemes)
local remotes=RS.FlyHigh.Remotes
local Manager={activeFlights={}}
_G.FlyHighBalloonManager=Manager
pcall(function() PhysicsService:RegisterCollisionGroup("FlyHighBalloons") end)
PhysicsService:CollisionGroupSetCollidable("FlyHighBalloons","FlyHighBalloons",false)
local function sync(fd)
 for _,p in ipairs(fd.players) do
  if p.Parent==Players then
   remotes.FlightStateSyncEvent:FireClient(p,{
    altitudeKm=fd.altitudeKm,holes=fd.holes,invulnTime=fd.invulnTime,shieldTime=fd.shieldTime,
    isGasActive=fd.isGasActive,isFreefalling=fd.isFreefalling,isGameOver=fd.isGameOver,isVictory=fd.isVictory,
    usedEmergencyKit=fd.usedKits[p.UserId] or false})
  end
 end
end
local function renderHoles(fd)
 for i=1,Config.MAX_HOLES do
  local h=fd.balloon.HoleSlots:FindFirstChild("Hole"..i)
  h.Transparency=fd.holeSet[i] and 0 or 1
  h.PatchPrompt.Enabled=fd.holeSet[i]==true and fd.holes<Config.MAX_HOLES and not fd.isVictory and not fd.isGameOver
 end
end
function Manager.EndFlight(fd,victory)
 if fd.isGameOver or fd.isVictory then return end
 fd.isVictory=victory==true fd.isGameOver=not victory
 fd.pilot=nil fd.pilotSteer=Vector3.zero fd.isGasActive=false
 _G.FlyHighTetherManager.CleanupBalloon(fd.balloon)
 _G.FlyHighWeaponManager.CleanupBalloon(fd.balloon)
 for _,p in ipairs(fd.players) do
  p:SetAttribute("IsMaster",false) p:SetAttribute("InFlight",false)
  if victory and U.Alive(p,fd) then _G.FlyHighDataManager.AddSummit(p) end
 end
 if victory then
  local dock=workspace.CloudPalace.CloudHavenDock
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
     data.root.CFrame=CFrame.new(dock.Position+Vector3.new((i-2)*4,5,-8))
     data.root.Anchored=data.anchored data.root.AssemblyLinearVelocity=Vector3.zero
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
 for _,p in ipairs(players) do
  if not U.Alive(p) or U.Flight(p,true) or not p:GetAttribute("DataReady") then return nil end
 end
 local theme=Themes.Get(podName)
 local variants=RS.FlyHigh.Templates:FindFirstChild("BalloonVariants")
 local template=variants and variants:FindFirstChild(theme.Template) or RS.FlyHigh.Templates.HotAirBalloon
 local b=template:Clone()
 b:SetAttribute("BalloonThemeId",theme.Id)
 b:SetAttribute("BalloonThemeName",theme.Name)
 b:SetAttribute("SourcePod",podName or "Pod_A")
 b.Name="Balloon_"..master.Name
 local start=Vector3.new(spawnPos and spawnPos.X or 0,Config.GROUND_Y,spawnPos and (spawnPos.Z-18) or -20)
 b:PivotTo(CFrame.new(start)) b.Parent=workspace
 for _,part in ipairs(b:GetDescendants()) do if part:IsA("BasePart") then part.CollisionGroup="FlyHighBalloons" end end
 local root=b.PrimaryPart
 root:SetNetworkOwner(nil)
 local fd={balloon=b,root=root,alignPos=root.AlignPosition,alignOri=root.AlignOrientation,
  burnerFlame=b.Burner.BurnerFlame,burnerLight=b.Burner.BurnerLight,sirenLight=b.EmergencySiren.SirenLight,
  groundY=Config.GROUND_Y,players=table.clone(players),master=master,characters={},dead={},connections={},
  pilot=nil,pilotSteer=Vector3.zero,isGasActive=false,altitudeKm=0,hasLiftedOff=false,
  holes=0,holeSet={},invulnTime=0,shieldTime=0,isFreefalling=false,isGameOver=false,isVictory=false,
  usedKits={},targetPosition=start,engineerTilt=Vector3.zero,boardingUntil=os.clock()+3}
 fd.alignPos.Position=start fd.alignOri.CFrame=CFrame.identity
 table.insert(Manager.activeFlights,fd)
 for i,p in ipairs(players) do
  fd.characters[p]=p.Character
  p:SetAttribute("CurrentPod",nil) p:SetAttribute("IsMaster",p==master) p:SetAttribute("InFlight",true)
  p:SetAttribute("FlightGhost",false) p:SetAttribute("UsedEmergencyKitThisFlight",false)
  local ref=p:FindFirstChild("FlightBalloon") or Instance.new("ObjectValue",p)
  ref.Name="FlightBalloon" ref.Value=b
  p.Character:PivotTo(CFrame.new(start+Vector3.new((i-2)*5,4,0)))
  table.insert(fd.connections,p.Character:FindFirstChildOfClass("Humanoid").Died:Connect(function()
   fd.dead[p]=true p:SetAttribute("FlightGhost",true)
   if fd.pilot==p then fd.pilot=nil fd.isGasActive=false fd.pilotSteer=Vector3.zero end
   _G.FlyHighTetherManager.CleanupPlayer(p)
   _G.FlyHighWeaponManager.CleanupPlayer(p)
  end))
 end
 local helm=b.HelmSeat
 helm.HelmPrompt.Triggered:Connect(function(p)
  if U.CrewNear(p,b,helm,7) and not helm.Occupant then helm:Sit(p.Character:FindFirstChildOfClass("Humanoid")) end
 end)
 helm:GetPropertyChangedSignal("Occupant"):Connect(function()
  local hum=helm.Occupant
  local p=hum and Players:GetPlayerFromCharacter(hum.Parent)
  if p and table.find(fd.players,p) and U.Alive(p,fd) and not fd.isGameOver and not fd.isVictory then fd.pilot=p
  else fd.pilot=nil if hum then hum.Sit=false end end
  fd.isGasActive=false fd.pilotSteer=Vector3.zero
  helm.HelmPrompt.Enabled=fd.pilot==nil
 end)
 b:SetAttribute("AKUpgraded",master:GetAttribute("BoughtAK47")==true)
 _G.FlyHighWeaponManager.SetupWeaponRacks(b,master:GetAttribute("BoughtAK47")==true)
 master:SetAttribute("BoughtAK47",false)
 _G.FlyHighTetherManager.SetupBalloonTethers(b,#players)
 b.Destroying:Connect(function()
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
function Manager.ApplyPuncture(fd)
 if fd.isGameOver or fd.isVictory or fd.altitudeKm<Config.SAFE_TAKEOFF_KM or fd.invulnTime>0 or fd.holes>=Config.MAX_HOLES then return false end
 for i=1,Config.MAX_HOLES do if not fd.holeSet[i] then fd.holeSet[i]=true break end end
 fd.holes+=1 fd.invulnTime=Config.PASSIVE_INVULN_DURATION fd.isFreefalling=fd.holes==Config.MAX_HOLES
 renderHoles(fd) return true
end
function Manager.RepairHole(fd,n)
 if fd.isGameOver or fd.isVictory or fd.holes>=Config.MAX_HOLES or not fd.holeSet[n] then return false end
 fd.holeSet[n]=nil fd.holes-=1 renderHoles(fd) return true
end
local kitRate=U.RateLimiter(0.25)
function Manager.UseEmergencyKit(p)
 local fd=U.Flight(p)
 if not fd or not U.Alive(p,fd) or fd.usedKits[p.UserId] or fd.shieldTime>0 then return false end
 if fd.isFreefalling and (fd.altitudeKm<=0 or fd.root.Position.Y<=fd.groundY+0.1) then return false end
 if not _G.FlyHighDataManager.ModifyEmergencyKits(p,-1) then return false end
 fd.usedKits[p.UserId]=true p:SetAttribute("UsedEmergencyKitThisFlight",true)
 fd.holes=0 fd.holeSet={} fd.isFreefalling=false
 fd.shieldTime=Config.CLUTCH_SAVE_INVULN_DURATION fd.invulnTime=fd.shieldTime
 fd.targetPosition=fd.root.Position fd.alignPos.Position=fd.targetPosition fd.root.AssemblyLinearVelocity=Vector3.zero
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
Players.PlayerRemoving:Connect(function(p) local fd=U.Flight(p) if fd then fd.dead[p]=true end end)
RunService.Heartbeat:Connect(function(dt)
 for _,fd in ipairs(table.clone(Manager.activeFlights)) do
  if fd.isGameOver or fd.isVictory then continue end
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
  fd.invulnTime=math.max(0,fd.invulnTime-dt) fd.shieldTime=math.max(0,fd.shieldTime-dt)
  local alerting=os.clock()<(fd.hazardUntil or 0)
  fd.sirenLight.Brightness=(fd.invulnTime>0 or alerting) and (math.floor(os.clock()*8)%2==0 and 4 or 0) or 0
  local effect=Config.HOLE_EFFECTS[fd.holes]
  local base=Config.MAX_ALTITUDE_KM/Config.BASE_FLIGHT_DURATION_SEC
  local speed
  if fd.holes==5 then speed=-base*3.5
  elseif fd.isGasActive then speed=effect.can_ascend and base*effect.ascend_rate or (fd.holes==2 and 0 or -base*0.4*effect.descend_mult*0.5)
  else speed=-base*0.4*effect.descend_mult end
  fd.burnerFlame.Size=fd.isGasActive and fd.holes<5 and 14 or 6
  fd.burnerLight.Brightness=fd.isGasActive and fd.holes<5 and 5 or 2
  local maxY=Config.GROUND_Y+Config.MAX_ALTITUDE_KM*Config.STUDS_PER_KM
  local y=math.clamp(fd.targetPosition.Y+speed*Config.STUDS_PER_KM*math.min(dt,0.1),Config.GROUND_Y,maxY)
  local steer=fd.pilotSteer
  if os.clock()<(fd.reverseUntil or 0) then steer=-steer end
  local push=os.clock()<(fd.windUntil or 0) and (fd.wind or Vector3.zero) or Vector3.zero
  fd.targetPosition=Vector3.new(math.clamp(fd.targetPosition.X+(steer.X*30+push.X)*dt,-Config.CORRIDOR_CENTER_LIMIT,Config.CORRIDOR_CENTER_LIMIT),
   y,math.clamp(fd.targetPosition.Z+(steer.Z*30+push.Z)*dt,-Config.CORRIDOR_CENTER_LIMIT,Config.CORRIDOR_CENTER_LIMIT))
  fd.alignPos.Position=fd.targetPosition
  fd.altitudeKm=math.clamp((fd.root.Position.Y-Config.GROUND_Y)/Config.STUDS_PER_KM,0,Config.MAX_ALTITUDE_KM)
  if fd.altitudeKm>1 then fd.hasLiftedOff=true end
  local tilt=fd.engineerTilt or Vector3.zero
  fd.alignOri.CFrame=CFrame.Angles(math.clamp(steer.Z*0.08+tilt.X,-0.18,0.18),0,math.clamp(-steer.X*0.08+tilt.Z,-0.18,0.18))
  if fd.holes==5 and fd.hasLiftedOff and fd.root.Position.Y<=Config.GROUND_Y+0.15 then Manager.EndFlight(fd,false) continue end
  if fd.root.Position.Y>=maxY-0.2 then fd.altitudeKm=Config.MAX_ALTITUDE_KM Manager.EndFlight(fd,true) continue end
  if os.clock()-(fd.lastSyncTime or 0)>=0.1 then
   fd.lastSyncTime=os.clock()
   for _,p in ipairs(fd.players) do if U.Alive(p,fd) then _G.FlyHighDataManager.UpdateAltitude(p,fd.altitudeKm) end end
   sync(fd)
  end
 end
end)
