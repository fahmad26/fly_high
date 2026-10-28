local assets=game.ReplicatedStorage.FlyHigh.EnvironmentAssets
local temp=Instance.new("Folder") temp.Name="NatureFlowerSculpt" temp.Parent=workspace
local offset=Vector3.new(0,200,0)
local pink=Color3.fromRGB(235,126,161)
local green=Color3.fromRGB(73,130,69)
local function triangle(a,b,c,color,parts)
 local ab=b-a local ac=c-a local bc=c-b
 if ab.Magnitude>ac.Magnitude and ab.Magnitude>bc.Magnitude then c,a=a,c
 elseif ac.Magnitude>ab.Magnitude and ac.Magnitude>bc.Magnitude then a,b=b,a end
 ab=b-a ac=c-a bc=c-b
 local right=ac:Cross(ab).Unit local up=bc:Cross(right).Unit local back=bc.Unit
 local height=math.abs(ab:Dot(up))
 for _,spec in ipairs({
  {p=(a+b)/2,r=right,u=up,b=back,length=math.abs(ab:Dot(back))},
  {p=(a+c)/2,r=-right,u=up,b=-back,length=math.abs(ac:Dot(back))}}) do
  local wedge=Instance.new("WedgePart")
  wedge.Size=Vector3.new(0.07,math.max(0.05,height),math.max(0.05,spec.length))
  wedge.CFrame=CFrame.fromMatrix(spec.p+offset,spec.r,spec.u,spec.b)
  wedge.Anchored=true wedge.CanCollide=false wedge.Color=color wedge.Material=Enum.Material.SmoothPlastic wedge.Parent=temp
  table.insert(parts,wedge)
 end
end
local function leaf(cf,color,parts,length,width)
 local pts={
  cf:PointToWorldSpace(Vector3.new(0,0,0)),
  cf:PointToWorldSpace(Vector3.new(-width/2,0.07,-length*0.45)),
  cf:PointToWorldSpace(Vector3.new(0,0.18,-length)),
  cf:PointToWorldSpace(Vector3.new(width/2,0.07,-length*0.45)),
  cf:PointToWorldSpace(Vector3.new(0,0.20,-length*0.42))}
 for _,t in ipairs({{1,2,5},{2,3,5},{3,4,5},{4,1,5}}) do triangle(pts[t[1]],pts[t[2]],pts[t[3]],color,parts) end
end
local function union(parts,name,color,parent)
 local first=table.remove(parts,1)
 local result=first:UnionAsync(parts,Enum.CollisionFidelity.Box,Enum.RenderFidelity.Automatic)
 result.Name=name result.UsePartColor=true result.Color=color result.Anchored=true result.CanCollide=false result.CanTouch=false result.CanQuery=false
 result.Parent=parent first:Destroy() for _,p in ipairs(parts) do p:Destroy() end
 return result
end
local flower=Instance.new("Model") flower.Name="Flower"
local petals={}
for i=0,5 do
 leaf(CFrame.new(0,2.12,0)*CFrame.Angles(0,i*math.pi/3,0),pink,petals,0.9,0.65)
end
union(petals,"PetalCorolla",pink,flower)
local foliage={}
local points={Vector3.new(0,0,0),Vector3.new(0.15,0.8,0),Vector3.new(-0.1,1.6,0.08),Vector3.new(0,2.15,0)}
for i=1,#points-1 do
 local a,b=points[i],points[i+1]
 local p=Instance.new("Part") p.Name="Stem" p.Shape=Enum.PartType.Cylinder p.Size=Vector3.new((b-a).Magnitude+0.05,0.10,0.10)
 p.CFrame=CFrame.new(offset)*CFrame.lookAt((a+b)/2,b)*CFrame.Angles(0,math.pi/2,0)
 p.Anchored=true p.CanCollide=false p.Color=green p.Parent=temp table.insert(foliage,p)
end
leaf(CFrame.new(0.08,0.85,0)*CFrame.Angles(-0.15,1.1,-0.3),green,foliage,0.85,0.38)
leaf(CFrame.new(-0.06,1.25,0)*CFrame.Angles(-0.2,-1.15,0.25),green,foliage,0.7,0.32)
union(foliage,"CurvedStemAndLeaves",green,flower)
local center=Instance.new("Part") center.Name="GoldenPollen" center.Shape=Enum.PartType.Cylinder center.Size=Vector3.new(0.14,0.35,0.35)
center.CFrame=CFrame.new(offset+Vector3.new(0,2.24,0))*CFrame.Angles(0,0,math.pi/2)
center.Anchored=true center.CanCollide=false center.CanTouch=false center.CanQuery=false center.Color=Color3.fromRGB(246,190,58) center.Parent=flower
local root=Instance.new("Part") root.Name="NatureRoot" root.Size=Vector3.new(0.2,0.2,0.2) root.Transparency=1
root.Anchored=true root.CanCollide=false root.CanTouch=false root.CanQuery=false root.CFrame=CFrame.new(offset) root.Parent=flower flower.PrimaryPart=root
flower:PivotTo(CFrame.identity)
for _,p in ipairs(flower:GetDescendants()) do if p:IsA("BasePart") and p~=root then p:SetAttribute("RestCFrame",p.CFrame) p:SetAttribute("Segment","flower") end end
local old=assets:FindFirstChild("Flower") if old then old:Destroy() end
flower.Parent=assets temp:Destroy()
return {petals=tostring(flower.PetalCorolla.Size),leaf=tostring(flower.CurvedStemAndLeaves.Size)}
