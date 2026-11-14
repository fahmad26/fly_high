local HUDMotion = require(game:GetService("ReplicatedStorage"):WaitForChild("FlyHigh"):WaitForChild("Modules"):WaitForChild("HUDMotion"))
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Marketplace=game:GetService("MarketplaceService")
local modules=ReplicatedStorage:WaitForChild("FlyHigh"):WaitForChild("Modules")
local Config=require(modules.FlyHighConfig)
local Assets=require(modules.HUDImageAssets)
local ShopTabsController=require(modules:WaitForChild("ShopTabsController"))
local DailyLoginModal=require(modules:WaitForChild("DailyLoginModal"))

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

local remotes = ReplicatedStorage:WaitForChild("FlyHigh"):WaitForChild("Remotes")
local shopPurchaseEvent = remotes:WaitForChild("ShopPurchaseEvent")
local weaponLoadoutEvent = remotes:WaitForChild("WeaponLoadoutEvent")
local playerLabelsEvent = remotes:WaitForChild("PlayerLabelsEvent")

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
local shopModal = Instance.new("Frame")
shopModal.Name = "ShopModal"
shopModal.Size = UDim2.new(0, 440, 0, 390)
shopModal.Position = UDim2.new(0.5, -220, 0.5, -195)
shopModal.BackgroundColor3 = Color3.fromRGB(25, 30, 40)
shopModal.BorderSizePixel = 0
shopModal.Active = true
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
card1.Active = true
card1.Parent = shopModal

local c1Corner = Instance.new("UICorner")
c1Corner.CornerRadius = UDim.new(0, 10)
c1Corner.Parent = card1

local c1Title = Instance.new("TextLabel")
c1Title.Name = "ProductTitle"
c1Title.Size = UDim2.new(1, -20, 0, 24)
c1Title.Position = UDim2.new(0, 10, 0, 6)
c1Title.BackgroundTransparency = 1
c1Title.Text = "Emergency Kit"
c1Title.TextColor3 = Color3.fromRGB(80, 220, 255)
c1Title.Font = Enum.Font.FredokaOne
c1Title.TextSize = 15
c1Title.TextXAlignment = Enum.TextXAlignment.Left
c1Title.Parent = card1

local c1Desc = Instance.new("TextLabel")
c1Desc.Name = "ProductDescription"
c1Desc.Size = UDim2.new(1, -20, 0, 42)
c1Desc.Position = UDim2.new(0, 10, 0, 32)
c1Desc.BackgroundTransparency = 1
c1Desc.Text = "Tambal semua lubang. Kebal 60 dtk. Sekali per terbang."
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
card2.Active = true
card2.Parent = shopModal

local c2Corner = Instance.new("UICorner")
c2Corner.CornerRadius = UDim.new(0, 10)
c2Corner.Parent = card2

local c2Title = Instance.new("TextLabel")
c2Title.Name = "ProductTitle"
c2Title.Size = UDim2.new(1, -20, 0, 24)
c2Title.Position = UDim2.new(0, 10, 0, 6)
c2Title.BackgroundTransparency = 1
c2Title.Text = "AK-47 Permanen"
c2Title.TextColor3 = Color3.fromRGB(255, 200, 50)
c2Title.Font = Enum.Font.FredokaOne
c2Title.TextSize = 15
c2Title.TextXAlignment = Enum.TextXAlignment.Left
c2Title.Parent = card2

local c2Desc = Instance.new("TextLabel")
c2Desc.Name = "ProductDescription"
c2Desc.Size = UDim2.new(1, -20, 0, 42)
c2Desc.Position = UDim2.new(0, 10, 0, 32)
c2Desc.BackgroundTransparency = 1
c2Desc.Text = "Satu AK-47 permanen. Pilih raknya di Setelan."
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
buyAKBtn.Text = "Beli 1 AK-47"
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
local refreshShopTabs=ShopTabsController.Attach(shopModal,localPlayer,function(msg) feedback.Text=msg or "" end)
DailyLoginModal.Ensure(screenGui,localPlayer)
local prices={}local busy={}local loading=false local refreshedAt=-math.huge
local function price(item)
 return prices[item] and (tostring(prices[item]).." Robux")or "lihat harga Roblox"
end
local function refreshButtons()
 buyKitBtn.Text=busy.EmergencyKit and "Membuka toko..." or ("Beli 1 Kit • "..price("EmergencyKit"))
 buyAKBtn.Text=busy.AK47Upgrade and "Membuka toko..." or ("Beli 1 AK-47 • "..price("AK47Upgrade"))
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
 refreshedAt=os.clock() loading=false refreshButtons()
