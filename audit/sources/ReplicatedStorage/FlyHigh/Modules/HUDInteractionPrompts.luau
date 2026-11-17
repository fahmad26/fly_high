--!strict
-- Custom visuals only: ProximityPrompt still owns eligibility/input/hold duration.
local Prompts = game:GetService("ProximityPromptService")
local Input = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Repair = {}
local titles: { [string]: string } = {
 PatchPrompt="TAMBAL BALON", RepairRopePrompt="PERBAIKI TALI",
 HelmPrompt="PEGANG KEMUDI", PickupPrompt="AMBIL SENJATA",
 StartPrompt="MULAI TERBANG", ReturnPrompt="KEMBALI KE PULAU",
 PhotoPrompt="FOTO KEMENANGAN", SitPrompt="DUDUK",
 TetherPrompt="PASANG TALI", DetachTetherPrompt="LEPAS TALI",
 ClimbPrompt="PANJAT KUBAH", DescendPrompt="TURUN KE GONDOLA",
 PullCrewPrompt="TARIK REKAN",
}
local padKeys: { [Enum.KeyCode]: string } = {
 [Enum.KeyCode.ButtonA]="A", [Enum.KeyCode.ButtonB]="B", [Enum.KeyCode.ButtonX]="X", [Enum.KeyCode.ButtonY]="Y",
 [Enum.KeyCode.ButtonR1]="R1", [Enum.KeyCode.ButtonR2]="R2", [Enum.KeyCode.ButtonR3]="R3",
 [Enum.KeyCode.ButtonL1]="L1", [Enum.KeyCode.ButtonL2]="L2", [Enum.KeyCode.ButtonL3]="L3",
}
local started = false
function Repair.Start(player: Player)
	if started then return end
	started = true
	local entries: { [ProximityPrompt]: () -> () } = {}
	local function show(prompt: ProximityPrompt, inputType: Enum.ProximityPromptInputType)
		if not titles[prompt.Name] then return end
		if prompt.Style ~= Enum.ProximityPromptStyle.Custom then return end
		if entries[prompt] then entries[prompt]() end
		local anchor = prompt.Parent
		if anchor and anchor:IsA("Model") then anchor = anchor.PrimaryPart end
		if not anchor or not (anchor:IsA("BasePart") or anchor:IsA("Attachment")) then return end
		-- Project the native world anchor into a transparent screen layer. This
		-- keeps the native location while giving touch a stable interactive surface.
		local gui = Instance.new("ScreenGui")
		gui.Name = "HUDInteractionPrompt"
		gui:SetAttribute("PromptName", prompt.Name)
		gui.IgnoreGuiInset = true
		gui.ScreenInsets = Enum.ScreenInsets.None
		local hud = player:WaitForChild("PlayerGui"):FindFirstChild("FlyHighHUD")
		gui.DisplayOrder = if hud and hud:IsA("ScreenGui") then hud.DisplayOrder - 1 else -1
		local touch = inputType == Enum.ProximityPromptInputType.Touch
		local width, height = 196, if touch then 52 else 50
		gui.ResetOnSpawn = false
		gui.Parent = player:WaitForChild("PlayerGui")
		local button = Instance.new("TextButton")
		button.Name = "ActionTarget"
		button.Visible = false
		button.Text = ""
		button.AutoButtonColor = false
		button.Selectable = false
		button.BackgroundColor3 = Color3.fromRGB(5, 17, 39)
		button.BackgroundTransparency = 0.65
		button.BorderSizePixel = 0
		button.Size = UDim2.fromOffset(width, height)
		button.AnchorPoint = Vector2.new(0.5, 0.5)
		button.Parent = gui
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0.5, 0)
		corner.Parent = button
		local border = Instance.new("UIStroke")
		border.Color = Color3.fromRGB(255, 222, 146)
		border.Thickness = 1
		border.Transparency = 0.55
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
			t.TextStrokeColor3 = Color3.fromRGB(3, 10, 23)
			t.TextStrokeTransparency = 0.5
			t.TextXAlignment = Enum.TextXAlignment.Left
			t.TextYAlignment = Enum.TextYAlignment.Center
			t.Parent = button
			return t
		end
		local key = if touch then (if prompt.HoldDuration > 0 then "TAHAN" else "TAP")
			elseif inputType == Enum.ProximityPromptInputType.Gamepad then padKeys[prompt.GamepadKeyCode] or Input:GetStringForKeyCode(prompt.GamepadKeyCode)
			else Input:GetStringForKeyCode(prompt.KeyboardKeyCode)
		if key == "" then key = "TAHAN" end
		local capSize = if touch then 36 else 32
		local cap = label("InputKey", key, 8, (height - capSize) / 2, capSize, capSize, if #key > 3 then 8 else (#key > 1 and 12 or 17), Color3.fromRGB(255, 230, 165))
		cap.TextXAlignment = Enum.TextXAlignment.Center
		cap.BackgroundColor3 = Color3.fromRGB(27, 62, 91)
		cap.BackgroundTransparency = 0.55
		local capCorner = Instance.new("UICorner")
		capCorner.CornerRadius = UDim.new(0.5, 0)
		capCorner.Parent = cap
		local function actionTitle()
			return if prompt.Name == "PickupPrompt" and prompt.ActionText ~= "" then string.upper(prompt.ActionText) else titles[prompt.Name]
		end
		local title = label("Action", actionTitle(), 52, 7, width - 64, 19, if touch then 14 else 13, Color3.fromRGB(249, 248, 238))
		local hint = if prompt.HoldDuration > 0 then string.format("Tahan · %.1f dtk", prompt.HoldDuration):gsub("%.", ",") else (if touch then "Ketuk untuk memilih" else "Tekan untuk memilih")
		local detail = label("ActionDetail", hint, 52, 26, width - 64, 15, 11, Color3.fromRGB(177, 216, 229))
		local track = Instance.new("Frame")
		track.Name = "HoldTrack"
		track.BackgroundColor3 = Color3.fromRGB(6, 15, 29)
		track.BackgroundTransparency = 0.65
		track.Visible = prompt.HoldDuration > 0
		track.BorderSizePixel = 0
		track.Position = UDim2.fromOffset(52, height - 7)
		track.Size = UDim2.fromOffset(width - 68, 2)
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
		local pendingSequence = 0
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
			-- Screen coordinates and GUI origin include different device/core insets.
			-- Subtract the root origin to keep the action on the native world anchor.
			local point, onScreen = camera:WorldToScreenPoint(position)
			button.Visible = onScreen and not (hud and hud:IsA("ScreenGui") and not hud.Enabled)
			button.Position = UDim2.fromOffset(point.X + prompt.UIOffset.X - gui.AbsolutePosition.X,
				point.Y + prompt.UIOffset.Y - gui.AbsolutePosition.Y)
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
			detail.Text = "Sedang menahan…"
			tween = TweenService:Create(fill, TweenInfo.new(prompt.HoldDuration, Enum.EasingStyle.Linear), { Size = UDim2.fromScale(1, 1) })
			tween:Play()
		end))
		table.insert(links, prompt.PromptButtonHoldEnded:Connect(reset))
		table.insert(links, prompt.Triggered:Connect(function()
			detail.Text = "Memproses…"
			pendingSequence += 1
			local token = pendingSequence
			task.delay(0.8, function()
				if not closed and token == pendingSequence then detail.Text = hint end
			end)
		end))
		table.insert(links, prompt:GetPropertyChangedSignal("ActionText"):Connect(function() title.Text = actionTitle() end))
		table.insert(links, prompt.PromptHidden:Connect(cleanup))
		table.insert(links, prompt.Destroying:Connect(cleanup))
		table.insert(links, prompt:GetPropertyChangedSignal("Enabled"):Connect(function() if not prompt.Enabled then cleanup() end end))
	end
	-- Register all game-owned prompt families without changing eligibility.
	local watchers: { [ProximityPrompt]: { RBXScriptConnection } } = {}
	local function watch(instance: Instance)
		if not instance:IsA("ProximityPrompt") or watchers[instance] then return end
		local prompt = instance
		local function configure()
			if titles[prompt.Name] then
				prompt.Style = Enum.ProximityPromptStyle.Custom
				prompt:SetAttribute("HUDCustomAction", true)
			end
		end
		local function unwatch()
			if entries[prompt] then entries[prompt]() end
			local list = watchers[prompt]
			if list then for _, connection in list do connection:Disconnect() end end
			watchers[prompt] = nil
		end
		watchers[prompt] = {
			prompt:GetPropertyChangedSignal("Name"):Connect(configure),
			prompt.Destroying:Connect(unwatch),
			prompt.AncestryChanged:Connect(function() if not prompt:IsDescendantOf(workspace) then unwatch() end end),
		}
		configure()
	end
	Prompts.PromptShown:Connect(show)
	workspace.DescendantAdded:Connect(watch)
	for _, instance in workspace:GetDescendants() do watch(instance) end
	player.CharacterRemoving:Connect(function()
		local pending = table.clone(entries)
		for _, cleanup in pending do cleanup() end
	end)
end
return Repair
