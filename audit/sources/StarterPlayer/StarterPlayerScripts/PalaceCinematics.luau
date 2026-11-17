-- Istana Awan cutscenes (CINE-01, design/features/palace-cutscenes/design.md).
-- Arrival (~8 s from docking), fallen-crew revival, and the portal descent through the five real zones (~6 s).
-- Client presentation only: the server owns the queue, positions and rewards. Not skippable; the
-- SETELAN switch (player attribute CutscenesEnabled, server-owned) turns the camera sequences off.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")
local fly = ReplicatedStorage:WaitForChild("FlyHigh")
local modules = fly:WaitForChild("Modules")
local AudioMixer = require(modules:WaitForChild("AudioMixer"))
local AdventureArt = require(modules:WaitForChild("HUDAdventureArt"))
local AdventureCatalog = require(modules:WaitForChild("HUDAdventureCatalog"))
local Config = require(modules:WaitForChild("FlyHighConfig"))
local SoundCatalog = require(modules:WaitForChild("ObstacleAudioCatalog"))
local Economy = require(modules:WaitForChild("DailyAndShopCatalog"))

AudioMixer.Bind(localPlayer)
local sfxGroup = AudioMixer.GetGroup("SFX")
local lowFx = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

local CAMERA_STEP = "FlyHighCinematicCamera"
local ARRIVAL_SECONDS = 8
local RETURN_SECONDS = 6
local SPARKLE = "rbxasset://textures/particles/sparkles_main.dds"
local SMOKE = "rbxasset://textures/particles/smoke_main.dds"

local function cutscenesOn()
	return localPlayer:GetAttribute("CutscenesEnabled") ~= false
end

local function ease(t)
	t = math.clamp(t, 0, 1)
	return t * t * (3 - 2 * t)
end

-- Sound ---------------------------------------------------------------------------------------
local function sound(asset, volume, pitch, parent, duration)
	local id = SoundCatalog.Assets[asset]
	if not id then return nil end
	local s = Instance.new("Sound")
	s.SoundId = id
	s.Volume = volume
	s.PlaybackSpeed = pitch or 1
	s.SoundGroup = sfxGroup
	if parent and (parent:IsA("BasePart") or parent:IsA("Attachment")) then
		s.RollOffMode = Enum.RollOffMode.InverseTapered
		s.RollOffMinDistance = 15
		s.RollOffMaxDistance = 260
	end
	s.Parent = parent or script
	s:Play()
	task.delay(duration or 6, function()
		if s.Parent then
			TweenService:Create(s, TweenInfo.new(0.4), { Volume = 0 }):Play()
			task.delay(0.45, function() s:Destroy() end)
		end
	end)
	return s
end

-- World effects (seen by every player) --------------------------------------------------------
local function pointAt(position, lifetime)
	local anchor = Instance.new("Attachment")
	anchor.Name = "CinematicFxPoint"
	anchor.WorldPosition = position
	anchor.Parent = workspace.Terrain
	task.delay(lifetime or 5, function() anchor:Destroy() end)
	return anchor
end

local function emitter(parent, props)
	local e = Instance.new("ParticleEmitter")
	e.Rate = 0
	e.Enabled = false
	for k, v in props do e[k] = v end
	e.Parent = parent
	return e
end

local function cloudPuff(position, scale)
	scale = scale or 1
	local anchor = pointAt(position, 4)
	local puff = emitter(anchor, {
		Texture = SMOKE,
		Color = ColorSequence.new(Color3.fromRGB(255, 252, 244), Color3.fromRGB(214, 230, 252)),
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(0.5, 0.45), NumberSequenceKeypoint.new(1, 1) }),
		Size = NumberSequence.new(2.2 * scale, 6 * scale),
		Lifetime = NumberRange.new(0.9, 1.6),
		Speed = NumberRange.new(4 * scale, 10 * scale),
		SpreadAngle = Vector2.new(180, 25),
		Acceleration = Vector3.new(0, 1.5, 0),
		RotSpeed = NumberRange.new(-40, 40),
		LightInfluence = 0.3,
	})
	puff:Emit(lowFx and 10 or 22)
	return anchor
end

local function petals(position)
	local anchor = pointAt(position + Vector3.new(0, 14, 0), 6)
	local fall = emitter(anchor, {
		Texture = SPARKLE,
		Color = ColorSequence.new(Color3.fromRGB(255, 196, 214), Color3.fromRGB(255, 236, 196)),
		Size = NumberSequence.new(0.45, 0.25),
		Transparency = NumberSequence.new(0.05, 1),
		Lifetime = NumberRange.new(2.5, 4),
		Speed = NumberRange.new(2, 6),
		SpreadAngle = Vector2.new(180, 180),
		Acceleration = Vector3.new(0, -3, 0),
		RotSpeed = NumberRange.new(-120, 120),
		LightEmission = 0.3,
	})
	fall:Emit(lowFx and 25 or 60)
