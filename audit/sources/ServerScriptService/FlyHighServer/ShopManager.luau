local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local Marketplace=game:GetService("MarketplaceService")
local Config=require(RS.FlyHigh.Modules.FlyHighConfig)
local U=require(script.Parent.ServerUtils)
local remote=RS.FlyHigh.Remotes.ShopPurchaseEvent
local rate=U.RateLimiter(1)
local function master(p)
 local fd=U.Flight(p)
 if fd then return fd.master==p and U.Alive(p,fd) end
 return p:GetAttribute("IsMaster")==true and p:GetAttribute("CurrentPod")~=nil and U.Alive(p)
end
local function upgrade(p)
 if not master(p) then return false end
 local fd=U.Flight(p)
 if (fd and fd.balloon:GetAttribute("AKUpgraded")) or p:GetAttribute("BoughtAK47") then return false end
 if not _G.FlyHighDataManager.ConsumeAKCredit(p) then return false end
 if fd then
  fd.balloon:SetAttribute("AKUpgraded",true)
  _G.FlyHighWeaponManager.CleanupBalloon(fd.balloon)
  _G.FlyHighWeaponManager.SetupWeaponRacks(fd.balloon,true)
 else p:SetAttribute("BoughtAK47",true) end
 return true
end
remote.OnServerEvent:Connect(function(p,item)
 if type(item)~="string" or not Config.PRODUCT_IDS[item] or not rate(p) or not p:GetAttribute("DataReady") then return end
 if item=="AK47Upgrade" then
  if not master(p) then remote:FireClient(p,"Hanya Party Master yang dapat menyediakan AK-47.") return end
  if upgrade(p) then remote:FireClient(p,"AK-47 terpasang untuk penerbangan ini.") return end
  local fd=U.Flight(p)
  if p:GetAttribute("BoughtAK47") or (fd and fd.balloon:GetAttribute("AKUpgraded")) then
   remote:FireClient(p,"AK-47 sudah tersedia.") return
  end
 end
 local id=Config.PRODUCT_IDS[item]
 if id<=0 or game.GameId==0 then
  remote:FireClient(p,"Pembelian belum tersedia: Developer Product belum dikonfigurasi.") return
 end
 local ok=pcall(function() Marketplace:PromptProductPurchase(p,id) end)
 if not ok then remote:FireClient(p,"Toko belum dapat dibuka. Silakan coba kembali.") end
end)
Marketplace.ProcessReceipt=function(receipt)
 local p=Players:GetPlayerByUserId(receipt.PlayerId)
 if not p or not _G.FlyHighDataManager then return Enum.ProductPurchaseDecision.NotProcessedYet end
 local item
 for name,id in pairs(Config.PRODUCT_IDS) do if id>0 and id==receipt.ProductId then item=name break end end
 if not item or not _G.FlyHighDataManager.GrantReceipt(p,tostring(receipt.PurchaseId),item) then return Enum.ProductPurchaseDecision.NotProcessedYet end
 if item=="AK47Upgrade" then upgrade(p) end
 remote:FireClient(p,item=="EmergencyKit" and "Emergency Kit ditambahkan ke stok." or "Upgrade diterima. Kredit tersimpan bila belum dipasang.")
 return Enum.ProductPurchaseDecision.PurchaseGranted
end
