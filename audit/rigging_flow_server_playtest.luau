local STS=game:GetService("StudioTestService")
if STS:GetTestArgs()~="FlyHighRiggingQA"then return end
assert(game.GameId==0)
local Players=game.Players local RS=game.ReplicatedStorage local Http=game:GetService("HttpService")
local qa=RS.FlyHigh.Remotes.MultiplayerQAEvent local report={checks={},motion={},players={},logs={}}
game:GetService("LogService").MessageOut:Connect(function(m,k)if k==Enum.MessageType.MessageError or k==Enum.MessageType.MessageWarning then table.insert(report.logs,{message=m,kind=k.Name})end end)
local replies={}local id=0
qa.OnServerEvent:Connect(function(p,kind,key,ok,value)local q=replies[key]if kind=="reply"and q and q.p==p then q.done=true q.ok=ok q.value=value end end)
local function waitFor(fn,t)local stop=os.clock()+t repeat local v=fn()if v then return v end task.wait(.05)until os.clock()>stop end
local function request(p,action,data)id+=1 local key=tostring(id)replies[key]={p=p}qa:FireClient(p,key,action,data or {})return key end
local function collect(key,t)local q=replies[key]assert(waitFor(function()return q.done end,t or 30),"client timeout")replies[key]=nil assert(q.ok,tostring(q.value))return q.value end
local function rpc(p,action,data,t)return collect(request(p,action,data),t)end
local function check(name,ok,detail)table.insert(report.checks,{name=name,passed=ok==true,detail=detail})assert(ok,name..": "..tostring(detail))end
local bm,tm,U,C,roster
local function position(p,cf)U.Unseat(p)p.Character:PivotTo(cf)p.Character.HumanoidRootPart.AssemblyLinearVelocity=Vector3.zero p.Character.HumanoidRootPart:SetNetworkOwnershipAuto()end
local function station(f,p)position(p,f.balloon.TetherStation.CFrame*CFrame.new(2,3,0))task.wait(.3)end
local function move(f,pos)
 f.balloon:PivotTo(CFrame.new(pos))f.targetPosition=pos f.alignPos.Position=pos f.root.AssemblyLinearVelocity=Vector3.zero f.boardingUntil=os.clock()+8
 for i,p in f.players do position(p,CFrame.new(pos+Vector3.new((i-1)*5,4,0)))end task.wait(.5)
end
local function clear()
 for _,f in table.clone(bm.activeFlights)do f.balloon:Destroy()end
 for i,p in roster do
  if p.Character.Humanoid.Health<=0 then p:LoadCharacterAsync()end
  position(p,CFrame.new((i-2)*5,16,35))
 end task.wait(.4)
