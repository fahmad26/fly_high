 assert(waitFor(function()return #P:GetPlayers()==2 end,60))
 local crew=P:GetPlayers()table.sort(crew,function(a,b)return a.Name<b.Name end)
 for _,p in crew do assert(waitFor(function()return p:GetAttribute("DataReady")and p.Character and p.Character:FindFirstChild("HumanoidRootPart")end,40))rpc(p,"Ping")end
 local victim,helper=unpack(crew)
 local bm=_G.FlyHighBalloonManager local tm=_G.FlyHighTetherManager local om=_G.FlyHighObstacleManager
 local U=require(game.ServerScriptService.FlyHighServer.ServerUtils)local C=require(RS.FlyHigh.Modules.FlyHighConfig)
 om.Paused=true _G.FlyHighLargeChallengeManager.Paused=true
 local f=assert(bm.LaunchBalloon(crew,victim,workspace.FlyHighLobby.MatchmakingPods.Pod_A.FloorPad.Position,"Pod_A"))
 assert(waitFor(function()return not f.boarding end,15))f.groundedSince=os.clock()+300
 local base=Vector3.new(0,C.GROUND_Y+2000*C.STUDS_PER_KM,0)
 f.balloon:PivotTo(CFrame.new(base))f.targetPosition=base f.alignPos.Position=base f.altitudeKm=2000
 local function place(p,v)p.Character:PivotTo(f.root.CFrame*CFrame.new(v))p.Character.HumanoidRootPart.AssemblyLinearVelocity=Vector3.zero task.wait(.2)end
 place(helper,Vector3.new(0,4,0))place(victim,Vector3.new(0,4,10))
 rpc(victim,"Prompt",{path="TetherStation.TetherPrompt"})
 assert(waitFor(function()return tm.activeTethers[victim.UserId]end,3))
 place(victim,Vector3.new(18,4,0))local t=tm.activeTethers[victim.UserId]
 check("fall at altitude waits for teammate",t.stage=="Hanging"and t.hrp.Anchored)
 local layout=rpc(helper,"ComfortUI")
 check("rescue action directly on main HUD",layout.parent=="FlyHighHUD"and layout.visible,layout)
 check("rescue target remains at least 44 pixels",layout.sizeX>=44 and layout.sizeY>=44)
 check("rescue action inside safe screen bounds",layout.inside)
 check("rescue does not overlap jump or actions",not layout.overlap)
 f.autoGas=true local startY=f.root.Position.Y
 rpc(helper,"ClickRescue")
 check("actual HUD click starts rescue",t.stage=="Rescuing")
 check("moving rescue lands within basket",waitFor(function()return t.stage=="Basket"and not t.winch end,4)~=nil and U.InBasket(t.hrp,f.balloon.BasketFloor))
 check("balloon ascends during rescue",f.root.Position.Y>startY+1)
 local landed=t.balloon.PrimaryPart.CFrame:PointToObjectSpace(t.hrp.Position)
 task.wait(1)
 check("landing stays stable after physics handoff",U.InBasket(t.hrp,f.balloon.BasketFloor)and not t.hrp.Anchored and not t.needsRescue,{landing=tostring(landed),current=tostring(f.root.CFrame:PointToObjectSpace(t.hrp.Position))})
 f.autoGas=false place(victim,Vector3.new(0,4,10))rpc(victim,"Tether",{action="Climb"})
 assert(waitFor(function()return t.stage=="Catwalk"end,4))place(victim,Vector3.new(23,20,0))
 check("deck fall remains locked from self-return",t.stage=="Hanging")
 rpc(victim,"Tether",{action="Descend"})task.wait(.35)check("Q cannot rescue fallen player",t.stage=="Hanging")
 rpc(helper,"RescueKey")
 check("B keyboard initiates teammate rescue",t.stage=="Rescuing")
 assert(waitFor(function()return t.stage=="Basket"end,4))
 tm.CleanupPlayer(victim)
 check("main rescue button hides after completion",not rpc(helper,"ComfortUI").visible)
 -- Exercise all regular encounter bands against the real manager, independently of scheduler.
 for band=1,9 do
  f.altitudeKm=band==1 and C.SAFE_TAKEOFF_KM or band*1000
  local o=assert(om.SpawnBand(band,f,false))
  local profile=C.OBSTACLE_PACING[band]
  check("band "..band.." uses configured enemy speed and HP",math.abs(o.velocity.Magnitude-profile.speed)<.01 and o.instance:GetAttribute("Health")==profile.health)
  o.instance:Destroy()
 end
 f.altitudeKm=C.SAFE_TAKEOFF_KM-1 check("safe takeoff remains free of encounters",om.SpawnBand(1,f,false)==nil and om.SpawnBand(1,f,true)==nil)
 f.altitudeKm=10000 check("victory altitude has no encounters",om.GetBand(f.altitudeKm)==nil)
 f.altitudeKm=2000 local o=assert(om.SpawnBand(2,f,true))
 check("hazard telegraph stays three seconds",math.abs(o.activeAt-o.born-3)<.05)
 o.instance:Destroy()
 for _,o in om.activeObstacles do o.instance:Destroy()end table.clear(om.activeObstacles)
 f.invulnTime=100 om.Paused=false task.wait(3)om.Paused=true
 local enemies,hazards=0,0 for _,o in om.activeObstacles do if o.shootable then enemies+=1 else hazards+=1 end end
 check("scheduler starts with shootable encounters",enemies>0)
 check("first hazard is staggered after entry",hazards==0)
 for _,p in crew do local snap=rpc(p,"Snapshot")check(p.Name.." clean client logs",#snap.logs==0,snap.logs)end

