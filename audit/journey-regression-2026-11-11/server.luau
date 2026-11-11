local STS=game:GetService("StudioTestService")local testArgs=STS:GetTestArgs()
if testArgs~="FlyHighFullJourneyQA"and testArgs~="FlyHighDuoTrioQA"and testArgs~="FlyHighDuoTrioJourneyOnlyQA"then return end
local P=game.Players local RS=game.ReplicatedStorage local Http=game:GetService("HttpService")local Run=game:GetService("RunService")
local qa=RS.FlyHigh.Remotes.FullJourneyQAEvent
local report={checks={},logs={},journeys={},samples={},fixtures={continuousAltitude="normal production integration, no altitude skips or shields",roles="scripted positions inside lobby/basket; native remotes and production manager validations",fatalBranches="not included in continuous run; separate focused regression"}}
report.fixtures.steering="Virtual WASD keys through production FlightHUDController; pilot holds horizontal input during repair; auto gas remains on; hazards stay enabled"
local pending={}local serial=0 local began=os.clock()
report.startedUTC=DateTime.now():ToIsoDate()
task.delay(1500,function()report.timeout=true STS:EndTest(Http:JSONEncode(report))end)
game:GetService("LogService").MessageOut:Connect(function(m,k)if k==Enum.MessageType.MessageWarning or k==Enum.MessageType.MessageError then table.insert(report.logs,m)end end)
qa.OnServerEvent:Connect(function(p,id,ok,v)local t=pending[id]if t and t.player==p then t.done=true t.ok=ok t.value=v end end)
local function waitFor(fn,t)local stop=os.clock()+t repeat local v=fn()if v then return v end task.wait(.05)until os.clock()>stop end
local function check(name,value,detail)table.insert(report.checks,{name=name,passed=value==true,detail=detail})return value end
local function need(name,value,detail)check(name,value,detail)assert(value,name)end
local function rpc(p,action,data,timeout)
 serial+=1 local id=tostring(serial)local entry={player=p}pending[id]=entry qa:FireClient(p,id,action,data or {})
 assert(waitFor(function()return entry.done end,timeout or 20),"RPC timeout "..p.Name.." "..action)pending[id]=nil
 assert(entry.ok,tostring(entry.value))return entry.value
end
local bm,tm,wm,om,lm,U,C,dm
local function pose(p,cf)
 U.Unseat(p)local fd=U.Flight(p)local relative=fd and fd.root.CFrame:ToObjectSpace(cf)
 rpc(p,"Pose",{cf=cf,relative=relative,balloon=fd and fd.balloon})
 assert(waitFor(function()
  local actual=p.Character.HumanoidRootPart.Position
  return relative and(fd.root.CFrame:PointToObjectSpace(actual)-relative.Position).Magnitude<4 or not relative and(actual-cf.Position).Magnitude<4
 end,3),"client pose did not replicate")
end
local function station(fd,p)
 -- Approach from inside the basket, clear of the station model and outer railing.
 pose(p,fd.root.CFrame*CFrame.new(0,4,6))task.wait(.35)
end
local function attach(fd,p)
 local deadline=os.clock()+2
 repeat
  if tm.attachHandlers[fd.balloon](p)then return true end
  task.wait(.15)
 until os.clock()>deadline
 local root=p.Character.HumanoidRootPart local h=p.Character.Humanoid local slots={}
 for _,slot in tm.ropePools[fd.balloon].slots do table.insert(slots,{hp=slot.value.Value,holder=slot.holder and slot.holder.Name,repair=slot.repair~=nil})end
 error("rope attach denied: "..Http:JSONEncode({player=p.Name,role=U.Role(p),alive=U.Alive(p,fd),near=U.Near(p,fd.balloon.TetherStation,10),inside=U.InBasket(root,fd.balloon.BasketFloor),localPosition=tostring(fd.root.CFrame:PointToObjectSpace(root.Position)),anchored=root.Anchored,sit=h.Sit,slots=slots,km=fd.altitudeKm}))
end
local function equip(fd,p)
 rpc(p,"ShootBot",{enabled=false})wm.CleanupPlayer(p)
 pose(p,fd.balloon.WeaponRack1.CFrame*CFrame.new(3,2,0))task.wait(.1)
 assert(wm.TryEquip(p,fd.balloon,fd.balloon.WeaponRack1),"gun equip denied")rpc(p,"ShootBot",{enabled=true})
