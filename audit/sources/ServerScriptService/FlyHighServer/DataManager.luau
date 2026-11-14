local Players=game:GetService("Players")
local DS=game:GetService("DataStoreService")
local RunService=game:GetService("RunService")
local Http=game:GetService("HttpService")
local RS=game:GetService("ReplicatedStorage")
local Catalog=require(RS.FlyHigh.Modules.DailyAndShopCatalog)
local U=require(script.Parent.ServerUtils)
local remotes=RS.FlyHigh.Remotes
local offline=RunService:IsStudio() and game.GameId==0
local store=not offline and DS:GetDataStore("FlyHigh_PlayerData_v1") or nil
local token=game.JobId~="" and game.JobId or Http:GenerateGUID(false)
local sessions={}
local Manager={}
_G.FlyHighDataManager=Manager
local function number(v)
 return type(v)=="number" and v==v and math.clamp(math.floor(v),0,1e9) or 0
end
local function cleanOwned(tbl)
 local out={}
 if type(tbl)~="table" then return out end
 for k,v in pairs(tbl) do
  if type(k)=="string" and v==true and Catalog.COSMETICS_BY_KEY[k] then out[k]=true end
 end
 return out
end
local function cleanTemp(tbl)
 local out={}
 if type(tbl)~="table" then return out end
 local now=os.time()
 for k,v in pairs(tbl) do
  if type(k)=="string" and type(v)=="number" and v==v and v>now and Catalog.COSMETICS_BY_KEY[k] then
   out[k]=math.floor(v)
  end
 end
 return out
end
local function cleanEquipped(tbl)
 local src=type(tbl)=="table" and tbl or {}
 local out={frame="none",tracer="none",title="none"}
 for _,cat in ipairs({"frame","tracer","title"}) do
  local id=src[cat]
  if type(id)=="string" and id~="none" and Catalog.GetCosmetic(cat,id) then out[cat]=id end
 end
 return out
end
local function pruneExpiredTemp(d,now)
 local t=now or os.time()
 local changed=false
 for k,exp in pairs(d.TempCosmetics) do
  if type(exp)~="number" or exp<=t or not Catalog.COSMETICS_BY_KEY[k] then
   d.TempCosmetics[k]=nil changed=true
  end
 end
 for _,cat in ipairs({"frame","tracer","title"}) do
  local id=d.EquippedCosmetics[cat]
  if id~="none" then
   local key=Catalog.CosmeticKey(cat,id)
   local hasPerm=d.OwnedCosmetics[key]==true
   local hasTemp=d.TempCosmetics[key]~=nil and d.TempCosmetics[key]>t
   if not hasPerm and not hasTemp then
    d.EquippedCosmetics[cat]="none" changed=true
   end
  end
 end
 return changed
end
local function clean(d)
 d=type(d)=="table" and d or {}
 local owned=number(d.AKOwned==nil and d.AKCredits or d.AKOwned)
 local slot1=owned>=1 and d.AKSlot1==true
 local slot2=owned>=(slot1 and 2 or 1) and d.AKSlot2==true
 local progress=d.DailyProgress==nil and 1 or number(d.DailyProgress)
 local cleaned={MaxAltitude=math.min(10000,number(d.MaxAltitude)),SummitCount=number(d.SummitCount),
  EmergencyKits=number(d.EmergencyKits),AKOwned=owned,AKSlot1=slot1,AKSlot2=slot2,ShowPlayerLabels=d.ShowPlayerLabels~=false,
  SkyCoins=number(d.SkyCoins),DailyProgress=math.clamp(progress<1 and 1 or progress,1,7),
  LastDailyClaimDay=number(d.LastDailyClaimDay),SpeedBoostStock=number(d.SpeedBoostStock),RopeBuffStock=number(d.RopeBuffStock),
  OwnedCosmetics=cleanOwned(d.OwnedCosmetics),TempCosmetics=cleanTemp(d.TempCosmetics),EquippedCosmetics=cleanEquipped(d.EquippedCosmetics),
  Receipts=type(d.Receipts)=="table" and d.Receipts or {},Session=d.Session}
 pruneExpiredTemp(cleaned)
 return cleaned
