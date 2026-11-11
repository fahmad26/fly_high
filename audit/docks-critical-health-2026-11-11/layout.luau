local lobby=workspace.FlyHighLobby
local terrain=workspace.Terrain
local rp=RaycastParams.new()rp.FilterType=Enum.RaycastFilterType.Include rp.FilterDescendantsInstances={terrain}
local function ground(x,z)
 local hit=workspace:Raycast(Vector3.new(x,60,z),Vector3.new(0,-100,0),rp)
 return hit and hit.Position.Y,hit and hit.Material
end
local report={pods={},trees={},decor={}}
local pads={} local hub=Vector3.new(0,10,15)
local segments={}
local function segment(a,b)table.insert(segments,{a,b})end
local last
for j=0,48 do
 local a=math.rad(-90+j*180/48)
 local p=Vector3.new(math.sin(a)*70,10,15-math.cos(a)*70)
 if last then segment(last,p)end last=p
end
segment(Vector3.new(0,10,20),Vector3.new(0,10,-55))
local history=game:GetService("ChangeHistoryService")
local recording=history:TryBeginRecording("Organize five docks and paths")
for i,name in ipairs({"Pod_A","Pod_B","Pod_C","Pod_D","Pod_E"})do
 local angle=math.rad((i-3)*45)
 local x,z=math.sin(angle)*90,15-math.cos(angle)*90
 local model=lobby.MatchmakingPods[name]local pad=model.FloorPad
 local y=assert(ground(x,z),"Dock must remain on terrain")
 local target=Vector3.new(x,y+.2,z)
 local normal=model.Console.StatusGui.Face==Enum.NormalId.Back and -model.Console.CFrame.LookVector or model.Console.CFrame.LookVector
 local desired=lobby.LobbySpawn.Position-target
 local yaw=math.atan2(desired.X,desired.Z)-math.atan2(normal.X,normal.Z)
 local transform=CFrame.new(target)*CFrame.Angles(0,yaw,0)*CFrame.new(-pad.Position)
 model:PivotTo(transform*model:GetPivot())
 local preview=model.DockDecor:FindFirstChild("PreviewBalloon")
 if preview then preview:SetAttribute("PreviewBase",preview:GetPivot())end
 pads[i]=target
 segment(Vector3.new(math.sin(angle)*70,10,15-math.cos(angle)*70),target)
 report.pods[i]={name=name,position={target.X,target.Y,target.Z}}
end
local function nearest(p)
 local best=math.huge local point
 for _,s in ipairs(segments)do
  local a,b=s[1],s[2]
  local v=Vector3.new(b.X-a.X,0,b.Z-a.Z)
  local q=Vector3.new(p.X-a.X,0,p.Z-a.Z)
  local t=math.clamp(q:Dot(v)/v:Dot(v),0,1)
  local candidate=a+v*t
  local d=Vector2.new(p.X-candidate.X,p.Z-candidate.Z).Magnitude
  if d<best then best=d point=candidate end
 end
 return best,point
end
local function padDistance(p)
 local best=math.huge local point
 for _,pad in ipairs(pads)do
  for _,center in ipairs({pad,pad+Vector3.new(0,0,-18)})do
   local d=Vector2.new(p.X-center.X,p.Z-center.Z).Magnitude
   if d<best then best=d point=center end
  end
 end
 return best,point
end
local function relocate(obj,x,z)
 local old=obj:GetPivot()
 local oldY=ground(old.X,old.Z)
 local newY=ground(x,z)
 if not oldY or not newY then return false end
 obj:PivotTo(old+Vector3.new(x-old.X,newY-oldY,z-old.Z))
 return true
end
local trees=lobby.IslandNature.Trees:GetChildren()
table.sort(trees,function(a,b)return a.Name<b.Name end)
local moved={}local kept={}
for _,tree in ipairs(trees)do
 local p=tree:GetPivot().Position
 if padDistance(p)<34 or nearest(p)<10 then table.insert(moved,tree)else table.insert(kept,p)end
