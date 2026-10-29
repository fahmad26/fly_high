-- Studio-only regression driver; not shipped in the place.
local STS=game:GetService("StudioTestService")
if STS:GetTestArgs()~="FlyHighTetherMotionRepro"then return end
assert(game.GameId==0)
local Players=game.Players local RS=game.ReplicatedStorage
local qa=RS.FlyHigh.Remotes.MultiplayerQAEvent
local result={samples={},logs={}}local replies={}local id=0
game:GetService("LogService").MessageOut:Connect(function(m,k)if k==Enum.MessageType.MessageError or k==Enum.MessageType.MessageWarning then table.insert(result.logs,{message=m,kind=k.Name})end end)
qa.OnServerEvent:Connect(function(p,kind,key,ok,value)local q=replies[key]if kind=="reply"and q and q.p==p then q.done=true q.ok=ok q.value=value end end)
local function waitFor(fn,t)local stop=os.clock()+t repeat local v=fn()if v then return v end task.wait(.1)until os.clock()>stop end
local function rpc(p,action,data)
 id+=1 local key=tostring(id)replies[key]={p=p}qa:FireClient(p,key,action,data or {})local q=replies[key]
 assert(waitFor(function()return q.done end,20),"client timeout")replies[key]=nil assert(q.ok,tostring(q.value))return q.value
end
local ok,err=xpcall(function()
 assert(waitFor(function()return #Players:GetPlayers()==2 end,90),"two clients required")
 local roster=Players:GetPlayers()table.sort(roster,function(a,b)return a.Name<b.Name end)
 for _,p in roster do assert(waitFor(function()return p:GetAttribute("DataReady")and p.Character and p.Character:FindFirstChild("HumanoidRootPart")end,60))rpc(p,"Ping")end
 local bm=_G.FlyHighBalloonManager local tm=_G.FlyHighTetherManager
 _G.FlyHighObstacleManager.Paused=true _G.FlyHighLargeChallengeManager.Paused=true
 local f=assert(bm.LaunchBalloon(roster,roster[1],workspace.FlyHighLobby.MatchmakingPods.Pod_C.FloorPad.Position,"Pod_C"))
 local pos=Vector3.new(0,512.5,-56)f.balloon:PivotTo(CFrame.new(pos))f.targetPosition=pos f.alignPos.Position=pos f.boardingUntil=os.clock()+30
 for i,p in roster do p.Character:PivotTo(CFrame.new(pos+Vector3.new((i-1)*5,4,0)))end
 task.wait(.7)
 local p=roster[2]p.Character:PivotTo(f.balloon.TetherStation.CFrame*CFrame.new(2,3,0))task.wait(.3)
 rpc(p,"Tether",{action="Attach"})task.wait(.4)assert(tm.activeTethers[p.UserId],"attach failed")
 f.autoGas=true f.balloon:SetAttribute("AutoGas",true)f.windUntil=os.clock()+10 f.wind=Vector3.new(8,0,0)
 local begin=f.root.Position
 for i=1,16 do
  task.wait(.5)local r=p.Character.HumanoidRootPart local t=tm.activeTethers[p.UserId]
  local owner=r:GetNetworkOwner()
  table.insert(result.samples,{time=i*.5,balloon=tostring(f.root.Position),character=tostring(r.Position),relative=tostring(f.root.CFrame:PointToObjectSpace(r.Position)),anchored=r.Anchored,owner=owner and owner.Name or "server",attached=t~=nil,health=p.Character.Humanoid.Health})
 end
 result.balloonRise=f.root.Position.Y-begin.Y
 result.characterStillAttached=tm.activeTethers[p.UserId]~=nil
end,debug.traceback)
result.ok=ok result.error=not ok and err or nil
STS:EndTest(game:GetService("HttpService"):JSONEncode(result))
