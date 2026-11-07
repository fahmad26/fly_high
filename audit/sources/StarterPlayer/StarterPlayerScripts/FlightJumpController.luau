local Players=game:GetService("Players")local RS=game:GetService("ReplicatedStorage")
local Run=game:GetService("RunService")local Input=game:GetService("UserInputService")
local p=Players.LocalPlayer local C=require(RS:WaitForChild("FlyHigh"):WaitForChild("Modules"):WaitForChild("FlyHighConfig"))
local remotes=RS.FlyHigh.Remotes local jump=remotes:WaitForChild("FlightJumpEvent")
local challengeEvent=remotes:WaitForChild("LargeChallengeEvent")
local gui=p.PlayerGui:WaitForChild("FlyHighHUD")
-- Hide only Roblox's jump button. Keep the native movement joystick enabled.
local nativeJumpConnections={}
local function hideNativeJump(object)
 if not object:IsA("GuiObject")or object.Name~="JumpButton"or not object:FindFirstAncestor("TouchGui")or nativeJumpConnections[object]then return end
 local function hide()if object.Visible then object.Visible=false end end
 nativeJumpConnections[object]=object:GetPropertyChangedSignal("Visible"):Connect(hide)
 object.Destroying:Once(function()local connection=nativeJumpConnections[object]if connection then connection:Disconnect()nativeJumpConnections[object]=nil end end)
 hide()
end
local nativeAdded=p.PlayerGui.DescendantAdded:Connect(hideNativeJump)
for _,object in p.PlayerGui:GetDescendants()do hideNativeJump(object)end
script.Destroying:Connect(function()nativeAdded:Disconnect()for _,connection in nativeJumpConnections do connection:Disconnect()end end)
local function frame(name,pos,size,color)
 local f=Instance.new("Frame")f.Name=name f.Position=pos f.Size=size f.BackgroundColor3=color f.BackgroundTransparency=.12 f.BorderSizePixel=0 f.Visible=false f.Parent=gui
 local corner=Instance.new("UICorner")corner.CornerRadius=UDim.new(0,12)corner.Parent=f return f
end
local function label(parent,name,pos,size,textSize)
 local l=Instance.new("TextLabel")l.Name=name l.Position=pos l.Size=size l.BackgroundTransparency=1 l.TextColor3=Color3.fromRGB(242,235,211)
 l.Font=Enum.Font.GothamBold l.TextSize=textSize l.TextWrapped=true l.Parent=parent return l
end
local panel=frame("JumpPanel",UDim2.new(0,20,0,265),UDim2.fromOffset(260,72),Color3.fromRGB(29,67,66))
local hint=label(panel,"JumpHint",UDim2.fromOffset(9,5),UDim2.fromOffset(158,60),12)
local button=Instance.new("TextButton")button.Name="JumpButton"button.Size=UDim2.fromOffset(82,56)button.Position=UDim2.fromOffset(171,8)
button.BackgroundColor3=Color3.fromRGB(190,151,78)button.TextColor3=Color3.fromRGB(24,41,46)button.Text="↑"
button.Font=Enum.Font.FredokaOne button.TextSize=34 button.BorderSizePixel=0 button.AutoButtonColor=false button.Parent=panel
local corner=Instance.new("UICorner")corner.CornerRadius=UDim.new(.5,0)corner.Parent=button
local outline=Instance.new("UIStroke")outline.Color=Color3.fromRGB(246,219,144)outline.Thickness=2 outline.Transparency=.25 outline.ApplyStrokeMode=Enum.ApplyStrokeMode.Border outline.Parent=button
local storm=frame("StormChallengePanel",UDim2.new(.5,-245,0,150),UDim2.fromOffset(490,82),Color3.fromRGB(31,57,76))
storm.AnchorPoint=Vector2.new(.5,0)storm.Position=UDim2.new(.5,0,0,75)
local title=label(storm,"Title",UDim2.fromOffset(8,5),UDim2.new(1,-16,0,25),17)
local detail=label(storm,"Detail",UDim2.fromOffset(10,31),UDim2.new(1,-20,0,44),13)
local active local hum local originalJump=true local lastEnabled
remotes.FlightStateSyncEvent.OnClientEvent:Connect(function(data) if data.isGameOver or data.isVictory then active=nil end end)
local function bind(char)
 hum=char:WaitForChild("Humanoid")originalJump=hum:GetStateEnabled(Enum.HumanoidStateType.Jumping)lastEnabled=nil active=nil
