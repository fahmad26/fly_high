local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

local remotes = ReplicatedStorage:WaitForChild("FlyHigh"):WaitForChild("Remotes")
local flightSyncEvent = remotes:WaitForChild("FlightStateSyncEvent")
local pilotControlEvent = remotes:WaitForChild("PilotControlEvent")
local flightActionEvent=remotes:WaitForChild("FlightActionEvent")
local ControlMath=require(ReplicatedStorage.FlyHigh.Modules.FlightControlMath)
local preparingBoarding={}
flightActionEvent.OnClientEvent:Connect(function(action,balloon,token)
 if action~="PrepareBoarding"or preparingBoarding[token]then return end
 preparingBoarding[token]=true
 task.spawn(function()
  if balloon and balloon.Parent and balloon:WaitForChild("BasketFloor",8)and balloon:WaitForChild("RootPart",8)and balloon:WaitForChild("TetherStation",8)then
   RunService.RenderStepped:Wait()RunService.RenderStepped:Wait()
   flightActionEvent:FireServer("BoardReady",token)
  end
  preparingBoarding[token]=nil
 end)
end)
local autoGas=false
local emergencyKitEvent = remotes:WaitForChild("EmergencyKitEvent")
local hazardAlertEvent = remotes:WaitForChild("HazardAlertEvent")
local tacticalPingEvent = remotes:WaitForChild("TacticalPingEvent")

-- 1. Create Flight ScreenGui
local screenGui = playerGui:FindFirstChild("FlyHighHUD")
if not screenGui then
	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "FlyHighHUD"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Parent = playerGui
end

-- Top Altimeter Frame
local altFrame = Instance.new("Frame")
altFrame.Name = "AltimeterFrame"
altFrame.Size = UDim2.new(0, 420, 0, 48)
altFrame.Position = UDim2.new(0.5, -210, 0, 15)
altFrame.BackgroundColor3 = Color3.fromRGB(20, 25, 35)
altFrame.BackgroundTransparency = 0.25
altFrame.BorderSizePixel = 0
altFrame.Parent = screenGui

local cornerAlt = Instance.new("UICorner")
cornerAlt.CornerRadius = UDim.new(0, 10)
cornerAlt.Parent = altFrame

local altLabel = Instance.new("TextLabel")
altLabel.Name = "AltLabel"
altLabel.Size = UDim2.new(1, -20, 0, 22)
altLabel.Position = UDim2.new(0, 10, 0, 4)
altLabel.BackgroundTransparency = 1
altLabel.Text = "Ketinggian: 0 km / 10.000 km (0.0%)"
altLabel.TextColor3 = Color3.fromRGB(240, 245, 255)
altLabel.Font = Enum.Font.FredokaOne
altLabel.TextSize = 16
altLabel.TextStrokeTransparency = 0.5
altLabel.Parent = altFrame

local barBg = Instance.new("Frame")
barBg.Name = "BarBg"
barBg.Size = UDim2.new(1, -150, 0, 10)
barBg.Position = UDim2.new(0, 10, 0, 28)
barBg.BackgroundColor3 = Color3.fromRGB(40, 45, 60)
barBg.BorderSizePixel = 0
barBg.Parent = altFrame

local barCorner = Instance.new("UICorner")
barCorner.CornerRadius = UDim.new(0, 5)
barCorner.Parent = barBg

local barFill = Instance.new("Frame")
barFill.Name = "BarFill"
barFill.Size = UDim2.new(0, 0, 1, 0)
barFill.BackgroundColor3 = Color3.fromRGB(0, 220, 180)
barFill.BorderSizePixel = 0
barFill.Parent = barBg

local fillCorner = Instance.new("UICorner")
fillCorner.CornerRadius = UDim.new(0, 5)
fillCorner.Parent = barFill

