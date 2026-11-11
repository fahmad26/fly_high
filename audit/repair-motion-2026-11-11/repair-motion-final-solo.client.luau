local STS=game:GetService("StudioTestService")if STS:GetTestArgs()~="RepairMotionQA"then return end
local p=game.Players.LocalPlayer local R=game.ReplicatedStorage.FlyHigh.Remotes
local qa=R:WaitForChild("RepairMotionQA")local goal
game:GetService("RunService"):BindToRenderStep("RepairMotionWalk",201,function()
 local c=p.Character local ref=p:FindFirstChild("FlightBalloon")local b=ref and ref.Value
 if goal and c and b and b.Parent then local v=b.PrimaryPart.CFrame:PointToWorldSpace(goal)-c.HumanoidRootPart.Position v=Vector3.new(v.X,0,v.Z)
 c.Humanoid:Move(v.Magnitude>.2 and v.Unit*math.min(1,v.Magnitude/2)or Vector3.zero,false)end
end)
qa.OnClientEvent:Connect(function(id,action,data)
 local ok,result=xpcall(function()
 local c=p.Character local ref=p:FindFirstChild("FlightBalloon")local b=ref and ref.Value
 if action=="Ready"then return p.PlayerGui:FindFirstChild("FlyHighHUD")~=nil
 elseif action=="Pose"then goal=nil c:PivotTo(b.PrimaryPart.CFrame*CFrame.new(data))c.HumanoidRootPart.AssemblyLinearVelocity=b.PrimaryPart.AssemblyLinearVelocity return true
 elseif action=="Follow"then goal=data return true
 elseif action=="Stop"then goal=nil c.Humanoid:Move(Vector3.zero,false)return true
 elseif action=="Tether"then R.TetherEvent:FireServer(data)return true
 elseif action=="Release"then R.FlightActionEvent:FireServer("ReleaseHelm")return true
 elseif action=="Jump"then local button=p.PlayerGui.FlyHighHUD:FindFirstChild("JumpPanel",true):FindFirstChild("JumpButton")
 local v=game:GetService("UserInputService"):CreateVirtualInput()
 local center=button.AbsolutePosition+button.AbsoluteSize/2+game:GetService("GuiService"):GetGuiInset()
 v:SendMouseButton(center,Enum.UserInputType.MouseButton1,true)task.wait(.1)v:SendMouseButton(center,Enum.UserInputType.MouseButton1,false)return true
 elseif action=="Space"then local v=game:GetService("UserInputService"):CreateVirtualInput()v:SendKey(true,Enum.KeyCode.Space,false)task.wait(.2)v:SendKey(false,Enum.KeyCode.Space,false)return true
 elseif action=="Patch"then local hole=b.HoleSlots.Hole1 local cam=workspace.CurrentCamera
 local d={began=0,triggered=0,ended=0}local connections={hole.PatchPrompt.PromptButtonHoldBegan:Connect(function()d.began+=1 d.beginAt=os.clock() end),hole.PatchPrompt.Triggered:Connect(function()d.triggered+=1 end),hole.PatchPrompt.PromptButtonHoldEnded:Connect(function()d.ended+=1 d.endAt=os.clock() d.keyDownAtEnd=game:GetService("UserInputService"):IsKeyDown(hole.PatchPrompt.KeyboardKeyCode) end)}
 local old=cam.CameraType cam.CameraType=Enum.CameraType.Scriptable
 cam.CFrame=CFrame.lookAt(c.HumanoidRootPart.Position+Vector3.new(0,3,7),hole.Position)
 local v=game:GetService("UserInputService"):CreateVirtualInput()task.wait(.35)
 game:GetService("RunService"):BindToRenderStep("RepairPromptCamera",202,function()cam.CFrame=CFrame.lookAt(c.HumanoidRootPart.Position+Vector3.new(0,3,7),hole.Position)cam.Focus=CFrame.new(hole.Position)end)
 v:SendKey(true,hole.PatchPrompt.KeyboardKeyCode,false)task.wait(math.max(6,hole.PatchPrompt.HoldDuration*2+.5))v:SendKey(false,hole.PatchPrompt.KeyboardKeyCode,false)
 game:GetService("RunService"):UnbindFromRenderStep("RepairPromptCamera")cam.CameraType=old for _,con in connections do con:Disconnect()end d.holdDuration=hole.PatchPrompt.HoldDuration d.bridgeReady=hole.PatchPrompt:GetAttribute("RepairInputBridgeReady") d.lastAction=hole.PatchPrompt:GetAttribute("RepairInputLastAction") d.presentationReady=b:GetAttribute("FleetPresentationReady") d.enabled=hole.PatchPrompt.Enabled d.style=hole.PatchPrompt.Style.Name d.service=game:GetService("ProximityPromptService").Enabled d.maxDistance=hole.PatchPrompt.MaxActivationDistance d.headDistance=(c.Head.Position-hole.Position).Magnitude d.distance=(c.HumanoidRootPart.Position-hole.Position).Magnitude return d
 elseif action=="Snapshot"then return {q=tostring(b.PrimaryPart.CFrame:PointToObjectSpace(c.HumanoidRootPart.Position)),jumpPower=c.Humanoid.JumpPower,enabled=c.Humanoid:GetStateEnabled(Enum.HumanoidStateType.Jumping),floor=c.Humanoid.FloorMaterial.Name,state=c.Humanoid:GetState().Name}end
 end,debug.traceback)
 qa:FireServer(id,ok,result)
end)
