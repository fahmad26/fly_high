local Players=game:GetService("Players")
local DS=game:GetService("DataStoreService")
local RunService=game:GetService("RunService")
local Http=game:GetService("HttpService")
local U=require(script.Parent.ServerUtils)
local offline=RunService:IsStudio() and game.GameId==0
local store=not offline and DS:GetDataStore("FlyHigh_PlayerData_v1") or nil
local token=game.JobId~="" and game.JobId or Http:GenerateGUID(false)
local sessions={}
local Manager={}
_G.FlyHighDataManager=Manager
local function number(v)
 return type(v)=="number" and v==v and math.clamp(math.floor(v),0,1e9) or 0
end
local function clean(d)
 d=type(d)=="table" and d or {}
 local owned=number(d.AKOwned==nil and d.AKCredits or d.AKOwned)
 local slot1=owned>=1 and d.AKSlot1==true
 local slot2=owned>=(slot1 and 2 or 1) and d.AKSlot2==true
 return {MaxAltitude=math.min(10000,number(d.MaxAltitude)),SummitCount=number(d.SummitCount),
  EmergencyKits=number(d.EmergencyKits),AKOwned=owned,AKSlot1=slot1,AKSlot2=slot2,ShowPlayerLabels=d.ShowPlayerLabels~=false,
  Receipts=type(d.Receipts)=="table" and d.Receipts or {},Session=d.Session}
end
local function snapshot(d)
 local copy=table.clone(d) copy.Receipts=table.clone(d.Receipts)
 return copy
end
local function attributes(p,d)
 for _,key in ipairs({"MaxAltitude","SummitCount","EmergencyKits","AKOwned","AKSlot1","AKSlot2","ShowPlayerLabels"}) do p:SetAttribute(key,d[key]) end
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
function Manager.GrantReceipt(p,id,item)
 local s=sessions[p]
 if not writable(s) then return false end
 while s.busy do task.wait(0.05) end
 if sessions[p]~=s or not writable(s) then return false end
 if s.data.Receipts[id] then return true,false end
 s.busy=true
 local d=snapshot(s.data)
 d.Receipts[id]=item
 if item=="EmergencyKit" then d.EmergencyKits+=1 elseif item=="AK47Upgrade" then d.AKOwned+=1 else s.busy=false return false end
 local ok=write(p,s,d,false)
 if ok then
  -- Preserve altitude/summit updates that happened while UpdateAsync yielded.
  s.data.Receipts=d.Receipts s.data.EmergencyKits=d.EmergencyKits s.data.AKOwned=d.AKOwned
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
