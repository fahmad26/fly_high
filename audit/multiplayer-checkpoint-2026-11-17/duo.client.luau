-- Temporary test client; never save into the production place.
local STS=game:GetService("StudioTestService")
if STS:GetTestArgs()~="DuoCheckpointQA" then return end
local Players=game:GetService("Players")
local Run=game:GetService("RunService")
local Input=game:GetService("UserInputService")
local R=game:GetService("ReplicatedStorage").FlyHigh.Remotes
local p=Players.LocalPlayer
local qa=R:WaitForChild("_QA_Duo")
local shots,errors={},{}
game:GetService("LogService").MessageOut:Connect(function(m,k)
 if k==Enum.MessageType.MessageError then table.insert(errors,m) end
end)
R.WeaponFireEvent.OnClientEvent:Connect(function(who,origin,target,impact)
 table.insert(shots,{who=who.Name,origin=tostring(origin),target=tostring(target),kind=impact and impact.kind or "none"})
end)
local function snapshot()
 local ammo=p.PlayerGui:FindFirstChild("AmmoLabel",true)
 local tool=p.Character and p.Character:FindFirstChildOfClass("Tool")
 local reload=p.PlayerGui:FindFirstChild("ReloadButton",true)
 local gameErrors,platformErrors,crew={},{},{}
 for _,message in errors do
  if message:match("^%[Roblox%]%[CoreGui%.RobloxGui%.") or message:match("^%[Roblox%]%[Script Context%.StarterScript%]") then table.insert(platformErrors,message)
  else table.insert(gameErrors,message) end
 end
 for _,member in Players:GetPlayers() do crew[member.Name]={revived=member:GetAttribute("ArrivalRevived")==true,palace=member:GetAttribute("PalaceArrival")~=nil} end
 return {shots=table.clone(shots),errors=table.clone(errors),gameErrors=gameErrors,platformErrors=platformErrors,crew=crew,hotbar=game:GetService("StarterGui"):GetCoreGuiEnabled(Enum.CoreGuiType.Backpack),ammo=ammo and ammo.Text,weapon=tool and tool.Name,reloadVisible=reload and reload.Visible,palace=p:GetAttribute("PalaceArrival")~=nil,revived=p:GetAttribute("ArrivalRevived")==true,summits=p:GetAttribute("SummitCount")}
end
qa.OnClientEvent:Connect(function(id,action,data)
 local ok,result=xpcall(function()
  local character=p.Character
  local ref=p:FindFirstChild("FlightBalloon")
  local balloon=ref and ref.Value
  if action=="Ready" then return p.PlayerGui:FindFirstChild("FlyHighHUD")~=nil
  elseif action=="Pose" then
   character:PivotTo(balloon.PrimaryPart.CFrame*CFrame.new(data))
   character.HumanoidRootPart.AssemblyLinearVelocity=Vector3.zero
   return true
  elseif action=="Snapshot" then return snapshot()
  elseif action=="HoldPrompt" then
   local prompt=data.prompt
   local anchor=prompt.Parent
   local position=if anchor:IsA("Attachment") then anchor.WorldPosition else anchor.Position
   local camera=workspace.CurrentCamera
   local oldType=camera.CameraType
   camera.CameraType=Enum.CameraType.Scriptable
   Run:BindToRenderStep("_QA_DuoCamera",205,function()
    camera.CFrame=CFrame.lookAt(position+Vector3.new(0,3,9),position)
    camera.Focus=CFrame.new(position)
   end)
   local button
   local deadline=os.clock()+3
   repeat
    for _,gui in p.PlayerGui:GetChildren() do
     if gui.Name=="HUDInteractionPrompt" and gui:GetAttribute("PromptName")==prompt.Name then
      local candidate=gui:FindFirstChild("ActionTarget")
      if candidate and candidate.Visible then button=candidate break end
     end
    end
    if not button then task.wait(.05) end
   until button or os.clock()>deadline
   local report={customVisible=button~=nil,style=prompt.Style.Name,enabled=prompt.Enabled,distance=(character.HumanoidRootPart.Position-position).Magnitude}
   if button then
    report.width=button.AbsoluteSize.X report.height=button.AbsoluteSize.Y report.transparency=button.BackgroundTransparency
    local counts={began=0,ended=0,triggered=0,pointer=0,globalPointer=0}
    local connections={prompt.PromptButtonHoldBegan:Connect(function()counts.began+=1 end),prompt.PromptButtonHoldEnded:Connect(function()counts.ended+=1 end),prompt.Triggered:Connect(function()counts.triggered+=1 end),button.InputBegan:Connect(function(i)if i.UserInputType==Enum.UserInputType.MouseButton1 then counts.pointer+=1 end end)}
    table.insert(connections,Input.InputBegan:Connect(function(i)if i.UserInputType==Enum.UserInputType.MouseButton1 then counts.globalPointer+=1 end end))
    local input=Input:CreateVirtualInput()
    if data.pointer then
     local guiCenter=button.AbsolutePosition+button.AbsoluteSize/2
     local inset=game:GetService("GuiService"):GetGuiInset()
     local center=guiCenter+inset
     report.center=tostring(center) report.guiInset=tostring(inset) report.hits={}
     for _,hit in p.PlayerGui:GetGuiObjectsAtPosition(guiCenter.X,guiCenter.Y) do
      table.insert(report.hits,{path=hit:GetFullName(),class=hit.ClassName,active=hit.Active})
     end
     input:SendMouseButton(center,Enum.UserInputType.MouseButton1,true)
     task.wait(data.seconds)
     input:SendMouseButton(center,Enum.UserInputType.MouseButton1,false)
    else
     input:SendKey(true,prompt.KeyboardKeyCode,false)
     task.wait(data.seconds)
     input:SendKey(false,prompt.KeyboardKeyCode,false)
    end
    report.events=counts report.mouse=tostring(Input:GetMouseLocation())
    for _,connection in connections do connection:Disconnect() end
   end
   Run:UnbindFromRenderStep("_QA_DuoCamera") camera.CameraType=oldType
   return report
  elseif action=="Fire" then R.WeaponFireEvent:FireServer(Vector3.zero,data.target,data.model) return true
  elseif action=="Reload" then R.WeaponReloadEvent:FireServer() return true
  elseif action=="Drop" then R.WeaponDropEvent:FireServer() return true
  elseif action=="Tether" then R.TetherEvent:FireServer(data) return true
  end
  error("Unknown QA action: "..action)
 end,debug.traceback)
 qa:FireServer(id,ok,result)
end)
