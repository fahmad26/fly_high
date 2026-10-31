 assert(waitFor(function()return #P:GetPlayers()==3 end,60))
 local crew=P:GetPlayers()table.sort(crew,function(a,b)return a.Name<b.Name end)
 for _,p in crew do assert(waitFor(function()return p:GetAttribute("DataReady")and p.Character and p.Character:FindFirstChild("HumanoidRootPart")end,40))rpc(p,"Ping")end
 local a,b,c=unpack(crew)
 local bm=_G.FlyHighBalloonManager local tm=_G.FlyHighTetherManager local U=require(game.ServerScriptService.FlyHighServer.ServerUtils)
 _G.FlyHighObstacleManager.Paused=true _G.FlyHighLargeChallengeManager.Paused=true
 local f=assert(bm.LaunchBalloon(crew,a,workspace.FlyHighLobby.MatchmakingPods.Pod_C.FloorPad.Position,"Pod_C"))
 assert(waitFor(function()return not f.boarding end,15))f.groundedSince=os.clock()+300
 local base=Vector3.new(0,512.5,0)f.balloon:PivotTo(CFrame.new(base))f.targetPosition=base f.alignPos.Position=base f.altitudeKm=2000
 local function place(p,offset)p.Character:PivotTo(f.root.CFrame*CFrame.new(offset))p.Character.HumanoidRootPart.AssemblyLinearVelocity=Vector3.zero task.wait(.2)end
 local function attach(p)place(p,Vector3.new(0,4,10))rpc(p,"Tether",{action="Attach"})assert(waitFor(function()return tm.activeTethers[p.UserId]end,3))task.wait(.35)return tm.activeTethers[p.UserId]end
 local prow=0 for _,o in f.balloon:GetDescendants()do if o.Name=="BoatProw"then prow+=1 end end
 check("live SkyKoi has no oversized prow boards",f.balloon:GetAttribute("BalloonThemeId")=="C"and prow==0)
 place(c,Vector3.new(0,4,0))local t=attach(a)place(a,Vector3.new(18,4,0))
 assert(t.stage=="Hanging")local root=a.Character.HumanoidRootPart local hum=a.Character.Humanoid
 local start=root.Position local velocityBefore=root.AssemblyLinearVelocity
 t.durability=.01
 assert(waitFor(function()return a.Character:GetAttribute("FatalRopeFall")==true end,1))
 check("rope removed as it breaks",not tm.activeTethers[a.UserId]and not root:FindFirstChild("SafetyRope"))
 check("broken rope releases anchor",not root.Anchored)
 check("character remains alive during ejection",hum.Health>0)
 check("ejection has outward physical velocity",Vector2.new(root.AssemblyLinearVelocity.X,root.AssemblyLinearVelocity.Z).Magnitude>30,tostring(root.AssemblyLinearVelocity))
 check("fall is server owned",root:GetNetworkOwner()==nil)
 check("fatal fall blocks gameplay roles",not U.Alive(a,f)and not U.CanStartRole(a))
 check("fatal fall cannot be rescued",tm.PullCrew(c)==false)
 task.wait(.25)
 check("avatar travels away before dying",(root.Position-start).Magnitude>5 and hum.Health>0)
 check("avatar falls below start",root.Position.Y<start.Y)
 task.wait(.12)check("ejected body regains world collision",root.CollisionGroup~="FlyHighWinching")
 check("broken rope durability persists",t.slot.value.Value==0 and t.slot.value:GetAttribute("HolderUserId")==0)
 check("death follows fall delay",waitFor(function()return hum.Health<=0 end,2)~=nil)
 check("unbroken team continues flying",not f.isGameOver and U.Alive(c,f))
 local tb=attach(b)place(b,Vector3.new(18,4,0))place(c,Vector3.new(0,4,0))
 assert(tm.PullCrew(c))task.wait(.2)check("rescue started for second victim",tb.stage=="Rescuing")
 local pose=tb.hrp.Position tb.durability=.01
 assert(waitFor(function()return b.Character:GetAttribute("FatalRopeFall")==true end,1))
 check("break cancels helper role",not tm.rescuers[c]and c:GetAttribute("CrewRole")==nil)
 check("break during rescue releases physics",not tb.hrp.Anchored and not tm.activeTethers[b.UserId])
 check("rescue break does not rewind to winch origin",(tb.hrp.Position-pose).Magnitude<8)
 check("rescue victim dies after delay",waitFor(function()return b.Character.Humanoid.Health<=0 end,2)~=nil)
 -- Repaired rope and a roof fall exercise the other active tether location.
 place(c,Vector3.new(0,4,10))local pool=tm.ropePools[f.balloon]
 assert(tm.BeginRopeRepair(c))task.wait(4.1)assert(tm.FinishRopeRepair(c))
 local tc=attach(c)rpc(c,"Tether",{action="Climb"})assert(waitFor(function()return tc.stage=="Catwalk"end,4))
 tc.durability=.01 assert(waitFor(function()return c.Character:GetAttribute("FatalRopeFall")==true end,1))
 check("roof break ejects instead of immediate death",c.Character.Humanoid.Health>0 and not tc.hrp.Anchored)
 local oldCharacter=c.Character c:LoadCharacterAsync()
 assert(waitFor(function()return c.Character and c.Character~=oldCharacter and c.Character:FindFirstChild("Humanoid")end,10))
 task.wait(1.5)
 check("old death timer cannot kill respawn",c.Character.Humanoid.Health>0 and c.Character:GetAttribute("FatalRopeFall")~=true)
 for _,p in crew do local snap=rpc(p,"Snapshot")check(p.Name.." clean client console",#snap.logs==0,snap.logs)end