end
local function request(item)
 if busy[item]then return end
 if localPlayer:GetAttribute("DataReady")~=true then feedback.Text="Data pemain sedang dimuat. Silakan coba sebentar lagi."return end
 busy[item]=true feedback.Text=""refreshButtons()
 shopPurchaseEvent:FireServer(item)
end
shopToggleBtn.Activated:Connect(function()
 HUDMotion.Toggle(shopModal)
 if shopModal.Visible then
  feedback.Text=""
  if refreshShopTabs then refreshShopTabs() end
  task.spawn(refreshPrices)
 end
end)
closeBtn.Activated:Connect(function()HUDMotion.SetVisible(shopModal,false) end)
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
refreshButtons()
task.spawn(refreshPrices)

local function settingsText(class, name, parent, caption, size, x, y, w, h)
 local object=Instance.new(class)
 object.Name=name
 object.Position=UDim2.new(x, x==0 and 12 or 0, 0, y)
 object.Size=UDim2.new(w, w==1 and -24 or 0, 0, h)
 object.BackgroundTransparency=1
 object.TextColor3=Color3.fromRGB(237,245,255)
 object.Font=Enum.Font.GothamBold
 object.TextSize=size
 object.Text=caption
 object.ZIndex=parent:IsA("GuiObject") and parent.ZIndex+2 or 1
 object.Parent=parent
 return object
end
local function styleButton(button,color)
 button.BackgroundColor3=color
 button.BackgroundTransparency=0
 local round=Instance.new("UICorner",button)
 round.CornerRadius=UDim.new(0,9)
 return button
end
local blue=Color3.fromRGB(31,71,109)
local teal=Color3.fromRGB(18,122,111)
local dim=Color3.fromRGB(38,47,66)
local settingsToggle=styleButton(settingsText("TextButton","SettingsToggleButton",screenGui,"SETELAN",11,0,0,0,50),blue)
local settings=Instance.new("Frame")
settings.Name="WeaponSettingsModal"
settings.BackgroundColor3=Color3.fromRGB(13,32,56)
settings.BorderSizePixel=0
settings.Active=true
settings.Visible=false
settings.ZIndex=22
local corners=Instance.new("UICorner",settings)
corners.CornerRadius=UDim.new(0,14)
local outline=Instance.new("UIStroke",settings)
outline.Color=Color3.fromRGB(226,180,90)
outline.Thickness=2
outline.ApplyStrokeMode=Enum.ApplyStrokeMode.Border
local title=settingsText("TextLabel","Title",settings,"Senjata Balon",22,0,8,1,44)
title.Size=UDim2.new(1,-72,0,44)
title.Font=Enum.Font.FredokaOne
title.TextColor3=Color3.fromRGB(255,230,153)
title.TextXAlignment=Enum.TextXAlignment.Center
local dismiss=styleButton(settingsText("TextButton","SettingsCloseButton",settings,"×",23,1,8,0,44),blue)
dismiss.Position=UDim2.new(1,-56,0,8)
dismiss.Size=UDim2.fromOffset(44,44)
local inventory=settingsText("TextLabel","InventoryCount",settings,"",14,0,55,1,24)
inventory.TextColor3=Color3.fromRGB(182,222,243)
local note=settingsText("TextLabel","LaunchNote",settings,
 "Untuk peluncuranmu sebagai Party Master.",13,0,81,1,37)
note.TextWrapped=true
local message=settingsText("TextLabel","SettingsFeedback",settings,"",13,0,239,1,33)
message.TextWrapped=true
message.TextColor3=Color3.fromRGB(255,219,143)
local slots={}
local function loadoutLocked()
 return localPlayer:GetAttribute("InFlight")==true
