local STS=game:GetService("StudioTestService")if STS:GetTestArgs()~="FlyHighWeaponBambooQA"then return end
local P=game.Players local RS=game.ReplicatedStorage local Http=game:GetService("HttpService")local qa=RS.FlyHigh.Remotes.MultiplayerQAEvent
local report={checks={},logs={}}local pending={}local serial=0
game:GetService("LogService").MessageOut:Connect(function(m,k)if k==Enum.MessageType.MessageWarning or k==Enum.MessageType.MessageError then table.insert(report.logs,m)end end)
qa.OnServerEvent:Connect(function(p,kind,id,ok,v)local t=pending[id]if kind=="reply"and t and t.p==p then t.done=true t.ok=ok t.value=v end end)
local function waitFor(fn,t)local deadline=os.clock()+t repeat local v=fn()if v then return v end task.wait(.05)until os.clock()>deadline end
local function check(n,v,d)table.insert(report.checks,{name=n,passed=v==true,detail=d})assert(v,n)end
local function rpc(p,action,data)serial+=1 local id=tostring(serial)pending[id]={p=p}qa:FireClient(p,id,action,data or {})local t=pending[id]assert(waitFor(function()return t.done end,20),"client timeout")pending[id]=nil assert(t.ok,tostring(t.value))return t.value end
local ok,err=xpcall(function()
 assert(waitFor(function()return #P:GetPlayers()==2 end,60))
 local crew=P:GetPlayers()table.sort(crew,function(a,b)return a.Name<b.Name end)
 for _,p in crew do assert(waitFor(function()return p:GetAttribute("DataReady")and p.Character and p.Character:FindFirstChild("HumanoidRootPart")end,40))rpc(p,"Ping")end
 local gunner,engineer=unpack(crew)
 local bm=_G.FlyHighBalloonManager local tm=_G.FlyHighTetherManager local wm=_G.FlyHighWeaponManager local U=require(game.ServerScriptService.FlyHighServer.ServerUtils)
 _G.FlyHighObstacleManager.Paused=true _G.FlyHighLargeChallengeManager.Paused=true
 local f=assert(bm.LaunchBalloon(crew,gunner,workspace.FlyHighLobby.MatchmakingPods.Pod_A.FloorPad.Position,"Pod_A"))
 assert(waitFor(function()return not f.boarding end,15))f.groundedSince=os.clock()+300
 local b=f.balloon
 local function place(p,part,offset)p.Character:PivotTo(part.CFrame*CFrame.new(offset or Vector3.new(3,2,0)))p.Character.HumanoidRootPart.AssemblyLinearVelocity=Vector3.zero task.wait(.3)end
 place(gunner,b.WeaponRack1)rpc(gunner,"Prompt",{path="WeaponRack1.PickupPrompt"})
 check("pistol equipped",wm.held[gunner]~=nil)
 check("weapon locks first person",rpc(gunner,"CameraState").mode=="LockFirstPerson")
 local target=Instance.new("Model")target.Name="WeaponFXTarget"target:SetAttribute("IsObstacle",true)target:SetAttribute("Shootable",true)target:SetAttribute("Health",1000)
 local part=Instance.new("Part")part.Anchored=true part.Size=Vector3.new(10,10,10)part.Position=f.root.Position+Vector3.new(-8,8,-100)part.Parent=target target.PrimaryPart=part target.Parent=workspace.FlyHighObstacles
 rpc(gunner,"BeginFxCapture")rpc(engineer,"BeginFxCapture")
 rpc(gunner,"AimShot",{target=part.Position})task.wait(.1)
 local own=rpc(gunner,"ReadFx")local peer=rpc(engineer,"ReadFx")
 check("accepted shot damages target",target:GetAttribute("Health")<1000)
 check("shooter sees tracer on screen",own.tracer and own.visible,own)
 check("shooter sees muzzle flash",own.flash)
 check("gunshot asset loads",own.loaded>0)
 check("gunshot plays with nonzero loudness",own.playing and own.loudness>0,own)
 check("teammate receives shot visuals",peer.tracer and peer.flash,peer)
 check("teammate hears spatial gunshot",peer.playing and peer.loudness>0)
 rpc(gunner,"Drop")task.wait(.5)local cam=rpc(gunner,"CameraState")
 check("drop restores Classic mode",cam.mode=="Classic")
 check("drop zooms camera out of first person",cam.distance>=6,cam)
 place(gunner,b.WeaponRack1)rpc(gunner,"Prompt",{path="WeaponRack1.PickupPrompt"})rpc(gunner,"Unequip")task.wait(.5)
 cam=rpc(gunner,"CameraState")check("backpack unequip also restores third person",cam.mode=="Classic"and cam.distance>=6,cam)
 place(gunner,b.WeaponRack1)assert(wm.TryEquip(gunner,b,b.WeaponRack1))rpc(gunner,"Drop")task.wait(.06)assert(wm.TryEquip(gunner,b,b.WeaponRack1))task.wait(.06)wm.CleanupPlayer(gunner)task.wait(.5)
 cam=rpc(gunner,"CameraState")check("rapid re-equip preserves normal zoom range",cam.mode=="Classic"and cam.distance>=6 and cam.minZoom==.5,cam)
 wm.SetupWeaponRacks(b,true)rpc(gunner,"Prompt",{path="WeaponRack1.PickupPrompt"})
 check("AK still equips",wm.held[gunner]and wm.held[gunner].tool.Name=="AK47")
 rpc(gunner,"BeginFxCapture")rpc(gunner,"AimShot",{target=part.Position})own=rpc(gunner,"ReadFx")
 check("AK has visual and audible feedback",own.tracer and own.playing and own.loudness>0)
 rpc(gunner,"Drop")target:Destroy()
 place(engineer,b.TetherStation,Vector3.new(2,3,0))rpc(engineer,"Prompt",{path="TetherStation.TetherPrompt"})task.wait(.35)rpc(engineer,"Tether",{action="Climb"})
 assert(waitFor(function()local t=tm.activeTethers[engineer.UserId]return t and t.stage=="Catwalk"and not t.winch end,4))
 check("winch lands on bamboo walkway",U.Alive(engineer,f)and not engineer.Character.HumanoidRootPart.Anchored)
 rpc(engineer,"WalkRing",{from=0,to=math.pi*2})
 local t=tm.activeTethers[engineer.UserId]
 check("full circle walk uses normal character physics",t and t.stage=="Catwalk"and not t.needsRescue and not t.hrp.Anchored)
 f.invulnTime=0 bm.ApplyPuncture(f,"SelfShot")rpc(engineer,"Prompt",{path="HoleSlots.Hole1.PatchPrompt"})
 check("repair still reachable from bamboo",f.holes==0)
 rpc(engineer,"Tether",{action="Descend"})
 check("descent still lands and detaches",waitFor(function()return not tm.activeTethers[engineer.UserId]end,4)~=nil and U.InBasket(engineer.Character.HumanoidRootPart,b.BasketFloor))
 task.wait(1)
 check("temporary flash and tracer cleaned",not workspace:FindFirstChild("BulletTracer")and not workspace:FindFirstChild("WeaponMuzzleFlash"))
 for _,p in crew do local snap=rpc(p,"Snapshot")check(p.Name.." clean console",#snap.logs==0,snap.logs)end

end,debug.traceback)
report.ok=ok and #report.logs==0 report.error=not ok and err or nil
STS:EndTest(Http:JSONEncode(report))