end
if p.Character then bind(p.Character)end p.CharacterAdded:Connect(bind)
local function request()
 if not hum or hum.Health<=0 then return end
 if p:GetAttribute("InFlight")and p:GetAttribute("FlightJumpAllowed")~=true then hum.Jump=false return end
 if p:GetAttribute("InFlight")then jump:FireServer("Request")end
end
Input.JumpRequest:Connect(request)
button.Activated:Connect(function()
 if (not p:GetAttribute("InFlight")or p:GetAttribute("FlightJumpAllowed")==true)and hum and hum.Health>0 and hum.FloorMaterial~=Enum.Material.Air and hum:GetStateEnabled(Enum.HumanoidStateType.Jumping) then
  request()
  -- TouchJump resets Humanoid.Jump each frame; enter the normal state immediately.
  hum.Jump=true hum:ChangeState(Enum.HumanoidStateType.Jumping)
 end
end)
challengeEvent.OnClientEvent:Connect(function(data)
 if data.kind=="Ended"then if active and active.id==data.id then active=nil end
 elseif data.kind=="Warning"then active=data end
end)
local elapsed=0
Run.Heartbeat:Connect(function(dt)
 elapsed+=dt if elapsed<.05 then return end elapsed=0
 local inFlight=p:GetAttribute("InFlight")==true and p:GetAttribute("FlightGhost")~=true
 local allowed=not inFlight or p:GetAttribute("FlightJumpAllowed")==true
 local enable=allowed and originalJump
 if hum and hum.Parent and lastEnabled~=enable then hum:SetStateEnabled(Enum.HumanoidStateType.Jumping,enable)lastEnabled=enable end
 if hum and not allowed then hum.Jump=false end
 panel.Visible=hum~=nil and hum.Health>0 and not(p:GetAttribute("InFlight")==true and p:GetAttribute("FlightGhost")==true)and not (hum and hum.SeatPart and hum.SeatPart.Name=="HelmSeat")
 local remaining=math.max(0,(p:GetAttribute("FlightJumpReadyAt")or 0)-workspace:GetServerTimeNow())
 button.Active=allowed
 hint.Text=not allowed and (p:GetAttribute("FlightJumpReason")or "Tunggu gondola")or(remaining>0 and string.format("Efek turun siap\ndalam %.1f detik",remaining)or "LOMPAT BERSAMA\nTurunkan balon untuk menghindari badai")
 storm.Visible=inFlight and active~=nil
 if active then
  local now=workspace:GetServerTimeNow()
  if now>active.endsAt or not inFlight then active=nil storm.Visible=false
  else
   local ref=p:FindFirstChild("FlightBalloon")local balloon=ref and ref.Value local root=balloon and balloon.PrimaryPart
   local drop=root and math.max(0,root.Position.Y-active.safeRootY)or 0
   local safe=root and drop<=.1
   local countdown=math.max(0,active.warningEndsAt-now)
   title.Text=countdown>0 and string.format("Dinding Badai · %.0f dtk",math.ceil(countdown)) or "Dinding Badai"
   storm.BackgroundColor3=safe and Color3.fromRGB(31,98,77)or Color3.fromRGB(31,57,76)
   local pilot=hum and balloon and hum.SeatPart==balloon:FindFirstChild("HelmSeat")
   local auto=balloon and balloon:GetAttribute("AutoGas")==true
   if not root then
    detail.Text="Posisi balon sedang dimuat"
   elseif pilot and auto then
    detail.Text="Matikan gas otomatis"
   elseif safe then
    detail.Text="Tetap di bawah awan"
   elseif pilot then
    detail.Text="Lepas gas agar balon turun"
   elseif allowed then
    detail.Text=string.format("Lompat bersama · turun %d km", math.ceil(drop/C.STUDS_PER_KM))
   else
    detail.Text=p:GetAttribute("FlightJumpReason") or "Kembali ke gondola"
   end
  end
 end
end)
