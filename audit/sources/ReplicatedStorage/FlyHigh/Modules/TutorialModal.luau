--!strict
-- Interactive 3-Tab Tutorial Modal ("CARA BERMAIN" / "HOW TO PLAY") triggered from WelcomeSign at spawn.
local ProximityPromptService = game:GetService("ProximityPromptService")

local Modules = script.Parent
local AdventureArt = require(Modules:WaitForChild("HUDAdventureArt"))
local HUDMotion = require(Modules:WaitForChild("HUDMotion"))

local TutorialModal = {}

type CardSpec = {
	icon: string,
	accent: Color3,
	title: string,
	body: string,
}

type PageSpec = {
	id: string,
	tabName: string,
	tabLabel: string,
	pageName: string,
	cards: { CardSpec },
}

local PAGES: { PageSpec } = {
	{
		id = "basics",
		tabName = "TabBasicsButton",
		tabLabel = "DASAR",
		pageName = "PageBasics",
		cards = {
			{
				icon = "master_crest",
				accent = Color3.fromRGB(251, 191, 36),
				title = "1. Masuk Dermaga (1–3 Pemain)",
				body = "Pilih salah satu dari 5 dermaga (Pod A–E). Pemain pertama jadi Party Master untuk menekan Mulai Terbang.",
			},
			{
				icon = "goal_marker",
				accent = Color3.fromRGB(56, 189, 248),
				title = "2. Capai Istana Awan (10.000 km)",
				body = "Terbang melewati 5 zona langit hingga 10.000 km. Di bawah 300 km bebas rintangan alam, tapi hindari tabrakan balon lain.",
			},
			{
				icon = "ping_danger",
				accent = Color3.fromRGB(248, 113, 113),
				title = "3. Waspadai 5 Lubang Balon",
				body = "Makin banyak lubang, balon makin cepat turun. Di 5 lubang balon terjun bebas — tambal sebelum menyentuh tanah!",
			},
		},
	},
	{
		id = "roles",
		tabName = "TabRolesButton",
		tabLabel = "PERAN",
		pageName = "PageRoles",
		cards = {
			{
				icon = "gas_normal",
				accent = Color3.fromRGB(251, 191, 36),
				title = "Pilot — Kemudi & Gas",
				body = "Duduk di kemudi [E], gerak (WASD/Analog), tahan GAS untuk naik ([Z] Auto-Gas), dan tekan [H] untuk berdiri.",
			},
			{
				icon = "art_shop_ak_v2",
				accent = Color3.fromRGB(96, 165, 250),
				title = "Gunner — Tembak Rintangan",
				body = "Ambil senjata di rak [E], tembak musuh terbang ([R] reload, [G] taruh). Hazard cuaca kebal peluru — jangan tembak balon sendiri!",
			},
			{
				icon = "ping_repair",
				accent = Color3.fromRGB(52, 211, 153),
				title = "Engineer — Tali & Tambal",
				body = "Pasang tali [E] → Panjat [F] → tahan [E] di lubang → Turun [Q]. Jangan biarkan tali 0%! Tahan [C] perbaiki tali, [B] tarik rekan.",
			},
		},
	},
	{
		id = "survival",
		tabName = "TabSurvivalButton",
		tabLabel = "BERTAHAN",
		pageName = "PageSurvival",
		cards = {
			{
				icon = "jump_normal",
				accent = Color3.fromRGB(250, 204, 21),
				title = "Dinding Badai — Lompat Turun Cepat",
				body = "Saat peringatan Dinding Badai muncul, kru non-Pilot cukup Lompat (Space/Tombol Lompat) agar balon turun melewati celah bawah.",
			},
			{
				icon = "art_shop_kit_v2",
				accent = Color3.fromRGB(74, 222, 128),
				title = "Perbekalan & Clutch Save",
				body = "Emergency Kit menambal semua lubang + perisai 60 dtk (bisa dipakai saat terjun bebas!). Turbo Gas & Tali Awet membantu perjalanan.",
			},
			{
				icon = "ping_normal",
				accent = Color3.fromRGB(167, 139, 250),
				title = "Mode Arwah (Ghost Spotter)",
				body = "Jika gugur saat rekan masih hidup, tekan [V] untuk menandai bahaya. Jika tim mencapai 10.000 km, kamu ikut hidup kembali & menang!",
			},
		},
	},
}

