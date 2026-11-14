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
flightActionEvent.OnClientEvent:Connect(function(action,balloon,payload)
 if action=="ReleaseRejectedHelm"then
  local hum=localPlayer.Character and localPlayer.Character:FindFirstChildOfClass("Humanoid")
  task.spawn(function()
   -- The seat weld and the rejection remote may replicate in either order.
   for _=1,8 do
    if not hum or not hum.Parent or localPlayer:GetAttribute("CrewRole")=="Pilot"then break end
    hum.Sit=false hum:ChangeState(Enum.HumanoidStateType.GettingUp)
    task.wait(.1)
   end
  end)
  return
 end
 if action=="CompleteBoarding"then
  local char=localPlayer.Character
  local hum=char and char:FindFirstChildOfClass("Humanoid")
  local hrp=char and char:FindFirstChild("HumanoidRootPart")
  if hum then hum.Sit=false hum.PlatformStand=false hum:ChangeState(Enum.HumanoidStateType.GettingUp) end
  if hrp and typeof(payload)=="CFrame" then
   local floor=balloon and balloon:FindFirstChild("BasketFloor")
   local needsSnap=not floor
   if floor then
    local rel=floor.CFrame:PointToObjectSpace(hrp.Position)
    needsSnap=math.abs(rel.X)>floor.Size.X/2-1 or math.abs(rel.Z)>floor.Size.Z/2-1 or rel.Y<1.2 or rel.Y>8
   end
   if needsSnap then
    hrp.AssemblyLinearVelocity=Vector3.zero
    hrp.CFrame=payload
   end
  end
  return
 end
 if action~="PrepareBoarding"or preparingBoarding[payload]then return end
 preparingBoarding[payload]=true
 task.spawn(function()
  local hum=localPlayer.Character and localPlayer.Character:FindFirstChildOfClass("Humanoid")
  if hum then hum.Sit=false hum.PlatformStand=false end
  if balloon and balloon.Parent and balloon:WaitForChild("BasketFloor",8)and balloon:WaitForChild("RootPart",8)and balloon:WaitForChild("TetherStation",8)then
   RunService.RenderStepped:Wait()RunService.RenderStepped:Wait()
   flightActionEvent:FireServer("BoardReady",payload)
  end
  preparingBoarding[payload]=nil
 end)
end)
local autoGas=false
local emergencyKitEvent = remotes:WaitForChild("EmergencyKitEvent")
local hazardAlertEvent = remotes:WaitForChild("HazardAlertEvent")
local tacticalPingEvent = remotes:WaitForChild("TacticalPingEvent")
local useBuffEvent = remotes:WaitForChild("UseBuffEvent", 10)
local coinToastEvent = remotes:WaitForChild("CoinToastEvent", 10)

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
speedLabel.TextColor3=Color3.fromRGB(147,197,253)speedLabel.Text="● 0.0 km/s"
speedLabel.Parent=altFrame

-- Left Hole Status Frame
local statusFrame = Instance.new("Frame")
statusFrame.Name = "StatusFrame"
statusFrame:SetAttribute("HoleCount", 0)
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
holeIcons.Text = "💚 💚 💚 💚 💚 (5/5 Kesehatan)"
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
invulnLabel.Visible = false
invulnLabel.Parent = statusFrame

-- Emergency Repair Button
local emBtn = Instance.new("TextButton")
emBtn.Name = "EmergencyKitButton"
emBtn.Size = UDim2.new(0, 260, 0, 44)
emBtn.Position = UDim2.new(0, 20, 0, 210)
emBtn.BackgroundColor3 = Color3.fromRGB(30, 110, 200)
emBtn.Text = "🛡️ Pakai Emergency Kit (1x/Game)"
emBtn.TextWrapped = true
emBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
emBtn.Font = Enum.Font.FredokaOne
emBtn.TextSize = 14
emBtn.BorderSizePixel = 0
emBtn.Parent = screenGui

local cornerEm = Instance.new("UICorner")
cornerEm.CornerRadius = UDim.new(0, 10)
cornerEm.Parent = emBtn

