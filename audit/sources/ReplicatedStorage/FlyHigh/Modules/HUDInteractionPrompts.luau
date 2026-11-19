--!strict
-- Custom visuals only: ProximityPrompt still owns eligibility/input/hold duration.
local Prompts = game:GetService("ProximityPromptService")
local Input = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local TouchInputGuard = require(script.Parent.TouchInputGuard)
local Repair = {}
local titles: { [string]: string } = {
 PatchPrompt="TAMBAL BALON", RepairRopePrompt="PERBAIKI TALI",
 HelmPrompt="PEGANG KEMUDI", PickupPrompt="AMBIL SENJATA",
 StartPrompt="MULAI TERBANG", ReturnPrompt="KEMBALI KE PULAU",
 PhotoPrompt="FOTO KEMENANGAN", SitPrompt="DUDUK",
 TetherPrompt="PASANG TALI", DetachTetherPrompt="LEPAS TALI",
 ClimbPrompt="PANJAT KUBAH", DescendPrompt="TURUN KE GONDOLA",
 PullCrewPrompt="TARIK REKAN", TutorialPrompt="CARA BERMAIN",
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
		local width, height = 196, if touch then 56 else 50
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
		local capSize = if touch then 44 else 34
		local textX = 8 + capSize + 10
		-- The key cap doubles as the hold gauge (playtest iPad 17 Nov: the old 2 px bar
		-- under the text was invisible under a thumb). A teal disc fills it bottom-up.
		local capRing = Instance.new("Frame")
		capRing.Name = "InputRing"
		capRing.Position = UDim2.fromOffset(8, (height - capSize) / 2)
		capRing.Size = UDim2.fromOffset(capSize, capSize)
		capRing.BackgroundColor3 = Color3.fromRGB(27, 62, 91)
		capRing.BackgroundTransparency = 0.35
		capRing.BorderSizePixel = 0
		capRing.Parent = button
		local ringCorner = Instance.new("UICorner")
		ringCorner.CornerRadius = UDim.new(0.5, 0)
		ringCorner.Parent = capRing
		local ringStroke = Instance.new("UIStroke")
		ringStroke.Name = "HoldRingStroke"
		ringStroke.Color = Color3.fromRGB(255, 222, 146)
		ringStroke.Thickness = 2
		ringStroke.Transparency = 0.2
		ringStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		ringStroke.Parent = capRing
		local fill = Instance.new("Frame")
		fill.Name = "HoldFill"
		fill.Size = UDim2.fromScale(1, 1)
		fill.BackgroundColor3 = Color3.fromRGB(79, 223, 204)
		fill.BackgroundTransparency = 0.05
		fill.BorderSizePixel = 0
		fill.Visible = false
		fill.Parent = capRing
		local fillCorner = Instance.new("UICorner")
		fillCorner.CornerRadius = UDim.new(0.5, 0)
		fillCorner.Parent = fill
		local fillGradient = Instance.new("UIGradient")
		fillGradient.Rotation = -90
		fillGradient.Parent = fill
		local function setProgress(p: number)
			p = math.clamp(p, 0, 1)
			fill.Visible = p > 0.001
			if p >= 0.999 then
				fillGradient.Transparency = NumberSequence.new(0)
			elseif p > 0.001 then
				fillGradient.Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(p, 0),
					NumberSequenceKeypoint.new(math.min(p + 0.002, 0.999), 1), NumberSequenceKeypoint.new(1, 1),
				})
			end
			ringStroke.Color = if p > 0.001 then Color3.fromRGB(79, 223, 204) else Color3.fromRGB(255, 222, 146)
		end
		local cap = label("InputKey", key, 0, 0, capSize, capSize, if #key > 3 then 9 else (#key > 1 and 12 or 17), Color3.fromRGB(255, 230, 165))
		cap.Parent = capRing
		cap.ZIndex = 3
		cap.TextXAlignment = Enum.TextXAlignment.Center
		cap.TextStrokeTransparency = 0.25
		if touch then
			-- Keep translated HOLD/TAHAN inside the circle, including devices with
			-- larger preferred text. The centered inner box leaves room for the rim.
			cap.Position = UDim2.fromOffset(6, 12)
			cap.Size = UDim2.fromOffset(capSize - 12, 20)
			cap.TextScaled = true
			local capTextSize = Instance.new("UITextSizeConstraint")
			capTextSize.MinTextSize = 9
			capTextSize.MaxTextSize = 11
			capTextSize.Parent = cap
		end
		local function actionTitle()
			return if prompt.Name == "PickupPrompt" and prompt.ActionText ~= "" then string.upper(prompt.ActionText) else titles[prompt.Name]
		end
		local title = label("Action", actionTitle(), textX, 7, width - textX - 12, 19, if touch then 14 else 13, Color3.fromRGB(249, 248, 238))
		local hint = if prompt.HoldDuration > 0 then string.format("Tahan · %.1f dtk", prompt.HoldDuration):gsub("%.", ",") else (if touch then "Ketuk untuk memilih" else "Tekan untuk memilih")
		local detail = label("ActionDetail", hint, textX, 26, width - textX - 12, 15, 11, Color3.fromRGB(177, 216, 229))
		-- Size the pill to its (possibly translated or font-substituted) text so the
		-- labels never run past the frame on iPad.
		local function fitWidth()
			local titleH = math.max(19, math.ceil(title.TextBounds.Y))
			local detailH = math.max(15, math.ceil(detail.TextBounds.Y))
			local blockH = titleH + 2 + detailH
			local pillH = math.max(height, blockH + 16)
			local top = (pillH - blockH) / 2
			local textW = math.max(title.TextBounds.X, detail.TextBounds.X)
			local w = math.max(150, math.ceil(textX + textW + 16))
			button.Size = UDim2.fromOffset(w, pillH)
			capRing.Position = UDim2.fromOffset(8, (pillH - capSize) / 2)
			title.Position = UDim2.fromOffset(textX, top)
			title.Size = UDim2.fromOffset(w - textX - 10, titleH)
			detail.Position = UDim2.fromOffset(textX, top + titleH + 2)
			detail.Size = UDim2.fromOffset(w - textX - 10, detailH)
		end
		title:GetPropertyChangedSignal("TextBounds"):Connect(fitWidth)
		detail:GetPropertyChangedSignal("TextBounds"):Connect(fitWidth)
		task.defer(fitWidth)
		local links: { RBXScriptConnection } = {}
		local holdStarted: number? = nil
		local pointer: InputObject? = nil
		local closed = false
		local pendingSequence = 0
		local function endPointer()
			if pointer then pointer = nil; prompt:InputHoldEnd() end
		end
		local function reset()
			holdStarted = nil
			setProgress(0)
			detail.Text = hint
		end
		local function cleanup()
			if closed then return end
			closed = true
			for _, link in links do link:Disconnect() end
			endPointer()
			gui:Destroy()
			entries[prompt] = nil
		end
		entries[prompt] = cleanup
		table.insert(links, RunService.RenderStepped:Connect(function()
			if holdStarted and prompt.HoldDuration > 0 then
				setProgress((os.clock() - holdStarted) / prompt.HoldDuration)
			end
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
			if pointer or not TouchInputGuard.IsDirectBegin(button, i) then return end
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
			holdStarted = os.clock()
		end))
		table.insert(links, prompt.PromptButtonHoldEnded:Connect(reset))
		table.insert(links, prompt.Triggered:Connect(function()
			holdStarted = nil
			setProgress(1)
			task.delay(0.35, function() if not closed and not holdStarted then setProgress(0) end end)
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
