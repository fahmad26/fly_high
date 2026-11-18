local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Catalog = require(ReplicatedStorage:WaitForChild("FlyHigh"):WaitForChild("Modules"):WaitForChild("DailyAndShopCatalog"))
local AdventureCatalog = require(ReplicatedStorage:WaitForChild("FlyHigh"):WaitForChild("Modules"):WaitForChild("HUDAdventureCatalog"))

local function formatAltitude(km)
	km = km or 0
	return string.format("%d km", math.floor(km))
end

local function updateOverheadTitle(player, billboard)
	local titleLabel = billboard:FindFirstChild("TitleLabel")
	local masterLabel = billboard:FindFirstChild("MasterLabel")
	local cosmeticPill = billboard:FindFirstChild("CosmeticTitlePill")
	local cosmeticLabel = cosmeticPill and cosmeticPill:FindFirstChild("CosmeticTitleLabel") or billboard:FindFirstChild("CosmeticTitleLabel")
	local nameLabel = billboard:FindFirstChild("NameLabel")
	if not titleLabel then return end

	local maxAltitude = player:GetAttribute("MaxAltitude") or 0
	local summitCount = player:GetAttribute("SummitCount") or 0
	local isMaster = player:GetAttribute("IsMaster") or false
	local equippedTitleId = player:GetAttribute("EquippedTitle")
	local cosmeticItem = type(equippedTitleId) == "string" and Catalog.GetCosmetic("title", equippedTitleId) or nil
	if cosmeticItem and not Catalog.CanAccessCosmetic(cosmeticItem, player.UserId) then
		cosmeticItem = nil
	end

	if masterLabel then
		masterLabel.Visible = isMaster
	end

	if summitCount > 0 then
		titleLabel.Text = string.format("[Puncak: %dx]", summitCount)
		titleLabel.TextColor3 = Color3.fromRGB(255, 215, 0) -- Gold
		titleLabel.TextStrokeColor3 = Color3.fromRGB(139, 90, 0)
	else
		titleLabel.Text = string.format("[Rekor: %s]", formatAltitude(maxAltitude))
		titleLabel.TextColor3 = Color3.fromRGB(80, 220, 255) -- Cyan
		titleLabel.TextStrokeColor3 = Color3.fromRGB(0, 60, 100)
	end

	local hasTitle = cosmeticItem ~= nil
	local pal = cosmeticItem and cosmeticItem.luxuryPalette
	local isLuxury = hasTitle and cosmeticItem.luxuryStyle ~= nil and pal ~= nil
	if cosmeticPill and cosmeticLabel then
		cosmeticPill.Visible = hasTitle
		local bgGrad = cosmeticPill:FindFirstChild("RoyalBgGradient")
		local rim = cosmeticPill:FindFirstChildOfClass("UIStroke")
		local rimGrad = rim and rim:FindFirstChild("RoyalRimGradient")
		local crest = cosmeticPill:FindFirstChild("RoyalCrest")
		local sparkle = cosmeticPill:FindFirstChild("RoyalSparkle")
		local sizeCap = cosmeticLabel:FindFirstChildOfClass("UITextSizeConstraint")

		if hasTitle and cosmeticItem then
			if isLuxury and pal then
				cosmeticPill.Size = UDim2.new(0.96, 0, 0, 24)
				cosmeticPill.Position = UDim2.new(0.02, 0, 0, 37)
				cosmeticPill.BackgroundColor3 = Color3.new(1, 1, 1)
				cosmeticPill.BackgroundTransparency = 0.04
				if bgGrad then
					bgGrad.Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0, pal.pillTop),
						ColorSequenceKeypoint.new(0.5, pal.pillMid),
						ColorSequenceKeypoint.new(1, pal.pillBottom),
					})
					bgGrad.Enabled = true
				end
				if rim then
					rim.Color = Color3.new(1, 1, 1)
					rim.Thickness = 2.1
				end
				if rimGrad then
					rimGrad.Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0, pal.rimA),
						ColorSequenceKeypoint.new(0.5, pal.rimB),
						ColorSequenceKeypoint.new(1, pal.rimC),
					})
					rimGrad.Enabled = true
				end
				if crest then
					local sprite = AdventureCatalog[cosmeticItem.artKey]
					crest.Image = sprite and sprite[1] or ""
					crest.Visible = sprite ~= nil
				end
				if sparkle then
					for _, arm in ipairs(sparkle:GetChildren()) do
						if arm:IsA("Frame") then arm.BackgroundColor3 = pal.rimA end
					end
					sparkle.Visible = true
				end
				cosmeticLabel.Position = UDim2.fromOffset(26, 0)
				cosmeticLabel.Size = UDim2.new(1, -46, 1, 0)
				cosmeticLabel.Text = cosmeticItem.titleText or cosmeticItem.name
				cosmeticLabel.TextColor3 = pal.textColor
				cosmeticLabel.TextStrokeColor3 = Color3.fromRGB(10, 12, 34)
				if sizeCap then sizeCap.MaxTextSize = 12 end
			else
				cosmeticPill.Size = UDim2.new(0.86, 0, 0, 18)
				cosmeticPill.Position = UDim2.new(0.07, 0, 0, 38)
				cosmeticPill.BackgroundColor3 = Color3.fromRGB(11, 28, 66)
				cosmeticPill.BackgroundTransparency = 0.12
				if bgGrad then bgGrad.Enabled = false end
				if rimGrad then rimGrad.Enabled = false end
				if rim then
					rim.Color = cosmeticItem.primaryColor or Color3.fromRGB(251, 191, 36)
					rim.Thickness = 1.3
				end
				if crest then crest.Visible = false end
				if sparkle then sparkle.Visible = false end
				cosmeticLabel.Position = UDim2.fromOffset(6, 0)
				cosmeticLabel.Size = UDim2.new(1, -12, 1, 0)
				cosmeticLabel.Text = "★ " .. (cosmeticItem.titleText or cosmeticItem.name)
				cosmeticLabel.TextColor3 = cosmeticItem.primaryColor or Color3.fromRGB(254, 240, 138)
				cosmeticLabel.TextStrokeColor3 = Color3.fromRGB(6, 18, 44)
				if sizeCap then sizeCap.MaxTextSize = 11 end
			end
		end
	end
	if nameLabel then
		nameLabel.Position = UDim2.new(0, 0, 0, hasTitle and (isLuxury and 65 or 60) or 36)
	end
	billboard.Size = UDim2.new(0, isLuxury and 252 or 220, 0, hasTitle and (isLuxury and 92 or 84) or 65)
