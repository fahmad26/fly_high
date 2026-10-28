local Players=game:GetService("Players")
local Run=game:GetService("RunService")
local RS=game:GetService("ReplicatedStorage")
local C=require(RS.FlyHigh.Modules.FlyHighConfig)
local U=require(script.Parent.ServerUtils)
local remote=RS.FlyHigh.Remotes.FlightJumpEvent
local Manager={states=setmetatable({},{__mode="k"})}
_G.FlyHighJumpManager=Manager
function Manager.CanJump(p,fd)
 if not U.Alive(p,fd)then return false,"Kru tidak aktif"end
 local hum=p.Character:FindFirstChildOfClass("Humanoid")local root=p.Character:FindFirstChild("HumanoidRootPart")
 if not root then return false,"Menunggu karakter"end
 if fd.pilot==p or hum.SeatPart==fd.balloon.HelmSeat then return false,"Lepas kemudi dahulu [H]"end
 local tether=_G.FlyHighTetherManager and _G.FlyHighTetherManager.activeTethers[p.UserId]
 if tether and (tether.winch or tether.repair)then return false,"Selesaikan katrol / perbaikan"end
 local floor=fd.balloon:FindFirstChild("BasketFloor")
 if not floor then return false,"Menunggu gondola"end
 local q=floor.CFrame:PointToObjectSpace(root.Position)
 if math.abs(q.X)>floor.Size.X/2 or math.abs(q.Z)>floor.Size.Z/2 or q.Y<0 or q.Y>C.JUMP_BASKET_HEIGHT then return false,"Kembali ke gondola [Q]"end
 if root.Anchored then return false,"Tunggu gerakan katrol selesai"end
 return true,"Lompat bersama untuk turun"
end
function Manager.EligibleCount(fd)
 local n=0 for _,p in ipairs(fd.players)do if Manager.CanJump(p,fd)then n+=1 end end return math.max(1,n)
end
local function restore(st)
 if st.hum.Parent then
  st.hum:SetStateEnabled(Enum.HumanoidStateType.Jumping,st.enabled)
  st.hum.JumpPower=st.power st.hum.JumpHeight=st.height
 end
end
local function state(p,fd)
 local hum=p.Character and p.Character:FindFirstChildOfClass("Humanoid")
 if not hum then return nil end
 local st=Manager.states[p]
 if not st or st.fd~=fd or st.hum~=hum then
  if st then if st.jumpConnection then st.jumpConnection:Disconnect()end restore(st)end
  st={fd=fd,hum=hum,enabled=hum:GetStateEnabled(Enum.HumanoidStateType.Jumping),power=hum.JumpPower,height=hum.JumpHeight,lastAt=-math.huge,lastGroundAt=-math.huge}
  st.jumpConnection=hum.Jumping:Connect(function(active)if active then st.actualJumpAt=os.clock()end end)
  Manager.states[p]=st p:SetAttribute("FlightJumpCount",0)p:SetAttribute("FlightJumpReadyAt",0)
 end
 return st
end
function Manager.Request(p)
 local fd=U.Flight(p)if not fd or not Manager.CanJump(p,fd)then return false end
 local st=state(p,fd)if not st then return false end
 st.pendingAt=st.pendingAt or os.clock()return true
