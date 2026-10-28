local templates=game.ReplicatedStorage.FlyHigh.Templates
local lib=templates.FleetGeometry
local offset=Vector3.new(250,220,0)
local temp=Instance.new("Folder") temp.Name="LotusSculptTemporary" temp.Parent=workspace
local function triangle(a,b,c,parts)
 local ab=b-a local ac=c-a local bc=c-b
 if ab.Magnitude>ac.Magnitude and ab.Magnitude>bc.Magnitude then c,a=a,c
 elseif ac.Magnitude>ab.Magnitude and ac.Magnitude>bc.Magnitude then a,b=b,a end
 ab=b-a ac=c-a bc=c-b
 local right=ac:Cross(ab).Unit local up=bc:Cross(right).Unit local back=bc.Unit
 for _,s in ipairs({{p=(a+b)/2,r=right,b=back,l=math.abs(ab:Dot(back))},{p=(a+c)/2,r=-right,b=-back,l=math.abs(ac:Dot(back))}}) do
  local w=Instance.new("WedgePart") w.Size=Vector3.new(0.12,math.max(0.05,math.abs(ab:Dot(up))),math.max(0.05,s.l))
  w.CFrame=CFrame.fromMatrix(offset+s.p,s.r,up,s.b) w.Anchored=true w.Parent=temp table.insert(parts,w)
 end
end

local function sculpt(name,points)
 local old=lib:FindFirstChild(name)if old then old:Destroy()end
 local pieces={}
 for i=2,#points-1 do triangle(points[1],points[i],points[i+1],pieces)end
 local first=table.remove(pieces,1)
 local result=first:UnionAsync(pieces,Enum.CollisionFidelity.Box,Enum.RenderFidelity.Automatic)
 result.Name="SculptedPetal" result.UsePartColor=true result.Material=Enum.Material.SmoothPlastic
 local m=Instance.new("Model")m.Name=name
 local root=Instance.new("Part")root.Name="GeometryRoot"root.Size=Vector3.one*.1 root.CFrame=CFrame.new(offset)root.Transparency=1 root.Anchored=true root.CanCollide=false root.CanQuery=false root.CanTouch=false root.Parent=m m.PrimaryPart=root
 result.Parent=m result.Anchored=true result.CanCollide=false result.CanQuery=false result.CanTouch=false
 m:PivotTo(CFrame.identity)m.Parent=lib
 first:Destroy()for _,p in ipairs(pieces)do p:Destroy()end
end
sculpt("LotusPetal",{Vector3.new(0,0,0),Vector3.new(-2.8,5,2.8),Vector3.new(-4.4,13,4.6),Vector3.new(-3.3,20,3.8),Vector3.new(0,27,1.2),Vector3.new(3.3,20,3.8),Vector3.new(4.4,13,4.6),Vector3.new(2.8,5,2.8)})
sculpt("LotusLeaf",{Vector3.new(0,0,0),Vector3.new(-3,1,2),Vector3.new(-3.6,2.6,5),Vector3.new(0,5,9),Vector3.new(3.6,2.6,5),Vector3.new(3,1,2)})
temp:Destroy()return "Sculpted petals and leaf skirt cached"