end

local function dockCelebration(dock)
	local top = dock.Position + Vector3.new(0, dock.Size.Y / 2 + 1, 0)
	cloudPuff(top, 2.2)
	petals(top)
	sound("Pixies", 0.55, 1, pointAt(top, 7), 6)
end

local function fadeCharacter(character, from, to, seconds)
	if not character then return end
	local parts = {}
	for _, d in character:GetDescendants() do
		if d:IsA("BasePart") or d:IsA("Decal") then table.insert(parts, d) end
	end
	local start = os.clock()
	task.spawn(function()
		while true do
			local a = math.clamp((os.clock() - start) / seconds, 0, 1)
			for _, p in parts do
				if p.Parent then p.LocalTransparencyModifier = from + (to - from) * a end
			end
			if a >= 1 then break end
			RunService.RenderStepped:Wait()
		end
	end)
end

local function revivalEffect(character)
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then return end
	local base = root.Position - Vector3.new(0, 3, 0)
	local gold = Color3.fromRGB(255, 220, 140)
	-- Soft light pillar: a camera-facing beam that fades towards the sky, not a solid neon tube.
	local foot = pointAt(base, 5)
	local top = pointAt(base + Vector3.new(0, 34, 0), 5)
	-- Two untextured beams: a wide soft halo and a bright narrow core.
	local layers = {}
	for _, spec in {
		{ w0 = 10, w1 = 6, emission = 0.6, bottom = 0.72, middle = 0.8, color = ColorSequence.new(Color3.fromRGB(255, 226, 150), Color3.fromRGB(255, 196, 92)) },
		{ w0 = 3.2, w1 = 1.4, emission = 0.9, bottom = 0.25, middle = 0.5, color = ColorSequence.new(Color3.fromRGB(255, 244, 214), Color3.fromRGB(255, 214, 128)) },
	} do
		local beamPart = Instance.new("Beam")
		beamPart.Attachment0 = foot
		beamPart.Attachment1 = top
		beamPart.LightEmission = spec.emission
		beamPart.LightInfluence = 0
		beamPart.FaceCamera = true
		beamPart.Color = spec.color
		beamPart.Width0 = spec.w0
		beamPart.Width1 = spec.w1
		beamPart.Segments = 4
		beamPart.Transparency = NumberSequence.new(1)
		beamPart.Parent = foot
		table.insert(layers, { beam = beamPart, bottom = spec.bottom, middle = spec.middle })
	end
	local start = os.clock()
	task.spawn(function()
		while foot.Parent do
			local t = os.clock() - start
			-- Rise 0.25 s, hold through the landing shot, fade out by 4 s.
			local alpha = math.clamp(t / 0.25, 0, 1) * (1 - math.clamp((t - 3.0) / 1.0, 0, 1))
			for _, layer in layers do
				layer.beam.Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 1 - (1 - layer.bottom) * alpha),
					NumberSequenceKeypoint.new(0.55, 1 - (1 - layer.middle) * alpha),
					NumberSequenceKeypoint.new(1, 1),
				})
			end
			if t > 4.1 then
				for _, layer in layers do layer.beam:Destroy() end
				break
			end
			RunService.RenderStepped:Wait()
		end
	end)
	local light = Instance.new("PointLight")
	light.Color = gold
	light.Range = 18
	light.Brightness = 3
	light.Parent = foot
	TweenService:Create(light, TweenInfo.new(2.6, Enum.EasingStyle.Sine), { Brightness = 0 }):Play()
	-- Ground ring wave.
	local ring = Instance.new("Part")
	ring.Name = "RevivalRing"
	ring.Shape = Enum.PartType.Cylinder
	ring.Material = Enum.Material.Neon
	ring.Color = gold
	ring.Size = Vector3.new(0.2, 2, 2)
	ring.CFrame = CFrame.new(base + Vector3.new(0, 0.15, 0)) * CFrame.Angles(0, 0, math.pi / 2)
	ring.Transparency = 0.2
	ring.Anchored = true ring.CanCollide = false ring.CanTouch = false ring.CanQuery = false ring.CastShadow = false
	ring.Parent = workspace
	TweenService:Create(ring, TweenInfo.new(1.1, Enum.EasingStyle.Quad), { Size = Vector3.new(0.2, 16, 16), Transparency = 1 }):Play()
	task.delay(1.2, function() ring:Destroy() end)
	local anchor = pointAt(base + Vector3.new(0, 1, 0), 5)
	emitter(anchor, { -- motes rising along the pillar
		Texture = SPARKLE,
		Color = ColorSequence.new(Color3.fromRGB(255, 240, 190), gold),
		Size = NumberSequence.new(0.5, 0),
		Lifetime = NumberRange.new(1.4, 2.2),
		Speed = NumberRange.new(6, 12),
		SpreadAngle = Vector2.new(12, 12),
		EmissionDirection = Enum.NormalId.Top,
		LightEmission = 0.9,
	}):Emit(lowFx and 25 or 60)
	local sky = pointAt(base + Vector3.new(0, 16, 0), 6)
	emitter(sky, { -- feathers drifting down onto the revived crew member
		Texture = SPARKLE,
		Color = ColorSequence.new(Color3.fromRGB(255, 252, 244)),
		Size = NumberSequence.new(0.42, 0.28),
		Lifetime = NumberRange.new(3, 4.2),
		Speed = NumberRange.new(0.5, 1.5),
		SpreadAngle = Vector2.new(180, 180),
		Acceleration = Vector3.new(0, -2.6, 0),
		RotSpeed = NumberRange.new(-120, 120),
		Drag = 0.8,
	}):Emit(lowFx and 12 or 28)
	cloudPuff(base, 1.2)
	fadeCharacter(character, 1, 0, 1.2)
	sound("Pixies", 0.5, 1.15, anchor, 5)