-- Turbo Gas & Tali Awet In-Flight Buff Dock Buttons
local turboBtn = Instance.new("TextButton")
turboBtn.Name = "TurboGasButton"
turboBtn.Size = UDim2.fromOffset(50, 58)
turboBtn.Position = UDim2.fromOffset(20, 265)
turboBtn.BackgroundColor3 = Color3.fromRGB(14, 165, 233)
turboBtn.Text = "TURBO"
turboBtn.TextColor3 = Color3.new(1, 1, 1)
turboBtn.Font = Enum.Font.FredokaOne
turboBtn.TextSize = 11
turboBtn.BorderSizePixel = 0
turboBtn.Visible = false
turboBtn.Parent = screenGui
local cornerTurbo = Instance.new("UICorner")
cornerTurbo.CornerRadius = UDim.new(0, 10)
cornerTurbo.Parent = turboBtn

local ropeBtn = Instance.new("TextButton")
ropeBtn.Name = "RopeBuffButton"
ropeBtn.Size = UDim2.fromOffset(50, 58)
ropeBtn.Position = UDim2.fromOffset(20, 330)
ropeBtn.BackgroundColor3 = Color3.fromRGB(245, 158, 11)
ropeBtn.Text = "TALI AWET"
ropeBtn.TextColor3 = Color3.new(1, 1, 1)
ropeBtn.Font = Enum.Font.FredokaOne
ropeBtn.TextSize = 11
ropeBtn.BorderSizePixel = 0
ropeBtn.Visible = false
ropeBtn.Parent = screenGui
local cornerRope = Instance.new("UICorner")
cornerRope.CornerRadius = UDim.new(0, 10)
cornerRope.Parent = ropeBtn

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
 return localPlayer:GetAttribute("InFlight")==true and localPlayer:GetAttribute("FlightGhost")~=true and hum and hum.Health>0 and seat and hum.SeatPart==seat
end
local function toggleAutoGas()
 if canUseHelm()then flightActionEvent:FireServer("AutoGas",not autoGas)end
end
local autoGasButton=flightButton("AutoGasButton","GAS OTOMATIS: OFF [Z]",200,toggleAutoGas)
local releaseHelmButton=flightButton("ReleaseHelmButton",UserInputService.TouchEnabled and "LEPAS KEMUDI"or "LEPAS KEMUDI [H]",255,function()flightActionEvent:FireServer("ReleaseHelm")end)
local groundNotice=Instance.new("TextLabel")groundNotice.Name="GroundedCountdown"groundNotice.Size=UDim2.fromOffset(420,28)
groundNotice.Position=UDim2.new(.5,-210,0,65)groundNotice.BackgroundColor3=Color3.fromRGB(79,47,34)
groundNotice.TextColor3=Color3.fromRGB(255,225,164)groundNotice.TextSize=14 groundNotice.Font=Enum.Font.GothamBold
groundNotice.Visible=false groundNotice.Parent=screenGui

-- Tactical Crew Ping & Ghost Spot HUD Banner
local crewPingBanner = Instance.new("Frame")
crewPingBanner.Name = "CrewPingBanner"
crewPingBanner.Size = UDim2.fromOffset(340, 54)
crewPingBanner.Position = UDim2.new(0.5, -170, 0, 145)
crewPingBanner.BackgroundColor3 = Color3.fromRGB(14, 34, 72)
crewPingBanner.BackgroundTransparency = 0.12
crewPingBanner.BorderSizePixel = 0
crewPingBanner.ZIndex = 16
crewPingBanner.Visible = false
crewPingBanner.Parent = screenGui

local pingCorner = Instance.new("UICorner")
pingCorner.CornerRadius = UDim.new(0.5, 0)
pingCorner.Parent = crewPingBanner

local pingStroke = Instance.new("UIStroke")
pingStroke.Name = "HUDFallbackStroke"
pingStroke.Color = Color3.fromRGB(255, 206, 94)
pingStroke.Thickness = 2
pingStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
pingStroke.Parent = crewPingBanner

local pingNonce = 0
tacticalPingEvent.OnClientEvent:Connect(function(_pos, message, name, kind, senderUserId)
 if localPlayer:GetAttribute("InFlight") ~= true then return end
 pingNonce += 1
 local isGhost = kind == "GhostSpot"
 local senderName = (type(name) == "string" and name ~= "") and name or (isGhost and "Arwah" or "Kru")
 local msgText = (type(message) == "string" and message ~= "") and message or "Bahaya terdeteksi oleh arwah!"
 local expiresAt = os.clock() + (isGhost and 3.8 or 4.0)
 crewPingBanner:SetAttribute("PingKind", isGhost and "ghost" or "quick")
 crewPingBanner:SetAttribute("PingSender", senderName)
 crewPingBanner:SetAttribute("PingMessage", msgText)
 crewPingBanner:SetAttribute("PingExpiresAt", expiresAt)
 crewPingBanner:SetAttribute("PingFromSelf", senderUserId == localPlayer.UserId)
 crewPingBanner:SetAttribute("HUDMotionClosing", false)
 crewPingBanner:SetAttribute("PingSeq", pingNonce)
 crewPingBanner.Visible = true
 screenGui:SetAttribute("HUDMotionPingCue", (isGhost and "ghost:" or "quick:") .. tostring(pingNonce))
end)

