local Http=game:GetService("HttpService")
local bm=_G.FlyHighBalloonManager
local p=game.Players:GetPlayers()[1]
local U=require(game.ServerScriptService.FlyHighServer.ServerUtils)
local Space=require(game.ServerScriptService.FlyHighServer.FlightSpace)
local C=require(game.ReplicatedStorage.FlyHigh.Modules.FlyHighConfig)
local result=Instance.new("StringValue")result.Name="CollisionQAResult"result.Parent=game.ServerStorage
local ok,r=xpcall(function()
 for _,f in ipairs(table.clone(bm.activeFlights))do f.balloon:Destroy()end
 if not U.Alive(p)then p:LoadCharacterAsync()task.wait(.8)end
 local foreign=game.ReplicatedStorage.FlyHigh.Templates.BalloonVariants.DawnExplorer:Clone()
 foreign.Name="ForeignBalloonQAFixture"
 local pad=workspace.FlyHighLobby.MatchmakingPods.Pod_A.FloorPad
 foreign:PivotTo(CFrame.new(Space.SpawnPosition(pad.Position)))foreign.Parent=workspace
 local other={balloon=foreign,root=foreign.PrimaryPart,players={},characters={},dead={},isVictory=true,holes=0,invulnTime=0,shieldTime=0,altitudeKm=0,holeSet={},contacts={}}
 table.insert(bm.activeFlights,other)
 assert(U.Flight(p,true)==nil,"player already in flight")
 local blocked=bm.LaunchBalloon({p},p,pad.Position,"Pod_A")==nil
 foreign:Destroy()table.remove(bm.activeFlights,table.find(bm.activeFlights,other))
 local fd=assert(bm.LaunchBalloon({p},p,Vector3.new(0,10,-38),"Pod_C"))
 foreign=game.ReplicatedStorage.FlyHigh.Templates.BalloonVariants.DawnExplorer:Clone()
 foreign.Name="ForeignBalloonQAFixture"
 foreign:PivotTo(fd.root.CFrame+C.BALLOON_CLEARANCE_DISTANCE*Vector3.xAxis-Vector3.xAxis)
 foreign.Parent=workspace
 other.balloon=foreign other.root=foreign.PrimaryPart other.isVictory=false other.invulnTime=0 other.contacts={}
 table.insert(bm.activeFlights,other)
 local safe=bm.ResolveCollisions(fd,fd.root.Position+Vector3.xAxis)
 local distance=Vector2.new(safe.X-other.root.Position.X,safe.Z-other.root.Position.Z).Magnitude
 assert(fd.holes==1 and other.holes==1,"collision must damage both at 0 km")
 assert(distance>=C.BALLOON_CLEARANCE_DISTANCE-.01,"overlap not resolved")
 fd.invulnTime=0 other.invulnTime=0
 bm.ResolveCollisions(fd,fd.root.Position+Vector3.xAxis)
 assert(fd.holes==1 and other.holes==1,"repeated contact damage")
 foreign:Destroy()table.remove(bm.activeFlights,table.find(bm.activeFlights,other))
 fd.balloon:Destroy()
 return {crossDockBlocked=blocked,collisionBothDamaged=true,noOverlapDistance=distance,oneDamagePerContact=true,clearance=C.BALLOON_CLEARANCE_DISTANCE}
end,debug.traceback)
result.Value=Http:JSONEncode({ok=ok,result=ok and r or nil,error=not ok and r or nil})
