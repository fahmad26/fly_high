-- Temporary Studio-only native multiplayer driver. Not shipped in the place.
if not game:GetService("RunService"):IsStudio()then return end
local Players=game:GetService("Players")local RS=game:GetService("ReplicatedStorage")
local player=Players.LocalPlayer local remote=RS.FlyHigh.Remotes:WaitForChild("MultiplayerQAEvent")
local remotes=RS.FlyHigh.Remotes local logs={}
game:GetService("LogService").MessageOut:Connect(function(message,kind)
 if kind==Enum.MessageType.MessageError or kind==Enum.MessageType.MessageWarning then table.insert(logs,{message=message,kind=kind.Name})end
end)
local function mine()local r=player:FindFirstChild("FlightBalloon")return r and r.Value end
local function prompt(modelName,path,force)
 local model=modelName and workspace:WaitForChild(modelName,10)or mine()
 local o=model
 for n in path:gmatch("[^.]+")do o=o:WaitForChild(n,10)assert(o,"missing "..n)end
 if force then o.Enabled=true end
 local cam=workspace.CurrentCamera local oldType=cam.CameraType
 local root=player.Character.HumanoidRootPart
 cam.CameraType=Enum.CameraType.Scriptable
 cam.CFrame=CFrame.lookAt(root.Position+Vector3.new(0,5,9),o.Parent.Position)
 local fired=false local connection=o.Triggered:Connect(function()fired=true end)
 task.wait(.3)
 local before=(root.Position-o.Parent.Position).Magnitude
 local input=game:GetService("UserInputService"):CreateVirtualInput()
 input:SendKey(true,o.KeyboardKeyCode,false)task.wait(math.max(.5,o.HoldDuration+.3))input:SendKey(false,o.KeyboardKeyCode,false)
 task.wait(.2)connection:Disconnect()cam.CameraType=oldType
 return {enabled=o.Enabled,triggered=fired,key=o.KeyboardKeyCode.Name,distance=before,health=player.Character.Humanoid.Health}