end
local function snapshot(d)
 local copy=table.clone(d)
 copy.Receipts=table.clone(d.Receipts)
 copy.OwnedCosmetics=table.clone(d.OwnedCosmetics)
 copy.TempCosmetics=table.clone(d.TempCosmetics)
 copy.EquippedCosmetics=table.clone(d.EquippedCosmetics)
 return copy
end
local function attributes(p,d)
 pruneExpiredTemp(d)
 for _,key in ipairs({"MaxAltitude","SummitCount","EmergencyKits","AKOwned","AKSlot1","AKSlot2","ShowPlayerLabels","SkyCoins","DailyProgress","LastDailyClaimDay","SpeedBoostStock","RopeBuffStock"}) do p:SetAttribute(key,d[key]) end
 p:SetAttribute("DailyClaimedToday",d.LastDailyClaimDay>=Catalog.GetUTC7Day())
 p:SetAttribute("EquippedFrame",d.EquippedCosmetics.frame)
 p:SetAttribute("EquippedTracer",d.EquippedCosmetics.tracer)
 p:SetAttribute("EquippedTitle",d.EquippedCosmetics.title)
 p:SetAttribute("OwnedCosmeticsJson",Http:JSONEncode(d.OwnedCosmetics))
 p:SetAttribute("TempCosmeticsJson",Http:JSONEncode(d.TempCosmetics))
 local stats=p:FindFirstChild("leaderstats")
 if stats then stats["Rekor (km)"].Value=d.MaxAltitude stats.Puncak.Value=d.SummitCount end
end
local function loseSession(p,s)
 if s.lost then return end
 s.lost=true
 p:SetAttribute("DataReady",false)
 p:SetAttribute("DataSessionLost",true)
 warn("[DataManager] Session ownership lost; data mutations fenced: "..p.UserId)
 task.defer(function()
  if p.Parent==Players then p:Kick("Sesi data berpindah atau berakhir. Silakan masuk kembali agar progres aman.") end
 end)
end
local function writable(s)
 return s and not s.lost and not s.released
end
local function write(p,s,data,release)
 if not writable(s) then return false end
 if offline then s.savedLabels=data.ShowPlayerLabels return true end
 data.Session=release and nil or {Id=token,Expires=os.time()+180}
 -- Explicit conditional: Lua's and/or cannot select nil.
 if release then data.Session=nil end
 for attempt=1,3 do
  local ownershipLost=false
  local ok,result=pcall(function()
   return store:UpdateAsync("User_"..p.UserId,function(old)
    old=clean(old)
    ownershipLost=not old.Session or old.Session.Id~=token
    if ownershipLost then return nil end
    return data
   end)
  end)
  -- Only a completed UpdateAsync confirms ownership loss; network errors remain retryable.
  if ok and ownershipLost then loseSession(p,s) return false end
  if ok and result then s.savedLabels=data.ShowPlayerLabels return true end
  if attempt<3 then task.wait(attempt) end
 end
 warn("[DataManager] Save failed; retained session data for retry: "..p.UserId)
 return false
end
function Manager.Save(p,release)
 local s=sessions[p]
 if not writable(s) then return false end
 while s.busy do task.wait(0.05) end
 if sessions[p]~=s or not writable(s) then return false end
 s.busy=true
 local ok=write(p,s,snapshot(s.data),release)
 if ok and release then s.released=true end
 s.busy=false
 return ok
end
local function added(p)
 if sessions[p] then return end
 p:SetAttribute("DataReady",false)
 local data
 if offline then data=clean(nil)
 else
  for attempt=1,3 do
   local ok,result=pcall(function()
    return store:UpdateAsync("User_"..p.UserId,function(old)
     local d=clean(old)
     if d.Session and d.Session.Id~=token and (d.Session.Expires or 0)>os.time() then return nil end
     d.Session={Id=token,Expires=os.time()+180}
     return d
    end)
   end)
   if ok and result then data=clean(result) break end
   if attempt<3 then task.wait(attempt*2) end
  end
 end
 if not data then p:Kick("Data belum dapat dimuat dengan aman. Silakan masuk kembali.") return end
 local s={data=data,busy=false,savedLabels=data.ShowPlayerLabels}
 sessions[p]=s
 if p.Parent~=Players then Manager.Save(p,true) sessions[p]=nil return end
 local stats=Instance.new("Folder") stats.Name="leaderstats" stats.Parent=p
 local a=Instance.new("IntValue") a.Name="Rekor (km)" a.Parent=stats
 local b=Instance.new("IntValue") b.Name="Puncak" b.Parent=stats
 attributes(p,data) p:SetAttribute("DataReady",true)
