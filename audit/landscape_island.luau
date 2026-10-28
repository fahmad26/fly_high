-- Edit-time island dressing. Generated mesh templates live in ReplicatedStorage.FlyHigh.EnvironmentAssets.
assert(game:GetService("RunService"):IsStudio() and not game:GetService("RunService"):IsRunning())
local lobby=workspace.FlyHighLobby
local assets=game.ReplicatedStorage.FlyHigh.EnvironmentAssets
local terrain=workspace.Terrain
local rng=Random.new(26028)
local nature=lobby:FindFirstChild("IslandNature") or Instance.new("Folder")
nature.Name="IslandNature" nature.Parent=lobby
for _,name in ipairs({"Trees","Plants","Flowers","Rocks","Details","Chickens","Butterflies"}) do
 local f=nature:FindFirstChild(name) or Instance.new("Folder")
 f.Name=name f.Parent=nature f:ClearAllChildren()
end
local paths={{Vector2.new(0,46),Vector2.new(0,5),10}}
local pods={}
for _,pod in ipairs(lobby.MatchmakingPods:GetChildren()) do
 local p=pod.FloorPad.Position
 table.insert(paths,{Vector2.new(0,5),Vector2.new(p.X,p.Z+10),7})
 table.insert(pods,Vector2.new(p.X,p.Z-18))
end
local function distanceSegment(p,a,b)
 local d=b-a
 local t=math.clamp((p-a):Dot(d)/d:Dot(d),0,1)
 return (p-(a+d*t)).Magnitude
end
local function protected(x,z,radius)
 local p=Vector2.new(x,z)
 if (p-Vector2.new(0,35)).Magnitude<14+radius then return true end
 if math.abs(x)<16+radius and math.abs(z-48)<6+radius then return true end
 for _,q in ipairs(pods) do if (p-q).Magnitude<25+radius then return true end end
 for _,s in ipairs(paths) do if distanceSegment(p,s[1],s[2])<s[3]/2+radius then return true end end
 return false
end
local params=RaycastParams.new()
params.FilterType=Enum.RaycastFilterType.Include params.FilterDescendantsInstances={terrain} params.IgnoreWater=false
local function ground(x,z)
 local hit=workspace:Raycast(Vector3.new(x,70,z),Vector3.new(0,-140,0),params)
 if not hit or hit.Material==Enum.Material.Water then return nil end
 return hit.Position.Y
end
-- Small, overlapping terrain knolls add relief around the perimeter gardens.
for _,h in ipairs({{-88,30,15,15},{-79,37,11,13},{78,52,14,14},{-42,82,12,13.5},{47,84,12,13.5},{-98,-6,12,12.8},{97,-14,12,12.8}}) do
 terrain:FillBall(Vector3.new(h[1],h[4]-h[3],h[2]),h[3],Enum.Material.Grass)
 task.wait()
end
local beds={{-34,13},{36,14},{-48,51},{48,51},{-18,77},{22,78},{-85,22},{86,22}}
local homes={{-48,24},{-38,65},{52,26},{38,70},{-76,4},{78,4}}
-- Replace tall default lawn blades with a legible leafy lawn; preserve all voxel heights.
local region=Region3.new(Vector3.new(-128,0,-112),Vector3.new(128,24,112))
local materials,occ=terrain:ReadVoxels(region,4)
for ix=1,#materials do
 for iy=1,#materials[ix] do
  for iz=1,#materials[ix][iy] do
   if materials[ix][iy][iz]==Enum.Material.Grass then
    local x=-128+(ix-0.5)*4 local z=-112+(iz-0.5)*4
    local p=Vector2.new(x,z) local path=false
    for _,s in ipairs(paths) do if distanceSegment(p,s[1],s[2])<s[3]/2 then path=true break end end
    local bed=false
    for _,b in ipairs(beds) do if (p-Vector2.new(b[1],b[2])).Magnitude<4.8 then bed=true break end end
    for _,h in ipairs(homes) do if (p-Vector2.new(h[1],h[2])).Magnitude<5 then bed=true break end end
    materials[ix][iy][iz]=(path or bed) and Enum.Material.Ground or Enum.Material.LeafyGrass
   end
  end
 end
 if ix%16==0 then task.wait() end
