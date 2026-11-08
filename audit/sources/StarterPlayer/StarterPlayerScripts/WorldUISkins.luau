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
	elseif parent.Name == "TeamSpotterMarker" then
		key = "marker"
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
		local pod = parent.Parent and parent.Parent.Name:match("^Pod_([A-E])$")
		if pod then lettering(gui:FindFirstChild("PodTitle"), "pod_" .. pod:lower()) end
		lettering(gui:FindFirstChild("StartHint"), "pod_start")
		lettering(gui:FindFirstChild("Footer"), "pod_footer")
		for i = 1, 3 do
			local slot = gui:FindFirstChild("CrewSlot" .. i)
			if slot and slot:IsA("Frame") then
				local fill = Assets.Mount(slot, "counter")
				local function refresh()
					fill.ImageColor3 = slot.BackgroundColor3:Lerp(Color3.new(1, 1, 1), 0.38)
					slot.BackgroundTransparency = fill.IsLoaded and 1 or 0
				end
				slot:GetPropertyChangedSignal("BackgroundColor3"):Connect(refresh)
				refresh()
				onImageReady(fill, refresh)
			end
		end
		local divider = gui:FindFirstChild("Divider")
		if divider and divider:IsA("Frame") then
			local line = Assets.Mount(divider, "progress")
			local function refresh()
				divider.BackgroundTransparency = line.IsLoaded and 1 or 0
			end
			refresh()
			onImageReady(line, refresh)
		end
	end
end

workspace.DescendantAdded:Connect(function(gui)
	if gui:IsA("LayerCollector") then task.defer(style, gui) end
end)
for _, gui in workspace:GetDescendants() do style(gui) end
