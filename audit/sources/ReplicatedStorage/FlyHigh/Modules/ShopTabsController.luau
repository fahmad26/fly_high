--!strict
-- 3-Tab controller for ShopModal: Tab 1 Robux (Card1/Card2), Tab 2 Perbekalan (Sky Coins), Tab 3 Kosmetik.
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = script.Parent
local AdventureCatalog = require(Modules:WaitForChild("HUDAdventureCatalog"))
local Catalog = require(Modules:WaitForChild("DailyAndShopCatalog"))
local HUDMotion = require(Modules:WaitForChild("HUDMotion"))

local ShopTabsController = {}

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
	lbl.TextXAlignment = align or Enum.TextXAlignment.Left
	lbl.TextYAlignment = Enum.TextYAlignment.Center
	lbl.Parent = parent
	local s = Instance.new("UIStroke")
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
	s.Color = Color3.fromRGB(4, 10, 24)
	s.Thickness = 1.4
	s.Parent = lbl
	return lbl
end

local function makeStyledButton(parent: Instance, name: string, zBase: number): (TextButton, Frame, UIStroke, UIGradient, TextLabel)
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
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 11)
	c.Parent = fill
	local rim = stroke(fill, Color3.fromRGB(125, 211, 252), 1.5, 0.1)
	local grad = Instance.new("UIGradient")
	grad.Rotation = 90
	grad.Color = ColorSequence.new(Color3.fromRGB(56, 189, 248), Color3.fromRGB(3, 105, 161))
	grad.Parent = fill

	local lbl = makeLabel(fill, "Caption", "", 13, Enum.Font.GothamBlack, Color3.new(1, 1, 1), Enum.TextXAlignment.Center)
	lbl.Size = UDim2.new(1, -10, 1, 0)
	lbl.Position = UDim2.fromOffset(5, 0)
	lbl.ZIndex = zBase + 2

	return btn, fill, rim, grad, lbl
end

local function decodeMap(jsonStr: any): { [string]: any }
	if type(jsonStr) ~= "string" or jsonStr == "" then
		return {}
	end
	local ok, decoded = pcall(function()
		return HttpService:JSONDecode(jsonStr)
	end)
	return (ok and type(decoded) == "table") and decoded or {}
end

local function formatRemainingTrial(expiry: number): string
	local rem = math.max(0, expiry - os.time())
	if rem >= 86400 then
		return string.format("UJI %d HR", math.ceil(rem / 86400))
	elseif rem >= 3600 then
		return string.format("UJI %d JAM", math.ceil(rem / 3600))
	end
	return "SEGERA HABIS"
end

