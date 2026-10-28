-- Fly High: replace the confirmed flat lobby terrain with a coastal island and real ocean.
-- Applies only below Y=64; flight corridor and palace stay above this terrain edit.
assert(game:GetService("RunService"):IsStudio() and not game:GetService("RunService"):IsRunning())
local terrain=workspace.Terrain
local lobby=workspace.FlyHighLobby
game:GetService("ChangeHistoryService"):SetWaypoint("Before Fly High ocean")
-- The original grass field occupies [-1024,1024] in X/Z at Y=10.
-- Clear only its surface, then replace its submerged volume with water.
for x=-1024,1023,512 do
 for z=-1024,1023,512 do
  terrain:FillBlock(CFrame.new(x+256,20,z+256),Vector3.new(512,88,512),Enum.Material.Air)
  task.wait()
 end
end
-- A 4096x4096 ocean, 64 studs deep, split into bounded terrain operations.
for x=-2048,2047,512 do
 for z=-2048,2047,512 do
  terrain:FillBlock(CFrame.new(x+256,-32,z+256),Vector3.new(512,64,512),Enum.Material.Water)
  task.wait()
 end
end
-- Sculpt the island around all existing pads and spawn without moving their ground level.
local resolution=4
local minY=-40
local maxY=20
for startX=-160,159,128 do
 local endX=math.min(startX+128,160)
 for startZ=-152,151,128 do
  local endZ=math.min(startZ+128,152)
  local nx=(endX-startX)/resolution
  local ny=(maxY-minY)/resolution
  local nz=(endZ-startZ)/resolution
  local materials={}
  local occupancies={}
  for ix=1,nx do
   materials[ix]={} occupancies[ix]={}
   local x=startX+(ix-0.5)*resolution
   for iy=1,ny do materials[ix][iy]={} occupancies[ix][iy]={} end
   for iz=1,nz do
    local z=startZ+(iz-0.5)*resolution
    local radius=math.sqrt((x/126)^2+(z/116)^2)
    radius+=math.noise(x*0.026,z*0.026)*0.035
    local height
    if radius<=0.86 then height=10
    elseif radius<=0.95 then height=10-(radius-0.86)/0.09*5
    elseif radius<=1.04 then height=5-(radius-0.95)/0.09*6
    elseif radius<=1.2 then height=-1-(radius-1.04)/0.16*25
    else height=-64 end
    for iy=1,ny do
     local bottom=minY+(iy-1)*resolution
     local ground=math.clamp((height-bottom-2)/resolution,0,1)
     local material
     local occupancy
     if ground>0 then
      material=(bottom<height-8) and Enum.Material.Rock or (height>6 and Enum.Material.Grass or Enum.Material.Sand)
      occupancy=ground
     elseif bottom<0 then material=Enum.Material.Water occupancy=1
     else material=Enum.Material.Air occupancy=0 end
     materials[ix][iy][iz]=material
     occupancies[ix][iy][iz]=occupancy
    end
   end
  end
  terrain:WriteVoxels(Region3.new(Vector3.new(startX,minY,startZ),Vector3.new(endX,maxY,endZ)),resolution,materials,occupancies)
  task.wait()
 end
end
terrain.WaterColor=Color3.fromRGB(15,116,163)
terrain.WaterTransparency=0.25
terrain.WaterReflectance=0.18
terrain.WaterWaveSize=0.16
terrain.WaterWaveSpeed=12
-- Retain the old named parts for compatibility and rollback, but remove their visible glass/flat square surface.
lobby.OceanWater.Transparency=1
lobby.OceanWater.CanCollide=false
lobby.OceanWater.CanTouch=false
lobby.OceanWater.CanQuery=false
lobby.OceanWater:SetAttribute("ReplacedByTerrainWater",true)
lobby.IslandGround.Transparency=1
lobby.IslandGround:SetAttribute("TerrainCoastSurface",true)
lobby:SetAttribute("OceanTerrainVersion",1)
workspace.CurrentCamera.CFrame=CFrame.lookAt(Vector3.new(190,150,205),Vector3.new(0,6,-10))
game:GetService("ChangeHistoryService"):SetWaypoint("Fly High coastal island and ocean")
return {oceanWidth=4096,waterLevel=0,coastRadius="approximately 126 x 116",lobbySurfaceY=10}
