-- Standalone Fly High glyph artwork, packed into the runtime PNG textures.
local Assets = require(script.Parent.HUDImageAssets)
local Glyphs = {}

local fallback = {
	shop = "T", kit = "+", sound = "♪", muted = "×", ping = "!",
	jump = "↑", climb = "↑", descend = "↓", fire = "⊕", aim = "+",
	close = "×", gas = "▲", auto = "↻", warning = "!",
}

function Glyphs.Draw(parent, key)
	local root = Instance.new("Frame")
	root.Name = "HUDGlyph"
	root.Size = UDim2.fromScale(1, 1)
	root.BackgroundTransparency = 1
	local image = Assets.Mount(root, "icon_" .. key, true)
	image.Name = "HUDGlyphImage"
	local text = Instance.new("TextLabel")
	text.Name = "HUDGlyphFallback"
	text.Size = UDim2.fromScale(1, 1)
	text.BackgroundTransparency = 1
	text.Text = fallback[key] or ""
	text.TextColor3 = Color3.new(1, 1, 1)
	text.TextScaled = true
	text.Font = Enum.Font.GothamBlack
	text.Parent = root
	local function refresh()
		local ready = image.IsLoaded
		image.Visible = ready
		text.Visible = not ready
	end
	image:GetPropertyChangedSignal("IsLoaded"):Connect(refresh)
	refresh()
	root.Parent = parent
	if not image.IsLoaded then
		task.spawn(function()
			local timeout = os.clock() + 8
			repeat
				task.wait(0.10)
			until not root.Parent or image.IsLoaded or os.clock() >= timeout
			if root.Parent then refresh() end
		end)
	end
	return root
end

return Glyphs