end
local function addChoiceArt(button)
 button.BackgroundTransparency=1
 local oldStroke=button:FindFirstChildOfClass("UIStroke")
 if oldStroke then oldStroke.Enabled=false end
 local visual=HUDMotion.Visual(button)
 visual.BackgroundTransparency=1
 local pill=visual:FindFirstChild("ChoicePill")
 if not pill then
  pill=Instance.new("Frame")
  pill.Name="ChoicePill"
  pill.Size=UDim2.fromScale(1,1)
  pill.BorderSizePixel=0
  pill.Active=false
  pill.ZIndex=button.ZIndex+1
  pill.Parent=visual
  local corner=Instance.new("UICorner",pill)
  corner.CornerRadius=UDim.new(0,10)
  local rim=Instance.new("UIStroke",pill)
  rim.Name="ChoiceBorder"
  rim.ApplyStrokeMode=Enum.ApplyStrokeMode.Border
  rim.Thickness=1.6
  local grad=Instance.new("UIGradient",pill)
  grad.Rotation=90
  grad.Color=ColorSequence.new(Color3.fromRGB(255,255,255),Color3.fromRGB(196,208,224))
 end
 pill.BackgroundTransparency=0
 local label=visual:FindFirstChild("ChoiceCaption")
 if not label then
  label=Instance.new("TextLabel")
  label.Name="ChoiceCaption"
  label.AnchorPoint=Vector2.new(.5,.5)
  label.Position=UDim2.fromScale(.5,.5)
  label.Size=UDim2.new(1,-16,1,-6)
  label.BackgroundTransparency=1
  label.Font=Enum.Font.FredokaOne
  label.TextSize=14
  label.TextScaled=true
  label.TextWrapped=false
  label.TextColor3=Color3.new(1,1,1)
  label.TextStrokeTransparency=1
  label.ZIndex=button.ZIndex+2
  label.Parent=visual
  local constraint=Instance.new("UITextSizeConstraint",label)
  constraint.MinTextSize=9
  constraint.MaxTextSize=14
  local textStroke=Instance.new("UIStroke",label)
  textStroke.ApplyStrokeMode=Enum.ApplyStrokeMode.Contextual
  textStroke.Thickness=1.4
  textStroke.Color=Color3.fromRGB(4,10,24)
 end
 button.TextTransparency=1
end
local function paintChoice(button,text,selected,accentColor,accentRim)
 button.Text=text
 local visual=HUDMotion.Visual(button)
 local pill=visual:FindFirstChild("ChoicePill")
 if pill then
  pill.BackgroundColor3=accentColor or (selected and Color3.fromRGB(36,186,92) or Color3.fromRGB(36,56,88))
  pill.BackgroundTransparency=0
  local rim=pill:FindFirstChildOfClass("UIStroke")
  if rim then
   rim.Color=accentRim or (selected and Color3.fromRGB(110,231,183) or Color3.fromRGB(90,119,163))
   rim.Transparency=selected and .08 or .22
  end
 end
 local cap=visual:FindFirstChild("ChoiceCaption",true)
 if cap then cap.Text=text cap.TextColor3=Color3.new(1,1,1) end
end
local function refreshLoadout()
 local owned=localPlayer:GetAttribute("AKOwned") or 0
 local count=(localPlayer:GetAttribute("AKSlot1") and 1 or 0)+(localPlayer:GetAttribute("AKSlot2") and 1 or 0)
 local locked=loadoutLocked()
 inventory.Text=string.format("AK-47 dimiliki: %d  ·  Di inventaris: %d",owned,math.max(0,owned-count))
 for slot,buttons in ipairs(slots) do
  local equipped=localPlayer:GetAttribute("AKSlot"..slot)==true
  local hgText=(equipped and "Handgun" or "✓ Handgun")
  local akText=(equipped and "✓ AK-47" or "AK-47")
  if locked then
   hgText=(not equipped and "🔒 " or "")..hgText
   akText=(equipped and "🔒 " or "")..akText
  end
  paintChoice(buttons.handgun,hgText,not equipped,
   locked and (not equipped and Color3.fromRGB(34,88,150) or dim) or nil,
   locked and (not equipped and Color3.fromRGB(96,165,250) or Color3.fromRGB(64,80,108)) or nil)
  paintChoice(buttons.rifle,akText,equipped,
   locked and (equipped and Color3.fromRGB(34,88,150) or dim) or nil,
   locked and (equipped and Color3.fromRGB(96,165,250) or Color3.fromRGB(64,80,108)) or nil)
  if not locked and not equipped and owned<=count then
   local visual=HUDMotion.Visual(buttons.rifle)
   local pill=visual:FindFirstChild("ChoicePill")
   if pill then
    pill.BackgroundColor3=dim
    local rim=pill:FindFirstChildOfClass("UIStroke")
    if rim then rim.Color=Color3.fromRGB(78,94,122) end
   end
   local cap=visual:FindFirstChild("ChoiceCaption",true)
   if cap then cap.TextColor3=Color3.fromRGB(168,184,210) end
  end
  for _,button in {buttons.handgun,buttons.rifle} do
   button.Interactable=not locked
   button.Selectable=not locked
   local visual=HUDMotion.Visual(button)
   local cap=visual:FindFirstChild("ChoiceCaption",true)
   if cap then
    cap.TextTransparency=locked and .16 or 0
    if locked then cap.TextColor3=Color3.fromRGB(185,204,230) end
   end
  end
 end
