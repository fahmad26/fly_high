local S=game:GetService("StudioTestService")if S:GetTestArgs()~="DockAccessQA"then return end local H=game:GetService("HttpService")local event=game.ReplicatedStorage.__AccessQA local report={checks={},errors={},walks={},startedUTC=DateTime.now():ToIsoDate(),fixture="One native client; pose reset at spawn between routes; client Humanoid Move toward waypoints; no jumping/teleport along paths; no launch"}local replies={}local serial=0
event.OnServerEvent:Connect(function(p,id,ok,v)replies[id]={ok=ok,value=v}end)
game:GetService("LogService").MessageOut:Connect(function(m,t)if t==Enum.MessageType.MessageError then table.insert(report.errors,m)end end)
local function waitFor(f,t)local stop=os.clock()+t repeat local v=f()if v then return v end task.wait(.05)until os.clock()>stop end
local function rpc(p,a,v)serial+=1 local id=serial event:FireClient(p,id,a,v)local r=assert(waitFor(function()return replies[id]end,22),"RPC timeout")replies[id]=nil assert(r.ok,r.value)return r.value end
local function check(n,v,d)table.insert(report.checks,{name=n,pass=v==true,detail=d})assert(v,n)end
task.delay(230,function()report.timeout=true S:EndTest(H:JSONEncode(report))end)
task.spawn(function()local ok,err=xpcall(function()
local p=assert(waitFor(function()local p=game.Players:GetPlayers()[1]return p and p.Character and p.Character:FindFirstChild("HumanoidRootPart")and p:GetAttribute("DataReady")and p end,25))
task.wait(2)
for i,name in {"Pod_A","Pod_B","Pod_C","Pod_D","Pod_E"}do local route={pod=name,waypoints={}}table.insert(report.walks,route)
rpc(p,"Pose",Vector3.new(0,14,35))task.wait(.35)
table.insert(route.waypoints,rpc(p,"Walk",Vector3.new(0,10,20)))
table.insert(route.waypoints,rpc(p,"Walk",Vector3.new(0,10,-55)))
local angle=(i-3)*45 local count=math.max(1,math.ceil(math.abs(angle)/9))
for j=1,count do local a=math.rad(angle*j/count)table.insert(route.waypoints,rpc(p,"Walk",Vector3.new(math.sin(a)*70,10,15-math.cos(a)*70)))end
local pad=workspace.FlyHighLobby.MatchmakingPods[name].FloorPad
table.insert(route.waypoints,rpc(p,"Walk",pad.Position))
check("walk to "..name.." joins correct dock",waitFor(function()return p:GetAttribute("CurrentPod")==name end,3)~=nil,p:GetAttribute("CurrentPod"))
check("alive after "..name,p.Character.Humanoid.Health>0)
end
check("no server errors",#report.errors==0)
end,debug.traceback)report.success=ok report.failure=not ok and err or nil report.finishedUTC=DateTime.now():ToIsoDate()S:EndTest(H:JSONEncode(report))end)
