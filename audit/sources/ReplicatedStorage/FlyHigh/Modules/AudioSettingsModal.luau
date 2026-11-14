-- Sky Adventure popup UI for Master, Music, and Sound Effect volume sliders & mute toggles.
local UserInputService = game:GetService("UserInputService")

local Modules = script.Parent
local AdventureArt = require(Modules:WaitForChild("HUDAdventureArt"))
local AudioMixer = require(Modules:WaitForChild("AudioMixer"))
local Glyphs = require(Modules:WaitForChild("HUDGlyphs"))
local HUDMotion = require(Modules:WaitForChild("HUDMotion"))

local AudioModal = {}

local FILL_GRADIENTS = {
	Master = ColorSequence.new(Color3.fromRGB(167, 224, 88), Color3.fromRGB(255, 230, 102)),
	Music = ColorSequence.new(Color3.fromRGB(14, 165, 233), Color3.fromRGB(76, 242, 255)),
	SFX = ColorSequence.new(Color3.fromRGB(16, 185, 129), Color3.fromRGB(94, 255, 186)),
}
local MUTED_FILL_GRADIENT = ColorSequence.new(Color3.fromRGB(90, 106, 132), Color3.fromRGB(130, 146, 172))

local function makeLabel(parent: Instance, name: string, text: string, size: number, font: Enum.Font, color: Color3, align: Enum.TextXAlignment?): TextLabel
	local lbl = Instance.new("TextLabel")
	lbl.Name = name
	lbl.BackgroundTransparency = 1
	lbl.BorderSizePixel = 0
	lbl.Active = false
	lbl.Selectable = false
	lbl.Text = text
	lbl.TextSize = size
	lbl.Font = font
	lbl.TextColor3 = color
	lbl.TextStrokeTransparency = 1
	lbl.TextXAlignment = align or Enum.TextXAlignment.Left
	lbl.TextYAlignment = Enum.TextYAlignment.Center
	lbl.Parent = parent
	local s = Instance.new("UIStroke")
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
	s.Color = Color3.fromRGB(4, 10, 24)
	s.Thickness = 1.6
	s.Parent = lbl
	return lbl
end

local function makeStyledButton(parent: Instance, name: string, zIndex: number): (TextButton, Frame, UIStroke)
	local btn = Instance.new("TextButton")
	btn.Name = name
	btn.Text = ""
	btn.TextTransparency = 1
	btn.AutoButtonColor = false
	btn.BackgroundTransparency = 1
	btn.BorderSizePixel = 0
	btn.ZIndex = zIndex
	btn.Parent = parent

	local visual = HUDMotion.Visual(btn)
	visual.BackgroundTransparency = 1

	local pill = Instance.new("Frame")
	pill.Name = "MutePill"
	pill.Size = UDim2.fromScale(1, 1)
	pill.BorderSizePixel = 0
	pill.Active = false
	pill.Selectable = false
	pill.ZIndex = zIndex + 1
	pill.Parent = visual

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = pill

	local rim = Instance.new("UIStroke")
	rim.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	rim.Thickness = 1.8
	rim.Parent = pill

	local grad = Instance.new("UIGradient")
	grad.Rotation = 90
	grad.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(192, 206, 224))
	grad.Parent = pill

	return btn, pill, rim
end

