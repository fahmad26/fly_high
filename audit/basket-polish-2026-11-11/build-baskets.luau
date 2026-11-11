local T=game.ReplicatedStorage.FlyHigh.Templates
local Themes=require(game.ReplicatedStorage.FlyHigh.Modules.BalloonThemes)
local targets={T.HotAirBalloon} for _,b in ipairs(T.BalloonVariants:GetChildren())do table.insert(targets,b)end
local results={}
for _,b in ipairs(targets)do
 local root=b.PrimaryPart local pivot=b:GetPivot()
 local theme=Themes.ByPod.Pod_A for _,v in pairs(Themes.ByPod)do if v.Template==b.Name then theme=v end end
 local old=b:FindFirstChild("GondolaFinish",true)if old then old:Destroy()end
 local decor=b:FindFirstChild("GondolaDecor",true)
 if decor then for _,o in decor:GetChildren()do if o.Name=="WickerWeave"or o.Name=="BasketBinding"or o.Name=="BasketRim"then o:Destroy()end end end
 local oldNew=b:FindFirstChild("GondolaCraft")if oldNew then oldNew:Destroy()end
 local m=Instance.new("Model")m.Name="GondolaCraft"
 local wood=Color3.fromRGB(94,52,32)local brass=Color3.fromRGB(205,159,76)
 local weave=theme.Dark:Lerp(Color3.fromRGB(181,128,70),0.52)
 local count=0
 local function p(name,size,cf,color,mat,shape)
  local v=Instance.new("Part")v.Name=name v.Size=size v.CFrame=pivot*cf v.Color=color v.Material=mat or Enum.Material.Wood
  if shape then v.Shape=shape end
  v.TopSurface=Enum.SurfaceType.Smooth v.BottomSurface=Enum.SurfaceType.Smooth
  v.CanCollide=false v.CanTouch=false v.CanQuery=false v.Massless=true v.CastShadow=size.Magnitude>3 v.Anchored=false v.Parent=m
  local w=Instance.new("WeldConstraint")w.Part0=root w.Part1=v w.Parent=v count+=1 return v
 end
 local function beam(name,a,c,width,color,mat)
  return p(name,Vector3.new((a-c).Magnitude,width,width),CFrame.lookAt((a+c)/2,c)*CFrame.Angles(0,math.pi/2,0),color,mat,Enum.PartType.Cylinder)
 end
 -- Four broad sides and four clipped corners soften the box silhouette.
 local points={Vector3.new(-12,0,-13.65),Vector3.new(12,0,-13.65),Vector3.new(13.65,0,-12),Vector3.new(13.65,0,12),Vector3.new(12,0,13.65),Vector3.new(-12,0,13.65),Vector3.new(-13.65,0,12),Vector3.new(-13.65,0,-12)}
 for i,a in ipairs(points)do
  local c=points[i%#points+1]local center=(a+c)/2 local n=Vector3.new(center.X,0,center.Z).Unit
  local len=(c-a).Magnitude
  local function face(y,depth)local pos=center+Vector3.yAxis*y+n*depth return CFrame.lookAt(pos,pos+n)end
  p("WovenPanel",Vector3.new(len,3.45,0.3),face(2.35,0),weave,Enum.Material.Fabric)
  for row=1,6 do p("WickerStrand",Vector3.new(len,0.075,0.08),face(0.75+row*0.48,0.19),weave:Lerp(brass,row%2==0 and 0.2 or 0.05))end
  beam("MahoganyHandrail",a+Vector3.new(0,4.42,0),c+Vector3.new(0,4.42,0),0.55,wood)
  beam("BrassCrown",a+Vector3.new(0,4.73,0),c+Vector3.new(0,4.73,0),0.10,brass,Enum.Material.Metal)
  p("LowerFrame",Vector3.new(len,0.45,0.5),face(0.65,0.04),wood)
  p("AccentRibbon",Vector3.new(len,0.32,0.09),face(3.75,0.21),theme.Accent,Enum.Material.SmoothPlastic)
  if len>10 then for _,x in ipairs({-8,-4,0,4,8})do
   local pos=face(2.38,0.23)*CFrame.new(x,0,0)
   p("LeatherBinding",Vector3.new(0.22,3.12,0.09),pos,wood,Enum.Material.Fabric)
   for _,dy in ipairs({-1.30,1.30})do p("BindingStud",Vector3.new(0.10,0.10,0.10),pos*CFrame.new(0,dy,0.08),brass,Enum.Material.Metal,Enum.PartType.Ball)end
  end end
  -- Tapered underside follows the same octagonal perimeter; no dangling boards.
  local aa=a*0.94 local cc=c*0.94 local mid=(aa+cc)/2
  p("HullFascia",Vector3.new(len*0.94,1.45,0.5),CFrame.lookAt(mid+Vector3.new(0,-0.65,0),mid+n+Vector3.new(0,-0.65,0))*CFrame.Angles(math.rad(-12),0,0),wood)
  beam("HullBrassBand",aa+Vector3.new(0,-1.18,0),cc+Vector3.new(0,-1.18,0),0.16,brass,Enum.Material.Metal)
  p("CornerStile",Vector3.new(0.55,4,0.55),CFrame.new(a+Vector3.new(0,2.5,0)),wood)
  for _,y in ipairs({0.85,3.65})do p("CornerCuff",Vector3.new(0.64,0.18,0.64),CFrame.new(a+Vector3.new(0,y,0)),brass,Enum.Material.Metal)end
 end
 -- Inset teak deck, seams and a brass navigation rose are purely visual.
 for i=0,13 do
  local shade=Color3.fromRGB(139+(i%3)*7,88+(i%3)*5,48+(i%3)*3)
  p("TeakDeck",Vector3.new(1.80,0.025,25.4),CFrame.new(-12.03+i*1.85,0.617,0),shade,Enum.Material.Wood)
 end
 for _,x in ipairs({-11.1,11.1})do p("DeckBorder",Vector3.new(0.08,0.025,22.2),CFrame.new(x,0.64,0),brass,Enum.Material.Metal)end
 for i=0,15 do local a=i*math.pi/8 local c=(i+1)*math.pi/8 beam("CompassRing",Vector3.new(math.cos(a)*1.7,0.66,math.sin(a)*1.7),Vector3.new(math.cos(c)*1.7,0.66,math.sin(c)*1.7),0.07,brass,Enum.Material.Metal)end
 for i=0,3 do p("CompassRay",Vector3.new(0.12,0.03,1.2),CFrame.Angles(0,i*math.pi/2,0)*CFrame.new(0,0.67,-0.7),theme.Accent,Enum.Material.Metal)end
 for _,x in ipairs({-12,12})do for _,z in ipairs({-12,12})do
  local pole=b:FindFirstChild("SupportPole"..(x<0 and(z<0 and 1 or 3)or(z<0 and 2 or 4)))
  if pole then pole.Color=wood pole.Material=Enum.Material.Wood end
  for _,y in ipairs({1,4.3,8.8})do p("MastFerrule",Vector3.new(0.78,0.28,0.78),CFrame.new(x,y,z),brass,Enum.Material.Metal)end
 end end
 -- Two enclosed lanterns hang at the rear corners, outside the playable center.
 for _,x in ipairs({-11.9,11.9})do
  beam("LanternHanger",Vector3.new(x,6.6,12),Vector3.new(x,6.1,12),0.10,brass,Enum.Material.Metal)
  p("LanternGlass",Vector3.new(0.60,0.80,0.60),CFrame.new(x,5.63,12),Color3.fromRGB(255,224,160),Enum.Material.Neon)
  for _,y in ipairs({5.16,6.10})do p("LanternCap",Vector3.new(0.88,0.18,0.88),CFrame.new(x,y,12),brass,Enum.Material.Metal)end
  for _,dx in ipairs({-0.34,0.34})do for _,dz in ipairs({-0.34,0.34})do beam("LanternFrame",Vector3.new(x+dx,5.2,12+dz),Vector3.new(x+dx,6.06,12+dz),0.07,wood,Enum.Material.Metal)end end
 end
 m.Parent=b
 b:SetAttribute("GondolaCraftVersion",1)
 table.insert(results,{name=b.Name,decorParts=count,floor=tostring(b.BasketFloor.Size)})
 task.wait()
end
return game:GetService("HttpService"):JSONEncode(results)
