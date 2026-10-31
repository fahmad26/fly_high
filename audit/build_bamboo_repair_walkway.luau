assert(not game:GetService("RunService"):IsRunning())
local templates=game.ReplicatedStorage.FlyHigh.Templates
local models={templates.HotAirBalloon}for _,b in templates.BalloonVariants:GetChildren()do table.insert(models,b)end
local report={}
for _,b in models do
 local root=b.PrimaryPart local old=b:FindFirstChild("BambooRigging")if old then old:Destroy()end
 local model=Instance.new("Model")model.Name="BambooRigging"
 local function part(name,size,cf,color,material,shape,collide)
  local p=Instance.new("Part")p.Name=name p.Size=size p.CFrame=cf p.Color=color p.Material=material
  if shape then p.Shape=shape end
  p.Anchored=false p.Massless=true p.CanCollide=collide==true p.CanQuery=false p.CanTouch=false p.Parent=model
  local w=Instance.new("WeldConstraint")w.Part0=root w.Part1=p w.Parent=p return p
 end
 local bamboo=Color3.fromRGB(173,155,75)local joint=Color3.fromRGB(104,105,48)local rope=Color3.fromRGB(119,86,53)
 local function line(name,a,c,diameter)
  local delta=c-a
  return part(name,Vector3.new(delta.Magnitude,diameter,diameter),CFrame.lookAt((a+c)/2,c)*CFrame.Angles(0,math.pi/2,0),rope,Enum.Material.Fabric,Enum.PartType.Cylinder)
 end
 local decor=b:FindFirstChild("GondolaDecor")
 if decor then for _,p in decor:GetChildren()do if p.Name=="CatwalkPost"or p.Name=="CatwalkHandrail"or p.Name=="SuspensionRope"then p:Destroy()end end end
 for _,floor in b.EnvelopeRing:GetChildren()do if floor:IsA("BasePart")and floor.Name:match("^Walkway%d")then
  -- Preserve the complete walking surface and original landing height.
  floor.Transparency=1 floor.CanCollide=true floor.CanQuery=true
  for _,side in {-1,1}do
   local cf=floor.CFrame*CFrame.new(0,.065,side*.66)
   part("BambooPole",Vector3.new(6.8,.42,.42),cf,bamboo,Enum.Material.Wood,Enum.PartType.Cylinder)
   for _,x in {-2.5,0,2.5}do part("BambooNode",Vector3.new(.10,.46,.46),cf*CFrame.new(x,0,0),joint,Enum.Material.Wood,Enum.PartType.Cylinder)end
  end
 end end
 -- Raycast only against the visible main envelope, not fins/rings/ornaments.
 local skin=b:FindFirstChild("EnvelopeVisual")or b.Envelope
 local temp=skin:Clone()temp.Parent=workspace local surfaces={}
 if temp:IsA("BasePart")then temp.Anchored=true temp.CanQuery=true table.insert(surfaces,temp)end
 for _,p in temp:GetDescendants()do if p:IsA("BasePart")then
  p.Anchored=true p.CanQuery=true
  local s=string.lower(p:GetAttribute("SkinSegment")or "")if s:find("envelope")or s=="body"then table.insert(surfaces,p)end
 end end
 if #surfaces==0 then table.insert(surfaces,temp)end
 local params=RaycastParams.new()params.FilterType=Enum.RaycastFilterType.Include params.FilterDescendantsInstances=surfaces
 local function anchor(angle)
  local v=Vector3.new(math.sin(angle),0,math.cos(angle))
  for _,y in {28,30,26,32,24}do
   local hit=workspace:Raycast(root.CFrame:PointToWorldSpace(v*55+Vector3.new(0,y,0)),root.CFrame:VectorToWorldSpace(-v*80),params)
   if hit then return hit.Position-hit.Normal*.04 end
  end
  error("No visible envelope attachment: "..b.Name)
 end
 local anchors=0
 for i=0,15 do
  local a=i*math.pi/8 local c=(i+1)*math.pi/8
  local p=root.CFrame:PointToWorldSpace(Vector3.new(math.sin(a)*17.6,21.1,math.cos(a)*17.6))
  local q=root.CFrame:PointToWorldSpace(Vector3.new(math.sin(c)*17.6,21.1,math.cos(c)*17.6))
  line("SafetyHandrope",p,q,.12)
  local guard=part("BambooGuard",Vector3.new((q-p).Magnitude,2.5,.28),CFrame.lookAt((p+q)/2-Vector3.new(0,1.1,0),q-Vector3.new(0,1.1,0))*CFrame.Angles(0,math.pi/2,0),rope,Enum.Material.Fabric,nil,true)guard.Transparency=1
  if i%2==0 then
   local base=root.CFrame:PointToWorldSpace(Vector3.new(math.sin(a)*16,18.6,math.cos(a)*16))
   local top=anchor(a)
   line("EnvelopeTie",base,top,.14)anchors+=1
   part("EnvelopeTiePatch",Vector3.new(.3,.3,.3),CFrame.new(top),rope,Enum.Material.Fabric,Enum.PartType.Ball)
   line("HandropeLashing",base,p,.12)
  end
 end
 -- Basket suspension uses the same actual-skin anchors.
 for _,x in {-12,12}do for _,z in {-12,12}do
  local base=root.CFrame:PointToWorldSpace(Vector3.new(x,4.6,z))
  line("BasketSuspension",base,anchor(math.atan2(x,z)),.19)
 end end
 temp:Destroy()model.Parent=b
 table.insert(report,{name=b.Name,bambooPoles=32,envelopeTies=anchors})task.wait()
end
return report
