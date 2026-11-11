local STS=game:GetService("StudioTestService")
if STS:GetTestArgs()~="DocksCriticalQA"then return end
local H=game:GetService("HttpService")local Run=game:GetService("RunService")
local report={startedUTC=DateTime.now():ToIsoDate(),checks={},cases={},errors={},fixture="Solo real balloon; altitude warps; 4 holes seeded using production puncture calls; character anchored/carried for measurement; natural spawning and storm walls paused; manually spawned real enemies; no shield"}
local function waitFor(f,t)local endAt=os.clock()+t repeat if f()then return true end task.wait(.05)until os.clock()>endAt return false end
local function check(n,v,d)table.insert(report.checks,{name=n,pass=v==true,detail=d})assert(v,n.." "..tostring(d))end
local log=game:GetService("LogService").MessageOut:Connect(function(m,k)if k==Enum.MessageType.MessageError then table.insert(report.errors,m)end end)
task.delay(180,function()report.timeout=true STS:EndTest(H:JSONEncode(report))end)
task.spawn(function()
local ok,err=xpcall(function()
 check("player and managers ready",waitFor(function()local p=game.Players:GetPlayers()[1]return p and p.Character and p.Character:FindFirstChild("HumanoidRootPart")and p:GetAttribute("DataReady")and _G.FlyHighObstacleManager and _G.FlyHighBalloonManager end,30))
 local p=game.Players:GetPlayers()[1]local bm=_G.FlyHighBalloonManager local om=_G.FlyHighObstacleManager
 om.Paused=true _G.FlyHighLargeChallengeManager.Paused=true
 local config=require(game.ReplicatedStorage.FlyHigh.Modules.FlyHighConfig)
 local Space=require(game.ServerScriptService.FlyHighServer.FlightSpace)
 local Motion=require(game.ServerScriptService.FlyHighServer.ObstacleMotion)
 local templates=game.ReplicatedStorage.FlyHigh.Templates.BalloonVariants
 local obstacles=game.Workspace.FlyHighObstacles
 local pods=workspace.FlyHighLobby.MatchmakingPods
 local models={}local fakes={}
 for i,name in ipairs({"Pod_A","Pod_B","Pod_C","Pod_D","Pod_E"})do
  local b=templates.DawnExplorer:Clone()b.Name="QADockProxy"..i b:PivotTo(CFrame.new(Space.SpawnPosition(pods[name].FloorPad.Position)))b.Parent=workspace
  table.insert(models,b)table.insert(fakes,{balloon=b,root=b.PrimaryPart})
 end
 for i,name in ipairs({"Pod_A","Pod_B","Pod_C","Pod_D","Pod_E"})do
  local others={}for j,f in ipairs(fakes)do if i~=j then table.insert(others,f)end end
  local pos=Space.SpawnPosition(pods[name].FloorPad.Position)
  check("other four docks do not block "..name,Space.Blocker(pos,others)==nil)
  check("same dock stays blocked "..name,Space.Blocker(pos,fakes)==fakes[i])
 end
 for _,b in ipairs(models)do b:Destroy()end
 local fd=bm.LaunchBalloon({p},p,pods.Pod_C.FloorPad.Position,"Pod_C")
 check("real balloon launches",fd~=nil)
 for crew,item in pairs(fd.boarding)do bm.FlightAction(crew,"BoardReady",item.token)end
 check("boarding settles",waitFor(function()return not fd.boarding end,5))
 local hrp=p.Character.HumanoidRootPart hrp.Anchored=true
 local carry=Run.PreSimulation:Connect(function()if fd.balloon.Parent then hrp.CFrame=fd.root.CFrame*CFrame.new(0,4,8)end end)
 local function clear()
  for _,item in ipairs(om.activeObstacles)do if item.instance.Parent then item.instance:Destroy()end end table.clear(om.activeObstacles)
 end
 local function setup(km,gas,holes)
  clear()fd.boardingUntil=os.clock()+3 fd.root.Anchored=true fd.holes=0 fd.holeSet={}fd.isFreefalling=false fd.invulnTime=0 fd.shieldTime=0 fd.autoGas=gas fd.isGasActive=false
  fd.balloon:PivotTo(CFrame.new(0,config.GROUND_Y+km*config.STUDS_PER_KM,-30))
  fd.targetPosition=fd.root.Position fd.alignPos.Position=fd.targetPosition fd.root.AssemblyLinearVelocity=Vector3.zero fd.altitudeKm=km fd.velocitySampleAt=nil
  hrp.CFrame=fd.root.CFrame*CFrame.new(0,4,8)hrp.AssemblyLinearVelocity=Vector3.zero
  for _=1,holes do fd.invulnTime=0 check("seed puncture",bm.ApplyPuncture(fd,"SelfShot"))end
  fd.invulnTime=0 fd.root.Anchored=false task.wait(.8)
 end
 setup(500,false,4)
 local center=fd.balloon.Envelope.Position local oldAim=center local oldStart=oldAim+Vector3.new(0,10,-95)
 local oldTime=(oldAim-oldStart).Magnitude/22
 local v=fd.root.AssemblyLinearVelocity.Y
 report.oldVerticalMissWithoutGas=math.abs(v*oldTime)
 setup(500,true,4)
 center=fd.balloon.Envelope.Position oldAim=center+Vector3.new(0,12.5,0)oldStart=oldAim+Vector3.new(0,10,-95)
 oldTime=(oldAim-oldStart).Magnitude/22
 report.oldVerticalMissWithGas=math.abs(12.5-fd.root.AssemblyLinearVelocity.Y*oldTime)
 check("old gas prediction misses critical descent radius",report.oldVerticalMissWithGas>18,report.oldVerticalMissWithGas)
 for band=1,9 do
  for _,gas in ipairs({true,false})do
   setup(band*1000+500,gas,4)
   local before=fd.holes local speed=fd.root.AssemblyLinearVelocity.Y
   local item=om.SpawnBand(band,fd,false)
   check("critical enemy spawned "..band.."/"..tostring(gas),item~=nil)
   local hit=waitFor(function()return fd.holes>before or fd.isGameOver end,8)
   table.insert(report.cases,{band=band,gas=gas,verticalSpeed=speed,effect=item.effect,hit=hit,holes=fd.holes})
   check("critical balloon can be hit "..band.."/"..tostring(gas),hit and fd.holes==5 and not fd.isGameOver,H:JSONEncode(report.cases[#report.cases]))
  end
 end
 setup(500,true,0)
 local item=om.SpawnBand(1,fd,false)
 check("healthy balloon still hit",item and waitFor(function()return fd.holes==1 end,8))
 setup(200,true,4)
 check("safe takeoff zone still blocks enemies",om.SpawnBand(1,fd,false)==nil)
 carry:Disconnect()hrp.Anchored=false
 clear()
 check("no runtime errors",#report.errors==0,H:JSONEncode(report.errors))
end,debug.traceback)
report.success=ok report.failure=not ok and err or nil report.finishedUTC=DateTime.now():ToIsoDate()log:Disconnect()
STS:EndTest(H:JSONEncode(report))
end)
