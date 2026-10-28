local STS=game:GetService("StudioTestService")
if STS:GetTestArgs()~="FlyHighStormQA"then return end
assert(game.GameId==0,"Cloud testing is deferred; run a local unpublished file")
local Players=game.Players local RS=game.ReplicatedStorage local Http=game:GetService("HttpService")
local qa=RS.FlyHigh.Remotes.StormQAEvent local result={checks={},balance={},waves={},players={},logs={}}
game:GetService("LogService").MessageOut:Connect(function(m,k)if k==Enum.MessageType.MessageError or k==Enum.MessageType.MessageWarning then table.insert(result.logs,{message=m,kind=k.Name})end end)
local replies={}local id=0
qa.OnServerEvent:Connect(function(p,key,ok,value)local q=replies[key]if q and q.p==p then q.done=true q.ok=ok q.value=value end end)
local function waitFor(fn,t)local untilT=os.clock()+t repeat local v=fn()if v then return v end task.wait(.1)until os.clock()>untilT end
local function request(p,action,data)id+=1 local key=tostring(id)replies[key]={p=p}qa:FireClient(p,key,action,data or {})return key end
local function collect(key,t)local q=replies[key]assert(waitFor(function()return q.done end,t or 25),"client timeout "..q.p.Name)replies[key]=nil assert(q.ok,tostring(q.value))return q.value end
local function rpc(p,a,d,t)return collect(request(p,a,d),t)end
local function check(name,ok,detail)table.insert(result.checks,{name=name,passed=ok==true,detail=detail})assert(ok,name..": "..tostring(detail))end
local function phase(s)print("[StormJumpQA] "..s)end
local bm,jm,lm,tm,wm,U,C,roster
local function hum(p)return p.Character and p.Character:FindFirstChildOfClass("Humanoid")end
local function position(p,cf)U.Unseat(p)local root=p.Character.HumanoidRootPart root.Anchored=false p.Character:PivotTo(cf)root.AssemblyLinearVelocity=Vector3.zero root:SetNetworkOwnershipAuto()end
local function clear()
 for _,wave in ipairs(table.clone(lm.active))do lm.Clear(wave)end
 for _,f in ipairs(table.clone(bm.activeFlights))do f.balloon:Destroy()end
 for i,p in ipairs(roster)do
  if not hum(p)or hum(p).Health<=0 then p:LoadCharacterAsync()end
  assert(waitFor(function()return hum(p)and hum(p).Health>0 and p.Character:FindFirstChild("HumanoidRootPart")end,12))
  position(p,CFrame.new((i-2)*5,16,35))
 end task.wait(.5)
end
local function move(f,pos)
 f.balloon:PivotTo(CFrame.new(pos))f.targetPosition=pos f.alignPos.Position=pos f.root.AssemblyLinearVelocity=Vector3.zero
 f.altitudeKm=(pos.Y-C.GROUND_Y)/C.STUDS_PER_KM f.boardingUntil=os.clock()+8 f.jumpDropRemaining=0
 for i,p in ipairs(f.players)do position(p,CFrame.new(pos+Vector3.new((i-2)*5,4,0)))end
 task.wait(.7)
end
local function launch(n)
 local crew={}for i=1,n do table.insert(crew,roster[i])end
 local f=assert(bm.LaunchBalloon(crew,crew[1],workspace.FlyHighLobby.MatchmakingPods.Pod_C.FloorPad.Position,"Pod_C"))
 move(f,Vector3.new(0,C.GROUND_Y+2000*C.STUDS_PER_KM,-56))return f,crew
end
local function group(crew,hops)
 local keys={}for _,p in ipairs(crew)do table.insert(keys,request(p,"Jump",{hops=hops}))end
 for _,key in ipairs(keys)do collect(key,20)end
