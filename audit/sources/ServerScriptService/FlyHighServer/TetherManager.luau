local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local RS=game:GetService("ReplicatedStorage")
local Config=require(RS.FlyHigh.Modules.FlyHighConfig)
local U=require(script.Parent.ServerUtils)
local remotes=RS.FlyHigh.Remotes
local Manager={activeTethers={},attachHandlers=setmetatable({},{__mode="k"})}
_G.FlyHighTetherManager=Manager
local function stationText(station)
 local used=station:GetAttribute("RopesInUse") or 0
 local max=station:GetAttribute("MaxRopes") or 1
 station.TetherPrompt.ObjectText=string.format("Stasiun Tali (%d/%d tersedia)",math.max(0,max-used),max)
end
function Manager.CleanupPlayer(p)
 local t=Manager.activeTethers[p.UserId]
 if not t then return end
 Manager.activeTethers[p.UserId]=nil
 if t.hrp.Parent and t.winch then t.hrp.Anchored=t.oldAnchored end
 if t.hum and t.hum.Parent then t.hum.AutoRotate=true end
 t.rope:Destroy() t.attChar:Destroy()
 if t.station.Parent then
  t.station:SetAttribute("RopesInUse",math.max(0,(t.station:GetAttribute("RopesInUse") or 1)-1))
  stationText(t.station)
 end
 if p.Parent==Players then remotes.TetherEvent:FireClient(p,{isTethered=false}) end
end
function Manager.CleanupBalloon(b)
 Manager.attachHandlers[b]=nil
 for _,t in pairs(table.clone(Manager.activeTethers)) do if t.balloon==b then Manager.CleanupPlayer(t.player) end end
end
local function travel(p,b,destination)
 local t=Manager.activeTethers[p.UserId]
 if not t or t.balloon~=b or t.winch or not U.Alive(p,U.Flight(p)) then return end
 U.Unseat(p)
 t.oldAnchored=t.hrp.Anchored t.hrp.Anchored=true t.hum.AutoRotate=false
 t.winch={from=b.PrimaryPart.CFrame:PointToObjectSpace(t.hrp.Position),to=destination,elapsed=0}
end
function Manager.SetupBalloonTethers(b,count)
 if b:GetAttribute("TethersSetup") then return end
 b:SetAttribute("TethersSetup",true)
 b.Destroying:Connect(function() Manager.CleanupBalloon(b) end)
 local station=b.TetherStation
 local floor=b.BasketFloor
 local walkway=b.EnvelopeWalkway
 local max=count==3 and 2 or 1
 station:SetAttribute("MaxRopes",max) station:SetAttribute("RopesInUse",0) stationText(station)
 local function attach(p)
  if not U.CrewNear(p,b,station,10) then return end
  local root=p.Character.HumanoidRootPart
  if not U.InBasket(root,floor) then return end
  local existing=Manager.activeTethers[p.UserId]
  if existing then
   if existing.balloon==b and not existing.winch then existing.durability=100 end
   return
  end
  if station:GetAttribute("RopesInUse")>=max then return end
  local a=station:FindFirstChild("TetherAttachment") or Instance.new("Attachment",station)
  a.Name="TetherAttachment"
  local ac=Instance.new("Attachment",root) ac.Name="RopeAttach"
  local rope=Instance.new("RopeConstraint")
  rope.Name="SafetyRope" rope.Attachment0=a rope.Attachment1=ac rope.Length=65
  rope.Visible=true rope.Color=BrickColor.new("Bright yellow") rope.Thickness=0.2 rope.Parent=root
  Manager.activeTethers[p.UserId]={player=p,balloon=b,station=station,hrp=root,hum=p.Character:FindFirstChildOfClass("Humanoid"),
   rope=rope,attChar=ac,durability=100}
  station:SetAttribute("RopesInUse",station:GetAttribute("RopesInUse")+1) stationText(station)
  remotes.TetherEvent:FireClient(p,{isTethered=true,durability=100,insideBasket=true})
 end
 Manager.attachHandlers[b]=attach
 station.TetherPrompt.Triggered:Connect(attach)
 station.ClimbPrompt.Triggered:Connect(function(p)
  if U.CrewNear(p,b,station,10) then travel(p,b,Vector3.new(0,21.6,-20)) end
 end)
 walkway.DescendPrompt.Triggered:Connect(function(p)
  if U.CrewNear(p,b,walkway,28) and not U.InBasket(p.Character.HumanoidRootPart,floor) then travel(p,b,Vector3.new(0,4,8)) end
 end)
 local duration=count==1 and 1.5 or (count==2 and 2 or 3)
 for _,hole in ipairs(b.HoleSlots:GetChildren()) do
  local prompt=hole.PatchPrompt
  prompt.HoldDuration=duration
  prompt.PromptButtonHoldBegan:Connect(function(p) Manager.BeginRepair(p,tonumber(hole.Name:match("%d+"))) end)
  prompt.Triggered:Connect(function(p) Manager.FinishRepair(p) end)
  prompt.PromptButtonHoldEnded:Connect(function(p)
   local t=Manager.activeTethers[p.UserId]
   local repair=t and t.repair
   task.delay(0.2,function() if t and t.repair==repair then t.repair=nil end end)
  end)
 end
