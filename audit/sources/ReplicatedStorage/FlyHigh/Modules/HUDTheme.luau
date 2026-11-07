-- Image-backed Sky Adventure presentation. Controllers own input and game state.
local Assets = require(script.Parent.HUDImageAssets)
local Glyphs = require(script.Parent.HUDGlyphs)
local Adventure = require(script.Parent.HUDAdventureArt)
local Input = game:GetService("UserInputService")
local Players = game:GetService("Players")

local Theme = {}

-- {1: GlyphKey, 2: FallbackTitle, 3: Sprite, 4: Style ("dock", "round", "wide", "tile")}
local configs = {
	ShopToggleButton = { "shop", "TOKO", "shop_toggle", "dock" },
	EmergencyKitButton = { "kit", "KIT", "kit_use", "dock" },
	PingButton = { "ping", "PING", "ping_toggle", "dock" },
	WarningAudioToggleButton = { "sound", "SUARA", "audio_on", "dock" },
	MobileShootButton = { "fire", "", "shoot", "round" },
	JumpButton = { "jump", "", "jump", "round" },
	GasButton = { "gas", "GAS NAIK", "gas", "tile" },
	AutoGasButton = { "auto", "GAS OTOMATIS", "auto_off", "wide" },
	ReleaseHelmButton = { "release", "LEPAS", "release", "tile" },
	ReloadButton = { "reload", "ISI", "reload", "tile" },
	DropButton = { "drop", "LEPAS", "drop", "tile" },
	AttachButton = { "attach", "PASANG TALI", "attach", "wide" },
	DetachButton = { "detach", "LEPAS TALI", "detach", "wide" },
	ClimbButton = { "climb", "NAIK KUBAH", "climb", "wide" },
	DescendButton = { "descend", "TURUN", "descend", "wide" },
	PullCrewButton = { "rescue", "TARIK REKAN", "pull", "wide" },
	BuyEmergencyKitButton = { "kit", "BELI 1 KIT • 29 R$", "buy_kit", "wide" },
	BuyAK47Button = { "weapon", "UPGRADE AK-47 • 79 R$", "buy_rifle", "wide" },
	SpotHazardButton = { "warning", "TANDAI BAHAYA", "spot", "wide" },
	CloseButton = { "close", "", "close", "round" },
	Ping1 = { "gas", "Gas Api Sekarang!", "ping1", "wide" },
	Ping2 = { "warning", "Awas Tornado Menghindar!", "ping2", "wide" },
	Ping3 = { "rope", "Tali Saya Mau Habis!", "ping3", "wide" },
	Ping4 = { "repair", "Saya yang Perbaiki!", "ping4", "wide" },
	Ping5 = { "aim", "Fokus Tembak Rintangan!", "ping5", "wide" },
}

local fullButtons = {
	shop_toggle = "shop_normal", kit_use = "kit_normal", kit_clutch = "kit_clutch",
	ping_toggle = "ping_normal", audio_on = "sound_on", audio_off = "sound_off",
	shoot = "fire_normal", jump = "jump_normal", gas = "gas_normal",
	auto_off = "auto_off", auto_on = "auto_on", release = "release_helm_normal",
	reload = "reload_v2", drop = "drop_normal", attach = "tether_attach",
	detach = "tether_detach", climb = "tether_climb", descend = "tether_descend",
	patch = "tether_patch", repair_rope = "tether_repair_rope", pull = "tether_pull",
	buy_kit = "buy_button", buy_rifle = "buy_button", close = "close_normal",
	ping1 = "ping_thrust", ping2 = "ping_danger", ping3 = "ping_rope",
	ping4 = "ping_repair", ping5 = "ping_target", spot = "context_panel",
}

local adventurePanels = {
	altitude = "altitude_panel", status = "hull_panel_v2", status_critical = "hull_panel_v2",
	ammo = "ammo_panel", tether = "rope_panel", countdown = "warning_amber",
	alert = "warning_critical", storm = "warning_amber", track = "progress_track",
	progress = "progress_fill", rope_fill = "progress_fill",
	hull_good = "hull_pip_intact", hull_broken = "hull_pip_torn",
	shop_panel = "shop_panel", ping_panel = "ping_panel", spot_panel = "context_panel",
	kit_card = "shop_kit_card", rifle_card = "shop_ak_card",
}

local function box(o, x, y, w, h)
	if not o then return end
	o.Position = UDim2.fromOffset(math.round(x), math.round(y))
	o.Size = UDim2.fromOffset(math.round(w), math.round(h))
end

local function frame(parent, name)
	local f = parent:FindFirstChild(name) or Instance.new("Frame")
	f.Name = name
	f.BorderSizePixel = 0
	f.BackgroundTransparency = 1
	f.Size = UDim2.fromScale(1, 1)
	f.Parent = parent
	return f
end

local function round(o, r)
	local c = o:FindFirstChildOfClass("UICorner") or Instance.new("UICorner", o)
	if type(r) == "number" then
		if r <= 1 then
			c.CornerRadius = UDim.new(r, 0)
		else
			c.CornerRadius = UDim.new(0, math.round(r))
		end
	else
		c.CornerRadius = UDim.new(0, 12)
	end
	return c
end

local function stroke(o, color, width, transparency)
	local s = o:FindFirstChildOfClass("UIStroke") or Instance.new("UIStroke", o)
	s.Color = color
	s.Thickness = width or 2
	s.Transparency = transparency or 0
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	return s
end

-- Professional Typography Engine: Uses vector UIStroke contextual mode,
-- eliminates pixelated legacy TextStroke, supports RichText and fixed readable sizes.
local function applyTextStyle(lbl, opts)
	if not lbl then return end
	lbl.Font = opts.font == Enum.Font.GothamBlack and Enum.Font.FredokaOne or Enum.Font.Nunito
	lbl.TextSize = opts.size or 14
	if not lbl:FindFirstChildOfClass("UITextSizeConstraint") then
		lbl.TextScaled = opts.scaled == true
		lbl.TextWrapped = opts.wrapped ~= false
	end
	lbl.RichText = opts.rich ~= false
	lbl.TextColor3 = opts.color or Color3.new(1, 1, 1)
	lbl.TextStrokeTransparency = 1 -- Disable legacy jagged stroke
	if opts.align then lbl.TextXAlignment = opts.align end
	if opts.valign then lbl.TextYAlignment = opts.valign end

	local s = lbl:FindFirstChildOfClass("UIStroke") or Instance.new("UIStroke", lbl)
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
	s.Thickness = (opts.strokeThickness or 2) * 0.72
	s.Color = opts.strokeColor or Color3.fromRGB(4, 10, 24)
	s.Transparency = opts.strokeTransparency or 0
	s.Enabled = true
	return s
end

