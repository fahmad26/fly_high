local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Marketplace=game:GetService("MarketplaceService")
local Config=require(ReplicatedStorage:WaitForChild("FlyHigh"):WaitForChild("Modules"):WaitForChild("FlyHighConfig"))

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

local remotes = ReplicatedStorage:WaitForChild("FlyHigh"):WaitForChild("Remotes")
local shopPurchaseEvent = remotes:WaitForChild("ShopPurchaseEvent")

local screenGui = playerGui:WaitForChild("FlyHighHUD", 10) or Instance.new("ScreenGui")
screenGui.Name = "FlyHighHUD"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

-- Shop Open Button (Top Right)
local shopToggleBtn = Instance.new("TextButton")
shopToggleBtn.Name = "ShopToggleButton"
shopToggleBtn.Size = UDim2.new(0, 160, 0, 42)
shopToggleBtn.Position = UDim2.new(1, -180, 0, 15)
shopToggleBtn.BackgroundColor3 = Color3.fromRGB(40, 140, 220)
shopToggleBtn.Text = "🛒 TOKO & UPGRADE"
shopToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
shopToggleBtn.Font = Enum.Font.FredokaOne
shopToggleBtn.TextSize = 14
shopToggleBtn.BorderSizePixel = 0
shopToggleBtn.Parent = screenGui

local sBtnCorner = Instance.new("UICorner")
sBtnCorner.CornerRadius = UDim.new(0, 10)
sBtnCorner.Parent = shopToggleBtn

-- Shop Modal Frame
local shopModal = Instance.new("ScrollingFrame")
shopModal.CanvasSize = UDim2.fromOffset(0, 390)
shopModal.ScrollBarThickness = 5
shopModal.ScrollingDirection = Enum.ScrollingDirection.Y
shopModal.ClipsDescendants = true
shopModal.Name = "ShopModal"
shopModal.Size = UDim2.new(0, 440, 0, 390)
shopModal.Position = UDim2.new(0.5, -220, 0.5, -195)
shopModal.BackgroundColor3 = Color3.fromRGB(25, 30, 40)
shopModal.BorderSizePixel = 0
shopModal.Visible = false
shopModal.Parent = screenGui

local modalCorner = Instance.new("UICorner")
modalCorner.CornerRadius = UDim.new(0, 14)
modalCorner.Parent = shopModal

local modalTitle = Instance.new("TextLabel")
modalTitle.Name = "ModalTitle"
modalTitle.Size = UDim2.new(1, -64, 0, 44)
modalTitle.TextWrapped = true
modalTitle.Position = UDim2.new(0, 0, 0, 8)
modalTitle.BackgroundTransparency = 1
modalTitle.Text = "🎈 TOKO PERLENGKAPAN FLY HIGH"
modalTitle.TextColor3 = Color3.fromRGB(255, 240, 200)
modalTitle.Font = Enum.Font.FredokaOne
modalTitle.TextSize = 18
modalTitle.Parent = shopModal

local closeBtn = Instance.new("TextButton")
closeBtn.Name = "CloseButton"
closeBtn.Size = UDim2.new(0, 44, 0, 44)
closeBtn.Position = UDim2.new(1, -52, 0, 4)
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Font = Enum.Font.FredokaOne
closeBtn.TextSize = 16
closeBtn.BorderSizePixel = 0
closeBtn.Parent = shopModal

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(1, 0)
closeCorner.Parent = closeBtn

-- Card 1: Emergency Kit
local card1 = Instance.new("Frame")
card1.Name = "Card1"
card1.Size = UDim2.new(1, -30, 0, 135)
card1.Position = UDim2.new(0, 15, 0, 60)
card1.BackgroundColor3 = Color3.fromRGB(35, 42, 55)
card1.BorderSizePixel = 0
card1.Parent = shopModal

local c1Corner = Instance.new("UICorner")
c1Corner.CornerRadius = UDim.new(0, 10)
c1Corner.Parent = card1