end
local function helm(fd,p,lane)
 wm.CleanupPlayer(p)pose(p,fd.balloon.HelmSeat.CFrame*CFrame.new(0,3,2))
 fd.balloon.HelmSeat:Sit(p.Character.Humanoid)
 assert(waitFor(function()return fd.pilot==p end,3),"helm acquisition failed")
 rpc(p,"Lane",{target=lane})rpc(p,"Action",{action="AutoGas",value=true})
 assert(waitFor(function()return fd.autoGas end,3),"auto gas denied")
end
local function launch(members,pod)
 local pad=workspace.FlyHighLobby.MatchmakingPods[pod].FloorPad
 for i,p in members do pose(p,pad.CFrame*CFrame.new((i-1)*3-3,4,4))task.wait(.3)end
 assert(waitFor(function()return members[1]:GetAttribute("CurrentPod")==pod and members[1]:GetAttribute("IsMaster")==true end,5),"dock membership failed")
 local space=require(game.ServerScriptService.FlyHighServer.FlightSpace)
 assert(waitFor(function()return not space.Blocker(space.SpawnPosition(pad.Position),bm.activeFlights)end,30),"dock remains occupied")
 rpc(members[1],"Start",{pod=pod})
 local fd=assert(waitFor(function()return U.Flight(members[1])end,8),"dock did not launch")
 assert(waitFor(function()return not fd.boarding end,20),"boarding not completed")return fd
end
local function restoreRope(fd,p,team)
 for attempt=1,3 do
  station(fd,p)rpc(p,"FollowStation",{enabled=true})
  local begun=tm.BeginRopeRepair(p)
  if not begun then rpc(p,"FollowStation",{enabled=false})return end
  local item=tm.ropeRepairs[p]task.wait(item.duration+.15)
  local finished=tm.FinishRopeRepair(p)
  rpc(p,"FollowStation",{enabled=false})
  if finished then return end
  table.insert(team.interruptions,{kind="rope",km=fd.altitudeKm,distance=(p.Character.HumanoidRootPart.Position-fd.balloon.TetherStation.Position).Magnitude,inside=U.InBasket(p.Character.HumanoidRootPart,fd.balloon.BasketFloor)})
 end
 error("rope restore interrupted three times")
end
local function repair(team)
 local fd=team.fd local p=team.engineer
 if wm.held[p]then rpc(p,"ShootBot",{enabled=false})wm.CleanupPlayer(p)end
 local t=tm.activeTethers[p.UserId]
 if t and t.needsRescue then
  local helper=team.members[1]if helper==p then error("solo engineer fell and needs a teammate")end
  if fd.pilot==helper then rpc(helper,"Action",{action="ReleaseHelm"})assert(waitFor(function()return not fd.pilot end,2))end
  wm.CleanupPlayer(helper)pose(helper,fd.root.CFrame*CFrame.new(0,4,8))
  assert(tm.PullCrew(helper),"rescue denied")assert(waitFor(function()return t.stage=="Basket"end,4))team.rescues+=1
  helm(fd,helper,team.lane)
 end
 if not t then
  station(fd,p)attach(fd,p)t=tm.activeTethers[p.UserId]
 end
 if t.stage=="Basket"then
  station(fd,p)rpc(p,"Tether",{action="Climb"})task.wait(.4)
  if t.stage=="Basket"then rpc(p,"Tether",{action="Climb"})end
 end
 local climbed=waitFor(function()return t.stage=="Catwalk"or t.stage=="Hanging"or not U.Alive(p,fd)or fd.isVictory end,6)
 if not climbed then error("climb timeout "..Http:JSONEncode({stage=t.stage,position=tostring(fd.root.CFrame:PointToObjectSpace(t.hrp.Position)),near=U.Near(p,fd.balloon.TetherStation,10),inside=U.InBasket(t.hrp,fd.balloon.BasketFloor),client=rpc(p,"PhysicalState")}))end
 if t.stage=="Hanging"then return end
 while U.Alive(p,fd)and not fd.isVictory and fd.holes>0 and fd.holes<5 and t.stage=="Catwalk"and t.durability>55 do
  local best local distance=math.huge
  for n in pairs(fd.holeSet)do local hole=fd.balloon.HoleSlots["Hole"..n]local d=(hole.Position-t.hrp.Position).Magnitude if d<distance then best=n distance=d end end
  if not best then break end
  -- Stand opposite the hole, rather than starting a hold at the edge of its radius.
  rpc(p,"WalkHole",{number=best},20)
  assert(t.stage=="Catwalk","engineer fell during walk")
  if t.durability<=23 then break end
  if not tm.BeginRepair(p,best)then error("patch begin denied "..Http:JSONEncode({stage=t.stage,distance=(t.hrp.Position-fd.balloon.HoleSlots["Hole"..best].Position).Magnitude,holes=fd.holes,client=rpc(p,"PhysicalState")}))end local duration=t.repair.duration
  task.wait(duration+.12)
  if not fd.isVictory then
   if tm.FinishRepair(p)then team.repairs+=1
   else
    table.insert(team.interruptions,{km=fd.altitudeKm,stage=t.stage,holes=fd.holes,durability=t.durability,distance=(t.hrp.Position-fd.balloon.HoleSlots["Hole"..best].Position).Magnitude})
    if t.stage~="Catwalk"then return end
    break -- A cancelled hold is a normal retry, not a fatal flight error.
   end
  end
 end
 if not U.Alive(p,fd)or fd.isVictory then rpc(p,"StopWalk")return end
 rpc(p,"StopWalk")
 assert(t.stage=="Catwalk","engineer not on deck")rpc(p,"Tether",{action="Descend"})
 assert(waitFor(function()return not tm.activeTethers[p.UserId]end,5),"descent did not finish")
 restoreRope(fd,p,team)
 if #team.members<3 then equip(fd,p)else station(fd,p)attach(fd,p)end