end
local rate=U.RateLimiter(.15)
remote.OnServerEvent:Connect(function(p,action)
 if action=="Request"and rate(p)then Manager.Request(p)end
end)
local elapsed=0
Run.Heartbeat:Connect(function(dt)
 elapsed+=dt if elapsed<.04 then return end elapsed=0
 local bm=_G.FlyHighBalloonManager local touched={}local now=os.clock()
 for _,fd in ipairs(bm and bm.activeFlights or {})do
  if fd.isGameOver or fd.isVictory or not fd.balloon.Parent then continue end
  for _,p in ipairs(fd.players)do
   if p.Parent~=Players then continue end
   local st=state(p,fd)if not st then continue end touched[p]=true
   local allowed,reason=Manager.CanJump(p,fd)
   if p:GetAttribute("FlightJumpAllowed")~=allowed then p:SetAttribute("FlightJumpAllowed",allowed)end
   if p:GetAttribute("FlightJumpReason")~=reason then p:SetAttribute("FlightJumpReason",reason)end
   if st.blocked~=(not allowed)then
    st.blocked=not allowed
    if allowed then restore(st)
    else st.hum:SetStateEnabled(Enum.HumanoidStateType.Jumping,false)st.hum.JumpPower=0 st.hum.JumpHeight=0 st.hum.Jump=false end
   end
   if not allowed then st.pendingAt=nil st.actualJumpAt=nil st.lastGroundAt=-math.huge continue end
   local root=p.Character.HumanoidRootPart local hum=st.hum
   local q=fd.balloon.BasketFloor.CFrame:PointToObjectSpace(root.Position)
   local relativeVy=root.AssemblyLinearVelocity.Y-fd.root.AssemblyLinearVelocity.Y
   local params=RaycastParams.new()params.FilterType=Enum.RaycastFilterType.Exclude params.FilterDescendantsInstances={p.Character}
   local hit=workspace:Raycast(root.Position,Vector3.new(0,-(hum.HipHeight+root.Size.Y/2+.8),0),params)
   local grounded=hum.FloorMaterial~=Enum.Material.Air and hit and hit.Instance:IsDescendantOf(fd.balloon)and relativeVy<=3 and hum:GetState()~=Enum.HumanoidStateType.Jumping
   if grounded then st.lastGroundAt=now st.groundY=q.Y st.consumed=false end
   if st.pendingAt and now-st.pendingAt>.45 then st.pendingAt=nil end
   local actualTakeoff=st.groundY and q.Y-st.groundY>=.35 and q.Y-st.groundY<=16 and relativeVy>=6 and relativeVy<=85
   local observedJump=(st.actualJumpAt and now-st.actualJumpAt<=.65)or root.AssemblyLinearVelocity.Y>=6
   if observedJump and not st.consumed and now-st.lastAt>=C.JUMP_COOLDOWN_SEC and now-st.lastGroundAt<=.65 and actualTakeoff and(st.pendingAt or hum:GetState()==Enum.HumanoidStateType.Jumping or(st.actualJumpAt and now-st.actualJumpAt<=.65))and fd.holes<C.MAX_HOLES and fd.root.Position.Y>C.GROUND_Y+1 then
    local drop=C.JUMP_DROP_STUDS/Manager.EligibleCount(fd)
    fd.jumpDropRemaining=math.min(C.JUMP_MAX_PENDING_STUDS,(fd.jumpDropRemaining or 0)+drop)
    fd.jumpCount=(fd.jumpCount or 0)+1 fd.jumpDropTotal=(fd.jumpDropTotal or 0)+drop
    fd.balloon:SetAttribute("JumpCount",fd.jumpCount)fd.balloon:SetAttribute("JumpDropTotal",fd.jumpDropTotal)
    st.consumed=true st.lastAt=now st.pendingAt=nil st.actualJumpAt=nil
    p:SetAttribute("FlightJumpCount",(p:GetAttribute("FlightJumpCount")or 0)+1)
    p:SetAttribute("FlightJumpReadyAt",workspace:GetServerTimeNow()+C.JUMP_COOLDOWN_SEC)
    remote:FireClient(p,{accepted=true,dropStuds=drop})
   end
  end
 end
 for p,st in pairs(Manager.states)do if not touched[p]then
  if st.jumpConnection then st.jumpConnection:Disconnect()end restore(st)Manager.states[p]=nil
  if p.Parent==Players then p:SetAttribute("FlightJumpAllowed",true)p:SetAttribute("FlightJumpReason","")end
 end end
end)
Players.PlayerRemoving:Connect(function(p)local st=Manager.states[p]if st then restore(st)Manager.states[p]=nil end end)
