-- Runtime-only QA fixture. Never install in Edit or publish.
local Http=game:GetService("HttpService")
local Run=game:GetService("RunService")
local bm,om,lm,dm=_G.FlyHighBalloonManager,_G.FlyHighObstacleManager,_G.FlyHighLargeChallengeManager,_G.FlyHighDataManager
local C=require(game.ReplicatedStorage.FlyHigh.Modules.FlyHighConfig)
local p=game.Players:GetPlayers()[1]
local report={cases={},fixture="Solo server driver; spawn/altitude/warning warp; character anchored and follows balloon; automatic obstacle spawning paused; reward/altitude writes intercepted"}
local originals={}
local fd,follow,hrp,oldAnchor
local function vec(v)return {v.X,v.Y,v.Z}end
local function check(name,pass,actual)table.insert(report.cases,{name=name,pass=pass,actual=actual})end
local function clear()
 for i=#om.activeObstacles,1,-1 do om.activeObstacles[i].instance:Destroy() table.remove(om.activeObstacles,i)end
 for _,item in table.clone(lm.active)do lm.Clear(item)end
end
local function reset()
 clear()
 fd.wind=nil fd.windSince=nil fd.windUntil=nil fd.windSource=nil
 fd.invulnTime=0 fd.shieldTime=0 fd.balloon:SetAttribute("ArrivalProtected",nil)
 if fd.holes==1 then bm.RepairHole(fd,1)end
 fd.largeChallengeUntil=nil fd.largeChallengeId=nil
 fd.largeChallengeSeen={}
 local pos=Vector3.new(0,C.GROUND_Y+1800*C.STUDS_PER_KM,0)
 fd.balloon:PivotTo(CFrame.new(pos))fd.targetPosition=pos
 fd.root.AssemblyLinearVelocity=Vector3.zero fd.root.AssemblyAngularVelocity=Vector3.zero
 fd.alignPos.Position=pos fd.altitudeKm=1800
 task.wait(.15)