end
function Manager.UpdateAltitude(p,km)
 local s=sessions[p]
 if writable(s) and km==km and km>s.data.MaxAltitude then s.data.MaxAltitude=math.clamp(math.floor(km),0,10000) attributes(p,s.data) end
end
function Manager.AddSummit(p)
 local s=sessions[p] if not writable(s) then return end
 s.data.SummitCount+=1 s.data.MaxAltitude=10000 attributes(p,s.data)
 task.spawn(Manager.Save,p,false)
end
function Manager.ModifyEmergencyKits(p,delta)
 local s=sessions[p]
 if not writable(s) or s.busy or (delta~=-1 and delta~=1) or s.data.EmergencyKits+delta<0 then return false end
 s.data.EmergencyKits+=delta attributes(p,s.data)
 task.spawn(Manager.Save,p,false)
 return true
end
function Manager.GetWeaponLoadout(p)
 local s=sessions[p]
 if not writable(s) then return false,false end
 return s.data.AKSlot1,s.data.AKSlot2
end
function Manager.SetWeaponSlot(p,slot,kind)
 if (slot~=1 and slot~=2) or (kind~="Pistol" and kind~="AK47") then return false,"Pilihan senjata tidak valid." end
 if U.Flight(p) then return false,"Pilihan senjata terkunci selama penerbangan." end
 local s=sessions[p]
 if not writable(s) or s.busy then return false,"Data sedang disimpan. Coba lagi sebentar." end
 local key=slot==1 and "AKSlot1" or "AKSlot2"
 local other=slot==1 and "AKSlot2" or "AKSlot1"
 local equip=kind=="AK47"
 if s.data[key]==equip then return true end
 if equip and s.data.AKOwned<(s.data[other] and 2 or 1) then
  return false,"AK-47 di inventaris belum cukup."
 end
 s.busy=true
 s.settingWeapons=true
 local d=snapshot(s.data)
 d[key]=equip
 local ok=write(p,s,d,false)
 if ok then
  s.data[key]=equip
  attributes(p,s.data)
 end
 s.busy=false
 s.settingWeapons=nil
 return ok,not ok and "Pengaturan gagal disimpan. Coba lagi." or nil
end
function Manager.IsWeaponLoadoutSaving(p)
 local s=sessions[p]
 return s and s.settingWeapons==true
end
function Manager.SetPlayerLabels(p,show)
 local s=sessions[p]
 if not writable(s) or type(show)~="boolean" or s.data.ShowPlayerLabels==show then return end
 s.data.ShowPlayerLabels=show
 p:SetAttribute("ShowPlayerLabels",show)
 if s.labelSaveQueued then return end
 -- Fixed window coalesces rapid changes without allowing continuous input to postpone forever.
 s.labelSaveQueued=true
 task.delay(5,function()
  if sessions[p]~=s then return end
  s.labelSaveQueued=nil
  if writable(s) and s.savedLabels~=s.data.ShowPlayerLabels then Manager.Save(p,false) end
 end)
end
function Manager.HasSession(p)
 return writable(sessions[p])
end
function Manager.GrantCoins(p,amount,reason)
 local s=sessions[p]
 if not writable(s) or type(amount)~="number" or amount~=amount or amount<=0 then return false end
 local add=math.floor(amount)
 if add<=0 then return false end
 s.data.SkyCoins=math.clamp(s.data.SkyCoins+add,0,1e9)
 attributes(p,s.data)
 local toast=remotes:FindFirstChild("CoinToastEvent")
 if toast and toast:IsA("RemoteEvent") then toast:FireClient(p,add,reason or "") end
 if not s.coinSaveQueued then
  s.coinSaveQueued=true
  task.delay(4,function()
   if sessions[p]~=s then return end
   s.coinSaveQueued=nil
   if writable(s) then Manager.Save(p,false) end
  end)
 end
 return true
