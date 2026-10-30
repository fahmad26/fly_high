local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local RS=game:GetService("ReplicatedStorage")
local Config=require(RS.FlyHigh.Modules.FlyHighConfig)
local U=require(script.Parent.ServerUtils)
local remotes=RS.FlyHigh.Remotes
local Physics=game:GetService("PhysicsService")
pcall(function()Physics:RegisterCollisionGroup("FlyHighBalloons")end)
pcall(function()Physics:RegisterCollisionGroup("FlyHighWinching")end)
for _,name in {"Default","FlyHighBalloons","FlyHighWinching"}do Physics:CollisionGroupSetCollidable("FlyHighWinching",name,false)end
local Manager={activeTethers={},attachHandlers=setmetatable({},{__mode="k"}),ropePools=setmetatable({},{__mode="k"}),ropeRepairs=setmetatable({},{__mode="k"})}
_G.FlyHighTetherManager=Manager

local function stationText(pool)
 local station=pool.station
 if not station.Parent then return end
 local used,available,damaged,repairing=0,0,0,0
 for _,slot in pool.slots do
  if slot.holder then used+=1
  elseif slot.repair then repairing+=1
  else
   if slot.value.Value>0 then available+=1 end
   if slot.value.Value<Config.ROPE_MAX_DURABILITY then damaged+=1 end
  end
 end
 station:SetAttribute("RopesInUse",used)
 station:SetAttribute("AvailableRopes",available)
 station:SetAttribute("RepairableRopes",damaged)
 station.TetherPrompt.ObjectText=string.format("Stasiun Tali (%d/%d siap)",available,#pool.slots)
 station.RepairRopePrompt.Enabled=damaged>0 or repairing>0
end

local function independentOwner(t,automatic)
 -- A seat weld belongs to the balloon assembly; never transfer balloon ownership.
 if t.hrp:IsDescendantOf(workspace)and not t.hrp.Anchored and not t.hum.SeatPart and t.hrp.AssemblyRootPart~=t.balloon.PrimaryPart then
  if automatic then t.hrp:SetNetworkOwnershipAuto()
  elseif t.player.Parent==Players then t.hrp:SetNetworkOwner(t.player)end
 end
end
local function restoreCollisions(t)
 for part,group in pairs(t.collisionGroups or {})do if part.Parent then part.CollisionGroup=group end end
 t.collisionGroups=nil
end

function Manager.CancelRopeRepair(p)
 local repair=Manager.ropeRepairs[p]
 if not repair then return end
 Manager.ropeRepairs[p]=nil
 if repair.slot.repair==repair then
  repair.slot.repair=nil
  if repair.slot.value.Parent then repair.slot.value:SetAttribute("RepairUserId",0)end
 end
 stationText(repair.pool)
 if p.Parent==Players then
  p:SetAttribute("RopeRepairing",false)
  p:SetAttribute("CrewRole",nil)
  remotes.TetherEvent:FireClient(p,{isTethered=false,isRepairingRope=false})
 end
end

function Manager.CleanupPlayer(p)
 Manager.CancelRopeRepair(p)
 local t=Manager.activeTethers[p.UserId]
 if not t then return end
 Manager.activeTethers[p.UserId]=nil
 if p.Parent==Players then p:SetAttribute("CrewRole",nil) end
 if t.hrp.Parent and t.winch then
  local root=t.balloon.PrimaryPart
  if root and root.Parent then t.hrp.CFrame=root.CFrame*CFrame.new(t.winch.from)t.hrp.AssemblyLinearVelocity=root.AssemblyLinearVelocity end
  t.hrp.AssemblyAngularVelocity=Vector3.zero t.hrp.Anchored=t.oldAnchored
 end
 restoreCollisions(t)
 if t.hum.Parent and t.winch then t.hum.AutoRotate=t.oldAutoRotate end
 t.rope:Destroy()t.attChar:Destroy()
 if t.slot.holder==p then
  t.slot.holder=nil
  if t.slot.value.Parent then
   t.slot.value.Value=t.durability
   t.slot.value:SetAttribute("HolderUserId",0)
  end
 end
 independentOwner(t,true)
 stationText(t.pool)
 if p.Parent==Players then remotes.TetherEvent:FireClient(p,{isTethered=false,isRepairingRope=false})end
end

function Manager.CleanupBalloon(b)
 Manager.attachHandlers[b]=nil
 for p,repair in pairs(table.clone(Manager.ropeRepairs))do if repair.balloon==b then Manager.CancelRopeRepair(p)end end
 for _,t in pairs(table.clone(Manager.activeTethers))do if t.balloon==b then Manager.CleanupPlayer(t.player)end end
 Manager.ropePools[b]=nil
end

local function stationContext(p)
 local fd=U.Flight(p)
 local pool=fd and Manager.ropePools[fd.balloon]
 if not pool or not U.CrewNear(p,fd.balloon,pool.station,10)or not U.InBasket(p.Character.HumanoidRootPart,fd.balloon.BasketFloor)then return end
 return fd,pool
end

function Manager.BeginRopeRepair(p)
 if not U.CanStartRole(p) then return false end
 local fd,pool=stationContext(p)
 if not fd then return false end
 local selected
 for _,slot in pool.slots do
  if not slot.holder and not slot.repair and slot.value.Value<Config.ROPE_MAX_DURABILITY and(not selected or slot.value.Value<selected.value.Value)then selected=slot end
 end
 if not selected then return false end
 local repair={balloon=fd.balloon,pool=pool,slot=selected,character=p.Character,start=os.clock(),duration=pool.station.RepairRopePrompt.HoldDuration}
 selected.repair=repair Manager.ropeRepairs[p]=repair
 selected.value:SetAttribute("RepairUserId",p.UserId)
 p:SetAttribute("RopeRepairing",true)
 p:SetAttribute("CrewRole","Engineer")
 stationText(pool)
 remotes.TetherEvent:FireClient(p,{isTethered=false,isRepairingRope=true,repairDuration=repair.duration})
 return true
end

function Manager.FinishRopeRepair(p)
 local repair=Manager.ropeRepairs[p]
 if not repair or os.clock()-repair.start<repair.duration-.08 then return false end
 local fd,pool=stationContext(p)
 if not fd or pool~=repair.pool or p.Character~=repair.character or Manager.activeTethers[p.UserId]or repair.slot.holder or repair.slot.repair~=repair then Manager.CancelRopeRepair(p)return false end
 repair.slot.value.Value=Config.ROPE_MAX_DURABILITY
 Manager.CancelRopeRepair(p)
 return true
end

local function syncTether(t,inside)
 t.slot.value.Value=t.durability
 remotes.TetherEvent:FireClient(t.player,{isTethered=true,durability=t.durability,insideBasket=inside,stage=t.stage,ropeSlot=t.slot.index})
end

local function travel(p,b,descending)
 local t=Manager.activeTethers[p.UserId]
 if not t or t.balloon~=b or t.winch or not U.Alive(p,U.Flight(p))then return false end
 U.Unseat(p)
 local leg=t.hum.RigType==Enum.HumanoidRigType.R6 and p.Character:FindFirstChild("Left Leg")
 local standing=t.hum.HipHeight+t.hrp.Size.Y/2+(leg and leg.Size.Y or 0)+math.max(.1,t.hrp.Size.Y/2)
 local destination=descending and Vector3.new(t.slot.index==2 and 4 or -4,b.BasketFloor.Size.Y/2+standing,8)or Vector3.new(0,18.6+standing,t.slot.index==2 and 16 or -16)
 t.oldAnchored=t.hrp.Anchored t.oldAutoRotate=t.hum.AutoRotate
 t.collisionGroups={}
 for _,part in p.Character:GetDescendants()do if part:IsA("BasePart")then t.collisionGroups[part]=part.CollisionGroup part.CollisionGroup="FlyHighWinching"end end
 t.hrp.Anchored=true t.hum.AutoRotate=false t.repair=nil
 t.stage=descending and "Descending"or "Climbing"
 t.winch={from=b.PrimaryPart.CFrame:PointToObjectSpace(t.hrp.Position),to=destination,elapsed=0,detach=descending}
 syncTether(t,U.InBasket(t.hrp,b.BasketFloor))
 return true
end

function Manager.SetupBalloonTethers(b,count)
 if b:GetAttribute("TethersSetup")then return end
 b:SetAttribute("TethersSetup",true)
 local station=b.TetherStation local floor=b.BasketFloor local walkway=b.EnvelopeWalkway
 local function prompt(name,action,key,hold)
  local p=station:FindFirstChild(name)or Instance.new("ProximityPrompt")
  p.Name=name p.ActionText=action p.ObjectText="Stasiun Tali"p.KeyboardKeyCode=key p.HoldDuration=hold p.RequiresLineOfSight=false p.MaxActivationDistance=10 p.Parent=station
  return p
 end
 prompt("TetherPrompt","Pasang Tali Pengaman",Enum.KeyCode.E,.5)
 local detach=prompt("DetachTetherPrompt","Lepas Tali Pengaman",Enum.KeyCode.T,0)detach.GamepadKeyCode=Enum.KeyCode.ButtonL2
 local ropeRepair=prompt("RepairRopePrompt","Perbaiki Tali yang Dilepas",Enum.KeyCode.C,Config.ROPE_MAX_DURABILITY/Config.ROPE_REPAIR_RATE_PER_SEC)
 ropeRepair.GamepadKeyCode=Enum.KeyCode.ButtonR3
 -- Two simultaneous station actions need separate native prompt rows.
 for _,p in {station.TetherPrompt,detach}do p.UIOffset=Vector2.new(0,-48)end
 for _,p in {station.ClimbPrompt,ropeRepair}do p.UIOffset=Vector2.new(0,48)end
 walkway.DescendPrompt.ActionText="Turun ke Gondola & Lepas Tali"
 walkway.DescendPrompt.MaxActivationDistance=28 walkway.DescendPrompt.RequiresLineOfSight=false
 local folder=Instance.new("Folder")folder.Name="RopeSlots"folder.Parent=station
 local pool={station=station,slots={}}
 Manager.ropePools[b]=pool
 for i=1,count==3 and 2 or 1 do
  local value=Instance.new("NumberValue")value.Name="Rope"..i value.Value=Config.ROPE_MAX_DURABILITY value:SetAttribute("HolderUserId",0)value:SetAttribute("RepairUserId",0)value.Parent=folder
  table.insert(pool.slots,{index=i,value=value})
 end
 station:SetAttribute("MaxRopes",#pool.slots)stationText(pool)
 b.Destroying:Connect(function()Manager.CleanupBalloon(b)end)
 local function attach(p)
  local fd,ownPool=stationContext(p)
  if not fd or fd.balloon~=b or ownPool~=pool or not U.CanStartRole(p) then return false end
  local root=p.Character.HumanoidRootPart local hum=p.Character:FindFirstChildOfClass("Humanoid")
  if root.Anchored or hum.Sit then return false end
  local selected
  for _,slot in pool.slots do
   if not slot.holder and not slot.repair and slot.value.Value>0 and(not selected or slot.value.Value>selected.value.Value)then selected=slot end
  end
  if not selected then return false end
  local a=station:FindFirstChild("TetherAttachment")or Instance.new("Attachment",station)a.Name="TetherAttachment"
  local ac=Instance.new("Attachment",root)ac.Name="RopeAttach"
  -- Visual rope keeps avatar and server-owned balloon in separate physics mechanisms.
  local rope=Instance.new("Beam")rope.Name="SafetyRope"rope.Attachment0=a rope.Attachment1=ac
  rope.FaceCamera=true rope.Width0=.2 rope.Width1=.2 rope.Color=ColorSequence.new(Color3.fromRGB(255,220,60))rope.Parent=root
  local t={player=p,balloon=b,pool=pool,slot=selected,station=station,hrp=root,hum=hum,rope=rope,attChar=ac,durability=selected.value.Value,stage="Basket"}
  selected.holder=p selected.value:SetAttribute("HolderUserId",p.UserId)
  Manager.activeTethers[p.UserId]=t
  p:SetAttribute("CrewRole","Engineer")
  independentOwner(t,false)
  stationText(pool)syncTether(t,true)
  return true
 end
 Manager.attachHandlers[b]=attach
 station.TetherPrompt.Triggered:Connect(attach)
 station.DetachTetherPrompt.Triggered:Connect(function(p)if U.CrewNear(p,b,station,10)then Manager.CleanupPlayer(p)end end)
 station.ClimbPrompt.Triggered:Connect(function(p)if U.CrewNear(p,b,station,10)and U.InBasket(p.Character.HumanoidRootPart,floor)then travel(p,b,false)end end)
 walkway.DescendPrompt.Triggered:Connect(function(p)if U.CrewNear(p,b,walkway,28)and not U.InBasket(p.Character.HumanoidRootPart,floor)then travel(p,b,true)end end)
 ropeRepair.PromptButtonHoldBegan:Connect(function(p)Manager.BeginRopeRepair(p)end)
 ropeRepair.Triggered:Connect(function(p)Manager.FinishRopeRepair(p)end)
 ropeRepair.PromptButtonHoldEnded:Connect(function(p)
  local repair=Manager.ropeRepairs[p]
  task.delay(.2,function()if repair and Manager.ropeRepairs[p]==repair then Manager.CancelRopeRepair(p)end end)
 end)
 local duration=count==1 and 1.5 or(count==2 and 2 or 3)
 for _,hole in b.HoleSlots:GetChildren()do
  local patch=hole.PatchPrompt patch.HoldDuration=duration patch.RequiresLineOfSight=false
  patch.PromptButtonHoldBegan:Connect(function(p)Manager.BeginRepair(p,tonumber(hole.Name:match("%d+")))end)
  patch.Triggered:Connect(function(p)Manager.FinishRepair(p)end)
  patch.PromptButtonHoldEnded:Connect(function(p)
   local t=Manager.activeTethers[p.UserId]local repair=t and t.repair
   task.delay(.2,function()if t and t.repair==repair then t.repair=nil end end)
  end)
 end
end

function Manager.BeginRepair(p,n)
 if type(n)~="number"or n%1~=0 or n<1 or n>5 then return false end
 local fd=U.Flight(p)local t=Manager.activeTethers[p.UserId]
 if not fd or not t or t.balloon~=fd.balloon or t.winch or t.stage~="Catwalk"or fd.holes>=5 then return false end
 local hole=fd.balloon.HoleSlots:FindFirstChild("Hole"..n)
 if not fd.holeSet[n]or not U.CrewNear(p,fd.balloon,hole,10)then return false end
 t.repair={number=n,start=os.clock(),duration=hole.PatchPrompt.HoldDuration,hole=hole}
 return true
end
function Manager.FinishRepair(p)
 local fd=U.Flight(p)local t=Manager.activeTethers[p.UserId]local repair=t and t.repair
 if not repair or os.clock()-repair.start<repair.duration-.08 then return false end
 t.repair=nil
 if not fd or t.balloon~=fd.balloon or t.winch or t.stage~="Catwalk"or not U.CrewNear(p,fd.balloon,repair.hole,10)then return false end
 return _G.FlyHighBalloonManager.RepairHole(fd,repair.number)
end
local repairRate=U.RateLimiter(.08)
remotes.RepairHoleEvent.OnServerEvent:Connect(function(p,action,n)
 if not repairRate(p)then return end
 if action=="Begin"then Manager.BeginRepair(p,n)
 elseif action=="Finish"then Manager.FinishRepair(p)
 elseif action=="Cancel"then local t=Manager.activeTethers[p.UserId]if t then t.repair=nil end end
end)
local travelRate=U.RateLimiter(.3)
remotes.TetherEvent.OnServerEvent:Connect(function(p,action)
 if action=="CancelRopeRepair"then Manager.CancelRopeRepair(p)return end
 if not travelRate(p)then return end
 if action=="BeginRopeRepair"then Manager.BeginRopeRepair(p)return
 elseif action=="FinishRopeRepair"then Manager.FinishRopeRepair(p)return end
 local fd=U.Flight(p)local t=Manager.activeTethers[p.UserId]
 if action=="Attach"then if fd and Manager.attachHandlers[fd.balloon]then Manager.attachHandlers[fd.balloon](p)end return end
 if not fd or not t or t.balloon~=fd.balloon then return end
 if action=="Detach"then Manager.CleanupPlayer(p)return end
 if action=="Climb"and U.CrewNear(p,fd.balloon,fd.balloon.TetherStation,10)and U.InBasket(t.hrp,fd.balloon.BasketFloor)then travel(p,fd.balloon,false)
 elseif action=="Descend"and U.CrewNear(p,fd.balloon,fd.balloon.EnvelopeWalkway,28)and not U.InBasket(t.hrp,fd.balloon.BasketFloor)then travel(p,fd.balloon,true)end
end)
Players.PlayerRemoving:Connect(Manager.CleanupPlayer)
RunService.Heartbeat:Connect(function(dt)
 local bm=_G.FlyHighBalloonManager
 for _,fd in ipairs(bm and bm.activeFlights or {})do fd.engineerTilt=Vector3.zero end
 for p,repair in pairs(table.clone(Manager.ropeRepairs))do
  local fd,pool=stationContext(p)
  if not fd or pool~=repair.pool or p.Character~=repair.character or Manager.activeTethers[p.UserId]then Manager.CancelRopeRepair(p)end
 end
 for _,t in pairs(table.clone(Manager.activeTethers))do
  local p=t.player local fd=U.Flight(p)
  if not fd or fd.balloon~=t.balloon or not U.Alive(p,fd)or not t.hrp.Parent then Manager.CleanupPlayer(p)continue end
  if t.repair and(t.winch or not t.repair.hole.Parent or not U.Near(p,t.repair.hole,10)or fd.holes>=5)then t.repair=nil end
  if t.winch then
   local w=t.winch w.elapsed+=dt
   local alpha=math.clamp(w.elapsed/Config.WINCH_MOVE_DURATION_SEC,0,1)local eased=alpha*alpha*(3-2*alpha)
   -- Re-evaluate against the moving balloon, never against a cached world altitude.
   t.hrp.CFrame=t.balloon.PrimaryPart.CFrame*CFrame.new(w.from:Lerp(w.to,eased))
   -- Replicate the settled landing pose before returning physics ownership.
   if w.elapsed>=Config.WINCH_MOVE_DURATION_SEC+Config.WINCH_SETTLE_DURATION_SEC then
    t.hrp.Anchored=t.oldAnchored t.hrp.AssemblyLinearVelocity=fd.root.AssemblyLinearVelocity t.hrp.AssemblyAngularVelocity=Vector3.zero
    restoreCollisions(t)
    t.hum.AutoRotate=t.oldAutoRotate t.hum:Move(Vector3.zero,false)t.winch=nil
    independentOwner(t,false)
    if w.detach then Manager.CleanupPlayer(p)continue end
    t.stage="Catwalk"
   end
  end
  local inside=U.InBasket(t.hrp,t.balloon.BasketFloor)
  if inside and not t.winch then t.stage="Basket"end
  if not inside then
   t.durability=math.max(0,t.durability-Config.ROPE_DECAY_PER_SEC*dt)
   local offset=fd.root.CFrame:PointToObjectSpace(t.hrp.Position)
   fd.engineerTilt+=Vector3.new(math.clamp(offset.Z*.005,-.12,.12),0,math.clamp(-offset.X*.005,-.12,.12))
  end
  if t.durability<=0 then
   local hum=t.hum Manager.CleanupPlayer(p)if hum.Parent then hum.Health=0 end
  elseif os.clock()-(t.lastSync or 0)>=.1 then t.lastSync=os.clock()syncTether(t,inside)end
 end
end)
local pingRate=U.RateLimiter(2)
remotes.TacticalPingEvent.OnServerEvent:Connect(function(p,kind,position,message)
 local fd=U.Flight(p)
 if not fd or not U.FiniteVector(position)or(position-fd.root.Position).Magnitude>300 or not pingRate(p)then return end
 local ghost=not U.Alive(p,fd)
 if kind=="GhostSpot"and not ghost then return end
 if kind~="GhostSpot"and kind~="QuickPing"then return end
 if kind=="GhostSpot"then message="Bahaya terdeteksi oleh arwah!"
 elseif not table.find(Config.TACTICAL_MESSAGES,message)or ghost then return end
 for _,crew in ipairs(fd.players)do if crew.Parent==Players then remotes.TacticalPingEvent:FireClient(crew,position,message,p.DisplayName)end end
end)
