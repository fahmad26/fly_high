assert(game:GetService("RunService"):IsStudio() and not game:GetService("RunService"):IsRunning())
local RS=game.ReplicatedStorage
local templates=RS.FlyHigh.Templates
local Themes=require(RS.FlyHigh.Modules.BalloonThemes)
local variants=templates:FindFirstChild("BalloonVariants") or Instance.new("Folder")
variants.Name="BalloonVariants" variants.Parent=templates
local gold=Color3.fromRGB(187,150,81)
local ropeColor=Color3.fromRGB(203,178,131)
local function part(parent,name,size,cf,color,material,shape,fine)
 local p=Instance.new("Part") p.Name=name p.Size=size p.CFrame=cf p.Color=color p.Material=material or Enum.Material.Wood
 p.Shape=shape or Enum.PartType.Block p.Anchored=true p.CanCollide=false p.CanTouch=false p.CanQuery=false p.Massless=true
 if fine then p:SetAttribute("FineDetail",true) end p.Parent=parent return p
end
local function rod(parent,name,a,b,width,color,material,fine)
 local delta=b-a
 if delta.Magnitude<0.01 then return nil end
 return part(parent,name,Vector3.new(delta.Magnitude,width,width),CFrame.lookAt((a+b)/2,b)*CFrame.Angles(0,math.pi/2,0),color,material,Enum.PartType.Cylinder,fine)
end
local function cylinder(parent,name,position,height,diameter,color,material)
 return part(parent,name,Vector3.new(height,diameter,diameter),CFrame.new(position)*CFrame.Angles(0,0,math.pi/2),color,material,Enum.PartType.Cylinder)
end
local function geometry(name,parent,cf,scale,color)
 local m=templates.FleetGeometry[name]:Clone() m.Name=name
 m:ScaleTo(m:GetScale()*(scale or 1)) m:PivotTo(cf) m.Parent=parent
 for _,p in ipairs(m:GetDescendants()) do if p:IsA("BasePart") and p.Transparency<1 and color then p.Color=color end end
 return m
end
local function motor(root,p,hinge,motion)
 local joint=Instance.new("Motor6D")
 joint.Name="Visual_"..motion joint.Part0=root joint.Part1=p joint.C0=CFrame.new(hinge)
 joint.C1=p.CFrame:ToObjectSpace(root.CFrame*joint.C0)
 joint:SetAttribute("BalloonMotion",motion) joint.Parent=p
 return joint
