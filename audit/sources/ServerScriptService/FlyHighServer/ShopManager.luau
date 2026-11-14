local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local Marketplace=game:GetService("MarketplaceService")
local Config=require(RS.FlyHigh.Modules.FlyHighConfig)
local U=require(script.Parent.ServerUtils)
local remotes=RS.FlyHigh.Remotes
local function ensureRemote(name,className)
 local found=remotes:FindFirstChild(name)
 if found then return found end
 local inst=Instance.new(className)
 inst.Name=name
 inst.Parent=remotes
 return inst
end
local remote=remotes.ShopPurchaseEvent
local loadout=remotes.WeaponLoadoutEvent
local playerLabels=remotes.PlayerLabelsEvent
local dailyFn=ensureRemote("DailyLoginFunction","RemoteFunction")
local coinShopFn=ensureRemote("ShopCoinFunction","RemoteFunction")
ensureRemote("CoinToastEvent","RemoteEvent")
ensureRemote("UseBuffEvent","RemoteEvent")
local rate=U.RateLimiter(1)
local loadoutRate=U.RateLimiter(0.25)
local labelsRate=U.RateLimiter(0.25)
local dailyRate=U.RateLimiter(1)
local coinShopRate=U.RateLimiter(0.35)
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
dailyFn.OnServerInvoke=function(p,action)
 if not p:GetAttribute("DataReady") or not _G.FlyHighDataManager or type(action)~="string" then
  return {ok=false,message="Data belum siap."}
 end
 if action=="GetState" then
  local state=_G.FlyHighDataManager.GetDailyState(p)
  return {ok=state~=nil,state=state}
 elseif action=="Claim" then
  if not dailyRate(p) then return {ok=false,message="Tunggu sebentar sebelum klaim ulang."} end
  local ok,msg,reward,state=_G.FlyHighDataManager.ClaimDailyLogin(p)
  return {ok=ok,message=msg,reward=reward,state=state or _G.FlyHighDataManager.GetDailyState(p)}
 end
 return {ok=false,message="Aksi tidak dikenal."}
end
coinShopFn.OnServerInvoke=function(p,action,arg1,arg2)
 if not p:GetAttribute("DataReady") or not _G.FlyHighDataManager or type(action)~="string" then
  return {ok=false,message="Data belum siap."}
 end
 if not coinShopRate(p) then
  return {ok=false,message="Terlalu cepat, coba sebentar lagi."}
 end
 if action=="BuySupply" then
  if type(arg1)~="string" then return {ok=false,message="Item tidak valid."} end
  local ok,msg=_G.FlyHighDataManager.BuySupply(p,arg1)
  return {ok=ok,message=msg,state=_G.FlyHighDataManager.GetDailyState(p)}
 elseif action=="BuyCosmetic" or action=="EquipCosmetic" or action=="UnequipCosmetic" then
  if type(arg1)~="string" then return {ok=false,message="Kategori tidak valid."} end
  local subAction=action=="BuyCosmetic" and "Buy" or (action=="EquipCosmetic" and "Equip" or "Unequip")
  local ok,msg=_G.FlyHighDataManager.CosmeticAction(p,subAction,arg1,type(arg2)=="string" and arg2 or "")
  return {ok=ok,message=msg,state=_G.FlyHighDataManager.GetDailyState(p)}
 end
 return {ok=false,message="Aksi toko tidak dikenal."}
end
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
