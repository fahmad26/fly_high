 om.Paused=true lm.Paused=true
 need("finished flights clean up naturally",waitFor(function()return #bm.activeFlights==0 end,25)~=nil)
 for _,p in roster do rpc(p,"ShootBot",{enabled=false})rpc(p,"Lane",{})p:LoadCharacterAsync()end
 for _,p in roster do assert(waitFor(function()return p.Character and p.Character:FindFirstChild("HumanoidRootPart")and p.Character.Humanoid.Health>0 end,15))end
 local function atAltitude(fd,km)
  local target=Vector3.new(fd.root.Position.X,C.GROUND_Y+km*C.STUDS_PER_KM,fd.root.Position.Z)
  local shift=target-fd.root.Position fd.balloon:PivotTo(fd.balloon:GetPivot()+shift)fd.targetPosition=target fd.alignPos.Position=target fd.altitudeKm=km fd.boardingUntil=os.clock()+5
  for _,p in fd.players do if U.Alive(p,fd)then p.Character:PivotTo(p.Character:GetPivot()+shift)p.Character.HumanoidRootPart.AssemblyLinearVelocity=Vector3.zero end end
 end
 local function fiveHoles(fd)
  fd.invulnTime=0 fd.shieldTime=0
  while fd.holes<5 do fd.invulnTime=0 assert(bm.ApplyPuncture(fd,"SelfShot"))end
 end
 local solo=launch({roster[1]},"Pod_A")atAltitude(solo,2000)
 assert(dm.ModifyEmergencyKits(roster[1],1))assert(dm.ModifyEmergencyKits(roster[1],1))fiveHoles(solo)
 need("five holes enter freefall",solo.isFreefalling and solo.holes==5)
 need("five holes block manual patch",bm.RepairHole(solo,1)==false)
 local stock=roster[1]:GetAttribute("EmergencyKits")rpc(roster[1],"Kit")
 need("Clutch Save clears five holes",waitFor(function()return solo.holes==0 and solo.shieldTime>59 end,2)~=nil)
 need("Clutch Save consumes one stored kit",roster[1]:GetAttribute("EmergencyKits")==stock-1)
 task.wait(.3)rpc(roster[1],"Kit")task.wait(.3)
 need("repeat emergency kit blocked",roster[1]:GetAttribute("EmergencyKits")==stock-1)
 atAltitude(solo,2000)fiveHoles(solo)local fallAt=os.clock()
 need("2000 km freefall reaches Game Over",waitFor(function()return solo.isGameOver end,5)~=nil)
 local seconds=os.clock()-fallAt
 need("freefall takes about three seconds",seconds>=2.7 and seconds<=3.6,seconds)
 need("ground impact kills solo crew",roster[1].Character.Humanoid.Health<=0)
 need("Game Over model cleans up",waitFor(function()return not solo.balloon.Parent end,6)~=nil)
 for _,p in {roster[2],roster[3]}do pose(p,workspace.FlyHighLobby.LobbySpawn.CFrame*CFrame.new(0,4,0))end
 local duo=launch({roster[2],roster[3]},"Pod_C")atAltitude(duo,2000)
 local helper,victim=roster[2],roster[3]
 station(duo,victim)assert(tm.attachHandlers[duo.balloon](victim))
 pose(victim,duo.root.CFrame*CFrame.new(18,4,0))task.wait(.2)
 local t=tm.activeTethers[victim.UserId]
 need("fallen tether wearer waits for rescue",t and t.stage=="Hanging")
 rpc(victim,"Tether",{action="Descend"})task.wait(.35)
 need("fallen crew cannot self-return",t.stage=="Hanging")
 pose(helper,duo.root.CFrame*CFrame.new(0,4,0))need("free teammate may rescue",tm.PullCrew(helper)==true)
 need("rescue completes with rope attached",waitFor(function()return t.stage=="Basket"and not t.winch end,4)~=nil and tm.activeTethers[victim.UserId]==t)
 pose(victim,duo.root.CFrame*CFrame.new(18,4,0))task.wait(.2)t.durability=.01
 need("rope break launches living victim",waitFor(function()return victim.Character:GetAttribute("FatalRopeFall")==true end,1)~=nil and victim.Character.Humanoid.Health>0)
 need("rope break death follows physical fall",waitFor(function()return victim.Character.Humanoid.Health<=0 end,2)~=nil)
 need("remaining teammate keeps flying",not duo.isGameOver and U.Alive(helper,duo))
 local oldCharacter=victim.Character victim:LoadCharacterAsync()task.wait(1.5)
 need("respawn is healthy and detached from old flight",victim.Character~=oldCharacter and victim.Character.Humanoid.Health>0 and not U.Alive(victim,duo))
 bm.EndFlight(duo,false)need("team Game Over kills remaining crew",helper.Character.Humanoid.Health<=0)
 assert(waitFor(function()return not duo.balloon.Parent end,6))
 for _,p in {roster[4],roster[5],roster[6]}do pose(p,workspace.FlyHighLobby.LobbySpawn.CFrame*CFrame.new(0,4,0))end
 local trio=launch({roster[4],roster[5],roster[6]},"Pod_E")
 need("trio has two ropes",trio.balloon.TetherStation:GetAttribute("MaxRopes")==2)
 need("trio repair hold lasts three seconds",trio.balloon.HoleSlots.Hole1.PatchPrompt.HoldDuration==3)
 local groundedAt=os.clock()
 need("grounded AFK timer reaches Game Over",waitFor(function()return trio.isGameOver end,65)~=nil)
 local afkSeconds=os.clock()-groundedAt
 need("grounded timeout remains one minute",afkSeconds>=58 and afkSeconds<=63,afkSeconds)
 for _,p in trio.players do need(p.Name.." AFK death",p.Character.Humanoid.Health<=0)end
 assert(waitFor(function()return not trio.balloon.Parent end,6))
 for _,p in roster do
  if p.Parent==P then local snap=rpc(p,"Snapshot")need(p.Name.." clean client logs",#snap.logs==0,snap.logs)end
 end
 local leaver=roster[6]leaver:LoadCharacterAsync()
 assert(waitFor(function()return leaver.Character and leaver.Character:FindFirstChild("HumanoidRootPart")and leaver.Character.Humanoid.Health>0 end,15))
 local last=launch({leaver},"Pod_E")need("native disconnect supported",rpc(leaver,"Leave")==true)
 need("departed last crew ends flight",waitFor(function()return last.isGameOver end,4)~=nil)
 need("disconnect removes balloon and flight",waitFor(function()return not last.balloon.Parent and #bm.activeFlights==0 end,7)~=nil)
 need("no tether reservations remain",next(tm.activeTethers)==nil and next(tm.ropeRepairs)==nil and next(tm.rescuers)==nil)
 need("no held weapons remain",next(wm.held)==nil)