end

local function portalFlash(portal)
	local flash = Instance.new("Part")
	flash.Shape = Enum.PartType.Ball
	flash.Material = Enum.Material.Neon
	flash.Color = Color3.fromRGB(196, 232, 255)
	flash.Size = Vector3.new(4, 4, 4)
	flash.CFrame = portal.CFrame
	flash.Transparency = 0.2
	flash.Anchored = true
	flash.CanCollide = false
	flash.CanTouch = false
	flash.CanQuery = false
	flash.CastShadow = false
	flash.Parent = workspace
	TweenService:Create(flash, TweenInfo.new(0.9, Enum.EasingStyle.Quad), { Size = Vector3.new(18, 18, 18), Transparency = 1 }):Play()
	task.delay(1, function() flash:Destroy() end)
	local anchor = pointAt(portal.Position, 4)
	sound("Swish", 0.7, 0.5, anchor, 2)
	sound("WindGust", 0.45, 1.4, anchor, 2)
end

-- Cinematic shell -----------------------------------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "FlyHighCinematic"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 60
gui.Enabled = false
gui.Parent = playerGui

local function bar(anchorY)
	local f = Instance.new("Frame")
	f.BackgroundColor3 = Color3.new(0, 0, 0)
	f.BorderSizePixel = 0
	f.AnchorPoint = Vector2.new(0, anchorY)
	f.Position = UDim2.fromScale(0, anchorY)
	f.Size = UDim2.fromScale(1, 0)
	f.Parent = gui
	return f
end
local topBar, bottomBar = bar(0), bar(1)
local BAR = lowFx and 0.07 or 0.1

local whiteout = Instance.new("Frame")
whiteout.Name = "Whiteout"
whiteout.BackgroundColor3 = Color3.fromRGB(250, 252, 255)
whiteout.BorderSizePixel = 0
whiteout.Size = UDim2.fromScale(1, 1)
whiteout.BackgroundTransparency = 1
whiteout.ZIndex = 10
whiteout.Parent = gui

local function label(parent, size, font, color)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Font = font or Enum.Font.FredokaOne
	l.TextColor3 = color or Color3.new(1, 1, 1)
	l.TextStrokeTransparency = 0.6
	l.TextScaled = true
	l.Size = size
	l.Parent = parent
	local limit = Instance.new("UITextSizeConstraint")
	limit.MaxTextSize = 44
	limit.Parent = l
	return l
end

local title = label(gui, UDim2.fromScale(0.8, 0.08))
title.Name = "CinematicTitle"
title.AnchorPoint = Vector2.new(0.5, 0.5)
title.Position = UDim2.fromScale(0.5, 0.2)
title.TextTransparency = 1
title.TextStrokeTransparency = 1