end

local function setupOverheadGui(player, character)
	local head = character:WaitForChild("Head", 10)
	if not head then return end

	-- Remove existing overhead if any
	local oldGui = head:FindFirstChild("OverheadGui")
	if oldGui then oldGui:Destroy() end

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "OverheadGui"
	billboard.Size = UDim2.new(0, 220, 0, 65)
	billboard.StudsOffset = Vector3.new(0, 2.5, 0)
	billboard.AlwaysOnTop = true
	billboard.MaxDistance = 100
	billboard:AddTag("FlyHighPlayerOverhead")
	billboard.Parent = head

	-- Party Master Label
	local masterLabel = Instance.new("TextLabel")
	masterLabel.Name = "MasterLabel"
	masterLabel.Size = UDim2.new(1, 0, 0, 16)
	masterLabel.Position = UDim2.new(0, 0, 0, 0)
	masterLabel.BackgroundTransparency = 1
	masterLabel.Text = "PARTY MASTER"
	masterLabel.TextColor3 = Color3.fromRGB(255, 220, 50)
	masterLabel.TextStrokeTransparency = 0.2
	masterLabel.TextStrokeColor3 = Color3.fromRGB(80, 50, 0)
	masterLabel.Font = Enum.Font.FredokaOne
	masterLabel.TextSize = 14
	masterLabel.Visible = false
	masterLabel.Parent = billboard

	-- Title Label (Rekor or Puncak)
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "TitleLabel"
	titleLabel.Size = UDim2.new(1, 0, 0, 20)
	titleLabel.Position = UDim2.new(0, 0, 0, 16)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = "[Memuat Rekor...]"
	titleLabel.TextColor3 = Color3.fromRGB(80, 220, 255)
	titleLabel.TextStrokeTransparency = 0.2
	titleLabel.TextStrokeColor3 = Color3.fromRGB(0, 40, 70)
	titleLabel.Font = Enum.Font.FredokaOne
	titleLabel.TextSize = 15
	titleLabel.Parent = billboard

	-- Cosmetic Overhead Title Pill (below Rekor/Puncak)
	local cosmeticPill = Instance.new("Frame")
	cosmeticPill.Name = "CosmeticTitlePill"
	cosmeticPill.Size = UDim2.new(0.86, 0, 0, 18)
	cosmeticPill.Position = UDim2.new(0.07, 0, 0, 38)
	cosmeticPill.BackgroundColor3 = Color3.fromRGB(11, 28, 66)
	cosmeticPill.BackgroundTransparency = 0.12
	cosmeticPill.BorderSizePixel = 0
	cosmeticPill.Visible = false
	cosmeticPill.Parent = billboard
	local cCorner = Instance.new("UICorner")
	cCorner.CornerRadius = UDim.new(1, 0)
	cCorner.Parent = cosmeticPill
	local bgGrad = Instance.new("UIGradient")
	bgGrad.Name = "RoyalBgGradient"
	bgGrad.Rotation = 90
	bgGrad.Enabled = false
	bgGrad.Parent = cosmeticPill
	local cStroke = Instance.new("UIStroke")
	cStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	cStroke.Thickness = 1.3
	cStroke.Color = Color3.fromRGB(251, 191, 36)
	cStroke.Parent = cosmeticPill
	local rimGrad = Instance.new("UIGradient")
	rimGrad.Name = "RoyalRimGradient"
	rimGrad.Rotation = 18
	rimGrad.Enabled = false
	rimGrad.Parent = cStroke

	local royalCrest = Instance.new("ImageLabel")
	royalCrest.Name = "RoyalCrest"
	royalCrest.BackgroundTransparency = 1
	royalCrest.BorderSizePixel = 0
	royalCrest.ScaleType = Enum.ScaleType.Fit
	royalCrest.AnchorPoint = Vector2.new(0, 0.5)
	royalCrest.Position = UDim2.new(0, 5, 0.5, 0)
	royalCrest.Size = UDim2.fromOffset(18, 18)
	royalCrest.ZIndex = 2
	royalCrest.Visible = false
	royalCrest.Parent = cosmeticPill

	-- Pure geometric 4-point star avoids missing Unicode glyph boxes on iOS/iPadOS fonts.
	local royalSparkle = Instance.new("Frame")
	royalSparkle.Name = "RoyalSparkle"
	royalSparkle.BackgroundTransparency = 1
	royalSparkle.BorderSizePixel = 0
	royalSparkle.AnchorPoint = Vector2.new(1, 0.5)
	royalSparkle.Position = UDim2.new(1, -6, 0.5, 0)
	royalSparkle.Size = UDim2.fromOffset(12, 12)
	royalSparkle.ZIndex = 2
	royalSparkle.Visible = false
	royalSparkle.Parent = cosmeticPill
	for _, spec in ipairs({
		{ w = 12, h = 2, r = 0 },
		{ w = 2, h = 12, r = 0 },
		{ w = 5, h = 5, r = 45 },
	}) do
		local arm = Instance.new("Frame")
		arm.BackgroundColor3 = Color3.new(1, 1, 1)
		arm.BorderSizePixel = 0
		arm.AnchorPoint = Vector2.new(0.5, 0.5)
		arm.Position = UDim2.fromScale(0.5, 0.5)
		arm.Size = UDim2.fromOffset(spec.w, spec.h)
		arm.Rotation = spec.r
		arm.ZIndex = 2
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(1, 0)
		c.Parent = arm
		arm.Parent = royalSparkle
	end

	local cosmeticLabel = Instance.new("TextLabel")
	cosmeticLabel.Name = "CosmeticTitleLabel"
	cosmeticLabel.Position = UDim2.fromOffset(6, 0)
	cosmeticLabel.Size = UDim2.new(1, -12, 1, 0)
	cosmeticLabel.BackgroundTransparency = 1
	cosmeticLabel.BorderSizePixel = 0
	cosmeticLabel.Text = ""
	cosmeticLabel.TextColor3 = Color3.fromRGB(254, 240, 138)
	cosmeticLabel.TextStrokeTransparency = 0.25
	cosmeticLabel.TextStrokeColor3 = Color3.fromRGB(6, 18, 44)
	cosmeticLabel.Font = Enum.Font.GothamBlack
	cosmeticLabel.TextSize = 11
	cosmeticLabel.TextScaled = true
	cosmeticLabel.TextWrapped = false
	cosmeticLabel.ZIndex = 2
	cosmeticLabel.Parent = cosmeticPill
	local cSizeCap = Instance.new("UITextSizeConstraint")
	cSizeCap.MinTextSize = 8
	cSizeCap.MaxTextSize = 11
	cSizeCap.Parent = cosmeticLabel

	-- Name Label
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "NameLabel"
	nameLabel.Size = UDim2.new(1, 0, 0, 18)
	nameLabel.Position = UDim2.new(0, 0, 0, 36)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = string.format("%s (@%s)", player.DisplayName, player.Name)
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextStrokeTransparency = 0.4
	nameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	nameLabel.Font = Enum.Font.Nunito
	nameLabel.TextSize = 13
	nameLabel.Parent = billboard

	-- Initial update
	updateOverheadTitle(player, billboard)

	-- Disconnect player-owned signals when this character GUI is destroyed.
	local connections = {}
	billboard.Destroying:Connect(function()
		for _, connection in ipairs(connections) do connection:Disconnect() end
	end)
	-- Listen for attribute changes
	table.insert(connections, player:GetAttributeChangedSignal("MaxAltitude"):Connect(function()
		updateOverheadTitle(player, billboard)
	end))
	table.insert(connections, player:GetAttributeChangedSignal("SummitCount"):Connect(function()
		updateOverheadTitle(player, billboard)
	end))
	table.insert(connections, player:GetAttributeChangedSignal("IsMaster"):Connect(function()
		updateOverheadTitle(player, billboard)
	end))
	table.insert(connections, player:GetAttributeChangedSignal("EquippedTitle"):Connect(function()
		updateOverheadTitle(player, billboard)
	end))
end

local function onPlayerAdded(player)
	player.CharacterAdded:Connect(function(character)
		setupOverheadGui(player, character)
	end)
	if player.Character then
		setupOverheadGui(player, player.Character)
	end
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in ipairs(Players:GetPlayers()) do
	onPlayerAdded(player)
end
