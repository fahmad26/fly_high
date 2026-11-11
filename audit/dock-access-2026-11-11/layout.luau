local L=workspace.FlyHighLobby local T=workspace.Terrain
local history=game:GetService("ChangeHistoryService")local rec=history:TryBeginRecording("Dock access grading and paving")
local previous=L:FindFirstChild("DockPromenade")if previous then previous:Destroy()end
local M=Instance.new("Model")M.Name="DockPromenade" M.Parent=L
local report={paths={},movedDecor={},terrainColumns=0}
local rp0=RaycastParams.new()rp0.FilterType=Enum.RaycastFilterType.Include rp0.FilterDescendantsInstances={T}
local function terrainY(p)local hit=workspace:Raycast(Vector3.new(p.X,80,p.Z),-Vector3.yAxis*120,rp0)return hit and hit.Position.Y or 10 end
local natureGround={}for _,cat in {"Plants","Flowers","Rocks","Details","Trees"}do for _,obj in L.IslandNature[cat]:GetChildren()do if obj:IsA("PVInstance")then natureGround[obj]=terrainY(obj:GetPivot().Position)end end end
local routes={}local function add(a,b,kind)table.insert(routes,{a=a,b=b,kind=kind})end
local hub=Vector3.new(0,0,15)
local arc={}
for i=0,48 do local ang=math.rad(-90+i*180/48)arc[i+1]=Vector3.new(math.sin(ang)*70,0,15-math.cos(ang)*70)if i>0 then add(arc[i],arc[i+1],"Arc")end end
add(Vector3.new(0,0,23),Vector3.new(0,0,-55),"Main")
for i,name in {"Pod_A","Pod_B","Pod_C","Pod_D","Pod_E"}do local ang=math.rad((i-3)*45)local inward=Vector3.new(math.sin(ang),0,-math.cos(ang))add(hub+inward*70,hub+inward*81,"Branch_"..name)end
local function nearest(p)local dist=math.huge local q local chosen for _,r in routes do local v=r.b-r.a local t=math.clamp((Vector3.new(p.X,0,p.Z)-r.a):Dot(v)/v:Dot(v),0,1)local c=r.a+v*t local d=(Vector3.new(p.X,0,p.Z)-c).Magnitude if d<dist then dist=d q=c chosen=r end end return dist,q,chosen end
-- Grade land locally. Flat access core, then a 10-stud blend back into the island.
local region=Region3.new(Vector3.new(-120,4,-108),Vector3.new(120,44,52)):ExpandToGrid(4)
local mats,occ=T:ReadVoxels(region,4)local dim=region.Size/4 local origin=region.CFrame.Position-region.Size/2
for ix=1,dim.X do for iz=1,dim.Z do local x,z=origin.X+(ix-.5)*4,origin.Z+(iz-.5)*4 local dist=nearest(Vector3.new(x,0,z))-9
 for _,p in L.MatchmakingPods:GetChildren()do local v=p.FloorPad.Position dist=math.min(dist,Vector2.new(x-v.X,z-v.Z).Magnitude-22)end
 if dist<10 then local top=4 local land=false for iy=1,dim.Y do if occ[ix][iy][iz]>0 and mats[ix][iy][iz]~=Enum.Material.Water and mats[ix][iy][iz]~=Enum.Material.Air then top=origin.Y+(iy-1)*4+occ[ix][iy][iz]*4 land=true end end
  if land then local alpha=1-math.clamp(dist/10,0,1)alpha=alpha*alpha*(3-2*alpha)local target=top+(8-top)*alpha
   for iy=1,dim.Y do local y=origin.Y+(iy-1)*4 if mats[ix][iy][iz]~=Enum.Material.Water then occ[ix][iy][iz]=math.clamp((target-y)/4,0,1) mats[ix][iy][iz]=occ[ix][iy][iz]>0 and Enum.Material.LeafyGrass or Enum.Material.Air end end report.terrainColumns+=1
  end
 end
end if ix%8==0 then task.wait()end end
T:WriteVoxels(region,4,mats,occ)
for obj,oldY in pairs(natureGround)do local cf=obj:GetPivot()local newY=terrainY(cf.Position)obj:PivotTo(cf+Vector3.yAxis*(newY-oldY))end
local function part(name,size,cf,color,material,collide)
 local p=Instance.new("Part")p.Name=name p.Size=size p.CFrame=cf p.Anchored=true p.Color=color p.Material=material p.CanCollide=collide p.CanTouch=false p.CanQuery=collide p.CastShadow=false p.TopSurface=Enum.SurfaceType.Smooth p.BottomSurface=Enum.SurfaceType.Smooth p.Parent=M return p
end
local stone={Color3.fromRGB(199,184,148),Color3.fromRGB(206,191,157),Color3.fromRGB(193,180,148)}
local serial=0
for _,r in routes do
 local length=(r.b-r.a).Magnitude local count=math.ceil(length/4.6)
 for j=1,count do
  local a=r.a:Lerp(r.b,(j-1)/count)local b=r.a:Lerp(r.b,j/count)local mid=(a+b)/2 local cf=CFrame.lookAt(Vector3.new(mid.X,10.10,mid.Z),Vector3.new(b.X,10.10,b.Z))
  serial+=1 part("Paving_"..serial,Vector3.new(9,.32,(b-a).Magnitude+.04),cf,stone[serial%3+1],Enum.Material.Sandstone,true)
 end
 -- Low, nonblocking edging: do not make players jump to enter the path.
 local mid=(r.a+r.b)/2 local cf=CFrame.lookAt(Vector3.new(mid.X,10.14,mid.Z),Vector3.new(r.b.X,10.14,r.b.Z))
 for _,side in {-1,1}do part("FlushStoneBorder",Vector3.new(.45,.34,length+.2),cf*CFrame.new(side*4.72,0,0),Color3.fromRGB(139,133,112),Enum.Material.Limestone,false)end
 table.insert(report.paths,{kind=r.kind,a={r.a.X,r.a.Z},b={r.b.X,r.b.Z},width=9,top=10.26})
end
-- Discs hide angled seams and make clear circular junctions at each fork.
for _,i in {1,13,25,37,49}do local q=arc[i]local p=part("Junction",Vector3.new(.34,10,10),CFrame.new(q.X,10.10,q.Z)*CFrame.Angles(0,0,math.pi/2),stone[2],Enum.Material.Sandstone,true)p.Shape=Enum.PartType.Cylinder end
local rp=RaycastParams.new()rp.FilterType=Enum.RaycastFilterType.Include rp.FilterDescendantsInstances={T}
local function ground(p)local h=workspace:Raycast(Vector3.new(p.X,70,p.Z),Vector3.new(0,-100,0),rp)return h and h.Position.Y or 10 end
for _,category in {"Plants","Flowers","Rocks","Details"}do for _,obj in L.IslandNature[category]:GetChildren()do if obj:IsA("PVInstance")then local cf=obj:GetPivot()local p=cf.Position local d,q=nearest(p)if d<9 then local v=Vector3.new(p.X-q.X,0,p.Z-q.Z)if v.Magnitude<.01 then v=Vector3.xAxis end local dest=q+v.Unit*11 local oldY=ground(p)local newY=ground(dest)obj:PivotTo(cf+Vector3.new(dest.X-p.X,newY-oldY,dest.Z-p.Z))table.insert(report.movedDecor,obj.Name)end end end end
report.partCount=#M:GetChildren()
if rec then history:FinishRecording(rec,Enum.FinishRecordingOperation.Commit)end
return game:GetService("HttpService"):JSONEncode(report)
