-- Temporary controlled gameplay regression, with isolated unpublished mock data.
local STS=game:GetService("StudioTestService")
if STS:GetTestArgs()~="DuoCheckpointQA" then return end
local H=game:GetService("HttpService")
local Players=game:GetService("Players")
local R=game:GetService("ReplicatedStorage").FlyHigh.Remotes
local qa=R:WaitForChild("_QA_Duo")
local report={run="duo-checkpoint-2026-11-17",base="de8c273",startedUTC=DateTime.now():ToIsoDate(),checks={},errors={},snapshots={},fixtures="2 real local clients; unpublished GameId=0 mock; manager launch; altitude warp; paused hazard scheduling; anchored balloon for prompt/combat measurements; damaged rope and configured AK47 rack are runtime-only fixtures; broad registered target is a combat fixture, not art QA"}
local finished=false
local log=game:GetService("LogService").MessageOut:Connect(function(m,k)if k==Enum.MessageType.MessageError then table.insert(report.errors,m) end end)
local function finish()
 if finished then return end finished=true
 report.finishedUTC=DateTime.now():ToIsoDate()
 log:Disconnect()
 STS:EndTest(H:JSONEncode(report))
end
task.delay(180,function()report.timeout=true report.success=false finish()end)
local replies={} local serial=0
qa.OnServerEvent:Connect(function(p,id,ok,result)replies[id]={p=p,ok=ok,result=result}end)
local function waitFor(f,seconds)
 local deadline=os.clock()+seconds
 repeat if f() then return true end task.wait(.05) until os.clock()>deadline
 return false
end
local function check(name,pass,detail)
 table.insert(report.checks,{name=name,pass=pass==true,detail=detail})
 assert(pass,name.." "..tostring(detail))
end
local function rpc(p,action,data)
 serial+=1 local id=serial qa:FireClient(p,id,action,data)
 assert(waitFor(function()return replies[id]end,12),"Client timeout: "..action)
 local reply=replies[id] replies[id]=nil
 assert(reply.p==p and reply.ok,tostring(reply.result))
 return reply.result
