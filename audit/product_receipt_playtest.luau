-- Runtime-only QA. Never ship fixtures or replace real ProcessReceipt in production.
local Http=game:GetService("HttpService")
local result=Instance.new("StringValue")result.Name="ProductQAResult"result.Parent=game.ServerStorage
local dm=require(game.ServerStorage.ProductDataQAAdapter)
local p=game.Players:GetPlayers()[1]or game.Players.PlayerAdded:Wait()
repeat task.wait(.05)until p:GetAttribute("DataReady")
local originalManager=_G.FlyHighDataManager
local old={CurrentPod=p:GetAttribute("CurrentPod"),IsMaster=p:GetAttribute("IsMaster"),BoughtAK47=p:GetAttribute("BoughtAK47")}
local checks={}
local function check(name,condition)assert(condition,name)table.insert(checks,name)end
local ok,err=xpcall(function()
 local fake={UserId=999,attributes={}}
 function fake:SetAttribute(name,value)self.attributes[name]=value end
 function fake:FindFirstChild()return nil end
 dm.QASeed(fake,{})
 local granted,fresh=dm.GrantReceipt(fake,"qa-kit","EmergencyKit")
 check("kit grants exactly one",granted and fresh and fake.attributes.EmergencyKits==1)
 granted,fresh=dm.GrantReceipt(fake,"qa-kit","EmergencyKit")
 check("duplicate kit is idempotent",granted and fresh==false and fake.attributes.EmergencyKits==1)
 granted,fresh=dm.GrantReceipt(fake,"qa-ak","AK47Upgrade")
 check("AK grants exactly one credit",granted and fresh and fake.attributes.AKCredits==1)
 granted,fresh=dm.GrantReceipt(fake,"qa-ak","AK47Upgrade")
 check("duplicate AK is idempotent",granted and fresh==false and fake.attributes.AKCredits==1)
 dm.QAWriteFails=true
 granted=dm.GrantReceipt(fake,"qa-failed","EmergencyKit")
 check("failed persistence grants nothing",not granted and fake.attributes.EmergencyKits==1)
 dm.QAWriteFails=false
 granted,fresh=dm.GrantReceipt(fake,"qa-failed","EmergencyKit")
 check("retry after save failure grants once",granted and fresh and fake.attributes.EmergencyKits==2)
 check("unknown item rejected",not dm.GrantReceipt(fake,"qa-unknown","Invalid"))
 local process=_G.FlyHighShopManager.ProcessReceipt
 local retry=Enum.ProductPurchaseDecision.NotProcessedYet
 local accepted=Enum.ProductPurchaseDecision.PurchaseGranted
 check("unpublished receipt stays pending",process({PlayerId=p.UserId,ProductId=3723339056,PurchaseId="qa-offline"})==retry)
 local ledger={}local calls={}local consumed=0
 _G.FlyHighDataManager={
  GrantReceipt=function(_,id,item)
   table.insert(calls,item)
   local fresh=not ledger[id]ledger[id]=true return true,fresh
  end,
  ConsumeAKCredit=function()consumed+=1 return true end
 }
 p:SetAttribute("CurrentPod","Pod_A")p:SetAttribute("IsMaster",true)p:SetAttribute("BoughtAK47",false)
 check("kit ID routes to EmergencyKit",process({PlayerId=p.UserId,ProductId=3723339056,PurchaseId="route-kit"})==accepted and calls[#calls]=="EmergencyKit")
 check("AK ID routes to AK47Upgrade",process({PlayerId=p.UserId,ProductId=3723339246,PurchaseId="route-ak"})==accepted and calls[#calls]=="AK47Upgrade"and consumed==1)
 p:SetAttribute("BoughtAK47",false)
 check("duplicate AK receipt cannot reactivate upgrade",process({PlayerId=p.UserId,ProductId=3723339246,PurchaseId="route-ak"})==accepted and consumed==1)
 check("unknown product stays pending",process({PlayerId=p.UserId,ProductId=123,PurchaseId="route-unknown"})==retry)
 check("missing player stays pending",process({PlayerId=-999999,ProductId=3723339056,PurchaseId="route-missing"})==retry)
 _G.FlyHighDataManager={GrantReceipt=function()return false end}
 check("receipt is pending when persistence fails",process({PlayerId=p.UserId,ProductId=3723339056,PurchaseId="route-failed"})==retry)
end,debug.traceback)
_G.FlyHighDataManager=originalManager
for _,key in ipairs({"CurrentPod","IsMaster","BoughtAK47"})do p:SetAttribute(key,old[key])end
result.Value=Http:JSONEncode({ok=ok,error=not ok and err or nil,checks=checks,count=#checks,mode="mock persistence and real receipt handler; no Robux transaction"})