local card = Instance.new("Frame")
card.Name = "ArrivalCard"
card.AnchorPoint = Vector2.new(0.5, 1)
card.Position = UDim2.fromScale(0.5, 0.86)
card.Size = UDim2.fromScale(0.42, 0.2)
card.BackgroundColor3 = Color3.fromRGB(10, 30, 74)
card.BackgroundTransparency = 0.06
card.Visible = false
card.Parent = gui
Instance.new("UICorner", card).CornerRadius = UDim.new(0, 14)
local stroke = Instance.new("UIStroke", card)
stroke.Color = Color3.fromRGB(255, 214, 128)
stroke.Thickness = 2
local cardRatio = Instance.new("UIAspectRatioConstraint", card)
cardRatio.AspectRatio = 2.9
local cardTitle = label(card, UDim2.new(0.86, 0, 0.3, 0), Enum.Font.FredokaOne, Color3.fromRGB(255, 226, 150))
cardTitle.Position = UDim2.fromScale(0.07, 0.19)
local cardLine1 = label(card, UDim2.new(0.86, 0, 0.17, 0), Enum.Font.GothamBold)
cardLine1.Position = UDim2.fromScale(0.07, 0.5)
local cardLine2 = label(card, UDim2.new(0.86, 0, 0.17, 0), Enum.Font.GothamBold, Color3.fromRGB(190, 230, 255))
cardLine2.Position = UDim2.fromScale(0.07, 0.69)
for _, l in { cardTitle, cardLine1, cardLine2 } do l.ZIndex = 3 end
-- Same chrome as the HUD popups (Sky Adventure 9-slice frame + victory crest); plain frame if not loaded.
local cardCrest = Instance.new("ImageLabel")
cardCrest.Name = "CardCrest"
cardCrest.BackgroundTransparency = 1
cardCrest.ScaleType = Enum.ScaleType.Fit
cardCrest.AnchorPoint = Vector2.new(0.5, 0.5)
cardCrest.Position = UDim2.fromScale(0.5, 0.02)
cardCrest.Size = UDim2.fromScale(0.34, 0.42)
cardCrest.ZIndex = 4
cardCrest.Image = AdventureCatalog.crest_victory and AdventureCatalog.crest_victory[1] or ""
cardCrest.Parent = card
local function dressCard()
	local loaded, frame = AdventureArt.DrawSlice(card, "modal_frame_9slice", 1, Rect.new(88, 84, 232, 236), 0.32, "CardFrame")
	if frame then
		frame.Position = UDim2.fromOffset(-3, -2)
		frame.Size = UDim2.new(1, 6, 1, 7)
	end
	stroke.Enabled = not loaded
	card.BackgroundTransparency = loaded and 1 or 0.06
	cardCrest.Visible = true
end
task.defer(dressCard)
task.spawn(function()
	pcall(function() game:GetService("ContentProvider"):PreloadAsync({ cardCrest }) end)
end)

-- This place has no PlayerModule fork, so movement is held by zeroing the local humanoid's speed and jump.
local held = {}
local function holdMovement(on)
	local character = localPlayer.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if on then
		if humanoid and not held[humanoid] then
			held[humanoid] = { walk = humanoid.WalkSpeed, jump = humanoid.JumpPower, height = humanoid.JumpHeight }
			humanoid.WalkSpeed = 0
			humanoid.JumpPower = 0
			humanoid.JumpHeight = 0
		end
	else
		for h, saved in held do
			if h.Parent then
				h.WalkSpeed = saved.walk
				h.JumpPower = saved.jump
				h.JumpHeight = saved.height
			end
		end
		table.clear(held)
	end
end

local running = false
local hiddenGuis = {}
local currentShot

local function setBars(open, seconds)
	local h = open and BAR or 0
	TweenService:Create(topBar, TweenInfo.new(seconds or 0.5), { Size = UDim2.fromScale(1, h) }):Play()
	TweenService:Create(bottomBar, TweenInfo.new(seconds or 0.5), { Size = UDim2.fromScale(1, h) }):Play()
end

local function setWhite(alpha, seconds)
	TweenService:Create(whiteout, TweenInfo.new(seconds or 0.15), { BackgroundTransparency = 1 - alpha }):Play()
end

