-- Runtime-only deterministic QA scenarios; never parent this Script in the saved place.
assert(game:GetService("RunService"):IsStudio() and game.PlaceId==0)
local RS=game:GetService("ReplicatedStorage")
local SS=game:GetService("ServerStorage")
local Config=require(RS.FlyHigh.Modules.FlyHighConfig)
local U=require(game.ServerScriptService.FlyHighServer.ServerUtils)
local p=game.Players:GetPlayers()[1]
local bm=_G.FlyHighBalloonManager
local om=_G.FlyHighObstacleManager
om.Paused=true
local fd=bm.activeFlights[1] or bm.LaunchBalloon({p},p,workspace.FlyHighLobby.MatchmakingPods.Pod_C.FloorPad.Position)
local results={}
local function check(name,actual,expected)
 table.insert(results,{test=name,actual=actual,expected=expected,pass=actual==expected})
end
local function place(km)
 U.Unseat(p)
 fd.boardingUntil=os.clock()+3
 fd.root.Anchored=true
 local pos=Vector3.new(0,Config.GROUND_Y+km*Config.STUDS_PER_KM,-38)
 fd.balloon:PivotTo(CFrame.new(pos)) fd.targetPosition=pos fd.alignPos.Position=pos fd.altitudeKm=km fd.hasLiftedOff=km>0
 p.Character.HumanoidRootPart.Anchored=true
 p.Character:PivotTo(CFrame.new(pos+Vector3.new(-5,4,0)))
end
place(1199.99)
check("No obstacle spawn below 1200",om.SpawnBand(1,fd,false)==nil,true)
check("No hazard spawn below 1200",om.SpawnBand(1,fd,true)==nil,true)
check("No damage below 1200",bm.ApplyPuncture(fd),false)
place(1200)
check("First obstacle at 1200",om.SpawnBand(1,fd,false)~=nil,true)
check("First puncture at 1200",bm.ApplyPuncture(fd),true)
check("Passive 5 second grace",bm.ApplyPuncture(fd),false)
check("Manual repair active hole",bm.RepairHole(fd,1),true)
check("Duplicate hole repair blocked",bm.RepairHole(fd,1),false)
for i=1,3 do fd.invulnTime=0 bm.ApplyPuncture(fd) end
check("Repair middle hole",bm.RepairHole(fd,2),true)
fd.invulnTime=0 bm.ApplyPuncture(fd)
local count=0 for _ in pairs(fd.holeSet) do count+=1 end
check("Hole count matches visuals after out-of-order repair",count,fd.holes)
while fd.holes<5 do fd.invulnTime=0 bm.ApplyPuncture(fd) end
check("Five holes causes freefall",fd.isFreefalling,true)
check("Five holes blocks manual repair",bm.RepairHole(fd,1),false)
_G.FlyHighDataManager.ModifyEmergencyKits(p,1)
check("Clutch Save allowed during passive grace",bm.UseEmergencyKit(p),true)
check("Clutch Save clears all holes",fd.holes,0)
check("Clutch Save grants sixty seconds",fd.shieldTime,60)
check("Clutch Save cancels freefall",fd.isFreefalling,false)
check("Clutch Save cancels downward velocity",fd.root.AssemblyLinearVelocity.Magnitude,0)
local stock=p:GetAttribute("EmergencyKits")
check("Second emergency activation blocked",bm.UseEmergencyKit(p),false)
check("Blocked activation preserves stock",p:GetAttribute("EmergencyKits"),stock)
fd.shieldTime=0 fd.invulnTime=0
_G.FlyHighDataManager.ModifyEmergencyKits(p,1)
check("One kit per player per flight",bm.UseEmergencyKit(p),false)
check("1200 km equals seventy-two seconds",Config.SAFE_TAKEOFF_KM/(Config.MAX_ALTITUDE_KM/Config.BASE_FLIGHT_DURATION_SEC),72)
for count=1,3 do
 local b=RS.FlyHigh.Templates.HotAirBalloon:Clone() b.RootPart.Anchored=true b.Parent=workspace
 _G.FlyHighTetherManager.SetupBalloonTethers(b,count)
 check("Rope capacity crew "..count,b.TetherStation:GetAttribute("MaxRopes"),count==3 and 2 or 1)
 check("Repair hold crew "..count,b.HoleSlots.Hole1.PatchPrompt.HoldDuration,count==1 and 1.5 or (count==2 and 2 or 3))
 b:Destroy()
end
check("Basket width doubled",fd.balloon.BasketFloor.Size.X,28)
check("Basket depth doubled",fd.balloon.BasketFloor.Size.Z,28)
check("Basket corner is inside",U.InBasket({Position=fd.balloon.BasketFloor.Position+Vector3.new(13,3,13)},fd.balloon.BasketFloor),true)
check("Dome is outside basket",U.InBasket({Position=fd.balloon.BasketFloor.Position+Vector3.new(0,22,-20)},fd.balloon.BasketFloor),false)
check("Reject NaN vector",U.FiniteVector(Vector3.new(0/0,0,0)),false)
check("Reject infinite vector",U.FiniteVector(Vector3.new(math.huge,0,0)),false)
check("Reject non-vector",U.FiniteVector({}),false)
for band=1,9 do
 local km=band==1 and 1200 or band*1000
 place(km)
 local hazard=om.SpawnBand(band,fd,true)
 check("Hazard telegraph 3 seconds band "..band,math.abs(hazard.activeAt-hazard.born-3)<0.05,true)
end
for _,o in ipairs(om.activeObstacles) do o.instance:Destroy() end table.clear(om.activeObstacles)
place(1500)
fd.invulnTime=0 fd.shieldTime=0
-- Prepare one active hole for the interactive rigging test.
bm.ApplyPuncture(fd)
for n in pairs(table.clone(fd.holeSet)) do if n~=1 then bm.RepairHole(fd,n) end end
fd.targetPosition=fd.root.Position
p.Character.HumanoidRootPart.Anchored=false
local value=Instance.new("StringValue") value.Name="FlyHighAuditCoreResults"
value.Value=game:GetService("HttpService"):JSONEncode(results) value.Parent=SS