-- State tracking
local isGasHeld = false
local gasInput
local gamepadGas=false
local function isPointer(input)
 return input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1
end

-- Gas button inputs (Mouse + Touch support)
local function setGas(held)
	isGasHeld = held
	if held then
		gasBtn.BackgroundColor3 = Color3.fromRGB(255, 140, 40)
	else
		gasBtn.BackgroundColor3 = Color3.fromRGB(240, 100, 30)
	end
end

gasBtn.InputBegan:Connect(function(input)
 if not gasInput and isPointer(input) then
  gasInput=input
  setGas(true)
 end
end)

-- Emergency Button Trigger
emBtn.MouseButton1Click:Connect(function()
	if emBtn.Active and localPlayer:GetAttribute("InFlight") == true then
		emergencyKitEvent:FireServer()
	end
end)

local kitBlocked
local flightFinished = false
local function updateKit()
	local kits = localPlayer:GetAttribute("EmergencyKits")
	local inFlight = localPlayer:GetAttribute("InFlight") == true
	local reason = kitBlocked
	if kits == nil or not screenGui:GetAttribute("FlightHUDReady") then
		reason = "Memuat kit"
	elseif kits <= 0 then
		reason = "Kit habis"
	end
	emBtn:SetAttribute("HUDLockReason", reason)
	emBtn.Active = inFlight and localPlayer:GetAttribute("FlightGhost") ~= true and reason == nil
end
local function updateBuffButtons()
	local inFlight = localPlayer:GetAttribute("InFlight") == true
	local ready = screenGui:GetAttribute("FlightHUDReady") == true
	local ghost = localPlayer:GetAttribute("FlightGhost") == true
	local speedStock = tonumber(localPlayer:GetAttribute("SpeedBoostStock")) or 0
	local ropeStock = tonumber(localPlayer:GetAttribute("RopeBuffStock")) or 0
	local turboRem = tonumber(localPlayer:GetAttribute("TurboRemaining")) or 0
	local usedTurbo = tonumber(localPlayer:GetAttribute("UsedTurboCount")) or 0
	local ropeActive = localPlayer:GetAttribute("RopeBuffActive") == true

	local turboAvail = inFlight and (speedStock > 0 or turboRem > 0 or usedTurbo > 0)
	turboBtn:SetAttribute("HUDAvailable", turboAvail)
	local tReason = nil
	if flightFinished then
		tReason = "Selesai"
	elseif not ready then
		tReason = "Memuat"
	elseif turboRem > 0 then
		tReason = string.format("%ds", math.ceil(turboRem))
	elseif usedTurbo >= 2 then
		tReason = "Maks 2×"
	elseif speedStock <= 0 then
		tReason = "Habis"
	end
	turboBtn:SetAttribute("HUDLockReason", tReason)
	turboBtn.Active = inFlight and not ghost and tReason == nil

	local ropeAvail = inFlight and (ropeStock > 0 or ropeActive)
	ropeBtn:SetAttribute("HUDAvailable", ropeAvail)
	local rReason = nil
	if flightFinished then
		rReason = "Selesai"
	elseif not ready then
		rReason = "Memuat"
	elseif ropeActive then
		rReason = "AKTIF"
	elseif ropeStock <= 0 then
		rReason = "Habis"
	end
	ropeBtn:SetAttribute("HUDLockReason", rReason)
	ropeBtn.Active = inFlight and not ghost and rReason == nil
end
turboBtn.Activated:Connect(function()
	if turboBtn.Active and localPlayer:GetAttribute("InFlight") == true and useBuffEvent then
		useBuffEvent:FireServer("turbo_gas")
	end
end)
ropeBtn.Activated:Connect(function()
	if ropeBtn.Active and localPlayer:GetAttribute("InFlight") == true and useBuffEvent then
		useBuffEvent:FireServer("tali_awet")
	end
end)
if useBuffEvent then
	useBuffEvent.OnClientEvent:Connect(function(ok, msg)
		if type(msg) == "string" and msg ~= "" then
			screenGui:SetAttribute("HUDMotionNotice", (ok and "⚡ " or "⚠ ") .. msg)
		end
	end)