end
local started=os.clock()
local ok,err=xpcall(function()
 check("three native clients",waitFor(function()return #Players:GetPlayers()==3 end,90)~=nil)
 roster=Players:GetPlayers()table.sort(roster,function(a,b)return a.Name<b.Name end)
 for _,p in roster do check(p.Name.." ready",waitFor(function()return p:GetAttribute("DataReady")and p.Character and p.Character:FindFirstChild("HumanoidRootPart")end,60)~=nil)table.insert(report.players,rpc(p,"Ping"))end
 bm=_G.FlyHighBalloonManager tm=_G.FlyHighTetherManager U=require(game.ServerScriptService.FlyHighServer.ServerUtils)C=require(RS.FlyHigh.Modules.FlyHighConfig)
 _G.FlyHighObstacleManager.Paused=true _G.FlyHighLargeChallengeManager.Paused=true
 local a,b,c=roster[1],roster[2],roster[3]
 local f=assert(bm.LaunchBalloon({a},a,workspace.FlyHighLobby.MatchmakingPods.Pod_C.FloorPad.Position,"Pod_C"))move(f,Vector3.new(-40,512.5,-56))
 station(f,a)rpc(a,"Prompt",{path="TetherStation.TetherPrompt"})task.wait(.2)
 local t=tm.activeTethers[a.UserId]
 check("native interaction attaches rope",t~=nil)
 check("rope does not join physics mechanisms",t.rope:IsA("Beam")and t.hrp:GetNetworkOwner()==a)
 check("balloon remains server owned",f.root:GetNetworkOwner()==nil)
 check("full rope cannot be repaired while worn",not tm.BeginRopeRepair(a))
 local slot=t.slot t.durability=74 slot.value.Value=74
 rpc(a,"Tether",{action="Attach"})task.wait(.4)
 check("attach does not refill worn rope",t.durability==74)
 rpc(a,"Tether",{action="Detach"})task.wait(.4)
 check("manual detach before climbing",not tm.activeTethers[a.UserId]and slot.value.Value==74)
 rpc(a,"Tether",{action="Attach"})task.wait(.4)
 check("reattach preserves slot durability",tm.activeTethers[a.UserId].durability==74)
 rpc(a,"Tether",{action="Detach"})task.wait(.4)
 check("premature repair finish rejected",not tm.FinishRopeRepair(a))
 rpc(a,"Prompt",{path="TetherStation.RepairRopePrompt"},12)task.wait(.2)
 check("unworn rope repairs through native hold",slot.value.Value==100 and not tm.ropeRepairs[a])
 f.autoGas=true f.balloon:SetAttribute("AutoGas",true)f.windUntil=os.clock()+9 f.wind=Vector3.new(6,0,0)
 rpc(a,"Tether",{action="Attach"})task.wait(.4)t=tm.activeTethers[a.UserId]
 local begin=f.root.Position local relative=f.root.CFrame:PointToObjectSpace(t.hrp.Position)local maxDrift=0
 for i=1,12 do task.wait(.5)local q=f.root.CFrame:PointToObjectSpace(t.hrp.Position)maxDrift=math.max(maxDrift,(q-relative).Magnitude)table.insert(report.motion,{time=i*.5,relative=tostring(q),owner=t.hrp:GetNetworkOwner()and t.hrp:GetNetworkOwner().Name})end
 check("attached crew follows ascent and lateral motion",f.root.Position.Y-begin.Y>20 and maxDrift<2,{rise=f.root.Position.Y-begin.Y,maxRelativeDrift=maxDrift})
 f.windUntil=0
 for i=1,4 do f.invulnTime=0 assert(bm.ApplyPuncture(f,"SelfShot"))end
 rpc(a,"Prompt",{path="TetherStation.ClimbPrompt"})
 check("climb follows moving balloon",waitFor(function()local x=tm.activeTethers[a.UserId]return x and not x.winch and x.stage=="Catwalk"end,4)~=nil)
 check("avatar ownership restored after winch",a.Character.HumanoidRootPart:GetNetworkOwner()==a and not a.Character.HumanoidRootPart.Anchored)
 for i=1,4 do
  if i>1 then rpc(a,"WalkRing",{from=(i-2)*math.pi*2/5,to=(i-1)*math.pi*2/5},10)end
  local response=rpc(a,"Prompt",{path="HoleSlots.Hole"..i..".PatchPrompt"})task.wait(.1)
  local tether=tm.activeTethers[a.UserId]
  check("hole "..i.." repaired through interaction",not f.holeSet[i],{remaining=f.holes,prompt=response,stage=tether and tether.stage,relative=tostring(f.root.CFrame:PointToObjectSpace(a.Character.HumanoidRootPart.Position))})
 end
 check("all four holes repaired on moving catwalk",f.holes==0 and a.Character.Humanoid.Health>0)
 rpc(a,"Prompt",{path="EnvelopeWalkway.DescendPrompt"})
 check("descent automatically releases rope",waitFor(function()return not tm.activeTethers[a.UserId]end,4)~=nil)
 check("descent leaves living mobile crew in basket",U.InBasket(a.Character.HumanoidRootPart,f.balloon.BasketFloor)and not a.Character.HumanoidRootPart.Anchored and a.Character.Humanoid.Health>0)
 check("rope wear persists after automatic release",slot.value.Value<95 and slot.value.Value>0,slot.value.Value)
 station(f,a)
 check("repair begins only at station while unworn",tm.BeginRopeRepair(a)==true)
 check("early finish cannot refill",not tm.FinishRopeRepair(a)and slot.value.Value<100)
 position(a,f.balloon.PrimaryPart.CFrame*CFrame.new(10,4,-8))task.wait(.3)
 check("walking away cancels rope repair",tm.ropeRepairs[a]==nil and slot.repair==nil)
 position(c,f.balloon.TetherStation.CFrame*CFrame.new(-2,3,0))task.wait(.2)
 check("noncrew repair denied",not tm.BeginRopeRepair(c))
 clear()
 local trio=assert(bm.LaunchBalloon(roster,a,workspace.FlyHighLobby.MatchmakingPods.Pod_A.FloorPad.Position,"Pod_A"))move(trio,Vector3.new(0,512.5,-56))
 check("trio receives two persistent ropes",#tm.ropePools[trio.balloon].slots==2)
 station(trio,a)station(trio,b)station(trio,c)
 rpc(a,"Tether",{action="Attach"})rpc(b,"Tether",{action="Attach"})task.wait(.4)
 check("two crew can wear separate ropes",tm.activeTethers[a.UserId]~=nil and tm.activeTethers[b.UserId]~=nil)
 rpc(c,"Tether",{action="Attach"})task.wait(.4)
 check("third crew cannot overbook ropes",tm.activeTethers[c.UserId]==nil)
 local pool=tm.ropePools[trio.balloon]local first=tm.activeTethers[a.UserId]
 first.durability=40 rpc(a,"Tether",{action="Detach"})task.wait(.4)
 check("repair reserves a free worn slot",tm.BeginRopeRepair(c)==true)
 rpc(a,"Tether",{action="Attach"})task.wait(.4)
 check("reserved rope cannot be attached by another crew",tm.activeTethers[a.UserId]==nil)
 tm.CancelRopeRepair(c)
 rpc(a,"Tether",{action="Attach"})task.wait(.4)
 check("cancelled repair releases slot without refilling",tm.activeTethers[a.UserId]and tm.activeTethers[a.UserId].durability==40)
 rpc(a,"Tether",{action="Climb"})task.wait(.3)rpc(a,"Tether",{action="Detach"})task.wait(.4)
 check("winch cancellation restores anchor state",not a.Character.HumanoidRootPart.Anchored and not tm.activeTethers[a.UserId])
 trio.balloon:Destroy()task.wait(.3)
 check("balloon cleanup removes ropes and pools",not tm.activeTethers[b.UserId]and tm.ropePools[trio.balloon]==nil)
end,debug.traceback)
local clientLogs=0
for i,p in ipairs(roster or {})do local good,s=pcall(rpc,p,"Snapshot")if good then report.players[i].logs=s.logs clientLogs+=#s.logs end end
report.clientLogCount=clientLogs report.ok=ok and #report.logs==0 and clientLogs==0 report.error=not ok and err or nil report.duration=os.clock()-started
STS:EndTest(Http:JSONEncode(report))
