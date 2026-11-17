-- Temporary local test only. Never install in the production place.
local STS=game:GetService("StudioTestService")
local args=STS:GetTestArgs()
if type(args)~="table" or args.kind~="CoreGuiImpact" then return end
local Players=game:GetService("Players")
local Input=game:GetService("UserInputService")
local StarterGui=game:GetService("StarterGui")
local GuiService=game:GetService("GuiService")
local CoreGui=game:GetService("CoreGui")
local Log=game:GetService("LogService")
local p=Players.LocalPlayer
local remote=game:GetService("ReplicatedStorage"):WaitForChild("_QA_CoreImpact")
local errors={}
local seen={}
local function captureError(message)
 if not seen[message] then seen[message]=true table.insert(errors,message) end
end
for _,entry in Log:GetLogHistory() do if entry.messageType==Enum.MessageType.MessageError then captureError(entry.message) end end
Log.MessageOut:Connect(function(message,kind)if kind==Enum.MessageType.MessageError then captureError(message) end end)
local function query(callback)
 local ok,result=pcall(callback)
 return {ok=ok,value=if ok then result else tostring(result)}
end
local function visible(object)
 local current=object
 while current and current~=CoreGui do
  if current:IsA("GuiObject") and not current.Visible then return false end
  if current:IsA("LayerCollector") and not current.Enabled then return false end
  current=current.Parent
 end
 return true
end
local function snapshot()
 local native={}
 local access=query(function()
  for _,object in CoreGui:GetDescendants() do
   if object:IsA("ScreenGui") or object.Name=="PlayerListMaster" or object.Name=="SettingsShield" or object.Name=="TopBarApp" or object.Name=="PlayerList" then
    table.insert(native,{path=object:GetFullName(),class=object.ClassName,visible=visible(object)})
   end
  end
  return true
 end)
 local hud=p.PlayerGui:FindFirstChild("FlyHighHUD")
 return {creatorType=query(function()return game.CreatorType.Name end),creatorId=game.CreatorId,placeId=game.PlaceId,gameId=game.GameId,
 topbar=query(function()return StarterGui:GetCore("TopbarEnabled")end),menuOpen=GuiService.MenuIsOpen,nativeAccess=access,native=native,
 playerListEnabled=StarterGui:GetCoreGuiEnabled(Enum.CoreGuiType.PlayerList),backpackEnabled=StarterGui:GetCoreGuiEnabled(Enum.CoreGuiType.Backpack),
 viewport=tostring(workspace.CurrentCamera.ViewportSize),hud=hud~=nil and hud.Enabled,errors=table.clone(errors)}
end
task.spawn(function()
 local report={player=p.Name,userId=p.UserId,case=args.case,startedUTC=DateTime.now():ToIsoDate()}
 local ok,failure=xpcall(function()
  local character=p.Character or p.CharacterAdded:Wait()
  local root=character:WaitForChild("HumanoidRootPart",30)
  assert(root,"Missing character root")
  task.wait(12)
  report.before=snapshot()
  local input=Input:CreateVirtualInput()
  local before=root.Position
  report.moveInput=query(function()input:SendKey(true,Enum.KeyCode.W,false) task.wait(.35) input:SendKey(false,Enum.KeyCode.W,false)return true end)
  task.wait(.2)
  report.moveDistance=(root.Position-before).Magnitude
  local baseY=root.Position.Y
  report.jumpInput=query(function()input:SendKey(true,Enum.KeyCode.Space,false)task.wait(.1)input:SendKey(false,Enum.KeyCode.Space,false)return true end)
  task.wait(.25) report.jumpDeltaY=root.Position.Y-baseY
  task.wait(.8)
  if args.case=="game" then
   local button=p.PlayerGui:FindFirstChild("SettingsToggleButton",true)
   local modal=p.PlayerGui:FindFirstChild("WeaponSettingsModal",true)
   report.customSettings=query(function()
    assert(button and modal,"Custom settings not present")
    input:SendMouseButton(button.AbsolutePosition+button.AbsoluteSize/2+GuiService:GetGuiInset(),Enum.UserInputType.MouseButton1,true)
    input:SendMouseButton(button.AbsolutePosition+button.AbsoluteSize/2+GuiService:GetGuiInset(),Enum.UserInputType.MouseButton1,false)
    task.wait(.5)
    local opened=modal.Visible
    local close=modal:FindFirstChild("SettingsCloseButton",true)
    if close and close.Visible then
     local point=close.AbsolutePosition+close.AbsoluteSize/2+GuiService:GetGuiInset()
     input:SendMouseButton(point,Enum.UserInputType.MouseButton1,true) input:SendMouseButton(point,Enum.UserInputType.MouseButton1,false)
    end
    task.wait(.4)
    return {opened=opened,closed=not modal.Visible}
   end)
  end
  report.beforeTab=snapshot()
  report.tabInput=query(function()input:SendKey(true,Enum.KeyCode.Tab,false)input:SendKey(false,Enum.KeyCode.Tab,false)return true end)
  task.wait(.5) report.afterTab=snapshot()
  report.escapeInput=query(function()input:SendKey(true,Enum.KeyCode.Escape,false)input:SendKey(false,Enum.KeyCode.Escape,false)return true end)
  task.wait(.8) report.afterEscape=snapshot()
 end,debug.traceback)
 report.executionCompleted=ok report.failure=if ok then nil else failure
 report.finishedUTC=DateTime.now():ToIsoDate()
 local gui=Instance.new("ScreenGui")gui.Name="_QA_CoreLabel"gui.ResetOnSpawn=false gui.Parent=p.PlayerGui
 local label=Instance.new("TextLabel")label.Size=UDim2.fromOffset(500,24)label.Position=UDim2.new(0,10,1,-34)label.BackgroundTransparency=.3
 label.TextSize=14 label.TextColor3=Color3.new(1,1,1)label.Text=string.format("QA %s | %s | errors %d",p.Name,args.case,#errors)label.Parent=gui
 remote:FireServer(report)
end)
