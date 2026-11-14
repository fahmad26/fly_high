--!strict
-- Presentation & feel only: layout/input roots never move. No gameplay callbacks/remotes.
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Input = game:GetService("UserInputService")
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local SoundService = game:GetService("SoundService")
local ContentProvider = game:GetService("ContentProvider")
local HttpService = game:GetService("HttpService")

local Art = require(script.Parent.HUDAdventureArt)
local AudioMixer = require(script.Parent.AudioMixer)
local RopeWarnings = require(script.Parent.FlyHighConfig).AUDIO_WARNINGS

local Motion = {}
local sessions: {[ScreenGui]: any} = setmetatable({}, {__mode = "k"}) :: any

local modalNames = {
	ShopModal = true,
	DailyLoginModal = true,
	WeaponSettingsModal = true,
	TacticalPingWheel = true,
	AudioSettingsModal = true,
}

local panels = {
	AltimeterFrame = true,
	ShopModal = true,
	DailyLoginModal = true,
	WeaponSettingsModal = true,
	TacticalPingWheel = true,
	AudioSettingsModal = true,
	HUDModalScrim = true,
	Card1 = true,
	Card2 = true,
	AlertBanner = true,
	StormChallengePanel = true,
	GroundedCountdown = true,
	StatusFrame = true,
	WeaponFrame = true,
	TetherFrame = true,
	GhostSpotterFrame = true,
	CrewPingBanner = true,
	HUDMotionToast = true,
	HUDFlightResult = true,
}

local ctaButtons = {
	ShopToggleButton = true,
	DailyToggleButton = true,
	BuyEmergencyKitButton = true,
	BuyAK47Button = true,
	GasButton = true,
	EmergencyKitButton = true,
	TurboGasButton = true,
	RopeBuffButton = true,
}

local settingsStaggerOrder = {
	HandgunSlot1 = 1,
	AK47Slot1 = 2,
	HandgunSlot2 = 3,
	AK47Slot2 = 4,
	PlayerLabelsToggle = 5,
	ReduceMotionToggle = 6,
}

local pingStaggerOrder = {
	Ping1 = 1,
	Ping2 = 2,
	Ping3 = 3,
	Ping4 = 4,
	Ping5 = 5,
}

local function easeBackOut(t: number, overshoot: number?): number
	local c1 = overshoot or 1.70158
	local c3 = c1 + 1
	local x = math.clamp(t, 0, 1) - 1
	return 1 + c3 * x * x * x + c1 * x * x
end

local function easeOutCubic(t: number): number
	local x = 1 - math.clamp(t, 0, 1)
	return 1 - x * x * x
end

local function isModalDescendant(o: Instance, gui: ScreenGui): Instance?
	local cur: Instance? = o.Parent
	while cur and cur ~= gui do
		if modalNames[cur.Name] then
			return cur
		end
		cur = cur.Parent
	end
	return nil
end

-- A centered child owns visual motion; the original GuiButton owns input/layout.
function Motion.Visual(o: Instance): Instance
	if not o:IsA("GuiButton") or o.Name == "HUDModalScrim" then
		return o
	end
	local host = o:FindFirstChild("HUDMotionVisual")
	if not host then
		host = Instance.new("Frame")
		host.Name = "HUDMotionVisual"
		host.BackgroundTransparency = 1
		host.BorderSizePixel = 0
		host.Active = false
		host.AnchorPoint = Vector2.new(0.5, 0.5)
		host.Position = UDim2.fromScale(0.5, 0.5)
		host.Size = UDim2.fromScale(1, 1)
		local scale = Instance.new("UIScale")
		scale.Name = "HUDMotionScale"
		scale.Parent = host
		host.Parent = o
	end
	return host
end

