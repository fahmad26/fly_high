--!strict
-- Custom visuals only: ProximityPrompt still owns eligibility/input/hold duration.
local Prompts = game:GetService("ProximityPromptService")
local Input = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Repair = {}
local started = false
function Repair.Start(player: Player)
	if started then return end
	started = true
	local entries: { [ProximityPrompt]: () -> () } = {}
	local function show(prompt: ProximityPrompt, inputType: Enum.ProximityPromptInputType)
		if prompt.Name ~= "PatchPrompt" and prompt.Name ~= "RepairRopePrompt" then return end
		if prompt.Style ~= Enum.ProximityPromptStyle.Custom then return end
		if entries[prompt] then entries[prompt]() end
		local anchor = prompt.Parent
		if anchor and anchor:IsA("Model") then anchor = anchor.PrimaryPart end
		if not anchor or not (anchor:IsA("BasePart") or anchor:IsA("Attachment")) then return end
		-- Project the native world anchor into a transparent screen layer. This
		-- keeps the native location while giving touch a stable interactive surface.
		local gui = Instance.new("ScreenGui")
		gui.Name = "HUDRepairPrompt"
		gui.IgnoreGuiInset = true
		gui.ScreenInsets = Enum.ScreenInsets.None
		gui.DisplayOrder = 11
		local width = if Input.TouchEnabled then 216 else 248
		gui.ResetOnSpawn = false
		gui.Parent = player:WaitForChild("PlayerGui")
		local button = Instance.new("TextButton")
		button.Name = "RepairHoldTarget"
		button.Text = ""
		button.AutoButtonColor = false
		button.Selectable = false
		button.BackgroundColor3 = Color3.fromRGB(5, 17, 39)
		button.BackgroundTransparency = 0.35
		button.BorderSizePixel = 0
		button.Size = UDim2.fromOffset(width, 72)
		button.AnchorPoint = Vector2.new(0.5, 0.5)
		button.Parent = gui
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 12)
		corner.Parent = button
		local border = Instance.new("UIStroke")
		border.Color = Color3.fromRGB(255, 222, 146)
		border.Thickness = 1.5
		border.Transparency = 0.25
		border.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		border.Parent = button
		local function label(name: string, text: string, x: number, y: number, w: number, h: number, size: number, color: Color3): TextLabel
			local t = Instance.new("TextLabel")
			t.Name = name
			t.Text = text
			t.Position = UDim2.fromOffset(x, y)
			t.Size = UDim2.fromOffset(w, h)
			t.BackgroundTransparency = 1
			t.Font = Enum.Font.GothamBold
			t.TextSize = size
			t.TextColor3 = color
			t.TextXAlignment = Enum.TextXAlignment.Left
			t.TextYAlignment = Enum.TextYAlignment.Center
			t.Parent = button
			return t
		end
		local key = if inputType == Enum.ProximityPromptInputType.Touch then "TAHAN"
			elseif inputType == Enum.ProximityPromptInputType.Gamepad then Input:GetStringForKeyCode(prompt.GamepadKeyCode)
			else Input:GetStringForKeyCode(prompt.KeyboardKeyCode)
		if key == "" then key = "TAHAN" end
		local cap = label("InputKey", key, 10, 14, 44, 36, if #key > 3 then 10 else 18, Color3.fromRGB(255, 230, 165))
		cap.TextXAlignment = Enum.TextXAlignment.Center
		cap.BackgroundColor3 = Color3.fromRGB(27, 62, 91)
		cap.BackgroundTransparency = 0.25
		local capCorner = Instance.new("UICorner")
		capCorner.CornerRadius = UDim.new(0, 8)
		capCorner.Parent = cap
		local action = if prompt.Name == "PatchPrompt" then "TAMBAL BALON" else "PERBAIKI TALI"
		label("Action", action, 64, 12, width - 74, 22, 14, Color3.fromRGB(249, 248, 238))
		local hint = string.format("Tahan · %.1f dtk", prompt.HoldDuration):gsub("%.", ",")
		local detail = label("HoldDetail", hint, 64, 35, width - 74, 17, 12, Color3.fromRGB(177, 216, 229))
		local track = Instance.new("Frame")
		track.Name = "HoldTrack"
		track.BackgroundColor3 = Color3.fromRGB(6, 15, 29)
		track.BackgroundTransparency = 0.25
		track.BorderSizePixel = 0
		track.Position = UDim2.fromOffset(12, 61)
		track.Size = UDim2.fromOffset(width - 24, 4)
		track.ClipsDescendants = true
		track.Parent = button
		local fill = Instance.new("Frame")
		fill.Name = "HoldFill"
		fill.BackgroundColor3 = Color3.fromRGB(79, 223, 204)
		fill.BorderSizePixel = 0
		fill.Size = UDim2.fromScale(0, 1)
		fill.Parent = track
		local links: { RBXScriptConnection } = {}
		local tween: Tween? = nil
		local pointer: InputObject? = nil
		local closed = false
		local function endPointer()
			if pointer then pointer = nil; prompt:InputHoldEnd() end
		end
		local function reset()
			if tween then tween:Cancel(); tween = nil end
			fill.Size = UDim2.fromScale(0, 1)
			detail.Text = hint
		end
		local function cleanup()
			if closed then return end
			closed = true
			for _, link in links do link:Disconnect() end
			endPointer()
			if tween then tween:Cancel() end
			gui:Destroy()
			entries[prompt] = nil
		end
		entries[prompt] = cleanup
		table.insert(links, RunService.RenderStepped:Connect(function()
			local camera = workspace.CurrentCamera
			if not camera or not anchor or not anchor.Parent then cleanup(); return end
			local position = if anchor:IsA("Attachment") then anchor.WorldPosition else (anchor :: BasePart).Position
			local point, onScreen = camera:WorldToViewportPoint(position)
			button.Visible = onScreen
			button.Position = UDim2.fromOffset(point.X + prompt.UIOffset.X, point.Y + prompt.UIOffset.Y)
		end))
		table.insert(links, button.InputBegan:Connect(function(i)
			if pointer or (i.UserInputType ~= Enum.UserInputType.Touch and i.UserInputType ~= Enum.UserInputType.MouseButton1) then return end
			pointer = i
			prompt:InputHoldBegin()
		end))
		table.insert(links, Input.InputEnded:Connect(function(i)
			if i == pointer or (pointer and i.UserInputType == Enum.UserInputType.MouseButton1 and pointer.UserInputType == i.UserInputType) then endPointer() end
		end))
		table.insert(links, Input.WindowFocusReleased:Connect(function() endPointer(); reset() end))
		table.insert(links, prompt.PromptButtonHoldBegan:Connect(function()
			reset()
			detail.Text = "Memperbaiki…"
			tween = TweenService:Create(fill, TweenInfo.new(prompt.HoldDuration, Enum.EasingStyle.Linear), { Size = UDim2.fromScale(1, 1) })
			tween:Play()
		end))
		table.insert(links, prompt.PromptButtonHoldEnded:Connect(reset))
		table.insert(links, prompt.Triggered:Connect(function() detail.Text = "Memproses…" end))
		table.insert(links, prompt.PromptHidden:Connect(cleanup))
		table.insert(links, prompt.Destroying:Connect(cleanup))
		table.insert(links, prompt:GetPropertyChangedSignal("Enabled"):Connect(function() if not prompt.Enabled then cleanup() end end))
	end
	Prompts.PromptShown:Connect(show)
	player.CharacterRemoving:Connect(function()
		local pending = table.clone(entries)
		for _, cleanup in pending do cleanup() end
	end)
end
return Repair