local function addStroke(parent: GuiObject, color: Color3, thickness: number, transparency: number?): UIStroke
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
	align: Enum.TextXAlignment?,
	strokeThickness: number?
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
	lbl.TextXAlignment = align or Enum.TextXAlignment.Left
	lbl.TextYAlignment = Enum.TextYAlignment.Center
	lbl.Parent = parent
	local s = Instance.new("UIStroke")
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
	s.Color = Color3.fromRGB(4, 10, 24)
	s.Thickness = strokeThickness or 1.4
	s.Parent = lbl
	return lbl
end

local function makeTabButton(parent: Instance, name: string, caption: string, zBase: number)
	local btn = Instance.new("TextButton")
	btn.Name = name
	btn.Text = ""
	btn.TextTransparency = 1
	btn.AutoButtonColor = false
	btn.BackgroundTransparency = 1
	btn.BorderSizePixel = 0
	btn.ZIndex = zBase
	btn.Parent = parent

	local vis = HUDMotion.Visual(btn)
	vis.BackgroundTransparency = 1

	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.fromScale(1, 1)
	fill.BackgroundColor3 = Color3.new(1, 1, 1)
	fill.BorderSizePixel = 0
	fill.ZIndex = zBase + 1
	fill.Parent = vis

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = fill

	local rim = addStroke(fill, Color3.fromRGB(45, 88, 153), 1.5, 0.1)
	local grad = Instance.new("UIGradient")
	grad.Rotation = 90
	grad.Color = ColorSequence.new(Color3.fromRGB(14, 38, 84), Color3.fromRGB(9, 25, 60))
	grad.Parent = fill

	local lbl = makeLabel(fill, "Caption", caption, 12, Enum.Font.GothamBlack, Color3.fromRGB(185, 213, 248), Enum.TextXAlignment.Center, 1.3)
	lbl.Size = UDim2.new(1, -10, 1, 0)
	lbl.Position = UDim2.fromOffset(5, 0)
	lbl.TextWrapped = false
	lbl.TextScaled = true
	lbl.ZIndex = zBase + 2

	local capConstraint = Instance.new("UITextSizeConstraint")
	capConstraint.MinTextSize = 8
	capConstraint.MaxTextSize = 13
	capConstraint.Parent = lbl

	return {
		btn = btn,
		rim = rim,
		grad = grad,
		lbl = lbl,
	}
end