end
function Manager.GetActiveCosmetic(p,category)
 local s=sessions[p]
 if not writable(s) or type(category)~="string" then return "none" end
 if pruneExpiredTemp(s.data) then attributes(p,s.data) end
 return s.data.EquippedCosmetics[category] or "none"
end
local function buildDailyPayload(s,now)
 local t=now or os.time()
 pruneExpiredTemp(s.data,t)
 local today=Catalog.GetUTC7Day(t)
 return {
  progress=s.data.DailyProgress,
  claimedToday=s.data.LastDailyClaimDay>=today,
  lastClaimDay=s.data.LastDailyClaimDay,
  dayWib=today,
  remainingSeconds=Catalog.SecondsUntilNextUTC7Day(t),
  skyCoins=s.data.SkyCoins,
  speedBoostStock=s.data.SpeedBoostStock,
  ropeBuffStock=s.data.RopeBuffStock,
  ownedCosmetics=table.clone(s.data.OwnedCosmetics),
  tempCosmetics=table.clone(s.data.TempCosmetics),
  equipped=table.clone(s.data.EquippedCosmetics),
 }
end
function Manager.GetDailyState(p)
 local s=sessions[p]
 if not writable(s) then return nil end
 local payload=buildDailyPayload(s)
 attributes(p,s.data)
 return payload
end
function Manager.ClaimDailyLogin(p)
 local s=sessions[p]
 if not writable(s) then return false,"Data belum siap." end
 while s.busy do task.wait(0.05) end
 if sessions[p]~=s or not writable(s) then return false,"Sesi data berakhir." end
 local now=os.time()
 local today=Catalog.GetUTC7Day(now)
 if s.data.LastDailyClaimDay>=today then
  attributes(p,s.data)
  return false,"Hadiah hari ini sudah diklaim!",nil,buildDailyPayload(s,now)
 end
 local step=s.data.DailyProgress
 local reward=Catalog.DAILY_REWARDS[step]
 if not reward then return false,"Reward harian tidak valid." end
 s.busy=true
 local beforeCoins=s.data.SkyCoins
 local d=snapshot(s.data)
 pruneExpiredTemp(d,now)
 local grantedDuplicate=false
 local bonusCoins=0
 d.SkyCoins=math.clamp(d.SkyCoins+(reward.coins or 0),0,1e9)
 d.SpeedBoostStock=math.clamp(d.SpeedBoostStock+(reward.turboGas or 0),0,1e9)
 d.RopeBuffStock=math.clamp(d.RopeBuffStock+(reward.ropeBuff or 0),0,1e9)
 d.EmergencyKits=math.clamp(d.EmergencyKits+(reward.kits or 0),0,1e9)
 if reward.tempCosmetic then
  local tc=reward.tempCosmetic
  local key=Catalog.CosmeticKey(tc.category,tc.id)
  if d.OwnedCosmetics[key]~=true then
   local baseExp=math.max(now,d.TempCosmetics[key] or 0)
   d.TempCosmetics[key]=baseExp+tc.days*86400
  end
  if d.EquippedCosmetics[tc.category]=="none" then d.EquippedCosmetics[tc.category]=tc.id end
 end
 if reward.permCosmetic then
  local pc=reward.permCosmetic
  local key=Catalog.CosmeticKey(pc.category,pc.id)
  if d.OwnedCosmetics[key]==true then
   grantedDuplicate=true
   bonusCoins=reward.duplicateCoins or Catalog.COINS.DAY7_DUPLICATE_BONUS
   d.SkyCoins=math.clamp(d.SkyCoins+bonusCoins,0,1e9)
  else
   d.OwnedCosmetics[key]=true
   d.TempCosmetics[key]=nil
   if d.EquippedCosmetics[pc.category]=="none" then d.EquippedCosmetics[pc.category]=pc.id end
  end
 end
 d.LastDailyClaimDay=today
 d.DailyProgress=(step%7)+1
 local ok=write(p,s,d,false)
 if ok then
  local externalDelta=s.data.SkyCoins-beforeCoins
  if externalDelta>0 then d.SkyCoins=math.clamp(d.SkyCoins+externalDelta,0,1e9) end
  s.data.SkyCoins=d.SkyCoins
  s.data.SpeedBoostStock=d.SpeedBoostStock
  s.data.RopeBuffStock=d.RopeBuffStock
  s.data.EmergencyKits=d.EmergencyKits
  s.data.OwnedCosmetics=d.OwnedCosmetics
  s.data.TempCosmetics=d.TempCosmetics
  s.data.EquippedCosmetics=d.EquippedCosmetics
  s.data.LastDailyClaimDay=d.LastDailyClaimDay
  s.data.DailyProgress=d.DailyProgress
  attributes(p,s.data)
 end
 s.busy=false
 if not ok then return false,"Gagal menyimpan klaim. Coba sebentar lagi." end
 local summary=reward.summary or string.format("Hadiah Hari ke-%d diklaim!",step)
 if grantedDuplicate then
  summary=string.format("%s (+%d Koin duplikat kosmetik!)",summary,bonusCoins)
 end
 return true,summary,{day=step,coins=(reward.coins or 0)+bonusCoins,duplicateBonus=grantedDuplicate},buildDailyPayload(s,now)