local c1Title = Instance.new("TextLabel")
c1Title.Size = UDim2.new(1, -20, 0, 24)
c1Title.Position = UDim2.new(0, 10, 0, 6)
c1Title.BackgroundTransparency = 1
c1Title.Text = "🛡️ Emergency Repair & Shield"
c1Title.TextColor3 = Color3.fromRGB(80, 220, 255)
c1Title.Font = Enum.Font.FredokaOne
c1Title.TextSize = 15
c1Title.TextXAlignment = Enum.TextXAlignment.Left
c1Title.Parent = card1

local c1Desc = Instance.new("TextLabel")
c1Desc.Size = UDim2.new(1, -20, 0, 42)
c1Desc.Position = UDim2.new(0, 10, 0, 32)
c1Desc.BackgroundTransparency = 1
c1Desc.Text = "Pulihkan seluruh lubang ke 0 seketika + Kebal 60 detik. Bisa dipakai saat 5 lubang terjun bebas (Clutch Save)! Tersimpan di akun, maksimal 1x per terbang."
c1Desc.TextColor3 = Color3.fromRGB(200, 220, 240)
c1Desc.Font = Enum.Font.Gotham
c1Desc.TextSize = 12
c1Desc.TextWrapped = true
c1Desc.TextXAlignment = Enum.TextXAlignment.Left
c1Desc.Parent = card1

local buyKitBtn = Instance.new("TextButton")
buyKitBtn.Name="BuyEmergencyKitButton"
buyKitBtn.Size = UDim2.new(1, -20, 0, 44)
buyKitBtn.Position = UDim2.new(0, 10, 0, 80)
buyKitBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 120)
buyKitBtn.Text = "Dapatkan Emergency Kit (Klik Beli)"
buyKitBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
buyKitBtn.Font = Enum.Font.FredokaOne
buyKitBtn.TextSize = 13
buyKitBtn.BorderSizePixel = 0
buyKitBtn.Parent = card1

local bKitCorner = Instance.new("UICorner")
bKitCorner.CornerRadius = UDim.new(0, 8)
bKitCorner.Parent = buyKitBtn

-- Card 2: AK-47 Upgrade
local card2 = Instance.new("Frame")
card2.Name = "Card2"
card2.Size = UDim2.new(1, -30, 0, 135)
card2.Position = UDim2.new(0, 15, 0, 205)
card2.BackgroundColor3 = Color3.fromRGB(35, 42, 55)
card2.BorderSizePixel = 0
card2.Parent = shopModal

local c2Corner = Instance.new("UICorner")
c2Corner.CornerRadius = UDim.new(0, 10)
c2Corner.Parent = card2

local c2Title = Instance.new("TextLabel")
c2Title.Size = UDim2.new(1, -20, 0, 24)
c2Title.Position = UDim2.new(0, 10, 0, 6)
c2Title.BackgroundTransparency = 1
c2Title.Text = "🔫 AK-47 Tactical Upgrade"
c2Title.TextColor3 = Color3.fromRGB(255, 200, 50)
c2Title.Font = Enum.Font.FredokaOne
c2Title.TextSize = 15
c2Title.TextXAlignment = Enum.TextXAlignment.Left
c2Title.Parent = card2

local c2Desc = Instance.new("TextLabel")
c2Desc.Size = UDim2.new(1, -20, 0, 42)
c2Desc.Position = UDim2.new(0, 10, 0, 32)
c2Desc.BackgroundTransparency = 1
c2Desc.Text = "Gantikan 2 rak pistol di balon menjadi AK-47 (30 peluru, otomatis cepat, amunisi tak terbatas). Hanya dapat dibeli & diaktifkan oleh Game Master."
c2Desc.TextColor3 = Color3.fromRGB(200, 220, 240)
c2Desc.Font = Enum.Font.Gotham
c2Desc.TextSize = 12
c2Desc.TextWrapped = true
c2Desc.TextXAlignment = Enum.TextXAlignment.Left
c2Desc.Parent = card2

