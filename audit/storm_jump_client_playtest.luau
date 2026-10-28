if not game:GetService("RunService"):IsStudio()then return end
local p=game.Players.LocalPlayer local RS=game.ReplicatedStorage local r=RS.FlyHigh.Remotes
local qa=r:WaitForChild("StormQAEvent")local logs={}
game:GetService("LogService").MessageOut:Connect(function(m,k)if k==Enum.MessageType.MessageError or k==Enum.MessageType.MessageWarning then table.insert(logs,{message=m,kind=k.Name})end end)
qa.OnClientEvent:Connect(function(token,action,data)
 local ok,value=xpcall(function()
  if action=="Ping"then p.PlayerGui:WaitForChild("FlyHighHUD",20):WaitForChild("JumpPanel",20)return {name=p.Name,userId=p.UserId}
  elseif action=="Jump"then
   local input=game:GetService("UserInputService"):CreateVirtualInput()
   for i=1,(data.hops or 1)do input:SendKey(true,Enum.KeyCode.Space,false)task.wait(.25)input:SendKey(false,Enum.KeyCode.Space,false)task.wait(data.gap or 1.35)end return true
  elseif action=="Spam"then
   for i=1,100 do r.FlightJumpEvent:FireServer("Request",{drop=999999,otherUser=123})end
   r.FlightJumpEvent:FireServer({})r.FlightJumpEvent:FireServer(99)return true
  elseif action=="Action"then r.FlightActionEvent:FireServer(data.action,data.value)return true
  elseif action=="Tether"then r.TetherEvent:FireServer(data.action)return true
  elseif action=="Drop"then r.WeaponDropEvent:FireServer()return true
  elseif action=="Pickup"then
   local b=p.FlightBalloon.Value local prompt=b.WeaponRack1.PickupPrompt
   local cam=workspace.CurrentCamera local old=cam.CameraType
   cam.CameraType=Enum.CameraType.Scriptable cam.CFrame=CFrame.lookAt(p.Character.HumanoidRootPart.Position+Vector3.new(0,4,8),prompt.Parent.Position)
   task.wait(.2)local input=game:GetService("UserInputService"):CreateVirtualInput()
   input:SendKey(true,prompt.KeyboardKeyCode,false)task.wait(.5)input:SendKey(false,prompt.KeyboardKeyCode,false)cam.CameraType=old return true
  elseif action=="Snapshot"then
   local h=p.Character and p.Character:FindFirstChildOfClass("Humanoid")
   local g=p.PlayerGui:FindFirstChild("FlyHighHUD")
   return {allowed=p:GetAttribute("FlightJumpAllowed"),reason=p:GetAttribute("FlightJumpReason"),accepted=p:GetAttribute("FlightJumpCount"),
    jumpEnabled=h and h:GetStateEnabled(Enum.HumanoidStateType.Jumping),health=h and h.Health,
    stormVisible=g and g.StormChallengePanel.Visible,jumpVisible=g and g.JumpPanel.Visible,logs=logs}
  end
  error("Unknown QA action")
 end,debug.traceback)
 qa:FireServer(token,ok,value)
end)
