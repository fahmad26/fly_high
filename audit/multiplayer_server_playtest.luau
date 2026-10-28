-- Native 3-client integration QA; temporary Studio-only driver, no cloud/purchases.
local STS=game:GetService("StudioTestService")
if STS:GetTestArgs()~="FlyHighMultiplayerQA"then return end
assert(game.GameId==0 and game.PlaceId==0,"Run this suite from an unpublished local file; cloud tests are deferred")
local Players=game:GetService("Players")local RS=game:GetService("ReplicatedStorage")
local Http=game:GetService("HttpService")local Run=game:GetService("RunService")
local remote=RS.FlyHigh.Remotes.MultiplayerQAEvent
local progress=Instance.new("StringValue")progress.Name="MultiplayerQAProgress"progress.Parent=game.ServerStorage
local logs={}game:GetService("LogService").MessageOut:Connect(function(message,kind)
 if kind==Enum.MessageType.MessageError or kind==Enum.MessageType.MessageWarning then table.insert(logs,{message=message,kind=kind.Name})end
end)
local report={checks={},metrics={},players={},serverLogs=logs,mode="3 native Studio clients",cloudTested=false,purchasesTested=false}
local pending={}local serial=0
remote.OnServerEvent:Connect(function(p,kind,token,ok,value)
 local r=pending[token]if kind=="reply"and r and r.player==p then r.done=true r.ok=ok r.value=value end
end)
local function phase(s)progress.Value=s print("[FlyHighMPQA] "..s)end
local function check(s,ok,detail)table.insert(report.checks,{name=s,passed=ok==true,detail=detail})assert(ok,s..": "..tostring(detail))end
local function waitFor(fn,seconds)
 local deadline=os.clock()+seconds repeat local value=fn()if value then return value end task.wait(.1)until os.clock()>deadline return nil
end
local function request(p,action,data)
 serial+=1 local token=tostring(serial)pending[token]={player=p}
 remote:FireClient(p,token,action,data or {})return token
end
local function collect(token,seconds)
 local r=pending[token]assert(waitFor(function()return r.done end,seconds or 25),"client response timeout "..r.player.Name)
 pending[token]=nil assert(r.ok,tostring(r.value))return r.value
end
local function rpc(p,action,data,seconds)return collect(request(p,action,data),seconds)end
local bm,tm,wm,U,Space,C,roster
local function hum(p)return p.Character and p.Character:FindFirstChildOfClass("Humanoid")end
local function position(p,cf)
 U.Unseat(p)local root=p.Character.HumanoidRootPart
 root.Anchored=false p.Character:PivotTo(cf)root.AssemblyLinearVelocity=Vector3.zero root:SetNetworkOwnershipAuto()
end
local function clear()
 for _,f in ipairs(table.clone(bm.activeFlights))do f.balloon:Destroy()end
 for i,p in ipairs(roster)do
  if p.Parent==Players then
   if not hum(p)or hum(p).Health<=0 then p:LoadCharacterAsync()end
   assert(waitFor(function()return hum(p)and hum(p).Health>0 and p.Character:FindFirstChild("HumanoidRootPart")end,15),"respawn failed")
   position(p,CFrame.new((i-2)*5,16,35))
  end
 end task.wait(.5)
end
local function move(f,pos)
 f.balloon:PivotTo(CFrame.new(pos))f.targetPosition=pos f.alignPos.Position=pos f.root.AssemblyLinearVelocity=Vector3.zero
 f.altitudeKm=(pos.Y-C.GROUND_Y)/C.STUDS_PER_KM f.hasLiftedOff=pos.Y>C.GROUND_Y+1 f.boardingUntil=os.clock()+8
 for i,p in ipairs(f.players)do if p.Parent==Players and hum(p).Health>0 then position(p,CFrame.new(pos+Vector3.new((i-2)*5,4,0)))end end
