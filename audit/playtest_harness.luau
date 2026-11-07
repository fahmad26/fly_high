-- Runtime-only QA harness. Insert as Script during Play; never ship in Edit DataModel.
local RS=game:GetService("ReplicatedStorage")
local ServerStorage=game:GetService("ServerStorage")
local Players=game:GetService("Players")
local Config=require(RS.FlyHigh.Modules.FlyHighConfig)
local U=require(game.ServerScriptService.FlyHighServer.ServerUtils)
local api=Instance.new("BindableFunction") api.Name="FlyHighAuditAPI" api.Parent=ServerStorage
local function manager() return _G.FlyHighBalloonManager end
local function flight() return manager().activeFlights[1] end
api.OnInvoke=function(action,data)
 local p=Players:GetPlayers()[1]
 if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
  if not p.Character.HumanoidRootPart.Anchored then p.Character.HumanoidRootPart:SetNetworkOwner(nil) end
 end
 local m=manager()
 local o=_G.FlyHighObstacleManager
 if action=="Status" then
  local fd=flight()
  return {ready=m~=nil,flights=#m.activeFlights,holes=fd and fd.holes,altitude=fd and fd.altitudeKm,
   pos=fd and tostring(fd.root.Position),target=fd and tostring(fd.targetPosition),pilot=fd and tostring(fd.pilot),
   gameOver=fd and fd.isGameOver,victory=fd and fd.isVictory,gas=fd and fd.isGasActive,obstacles=#o.activeObstacles,
   tethers=(function() local n=0 for _ in pairs(_G.FlyHighTetherManager.activeTethers) do n+=1 end return n end)()}
 elseif action=="Launch" then
  o.Paused=true
  return m.LaunchBalloon({p},p,workspace.FlyHighLobby.MatchmakingPods.Pod_C.FloorPad.Position)~=nil
 elseif action=="Move" then
  U.Unseat(p)
  task.wait(0.1)
  local fd=flight()
  fd.boardingUntil=os.clock()+3
  local pos=Vector3.new(data.x or 0,Config.GROUND_Y+data.km*Config.STUDS_PER_KM,data.z or -38)
  fd.balloon:PivotTo(CFrame.new(pos)) fd.targetPosition=pos fd.alignPos.Position=pos fd.root.AssemblyLinearVelocity=Vector3.zero
  fd.altitudeKm=data.km fd.hasLiftedOff=data.km>1
  fd.root.Anchored=data.anchored==true
  for i,crew in ipairs(fd.players) do
   if U.Alive(crew,fd) then crew.Character:PivotTo(CFrame.new(pos+Vector3.new((i-2)*5,4,0))) end
  end
  return true
 elseif action=="Puncture" then
  local fd=flight() fd.invulnTime=0
  return m.ApplyPuncture(fd)
 elseif action=="PunctureNoReset" then return m.ApplyPuncture(flight())
 elseif action=="Repair" then return m.RepairHole(flight(),data)
 elseif action=="Kit" then
  if data then _G.FlyHighDataManager.ModifyEmergencyKits(p,1) end
  return m.UseEmergencyKit(p)
 elseif action=="State" then
  local fd=flight() if not fd then return {ended=true} end
  return {holes=fd.holes,holeSet=fd.holeSet,invuln=fd.invulnTime,shield=fd.shieldTime,
   kits=p:GetAttribute("EmergencyKits"),freefall=fd.isFreefalling,velocity=tostring(fd.root.AssemblyLinearVelocity),
   used=p:GetAttribute("UsedEmergencyKitThisFlight"),dead=fd.dead[p]==true}
 elseif action=="ClearShield" then local fd=flight() fd.shieldTime=0 fd.invulnTime=0 return true
 elseif action=="PrepareSecondKit" then local fd=flight() fd.usedKits[p.UserId]=nil p:SetAttribute("UsedEmergencyKitThisFlight",false) return true
 elseif action=="Spawn" then
  o.Paused=true
  local fd=flight()
  local item=o.SpawnBand(o.GetBand(fd.altitudeKm) or 1,fd,data)
  return item~=nil
 elseif action=="ObstacleStatus" then
  local out={}
  for _,item in ipairs(o.activeObstacles) do table.insert(out,{name=item.instance.Name,pos=tostring(item.instance:GetPivot().Position),
   health=item.instance:GetAttribute("Health"),activeIn=item.activeAt-os.clock(),shootable=item.shootable}) end
  return out
 elseif action=="BandCheck" then
  local result={}
  for _,km in ipairs({0,299,299.99,300,999,1000,1999,2000,3000,4000,5000,6000,7000,8000,9000,9999,10000}) do
   table.insert(result,{km=km,band=o.GetBand(km) or 0})
  end return result
 elseif action=="Helm" then local fd=flight() fd.balloon.HelmSeat:Sit(p.Character:FindFirstChildOfClass("Humanoid")) return true
 elseif action=="RepairConfig" then
  local results={}
  for count=1,3 do
   local clone=RS.FlyHigh.Templates.HotAirBalloon:Clone() clone.Parent=workspace
   clone.RootPart.Anchored=true
   _G.FlyHighTetherManager.SetupBalloonTethers(clone,count)
   table.insert(results,{crew=count,ropes=clone.TetherStation:GetAttribute("MaxRopes"),hold=clone.HoleSlots.Hole1.PatchPrompt.HoldDuration})
   clone:Destroy()
  end
  return results
 elseif action=="SafeSpawnAll" then
  local fd=flight() local results={}
  for band=1,9 do
   local km=band==1 and Config.SAFE_TAKEOFF_KM or band*1000
   fd.altitudeKm=km
   local pos=Vector3.new(0,Config.GROUND_Y+km*Config.STUDS_PER_KM,0)
   fd.balloon:PivotTo(CFrame.new(pos)) fd.targetPosition=pos fd.root.Anchored=true
   local item=o.SpawnBand(band,fd,false)
   local hazard=o.SpawnBand(band,fd,true)
   table.insert(results,{band=band,enemy=item and item.instance.Name,hazard=hazard and hazard.instance.Name,telegraph=hazard and math.abs(hazard.activeAt-hazard.born-3)<0.05})
  end
  return results
 elseif action=="Station" then
  local fd=flight()
  p.Character:FindFirstChildOfClass("Humanoid").Sit=false
  p.Character.HumanoidRootPart.CFrame=fd.balloon.TetherStation.CFrame*CFrame.new(0,1,-3)
  return true
 elseif action=="TetherStatus" then
  local fd=flight() local t=_G.FlyHighTetherManager.activeTethers[p.UserId]
  return {attached=t~=nil,durability=t and t.durability,inside=t and U.InBasket(t.hrp,fd.balloon.BasketFloor),
   winch=t and t.winch~=nil,inUse=fd.balloon.TetherStation:GetAttribute("RopesInUse"),pos=t and tostring(t.hrp.Position)}
 elseif action=="Outside" then local fd=flight() p.Character.HumanoidRootPart.CFrame=fd.root.CFrame*CFrame.new(20,22,0) return true
 elseif action=="Snap" then local t=_G.FlyHighTetherManager.activeTethers[p.UserId] if t then t.durability=0 end return t~=nil
 elseif action=="WeaponRack" then
  local fd=flight() p.Character.HumanoidRootPart.CFrame=fd.balloon.WeaponRack1.CFrame*CFrame.new(3,1,0) return true
 elseif action=="WeaponState" then
  local s=_G.FlyHighWeaponManager.held[p]
  return {held=s~=nil,ammo=s and s.ammo,reloading=s and s.reloading,tool=s and s.tool.Name,
   occupied=flight().balloon.WeaponRack1:GetAttribute("IsOccupied")}
 elseif action=="End" then m.EndFlight(flight(),data==true) return true
 elseif action=="Destroy" then if flight() then flight().balloon:Destroy() end return true
 elseif action=="Kill" then p.Character:FindFirstChildOfClass("Humanoid").Health=0 return true
 end
 return false
end