end
terrain:WriteVoxels(region,4,materials,occ)
terrain:SetMaterialColor(Enum.Material.LeafyGrass,Color3.fromRGB(82,139,76))
terrain:SetMaterialColor(Enum.Material.Ground,Color3.fromRGB(137,112,80))
terrain:SetMaterialColor(Enum.Material.Sand,Color3.fromRGB(226,208,170))
local function rest(model)
 local root=model.PrimaryPart
 for _,p in ipairs(model:GetDescendants()) do
  if p:IsA("BasePart") and p~=root then
   p:SetAttribute("RestCFrame",root.CFrame:ToObjectSpace(p.CFrame))
   if p:GetAttribute("Segment")==nil then p:SetAttribute("Segment",p.Parent.Name) end
  end
 end
end
local function place(kind,name,x,z,scale,yaw,parent,offset)
 local y=ground(x,z) if not y then return nil end
 local template=assets:FindFirstChild(kind) if not template then return nil end
 local m=template:Clone() m.Name=name
 m:ScaleTo(m:GetScale()*(scale or 1))
 if kind=="Boulder" then
  local sx=rng:NextNumber(1.05,1.5) local sy=rng:NextNumber(0.45,0.75) local sz=rng:NextNumber(1.0,1.4)
  local root=m.PrimaryPart
  for _,p in ipairs(m:GetDescendants()) do
   if p:IsA("BasePart") and p~=root then
    local cf=root.CFrame:ToObjectSpace(p.CFrame)
    p.Size=Vector3.new(p.Size.X*sx,p.Size.Y*sy,p.Size.Z*sz)
    p.CFrame=root.CFrame*(CFrame.new(cf.X*sx,cf.Y*sy,cf.Z*sz)*cf.Rotation)
   end
  end
 elseif kind=="Flower" then
  local colors={Color3.fromRGB(235,126,161),Color3.fromRGB(244,220,151),Color3.fromRGB(190,155,225),Color3.fromRGB(244,166,128)}
  local petals=m:FindFirstChild("PetalCorolla")
  if petals then petals.Color=colors[rng:NextInteger(1,#colors)] end
 end
 m:PivotTo(CFrame.new(x,y+(offset or -0.08),z)*CFrame.Angles(0,yaw or rng:NextNumber(-math.pi,math.pi),0))
 m.ModelStreamingMode=Enum.ModelStreamingMode.Atomic
 m:SetAttribute("NatureType",kind)
 m:SetAttribute("VisualScale",scale or 1)
 rest(m)
 m.Parent=parent
 if kind=="Boulder" and parent==nature.Rocks then
  for _,p in ipairs(m:GetDescendants()) do
   if p:IsA("BasePart") and p:GetAttribute("Segment")=="boulder" then p.CanCollide=true p.CanQuery=true end
  end
 end
 return m
end
local treePositions={
 {"PalmTree",-100,-22,0.95},{"PalmTree",-102,25,1.05},{"PalmTree",-78,70,0.9},
 {"PalmTree",-32,96,0.92},{"PalmTree",28,97,1.04},{"PalmTree",78,69,1},
 {"PalmTree",100,22,0.92},{"PalmTree",96,-43,0.88},
 {"BroadleafTree",-88,-49,0.94},{"BroadleafTree",-84,4,1.08},{"BroadleafTree",-79,45,0.92},
 {"BroadleafTree",-59,74,1.1},{"BroadleafTree",-8,83,0.9},{"BroadleafTree",45,78,1.04},
 {"BroadleafTree",78,39,1.05},{"BroadleafTree",90,-5,0.92},
 {"BroadleafTree",-66,17,0.78},{"BroadleafTree",-52,58,0.78},{"BroadleafTree",55,57,0.82},{"BroadleafTree",68,9,0.8},
}
local treeCenters={}
for i,t in ipairs(treePositions) do
 if not protected(t[2],t[3],7) then
  local m=place(t[1],t[1].."_"..i,t[2],t[3],t[4],nil,nature.Trees,-0.18)
  if m then
   table.insert(treeCenters,Vector3.new(t[2],m.PrimaryPart.Position.Y,t[3]))
   local collider=Instance.new("Part") collider.Name="TrunkCollider" collider.Shape=Enum.PartType.Cylinder
   collider.Size=Vector3.new(7*t[4],1.8*t[4],1.8*t[4])
   collider.CFrame=m.PrimaryPart.CFrame*CFrame.new(0,3.4*t[4],0)*CFrame.Angles(0,0,math.pi/2)
   collider.Anchored=true collider.Transparency=1 collider.CanCollide=true collider.CanTouch=false collider.Parent=m
  end
 end
 if i%5==0 then task.wait() end
end
-- Understory pockets follow trees and rocks rather than a uniform random grid.
local plantIndex=0
for _,center in ipairs(treeCenters) do
 for j=1,3 do
  local angle=rng:NextNumber(0,math.pi*2) local r=rng:NextNumber(3,6)
  local x=center.X+math.cos(angle)*r local z=center.Z+math.sin(angle)*r
  if not protected(x,z,2) then
   plantIndex+=1 place("Fern","Fern_"..plantIndex,x,z,rng:NextNumber(0.55,1.15),nil,nature.Plants)
  end
 end
 task.wait()
end
local rockIndex=0
for _,p in ipairs({{-106,5},{-81,65},{-56,89},{-8,104},{52,91},{95,46},{107,2},{87,-54},{-97,-48},{-73,28},{69,61},{-29,80}}) do
 if not protected(p[1],p[2],3) then
  rockIndex+=1 place("Boulder","Boulder_"..rockIndex,p[1],p[2],rng:NextNumber(1.1,1.9),nil,nature.Rocks,-0.45)
 end
end
-- Faceted mesh pebbles: varied sizes and partly embedded in the sand.
for i=1,115 do
 local a=rng:NextNumber(0,math.pi*2)
 local r=rng:NextNumber(0.91,1.015)
 local x=math.cos(a)*126*r local z=math.sin(a)*116*r
 if not protected(x,z,0.6) then
  local m=place("Boulder","Pebble_"..i,x,z,rng:NextNumber(0.09,0.28),nil,nature.Details,-0.11)
  if m then
   for _,p in ipairs(m:GetDescendants()) do if p:IsA("BasePart") then p.CastShadow=false end end
  end
 end
 if i%20==0 then task.wait() end
end
-- Flower beds are small asymmetric groups with room for butterflies to circle above them.
if assets:FindFirstChild("Flower") then
 for bed,b in ipairs(beds) do
  for j=1,7 do
   local angle=rng:NextNumber(0,math.pi*2) local r=math.sqrt(rng:NextNumber())*4.5
   local x=b[1]+math.cos(angle)*r local z=b[2]+math.sin(angle)*r
   if not protected(x,z,1) then place("Flower","Flower_"..bed.."_"..j,x,z,rng:NextNumber(0.65,1.15),nil,nature.Flowers) end
  end
  task.wait()
 end
end
for i,h in ipairs(homes) do
 local m=place("Chicken","Hen_"..i,h[1],h[2],rng:NextNumber(0.82,1.04),rng:NextNumber(-math.pi,math.pi),nature.Chickens,0.03)
 if m then m:SetAttribute("Home",m.PrimaryPart.Position) m:SetAttribute("RoamRadius",8) m:SetAttribute("WalkSpeed",rng:NextNumber(1.8,2.7)) m:SetAttribute("Walking",false) m:SetAttribute("Pecking",false) m:SetAttribute("Phase",rng:NextNumber(0,6.28)) end
end
for i=1,14 do
 local bed=beds[(i-1)%#beds+1]
 local m=place("Butterfly","Butterfly_"..i,bed[1]+rng:NextNumber(-2,2),bed[2]+rng:NextNumber(-2,2),rng:NextNumber(0.55,0.88),nil,nature.Butterflies,3)
 if m then m:SetAttribute("FlightCenter",m.PrimaryPart.Position) m:SetAttribute("Phase",rng:NextNumber(0,6.28)) m:SetAttribute("FlightRadius",rng:NextNumber(2.2,4.5)) end
end
-- Add modest stepping stones along the main lane; flattened faceted geometry.
for i=1,7 do
 local z=8+i*4.1 local x=(i%2==0) and 1.5 or -1.5
 local m=place("Boulder","SteppingStone_"..i,x,z,0.9,rng:NextNumber(-0.3,0.3),nature.Details,-0.1)
 if m then
  local root=m.PrimaryPart
  for _,p in ipairs(m:GetDescendants()) do
   if p:IsA("BasePart") and p~=root then
    local localCF=root.CFrame:ToObjectSpace(p.CFrame)
    p.Size=Vector3.new(p.Size.X, p.Size.Y*0.1, p.Size.Z)
    p.CFrame=root.CFrame*(CFrame.new(localCF.X,localCF.Y*0.1,localCF.Z)*localCF.Rotation)
   end
  end
  rest(m)
 end
end
nature:SetAttribute("LandscapeVersion",1)
local counts={}
for _,f in ipairs(nature:GetChildren()) do counts[f.Name]=#f:GetChildren() end
game:GetService("ChangeHistoryService"):SetWaypoint("Fly High island nature")
return counts
