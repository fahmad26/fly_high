-- AAA Arcade HUD Theme (UI Designer Pass) for "Fly High"
-- Designed with professional UI/UX hierarchy, pure transparent PNG rendering
-- (zero black/dark box artifacts), balanced typography, and cohesive arcade styling.

local Assets = require(script.Parent.HUDImageAssets)
local Glyphs = require(script.Parent.HUDGlyphs)
local Input = game:GetService("UserInputService")
local Content = game:GetService("ContentProvider")

local Theme = {}

-- Saturated 4-stop arcade palettes: {1: Top Shine, 2: Mid Core, 3: 3D Bevel, 4: Dark Outline}
local palettes = {
	blue = {
		Color3.fromRGB(120, 235, 255),
		Color3.fromRGB(0, 162, 255),
		Color3.fromRGB(0, 78, 178),
		Color3.fromRGB(4, 28, 70),
	},
	green = {
		Color3.fromRGB(160, 255, 110),
		Color3.fromRGB(36, 212, 85),
		Color3.fromRGB(16, 128, 48),
		Color3.fromRGB(6, 48, 18),
	},
	gold = {
		Color3.fromRGB(255, 240, 110),
		Color3.fromRGB(255, 174, 0),
		Color3.fromRGB(190, 105, 0),
		Color3.fromRGB(70, 36, 0),
	},
	orange = {
		Color3.fromRGB(255, 195, 90),
		Color3.fromRGB(255, 106, 19),
		Color3.fromRGB(186, 52, 6),
		Color3.fromRGB(68, 16, 2),
	},
	red = {
		Color3.fromRGB(255, 130, 150),
		Color3.fromRGB(255, 42, 75),
		Color3.fromRGB(170, 18, 45),
		Color3.fromRGB(60, 5, 15),
	},
	purple = {
		Color3.fromRGB(215, 165, 255),
		Color3.fromRGB(152, 74, 255),
		Color3.fromRGB(94, 32, 178),
		Color3.fromRGB(36, 10, 75),
	},
	dark = {
		Color3.fromRGB(72, 98, 140),
		Color3.fromRGB(28, 42, 68),
		Color3.fromRGB(12, 18, 32),
		Color3.fromRGB(6, 10, 18),
	},
	disabled = {
		Color3.fromRGB(130, 145, 165),
		Color3.fromRGB(85, 98, 115),
		Color3.fromRGB(50, 58, 70),
		Color3.fromRGB(25, 30, 38),
	},
}

local configs = {
	ShopToggleButton = { "shop", "TOKO", "gold", "dock" },
	EmergencyKitButton = { "kit", "KIT", "green", "dock" },
	PingButton = { "ping", "PING", "blue", "dock" },
	WarningAudioToggleButton = { "sound", "SUARA", "purple", "dock" },
	MobileShootButton = { "fire", "TEMBAK", "red", "round" },
	JumpButton = { "jump", "LOMPAT", "blue", "round" },
	GasButton = { "gas", "NAIK", "orange", "tile" },
	AutoGasButton = { "gas", "OTOMATIS", "blue", "wide" },
	ReleaseHelmButton = { "release", "LEPAS", "dark", "tile" },
	ReloadButton = { "reload", "ISI", "blue", "tile" },
	DropButton = { "drop", "LEPAS", "dark", "tile" },
	AttachButton = { "attach", "PASANG TALI", "blue", "wide" },
	DetachButton = { "detach", "LEPAS TALI", "dark", "wide" },
	ClimbButton = { "climb", "NAIK KUBAH", "blue", "wide" },
	DescendButton = { "descend", "TURUN", "blue", "wide" },
	RepairButton = { "repair", "TAHAN TAMBAL", "green", "wide" },
	RepairRopeButton = { "rope", "TAHAN PERBAIKI TALI", "green", "wide" },
	PullCrewButton = { "rescue", "TARIK REKAN", "orange", "wide" },
	BuyEmergencyKitButton = { "kit", "BELI 1 KIT • 29 R$", "green", "wide" },
	BuyAK47Button = { "weapon", "BELI AK-47 • 79 R$", "gold", "wide" },
	SpotHazardButton = { "warning", "TANDAI BAHAYA", "purple", "wide" },
	CloseButton = { "close", "", "red", "round" },
	Ping1 = { "flame", "Gas Api Sekarang!", "orange", "wide" },
	Ping2 = { "warning", "Awas Tornado Menghindar!", "purple", "wide" },
	Ping3 = { "rope", "Tali Saya Mau Habis!", "gold", "wide" },
	Ping4 = { "repair", "Saya yang Perbaiki!", "green", "wide" },
	Ping5 = { "aim", "Fokus Tembak Rintangan!", "red", "wide" },
}