local speedLabel=Instance.new("TextLabel")
speedLabel.Name="VerticalSpeedLabel"
speedLabel.Position=UDim2.new(1,-132,0,26)speedLabel.Size=UDim2.fromOffset(122,16)
speedLabel.BackgroundTransparency=1 speedLabel.Font=Enum.Font.GothamBold speedLabel.TextSize=12
speedLabel.TextColor3=Color3.fromRGB(210,220,235)speedLabel.Text="DIAM 0.0 km/dtk"
speedLabel.Parent=altFrame

-- Left Hole Status Frame
local statusFrame = Instance.new("Frame")
statusFrame.Name = "StatusFrame"
statusFrame.Size = UDim2.new(0, 260, 0, 110)
statusFrame.Position = UDim2.new(0, 20, 0, 85)
statusFrame.BackgroundColor3 = Color3.fromRGB(20, 25, 35)
statusFrame.BackgroundTransparency = 0.3
statusFrame.BorderSizePixel = 0
statusFrame.Parent = screenGui

local cornerStatus = Instance.new("UICorner")
cornerStatus.CornerRadius = UDim.new(0, 10)
cornerStatus.Parent = statusFrame

local holeTitle = Instance.new("TextLabel")
holeTitle.Name = "HoleTitle"
holeTitle.Size = UDim2.new(1, -16, 0, 24)
holeTitle.Position = UDim2.new(0, 10, 0, 6)
holeTitle.BackgroundTransparency = 1
holeTitle.Text = "KONDISI BALON:"
holeTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
holeTitle.Font = Enum.Font.FredokaOne
holeTitle.TextSize = 15
holeTitle.TextXAlignment = Enum.TextXAlignment.Left
holeTitle.Parent = statusFrame

local holeIcons = Instance.new("TextLabel")
holeIcons.Name = "HoleIcons"
holeIcons.Size = UDim2.new(1, -16, 0, 26)
holeIcons.Position = UDim2.new(0, 10, 0, 30)
holeIcons.BackgroundTransparency = 1
holeIcons.Text = "💚 💚 💚 💚 💚 (0/5 Lubang)"
holeIcons.TextColor3 = Color3.fromRGB(100, 255, 120)
holeIcons.Font = Enum.Font.GothamBold
holeIcons.TextSize = 16
holeIcons.TextXAlignment = Enum.TextXAlignment.Left
holeIcons.Parent = statusFrame

local holePenalty = Instance.new("TextLabel")
holePenalty.Name = "HolePenalty"
holePenalty.Size = UDim2.new(1, -16, 0, 20)
holePenalty.Position = UDim2.new(0, 10, 0, 58)
holePenalty.BackgroundTransparency = 1
holePenalty.Text = "Status: Penerbangan Normal"
holePenalty.TextColor3 = Color3.fromRGB(180, 220, 255)
holePenalty.Font = Enum.Font.GothamMedium
holePenalty.TextSize = 13
holePenalty.TextXAlignment = Enum.TextXAlignment.Left
holePenalty.Parent = statusFrame

local invulnLabel = Instance.new("TextLabel")
invulnLabel.Name = "InvulnLabel"
invulnLabel.Size = UDim2.new(1, -16, 0, 20)
invulnLabel.Position = UDim2.new(0, 10, 0, 80)
invulnLabel.BackgroundTransparency = 1
invulnLabel.Text = ""
invulnLabel.TextColor3 = Color3.fromRGB(255, 220, 50)
invulnLabel.Font = Enum.Font.FredokaOne
invulnLabel.TextSize = 14
invulnLabel.TextXAlignment = Enum.TextXAlignment.Left
invulnLabel.Parent = statusFrame

-- Emergency Repair Button
local emBtn = Instance.new("TextButton")
emBtn.Name = "EmergencyKitButton"
emBtn.Size = UDim2.new(0, 260, 0, 44)
emBtn.Position = UDim2.new(0, 20, 0, 210)
emBtn.BackgroundColor3 = Color3.fromRGB(30, 110, 200)
emBtn.Text = "🛡️ Pakai Emergency Kit (1x/Game)"
emBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
emBtn.Font = Enum.Font.FredokaOne
emBtn.TextSize = 14
emBtn.BorderSizePixel = 0
emBtn.Parent = screenGui