function ShopTabsController.Attach(shopModal: Frame, player: Player, setFeedback: (string) -> ())
	local remotes = ReplicatedStorage:WaitForChild("FlyHigh"):WaitForChild("Remotes")
	local coinShopFn = remotes:WaitForChild("ShopCoinFunction", 15) :: RemoteFunction?

	shopModal:SetAttribute("ActiveShopTab", "robux")

	-- Toolbar: 3 Tabs + Coin Balance Pill
	local toolbar = Instance.new("Frame")
	toolbar.Name = "ShopToolbar"
	toolbar.BackgroundTransparency = 1
	toolbar.BorderSizePixel = 0
	toolbar.ZIndex = 24
	toolbar.Parent = shopModal

	local tabRow = Instance.new("Frame")
	tabRow.Name = "TabButtonsBar"
	tabRow.BackgroundColor3 = Color3.fromRGB(5, 17, 46)
	tabRow.BorderSizePixel = 0
	tabRow.ZIndex = 24
	tabRow.Parent = toolbar
	local trc = Instance.new("UICorner")
	trc.CornerRadius = UDim.new(0, 11)
	trc.Parent = tabRow
	stroke(tabRow, Color3.fromRGB(45, 98, 168), 1.4, 0.15)

	local tabDefs = {
		{ id = "robux", name = "TabRobuxButton", label = "ROBUX", shortLabel = "ROBUX" },
		{ id = "perbekalan", name = "TabPerbekalanButton", label = "PERBEKALAN", shortLabel = "BEKAL" },
		{ id = "kosmetik", name = "TabKosmetikButton", label = "KOSMETIK", shortLabel = "KOSMETIK" },
	}
	local tabButtons = {}
	for i, td in ipairs(tabDefs) do
		local btn, fill, rim, grad, lbl = makeStyledButton(tabRow, td.name, 25)
		btn.Size = UDim2.new(1 / 3, -4, 1, -6)
		btn.Position = UDim2.new((i - 1) / 3, 2, 0, 3)
		lbl.Text = td.label
		lbl.TextSize = 11
		local c = fill:FindFirstChildOfClass("UICorner")
		if c then c.CornerRadius = UDim.new(0, 8) end
		tabButtons[td.id] = { btn = btn, rim = rim, grad = grad, lbl = lbl, def = td }
	end

	-- Coin Balance Pill
	local coinPill = Instance.new("Frame")
	coinPill.Name = "ShopCoinPill"
	coinPill.BackgroundColor3 = Color3.fromRGB(5, 19, 50)
	coinPill.BorderSizePixel = 0
	coinPill.ZIndex = 24
	coinPill.Parent = toolbar
	local cpc = Instance.new("UICorner")
	cpc.CornerRadius = UDim.new(1, 0)
	cpc.Parent = coinPill
	stroke(coinPill, Color3.fromRGB(251, 191, 36), 1.5, 0.08)

	local coinIcon = Instance.new("ImageLabel")
	coinIcon.Name = "CoinIcon"
	coinIcon.BackgroundTransparency = 1
	coinIcon.BorderSizePixel = 0
	coinIcon.ScaleType = Enum.ScaleType.Fit
	coinIcon.AnchorPoint = Vector2.new(0, 0.5)
	coinIcon.Position = UDim2.new(0, 6, 0.5, 0)
	coinIcon.Size = UDim2.fromOffset(18, 18)
	coinIcon.ZIndex = 25
	local coinSprite = AdventureCatalog.icon_coin
	if coinSprite then coinIcon.Image = coinSprite[1] end
	coinIcon.Parent = coinPill

	local coinLbl = makeLabel(coinPill, "CoinBalance", "0 Koin", 12, Enum.Font.GothamBlack, Color3.fromRGB(254, 240, 138), Enum.TextXAlignment.Center)
	coinLbl.Position = UDim2.fromOffset(24, 0)
	coinLbl.Size = UDim2.new(1, -28, 1, 0)
	coinLbl.ZIndex = 25

	-- Tab 2: Supplies Container
	local suppliesFrame = Instance.new("Frame")
	suppliesFrame.Name = "SuppliesContainer"
	suppliesFrame.BackgroundTransparency = 1
	suppliesFrame.BorderSizePixel = 0
	suppliesFrame.Visible = false
	suppliesFrame.ZIndex = 23
	suppliesFrame.Parent = shopModal

	local supplyCards = {}
	for _, spec in ipairs(Catalog.SUPPLIES) do
		local card = Instance.new("Frame")
		card.Name = "SupplyCard_" .. spec.id
		card.BackgroundColor3 = Color3.new(1, 1, 1)
		card.BorderSizePixel = 0
		card.ZIndex = 23
		card.Parent = suppliesFrame
		local cc = Instance.new("UICorner")
		cc.CornerRadius = UDim.new(0, 15)
		cc.Parent = card
		stroke(card, Color3.fromRGB(59, 130, 246), 1.6, 0.25)
		local cGrad = Instance.new("UIGradient")
		cGrad.Rotation = 90
		cGrad.Color = ColorSequence.new(Color3.fromRGB(16, 43, 96), Color3.fromRGB(8, 26, 63))
		cGrad.Parent = card

		local stage = Instance.new("Frame")
		stage.Name = "ArtStage"
		stage.BackgroundColor3 = Color3.fromRGB(6, 20, 51)
		stage.BorderSizePixel = 0
		stage.ZIndex = 24
		stage.Parent = card
		local sc = Instance.new("UICorner")
		sc.CornerRadius = UDim.new(0, 11)
		sc.Parent = stage
		stroke(stage, Color3.fromRGB(30, 75, 138), 1.3, 0.1)

		local artImg = Instance.new("ImageLabel")
		artImg.Name = "ArtImage"
		artImg.BackgroundTransparency = 1
		artImg.BorderSizePixel = 0
		artImg.ScaleType = Enum.ScaleType.Fit
		artImg.Size = UDim2.new(1, -12, 1, -8)
		artImg.Position = UDim2.fromOffset(6, 4)
		artImg.ZIndex = 25
		local sArt = AdventureCatalog[spec.artKey]
		if sArt then artImg.Image = sArt[1] end
		artImg.Parent = stage

		local stockPill = Instance.new("TextLabel")
		stockPill.Name = "StockBadge"
		stockPill.BackgroundColor3 = Color3.fromRGB(8, 28, 66)
		stockPill.BorderSizePixel = 0
		stockPill.Font = Enum.Font.GothamBlack
		stockPill.TextSize = 10
		stockPill.TextColor3 = Color3.fromRGB(125, 211, 252)
		stockPill.Text = "MILIKI: 0"
		stockPill.ZIndex = 26
		stockPill.Parent = stage
		local spc = Instance.new("UICorner")
		spc.CornerRadius = UDim.new(1, 0)
		spc.Parent = stockPill
		stroke(stockPill, spec.badgeColor, 1.2, 0.2)

		local tagLbl = makeLabel(card, "Tag", spec.tag, 10, Enum.Font.GothamBlack, spec.badgeColor, Enum.TextXAlignment.Center)
		tagLbl.ZIndex = 25
		local titleLbl = makeLabel(card, "Title", spec.name, 16, Enum.Font.GothamBlack, Color3.new(1, 1, 1), Enum.TextXAlignment.Center)
		titleLbl.ZIndex = 25
		local descLbl = makeLabel(card, "Desc", spec.description, 12, Enum.Font.GothamBold, Color3.fromRGB(203, 226, 255), Enum.TextXAlignment.Center)
		descLbl.TextWrapped = true
		descLbl.TextScaled = true
		descLbl.ZIndex = 25
		local descConstraint = Instance.new("UITextSizeConstraint")
		descConstraint.MaxTextSize = 12
		descConstraint.MinTextSize = 9
		descConstraint.Parent = descLbl

		local buyBtn, _, buyRim, buyGrad, buyLbl = makeStyledButton(card, "BuyCoin_" .. spec.id, 25)
		buyBtn:SetAttribute("ItemId", spec.id)

		supplyCards[spec.id] = {
			spec = spec,
			card = card,
			stage = stage,
			stockPill = stockPill,
			tag = tagLbl,
			title = titleLbl,
			desc = descLbl,
			buyBtn = buyBtn,
			buyRim = buyRim,
			buyGrad = buyGrad,
			buyLbl = buyLbl,
		}
	end

	-- Tab 3: Cosmetics Scrolling List
	local cosScroll = Instance.new("ScrollingFrame")
	cosScroll.Name = "CosmeticsScroll"
	cosScroll.BackgroundTransparency = 1
	cosScroll.BorderSizePixel = 0
	cosScroll.ScrollBarThickness = 5
	cosScroll.ScrollBarImageColor3 = Color3.fromRGB(56, 189, 248)
	cosScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	cosScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	cosScroll.Visible = false
	cosScroll.ZIndex = 23
	cosScroll.Parent = shopModal

	local cosListLayout = Instance.new("UIListLayout")
	cosListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	cosListLayout.Padding = UDim.new(0, 8)
	cosListLayout.Parent = cosScroll

	local cosPad = Instance.new("UIPadding")
	cosPad.PaddingRight = UDim.new(0, 8)
	cosPad.PaddingTop = UDim.new(0, 2)
	cosPad.PaddingBottom = UDim.new(0, 4)
	cosPad.Parent = cosScroll

	local cosmeticRows = {}
	for idx, item in ipairs(Catalog.COSMETICS) do
		local row = Instance.new("Frame")
		row.Name = "CosmeticRow_" .. item.category .. "_" .. item.id
		row.LayoutOrder = idx
		row.Size = UDim2.new(1, 0, 0, 86)
		row.BackgroundColor3 = Color3.new(1, 1, 1)
		row.BorderSizePixel = 0
		row.ZIndex = 23
		row.Parent = cosScroll
		local rc = Instance.new("UICorner")
		rc.CornerRadius = UDim.new(0, 14)
		rc.Parent = row
		local rowStroke = stroke(row, Color3.fromRGB(47, 104, 175), 1.5, 0.15)
		local rowGrad = Instance.new("UIGradient")
		rowGrad.Rotation = 90
		rowGrad.Color = ColorSequence.new(Color3.fromRGB(12, 35, 82), Color3.fromRGB(7, 23, 58))
		rowGrad.Parent = row

		local artStage = Instance.new("Frame")
		artStage.Name = "ThumbStage"
		artStage.Size = UDim2.fromOffset(66, 66)
		artStage.Position = UDim2.fromOffset(10, 10)
		artStage.BackgroundColor3 = Color3.fromRGB(6, 20, 51)
		artStage.BorderSizePixel = 0
		artStage.ZIndex = 24
		artStage.Parent = row
		local ac = Instance.new("UICorner")
		ac.CornerRadius = UDim.new(0, 11)
		ac.Parent = artStage
		stroke(artStage, item.primaryColor, 1.5, 0.25)

		local artImg = Instance.new("ImageLabel")
		artImg.Name = "ThumbImage"
		artImg.BackgroundTransparency = 1
		artImg.BorderSizePixel = 0
		artImg.ScaleType = Enum.ScaleType.Fit
		artImg.Size = UDim2.new(1, -10, 1, -10)
		artImg.Position = UDim2.fromOffset(5, 5)
		artImg.ZIndex = 25
		local artSprite = AdventureCatalog[item.artKey]
		if artSprite then artImg.Image = artSprite[1] end
		artImg.Parent = artStage

		local tagLbl = makeLabel(row, "ItemTag", item.tag, 10, Enum.Font.GothamBlack, item.primaryColor, Enum.TextXAlignment.Left)
		tagLbl.Position = UDim2.fromOffset(86, 10)
		tagLbl.Size = UDim2.new(1, -214, 0, 14)
		tagLbl.TextWrapped = false
		tagLbl.TextScaled = true
		tagLbl.ZIndex = 25
		local tagCap = Instance.new("UITextSizeConstraint")
		tagCap.MinTextSize = 7
		tagCap.MaxTextSize = 10
		tagCap.Parent = tagLbl

		local titleLbl = makeLabel(row, "ItemTitle", item.name, 14, Enum.Font.GothamBlack, Color3.new(1, 1, 1), Enum.TextXAlignment.Left)
		titleLbl.Position = UDim2.fromOffset(86, 26)
		titleLbl.Size = UDim2.new(1, -214, 0, 20)
		titleLbl.TextWrapped = false
		titleLbl.TextScaled = true
		titleLbl.ZIndex = 25
		local titleCap = Instance.new("UITextSizeConstraint")
		titleCap.MinTextSize = 8
		titleCap.MaxTextSize = 14
		titleCap.Parent = titleLbl

		local descLbl = makeLabel(row, "ItemDesc", item.description, 11, Enum.Font.GothamBold, Color3.fromRGB(191, 219, 254), Enum.TextXAlignment.Left)
		descLbl.Position = UDim2.fromOffset(86, 46)
		descLbl.Size = UDim2.new(1, -214, 0, 32)
		descLbl.TextWrapped = true
		descLbl.TextScaled = true
		descLbl.TextYAlignment = Enum.TextYAlignment.Top
		descLbl.ZIndex = 25
		local descCap = Instance.new("UITextSizeConstraint")
		descCap.MinTextSize = 8
		descCap.MaxTextSize = 11
		descCap.Parent = descLbl

		local actBtn, _, actRim, actGrad, actLbl = makeStyledButton(row, "ActCosmetic_" .. item.id, 25)
		actBtn.AnchorPoint = Vector2.new(1, 0.5)
		actBtn.Position = UDim2.new(1, -10, 0.5, 0)
		actBtn.Size = UDim2.fromOffset(112, 44)

		cosmeticRows[item.key] = {
			item = item,
			row = row,
			thumb = artStage,
			stroke = rowStroke,
			tag = tagLbl,
			title = titleLbl,
			desc = descLbl,
			actBtn = actBtn,
			actRim = actRim,
			actGrad = actGrad,
			actLbl = actLbl,
		}
	end

	local busyAction = false

	local function refreshUI()
		local activeTab = shopModal:GetAttribute("ActiveShopTab") or "robux"
		local coins = tonumber(player:GetAttribute("SkyCoins")) or 0
		coinLbl.Text = tostring(coins) .. " Koin"

		local compactW = shopModal.AbsoluteSize.X > 0 and shopModal.AbsoluteSize.X < 430
		for _, tb in pairs(tabButtons) do
			local selected = tb.def.id == activeTab
			tb.lbl.Text = compactW and tb.def.shortLabel or tb.def.label
			tb.grad.Color = selected
				and ColorSequence.new(Color3.fromRGB(56, 189, 248), Color3.fromRGB(2, 132, 199))
				or ColorSequence.new(Color3.fromRGB(18, 39, 78), Color3.fromRGB(10, 23, 52))
			tb.rim.Color = selected and Color3.fromRGB(125, 211, 252) or Color3.fromRGB(45, 98, 168)
			tb.lbl.TextColor3 = selected and Color3.new(1, 1, 1) or Color3.fromRGB(165, 195, 235)
		end

		local c1 = shopModal:FindFirstChild("Card1") :: GuiObject?
		local c2 = shopModal:FindFirstChild("Card2") :: GuiObject?
		if c1 then c1.Visible = (activeTab == "robux") end
		if c2 then c2.Visible = (activeTab == "robux") end
		suppliesFrame.Visible = (activeTab == "perbekalan")
		cosScroll.Visible = (activeTab == "kosmetik")

		-- Supply state refresh
		for id, sc in pairs(supplyCards) do
			local stock = tonumber(player:GetAttribute(sc.spec.stockAttribute)) or 0
			sc.stockPill.Text = "MILIKI: " .. tostring(stock)
			local canAfford = coins >= sc.spec.price
			sc.buyLbl.Text = busyAction and "MEMPROSES..." or (tostring(sc.spec.price) .. " Koin")
			sc.buyBtn.Active = not busyAction
			if busyAction then
				sc.buyGrad.Color = ColorSequence.new(Color3.fromRGB(56, 189, 248), Color3.fromRGB(3, 105, 161))
				sc.buyRim.Color = Color3.fromRGB(125, 211, 252)
			elseif canAfford then
				sc.buyGrad.Color = ColorSequence.new(Color3.fromRGB(253, 224, 71), Color3.fromRGB(180, 83, 9))
				sc.buyRim.Color = Color3.fromRGB(254, 240, 138)
			else
				sc.buyGrad.Color = ColorSequence.new(Color3.fromRGB(51, 65, 85), Color3.fromRGB(30, 41, 59))
				sc.buyRim.Color = Color3.fromRGB(100, 116, 139)
			end
		end

		-- Cosmetics state refresh
		local ownedMap = decodeMap(player:GetAttribute("OwnedCosmeticsJson"))
		local tempMap = decodeMap(player:GetAttribute("TempCosmeticsJson"))
		local eqFrame = tostring(player:GetAttribute("EquippedFrame") or "none")
		local eqTracer = tostring(player:GetAttribute("EquippedTracer") or "none")
		local eqTitle = tostring(player:GetAttribute("EquippedTitle") or "none")
		local equippedByCat = { frame = eqFrame, tracer = eqTracer, title = eqTitle }
		local nowUnix = os.time()

		for _, cr in pairs(cosmeticRows) do
			local it = cr.item
			local isPerm = ownedMap[it.key] == true
			local expUnix = tonumber(tempMap[it.key])
			local isTemp = (not isPerm) and (expUnix ~= nil and expUnix > nowUnix)
			local ownedAny = isPerm or isTemp
			local isEquipped = ownedAny and equippedByCat[it.category] == it.id

			if isEquipped then
				cr.stroke.Color = Color3.fromRGB(16, 185, 129)
				cr.actGrad.Color = ColorSequence.new(Color3.fromRGB(63, 230, 125), Color3.fromRGB(18, 128, 56))
				cr.actRim.Color = Color3.fromRGB(134, 239, 172)
				cr.actLbl.Text = "✓ DIPAKAI"
			elseif ownedAny then
				cr.stroke.Color = Color3.fromRGB(56, 189, 248)
				cr.actGrad.Color = ColorSequence.new(Color3.fromRGB(56, 189, 248), Color3.fromRGB(2, 132, 199))
				cr.actRim.Color = Color3.fromRGB(125, 211, 252)
				cr.actLbl.Text = "PAKAI"
			else
				cr.stroke.Color = Color3.fromRGB(47, 104, 175)
				if coins >= it.price then
					cr.actGrad.Color = ColorSequence.new(Color3.fromRGB(253, 224, 71), Color3.fromRGB(180, 83, 9))
					cr.actRim.Color = Color3.fromRGB(254, 240, 138)
				else
					cr.actGrad.Color = ColorSequence.new(Color3.fromRGB(51, 65, 85), Color3.fromRGB(30, 41, 59))
					cr.actRim.Color = Color3.fromRGB(100, 116, 139)
				end
				cr.actLbl.Text = tostring(it.price) .. " Koin"
			end

			cr.tag.Text = isTemp and expUnix
				and string.format("%s · %s", it.tag, formatRemainingTrial(expUnix))
				or it.tag

			-- Responsive text width on narrow modals
			local narrowRow = cr.row.AbsoluteSize.X > 0 and cr.row.AbsoluteSize.X < 380
			local thumbSize = narrowRow and 54 or 66
			local thumbX = narrowRow and 8 or 10
			local textX = thumbX + thumbSize + 8
			local btnW = narrowRow and 86 or 112
			local btnH = narrowRow and 40 or 44
			local rightPad = narrowRow and 8 or 10
			local rightReserve = btnW + rightPad + 8
			cr.thumb.Size = UDim2.fromOffset(thumbSize, thumbSize)
			cr.thumb.Position = UDim2.fromOffset(thumbX, math.floor((86 - thumbSize) / 2))
			cr.actBtn.Size = UDim2.fromOffset(btnW, btnH)
			cr.actBtn.Position = UDim2.new(1, -rightPad, 0.5, 0)
			cr.tag.Position = UDim2.fromOffset(textX, 8)
			cr.tag.Size = UDim2.new(1, -(textX + rightReserve), 0, 14)
			cr.title.Position = UDim2.fromOffset(textX, 24)
			cr.title.Size = UDim2.new(1, -(textX + rightReserve), 0, 20)
			cr.desc.Position = UDim2.fromOffset(textX, 45)
			cr.desc.Size = UDim2.new(1, -(textX + rightReserve), 0, 34)
		end

		local idleHint = shopModal:FindFirstChild("ShopIdleHint") :: TextLabel?
		if idleHint then
			if activeTab == "robux" then
				idleHint.Text = "Pilih item untuk membeli lewat Roblox."
			elseif activeTab == "perbekalan" then
				idleHint.Text = "Tab PERBEKALAN · Pakai saat terbang lewat ikon kiri HUD."
			else
				idleHint.Text = "Tab KOSMETIK · Visual murni tanpa mengubah kecepatan."
			end
		end
	end

	-- Wire tab clicks
	for tabId, tb in pairs(tabButtons) do
		tb.btn.Activated:Connect(function()
			shopModal:SetAttribute("ActiveShopTab", tabId)
			setFeedback("")
			refreshUI()
		end)
	end

	-- Wire supply purchases
	for itemId, sc in pairs(supplyCards) do
		sc.buyBtn.Activated:Connect(function()
			if busyAction or not coinShopFn then return end
			if player:GetAttribute("DataReady") ~= true then
				setFeedback("Data sedang dimuat...")
				return
			end
			busyAction = true
			setFeedback("")
			refreshUI()
			local ok, res = pcall(function()
				return coinShopFn:InvokeServer("BuySupply", itemId)
			end)
			busyAction = false
			if ok and type(res) == "table" then
				setFeedback(res.message or "")
			else
				setFeedback("Pembelian gagal diproses.")
			end
			refreshUI()
		end)
	end

	-- Wire cosmetic actions
	for _, cr in pairs(cosmeticRows) do
		cr.actBtn.Activated:Connect(function()
			if busyAction or not coinShopFn then return end
			if player:GetAttribute("DataReady") ~= true then
				setFeedback("Data sedang dimuat...")
				return
			end
			local ownedMap = decodeMap(player:GetAttribute("OwnedCosmeticsJson"))
			local tempMap = decodeMap(player:GetAttribute("TempCosmeticsJson"))
			local eqAttr = cr.item.category == "frame" and "EquippedFrame"
				or (cr.item.category == "tracer" and "EquippedTracer" or "EquippedTitle")
			local curEq = tostring(player:GetAttribute(eqAttr) or "none")
			local isPerm = ownedMap[cr.item.key] == true
			local expUnix = tonumber(tempMap[cr.item.key])
			local ownedAny = isPerm or (expUnix ~= nil and expUnix > os.time())

			local actionName = "BuyCosmetic"
			if ownedAny then
				actionName = (curEq == cr.item.id) and "UnequipCosmetic" or "EquipCosmetic"
			end

			busyAction = true
			setFeedback("")
			refreshUI()
			local ok, res = pcall(function()
				return coinShopFn:InvokeServer(actionName, cr.item.category, cr.item.id)
			end)
			busyAction = false
			if ok and type(res) == "table" then
				setFeedback(res.message or "")
			else
				setFeedback("Aksi kosmetik gagal.")
			end
			refreshUI()
		end)
	end

	-- Deterministic card positioning for SupplyCards inside SuppliesContainer
	local function layoutHorizontalCard(sc, cardX: number, cardY: number, cardW: number, cardH: number, btnH: number)
		sc.card.Position = UDim2.fromOffset(cardX, cardY)
		sc.card.Size = UDim2.fromOffset(cardW, cardH)
		local btnY = cardH - btnH - 8
		local topH = btnY - 12
		local stageSize = math.clamp(math.min(topH - 2, math.round(cardW * 0.28)), 72, 92)
		sc.stage.Position = UDim2.fromOffset(10, 8)
		sc.stage.Size = UDim2.fromOffset(stageSize, stageSize)
		sc.stockPill.Position = UDim2.new(0.5, -34, 1, -18)
		sc.stockPill.Size = UDim2.fromOffset(68, 16)
		local tx = 10 + stageSize + 10
		local tw = math.max(80, cardW - tx - 10)
		sc.tag.TextXAlignment = Enum.TextXAlignment.Left
		sc.title.TextXAlignment = Enum.TextXAlignment.Left
		sc.desc.TextXAlignment = Enum.TextXAlignment.Left
		sc.tag.Position = UDim2.fromOffset(tx, 8)
		sc.tag.Size = UDim2.fromOffset(tw, 14)
		sc.title.Position = UDim2.fromOffset(tx, 23)
		sc.title.Size = UDim2.fromOffset(tw, 20)
		sc.desc.Position = UDim2.fromOffset(tx, 45)
		sc.desc.Size = UDim2.fromOffset(tw, math.max(18, btnY - 51))
		sc.buyBtn.Position = UDim2.fromOffset(10, btnY)
		sc.buyBtn.Size = UDim2.fromOffset(cardW - 20, btnH)
	end

	local function layoutSupplies()
		local sw = suppliesFrame.AbsoluteSize.X
		local sh = suppliesFrame.AbsoluteSize.Y
		if sw < 1 or sh < 1 then return end
		local phoneStack = sw < 380 or (shopModal.AbsoluteSize.X < 460 and sh >= 240)
		local list = { supplyCards.turbo_gas, supplyCards.tali_awet }
		if phoneStack then
			local gap = 10
			local ch = math.floor((sh - gap) / 2)
			for i, sc in ipairs(list) do
				layoutHorizontalCard(sc, 0, (i - 1) * (ch + gap), sw, ch, 38)
			end
		elseif sh < 250 then
			local gap = 14
			local cw = math.floor((sw - gap) / 2)
			for i, sc in ipairs(list) do
				layoutHorizontalCard(sc, (i - 1) * (cw + gap), 0, cw, sh, 38)
			end
		else
			local gap = 14
			local cw = math.floor((sw - gap) / 2)
			for i, sc in ipairs(list) do
				local cx = (i - 1) * (cw + gap)
				sc.card.Position = UDim2.fromOffset(cx, 0)
				sc.card.Size = UDim2.fromOffset(cw, sh)
				local stageH = math.clamp(math.round(sh * 0.34), 60, 100)
				sc.stage.Position = UDim2.fromOffset(12, 10)
				sc.stage.Size = UDim2.fromOffset(cw - 24, stageH)
				sc.stockPill.Position = UDim2.new(1, -78, 0, 6)
				sc.stockPill.Size = UDim2.fromOffset(72, 18)
				local curY = 10 + stageH + 8
				sc.tag.TextXAlignment = Enum.TextXAlignment.Center
				sc.title.TextXAlignment = Enum.TextXAlignment.Center
				sc.desc.TextXAlignment = Enum.TextXAlignment.Center
				sc.tag.Position = UDim2.fromOffset(12, curY)
				sc.tag.Size = UDim2.fromOffset(cw - 24, 16)
				sc.title.Position = UDim2.fromOffset(12, curY + 18)
				sc.title.Size = UDim2.fromOffset(cw - 24, 22)
				local btnY = sh - 54
				local descH = math.max(20, btnY - 6 - (curY + 42))
				sc.desc.Position = UDim2.fromOffset(12, curY + 42)
				sc.desc.Size = UDim2.fromOffset(cw - 24, descH)
				sc.buyBtn.Position = UDim2.fromOffset(12, btnY)
				sc.buyBtn.Size = UDim2.fromOffset(cw - 24, 44)
			end
		end
	end

	suppliesFrame:GetPropertyChangedSignal("AbsoluteSize"):Connect(layoutSupplies)
	shopModal:GetPropertyChangedSignal("AbsoluteSize"):Connect(refreshUI)
	for _, attr in { "SkyCoins", "SpeedBoostStock", "RopeBuffStock", "EquippedFrame", "EquippedTracer", "EquippedTitle", "OwnedCosmeticsJson", "TempCosmeticsJson" } do
		player:GetAttributeChangedSignal(attr):Connect(refreshUI)
	end
	shopModal:GetAttributeChangedSignal("ActiveShopTab"):Connect(function()
		refreshUI()
		layoutSupplies()
	end)
	cosScroll:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		refreshUI()
	end)

	refreshUI()
	return refreshUI
end

return ShopTabsController