-- Keep a single line inside its artwork, with a cap that honors text preference.
local function fitLine(lbl, textBoost)
	local constraint = lbl:FindFirstChildOfClass("UITextSizeConstraint")
	if not constraint then
		constraint = Instance.new("UITextSizeConstraint")
		constraint.MinTextSize = 9
		constraint.Parent = lbl
	end
	constraint.MaxTextSize = math.max(9, lbl.TextSize + textBoost)
	lbl.TextTruncate = Enum.TextTruncate.None
	lbl.TextScaled = true
end

local function label(parent, name, size, font, color, strokeColor, strokeThickness)
	local l = parent:FindFirstChild(name) or Instance.new("TextLabel")
	l.Name = name
	l.BackgroundTransparency = 1
	l.Size = UDim2.fromScale(1, 1)
	l.Parent = parent
	applyTextStyle(l, {
		size = size or 14,
		font = font or Enum.Font.GothamBold,
		color = color or Color3.new(1, 1, 1),
		strokeColor = strokeColor or Color3.fromRGB(4, 10, 24),
		strokeThickness = strokeThickness or 2,
	})
	return l
end

local function ztree(root, z)
	if not root then return end
	root.ZIndex = z
	for _, o in root:GetDescendants() do
		if o:IsA("GuiObject") then
			o.ZIndex = z
		end
	end
end

local surfaceKeys = {
	AltimeterFrame = "altitude",
	StatusFrame = "status",
	WeaponFrame = "ammo",
	TetherFrame = "tether",
	GroundedCountdown = "countdown",
	AlertBanner = "alert",
	StormChallengePanel = "storm",
	ShopModal = "shop_panel",
	TacticalPingWheel = "ping_panel",
	GhostSpotterFrame = "spot_panel",
	Card1 = "kit_card",
	Card2 = "rifle_card",
}

local function raster(o, key, z, tint, completeKey, mode)
	local adventureKey = completeKey or adventurePanels[key]
	local complete, adventureImage = Adventure.Draw(o, adventureKey, z,
		mode or ((o:IsA("ScrollingFrame") or key == "ping_panel" or key == "kit_card" or key == "rifle_card") and "stretch" or "wide"), tint)
	local image = o:FindFirstChild("HUDRaster")
	local loaded = complete
	if complete then
		if image then image.Visible = false end
	else
		if not image then image = Assets.Mount(o, key) end
		loaded = Assets.Apply(image, key)
		Assets.Surface(image, key, o.AbsoluteSize)
		image.Visible = true
		image.ZIndex = z
		image.ImageColor3 = tint or Color3.new(1, 1, 1)
		if o:IsA("ScrollingFrame") then
			image.Position = UDim2.fromOffset(o.CanvasPosition.X, o.CanvasPosition.Y)
			image.Size = UDim2.fromOffset(o.AbsoluteWindowSize.X, o.AbsoluteWindowSize.Y)
		end
	end
	o.BackgroundTransparency = loaded and 1 or 0.12
	local outline = o:FindFirstChildOfClass("UIStroke")
	if outline and outline.ApplyStrokeMode == Enum.ApplyStrokeMode.Border then outline.Enabled = not loaded end
	return complete, adventureImage
end

local function chip(label, key, z)
	local name = label.Name .. "Raster"
	local image = label.Parent:FindFirstChild(name)
	if not image then
		image = Assets.Mount(label.Parent, key)
		image.Name = name
	end
	local loaded = Assets.Apply(image, key)
	Assets.Surface(image, key, label.AbsoluteSize)
	image.AnchorPoint = label.AnchorPoint
	image.Position = label.Position
	image.Size = label.Size
	image.Visible = label.Visible
	image.ZIndex = z
	label.ZIndex = z + 1
	label.BackgroundTransparency = loaded and 1 or 0.2
	local outline = label:FindFirstChildOfClass("UIStroke")
	if outline then outline.Enabled = not loaded end
end

