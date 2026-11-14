-- Image-backed Sky Adventure presentation. Controllers own input and game state.
local Assets = require(script.Parent.HUDImageAssets)
local Glyphs = require(script.Parent.HUDGlyphs)
local Adventure = require(script.Parent.HUDAdventureArt)
local AdventureCatalog = require(script.Parent.HUDAdventureCatalog)
local Input = game:GetService("UserInputService")
local Players = game:GetService("Players")

local AudioMixer = require(script.Parent.AudioMixer)
local Motion = require(script.Parent.HUDMotion)
local AltitudeTracker = require(script.Parent.HUDAltitudeTracker)
local FlyHighConfig = require(script.Parent.FlyHighConfig)
local Theme = {}

local BIOME_ZONES = {
	{ title = "LANGIT CERAH", zone = "Zona 1" },
	{ title = "AWAN MENDUNG", zone = "Zona 2" },
	{ title = "PULAU SENJA", zone = "Zona 3" },
	{ title = "LANGIT BINTANG", zone = "Zona 4" },
	{ title = "GERBANG SURGAWI", zone = "Zona 5" },
}

-- {1: GlyphKey, 2: FallbackTitle, 3: Sprite, 4: Style ("dock", "round", "wide", "tile")}
local configs = {
	ShopToggleButton = { "shop", "TOKO", "shop_toggle", "dock" },
	DailyToggleButton = { "daily", "HARIAN", "daily_toggle", "dock" },
	SettingsToggleButton = { "settings", "SETELAN", "buy_rifle", "dock" },
	EmergencyKitButton = { "kit", "KIT", "kit_use", "dock" },
	TurboGasButton = { "turbo", "TURBO", "turbo_toggle", "dock" },
	RopeBuffButton = { "rope", "TALI", "rope_toggle", "dock" },
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
	BuyAK47Button = { "weapon", "BELI 1 AK-47", "buy_rifle", "wide" },
	SpotHazardButton = { "warning", "TANDAI BAHAYA", "spot", "wide" },
	CloseButton = { "close", "", "close", "round" },
	DailyCloseButton = { "close", "", "close", "round" },
	SettingsCloseButton = { "close", "", "close", "round" },
	AudioCloseButton = { "close", "", "close", "round" },
	PingCloseButton = { "close", "", "close", "round" },
	Ping1 = { "gas", "Gas Api Sekarang!", "ping1", "ping" },
	Ping2 = { "warning", "Awas Tornado Menghindar!", "ping2", "ping" },
	Ping3 = { "rope", "Tali Saya Mau Habis!", "ping3", "ping" },
	Ping4 = { "repair", "Saya yang Perbaiki!", "ping4", "ping" },
	Ping5 = { "aim", "Fokus Tembak Rintangan!", "ping5", "ping" },
}

local fullButtons = {
	shop_toggle = "shop_normal", daily_toggle = "daily_normal", turbo_toggle = "turbo_normal", rope_toggle = "rope_normal",
	kit_use = "kit_normal", kit_clutch = "kit_clutch",
	ping_toggle = "ping_normal", audio_on = "sound_on", audio_off = "sound_off",
	shoot = "fire_normal", jump = "jump_normal", gas = "gas_normal",
	auto_off = "auto_off", auto_on = "auto_on", release = "release_helm_normal",
	reload = "reload_v2", drop = "drop_normal", attach = "tether_attach",
	detach = "tether_detach", climb = "tether_climb", descend = "tether_descend",
	patch = "tether_patch", repair_rope = "tether_repair_rope", pull = "tether_pull",
	buy_kit = "buy_button", buy_rifle = "buy_button", close = "btn_close_v2",
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

local pingMessageIcons = {
	["Gas Api Sekarang!"] = "ping_thrust",
	["Awas Tornado Menghindar!"] = "ping_danger",
	["Tali Saya Mau Habis!"] = "ping_rope",
	["Saya yang Perbaiki!"] = "ping_repair",
	["Fokus Tembak Rintangan!"] = "ping_target",
}

-- Crop the transparent padding from the dock sprites. The kit states retain
-- the same framing so swapping state never changes the visible button size.
local dockCrops = {
	kit_normal = Rect.new(17, 24, 236, 247),
	kit_empty = Rect.new(17, 24, 236, 247),
	kit_clutch = Rect.new(17, 24, 236, 247),
	ping_normal = Rect.new(3, 3, 253, 252),
	sound_on = Rect.new(3, 3, 252, 253),
	sound_off = Rect.new(3, 4, 253, 253),
	shop_normal = Rect.new(4, 3, 253, 253),
	daily_normal = Rect.new(4, 4, 252, 252),
	turbo_normal = Rect.new(4, 4, 252, 252),
	rope_normal = Rect.new(4, 4, 252, 252),
	settings_normal = Rect.new(3, 3, 253, 253),
}

local function box(o, x, y, w, h)
	if not o then return end
	o.Position = UDim2.fromOffset(math.round(x), math.round(y))
	o.Size = UDim2.fromOffset(math.round(w), math.round(h))
end

local function frame(parent, name)
	parent = Motion.Visual(parent)
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
	end
	lbl.TextWrapped = opts.wrapped ~= false
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

-- Keep text cleanly constrained inside its container while honoring text preference.
local function fitLine(lbl, textBoost, minSize)
	local constraint = lbl:FindFirstChildOfClass("UITextSizeConstraint")
	if not constraint then
		constraint = Instance.new("UITextSizeConstraint")
		constraint.Parent = lbl
	end
	local floorSize = minSize or 9
	constraint.MinTextSize = floorSize
	constraint.MaxTextSize = math.max(floorSize, lbl.TextSize + textBoost)
	lbl.TextTruncate = Enum.TextTruncate.None
	lbl.TextScaled = true
end

local function label(parent, name, size, font, color, strokeColor, strokeThickness)
	parent = Motion.Visual(parent)
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
	DailyLoginModal = "ping_panel",
	WeaponSettingsModal = "ping_panel",
	AudioSettingsModal = "ping_panel",
	TacticalPingWheel = "ping_panel",
	GhostSpotterFrame = "spot_panel",
	CrewPingBanner = "hint",
	Card1 = "kit_card",
	Card2 = "rifle_card",
}

local unreadySince = setmetatable({}, { __mode = "k" })

local function isGuiTreeVisible(o)
	local cur = o
	while cur do
		if cur:IsA("ScreenGui") then
			return cur.Enabled
		elseif cur:IsA("GuiObject") then
			if not cur.Visible then return false end
		end
		cur = cur.Parent
	end
	return false
end

local function raster(o, key, z, tint, completeKey, mode)
	local buttonOwner = o:IsA("GuiButton") and o or nil
	if buttonOwner then o.BackgroundTransparency=1 o=Motion.Visual(o) end
	local adventureKey = completeKey or adventurePanels[key]
	local complete, adventureImage = Adventure.Draw(o, adventureKey, z,
		mode or ((o:IsA("ScrollingFrame") or key == "shop_panel" or key == "ping_panel" or key == "kit_card" or key == "rifle_card") and "stretch" or "wide"), tint)
	local image = o:FindFirstChild("HUDRaster",true)
	local loaded = complete
	if complete then
		if image then image.Visible = false end
	elseif Assets.Has(key) then
		if not image then image = Assets.Mount(o, key) end
		loaded = Assets.Apply(image, key)
		Assets.Surface(image, key, o.Name=="HUDMotionVisual" and o.Parent.AbsoluteSize or o.AbsoluteSize)
		image.Visible = true
		image.ZIndex = z
		image.ImageColor3 = tint or Color3.new(1, 1, 1)
		if o:IsA("ScrollingFrame") then
			image.Position = UDim2.fromOffset(o.CanvasPosition.X, o.CanvasPosition.Y)
			image.Size = UDim2.fromOffset(o.AbsoluteWindowSize.X, o.AbsoluteWindowSize.Y)
		end
	else
		if image then image.Visible = false end
	end
	local showFallback = false
	if loaded then
		unreadySince[o] = nil
	else
		local hasCatalogArt = adventureKey ~= nil and AdventureCatalog[adventureKey] ~= nil
		if not hasCatalogArt then
			showFallback = true
		elseif isGuiTreeVisible(buttonOwner or o) then
			local now = os.clock()
			local startedAt = unreadySince[o]
			if not startedAt then
				unreadySince[o] = now
			elseif now - startedAt >= 0.5 then
				showFallback = true
			end
		else
			unreadySince[o] = nil
		end
	end
	o.BackgroundTransparency = showFallback and 0.12 or 1
	local outline = o:FindFirstChildOfClass("UIStroke")
	if outline and outline.ApplyStrokeMode == Enum.ApplyStrokeMode.Border then outline.Enabled = showFallback end
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
local pingTileColors = {
	Ping1 = Color3.fromRGB(234, 88, 12),
	Ping2 = Color3.fromRGB(220, 38, 38),
	Ping3 = Color3.fromRGB(217, 119, 6),
	Ping4 = Color3.fromRGB(5, 150, 105),
	Ping5 = Color3.fromRGB(2, 132, 199),
}

