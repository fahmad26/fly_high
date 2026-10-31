 assert(waitFor(function()return #P:GetPlayers()==2 end,60))
 local crew=P:GetPlayers()table.sort(crew,function(a,b)return a.Name<b.Name end)
 for _,p in crew do assert(waitFor(function()return p:GetAttribute("DataReady")and p.Character and p.Character:FindFirstChild("HumanoidRootPart")end,40))rpc(p,"Ping")end
 local shooter,observer=unpack(crew)
 local bm=_G.FlyHighBalloonManager local wm=_G.FlyHighWeaponManager
 _G.FlyHighObstacleManager.Paused=true _G.FlyHighLargeChallengeManager.Paused=true
 local f=assert(bm.LaunchBalloon(crew,shooter,workspace.FlyHighLobby.MatchmakingPods.Pod_A.FloorPad.Position,"Pod_A"))
 assert(waitFor(function()return not f.boarding end,15))f.groundedSince=os.clock()+300
 shooter.Character:PivotTo(f.balloon.WeaponRack1.CFrame*CFrame.new(3,2,0))task.wait(.3)
 rpc(shooter,"Prompt",{path="WeaponRack1.PickupPrompt"})check("native pistol equip",wm.held[shooter]~=nil)
 local target=Instance.new("Model")target.Name="FlyingBulletTarget"target:SetAttribute("IsObstacle",true)target:SetAttribute("Shootable",true)target:SetAttribute("Health",1000)
 local p=Instance.new("Part")p.Anchored=true p.Size=Vector3.new(10,10,10)p.Position=f.root.Position+Vector3.new(-8,8,-100)p.Parent=target target.PrimaryPart=p target.Parent=workspace.FlyHighObstacles
 rpc(observer,"SideView",{position=f.root.Position+Vector3.new(70,20,-50),target=f.root.Position+Vector3.new(-8,8,-50)})
 rpc(shooter,"TrackBullets")rpc(observer,"TrackBullets")rpc(shooter,"AimShot",{target=p.Position})
 local own=rpc(shooter,"BulletMetrics")local other=rpc(observer,"BulletMetrics")
 check("first-person bullet visible over several frames",own.visibleFrames>=6,own)
 check("bullet visibly travels toward target",own.maxTravel>50)
 check("100-stud flight lasts long enough to follow",own.maxLife>=.25)
 check("bullet has trail and readable core",own.trail and own.glow)
 check("teammate also sees bullet travel",other.visibleFrames>=6 and other.maxTravel>50,other)
 check("server damage still authoritative",target:GetAttribute("Health")<1000)
 target:Destroy()task.wait(.6)
 local rise=Vector3.new(0,600,0)f.balloon:PivotTo(f.root.CFrame+rise)f.targetPosition+=rise f.alignPos.Position=f.targetPosition f.boardingUntil=os.clock()+10
 for _,p in crew do p.Character:PivotTo(p.Character:GetPivot()+rise)end task.wait(.4)
 rpc(shooter,"TrackBullets")rpc(shooter,"AimShot",{target=f.root.Position+Vector3.new(-8,18,450)})task.wait(2)
 local far=rpc(shooter,"BulletMetrics")far.flightRoot=tostring(f.root.Position)far.playerRoot=tostring(shooter.Character.HumanoidRootPart.Position)check("long-range bullet stays visible longer",far.maxLife>=.8,far)
 check("long-range cosmetic has no collision",far.nonColliding)
 rpc(shooter,"Drop")task.wait(.3)wm.SetupWeaponRacks(f.balloon,true)
 rpc(shooter,"Prompt",{path="WeaponRack1.PickupPrompt"})check("AK equips",wm.held[shooter]and wm.held[shooter].tool.Name=="AK47")
 rpc(shooter,"TrackBullets")rpc(shooter,"AimShot",{target=f.root.Position+Vector3.new(-8,8,450)})task.wait(1.5)
 local auto=rpc(shooter,"BulletMetrics")check("AK renders individual bullets",auto.bullets>=2,auto)
 check("active bullet count remains bounded",auto.maxConcurrent<=32)
 task.wait(.4)check("bullet and trail objects clean up",rpc(shooter,"BulletMetrics").active==0)
 rpc(shooter,"Drop")
 for _,p in crew do local snap=rpc(p,"Snapshot")check(p.Name.." clean console",#snap.logs==0,snap.logs)end