end
function Manager.BeginRepair(p,n)
 if type(n)~="number" or n%1~=0 or n<1 or n>5 then return false end
 local fd=U.Flight(p) local t=Manager.activeTethers[p.UserId]
 if not fd or not t or t.balloon~=fd.balloon or t.winch or fd.holes>=5 then return false end
 local hole=fd.balloon.HoleSlots:FindFirstChild("Hole"..n)
 if not fd.holeSet[n] or not U.CrewNear(p,fd.balloon,hole,10) then return false end
 t.repair={number=n,start=os.clock(),duration=hole.PatchPrompt.HoldDuration,hole=hole}
 return true
end
function Manager.FinishRepair(p)
 local fd=U.Flight(p) local t=Manager.activeTethers[p.UserId]
 local repair=t and t.repair
 if not repair then return false end
 if os.clock()-repair.start<repair.duration-0.08 then return false end
 t.repair=nil
 if not fd or t.balloon~=fd.balloon or t.winch or not U.CrewNear(p,fd.balloon,repair.hole,10) then return false end
 return _G.FlyHighBalloonManager.RepairHole(fd,repair.number)
end
local repairRate=U.RateLimiter(0.08)
remotes.RepairHoleEvent.OnServerEvent:Connect(function(p,action,n)
 if not repairRate(p) then return end
 if action=="Begin" then Manager.BeginRepair(p,n)
 elseif action=="Finish" then Manager.FinishRepair(p)
 elseif action=="Cancel" then
  local t=Manager.activeTethers[p.UserId] if t then t.repair=nil end
 end
end)
local travelRate=U.RateLimiter(0.3)
remotes.TetherEvent.OnServerEvent:Connect(function(p,action)
 if not travelRate(p) then return end
 local fd=U.Flight(p) local t=Manager.activeTethers[p.UserId]
 if action=="Attach" then
  if fd and Manager.attachHandlers[fd.balloon] then Manager.attachHandlers[fd.balloon](p) end
  return
 end
 if not fd or not t or t.balloon~=fd.balloon then return end
 if action=="Climb" and U.CrewNear(p,fd.balloon,fd.balloon.TetherStation,10) then travel(p,fd.balloon,Vector3.new(0,21.6,-20))
 elseif action=="Descend" and U.Alive(p,fd) and not U.InBasket(t.hrp,fd.balloon.BasketFloor) and U.Near(p,fd.balloon.EnvelopeWalkway,28) then
  travel(p,fd.balloon,Vector3.new(0,4,8))
 end
end)
Players.PlayerRemoving:Connect(Manager.CleanupPlayer)
RunService.Heartbeat:Connect(function(dt)
 local bm=_G.FlyHighBalloonManager
 for _,fd in ipairs(bm and bm.activeFlights or {}) do fd.engineerTilt=Vector3.zero end
 for _,t in pairs(table.clone(Manager.activeTethers)) do
  local p=t.player
  local fd=U.Flight(p)
  if not fd or fd.balloon~=t.balloon or not U.Alive(p,fd) or not t.hrp.Parent then Manager.CleanupPlayer(p) continue end
  if t.repair and (t.winch or not t.repair.hole.Parent or not U.Near(p,t.repair.hole,10) or fd.holes>=5) then t.repair=nil end
  if t.winch then
   local w=t.winch w.elapsed+=dt
   local alpha=math.clamp(w.elapsed/1.6,0,1)
   local eased=alpha*alpha*(3-2*alpha)
   t.hrp.CFrame=t.balloon.PrimaryPart.CFrame*CFrame.new(w.from:Lerp(w.to,eased))
   if alpha>=1 then
    t.hrp.Anchored=t.oldAnchored t.hrp.AssemblyLinearVelocity=fd.root.AssemblyLinearVelocity
    t.hum.AutoRotate=true t.hum:MoveTo(t.hrp.Position) t.winch=nil
   end
  end
  local inside=U.InBasket(t.hrp,t.balloon.BasketFloor)
  if not inside then
   t.durability=math.max(0,t.durability-Config.ROPE_DECAY_PER_SEC*dt)
   local offset=fd.root.CFrame:PointToObjectSpace(t.hrp.Position)
   fd.engineerTilt+=Vector3.new(math.clamp(offset.Z*0.005,-0.12,0.12),0,math.clamp(-offset.X*0.005,-0.12,0.12))
  end
  if t.durability<=0 then
   local hum=t.hum Manager.CleanupPlayer(p)
   if hum.Parent then hum.Health=0 end
  elseif os.clock()-(t.lastSync or 0)>=0.1 then
   t.lastSync=os.clock()
   remotes.TetherEvent:FireClient(p,{isTethered=true,durability=t.durability,insideBasket=inside})
  end
 end
end)
local pingRate=U.RateLimiter(2)
remotes.TacticalPingEvent.OnServerEvent:Connect(function(p,kind,position,message)
 local fd=U.Flight(p)
 if not fd or not U.FiniteVector(position) or (position-fd.root.Position).Magnitude>300 or not pingRate(p) then return end
 local ghost=not U.Alive(p,fd)
 if kind=="GhostSpot" and not ghost then return end
 if kind~="GhostSpot" and kind~="QuickPing" then return end
 local allowed=Config.TACTICAL_MESSAGES
 if kind=="GhostSpot" then message="Bahaya terdeteksi oleh arwah!"
 elseif not table.find(allowed,message) or ghost then return end
 for _,crew in ipairs(fd.players) do
  if crew.Parent==Players then remotes.TacticalPingEvent:FireClient(crew,position,message,p.DisplayName) end
 end
end)