end
if coinToastEvent then
	coinToastEvent.OnClientEvent:Connect(function(amount, reason)
		if type(amount) == "number" and amount > 0 then
			local detail = (type(reason) == "string" and reason ~= "") and (" · " .. reason) or ""
			screenGui:SetAttribute("HUDMotionNotice", string.format("+%d Koin%s", math.floor(amount), detail))
		end
	end)
end
for _, attr in { "SpeedBoostStock", "RopeBuffStock", "TurboRemaining", "RopeBuffActive", "UsedTurboCount", "FlightGhost" } do
	localPlayer:GetAttributeChangedSignal(attr):Connect(updateBuffButtons)
end
localPlayer:GetAttributeChangedSignal("EmergencyKits"):Connect(updateKit)
localPlayer:GetAttributeChangedSignal("FlightGhost"):Connect(updateKit)
localPlayer:GetAttributeChangedSignal("InFlight"):Connect(function()
	if not localPlayer:GetAttribute("InFlight") then
		screenGui:SetAttribute("FlightHUDReady", false)
		screenGui:SetAttribute("HUDGroundedSeconds", nil)
		altFrame:SetAttribute("TurboRemaining", 0)
		altFrame:SetAttribute("TurboOwner", "")
		kitBlocked = nil
		flightFinished = false
	end
	updateKit()
	updateBuffButtons()
end)
updateKit()
updateBuffButtons()

local motionBiome: number? = nil
local motionVictory=false
localPlayer:GetAttributeChangedSignal("InFlight"):Connect(function()
 if not localPlayer:GetAttribute("InFlight") then motionBiome=nil motionVictory=false end
end)
-- Server Flight State Listener
flightSyncEvent.OnClientEvent:Connect(function(data)
	screenGui:SetAttribute("FlightHUDReady", not data.isGameOver and not data.isVictory)
	autoGas=data.autoGas==true
	autoGasButton.Text=(autoGas and "GAS OTOMATIS: ON"or "GAS OTOMATIS: OFF")..(UserInputService.TouchEnabled and ""or " [Z]")
	autoGasButton.BackgroundColor3=autoGas and Color3.fromRGB(35,130,94)or Color3.fromRGB(35,65,85)
	local groundedSeconds = not data.isGameOver and not data.isVictory and data.groundedRemaining
	screenGui:SetAttribute("HUDGroundedSeconds", groundedSeconds and math.ceil(groundedSeconds) or nil)
	local altKm = data.altitudeKm or 0
	local holes = math.clamp(math.floor(tonumber(data.holes) or 0), 0, 5)
	statusFrame:SetAttribute("HoleCount", holes)
	local invuln = data.invulnTime or 0
	local isFreefalling = data.isFreefalling or false
	local usedKit = data.usedEmergencyKit or false

	if data.isVictory then
		holePenalty.Text = "🏆 Tiba di Istana Awan!"
	elseif data.isGameOver then
		holePenalty.Text = "GAME OVER"
	end
	-- Update Altimeter
	local biome=math.min(4,math.floor(altKm/2000))
 if motionBiome~=nil and biome>motionBiome and not data.isVictory and not data.isGameOver then
  screenGui:SetAttribute("HUDMotionNotice","✦ Bioma baru · "..tostring(biome*2000).." km")
 end
 motionBiome=math.max(motionBiome or biome,biome)
 if data.isVictory and not motionVictory then
  motionVictory=true screenGui:SetAttribute("HUDMotionNotice","✦ Tiba di Istana Awan!")
 end
 local pct = math.clamp(altKm / 10000, 0, 1)
	altLabel.Text = string.format("Ketinggian: %d km / 10.000 km (%.1f%%)", math.floor(altKm), pct * 100)
	barFill.Size = UDim2.new(pct, 0, 1, 0)
	local speed=data.verticalSpeedKmPerSec or 0
	if data.isGameOver or data.isVictory or math.abs(speed)<.05 then speed=0 end
	altFrame:SetAttribute("VerticalSpeed", speed)
	speedLabel:SetAttribute("VerticalSpeed", speed)
	speedLabel.Text=speed>0 and string.format("▲ +%.1f km/s",speed)or(speed<0 and string.format("▼ -%.1f km/s",math.abs(speed))or "● 0.0 km/s")
	speedLabel.TextColor3=speed>0 and Color3.fromRGB(74,222,128)or(speed<0 and Color3.fromRGB(248,113,113)or Color3.fromRGB(147,197,253))

	-- Update Hole Visuals
	local icons = ""
	for i = 1, 5 do
		if i <= holes then
			icons = icons .. "💔 "
		else
			icons = icons .. "💚 "
		end
	end
	holeIcons.Text = string.format("%s (%d/5 Kesehatan)", icons, 5 - holes)

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
	flightFinished = data.isGameOver == true or data.isVictory == true
	local turboRem = math.ceil(math.max(0, tonumber(data.turboTime) or 0))
	altFrame:SetAttribute("TurboRemaining", turboRem)
	altFrame:SetAttribute("TurboOwner", type(data.turboOwner) == "string" and data.turboOwner or "")
	kitBlocked = (data.isGameOver or data.isVictory) and "Penerbangan selesai"
		or usedKit and "Kit terpakai"
		or (data.shieldTime or 0) > 0 and "Perisai aktif"
		or nil
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
		emBtn.Text = UserInputService.TouchEnabled and string.format("🛡️ EMERGENCY KIT · %d\nGUNAKAN",totalKits)or string.format("🛡️ Emergency Kit (Miliki: %d) [GUNAKAN]", totalKits)
		emBtn.BackgroundColor3 = Color3.fromRGB(30, 110, 200)
		emBtn.Active = true
	end
	updateKit()
	updateBuffButtons()
end)

