local STS=game:GetService("StudioTestService")if STS:GetTestArgs()~="RepairMotionQA"then return end
local H=game:GetService("HttpService")local R=game.ReplicatedStorage.FlyHigh.Remotes local qa=R.RepairMotionQA
local report={run="repair-motion-2026-11-11",checks={},samples={},errors={},startedUTC=DateTime.now():ToIsoDate(),fixtures="3 real clients; altitude warp; shield; client position setup and following local catwalk point; manager begin/finish repair with production validation"}
local log=game:GetService("LogService").MessageOut:Connect(function(m,k)if k==Enum.MessageType.MessageError then table.insert(report.errors,m)end end)
local serial=0 local replies={}
qa.OnServerEvent:Connect(function(p,id,ok,result)replies[id]={p=p,ok=ok,result=result}end)
local function waitFor(f,t)local last=os.clock()+t repeat if f()then return true end task.wait(.05)until os.clock()>last return false end
local function check(n,v,d)table.insert(report.checks,{name=n,pass=v==true,detail=d})assert(v,n.." "..tostring(d))end
local function rpc(p,a,d)
 serial+=1 local id=serial qa:FireClient(p,id,a,d)
 assert(waitFor(function()return replies[id]end,10),"client timeout "..a)
 local reply=replies[id]replies[id]=nil assert(reply.p==p and reply.ok,tostring(reply.result))return reply.result