end
remote.OnClientEvent:Connect(function(token,action,data)
 local ok,value=xpcall(function()
  if action=="Ping"then
   local gui=player.PlayerGui:WaitForChild("FlyHighHUD",20)
   return {name=player.Name,userId=player.UserId,hud=gui~=nil}
  elseif action=="Start"then
   local pod=workspace.FlyHighLobby.MatchmakingPods[data.pod]
   local o=pod.Console.StartPrompt
   assert(o.Enabled,"start prompt disabled")
   local cam=workspace.CurrentCamera local oldType=cam.CameraType
   local root=player.Character.HumanoidRootPart
   cam.CameraType=Enum.CameraType.Scriptable cam.CFrame=CFrame.lookAt(root.Position+Vector3.new(0,4,8),o.Parent.Position)
   task.wait(.2)
   local before={distance=(root.Position-o.Parent.Position).Magnitude,enabled=o.Enabled}
   local input=game:GetService("UserInputService"):CreateVirtualInput()
   input:SendKey(true,o.KeyboardKeyCode,false)task.wait(math.max(.5,o.HoldDuration+.3))input:SendKey(false,o.KeyboardKeyCode,false)
   cam.CameraType=oldType return before
  elseif action=="ComfortUI"then
   task.wait(.2)local gui=player.PlayerGui.FlyHighHUD local b=gui:FindFirstChild("PullCrewButton",true)
   local pos=b.AbsolutePosition local size=b.AbsoluteSize local viewport=workspace.CurrentCamera.ViewportSize
   local overlap=false
   for _,name in {"JumpPanel","FlightActionsButton"}do local o=gui:FindFirstChild(name,true)if o and o.Visible then local p=o.AbsolutePosition local s=o.AbsoluteSize if pos.X<p.X+s.X and pos.X+size.X>p.X and pos.Y<p.Y+s.Y and pos.Y+size.Y>p.Y then overlap=true end end end
   return {parent=b.Parent.Name,visible=b.Visible,sizeX=size.X,sizeY=size.Y,inside=pos.X>=0 and pos.Y>=0 and pos.X+size.X<=viewport.X and pos.Y+size.Y<=viewport.Y,overlap=overlap,compact=gui:GetAttribute("CompactLayout"),viewport=tostring(viewport)}
  elseif action=="ClickRescue"then
   local b=player.PlayerGui.FlyHighHUD:FindFirstChild("PullCrewButton",true)assert(b.Visible)
   local center=b.AbsolutePosition+b.AbsoluteSize/2+game:GetService("GuiService"):GetGuiInset() local v=game:GetService("UserInputService"):CreateVirtualInput()
   v:SendMouseButton(center,Enum.UserInputType.MouseButton1,true)task.wait(.08)v:SendMouseButton(center,Enum.UserInputType.MouseButton1,false)task.wait(.2)return true
  elseif action=="RescueKey"then
   local v=game:GetService("UserInputService"):CreateVirtualInput()v:SendKey(true,Enum.KeyCode.B,false)task.wait(.08)v:SendKey(false,Enum.KeyCode.B,false)task.wait(.2)return true
  elseif action=="AimShot"then
   local cam=workspace.CurrentCamera local run=game:GetService("RunService")local root=player.Character.HumanoidRootPart
   run:BindToRenderStep("CrewQAAim",Enum.RenderPriority.Camera.Value+2,function()cam.CameraType=Enum.CameraType.Scriptable cam.CFrame=CFrame.lookAt(root.Position+Vector3.new(0,2,0),data.target)end)
   task.wait(.3)local input=game:GetService("UserInputService"):CreateVirtualInput()input:SendKey(true,Enum.KeyCode.ButtonR2,false)task.wait(.3)input:SendKey(false,Enum.KeyCode.ButtonR2,false)task.wait(.2)
   run:UnbindFromRenderStep("CrewQAAim")cam.CameraType=Enum.CameraType.Custom return true
  elseif action=="Prompt"then return prompt(data.model,data.path,data.force)
  elseif action=="Action"then remotes.FlightActionEvent:FireServer(data.action,data.value)return true
  elseif action=="Tether"then remotes.TetherEvent:FireServer(data.action)return true
  elseif action=="Drop"then remotes.WeaponDropEvent:FireServer()return true
  elseif action=="Unequip"then player.Character.Humanoid:UnequipTools()return true
  elseif action=="Shoot"then remotes.WeaponFireEvent:FireServer(Vector3.new(999999,999999,999999),data.target)return true
  elseif action=="Repair"then
   remotes.RepairHoleEvent:FireServer("Begin",data.hole)task.wait(data.duration+.2)
   remotes.RepairHoleEvent:FireServer("Finish")return true
  elseif action=="Kit"then remotes.EmergencyKitEvent:FireServer()return true
  elseif action=="Drive"then
   local endTime=os.clock()+data.duration
   repeat remotes.PilotControlEvent:FireServer(Vector3.new(data.x,0,data.z or 0),data.gas==true)task.wait(.1)until os.clock()>=endTime
   remotes.PilotControlEvent:FireServer(Vector3.zero,false)return true
  elseif action=="Snapshot"then
   local b=mine()local foreign=data and data.foreign and workspace:FindFirstChild(data.foreign)
   local gui=player.PlayerGui:FindFirstChild("FlyHighHUD")
   local states={}for _,p in ipairs(Players:GetPlayers())do
    states[p.Name]={tool=p.Character and p.Character:FindFirstChildOfClass("Tool")~=nil,rope=p.Character and p.Character:FindFirstChild("SafetyRope",true)~=nil}
   end
   return {cameraMode=player.CameraMode.Name,own=b and b.Name,autoGas=b and b:GetAttribute("AutoGas"),autoButton=gui and gui:FindFirstChild("AutoGasButton",true).Visible,
    enemyHelm=foreign and foreign.HelmSeat.HelmPrompt.Enabled,enemyRack=foreign and foreign.WeaponRack2.PickupPrompt.Enabled,
    players=states,logs=logs}
  elseif action=="Leave"then
   local sts=game:GetService("StudioTestService")local can=sts:CanLeaveTest()
   if can then task.delay(.4,function()sts:LeaveTest()end)end return {canLeave=can}
  end
  error("unknown command "..action)
 end,debug.traceback)
 remote:FireServer("reply",token,ok,value)
end)