local alertVersion=0
hazardAlertEvent.OnClientEvent:Connect(function(data)
 if data.effect then return end
 alertVersion+=1 local version=alertVersion
 alertDesc.Text=(data.hazardName or "Bahaya").." dari "..string.lower(data.direction or "depan")
 local duration=tonumber(data.duration) or 3
 local deadline=os.clock()+duration
 alertTitle.Text=string.format("Waspada · %.1f dtk",duration):gsub("%.",",")
 alertBanner:SetAttribute("HUDAlertActive",true)
 task.spawn(function()
  while version==alertVersion and os.clock()<deadline do
   alertTitle.Text=string.format("Waspada · %.1f dtk",math.max(0,deadline-os.clock())):gsub("%.",",")
   task.wait(0.1)
  end
  if version==alertVersion then alertBanner:SetAttribute("HUDAlertActive",false) end
 end)
end)
localPlayer:GetAttributeChangedSignal("InFlight"):Connect(function()
 if localPlayer:GetAttribute("InFlight") then return end
 alertVersion+=1
 alertBanner:SetAttribute("HUDAlertActive",false)
 crewPingBanner:SetAttribute("PingExpiresAt", 0)
 crewPingBanner:SetAttribute("HUDMotionClosing", false)
 crewPingBanner.Visible = false
end)
UserInputService.InputEnded:Connect(function(input)
 if gasInput==input or (gasInput and gasInput.UserInputType==Enum.UserInputType.MouseButton1
  and input.UserInputType==Enum.UserInputType.MouseButton1) then gasInput=nil end
 if input.KeyCode==Enum.KeyCode.ButtonR1 then gamepadGas=false end
 setGas(gasInput~=nil or gamepadGas)
end)
UserInputService.WindowFocusReleased:Connect(function()
 gasInput=nil gamepadGas=false
 setGas(false)
end)
UserInputService.InputBegan:Connect(function(input)
 if UserInputService:GetFocusedTextBox()then return end
 if input.KeyCode==Enum.KeyCode.ButtonR1 and gasBtn.Visible then gamepadGas=true setGas(true)
 elseif input.KeyCode==Enum.KeyCode.H or input.KeyCode==Enum.KeyCode.ButtonY then flightActionEvent:FireServer("ReleaseHelm")
 elseif input.KeyCode==Enum.KeyCode.Z or input.KeyCode==Enum.KeyCode.ButtonL1 then toggleAutoGas()end
end)
local controls
local nativeMoveAction
task.spawn(function()
 local pm = game:GetService("StarterPlayer"):FindFirstChild("PlayerModule")
  or localPlayer.PlayerScripts:WaitForChild("PlayerModule", 10)
 if not pm then return end
 local contexts = pm:FindFirstChild("InputContexts")
 if contexts then
  nativeMoveAction = contexts:WaitForChild("CharacterContext"):WaitForChild("MoveAction")
 else
  controls = require(pm):GetControls()
 end
end)
-- Pilot WASD and Gas Input Loop (Throttled & HelmSeat Only)
local wasSeated = false
local lastSendTime = 0