function AudioModal.Ensure(screenGui: ScreenGui, player: Player): Frame
	local existing = screenGui:FindFirstChild("AudioSettingsModal")
	if existing and existing:IsA("Frame") then
		return existing
	end

	AudioMixer.Bind(player)

	local modal = Instance.new("Frame")
	modal.Name = "AudioSettingsModal"
	modal.Size = UDim2.fromOffset(468, 392)
	modal.Position = UDim2.new(0.5, -234, 0.5, -196)
	modal.BackgroundColor3 = Color3.fromRGB(13, 32, 56)
	modal.BorderSizePixel = 0
	modal.Active = true
	modal.Visible = false
	modal.ZIndex = 22
	modal.Parent = screenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 14)
	corner.Parent = modal

	local rim = Instance.new("UIStroke")
	rim.Color = Color3.fromRGB(226, 180, 90)
	rim.Thickness = 2
	rim.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	rim.Parent = modal

	local title = makeLabel(modal, "AudioTitle", "PENGATURAN SUARA", 20, Enum.Font.FredokaOne, Color3.fromRGB(255, 226, 136), Enum.TextXAlignment.Center)
	title.ZIndex = 24

	local subtitle = makeLabel(modal, "AudioSubtitle", "Master mengatur seluruh musik & efek suara", 13, Enum.Font.GothamBold, Color3.fromRGB(186, 226, 248), Enum.TextXAlignment.Center)
	subtitle.ZIndex = 24

	local footerHint = makeLabel(modal, "AudioFooterHint", "Geser slider atau ketuk tombol speaker untuk bisu / buka suara", 12, Enum.Font.Nunito, Color3.fromRGB(147, 197, 253), Enum.TextXAlignment.Center)
	footerHint.ZIndex = 24

	-- Close button is themed as a round Sky Adventure btn_close_v2 control by HUDTheme.
	local closeBtn = Instance.new("TextButton")
	closeBtn.Name = "AudioCloseButton"
	closeBtn.Text = "×"
	closeBtn.Font = Enum.Font.FredokaOne
	closeBtn.TextSize = 23
	closeBtn.TextColor3 = Color3.new(1, 1, 1)
	closeBtn.BackgroundColor3 = Color3.fromRGB(22, 68, 122)
	closeBtn.BorderSizePixel = 0
	closeBtn.Size = UDim2.fromOffset(44, 44)
	closeBtn.ZIndex = 25
	closeBtn.Parent = modal
	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(0, 12)
	closeCorner.Parent = closeBtn
	closeBtn.Activated:Connect(function()
		HUDMotion.SetVisible(modal, false)
	end)

	local activeDrag: { key: string, track: Frame, input: InputObject }? = nil
	local rowControls = {}
	local refreshAll: () -> ()

	local function buildChannelRow(spec)
		local row = Instance.new("Frame")
		row.Name = "AudioRow" .. spec.key
		row.BackgroundColor3 = Color3.fromRGB(10, 29, 70)
		row.BackgroundTransparency = 0.08
		row.BorderSizePixel = 0
		row.Active = true
		row.ZIndex = 23
		row.Parent = modal

		local rowCorner = Instance.new("UICorner")
		rowCorner.CornerRadius = UDim.new(0, 13)
		rowCorner.Parent = row

		local rowStroke = Instance.new("UIStroke")
		rowStroke.Color = Color3.fromRGB(47, 104, 175)
		rowStroke.Transparency = 0.2
		rowStroke.Thickness = 1.4
		rowStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		rowStroke.Parent = row

		local nameLabel = makeLabel(row, "ChannelLabel", spec.label, 14, Enum.Font.GothamBlack, Color3.fromRGB(240, 246, 255), Enum.TextXAlignment.Left)
		nameLabel.ZIndex = 24

		local valueLabel = makeLabel(row, "ChannelValue", "100%", 13, Enum.Font.GothamBlack, spec.accent, Enum.TextXAlignment.Right)
		valueLabel.ZIndex = 24

		local sliderHit = Instance.new("Frame")
		sliderHit.Name = "SliderHit"
		sliderHit.BackgroundTransparency = 1
		sliderHit.BorderSizePixel = 0
		sliderHit.Active = true
		sliderHit.ZIndex = 24
		sliderHit.Parent = row

		local track = Instance.new("Frame")
		track.Name = "SliderTrack"
		track.AnchorPoint = Vector2.new(0, 0.5)
		track.Position = UDim2.new(0, 0, 0.68, 0)
		track.Size = UDim2.new(1, 0, 0, 14)
		track.BackgroundColor3 = Color3.fromRGB(6, 16, 32)
		track.BorderSizePixel = 0
		track.Active = false
		track.ZIndex = 24
		track.Parent = sliderHit

		local trackCorner = Instance.new("UICorner")
		trackCorner.CornerRadius = UDim.new(0.5, 0)
		trackCorner.Parent = track

		local trackStroke = Instance.new("UIStroke")
		trackStroke.Color = Color3.fromRGB(45, 96, 160)
		trackStroke.Thickness = 1.4
		trackStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		trackStroke.Parent = track

		local fillStage = Instance.new("Frame")
		fillStage.Name = "FillStage"
		fillStage.BackgroundTransparency = 1
		fillStage.BorderSizePixel = 0
		fillStage.Position = UDim2.fromOffset(2, 2)
		fillStage.Size = UDim2.new(1, -4, 1, -4)
		fillStage.Active = false
		fillStage.ZIndex = 25
		fillStage.Parent = track

		local fillClip = Instance.new("Frame")
		fillClip.Name = "FillClip"
		fillClip.BackgroundTransparency = 1
		fillClip.BorderSizePixel = 0
		fillClip.ClipsDescendants = true
		fillClip.Size = UDim2.fromScale(1, 1)
		fillClip.Active = false
		fillClip.ZIndex = 25
		fillClip.Parent = fillStage

		local fillBar = Instance.new("Frame")
		fillBar.Name = "FillBar"
		fillBar.BackgroundColor3 = Color3.new(1, 1, 1)
		fillBar.BorderSizePixel = 0
		fillBar.Size = UDim2.fromScale(1, 1)
		fillBar.Active = false
		fillBar.ZIndex = 25
		fillBar.Parent = fillClip

		local fillCorner = Instance.new("UICorner")
		fillCorner.CornerRadius = UDim.new(0.5, 0)
		fillCorner.Parent = fillBar

		local fillGrad = Instance.new("UIGradient")
		fillGrad.Name = "FillGradient"
		fillGrad.Color = FILL_GRADIENTS[spec.key] or MUTED_FILL_GRADIENT
		fillGrad.Parent = fillBar

		local function syncFillWidth()
			local w = math.round(fillStage.AbsoluteSize.X)
			if w > 0 then
				fillBar.Size = UDim2.new(0, w, 1, 0)
			else
				fillBar.Size = UDim2.fromScale(1, 1)
			end
		end
		fillStage:GetPropertyChangedSignal("AbsoluteSize"):Connect(syncFillWidth)

		local knob = Instance.new("Frame")
		knob.Name = "SliderKnob"
		knob.AnchorPoint = Vector2.new(0.5, 0.5)
		knob.Position = UDim2.fromScale(1, 0.5)
		knob.Size = UDim2.fromOffset(22, 22)
		knob.BackgroundColor3 = Color3.fromRGB(246, 251, 255)
		knob.BorderSizePixel = 0
		knob.Active = false
		knob.ZIndex = 26
		knob.Parent = track

		local knobCorner = Instance.new("UICorner")
		knobCorner.CornerRadius = UDim.new(0.5, 0)
		knobCorner.Parent = knob

		local knobStroke = Instance.new("UIStroke")
		knobStroke.Color = spec.accent
		knobStroke.Thickness = 2.4
		knobStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		knobStroke.Parent = knob

		local knobCore = Instance.new("Frame")
		knobCore.Name = "KnobCore"
		knobCore.AnchorPoint = Vector2.new(0.5, 0.5)
		knobCore.Position = UDim2.fromScale(0.5, 0.5)
		knobCore.Size = UDim2.fromOffset(8, 8)
		knobCore.BackgroundColor3 = spec.accent
		knobCore.BorderSizePixel = 0
		knobCore.Active = false
		knobCore.ZIndex = 26
		knobCore.Parent = knob

		local coreCorner = Instance.new("UICorner")
		coreCorner.CornerRadius = UDim.new(0.5, 0)
		coreCorner.Parent = knobCore

		local muteBtn, mutePill, muteRim = makeStyledButton(row, "AudioMute" .. spec.key, 24)
		local iconSlot = Instance.new("Frame")
		iconSlot.Name = "IconSlot"
		iconSlot.AnchorPoint = Vector2.new(0.5, 0.5)
		iconSlot.Position = UDim2.fromScale(0.5, 0.5)
		iconSlot.Size = UDim2.fromOffset(36, 36)
		iconSlot.BackgroundTransparency = 1
		iconSlot.BorderSizePixel = 0
		iconSlot.Active = false
		iconSlot.Selectable = false
		iconSlot.ZIndex = 26
		iconSlot.Parent = HUDMotion.Visual(muteBtn)
		local fallbackGlyph = Glyphs.Draw(iconSlot, "sound")

		local entry = {
			spec = spec,
			row = row,
			valueLabel = valueLabel,
			track = track,
			fillClip = fillClip,
			fillBar = fillBar,
			fillGrad = fillGrad,
			knob = knob,
			knobStroke = knobStroke,
			knobCore = knobCore,
			muteBtn = muteBtn,
			mutePill = mutePill,
			muteRim = muteRim,
			iconSlot = iconSlot,
			fallbackGlyph = fallbackGlyph,
			lastIconKey = nil :: string?,
		}
		table.insert(rowControls, entry)

		local function applyPointerX(screenX: number)
			local w = track.AbsoluteSize.X
			if w <= 1 then
				return
			end
			local norm = math.clamp((screenX - track.AbsolutePosition.X) / w, 0, 1)
			AudioMixer.SetVolume(player, spec.key, norm)
		end

		sliderHit.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				activeDrag = { key = spec.key, track = track, input = input }
				applyPointerX(input.Position.X)
				refreshAll()
			end
		end)

		muteBtn.Activated:Connect(function()
			AudioMixer.ToggleMuted(player, spec.key)
		end)
	end

	for _, spec in AudioMixer.CHANNELS do
		buildChannelRow(spec)
	end

	refreshAll = function()
		if not modal.Parent then
			return
		end
		local masterSilenced = AudioMixer.GetMasterGain(player) <= 0
		if masterSilenced then
			subtitle.Text = "Semua audio dibisukan oleh Master"
			subtitle.TextColor3 = Color3.fromRGB(255, 186, 168)
		else
			subtitle.Text = "Master mengatur keseluruhan musik & efek suara"
			subtitle.TextColor3 = Color3.fromRGB(186, 226, 248)
		end

		for _, entry in rowControls do
			local spec = entry.spec
			local vol = AudioMixer.GetVolume(player, spec.key)
			local muted = AudioMixer.IsMuted(player, spec.key)
			local dimmed = muted or (spec.key ~= "Master" and masterSilenced)
			local draggingThis = activeDrag ~= nil and activeDrag.key == spec.key

			entry.fillClip.Size = UDim2.fromScale(vol, 1)
			entry.fillBar.BackgroundColor3 = Color3.new(1, 1, 1)
			entry.fillGrad.Color = dimmed and MUTED_FILL_GRADIENT or (FILL_GRADIENTS[spec.key] or MUTED_FILL_GRADIENT)

			entry.knob.Position = UDim2.fromScale(vol, 0.5)
			local knobSize = draggingThis and 24 or 20
			entry.knob.Size = UDim2.fromOffset(knobSize, knobSize)
			entry.knobStroke.Color = dimmed and Color3.fromRGB(130, 146, 170) or spec.accent
			entry.knobCore.BackgroundColor3 = dimmed and Color3.fromRGB(130, 146, 170) or spec.accent

			if muted then
				entry.valueLabel.Text = "BISU"
				entry.valueLabel.TextColor3 = Color3.fromRGB(252, 165, 165)
			else
				entry.valueLabel.Text = string.format("%d%%", math.round(vol * 100))
				entry.valueLabel.TextColor3 = dimmed and Color3.fromRGB(154, 174, 202) or spec.accent
			end

			entry.mutePill.BackgroundColor3 = muted and Color3.fromRGB(190, 32, 48)
				or (dimmed and Color3.fromRGB(72, 86, 118) or Color3.fromRGB(136, 48, 224))
			entry.muteRim.Color = muted and Color3.fromRGB(252, 165, 165)
				or (dimmed and Color3.fromRGB(148, 163, 184) or Color3.fromRGB(233, 213, 255))

			local spriteKey = muted and "sound_off" or "sound_on"
			local loaded = AdventureArt.Draw(entry.iconSlot, spriteKey, 26, "fit")
			local glyphKey = muted and "muted" or "sound"
			if entry.lastIconKey ~= glyphKey then
				entry.fallbackGlyph:Destroy()
				entry.fallbackGlyph = Glyphs.Draw(entry.iconSlot, glyphKey)
				entry.lastIconKey = glyphKey
			end
			entry.fallbackGlyph.Visible = not loaded
		end
	end

	local dragChangedConn = UserInputService.InputChanged:Connect(function(input)
		if not activeDrag then
			return
		end
		local isPointer = (activeDrag.input.UserInputType == Enum.UserInputType.MouseButton1 and input.UserInputType == Enum.UserInputType.MouseMovement)
			or (activeDrag.input.UserInputType == Enum.UserInputType.Touch and input == activeDrag.input)
		if not isPointer then
			return
		end
		local w = activeDrag.track.AbsoluteSize.X
		if w > 1 then
			local norm = math.clamp((input.Position.X - activeDrag.track.AbsolutePosition.X) / w, 0, 1)
			AudioMixer.SetVolume(player, activeDrag.key, norm)
		end
	end)

	local function endDrag(input: InputObject?)
		if not activeDrag then
			return
		end
		if input then
			local match = (activeDrag.input.UserInputType == Enum.UserInputType.MouseButton1 and input.UserInputType == Enum.UserInputType.MouseButton1)
				or input == activeDrag.input
			if not match then
				return
			end
		end
		activeDrag = nil
		refreshAll()
	end

	local dragEndedConn = UserInputService.InputEnded:Connect(endDrag)
	local focusConn = UserInputService.WindowFocusReleased:Connect(function()
		endDrag(nil)
	end)
	local visConn = modal:GetPropertyChangedSignal("Visible"):Connect(function()
		if not modal.Visible then
			endDrag(nil)
		else
			refreshAll()
		end
	end)

	local observerConn = AudioMixer.Observe(player, refreshAll)
	modal.Destroying:Connect(function()
		dragChangedConn:Disconnect()
		dragEndedConn:Disconnect()
		focusConn:Disconnect()
		visConn:Disconnect()
		observerConn:Disconnect()
	end)

	refreshAll()
	return modal
end

return AudioModal
