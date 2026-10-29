local STS=game:GetService("StudioTestService")
if STS:GetTestArgs()~="FlyHighWarningAudioQA"then return end
assert(game.GameId==0)
local Players=game.Players local RS=game.ReplicatedStorage local Http=game:GetService("HttpService")
local r=RS.FlyHigh.Remotes local qa=r.WarningAudioQAEvent
local report={checks={},players={},metrics={},logs={}}local pending={}local id=0
game:GetService("LogService").MessageOut:Connect(function(m,k)if k==Enum.MessageType.MessageError or k==Enum.MessageType.MessageWarning then table.insert(report.logs,{message=m,kind=k.Name})end end)
qa.OnServerEvent:Connect(function(p,key,ok,value)local q=pending[key]if q and q.p==p then q.done=true q.ok=ok q.value=value end end)
local function waitFor(fn,t)local stop=os.clock()+t repeat local v=fn()if v then return v end task.wait(.05)until os.clock()>stop end
local function request(p,a,d)id+=1 local key=tostring(id)pending[key]={p=p}qa:FireClient(p,key,a,d or {})return key end
local function collect(key,t)local q=pending[key]assert(waitFor(function()return q.done end,t or 25),"client timeout")pending[key]=nil assert(q.ok,tostring(q.value))return q.value end
local function rpc(p,a,d,t)return collect(request(p,a,d),t)end
local function check(n,ok,d)table.insert(report.checks,{name=n,passed=ok==true,detail=d})assert(ok,n..": "..tostring(d))end
local roster,bm,tm,lm,U,C
local function move(f,pos)
 f.balloon:PivotTo(CFrame.new(pos))f.targetPosition=pos f.alignPos.Position=pos f.root.AssemblyLinearVelocity=Vector3.zero f.boardingUntil=os.clock()+600
 f.altitudeKm=(pos.Y-C.GROUND_Y)/C.STUDS_PER_KM
 for i,p in f.players do U.Unseat(p)p.Character:PivotTo(CFrame.new(pos+Vector3.new((i-1)*5,4,0)))p.Character.HumanoidRootPart.AssemblyLinearVelocity=Vector3.zero end task.wait(.4)
end
local function holes(f,n)
 while f.holes<n do f.invulnTime=0 f.shieldTime=0 assert(bm.ApplyPuncture(f,"SelfShot"))end
 while f.holes>n do for i in f.holeSet do assert(bm.RepairHole(f,i))break end end
 task.wait(.2)