local function showTitle(text, seconds)
	title.Text = text
	TweenService:Create(title, TweenInfo.new(0.5), { TextTransparency = 0, TextStrokeTransparency = 0.5 }):Play()
	task.delay(seconds, function()
		TweenService:Create(title, TweenInfo.new(0.6), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
	end)
end

local function enterCinematic()
	running = true
	for _, g in playerGui:GetChildren() do
		if g:IsA("ScreenGui") and g ~= gui and g.Enabled then
			hiddenGuis[g] = true
			g.Enabled = false
		end
	end
	holdMovement(true)
	card.Visible = false
	whiteout.BackgroundTransparency = 1
	gui.Enabled = true
	setBars(true, 0.5)
	local camera = workspace.CurrentCamera
	RunService:BindToRenderStep(CAMERA_STEP, Enum.RenderPriority.Camera.Value + 2, function()
		for _, effect in game:GetService("Lighting"):GetChildren() do
			if effect:IsA("BlurEffect") and effect.Enabled then effect.Enabled = false end
		end
		if currentShot then
			local ok, cf = pcall(currentShot, os.clock())
			if ok and typeof(cf) == "CFrame" then
				camera.CameraType = Enum.CameraType.Scriptable
				camera.CFrame = cf
			end
		end
	end)
end

local function behindPlayer()
	local character = localPlayer.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then return nil end
	local look = root.CFrame.LookVector
	local flat = Vector3.new(look.X, 0, look.Z)
	flat = flat.Magnitude > 0.01 and flat.Unit or Vector3.new(0, 0, -1)
	local focus = root.Position + Vector3.new(0, 2, 0)
	return CFrame.lookAt(focus - flat * 13 + Vector3.new(0, 2, 0), focus)
end

local function exitCinematic(blend)
	local camera = workspace.CurrentCamera
	local final = behindPlayer()
	if blend and final and currentShot then
		local from = camera.CFrame
		local start = os.clock()
		currentShot = function(now)
			return from:Lerp(final, ease((now - start) / 0.8))
		end
		task.wait(0.8)
	end
	RunService:UnbindFromRenderStep(CAMERA_STEP)
	currentShot = nil
	local character = localPlayer.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then camera.CameraSubject = humanoid end
	camera.CameraType = Enum.CameraType.Custom
	if final then camera.CFrame = final end
	setBars(false, 0.4)
	setWhite(0, 0.2)
	card.Visible = false
	task.delay(0.45, function() if not running then gui.Enabled = false end end)
	for g in hiddenGuis do
		if g.Parent then g.Enabled = true end
	end
	table.clear(hiddenGuis)
	holdMovement(false)
	localPlayer:SetAttribute("CinematicAltitudeKm", nil)
	running = false
end

-- Run a sequence with a hard watchdog so the camera and controls always come back.
local function guarded(limit, body)
	if running then return end
	enterCinematic()
	local done = false
	task.delay(limit, function()
		if not done and running then
			warn("[PalaceCinematics] watchdog restored the camera")
			done = true
			exitCinematic(false)
		end
	end)
	local ok, err = pcall(body, function() return done end)
	if not ok then warn("[PalaceCinematics] " .. tostring(err)) end
	if not done then
		done = true
		exitCinematic(ok)
	end
end

-- 1. Arrival ----------------------------------------------------------------------------------
local inFlightSince
localPlayer:GetAttributeChangedSignal("InFlight"):Connect(function()
	if localPlayer:GetAttribute("InFlight") == true then inFlightSince = os.clock() end
end)

local function formatTime(seconds)
	seconds = math.max(0, math.floor(seconds))
	return string.format("%d:%02d", seconds // 60, seconds % 60)
end

local function runArrival()
	if not cutscenesOn() or running then return end
	local ref = localPlayer:FindFirstChild("FlightBalloon")
	local balloon = ref and ref.Value
	local palace = workspace:FindFirstChild("CloudPalace")
	local dock = palace and palace:FindFirstChild("CloudHavenDock")
	local keep = palace and palace:FindFirstChild("CastleKeep")
	if not (balloon and dock and keep) then return end
	local flightSeconds = inFlightSince and (os.clock() - inFlightSince) or nil
	local fallen = localPlayer:GetAttribute("FlightGhost") == true
	local staleArrival = localPlayer:GetAttribute("PalaceArrival") -- left over from an earlier visit
	local K, D = keep.Position, dock.Position
	local out = Vector3.new(D.X - K.X, 0, D.Z - K.Z).Unit
	local right = out:Cross(Vector3.yAxis).Unit

	guarded(75, function(isDone)
		local started = os.clock()
		local dockStart, landed, cardShown
		local function balloonPos()
			local pp = balloon.Parent and balloon.PrimaryPart
			return pp and pp.Position or D
		end
		local function shot(now)
			if not dockStart then
				local a = (now - started) * 0.12
				local pos = K + Vector3.new(math.cos(a), 0, math.sin(a)) * 170 + Vector3.new(0, 55, 0)
				return "queue", CFrame.lookAt(pos, K + Vector3.new(0, 20, 0))
			end
			local t = now - dockStart
			if not landed then
				if t < 2 then
					local pos = D + out * 95 + right * 35 + Vector3.new(0, 8 + t * 3, 0)
					return "establish", CFrame.lookAt(pos, K + Vector3.new(0, 34 - t * 6, 0))
				end
				local b = balloonPos()
				local a = math.rad(35 + (t - 2) * 12)
				local side = out * math.cos(a) + right * math.sin(a)
				return "balloon", CFrame.lookAt(b + side * 50 + Vector3.new(0, 12, 0), b + Vector3.new(0, 2, 0))
			end
			local arrival = localPlayer:GetAttribute("PalaceArrival")
			local focus = typeof(arrival) == "Vector3" and arrival or (D + Vector3.new(0, 5, 0))
			local tl = now - landed
			if fallen then
				-- Wider and higher first so the light pillar of the revival reads, then settle on the crew.
				local w = 1 - ease(tl / 2.4)
				local dist = 20 + 10 * w - tl * 1.0
				return "landed", CFrame.lookAt(focus - out * dist + right * 5 + Vector3.new(0, 4 + 5 * w + tl * 0.4, 0),
					focus - Vector3.new(0, 3.2 - 9 * w, 0))
			end
			-- From the keep side so the crew faces the camera; aim low so they sit above the card.
			return "landed", CFrame.lookAt(focus - out * (20 - tl * 1.2) + right * 5 + Vector3.new(0, 4 + tl * 0.4, 0), focus - Vector3.new(0, 3.2, 0))
		end
		-- Every change of shot is a short camera move from the previous framing instead of a hard cut.
		local lastPhase, lastCF, blendFrom, blendStart
		currentShot = function(now)
			local phase, cf = shot(now)
			if phase ~= lastPhase then
				if lastCF then blendFrom, blendStart = lastCF, now end
				lastPhase = phase
			end
			if blendFrom then
				local a = (now - blendStart) / 0.9
				if a >= 1 then blendFrom = nil else cf = blendFrom:Lerp(cf, ease(a)) end
			end
			lastCF = cf
			return cf
		end
		while not isDone() do
			local now = os.clock()
			local state = balloon.Parent and balloon:GetAttribute("ArrivalState")
			if not dockStart then
				if state == "Docking" or state == "Departing" then
					dockStart = now
					task.delay(1.2, function() if running then showTitle("ISTANA AWAN · 10.000 km", 2.6) end end)
				elseif now - started > 60 or not balloon.Parent then
					return
				end
			end
			local arrival = localPlayer:GetAttribute("PalaceArrival")
			if dockStart and not landed and (state == "Departing" or not balloon.Parent
				or (typeof(arrival) == "Vector3" and arrival ~= staleArrival)) then
				landed = now
				-- Celebrate once on the dock (revived crew after their fade-in).
				task.delay(fallen and 1.5 or 0.45, function()
					local humanoid = localPlayer.Character and localPlayer.Character:FindFirstChildOfClass("Humanoid")
					if running and humanoid and humanoid.Health > 0 then pcall(function() humanoid:PlayEmote("cheer") end) end
				end)
			end
			if landed and not cardShown and now - landed > 1.2 then
				cardShown = true
				local stats = localPlayer:FindFirstChild("leaderstats")
				local summits = stats and stats:FindFirstChild("Puncak")
				cardTitle.Text = "ISTANA AWAN TERCAPAI"
				cardLine1.Text = (summits and ("10.000 km · Puncak ke-" .. summits.Value) or "10.000 km")
					.. (flightSeconds and (" · " .. formatTime(flightSeconds)) or "")
				cardLine2.Text = fallen and "Kru bangkit — kamu ikut sampai!" or ("+" .. Economy.COINS.PALACE_ARRIVAL .. " koin")
				dressCard()
				card.Visible = true
			end
			if dockStart and now >= dockStart + ARRIVAL_SECONDS and landed and now >= landed + (fallen and 3.6 or 3) then return end
			if dockStart and now > dockStart + 16 then return end
			task.wait()
		end
	end)
end

localPlayer:GetAttributeChangedSignal("ArrivalPending"):Connect(function()
	if localPlayer:GetAttribute("ArrivalPending") == true then task.spawn(runArrival) end
end)

-- Every client: dock celebration when a winning balloon has unloaded its crew.
local function watchBalloon(model)
	if not model:IsA("Model") or not model.Name:match("^Balloon_") then return end
	model:GetAttributeChangedSignal("ArrivalState"):Connect(function()
		if model:GetAttribute("ArrivalState") ~= "Departing" then return end
		local palace = workspace:FindFirstChild("CloudPalace")
		local dock = palace and palace:FindFirstChild("CloudHavenDock")
		if dock then dockCelebration(dock) end
	end)
end
for _, child in workspace:GetChildren() do watchBalloon(child) end
workspace.ChildAdded:Connect(watchBalloon)

-- 2. Revival and portal effects on other players ------------------------------------------------
local function watchPlayer(player)
	player:GetAttributeChangedSignal("ArrivalRevived"):Connect(function()
		if player:GetAttribute("ArrivalRevived") ~= true then return end
		local character = player.Character
		if character then revivalEffect(character) end
	end)
	player:GetAttributeChangedSignal("ReturnSequence"):Connect(function()
		if player == localPlayer then return end
		local palace = workspace:FindFirstChild("CloudPalace")
		local portal = palace and palace:FindFirstChild("ReturnPortal")
		if portal then portalFlash(portal) end
	end)
	player:GetAttributeChangedSignal("ReturnLandedAt"):Connect(function()
		if player == localPlayer and cutscenesOn() then return end -- the local montage plays its own landing
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if root then
			cloudPuff(root.Position - Vector3.new(0, 2.5, 0), 1.3)
			sound("WindGust", 0.35, 1.5, pointAt(root.Position, 3), 1.5)
		end
	end)
end
for _, p in Players:GetPlayers() do watchPlayer(p) end
Players.PlayerAdded:Connect(watchPlayer)

-- 3. Portal descent through the five real zones ------------------------------------------------------
-- The camera falls down the flight column while BiomeLightingController keeps every biome's real scenery
-- built (CinematicAltitudeKm), so the player sees the same zones they climbed through, top to bottom.
local ZONE_LABELS = { "LANGIT CERAH", "AWAN MENDUNG", "PULAU SENJA", "LANGIT BINTANG", "GERBANG SURGAWI" }
local FALL_TOP_KM, FALL_BOTTOM_KM = 9850, 140
local FALL_SECONDS = 3.8
local COLUMN = Vector3.new(0, 0, -20)

local function kmToY(km)
	return Config.GROUND_Y + km * Config.STUDS_PER_KM
end

-- Each zone gets an equal share of the fall: quick through the boundaries, slower mid-zone so it reads.
local function fallKm(u)
	u = math.clamp(u, 0, 1)
	local step = Config.BIOME_STEP_KM
	local scaled = u * 5
	local index = math.min(math.floor(scaled), 4) -- 0 = Gateway ... 4 = Dawn
	local f = scaled - index
	local g = f + 0.6 * math.sin(2 * math.pi * f) / (2 * math.pi)
	local top = index == 0 and FALL_TOP_KM or (5 - index) * step
	local bottom = index == 4 and FALL_BOTTOM_KM or (4 - index) * step
	return top + (bottom - top) * g
end

local zoneLabel = label(gui, UDim2.fromScale(0.7, 0.07))
zoneLabel.Name = "ZoneLabel"
zoneLabel.AnchorPoint = Vector2.new(0.5, 0.5)
zoneLabel.Position = UDim2.fromScale(0.5, 0.82)
zoneLabel.TextTransparency = 1
zoneLabel.TextStrokeTransparency = 1
local zoneLabelVersion = 0
local function flashZone(index)
	zoneLabelVersion += 1
	local version = zoneLabelVersion
	zoneLabel.Text = "ZONA " .. index .. " · " .. ZONE_LABELS[index]
	TweenService:Create(zoneLabel, TweenInfo.new(0.12), { TextTransparency = 0, TextStrokeTransparency = 0.45 }):Play()
	task.delay(0.55, function()
		if version ~= zoneLabelVersion then return end
		TweenService:Create(zoneLabel, TweenInfo.new(0.2), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
	end)
end

local function runReturn()
	if not cutscenesOn() or running then return end
	local palace = workspace:FindFirstChild("CloudPalace")
	local portal = palace and palace:FindFirstChild("ReturnPortal")
	local camera = workspace.CurrentCamera
	if not portal then return end
	guarded(RETURN_SECONDS + 10, function(isDone)
		local started = os.clock()
		local fromCF = camera.CFrame
		local P = portal.Position
		local away = (fromCF.Position - P)
		away = Vector3.new(away.X, 0, away.Z)
		away = away.Magnitude > 0.1 and away.Unit or Vector3.new(0, 0, 1)
		local pullCF = CFrame.lookAt(P + away * 26 + Vector3.new(0, 10, 0), P)
		local character = localPlayer.Character
		fadeCharacter(character, 0, 1, 0.7)
		portalFlash(portal)
		local swirl = pointAt(P, 3)
		emitter(swirl, {
			Texture = SMOKE,
			Color = ColorSequence.new(Color3.fromRGB(230, 240, 255)),
			Transparency = NumberSequence.new(0.3, 1),
			Size = NumberSequence.new(3, 8),
			Lifetime = NumberRange.new(0.8, 1.2),
			Speed = NumberRange.new(6, 12),
			SpreadAngle = Vector2.new(180, 180),
			RotSpeed = NumberRange.new(200, 360),
		}):Emit(lowFx and 12 or 30)
		local fallStart, fallEndCF, landedAt
		local yaw0 = math.atan2(-away.X, -away.Z)
		local function fallShot(now)
			local u = math.clamp((now - fallStart) / FALL_SECONDS, 0, 1)
			local km = fallKm(u)
			local position = COLUMN + Vector3.new(0, kmToY(km), 0)
			local yaw = yaw0 + (now - fallStart) * 0.32
			-- Look out at the zone's islands; tip down over the last stretch to find the home island.
			local dive = ease((u - 0.82) / 0.18)
			local pitch = -0.28 - 0.75 * dive
			return CFrame.new(position) * CFrame.Angles(0, yaw, 0) * CFrame.Angles(pitch, 0, 0), km
		end
		currentShot = function(now)
			local t = now - started
			if not fallStart then
				return fromCF:Lerp(pullCF, ease(t / 0.7))
			end
			if not landedAt then
				return (fallShot(now))
			end
			local final = behindPlayer()
			if not final then return camera.CFrame end
			return fallEndCF:Lerp(final, ease((now - landedAt) / 1.4))
		end
		task.wait(0.7)
		setWhite(1, 0.15)
		task.wait(0.15)
		-- Behind the whiteout: switch every biome on (built one per frame) at the top of the column.
		localPlayer:SetAttribute("CinematicAltitudeKm", FALL_TOP_KM)
		local sceneRoot = workspace:FindFirstChild("ClientBiomeScenery")
		local buildDeadline = os.clock() + 1.2
		while sceneRoot and #sceneRoot:GetChildren() < 5 and os.clock() < buildDeadline and not isDone() do task.wait() end
		fallStart = os.clock()
		sound("WindGust", 0.6, 1.2, nil, FALL_SECONDS + 0.4)
		setWhite(0, 0.2)
		local zone = 0
		while os.clock() - fallStart < FALL_SECONDS and not isDone() do
			local _, km = fallShot(os.clock())
			localPlayer:SetAttribute("CinematicAltitudeKm", km)
			local index = math.clamp(math.floor(km / Config.BIOME_STEP_KM) + 1, 1, 5)
			if index ~= zone then
				if zone ~= 0 then sound("Swish", 0.45, 0.8, nil, 1) end
				zone = index
				flashZone(index)
				if index == 2 then -- storm flash
					task.delay(0.2, function() setWhite(0.5, 0.05) task.delay(0.08, function() setWhite(0, 0.12) end) end)
				end
			end
			task.wait()
		end
		fallEndCF = (fallShot(fallStart + FALL_SECONDS))
		-- The server moved us during the pull-back; only cover with white if it has not finished.
		local function hasLanded()
			local landed = localPlayer:GetAttribute("ReturnLandedAt")
			return typeof(landed) == "number" and landed >= (localPlayer:GetAttribute("ReturnSequence") or 0)
		end
		if not hasLanded() then
			setWhite(1, 0.15)
			local deadline = os.clock() + 3
			while not isDone() and os.clock() < deadline and not hasLanded() do task.wait(0.05) end
			setWhite(0, 0.35)
		end
		localPlayer:SetAttribute("CinematicAltitudeKm", nil)
		landedAt = os.clock()
		character = localPlayer.Character
		fadeCharacter(character, 1, 0, 0.6)
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if root then
			task.delay(0.7, function()
				cloudPuff(root.Position - Vector3.new(0, 2.5, 0), 1.3)
				sound("WindGust", 0.4, 1.5, nil, 1.5)
			end)
		end
		task.wait(1.5)
	end)
	localPlayer:SetAttribute("CinematicAltitudeKm", nil)
	local character = localPlayer.Character
	if character then fadeCharacter(character, 0, 0, 0.01) end
end

localPlayer:GetAttributeChangedSignal("ReturnSequence"):Connect(function()
	task.spawn(runReturn)
end)

-- A character that spawns mid-sequence (fallen crew revived at the dock) is held as well.
localPlayer.CharacterAdded:Connect(function(character)
	if running then
		character:WaitForChild("Humanoid", 5)
		holdMovement(true)
	end
end)

-- GUIs recreated on respawn (fallen crew revive mid-sequence) stay hidden until the sequence ends.
playerGui.ChildAdded:Connect(function(g)
	if running and g:IsA("ScreenGui") and g ~= gui and g.Enabled then
		hiddenGuis[g] = true
		g.Enabled = false
	end
end)