local modalPanelSet = {
	ShopModal = true,
	DailyLoginModal = true,
	WeaponSettingsModal = true,
	AudioSettingsModal = true,
	TacticalPingWheel = true,
}

local function applyModalChrome(o, frameKey, crestKey, z)
	o.ClipsDescendants = false
	for _, legacyName in { "HUDRaster", "HUDAdventureRaster" } do
		local legacy = o:FindFirstChild(legacyName)
		if legacy and legacy:IsA("GuiObject") then legacy.Visible = false end
	end
	local sliceCenter = Rect.new(88, 84, 232, 236)
	local loaded, frameImg = Adventure.DrawSlice(o, frameKey, z, sliceCenter, 0.5, "HUDModalFrame")
	if frameImg then
		frameImg.Position = UDim2.fromOffset(-4, -3)
		frameImg.Size = UDim2.new(1, 8, 1, 9)
	end
	local oldStroke = o:FindFirstChildOfClass("UIStroke")
	if oldStroke then oldStroke.Enabled = not loaded end
	o.BackgroundColor3 = frameKey == "modal_frame_crimson_9slice" and Color3.fromRGB(36, 18, 44) or Color3.fromRGB(10, 30, 74)
	o.BackgroundTransparency = loaded and 1 or 0.06

	local crest = o:FindFirstChild("HUDModalCrest")
	if not crest then
		crest = Instance.new("ImageLabel")
		crest.Name = "HUDModalCrest"
		crest.BackgroundTransparency = 1
		crest.BorderSizePixel = 0
		crest.Active = false
		crest.Selectable = false
		crest.ScaleType = Enum.ScaleType.Fit
		local ratio = Instance.new("UIAspectRatioConstraint")
		ratio.AspectRatio = 408 / 168
		ratio.Parent = crest
		crest.Parent = o
	end
	local sprite = AdventureCatalog[crestKey]
	if sprite and crest:GetAttribute("HUDCrestKey") ~= crestKey then
		crest.Image = sprite[1]
		crest:SetAttribute("HUDCrestKey", crestKey)
	end
	local crestH = o.Name == "HUDFlightResult" and 62 or (o.AbsoluteSize.Y > 0 and o.AbsoluteSize.Y < 395 and 56 or 68)
	crest.AnchorPoint = Vector2.new(0.5, 0.5)
	crest.Position = UDim2.new(0.5, 0, 0, 4)
	crest.Size = UDim2.fromOffset(math.round(crestH * (408 / 168)), crestH)
	crest.ZIndex = z + 6
	crest.Visible = true
end

local function ensurePanelChild(parent, className, name, setup)
	local obj = parent:FindFirstChild(name)
	if not obj then
		obj = Instance.new(className)
		obj.Name = name
		if obj:IsA("GuiObject") then
			obj.Active = false
			obj.BorderSizePixel = 0
		end
		obj.Parent = parent
		if setup then setup(obj) end
	end
	return obj
