local STS=game:GetService("StudioTestService")if STS:GetTestArgs()~="FlyHighRoleQA"then return end
local P=game.Players local RS=game.ReplicatedStorage local Http=game:GetService("HttpService")local qa=RS.FlyHigh.Remotes.MultiplayerQAEvent
local report={checks={},logs={}}local pending={}local serial=0
game:GetService("LogService").MessageOut:Connect(function(m,k)if k==Enum.MessageType.MessageWarning or k==Enum.MessageType.MessageError then table.insert(report.logs,m)end end)
qa.OnServerEvent:Connect(function(p,kind,id,ok,v)local t=pending[id]if kind=="reply"and t and t.p==p then t.done=true t.ok=ok t.value=v end end)
local function waitFor(fn,t)local deadline=os.clock()+t repeat local v=fn()if v then return v end task.wait(.05)until os.clock()>deadline end
local function check(n,v,d)table.insert(report.checks,{name=n,passed=v==true,detail=d})assert(v,n)end
local function rpc(p,action,data)serial+=1 local id=tostring(serial)pending[id]={p=p}qa:FireClient(p,id,action,data or {})local t=pending[id]assert(waitFor(function()return t.done end,20),"client timeout")pending[id]=nil assert(t.ok,tostring(t.value))return t.value end
local ok,err=xpcall(function()
 local p=assert(waitFor(function()return P:GetPlayers()[1]end,60))
 assert(waitFor(function()return p:GetAttribute("DataReady")and p.Character and p.Character:FindFirstChild("HumanoidRootPart")end,40))rpc(p,"Ping")
 local bm=_G.FlyHighBalloonManager local wm=_G.FlyHighWeaponManager local tm=_G.FlyHighTetherManager local U=require(game.ServerScriptService.FlyHighServer.ServerUtils)
 _G.FlyHighObstacleManager.Paused=true _G.FlyHighLargeChallengeManager.Paused=true
 local f=assert(bm.LaunchBalloon({p},p,workspace.FlyHighLobby.MatchmakingPods.Pod_A.FloorPad.Position,"Pod_A"))
 assert(waitFor(function()return not f.boarding end,15))f.groundedSince=os.clock()+300
 local b=f.balloon local hum=p.Character.Humanoid local rack=b.WeaponRack1
 local function place(part,offset)U.Unseat(p)p.Character:PivotTo(part.CFrame*CFrame.new(offset or Vector3.new(2,3,0)))p.Character.HumanoidRootPart.AssemblyLinearVelocity=Vector3.zero task.wait(.3)end
 place(b.HelmSeat,Vector3.new(0,3,2))local first=rpc(p,"Prompt",{path="HelmSeat.HelmPrompt"})task.wait(.5)
 check("initial helm prompt seats free crew",f.pilot==p,first)
 rpc(p,"Action",{action="ReleaseHelm"})task.wait(4)
 place(rack,Vector3.new(3,1,0))
 local response=rpc(p,"Prompt",{path="WeaponRack1.PickupPrompt"})task.wait(.3)
 check("native E prompt equips pistol",wm.held[p]~=nil,response)
 check("gun is physically attached to hand",p.Character:FindFirstChild("RightGrip",true)~=nil)
 check("first person on equip",rpc(p,"Snapshot").cameraMode=="LockFirstPerson")
 check("gunner role replicated",p:GetAttribute("CrewRole")=="Gunner")
 check("held gun disappears from rack",rack.RackDisplay:FindFirstChild("PistolBody").Transparency==1)
 place(b.TetherStation)rpc(p,"Tether",{action="Attach"})task.wait(.2)
 check("gunner cannot attach rope through remote",tm.activeTethers[p.UserId]==nil)
 tm.ropePools[b].slots[1].value.Value=55
 check("gunner cannot repair detached rope",tm.BeginRopeRepair(p)==false)
 place(b.HelmSeat) b.HelmSeat:Sit(hum)task.wait(.4)
 check("gunner physical seat bypass rejected",f.pilot~=p and b.HelmSeat.Occupant~=hum)
 rpc(p,"Unequip")task.wait(.4)
 check("backpack unequip returns gun and frees role",not wm.held[p]and p:GetAttribute("CrewRole")==nil and rack:GetAttribute("IsOccupied"))
 check("camera restored after backpack unequip",rpc(p,"Snapshot").cameraMode=="Classic")
 place(rack,Vector3.new(3,1,0))local again=rpc(p,"Prompt",{path="WeaponRack1.PickupPrompt"})task.wait(.2)
 check("pistol can be equipped again",wm.held[p]~=nil,{prompt=again,role=U.Role(p),attribute=p:GetAttribute("CrewRole"),seat=hum.SeatPart and hum.SeatPart.Name,occupied=rack:GetAttribute("IsOccupied"),near=U.CrewNear(p,b,rack,10)~=nil,canStart=U.CanStartRole(p)})
 local ammo=wm.held[p].ammo rpc(p,"Shoot",{target=f.root.Position+Vector3.new(-100,3,0)})task.wait(.2)
 check("server fires equipped pistol",wm.held[p].ammo==ammo-1)
 rpc(p,"Drop")task.wait(.3)
 check("drop returns rack display",not wm.held[p]and rack.RackDisplay:FindFirstChild("PistolBody").Transparency<1)
 place(b.TetherStation)rpc(p,"Tether",{action="Attach"})task.wait(.2)
 check("free crew attaches engineer rope",tm.activeTethers[p.UserId]~=nil and p:GetAttribute("CrewRole")=="Engineer")
 place(rack,Vector3.new(3,1,0))check("engineer cannot take pistol server-side",not wm.TryEquip(p,b,rack)and not wm.held[p])
 place(b.HelmSeat)b.HelmSeat:Sit(hum)task.wait(.4)
 check("engineer physical seat bypass rejected",f.pilot~=p and b.HelmSeat.Occupant~=hum)
 place(b.TetherStation)rpc(p,"Tether",{action="Detach"})task.wait(.2)
 check("detach frees engineer role",not tm.activeTethers[p.UserId]and p:GetAttribute("CrewRole")==nil)
 check("detached rope repair acquires engineer role",tm.BeginRopeRepair(p)==true and p:GetAttribute("CrewRole")=="Engineer")
 place(rack,Vector3.new(3,1,0)) -- leaving station cancels repair; reacquire beside station for role check
 place(b.TetherStation)tm.BeginRopeRepair(p)
 check("rope repair blocks another role",not U.CanStartRole(p))
 tm.CancelRopeRepair(p)check("cancel repair releases role",U.CanStartRole(p)==true)
 place(b.HelmSeat,Vector3.new(0,3,2))local helmResponse=rpc(p,"Prompt",{path="HelmSeat.HelmPrompt"})task.wait(.3)
 check("free player can use native helm prompt",f.pilot==p and p:GetAttribute("CrewRole")=="Pilot",{prompt=helmResponse,sit=hum.Sit,role=U.Role(p),seat=hum.SeatPart and hum.SeatPart.Name,occupant=b.HelmSeat.Occupant~=nil})
 -- Bypass distance only in this synchronous test fixture to isolate role checks.
 local originalNear=U.CrewNear U.CrewNear=function()return f end
 check("pilot cannot equip weapon",not wm.TryEquip(p,b,rack)and not wm.held[p])
 check("pilot cannot attach rope",tm.attachHandlers[b](p)==false)
 check("pilot cannot repair rope",tm.BeginRopeRepair(p)==false)
 U.CrewNear=originalNear
 rpc(p,"Action",{action="ReleaseHelm"})task.wait(.9)
 check("release helm frees role",f.pilot==nil and p:GetAttribute("CrewRole")==nil)
 place(rack,Vector3.new(3,1,0))wm.SetupWeaponRacks(b,true)rpc(p,"Prompt",{path="WeaponRack1.PickupPrompt"})task.wait(.3)
 check("AK remains equipable",wm.held[p]and wm.held[p].tool.Name=="AK47")
 hum.Health=0 task.wait(.5)
 check("death clears role and weapon",not wm.held[p]and not tm.activeTethers[p.UserId]and p:GetAttribute("CrewRole")==nil)
 local snapshot=rpc(p,"Snapshot")check("client console clean",#snapshot.logs==0,snapshot.logs)
end,debug.traceback)
report.ok=ok and #report.logs==0 report.error=not ok and err or nil
STS:EndTest(Http:JSONEncode(report))
