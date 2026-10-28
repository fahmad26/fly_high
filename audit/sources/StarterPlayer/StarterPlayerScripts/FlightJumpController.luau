local Players=game:GetService("Players")local RS=game:GetService("ReplicatedStorage")
local Run=game:GetService("RunService")local Input=game:GetService("UserInputService")
local p=Players.LocalPlayer local C=require(RS:WaitForChild("FlyHigh"):WaitForChild("Modules"):WaitForChild("FlyHighConfig"))
local remotes=RS.FlyHigh.Remotes local jump=remotes:WaitForChild("FlightJumpEvent")
local challengeEvent=remotes:WaitForChild("LargeChallengeEvent")
local gui=p.PlayerGui:WaitForChild("FlyHighHUD")
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
button.BackgroundColor3=Color3.fromRGB(190,151,78)button.TextColor3=Color3.fromRGB(24,41,46)button.Text="LOMPAT\nSpace / A"
button.Font=Enum.Font.GothamBold button.TextSize=12 button.Parent=panel
local corner=Instance.new("UICorner")corner.CornerRadius=UDim.new(0,9)corner.Parent=button
local storm=frame("StormChallengePanel",UDim2.new(.5,-245,0,150),UDim2.fromOffset(490,82),Color3.fromRGB(31,57,76))
storm.AnchorPoint=Vector2.new(.5,0)storm.Position=UDim2.new(.5,0,0,75)
local title=label(storm,"Title",UDim2.fromOffset(8,5),UDim2.new(1,-16,0,25),17)
local detail=label(storm,"Detail",UDim2.fromOffset(10,31),UDim2.new(1,-20,0,44),13)
local active local hum local originalJump=true local lastEnabled
local holes=0 local hiddenStatus
remotes.FlightStateSyncEvent.OnClientEvent:Connect(function(data)holes=data.holes or 0 if data.isGameOver or data.isVictory then active=nil end end)
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
 if p:GetAttribute("FlightJumpAllowed")==true and hum then request()hum.Jump=true end
end)
challengeEvent.OnClientEvent:Connect(function(data)
 if data.kind=="Ended"then if active and active.id==data.id then active=nil end
 elseif data.kind=="Warning"then active=data end
end)
local elapsed=0
Run.Heartbeat:Connect(function(dt)
 elapsed+=dt if elapsed<.05 then return end elapsed=0
 local camera=workspace.CurrentCamera
 if camera then
  local small=camera.ViewportSize.X<600
  for f,scale in pairs({[panel]=small and .85 or 1,[storm]=math.clamp((camera.ViewportSize.X-24)/490,.55,1)})do
   local s=f:FindFirstChild("ResponsiveScale")or Instance.new("UIScale")s.Name="ResponsiveScale"
   s.Scale=scale s.Parent=f
  end
  hint.TextSize=small and 14 or 12 button.TextSize=small and 14 or 12 detail.TextSize=small and 16 or 13
 end
 local inFlight=p:GetAttribute("InFlight")==true and p:GetAttribute("FlightGhost")~=true
 local allowed=not inFlight or p:GetAttribute("FlightJumpAllowed")==true
 local enable=allowed and originalJump
 if hum and hum.Parent and lastEnabled~=enable then hum:SetStateEnabled(Enum.HumanoidStateType.Jumping,enable)lastEnabled=enable end
 if hum and not allowed then hum.Jump=false end
 panel.Visible=inFlight
 local remaining=math.max(0,(p:GetAttribute("FlightJumpReadyAt")or 0)-workspace:GetServerTimeNow())
 button.Active=allowed button.AutoButtonColor=allowed button.BackgroundTransparency=allowed and 0 or .6
 hint.Text=not allowed and (p:GetAttribute("FlightJumpReason")or "Tunggu gondola")or(remaining>0 and string.format("Efek turun siap\ndalam %.1f detik",remaining)or "LOMPAT BERSAMA\nTurunkan balon untuk menghindari badai")
 storm.Visible=inFlight and active~=nil
 if active then
  local now=workspace:GetServerTimeNow()
  if now>active.endsAt or not inFlight then active=nil storm.Visible=false
  else
   local ref=p:FindFirstChild("FlightBalloon")local balloon=ref and ref.Value local root=balloon and balloon.PrimaryPart
   local drop=root and math.max(0,root.Position.Y-active.safeRootY)or 0
   local safe=root and drop<=.1
   title.Text=(safe and "POSISI AMAN"or "↓ DINDING BADAI").." • "..holes.."/5 LUBANG"
   title.TextColor3=holes>=4 and Color3.fromRGB(255,150,134)or Color3.fromRGB(242,235,211)
   storm.BackgroundColor3=safe and Color3.fromRGB(31,98,77)or Color3.fromRGB(31,57,76)
   local countdown=math.max(0,active.warningEndsAt-now)
   detail.Text=(countdown>0 and string.format("Mulai menyapu dalam %.1f detik. ",countdown)or "Badai sedang menyapu koridor! ")..(safe and ((balloon and balloon:GetAttribute("AutoGas"))and "Pertahankan posisi: matikan GAS OTOMATIS [Z]."or "Pertahankan posisi di bawah awan.")or string.format("Turun lagi %d km. %s",math.ceil(drop/C.STUDS_PER_KM),allowed and ((balloon and balloon:GetAttribute("AutoGas"))and "Lompat; matikan GAS OTOMATIS [Z]."or "Lompat bersama!")or(p:GetAttribute("FlightJumpReason")or "Kembali ke gondola")))
  end
 end
 local status=gui:FindFirstChild("StatusFrame")
 if storm.Visible then
  if status then if hiddenStatus==nil then hiddenStatus=status.Visible end status.Visible=false end
  local alert=gui:FindFirstChild("AlertBanner")if alert then alert.Visible=false end
 elseif hiddenStatus~=nil then
  if status then status.Visible=hiddenStatus end hiddenStatus=nil
 end

end)
