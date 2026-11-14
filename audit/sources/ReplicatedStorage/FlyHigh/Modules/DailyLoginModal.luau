--!strict
-- Interactive 7-day non-resetting Daily Login modal & Lobby dock trigger for Fly High.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Modules = script.Parent
local AdventureCatalog = require(Modules:WaitForChild("HUDAdventureCatalog"))
local Catalog = require(Modules:WaitForChild("DailyAndShopCatalog"))
local HUDMotion = require(Modules:WaitForChild("HUDMotion"))

local DailyLoginModal = {}

local function stroke(parent: GuiObject, color: Color3, thickness: number, transparency: number?): UIStroke
	local s = Instance.new("UIStroke")
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Color = color
	s.Thickness = thickness
	s.Transparency = transparency or 0
	s.Parent = parent
	return s
end

local function makeLabel(
	parent: Instance,
	name: string,
	text: string,
	size: number,
	font: Enum.Font,
	color: Color3,
	align: Enum.TextXAlignment?
): TextLabel
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
	lbl.TextXAlignment = align or Enum.TextXAlignment.Center
	lbl.TextYAlignment = Enum.TextYAlignment.Center
	lbl.Parent = parent
	local s = Instance.new("UIStroke")
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
	s.Color = Color3.fromRGB(4, 10, 24)
	s.Thickness = 1.5
	s.Parent = lbl
	return lbl
end

local function makeCoinBadge(parent: Instance, name: string, zBase: number): (Frame, TextLabel)
	local pill = Instance.new("Frame")
	pill.Name = name
	pill.BackgroundColor3 = Color3.fromRGB(5, 19, 50)
	pill.BorderSizePixel = 0
	pill.Active = false
	pill.ZIndex = zBase
	pill.Parent = parent
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(1, 0)
	c.Parent = pill
	stroke(pill, Color3.fromRGB(251, 191, 36), 1.5, 0.08)

	local icon = Instance.new("ImageLabel")
	icon.Name = "CoinIcon"
	icon.BackgroundTransparency = 1
	icon.BorderSizePixel = 0
	icon.ScaleType = Enum.ScaleType.Fit
	icon.AnchorPoint = Vector2.new(0, 0.5)
	icon.Position = UDim2.new(0, 6, 0.5, 0)
	icon.Size = UDim2.fromOffset(18, 18)
	icon.ZIndex = zBase + 1
	local sprite = AdventureCatalog.icon_coin
	if sprite then
		icon.Image = sprite[1]
	end
	icon.Parent = pill

	local text = makeLabel(pill, "CoinAmount", "0 Koin", 12, Enum.Font.GothamBlack, Color3.fromRGB(254, 240, 138), Enum.TextXAlignment.Center)
	text.Position = UDim2.fromOffset(24, 0)
	text.Size = UDim2.new(1, -28, 1, 0)
	text.TextScaled = false
	text.ZIndex = zBase + 1
	return pill, text
end

local function buildIconView(parent: Instance, key: string, zIndex: number): Frame
	local box = Instance.new("Frame")
	box.Name = "RewardArt"
	box.BackgroundColor3 = Color3.fromRGB(6, 20, 51)
	box.BorderSizePixel = 0
	box.Active = false
	box.ZIndex = zIndex
	box.Parent = parent
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = box
	stroke(box, Color3.fromRGB(30, 75, 138), 1.2, 0.15)

	local function attachImage(spriteKey: string, pos: UDim2, size: UDim2)
		local img = Instance.new("ImageLabel")
		img.Name = "Sprite_" .. spriteKey
		img.BackgroundTransparency = 1
		img.BorderSizePixel = 0
		img.ScaleType = Enum.ScaleType.Fit
		img.Position = pos
		img.Size = size
		img.ZIndex = zIndex + 1
		local sprite = AdventureCatalog[spriteKey]
		if sprite then
			img.Image = sprite[1]
		end
		img.Parent = box
	end

	if key == "both_supply" then
		attachImage("art_turbo_gas", UDim2.fromScale(0.02, 0.08), UDim2.fromScale(0.5, 0.84))
		attachImage("art_tali_awet", UDim2.fromScale(0.48, 0.08), UDim2.fromScale(0.5, 0.84))
	elseif key == "grand_day7" then
		attachImage("art_shop_kit_v2", UDim2.fromScale(0.02, 0.08), UDim2.fromScale(0.5, 0.84))
		attachImage("art_cosmetic_frame", UDim2.fromScale(0.5, 0.08), UDim2.fromScale(0.48, 0.84))
	else
		attachImage(key, UDim2.fromScale(0.1, 0.08), UDim2.fromScale(0.8, 0.84))
	end

	return box