local cornerEm = Instance.new("UICorner")
cornerEm.CornerRadius = UDim.new(0, 10)
cornerEm.Parent = emBtn

-- Large Gas / Naik Button (Right Center for Mobile & PC)
local gasBtn = Instance.new("TextButton")
gasBtn.Name = "GasButton"
gasBtn.Size = UDim2.new(0, 160, 0, 60)
gasBtn.Position = UDim2.new(1, -180, 1, -140)
gasBtn.BackgroundColor3 = Color3.fromRGB(240, 100, 30)
gasBtn.Text = "🔥 GAS / NAIK\n(Tahan)"
gasBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
gasBtn.Font = Enum.Font.FredokaOne
gasBtn.TextSize = 16
gasBtn.BorderSizePixel = 0
gasBtn.Visible = false
gasBtn.Parent = screenGui

local cornerGas = Instance.new("UICorner")
cornerGas.CornerRadius = UDim.new(0, 14)
cornerGas.Parent = gasBtn

-- Early Warning Alert Banner (3 Detik)
local alertBanner = Instance.new("Frame")
alertBanner.Name = "AlertBanner"
alertBanner.Size = UDim2.new(0, 520, 0, 65)
alertBanner.Position = UDim2.new(0.5, -260, 0, 75)
alertBanner.BackgroundColor3 = Color3.fromRGB(220, 40, 40)
alertBanner.BackgroundTransparency = 0.1
alertBanner.BorderSizePixel = 0
alertBanner.Visible = false
alertBanner.Parent = screenGui

local alertCorner = Instance.new("UICorner")
alertCorner.CornerRadius = UDim.new(0, 12)
alertCorner.Parent = alertBanner

local alertTitle = Instance.new("TextLabel")
alertTitle.Name = "AlertTitle"
alertTitle.Size = UDim2.new(1, 0, 0, 30)
alertTitle.Position = UDim2.new(0, 0, 0, 4)
alertTitle.BackgroundTransparency = 1
alertTitle.Text = "⚠️ PERINGATAN DARURAT: 3.0s ⚠️"
alertTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
alertTitle.Font = Enum.Font.FredokaOne
alertTitle.TextSize = 20
alertTitle.Parent = alertBanner

local alertDesc = Instance.new("TextLabel")
alertDesc.Name = "AlertDesc"
alertDesc.Size = UDim2.new(1, 0, 0, 24)
alertDesc.Position = UDim2.new(0, 0, 0, 32)
alertDesc.BackgroundTransparency = 1
alertDesc.Text = "ANGIN TOPAN MENDEKAT DARI SISI KIRI! SIAPKAN MANUVER!"
alertDesc.TextColor3 = Color3.fromRGB(255, 230, 100)
alertDesc.Font = Enum.Font.GothamBold
alertDesc.TextSize = 14
alertDesc.Parent = alertBanner

local function flightButton(name,text,offset,callback)
 local b=Instance.new("TextButton")b.Name=name b.Text=text b.Size=UDim2.fromOffset(160,48)
 b.Position=UDim2.new(1,-180,1,-offset)b.BackgroundColor3=Color3.fromRGB(35,65,85)
 b.TextColor3=Color3.new(1,1,1)b.Font=Enum.Font.GothamBold b.TextSize=13 b.TextWrapped=true b.Visible=false b.Parent=screenGui
 local corner=Instance.new("UICorner")corner.CornerRadius=UDim.new(0,10)corner.Parent=b
 b.Activated:Connect(callback)return b
end
local function canUseHelm()
 local ref=localPlayer:FindFirstChild("FlightBalloon")local b=ref and ref.Value
 local hum=localPlayer.Character and localPlayer.Character:FindFirstChildOfClass("Humanoid")
 local seat=b and b:FindFirstChild("HelmSeat")
 return localPlayer:GetAttribute("InFlight")==true and localPlayer:GetAttribute("FlightGhost")~=true and hum and hum.Health>0 and seat and hum.SeatPart==seat and seat.Occupant==hum
