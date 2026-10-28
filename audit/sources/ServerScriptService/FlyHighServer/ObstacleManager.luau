local RunService=game:GetService("RunService")
local RS=game:GetService("ReplicatedStorage")
local Config=require(RS.FlyHigh.Modules.FlyHighConfig)
local remotes=RS.FlyHigh.Remotes
local templates=RS.FlyHigh.Templates.Obstacles
local Manager={activeObstacles={},Paused=false}
_G.FlyHighObstacleManager=Manager
local folder=Instance.new("Folder") folder.Name="FlyHighObstacles" folder.Parent=workspace
local bands={
 [1]={enemy="WildBird",hazard="Angin Topan",effect="Wind",color=Color3.fromRGB(220,235,245)},
 [2]={enemy="StormBat",hazard="Awan Petir",effect="Lightning",color=Color3.fromRGB(110,80,190)},
 [3]={enemy="Hailstone",hazard="Jetstream Crosswind",effect="Wind",color=Color3.fromRGB(160,230,255)},
 [4]={enemy="GuardianDrone",hazard="AncientDebris",effect="Debris",color=Color3.fromRGB(200,160,90)},
 [5]={enemy="FireBee",hazard="Gelombang Panas",effect="Heat",color=Color3.fromRGB(255,130,30)},
 [6]={enemy="CrystalWyvern",hazard="Anomali Magnetik",effect="Magnetic",color=Color3.fromRGB(80,255,210)},
 [7]={enemy="ShadowPhantom",hazard="Kabut Hampa",effect="Fog",color=Color3.fromRGB(120,80,170)},
 [8]={enemy="SatelliteDebris",hazard="Meteorit Mikro",effect="Meteor",color=Color3.fromRGB(160,170,195)},
 [9]={enemy="CelestialPhoenix",hazard="Badai Gerbang Surgawi",effect="Storm",color=Color3.fromRGB(255,215,70)},
}
function Manager.GetBand(km)
 if km<Config.SAFE_TAKEOFF_KM or km>=Config.MAX_ALTITUDE_KM then return nil end
 return math.clamp(math.floor(km/1000),1,9)
end
local function flights()
 local bm=_G.FlyHighBalloonManager
 local out={}
 for _,fd in ipairs(bm and bm.activeFlights or {}) do
  if not fd.isGameOver and not fd.isVictory and Manager.GetBand(fd.altitudeKm) then table.insert(out,fd) end
 end
 return out
end
local function add(model,pos,velocity,shootable,name,color,effect,delayTime)
 model.Name=name model:SetAttribute("IsObstacle",true) model:SetAttribute("Shootable",shootable)
 model:SetAttribute("Health",shootable and 70 or 0)
 for _,part in ipairs(model:GetDescendants()) do
  if part:IsA("BasePart") then
   part.Anchored=true part.CanCollide=false part.CanTouch=false part.CanQuery=shootable part.Color=color
  end
 end
 model:PivotTo(CFrame.new(pos)) model.Parent=folder
 local _,size=model:GetBoundingBox()
 local minY=Config.GROUND_Y+Config.SAFE_TAKEOFF_KM*Config.STUDS_PER_KM+size.Y/2
 if pos.Y<minY then pos=Vector3.new(pos.X,minY,pos.Z) model:PivotTo(CFrame.new(pos)) end
 local item={instance=model,velocity=velocity,shootable=shootable,effect=effect,
  born=os.clock(),activeAt=os.clock()+(delayTime or 0),expires=os.clock()+14,minY=minY,hit={}}
 table.insert(Manager.activeObstacles,item)
 return item