function TutorialModal.Ensure(screenGui: ScreenGui, player: Player): Frame
	local existing = screenGui:FindFirstChild("TutorialModal")
	if existing and existing:IsA("Frame") then
		return existing
	end

	AdventureArt.Preload()

	local modal = Instance.new("Frame")
	modal.Name = "TutorialModal"
	modal.Size = UDim2.fromOffset(580, 474)
	modal.Position = UDim2.new(0.5, -290, 0.5, -237)
	modal.BackgroundColor3 = Color3.fromRGB(10, 30, 74)
	modal.BorderSizePixel = 0
	modal.Active = true
	modal.Visible = false
	modal.ZIndex = 22
	modal.Parent = screenGui

	local modalCorner = Instance.new("UICorner")
	modalCorner.CornerRadius = UDim.new(0, 14)
	modalCorner.Parent = modal

	addStroke(modal, Color3.fromRGB(226, 180, 90), 2, 0)

	local title = makeLabel(modal, "TutorialTitle", "CARA BERMAIN", 21, Enum.Font.GothamBlack, Color3.fromRGB(255, 246, 209), Enum.TextXAlignment.Center, 2.2)
	title.ZIndex = 26

	local subtitle = makeLabel(modal, "TutorialSubtitle", "Panduan singkat 3 langkah menuju Istana Awan", 12, Enum.Font.GothamBold, Color3.fromRGB(147, 197, 253), Enum.TextXAlignment.Center, 1.2)
	subtitle.ZIndex = 26

	local closeBtn = Instance.new("TextButton")
	closeBtn.Name = "TutorialCloseButton"
	closeBtn.Text = "×"
	closeBtn.Font = Enum.Font.FredokaOne
	closeBtn.TextSize = 23
	closeBtn.TextColor3 = Color3.new(1, 1, 1)
	closeBtn.BackgroundColor3 = Color3.fromRGB(22, 68, 122)
	closeBtn.BorderSizePixel = 0
	closeBtn.Size = UDim2.fromOffset(44, 44)
	closeBtn.ZIndex = 28
	closeBtn.Parent = modal
	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(0, 12)
	closeCorner.Parent = closeBtn
	closeBtn.Activated:Connect(function()
		HUDMotion.SetVisible(modal, false)
	end)

	local tabBar = Instance.new("Frame")
	tabBar.Name = "TutorialTabBar"
	tabBar.BackgroundColor3 = Color3.fromRGB(5, 17, 46)
	tabBar.BorderSizePixel = 0
	tabBar.ZIndex = 24
	tabBar.Parent = modal
	local tabCorner = Instance.new("UICorner")
	tabCorner.CornerRadius = UDim.new(0, 11)
	tabCorner.Parent = tabBar
	addStroke(tabBar, Color3.fromRGB(45, 98, 168), 1.4, 0.15)

	local cardsArea = Instance.new("ScrollingFrame")
	cardsArea.Name = "TutorialCardsArea"
	cardsArea.BackgroundTransparency = 1
	cardsArea.BorderSizePixel = 0
	cardsArea.ScrollBarThickness = 0
	cardsArea.ScrollBarImageColor3 = Color3.fromRGB(56, 189, 248)
	cardsArea.ScrollingEnabled = false
	cardsArea.CanvasSize = UDim2.new(0, 0, 0, 0)
	cardsArea.ZIndex = 23
	cardsArea.Parent = modal

	local footer = makeLabel(modal, "TutorialFooterHint", "1 peran aktif per pemain · Bisa berganti peran kapan saja", 12, Enum.Font.GothamBold, Color3.fromRGB(186, 220, 255), Enum.TextXAlignment.Center, 1.1)
	footer.ZIndex = 26

	local tabButtons = {}
	local pageFrames: { [string]: Frame } = {}

	local function setTab(tabId: string)
		modal:SetAttribute("ActiveTutorialTab", tabId)
		cardsArea.CanvasPosition = Vector2.zero
		for _, pageSpec in ipairs(PAGES) do
			local active = pageSpec.id == tabId
			local tb = tabButtons[pageSpec.id]
			if tb then
				tb.rim.Color = if active then Color3.fromRGB(125, 211, 252) else Color3.fromRGB(45, 88, 153)
				tb.grad.Color = if active
					then ColorSequence.new(Color3.fromRGB(56, 189, 248), Color3.fromRGB(3, 105, 161))
					else ColorSequence.new(Color3.fromRGB(14, 38, 84), Color3.fromRGB(9, 25, 60))
				tb.lbl.TextColor3 = if active then Color3.new(1, 1, 1) else Color3.fromRGB(185, 213, 248)
			end
			local pf = pageFrames[pageSpec.id]
			if pf then
				pf.Visible = active
			end
		end
	end

	for i, pageSpec in ipairs(PAGES) do
		local tb = makeTabButton(tabBar, pageSpec.tabName, pageSpec.tabLabel, 25)
		tb.btn.Size = UDim2.new(1 / 3, -4, 1, -6)
		tb.btn.Position = UDim2.new((i - 1) / 3, 2, 0, 3)
		tb.btn.Activated:Connect(function()
			setTab(pageSpec.id)
		end)
		tabButtons[pageSpec.id] = tb

		local pageFrame = Instance.new("Frame")
		pageFrame.Name = pageSpec.pageName
		pageFrame.BackgroundTransparency = 1
		pageFrame.BorderSizePixel = 0
		pageFrame.Size = UDim2.fromScale(1, 1)
		pageFrame.Visible = false
		pageFrame.ZIndex = 23
		pageFrame.Parent = cardsArea
		pageFrames[pageSpec.id] = pageFrame

		for cardIdx, cardSpec in ipairs(pageSpec.cards) do
			local card = Instance.new("Frame")
			card.Name = "TutCard" .. tostring(cardIdx)
			card.BackgroundColor3 = Color3.new(1, 1, 1)
			card.BorderSizePixel = 0
			card.ZIndex = 23
			card.Parent = pageFrame

			local cardCorner = Instance.new("UICorner")
			cardCorner.CornerRadius = UDim.new(0, 13)
			cardCorner.Parent = card
			addStroke(card, cardSpec.accent, 1.6, 0.32)

			local grad = Instance.new("UIGradient")
			grad.Rotation = 90
			grad.Color = ColorSequence.new(Color3.fromRGB(12, 35, 82), Color3.fromRGB(7, 23, 58))
			grad.Parent = card

			local iconSlot = Instance.new("Frame")
			iconSlot.Name = "IconSlot"
			iconSlot.BackgroundColor3 = Color3.fromRGB(6, 20, 51)
			iconSlot.BorderSizePixel = 0
			iconSlot.Active = false
			iconSlot.ZIndex = 24
			iconSlot.Parent = card
			local slotCorner = Instance.new("UICorner")
			slotCorner.CornerRadius = UDim.new(0, 11)
			slotCorner.Parent = iconSlot
			addStroke(iconSlot, cardSpec.accent, 1.4, 0.22)

			local iconArt = Instance.new("Frame")
			iconArt.Name = "IconArt"
			iconArt.BackgroundTransparency = 1
			iconArt.BorderSizePixel = 0
			iconArt.Position = UDim2.fromOffset(5, 5)
			iconArt.Size = UDim2.new(1, -10, 1, -10)
			iconArt.Active = false
			iconArt.ZIndex = 25
			iconArt.Parent = iconSlot
			AdventureArt.Draw(iconArt, cardSpec.icon, 25, "fit")

			local cTitle = makeLabel(card, "CardTitle", cardSpec.title, 15, Enum.Font.GothamBlack, cardSpec.accent, Enum.TextXAlignment.Left, 1.4)
			cTitle.TextWrapped = false
			cTitle.TextScaled = true
			cTitle.ZIndex = 25
			local titleConstraint = Instance.new("UITextSizeConstraint")
			titleConstraint.MinTextSize = 10
			titleConstraint.MaxTextSize = 15
			titleConstraint.Parent = cTitle

			local cBody = makeLabel(card, "CardBody", cardSpec.body, 13, Enum.Font.GothamMedium, Color3.fromRGB(220, 238, 255), Enum.TextXAlignment.Left, 1.1)
			cBody.TextWrapped = true
			cBody.TextScaled = false
			cBody.TextYAlignment = Enum.TextYAlignment.Top
			cBody.ZIndex = 25
		end
	end

	setTab("basics")

	ProximityPromptService.PromptTriggered:Connect(function(prompt, triggerPlayer)
		if triggerPlayer == player and prompt.Name == "TutorialPrompt" and modal.Parent then
			if player:GetAttribute("InFlight") == true then
				return
			end
			if not modal.Visible then
				setTab("basics")
			end
			HUDMotion.SetVisible(modal, true)
		end
	end)

	player:GetAttributeChangedSignal("InFlight"):Connect(function()
		if player:GetAttribute("InFlight") == true and modal.Visible then
			HUDMotion.SetVisible(modal, false)
		end
	end)

	return modal
end

return TutorialModal
