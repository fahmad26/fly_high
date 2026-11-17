--!strict
-- Shared visual language with Sky Adventure popup chrome. No gameplay state.
local Art = require(script.Parent.HUDAdventureArt)
local Chrome = {}
local function shape(parent: Instance, name: string, x: number, y: number, w: number, h: number, color: Color3, radius: number, z: number): Frame
	local found = parent:FindFirstChild(name)
	local f = found :: Frame
	if not f then
		f = Instance.new("Frame")
		f.Name = name
		f.BorderSizePixel = 0
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(radius, 0)
		corner.Parent = f
		f.Parent = parent
	end
	f.Position = UDim2.fromScale(x, y)
	f.Size = UDim2.fromScale(w, h)
	f.BackgroundColor3 = color
	f.ZIndex = z
	return f
end
function Chrome.Panel(parent: GuiObject, z: number)
	for _, name in { "HUDRaster", "HUDAdventureRaster" } do
		local old = parent:FindFirstChild(name)
		if old and old:IsA("GuiObject") then old.Visible = false end
	end
	local ready, surface = Art.DrawSlice(parent, "modal_frame_9slice", z, Rect.new(96, 96, 224, 224), 0.24, "HUDHeaderSurface")
	if surface then
		surface.Position = UDim2.fromScale(0, 0)
		surface.Size = UDim2.fromScale(1, 1)
	end
	parent.BackgroundTransparency = if ready then 1 else 0.12
	parent.BackgroundColor3 = Color3.fromRGB(5, 17, 49)
	local outline = parent:FindFirstChildOfClass("UIStroke")
	if outline then outline.Enabled = not ready end
end
function Chrome.Emblem(parent: GuiObject, z: number)
	local navy = Color3.fromRGB(6, 22, 51)
	local gold = Color3.fromRGB(255, 222, 125)
	shape(parent, "HUDDiscRim", 0, 0, 1, 1, gold, 0.5, z)
	shape(parent, "HUDDiscInset", 0.055, 0.055, 0.89, 0.89, navy, 0.5, z + 1)
	shape(parent, "HUDDiscBlue", 0.12, 0.12, 0.76, 0.76, Color3.fromRGB(25, 75, 129), 0.5, z + 2)
	shape(parent, "HUDDiscFace", 0.155, 0.155, 0.69, 0.69, navy, 0.5, z + 3)
	shape(parent, "HUDBalloon", 0.30, 0.20, 0.40, 0.48, Color3.fromRGB(255, 115, 121), 0.5, z + 4)
	shape(parent, "HUDBalloonRib", 0.465, 0.23, 0.07, 0.38, Color3.fromRGB(255, 226, 161), 0.5, z + 5)
	shape(parent, "HUDCordL", 0.39, 0.63, 0.035, 0.12, gold, 0, z + 4)
	shape(parent, "HUDCordR", 0.575, 0.63, 0.035, 0.12, gold, 0, z + 4)
	shape(parent, "HUDBasket", 0.405, 0.73, 0.19, 0.105, Color3.fromRGB(225, 164, 74), 0.1, z + 4)
end
return Chrome