end
local function seat(f,p)position(p,f.balloon.HelmSeat.CFrame*CFrame.new(2,3,1))f.balloon.HelmSeat:Sit(hum(p))task.wait(.25)end
local started=os.clock()
local ok,err=xpcall(function()
 phase("Waiting for three native clients")
 check("three connected players",waitFor(function()return #Players:GetPlayers()==3 end,90)~=nil)
 roster=Players:GetPlayers()table.sort(roster,function(a,b)return a.Name<b.Name end)
 for _,p in ipairs(roster)do
  check(p.Name.." ready",waitFor(function()return p:GetAttribute("DataReady")and hum(p)and p.Character:FindFirstChild("HumanoidRootPart")end,60)~=nil)
  table.insert(report.players,rpc(p,"Ping"))
 end
 bm=_G.FlyHighBalloonManager tm=_G.FlyHighTetherManager wm=_G.FlyHighWeaponManager
 U=require(game.ServerScriptService.FlyHighServer.ServerUtils)Space=require(game.ServerScriptService.FlyHighServer.FlightSpace)
 C=require(RS.FlyHigh.Modules.FlyHighConfig)_G.FlyHighObstacleManager.Paused=true
 local a,b,c=roster[1],roster[2],roster[3]
 local pods=workspace.FlyHighLobby.MatchmakingPods
 phase("Lobby admission and master handoff")
 for i,p in ipairs(roster)do position(p,CFrame.new(pods.Pod_C.FloorPad.Position+Vector3.new((i-2)*4,4,0)))task.wait(.45)end
 check("three crew on dock",pods.Pod_C.Console.StatusGui.CountLabel.Text=="3 / 3 KRU")
 check("first arrival is master",a:GetAttribute("IsMaster")==true)
 position(a,CFrame.new(0,16,25))task.wait(.5)
 check("master transfers when leader steps away",b:GetAttribute("IsMaster")==true and a:GetAttribute("IsMaster")~=true)
 position(a,CFrame.new(pods.Pod_C.FloorPad.Position+Vector3.new(-4,4,0)))task.wait(.5)
 check("returning player keeps current master",b:GetAttribute("IsMaster")==true)
 position(b,CFrame.new(pods.Pod_C.FloorPad.Position+Vector3.new(-6,4,3)))task.wait(.6)
 report.metrics.startPrompt=rpc(b,"Start",{pod="Pod_C"})
 local f=waitFor(function()return bm.activeFlights[1]end,10)
 check("native prompt launches trio",f~=nil and #f.players==3)
 check("trio rope and repair configuration",f.balloon.TetherStation:GetAttribute("MaxRopes")==2 and f.balloon.HoleSlots.Hole1.PatchPrompt.HoldDuration==3)
 phase("Pilot release, auto gas and crew replication")
 seat(f,a)check("pilot seated",f.pilot==a)
 rpc(a,"Action",{action="AutoGas",value=true})task.wait(.3)
 rpc(a,"Action",{action="ReleaseHelm"})task.wait(.7)
 check("gas persists after pilot release",f.autoGas and not hum(a).SeatPart and f.pilot==nil)
 check("balloon ascends without seated pilot",f.root.Position.Y>C.GROUND_Y+1)
 position(b,f.balloon.WeaponRack1.CFrame*CFrame.new(3,2,0))task.wait(.4)
 report.metrics.firstPickup=rpc(b,"Prompt",{path="WeaponRack1.PickupPrompt"})
 check("second client picks weapon",waitFor(function()return wm.held[b]end,4)~=nil,{prompt=report.metrics.firstPickup,health=hum(b).Health,position=tostring(b.Character.HumanoidRootPart.Position),rack=tostring(f.balloon.WeaponRack1.Position),inFlight=b:GetAttribute("InFlight")})
 position(c,f.balloon.TetherStation.CFrame*CFrame.new(0,2,-2))task.wait(.3)
 rpc(c,"Tether",{action="Attach"})task.wait(.3)
 check("third client attaches tether",tm.activeTethers[c.UserId]~=nil)
 for _,p in ipairs(roster)do
  local s=rpc(p,"Snapshot")
  check(p.Name.." sees crew equipment",s.players[b.Name].tool and s.players[c.Name].rope,s)
 end
 phase("Self damage and three-player repair hold")
 f.invulnTime=0 rpc(b,"Shoot",{target=f.balloon.Envelope.Position})task.wait(.4)
 check("own shot creates hole and spends ammo",f.holes==1 and wm.held[b].ammo==7)
 rpc(c,"Tether",{action="Climb"})task.wait(1.9)
 check("engineer reaches catwalk",tm.activeTethers[c.UserId]and not tm.activeTethers[c.UserId].winch and not U.InBasket(c.Character.HumanoidRootPart,f.balloon.BasketFloor))
 local hole=f.balloon.HoleSlots.Hole1
 -- Hold position near the patch to isolate replicated repair timing from walking.
 position(c,hole.CFrame*CFrame.new(0,2,2))c.Character.HumanoidRootPart.Anchored=true task.wait(.2)
 rpc(c,"Repair",{hole=1,duration=3})task.wait(.3)
 c.Character.HumanoidRootPart.Anchored=false
 check("three-second repair accepted",f.holes==0)
 rpc(c,"Tether",{action="Descend"})task.wait(1.9)
 rpc(c,"Tether",{action="Detach"})rpc(b,"Drop")task.wait(.3)
 check("weapon and tether release",not tm.activeTethers[c.UserId]and not wm.held[b])
 phase("Clutch Save rescues all three clients")
 f.autoGas=false f.balloon:SetAttribute("AutoGas",false)
 move(f,Vector3.new(0,C.GROUND_Y+2000*C.STUDS_PER_KM,-56))
 for i=1,5 do f.invulnTime=0 bm.ApplyPuncture(f,"SelfShot")end
 _G.FlyHighDataManager.ModifyEmergencyKits(b,1)
 task.wait(.7)rpc(b,"Kit")task.wait(.4)
 check("clutch restores holes and shield",f.holes==0 and f.shieldTime>0)
 for _,p in ipairs(roster)do check(p.Name.." survives clutch",hum(p).Health>0)end
 phase("Ground timeout kills trio (accelerated clock)")
 move(f,Vector3.new(0,C.GROUND_Y,-56))f.groundedSince=os.clock()-59.7 f.nextGroundCheck=0
 check("ground timeout ends flight",waitFor(function()return f.isGameOver end,3)~=nil)
 for _,p in ipairs(roster)do check(p.Name.." dies on timeout",hum(p).Health<=0)end
 clear()
 phase("Cross-team dock occupancy")
 local teamA=assert(bm.LaunchBalloon({a,b},a,pods.Pod_A.FloorPad.Position,"Pod_A"))
 task.wait(.5)
 check("occupied A rejects third player summon",bm.LaunchBalloon({c},c,pods.Pod_A.FloorPad.Position,"Pod_A")==nil)
 move(teamA,Space.SpawnPosition(pods.Pod_E.FloorPad.Position))task.wait(.5)
 check("A balloon blocks E dock",pods.Pod_E:GetAttribute("LaunchBlocked")==true and bm.LaunchBalloon({c},c,pods.Pod_E.FloorPad.Position,"Pod_E")==nil)
 check("A dock clears when balloon leaves",pods.Pod_A:GetAttribute("LaunchBlocked")==false)
 move(teamA,Vector3.new(-52,160,-33))
 local teamB=assert(bm.LaunchBalloon({c},c,pods.Pod_E.FloorPad.Position,"Pod_E"))
 check("second team launches after clearance",#bm.activeFlights==2)
 phase("Native two-team collision under simultaneous client controls")
 move(teamA,Vector3.new(-40,180,-56))move(teamB,Vector3.new(40,180,-56))
 seat(teamA,a)seat(teamB,c)
 local one=request(a,"Drive",{x=1,gas=true,duration=8})local two=request(c,"Drive",{x=-1,gas=true,duration=8})
 local minDistance=math.huge local untilTime=os.clock()+8.2
 repeat
  local d=teamA.root.Position-teamB.root.Position
  minDistance=math.min(minDistance,Vector2.new(d.X,d.Z).Magnitude)
  task.wait(.05)
 until os.clock()>=untilTime
 collect(one)collect(two)
 report.metrics.minimumCollisionDistance=minDistance
 check("both real teams receive one collision hole",teamA.holes==1 and teamB.holes==1,{a=teamA.holes,b=teamB.holes})
 check("collision stays separated",minDistance>=58,minDistance)
 check("server retains ownership",teamA.root:GetNetworkOwner()==nil and teamB.root:GetNetworkOwner()==nil)
 phase("Cross-team prompt and shot security")
 for _,p in ipairs({a,b})do local snap=rpc(p,"Snapshot",{foreign=teamB.balloon.Name})check(p.Name.." foreign prompts hidden",snap.enemyHelm==false and snap.enemyRack==false)end
 local snap=rpc(c,"Snapshot",{foreign=teamA.balloon.Name})check("third client foreign prompts hidden",snap.enemyHelm==false and snap.enemyRack==false)
 U.Unseat(c)position(c,teamA.balloon.WeaponRack2.CFrame*CFrame.new(-3,2,0))task.wait(.3)
 rpc(c,"Prompt",{model=teamA.balloon.Name,path="WeaponRack2.PickupPrompt",force=true})task.wait(.3)
 check("foreign pickup denied on server",not wm.held[c])
 rpc(c,"Tether",{action="Attach"})task.wait(.3)check("foreign tether denied",not tm.activeTethers[c.UserId])
 position(c,teamB.balloon.WeaponRack1.CFrame*CFrame.new(3,2,0))task.wait(.3)
 rpc(c,"Prompt",{path="WeaponRack1.PickupPrompt"})task.wait(.3)check("own team weapon pickup allowed",wm.held[c]~=nil,{health=hum(c).Health,inFlight=c:GetAttribute("InFlight"),distance=(c.Character.HumanoidRootPart.Position-teamB.balloon.WeaponRack1.Position).Magnitude})
 local before=teamA.holes rpc(c,"Shoot",{target=teamA.balloon.Envelope.Position})task.wait(.4)
 check("enemy balloon ignores bullets",teamA.holes==before)
 rpc(c,"Drop")position(c,teamB.balloon.TetherStation.CFrame*CFrame.new(0,2,-2))task.wait(.3)
 rpc(c,"Tether",{action="Attach"})task.wait(.3)
 check("solo tether attached before disconnect",tm.activeTethers[c.UserId]~=nil)
 for _,p in ipairs(roster)do local data=rpc(p,"Snapshot")report.players[_].logs=data.logs end
 phase("Third client disconnect and flight cleanup")
 local leave=rpc(c,"Leave")check("native client can disconnect",leave.canLeave)
 check("player leaves server",waitFor(function()return c.Parent~=Players end,10)~=nil)
 check("departed flight cleaned",waitFor(function()return not teamB.balloon.Parent end,8)~=nil)
 check("departed equipment cleaned",not tm.activeTethers[c.UserId]and not wm.held[c])
 check("remaining team continues",teamA.balloon.Parent~=nil and not teamA.isGameOver and hum(a).Health>0 and hum(b).Health>0)
end,debug.traceback)
for i,p in ipairs(roster or {})do
 if p.Parent==Players then
  local received,snapshot=pcall(rpc,p,"Snapshot",{},4)
  if received then report.players[i].logs=snapshot.logs end
 end
end
local clientErrors=0 for _,p in ipairs(report.players)do clientErrors+=#(p.logs or {})end
report.clientLogCount=clientErrors
report.ok=ok and clientErrors==0 and #logs==0
report.error=not ok and err or ((clientErrors>0 or #logs>0)and "Console errors or warnings captured"or nil)
report.duration=os.clock()-started
phase(ok and "COMPLETE"or("FAILED: "..tostring(err)))
STS:EndTest(Http:JSONEncode(report))
