assert(game:GetService("RunService"):IsStudio() and not game:GetService("RunService"):IsRunning())
local templates=game.ReplicatedStorage.FlyHigh.Templates
local lib=templates:FindFirstChild("FleetGeometry") or Instance.new("Folder")
lib.Name="FleetGeometry" lib.Parent=templates
local offset=Vector3.new(250,220,0)
local temp=Instance.new("Folder") temp.Name="FleetGeometryTemporary" temp.Parent=workspace
local function finish(part,name)
 local model=Instance.new("Model") model.Name=name
 local root=Instance.new("Part") root.Name="GeometryRoot" root.Size=Vector3.new(0.1,0.1,0.1)
 root.CFrame=CFrame.new(offset) root.Transparency=1 root.Anchored=true root.CanCollide=false root.CanTouch=false root.CanQuery=false root.Parent=model model.PrimaryPart=root
 part.Parent=model part.Anchored=true part.CanCollide=false part.CanTouch=false part.CanQuery=false
 model:PivotTo(CFrame.identity) model.Parent=lib return model
end
local function annulus(name,outer,inner,height)
 if lib:FindFirstChild(name) then return end
 local a=Instance.new("Part") a.Shape=Enum.PartType.Cylinder a.Size=Vector3.new(height,outer*2,outer*2)
 a.CFrame=CFrame.new(offset)*CFrame.Angles(0,0,math.pi/2) a.Anchored=true a.Parent=temp
 local b=a:Clone() b.Size=Vector3.new(height+4,inner*2,inner*2) b.Parent=temp
 local ring=a:SubtractAsync({b},Enum.CollisionFidelity.Box,Enum.RenderFidelity.Automatic)
 ring.Name="Ring" ring.UsePartColor=true ring.Material=Enum.Material.Metal ring.Color=Color3.fromRGB(190,151,83)
 finish(ring,name) a:Destroy() b:Destroy()
end
annulus("DockRim",11.15,10.85,0.13)
annulus("SaturnRing",23,17.4,0.42)
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
if not lib:FindFirstChild("Star") then
 local points={}
 for i=0,9 do local a=math.pi/2+i*math.pi/5 local r=i%2==0 and 1 or 0.44 table.insert(points,Vector3.new(math.cos(a)*r,math.sin(a)*r,0)) end
 local pieces={}
 for i=1,10 do triangle(Vector3.zero,points[i],points[i%10+1],pieces) end
 local first=table.remove(pieces,1) local star=first:UnionAsync(pieces,Enum.CollisionFidelity.Box,Enum.RenderFidelity.Automatic)
 star.Name="Star" star.UsePartColor=true star.Color=Color3.fromRGB(237,192,89) star.Material=Enum.Material.Metal
 finish(star,"Star") first:Destroy() for _,p in ipairs(pieces) do p:Destroy() end
end
temp:Destroy()
return #lib:GetChildren()
