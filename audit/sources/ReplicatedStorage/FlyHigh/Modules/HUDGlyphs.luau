-- Modern Arcade vector glyphs using high-resolution Lucide Icon Spritesheets (MIT License).
-- Zero external web dependencies, 100% free for commercial use, fast preloaded spritesheets.
local Glyphs = {}

local ICONS = {
	shop = { id = "16898613777", size = Vector2.new(48, 48), offset = Vector2.new(404, 967) }, -- store
	kit = { id = "16898612819", size = Vector2.new(48, 48), offset = Vector2.new(820, 404) }, -- briefcase-medical
	shield = { id = "16898613777", size = Vector2.new(48, 48), offset = Vector2.new(49, 771) }, -- shield-alert
	ping = { id = "16898613699", size = Vector2.new(48, 48), offset = Vector2.new(306, 918) }, -- radio
	sound = { id = "16898613869", size = Vector2.new(48, 48), offset = Vector2.new(771, 808) }, -- volume-2
	muted = { id = "16898613869", size = Vector2.new(48, 48), offset = Vector2.new(661, 918), slash = true }, -- volume + slash
	gas = { id = "16898613353", size = Vector2.new(48, 48), offset = Vector2.new(967, 306) }, -- flame
	jump = { id = "16898612629", size = Vector2.new(48, 48), offset = Vector2.new(918, 306) }, -- arrow-big-up
	climb = { id = "16898612629", size = Vector2.new(48, 48), offset = Vector2.new(918, 306) }, -- arrow-big-up
	descend = { id = "16898612629", size = Vector2.new(48, 48), offset = Vector2.new(196, 771) }, -- arrow-big-down
	drop = { id = "16898612629", size = Vector2.new(48, 48), offset = Vector2.new(196, 771) }, -- arrow-big-down
	fire = { id = "16898613044", size = Vector2.new(48, 48), offset = Vector2.new(453, 869) }, -- crosshair
	aim = { id = "16898613869", size = Vector2.new(48, 48), offset = Vector2.new(514, 771) }, -- target
	reload = { id = "16898613699", size = Vector2.new(48, 48), offset = Vector2.new(404, 869) }, -- refresh-cw
	repair = { id = "16898613509", size = Vector2.new(48, 48), offset = Vector2.new(306, 820) }, -- hammer
	rope = { id = "16898613509", size = Vector2.new(48, 48), offset = Vector2.new(967, 404) }, -- link-2
	attach = { id = "16898613509", size = Vector2.new(48, 48), offset = Vector2.new(967, 404) }, -- link-2
	detach = { id = "16898613869", size = Vector2.new(48, 48), offset = Vector2.new(869, 612) }, -- unlink
	rescue = { id = "16898613509", size = Vector2.new(48, 48), offset = Vector2.new(820, 563) }, -- hand-helping
	release = { id = "16898613509", size = Vector2.new(48, 48), offset = Vector2.new(820, 955) }, -- log-out
	warning = { id = "16898612629", size = Vector2.new(48, 48), offset = Vector2.new(869, 0) }, -- alert-circle
	close = { id = "16898613869", size = Vector2.new(48, 48), offset = Vector2.new(869, 906) }, -- x
	weapon = { id = "16898613777", size = Vector2.new(48, 48), offset = Vector2.new(967, 759) }, -- swords
	helm = { id = "16898613044", size = Vector2.new(48, 48), offset = Vector2.new(514, 967) }, -- compass
}

function Glyphs.Draw(parent, key)
	local root = Instance.new("Frame")
	root.Name = "HUDGlyph"
	root.Size = UDim2.fromScale(1, 1)
	root.BackgroundTransparency = 1
	root.Parent = parent

	local data = ICONS[key]
	if data then
		-- 1. Soft Drop Shadow (Embossed Depth)
		local shadow = Instance.new("ImageLabel")
		shadow.Name = "HUDIconShadow"
		shadow.Size = UDim2.fromScale(0.82, 0.82)
		shadow.AnchorPoint = Vector2.new(0.5, 0.5)
		shadow.Position = UDim2.fromScale(0.5, 0.54)
		shadow.BackgroundTransparency = 1
		shadow.Image = "rbxassetid://" .. data.id
		shadow.ImageRectSize = data.size
		shadow.ImageRectOffset = data.offset
		shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
		shadow.ImageTransparency = 0.55
		shadow.ScaleType = Enum.ScaleType.Fit
		shadow.ZIndex = 1
		shadow.Parent = root

		-- 2. Crisp White Vector Glyph
		local icon = Instance.new("ImageLabel")
		icon.Name = "HUDIconImg"
		icon.Size = UDim2.fromScale(0.82, 0.82)
		icon.AnchorPoint = Vector2.new(0.5, 0.5)
		icon.Position = UDim2.fromScale(0.5, 0.5)
		icon.BackgroundTransparency = 1
		icon.Image = "rbxassetid://" .. data.id
		icon.ImageRectSize = data.size
		icon.ImageRectOffset = data.offset
		icon.ImageColor3 = Color3.fromRGB(255, 255, 255)
		icon.ImageTransparency = 0
		icon.ScaleType = Enum.ScaleType.Fit
		icon.ZIndex = 2
		icon.Parent = root

		if data.slash then
			local slashShadow = Instance.new("Frame")
			slashShadow.Size = UDim2.new(0.88, 0, 0, 4)
			slashShadow.AnchorPoint = Vector2.new(0.5, 0.5)
			slashShadow.Position = UDim2.fromScale(0.5, 0.54)
			slashShadow.Rotation = -45
			slashShadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
			slashShadow.BackgroundTransparency = 0.5
			slashShadow.BorderSizePixel = 0
			slashShadow.ZIndex = 3
			slashShadow.Parent = root

			local slash = Instance.new("Frame")
			slash.Size = UDim2.new(0.88, 0, 0, 3.5)
			slash.AnchorPoint = Vector2.new(0.5, 0.5)
			slash.Position = UDim2.fromScale(0.5, 0.5)
			slash.Rotation = -45
			slash.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
			slash.BorderSizePixel = 0
			slash.ZIndex = 4
			slash.Parent = root
			local sc = Instance.new("UICorner", slash)
			sc.CornerRadius = UDim.new(0.5, 0)
		end
		return root
	end

	-- Procedural fallback for any unrecognized key
	local fallback = Instance.new("Frame")
	fallback.Size = UDim2.fromScale(0.65, 0.65)
	fallback.AnchorPoint = Vector2.new(0.5, 0.5)
	fallback.Position = UDim2.fromScale(0.5, 0.5)
	fallback.BackgroundTransparency = 1
	fallback.Parent = root
	local s = Instance.new("UIStroke", fallback)
	s.Color = Color3.new(1, 1, 1)
	s.Thickness = 2.5
	local c = Instance.new("UICorner", fallback)
	c.CornerRadius = UDim.new(0.5, 0)

	return root
end

return Glyphs