end

	local result = frame(gui, "HUDFlightResult")
	result.AnchorPoint = Vector2.new(0.5, 0.5)
	result.Position = UDim2.fromScale(0.5, 0.44)
	result.Size = UDim2.new(0.84, 0, 0, 174)
	result.ClipsDescendants = false
	local resultSize = Instance.new("UISizeConstraint")
	resultSize.MinSize = Vector2.new(280, 152)
	resultSize.MaxSize = Vector2.new(450, 174)
	resultSize.Parent = result
	result.BackgroundColor3 = Color3.fromRGB(14, 37, 66)
	result.ZIndex = 17
	result.Visible = false
	round(result, 18)
	local resultText = label(result, "HUDResultTitle", 22, Enum.Font.GothamBlack, Color3.fromRGB(254, 240, 138))
	resultText.Position = UDim2.new(0, 26, 0, 42)
	resultText.Size = UDim2.new(1, -52, 0, 32)
	resultText.ZIndex = 20
	local resultSub = label(result, "HUDResultSubtitle", 13, Enum.Font.GothamBold, Color3.fromRGB(224, 242, 254))
	resultSub.Position = UDim2.new(0, 26, 0, 76)
	resultSub.Size = UDim2.new(1, -52, 0, 24)
	resultSub.ZIndex = 20
	local resultPill = frame(result, "HUDResultPill")
	resultPill.AnchorPoint = Vector2.new(0.5, 0)
	resultPill.Position = UDim2.new(0.5, 0, 0, 110)
	resultPill.Size = UDim2.fromOffset(224, 28)
	resultPill.BackgroundTransparency = 0
	resultPill.ZIndex = 20
	round(resultPill, 14)
	stroke(resultPill, Color3.fromRGB(52, 211, 153), 1.4, 0.1)
	local resultPillLbl = label(resultPill, "HUDResultPillLabel", 12, Enum.Font.GothamBlack, Color3.fromRGB(167, 243, 208))
	resultPillLbl.Size = UDim2.new(1, -16, 1, 0)
	resultPillLbl.Position = UDim2.fromOffset(8, 0)
	resultPillLbl.ZIndex = 21
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
			if config[1] == "settings" then
				r.glyph = label(r.glyphBox, "HUDSettingsGear", 26, Enum.Font.GothamBlack,
					Color3.fromRGB(255, 244, 208), Color3.fromRGB(21, 38, 65), 2.5)
				r.glyph.Text = "⚙"
				r.glyph.TextScaled = true
			else
				r.glyph = Glyphs.Draw(r.glyphBox, config[1])
			end

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

			r.divider = frame(o, "HUDTopDivider")
			r.divider.BackgroundColor3 = Color3.fromRGB(45, 92, 152)
			r.divider.BackgroundTransparency = 0.25

			-- Dedicated Speed Telemetry Pill Box & Label (Option B emerald/crimson/navy capsule)
			r.speedPill = frame(o, "HUDSpeedPill")
			r.speedPill.BackgroundColor3 = Color3.fromRGB(6, 16, 34)
			r.speedPill.BackgroundTransparency = 0.08
			round(r.speedPill, 999)
			local pillStroke = stroke(r.speedPill, Color3.fromRGB(56, 189, 248), 1.4)
			pillStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			r.speedStroke = pillStroke

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

		elseif kind == "ping_banner" then
			r.emblem = frame(o, "HUDPingEmblem")
			r.emblem.BackgroundTransparency = 1
			r.glyph = Glyphs.Draw(r.emblem, "ping")
			r.sender = label(o, "HUDPingSender", 11, Enum.Font.GothamBlack, Color3.fromRGB(132, 232, 255), Color3.fromRGB(4, 10, 24), 1.6)
			r.sender.TextXAlignment = Enum.TextXAlignment.Left
			r.sender.TextWrapped = false
			r.sender.TextTruncate = Enum.TextTruncate.AtEnd
			r.message = label(o, "HUDPingMessage", 15, Enum.Font.GothamBlack, Color3.new(1, 1, 1), Color3.fromRGB(4, 10, 24), 1.8)
			r.message.TextXAlignment = Enum.TextXAlignment.Left
			r.message.TextWrapped = false
			table.insert(r.links, o:GetAttributeChangedSignal("PingSeq"):Connect(function()
				local z = o.ZIndex
				local w, h = o.AbsoluteSize.X, o.AbsoluteSize.Y
				if w < 1 or h < 1 then return end
				local isGhost = o:GetAttribute("PingKind") == "ghost"
				local fullPanel = raster(o, isGhost and "alert" or "hint", z, nil, isGhost and "warning_critical" or "nameplate")
				local msg = o:GetAttribute("PingMessage") or ""
				local sender = o:GetAttribute("PingSender") or (isGhost and "Arwah" or "Kru")
				r.sender.Text = (isGhost and "ARWAH • " or "KRU • ") .. sender
				r.sender.TextColor3 = isGhost and Color3.fromRGB(255, 224, 130) or Color3.fromRGB(132, 232, 255)
				r.message.Text = msg
				if isGhost then
					r.emblem.Visible = not fullPanel
					if r.glyph then r.glyph.Visible = not fullPanel end
					local iconImg = r.emblem:FindFirstChild("HUDAdventureRaster")
					if iconImg then iconImg.Visible = false end
				else
					r.emblem.Visible = true
					local ready = Adventure.Draw(r.emblem, pingMessageIcons[msg] or "ping_normal", z + 4, "fit")
					if r.glyph then r.glyph.Visible = not ready end
				end
			end))

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
		elseif o.Name == "CrewPingBanner" then
			build(o, "ping_banner")
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

	local lastStepAt = os.clock()

	function state.Step()
		local now = os.clock()
		local dt = math.clamp(now - lastStepAt, 1 / 240, 0.1)
		lastStepAt = now
		local compact = gui:GetAttribute("CompactLayout") == true
		local textBoost = gui:GetAttribute("HUDTextBoost") or 0
		local inFlight = player:GetAttribute("InFlight") == true

		local trackerFrame = gui:FindFirstChild("ServerAltitudeTracker")
		if trackerFrame and trackerFrame:IsA("Frame") and trackerFrame.Visible then
			AltitudeTracker.Step(trackerFrame, dt, compact, textBoost)
		end
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local palace = not inFlight and workspace:FindFirstChild("CloudPalace")
		local terrace = palace and palace:FindFirstChild("GoldenRim")
		local offset = root and terrace and terrace.CFrame:PointToObjectSpace(root.Position)
		local atPalace = offset and math.abs(offset.X) <= terrace.Size.X / 2 + 10
			and math.abs(offset.Z) <= terrace.Size.Z / 2 + 12 and offset.Y >= -3 and offset.Y <= 55
		local flightReady = gui:GetAttribute("FlightHUDReady") == true
		local status = gui:FindFirstChild("StatusFrame")
		local penalty = status and status:FindFirstChild("HolePenalty")
		local outcome = penalty and (penalty.Text == "GAME OVER" and "result_gameover"
			or penalty.Text:find("Tiba di Istana Awan", 1, true) and "result_victory")
		if outcome and outcome ~= lastResult then
			resultUntil = os.clock() + 4
			local won = outcome == "result_victory"
			resultText.Text = won and "TIBA DI ISTANA AWAN!" or "GAME OVER"
			resultText.TextColor3 = won and Color3.fromRGB(254, 240, 138) or Color3.fromRGB(252, 165, 165)
			resultSub.Text = won and "Selamat! Kru berhasil mencapai puncak langit 10.000 km" or "Balon tidak selamat di tengah badai"
			resultSub.TextColor3 = won and Color3.fromRGB(224, 242, 254) or Color3.fromRGB(254, 205, 211)
			resultPill.BackgroundColor3 = won and Color3.fromRGB(6, 78, 59) or Color3.fromRGB(127, 29, 29)
			local pStroke = resultPill:FindFirstChildOfClass("UIStroke")
			if pStroke then
				pStroke.Color = won and Color3.fromRGB(52, 211, 153) or Color3.fromRGB(248, 113, 113)
			end
			resultPillLbl.Text = won and "✓  PENERBANGAN SUKSES" or "BALON HANCUR  ·  COBA LAGI"
			resultPillLbl.TextColor3 = won and Color3.fromRGB(167, 243, 208) or Color3.fromRGB(254, 202, 202)
		end
		lastResult = outcome
		result.Visible = outcome ~= nil and outcome ~= false and os.clock() < resultUntil
		if result.Visible then
			local won = outcome == "result_victory"
			applyModalChrome(result, won and "modal_frame_9slice" or "modal_frame_crimson_9slice", won and "crest_victory" or "crest_gameover", 17)
			applyTextStyle(resultText, { font = Enum.Font.GothamBlack, size = 22, color = resultText.TextColor3, strokeThickness = 2.4, wrapped = false, align = Enum.TextXAlignment.Center })
			fitLine(resultText, textBoost, 13)
			applyTextStyle(resultSub, { font = Enum.Font.GothamBold, size = 13, color = resultSub.TextColor3, strokeThickness = 1.4, wrapped = false, align = Enum.TextXAlignment.Center })
			fitLine(resultSub, textBoost, 9)
			applyTextStyle(resultPillLbl, { font = Enum.Font.GothamBlack, size = 12, color = resultPillLbl.TextColor3, strokeThickness = 1.2, wrapped = false, align = Enum.TextXAlignment.Center })
			fitLine(resultPillLbl, math.min(2, textBoost), 9)
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
			local completeKey
			if o.Name == "CrewPingBanner" then
				local isGhost = o:GetAttribute("PingKind") == "ghost"
				background = isGhost and "alert" or "hint"
				completeKey = isGhost and "warning_critical" or "nameplate"
			end
			if r.kind == "card" and h < 236 then background = "speed" end
			local fullPanel = false
			if background and r.kind ~= "status" and r.kind ~= "card" and not modalPanelSet[o.Name] then
				fullPanel = raster(o, background, z, nil, completeKey, nil)
			end

			if r.kind == "button" then
				local cfg = r.config
				local key = cfg[1]
				local sprite = cfg[3]
				local title = cfg[2] or o.Text

				if o.Name == "WarningAudioToggleButton" then
					local muted = AudioMixer.IsOverallMuted(player)
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
					title = o.Text:find("Gunakan Kredit", 1, true) and "Pakai Kredit Gratis"
						or (o.Text:find("%.%.%.") and "Memuat…")
						or (o.Text:find("Robux", 1, true) and o.Text)
						or (o.Text:find("lihat harga", 1, true) and (o.Name == "BuyEmergencyKitButton" and "Beli 1 Kit • Cek Harga" or "Beli 1 AK-47 • Cek Harga"))
						or o.Text
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
				local fullKey = key == "settings" and "settings_normal" or fullButtons[sprite]
				local shade = not o.Active and 0.52 or r.pressed and 0.76 or 1
				if o.Name == "JumpButton" then
					fullKey = not o.Active and "jump_locked" or r.pressed and "jump_pressed" or "jump_normal"
					shade = 1
				elseif o.Name == "EmergencyKitButton" and reason == "Kit habis" then
					fullKey, shade = "kit_empty", 1
				end
				local complete, illustration = false, nil
				if not purchase and style ~= "ping" then
					complete, illustration = raster(o, sprite, z + 1, Color3.new(shade, shade, shade),
						fullKey, style == "wide" and "wide" or "fit")
				else
					o.BackgroundTransparency = 1
					local vis = Motion.Visual(o)
					local oldR = vis:FindFirstChild("HUDRaster")
					if oldR and oldR:IsA("GuiObject") then oldR.Visible = false end
					local oldAR = vis:FindFirstChild("HUDAdventureRaster")
					if oldAR and oldAR:IsA("GuiObject") then oldAR.Visible = false end
				end
				-- The jump glyph falls back to a local arrow if its image also fails.
				r.glyphBox.Visible = not complete and not purchase and style ~= "ping"
				r.captionPill.Visible = style ~= "round"
				if complete and illustration then
					if style == "tile" then
						illustration.Size = UDim2.new(1, 0, 1, -12 - textBoost)
					end
				end
				if style == "ping" then
					local visual = Motion.Visual(o)
					local vStroke = visual:FindFirstChildOfClass("UIStroke")
					if vStroke then vStroke.Enabled = false end
					local pingFill = ensurePanelChild(visual, "Frame", "HUDPingFill", function(f)
						f.BackgroundColor3 = Color3.new(1, 1, 1)
						f.BackgroundTransparency = 0
						f.Size = UDim2.fromScale(1, 1)
						round(f, 12)
					end)
					pingFill.Size = UDim2.fromScale(1, 1)
					pingFill.ZIndex = z
					stroke(pingFill, r.pressed and Color3.fromRGB(125, 211, 252) or Color3.fromRGB(47, 104, 175), 1.5, r.pressed and 0.05 or 0.18)
					local rowGrad = ensurePanelChild(pingFill, "UIGradient", "HUDPingRowGrad", function(g)
						g.Rotation = 90
					end)
					rowGrad.Color = r.pressed
						and ColorSequence.new(Color3.fromRGB(28, 76, 138), Color3.fromRGB(14, 42, 86))
						or ColorSequence.new(Color3.fromRGB(18, 50, 112), Color3.fromRGB(8, 25, 62))

					local tileSize = math.clamp(h - 14, 28, 36)
					local badgeTile = ensurePanelChild(visual, "Frame", "HUDPingBadgeTile", function(f)
						f.BorderSizePixel = 0
						round(f, 9)
						stroke(f, Color3.fromRGB(6, 18, 44), 1.8, 0)
					end)
					badgeTile.BackgroundColor3 = pingTileColors[o.Name] or Color3.fromRGB(2, 132, 199)
					badgeTile.BackgroundTransparency = 0
					badgeTile.Visible = true
					box(badgeTile, 10, (h - tileSize) / 2, tileSize, tileSize)
					badgeTile.ZIndex = z + 2
					local tileReady = Adventure.Draw(badgeTile, fullKey, z + 3, "fit")
					if tileReady then
						local tileImg = badgeTile:FindFirstChild("HUDAdventureRaster")
						if tileImg and tileImg:IsA("ImageLabel") then
							tileImg.Position = UDim2.fromOffset(3, 3)
							tileImg.Size = UDim2.new(1, -6, 1, -6)
						end
					end

					local idx = o.Name:match("^Ping(%d)$")
					local showShortcut = idx ~= nil and not Input.TouchEnabled and w >= 200
					local scPill = ensurePanelChild(visual, "TextLabel", "HUDPingShortcut", function(lbl)
						lbl.BackgroundColor3 = Color3.fromRGB(6, 20, 51)
						lbl.BackgroundTransparency = 0
						lbl.TextColor3 = Color3.fromRGB(125, 211, 252)
						lbl.Font = Enum.Font.Nunito
						lbl.TextSize = 12
						lbl.TextXAlignment = Enum.TextXAlignment.Center
						lbl.TextYAlignment = Enum.TextYAlignment.Center
						round(lbl, 6)
						stroke(lbl, Color3.fromRGB(45, 98, 168), 1.2, 0.15)
					end)
					scPill.Visible = showShortcut
					if showShortcut then
						scPill.Text = tostring(idx)
						box(scPill, w - 36, (h - 22) / 2, 26, 22)
						scPill.ZIndex = z + 3
					end

					local left = 10 + tileSize + 12
					local rightGap = showShortcut and 44 or 12
					r.captionPill.BackgroundTransparency = 1
					box(r.captionPill, left, 3, math.max(1, w - left - rightGap), math.max(1, h - 6))
					applyTextStyle(r.caption, { font = Enum.Font.GothamBlack, size = 15 + math.min(2, textBoost), strokeThickness = 1.5, wrapped = false, align = Enum.TextXAlignment.Left })

				elseif purchase then
					local visual = Motion.Visual(o)
					local vStroke = visual:FindFirstChildOfClass("UIStroke")
					if vStroke then vStroke.Enabled = false end
					local ctaFill = ensurePanelChild(visual, "Frame", "HUDCtaFill", function(f)
						f.BackgroundColor3 = Color3.new(1, 1, 1)
						f.BackgroundTransparency = 0
						f.Size = UDim2.fromScale(1, 1)
						f.ClipsDescendants = true
						round(f, 11)
					end)
					ctaFill.Size = UDim2.fromScale(1, 1)
					ctaFill.ZIndex = z
					stroke(ctaFill, Color3.fromRGB(134, 239, 172), 1.6, 0.1)
					local ctaGrad = ensurePanelChild(ctaFill, "UIGradient", "HUDCtaGrad", function(g)
						g.Rotation = 90
					end)
					ctaGrad.Color = r.pressed
						and ColorSequence.new(Color3.fromRGB(32, 160, 86), Color3.fromRGB(14, 96, 46))
						or ColorSequence.new(Color3.fromRGB(58, 224, 122), Color3.fromRGB(20, 134, 60))
					local gloss = ensurePanelChild(ctaFill, "Frame", "HUDCtaGloss", function(f)
						f.BackgroundColor3 = Color3.new(1, 1, 1)
						f.BackgroundTransparency = 0.78
						round(f, 8)
					end)
					gloss.Position = UDim2.fromOffset(6, 3)
					gloss.Size = UDim2.new(1, -12, 0, math.max(8, math.round(h * 0.34)))
					gloss.ZIndex = z + 1
					gloss.Visible = true

					r.captionPill.BackgroundTransparency = 1
					local pStroke = r.captionPill:FindFirstChildOfClass("UIStroke")
					if pStroke then pStroke.Enabled = false end
					box(r.captionPill, 10, 3, math.max(1, w - 20), math.max(1, h - 6))
					applyTextStyle(r.caption, { font = Enum.Font.GothamBlack, size = 14, color = Color3.new(1, 1, 1), strokeColor = Color3.fromRGB(8, 61, 27), strokeThickness = 1.6, wrapped = false, align = Enum.TextXAlignment.Center })

				elseif style == "wide" then
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
						local left = math.max(39, math.round(h * 1.15))
						box(r.captionPill, left, 4, math.max(1, w - left - 15), h - 8)
					end

				elseif style == "dock" then
					local captionHeight = 14 + textBoost
					local bottomPad = 3
					local iconSize = math.max(1, math.min(w - 6, h - captionHeight - bottomPad - 3))
					local iconX = (w - iconSize) / 2
					local crop, sprite = dockCrops[fullKey], AdventureCatalog[fullKey]
					if illustration and crop and sprite then
						illustration.ImageRectOffset = Vector2.new(sprite[2], sprite[3]) + crop.Min
						illustration.ImageRectSize = crop.Max - crop.Min
						illustration.ScaleType = Enum.ScaleType.Stretch
						box(illustration, iconX, 2, iconSize, iconSize)
					end
					box(o:FindFirstChild("HUDRaster",true), iconX, 2, iconSize, iconSize)
					local glyphSize = math.round(iconSize * .68)
					box(r.glyphBox, (w - glyphSize) / 2, 2 + (iconSize - glyphSize) / 2, glyphSize, glyphSize)
					r.captionPill.BackgroundTransparency = 1
					local pStroke = r.captionPill:FindFirstChildOfClass("UIStroke")
					if pStroke then pStroke.Enabled = false end

					box(r.captionPill, 1, h - captionHeight - bottomPad, w - 2, captionHeight)
					applyTextStyle(r.caption, { font = Enum.Font.GothamBlack, size = 11, color = Color3.new(1, 1, 1), strokeThickness = 1.8, wrapped = false, align = Enum.TextXAlignment.Center })

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
				r.caption.Size = UDim2.new(1, style == "dock" and -2 or -4, 0, math.max(1, captionH))
				fitLine(r.caption, textBoost, style == "dock" and 7 or nil)
				local fixed = title ~= "" and not purchase and not reason and title ~= "ISI ULANG"
				local lockKeys = {
					["Kit habis"]="kit_empty", ["Memuat kit"]="kit_loading",
					["Kit terpakai"]="kit_used", ["Perisai aktif"]="kit_shield", ["ISI ULANG"]="reload_empty",
				}
				letter(r.caption, style ~= "dock" and (fixed and sprite or lockKeys[title]) or nil)

				local hint = o.Text:match("%[([^%]]+)%]")
				r.hint.Visible = style ~= "ping" and not Input.TouchEnabled and hint ~= nil and #hint <= 7 and hint ~= "GUNAKAN"
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
				local useRedBadge = false
				if o.Name == "EmergencyKitButton" then
					local kits = player:GetAttribute("EmergencyKits") or 0
					if kits > 0 then
						r.badge.Visible = true
						r.badge.Text = tostring(kits)
						r.badge.BackgroundColor3 = Color3.fromRGB(36, 212, 85)
					else
						r.badge.Visible = false
					end
				elseif o.Name == "DailyToggleButton" then
					local claimed = player:GetAttribute("DailyClaimedToday") == true
					r.badge.Visible = true
					r.badge.Text = claimed and "✓" or "!"
					useRedBadge = not claimed
					r.badge.BackgroundColor3 = claimed and Color3.fromRGB(16, 185, 129) or Color3.fromRGB(239, 68, 68)
				elseif o.Name == "TurboGasButton" then
					local turboRem = tonumber(player:GetAttribute("TurboRemaining")) or 0
					local stock = tonumber(player:GetAttribute("SpeedBoostStock")) or 0
					if turboRem > 0 then
						r.badge.Visible = true
						r.badge.Text = math.ceil(turboRem) .. "s"
						useRedBadge = true
						r.badge.BackgroundColor3 = Color3.fromRGB(14, 165, 233)
					elseif stock > 0 then
						r.badge.Visible = true
						r.badge.Text = tostring(stock)
						r.badge.BackgroundColor3 = Color3.fromRGB(36, 212, 85)
					else
						r.badge.Visible = false
					end
				elseif o.Name == "RopeBuffButton" then
					local ropeActive = player:GetAttribute("RopeBuffActive") == true
					local stock = tonumber(player:GetAttribute("RopeBuffStock")) or 0
					if ropeActive then
						r.badge.Visible = true
						r.badge.Text = "✓"
						r.badge.BackgroundColor3 = Color3.fromRGB(16, 185, 129)
					elseif stock > 0 then
						r.badge.Visible = true
						r.badge.Text = tostring(stock)
						r.badge.BackgroundColor3 = Color3.fromRGB(36, 212, 85)
					else
						r.badge.Visible = false
					end
				elseif o.Name == "JumpButton" and not o.Active and not complete then
					r.badge.Visible = true
					r.badge.Text = "!"
					useRedBadge = true
				elseif o.Name == "JumpButton" and inFlight and cooldown > 0 then
					r.badge.Visible = true
					r.badge.Text = math.ceil(cooldown) .. "s"
					useRedBadge = true
					r.badge.BackgroundColor3 = Color3.fromRGB(255, 45, 80)
				else
					r.badge.Visible = false
				end

				if r.badge.Visible then
					box(r.badge, w - 18, -4, 22, 22)
					applyTextStyle(r.badge, { font = Enum.Font.GothamBlack, size = 11, strokeThickness = 1.5, align = Enum.TextXAlignment.Center })
				end
				chip(r.badge, (o.Name == "JumpButton" or useRedBadge) and "badge_red" or "badge_green", z + 5)
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
					local iconSize = narrow and 32 or compact and 40 or 44
					box(r.emblem, 12, (h - iconSize) / 2, iconSize, iconSize)
					local loaded = use(r.art, "art_balloon")
					r.glyph.Visible = not loaded
					r.emblem.Visible = not fullPanel
					ztree(r.emblem, z + 3)

					local headingX = fullPanel and math.max(iconSize + 18, h + 4) or iconSize + 18
					local rightInset = narrow and 14 or 16
					local gap = narrow and 8 or 10
					local centerY = h / 2
					local titleY = centerY - 9 - textBoost / 2
					local detailY = centerY + 10 + textBoost / 2
					local titleH = 22 + textBoost
					local detailH = 14 + textBoost
					local speedW = (narrow and 94 or 106) + 4 * textBoost
					local speedH = (narrow and 26 or 28) + textBoost
					local speedX = w - rightInset - speedW
					local turboRem = math.ceil(math.max(0, tonumber(o:GetAttribute("TurboRemaining")) or tonumber(player:GetAttribute("TurboRemaining")) or 0))
					local showTurboInline = inFlight and turboRem > 0 and w >= 365
					local turboW = showTurboInline and (58 + 2 * textBoost) or 0
					local turboX = speedX - (showTurboInline and (turboW + 6) or 0)
					local dividerX = (showTurboInline and turboX or speedX) - gap
					local vVal = o:GetAttribute("VerticalSpeed") or (speed and speed:GetAttribute("VerticalSpeed")) or 0

					local headingWidth = w - headingX - rightInset
					local goalWidth = headingWidth
					if inFlight then
						local attrAlt = tonumber(o:GetAttribute("AltitudeKm"))
						local lblAlt = tonumber(altitude) or 0
						local altNum = (attrAlt and math.abs(attrAlt - lblAlt) <= 2) and attrAlt or lblAlt
						local biomeStep = FlyHighConfig.BIOME_STEP_KM or 2000
						local biomeIdx = math.clamp(math.floor(altNum / biomeStep) + 1, 1, #BIOME_ZONES)
						local zoneInfo = BIOME_ZONES[biomeIdx] or BIOME_ZONES[1]
						local descending = flightReady and vVal <= -0.05
						r.head.Text = flightReady and zoneInfo.title or "MEMUAT ZONA"
						r.head.TextColor3 = Color3.fromRGB(254, 249, 231)
						r.head.TextSize = narrow and 16 or 19
						r.goal.Text = not flightReady and "Menghitung ketinggian..."
							or descending and (zoneInfo.zone .. " · Balon Menurun!")
							or (zoneInfo.zone .. " · Target Istana Awan")
						r.goal.TextColor3 = descending and Color3.fromRGB(252, 165, 165) or Color3.fromRGB(147, 197, 253)
						headingWidth = math.max(60, dividerX - gap - headingX)
						goalWidth = headingWidth
					elseif atPalace or (outcome == "result_victory" and os.clock() < resultUntil) then
						r.head.Text = "ISTANA AWAN"
						r.head.TextColor3 = Color3.fromRGB(254, 249, 231)
						r.head.TextSize = 19
						r.goal.Text = "Puncak · 10.000 km"
						r.goal.TextColor3 = Color3.fromRGB(253, 224, 71)
					else
						local pod = player:GetAttribute("CurrentPod")
						local podLetter = pod and pod:match("^Pod_([A-E])$")
						r.head.Text = podLetter and "DERMAGA " .. podLetter or "FLY HIGH"
						r.head.TextColor3 = Color3.fromRGB(254, 249, 231)
						r.head.TextSize = 19
						r.goal.Text = "Pilih dermaga"
						r.goal.TextColor3 = Color3.fromRGB(213, 237, 255)
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

					if r.divider then
						r.divider.Visible = inFlight
						box(r.divider, dividerX, centerY - 14, 1, 28)
						r.divider.ZIndex = z + 3
					end

					local turboPill = ensurePanelChild(o, "Frame", "HUDTurboPill", function(f)
						f.BackgroundColor3 = Color3.fromRGB(12, 54, 108)
						f.BackgroundTransparency = 0.06
						round(f, 10)
						stroke(f, Color3.fromRGB(250, 204, 21), 1.4, 0.08)
						local tLbl = ensurePanelChild(f, "TextLabel", "HUDTurboText", function(lbl)
							lbl.BackgroundTransparency = 1
							lbl.Size = UDim2.fromScale(1, 1)
						end)
						applyTextStyle(tLbl, { font = Enum.Font.GothamBlack, size = 12, color = Color3.fromRGB(254, 240, 138), strokeThickness = 1.4, align = Enum.TextXAlignment.Center })
					end)
					turboPill.Visible = showTurboInline
					if showTurboInline then
						box(turboPill, turboX, centerY - speedH / 2, turboW, speedH)
						turboPill.ZIndex = z + 4
						local tLbl = turboPill:FindFirstChild("HUDTurboText")
						if tLbl and tLbl:IsA("TextLabel") then
							tLbl.Text = "⚡ " .. tostring(turboRem) .. "s"
							tLbl.ZIndex = z + 5
							fitLine(tLbl, textBoost, 9)
						end
					end

					local direction, value, color = "●", "0.0 km/s", Color3.fromRGB(147, 197, 253)
					local pillBg, pillRim = Color3.fromRGB(6, 16, 34), Color3.fromRGB(56, 189, 248)
					if vVal >= 0.05 then
						direction, value, color = "▲", string.format("+%.1f km/s", vVal), Color3.fromRGB(74, 222, 128)
						pillBg, pillRim = Color3.fromRGB(10, 61, 46), Color3.fromRGB(52, 211, 153)
					elseif vVal <= -0.05 then
						direction, value, color = "▼", string.format("%.1f km/s", vVal), Color3.fromRGB(248, 113, 113)
						pillBg, pillRim = Color3.fromRGB(69, 10, 10), Color3.fromRGB(248, 113, 113)
					end
					r.speed.Text = flightReady and (direction .. " " .. value) or "—"
					r.speed.TextColor3 = color
					box(r.speedPill, speedX, centerY - speedH / 2, speedW, speedH)
					box(r.speed, 6, 0, speedW - 12, speedH)
					fitLine(r.speed, textBoost)
					r.speedPill.BackgroundColor3 = pillBg
					r.speedPill.BackgroundTransparency = 0.08
					if r.speedStroke then r.speedStroke.Color = pillRim end
					r.speedPill.ZIndex = z + 4
					r.speedPill.Visible = inFlight
					for _, legacyRasterName in { "HUDRaster", "HUDAdventureRaster" } do
						local legacyRaster = r.speedPill:FindFirstChild(legacyRasterName)
						if legacyRaster and legacyRaster:IsA("GuiObject") then legacyRaster.Visible = false end
					end
					r.speed.ZIndex = z + 5

					-- Hidden legacy horizontal bar computations kept out of Option B display
					local stacked = false
					local barX = headingX + headingWidth + gap
					local percentW = 48 + 3 * textBoost
					local percentH = 16 + textBoost
					local barEnd = speedX - gap
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

					bar.Visible = false
					r.percent.Visible = false
					if r.markerSlot then r.markerSlot.Visible = false end
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
				box(r.emblem, 10, (h - 26) / 2, 26, 26)
				ztree(r.emblem, z + 3)
				r.emblem.Visible = not fullPanel
				local title = o:FindFirstChild("AlertTitle") or o:FindFirstChild("Title")
				local detail = o:FindFirstChild("AlertDesc") or o:FindFirstChild("Detail")
				local alertInset = fullPanel and math.round(math.min(h * 1.04, w * 0.25)) or 44
				local contentWidth = math.max(1, w - alertInset - 16)
				local titleHeight, detailHeight = 22 + math.floor(textBoost / 2), 17 + math.floor(textBoost / 2)
				local top = (h - titleHeight - detailHeight) / 2
				if title then
					box(title, alertInset, top, contentWidth, titleHeight)
					applyTextStyle(title, { font = Enum.Font.GothamBlack, size = 16, strokeThickness = 2,
						align = Enum.TextXAlignment.Left, valign = Enum.TextYAlignment.Center, wrapped = false })
					fitLine(title, textBoost)
					title.ZIndex = z + 3
				end
				if detail then
					box(detail, alertInset, top + titleHeight, contentWidth, detailHeight)
					applyTextStyle(detail, { font = Enum.Font.GothamBold, size = 14, strokeThickness = 1.5,
						align = Enum.TextXAlignment.Left, valign = Enum.TextYAlignment.Center, wrapped = false })
					fitLine(detail, textBoost)
					detail.ZIndex = z + 3
				end

			elseif r.kind == "ping_banner" then
				local isGhost = o:GetAttribute("PingKind") == "ghost"
				local msg = o:GetAttribute("PingMessage") or ""
				local sender = o:GetAttribute("PingSender") or (isGhost and "Arwah" or "Kru")
				o.BackgroundColor3 = isGhost and Color3.fromRGB(92, 18, 28) or Color3.fromRGB(14, 34, 72)
				local fbStroke = o:FindFirstChild("HUDFallbackStroke")
				if fbStroke and fbStroke:IsA("UIStroke") then
					fbStroke.Color = isGhost and Color3.fromRGB(255, 198, 96) or Color3.fromRGB(115, 224, 255)
				end
				local iconSize = math.max(24, math.round(h * 0.56))
				local iconX = isGhost and 10 or math.round(h * 0.36)
				box(r.emblem, iconX, (h - iconSize) / 2, iconSize, iconSize)
				ztree(r.emblem, z + 4)
				if isGhost then
					r.emblem.Visible = not fullPanel
					if r.glyph then r.glyph.Visible = not fullPanel end
					local iconImg = r.emblem:FindFirstChild("HUDAdventureRaster")
					if iconImg then iconImg.Visible = false end
				else
					r.emblem.Visible = true
					local ready = Adventure.Draw(r.emblem, pingMessageIcons[msg] or "ping_normal", z + 4, "fit")
					if r.glyph then r.glyph.Visible = not ready end
				end
				local textX = isGhost and (fullPanel and math.round(math.min(h * 1.08, w * 0.25)) or (iconX + iconSize + 8)) or (iconX + iconSize + 8)
				local rightPad = math.round(h * 0.34)
				local textW = math.max(1, w - textX - rightPad)
				local topPad = math.max(7, math.round(h * 0.17))
				local senderH = 14 + math.floor(textBoost / 2)
				local msgH = math.max(16, h - topPad * 2 - senderH)
				box(r.sender, textX, topPad, textW, senderH)
				r.sender.Text = (isGhost and "ARWAH • " or "KRU • ") .. sender
				applyTextStyle(r.sender, { font = Enum.Font.GothamBlack, size = 11 + math.floor(textBoost / 2),
					color = isGhost and Color3.fromRGB(255, 224, 130) or Color3.fromRGB(132, 232, 255),
					strokeThickness = 1.6, align = Enum.TextXAlignment.Left, valign = Enum.TextYAlignment.Center, wrapped = false })
				r.sender.TextTruncate = Enum.TextTruncate.AtEnd
				r.sender.ZIndex = z + 4
				box(r.message, textX, topPad + senderH, textW, msgH)
				r.message.Text = msg
				applyTextStyle(r.message, { font = Enum.Font.GothamBlack, size = compact and 14 or 15,
					color = Color3.new(1, 1, 1), strokeThickness = 1.8,
					align = Enum.TextXAlignment.Left, valign = Enum.TextYAlignment.Center, wrapped = false })
				fitLine(r.message, textBoost, 10)
				r.message.ZIndex = z + 4

			elseif r.kind == "card" then
				o.ZIndex = z
				for _, legacyName in { "HUDRaster", "HUDAdventureRaster" } do
					local legacy = o:FindFirstChild(legacyName)
					if legacy and legacy:IsA("GuiObject") then legacy.Visible = false end
				end
				o.BackgroundColor3 = Color3.new(1, 1, 1)
				o.BackgroundTransparency = 0
				round(o, 15)
				stroke(o, Color3.fromRGB(59, 130, 246), 1.6, 0.25)
				local cardGrad = ensurePanelChild(o, "UIGradient", "HUDCardGrad", function(g)
					g.Rotation = 90
					g.Color = ColorSequence.new(Color3.fromRGB(16, 43, 96), Color3.fromRGB(8, 26, 63))
				end)
				cardGrad.Enabled = true

				local isKit = o.Name == "Card1"
				local compactCard = (o.Parent and o.Parent:GetAttribute("HUDCompactCard") == true) or h < 230
				local horizontal = compactCard and w >= 290 and h <= 210

				local stage = ensurePanelChild(o, "Frame", "HUDCardStage", function(f)
					f.BackgroundColor3 = Color3.fromRGB(6, 20, 51)
					f.BackgroundTransparency = 0
					round(f, 11)
					stroke(f, Color3.fromRGB(30, 75, 138), 1.3, 0.1)
				end)
				stage.ZIndex = z + 1
				stage.Visible = true

				local badge = ensurePanelChild(o, "Frame", "HUDCardBadge", function(f)
					f.BackgroundTransparency = 0
					round(f, 10)
				end)
				local badgeLbl = ensurePanelChild(badge, "TextLabel", "HUDCardBadgeText", function(lbl)
					lbl.BackgroundTransparency = 1
					lbl.AnchorPoint = Vector2.new(0.5, 0.5)
					lbl.Position = UDim2.fromScale(0.5, 0.5)
					lbl.Size = UDim2.new(1, -10, 1, -2)
					lbl.Font = Enum.Font.FredokaOne
					lbl.TextWrapped = false
					lbl.TextScaled = true
					lbl.TextStrokeTransparency = 1
					lbl.TextXAlignment = Enum.TextXAlignment.Center
					lbl.TextYAlignment = Enum.TextYAlignment.Center
				end)
				badgeLbl.Text = isKit and "SEKALI PER TERBANG" or "PERMANEN · RAK SETELAN"
				badge.BackgroundColor3 = isKit and Color3.fromRGB(12, 74, 110) or Color3.fromRGB(88, 35, 6)
				badgeLbl.TextColor3 = isKit and Color3.fromRGB(125, 211, 252) or Color3.fromRGB(253, 224, 71)
				local bStroke = stroke(badge, badgeLbl.TextColor3, 1.2, 0.32)
				bStroke.Enabled = true
				badge.ZIndex = z + 3
				badgeLbl.ZIndex = z + 4

				local title = o:FindFirstChild("ProductTitle")
				local detail = o:FindFirstChild("ProductDescription")
				local purchase = o:FindFirstChildWhichIsA("TextButton")
				local artKey = isKit and "art_shop_kit_v2" or "art_shop_ak_v2"

				if horizontal then
					local buttonH = 44
					local stageW = math.clamp(math.round(w * 0.30), 86, 108)
					local stageH = math.max(64, h - buttonH - 28)
					box(stage, 10, 10, stageW, stageH)
					box(r.artBox, 6, 4, stageW - 12, stageH - 8)
					r.artBox.Parent = stage
					r.artBox.Visible = true
					ztree(r.artBox, z + 2)
					local loaded = Adventure.Draw(r.artBox, artKey, z + 2, "fit")
					r.art.Visible = not loaded
					if not loaded then use(r.art, isKit and "art_kit" or "art_rifle") end

					local tx = 10 + stageW + 12
					local tw = math.max(80, w - tx - 10)
					badge.Visible = stageH >= 74
					local curY = 10
					if title then
						box(title, tx, curY, tw, 22)
						title.ZIndex = z + 3
						applyTextStyle(title, { font = Enum.Font.GothamBlack, size = 16, color = Color3.new(1, 1, 1), strokeThickness = 1.6, wrapped = false, align = Enum.TextXAlignment.Left })
						fitLine(title, math.min(2, textBoost), 11)
						curY += 23
					end
					if badge.Visible then
						local bw = math.min(tw, isKit and 144 or 172)
						box(badge, tx, curY, bw, 20)
						applyTextStyle(badgeLbl, { font = Enum.Font.GothamBlack, size = 10, color = badgeLbl.TextColor3, strokeThickness = 0.4, wrapped = false, align = Enum.TextXAlignment.Center })
						fitLine(badgeLbl, 0, 8)
						curY += 22
					end
					if detail then
						box(detail, tx, curY, tw, math.max(18, 10 + stageH - curY))
						detail.ZIndex = z + 3
						applyTextStyle(detail, { font = Enum.Font.GothamBold, size = 12, color = Color3.fromRGB(203, 226, 255), strokeThickness = 1, wrapped = true, align = Enum.TextXAlignment.Left, valign = Enum.TextYAlignment.Top, scaled = true })
						fitLine(detail, textBoost, 9)
					end
					if purchase then
						purchase.ZIndex = z + 4
						box(purchase, 10, h - buttonH - 10, w - 20, buttonH)
					end
				else
					local buttonH = 44
					local buttonY = h - buttonH - 10
					local stageH = math.clamp(math.round(h * 0.34), 52, 106)
					box(stage, 12, 10, w - 24, stageH)
					box(r.artBox, 8, 4, w - 40, stageH - 8)
					r.artBox.Parent = stage
					r.artBox.Visible = true
					ztree(r.artBox, z + 2)
					local loaded = Adventure.Draw(r.artBox, artKey, z + 2, "fit")
					r.art.Visible = not loaded
					if not loaded then use(r.art, isKit and "art_kit" or "art_rifle") end

					local curY = 10 + stageH + 8
					local showBadge = h >= 238
					badge.Visible = showBadge
					if showBadge then
						local bw = math.min(w - 24, isKit and 154 or 184)
						box(badge, (w - bw) / 2, curY, bw, 22)
						applyTextStyle(badgeLbl, { font = Enum.Font.GothamBlack, size = 11, color = badgeLbl.TextColor3, strokeThickness = 0.4, wrapped = false, align = Enum.TextXAlignment.Center })
						fitLine(badgeLbl, 0, 8)
						curY += 28
					end
					if title then
						box(title, 12, curY, w - 24, 22)
						title.ZIndex = z + 3
						applyTextStyle(title, { font = Enum.Font.GothamBlack, size = 17, color = Color3.new(1, 1, 1), strokeThickness = 1.6, wrapped = false, align = Enum.TextXAlignment.Center })
						fitLine(title, math.min(2, textBoost), 11)
						curY += 24
					end
					if detail then
						box(detail, 14, curY, w - 28, math.max(16, buttonY - curY - 6))
						detail.ZIndex = z + 3
						applyTextStyle(detail, { font = Enum.Font.GothamBold, size = 12, color = Color3.fromRGB(203, 226, 255), strokeThickness = 1, wrapped = true, align = Enum.TextXAlignment.Center, valign = Enum.TextYAlignment.Top, scaled = true })
						fitLine(detail, textBoost, 8)
					end
					if purchase then
						purchase.ZIndex = z + 4
						box(purchase, 12, buttonY, w - 24, buttonH)
					end
				end

			elseif r.kind == "reticle" then
				ztree(r.glyph, z + 2)
				local locked = o:GetAttribute("AimLocked") == true
				r.glyph.Visible = not locked
				o.TextTransparency = locked and 0 or 1

			elseif r.kind == "panel" then
				o.ZIndex = z
				if o.Name == "ShopModal" then
					applyModalChrome(o, "modal_frame_9slice", "crest_shop", z)
					local title = o:FindFirstChild("ModalTitle")
					if title then
						title.Text = "TOKO SKY ADVENTURE"
						applyTextStyle(title, { font = Enum.Font.GothamBlack, size = 21, color = Color3.fromRGB(255, 246, 209), strokeThickness = 2.2, wrapped = false, align = Enum.TextXAlignment.Center })
						fitLine(title, math.min(2, textBoost), 13)
						title.ZIndex = z + 3
					end
					local sub = ensurePanelChild(o, "TextLabel", "ShopSubtitle", function(lbl)
						lbl.BackgroundTransparency = 1
						lbl.Text = "Perkuat balon, perbekalan kru & kosmetik"
					end)
					sub.Text = "Perkuat balon, perbekalan kru & kosmetik"
					applyTextStyle(sub, { font = Enum.Font.GothamBold, size = 12, color = Color3.fromRGB(186, 220, 255), strokeThickness = 1.1, wrapped = false, align = Enum.TextXAlignment.Center })
					fitLine(sub, math.min(2, textBoost), 9)
					sub.ZIndex = z + 3

					local feedback = o:FindFirstChild("ShopFeedback")
					local idleHint = ensurePanelChild(o, "TextLabel", "ShopIdleHint", function(lbl)
						lbl.BackgroundTransparency = 1
						lbl.Text = "Pilih item untuk membeli lewat Roblox."
					end)
					if feedback then
						applyTextStyle(feedback, { font = Enum.Font.GothamBold, size = 12, color = Color3.fromRGB(255, 232, 148), strokeThickness = 1.4, wrapped = true, align = Enum.TextXAlignment.Center, valign = Enum.TextYAlignment.Center })
						fitLine(feedback, math.min(2, textBoost), 8)
						feedback.ZIndex = z + 3
						idleHint.Position = feedback.Position
						idleHint.Size = feedback.Size
						idleHint.ZIndex = z + 3
						idleHint.Visible = feedback.Text == ""
						applyTextStyle(idleHint, { font = Enum.Font.GothamBold, size = 12, color = Color3.fromRGB(147, 197, 253), strokeThickness = 1.2, wrapped = false, align = Enum.TextXAlignment.Center })
						fitLine(idleHint, math.min(2, textBoost), 8)
					end
				elseif o.Name == "DailyLoginModal" then
					applyModalChrome(o, "modal_frame_9slice", "crest_daily", z)
					local dTitle = o:FindFirstChild("DailyTitle")
					if dTitle then
						applyTextStyle(dTitle, { font = Enum.Font.GothamBlack, size = 21, color = Color3.fromRGB(255, 246, 209), strokeThickness = 2.2, wrapped = false, align = Enum.TextXAlignment.Center })
						fitLine(dTitle, math.min(2, textBoost), 13)
						dTitle.ZIndex = z + 4
					end
					local dSub = o:FindFirstChild("DailySubtitle")
					if dSub then
						applyTextStyle(dSub, { font = Enum.Font.GothamBold, size = 12, color = Color3.fromRGB(147, 197, 253), strokeThickness = 1.1, wrapped = false, align = dSub.TextXAlignment })
						fitLine(dSub, math.min(1, textBoost), 9)
						dSub.ZIndex = z + 4
					end
					local dFooter = o:FindFirstChild("DailyFooterNote")
					if dFooter then
						fitLine(dFooter, math.min(1, textBoost), 8)
						dFooter.ZIndex = z + 4
					end
				elseif o.Name == "TacticalPingWheel" then
					applyModalChrome(o, "modal_frame_9slice", "crest_ping", z)
					local pingTitle = o:FindFirstChild("PingTitle")
					if pingTitle then
						applyTextStyle(pingTitle, { font = Enum.Font.GothamBlack, size = 21, color = Color3.fromRGB(255, 246, 209), strokeThickness = 2.2, wrapped = false, align = Enum.TextXAlignment.Center })
						fitLine(pingTitle, math.min(2, textBoost), 13)
						pingTitle.ZIndex = z + 4
					end
					local pSub = ensurePanelChild(o, "TextLabel", "PingSubtitle", function(lbl)
						lbl.BackgroundTransparency = 1
						lbl.Text = "Kirim sinyal cepat ke kru balon"
					end)
					applyTextStyle(pSub, { font = Enum.Font.GothamBold, size = 12, color = Color3.fromRGB(147, 197, 253), strokeThickness = 1.2, wrapped = false, align = Enum.TextXAlignment.Center })
					fitLine(pSub, math.min(2, textBoost), 9)
					pSub.ZIndex = z + 4
					local pFooter = ensurePanelChild(o, "TextLabel", "PingFooterHint", function(lbl)
						lbl.BackgroundTransparency = 1
					end)
					pFooter.Text = Input.TouchEnabled and "Ketuk pesan untuk langsung kirim ke kru" or "Tekan [V] untuk buka / tutup  ·  Klik pesan untuk kirim"
					applyTextStyle(pFooter, { font = Enum.Font.GothamBold, size = 12, color = Color3.fromRGB(186, 220, 255), strokeThickness = 1.1, wrapped = false, align = Enum.TextXAlignment.Center })
					fitLine(pFooter, math.min(1, textBoost), 8)
					pFooter.ZIndex = z + 4
				elseif o.Name == "WeaponSettingsModal" then
					applyModalChrome(o, "modal_frame_9slice", "crest_weapon", z)
					local title = o:FindFirstChild("Title")
					if title then
						title.Text = "SENJATA BALON"
						applyTextStyle(title, { font = Enum.Font.GothamBlack, size = 21, color = Color3.fromRGB(255, 246, 209), strokeThickness = 2.2, wrapped = false, align = Enum.TextXAlignment.Center })
						fitLine(title, math.min(2, textBoost), 13)
						title.ZIndex = z + 4
					end
					local invPill = ensurePanelChild(o, "Frame", "HUDInventoryPill", function(f)
						f.BackgroundColor3 = Color3.fromRGB(6, 20, 51)
						f.BackgroundTransparency = 0
						round(f, 12)
						stroke(f, Color3.fromRGB(45, 98, 168), 1.3, 0.15)
					end)
					invPill.ZIndex = z + 3
					local inv = o:FindFirstChild("InventoryCount")
					if inv then
						applyTextStyle(inv, { font = Enum.Font.GothamBold, size = 13, color = Color3.fromRGB(224, 242, 254), strokeThickness = 1.1, wrapped = false, align = Enum.TextXAlignment.Center })
						fitLine(inv, math.min(2, textBoost), 8)
						inv.ZIndex = z + 4
					end
					for slot = 1, 2 do
						local rackRow = ensurePanelChild(o, "Frame", "HUDRackRow" .. slot, function(f)
							f.BackgroundColor3 = Color3.new(1, 1, 1)
							f.BackgroundTransparency = 0
							round(f, 13)
							stroke(f, Color3.fromRGB(47, 104, 175), 1.4, 0.2)
							local rg = Instance.new("UIGradient")
							rg.Rotation = 90
							rg.Color = ColorSequence.new(Color3.fromRGB(12, 35, 82), Color3.fromRGB(7, 23, 58))
							rg.Parent = f
						end)
						rackRow.ZIndex = z + 1
						local slotLbl = o:FindFirstChild("SlotLabel" .. slot)
						if slotLbl then
							applyTextStyle(slotLbl, { font = Enum.Font.GothamBold, size = 14, color = Color3.fromRGB(224, 242, 254), strokeThickness = 1.4, wrapped = false, align = Enum.TextXAlignment.Left })
							fitLine(slotLbl, math.min(2, textBoost))
							slotLbl.ZIndex = z + 4
						end
					end
					local div = ensurePanelChild(o, "Frame", "HUDWeaponDivider", function(f)
						f.BackgroundColor3 = Color3.fromRGB(45, 98, 168)
						f.BackgroundTransparency = 0.52
					end)
					div.ZIndex = z + 2
					local footerPill = ensurePanelChild(o, "Frame", "HUDWeaponFooterPill", function(f)
						f.BackgroundColor3 = Color3.fromRGB(6, 20, 51)
						f.BackgroundTransparency = 0.25
						round(f, 10)
					end)
					footerPill.ZIndex = z + 2
					for _, noteSpec in {
						{ "LaunchNote", player:GetAttribute("InFlight") == true and Color3.fromRGB(252, 211, 77) or Color3.fromRGB(147, 197, 253) },
						{ "SettingsFeedback", Color3.fromRGB(255, 219, 143) },
					} do
						local lbl = o:FindFirstChild(noteSpec[1])
						if lbl then
							applyTextStyle(lbl, { font = Enum.Font.GothamBold, size = 12, color = noteSpec[2], strokeThickness = 1.2, wrapped = false, align = Enum.TextXAlignment.Center, valign = Enum.TextYAlignment.Center })
							fitLine(lbl, math.min(2, textBoost), 8)
							lbl.ZIndex = z + 4
						end
					end
					for _, child in o:GetChildren() do
						if child:IsA("TextButton") and child.Name ~= "SettingsCloseButton" then
							local cap = child:FindFirstChild("ChoiceCaption", true)
							if cap and cap:IsA("TextLabel") then
								cap.ZIndex = z + 5
								fitLine(cap, math.min(2, textBoost))
							end
						end
					end
				elseif o.Name == "AudioSettingsModal" then
					applyModalChrome(o, "modal_frame_9slice", "crest_audio", z)
					local title = o:FindFirstChild("AudioTitle")
					if title then
						applyTextStyle(title, { font = Enum.Font.GothamBlack, size = 21, color = Color3.fromRGB(255, 246, 209), strokeThickness = 2.2, wrapped = false, align = Enum.TextXAlignment.Center })
						fitLine(title, math.min(2, textBoost), 13)
						title.ZIndex = z + 4
					end
					local sub = o:FindFirstChild("AudioSubtitle")
					if sub then
						applyTextStyle(sub, { font = Enum.Font.GothamBold, size = 12, color = sub.TextColor3, strokeThickness = 1.2, wrapped = false, align = Enum.TextXAlignment.Center })
						fitLine(sub, math.min(2, textBoost), 8)
						sub.ZIndex = z + 4
					end
					local aFooter = o:FindFirstChild("AudioFooterHint")
					if aFooter then
						applyTextStyle(aFooter, { font = Enum.Font.GothamBold, size = 12, color = Color3.fromRGB(186, 220, 255), strokeThickness = 1.1, wrapped = false, align = Enum.TextXAlignment.Center })
						fitLine(aFooter, math.min(1, textBoost), 8)
						aFooter.ZIndex = z + 4
					end
					for _, keyName in { "Master", "Music", "SFX" } do
						local row = o:FindFirstChild("AudioRow" .. keyName)
						if row then
							local chLbl = row:FindFirstChild("ChannelLabel")
							if chLbl then
								applyTextStyle(chLbl, { font = Enum.Font.GothamBold, size = 14, color = Color3.fromRGB(240, 246, 255), strokeThickness = 1.4, wrapped = false, align = Enum.TextXAlignment.Left })
								fitLine(chLbl, math.min(2, textBoost), 9)
								chLbl.ZIndex = z + 3
							end
							local chVal = row:FindFirstChild("ChannelValue")
							if chVal then
								applyTextStyle(chVal, { font = Enum.Font.GothamBlack, size = 13, color = chVal.TextColor3, strokeThickness = 1.4, wrapped = false, align = Enum.TextXAlignment.Right })
								fitLine(chVal, math.min(2, textBoost), 9)
								chVal.ZIndex = z + 3
							end
						end
					end
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