end
local function toggleAutoGas()
 if canUseHelm()then flightActionEvent:FireServer("AutoGas",not autoGas)end
end
local autoGasButton=flightButton("AutoGasButton","GAS OTOMATIS: OFF [Z]",200,toggleAutoGas)
local releaseHelmButton=flightButton("ReleaseHelmButton","LEPAS KEMUDI [H]",255,function()flightActionEvent:FireServer("ReleaseHelm")end)
local groundNotice=Instance.new("TextLabel")groundNotice.Name="GroundedCountdown"groundNotice.Size=UDim2.fromOffset(420,28)
groundNotice.Position=UDim2.new(.5,-210,0,65)groundNotice.BackgroundColor3=Color3.fromRGB(79,47,34)
groundNotice.TextColor3=Color3.fromRGB(255,225,164)groundNotice.TextSize=14 groundNotice.Font=Enum.Font.GothamBold
groundNotice.Visible=false groundNotice.Parent=screenGui

-- State tracking
local isGasHeld = false
local steerVector = Vector3.zero

-- Gas button inputs (Mouse + Touch support)
local function setGas(held)
	isGasHeld = held
	if held then
		gasBtn.BackgroundColor3 = Color3.fromRGB(255, 140, 40)
	else
		gasBtn.BackgroundColor3 = Color3.fromRGB(240, 100, 30)
	end
end

gasBtn.MouseButton1Down:Connect(function() setGas(true) end)
gasBtn.MouseButton1Up:Connect(function() setGas(false) end)
gasBtn.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch then
		setGas(true)
	end
end)
gasBtn.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch then
		setGas(false)
	end
end)

-- Emergency Button Trigger
emBtn.MouseButton1Click:Connect(function()
	emergencyKitEvent:FireServer()
end)