end
function Manager.SpawnBand(index,fd,hazard)
 local spec=bands[index]
 if not spec or (fd.largeChallengeUntil and os.clock()<fd.largeChallengeUntil) or not Manager.GetBand(fd.altitudeKm) or #Manager.activeObstacles>=60 then return nil end
 local center=fd.balloon.Envelope.Position
 local predicted=center+Vector3.new(0,(fd.isGasActive or fd.autoGas) and 12.5 or 0,0)
 if not hazard then
  local template=spec.enemy=="Hailstone" and templates.Hailstone or templates.WildBird
  local pos=predicted+Vector3.new((math.random()-0.5)*90,10,-95)
  local velocity=(predicted-pos).Unit*28
  return add(template:Clone(),pos,velocity,true,spec.enemy,spec.color,nil,0)
 end
 -- Shared telegraph remains fixed in world space, visible to every balloon nearby.
 local pos=predicted+Vector3.new(0,0,-12)
 local model=templates.Tornado:Clone()
 local core=model.PrimaryPart
 core.Shape=Enum.PartType.Ball core.Size=Vector3.new(32,32,32) core.Transparency=0.65
 local item=add(model,pos,Vector3.zero,false,spec.hazard,spec.color,spec.effect,3)
 item.expires=item.activeAt+2.5
 local recipients=flights()
 for _,crewFlight in ipairs(recipients) do
  if math.abs(crewFlight.balloon.Envelope.Position.Y-pos.Y)<90 then
   crewFlight.hazardUntil=item.activeAt
   for _,p in ipairs(crewFlight.players) do
    if p.Parent==game.Players then remotes.HazardAlertEvent:FireClient(p,{hazardName=spec.hazard,direction="Depan",duration=3}) end
   end
  end
 end
 return item
end
local nextEnemy={} local nextHazard={}
task.spawn(function()
 while true do
  task.wait(2.5)
  if Manager.Paused then continue end
  local occupied={}
  for _,fd in ipairs(flights()) do
   local band=Manager.GetBand(fd.altitudeKm)
   occupied[band]=occupied[band] or {} table.insert(occupied[band],fd)
  end
  for band,crew in pairs(occupied) do
   local fd=crew[math.random(1,#crew)]
   local now=os.clock()
   if now>=(nextEnemy[band] or 0) then Manager.SpawnBand(band,fd,false) nextEnemy[band]=now+5 end
   if now>=(nextHazard[band] or 0) then Manager.SpawnBand(band,fd,true) nextHazard[band]=now+20 end
  end
 end
end)
RunService.Heartbeat:Connect(function(dt)
 local current=flights()
 for i=#Manager.activeObstacles,1,-1 do
  local o=Manager.activeObstacles[i]
  local model=o.instance
  local pos=model.Parent and model:GetPivot().Position
  if not pos or os.clock()>o.expires or pos.Y<o.minY or #current==0 then
   model:Destroy() table.remove(Manager.activeObstacles,i) continue
  end
  local nextPivot=model:GetPivot()+o.velocity*math.min(dt,0.1)
  if nextPivot.Position.Y<o.minY then model:Destroy() table.remove(Manager.activeObstacles,i) continue end
  model:PivotTo(nextPivot)
  if os.clock()<o.activeAt then continue end
  if not o.shootable then model.PrimaryPart.Transparency=0.25 end
  for _,fd in ipairs(current) do
   local center=fd.balloon.Envelope.Position
   if not o.hit[fd] and (model.PrimaryPart.Position-center).Magnitude<(o.shootable and 18 or 33) then
    o.hit[fd]=true
    if fd.invulnTime>0 then continue end
    if o.effect=="Magnetic" then fd.reverseUntil=os.clock()+4
    elseif o.effect=="Wind" then fd.wind=Vector3.new(25,0,0) fd.windUntil=os.clock()+3
    elseif o.effect=="Fog" then
     for _,p in ipairs(fd.players) do
      if p.Parent==game.Players then remotes.HazardAlertEvent:FireClient(p,{hazardName="Kabut Hampa",effect="Fog",duration=5}) end
     end
    else _G.FlyHighBalloonManager.ApplyPuncture(fd) end
    if o.shootable then model:Destroy() break end
   end
  end
 end
end)