function Theme.Start(gui, player)
	local state = {}
	local alive = true
	local records, links = {}, {}
	gui:SetAttribute("HUDArtDirection", "Sky Adventure PNG")
	Assets.Preload()
	Adventure.Preload()
	local function letter(label)
		label.TextTransparency = 0
	end
	local function meter(label)
		label.TextTransparency = 0
		return label.TextBounds.X
	end
	local result = frame(gui, "HUDFlightResult")
	result.AnchorPoint = Vector2.new(0.5, 0.5)
	result.Position = UDim2.fromScale(0.5, 0.45)
	result.Size = UDim2.new(0.74, 0, 0, 140)
	local resultSize = Instance.new("UISizeConstraint")
	resultSize.MaxSize = Vector2.new(380, 140)
	resultSize.Parent = result
	result.BackgroundColor3 = Color3.fromRGB(14, 37, 66)
	result.ZIndex = 17
	result.Visible = false
	round(result, 18)
	local resultText = label(result, "HUDResultTitle", 23, Enum.Font.GothamBlack)
	resultText.Position = UDim2.fromScale(0.09, 0.43)
	resultText.Size = UDim2.fromScale(0.82, 0.38)
	resultText.TextScaled = true
	resultText.ZIndex = 18
	local lastResult, resultUntil = nil, 0

	local function connect(signal, fn)
		local c = signal:Connect(fn)
		table.insert(links, c)
		return c
	end

	-- Pure transparent PNG illustration (Zero black background artifact!)
	local function art(parent)
		local a = Instance.new("ImageLabel")
		a.Name = "HUDIllustration"
		a.BackgroundTransparency = 1
		a.BorderSizePixel = 0
		a.Active = false
		a.Selectable = false
		a.ScaleType = Enum.ScaleType.Fit
		a.Size = UDim2.fromScale(1, 1)
		a.Visible = false
		a.Parent = parent
		return a
	end

	local function use(image, key)
		image.Visible = true
		return Assets.Apply(image, key)
	end

	local function build(o, kind, config)
		if records[o] then return end
		local r = { kind = kind, config = config, pressed = false, links = {} }
		records[o] = r

		if kind ~= "reticle" then
			o.BorderSizePixel = 0
		end

		if kind == "button" then
			o.TextTransparency = 1
			local oldStroke = o:FindFirstChildOfClass("UIStroke")
			if oldStroke then oldStroke.Enabled = false end
			o.AutoButtonColor = false

			r.glyphBox = frame(o, "HUDIconBox")
			r.glyphBox.BackgroundTransparency = 1
			r.glyph = Glyphs.Draw(r.glyphBox, config[1])

			-- Sleek bottom caption ribbon
			r.captionPill = frame(o, "HUDCaptionPill")
			r.captionPill.BackgroundColor3 = Color3.fromRGB(6, 12, 24)
			r.captionPill.BackgroundTransparency = 0.2
			round(r.captionPill, 4)

			r.caption = label(r.captionPill, "HUDCaption", config[4] == "wide" and 13 or 11, Enum.Font.GothamBlack)
			r.caption.TextXAlignment = Enum.TextXAlignment.Center

			-- Keyboard shortcut hint
			r.hint = label(o, "HUDKeyHint", 10, Enum.Font.GothamBlack, Color3.fromRGB(255, 235, 120))
			r.hint.BackgroundTransparency = 0.2
			r.hint.BackgroundColor3 = Color3.fromRGB(6, 14, 28)
			round(r.hint, 3)

			-- Notification / Cooldown badge
			r.badge = label(o, "HUDBadge", 11, Enum.Font.GothamBlack, Color3.new(1, 1, 1), Color3.fromRGB(4, 10, 24), 1.8)
			r.badge.BackgroundTransparency = 0
			r.badge.BackgroundColor3 = Color3.fromRGB(36, 212, 85)
			round(r.badge, 0.5)
			stroke(r.badge, Color3.new(1, 1, 1), 1.5)

			local function link(signal, fn)
				table.insert(r.links, signal:Connect(fn))
			end
			link(o.InputBegan, function(i)
				if o.Active and (i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1) then
					r.pressed = true
					r.input = i
				end
			end)
			link(o.MouseLeave, function()
				if r.input and r.input.UserInputType ~= Enum.UserInputType.Touch then
					r.pressed = false
				end
			end)

		elseif kind == "alt" then
			-- Altitude Hero Metric (RichText bold number + colored unit)
			r.head = label(o, "HUDAltitude", 26, Enum.Font.GothamBlack, Color3.new(1, 1, 1), Color3.fromRGB(4, 12, 28), 2.5)
			r.head.TextXAlignment = Enum.TextXAlignment.Left
			r.head.TextWrapped = false

			r.goal = label(o, "HUDGoal", 12, Enum.Font.GothamBold, Color3.fromRGB(213, 237, 255), Color3.fromRGB(4, 12, 28), 1)
			r.goal.FontFace = Font.new(r.goal.FontFace.Family, Enum.FontWeight.Bold)
			r.goal.TextXAlignment = Enum.TextXAlignment.Left
			r.goal.TextWrapped = false
			r.goal.TextTruncate = Enum.TextTruncate.AtEnd

			r.percent = label(o, "HUDProgress", 12, Enum.Font.GothamBlack, Color3.fromRGB(224, 242, 254), Color3.fromRGB(4, 12, 28), 1.5)
			r.percent.TextXAlignment = Enum.TextXAlignment.Center
			r.percent.TextWrapped = false

			-- Dedicated Speed Telemetry Pill Box & Label (eliminates duplicate writes and text flapping)
			r.speedPill = frame(o, "HUDSpeedPill")
			r.speedPill.BackgroundColor3 = Color3.fromRGB(6, 16, 34)
			r.speedPill.BackgroundTransparency = 0.25
			round(r.speedPill, 6)
			local pillStroke = stroke(r.speedPill, Color3.fromRGB(28, 54, 96), 1)
			pillStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

			r.speed = label(r.speedPill, "HUDSpeedText", 12, Enum.Font.GothamBlack, Color3.fromRGB(147, 197, 253), Color3.fromRGB(4, 12, 28), 1.5)
			r.speed.TextXAlignment = Enum.TextXAlignment.Center
			r.speed.TextYAlignment = Enum.TextYAlignment.Center
			r.speed.TextWrapped = false

			-- 100% Transparent Emblem Container (No black disc!)
			r.emblem = frame(o, "HUDEmblem")
			r.emblem.BackgroundTransparency = 1
			r.emblem.BorderSizePixel = 0

			r.glyph = Glyphs.Draw(r.emblem, "climb")
			r.art = art(r.emblem)

		elseif kind == "status" then
			r.head = label(o, "HUDCondition", 11, Enum.Font.GothamBold, Color3.fromRGB(147, 197, 253), Color3.fromRGB(4, 10, 24), 1.5)
			r.head.TextXAlignment = Enum.TextXAlignment.Left

			r.count = label(o, "HUDDamageCount", 11, Enum.Font.GothamBlack, Color3.fromRGB(34, 197, 94), Color3.fromRGB(4, 10, 24), 1.5)
			r.count.BackgroundColor3 = Color3.fromRGB(8, 20, 42)
			r.count.BackgroundTransparency = 0.2
			round(r.count, 4)
			stroke(r.count, Color3.fromRGB(28, 54, 96), 1)

			r.detail = label(o, "HUDConditionDetail", 11, Enum.Font.GothamBold, Color3.fromRGB(74, 222, 128), Color3.fromRGB(4, 10, 24), 1.5)
			r.detail.TextXAlignment = Enum.TextXAlignment.Left

			r.pips = {}
			for i = 1, 5 do
				local pip = frame(o, "HUDHull" .. i)
				r.pips[i] = pip
			end

		elseif kind == "weapon" then
			r.head = label(o, "HUDWeapon", 13, Enum.Font.GothamBlack, Color3.fromRGB(255, 220, 90))
			r.ammo = label(o, "HUDAmmo", 28, Enum.Font.GothamBlack, Color3.new(1, 1, 1), Color3.fromRGB(4, 10, 24), 2.5)
			r.magazine = label(o, "HUDMagazine", 11, Enum.Font.GothamBold, Color3.fromRGB(160, 200, 240))
			r.emblem = frame(o, "HUDWeaponIcon")
			r.emblem.BackgroundTransparency = 1
			r.glyph = Glyphs.Draw(r.emblem, "weapon")
			r.art = art(r.emblem)

		elseif kind == "tether" then
			r.head = label(o, "HUDRopeState", 11, Enum.Font.GothamBlack, Color3.fromRGB(255, 235, 120))

		elseif kind == "countdown" then
			-- Sleek danger notice ribbon
			r.emblem = frame(o, "HUDWarningIcon")
			r.emblem.BackgroundTransparency = 1
			r.glyph = Glyphs.Draw(r.emblem, "warning")
			r.notice = label(o, "HUDCountdownNotice", 13, Enum.Font.GothamBlack, Color3.fromRGB(255, 250, 240), Color3.fromRGB(70, 20, 4), 2)
			r.notice.TextXAlignment = Enum.TextXAlignment.Center
			o.TextTransparency = 1

		elseif kind == "alert" then
			r.emblem = frame(o, "HUDWarningIcon")
			r.emblem.BackgroundTransparency = 1
			r.glyph = Glyphs.Draw(r.emblem, "warning")

		elseif kind == "reticle" then
			o.TextTransparency = 1
			r.glyph = Glyphs.Draw(o, "aim")

		elseif kind == "card" then
			r.artBox = frame(o, "HUDArtFrame")
			r.artBox.BackgroundTransparency = 1 -- 100% Transparent, no black box!
			r.artBox.BorderSizePixel = 0
			r.art = art(r.artBox)


		end
	end

	local function scan(o)
		if not o:IsA("GuiObject") or o.Name:sub(1, 3) == "HUD" then return end
		if o:IsA("TextButton") then
			if configs[o.Name] then
				build(o, "button", configs[o.Name])
			end
		elseif o.Name == "AltimeterFrame" then
			build(o, "alt")
		elseif o.Name == "StatusFrame" then
			build(o, "status")
		elseif o.Name == "WeaponFrame" then
			build(o, "weapon")
		elseif o.Name == "TetherFrame" then
			build(o, "tether")
		elseif o.Name == "GroundedCountdown" then
			build(o, "countdown")
		elseif o.Name == "AlertBanner" or o.Name == "StormChallengePanel" then
			build(o, "alert")
		elseif o.Name == "WeaponReticle" then
			build(o, "reticle")
		elseif o.Name == "Card1" or o.Name == "Card2" then
			build(o, "card")
		elseif surfaceKeys[o.Name] then
			build(o, "panel")
		end
	end

	for _, o in gui:GetDescendants() do scan(o) end
	connect(gui.DescendantAdded, scan)

	connect(Input.InputEnded, function(i)
		for _, r in records do
			if r.input == i or (r.input and i.UserInputType == Enum.UserInputType.MouseButton1 and r.input.UserInputType == i.UserInputType) then
				r.pressed = false
				r.input = nil
			end
		end
	end)
	connect(Input.WindowFocusReleased, function()
		for _, r in records do
			r.pressed = false
			r.input = nil
		end
	end)

	local function hide(o)
		if o and (o:IsA("TextLabel") or o:IsA("TextButton")) then
			o.TextTransparency = 1
		end
	end

	local function textStyle(o, maxSize, font)
		applyTextStyle(o, {
			font = font or Enum.Font.GothamBold,
			size = maxSize or 14,
			strokeThickness = 2,
		})
	end

	function state.Step()
		local compact = gui:GetAttribute("CompactLayout") == true
		local textBoost = gui:GetAttribute("HUDTextBoost") or 0
		local inFlight = player:GetAttribute("InFlight") == true
		local flightReady = gui:GetAttribute("FlightHUDReady") == true
		local status = gui:FindFirstChild("StatusFrame")
		local penalty = status and status:FindFirstChild("HolePenalty")
		local outcome = penalty and (penalty.Text == "GAME OVER" and "result_gameover"
			or penalty.Text:find("Tiba di Istana Awan", 1, true) and "result_victory")
		if outcome and outcome ~= lastResult then
			resultUntil = os.clock() + 4
			resultText.Text = outcome == "result_victory" and "Tiba di Istana Awan!" or "Penerbangan berakhir"
		end
		lastResult = outcome
		result.Visible = outcome ~= nil and outcome ~= false and os.clock() < resultUntil
		if result.Visible then
			local full = Adventure.Draw(result, outcome, result.ZIndex, "stretch")
			result.BackgroundTransparency = full and 1 or 0.1
		end
		for o, r in records do
			if not o:IsDescendantOf(gui) then
				for _, c in r.links do c:Disconnect() end
				records[o] = nil
				continue
			end

			local z = o.ZIndex
			local w, h = o.AbsoluteSize.X, o.AbsoluteSize.Y

			local background = surfaceKeys[o.Name]
			local fullPanel = false
			if background and r.kind ~= "status" then
				fullPanel = raster(o, background, z)
			end

			if r.kind == "button" then
				local cfg = r.config
				local key = cfg[1]
				local sprite = cfg[3]
				local title = cfg[2] or o.Text

				if o.Name == "WarningAudioToggleButton" then
					local muted = player:GetAttribute("WarningAudioMuted") == true
					key = muted and "muted" or "sound"
					sprite = muted and "audio_off" or "audio_on"
					if r.lastKey ~= key then
						r.glyph:Destroy()
						r.glyph = Glyphs.Draw(r.glyphBox, key)
						r.lastKey = key
					end
				elseif o.Name == "AutoGasButton" then
					local on = o.Text:find(": ON", 1, true) ~= nil
					title = on and "OTOMATIS: ON" or "OTOMATIS: OFF"
					sprite = on and "auto_on" or "auto_off"
				elseif o.Name == "EmergencyKitButton" then
					if o.Text:find("CLUTCH", 1, true) then
						sprite = "kit_clutch"
						title = "SAVE!"
					end
				end

				local purchase = o.Name == "BuyEmergencyKitButton" or o.Name == "BuyAK47Button"
				local reason = o:GetAttribute("HUDLockReason")
				if purchase then
					title = o.Text:match("(%d+ Robux)")
						or (o.Text:find("Gunakan Kredit", 1, true) and "Pakai kredit")
						or (o.Text:find("%.%.%.") and "Memuat…")
						or "Lihat harga"
				elseif sprite == "audio_off" then
					title = "BISU"
				elseif reason then
					title = reason
				elseif o.Name == "ReloadButton" then
					local weapon = gui:FindFirstChild("WeaponFrame")
					local ammo = weapon and weapon:FindFirstChild("AmmoLabel")
					if ammo and ammo.Text:match("^0%s*/") then title = "ISI ULANG" end
				end
				local style = cfg[4]
				local fullKey = fullButtons[sprite]
				local shade = not o.Active and 0.52 or r.pressed and 0.76 or 1
				if o.Name == "JumpButton" then
					fullKey = not o.Active and "jump_locked" or r.pressed and "jump_pressed" or "jump_normal"
					shade = 1
				elseif o.Name == "EmergencyKitButton" and reason == "Kit habis" then
					fullKey, shade = "kit_empty", 1
				end
				local pingChoice = o.Name:match("^Ping[1-5]$") ~= nil
				local complete, illustration = raster(o, sprite, z + 1, Color3.new(shade, shade, shade),
					fullKey, purchase and "stretch" or (style == "wide" and not pingChoice) and "wide" or "fit")
				-- The jump glyph falls back to a local arrow if its image also fails.
				r.glyphBox.Visible = not complete
				r.captionPill.Visible = style ~= "round"
				if complete and illustration then
					if pingChoice then
						illustration.Position = UDim2.fromOffset(3, 2)
						illustration.Size = UDim2.fromOffset(math.max(1, h - 4), math.max(1, h - 4))
					elseif style == "dock" or style == "tile" then
						illustration.Size = UDim2.new(1, 0, 1, -12 - textBoost)
					end
				end
				if style == "wide" then
					r.captionPill.BackgroundTransparency = 1
					local pStroke = r.captionPill:FindFirstChildOfClass("UIStroke")
					if pStroke then pStroke.Enabled = false end

					if o.Name == "AutoGasButton" then
						box(r.glyphBox, 12, (h - 26) / 2, 26, 26)
						box(r.captionPill, 44, 4, w - 50, h - 8)
						r.caption.TextWrapped = false
						applyTextStyle(r.caption, { font = Enum.Font.GothamBlack, size = 14, strokeThickness = 2, align = Enum.TextXAlignment.Center })
					else
						box(r.glyphBox, 12, (h - 26) / 2, 26, 26)
						box(r.captionPill, 44, 4, w - 50, h - 8)
						applyTextStyle(r.caption, { font = Enum.Font.GothamBlack, size = 14, strokeThickness = 2, align = Enum.TextXAlignment.Left })
					end
					if complete then
						local left = purchase and math.round(w * 0.26) or pingChoice and h + 7 or math.max(39, math.round(h * 1.15))
						box(r.captionPill, left, 4, math.max(1, w - left - 15), h - 8)
					end

				elseif style == "dock" then
					-- Left Toolbar: Icon sits in upper half with ample breathing room!
					local iconSize = 28
					box(r.glyphBox, (w - iconSize) / 2, 7, iconSize, iconSize)

					-- Pure transparent caption container (No black inner sticker box!)
					r.captionPill.BackgroundTransparency = 1
					local pStroke = r.captionPill:FindFirstChildOfClass("UIStroke")
					if pStroke then pStroke.Enabled = false end

					box(r.captionPill, 2, h - (complete and 16 or 21) - textBoost, w - 4, 15 + textBoost)
					applyTextStyle(r.caption, { font = Enum.Font.GothamBlack, size = 11, color = Color3.new(1, 1, 1), strokeThickness = 1.8, align = Enum.TextXAlignment.Center })

				elseif style == "round" then
					-- Circular action buttons: perfectly centered icon, NO rectangular caption pills!
					local iconSize = math.round(math.min(w, h) * 0.58)
					box(r.glyphBox, (w - iconSize) / 2, (h - iconSize) / 2, iconSize, iconSize)
					r.captionPill.Visible = false
					if o.Name == "JumpButton" and not complete then
						r.captionPill.Visible = true
						title = o.Active and "LOMPAT" or "TERKUNCI"
						box(r.glyphBox, (w - iconSize) / 2, (h - iconSize) / 2 - 6, iconSize, iconSize)
						box(r.captionPill, 4, h - 22, w - 8, 18)
					end

				else
					-- Standard square tile button (e.g. Gas, Reload, Drop)
					local iconSize = math.round(math.min(w, h) * 0.50)
					box(r.glyphBox, (w - iconSize) / 2, 6, iconSize, iconSize)

					r.captionPill.BackgroundTransparency = 1
					box(r.captionPill, 3, h - (complete and 16 or 21) - textBoost, w - 6, 15 + textBoost)
					applyTextStyle(r.caption, { font = Enum.Font.GothamBlack, size = 11, strokeThickness = 1.8, align = Enum.TextXAlignment.Center })
				end

				ztree(r.glyphBox, z + 3)
				ztree(r.captionPill, z + 4)
				r.caption.Text = title
				local captionH = math.min(r.captionPill.Size.Y.Offset, r.caption.TextSize + textBoost + 2)
				r.caption.AnchorPoint = Vector2.new(0.5, 0.5)
				r.caption.Position = UDim2.fromScale(0.5, 0.5)
				r.caption.Size = UDim2.new(1, -4, 0, math.max(1, captionH))
				fitLine(r.caption, textBoost)
				local fixed = title ~= "" and not purchase and not reason and title ~= "ISI ULANG"
				local lockKeys = {
					["Kit habis"]="kit_empty", ["Memuat kit"]="kit_loading",
					["Kit terpakai"]="kit_used", ["Perisai aktif"]="kit_shield", ["ISI ULANG"]="reload_empty",
				}
				letter(r.caption, fixed and sprite or lockKeys[title])

				local hint = o.Text:match("%[([^%]]+)%]")
				r.hint.Visible = not Input.TouchEnabled and hint ~= nil and #hint <= 7 and hint ~= "GUNAKAN"
				if r.hint.Visible then
					r.hint.Text = hint:match("^%w+") or ""
					box(r.hint, w - 20, 2, 18, 14)
					applyTextStyle(r.hint, { font = Enum.Font.GothamBlack, size = 10, color = Color3.fromRGB(255, 235, 120), strokeThickness = 1.5, align = Enum.TextXAlignment.Center })
				elseif o.Name == "JumpButton" and not Input.TouchEnabled then
					r.hint.Visible = true
					r.hint.Text = "SPACE"
					box(r.hint, 2, 2, 42, 15)
					applyTextStyle(r.hint, { font = Enum.Font.GothamBlack, size = 9, color = Color3.fromRGB(255, 235, 120), strokeThickness = 1.2, align = Enum.TextXAlignment.Center })
				end
				chip(r.hint, "hint", z + 5)
				if r.hint.Visible then
					letter(r.hint, "key_" .. r.hint.Text:lower())
				end

				-- Smart Notification Badge
				local cooldown = math.max(0, (player:GetAttribute("FlightJumpReadyAt") or 0) - workspace:GetServerTimeNow())
				if o.Name == "EmergencyKitButton" then
					local kits = player:GetAttribute("EmergencyKits") or 0
					if kits > 0 then
						r.badge.Visible = true
						r.badge.Text = tostring(kits)
						r.badge.BackgroundColor3 = Color3.fromRGB(36, 212, 85)
					else
						r.badge.Visible = false
					end
				elseif o.Name == "JumpButton" and not o.Active and not complete then
					r.badge.Visible = true
					r.badge.Text = "!"
				elseif o.Name == "JumpButton" and inFlight and cooldown > 0 then
					r.badge.Visible = true
					r.badge.Text = math.ceil(cooldown) .. "s"
					r.badge.BackgroundColor3 = Color3.fromRGB(255, 45, 80)
				else
					r.badge.Visible = false
				end

				if r.badge.Visible then
					box(r.badge, w - 18, -4, 22, 22)
					applyTextStyle(r.badge, { font = Enum.Font.GothamBlack, size = 11, strokeThickness = 1.5, align = Enum.TextXAlignment.Center })
				end
				chip(r.badge, o.Name == "JumpButton" and "badge_red" or "badge_green", z + 5)
				if r.badge.Visible then
					local digits = r.badge.Text:match("^(%d+)")
					meter(r.badge, digits, 17, nil, r.badge.Text:find("s", 1, true) and "meter_glyph_seconds_short" or nil)
				end

				o.TextTransparency = 1

			elseif r.kind == "alt" then
				local original = o:FindFirstChild("AltLabel")
				local bar = o:FindFirstChild("BarBg")
				local speed = o:FindFirstChild("VerticalSpeedLabel")

				if original and bar then
					local altitude = original.Text:match("Ketinggian:%s*(%d+)") or "0"
					hide(original)
					if speed then
						hide(speed)
						speed.BackgroundTransparency = 1
					end

					-- 1. Balloon Icon on Left (Pure transparency, perfectly centered!)
					local narrow = w < 380
					local iconSize = narrow and 32 or compact and 40 or 46
					box(r.emblem, 12, (h - iconSize) / 2, iconSize, iconSize)
					local loaded = use(r.art, "art_balloon")
					r.glyph.Visible = not loaded
					r.emblem.Visible = not fullPanel
					ztree(r.emblem, z + 3)

					local headingX = fullPanel and math.max(iconSize + 18, h + 4) or iconSize + 18
					local rightInset = 18
					local gap = 10
					local centerY = h / 2
					local stacked = narrow and inFlight
					local titleY = centerY - (stacked and 15 or 9) - textBoost / 2
					local detailY = centerY + (stacked and 3 or 9) + (stacked and 0 or textBoost / 2)
					local titleH = 24 + textBoost
					local detailH = 14 + textBoost
					local speedW = (narrow and 100 or 108) + 4 * textBoost
					local speedH = 24 + textBoost
					local speedX = w - rightInset - speedW

					local headingWidth = w - headingX - rightInset
					local goalWidth = headingWidth
					if inFlight then
						local formatted = altitude:reverse():gsub("(%d%d%d)", "%1."):reverse():gsub("^%.", "")
						r.head.Text = flightReady and (formatted .. ' <font color="#B9E7FF">km</font>') or "—"
						r.head.TextSize = w < 320 and 20 or 23
						r.goal.Text = "Istana Awan · 10.000 km"
						if stacked then
							headingWidth = speedX - gap - headingX
						else
							headingWidth = 138 + 5 * textBoost
							goalWidth = headingWidth
						end
					else
						local pod = player:GetAttribute("CurrentPod")
						local podLetter = pod and pod:match("^Pod_([A-E])$")
						r.head.Text = podLetter and "DERMAGA " .. podLetter or "FLY HIGH"
						r.head.TextSize = 20
						r.goal.Text = "Pilih dermaga"
						if podLetter then
							local crew = 0
							for _, member in Players:GetPlayers() do
								if member:GetAttribute("CurrentPod") == pod then crew += 1 end
							end
							local action = player:GetAttribute("IsMaster") and "Mulai penerbangan" or "Menunggu Master"
							r.goal.Text = string.format("%d/3 kru · %s", crew, action)
						end
					end
					box(r.head, headingX, titleY - titleH / 2, headingWidth, titleH)
					box(r.goal, headingX, detailY - detailH / 2, goalWidth, detailH)
					fitLine(r.head, textBoost)
					fitLine(r.goal, textBoost)
					r.head.ZIndex = z + 4
					r.goal.ZIndex = z + 4

					local vVal = o:GetAttribute("VerticalSpeed") or (speed and speed:GetAttribute("VerticalSpeed")) or 0
					local direction, value, color = "●", "0.0 km/s", Color3.fromRGB(147, 197, 253)
					if vVal >= 0.05 then
						direction, value, color = "▲", string.format("+%.1f km/s", vVal), Color3.fromRGB(74, 222, 128)
					elseif vVal <= -0.05 then
						direction, value, color = "▼", string.format("%.1f km/s", vVal), Color3.fromRGB(248, 113, 113)
					end
					r.speed.Text = flightReady and ('<font color="#D5EDFF">' .. direction .. '</font>  ' .. value) or "—"
					r.speed.TextColor3 = color
					box(r.speedPill, speedX, (stacked and titleY or centerY) - speedH / 2, speedW, speedH)
					-- Center the glyphs on the capsule face above its lower shadow.
					box(r.speed, 8, -3, speedW - 16, speedH)
					fitLine(r.speed, textBoost)
					r.speedPill.ZIndex = z + 4
					r.speedPill.Visible = inFlight
					raster(r.speedPill, "speed", z + 4)
					r.speed.ZIndex = z + 5

					-- Put the percentage over the track, or directly beside it on narrow screens.
					local barX = stacked and headingX or headingX + headingWidth + gap
					local percentW = 48 + 3 * textBoost
					local percentH = 16 + textBoost
					local barEnd = stacked and w - (rightInset + 6) - percentW - gap or speedX - gap
					local barWidth = math.max(1, barEnd - barX)
					local barY = stacked and centerY + 16 + textBoost / 2 or detailY
					box(bar, barX, barY - 4, barWidth, 8)
					if stacked then
						box(r.percent, barEnd + gap, barY - percentH / 2, percentW, percentH)
					else
						box(r.percent, barX, titleY - percentH / 2, barWidth, percentH)
					end
					local progressVisible = inFlight and flightReady
					r.percent.Text = original.Text:match("%((.-)%)") or "0%"
					fitLine(r.percent, textBoost)
					r.percent.Visible = progressVisible
					r.percent.ZIndex = z + 4
					bar.Visible = progressVisible
					bar.ZIndex = z + 3
					bar.BackgroundColor3 = Color3.fromRGB(6, 16, 32)
					bar.BackgroundTransparency = 0
					round(bar, 4)
					raster(bar, "track", z + 3)
					if not r.markerSlot then
						r.markerSlot = frame(bar, "HUDGoalMarkerSlot")
						r.markerSlot.AnchorPoint = Vector2.new(1, 0.5)
						r.markerSlot.Position = UDim2.fromScale(1, 0.5)
						r.markerSlot.Size = UDim2.fromOffset(12, 12)
					end
					r.markerSlot.ZIndex = z + 5
					Adventure.Draw(r.markerSlot, "goal_marker", z + 5, "fit")

					local fill = bar:FindFirstChild("BarFill")
					if fill then
						fill.BackgroundColor3 = Color3.fromRGB(0, 240, 140)
						fill.ZIndex = z + 4
						round(fill, 5)
						raster(fill, "progress", z + 4)
					end

				end

			elseif r.kind == "status" then
				local holesLabel = o:FindFirstChild("HoleIcons")
				local penalty = o:FindFirstChild("HolePenalty")
				local invuln = o:FindFirstChild("InvulnLabel")

				if holesLabel and penalty then
					local holes = math.clamp(o:GetAttribute("HoleCount") or 0, 0, 5)
					local health = 5 - holes
					local critical = holes >= 4 and Color3.fromRGB(250, 200, 206) or nil
					local fullHull = raster(o, holes >= 4 and "status_critical" or "status", z, critical)

					for _, name in { "HoleTitle", "HoleIcons", "HolePenalty", "InvulnLabel" } do
						hide(o:FindFirstChild(name))
					end

					r.head.Text = not flightReady and "MEMUAT KONDISI" or holes == 5 and "TERJUN BEBAS"
						or holes == 4 and "KRITIS" or holes == 0 and "BALON AMAN" or "KONDISI LAMBUNG"
					r.count.Text = flightReady and health .. " / 5" or "—"
					local hullInset = fullHull and 50 + textBoost or 14
					box(r.head, hullInset, 11, w - hullInset - 64 - textBoost, 16 + textBoost)
					box(r.count, w - 60 - textBoost, 10, 38 + textBoost, 18 + textBoost)
					applyTextStyle(r.head, { font = Enum.Font.GothamBlack, size = 12, wrapped = false, color = Color3.fromRGB(208, 235, 255), strokeThickness = 1, align = Enum.TextXAlignment.Left })
					applyTextStyle(r.count, { font = Enum.Font.GothamBlack, size = 11, color = holes == 0 and Color3.fromRGB(34, 197, 94) or Color3.fromRGB(239, 68, 68), strokeThickness = 1.5, align = Enum.TextXAlignment.Center })
					fitLine(r.head, textBoost)
					fitLine(r.count, textBoost)

					local py = 29 + textBoost
					local pipW = math.floor((w - hullInset - 30) / 5)
					for i, pip in r.pips do
						box(pip, hullInset + (i - 1) * (pipW + 2), py, pipW, 10)
						local intact = i <= (5 - holes)
						pip.Visible = flightReady
						pip.BackgroundColor3 = intact and Color3.fromRGB(36, 212, 85) or Color3.fromRGB(220, 32, 60)
						pip.ZIndex = z + 3
						local fullPip = raster(pip, intact and "hull_good" or "hull_broken", z + 3, nil, nil, "stretch")
						local fracture = pip:FindFirstChild("HUDBrokenIcon")
						if not fullPip and not intact and not fracture then
							fracture = Assets.Mount(pip, "icon_warning", true)
							fracture.Name = "HUDBrokenIcon"
							fracture.ZIndex = z + 4
						end
						if fracture then fracture.Visible = not fullPip and not intact end
					end

					local details = {
						[0] = "▲ Naik optimal",
						[1] = "▲ Naik melambat",
						[2] = "■ Gaya angkat seimbang",
						[3] = "▼ Turun 1,5×",
						[4] = "▼ Turun 2,5×",
						[5] = "▼ Terjun bebas",
					}
					local shield = invuln and invuln.Visible
					local terminal = penalty.Text == "GAME OVER" and "flight_lost"
						or (penalty.Text:find("Tiba di Istana Awan", 1, true) and "flight_won")
					r.detail.Text = terminal == "flight_lost" and "GAME OVER"
						or terminal == "flight_won" and "TIBA DI ISTANA AWAN!"
						or shield and invuln.Text:gsub("🛡️%s*", "") or details[holes]
					box(r.detail, hullInset, 41 + textBoost, w - hullInset - 22, 14 + textBoost)
					applyTextStyle(r.detail, { font = Enum.Font.GothamBold, size = 11, wrapped = false, color = shield and Color3.fromRGB(157, 228, 255) or holes == 0 and Color3.fromRGB(166, 255, 197) or Color3.fromRGB(255, 190, 180), strokeThickness = 1, align = Enum.TextXAlignment.Left })
					fitLine(r.detail, textBoost)

					r.head.ZIndex = z + 3
					chip(r.count, "counter", z + 3)
					r.detail.ZIndex = z + 3
					local conditionKey = not flightReady and "hull_loading" or holes == 5 and "hull_freefall"
						or holes == 4 and "hull_critical" or (holes == 0 and "hull_safe" or "hull_damage")
					letter(r.head, conditionKey or nil)
					letter(r.count)
					r.detail.Visible = flightReady
					letter(r.detail, terminal or (not shield and "hull_" .. holes or nil))
				end

			elseif r.kind == "weapon" then
				local name = o:FindFirstChild("WeaponName")
				local ammo = o:FindFirstChild("AmmoLabel")

				if name and ammo then
					hide(name)
					hide(ammo)
					hide(o:FindFirstChild("DropTip"))

					local weaponName = name.Text:find("AK", 1, true) and "AK-47" or "PISTOL"
					r.head.Text = weaponName
					applyTextStyle(r.head, { font = Enum.Font.GothamBlack, size = 12, color = Color3.fromRGB(255, 220, 90), strokeThickness = 1.8, align = Enum.TextXAlignment.Left })

					local curAmmo = ammo.Text:match("^%s*(%d+)%s*/")
					r.ammo.Text = curAmmo and (curAmmo .. ' <font color="#B8D5EE">/ ∞</font>') or "MENGISI"
					applyTextStyle(r.ammo, { font = Enum.Font.GothamBlack, size = curAmmo and (compact and 19 or 23) or 13, rich = true, wrapped = false, strokeThickness = 1.5, align = Enum.TextXAlignment.Center, valign = Enum.TextYAlignment.Center })

					local capacity = ammo:GetAttribute("MagazineCapacity")
					r.magazine.Text = capacity and string.format(compact and "MAG: %d" or "MAGAZEN: %d", capacity) or ""
					applyTextStyle(r.magazine, { font = Enum.Font.GothamBold, size = 11, color = Color3.fromRGB(160, 200, 240), strokeThickness = 1.5, align = Enum.TextXAlignment.Left })

					local textInset = fullPanel and math.round(h * 1.06) or 54
					local ammoWidth = (compact and 62 or 72) + 4 * textBoost
					local ammoRight = w - 22
					local textWidth = math.max(1, ammoRight - ammoWidth - textInset - 8)
					box(r.head, textInset, h / 2 - 16 - textBoost, textWidth, 16 + textBoost)
					box(r.magazine, textInset, h / 2 + 1, textWidth, 13 + textBoost)
					box(r.ammo, ammoRight - ammoWidth, h / 2 - 14 - textBoost / 2, ammoWidth, 28 + textBoost)
					fitLine(r.head, textBoost)
					fitLine(r.magazine, textBoost)
					fitLine(r.ammo, textBoost)
					r.magazine.Visible = w >= 180

					box(r.emblem, 10, compact and 8 or 14, 38, 30)
					r.glyph.Visible = not use(r.art, weaponName == "AK-47" and "art_rifle" or "art_pistol")
					r.emblem.Visible = not fullPanel
					ztree(r.emblem, z + 3)

					r.head.ZIndex = z + 3
					r.ammo.ZIndex = z + 3
					r.magazine.ZIndex = z + 3
					letter(r.head, weaponName == "AK-47" and "rifle" or "pistol")
					letter(r.magazine)
					letter(r.ammo)
				end

			elseif r.kind == "tether" then
				local original = o:FindFirstChild("TetherLabel")
				local bar = o:FindFirstChild("TBarBg")
				if original and bar then
					hide(original)
					r.head.Text = original.Text:gsub("Tali Pengaman: ", "TALI: ")
					local ropeInset = fullPanel and 42 or 10
					box(r.head, ropeInset, 4, w - ropeInset - 14, 13 + textBoost)
					applyTextStyle(r.head, { font = Enum.Font.GothamBlack, size = 11, color = Color3.fromRGB(255, 235, 120), strokeThickness = 1.8 })
					fitLine(r.head, textBoost)
					r.head.ZIndex = z + 3
					box(bar, ropeInset, h - 11, w - ropeInset - 14, 5)
					bar.ZIndex = z + 3
					round(bar, 3)
					raster(bar, "track", z + 3)
					local fill = bar:FindFirstChild("TBarFill")
					if fill then
						fill.ZIndex = z + 4
						round(fill, 3)
						raster(fill, "rope_fill", z + 4, fill.BackgroundColor3:Lerp(Color3.new(1, 1, 1), 0.6))
					end
				end

			elseif r.kind == "countdown" then
				-- Sleek danger warning ribbon

				local iconSize = 18
				box(r.emblem, 12, (h - iconSize) / 2, iconSize, iconSize)
				ztree(r.emblem, z + 3)
				r.emblem.Visible = not fullPanel

				r.notice.Text = o.Text
				local inset = fullPanel and math.round(h * 1.05) or 36
				box(r.notice, inset, 2, w - inset - 15, h - 4)
				applyTextStyle(r.notice, { font = Enum.Font.GothamBlack, size = w < 300 and 13 or 14, color = Color3.fromRGB(255, 250, 240), strokeColor = Color3.fromRGB(70, 20, 4), strokeThickness = 2, align = Enum.TextXAlignment.Left })
				r.notice.ZIndex = z + 4
				fitLine(r.notice, textBoost)
				local seconds = gui:GetAttribute("HUDGroundedSeconds")
				local pilot = o.Text:find("Tahan gas", 1, true) ~= nil
				meter(r.notice, seconds and tostring(seconds) or nil, 20, pilot and "meter_ground_pilot" or "meter_ground_crew", "meter_glyph_seconds_short")
				o.TextTransparency = 1

			elseif r.kind == "alert" then
				box(r.emblem, 10, 10, 26, 26)
				ztree(r.emblem, z + 3)
				r.emblem.Visible = not fullPanel
				local title = o:FindFirstChild("AlertTitle") or o:FindFirstChild("Title")
				local detail = o:FindFirstChild("AlertDesc") or o:FindFirstChild("Detail")
				local alertInset = fullPanel and math.round(math.min(h * 1.04, w * 0.25)) or 44
				if title then
					box(title, alertInset, 6, w - alertInset - 16, 22)
					applyTextStyle(title, { font = Enum.Font.GothamBlack, size = 15, strokeThickness = 2 })
					title.ZIndex = z + 3
				end
				if detail then
					local detailInset = fullPanel and alertInset or 12
					box(detail, detailInset, 32, w - detailInset - 18, h - 38)
					applyTextStyle(detail, { font = Enum.Font.GothamBold, size = 12, strokeThickness = 1.5 })
					detail.ZIndex = z + 3
				end

			elseif r.kind == "card" then
				o.ZIndex = z
				r.artBox.Visible = not fullPanel
				box(r.artBox, (w - 78) / 2, 12, 78, math.min(78, h * 0.4))
				ztree(r.artBox, z + 2)
				if not fullPanel then
					use(r.art, o.Name == "Card1" and "art_kit" or "art_rifle")
				end

				local titleY = math.round(h * 0.49)
				for _, child in o:GetChildren() do
					if child:IsA("TextLabel") and child.Name:sub(1, 3) ~= "HUD" then
						child.ZIndex = z + 3
						local productTitle = child:GetAttribute("HUDProductTitle")
						if productTitle == nil then
							productTitle = child.Position.Y.Offset < 30
							child:SetAttribute("HUDProductTitle", productTitle)
						end
						if productTitle then
							child.Text = o.Name == "Card1" and "Emergency Kit" or "Upgrade AK-47"
							box(child, 10, titleY, w - 20, 22)
							applyTextStyle(child, { font = Enum.Font.GothamBlack, size = 15, color = Color3.fromRGB(255, 225, 90), strokeThickness = 2, wrapped = false })
						else
							child.Text = o.Name == "Card1" and "Tambal semua lubang, termasuk saat terjun bebas. Kebal 60 dtk. 1× per terbang."
								or "Ubah dua rak menjadi AK-47. 30 peluru. Khusus Party Master."
							box(child, 12, titleY + 22, w - 24, math.max(22, h - titleY - 78))
							applyTextStyle(child, { font = Enum.Font.GothamBold, size = 12, color = Color3.fromRGB(215, 230, 250), strokeThickness = 1.2, align = Enum.TextXAlignment.Left })
						end
					elseif child:IsA("TextButton") then
						child.ZIndex = z + 4
						box(child, 8, h - 54, w - 16, 44)
					end
				end

			elseif r.kind == "reticle" then
				ztree(r.glyph, z + 2)

			elseif r.kind == "panel" then
				o.ZIndex = z
				local title = o:FindFirstChild("ModalTitle")
				if title then
					title.Text = "TOKO PERBEKALAN"
					applyTextStyle(title, { font = Enum.Font.GothamBlack, size = 18, color = Color3.fromRGB(255, 220, 80), strokeThickness = 2.5, align = Enum.TextXAlignment.Center })
					box(title, 63, h < 330 and 28 or 37, w - 126, 25)
					title.ZIndex = z + 3
					letter(title, "shop_title", 22)
				end
				local feedback = o:FindFirstChild("ShopFeedback")
				if feedback then
					applyTextStyle(feedback, { font = Enum.Font.GothamBold, size = 11, strokeThickness = 1.5, align = Enum.TextXAlignment.Center })
					feedback.ZIndex = z + 3
					local card = o:FindFirstChild("Card1")
					local y = card and (card.Position.Y.Offset + card.Size.Y.Offset + 4) or h - 28
					box(feedback, 26, y, w - 52, 25)
				end
			end
		end
	end

	function state.Destroy()
		if not alive then return end
		alive = false
		for _, c in links do c:Disconnect() end
		for _, r in records do
			for _, c in r.links do c:Disconnect() end
		end
		table.clear(records)
	end

	connect(gui.Destroying, state.Destroy)
	return state
end

return Theme