end
function Manager.BuySupply(p,itemId)
 local s=sessions[p]
 if not writable(s) then return false,"Data belum siap." end
 local item=Catalog.SUPPLIES_BY_ID[itemId]
 if not item then return false,"Item perbekalan tidak valid." end
 while s.busy do task.wait(0.05) end
 if sessions[p]~=s or not writable(s) then return false,"Sesi data berakhir." end
 if s.data.SkyCoins<item.price then
  return false,string.format("Sky Coins kurang (%d / %d Koin).",s.data.SkyCoins,item.price)
 end
 s.busy=true
 local beforeCoins=s.data.SkyCoins
 local d=snapshot(s.data)
 d.SkyCoins-=item.price
 local stockField=item.id=="turbo_gas" and "SpeedBoostStock" or "RopeBuffStock"
 d[stockField]=math.clamp(d[stockField]+1,0,1e9)
 local ok=write(p,s,d,false)
 if ok then
  local externalDelta=s.data.SkyCoins-beforeCoins
  if externalDelta>0 then d.SkyCoins=math.clamp(d.SkyCoins+externalDelta,0,1e9) end
  s.data.SkyCoins=d.SkyCoins
  s.data[stockField]=d[stockField]
  attributes(p,s.data)
 end
 s.busy=false
 if not ok then return false,"Pembelian gagal disimpan. Coba lagi." end
 return true,string.format("1× %s ditambahkan ke perbekalan! (Stok: %d)",item.name,s.data[stockField])
end
function Manager.ConsumeSupply(p,itemId)
 local s=sessions[p]
 if not writable(s) or s.busy then return false end
 local stockField=itemId=="turbo_gas" and "SpeedBoostStock" or (itemId=="tali_awet" and "RopeBuffStock" or nil)
 if not stockField or s.data[stockField]<1 then return false end
 s.data[stockField]-=1
 attributes(p,s.data)
 task.spawn(Manager.Save,p,false)
 return true