end
local started=os.clock()
local ok,err=xpcall(function()
 phase("Three clients and solo/duo/trio jump balance")
 check("three clients join",waitFor(function()return #Players:GetPlayers()==3 end,90)~=nil)
 roster=Players:GetPlayers()table.sort(roster,function(a,b)return a.Name<b.Name end)
 for _,p in ipairs(roster)do
  check(p.Name.." ready",waitFor(function()return p:GetAttribute("DataReady")and hum(p)and p.Character:FindFirstChild("HumanoidRootPart")end,60)~=nil)
  table.insert(result.players,rpc(p,"Ping"))
 end
 bm=_G.FlyHighBalloonManager jm=_G.FlyHighJumpManager lm=_G.FlyHighLargeChallengeManager tm=_G.FlyHighTetherManager wm=_G.FlyHighWeaponManager
 U=require(game.ServerScriptService.FlyHighServer.ServerUtils)C=require(RS.FlyHigh.Modules.FlyHighConfig)
 _G.FlyHighObstacleManager.Paused=true lm.Paused=true
 for n=1,3 do
  clear()local f,crew=launch(n)local before=f.root.Position.Y
  check(n.." crew are allowed to jump",jm.EligibleCount(f)==n)
  group(crew,1)task.wait(.3)
  result.balance[n]={crew=n,accepted=f.jumpCount or 0,totalDrop=f.jumpDropTotal or 0,actualDescent=before-f.root.Position.Y}
  check(n.." crew actual jumps counted",f.jumpCount==n,result.balance[n])
  check(n.." crew share same total impulse",math.abs((f.jumpDropTotal or 0)-C.JUMP_DROP_STUDS)<.01,result.balance[n])
  check(n.." crew descend",before-f.root.Position.Y>=16,result.balance[n])
  local count=f.jumpCount rpc(crew[1],"Spam")task.wait(.65)
  check(n.." crew remote spam adds no drop",f.jumpCount==count)
  if n==1 then rpc(roster[2],"Spam")task.wait(.3)check("non-crew cannot cause jump drop",f.jumpCount==count)end
 end
 local f=bm.activeFlights[1]local a,b,c=roster[1],roster[2],roster[3]
 phase("Pilot, weapon, tether and catwalk jump restrictions")
 position(a,f.balloon.HelmSeat.CFrame*CFrame.new(2,3,1))f.balloon.HelmSeat:Sit(hum(a))task.wait(.4)
 local snap=rpc(a,"Snapshot")check("pilot jump disabled on client and server",snap.allowed==false and snap.jumpEnabled==false and not hum(a):GetStateEnabled(Enum.HumanoidStateType.Jumping))
 local count=f.jumpCount rpc(a,"Jump")rpc(a,"Spam")task.wait(.2)
 check("space does not eject pilot or create drop",hum(a).SeatPart==f.balloon.HelmSeat and f.jumpCount==count)
 rpc(a,"Action",{action="ReleaseHelm"})task.wait(.8)
 check("leaving helm restores jump",a:GetAttribute("FlightJumpAllowed")==true and hum(a).JumpPower>0)
 position(b,f.balloon.WeaponRack1.CFrame*CFrame.new(3,2,0))task.wait(.3)rpc(b,"Pickup")
 check("gunner equipped",waitFor(function()return wm.held[b]end,4)~=nil)
 position(c,f.balloon.TetherStation.CFrame*CFrame.new(0,2,-2))task.wait(.3)rpc(c,"Tether",{action="Attach"})task.wait(.3)
 check("tether attached on basket",tm.activeTethers[c.UserId]~=nil)
 local base=f.jumpCount local drop=f.jumpDropTotal group(roster,1)task.wait(.2)
 check("free gunner and tethered crew can all jump",f.jumpCount==base+3)
 check("equipment does not change crew balance",math.abs(f.jumpDropTotal-drop-C.JUMP_DROP_STUDS)<.01)
 position(c,f.balloon.TetherStation.CFrame*CFrame.new(0,2,-2))task.wait(.2)
 rpc(c,"Tether",{action="Climb"})task.wait(.25)
 check("winch blocks jumping",c:GetAttribute("FlightJumpAllowed")==false)
 task.wait(1.5)
 check("engineer outside basket cannot jump",c:GetAttribute("FlightJumpAllowed")==false)
 base=f.jumpCount rpc(c,"Jump")rpc(c,"Spam")check("engineer cannot create impulse",f.jumpCount==base)
 rpc(c,"Tether",{action="Descend"})task.wait(1.9)rpc(c,"Tether",{action="Detach"})rpc(b,"Drop")task.wait(.3)
 check("returning to gondola restores jump",c:GetAttribute("FlightJumpAllowed")==true and hum(c).JumpPower>0)
 phase("Storm cannot be spawned in safe zone")
 clear()local solo=assert(bm.LaunchBalloon({a},a,workspace.FlyHighLobby.MatchmakingPods.Pod_A.FloorPad.Position,"Pod_A"))
 check("storm rejected below 1200 km",lm.Spawn(1800,solo)==nil and #lm.active==0)
 phase("Global wall hits both edges if teams do not descend")
 clear()
 local left=assert(bm.LaunchBalloon({a,b},a,workspace.FlyHighLobby.MatchmakingPods.Pod_A.FloorPad.Position,"Pod_A"))
 move(left,Vector3.new(-110,C.GROUND_Y+1820*C.STUDS_PER_KM,110))
 local right=assert(bm.LaunchBalloon({c},c,workspace.FlyHighLobby.MatchmakingPods.Pod_E.FloorPad.Position,"Pod_E"))
 move(right,Vector3.new(110,left.root.Position.Y,110))
 local wave=assert(lm.Spawn(1800,left))
 check("one shared storm per zone",lm.Spawn(1800,right)==nil and #lm.active==1)
 check("wall is not shootable",wave.model:GetAttribute("Shootable")==false)
 task.wait(.3)local warning=rpc(c,"Snapshot")check("other team receives warning",warning.stormVisible,warning)
 task.wait(2)check("warning does not deal damage",left.holes==0 and right.holes==0)
 assert(waitFor(function()return not wave.model.Parent end,16),"wall expiry")
 check("wall hits left boundary team",left.holes==1,left.holes)
 check("wall hits right boundary team",right.holes==1,right.holes)
 check("global wave cleans up",#lm.active==0 and lm.byZone[1800]==nil)
 for n=1,3 do
  phase("Avoid storm by jumping: "..n.." crew")
  clear()local flight,crew=launch(n)
  move(flight,Vector3.new(0,C.GROUND_Y+1820*C.STUDS_PER_KM,-56))
  local w=assert(lm.Spawn(1800,flight))
  local before=flight.root.Position.Y
  group(crew,4)
  local lower=flight.root.Position.Y
  check(n.." crew can reach safe height",lower<=w.bottom-C.BALLOON_TOP_CLEARANCE,{rootY=lower,safeY=w.bottom-C.BALLOON_TOP_CLEARANCE})
  assert(waitFor(function()return not w.model.Parent end,14),"success wave expiry")
  result.waves[n]={crew=n,holes=flight.holes,drop=before-lower}
  check(n.." crew avoid curtain without damage",flight.holes==0,result.waves[n])
 end
 phase("Automatic altitude schedule and repeat prevention")
 clear()local auto,crew=launch(1)
 move(auto,Vector3.new(0,C.GROUND_Y+1820*C.STUDS_PER_KM,-56))
 _G.FlyHighObstacleManager.Paused=false lm.Paused=false
 check("scheduled wave spawns at threshold",waitFor(function()return #lm.active>0 end,2)~=nil)
 _G.FlyHighObstacleManager.Paused=true lm.Paused=true
 local active=lm.active[1]check("milestone marked once",auto.largeChallengeSeen[1800]==true)
 lm.Clear(active)
 _G.FlyHighObstacleManager.Paused=false lm.Paused=false task.wait(.6)
 check("same flight cannot retrigger cleared milestone",#lm.active==0)
 _G.FlyHighObstacleManager.Paused=true lm.Paused=true
 clear()
 for _,p in ipairs(roster)do local s=rpc(p,"Snapshot")check(p.Name.." jump restored in lobby",s.jumpEnabled==true and s.jumpVisible==false)end
end,debug.traceback)
for i,p in ipairs(roster or {})do local got,s=pcall(rpc,p,"Snapshot",{},5)if got then result.players[i].logs=s.logs end end
local clientLogs=0 for _,p in ipairs(result.players)do clientLogs+=#(p.logs or {})end
result.ok=ok and clientLogs==0 and #result.logs==0 result.error=not ok and err or ((clientLogs>0 or #result.logs>0)and "runtime logs captured"or nil)
result.clientLogCount=clientLogs result.duration=os.clock()-started
STS:EndTest(Http:JSONEncode(result))