RunService.RenderStepped:Connect(function()
	local isSeatedInHelm = canUseHelm()==true
 releaseHelmButton.Visible=isSeatedInHelm
 autoGasButton.Visible=isSeatedInHelm
 local preferred=UserInputService.PreferredInput

	if isSeatedInHelm then
		gasBtn.Visible = true

		local moveX = 0
		local moveZ = 0
		if (UserInputService:IsKeyDown(Enum.KeyCode.W) or UserInputService:IsKeyDown(Enum.KeyCode.Up)) then moveZ = moveZ - 1 end
		if (UserInputService:IsKeyDown(Enum.KeyCode.S) or UserInputService:IsKeyDown(Enum.KeyCode.Down)) then moveZ = moveZ + 1 end
		if (UserInputService:IsKeyDown(Enum.KeyCode.A) or UserInputService:IsKeyDown(Enum.KeyCode.Left)) then moveX = moveX - 1 end
		if (UserInputService:IsKeyDown(Enum.KeyCode.D) or UserInputService:IsKeyDown(Enum.KeyCode.Right)) then moveX = moveX + 1 end

		local steerVector = Vector3.new(moveX, 0, moveZ)
		if controls and (preferred == Enum.PreferredInput.Touch or preferred == Enum.PreferredInput.Gamepad) then
			steerVector = controls:GetMoveVector()
		elseif nativeMoveAction and (preferred == Enum.PreferredInput.Touch or preferred == Enum.PreferredInput.Gamepad) then
			local move = nativeMoveAction:GetState()
			steerVector = Vector3.new(move.X, 0, -move.Y)
		end

		local scrim = screenGui:FindFirstChild("HUDModalScrim")
		if UserInputService:GetFocusedTextBox() or (scrim and scrim.Visible) then steerVector=Vector3.zero end
		steerVector=ControlMath.CameraSteer(steerVector,workspace.CurrentCamera.CFrame)
		local now = os.clock()
		if now - lastSendTime >= 0.1 then
			pilotControlEvent:FireServer(steerVector, isGasHeld)
			lastSendTime = now
		end
		wasSeated = true
	else
		gasBtn.Visible = false
		if wasSeated then
			gasInput=nil gamepadGas=false
			setGas(false)
			pilotControlEvent:FireServer(Vector3.zero, false)
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
-- Vertical all-flyers server altitude tracker & live flight sync
local trackerModule = require(ReplicatedStorage.FlyHigh.Modules:WaitForChild("HUDAltitudeTracker"))
local trackerFrame = Instance.new("Frame")
trackerFrame.Name = "ServerAltitudeTracker"
trackerFrame.BackgroundTransparency = 1
trackerFrame.BorderSizePixel = 0
trackerFrame.ClipsDescendants = false
trackerFrame.Visible = false
trackerFrame.ZIndex = 6
trackerFrame.Parent = screenGui

flightSyncEvent.OnClientEvent:Connect(function(data)
 if type(data) ~= "table" then return end
 if type(data.altitudeKm) == "number" then
  altFrame:SetAttribute("AltitudeKm", data.altitudeKm)
  trackerModule.SetLocalAltitude(data.altitudeKm)
 end
end)

local serverFlightsSyncEvent = remotes:FindFirstChild("ServerFlightsSyncEvent")
 if not serverFlightsSyncEvent then
  local conn
  conn = remotes.ChildAdded:Connect(function(child)
   if child.Name == "ServerFlightsSyncEvent" and child:IsA("RemoteEvent") then
    conn:Disconnect()
    child.OnClientEvent:Connect(function(snapshot)
     trackerModule.SetServerFlights(snapshot)
    end)
   end
  end)
 else
  serverFlightsSyncEvent.OnClientEvent:Connect(function(snapshot)
   trackerModule.SetServerFlights(snapshot)
  end)
 end

localPlayer:GetAttributeChangedSignal("InFlight"):Connect(function()
 if localPlayer:GetAttribute("InFlight") ~= true then
  altFrame:SetAttribute("AltitudeKm", nil)
  trackerModule.Reset()
 end
end)

-- Shared layout keeps touch targets usable and accounts for the safe GUI area.
require(ReplicatedStorage.FlyHigh.Modules:WaitForChild("HUDLayout")).Start(screenGui, localPlayer)