end
local started=os.clock()
local ok,err=xpcall(function()
 check("three clients join",waitFor(function()return #Players:GetPlayers()==3 end,90)~=nil)
 roster=Players:GetPlayers()table.sort(roster,function(a,b)return a.Name<b.Name end)
 for _,p in roster do
  check(p.Name.." data ready",waitFor(function()return p:GetAttribute("DataReady")and p.Character and p.Character:FindFirstChild("HumanoidRootPart")end,60)~=nil)
  local s=rpc(p,"Ready")table.insert(report.players,{name=p.Name,logs=s.logs})
  check(p.Name.." two audio assets loaded",s.loaded==2,s.assets)
  check(p.Name.." lobby silent",s.state==""and s.playing==0,s)
 end
 bm=_G.FlyHighBalloonManager tm=_G.FlyHighTetherManager lm=_G.FlyHighLargeChallengeManager U=require(game.ServerScriptService.FlyHighServer.ServerUtils)C=require(RS.FlyHigh.Modules.FlyHighConfig)
 _G.FlyHighObstacleManager.Paused=true lm.Paused=true
 local a,b,c=roster[1],roster[2],roster[3]
 report.metrics.idleInput=rpc(a,"Idle")
 local f=assert(bm.LaunchBalloon({a},a,workspace.FlyHighLobby.MatchmakingPods.Pod_A.FloorPad.Position,"Pod_A"))move(f,Vector3.new(-70,512.5,-56))
 local other=assert(bm.LaunchBalloon({b,c},b,workspace.FlyHighLobby.MatchmakingPods.Pod_E.FloorPad.Position,"Pod_E"))move(other,Vector3.new(70,512.5,-56))
 check("healthy flight is silent",rpc(a,"Snapshot").state=="")
 r.HazardAlertEvent:FireClient(a,{hazardName="Angin Topan",direction="Depan",duration=3})task.wait(.15)
 local sample=rpc(a,"Monitor",{duration=.5})
 check("hazard alarm produces playback signal",sample.first.state=="Hazard"and sample.maxPlaying==1 and sample.peak>0 and sample.progress>0,sample)
 check("other team does not hear private hazard",rpc(b,"Snapshot").state==""and rpc(c,"Snapshot").state=="")
 local before=rpc(a,"Snapshot")for i=1,20 do r.HazardAlertEvent:FireClient(a,{duration=3})end
 sample=rpc(a,"Monitor",{duration=.5})
 check("duplicate warnings do not restart every packet",sample.last.cues-before.cues<=1 and sample.maxPlaying<=1,sample)
 task.wait(3.1)check("hazard alarm stops at expiry",rpc(a,"Snapshot").state=="")
 a.Character:PivotTo(f.balloon.TetherStation.CFrame*CFrame.new(2,3,0))task.wait(.3)assert(tm.attachHandlers[f.balloon](a))
 local tether=tm.activeTethers[a.UserId]tether.durability=29 task.wait(.2)
 check("worn rope in basket stays silent",rpc(a,"Snapshot").state=="")
 tether.durability=70 rpc(a,"Tether",{action="Climb"})
 check("climb completes",waitFor(function()return tether.stage=="Catwalk"and not tether.winch end,4)~=nil)
 report.metrics.landing={}
 for i=1,10 do
  task.wait(.2)local q=f.root.CFrame:PointToObjectSpace(tether.hrp.Position)
  table.insert(report.metrics.landing,{relative=tostring(q),velocity=tostring(tether.hrp.AssemblyLinearVelocity),angular=tostring(tether.hrp.AssemblyAngularVelocity),walkway=tostring(f.root.CFrame:PointToObjectSpace(f.balloon.EnvelopeRing.Walkway0.Position)),move=tostring(tether.hum.MoveDirection),floor=tether.hum.FloorMaterial.Name})
 end
 report.metrics.characterParts={}for _,part in a.Character:GetDescendants()do if part:IsA("BasePart")and part.CanCollide then table.insert(report.metrics.characterParts,{name=part.Name,size=tostring(part.Size),group=part.CollisionGroup})end end
 local standing=f.root.CFrame:PointToObjectSpace(tether.hrp.Position)
 check("engineer remains on catwalk while idle",standing.Y>18 and standing.Y<30 and Vector2.new(standing.X,standing.Z).Magnitude<24,{relative=tostring(standing),rig=tether.hum.RigType.Name,hip=tether.hum.HipHeight})
 tether.durability=29 task.wait(.2)
 check("low rope warns outside basket",rpc(a,"Snapshot").state=="RopeLow")
 tether.durability=14 task.wait(.2)
 check("critical rope escalates warning",rpc(a,"Snapshot").state=="RopeCritical")
 r.HazardAlertEvent:FireClient(a,{duration=2})task.wait(.1)
 sample=rpc(a,"Monitor",{duration=.8})
 check("critical rope preempts hazard without overlapping",sample.first.state=="RopeCritical"and sample.maxPlaying==1 and sample.last.notes-sample.first.notes<=4,sample)
 tether.durability=14
 rpc(a,"Tether",{action="Descend"})
 check("descent starts",waitFor(function()return tether.stage=="Descending"end,1)~=nil,{stage=tether.stage,durability=tether.durability,relative=tostring(f.root.CFrame:PointToObjectSpace(a.Character.HumanoidRootPart.Position))})
 task.wait(.3)local descending=rpc(a,"Snapshot")
 check("descending suppresses rope reminder",descending.state~="RopeCritical",descending)
 check("descent releases rope",waitFor(function()return not tm.activeTethers[a.UserId]end,3)~=nil)
 task.wait(.5)
 holes(other,3)check("three holes do not trigger critical alarm",rpc(b,"Snapshot").state=="")
 holes(other,4)
 check("critical alarm reaches both crew",rpc(b,"Snapshot").state=="Critical"and rpc(c,"Snapshot").state=="Critical")
 check("critical alarm stays within own team",rpc(a,"Snapshot").state=="")
 holes(f,4)check("four holes trigger caution",rpc(a,"Snapshot").state=="Critical")
 move(f,Vector3.new(-70,712.5,-56))holes(f,5)
 sample=rpc(a,"Monitor",{duration=.35})
 check("five holes switch to freefall siren",sample.first.state=="Freefall"and sample.maxPlaying==1 and sample.peak>0,sample)
 _G.FlyHighDataManager.ModifyEmergencyKits(a,1)check("clutch repair succeeds",bm.UseEmergencyKit(a))task.wait(.2)
 check("clutch immediately silences freefall",rpc(a,"Snapshot").state==""and rpc(a,"Snapshot").playing==0)
 local muted=rpc(b,"Mute",{value=true})sample=rpc(b,"Monitor",{duration=2.8})
 check("mute stops audio and future cue scheduling",muted.muted and sample.maxPlaying==0 and sample.first.notes==sample.last.notes and sample.last.volume==0,sample)
 check("mute does not affect teammate",rpc(c,"Snapshot").muted==false)
 rpc(b,"Mute",{value=false})sample=rpc(b,"Monitor",{duration=.55})
 check("unmute resumes current warning",sample.last.muted==false and sample.maxPlaying==1,sample)
 move(f,Vector3.new(-70,467.5,-56))
 local wave=assert(lm.Spawn(1800,f))task.wait(.15)
 check("storm warning selects storm siren",rpc(a,"Snapshot").state=="Storm")
 check("shared storm preempts other crew caution",rpc(b,"Snapshot").state=="Storm"and rpc(c,"Snapshot").state=="Storm")
 move(f,Vector3.new(-70,wave.bottom-C.BALLOON_TOP_CLEARANCE-3,-56))
 check("safe altitude silences storm for safe team",rpc(a,"Snapshot").state=="")
 local old=rpc(b,"Snapshot")
 for i=1,20 do r.LargeChallengeEvent:FireClient(b,{kind="Warning",id=wave.id,endsAt=workspace:GetServerTimeNow()+10,safeRootY=wave.bottom-C.BALLOON_TOP_CLEARANCE,warningEndsAt=workspace:GetServerTimeNow()+6})end
 sample=rpc(b,"Monitor",{duration=.4})
 check("duplicate storm ID does not restart alarm",sample.last.cues-old.cues<=1 and sample.maxPlaying<=1,sample)
 lm.Clear(wave)task.wait(.15)
 check("storm end restores remaining critical warning",rpc(b,"Snapshot").state=="Critical")
 b.Character.Humanoid.Health=0 task.wait(.2)
 check("ghost spectator is silent",rpc(b,"Snapshot").state==""and rpc(b,"Snapshot").playing==0)
 check("living crew retains warning",rpc(c,"Snapshot").state=="Critical")
 bm.EndFlight(other,false)bm.EndFlight(f,false)task.wait(.2)
 for _,p in roster do local s=rpc(p,"Snapshot")check(p.Name.." game over silences audio",s.state==""and s.playing==0)check(p.Name.." fixed pool has four objects",s.children==4)end
 f.balloon:Destroy()other.balloon:Destroy()a:LoadCharacterAsync()task.wait(.5)
 local nextFlight=assert(bm.LaunchBalloon({a},a,workspace.FlyHighLobby.MatchmakingPods.Pod_C.FloorPad.Position,"Pod_C"))task.wait(.4)
 local s=rpc(a,"Snapshot")check("next flight does not retain alerts or duplicate sounds",s.state==""and s.children==4 and not s.fallback,s)
 local destroyed=rpc(a,"Destroy")check("controller cleanup removes sounds and toggle",not destroyed.folder and not destroyed.toggle,destroyed)
 nextFlight.balloon:Destroy()
end,debug.traceback)
local clientLogs=0 for i,p in ipairs(roster or {})do local good,s=pcall(rpc,p,"Snapshot",{},5)if good then report.players[i].logs=s.logs clientLogs+=#s.logs end end
report.ok=ok and #report.logs==0 and clientLogs==0 report.error=not ok and err or nil report.clientLogCount=clientLogs report.duration=os.clock()-started
STS:EndTest(Http:JSONEncode(report))