end
local success,err=xpcall(function()
 assert(bm and om and lm and dm,"Production managers unavailable")
 assert(p and p:GetAttribute("DataReady"),"Player not ready")
 for _,key in {"GrantCoins","UpdateAltitude","AddSummit"}do
  originals[key]=dm[key]
  dm[key]=function() report.blockedProgressWrites=(report.blockedProgressWrites or 0)+1 return 0 end
 end
 report.oldPaused={obstacles=om.Paused,large=lm.Paused}
 om.Paused=true lm.Paused=true
 fd=assert(bm.LaunchBalloon({p},p,nil,"Pod_A"),"Launch failed")
 hrp=p.Character.HumanoidRootPart oldAnchor=false
 fd.boarding=nil fd.boardingUntil=os.clock()+120 fd.nextGroundCheck=os.clock()+120 fd.grounded=false
 fd.root.Anchored=false fd.root:SetNetworkOwner(nil)
 p:SetAttribute("BoardingFlight",nil)
 hrp.Anchored=true
 follow=Run.PreSimulation:Connect(function()
  if fd and fd.root.Parent and hrp.Parent then hrp.CFrame=fd.root.CFrame*CFrame.new(0,4.8,0)end
 end)
 local cases={
  {"tornado +X",1,Vector3.xAxis},{"tornado -X",1,-Vector3.xAxis},
  {"tornado +Z fixture",1,Vector3.zAxis},{"tornado -Z fixture",1,-Vector3.zAxis},
  {"jetstream +X",3,Vector3.xAxis},{"jetstream -X fixture",3,-Vector3.xAxis},
 }
 for _,case in cases do
  reset()
  local item=assert(om.SpawnBand(case[2],fd,true),"Hazard spawn failed")
  local dir=case[3]
  item.velocity=dir*(item.effect=="Wind" and 136 or 140)/2.5
  item.path=dir*140 item.origin=CFrame.new(fd.balloon.Envelope.Position-dir*20)
  item.activeAt=os.clock()+.05 item.instance:PivotTo(item.origin)
  local start=fd.root.Position
  task.wait(1.8)
  local delta=fd.root.Position-start
  local wind=fd.wind or Vector3.zero
  check(case[1],delta:Dot(dir)>1 and wind:Dot(dir)>0 and math.abs(delta:Dot(Vector3.new(-dir.Z,0,dir.X)))<2,
   {delta=vec(delta),wind=vec(wind),holes=fd.holes})
  check(case[1].." no puncture",fd.holes==0,fd.holes)
 end
 for _,mode in {"hit","below","shield","grace","arrival"}do
  reset()
  if mode=="shield"then fd.shieldTime=10 end
  if mode=="grace"then fd.invulnTime=10 end
  if mode=="arrival"then fd.balloon:SetAttribute("ArrivalProtected",true)end
  local item=assert(lm.Spawn(1800,fd),"Curtain spawn failed")
  if mode=="below"then item.bottom=fd.root.Position.Y+C.BALLOON_TOP_CLEARANCE+10 item.top=item.bottom+C.LARGE_HEIGHT end
  local now=os.clock()
  item.activeAt=now-C.LARGE_START_Z/C.LARGE_SPEED item.lastZ=-2
  item.warned[fd]=now-1
  local start=fd.root.Position
  task.wait(.5)
  local wind=fd.wind or Vector3.zero
  local hits=fd.balloon:GetAttribute("StormHits")or 0
  if mode=="hit"then
   check("curtain follows +Z sweep",wind.Z>0 and math.abs(wind.X)<.001,{wind=vec(wind),sweep=vec(item.velocity)})
   check("curtain one puncture",fd.holes==1,fd.holes)
   local untilTime=fd.windUntil
   task.wait(3)
   local delta=fd.root.Position-start
   check("curtain actual displacement",delta.Z>25 and math.abs(delta.X)<2,{delta=vec(delta)})
   check("curtain gust expires and does not retrigger",fd.windUntil==untilTime and os.clock()>fd.windUntil and fd.holes==1 and hits==(fd.balloon:GetAttribute("StormHits")or 0),{hits=hits,holes=fd.holes})
   local tailStart=fd.targetPosition
   task.wait(.35)
   check("no target drift after gust",math.abs(fd.targetPosition.Z-tailStart.Z)<.05,vec(fd.targetPosition-tailStart))
  else
   check("curtain "..mode.." no push or damage",wind.Magnitude==0 and fd.holes==0,{wind=vec(wind),holes=fd.holes})
  end
 end
end,debug.traceback)
if follow then follow:Disconnect()end
if fd then
 for _,link in ipairs(fd.connections)do link:Disconnect()end
 clear()
 _G.FlyHighTetherManager.CleanupBalloon(fd.balloon)
 _G.FlyHighWeaponManager.CleanupBalloon(fd.balloon)
 fd.balloon:Destroy()
 local index=table.find(bm.activeFlights,fd)if index then table.remove(bm.activeFlights,index)end
 p:SetAttribute("InFlight",false)p:SetAttribute("IsMaster",false)p:SetAttribute("BoardingFlight",nil)
 local ref=p:FindFirstChild("FlightBalloon")if ref then ref.Value=nil end
 if hrp and hrp.Parent then hrp.CFrame=CFrame.new(0,20,0)hrp.Anchored=oldAnchor end
end
for key,func in pairs(originals)do dm[key]=func end
if report.oldPaused then om.Paused=report.oldPaused.obstacles lm.Paused=report.oldPaused.large end
report.success=success report.error=err report.passed=0
for _,row in report.cases do if row.pass then report.passed+=1 end end
report.total=#report.cases report.cleanup={flights=#bm.activeFlights,obstacles=#om.activeObstacles,large=#lm.active,progressFunctionsRestored=true}
script:SetAttribute("Report",Http:JSONEncode(report))
script:SetAttribute("Done",true)
