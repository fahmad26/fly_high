local STS=game:GetService("StudioTestService")
if STS:GetTestArgs()~="FlightFixQA"then return end
local H=game:GetService("HttpService")
local report={run="flight-fixes-2026-11-11",startedUTC=DateTime.now():ToIsoDate(),fixture="5 clients; manager launch/boarding calls, altitude warps, shield during motion; not a full journey",checks={},errors={}}
local Log=game:GetService("LogService"):GetLogHistory()
local conn=game:GetService("LogService").MessageOut:Connect(function(m,t)if t==Enum.MessageType.MessageError then table.insert(report.errors,m)end end)
local function check(n,v,detail)table.insert(report.checks,{name=n,pass=v==true,detail=detail}) print("FLIGHT_QA "..n.." "..tostring(v))assert(v,n)end
local function waitFor(fn,timeout)local t=os.clock()repeat if fn()then return true end task.wait(.1)until os.clock()-t>timeout return false end
task.delay(240,function()report.timeout=true STS:EndTest(H:JSONEncode(report))end)
task.spawn(function()
local ok,err=xpcall(function()
 local Players=game:GetService("Players")
 check("5 players ready",waitFor(function()if #Players:GetPlayers()~=5 then return false end for _,p in Players:GetPlayers()do if not p:GetAttribute("DataReady")or not p.Character or not p.Character:FindFirstChild("HumanoidRootPart")then return false end end return _G.FlyHighBalloonManager~=nil end,90))
 local people=Players:GetPlayers() table.sort(people,function(a,b)return a.UserId<b.UserId end)
 local bm=_G.FlyHighBalloonManager local space=require(game.ServerScriptService.FlyHighServer.FlightSpace)
 local config=require(game.ReplicatedStorage.FlyHigh.Modules.FlyHighConfig)
 local groups={{people[1]},{people[2]},{people[3]},{people[4]},{people[5]}}
 local flights={}
 for i,name in ipairs({"Pod_A","Pod_B","Pod_C","Pod_D","Pod_E"})do
  local pad=workspace.FlyHighLobby.MatchmakingPods[name].FloorPad
  local fd=bm.LaunchBalloon(groups[i],groups[i][1],pad.Position,name)
  check("independent dock "..name,fd~=nil)
  flights[i]=fd fd.shieldTime=999
  for p,item in pairs(fd.boarding)do bm.FlightAction(p,"BoardReady",item.token)end
 end
 task.wait(1)
 for i,fd in ipairs(flights)do check("same dock blocked "..i,space.Blocker(fd.root.Position,bm.activeFlights)==fd)end
 for _,f in flights do bm.EndFlight(f,false)end
 task.wait(5)
 for _,p in people do p:LoadCharacterAsync()end
 task.wait(1)
 flights={}
 local function launch(group,name)
  local f=bm.LaunchBalloon(group,group[1],workspace.FlyHighLobby.MatchmakingPods[name].FloorPad.Position,name)
  check("launch fixture "..name,f~=nil)
  f.shieldTime=999
  for p,item in pairs(f.boarding)do bm.FlightAction(p,"BoardReady",item.token)end
  task.wait(.5)
  return f
 end
 flights[1]=launch({people[1],people[2],people[3]},"Pod_A")
 flights[2]=launch({people[4],people[5]},"Pod_B")
 local function warp(fd,km)
  local cf=CFrame.new(fd.root.Position.X,config.GROUND_Y+km*config.STUDS_PER_KM,fd.root.Position.Z)
  local delta=cf.Position-fd.root.Position
  fd.balloon:PivotTo(cf)fd.targetPosition=cf.Position fd.alignPos.Position=cf.Position fd.root.AssemblyLinearVelocity=Vector3.zero
  for _,p in fd.players do if not fd.dead[p]then p.Character:PivotTo(p.Character:GetPivot()+delta)p.Character.HumanoidRootPart.AssemblyLinearVelocity=Vector3.zero end end
  fd.altitudeKm=km task.wait(.25)
 end
 local fd=flights[1]
 warp(fd,200)people[1].Character.Humanoid.Health=0 task.wait(.15)
 warp(fd,1000)warp(fd,700)people[2].Character.Humanoid.Health=0 task.wait(.15)
 warp(fd,4000)people[3].Character.Humanoid.Health=0 task.wait(.25)
 check("personal altitude frozen after death",fd.personalBest[people[1]]<205 and fd.personalBest[people[2]]>990 and fd.personalBest[people[2]]<1005 and fd.personalBest[people[3]]>3990,H:JSONEncode({fd.personalBest[people[1]],fd.personalBest[people[2]],fd.personalBest[people[3]]}))
 check("all-dead crew fails",fd.isGameOver and not fd.isVictory)
 task.wait(5)
 for i=1,3 do people[i]:LoadCharacterAsync()end
 task.wait(.5)
 for i=1,3 do flights[i+2]=launch({people[i]},({"Pod_C","Pod_D","Pod_E"})[i])end
 local winner=flights[2]
 warp(winner,200)people[4].Character.Humanoid.Health=0 task.wait(.15)
 local before={}for i=1,5 do before[people[i]]=people[i]:GetAttribute("SummitCount")end
 -- Measure steady climb at production speed before entering the arrival queue.
 local moving=flights[3]moving.autoGas=true local backwards=0 local previous=moving.root.Position.Y local t=os.clock()
 while os.clock()-t<2 do game:GetService("RunService").Heartbeat:Wait()local y=moving.root.Position.Y if y<previous-.05 then backwards+=1 end previous=y end
 check("steady climb has no backwards jumps",backwards==0,backwards)
 for i=2,5 do bm.EndFlight(flights[i],true)end
 check("one arrival worker",require(game.ServerScriptService.FlyHighServer.PalaceArrival).busy)
 local queued=0 for i=2,5 do local f=flights[i] if f.balloon:GetAttribute("ArrivalState")=="Queued"then queued+=1 end check("arrival invulnerable "..i,bm.ApplyPuncture(f,"SelfShot")==false and bm.ApplyPuncture(f,"Collision")==false)end
 check("simultaneous winners queued",queued>=3,queued)
 bm.EndFlight(winner,true)
 local seen={}local order={}local last
 check("arrival queue finishes",waitFor(function()
  local active=0
  for i=2,5 do local f=flights[i]if f.balloon.Parent then local state=f.balloon:GetAttribute("ArrivalState") if state=="Docking"or state=="Departing"then active+=1 if not seen[i]then seen[i]=true table.insert(order,i)end end end end
  checkCount=active
  assert(active<=1,"overlapping dock animations")
  return not require(game.ServerScriptService.FlyHighServer.PalaceArrival).busy
 end,40))
 report.arrivalOrder=order
 check("FIFO arrival order",table.concat(order,",")=="2,3,4,5",table.concat(order,","))
 for i=1,5 do local p=people[i]
  check("summit exactly once "..i,p:GetAttribute("SummitCount")==before[p]+1)
  check("crew landed "..i,p.Character.Humanoid.Health>0 and p:GetAttribute("PalaceArrival")~=nil and p:GetAttribute("FlightGhost")==false)
  local gui=p.Character.Head:FindFirstChild("OverheadGui")
  check("summit overhead priority "..i,gui and string.find(gui.TitleLabel.Text,"Puncak")~=nil)
 end
 for i=2,5 do check("balloon departed and removed "..i,not flights[i].balloon.Parent)end
 check("no runtime errors",#report.errors==0,H:JSONEncode(report.errors))
end,debug.traceback)
report.success=ok report.failure=not ok and err or nil report.finishedUTC=DateTime.now():ToIsoDate()
conn:Disconnect()
STS:EndTest(H:JSONEncode(report))
end)