end
local function chooseWeapon(slot,kind)
 if not loadoutLocked() then weaponLoadoutEvent:FireServer(slot,kind) end
end
for slot=1,2 do
 local y=124+(slot-1)*56
 local name=settingsText("TextLabel","SlotLabel"..slot,settings,"Rak "..slot,14,0,y,0.19,44)
 name.TextXAlignment=Enum.TextXAlignment.Left
 local handgun=styleButton(settingsText("TextButton","HandgunSlot"..slot,settings,"Handgun",14,.23,y,.35,44),blue)
 local rifle=styleButton(settingsText("TextButton","AK47Slot"..slot,settings,"AK-47",14,.61,y,.35,44),blue)
 addChoiceArt(handgun)
 addChoiceArt(rifle)
 handgun.Activated:Connect(function() chooseWeapon(slot,"Pistol") end)
 rifle.Activated:Connect(function() chooseWeapon(slot,"AK47") end)
 slots[slot]={handgun=handgun,rifle=rifle}
end
for _,key in {"AKOwned","AKSlot1","AKSlot2"} do
 localPlayer:GetAttributeChangedSignal(key):Connect(refreshLoadout)
end
local launchNote=note.Text
local function updateFlightLock()
 note.Text=loadoutLocked() and "Senjata terkunci saat terbang." or launchNote
 note.Visible=true
 message.Text=""
 refreshLoadout()
end
localPlayer:GetAttributeChangedSignal("InFlight"):Connect(updateFlightLock)
weaponLoadoutEvent.OnClientEvent:Connect(function(result)
 message.Text=result
 note.Visible=false
end)
settingsToggle.Activated:Connect(function()
 HUDMotion.Toggle(settings)
 if settings.Visible then updateFlightLock() end
end)
dismiss.Activated:Connect(function() HUDMotion.SetVisible(settings,false) end)

local labelsTitle=settingsText("TextLabel","PlayerLabelsLabel",settings,"Tulisan di atas pemain",14,0,0,1,44)
labelsTitle.TextXAlignment=Enum.TextXAlignment.Left
local labelsToggle=styleButton(settingsText("TextButton","PlayerLabelsToggle",settings,"Tampil",14,0,0,1,44),blue)
addChoiceArt(labelsToggle)
local overheadTag="FlyHighPlayerOverhead"
local nativeNameDistance=localPlayer.NameDisplayDistance
local function labelsShown()
 return localPlayer:GetAttribute("ShowPlayerLabels")~=false
end
local function updateOverhead(gui)
 if gui:IsA("BillboardGui") then gui.Enabled=labelsShown() end
end
local function refreshPlayerLabels()
 local visible=labelsShown()
 paintChoice(labelsToggle,visible and "Nama: Tampil" or "Nama: Sembunyi",visible)
 localPlayer.NameDisplayDistance=visible and nativeNameDistance or 0
 for _,gui in CollectionService:GetTagged(overheadTag) do updateOverhead(gui) end
end
labelsToggle.Activated:Connect(function() playerLabelsEvent:FireServer(not labelsShown()) end)
CollectionService:GetInstanceAddedSignal(overheadTag):Connect(updateOverhead)
localPlayer:GetAttributeChangedSignal("ShowPlayerLabels"):Connect(refreshPlayerLabels)
updateFlightLock()
refreshPlayerLabels()
local motionToggle=styleButton(settingsText("TextButton","ReduceMotionToggle",settings,"Animasi: Penuh",13,0,0,1,44),blue)
addChoiceArt(motionToggle)
local function refreshMotion()
 local reduced=localPlayer:GetAttribute("ReduceHUDMotion")==true
 paintChoice(motionToggle,reduced and "Animasi: Ringan" or "Animasi: Penuh",true,
  reduced and Color3.fromRGB(22,126,184) or Color3.fromRGB(36,112,216),
  reduced and Color3.fromRGB(125,211,252) or Color3.fromRGB(96,165,250))
end
motionToggle.Activated:Connect(function() localPlayer:SetAttribute("ReduceHUDMotion",localPlayer:GetAttribute("ReduceHUDMotion")~=true) end)
localPlayer:GetAttributeChangedSignal("ReduceHUDMotion"):Connect(refreshMotion)
refreshMotion()
settings.Parent=screenGui
