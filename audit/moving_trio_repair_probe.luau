local STS=game:GetService("StudioTestService")local testArgs=STS:GetTestArgs()
if testArgs~="FlyHighFullJourneyQA"and testArgs~="FlyHighDuoTrioQA"and testArgs~="FlyHighDuoTrioJourneyOnlyQA"then return end
local P=game.Players local RS=game.ReplicatedStorage local Http=game:GetService("HttpService")local Run=game:GetService("RunService")
local qa=RS.FlyHigh.Remotes.FullJourneyQAEvent
local report={checks={},logs={},journeys={},samples={},fixtures={continuousAltitude="normal production integration, no altitude skips or shields",roles="scripted positions inside lobby/basket; native remotes and production manager validations",fatalBranches="controlled altitude/damage/inventory after full journeys"}}
local pending={}local serial=0 local began=os.clock()
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

local fd
report.fixtures={altitude="controlled warp to 2500 km before seating pilot",hazards="paused for focused reproduction only",steering="pilot holds horizontal input during repair; auto gas remains on",damage="one controlled self-shot puncture per cycle",roles="client-acknowledged relative placement; production role and repair validation"}
local ok,err=xpcall(function()
 assert(waitFor(function()return #P:GetPlayers()==6 end,120))
 bm=_G.FlyHighBalloonManager tm=_G.FlyHighTetherManager wm=_G.FlyHighWeaponManager om=_G.FlyHighObstacleManager lm=_G.FlyHighLargeChallengeManager dm=_G.FlyHighDataManager
 U=require(game.ServerScriptService.FlyHighServer.ServerUtils)C=require(RS.FlyHigh.Modules.FlyHighConfig)
 om.Paused=true lm.Paused=true
 local members={P.Player4,P.Player5,P.Player6}
 for _,p in members do assert(waitFor(function()return p:GetAttribute("DataReady")and p.Character and p.Character:FindFirstChild("HumanoidRootPart")end,40))rpc(p,"Ready")end
 fd=launch(members,"Pod_E")local lane=Vector3.new(90,0,-85)
 local shift=Vector3.new(0,C.GROUND_Y+2500*C.STUDS_PER_KM-fd.root.Position.Y,0)
 fd.balloon:PivotTo(fd.balloon:GetPivot()+shift)fd.targetPosition+=shift fd.altitudeKm=2500 fd.alignPos.Position=fd.targetPosition fd.boardingUntil=os.clock()+5
 for _,p in members do p.Character:PivotTo(p.Character:GetPivot()+shift)end
 fd.root.AssemblyLinearVelocity=Vector3.zero task.wait(1)helm(fd,members[1],lane)
 local team={fd=fd,members=members,engineer=members[3],lane=lane,repairs=0,rescues=0,interruptions={}}
 for cycle=1,8 do
  team.lane=Vector3.new(90,0,cycle%2==0 and -85 or 85)rpc(members[1],"Lane",{target=team.lane})
  fd.invulnTime=0 assert(bm.ApplyPuncture(fd,"SelfShot"))
  rpc(members[1],"Lane",{})task.wait(.85)
  repair(team)
  need("moving trio repair cycle "..cycle,fd.holes==0 and U.Alive(members[3],fd),{repairs=team.repairs,rescues=team.rescues,interruptions=team.interruptions})
 end
 report.repairs=team.repairs report.rescues=team.rescues report.interruptions=team.interruptions
 for _,p in members do local s=rpc(p,"Snapshot")need(p.Name.." clean client logs",#s.logs==0,s.logs)end
end,debug.traceback)
if fd then
 local p=fd.players[3]local t=tm.activeTethers[p.UserId]
 report.finalState={km=fd.altitudeKm,holes=fd.holes,role=U.Role(p),position=tostring(fd.root.CFrame:PointToObjectSpace(p.Character.HumanoidRootPart.Position)),tether=t and{stage=t.stage,durability=t.durability,winch=t.winch and t.winch.elapsed}}
 bm.EndFlight(fd,false)
end
report.ok=ok and #report.logs==0 report.error=not ok and err or nil report.elapsed=os.clock()-began
STS:EndTest(Http:JSONEncode(report))
