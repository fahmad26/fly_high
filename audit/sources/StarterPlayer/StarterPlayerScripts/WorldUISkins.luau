-- Give Fly High's world signs image backgrounds while keeping their live text.
local Modules = game:GetService("ReplicatedStorage"):WaitForChild("FlyHigh"):WaitForChild("Modules")
local Assets = require(Modules:WaitForChild("HUDImageAssets"))
local pendingImages = {}
local pollThread

local function onImageReady(image, refresh)
	if image.IsLoaded then
		refresh()
		return
	end
	pendingImages[image] = refresh
	if pollThread then return end
	pollThread = task.defer(function()
		while next(pendingImages) do
			for pending, callback in pendingImages do
				if not pending:IsDescendantOf(workspace) then
					pendingImages[pending] = nil
				elseif pending.IsLoaded then
					pendingImages[pending] = nil
					callback()
				end
			end
			task.wait(0.25)
		end
		pollThread = nil
	end)
end

local function backplate(gui, key)
	local background = gui:FindFirstChild("Background")
	local image = Assets.Mount(background or gui, key)
	image.ZIndex = 0
	if background then
		local function refresh()
			background.BackgroundTransparency = image.IsLoaded and 1 or 0
		end
		refresh()
		onImageReady(image, refresh)
	end
end

local function lettering(label, key)
	if not label or not label:IsA("TextLabel") then return end
	local function refresh()
		Assets.Letter(label, key)
	end
	local image = Assets.Letter(label, key)
	if not image then return end
	onImageReady(image, refresh)
	label:GetPropertyChangedSignal("AbsoluteSize"):Connect(refresh)
end

local function styleWelcomeSign(gui)
	-- Match the canvas aspect to the board so the lettering keeps its shape.
	gui.SizingMode = Enum.SurfaceGuiSizingMode.FixedSize
	gui.CanvasSize = Vector2.new(880, 344)
	local title = gui:FindFirstChildOfClass("TextLabel")
	if not title then return end

	title.Text = "FLY HIGH"
	title.Position = UDim2.fromScale(0.1, 0.22)
	title.Size = UDim2.fromScale(0.8, 0.33)
	title.Font = Enum.Font.FredokaOne
	title.TextSize = 96
	title.TextScaled = false
	title.TextWrapped = false
	title.TextColor3 = Color3.fromRGB(255, 221, 134)
	title.TextStrokeColor3 = Color3.fromRGB(4, 12, 28)
	title.TextStrokeTransparency = 0.55
	title.TextXAlignment = Enum.TextXAlignment.Center
	title.TextYAlignment = Enum.TextYAlignment.Center
	title.BackgroundTransparency = 1
	title.ZIndex = 2

	local subtitle = Instance.new("TextLabel")
	subtitle.Name = "WelcomeInstructions"
	subtitle.Text = "Pilih dermaga • Bentuk kru\nSiap terbang!"
	subtitle.Position = UDim2.fromScale(0.1, 0.52)
	subtitle.Size = UDim2.fromScale(0.8, 0.34)
	subtitle.Font = Enum.Font.Nunito
	subtitle.TextSize = 52
	subtitle.TextColor3 = Color3.fromRGB(222, 241, 255)
	subtitle.BackgroundTransparency = 1
	subtitle.ZIndex = 2
	subtitle.Parent = gui
end

local function dockLabel(gui, name, x, y, width, height, font, size, color)
	local label = gui:FindFirstChild(name)
	if not label then return end

	label.Position = UDim2.fromOffset(x, y)
	label.Size = UDim2.fromOffset(width, height)
	label.Font = font
	label.TextSize = size
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Center
	if color then label.TextColor3 = color end
	label.ZIndex = 2
	return label
end

local function styleDockSign(gui)
	-- Keep the fixed canvas proportional to the 8.1 × 5.3 stud board.
	gui.CanvasSize = Vector2.new(560, 366)
	local left, width = 36, 488
	local heading = Enum.Font.FredokaOne
	local body = Enum.Font.Nunito
	local cream = Color3.fromRGB(255, 234, 185)
	local light = Color3.fromRGB(224, 235, 255)

	dockLabel(gui, "PodTitle", left, 23, width, 30, heading, 24)
	dockLabel(gui, "ThemeTitle", left, 55, width, 52, heading, 40, cream)

	local crewRow = Instance.new("Frame")
	crewRow.Name = "CrewRowBackground"
	crewRow.Position = UDim2.fromOffset(left, 114)
	crewRow.Size = UDim2.fromOffset(width, 48)
	crewRow.BackgroundColor3 = Color3.fromRGB(18, 39, 73)
	crewRow.BorderSizePixel = 0
	crewRow.ZIndex = 1
	local rowCorner = Instance.new("UICorner", crewRow)
	rowCorner.CornerRadius = UDim.new(0, 12)
	crewRow.Parent = gui

	dockLabel(gui, "CountLabel", left + 16, 114, 260, 48, heading, 29)
	for index = 1, 3 do
		local slot = gui:FindFirstChild("CrewSlot" .. index)
		if slot then
			slot.Position = UDim2.fromOffset(398 + (index - 1) * 39, 126)
			slot.Size = UDim2.fromOffset(25, 25)
			slot.ZIndex = 2
			local outline = Instance.new("UIStroke", slot)
			outline.Thickness = 2
			outline.Color = Color3.fromRGB(133, 158, 197)
		end
	end

	dockLabel(gui, "MasterInfo", left, 169, width, 34, body, 25, light)
	dockLabel(gui, "StatusLabel", left, 204, width, 32, body, 25)
	local divider = gui:FindFirstChild("Divider")
	if divider then
		divider.Position = UDim2.fromOffset(left, 243)
		divider.Size = UDim2.fromOffset(width, 2)
		divider.BackgroundTransparency = 0.48
	end

	local start = dockLabel(gui, "StartHint", left, 253, width, 31, heading, 27, cream)
	if start then start.Text = "Mulai penerbangan" end
	local footer = dockLabel(gui, "Footer", left, 286, width, 27, body, 22, light)
	if footer then footer.Text = "Khusus Party Master" end
end

local function style(gui)
	if not gui:IsA("SurfaceGui") and not gui:IsA("BillboardGui") then return end
	local parent = gui.Parent
	if not parent or gui:GetAttribute("FlyHighRasterWorld") then return end
	local key
	if parent.Name == "WelcomeSign" then
		key = "world_sign"
	elseif gui.Name == "StatusGui" and parent.Name == "Console" then
		key = "pod_sign"
	elseif parent.Name == "CloudHavenDock" then
		key = "palace_sign"
	elseif gui.Name == "StormSign" then
		key = "storm_sign"
	end
	if not key then return end
	gui:SetAttribute("FlyHighRasterWorld", true)
	backplate(gui, key)

	if key == "world_sign" then
		styleWelcomeSign(gui)
	elseif key == "palace_sign" or key == "storm_sign" then
		lettering(gui:FindFirstChildOfClass("TextLabel"), key)
	end

	if key == "pod_sign" then
		styleDockSign(gui)
	end
end

workspace.DescendantAdded:Connect(function(gui)
	if gui:IsA("LayerCollector") then task.defer(style, gui) end
end)
for _, gui in workspace:GetDescendants() do style(gui) end