end
function Manager.CosmeticAction(p,action,category,itemId)
 local s=sessions[p]
 if not writable(s) then return false,"Data belum siap." end
 if action~="Buy" and action~="Equip" and action~="Unequip" then return false,"Aksi kosmetik tidak valid." end
 if category~="frame" and category~="tracer" and category~="title" then return false,"Kategori kosmetik tidak valid." end
 if action=="Unequip" then
  while s.busy do task.wait(0.05) end
  if sessions[p]~=s or not writable(s) then return false,"Sesi data berakhir." end
  if s.data.EquippedCosmetics[category]=="none" then return true,"Kosmetik sudah dilepas." end
  s.busy=true
  local beforeCoins=s.data.SkyCoins
  local d=snapshot(s.data)
  d.EquippedCosmetics[category]="none"
  local ok=write(p,s,d,false)
  if ok then
   local externalDelta=s.data.SkyCoins-beforeCoins
   if externalDelta>0 then d.SkyCoins=math.clamp(d.SkyCoins+externalDelta,0,1e9) end
   s.data.SkyCoins=d.SkyCoins
   s.data.EquippedCosmetics=d.EquippedCosmetics
   attributes(p,s.data)
  end
  s.busy=false
  return ok,ok and "Kosmetik dilepas." or "Gagal melepas kosmetik."
 end
 local item=type(itemId)=="string" and Catalog.GetCosmetic(category,itemId) or nil
 if not item then return false,"Kosmetik tidak ditemukan." end
 while s.busy do task.wait(0.05) end
 if sessions[p]~=s or not writable(s) then return false,"Sesi data berakhir." end
 local now=os.time()
 local key=item.key
 local beforeCoins=s.data.SkyCoins
 local d=snapshot(s.data)
 pruneExpiredTemp(d,now)
 if action=="Buy" then
  if d.OwnedCosmetics[key]==true then return false,"Kamu sudah memiliki kosmetik ini secara permanen." end
  if d.SkyCoins<item.price then return false,string.format("Sky Coins kurang (%d / %d Koin).",d.SkyCoins,item.price) end
  d.SkyCoins-=item.price
  d.OwnedCosmetics[key]=true
  d.TempCosmetics[key]=nil
  d.EquippedCosmetics[category]=item.id
 else
  local hasPerm=d.OwnedCosmetics[key]==true
  local hasTemp=d.TempCosmetics[key]~=nil and d.TempCosmetics[key]>now
  if not hasPerm and not hasTemp then return false,"Kamu belum memiliki kosmetik ini." end
  d.EquippedCosmetics[category]=item.id
 end
 s.busy=true
 local ok=write(p,s,d,false)
 if ok then
  local externalDelta=s.data.SkyCoins-beforeCoins
  if externalDelta>0 then d.SkyCoins=math.clamp(d.SkyCoins+externalDelta,0,1e9) end
  s.data.SkyCoins=d.SkyCoins
  s.data.OwnedCosmetics=d.OwnedCosmetics
  s.data.TempCosmetics=d.TempCosmetics
  s.data.EquippedCosmetics=d.EquippedCosmetics
  attributes(p,s.data)
 end
 s.busy=false
 if not ok then return false,"Gagal menyimpan perubahan kosmetik." end
 return true,action=="Buy" and (item.name.." dibeli & dipasang!") or (item.name.." dipasang!")
end
function Manager.GrantReceipt(p,id,item)
 local s=sessions[p]
 if not writable(s) then return false end
 while s.busy do task.wait(0.05) end
 if sessions[p]~=s or not writable(s) then return false end
 if s.data.Receipts[id] then return true,false end
 s.busy=true
 local beforeCoins=s.data.SkyCoins
 local d=snapshot(s.data)
 d.Receipts[id]=item
 if item=="EmergencyKit" then d.EmergencyKits+=1 elseif item=="AK47Upgrade" then d.AKOwned+=1 else s.busy=false return false end
 local ok=write(p,s,d,false)
 if ok then
  -- Preserve altitude/summit/coin updates that happened while UpdateAsync yielded.
  local externalDelta=s.data.SkyCoins-beforeCoins
  if externalDelta>0 then d.SkyCoins=math.clamp(d.SkyCoins+externalDelta,0,1e9) end
  s.data.SkyCoins=d.SkyCoins s.data.Receipts=d.Receipts s.data.EmergencyKits=d.EmergencyKits s.data.AKOwned=d.AKOwned
  attributes(p,s.data)
 end
 s.busy=false return ok,ok
end
Players.PlayerAdded:Connect(added)
for _,p in ipairs(Players:GetPlayers()) do task.spawn(added,p) end
Players.PlayerRemoving:Connect(function(p)
 local s=sessions[p]
 if (s and s.lost) or Manager.Save(p,true) then sessions[p]=nil end
end)
task.spawn(function()
 while true do
  task.wait(60)
  for p,s in pairs(sessions) do
   task.spawn(function()
    if p.Parent~=Players and s.lost then sessions[p]=nil return end
    if Manager.Save(p,p.Parent~=Players) and p.Parent~=Players then sessions[p]=nil end
   end)
  end
 end
end)
game:BindToClose(function()
 local remaining=0
 for p in pairs(sessions) do
  remaining+=1 task.spawn(function() Manager.Save(p,true) remaining-=1 end)
 end
 local deadline=os.clock()+25
 while remaining>0 and os.clock()<deadline do task.wait(0.1) end
end)
if offline then print("[DataManager] Unpublished Studio: isolated mock data; checkout disabled.") end
