local Players = game:GetService("Players")

local function formatAltitude(km)
	km = km or 0
	return string.format("%d km", math.floor(km))
end

local function updateOverheadTitle(player, billboard)
	local titleLabel = billboard:FindFirstChild("TitleLabel")
	local masterLabel = billboard:FindFirstChild("MasterLabel")
	if not titleLabel then return end

	local maxAltitude = player:GetAttribute("MaxAltitude") or 0
	local summitCount = player:GetAttribute("SummitCount") or 0
	local isMaster = player:GetAttribute("IsMaster") or false

	if masterLabel then
		masterLabel.Visible = isMaster
	end

	if summitCount > 0 then
		titleLabel.Text = string.format("[⭐ Puncak: %dx]", summitCount)
		titleLabel.TextColor3 = Color3.fromRGB(255, 215, 0) -- Gold
		titleLabel.TextStrokeColor3 = Color3.fromRGB(139, 90, 0)
	else
		titleLabel.Text = string.format("[Rekor: %s]", formatAltitude(maxAltitude))
		titleLabel.TextColor3 = Color3.fromRGB(80, 220, 255) -- Cyan
		titleLabel.TextStrokeColor3 = Color3.fromRGB(0, 60, 100)
	end
end

local function setupOverheadGui(player, character)
	local head = character:WaitForChild("Head", 10)
	if not head then return end

	-- Remove existing overhead if any
	local oldGui = head:FindFirstChild("OverheadGui")
	if oldGui then oldGui:Destroy() end

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "OverheadGui"
	billboard.Size = UDim2.new(0, 200, 0, 65)
	billboard.StudsOffset = Vector3.new(0, 2.5, 0)
	billboard.AlwaysOnTop = true
	billboard.MaxDistance = 100
	billboard.Parent = head

	-- Master Crown Label
	local masterLabel = Instance.new("TextLabel")
	masterLabel.Name = "MasterLabel"
	masterLabel.Size = UDim2.new(1, 0, 0, 16)
	masterLabel.Position = UDim2.new(0, 0, 0, 0)
	masterLabel.BackgroundTransparency = 1
	masterLabel.Text = "👑 PARTY MASTER"
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
	nameLabel.Font = Enum.Font.GothamBold
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