-- Server Flight State Listener
flightSyncEvent.OnClientEvent:Connect(function(data)
	autoGas=data.autoGas==true
	autoGasButton.Text=autoGas and "GAS OTOMATIS: ON [Z]" or "GAS OTOMATIS: OFF [Z]"
	autoGasButton.BackgroundColor3=autoGas and Color3.fromRGB(35,130,94)or Color3.fromRGB(35,65,85)
	groundNotice.Visible=data.groundedRemaining~=nil and not data.isGameOver and not data.isVictory
	groundNotice.Text=data.groundedRemaining and string.format("LEPAS LANDAS! Balon hancur dalam %d detik",math.ceil(data.groundedRemaining))or ""
	local altKm = data.altitudeKm or 0
	local holes = data.holes or 0
	local invuln = data.invulnTime or 0
	local isFreefalling = data.isFreefalling or false
	local usedKit = data.usedEmergencyKit or false

	if data.isVictory then
		holePenalty.Text = "🏆 Tiba di Istana Awan!"
	elseif data.isGameOver then
		holePenalty.Text = "GAME OVER"
	end
	-- Update Altimeter
	local pct = math.clamp(altKm / 10000, 0, 1)
	altLabel.Text = string.format("Ketinggian: %d km / 10.000 km (%.1f%%)", math.floor(altKm), pct * 100)
	barFill.Size = UDim2.new(pct, 0, 1, 0)
	local speed=data.verticalSpeedKmPerSec or 0
	if data.isGameOver or data.isVictory or math.abs(speed)<.05 then speed=0 end
	speedLabel.Text=speed>0 and string.format("NAIK +%.1f km/dtk",speed)or(speed<0 and string.format("TURUN %.1f km/dtk",speed)or "DIAM 0.0 km/dtk")
	speedLabel.TextColor3=speed>0 and Color3.fromRGB(120,255,185)or(speed<0 and Color3.fromRGB(255,175,115)or Color3.fromRGB(210,220,235))

	-- Update Hole Visuals
	local icons = ""
	for i = 1, 5 do
		if i <= holes then
			icons = icons .. "💔 "
		else
			icons = icons .. "💚 "
		end
	end
	holeIcons.Text = string.format("%s (%d/5 Lubang)", icons, holes)

	-- Hole penalty text
	if data.isGameOver then
		holePenalty.Text = "GAME OVER"
	elseif data.isVictory then
		holePenalty.Text = "🏆 Tiba di Istana Awan!"
	elseif holes == 0 then
		holePenalty.Text = "Status: Normal (Naik Optimal)"
		holePenalty.TextColor3 = Color3.fromRGB(150, 255, 150)
	elseif holes == 1 then
		holePenalty.Text = "Status: Naik Lambat"
		holePenalty.TextColor3 = Color3.fromRGB(255, 230, 100)
	elseif holes == 2 then
		holePenalty.Text = "Status: Tidak Bisa Naik (Hover / Turun 1.2x)"
		holePenalty.TextColor3 = Color3.fromRGB(255, 160, 80)
	elseif holes == 3 then
		holePenalty.Text = "Status: Bahaya (Turun 1.5x)"
		holePenalty.TextColor3 = Color3.fromRGB(255, 100, 60)
	elseif holes == 4 then
		holePenalty.Text = "Status: Kritis (Turun 2.5x)"
		holePenalty.TextColor3 = Color3.fromRGB(255, 60, 40)
	elseif holes == 5 then
		holePenalty.Text = "Status: ⚠️ TERJUN BEBAS! LAKUKAN CLUTCH SAVE!"
		holePenalty.TextColor3 = Color3.fromRGB(255, 20, 20)
	end

	-- Invulnerability label
	if invuln > 0 then
		invulnLabel.Text = string.format("🛡️ KEBAL SERANGAN: %.1fs", invuln)
		invulnLabel.Visible = true
	else
		invulnLabel.Visible = false
	end

	-- Emergency Button update
	if usedKit then
		emBtn.Text = "🛡️ Emergency Kit: Sudah Digunakan"
		emBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 90)
		emBtn.Active = false
	elseif (data.shieldTime or 0) > 0 then
		emBtn.Text = "🛡️ Shield Tim Sedang Aktif!"
		emBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 90)
		emBtn.Active = false
	elseif isFreefalling then
		emBtn.Text = "⚠️ CLUTCH SAVE! KLIK SEKARANG!"
		emBtn.BackgroundColor3 = Color3.fromRGB(255, 40, 40)
		emBtn.Active = true
	else
		local totalKits = localPlayer:GetAttribute("EmergencyKits") or 0
		emBtn.Text = string.format("🛡️ Emergency Kit (Miliki: %d) [GUNAKAN]", totalKits)
		emBtn.BackgroundColor3 = Color3.fromRGB(30, 110, 200)
		emBtn.Active = true
	end
end)

local alertVersion=0
hazardAlertEvent.OnClientEvent:Connect(function(data)
 if data.effect then return end
 alertVersion+=1 local version=alertVersion
 alertBanner.Visible=true
 alertDesc.Text=string.upper(data.hazardName or "BAHAYA").." DARI "..string.upper(data.direction or "DEPAN")
 local deadline=os.clock()+3
 task.spawn(function()
  while version==alertVersion and os.clock()<deadline do
   alertTitle.Text=string.format("⚠️ PERINGATAN: %.1fs ⚠️",math.max(0,deadline-os.clock()))
   alertBanner.BackgroundColor3=math.floor(os.clock()*6)%2==0 and Color3.fromRGB(255,40,40) or Color3.fromRGB(255,180,0)
   task.wait(0.1)
  end
  if version==alertVersion then alertBanner.Visible=false end
 end)
end)
UserInputService.InputEnded:Connect(function(input)
 if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch or input.KeyCode==Enum.KeyCode.ButtonR1 then setGas(false) end
end)
UserInputService.WindowFocusReleased:Connect(function() setGas(false) end)
UserInputService.InputBegan:Connect(function(input)
 if UserInputService:GetFocusedTextBox()then return end
 if input.KeyCode==Enum.KeyCode.ButtonR1 and gasBtn.Visible then setGas(true)
 elseif input.KeyCode==Enum.KeyCode.H or input.KeyCode==Enum.KeyCode.ButtonY then flightActionEvent:FireServer("ReleaseHelm")
 elseif input.KeyCode==Enum.KeyCode.Z or input.KeyCode==Enum.KeyCode.ButtonL1 then toggleAutoGas()end
end)
local controls
task.spawn(function()
 local pm=localPlayer.PlayerScripts:WaitForChild("PlayerModule",10)
 if pm then controls=require(pm):GetControls() end
end)
-- Pilot WASD and Gas Input Loop (Throttled & HelmSeat Only)
local wasSeated = false
local lastSentSteer = Vector3.zero
local lastSentGas = false
local lastSendTime = 0

