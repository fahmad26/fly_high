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

 for _,band in {1,3}do
  reset()
  local item=assert(om.SpawnBand(band,fd,true))
  local dir=Vector3.new(item.velocity.X,0,item.velocity.Z).Unit
  local start=fd.root.Position
  local peak=0
  local activeAt=item.activeAt
  local born=os.clock()
  while os.clock()<activeAt+.05 do
   check('warning no early gust '..band,fd.wind==nil,{elapsed=os.clock()-born})
   task.wait(.5)
  end
  local sampleEnd=activeAt+3.5
  while os.clock()<sampleEnd do task.wait(.05) peak=math.max(peak,(fd.wind or Vector3.zero):Dot(dir))end
  local delta=fd.root.Position-start
  check('native trajectory '..band,peak>0 and delta:Dot(dir)>1,{direction=vec(dir),delta=vec(delta),peak=peak,warning=activeAt-born})
 end
 for _,mode in {'normal','opposed','boundary','rider'}do
  reset()
  if mode=='boundary'then
   local pos=fd.root.Position+Vector3.new(0,0,C.CORRIDOR_CENTER_LIMIT-2)
   fd.balloon:PivotTo(CFrame.new(pos))fd.targetPosition=pos fd.alignPos.Position=pos
  end
  fd.altitudeKm=1800
  local item=assert(lm.Spawn(1800,fd))
  local start=fd.root.Position
  local born=os.clock()
  script:SetAttribute('Stage',mode)
  if mode=='rider'then
   follow:Disconnect()follow=nil
   hrp.CFrame=fd.root.CFrame*CFrame.new(0,4.8,0)hrp.Anchored=false
   p.Character.Humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
  end
  local noEarly=true
  while os.clock()<item.activeAt do noEarly=noEarly and fd.holes==0 and fd.wind==nil task.wait(.1)end
  check(mode..' full 6s warning',noEarly,{duration=item.activeAt-born})
  local waitUntil=os.clock()+9
  local firstHit=nil local minZ=math.huge local maxZ=-math.huge
  local oppose
  if mode=='opposed'then
   oppose=Run.Heartbeat:Connect(function()
    fd.pilot=p fd.lastControl=os.clock()
    fd.pilotSteer=fd.wind and -Vector3.zAxis or Vector3.zero
   end)
  end
  while os.clock()<waitUntil do
   task.wait(.05)
   if fd.wind and not firstHit then firstHit=os.clock()end
   minZ=math.min(minZ,fd.targetPosition.Z)maxZ=math.max(maxZ,fd.targetPosition.Z)
  end
  if oppose then oppose:Disconnect()fd.pilot=nil fd.pilotSteer=Vector3.zero end
  local delta=fd.root.Position-start
  check(mode..' curtain reaches balloon',firstHit~=nil,{hitAfter=firstHit and firstHit-born,holes=fd.holes})
  if mode=='normal'then
   report.normalDelta=delta.Z
   check('normal gust movement',delta.Z>30 and fd.holes==1,vec(delta))
  elseif mode=='opposed'then
   check('pilot can oppose gust',firstHit~=nil and delta.Z<report.normalDelta-20,{delta=vec(delta),normal=report.normalDelta})
  elseif mode=='boundary'then
   check('corridor target bounded',maxZ<=C.CORRIDOR_CENTER_LIMIT+.01,{maxZ=maxZ,limit=C.CORRIDOR_CENTER_LIMIT})
  else
   local rel=fd.root.CFrame:PointToObjectSpace(hrp.Position)
   check('unanchored rider stays aboard',p.Character.Humanoid.Health>0 and Vector2.new(rel.X,rel.Z).Magnitude<15 and rel.Y>-8,{relative=vec(rel),health=p.Character.Humanoid.Health,anchored=hrp.Anchored})
  end
  check(mode..' one hit per wave',fd.holes==1 and fd.balloon:GetAttribute('StormHits')~=nil,{holes=fd.holes})
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