end
local candidates={Vector3.new(-25,10,-20),Vector3.new(25,10,-20),Vector3.new(-45,10,-5),Vector3.new(45,10,-5),Vector3.new(-25,10,-40),Vector3.new(25,10,-40)}
for _,z in ipairs({60,78,94,104})do
 for _,x in ipairs({-25,25,-50,50,0,-75,75})do table.insert(candidates,Vector3.new(x,10,z))end
end
for _,tree in ipairs(moved)do
 local original=tree:GetPivot().Position local selected
 for _,p in ipairs(candidates)do
  local _,mat=ground(p.X,p.Z)
  local clear=mat==Enum.Material.Grass or mat==Enum.Material.LeafyGrass or mat==Enum.Material.Ground
  clear=clear and (Vector2.new(p.X,p.Z-35).Magnitude>34)and padDistance(p)>34 and nearest(p)>10
  for _,q in ipairs(kept)do if Vector2.new(p.X-q.X,p.Z-q.Z).Magnitude<14 then clear=false break end end
  if clear then selected=p break end
 end
 assert(selected,"No safe tree clearing candidate: "..tree.Name)
 relocate(tree,selected.X,selected.Z)table.insert(kept,selected)
 table.insert(report.trees,{name=tree.Name,from=tostring(original),to=tostring(tree:GetPivot().Position)})
end
for _,category in ipairs({"Plants","Flowers","Rocks","Details"})do
 for index,obj in ipairs(lobby.IslandNature[category]:GetChildren())do
  if not(obj:IsA("Model")or obj:IsA("BasePart"))then continue end
  local p=obj:GetPivot().Position
  local distance,closest=nearest(p)
  local dockDistance,dock=padDistance(p)
  local destination
  if dockDistance<17 then
   local direction=Vector3.new(p.X-dock.X,0,p.Z-dock.Z)
   if direction.Magnitude<.01 then direction=Vector3.zAxis end
   destination=dock+direction.Unit*20
  elseif distance<4.5 then
   local direction=Vector3.new(p.X-closest.X,0,p.Z-closest.Z)
   if direction.Magnitude<.01 then direction=Vector3.xAxis end
   destination=closest+direction.Unit*7
  end
  if destination and relocate(obj,destination.X,destination.Z)then table.insert(report.decor,obj.Name)end
  if index%150==0 then task.wait()end
 end
end
-- Repaint materials only; do not alter terrain heights, occupancy, water or coastline.
local low=Vector3.new(-112,4,-104)
local region=Region3.new(low,Vector3.new(112,16,60)):ExpandToGrid(4)
local materials,occupancy=terrain:ReadVoxels(region,4)
local size=region.Size/4 local origin=region.CFrame.Position-region.Size/2
local painted,restored=0,0
for ix=1,size.X do
 for iz=1,size.Z do
  local x,z=origin.X+(ix-.5)*4,origin.Z+(iz-.5)*4
  local distance=nearest(Vector3.new(x,10,z))
  for iy=1,size.Y do
   local mat=materials[ix][iy][iz]
   if occupancy[ix][iy][iz]>0 and(mat==Enum.Material.Ground or mat==Enum.Material.Grass or mat==Enum.Material.LeafyGrass)then
    if mat==Enum.Material.Ground and math.abs(x)<78 and z> -64 and z<54 then materials[ix][iy][iz]=Enum.Material.LeafyGrass restored+=1 end
    if distance<3.8 then materials[ix][iy][iz]=Enum.Material.Ground painted+=1 end
   end
  end
 end
 if ix%8==0 then task.wait()end
end
terrain:WriteVoxels(region,4,materials,occupancy)
report.paintedCells=painted report.restoredCells=restored
report.minimumDockDistance=math.huge
for i=1,5 do for j=i+1,5 do report.minimumDockDistance=math.min(report.minimumDockDistance,(pads[i]-pads[j]).Magnitude)end end
if recording then history:FinishRecording(recording,Enum.FinishRecordingOperation.Commit)end
return game:GetService("HttpService"):JSONEncode(report)