function Motion.Start(gui: ScreenGui, player: Player): any
	if sessions[gui] then
		return sessions[gui]
	end
	local state: any = {
		records = {},
		base = {},
		links = {},
		dead = false,
	}
	local stepName = "FlyHighHUDMotion_" .. HttpService:GenerateGUID(false)
	sessions[gui] = state

	local function reduced(): boolean
		return player:GetAttribute("ReduceHUDMotion") == true
	end

	local function link(signal: any, callback: any)
		table.insert(state.links, signal:Connect(callback))
	end

	-- Soft throttled UI audio pool stored in SoundService so gui descendants remain deterministic.
	local audioFolder = Instance.new("Folder")
	audioFolder.Name = "FlyHighUIAudio_" .. HttpService:GenerateGUID(false):sub(1, 8)
	local audioGroup = Instance.new("SoundGroup")
	audioGroup.Name = "UIGroup"
	audioGroup.Volume = AudioMixer.GetSFXScale(player)
	audioGroup.Parent = audioFolder
	table.insert(state.links, AudioMixer.Observe(player, function()
		if audioGroup.Parent then
			audioGroup.Volume = AudioMixer.GetSFXScale(player)
		end
	end))
	local sfxDefs = {
		hover = { id = "rbxasset://sounds/clickfast.wav", vol = 0.045, pitch = 1.48 },
		click = { id = "rbxasset://sounds/switch.wav", vol = 0.11, pitch = 1.18 },
		open = { id = "rbxasset://sounds/button.wav", vol = 0.10, pitch = 1.24 },
		close = { id = "rbxasset://sounds/switch.wav", vol = 0.08, pitch = 0.84 },
		chime = { id = "rbxasset://sounds/electronicpingshort.wav", vol = 0.11, pitch = 1.38 },
		alert = { id = "rbxasset://sounds/electronicpingshort.wav", vol = 0.09, pitch = 0.92 },
		ping = { id = "rbxasset://sounds/electronicpingshort.wav", vol = 0.14, pitch = 1.56 },
		pingGhost = { id = "rbxasset://sounds/electronicpingshort.wav", vol = 0.16, pitch = 1.24 },
	}
	local sfxPool: {[string]: Sound} = {}
	local sfxPreload = {}
	for key, def in sfxDefs do
		local snd = Instance.new("Sound")
		snd.Name = key
		snd.SoundId = def.id
		snd.Volume = def.vol
		snd.PlaybackSpeed = def.pitch
		snd.SoundGroup = audioGroup
		snd.Parent = audioFolder
		sfxPool[key] = snd
		table.insert(sfxPreload, snd)
	end
	audioFolder.Parent = SoundService
	local sfxPreloadTask = task.spawn(function()
		pcall(ContentProvider.PreloadAsync, ContentProvider, sfxPreload)
	end)
	local lastSfxAt: {[string]: number} = {}
	local function playSfx(kind: string, pitchJitter: number?)
		if reduced() and kind ~= "click" then
			return
		end
		if (kind == "ping" or kind == "pingGhost") and AudioMixer.GetSFXScale(player) <= 0 then
			return
		end
		local now = os.clock()
		local minGap = kind == "hover" and 0.065 or 0.045
		if now - (lastSfxAt[kind] or 0) < minGap then
			return
		end
		local snd = sfxPool[kind]
		local def = sfxDefs[kind]
		if snd and def and snd.IsLoaded then
			lastSfxAt[kind] = now
			snd.Volume = def.vol
			snd.PlaybackSpeed = def.pitch + (pitchJitter or 0)
			snd.TimePosition = 0
			snd:Play()
		end
	end
	state.PlaySfx = playSfx

	-- Optional soft background blur when a modal is open.
	local modalBlur = Instance.new("BlurEffect")
	modalBlur.Name = "HUDMotionModalBlur_" .. HttpService:GenerateGUID(false):sub(1, 8)
	modalBlur.Size = 0
	modalBlur.Enabled = false
	modalBlur.Parent = Lighting
	local blurTween: Tween? = nil
	local function setBlur(targetSize: number, dur: number)
		if reduced() then
			targetSize = 0
		end
		if blurTween then
			blurTween:Cancel()
		end
		if targetSize > 0 then
			modalBlur.Enabled = true
		end
		blurTween = TweenService:Create(modalBlur, TweenInfo.new(dur, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = targetSize })
		if blurTween then
			blurTween:Play()
			if targetSize == 0 then
				task.delay(dur + 0.02, function()
					if not state.dead and modalBlur.Size < 0.1 then
						modalBlur.Enabled = false
					end
				end)
			end
		end
	end
	function state.SyncModalBlur(dur: number?)
		local anyOpen = false
		for o, r in state.records do
			if r.modal and o.Parent and o.Visible and gui.Enabled and o:GetAttribute("HUDMotionClosing") ~= true then
				anyOpen = true
				break
			end
		end
		if anyOpen ~= state.modalBlurActive then
			state.modalBlurActive = anyOpen
			setBlur(anyOpen and 8 or 0, dur or (anyOpen and 0.22 or 0.14))
		elseif not anyOpen and modalBlur.Enabled then
			setBlur(0, dur or 0.14)
		end
	end

	-- Pooled perimeter sparkle particles inside gui (fixed count, never allocated per click).
	local SPARK_COUNT = 10
	local sparkPool: {{ label: TextLabel, scale: UIScale, active: boolean, born: number, dur: number, sx: number, sy: number, vx: number, vy: number, rot0: number, rotVel: number }} = {}
	for i = 1, SPARK_COUNT do
		local star = Instance.new("TextLabel")
		star.Name = "HUDHoverStar" .. i
		star.Text = "✦"
		star.Font = Enum.Font.FredokaOne
		star.BackgroundTransparency = 1
		star.TextSize = i % 2 == 0 and 18 or 14
		star.Size = UDim2.fromOffset(22, 22)
		star.AnchorPoint = Vector2.new(0.5, 0.5)
		star.TextColor3 = i % 3 == 0 and Color3.fromRGB(255, 250, 205)
			or (i % 2 == 0 and Color3.fromRGB(255, 218, 98) or Color3.fromRGB(130, 240, 255))
		star.TextStrokeColor3 = Color3.fromRGB(12, 24, 48)
		star.TextStrokeTransparency = 0.35
		star.ZIndex = 45
		star.Active = false
		star.Visible = false
		local us = Instance.new("UIScale")
		us.Parent = star
		star.Parent = gui
		table.insert(sparkPool, {
			label = star,
			scale = us,
			active = false,
			born = 0,
			dur = 0.5,
			sx = 0,
			sy = 0,
			vx = 0,
			vy = 0,
			rot0 = 0,
			rotVel = 0,
		})
	end
	local sparkCursor = 1
	local function spawnPerimeterBurst(target: GuiObject, count: number, colorOverride: Color3?, speedScale: number?)
		if reduced() or not target.Parent or not target.Visible or not gui.Enabled then
			return
		end
		local pos = target.AbsolutePosition - gui.AbsolutePosition
		local sz = target.AbsoluteSize
		if sz.X < 4 or sz.Y < 4 then
			return
		end
		local guiSz = gui.AbsoluteSize
		local cx = pos.X + sz.X * 0.5
		local cy = pos.Y + sz.Y * 0.5
		local rx = sz.X * 0.52 + 4
		local ry = sz.Y * 0.52 + 4
		local spd = speedScale or 1
		local now = os.clock()
		local basePhase = (now * 3.7) % (math.pi * 2)
		for idx = 1, count do
			local slot = sparkPool[sparkCursor]
			sparkCursor = (sparkCursor % SPARK_COUNT) + 1
			local angle = basePhase + (idx - 1) * (math.pi * 2 / count) + (((idx % 3) - 1) * 0.14)
			local ca, sa = math.cos(angle), math.sin(angle)
			local rawX = cx + ca * rx
			local rawY = cy + sa * ry
			slot.sx = math.clamp(rawX, 12, math.max(12, guiSz.X - 12))
			slot.sy = math.clamp(rawY, 12, math.max(12, guiSz.Y - 12))
			local outSpd = (36 + (idx % 3) * 14) * spd
			local vx = ca * outSpd
			if cx < 72 and vx < 0 then
				vx = math.abs(vx) * 0.75 + 18
			elseif guiSz.X > 100 and cx > guiSz.X - 72 and vx > 0 then
				vx = -(math.abs(vx) * 0.75 + 18)
			end
			slot.vx = vx
			slot.vy = sa * outSpd - 22 * spd -- gentle upward buoyancy
			slot.born = now
			slot.dur = 0.50 + (idx % 3) * 0.08
			slot.rot0 = idx * 35
			slot.rotVel = (idx % 2 == 0 and 1 or -1) * 140
			slot.active = true
			if colorOverride then
				slot.label.TextColor3 = colorOverride
			else
				slot.label.TextColor3 = idx % 3 == 0 and Color3.fromRGB(255, 250, 205)
					or (idx % 2 == 0 and Color3.fromRGB(255, 218, 98) or Color3.fromRGB(130, 240, 255))
			end
			slot.label.Visible = true
		end
	end

	local function tween(r: any, scale: number, opacity: number, duration: number, style: Enum.EasingStyle?, dir: Enum.EasingDirection?)
		if r.tween then
			r.tween:Cancel()
		end
		if r.button and r.host then
			if r.poseTween then
				r.poseTween:Cancel()
			end
			local y = if reduced() then 0 elseif r.pressed then 2.5 elseif r.hover then -2.5 else 0
			r.poseTween = TweenService:Create(
				r.host,
				TweenInfo.new(duration, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
				{ Position = UDim2.new(0.5, 0, 0.5, y) }
			)
			if r.poseTween then
				r.poseTween:Play()
			end
		end
		local easing = style or (if r.button then Enum.EasingStyle.Sine else Enum.EasingStyle.Quad)
		local direction = dir or Enum.EasingDirection.Out
		r.tween = TweenService:Create(
			r.values,
			TweenInfo.new(duration, easing, direction),
			{ Value = if reduced() then 1 else scale }
		)
		if r.tween then
			r.tween:Play()
		end
		if r.fadeTween then
			r.fadeTween:Cancel()
		end
		r.fadeTween = TweenService:Create(r.fade, TweenInfo.new(math.max(0.05, duration * 0.85), Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Value = opacity })
		if r.fadeTween then
			r.fadeTween:Play()
		end
	end

	local function sweepSheen(r: any, duration: number?)
		if reduced() then
			return
		end
		local dur = duration or 0.48
		if r.hasSheenFace and r.gradient then
			if r.sheenTween then
				r.sheenTween:Cancel()
			end
			r.gradient.Offset = Vector2.new(-1, 0)
			r.sheenTween = TweenService:Create(r.gradient, TweenInfo.new(dur, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), { Offset = Vector2.new(1, 0) })
			if r.sheenTween then
				r.sheenTween:Play()
			end
		elseif r.hasWideSheen and r.wideGradient and r.wideMask then
			if r.sheenTween then
				r.sheenTween:Cancel()
			end
			r.sheenUntil = os.clock() + dur + 0.02
			r.wideMask.Visible = true
			r.wideGradient.Offset = Vector2.new(-1, 0)
			r.sheenTween = TweenService:Create(r.wideGradient, TweenInfo.new(dur, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), { Offset = Vector2.new(1, 0) })
			if r.sheenTween then
				r.sheenTween:Play()
			end
		end
	end

	local function neutral(r: any, force: boolean?)
		r.pressed = false
		r.input = nil
		if not force and os.clock() < (r.popUntil or 0) then
			return
		end
		tween(r, if r.hover and not reduced() then 1.08 else 1, 1, 0.22, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
	end

	local function eligible(o: GuiObject): boolean
		if not (o.Active and o.Interactable and o.Visible and gui.Enabled) then
			return false
		end
		local scrim = gui:FindFirstChild("HUDModalScrim")
		if scrim and scrim:IsA("GuiObject") and scrim.Visible then
			local a = o.Parent
			local inside = false
			while a and a ~= gui do
				if modalNames[a.Name] then
					inside = true
					break
				end
				a = a.Parent
			end
			if not inside then
				return false
			end
		end
		return true
	end

	local function hover(o: GuiObject, r: any, on: boolean)
		if r.hover == on then
			return
		end
		r.hover = on
		if not r.pressed and os.clock() >= (r.popUntil or 0) then
			tween(r, if on then 1.08 else 1, 1, 0.22, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
		end
		if on and not reduced() then
			spawnPerimeterBurst(o, 5, nil, 0.9)
			sweepSheen(r, 0.46)
			playSfx("hover")
		end
	end

	local function triggerButtonActivate(o: GuiObject, r: any)
		if not eligible(o) then
			return
		end
		local now = os.clock()
		r.pressed = false
		r.input = nil
		r.popUntil = now + 0.16
		r.rotPulseAt = now
		r.rotPulseDir = (o.Name == "CloseButton" or o.Name == "DailyCloseButton" or o.Name == "SettingsCloseButton" or o.Name == "AudioCloseButton" or o.Name == "PingCloseButton") and -4 or 2.6
		if not reduced() then
			r.values.Value = 0.90
			tween(r, if r.hover then 1.08 else 1.0, 1, 0.30, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
			spawnPerimeterBurst(o, 8, nil, 1.15)
			sweepSheen(r, 0.38)
		else
			tween(r, 1, 1, 0.08)
		end
		playSfx("click")
	end

	-- Auxiliary micro-scale attachments & Altimeter progress sheen (created once on bind).
	local auxScaleNames = {
		HUDGoalMarkerSlot = "HUDMarkerScale",
		HUDSpeedPill = "HUDSpeedPop",
		WeaponReticle = "HUDReticleScale",
		HUDWarningIcon = "HUDWarnScale",
	}
	local barFillInstance: GuiObject? = nil
	local barShimmer: Frame? = nil
	local barShimmerGrad: UIGradient? = nil
	local function ensureBarShimmer(fill: GuiObject)
		if barFillInstance == fill and barShimmer and barShimmer.Parent == fill then
			return
		end
		barFillInstance = fill
		fill.ClipsDescendants = true
		local existing = fill:FindFirstChild("HUDProgressSheen")
		if existing and existing:IsA("Frame") then
			barShimmer = existing
			barShimmerGrad = existing:FindFirstChildOfClass("UIGradient")
			return
		end
		local shimmer = Instance.new("Frame")
		shimmer.Name = "HUDProgressSheen"
		shimmer.BackgroundColor3 = Color3.new(1, 1, 1)
		shimmer.BackgroundTransparency = 0.35
		shimmer.BorderSizePixel = 0
		shimmer.Active = false
		shimmer.Size = UDim2.new(0.28, 24, 1, 0)
		shimmer.Position = UDim2.fromScale(-0.35, 0)
		shimmer.ZIndex = fill.ZIndex + 3
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 5)
		corner.Parent = shimmer
		local grad = Instance.new("UIGradient")
		grad.Rotation = 18
		grad.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.42, 0.25),
			NumberSequenceKeypoint.new(0.5, 0),
			NumberSequenceKeypoint.new(0.58, 0.25),
			NumberSequenceKeypoint.new(1, 1),
		})
		grad.Parent = shimmer
		shimmer.Parent = fill
		barShimmer = shimmer
		barShimmerGrad = grad
	end

	local function isDynamicOverlay(o: Instance): boolean
		return o.Name == "GhostSpotArrows"
			or o:FindFirstAncestor("GhostSpotArrows") ~= nil
			or o.Name == "ServerAltitudeTracker"
			or o:FindFirstAncestor("ServerAltitudeTracker") ~= nil
	end

	local function bind(o: Instance)
		if state.dead or isDynamicOverlay(o) then
			return
		end
		if o:IsA("GuiObject") then
			local scaleName = auxScaleNames[o.Name]
			if scaleName and not o:FindFirstChild(scaleName) then
				local sc = Instance.new("UIScale")
				sc.Name = scaleName
				sc.Parent = o
			elseif o.Name == "BarFill" then
				ensureBarShimmer(o)
			end
		end
		if not o:IsA("GuiObject") or state.records[o] then
			return
		end
		local isPip = o.Name:match("^HUDHull%d$") ~= nil
		local isButton = o:IsA("GuiButton") and o.Name ~= "HUDModalScrim"
		local isPanel = panels[o.Name] == true
		if not isButton and not isPanel and not isPip then
			return
		end

		local r: any = {
			button = isButton,
			modal = modalNames[o.Name] == true,
			isPip = isPip,
			isScrim = o.Name == "HUDModalScrim",
			visible = false,
			links = {},
			values = Instance.new("NumberValue"),
			fade = Instance.new("NumberValue"),
			offX = 0,
			offY = 0,
			shakeAmp = 0,
			shakeAge = 0,
			popAge = -1,
			popDur = 0.3,
			popAmp = 0,
			staggerWait = 0,
			sheenUntil = 0,
			nextIdleSheen = os.clock() + 3.2 + math.random() * 2.0,
		}
		r.values.Value = 1
		r.fade.Value = 1
		state.records[o] = r

		if isButton then
			r.host = Motion.Visual(o)
			r.visualScale = (r.host :: Instance):FindFirstChild("HUDMotionScale")

			-- 1. Single-sprite silhouette sheen
			local mask = Instance.new("ImageLabel")
			mask.Name = "HUDMotionSheen"
			mask.BackgroundTransparency = 1
			mask.BorderSizePixel = 0
			mask.Active = false
			mask.Selectable = false
			mask.ImageTransparency = 0.50
			mask.ImageColor3 = Color3.fromRGB(210, 245, 255)
			mask.Visible = false
			mask.Parent = r.host
			r.mask = mask

			local gradient = Instance.new("UIGradient")
			gradient.Rotation = -25
			gradient.Offset = Vector2.new(-1, 0)
			gradient.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(0.36, 1),
				NumberSequenceKeypoint.new(0.5, 0.02),
				NumberSequenceKeypoint.new(0.64, 1),
				NumberSequenceKeypoint.new(1, 1),
			})
			gradient.Parent = mask
			r.gradient = gradient

			-- 2. Three-segment wide button sheen (composited via CanvasGroup only during active sweep)
			local wideMask = Instance.new("CanvasGroup")
			wideMask.Name = "HUDMotionWideSheen"
			wideMask.BackgroundTransparency = 1
			wideMask.BorderSizePixel = 0
			wideMask.Active = false
			wideMask.Size = UDim2.fromScale(1, 1)
			wideMask.GroupTransparency = 0.48
			wideMask.Visible = false
			wideMask.Parent = r.host
			r.wideMask = wideMask

			local wideParts: {[string]: ImageLabel} = {}
			for _, segName in { "HUDArtLeft", "HUDArtMiddle", "HUDArtRight" } do
				local seg = Instance.new("ImageLabel")
				seg.Name = segName
				seg.BackgroundTransparency = 1
				seg.BorderSizePixel = 0
				seg.Active = false
				seg.ImageColor3 = Color3.fromRGB(220, 246, 255)
				seg.Parent = wideMask
				wideParts[segName] = seg
			end
			r.wideParts = wideParts

			local wideGrad = Instance.new("UIGradient")
			wideGrad.Rotation = -24
			wideGrad.Offset = Vector2.new(-1, 0)
			wideGrad.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(0.36, 1),
				NumberSequenceKeypoint.new(0.5, 0.04),
				NumberSequenceKeypoint.new(0.64, 1),
				NumberSequenceKeypoint.new(1, 1),
			})
			wideGrad.Parent = wideMask
			r.wideGradient = wideGrad

			local function linkBtn(signal: any, fn: any)
				table.insert(r.links, signal:Connect(fn))
			end
			local btn = o :: GuiButton
			linkBtn(btn.InputBegan, function(i: InputObject)
				if eligible(o) and (i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 or i.KeyCode == Enum.KeyCode.ButtonA) then
					r.pressed = true
					r.input = i
					tween(r, 0.89, 1, 0.065, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
				end
			end)
			linkBtn(btn.Activated, function()
				triggerButtonActivate(o, r)
			end)
			linkBtn(o.MouseEnter, function()
				if eligible(o) and Input.PreferredInput ~= Enum.PreferredInput.Touch then
					hover(o, r, true)
				end
			end)
			linkBtn(o.MouseLeave, function()
				hover(o, r, false)
				if not r.input or r.input.UserInputType ~= Enum.UserInputType.Touch then
					neutral(r)
				end
			end)
			linkBtn(o.SelectionGained, function()
				if eligible(o) then
					hover(o, r, true)
				end
			end)
			linkBtn(o.SelectionLost, function()
				hover(o, r, false)
				neutral(r)
			end)
		elseif not r.isScrim then
			local existing = o:FindFirstChild("HUDMotionPanelScale")
			local pScale = if existing and existing:IsA("UIScale") then existing else Instance.new("UIScale")
			pScale.Name = "HUDMotionPanelScale"
			pScale.Scale = 1
			pScale.Parent = o
			r.panelScale = pScale
		end
	end

	for _, o in gui:GetDescendants() do
		bind(o)
	end
	link(gui.DescendantAdded, bind)

	link(Input.InputEnded, function(i: InputObject)
		for _, r in state.records do
			if r.input == i then
				neutral(r)
			end
		end
	end)
	link(Input.WindowFocusReleased, function()
		for o, r in state.records do
			if r.button then
				hover(o, r, false)
			end
			r.hover = false
			neutral(r, true)
		end
	end)

	-- Toast sheen setup helper
	local toast = Instance.new("Frame")
	toast.Name = "HUDMotionToast"
	toast.BackgroundTransparency = 1
	toast.AnchorPoint = Vector2.new(0.5, 0)
	toast.Size = UDim2.new(0.8, 0, 0, 44)
	toast.Position = UDim2.new(0.5, 0, 0, 145)
	toast.Visible = false
	toast.ZIndex = 18
	toast.Parent = gui
	local constraint = Instance.new("UISizeConstraint")
	constraint.MaxSize = Vector2.new(440, 44)
	constraint.Parent = toast
	Art.Draw(toast, "warning_amber", 18, "wide")

	local toastSheen = Instance.new("Frame")
	toastSheen.Name = "HUDToastSheen"
	toastSheen.BackgroundColor3 = Color3.fromRGB(255, 248, 200)
	toastSheen.BackgroundTransparency = 0.3
	toastSheen.BorderSizePixel = 0
	toastSheen.Size = UDim2.new(1, -6, 1, -6)
	toastSheen.Position = UDim2.fromOffset(3, 3)
	toastSheen.ZIndex = 19
	toastSheen.Visible = false
	toastSheen.Parent = toast
	local toastCorner = Instance.new("UICorner")
	toastCorner.CornerRadius = UDim.new(0.5, 0)
	toastCorner.Parent = toastSheen
	local toastGrad = Instance.new("UIGradient")
	toastGrad.Rotation = -22
	toastGrad.Offset = Vector2.new(-1, 0)
	toastGrad.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.38, 1),
		NumberSequenceKeypoint.new(0.5, 0.15),
		NumberSequenceKeypoint.new(0.62, 1),
		NumberSequenceKeypoint.new(1, 1),
	})
	toastGrad.Parent = toastSheen

	local caption = Instance.new("TextLabel")
	caption.Name = "Caption"
	caption.BackgroundTransparency = 1
	caption.Size = UDim2.new(1, -48, 1, -8)
	caption.Position = UDim2.fromOffset(24, 4)
	caption.Font = Enum.Font.FredokaOne
	caption.TextSize = 18
	caption.TextColor3 = Color3.new(1, 1, 1)
	caption.TextStrokeTransparency = 0.3
	caption.TextWrapped = true
	caption.ZIndex = 20
	caption.Parent = toast

	local stars: {{ label: TextLabel, scale: UIScale }} = {}
	for i = 1, 8 do
		local star = Instance.new("TextLabel")
		star.Name = "Spark" .. i
		star.Text = "✦"
		star.Font = Enum.Font.FredokaOne
		star.TextColor3 = i % 2 == 0 and Color3.fromRGB(255, 224, 118) or Color3.fromRGB(165, 245, 255)
		star.TextStrokeColor3 = Color3.fromRGB(24, 30, 56)
		star.TextStrokeTransparency = 0.35
		star.AnchorPoint = Vector2.new(0.5, 0.5)
		star.BackgroundTransparency = 1
		star.Size = UDim2.fromOffset(22, 22)
		star.TextSize = i % 2 == 0 and 18 or 14
		star.Active = false
		star.ZIndex = 21
		local sc = Instance.new("UIScale")
		sc.Parent = star
		star.Parent = toast
		table.insert(stars, { label = star, scale = sc })
	end

	local expires = 0
	local born = 0
	link(gui:GetAttributeChangedSignal("HUDMotionNotice"), function()
		caption.Text = (gui:GetAttribute("HUDMotionNotice") :: string?) or ""
		toast.Visible = true
		born = os.clock()
		expires = born + 1.5
		local tr = state.records[toast]
		if tr then
			if tr.tween then tr.tween:Cancel() end
			if tr.fadeTween then tr.fadeTween:Cancel() end
			tr.visible = true
			if reduced() then
				tr.values.Value = 1
				tr.fade.Value = 1
				tr.offY = 0
			else
				tr.values.Value = 0.64
				tr.fade.Value = 0.05
				tr.offY = -16
				tween(tr, 1, 1, 0.36, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
			end
		end
		playSfx("chime")
	end)

	link(gui:GetAttributeChangedSignal("HUDMotionPingCue"), function()
		local cue = gui:GetAttribute("HUDMotionPingCue")
		if type(cue) ~= "string" or cue == "" then
			return
		end
		local isGhost = cue:sub(1, 6) == "ghost:"
		local banner = gui:FindFirstChild("CrewPingBanner")
		local r = banner and state.records[banner]
		if banner and banner:IsA("GuiObject") and r then
			if r.closeTask then
				task.cancel(r.closeTask)
				r.closeTask = nil
			end
			if r.tween then r.tween:Cancel() end
			if r.fadeTween then r.fadeTween:Cancel() end
			banner:SetAttribute("HUDMotionClosing", false)
			banner.Visible = true
			r.visible = true
			if state.EnsureBase then
				state.EnsureBase(banner)
			end
			if reduced() then
				r.values.Value = 1
				r.fade.Value = 1
				r.offY = 0
				r.shakeAmp = 0
			else
				r.values.Value = 0.84
				r.fade.Value = 0.08
				r.offY = -14
				r.popAge = 0
				r.popDur = 0.34
				r.popAmp = isGhost and 0.075 or 0.055
				r.shakeAmp = isGhost and 5 or 0
				r.shakeAge = 0
				tween(r, 1, 1, 0.30, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
				spawnPerimeterBurst(
					banner,
					isGhost and 8 or 5,
					isGhost and Color3.fromRGB(255, 198, 96) or Color3.fromRGB(132, 232, 255),
					isGhost and 1.15 or 0.9
				)
			end
		end
		playSfx(isGhost and "pingGhost" or "ping", isGhost and 0 or 0.04)
	end)

	-- Restore exact base properties before HUDLayout/HUDTheme calculate geometry.
	function state.BeforeLayout()
		for o, b in state.base do
			if o.Parent then
				local rec = state.records[o]
				if rec and rec.panelScale then
					rec.panelScale.Scale = 1
				end
				if o.Name ~= "HUDMotionVisual" and o.Position == b.appliedPosition then
					o.Position = b.position
				end
				if o.Size == b.appliedSize then
					o.Size = b.size
				end
				if rec and rec.rotApplied and o.Rotation == rec.rotApplied then
					o.Rotation = 0
				end
				o.BackgroundTransparency = b.bg
				if b.image ~= nil then
					(o :: any).ImageTransparency = b.image
				end
				if b.text ~= nil then
					(o :: any).TextTransparency = b.text
					;(o :: any).TextStrokeTransparency = b.stroke
				end
			end
		end
	end

	function state.Pulse(name: string, amplitude: number?, shake: number?)
		local o = gui:FindFirstChild(name, true)
		local r = o and state.records[o]
		if r and o and (o :: GuiObject).Visible and not reduced() then
			local now = os.clock()
			local minGap = (o :: any).Name:match("^HUDHull%d$") and 0.05 or 0.09
			if now - (r.pulseAt or 0) > minGap then
				r.pulseAt = now
				r.popAmp = math.max(r.popAmp or 0, amplitude or 0.16)
				r.popAge = 0
				r.popDur = 0.32
				if shake and shake > 0 then
					r.shakeAmp = math.max(r.shakeAmp or 0, shake)
					r.shakeAge = 0
				end
			end
		end
	end

	local function triggerStagger(modalObj: Instance)
		if reduced() then
			return
		end
		for o, r in state.records do
			if isModalDescendant(o, gui) == modalObj then
				local delaySec = 0
				if o.Name == "Card1" then
					delaySec = 0.05
				elseif o.Name == "Card2" then
					delaySec = 0.12
				elseif settingsStaggerOrder[o.Name] then
					delaySec = 0.02 + (settingsStaggerOrder[o.Name] - 1) * 0.022
				elseif pingStaggerOrder[o.Name] then
					delaySec = 0.02 + (pingStaggerOrder[o.Name] - 1) * 0.025
				end
				if delaySec > 0 then
					r.staggerUntil = os.clock() + delaySec
					r.fade.Value = 0
					r.values.Value = 0.86
					r.staggerPending = true
					if pingStaggerOrder[o.Name] then
						r.offX = -14
						r.offY = 0
					else
						r.offX = 0
						r.offY = 14
					end
				end
			end
		end
	end

	local function captureGuiBase(o: GuiObject): any
		local b: any = {
			position = o.Position,
			size = o.Size,
			bg = o.BackgroundTransparency,
			unscaledSize = o.AbsoluteSize,
		}
		if o:IsA("ImageLabel") or o:IsA("ImageButton") then
			b.image = o.ImageTransparency
		end
		if o:IsA("TextLabel") or o:IsA("TextButton") then
			b.text = o.TextTransparency
			b.stroke = o.TextStrokeTransparency
		end
		return b
	end

	function state.EnsureBase(root: GuiObject)
		if isDynamicOverlay(root) then
			return
		end
		if not state.base[root] then
			state.base[root] = captureGuiBase(root)
		end
		for _, child in root:GetDescendants() do
			if child:IsA("GuiObject") and not isDynamicOverlay(child) and not state.base[child] then
				state.base[child] = captureGuiBase(child)
			end
		end
	end

	function state.TriggerEnter(o: GuiObject, r: any)
		r.visible = true
		if r.isScrim then
			r.fade.Value = reduced() and 1 or 0
			tween(r, 1, 1, 0.20, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		elseif r.modal then
			r.values.Value = reduced() and 1 or 0.80
			r.fade.Value = reduced() and 1 or 0.05
			r.offY = reduced() and 0 or 22
			tween(r, 1, 1, 0.34, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
			triggerStagger(o)
			playSfx("open")
		elseif o.Name == "HUDFlightResult" then
			r.values.Value = reduced() and 1 or 0.72
			r.fade.Value = reduced() and 1 or 0.05
			r.offY = reduced() and 0 or -18
			tween(r, 1, 1, 0.42, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
			local resTitle = o:FindFirstChild("HUDResultTitle")
			if resTitle and resTitle:IsA("TextLabel") and resTitle.Text:lower():find("istana awan", 1, true) then
				spawnPerimeterBurst(o, 10, Color3.fromRGB(255, 224, 110), 1.4)
				playSfx("chime")
			end
		elseif o.Name == "AlertBanner" or o.Name == "StormChallengePanel" then
			r.values.Value = reduced() and 1 or 0.84
			r.fade.Value = reduced() and 1 or 0.1
			r.offY = reduced() and 0 or -10
			r.shakeAmp = reduced() and 0 or 6
			r.shakeAge = 0
			tween(r, 1, 1, 0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
			playSfx("alert")
		elseif o.Name == "CrewPingBanner" then
			r.values.Value = reduced() and 1 or 0.86
			r.fade.Value = reduced() and 1 or 0.08
			r.offY = reduced() and 0 or -14
			tween(r, 1, 1, 0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
		elseif o.Name == "AltimeterFrame" then
			r.values.Value = reduced() and 1 or 0.90
			r.fade.Value = reduced() and 1 or 0.1
			r.offY = reduced() and 0 or -12
			tween(r, 1, 1, 0.30, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
		elseif o.Name ~= "Card1" and o.Name ~= "Card2" and o.Name ~= "HUDMotionToast" then
			r.values.Value = reduced() and 1 or 0.90
			r.fade.Value = reduced() and 1 or 0.12
			r.offY = reduced() and 0 or 10
			tween(r, 1, 1, 0.26, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
		end
	end

	function state.Capture()
		local modalShowing = false
		for o, r in state.records do
			if r.button and o.Parent then
				for _, child in o:GetChildren() do
					if child:IsA("GuiObject") and child ~= r.host then
						child.Parent = r.host
					end
				end
				r.host.ZIndex = o.ZIndex
				if o.BackgroundTransparency < 1 then
					r.host.BackgroundColor3 = o.BackgroundColor3
					r.host.BackgroundTransparency = o.BackgroundTransparency
					o.BackgroundTransparency = 1
				else
					r.host.BackgroundTransparency = 1
				end

				local face = r.host:FindFirstChild("HUDAdventureRaster") or r.host:FindFirstChild("HUDRaster")
				local singleReady = face and face:IsA("ImageLabel") and face.ImageTransparency < 0.99 and face.Visible and face.IsLoaded
				local artLeft = face and face:FindFirstChild("HUDArtLeft")
				local artMid = face and face:FindFirstChild("HUDArtMiddle")
				local artRight = face and face:FindFirstChild("HUDArtRight")
				local wideReady = face and face:IsA("ImageLabel") and face.Visible and face.ImageTransparency >= 0.99
					and artLeft and artLeft:IsA("ImageLabel") and artLeft.IsLoaded
					and artMid and artMid:IsA("ImageLabel") and artMid.IsLoaded
					and artRight and artRight:IsA("ImageLabel") and artRight.IsLoaded

				r.hasSheenFace = singleReady == true
				r.hasWideSheen = wideReady == true

				if r.hasSheenFace and face and face:IsA("ImageLabel") then
					r.mask.Position = face.Position
					r.mask.Size = face.Size
					r.mask.AnchorPoint = face.AnchorPoint
					r.mask.Image = face.Image
					r.mask.ImageRectOffset = face.ImageRectOffset
					r.mask.ImageRectSize = face.ImageRectSize
					r.mask.ScaleType = face.ScaleType
					r.mask.ZIndex = math.min(o.ZIndex + 2, face.ZIndex + 1)
				end
				if r.hasWideSheen and face and face:IsA("ImageLabel") then
					local wideZ = math.min(o.ZIndex + 2, face.ZIndex + 1)
					r.wideMask.Position = face.Position
					r.wideMask.Size = face.Size
					r.wideMask.AnchorPoint = face.AnchorPoint
					r.wideMask.ZIndex = wideZ
					local map = { HUDArtLeft = artLeft, HUDArtMiddle = artMid, HUDArtRight = artRight }
					for segName, srcSeg in map do
						local dstSeg = r.wideParts[segName]
						if dstSeg and srcSeg and srcSeg:IsA("ImageLabel") then
							dstSeg.Position = srcSeg.Position
							dstSeg.Size = srcSeg.Size
							dstSeg.Image = srcSeg.Image
							dstSeg.ImageRectOffset = srcSeg.ImageRectOffset
							dstSeg.ImageRectSize = srcSeg.ImageRectSize
							dstSeg.ScaleType = srcSeg.ScaleType
							dstSeg.ZIndex = wideZ
						end
					end
				end
				if not eligible(o) and (r.hover or r.pressed) then
					r.hover = false
					neutral(r, true)
				end
			elseif not r.button and o.Parent then
				if r.modal and o.Visible and gui.Enabled and o:GetAttribute("HUDMotionClosing") ~= true then
					modalShowing = true
				end
			end
		end

		if modalShowing ~= state.modalBlurActive then
			state.modalBlurActive = modalShowing
			setBlur(modalShowing and 8 or 0, modalShowing and 0.22 or 0.15)
		end

		local base = {}
		for _, o in gui:GetDescendants() do
			if o:IsA("GuiObject") and not isDynamicOverlay(o) then
				base[o] = captureGuiBase(o)
			end
		end
		state.base = base

		for o, r in state.records do
			if not o:IsDescendantOf(gui) then
				if r.poseTween then r.poseTween:Cancel() end
				if r.sheenTween then r.sheenTween:Cancel() end
				if r.tween then r.tween:Cancel() end
				if r.fadeTween then r.fadeTween:Cancel() end
				if r.closeTask then task.cancel(r.closeTask) end
				for _, c in r.links do c:Disconnect() end
				r.values:Destroy()
				r.fade:Destroy()
				state.records[o] = nil
			else
				local visible = o.Visible and gui.Enabled
				if visible and not r.visible and not r.button and not r.isPip then
					state.TriggerEnter(o, r)
				elseif (not visible and r.visible) or (r.button and not o.Active and r.pressed) then
					neutral(r, true)
					if not visible and r.modal then
						r.offY = 0
					end
					r.visible = visible
				else
					r.visible = visible
				end
			end
		end
	end

	local lastRope: number? = nil
	local lastHoles: number? = nil
	local lastAmmo: string? = nil
	local lastAmmoNum: number? = nil
	local wasReloading = false
	local lastSpeedDir = 0
	local lastAimLocked = false
	local smoothed: {[Instance]: number} = {}
	local shimmerPhase = 0
	local nextClutchSpark = 0

	link(player:GetAttributeChangedSignal("InFlight"), function()
		lastHoles = nil
		lastAmmo = nil
		lastAmmoNum = nil
		wasReloading = false
		lastRope = nil
		lastSpeedDir = 0
	end)

	local function render(dt: number)
		if state.dead then
			return
		end
		local now = os.clock()
		local isRed = reduced()

		if toast.Visible and now >= expires then
			toast.Visible = false
		end
		if toast.Visible then
			local tb = state.base[toast]
			if tb then
				tb.position = UDim2.new(0.5, 0, 0, math.min(gui.AbsoluteSize.Y * 0.32, 145))
				if tb.unscaledSize and tb.unscaledSize.X < 1 then
					tb.unscaledSize = Vector2.new(math.min(gui.AbsoluteSize.X * 0.8, 440), 44)
				end
			end
		end

		-- Update staggered entrances & analytical offsets/shakes
		for o, r in state.records do
			if not o.Parent then
				continue
			end
			if r.staggerPending and now >= (r.staggerUntil or 0) then
				r.staggerPending = false
				tween(r, 1, 1, 0.30, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
			end
			if not r.staggerPending then
				local decay = 1 - math.exp(-dt * 12)
				r.offX = (r.offX or 0) * (1 - decay)
				r.offY = (r.offY or 0) * (1 - decay)
				if math.abs(r.offX) < 0.08 then r.offX = 0 end
				if math.abs(r.offY) < 0.08 then r.offY = 0 end
			end
			if (r.shakeAmp or 0) > 0.05 then
				r.shakeAge += dt
				r.shakeAmp *= math.exp(-dt * 9.5)
				if r.shakeAmp < 0.1 then
					r.shakeAmp = 0
				end
			end
			if (r.popAge or -1) >= 0 then
				r.popAge += dt
				if r.popAge >= r.popDur then
					r.popAge = -1
					r.popAmp = 0
				end
			end
		end

		-- Sync smoothed progress bars + base transparency & offsets
		for o, b in state.base do
			if not o.Parent then
				continue
			end
			if b.appliedSize and o.Size ~= b.appliedSize then
				b.size = o.Size
			end
			if b.appliedPosition and o.Position ~= b.appliedPosition then
				b.position = o.Position
			end
			local p, s = b.position, b.size
			local r = state.records[o]

			if o.Name == "BarFill" or o.Name == "TBarFill" then
				local goal = s.X.Scale
				local display = smoothed[o] or goal
				display = if isRed then goal else display + (goal - display) * (1 - math.exp(-dt / 0.09))
				smoothed[o] = display
				o.Size = UDim2.new(display, s.X.Offset, s.Y.Scale, s.Y.Offset)
				if o.Name == "BarFill" then
					ensureBarShimmer(o)
				end
			end

			if r and r.panelScale and not r.isScrim then
				local baseScale = if isRed then 1 else r.values.Value
				local popBonus = 0
				if not isRed and (r.popAge or -1) >= 0 then
					local tNorm = math.clamp(r.popAge / math.max(0.01, r.popDur), 0, 1)
					popBonus = (r.popAmp or 0) * math.sin(tNorm * math.pi) * (1 - tNorm * 0.35)
				end

				-- Rhythmic urgency breathing for critical state
				local ambientScale = 0
				if not isRed and o.Visible and gui.Enabled then
					if o.Name == "StatusFrame" and (o:GetAttribute("HoleCount") or 0) >= 4 then
						local pulse = math.max(0, math.sin(now * 5.2))
						ambientScale = 0.032 * pulse * pulse
					elseif (o.Name == "AlertBanner" or o.Name == "StormChallengePanel") then
						ambientScale = 0.018 * (0.5 + 0.5 * math.sin(now * 6.5))
					end
				end

				local finalScale = math.max(0.05, baseScale + popBonus + ambientScale)
				r.panelScale.Scale = finalScale

				local anchor = o.AnchorPoint
				local us = b.unscaledSize or o.AbsoluteSize
				local fixX = (0.5 - anchor.X) * us.X * (1 - finalScale)
				local fixY = (0.5 - anchor.Y) * us.Y * (1 - finalScale)
				local shakeX = if isRed or (r.shakeAmp or 0) <= 0 then 0 else math.sin(r.shakeAge * 48) * r.shakeAmp
				o.Position = UDim2.new(
					p.X.Scale, p.X.Offset + math.round(fixX + (r.offX or 0) + shakeX),
					p.Y.Scale, p.Y.Offset + math.round(fixY + (r.offY or 0))
				)
			end

			local opacity = 1
			local ancestor: Instance? = o
			while ancestor and ancestor ~= gui do
				local record = state.records[ancestor]
				if record then
					opacity *= record.fade.Value
				end
				ancestor = ancestor.Parent
			end
			o.BackgroundTransparency = 1 - (1 - b.bg) * opacity
			if b.image ~= nil then
				(o :: any).ImageTransparency = 1 - (1 - b.image) * opacity
			end
			if b.text ~= nil then
				(o :: any).TextTransparency = 1 - (1 - b.text) * opacity
				;(o :: any).TextStrokeTransparency = 1 - (1 - b.stroke) * opacity
			end
			b.appliedPosition = o.Position
			b.appliedSize = o.Size
		end

		-- Flowing sheen across Altimeter BarFill + Goal marker pulse
		if barShimmer and barShimmer.Parent and barShimmerGrad then
			if not isRed and barFillInstance and barFillInstance.Visible and barFillInstance.AbsoluteSize.X >= 4 then
				shimmerPhase = (shimmerPhase + dt / 2.2) % 1
				barShimmer.Visible = true
				local sx = -0.35 + shimmerPhase * 1.7
				barShimmer.Position = UDim2.fromScale(sx, 0)
			else
				barShimmer.Visible = false
			end
		end
		local alt = gui:FindFirstChild("AltimeterFrame")
		if alt then
			local marker = alt:FindFirstChild("HUDGoalMarkerSlot", true)
			if marker and marker:IsA("GuiObject") then
				local ms = marker:FindFirstChild("HUDMarkerScale") :: UIScale?
				if ms then
					ms.Scale = if not isRed and player:GetAttribute("InFlight") == true then 1 + 0.09 * (0.5 + 0.5 * math.sin(now * 3.8)) else 1
				end
			end
			local speedText = alt:FindFirstChild("HUDSpeedText", true)
			local speedPill = alt:FindFirstChild("HUDSpeedPill", true)
			if speedPill and speedPill:IsA("GuiObject") and speedText and speedText:IsA("TextLabel") then
				local v = alt:GetAttribute("VerticalSpeed")
				local dir = if typeof(v) == "number" then (v >= 0.05 and 1 or (v <= -0.05 and -1 or 0)) else 0
				if dir ~= lastSpeedDir and player:GetAttribute("InFlight") == true and not isRed then
					local ps = speedPill:FindFirstChild("HUDSpeedPop") :: UIScale?
					if ps then
						ps.Scale = 1.16
						TweenService:Create(ps, TweenInfo.new(0.24, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
					end
				end
				lastSpeedDir = dir
			end
		end

		-- Reticle auto-aim lock-on pop & snap rotation
		local reticle = gui:FindFirstChild("WeaponReticle")
		if reticle and reticle:IsA("GuiObject") then
			local locked = reticle:GetAttribute("AimLocked") == true
			local rs = reticle:FindFirstChild("HUDReticleScale") :: UIScale?
			if locked ~= lastAimLocked and rs and not isRed then
				if locked then
					rs.Scale = 1.48
					reticle.Rotation = 45
					TweenService:Create(rs, TweenInfo.new(0.20, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
					TweenService:Create(reticle, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Rotation = 0 }):Play()
				else
					rs.Scale = 1
					reticle.Rotation = 0
				end
			end
			lastAimLocked = locked
		end

		-- Urgent pulsing warning icon inside AlertBanner / StormChallengePanel
		for _, wName in { "AlertBanner", "StormChallengePanel" } do
			local wb = gui:FindFirstChild(wName)
			if wb and wb:IsA("GuiObject") and wb.Visible then
				local icon = wb:FindFirstChild("HUDWarningIcon")
				if icon and icon:IsA("GuiObject") then
					local ws = icon:FindFirstChild("HUDWarnScale") :: UIScale?
					if ws then
						ws.Scale = if not isRed then 1 + 0.14 * (0.5 + 0.5 * math.sin(now * 8.5)) else 1
					end
				end
			end
		end

		-- Buttons update: scale, sheen visibility, click tilt, ambient CTA shimmer, & clutch attention
		local groundedOn = gui:GetAttribute("HUDGroundedSeconds") ~= nil
		for o, r in state.records do
			if r.button and r.host and r.host.Parent then
				local btn = o :: GuiButton
				local canAct = eligible(o)
				local idleBreath = 0
				local idleY = 0
				if not isRed and canAct then
					-- Clutch Save or takeoff gas attention pulse
					local isClutch = o.Name == "EmergencyKitButton" and btn.Text:find("CLUTCH", 1, true) ~= nil
					local isGasAttention = o.Name == "GasButton" and groundedOn
					if isClutch and not r.pressed then
						idleBreath = 0.065 * (0.5 + 0.5 * math.sin(now * 7.5))
						if now >= nextClutchSpark then
							nextClutchSpark = now + 0.85
							spawnPerimeterBurst(o, 5, Color3.fromRGB(255, 110, 90), 1.0)
						end
					elseif isGasAttention and not r.pressed then
						idleBreath = 0.04 * (0.5 + 0.5 * math.sin(now * 4.5))
					end

					-- Periodic subtle sheen on key CTA buttons
					if (ctaButtons[o.Name] or isClutch) and now >= (r.nextIdleSheen or 0) then
						r.nextIdleSheen = now + 4.4 + math.random() * 1.4
						if not r.hover and not r.pressed then
							sweepSheen(r, 0.52)
						end
					end
				end

				r.visualScale.Scale = if isRed then 1 else math.max(0.5, r.values.Value + idleBreath)

				-- Crisp micro-tilt on tap rebound
				if not isRed and r.rotPulseAt and now - r.rotPulseAt < 0.24 then
					local rt = (now - r.rotPulseAt) / 0.24
					r.host.Rotation = (r.rotPulseDir or 2.5) * math.sin(rt * math.pi) * (1 - rt)
				else
					r.host.Rotation = 0
				end

				-- Off-modal stagger offset inside HUDMotionVisual
				if not isRed and (math.abs(r.offX or 0) > 0.1 or math.abs(r.offY or 0) > 0.1) and not r.pressed and not r.hover then
					r.host.Position = UDim2.new(0.5, math.round(r.offX or 0), 0.5, math.round(r.offY or 0))
				elseif idleY ~= 0 then
					r.host.Position = UDim2.new(0.5, 0, 0.5, idleY)
				end

				r.mask.Visible = r.hasSheenFace == true and canAct and not isRed
				if r.wideMask then
					r.wideMask.Visible = r.hasWideSheen == true and canAct and not isRed and now < (r.sheenUntil or 0)
				end
			end
		end

		-- Update pooled perimeter sparkle particles
		for _, sp in sparkPool do
			if sp.active then
				local age = now - sp.born
				if age >= sp.dur or isRed or not gui.Enabled then
					sp.active = false
					sp.label.Visible = false
				else
					local u = age / sp.dur
					local ease = easeOutCubic(u)
					sp.label.Position = UDim2.fromOffset(sp.sx + sp.vx * ease * sp.dur, sp.sy + sp.vy * ease * sp.dur)
					sp.label.Rotation = sp.rot0 + sp.rotVel * age
					-- Bell-curve scale: pop big quickly, then twinkle out cleanly
					local szScale = u < 0.25 and (0.4 + 0.85 * (u / 0.25)) or (1.25 * (1 - (u - 0.25) / 0.75))
					sp.scale.Scale = math.max(0.05, szScale)
					sp.label.TextTransparency = u < 0.45 and 0 or ((u - 0.45) / 0.55)
					sp.label.TextStrokeTransparency = 0.35 + 0.65 * sp.label.TextTransparency
				end
			end
		end

		-- Update Biome Milestone / Victory Toast banner + 8 Spark firework children
		local banner = gui:FindFirstChild("AlertBanner")
		local scrim = gui:FindFirstChild("HUDModalScrim")
		if toast.Visible then
			local age = now - born
			local blocked = (banner and (banner :: GuiObject).Visible) or (scrim and (scrim :: GuiObject).Visible)
			caption.Visible = not blocked
			local art = toast:FindFirstChild("HUDAdventureRaster")
			if art and art:IsA("GuiObject") then
				art.Visible = not blocked
			end

			-- Smooth golden sheen pass at 0.08s..0.64s
			if not isRed and not blocked and age >= 0.06 and age <= 0.66 then
				toastSheen.Visible = true
				local su = (age - 0.06) / 0.60
				toastGrad.Offset = Vector2.new(-1 + su * 2, 0)
			else
				toastSheen.Visible = false
			end

			-- Smooth exit scale-fade at the final 0.26s before expiry
			local tr = state.records[toast]
			if tr and not isRed and age >= 1.22 and not tr.exitStarted then
				tr.exitStarted = true
				tween(tr, 0.90, 0, 0.26, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			elseif age < 0.2 and tr then
				tr.exitStarted = false
			end
			if tr and not state.base[toast] then
				if tr.panelScale then
					tr.panelScale.Scale = if isRed then 1 else math.max(0.05, tr.values.Value)
				end
				toast.Position = UDim2.new(0.5, 0, 0, math.min(gui.AbsoluteSize.Y * 0.32, 145) + math.round(if isRed then 0 else (tr.offY or 0)))
			end

			local halfW = toast.AbsoluteSize.X * 0.44
			local halfH = toast.AbsoluteSize.Y * 0.42
			for i, sp in stars do
				local showStar = not isRed and not blocked and age < 0.8
				sp.label.Visible = showStar
				if showStar then
					local u = age / 0.8
					local e = easeOutCubic(u)
					local angle = (i - 1) * (math.pi / 4) + 0.2
					local rx = math.cos(angle) * (halfW * 0.35 + e * math.max(52, halfW * 0.72))
					local ry = math.sin(angle) * (halfH * 0.45 + e * 38) - e * 10
					sp.label.Position = UDim2.new(0.5, math.round(rx), 0.5, math.round(ry))
					sp.label.Rotation = i * 25 + age * 130
					sp.scale.Scale = math.max(0.1, math.sin(u * math.pi) * 1.28)
					sp.label.TextTransparency = u < 0.55 and 0 or ((u - 0.55) / 0.45)
					sp.label.TextStrokeTransparency = 0.35 + 0.65 * sp.label.TextTransparency
				end
			end
		end

		-- Reactive Gameplay HUD Feedback Triggers
		-- 1. Balloon Health Pips: big visible pop + StatusFrame impact shake & sparks
		local hull = gui:FindFirstChild("StatusFrame")
		local holes = hull and hull:GetAttribute("HoleCount")
		if typeof(holes) == "number" then
			if lastHoles ~= nil and lastHoles ~= holes then
				local damaged = holes > lastHoles
				if hull and hull:IsA("GuiObject") and hull.Visible then
					if damaged then
						state.Pulse("StatusFrame", 0.08, 7)
						spawnPerimeterBurst(hull, 6, Color3.fromRGB(255, 95, 75), 1.05)
					else
						state.Pulse("StatusFrame", holes == 0 and 0.11 or 0.06, 0)
						spawnPerimeterBurst(hull, 6, Color3.fromRGB(95, 255, 165), 1.0)
					end
				end
				for i = math.min(5 - lastHoles, 5 - holes) + 1, math.max(5 - lastHoles, 5 - holes) do
					state.Pulse("HUDHull" .. i, 0.55, damaged and 3 or 0)
				end
			end
			lastHoles = holes
		end

		-- 2. Tether Durability Threshold Pulse & Critical Shake
		local rope = gui:FindFirstChild("TetherLabel", true)
		local durability = rope and rope:IsA("TextLabel") and tonumber(rope.Text:match("(%d+)%%"))
		if durability then
			if lastRope and ((lastRope > RopeWarnings.ROPE_LOW_PERCENT and durability <= RopeWarnings.ROPE_LOW_PERCENT)
				or (lastRope > RopeWarnings.ROPE_CRITICAL_PERCENT and durability <= RopeWarnings.ROPE_CRITICAL_PERCENT)) then
				state.Pulse("TetherFrame", 0.16, durability <= RopeWarnings.ROPE_CRITICAL_PERCENT and 4 or 0)
				playSfx("alert")
			end
			lastRope = durability
		else
			lastRope = nil
		end

		-- 3. Weapon Ammo Recoil & Reload Completion Pop
		local weaponFrame = gui:FindFirstChild("WeaponFrame")
		local ammo = gui:FindFirstChild("AmmoLabel", true)
		if ammo and ammo:IsA("TextLabel") and weaponFrame and weaponFrame:IsA("GuiObject") and weaponFrame.Visible then
			local reloadingNow = ammo.Text:find("RELOADING", 1, true) ~= nil
			local curNum = tonumber(ammo.Text:match("^(%d+)"))
			if wasReloading and not reloadingNow and curNum then
				-- Reload finished! Satisfying ready bounce + sparkles
				state.Pulse("WeaponFrame", 0.15, 0)
				spawnPerimeterBurst(weaponFrame, 5, Color3.fromRGB(130, 235, 255), 0.9)
				playSfx("chime", 0.15)
			elseif curNum and lastAmmoNum and curNum < lastAmmoNum then
				-- Bullet fired! Snappy recoil nudge on WeaponFrame
				local wr = state.records[weaponFrame]
				if wr and not isRed then
					wr.offX = -7
					wr.offY = 2
					state.Pulse("WeaponFrame", 0.08, 0)
				end
			elseif lastAmmo and lastAmmo ~= ammo.Text and not reloadingNow then
				state.Pulse("WeaponFrame", 0.08, 0)
			end
			wasReloading = reloadingNow
			lastAmmoNum = curNum
			lastAmmo = ammo.Text
		else
			lastAmmo = nil
			lastAmmoNum = nil
			wasReloading = false
		end

		for o in smoothed do
			if not o:IsDescendantOf(gui) then
				smoothed[o] = nil
			end
		end
	end

	RunService:BindToRenderStep(stepName, Enum.RenderPriority.Last.Value + 20, render)

	function state.Destroy()
		if state.dead then
			return
		end
		state.dead = true
		state.BeforeLayout()
		RunService:UnbindFromRenderStep(stepName)
		if coroutine.status(sfxPreloadTask) ~= "dead" then
			task.cancel(sfxPreloadTask)
		end
		if blurTween then
			blurTween:Cancel()
		end
		modalBlur:Destroy()
		audioFolder:Destroy()
		for _, sp in sparkPool do
			sp.label:Destroy()
		end
		for _, c in state.links do
			c:Disconnect()
		end
		for _, r in state.records do
			if r.tween then r.tween:Cancel() end
			if r.fadeTween then r.fadeTween:Cancel() end
			if r.poseTween then r.poseTween:Cancel() end
			if r.sheenTween then r.sheenTween:Cancel() end
			for _, c in r.links do c:Disconnect() end
			if r.closeTask then task.cancel(r.closeTask) end
			r.values:Destroy()
			r.fade:Destroy()
		end
		table.clear(state.base)
		table.clear(state.records)
		table.clear(smoothed)
		toast:Destroy()
		sessions[gui] = nil
	end

	link(gui.Destroying, state.Destroy)
	return state
end

function Motion.SetVisible(o: GuiObject, visible: boolean)
	local gui = o:FindFirstAncestorWhichIsA("ScreenGui")
	if not gui then
		o.Visible = visible
		return
	end
	local state = Motion.Start(gui, Players.LocalPlayer)
	local r = state.records[o]
	if not r then
		o.Visible = visible
		return
	end
	if r.closeTask then
		task.cancel(r.closeTask)
		r.closeTask = nil
	end
	local wasOpen = o.Visible and o:GetAttribute("HUDMotionClosing") ~= true
	o:SetAttribute("HUDMotionClosing", not visible)
	if visible then
		o.Visible = true
		r.visible = false
		if state.EnsureBase then
			state.EnsureBase(o)
		end
		if gui.Enabled and not r.button and not r.isPip and state.TriggerEnter then
			state.TriggerEnter(o, r)
		end
		if r.modal and state.SyncModalBlur then
			state.SyncModalBlur(0.22)
		end
	else
		if r.tween then r.tween:Cancel() end
		if r.fadeTween then r.fadeTween:Cancel() end
		local red = Players.LocalPlayer:GetAttribute("ReduceHUDMotion") == true
		if r.modal and not red then
			r.values.Value = r.values.Value
			r.tween = TweenService:Create(r.values, TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Value = 0.88 })
			r.tween:Play()
			r.offY = 12
		end
		r.fadeTween = TweenService:Create(r.fade, TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Value = 0 })
		r.fadeTween:Play()

		-- Synchronously fade scrim, close sound, and blur during modal closing
		if r.modal then
			local scrim = gui:FindFirstChild("HUDModalScrim")
			local sr = scrim and state.records[scrim]
			if sr then
				if sr.fadeTween then sr.fadeTween:Cancel() end
				sr.fadeTween = TweenService:Create(sr.fade, TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Value = 0 })
				sr.fadeTween:Play()
			end
			if state.SyncModalBlur then
				state.SyncModalBlur(0.14)
			end
			if wasOpen and state.PlaySfx then
				state.PlaySfx("close")
			end
		end

		r.closeTask = task.delay(0.14, function()
			r.closeTask = nil
			if o.Parent then
				o.Visible = false
			end
		end)
	end
end

function Motion.Toggle(o: GuiObject)
	Motion.SetVisible(o, not o.Visible or o:GetAttribute("HUDMotionClosing") == true)
end

return Motion