end
task.delay(150,function()report.timeout=true STS:EndTest(H:JSONEncode(report))end)
task.spawn(function()
 local ok,err=xpcall(function()
 check("3 clients ready",waitFor(function()if #game.Players:GetPlayers()~=3 then return end for _,p in game.Players:GetPlayers()do if not p.Character or not p.Character:FindFirstChild("HumanoidRootPart")or not p:GetAttribute("DataReady")then return end end return _G.FlyHighBalloonManager~=nil end,60))
 local ps=game.Players:GetPlayers()table.sort(ps,function(a,b)return a.UserId<b.UserId end)
 for _,p in ps do check("HUD ready "..p.Name,rpc(p,"Ready"))end
 local bm=_G.FlyHighBalloonManager local tm=_G.FlyHighTetherManager
 local fd=bm.LaunchBalloon(ps,ps[1],workspace.FlyHighLobby.MatchmakingPods.Pod_C.FloorPad.Position,"Pod_C")
 check("launch",fd~=nil)
 for p,x in pairs(fd.boarding)do bm.FlightAction(p,"BoardReady",x.token)end
 assert(waitFor(function()return not fd.boarding end,5))
 fd.boardingUntil=os.clock()+20 -- Warp fixture grace: keep the distance guard from racing client positioning.
 local delta=Vector3.new(0,125,0)fd.balloon:PivotTo(fd.balloon:GetPivot()+delta)fd.targetPosition=fd.root.Position fd.alignPos.Position=fd.targetPosition
 for _,p in ps do rpc(p,"Pose",Vector3.new(0,5,8))end
 fd.shieldTime=999 fd.autoGas=false
 local engineer=ps[2]
 rpc(engineer,"Pose",fd.root.CFrame:PointToObjectSpace(fd.balloon.TetherStation.Position)+Vector3.new(0,2,-3))
 task.wait(.2)
 local attachOK=false
 for attempt=1,3 do
  rpc(engineer,"Pose",Vector3.new(0,4,8))task.wait(.15)
  attachOK=tm.attachHandlers[fd.balloon] and tm.attachHandlers[fd.balloon](engineer)
  if attachOK then break end
 end
 report.attachDiagnostic={client=rpc(engineer,"Snapshot"),alive=engineer.Character.Humanoid.Health,dead=fd.dead[engineer],role=engineer:GetAttribute("CrewRole"),anchored=engineer.Character.HumanoidRootPart.Anchored,boarding=fd.boarding~=nil}
 check("attach",attachOK==true,H:JSONEncode(report.attachDiagnostic))
 fd.autoGas=true
 rpc(engineer,"Tether","Climb")
 check("climb settles",waitFor(function()local t=tm.activeTethers[engineer.UserId]return t and t.stage=="Catwalk"end,5))
 local t=tm.activeTethers[engineer.UserId]
 rpc(engineer,"Follow",Vector3.new(0,26,-16))
 local drive=true
 task.spawn(function()local began=os.clock()while drive do
 local elapsed=os.clock()-began
 fd.pilot=ps[1]fd.lastControl=os.clock()
 fd.pilotSteer=Vector3.new(math.sin(elapsed*2),0,math.cos(elapsed*2))
 task.wait(.08)
 end end)
 for trial=1,3 do
  task.wait(.5)
  local holesBefore=fd.holes bm.ApplyPuncture(fd,"SelfShot")
  -- Shield used only for environmental stability; explicit requested test damage.
  if fd.holes==holesBefore then fd.shieldTime=0 fd.invulnTime=0 bm.ApplyPuncture(fd,"SelfShot")fd.shieldTime=999 end
  local n=next(fd.holeSet)
  local h=fd.balloon.HoleSlots["Hole"..n]
  local q=fd.root.CFrame:PointToObjectSpace(h.Position)
  local flat=Vector3.new(q.X,0,q.Z).Unit*16
  rpc(engineer,"Follow",Vector3.new(flat.X,26,flat.Z))
  task.wait(1)
  table.insert(report.samples,{stage=t.stage,serverQ=tostring(fd.root.CFrame:PointToObjectSpace(t.hrp.Position)),distance=(t.hrp.Position-h.Position).Magnitude,client=rpc(engineer,"Snapshot")})
  check("repair begins moving "..trial,tm.BeginRepair(engineer,n),H:JSONEncode(report.samples[#report.samples]))
  task.wait(h.PatchPrompt.HoldDuration+.15)
  check("repair finishes moving "..trial,tm.FinishRepair(engineer),t.stage)
  check("no false hanging "..trial,t.stage=="Catwalk")
 end
 fd.shieldTime=0 fd.invulnTime=0 bm.ApplyPuncture(fd,"SelfShot")fd.shieldTime=999
 report.nativePromptInput="ProximityPrompt InputHoldBegin/End (engine path; no keyboard visibility claim)"
 report.nativePrompt=rpc(engineer,"Patch")
 table.insert(report.checks,{name="native repair hold moving",pass=fd.holes==0,detail=report.nativePrompt})
 drive=false fd.pilot=nil fd.pilotSteer=Vector3.zero
 rpc(engineer,"Stop")
 rpc(engineer,"Tether","Descend")
 check("descent detaches",waitFor(function()return not tm.activeTethers[engineer.UserId]end,5))
 local function settled()
  rpc(engineer,"Pose",Vector3.new(0,4,7)) task.wait(1)
 end
 local function hop(label,action)
  check("jump allowed "..label,waitFor(function()return engineer:GetAttribute("FlightJumpAllowed")==true end,2),rpc(engineer,"Snapshot"))
  local before=engineer:GetAttribute("FlightJumpCount")or 0
  rpc(engineer,action or "Jump")
  local jumped=waitFor(function()return (engineer:GetAttribute("FlightJumpCount")or 0)>before end,2)
  check("jump counted "..label,jumped,H:JSONEncode(rpc(engineer,"Snapshot")))
  task.wait(1.3)
 end
 settled()hop("after descent")
 rpc(engineer,"Pose",fd.root.CFrame:PointToObjectSpace(fd.balloon.HelmSeat.Position)+Vector3.new(0,2,0))
 fd.balloon.HelmSeat:Sit(engineer.Character.Humanoid)
 check("pilot blocks jump",waitFor(function()return fd.pilot==engineer and engineer:GetAttribute("FlightJumpAllowed")==false end,2))
 rpc(engineer,"Release")
 check("helm releases",waitFor(function()return fd.pilot==nil end,2))
 settled()hop("after helm","Space")
 local wm=_G.FlyHighWeaponManager
 local rack=fd.balloon.WeaponRack1
 local rackQ=fd.root.CFrame:PointToObjectSpace(rack.Position)
 rpc(engineer,"Pose",Vector3.new(rackQ.X*.65,4,rackQ.Z*.65))task.wait(.3)
 check("gunner equipped",wm.TryEquip(engineer,fd.balloon,rack)==true)
 settled()hop("holding weapon","Space")
 wm.CleanupPlayer(engineer)
 settled()hop("after drop")
 rpc(engineer,"Pose",fd.root.CFrame:PointToObjectSpace(fd.balloon.TetherStation.Position)+Vector3.new(0,2,-3))task.wait(.2)
 check("reattach",tm.attachHandlers[fd.balloon](engineer)==true)
 settled()hop("attached in basket")
 tm.CleanupPlayer(engineer)
 settled()hop("after detach")
 check("no runtime errors",#report.errors==0)
 end,debug.traceback)
 report.executionCompleted=ok report.success=ok for _,c in report.checks do if not c.pass then report.success=false end end report.failure=not ok and err or nil report.finishedUTC=DateTime.now():ToIsoDate()log:Disconnect()
 STS:EndTest(H:JSONEncode(report))
end)