local function box(o, x, y, w, h)
	if not o then return end
	o.Position = UDim2.fromOffset(math.round(x), math.round(y))
	o.Size = UDim2.fromOffset(math.round(w), math.round(h))
end

local function label(parent, name, maxSize)
	local l = Instance.new("TextLabel")
	l.Name = name
	l.BackgroundTransparency = 1
	l.TextColor3 = Color3.new(1, 1, 1)
	l.Font = Enum.Font.FredokaOne
	l.TextScaled = true
	l.TextWrapped = true
	l.TextStrokeColor3 = Color3.fromRGB(6, 12, 24)
	l.TextStrokeTransparency = 0
	l.Size = UDim2.fromScale(1, 1)
	l.Parent = parent
	local c = Instance.new("UITextSizeConstraint", l)
	c.MinTextSize = 8
	c.MaxTextSize = maxSize or 18
	return l
end

local function frame(parent, name)
	local f = Instance.new("Frame")
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

local function ztree(root, z)
	if not root then return end
	root.ZIndex = z
	for _, o in root:GetDescendants() do
		if o:IsA("GuiObject") then
			o.ZIndex = z
		end
	end
end

-- Builds a rich 3D Arcade Button surface with Bevel, Outer Stroke, Inner Ring, and Specular Gloss
local function surface(parent, circular)
	local rad = circular and 0.5 or nil

	-- 1. Ambient Drop Shadow (Ground depth)
	local shadow = frame(parent, "HUDShadow")
	shadow.BackgroundTransparency = 0.55
	shadow.BackgroundColor3 = Color3.fromRGB(2, 6, 14)
	shadow.Position = UDim2.fromOffset(0, 4)
	round(shadow, rad)

	-- 2. 3D Bottom Bevel Lip (Darker extrusion)
	local bevel = frame(parent, "HUDBevel")
	bevel.BackgroundTransparency = 0
	bevel.Position = UDim2.fromOffset(0, 3)
	round(bevel, rad)
	stroke(bevel, Color3.fromRGB(6, 12, 24), 2.2)

	-- 3. Top Interactive Face (Translates down 3px when pressed)
	local face = frame(parent, "HUDSurface")
	face.BackgroundColor3 = Color3.new(1, 1, 1)
	face.BackgroundTransparency = 0
	face.Position = UDim2.fromOffset(0, 0)
	round(face, rad)
	stroke(face, Color3.fromRGB(6, 12, 24), 2.2)

	local gradient = Instance.new("UIGradient", face)
	gradient.Rotation = 90

	-- 4. Inner Bright Highlight Ring (Specular bevel)
	local inner = frame(face, "HUDInnerRing")
	inner.Position = UDim2.fromOffset(1, 1)
	inner.Size = UDim2.new(1, -2, 1, -2)
	round(inner, rad)
	local inStroke = stroke(inner, Color3.new(1, 1, 1), 1, 0.55)
	inStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

	-- 5. Top Specular Gloss Reflection (Juicy Arcade Sheen)
	local shine = frame(face, "HUDGloss")
	shine.Position = UDim2.new(0, 2, 0, 1)
	shine.Size = UDim2.new(1, -4, 0.42, 0)
	shine.BackgroundColor3 = Color3.new(1, 1, 1)
	round(shine, rad)
	local glossGrad = Instance.new("UIGradient", shine)
	glossGrad.Rotation = 90
	glossGrad.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.45),
		NumberSequenceKeypoint.new(0.65, 0.85),
		NumberSequenceKeypoint.new(1, 1.0),
	})

	return {
		face = face,
		bevel = bevel,
		shadow = shadow,
		gradient = gradient,
		shine = shine,
		inner = inner,
	}
