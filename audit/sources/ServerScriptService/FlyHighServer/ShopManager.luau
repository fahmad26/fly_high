local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local Marketplace=game:GetService("MarketplaceService")
local Config=require(RS.FlyHigh.Modules.FlyHighConfig)
local U=require(script.Parent.ServerUtils)
local remote=RS.FlyHigh.Remotes.ShopPurchaseEvent
local loadout=RS.FlyHigh.Remotes.WeaponLoadoutEvent
local playerLabels=RS.FlyHigh.Remotes.PlayerLabelsEvent
local rate=U.RateLimiter(1)
local loadoutRate=U.RateLimiter(0.25)
local labelsRate=U.RateLimiter(0.25)
local Manager={}
_G.FlyHighShopManager=Manager
loadout.OnServerEvent:Connect(function(p,slot,kind)
 if not loadoutRate(p) or not p:GetAttribute("DataReady") then return end
 local ok,message=_G.FlyHighDataManager.SetWeaponSlot(p,slot,kind)
 loadout:FireClient(p,ok and "Tersimpan untuk penerbangan berikutnya." or message)
end)
playerLabels.OnServerEvent:Connect(function(p,show)
 if type(show)~="boolean" or not p:GetAttribute("DataReady") or not labelsRate(p) then return end
 _G.FlyHighDataManager.SetPlayerLabels(p,show)
end)
remote.OnServerEvent:Connect(function(p,item)
 if type(item)~="string" or not Config.PRODUCT_IDS[item] or not rate(p) or not p:GetAttribute("DataReady") then return end
 local id=Config.PRODUCT_IDS[item]
 if id<=0 then
  remote:FireClient(p,"Pembelian belum tersedia: Developer Product belum dikonfigurasi.") return
 end
 if game.GameId==0 then
  remote:FireClient(p,"Produk siap. Publikasikan place ke experience Fly High untuk menguji pembelian.") return
 end
 local ok=pcall(function() Marketplace:PromptProductPurchase(p,id) end)
 if not ok then remote:FireClient(p,"Toko belum dapat dibuka. Silakan coba kembali.") end
end)
function Manager.ProcessReceipt(receipt)
 local p=Players:GetPlayerByUserId(receipt.PlayerId)
 if not p or not _G.FlyHighDataManager then return Enum.ProductPurchaseDecision.NotProcessedYet end
 local item
 for name,id in pairs(Config.PRODUCT_IDS) do if id>0 and id==receipt.ProductId then item=name break end end
 if not item then return Enum.ProductPurchaseDecision.NotProcessedYet end
 local granted,isNew=_G.FlyHighDataManager.GrantReceipt(p,tostring(receipt.PurchaseId),item)
 if not granted then return Enum.ProductPurchaseDecision.NotProcessedYet end
 if isNew then
  remote:FireClient(p,item=="EmergencyKit" and "Emergency Kit ditambahkan ke stok." or "1 AK-47 permanen ditambahkan ke inventaris.")
 end
 return Enum.ProductPurchaseDecision.PurchaseGranted
end
Marketplace.ProcessReceipt=Manager.ProcessReceipt