end
local teams={}
local control=Instance.new("BindableFunction")control.Name="FullJourneyControl"control.Parent=game.ServerStorage
control.OnInvoke=function(action)
 if action=="Status"then local out={elapsed=os.clock()-began,checks=#report.checks,logs=report.logs,crews={}}for _,t in teams do out.crews[t.name]={km=t.fd.altitudeKm,holes=t.fd.holes,repairs=t.repairs,done=t.done,error=t.error,pilot=t.fd.pilot and t.fd.pilot.Name}end return out end
 if action=="Abort"then game:GetService("StudioTestService"):EndTest(Http:JSONEncode(report))end
end

local function runJourney(team)
 local ok,err=xpcall(function()
  local fd=team.fd local nextRepair=0 local lastHazard=0
  while not fd.isVictory and not fd.isGameOver do
   if os.clock()-team.start>1150 then error("continuous journey exceeded 1150 seconds")end
   for _,p in team.members do assert(U.Alive(p,fd),p.Name.." died during the continuous journey")end
   if #team.members>1 and fd.pilot==team.members[1]and(fd.hazardUntil or 0)>os.clock()and fd.hazardUntil~=lastHazard then
    lastHazard=fd.hazardUntil team.lane=Vector3.new(team.lane.X,0,fd.root.Position.Z<0 and 85 or -85)
    rpc(team.members[1],"Lane",{target=team.lane})team.dodges+=1
   end
   if fd.holes>0 and os.clock()>=nextRepair then
    nextRepair=os.clock()+1
    if fd.holes==5 then error("five holes reached during full journey")end
    -- Coordinate the crew: keep climbing, hold horizontal position during repairs.
    local pilot=fd.pilot
    if pilot then rpc(pilot,"Lane",{})task.wait(.85)end
    local repairOK,repairError=xpcall(function()repair(team)end,debug.traceback)
    if not repairOK then
     if not fd.isVictory then error(repairError)end
     table.insert(team.terminalCancellations,repairError)
    end
    if pilot and fd.pilot==pilot and not fd.isVictory and not fd.isGameOver then rpc(pilot,"Lane",{target=team.lane})end
   end
   task.wait(.2)
  end
  need(team.name.." reaches Victory",fd.isVictory==true,{seconds=os.clock()-team.start,holes=fd.holes})
  team.seconds=os.clock()-team.start
  assert(waitFor(function()return not fd.balloon.Parent end,45),"arrival timeout")
  for _,p in team.members do
   need(team.name.." "..p.Name.." summit credited",p:GetAttribute("SummitCount")==1 and p:GetAttribute("MaxAltitude")==10000)
   local dock=workspace.CloudPalace.CloudHavenDock
   need(team.name.." "..p.Name.." lands alive at palace",p.Character.Humanoid.Health>0 and(p.Character.HumanoidRootPart.Position-dock.Position).Magnitude<35)
   local snap=rpc(p,"Snapshot")local count=0 for i=1,5 do if snap.biomes[i] or snap.biomes[tostring(i)]then count+=1 end end
   need(team.name.." "..p.Name.." traverses all five biomes",count==5,snap)
   need(team.name.." "..p.Name.." clean client logs",#snap.logs==0,snap.logs)
  end
  local zones=0 for _,z in C.LARGE_CHALLENGE_ZONES do if fd.largeChallengeSeen and fd.largeChallengeSeen[z]then zones+=1 end end
  need(team.name.." sees five storm milestones",zones==5,{zones=zones,stormHits=fd.balloon:GetAttribute("StormHits")})
 end,debug.traceback)
 team.ok=ok team.error=not ok and err or nil team.done=true
 if not ok then check(team.name.." continuous run",false,err)if team.fd.balloon.Parent then bm.EndFlight(team.fd,false)end end
 print("[FullJourneyQA] "..team.name.." finished: "..tostring(ok))
end
local ok,err=xpcall(function()
 assert(waitFor(function()return #P:GetPlayers()==6 end,120),"six native clients did not join")
 local roster=P:GetPlayers()table.sort(roster,function(a,b)return a.Name<b.Name end)
 bm=_G.FlyHighBalloonManager tm=_G.FlyHighTetherManager wm=_G.FlyHighWeaponManager om=_G.FlyHighObstacleManager lm=_G.FlyHighLargeChallengeManager dm=_G.FlyHighDataManager
 U=require(game.ServerScriptService.FlyHighServer.ServerUtils)C=require(RS.FlyHigh.Modules.FlyHighConfig)
 for _,p in roster do assert(waitFor(function()return p:GetAttribute("DataReady")and p.Character and p.Character:FindFirstChild("HumanoidRootPart")end,45))rpc(p,"Ready")end
 local setups={
  {name="solo",members={roster[1]},pod="Pod_A",lane=Vector3.new(-90,0,-85)},
  {name="duo",members={roster[2],roster[3]},pod="Pod_C",lane=Vector3.new(0,0,85)},
  {name="trio",members={roster[4],roster[5],roster[6]},pod="Pod_E",lane=Vector3.new(90,0,-85)},
 }
 if testArgs~="FlyHighFullJourneyQA"then table.remove(setups,1)end
 for _,team in setups do
  team.repairs=0 team.rescues=0 team.dodges=0 team.interruptions={} team.terminalCancellations={}team.start=os.clock()
  team.fd=launch(team.members,team.pod)team.engineer=team.members[#team.members]
  helm(team.fd,team.members[1],team.lane)
  assert(waitFor(function()local d=team.fd.root.Position-team.lane return Vector2.new(d.X,d.Z).Magnitude<5 end,25),"departure lane timeout")
  if testArgs~="FlyHighFullJourneyQA"then
   rpc(team.members[1],"Lane",{})task.wait(.85)
   for cycle=1,20 do station(team.fd,team.engineer)attach(team.fd,team.engineer)tm.CleanupPlayer(team.engineer)end
   need(team.name.." repeated station approach and attach",true)
  end
  if #team.members==1 then
   rpc(team.members[1],"Action",{action="ReleaseHelm"})assert(waitFor(function()return not team.fd.pilot end,3))equip(team.fd,team.members[1])
  else
   equip(team.fd,team.members[2])
   if #team.members==3 then station(team.fd,team.engineer)attach(team.fd,team.engineer)end
  end
  if team.fd.pilot==team.members[1]then rpc(team.members[1],"Lane",{target=team.lane})end
  table.insert(teams,team)need(team.name.." native dock launch and boarding",team.fd.autoGas==true)
  task.spawn(runJourney,team)
 end
 local nextSample=0
 while true do
  local done=true for _,t in teams do if not t.done then done=false end end if done then break end
  if os.clock()>nextSample then
   nextSample=os.clock()+30 local sample={elapsed=os.clock()-began,obstacles=#om.activeObstacles,storms=#lm.active,crews={}}
   for _,t in teams do sample.crews[t.name]={km=t.fd.altitudeKm,holes=t.fd.holes,repairs=t.repairs,done=t.done}end
   table.insert(report.samples,sample)print("[FullJourneyQA] "..Http:JSONEncode(sample))
  end
  task.wait(.5)
 end
 for _,team in teams do table.insert(report.journeys,{name=team.name,ok=team.ok,error=team.error,seconds=team.seconds,repairs=team.repairs,rescues=team.rescues,dodges=team.dodges,interruptions=team.interruptions,terminalCancellations=team.terminalCancellations,victory=team.fd.isVictory,altitudeKm=team.fd.altitudeKm})end
 local allSucceeded=true for _,team in teams do if not team.ok then allSucceeded=false end end
 check("all requested continuous journeys succeed",allSucceeded)
 if testArgs=="FlyHighDuoTrioJourneyOnlyQA"then return end

end,debug.traceback)
report.ok=ok for _,c in report.checks do if not c.passed then report.ok=false end end
report.error=not ok and err or nil report.elapsed=os.clock()-began report.finishedUTC=DateTime.now():ToIsoDate()
STS:EndTest(Http:JSONEncode(report))