end

local function paint(s, paletteKey, z, pressed)
	local c = palettes[paletteKey] or palettes.blue
	s.face.BackgroundColor3 = Color3.new(1, 1, 1)
	s.bevel.BackgroundColor3 = c[3]

	local shade = pressed and 0.15 or 0
	s.gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, c[1]:Lerp(Color3.new(0, 0, 0), shade)),
		ColorSequenceKeypoint.new(0.42, c[2]:Lerp(Color3.new(0, 0, 0), shade)),
		ColorSequenceKeypoint.new(1, c[3]:Lerp(Color3.new(0, 0, 0), shade)),
	})

	-- Physical button depression
	s.face.Position = UDim2.fromOffset(0, pressed and 3 or 0)
	s.shine.Visible = not pressed

	ztree(s.shadow, math.max(1, z))
	ztree(s.bevel, z + 1)
	ztree(s.face, z + 2)
end

function Theme.Start(gui, player)
	local state = {}
	local alive = true
	local records, links, ready = {}, {}, {}
	gui:SetAttribute("HUDArtDirection", "Sky Arcade Pro Designer")

	local probes = Instance.new("Folder")
	probes.Name = "HUDImagePreload"
	probes.Parent = gui

	local wanted = { "balloon_intact", "emergency_kit", "weapon_pistol", "weapon_ak47" }
	local worker = task.spawn(function()
		for pass = 1, 2 do
			for _, key in wanted do
				if not alive then return end
				if not ready[key] then
					local probe = Instance.new("ImageLabel")
					probe.Name = key
					probe.Visible = false
					probe.Image = Assets[key]
					probe.Parent = probes
					local status
					pcall(function()
						Content:PreloadAsync({ probe }, function(_, result)
							status = result
						end)
					end)
					ready[key] = status == Enum.AssetFetchStatus.Success or probe.IsLoaded
					probe:Destroy()
					gui:SetAttribute("ImageLoaded_" .. key, ready[key] == true)
					task.wait(1)
				end
			end
			if pass < 2 then task.wait(60) end
		end
	end)

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

	local function use(a, key)
		local asset = Assets[key]
		if asset and #asset > 0 then
			a.Image = asset
			a.Visible = true
			return true
		end
		a.Image = ""
		a.Visible = false
		return false
	end

	local function build(o, kind, config)
		if records[o] then return end
		local r = { kind = kind, config = config, pressed = false, links = {} }
		records[o] = r

		-- Skip surface skin for panel and card containers so children are never occluded
		if kind ~= "reticle" and kind ~= "panel" and kind ~= "card" then
			r.skin = surface(o, config and config[4] == "round")
			o.BackgroundTransparency = 1
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
			stroke(r.captionPill, Color3.fromRGB(20, 34, 58), 1)
			r.caption = label(r.captionPill, "HUDCaption", config[4] == "wide" and 14 or 10)

			-- Keyboard shortcut hint
			r.hint = label(o, "HUDKeyHint", 10)
			r.hint.BackgroundTransparency = 0.2
			r.hint.BackgroundColor3 = Color3.fromRGB(6, 14, 28)
			round(r.hint, 3)

			-- Notification / Cooldown badge
			r.badge = label(o, "HUDBadge", 11)
			r.badge.BackgroundTransparency = 0
			r.badge.BackgroundColor3 = Color3.fromRGB(255, 45, 80)
			round(r.badge, 0.5)
			stroke(r.badge, Color3.fromRGB(255, 235, 120), 1.5)

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
			r.head = label(o, "HUDAltitude", 28)
			r.goal = label(o, "HUDGoal", 11)
			r.percent = label(o, "HUDProgress", 11)

			-- 100% Transparent Emblem Container (No black disc!)
			r.emblem = frame(o, "HUDEmblem")
			r.emblem.BackgroundTransparency = 1
			r.emblem.BorderSizePixel = 0

			r.glyph = Glyphs.Draw(r.emblem, "climb")
			r.art = art(r.emblem)

		elseif kind == "status" then
			r.head = label(o, "HUDCondition", 12)
			r.count = label(o, "HUDDamageCount", 13)
			r.detail = label(o, "HUDConditionDetail", 10)
			r.pips = {}
			for i = 1, 5 do
				local pip = frame(o, "HUDHull" .. i)
				pip.BackgroundTransparency = 0
				round(pip, 3)
				stroke(pip, Color3.fromRGB(6, 12, 24), 1.2)
				local shine = frame(pip, "PipShine")
				shine.Size = UDim2.new(1, -2, 0.45, 0)
				shine.Position = UDim2.fromOffset(1, 1)
				shine.BackgroundColor3 = Color3.new(1, 1, 1)
				shine.BackgroundTransparency = 0.5
				round(shine, 2)
				r.pips[i] = pip
			end

		elseif kind == "weapon" then
			r.head = label(o, "HUDWeapon", 13)
			r.ammo = label(o, "HUDAmmo", 28)
			r.reserve = label(o, "HUDReserve", 11)
			r.emblem = frame(o, "HUDWeaponIcon")
			r.emblem.BackgroundTransparency = 1
			r.glyph = Glyphs.Draw(r.emblem, "weapon")
			r.art = art(r.emblem)

		elseif kind == "tether" then
			r.head = label(o, "HUDRopeState", 11)

		elseif kind == "countdown" then
			-- Sleek danger notice ribbon
			r.emblem = frame(o, "HUDWarningIcon")
			r.emblem.BackgroundTransparency = 1
			r.glyph = Glyphs.Draw(r.emblem, "warning")
			r.notice = label(o, "HUDCountdownNotice", 13)
			o.TextTransparency = 1

		elseif kind == "alert" then
			r.emblem = frame(o, "HUDWarningIcon")
			r.emblem.BackgroundTransparency = 1
			r.glyph = Glyphs.Draw(r.emblem, "warning")

		elseif kind == "reticle" then
			o.TextTransparency = 1
			r.glyph = Glyphs.Draw(o, "aim")

		elseif kind == "card" then
			-- Direct Arcade Card styling (No black boxes!)
			o.BackgroundColor3 = Color3.fromRGB(16, 26, 44)
			o.BackgroundTransparency = 0.05
			round(o, 12)
			stroke(o, Color3.fromRGB(38, 62, 102), 1.8)

			r.artBox = frame(o, "HUDArtFrame")
			r.artBox.BackgroundTransparency = 1 -- 100% Transparent, no black box!
			r.artBox.BorderSizePixel = 0
			r.art = art(r.artBox)

		elseif kind == "panel" then
			-- Clean rectangular modal with rounded corners (16px, not an oval!)
			o.BackgroundColor3 = Color3.fromRGB(11, 18, 32)
			o.BackgroundTransparency = 0.05
			o.BorderSizePixel = 0
			round(o, 16)
			stroke(o, Color3.fromRGB(42, 74, 126), 2.5)
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
		elseif o.Name == "ShopModal" or o.Name == "GhostSpotterFrame" then
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

	local function textStyle(o, maxSize)
		o.Font = Enum.Font.FredokaOne
		o.TextColor3 = Color3.new(1, 1, 1)
		o.TextStrokeColor3 = Color3.fromRGB(6, 12, 24)
		o.TextStrokeTransparency = 0
		o.TextScaled = true
		local c = o:FindFirstChildOfClass("UITextSizeConstraint") or Instance.new("UITextSizeConstraint", o)
		c.MinTextSize = 9
		c.MaxTextSize = maxSize or 15
	end

	function state.Step()
		local compact = gui:GetAttribute("CompactLayout") == true
		for o, r in records do
			if not o:IsDescendantOf(gui) then
				for _, c in r.links do c:Disconnect() end
				records[o] = nil
				continue
			end

			local z = o.ZIndex
			local w, h = o.AbsoluteSize.X, o.AbsoluteSize.Y

			if r.skin then
				paint(r.skin, "dark", z, false)
				o.BackgroundTransparency = 1
			end

			if r.kind == "button" then
				local cfg = r.config
				local key = cfg[1]
				local palette = cfg[3]
				local title = cfg[2] or o.Text

				if o.Name == "WarningAudioToggleButton" then
					key = player:GetAttribute("WarningAudioMuted") and "muted" or "sound"
					if r.lastKey ~= key then
						r.glyph:Destroy()
						r.glyph = Glyphs.Draw(r.glyphBox, key)
						r.lastKey = key
					end
				elseif o.Name == "AutoGasButton" then
					local on = o.Text:find(": ON", 1, true) ~= nil
					title = "OTOMATIS: " .. (on and "ON" or "OFF")
					palette = on and "green" or "blue"
				elseif o.Name == "EmergencyKitButton" then
					if o.Text:find("CLUTCH", 1, true) then
						palette = "red"
						title = "SAVE!"
					end
				end

				if not o.Active then
					palette = "disabled"
					if o.Name == "JumpButton" then title = "TERKUNCI" end
				end

				paint(r.skin, palette, z, r.pressed)

				local style = cfg[4]
				if style == "wide" then
					r.captionPill.BackgroundTransparency = 1
					local pStroke = r.captionPill:FindFirstChildOfClass("UIStroke")
					if pStroke then pStroke.Enabled = false end

					box(r.glyphBox, 10, (h - 28) / 2, 28, 28)
					box(r.captionPill, 44, 4, w - 50, h - 8)
					r.caption.TextXAlignment = Enum.TextXAlignment.Left

				elseif style == "dock" then
					-- Left Toolbar: Icon sits in upper half with ample breathing room!
					local iconSize = 28
					box(r.glyphBox, (w - iconSize) / 2, 6, iconSize, iconSize)

					-- Caption ribbon sits cleanly at the bottom without overlapping icon
					r.captionPill.BackgroundTransparency = 0.2
					local pStroke = r.captionPill:FindFirstChildOfClass("UIStroke")
					if pStroke then
						pStroke.Enabled = true
						if o.Name == "ShopToggleButton" then
							pStroke.Color = Color3.fromRGB(255, 190, 40)
						elseif o.Name == "EmergencyKitButton" then
							pStroke.Color = Color3.fromRGB(40, 220, 110)
						elseif o.Name == "PingButton" then
							pStroke.Color = Color3.fromRGB(40, 180, 255)
						elseif o.Name == "WarningAudioToggleButton" then
							pStroke.Color = Color3.fromRGB(180, 90, 255)
						end
					end

					box(r.captionPill, 3, h - 17, w - 6, 15)
					r.caption.TextXAlignment = Enum.TextXAlignment.Center

				elseif style == "round" then
					local iconSize = math.round(math.min(w, h) * (#title == 0 and 0.58 or 0.52))
					box(r.glyphBox, (w - iconSize) / 2, (h - iconSize) / 2 + (#title == 0 and 0 or -3), iconSize, iconSize)

					if #title > 0 then
						r.captionPill.Visible = true
						r.captionPill.BackgroundTransparency = 0.25
						box(r.captionPill, 6, h - 18, w - 12, 15)
						r.caption.TextXAlignment = Enum.TextXAlignment.Center
					else
						r.captionPill.Visible = false
					end

				else
					-- Standard square tile button (e.g. Gas, Reload, Drop)
					local iconSize = math.round(math.min(w, h) * 0.52)
					box(r.glyphBox, (w - iconSize) / 2, 5, iconSize, iconSize)

					r.captionPill.BackgroundTransparency = 0.2
					box(r.captionPill, 2, h - 17, w - 4, 15)
					r.caption.TextXAlignment = Enum.TextXAlignment.Center
				end

				ztree(r.glyphBox, z + 3)
				ztree(r.captionPill, z + 4)
				r.caption.Text = title
				r.caption.TextColor3 = Color3.new(1, 1, 1)

				local hint = o.Text:match("%[([^%]]+)%]")
				r.hint.Visible = not Input.TouchEnabled and hint ~= nil and #hint <= 7 and hint ~= "GUNAKAN"
				if r.hint.Visible then
					r.hint.Text = hint:match("^%w+") or ""
					box(r.hint, w - 20, 2, 18, 13)
				end
				r.hint.ZIndex = z + 5

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
				elseif o.Name == "JumpButton" and player:GetAttribute("InFlight") == true and cooldown > 0 then
					r.badge.Visible = true
					r.badge.Text = math.ceil(cooldown) .. "s"
					r.badge.BackgroundColor3 = Color3.fromRGB(255, 45, 80)
				else
					r.badge.Visible = false
				end

				if r.badge.Visible then
					box(r.badge, w - 18, -4, 22, 22)
				end
				r.badge.ZIndex = z + 5

				o.TextTransparency = 1
				local jumpCaption = o:FindFirstChild("JumpCaption")
				if jumpCaption then jumpCaption.Visible = false end

			elseif r.kind == "alt" then
				paint(r.skin, "blue", z, false)
				local original = o:FindFirstChild("AltLabel")
				local bar = o:FindFirstChild("BarBg")
				local speed = o:FindFirstChild("VerticalSpeedLabel")

				if original and bar and speed then
					local altitude = original.Text:match("Ketinggian:%s*(%d+)") or "0"
					hide(original)

					-- 1. Balloon Icon on Left (Pure transparency, perfectly centered!)
					local iconSize = compact and 38 or 44
					box(r.emblem, 10, (h - iconSize) / 2, iconSize, iconSize)
					local loaded = use(r.art, "balloon_intact")
					r.glyph.Visible = not loaded
					ztree(r.emblem, z + 3)

					-- 2. Altitude Number & Mission Subtitle
					r.head.Text = player:GetAttribute("InFlight") and (altitude .. " KM") or "FLY HIGH"
					box(r.head, iconSize + 18, 4, 150, compact and 24 or 28)
					r.head.TextXAlignment = Enum.TextXAlignment.Left

					r.goal.Text = "ISTANA AWAN • 10.000 KM"
					box(r.goal, iconSize + 20, compact and 28 or 33, 170, 13)
					r.goal.TextXAlignment = Enum.TextXAlignment.Left
					r.goal.TextColor3 = Color3.fromRGB(186, 230, 253)

					-- 3. Progress Bar Track (Horizontally aligned with altitude)
					local barX = iconSize + 195
					local barW = math.max(60, w - barX - 110)
					box(bar, barX, (h - 8) / 2 + 6, barW, 8)
					bar.ZIndex = z + 3
					bar.BackgroundColor3 = Color3.fromRGB(6, 16, 32)
					bar.BackgroundTransparency = 0
					round(bar, 4)

					local fill = bar:FindFirstChild("BarFill")
					if fill then
						fill.BackgroundColor3 = Color3.fromRGB(0, 235, 140)
						fill.ZIndex = z + 4
						round(fill, 4)
					end

					-- Percentage display next to progress bar
					r.percent.Text = original.Text:match("%((.-)%)") or "0%"
					box(r.percent, barX + barW + 8, (h - 14) / 2 + 6, 44, 13)
					r.percent.TextXAlignment = Enum.TextXAlignment.Left
					r.percent.TextColor3 = Color3.fromRGB(224, 242, 254)

					-- 4. Speed Indicator Chip (Upper right corner)
					box(speed, w - 100, 6, 92, 22)
					textStyle(speed, 11)
					speed.ZIndex = z + 4
					speed.BackgroundColor3 = Color3.fromRGB(6, 16, 34)
					speed.BackgroundTransparency = 0.3
					round(speed, 6)
					stroke(speed, Color3.fromRGB(14, 40, 75), 1)

					r.head.ZIndex = z + 4
					r.goal.ZIndex = z + 4
					r.percent.ZIndex = z + 4
				end

			elseif r.kind == "status" then
				local holesLabel = o:FindFirstChild("HoleIcons")
				local penalty = o:FindFirstChild("HolePenalty")
				local invuln = o:FindFirstChild("InvulnLabel")

				if holesLabel and penalty then
					local holes = tonumber(holesLabel.Text:match("(%d)/5")) or 0
					paint(r.skin, holes >= 4 and "red" or "dark", z, false)

					for _, name in { "HoleTitle", "HoleIcons", "HolePenalty", "InvulnLabel" } do
						hide(o:FindFirstChild(name))
					end

					r.head.Text = holes == 0 and "BALON AMAN" or "KONDISI BALON"
					r.count.Text = holes .. "/5"
					box(r.head, 10, 4, w - 58, 15)
					box(r.count, w - 44, 3, 34, 16)
					r.head.TextXAlignment = Enum.TextXAlignment.Left

					local py = compact and 22 or 25
					local pipW = math.floor((w - 28) / 5)
					for i, pip in r.pips do
						box(pip, 10 + (i - 1) * (pipW + 2), py, pipW, compact and 8 or 10)
						local intact = i <= (5 - holes)
						pip.BackgroundColor3 = intact and Color3.fromRGB(36, 212, 85) or Color3.fromRGB(220, 32, 60)
						pip.ZIndex = z + 3
					end

					local details = {
						[0] = "▲ Naik optimal",
						[1] = "▲ Naik melambat",
						[2] = "■ Tidak bisa naik",
						[3] = "▼ Bahaya - turun 1.5x",
						[4] = "▼ Kritis - turun 2.5x",
						[5] = "▼ TERJUN BEBAS!",
					}
					r.detail.Text = (invuln and invuln.Visible and invuln.Text:gsub("🛡️%s*", "")) or details[holes]
					box(r.detail, 10, compact and 35 or 40, w - 20, 13)
					r.detail.TextXAlignment = Enum.TextXAlignment.Left

					r.head.ZIndex = z + 3
					r.count.ZIndex = z + 3
					r.detail.ZIndex = z + 3
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
					r.head.TextXAlignment = Enum.TextXAlignment.Left
					r.ammo.Text = ammo.Text:match("^(%d+%s*/%s*%d+)") or "MENGISI"
					r.ammo.TextXAlignment = Enum.TextXAlignment.Right
					r.reserve.Text = "CADANGAN: ∞"

					box(r.head, 54, 5, w - 60, 15)
					box(r.ammo, w - math.min(108, w - 54), compact and 18 or 22, math.min(98, w - 60), compact and 26 or 34)
					box(r.reserve, 12, h - 16, w - 120, 12)
					r.reserve.TextXAlignment = Enum.TextXAlignment.Left
					r.reserve.Visible = w >= 180

					box(r.emblem, 10, compact and 8 or 14, 38, 30)
					r.glyph.Visible = not use(r.art, weaponName == "AK-47" and "weapon_ak47" or "weapon_pistol")
					ztree(r.emblem, z + 3)

					r.head.ZIndex = z + 3
					r.ammo.ZIndex = z + 3
					r.reserve.ZIndex = z + 3
				end

			elseif r.kind == "tether" then
				local original = o:FindFirstChild("TetherLabel")
				local bar = o:FindFirstChild("TBarBg")
				if original and bar then
					hide(original)
					r.head.Text = original.Text:gsub("Tali Pengaman: ", "TALI  ")
					box(r.head, 10, 3, w - 20, 14)
					r.head.ZIndex = z + 3
					box(bar, 10, h - 9, w - 20, 5)
					bar.ZIndex = z + 3
					round(bar, 3)
					local fill = bar:FindFirstChild("TBarFill")
					if fill then
						fill.ZIndex = z + 4
						round(fill, 3)
					end
				end

			elseif r.kind == "countdown" then
				-- Sleek danger warning ribbon
				paint(r.skin, "orange", z, false)
				stroke(r.skin.face, Color3.fromRGB(255, 205, 50), 1.8)

				local iconSize = 18
				box(r.emblem, 10, (h - iconSize) / 2, iconSize, iconSize)
				ztree(r.emblem, z + 3)

				local rawText = o.Text
				if rawText and #rawText > 0 then
					local cleanText = rawText:gsub("^[⚠️%s%p]*", "")
					r.notice.Text = cleanText
				else
					r.notice.Text = ""
				end
				box(r.notice, 34, 2, w - 42, h - 4)
				r.notice.TextColor3 = Color3.fromRGB(255, 250, 240)
				r.notice.TextXAlignment = Enum.TextXAlignment.Center
				r.notice.ZIndex = z + 4
				o.TextTransparency = 1

			elseif r.kind == "alert" then
				paint(r.skin, o.Name == "AlertBanner" and "red" or "orange", z, false)
				box(r.emblem, 10, 10, 26, 26)
				ztree(r.emblem, z + 3)
				local title = o:FindFirstChild("AlertTitle") or o:FindFirstChild("Title")
				local detail = o:FindFirstChild("AlertDesc") or o:FindFirstChild("Detail")
				if title then
					box(title, 44, 6, w - 50, 22)
					textStyle(title, 15)
					title.ZIndex = z + 3
				end
				if detail then
					box(detail, 12, 32, w - 24, h - 38)
					textStyle(detail, 12)
					detail.ZIndex = z + 3
				end

			elseif r.kind == "card" then
				o.ZIndex = z
				-- Pure transparent illustration on left (NO black box!)
				box(r.artBox, 14, 12, 64, 64)
				ztree(r.artBox, z + 2)
				use(r.art, o.Name == "Card1" and "emergency_kit" or "weapon_ak47")

				-- Position and style child labels and buttons cleanly
				for _, child in o:GetChildren() do
					if child:IsA("TextLabel") and child.Name:sub(1, 3) ~= "HUD" then
						child.ZIndex = z + 3
						if child.Position.Y.Offset < 30 then
							-- Card Title (Gold FredokaOne)
							box(child, 88, 10, w - 98, 22)
							textStyle(child, 15)
							child.TextColor3 = Color3.fromRGB(255, 225, 100)
							child.TextXAlignment = Enum.TextXAlignment.Left
						else
							-- Card Description (Clean white/cyan wrapped text)
							box(child, 88, 34, w - 98, 44)
							textStyle(child, 11)
							child.TextColor3 = Color3.fromRGB(215, 230, 250)
							child.TextXAlignment = Enum.TextXAlignment.Left
						end
					elseif child:IsA("TextButton") then
						child.ZIndex = z + 4
						box(child, 88, h - 44, w - 98, 36)
					end
				end

			elseif r.kind == "reticle" then
				ztree(r.glyph, z + 2)

			elseif r.kind == "panel" then
				o.ZIndex = z
				local title = o:FindFirstChild("ModalTitle")
				if title then
					title.Text = "🛍️ PERBEKALAN PENERBANGAN"
					textStyle(title, 17)
					title.TextColor3 = Color3.fromRGB(255, 220, 90)
					box(title, 16, 6, w - 60, 32)
					title.TextXAlignment = Enum.TextXAlignment.Left
					title.ZIndex = z + 3
				end
				local feedback = o:FindFirstChild("ShopFeedback")
				if feedback then
					textStyle(feedback, 11)
					feedback.ZIndex = z + 3
					box(feedback, 16, h - 28, w - 32, 22)
				end
			end
		end
	end

	function state.Destroy()
		if not alive then return end
		alive = false
		if coroutine.status(worker) ~= "dead" then task.cancel(worker) end
		probes:Destroy()
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