local buyAKBtn = Instance.new("TextButton")
buyAKBtn.Name="BuyAK47Button"
buyAKBtn.Size = UDim2.new(1, -20, 0, 44)
buyAKBtn.Position = UDim2.new(0, 10, 0, 80)
buyAKBtn.BackgroundColor3 = Color3.fromRGB(210, 120, 20)
buyAKBtn.Text = "Beli AK-47 Upgrade (Khusus Master)"
buyAKBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
buyAKBtn.Font = Enum.Font.FredokaOne
buyAKBtn.TextSize = 13
buyAKBtn.BorderSizePixel = 0
buyAKBtn.Parent = card2

local bAKCorner = Instance.new("UICorner")
bAKCorner.CornerRadius = UDim.new(0, 8)
bAKCorner.Parent = buyAKBtn

-- Prices are retrieved on the client so regional prices match Roblox checkout.
local feedback=Instance.new("TextLabel",shopModal)
feedback.Name="ShopFeedback" feedback.Size=UDim2.new(1,-20,0,30) feedback.Position=UDim2.fromOffset(10,348)
feedback.BackgroundTransparency=1 feedback.TextColor3=Color3.fromRGB(255,230,140) feedback.TextSize=12 feedback.TextWrapped=true feedback.Text=""
local prices={}local busy={}local loading=false local refreshedAt=-math.huge
local function price(item)
 return prices[item] and (tostring(prices[item]).." Robux")or "lihat harga Roblox"
end
local function refreshButtons()
 buyKitBtn.Text=busy.EmergencyKit and "Membuka toko..." or ("Beli 1 Kit • "..price("EmergencyKit"))
 local credits=localPlayer:GetAttribute("AKCredits")or 0
 buyAKBtn.Text=busy.AK47Upgrade and "Memeriksa upgrade..." or (credits>0 and ("Gunakan Kredit AK-47 ("..credits..")")or ("Beli Upgrade • "..price("AK47Upgrade").." (Master)"))
end
local function refreshPrices()
 if loading or os.clock()-refreshedAt<60 then return end
 loading=true
 for _,item in ipairs({"EmergencyKit","AK47Upgrade"})do
  local ok,info=pcall(function()return Marketplace:GetProductInfoAsync(Config.PRODUCT_IDS[item],Enum.InfoType.Product)end)
  if ok and type(info.PriceInRobux)=="number"then
   prices[item]=info.PriceInRobux
   shopModal:SetAttribute(item.."Price",info.PriceInRobux)
  end
 end
 c1Title.Text="🛡️ Emergency Repair & Shield ("..price("EmergencyKit")..")"
 c2Title.Text="🔫 AK-47 Tactical Upgrade ("..price("AK47Upgrade")..")"
 refreshedAt=os.clock() loading=false refreshButtons()
end
local function request(item)
 if busy[item]then return end
 if localPlayer:GetAttribute("DataReady")~=true then feedback.Text="Data pemain sedang dimuat. Silakan coba sebentar lagi."return end
 busy[item]=true feedback.Text=""refreshButtons()
 shopPurchaseEvent:FireServer(item)
end
shopToggleBtn.MouseButton1Click:Connect(function()
 shopModal.Visible=not shopModal.Visible
 if shopModal.Visible then task.spawn(refreshPrices)end
end)
closeBtn.MouseButton1Click:Connect(function()shopModal.Visible=false end)
buyKitBtn.Activated:Connect(function()request("EmergencyKit")end)
buyAKBtn.Activated:Connect(function()request("AK47Upgrade")end)
shopPurchaseEvent.OnClientEvent:Connect(function(message)
 feedback.Text=message busy={}refreshButtons()
end)
Marketplace.PromptProductPurchaseFinished:Connect(function(userId,productId,purchased)
 if userId~=localPlayer.UserId then return end
 for item,id in pairs(Config.PRODUCT_IDS)do
  if id==productId then
   busy[item]=nil
   if not purchased then feedback.Text="Pembelian dibatalkan."
   elseif feedback.Text==""then feedback.Text="Pembelian sedang diverifikasi Roblox..."end
   refreshButtons()break
  end
 end
 -- Item grants always come from server ProcessReceipt, never from this client event.
end)
localPlayer:GetAttributeChangedSignal("AKCredits"):Connect(refreshButtons)
refreshButtons()
task.spawn(refreshPrices)
