-- Temporary native-client automation; never shipped in the place.
if not game:GetService("RunService"):IsStudio()then return end
local P=game.Players local RS=game.ReplicatedStorage local Run=game:GetService("RunService")local player=P.LocalPlayer
local R=RS.FlyHigh.Remotes local qa=R:WaitForChild("FullJourneyQAEvent")local input=game:GetService("UserInputService"):CreateVirtualInput()
local logs={}local biomes={}local samples={}local events={warnings=0,storms=0,shots=0}local shooter=false local lane=nil local goal=nil
game:GetService("LogService").MessageOut:Connect(function(m,k)
 if k==Enum.MessageType.MessageWarning or k==Enum.MessageType.MessageError then
  if m:find("[Roblox][sabuiltin_Assistant",1,true)==1 and m:find("The execute_luau changed camera type.",1,true)then return end
  table.insert(logs,{message=m,kind=k.Name})
 end
end)
local function balloon()local r=player:FindFirstChild("FlightBalloon")return r and r.Value end
R.HazardAlertEvent.OnClientEvent:Connect(function()events.warnings+=1 end)
R.LargeChallengeEvent.OnClientEvent:Connect(function(d)if d.kind=="Warning"then events.storms+=1 end end)
R.WeaponFireEvent.OnClientEvent:Connect(function(p)if p==player then events.shots+=1 end end)
R.FlightStateSyncEvent.OnClientEvent:Connect(function(d)
 local b=math.clamp(math.floor((d.altitudeKm or 0)/2000)+1,1,5)
 if not biomes[b]then
  biomes[b]=true
  task.delay(5.4,function()local l=game.Lighting table.insert(samples,{biome=b,clock=l.ClockTime,brightness=l.Brightness,fogEnd=l.FogEnd})end)
 end
end)
Run:BindToRenderStep("FullJourneyWalk",Enum.RenderPriority.Last.Value-1,function()
 local c=player.Character local h=c and c:FindFirstChildOfClass("Humanoid")local root=c and c:FindFirstChild("HumanoidRootPart")local b=balloon()
 if goal and h and root and b and b.Parent then
  local q=b.PrimaryPart.CFrame:PointToWorldSpace(goal)local v=Vector3.new(q.X-root.Position.X,0,q.Z-root.Position.Z)
  h:Move(v.Magnitude>.15 and v.Unit*math.min(1,v.Magnitude/2)or Vector3.zero,false)
 end
end)
task.spawn(function()
 while task.wait(.1)do
  local c=player.Character local h=c and c:FindFirstChildOfClass("Humanoid")local b=balloon()
  if b and b.Parent and h and h.Health>0 then
   if lane and h.SeatPart==b.HelmSeat then
    local d=Vector3.new(lane.X-b.PrimaryPart.Position.X,0,lane.Z-b.PrimaryPart.Position.Z)
    local v=d.Magnitude>2 and d.Unit*math.min(1,d.Magnitude/8)or Vector3.zero
    R.PilotControlEvent:FireServer(v,false)
   end
   local tool=c:FindFirstChildOfClass("Tool")
   if shooter and tool and not tool:GetAttribute("Reloading")then
    local best local distance=180
    for _,m in workspace.FlyHighObstacles:GetChildren()do
     local p=m.PrimaryPart
     if p and m:GetAttribute("Shootable")then local d=(p.Position-tool.Handle.Position).Magnitude if d<distance then best=p distance=d end end
    end
    if best then R.WeaponFireEvent:FireServer(tool.Handle.Position,best.Position)end
   end
  end
 end
end)
local function waitFor(fn,t)local stop=os.clock()+t repeat local v=fn()if v then return v end task.wait(.05)until os.clock()>stop end
qa.OnClientEvent:Connect(function(id,action,data)
 local ok,result=xpcall(function()
  data=data or {}
  if action=="Ready"then assert(player.PlayerGui:WaitForChild("FlyHighHUD",30))return true
  elseif action=="Pose"then
   local c=player.Character local h=c.Humanoid h.Sit=false h:ChangeState(Enum.HumanoidStateType.GettingUp)
   local cf=data.relative and data.balloon.PrimaryPart.CFrame*data.relative or data.cf
   c:PivotTo(cf)c.HumanoidRootPart.AssemblyLinearVelocity=Vector3.zero task.wait(.15)return true
  elseif action=="StopWalk"then goal=nil player.Character.Humanoid:Move(Vector3.zero,false)return true
  elseif action=="PhysicalState"then
   local b=balloon()local c=player.Character local root=c.HumanoidRootPart
   return {position=tostring(b.PrimaryPart.CFrame:PointToObjectSpace(root.Position)),anchored=root.Anchored,state=c.Humanoid:GetState().Name,role=player:GetAttribute("CrewRole")}
  elseif action=="Start"then
   local o=workspace.FlyHighLobby.MatchmakingPods[data.pod].Console.StartPrompt
   local camera=workspace.CurrentCamera local root=player.Character.HumanoidRootPart camera.CameraType=Enum.CameraType.Scriptable camera.CFrame=CFrame.lookAt(root.Position+Vector3.new(0,4,8),o.Parent.Position)task.wait(.2)
   input:SendKey(true,o.KeyboardKeyCode,false)task.wait(math.max(.5,o.HoldDuration+.2))input:SendKey(false,o.KeyboardKeyCode,false)camera.CameraType=Enum.CameraType.Custom return true
  elseif action=="Lane"then lane=data.target return true
  elseif action=="ShootBot"then shooter=data.enabled return true
  elseif action=="Action"then R.FlightActionEvent:FireServer(data.action,data.value)return true
  elseif action=="Tether"then R.TetherEvent:FireServer(data.action)return true
  elseif action=="Kit"then R.EmergencyKitEvent:FireServer()return true
  elseif action=="FollowStation"then
   goal=data.enabled and Vector3.new(0,4,6)or nil
   if not goal then player.Character.Humanoid:Move(Vector3.zero,false)end return true
  elseif action=="WalkHole"then
   local b=assert(balloon())local root=player.Character.HumanoidRootPart local hole=b.HoleSlots["Hole"..data.number]
   local q=b.PrimaryPart.CFrame:PointToObjectSpace(root.Position)local h=b.PrimaryPart.CFrame:PointToObjectSpace(hole.Position)
   local current=math.atan2(q.X,-q.Z)local finish=math.atan2(h.X,-h.Z)
   local delta=(finish-current+math.pi)%(math.pi*2)-math.pi
   local travelled=0
   while math.abs(travelled-delta)>.01 do
    local step=math.clamp(delta-travelled,-math.pi/8,math.pi/8)travelled+=step
    goal=Vector3.new(math.sin(current+travelled)*16,20,-math.cos(current+travelled)*16)
    assert(waitFor(function()local p=b.PrimaryPart.CFrame:PointToObjectSpace(root.Position)return Vector2.new(p.X-goal.X,p.Z-goal.Z).Magnitude<.5 end,4),"walk timed out")
   end
   return true -- Keep following this local point through the repair hold.
  elseif action=="Snapshot"then
   local c=player.Character local h=c and c:FindFirstChildOfClass("Humanoid")local camera=workspace.CurrentCamera
   return {logs=logs,biomes=biomes,lightingSamples=samples,events=events,alive=h and h.Health>0,inFlight=player:GetAttribute("InFlight"),cameraMode=player.CameraMode.Name,zoom=(camera.CFrame.Position-camera.Focus.Position).Magnitude}
  elseif action=="Leave"then
   local s=game:GetService("StudioTestService")local yes=s:CanLeaveTest()if yes then task.delay(.2,function()s:LeaveTest()end)end return yes
  end
  error("unknown QA action "..action)
 end,debug.traceback)
 if not ok then goal=nil end
 qa:FireServer(id,ok,result)
end)
