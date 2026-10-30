local STS=game:GetService("StudioTestService")if STS:GetTestArgs()~="FlyHighCrewQA"then return end
local P=game.Players local RS=game.ReplicatedStorage local Http=game:GetService("HttpService")local qa=RS.FlyHigh.Remotes.MultiplayerQAEvent
local report={checks={},logs={}}local pending={}local serial=0
game:GetService("LogService").MessageOut:Connect(function(m,k)if k==Enum.MessageType.MessageWarning or k==Enum.MessageType.MessageError then table.insert(report.logs,m)end end)
qa.OnServerEvent:Connect(function(p,kind,id,ok,v)local t=pending[id]if kind=="reply"and t and t.p==p then t.done=true t.ok=ok t.value=v end end)
local function waitFor(fn,t)local deadline=os.clock()+t repeat local v=fn()if v then return v end task.wait(.05)until os.clock()>deadline end
local function check(n,v,d)table.insert(report.checks,{name=n,passed=v==true,detail=d})assert(v,n)end
local function rpc(p,action,data)serial+=1 local id=tostring(serial)pending[id]={p=p}qa:FireClient(p,id,action,data or {})local t=pending[id]assert(waitFor(function()return t.done end,20),"client timeout")pending[id]=nil assert(t.ok,tostring(t.value))return t.value end
local roster
local ok,err=xpcall(function()
 assert(waitFor(function()return #P:GetPlayers()==4 end,90))roster=P:GetPlayers()table.sort(roster,function(a,b)return a.Name<b.Name end)
 for _,p in roster do assert(waitFor(function()return p:GetAttribute("DataReady")and p.Character and p.Character:FindFirstChild("HumanoidRootPart")end,40))rpc(p,"Ping")end
 local bm=_G.FlyHighBalloonManager local wm=_G.FlyHighWeaponManager local U=require(game.ServerScriptService.FlyHighServer.ServerUtils)
 _G.FlyHighObstacleManager.Paused=true _G.FlyHighLargeChallengeManager.Paused=true
 local a,b,c,d=unpack(roster)local pod=workspace.FlyHighLobby.MatchmakingPods.Pod_A
 local function place(p,cf)U.Unseat(p)p.Character:PivotTo(cf)p.Character.HumanoidRootPart.AssemblyLinearVelocity=Vector3.zero end
 for i,p in {a,b,c}do place(p,pod.FloorPad.CFrame*CFrame.new(i-2,4,0))task.wait(.3)end
 place(d,pod.FloorPad.CFrame*CFrame.new(0,4,0))task.wait(.5)
 check("fourth player cannot join full dock",d:GetAttribute("CurrentPod")~="Pod_A")
 local q=pod.FloorPad.CFrame:PointToObjectSpace(d.Character.HumanoidRootPart.Position)
 check("fourth player physically leaves dock",math.abs(q.X)>pod.FloorPad.Size.X/2 or math.abs(q.Z)>pod.FloorPad.Size.Z/2)
 local f=assert(bm.LaunchBalloon({a,b,c},a,pod.FloorPad.Position,"Pod_A"))
 check("boarding holds players before replica acknowledgement",f.boarding~=nil and a.Character.HumanoidRootPart.Anchored)
 check("forged boarding acknowledgement denied",bm.FlightAction(a,"BoardReady","wrong-token")==false)
 check("all clients acknowledge replicated balloon",waitFor(function()return f.boarding==nil end,15)~=nil)
 for _,p in {a,b,c}do check(p.Name.." lands inside basket",U.InBasket(p.Character.HumanoidRootPart,f.balloon.BasketFloor)and not p.Character.HumanoidRootPart.Anchored)end
 local foreign=assert(bm.LaunchBalloon({d},d,workspace.FlyHighLobby.MatchmakingPods.Pod_E.FloorPad.Position,"Pod_E"))assert(waitFor(function()return not foreign.boarding end,15))
 place(d,f.root.CFrame*CFrame.new(0,5,5))task.wait(.4)
 check("foreign crew cannot ride other balloon",U.InBasket(d.Character.HumanoidRootPart,foreign.balloon.BasketFloor))
 check("foreign weapon interaction rejected",not wm.held[d])
 place(a,f.balloon.WeaponRack1.CFrame*CFrame.new(3,3,0))task.wait(.3)rpc(a,"Prompt",{path="WeaponRack1.PickupPrompt"})task.wait(.3)
 check("handgun equips for own crew",wm.held[a]~=nil)
 check("equipped weapon locks first person",rpc(a,"Snapshot").cameraMode=="LockFirstPerson")
 local target=Instance.new("Model")target.Name="AutoAimQA"target:SetAttribute("IsObstacle",true)target:SetAttribute("Shootable",true)target:SetAttribute("Health",1000)
 local part=Instance.new("Part")part.Size=Vector3.new(10,10,10)part.Anchored=true part.Position=f.root.Position+Vector3.new(-12,8,-100)part.Parent=target target.PrimaryPart=part target.Parent=workspace.FlyHighObstacles
 rpc(a,"AimShot",{target=part.Position})task.wait(.2)check("desktop uses centred auto aim",target:GetAttribute("Health")<1000,target:GetAttribute("Health"))target:Destroy()
 rpc(a,"Drop")task.wait(.3)check("drop restores normal camera",rpc(a,"Snapshot").cameraMode=="Classic")
 wm.SetupWeaponRacks(f.balloon,true)rpc(a,"Prompt",{path="WeaponRack1.PickupPrompt"})task.wait(.2)
 check("AK47 model equips in first person",wm.held[a]and wm.held[a].tool.Name=="AK47"and rpc(a,"Snapshot").cameraMode=="LockFirstPerson")rpc(a,"Drop")task.wait(.2)
 place(a,f.balloon.TetherStation.CFrame*CFrame.new(2,3,0))task.wait(.3)rpc(a,"Tether",{action="Attach"})task.wait(.3)rpc(a,"Tether",{action="Climb"})
 local tm=_G.FlyHighTetherManager assert(waitFor(function()local t=tm.activeTethers[a.UserId]return t and t.stage=="Catwalk"and not t.winch end,5))
 local landing=f.root.CFrame:PointToObjectSpace(a.Character.HumanoidRootPart.Position)
 check("winch lands on smaller service deck",math.abs(landing.Z+16)<1)
 for i=1,5 do f.invulnTime=0 bm.ApplyPuncture(f,"SelfShot")if i==1 then
  local h=f.balloon.HoleSlots.Hole1 check("puncture reveals cloth frays",h.FrayedCloth.Transparency==0)
  rpc(a,"Prompt",{path="HoleSlots.Hole1.PatchPrompt"})task.wait(.2)check("cloth hole reachable from smaller deck",f.holes==0)
  check("repair hides cloth frays",h.FrayedCloth.Transparency==1)break
 end end
 rpc(a,"Tether",{action="Descend"})check("compact deck descent releases rope",waitFor(function()return not tm.activeTethers[a.UserId]end,5)~=nil)
 local deck=f.balloon.EnvelopeRing.Walkway0 check("service deck narrowed",deck.Size.Z==3 and deck.Size.Y<.6)
 for _,p in roster do local s=rpc(p,"Snapshot")check(p.Name.." clean client console",#s.logs==0,s.logs)end
end,debug.traceback)
report.ok=ok and #report.logs==0 report.error=not ok and err or nil
STS:EndTest(Http:JSONEncode(report))