end

function DailyLoginModal.Ensure(screenGui: ScreenGui, player: Player)
	local existing = screenGui:FindFirstChild("DailyLoginModal")
	if existing and existing:IsA("Frame") then
		return existing
	end

	local remotes = ReplicatedStorage:WaitForChild("FlyHigh"):WaitForChild("Remotes")
	local dailyFn = remotes:WaitForChild("DailyLoginFunction", 15) :: RemoteFunction?

	-- Lobby dock button styled cleanly by HUDTheme as "dock"
	local dockBtn = screenGui:FindFirstChild("DailyToggleButton") :: TextButton?
	if not dockBtn then
		dockBtn = Instance.new("TextButton")
		dockBtn.Name = "DailyToggleButton"
		dockBtn.Size = UDim2.fromOffset(50, 58)
		dockBtn.Position = UDim2.fromOffset(18, 86)
		dockBtn.BackgroundColor3 = Color3.fromRGB(245, 158, 11)
		dockBtn.BorderSizePixel = 0
		dockBtn.Text = "HARIAN"
		dockBtn.TextColor3 = Color3.new(1, 1, 1)
		dockBtn.Font = Enum.Font.FredokaOne
		dockBtn.TextSize = 11
		dockBtn.ZIndex = 10
		dockBtn.Parent = screenGui
		local dc = Instance.new("UICorner")
		dc.CornerRadius = UDim.new(0, 12)
		dc.Parent = dockBtn
	end

	local modal = Instance.new("Frame")
	modal.Name = "DailyLoginModal"
	modal.Size = UDim2.fromOffset(660, 504)
	modal.Position = UDim2.new(0.5, -330, 0.5, -252)
	modal.BackgroundColor3 = Color3.fromRGB(10, 30, 74)
	modal.BorderSizePixel = 0
	modal.Active = true
	modal.Visible = false
	modal.ZIndex = 22
	modal.Parent = screenGui

	local mc = Instance.new("UICorner")
	mc.CornerRadius = UDim.new(0, 18)
	mc.Parent = modal
	stroke(modal, Color3.fromRGB(226, 180, 90), 2, 0.1)

	local closeBtn = Instance.new("TextButton")
	closeBtn.Name = "DailyCloseButton"
	closeBtn.Text = "×"
	closeBtn.Font = Enum.Font.FredokaOne
	closeBtn.TextSize = 23
	closeBtn.TextColor3 = Color3.new(1, 1, 1)
	closeBtn.BackgroundColor3 = Color3.fromRGB(190, 48, 48)
	closeBtn.BorderSizePixel = 0
	closeBtn.Size = UDim2.fromOffset(44, 44)
	closeBtn.ZIndex = 28
	closeBtn.Parent = modal
	local cc = Instance.new("UICorner")
	cc.CornerRadius = UDim.new(1, 0)
	cc.Parent = closeBtn
	closeBtn.Activated:Connect(function()
		HUDMotion.SetVisible(modal, false)
	end)

	local title = makeLabel(modal, "DailyTitle", "HADIAH HARIAN", 21, Enum.Font.GothamBlack, Color3.fromRGB(255, 246, 209), Enum.TextXAlignment.Center)
	title.ZIndex = 24

	local subtitle = makeLabel(modal, "DailySubtitle", "Absen tidak akan hangus walau sempat bolong!", 12, Enum.Font.GothamBold, Color3.fromRGB(186, 220, 255), Enum.TextXAlignment.Center)
	subtitle.ZIndex = 24

	local coinPill, coinAmountLbl = makeCoinBadge(modal, "DailyCoinPill", 24)

	local gridContainer = Instance.new("Frame")
	gridContainer.Name = "DailyCardsContainer"
	gridContainer.BackgroundTransparency = 1
	gridContainer.BorderSizePixel = 0
	gridContainer.Active = false
	gridContainer.ZIndex = 23
	gridContainer.Parent = modal

	local dayWidgets = {}
	for day = 1, 7 do
		local reward = Catalog.DAILY_REWARDS[day]
		local card = Instance.new("Frame")
		card.Name = "DayCard" .. tostring(day)
		card.BackgroundColor3 = Color3.fromRGB(16, 43, 96)
		card.BorderSizePixel = 0
		card.Active = false
		card.ZIndex = 23
		card.Parent = gridContainer
		local cardCorner = Instance.new("UICorner")
		cardCorner.CornerRadius = UDim.new(0, 13)
		cardCorner.Parent = card
		local cardStroke = stroke(card, Color3.fromRGB(47, 104, 175), 1.6, 0.15)
		local cardGrad = Instance.new("UIGradient")
		cardGrad.Rotation = 90
		cardGrad.Color = ColorSequence.new(Color3.fromRGB(16, 43, 96), Color3.fromRGB(8, 26, 63))
		cardGrad.Parent = card

		local dayPill = Instance.new("Frame")
		dayPill.Name = "DayPill"
		dayPill.BorderSizePixel = 0
		dayPill.BackgroundColor3 = Color3.fromRGB(12, 34, 78)
		dayPill.ZIndex = 24
		dayPill.Parent = card
		local dpCorner = Instance.new("UICorner")
		dpCorner.CornerRadius = UDim.new(1, 0)
		dpCorner.Parent = dayPill
		local dayLbl = makeLabel(dayPill, "DayText", "HARI " .. tostring(day), 10, Enum.Font.GothamBlack, Color3.fromRGB(224, 242, 254), Enum.TextXAlignment.Center)
		dayLbl.Size = UDim2.fromScale(1, 1)
		dayLbl.TextScaled = true
		dayLbl.ZIndex = 25
		local dCap = Instance.new("UITextSizeConstraint")
		dCap.MinTextSize = 7
		dCap.MaxTextSize = 10
		dCap.Parent = dayLbl

		local statusPill = makeLabel(card, "StatusTag", "TERKUNCI", 10, Enum.Font.GothamBlack, Color3.fromRGB(148, 163, 184), Enum.TextXAlignment.Right)
		statusPill.TextScaled = true
		statusPill.ZIndex = 25
		local stCap = Instance.new("UITextSizeConstraint")
		stCap.MinTextSize = 7
		stCap.MaxTextSize = 10
		stCap.Parent = statusPill

		local artBox = buildIconView(card, reward.icon, 24)
		local primaryLbl = makeLabel(card, "RewardPrimary", reward.primaryText, 12, Enum.Font.GothamBlack, Color3.new(1, 1, 1), day == 7 and Enum.TextXAlignment.Left or Enum.TextXAlignment.Center)
		primaryLbl.TextWrapped = false
		primaryLbl.TextScaled = true
		primaryLbl.ZIndex = 25
		local pCap = Instance.new("UITextSizeConstraint")
		pCap.MinTextSize = 6
		pCap.MaxTextSize = 12
		pCap.Parent = primaryLbl

		local subLbl = makeLabel(card, "RewardSub", reward.subText, 11, Enum.Font.GothamBold, Color3.fromRGB(254, 240, 138), day == 7 and Enum.TextXAlignment.Left or Enum.TextXAlignment.Center)
		subLbl.TextWrapped = (day == 7)
		subLbl.TextScaled = true
		subLbl.ZIndex = 25
		local sCap = Instance.new("UITextSizeConstraint")
		sCap.MinTextSize = 8
		sCap.MaxTextSize = 11
		sCap.Parent = subLbl

		dayWidgets[day] = {
			card = card,
			stroke = cardStroke,
			grad = cardGrad,
			dayPill = dayPill,
			dayLbl = dayLbl,
			status = statusPill,
			art = artBox,
			primary = primaryLbl,
			sub = subLbl,
		}
	end

	local claimBtn = Instance.new("TextButton")
	claimBtn.Name = "ClaimDailyButton"
	claimBtn.Text = ""
	claimBtn.TextTransparency = 1
	claimBtn.AutoButtonColor = false
	claimBtn.BackgroundTransparency = 1
	claimBtn.BorderSizePixel = 0
	claimBtn.ZIndex = 24
	claimBtn.Parent = modal

	local claimVis = HUDMotion.Visual(claimBtn)
	claimVis.BackgroundTransparency = 1
	local claimFill = Instance.new("Frame")
	claimFill.Name = "ClaimFill"
	claimFill.Size = UDim2.fromScale(1, 1)
	claimFill.BackgroundColor3 = Color3.new(1, 1, 1)
	claimFill.BorderSizePixel = 0
	claimFill.ZIndex = 24
	claimFill.Parent = claimVis
	local cfCorner = Instance.new("UICorner")
	cfCorner.CornerRadius = UDim.new(0, 12)
	cfCorner.Parent = claimFill
	local claimStroke = stroke(claimFill, Color3.fromRGB(134, 239, 172), 1.8, 0.08)
	local claimGrad = Instance.new("UIGradient")
	claimGrad.Rotation = 90
	claimGrad.Color = ColorSequence.new(Color3.fromRGB(63, 230, 125), Color3.fromRGB(18, 128, 56))
	claimGrad.Parent = claimFill
	local claimLbl = makeLabel(claimFill, "ClaimText", "KLAIM HADIAH HARI INI!", 15, Enum.Font.GothamBlack, Color3.new(1, 1, 1), Enum.TextXAlignment.Center)
	claimLbl.Size = UDim2.new(1, -16, 1, 0)
	claimLbl.Position = UDim2.fromOffset(8, 0)
	claimLbl.ZIndex = 25

	local statusMsg = makeLabel(modal, "DailyFooterNote", "Hadiah otomatis tersimpan aman di inventaris.", 11, Enum.Font.GothamBold, Color3.fromRGB(147, 197, 253), Enum.TextXAlignment.Center)
	statusMsg.ZIndex = 24

	local isBusy = false
	local feedbackMessage: string? = nil

	local function refreshVisuals()
		local progress = math.clamp(tonumber(player:GetAttribute("DailyProgress")) or 1, 1, 7)
		local claimedToday = player:GetAttribute("DailyClaimedToday") == true
		local coins = tonumber(player:GetAttribute("SkyCoins")) or 0
		coinAmountLbl.Text = tostring(coins) .. " Koin"

		-- Step completed today if claimedToday is true:
		-- Since progress advances (step % 7) + 1 upon claiming:
		-- If progress == 1 and claimedToday == true => Days 1..7 all claimed this cycle!
		-- Otherwise Days 1..(progress - 1) are already claimed.
		local completedCount = (claimedToday and progress == 1) and 7 or (progress - 1)
		local readyDay = not claimedToday and progress or nil

		for day = 1, 7 do
			local w = dayWidgets[day]
			local compactDays = (day < 7) and ((w.dayPill.AbsoluteSize.X > 0 and w.dayPill.AbsoluteSize.X <= 38) or (modal.AbsoluteSize.X > 0 and modal.AbsoluteSize.X < 420))
			w.dayLbl.Text = (compactDays and "H" or "HARI ") .. tostring(day)
			local isClaimed = day <= completedCount
			local isReady = readyDay == day
			local isNext = claimedToday and (day == progress)

			if isClaimed then
				w.grad.Color = ColorSequence.new(Color3.fromRGB(12, 42, 72), Color3.fromRGB(8, 28, 52))
				w.stroke.Color = Color3.fromRGB(16, 185, 129)
				w.stroke.Thickness = 1.6
				w.dayPill.BackgroundColor3 = Color3.fromRGB(6, 95, 70)
				w.dayLbl.TextColor3 = Color3.fromRGB(167, 243, 208)
				w.status.Text = "✓ DIKLAIM"
				w.status.TextColor3 = Color3.fromRGB(52, 211, 153)
			elseif isReady then
				w.grad.Color = ColorSequence.new(Color3.fromRGB(28, 70, 148), Color3.fromRGB(12, 38, 92))
				w.stroke.Color = Color3.fromRGB(253, 224, 71)
				w.stroke.Thickness = 2.4
				w.dayPill.BackgroundColor3 = Color3.fromRGB(217, 119, 6)
				w.dayLbl.TextColor3 = Color3.fromRGB(254, 249, 195)
				w.status.Text = "SIAP!"
				w.status.TextColor3 = Color3.fromRGB(253, 224, 71)
			elseif day == 7 then
				w.grad.Color = ColorSequence.new(Color3.fromRGB(39, 50, 112), Color3.fromRGB(11, 19, 54))
				w.stroke.Color = Color3.fromRGB(251, 191, 36)
				w.stroke.Thickness = 1.8
				w.dayPill.BackgroundColor3 = Color3.fromRGB(146, 64, 14)
				w.dayLbl.TextColor3 = Color3.fromRGB(254, 240, 138)
				w.status.Text = isNext and "BESOK" or "GRAND"
				w.status.TextColor3 = Color3.fromRGB(251, 191, 36)
			else
				w.grad.Color = ColorSequence.new(Color3.fromRGB(11, 27, 64), Color3.fromRGB(6, 17, 44))
				w.stroke.Color = Color3.fromRGB(37, 74, 132)
				w.stroke.Thickness = 1.3
				w.dayPill.BackgroundColor3 = Color3.fromRGB(15, 36, 78)
				w.dayLbl.TextColor3 = Color3.fromRGB(148, 163, 184)
				w.status.Text = isNext and "BESOK" or "TERKUNCI"
				w.status.TextColor3 = isNext and Color3.fromRGB(125, 211, 252) or Color3.fromRGB(100, 116, 139)
			end
		end

		if isBusy then
			claimBtn.Active = false
			claimBtn.Interactable = false
			claimGrad.Color = ColorSequence.new(Color3.fromRGB(56, 189, 248), Color3.fromRGB(3, 105, 161))
			claimStroke.Color = Color3.fromRGB(125, 211, 252)
			claimLbl.Text = "MENYIMPAN KLAIM..."
		elseif not claimedToday and player:GetAttribute("DataReady") == true then
			claimBtn.Active = true
			claimBtn.Interactable = true
			claimGrad.Color = ColorSequence.new(Color3.fromRGB(63, 230, 125), Color3.fromRGB(18, 128, 56))
			claimStroke.Color = Color3.fromRGB(134, 239, 172)
			claimLbl.Text = string.format("KLAIM HADIAH HARI KE-%d!", progress)
		elseif player:GetAttribute("DataReady") ~= true then
			claimBtn.Active = false
			claimBtn.Interactable = false
			claimGrad.Color = ColorSequence.new(Color3.fromRGB(40, 60, 94), Color3.fromRGB(23, 36, 59))
			claimStroke.Color = Color3.fromRGB(71, 85, 105)
			claimLbl.Text = "MEMUAT DATA..."
		else
			claimBtn.Active = false
			claimBtn.Interactable = false
			claimGrad.Color = ColorSequence.new(Color3.fromRGB(40, 60, 94), Color3.fromRGB(23, 36, 59))
			claimStroke.Color = Color3.fromRGB(71, 85, 105)
			local countdown = Catalog.FormatDurationHMS(Catalog.SecondsUntilNextUTC7Day())
			claimLbl.Text = "SUDAH DIKLAIM • BESOK " .. countdown
		end

		if feedbackMessage and feedbackMessage ~= "" then
			statusMsg.Text = feedbackMessage
			statusMsg.TextColor3 = Color3.fromRGB(254, 240, 138)
		else
			statusMsg.Text = "Streak tidak hangus jika terlewat · Reset harian 00:00 WIB"
			statusMsg.TextColor3 = Color3.fromRGB(147, 197, 253)
		end
	end

	local function syncFromServer()
		if not dailyFn then return end
		local ok, res = pcall(function()
			return dailyFn:InvokeServer("GetState")
		end)
		if ok and type(res) == "table" and res.state then
			refreshVisuals()
		end
	end

	claimBtn.Activated:Connect(function()
		if isBusy or player:GetAttribute("DailyClaimedToday") == true or not dailyFn then
			return
		end
		isBusy = true
		feedbackMessage = nil
		refreshVisuals()
		local ok, res = pcall(function()
			return dailyFn:InvokeServer("Claim")
		end)
		isBusy = false
		if ok and type(res) == "table" then
			feedbackMessage = res.message or (res.ok and "Hadiah berhasil diklaim!" or "Klaim gagal.")
		else
			feedbackMessage = "Koneksi bermasalah. Coba lagi."
		end
		refreshVisuals()
	end)

	dockBtn.Activated:Connect(function()
		if player:GetAttribute("InFlight") == true then return end
		feedbackMessage = nil
		HUDMotion.Toggle(modal)
		if modal.Visible then
			refreshVisuals()
			task.spawn(syncFromServer)
		end
	end)

	for _, attr in { "DailyProgress", "DailyClaimedToday", "SkyCoins", "DataReady" } do
		player:GetAttributeChangedSignal(attr):Connect(refreshVisuals)
	end

	player:GetAttributeChangedSignal("InFlight"):Connect(function()
		if player:GetAttribute("InFlight") == true and modal.Visible then
			HUDMotion.SetVisible(modal, false)
		end
	end)

	modal:GetPropertyChangedSignal("Visible"):Connect(function()
		if modal.Visible then
			refreshVisuals()
		end
	end)

	modal:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		if modal.Visible then
			refreshVisuals()
		end
	end)

	-- Live countdown refresh once per second only while modal is open
	task.spawn(function()
		while modal.Parent do
			task.wait(1)
			if modal.Visible and player:GetAttribute("DailyClaimedToday") == true then
				refreshVisuals()
			end
		end
	end)

	-- Auto-open once per Lobby session if unclaimed today
	local autoPrompted = false
	task.spawn(function()
		local deadline = os.clock() + 12
		while player:GetAttribute("DataReady") ~= true and os.clock() < deadline do
			task.wait(0.25)
		end
		if autoPrompted or not modal.Parent then return end
		task.wait(1.5)
		if autoPrompted or not modal.Parent then return end
		if player:GetAttribute("DataReady") == true and player:GetAttribute("InFlight") ~= true then
			syncFromServer()
			if player:GetAttribute("DailyClaimedToday") ~= true and player:GetAttribute("InFlight") ~= true and not modal.Visible then
				autoPrompted = true
				HUDMotion.SetVisible(modal, true)
			end
		end
	end)

	refreshVisuals()
	return modal
end

return DailyLoginModal
