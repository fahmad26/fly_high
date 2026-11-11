local S=game:GetService("StudioTestService") if S:GetTestArgs()~="DriverKeyQA"then return end
local H=game:GetService("HttpService")local R=game.ReplicatedStorage.FlyHigh.Remotes local q=R.FullJourneyQAEvent
local report={checks={},errors={},fixture="Solo native client; manager launch and boarding; natural climb in safe zone; driver pose and virtual keys; no full journey",startedUTC=DateTime.now():ToIsoDate()}
game:GetService("LogService").MessageOut:Connect(function(m,t)if t==Enum.MessageType.MessageError then table.insert(report.errors,m)end end)
local id=0 local replies={}q.OnServerEvent:Connect(function(p,n,ok,data)replies[n]={ok=ok,data=data}end)
local function waitFor(f,t)local endAt=os.clock()+t repeat local r=f()if r then return r end task.wait(.05)until os.clock()>endAt end
local function check(n,v,d)table.insert(report.checks,{name=n,pass=v==true,detail=d})assert(v,n)end
local function rpc(p,a,d)id+=1 local n=id q:FireClient(p,n,a,d or {})assert(waitFor(function()return replies[n]end,12),"RPC "..a)local r=replies[n]replies[n]=nil assert(r.ok,tostring(r.data))return r.data end
task.delay(80,function()report.timeout=true S:EndTest(H:JSONEncode(report))end)
task.spawn(function()local ok,err=xpcall(function()
 local p=waitFor(function()local p=game.Players:GetPlayers()[1]return p and p:GetAttribute("DataReady")and p.Character and p.Character:FindFirstChild("HumanoidRootPart")and _G.FlyHighBalloonManager and p end,25)check("player ready",p~=nil)
 rpc(p,"Ready")
 local bm=_G.FlyHighBalloonManager local tm=_G.FlyHighTetherManager local U=require(game.ServerScriptService.FlyHighServer.ServerUtils)
 local fd=bm.LaunchBalloon({p},p,workspace.FlyHighLobby.MatchmakingPods.Pod_C.FloorPad.Position,"Pod_C")
 for player,item in pairs(fd.boarding)do bm.FlightAction(player,"BoardReady",item.token)end check("boarding",waitFor(function()return not fd.boarding end,8)~=nil)
 rpc(p,"Pose",{relative=CFrame.new(0,4,0),balloon=fd.balloon})
 fd.balloon.HelmSeat:Sit(p.Character.Humanoid)check("pilot acquired",waitFor(function()return fd.pilot==p end,3)~=nil)
 rpc(p,"Action",{action="AutoGas",value=true})rpc(p,"Lane",{target=fd.root.Position+Vector3.new(20,0,0)})task.wait(.5)
 check("virtual WASD held as pilot",rpc(p,"PhysicalState").keysDown==true)
 rpc(p,"Action",{action="ReleaseHelm"})check("pilot released",waitFor(function()return not fd.pilot end,3)~=nil)task.wait(.3)
 check("driver released WASD on role exit",rpc(p,"PhysicalState").keysDown==false)
 rpc(p,"Pose",{relative=CFrame.new(0,4,6),balloon=fd.balloon})task.wait(.2)
 check("attach at station",tm.attachHandlers[fd.balloon](p)==true)
 rpc(p,"Tether",{action="Climb"})
 check("solo climbs after pilot release",waitFor(function()local t=tm.activeTethers[p.UserId]return t and t.stage=="Catwalk"end,6)~=nil)
 rpc(p,"Tether",{action="Descend"})
 check("descent and detach",waitFor(function()return not tm.activeTethers[p.UserId]end,6)~=nil)
 local snap=rpc(p,"Snapshot")report.clientLogs=snap.logs check("clean client warnings and errors",#snap.logs==0,snap.logs)
 check("no server errors",#report.errors==0)
end,debug.traceback)report.success=ok report.failure=not ok and err or nil report.finishedUTC=DateTime.now():ToIsoDate()S:EndTest(H:JSONEncode(report))end)