end
task.spawn(function()
 local ok,err=xpcall(function()
  check("isolated mock universe",game.GameId==0)
  check("2 clients ready",waitFor(function()
   if #Players:GetPlayers()~=2 or not _G.FlyHighBalloonManager then return false end
   for _,p in Players:GetPlayers() do if not p.Character or not p.Character:FindFirstChild("HumanoidRootPart") or not p:GetAttribute("DataReady") then return false end end
   return true
  end,65))
  local ps=Players:GetPlayers() table.sort(ps,function(a,b)return a.UserId<b.UserId end)
  for _,p in ps do check("HUD ready "..p.Name,rpc(p,"Ready")) end
  local bm,tm,wm,om=_G.FlyHighBalloonManager,_G.FlyHighTetherManager,_G.FlyHighWeaponManager,_G.FlyHighObstacleManager
  om.Paused=true _G.FlyHighLargeChallengeManager.Paused=true
  local fd=bm.LaunchBalloon(ps,ps[1],workspace.FlyHighLobby.MatchmakingPods.Pod_C.FloorPad.Position,"Pod_C")
  check("duo launch",fd~=nil)
  check("boarding completes",waitFor(function()return not fd.boarding end,8))
  fd.root.Anchored=true fd.shieldTime=999 fd.autoGas=false
  fd.balloon:PivotTo(fd.balloon:GetPivot()+Vector3.new(0,125,0))
  fd.targetPosition=fd.root.Position fd.alignPos.Position=fd.targetPosition fd.boardingUntil=os.clock()+90
  local engineer=ps[2]
  for _,p in ps do rpc(p,"Pose",Vector3.new(0,4,8)) end
  task.wait(.6)
  local slot=tm.ropePools[fd.balloon].slots[1]
  check("rope fixture attached",tm.attachHandlers[fd.balloon](engineer)==true)
  tm.activeTethers[engineer.UserId].durability=30
  tm.CleanupPlayer(engineer) -- Production detach publishes station eligibility.
  task.wait(.5)
  local ropePrompt=fd.balloon.TetherStation.RepairRopePrompt
  report.ropeEvents={}
  ropePrompt.PromptButtonHoldBegan:Connect(function(p)table.insert(report.ropeEvents,{kind="Begin",player=p.Name,role=p:GetAttribute("CrewRole"),repairing=tm.ropeRepairs[p]~=nil})end)
  ropePrompt.PromptButtonHoldEnded:Connect(function(p)table.insert(report.ropeEvents,{kind="End",player=p.Name,repairing=tm.ropeRepairs[p]~=nil})end)
  ropePrompt.Triggered:Connect(function(p)table.insert(report.ropeEvents,{kind="Triggered",player=p.Name,value=slot.value.Value})end)
  local partial=rpc(engineer,"HoldPrompt",{prompt=ropePrompt,seconds=.3,pointer=true})
  report.snapshots.ropePartial=partial
  check("custom rope capsule appears",partial.customVisible and partial.style=="Custom",H:JSONEncode(partial))
  task.wait(.6)
  check("early rope hold does not fill",slot.value.Value==30 and not tm.ropeRepairs[engineer])
  local full=rpc(engineer,"HoldPrompt",{prompt=ropePrompt,seconds=ropePrompt.HoldDuration+.5,pointer=true})
  report.snapshots.ropeFull=full
  check("custom rope pointer hold reaches server",waitFor(function()return slot.value.Value==100 end,2),H:JSONEncode(full))
  check("rope role released",not tm.ropeRepairs[engineer] and not engineer:GetAttribute("RopeRepairing"))
  check("patch fixture tether attached",tm.attachHandlers[fd.balloon](engineer)==true)
  rpc(engineer,"Tether","Climb")
  check("patch fixture reaches catwalk",waitFor(function()local t=tm.activeTethers[engineer.UserId]return t and t.stage=="Catwalk"end,5))
  fd.shieldTime=0 fd.invulnTime=0
  check("patch fixture puncture",bm.ApplyPuncture(fd,"SelfShot")==true)
  fd.shieldTime=999
  local hole=fd.balloon.HoleSlots["Hole"..next(fd.holeSet)]
  local q=fd.root.CFrame:PointToObjectSpace(hole.Position)
  local flat=Vector3.new(q.X,0,q.Z).Unit*16
  rpc(engineer,"Pose",Vector3.new(flat.X,26,flat.Z)) task.wait(1)
  local patchPartial=rpc(engineer,"HoldPrompt",{prompt=hole.PatchPrompt,seconds=.3,pointer=true})
  report.snapshots.patchPartial=patchPartial
  check("custom patch capsule appears",patchPartial.customVisible,H:JSONEncode(patchPartial))
  task.wait(.5)
  check("early patch hold remains cancelled",fd.holes==1)
  local patchFull=rpc(engineer,"HoldPrompt",{prompt=hole.PatchPrompt,seconds=hole.PatchPrompt.HoldDuration+.5,pointer=true})
  report.snapshots.patchFull=patchFull
  check("custom patch pointer hold reaches server",waitFor(function()return fd.holes==0 end,2),H:JSONEncode(patchFull))
  rpc(engineer,"Tether","Descend")
  check("patch fixture descends",waitFor(function()return not tm.activeTethers[engineer.UserId]end,5))
  wm.SetupWeaponRacks(fd.balloon,false,true)
  for rackIndex,kind in {"Pistol","AK47"} do
   local rack=fd.balloon["WeaponRack"..rackIndex]
   local q=fd.root.CFrame:PointToObjectSpace(rack.Position)
   rpc(engineer,"Pose",Vector3.new(q.X*.65,4,q.Z*.65)) task.wait(.5)
   local pickup=rpc(engineer,"HoldPrompt",{prompt=rack.PickupPrompt,seconds=.6})
   check(kind.." custom pickup visible",pickup.customVisible,H:JSONEncode(pickup))
   check(kind.." native key pickup accepted",waitFor(function()return wm.held[engineer]~=nil end,2))
   local held=wm.held[engineer]
   check(kind.." correct magazine capacity",held.cfg.MagSize==(kind=="Pistol" and 8 or 30) and held.ammo==held.cfg.MagSize)
   task.wait(.4)
   local ui=rpc(engineer,"Snapshot") report.snapshots[kind.."Equipped"]=ui
   check(kind.." native hotbar hidden",ui.hotbar==false and ui.weapon==kind,H:JSONEncode(ui))
   check(kind.." infinite reserve label",ui.ammo==string.format("%d / ∞",held.cfg.MagSize),ui.ammo)
   local origin=held.tool.Handle.MuzzleAttachment.WorldPosition
   local target=Instance.new("Model") target.Name="_QA_CombatTarget"
   local part=Instance.new("Part") part.Name="Body" part.Size=Vector3.new(10,10,10) part.Anchored=true part.CanCollide=false
   local direction=if rackIndex==1 then Vector3.new(-1,0,0) else Vector3.new(1,0,0)
   part.Position=origin+direction*55 part.Parent=target target.PrimaryPart=part
   target:SetAttribute("IsObstacle",true) target:SetAttribute("Shootable",true) target:SetAttribute("Health",50)
   target.Parent=workspace.FlyHighObstacles
   table.insert(om.activeObstacles,{instance=target,velocity=Vector3.zero,shootable=true,effect="Fixture",born=os.clock(),activeAt=os.clock(),expires=os.clock()+60,minY=-10000,hit={},beams={},fragments={},animated={},spirals={},rails={},origin=target:GetPivot(),visualScale=1,fadeDone=true})
   task.wait(.2)
   for shot=1,2 do
    rpc(engineer,"Fire",{target=part.Position,model=target}) task.wait(held.cfg.FireRate+.15)
   end
   check(kind.." target destroyed by server",target.Parent==nil)
   check(kind.." two rounds spent",held.ammo==held.cfg.MagSize-2,held.ammo)
   local beforeReload=held.ammo rpc(engineer,"Reload") task.wait(.2)
   check(kind.." reload begins without instant refill",held.reloading and held.ammo==beforeReload)
   check(kind.." magazine refills to cap",waitFor(function()return not held.reloading and held.ammo==held.cfg.MagSize end,held.cfg.ReloadTime+2))
   local observer=rpc(ps[1],"Snapshot") report.snapshots[kind.."Observer"]=observer
   check(kind.." shots replicated to teammate",#observer.shots>=rackIndex*2,H:JSONEncode(observer.shots))
   check(kind.." teammate hotbar unaffected",observer.hotbar==true)
   rpc(engineer,"Drop")
   check(kind.." rack returned",waitFor(function()return not wm.held[engineer] and rack:GetAttribute("IsOccupied")end,2))
   task.wait(.3)
   check(kind.." hotbar restored",rpc(engineer,"Snapshot").hotbar==true)
  end
  local summits={} for _,p in ps do summits[p]=p:GetAttribute("SummitCount")or 0 end
  engineer.Character.Humanoid.Health=0
  check("dead teammate tracked",waitFor(function()return fd.dead[engineer]==true end,3))
  bm.EndFlight(fd,true)
  check("arrival blocks damage",fd.balloon:GetAttribute("ArrivalProtected")==true and bm.ApplyPuncture(fd)==false)
  check("arrival finishes and balloon departs",waitFor(function()return not fd.balloon.Parent end,25))
  for _,p in ps do
   check("summit credited once "..p.Name,p:GetAttribute("SummitCount")==summits[p]+1)
   check("alive at palace "..p.Name,p.Character and p.Character.Humanoid.Health>0 and p:GetAttribute("PalaceArrival")~=nil)
   local snap=rpc(p,"Snapshot") report.snapshots["arrival"..p.Name]=snap
   check("game client errors empty "..p.Name,#snap.gameErrors==0,H:JSONEncode(snap.gameErrors))
  end
  local observerArrival=rpc(ps[1],"Snapshot")
  check("fallen teammate revival state replicated",observerArrival.palace and observerArrival.crew[engineer.Name].revived==true)
  check("no server runtime errors",#report.errors==0,H:JSONEncode(report.errors))
 end,debug.traceback)
 report.success=ok report.failure=if ok then nil else err
 finish()
end)