RunService.RenderStepped:Connect(function()
	local char = localPlayer.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local seat = hum and hum.SeatPart
	local isSeatedInHelm = (seat ~= nil and seat.Name == "HelmSeat")
 releaseHelmButton.Visible=isSeatedInHelm
 autoGasButton.Visible=canUseHelm()==true

	if isSeatedInHelm then
		gasBtn.Visible = true

		local moveX = 0
		local moveZ = 0
		if (UserInputService:IsKeyDown(Enum.KeyCode.W) or UserInputService:IsKeyDown(Enum.KeyCode.Up)) then moveZ = moveZ - 1 end
		if (UserInputService:IsKeyDown(Enum.KeyCode.S) or UserInputService:IsKeyDown(Enum.KeyCode.Down)) then moveZ = moveZ + 1 end
		if (UserInputService:IsKeyDown(Enum.KeyCode.A) or UserInputService:IsKeyDown(Enum.KeyCode.Left)) then moveX = moveX - 1 end
		if (UserInputService:IsKeyDown(Enum.KeyCode.D) or UserInputService:IsKeyDown(Enum.KeyCode.Right)) then moveX = moveX + 1 end

		steerVector = Vector3.new(moveX, 0, moveZ)
		local lastInput=UserInputService:GetLastInputType()
		if controls and (lastInput==Enum.UserInputType.Touch or string.find(lastInput.Name,"Gamepad")) then steerVector = controls:GetMoveVector() end

		if UserInputService:GetFocusedTextBox()then steerVector=Vector3.zero end
		steerVector=ControlMath.CameraSteer(steerVector,workspace.CurrentCamera.CFrame)
		local now = os.clock()
		local stateChanged = (steerVector ~= lastSentSteer) or (isGasHeld ~= lastSentGas)
		if now - lastSendTime >= 0.1 then
			pilotControlEvent:FireServer(steerVector, isGasHeld)
			lastSentSteer = steerVector
			lastSentGas = isGasHeld
			lastSendTime = now
		end
		wasSeated = true
	else
		gasBtn.Visible = false
		isGasHeld = false
		if wasSeated then
			pilotControlEvent:FireServer(Vector3.zero, false)
			lastSentSteer = Vector3.zero
			lastSentGas = false
			wasSeated = false
		end
	end
end)

-- Persistent palace is streamed to clients so its local photo prompt is available.
task.spawn(function()
 local palace=workspace:WaitForChild("CloudPalace")
 local prompt=palace:WaitForChild("PhotoboothSpot"):WaitForChild("PhotoPrompt")
 local photoVersion=0
 prompt.Triggered:Connect(function(player)
  if player and player~=localPlayer then return end
  photoVersion+=1 local version=photoVersion
  screenGui.Enabled=false
  task.delay(8,function() if version==photoVersion then screenGui.Enabled=true end end)
 end)
end)
-- Shared layout keeps touch targets usable and accounts for the safe GUI area.
require(ReplicatedStorage.FlyHigh.Modules:WaitForChild("HUDLayout")).Start(screenGui, localPlayer)