end
local summary={}
for _,pod in ipairs(Themes.Order) do
 local theme=Themes.Get(pod)
 local old=variants:FindFirstChild(theme.Template) if old then old:Destroy() end
 local b=templates.HotAirBalloon:Clone() b.Name=theme.Template b:PivotTo(CFrame.identity)
 b:SetAttribute("BalloonThemeId",theme.Id) b:SetAttribute("BalloonThemeName",theme.Name)
 b:SetAttribute("TethersSetup",nil)
 local root=b.RootPart
 b.Envelope.Transparency=1 b.Envelope.CanQuery=false b.Envelope.CanTouch=false
 b.EnvelopeStripe.Transparency=1 b.EnvelopeStripe.CanCollide=false b.EnvelopeStripe.CanQuery=false
 local decor=Instance.new("Folder") decor.Name="GondolaDecor" decor.Parent=b
 local visual=templates.BalloonSkins[theme.Id]:Clone()
 visual.Name="EnvelopeVisual" visual:PivotTo(CFrame.new(0,theme.Id=="D" and 32 or (theme.Id=="C" and 31 or 28),0)) visual.Parent=b
 local animated={}
 if theme.Id=="C" then
  for _,p in ipairs(visual:GetDescendants()) do
   if p:IsA("BasePart") and p:GetAttribute("SkinSegment")=="tail" then
    motor(root,p,Vector3.new(0,32,10),"KoiTail") animated[p]=true
   elseif p:IsA("BasePart") and string.find(p:GetAttribute("SkinSegment") or "","fin") then
    motor(root,p,Vector3.new((p.Position.X<0 and -7 or 7),28,0),"KoiFin") animated[p]=true
   end
  end
 end
 if theme.Id=="B" then
  for i=0,7 do
   local a=i*math.pi/4
   geometry("LotusPetal",visual,CFrame.new(math.sin(a)*11.5,15,math.cos(a)*11.5)*CFrame.Angles(0,a,0),1,i%2==0 and Color3.fromRGB(235,137,166) or Color3.fromRGB(249,184,199))
   geometry("LotusLeaf",visual,CFrame.new(math.sin(a)*7,11,math.cos(a)*7)*CFrame.Angles(0,a,0),1,Color3.fromRGB(94,143,104))
  end
 end
 if theme.Id=="D" then
  geometry("SaturnRing",visual,CFrame.new(0,33,0)*CFrame.Angles(math.rad(18),0,math.rad(7)),1,Color3.fromRGB(204,174,116))
  for i=1,3 do
   local m=geometry("Star",visual,CFrame.new(math.cos(i*2.1)*19,35+math.sin(i*2.1)*3,math.sin(i*2.1)*19),0.65,gold)
   for _,p in ipairs(m:GetDescendants()) do
    if p:IsA("BasePart") and p.Transparency<1 then
     motor(root,p,Vector3.new(0,34,0),"OrbitStar") animated[p]=true
     p:SetAttribute("OrbitSpeed",0.09+i*0.015)
    end
   end
  end
 end
 b.BasketFloor.Material=Enum.Material.WoodPlanks b.BasketFloor.Color=theme.Dark:Lerp(Color3.fromRGB(175,135,83),0.4)
 local railingNames={"RailingNorth","RailingSouth","RailingEast","RailingWest"}
 for side,name in ipairs(railingNames) do
  local rail=b[name] rail.Color=theme.Dark rail.Material=Enum.Material.WoodPlanks
  if theme.Id=="A" or theme.Id=="B" then
   rail.Transparency=1
   for row=0,8 do
    local y=0.8+row*0.4
    if side<=2 then
     local z=side==1 and -13.6 or 13.6
     rod(decor,"WickerWeave",Vector3.new(-13,y,z),Vector3.new(13,y,z),0.24,theme.Id=="A" and Color3.fromRGB(179,135,80) or theme.Dark,Enum.Material.Wood,true)
    else
     local x=side==3 and 13.6 or -13.6
     rod(decor,"WickerWeave",Vector3.new(x,y,-13),Vector3.new(x,y,13),0.24,theme.Id=="A" and Color3.fromRGB(179,135,80) or theme.Dark,Enum.Material.Wood,true)
    end
   end
   for n=-3,3 do
    local d=n*3.6
    if side<=2 then
     local z=side==1 and -13.65 or 13.65
     rod(decor,"BasketBinding",Vector3.new(d-1,0.7,z),Vector3.new(d+1,4,z),0.16,theme.Dark,Enum.Material.Wood,true)
    else
     local x=side==3 and 13.65 or -13.65
     rod(decor,"BasketBinding",Vector3.new(x,0.7,d-1),Vector3.new(x,4,d+1),0.16,theme.Dark,Enum.Material.Wood,true)
    end
   end
  end
 end
 for _,z in ipairs({-13.6,13.6}) do rod(decor,"BasketRim",Vector3.new(-13.8,4.6,z),Vector3.new(13.8,4.6,z),0.38,theme.Accent,Enum.Material.Wood) end
 for _,x in ipairs({-13.6,13.6}) do rod(decor,"BasketRim",Vector3.new(x,4.6,-13.8),Vector3.new(x,4.6,13.8),0.38,theme.Accent,Enum.Material.Wood) end
 for _,x in ipairs({-12,12}) do
  for _,z in ipairs({-12,12}) do
   rod(decor,"SuspensionRope",Vector3.new(x,4.6,z),Vector3.new(x*0.91,27,z*0.91),0.19,ropeColor,Enum.Material.Fabric)
   if theme.Id=="B" then
    local flower=RS.FlyHigh.EnvironmentAssets.Flower:Clone()
    flower.Name="FlowerCarving" flower:ScaleTo(flower:GetScale()*0.9)
    flower:PivotTo(CFrame.new(x,2.4,z)*CFrame.Angles(0,math.atan2(x,z),0)) flower.Parent=decor
    if flower:FindFirstChild("PetalCorolla") then flower.PetalCorolla.Color=theme.Accent end
   elseif theme.Id=="E" then
    rod(decor,"PavilionPost",Vector3.new(x,0.5,z),Vector3.new(x,9,z),0.45,theme.Dark,Enum.Material.Wood)
    local eave=Instance.new("CornerWedgePart") eave.Name="UpturnedEave" eave.Size=Vector3.new(4.8,1.3,4.8)
    eave.CFrame=CFrame.new(x,9,z)*CFrame.Angles(0,math.atan2(x,z)+math.pi/4,0) eave.Color=gold eave.Material=Enum.Material.Metal eave.Anchored=true eave.CanCollide=false eave.CanTouch=false eave.CanQuery=false eave.Parent=decor
    local tassel=part(decor,"LanternTassel",Vector3.new(0.28,1.8,0.28),CFrame.new(x,6.6,z),gold,Enum.Material.Fabric)
    motor(root,tassel,Vector3.new(x,7.5,z),"Tassel") animated[tassel]=true
   end
  end
 end
 if theme.Id=="E" then
  for _,z in ipairs({-12,12}) do rod(decor,"PavilionCornice",Vector3.new(-12,8.7,z),Vector3.new(12,8.7,z),0.7,theme.Dark,Enum.Material.Wood) end
  for _,x in ipairs({-12,12}) do rod(decor,"PavilionCornice",Vector3.new(x,8.7,-12),Vector3.new(x,8.7,12),0.7,theme.Dark,Enum.Material.Wood) end
 elseif theme.Id=="C" then
  for _,s in ipairs({-1,1}) do
   for _,x in ipairs({-6.6,6.6}) do
    local prow=Instance.new("CornerWedgePart") prow.Name="BoatProw" prow.Size=Vector3.new(13,3.2,6.5)
    prow.CFrame=CFrame.new(x,-0.2,s*15)*CFrame.Angles(0,(x<0 and math.pi or 0)+(s<0 and math.pi/2 or -math.pi/2),0)
    prow.Color=theme.Dark prow.Material=Enum.Material.WoodPlanks prow.Anchored=true prow.CanCollide=false prow.CanTouch=false prow.CanQuery=false prow.Parent=decor
   end
  end
  for _,x in ipairs({-14.1,14.1}) do
   for i=0,10 do
    local a=Vector3.new(x,2.4+math.sin(i*0.8)*0.35,-12+i*2.3)
    local c=Vector3.new(x,2.4+math.sin((i+1)*0.8)*0.35,-12+(i+1)*2.3)
    rod(decor,"WaveTrim",a,c,0.16,theme.Accent,Enum.Material.Metal,true)
   end
  end
 elseif theme.Id=="D" then
  for _,s in ipairs({-1,1}) do geometry("Star",decor,CFrame.new(s*9,2.7,-14.1),0.85,gold) end
  local a=Vector3.new(8,3.8,-10) local c=Vector3.new(8,5.6,-13)
  rod(decor,"Telescope",a,c,0.8,theme.Dark,Enum.Material.Metal)
  rod(decor,"TelescopeRim",c-(c-a).Unit*0.2,c,1.0,gold,Enum.Material.Metal)
  rod(decor,"TelescopeStand",Vector3.new(8,0.8,-10),a,0.25,gold,Enum.Material.Metal)
 end
 -- Open catwalk rails keep the repair deck readable instead of a second wooden basket.
 for _,o in ipairs(b.EnvelopeRing:GetChildren()) do
  if string.sub(o.Name,1,4)=="Rail" then o.Transparency=1
  elseif o:IsA("BasePart") then o.Color=theme.Dark:Lerp(Color3.fromRGB(145,125,96),0.55) end
 end
 for i=0,15 do
  local a=i*math.pi/8 local nextAngle=(i+1)*math.pi/8
  local p=Vector3.new(math.sin(a)*23.1,0,math.cos(a)*23.1)
  local q=Vector3.new(math.sin(nextAngle)*23.1,0,math.cos(nextAngle)*23.1)
  rod(decor,"CatwalkPost",p+Vector3.new(0,18.6,0),p+Vector3.new(0,21.5,0),0.15,gold,Enum.Material.Metal)
  rod(decor,"CatwalkHandrail",p+Vector3.new(0,21.5,0),q+Vector3.new(0,21.5,0),0.17,gold,Enum.Material.Metal)
 end
 -- A visible wheel, burner housing and rope spool preserve the existing interaction anchors.
 b.Burner.Transparency=1
 cylinder(decor,"BurnerHousing",Vector3.new(0,9.6,0),1.1,2.5,Color3.fromRGB(54,56,59),Enum.Material.Metal)
 cylinder(decor,"BurnerBrassBand",Vector3.new(0,9.2,0),0.2,2.7,gold,Enum.Material.Metal)
 b.HelmSeat.Color=theme.Dark b.HelmSeat.Material=Enum.Material.Wood
 geometry("DockRim",decor,CFrame.new(0,3.2,-12.4)*CFrame.Angles(math.rad(73),0,0),0.105,gold)
 rod(decor,"WheelStand",Vector3.new(0,0.8,-12),Vector3.new(0,3.2,-12.4),0.25,theme.Dark,Enum.Material.Wood)
 for i=0,5 do
  local a=i*math.pi/3
  local cf=CFrame.new(0,3.2,-12.4)*CFrame.Angles(math.rad(73),0,0)
  rod(decor,"WheelSpoke",cf.Position,cf:PointToWorldSpace(Vector3.new(math.cos(a)*1.08,0,math.sin(a)*1.08)),0.1,gold,Enum.Material.Metal,true)
 end
 b.TetherStation.Transparency=1
 part(decor,"RopeSpool",Vector3.new(2.0,1.7,1.7),CFrame.new(0,2,11),ropeColor,Enum.Material.Fabric,Enum.PartType.Cylinder)
 for _,x in ipairs({-1.1,1.1}) do
  part(decor,"SpoolFlange",Vector3.new(0.17,2.1,2.1),CFrame.new(x,2,11),theme.Dark,Enum.Material.Wood,Enum.PartType.Cylinder)
 end
 for _,name in ipairs({"WeaponRack1","WeaponRack2"}) do
  local rack=b[name] rack.Color=theme.Dark rack.Material=Enum.Material.Wood
 end
 -- Every piece belongs to one server-owned assembly; animated pieces use visual motors.
 for _,w in ipairs(b:GetDescendants()) do if w:IsA("WeldConstraint") then w:Destroy() end end
 local count=0
 for _,p in ipairs(b:GetDescendants()) do
  if p:IsA("BasePart") then
   count+=1 p.Anchored=false
   if p~=root then
    p.Massless=true
    if not animated[p] then local w=Instance.new("WeldConstraint") w.Name="FleetWeld" w.Part0=root w.Part1=p w.Parent=p end
   end
  end
 end
 root.Massless=false root.RootPriority=127
 b.Parent=variants
 table.insert(summary,{theme=theme.Name,template=b.Name,parts=count,motors=(function() local n=0 for _ in pairs(animated) do n+=1 end return n end)()})
 task.wait()
end
return summary
