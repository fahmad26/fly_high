assert(not game:GetService("RunService"):IsRunning())
local templates=game.ReplicatedStorage.FlyHigh.Templates
local models={templates.HotAirBalloon}for _,m in templates.BalloonVariants:GetChildren()do table.insert(models,m)end
for _,b in models do
 local root=b.PrimaryPart
 for _,p in b.EnvelopeRing:GetChildren()do
  if p:IsA("BasePart")and p.Name:match("^Walkway%d")then
   local q=root.CFrame:PointToObjectSpace(p.Position)local radius=Vector2.new(q.X,q.Z).Magnitude
   p.Size=Vector3.new(6.8,.55,3)
   p.CFrame=CFrame.new(root.CFrame:PointToWorldSpace(Vector3.new(q.X*16/radius,18.325,q.Z*16/radius)))*p.CFrame.Rotation
  end
 end
 local decor=b:FindFirstChild("GondolaDecor")
 if decor then for _,p in decor:GetChildren()do
  if p:IsA("BasePart")and(p.Name=="CatwalkPost"or p.Name=="CatwalkHandrail")then
   local q=root.CFrame:PointToObjectSpace(p.Position)local radius=math.sqrt(q.X*q.X+q.Z*q.Z)
   if radius>0 then p.CFrame=p.CFrame+root.CFrame:VectorToWorldSpace(Vector3.new(q.X,q.Y,q.Z)*Vector3.new(17.6/radius-1,0,17.6/radius-1))end
   if p.Name=="CatwalkHandrail"then p.Size=Vector3.new(6.87,p.Size.Y,p.Size.Z)end
  end
 end end
 local visual=b:FindFirstChild("EnvelopeVisual")
 local temp=visual and visual:Clone()or b.Envelope:Clone()
 temp.Parent=workspace
 for _,p in temp:GetDescendants()do if p:IsA("BasePart")then p.Anchored=true p.CanQuery=true end end
 if temp:IsA("BasePart")then temp.Anchored=true temp.CanQuery=true end
 local surfaces={}
 for _,p in temp:GetDescendants()do if p:IsA("BasePart")then local s=string.lower(p:GetAttribute("SkinSegment")or "")if s:find("envelope")or s=="body"then table.insert(surfaces,p)end end end
 if #surfaces==0 then surfaces={temp}end
 local params=RaycastParams.new()params.FilterType=Enum.RaycastFilterType.Include params.FilterDescendantsInstances=surfaces
 local placed={}
 for i=1,5 do
  local hole=b.HoleSlots["Hole"..i]local a=(i-1)*math.pi*2/5 local radial=Vector3.new(math.sin(a),0,-math.cos(a))
  for _,old in hole:GetChildren()do if old.Name=="FrayedCloth"then old:Destroy()end end
  local start=root.CFrame:PointToWorldSpace(radial*45+Vector3.new(0,24,0))
  local hit=workspace:Raycast(start,root.CFrame:VectorToWorldSpace(-radial*45),params)
  local function reach(h)
   if not h then return math.huge end local q=root.CFrame:PointToObjectSpace(h.Position)
   return math.sqrt((Vector2.new(q.X,q.Z).Magnitude-16)^2+(q.Y-20.5)^2)
  end
  if reach(hit)>9 then
   local best local score=math.huge
   for _,offset in {0,.2,-.2,.4,-.4,.6,-.6,.8,-.8,1,-1,1.2,-1.2,1.6,-1.6,2,-2,2.6,-2.6,math.pi}do for _,height in {24,22,26,20,28}do
    local v=Vector3.new(math.sin(a+offset),0,-math.cos(a+offset))
    local h=workspace:Raycast(root.CFrame:PointToWorldSpace(v*45+Vector3.new(0,height,0)),root.CFrame:VectorToWorldSpace(-v*45),params)
    local separate=true if h then for _,q in placed do if(q-h.Position).Magnitude<3 then separate=false end end end
    local rating=math.abs(offset)*3+math.abs(height-24)*.2+reach(h)*.1
    if separate and reach(h)<9.5 and rating<score then best=h score=rating end
   end end
   if best then hit=best end
  end
  if hit then table.insert(placed,hit.Position)end
  local point=hit and hit.Position or root.CFrame:PointToWorldSpace(radial*14+Vector3.new(0,24,0))
  local normal=hit and hit.Normal or root.CFrame:VectorToWorldSpace(radial)
  hole.CFrame=CFrame.lookAt(point+normal*.25,point+normal)
  hole.Shape=Enum.PartType.Ball hole.Size=Vector3.new(2.6,1.8,.09)hole.Material=Enum.Material.Fabric hole.Color=Color3.fromRGB(24,18,15)hole.Transparency=1
  for j=1,7 do
   local p=Instance.new("WedgePart")p.Name="FrayedCloth"p.Size=Vector3.new(.15,.5+(j%3)*.15,.12)
   local theta=j*math.pi*2/7
   p.CFrame=hole.CFrame*CFrame.new(math.cos(theta)*1.2,math.sin(theta)*.83,-.12)*CFrame.Angles(0,.3,theta-math.pi/2)
   p.Color=hit and hit.Instance.Color or Color3.fromRGB(166,111,71)p.Material=Enum.Material.Fabric
   p.CanCollide=false p.CanQuery=false p.CanTouch=false p.Massless=true p.Anchored=false p.Transparency=1 p.Parent=hole
   local w=Instance.new("WeldConstraint")w.Part0=hole w.Part1=p w.Parent=p
  end
 end
 temp:Destroy()
end
return #models

