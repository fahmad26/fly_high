-- Image presentation only; the existing controls keep their input and game state.
local Catalog = require(script.Parent.HUDAdventureCatalog)
local ContentProvider = game:GetService("ContentProvider")
local Art = {}
local preloaded = false

local function segment(parent, name, id, x, y, w, h, px, width, tint, z)
	local image = parent:FindFirstChild(name)
	if not image then
		image = Instance.new("ImageLabel")
		image.Name = name
		image.BackgroundTransparency = 1
		image.BorderSizePixel = 0
		image.Active = false
		image.Parent = parent
	end
	if image.Image ~= id then image.Image = id end
	image.ImageRectOffset = Vector2.new(x, y)
	image.ImageRectSize = Vector2.new(w, h)
	image.Position = UDim2.fromOffset(px, 0)
	image.Size = UDim2.new(0, width, 1, 0)
	image.ImageColor3 = tint
	image.ZIndex = z
	return image.IsLoaded
end

function Art.Preload()
	if preloaded then return end
	preloaded = true
	local pages, seen = {}, {}
	for _, sprite in Catalog do
		if not seen[sprite[1]] then
			seen[sprite[1]] = true
			table.insert(pages, sprite[1])
		end
	end
	task.spawn(function()
		pcall(ContentProvider.PreloadAsync, ContentProvider, pages)
	end)
end

function Art.Draw(parent, key, z, mode, tint)
	local image = parent:FindFirstChild("HUDAdventureRaster")
	local sprite = Catalog[key]
	if not sprite then
		if image then image.Visible = false end
		return false, image
	end
	if not image then
		image = Instance.new("ImageLabel")
		image.Name = "HUDAdventureRaster"
		image.BackgroundTransparency = 1
		image.BorderSizePixel = 0
		image.Active = false
		image.Selectable = false
		image.Visible = false
		image.Parent = parent
	end
	local id, x, y, w, h = table.unpack(sprite)
	if image:GetAttribute("AdventureArtKey") ~= key then
		image.Image = id
		image.ImageRectOffset = Vector2.new(x, y)
		image.ImageRectSize = Vector2.new(w, h)
		image:SetAttribute("AdventureArtKey", key)
	end
	image.ZIndex = z
	image.ImageColor3 = tint or Color3.new(1, 1, 1)
	image.Position = UDim2.fromScale(0, 0)
	image.Size = UDim2.fromScale(1, 1)
	if parent:IsA("ScrollingFrame") then
		image.Position = UDim2.fromOffset(parent.CanvasPosition.X, parent.CanvasPosition.Y)
		image.Size = UDim2.fromOffset(parent.AbsoluteWindowSize.X, parent.AbsoluteWindowSize.Y)
	end
	-- Roblox only resolves IsLoaded after a visible GUI has requested the image.
	-- An unready image draws nothing; the caller keeps a fallback until it is ready.
	image.Visible = true
	local segmentsLoaded = false
	if mode == "fit" then
		image.ScaleType = Enum.ScaleType.Fit
	elseif mode == "wide" then
		-- Horizontal three-part sprite. Preserve the emblem and round ends without
		-- relying on Roblox's atlas nine-slice to render a very shallow panel.
		local left, right = math.round(w * 0.31), math.round(w * 0.14)
		local target = parent.Name=="HUDMotionVisual" and parent.Parent.AbsoluteSize or parent.AbsoluteSize
		local scale = math.min(target.Y / h, target.X / (left + right + 2))
		local leftWidth, rightWidth = math.floor(left * scale), math.floor(right * scale)
		local middle = math.max(0, target.X - leftWidth - rightWidth)
		local leftReady = segment(image, "HUDArtLeft", id, x, y, left, h, 0, leftWidth, image.ImageColor3, z)
		local middleReady = segment(image, "HUDArtMiddle", id, x + left, y, w - left - right, h, leftWidth, middle, image.ImageColor3, z)
		local rightReady = segment(image, "HUDArtRight", id, x + w - right, y, right, h, leftWidth + middle, rightWidth, image.ImageColor3, z)
		segmentsLoaded = leftReady and (middle <= 0 or middleReady) and rightReady
	else
		image.ScaleType = Enum.ScaleType.Stretch
	end
	image.ImageTransparency = mode == "wide" and 1 or 0
	local loaded = (mode == "wide" and segmentsLoaded) or (mode ~= "wide" and image.IsLoaded)
	return loaded, image
end

return Art
