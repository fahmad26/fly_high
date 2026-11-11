local L=workspace.FlyHighLobby local road=L.DockPromenade local H=game:GetService("HttpService")
local old=L:FindFirstChild("PromenadeGarden")if old then old:Destroy()end
local m=Instance.new("Model")m.Name="PromenadeGarden"local rng=Random.new(43)local count=0
local colors={Color3.fromRGB(178,161,127),Color3.fromRGB(192,174,140),Color3.fromRGB(184,168,135)}
local paving=0
for _,v in road:GetChildren()do
 if v.Name:match("^Paving_")then v.Material=Enum.Material.Cobblestone v.Color=colors[1+(paving%3)]paving+=1
 elseif v.Name=="FlushStoneBorder"then v.Material=Enum.Material.Slate v.Color=Color3.fromRGB(98,107,103)
 elseif v.Name=="Junction"then v.Material=Enum.Material.Cobblestone v.Color=Color3.fromRGB(188,172,138)end
end
local function part(name,size,cf,color,material,shape)
 local p=Instance.new("Part")p.Name=name p.Size=size p.CFrame=cf p.Anchored=true p.Color=color p.Material=material or Enum.Material.SmoothPlastic p.CanCollide=false p.CanTouch=false p.CanQuery=false p.TopSurface=Enum.SurfaceType.Smooth p.BottomSurface=Enum.SurfaceType.Smooth
 if shape then p.Shape=shape end p.CastShadow=size.Magnitude>2 p.Parent=m count+=1 return p
end
local brass=Color3.fromRGB(192,152,79)local slate=Color3.fromRGB(50,81,87)
local function rod(name,a,b,width,color,mat)
 return part(name,Vector3.new((b-a).Magnitude,width,width),CFrame.lookAt((a+b)/2,b)*CFrame.Angles(0,math.pi/2,0),color,mat,Enum.PartType.Cylinder)
end
local lamps={}
for _,z in ipairs({10,-15,-38})do for _,x in ipairs({-6.8,6.8})do table.insert(lamps,Vector3.new(x,10,z))end end
for _,degrees in ipairs({-67.5,-22.5,22.5,67.5})do local a=math.rad(degrees)table.insert(lamps,Vector3.new(math.sin(a)*62,10,15-math.cos(a)*62))end
for _,q in lamps do
 part("LanternFoot",Vector3.new(.25,1.12,1.12),CFrame.new(q+Vector3.new(0,.15,0))*CFrame.Angles(0,0,math.pi/2),brass,Enum.Material.Metal,Enum.PartType.Cylinder)
 rod("FlutedPost",q+Vector3.new(0,.2,0),q+Vector3.new(0,2.6,0),.23,slate,Enum.Material.Metal)
 part("WarmGlass",Vector3.new(.65,.95,.65),CFrame.new(q+Vector3.new(0,3.05,0)),Color3.fromRGB(255,224,159),Enum.Material.Neon)
 for _,y in ipairs({2.55,3.6})do part("LanternCrown",Vector3.new(.9,.15,.9),CFrame.new(q+Vector3.new(0,y,0)),brass,Enum.Material.Metal)end
 for _,dx in ipairs({-.34,.34})do for _,dz in ipairs({-.34,.34})do rod("LanternCage",q+Vector3.new(dx,2.6,dz),q+Vector3.new(dx,3.55,dz),.06,slate,Enum.Material.Metal)end end
end
local themes=require(game.ReplicatedStorage.FlyHigh.Modules.BalloonThemes)
for i=1,5 do
 local theta=math.rad((i-3)*45)local radial=Vector3.new(math.sin(theta),0,-math.cos(theta))local junction=Vector3.new(0,10.31,15)+radial*70 local accent=themes.Get("Pod_"..string.char(64+i)).Accent
 local med=part("DockWayfinder_"..i,Vector3.new(.055,3.4,3.4),CFrame.new(junction)*CFrame.Angles(0,0,math.pi/2),slate,Enum.Material.Slate,Enum.PartType.Cylinder)
 for n=0,15 do local a=n*math.pi/8 local b=(n+1)*math.pi/8 rod("MosaicBorder",junction+Vector3.new(math.cos(a)*1.65,.04,math.sin(a)*1.65),junction+Vector3.new(math.cos(b)*1.65,.04,math.sin(b)*1.65),.09,accent,Enum.Material.Sandstone)end
 local label=Instance.new("SurfaceGui")label.Name="DockLetter"label.Face=Enum.NormalId.Right label.CanvasSize=Vector2.new(128,128)label.Parent=med
 local t=Instance.new("TextLabel")t.Size=UDim2.fromScale(1,1)t.BackgroundTransparency=1 t.Font=Enum.Font.FredokaOne t.Text=string.char(64+i)t.TextColor3=Color3.fromRGB(255,235,193)t.TextScaled=true t.Parent=label
 local dir=radial
 for n=1,3 do local q=junction+dir*(2.4+n*1.4)part("DockGuideStone",Vector3.new(.8,.04,.6),CFrame.lookAt(q,q+dir),accent,Enum.Material.Sandstone)end
end
-- Plant pockets sit outside the road, away from branches and summon volumes.
for _,degrees in ipairs({-67.5,-22.5,22.5,67.5})do
 local a=math.rad(degrees)local q=Vector3.new(math.sin(a)*59,10,15-math.cos(a)*59)
 part("GardenBed",Vector3.new(.16,3.8,3.8),CFrame.new(q)*CFrame.Angles(0,0,math.pi/2),Color3.fromRGB(87,98,77),Enum.Material.Slate,Enum.PartType.Cylinder)
 for j=1,5 do
  local angle=j*math.pi*2/5 local pos=q+Vector3.new(math.cos(angle)*.8,.5,math.sin(angle)*.8)
  local leaf=part("SageLeaf",Vector3.new(.65,1.5,.22),CFrame.new(pos)*CFrame.Angles(.4,angle,.35),Color3.fromRGB(89+j*6,135+j*3,91),Enum.Material.Grass,Enum.PartType.Ball)
 end
 for j=1,3 do
  local pos=q+Vector3.new((j-2)*.65,.8,0)rod("FlowerStem",pos-Vector3.yAxis*.7,pos,.055,Color3.fromRGB(60,102,63),Enum.Material.Grass)
  for k=1,5 do local a=k*math.pi*2/5 part("DaisyPetal",Vector3.new(.3,.08,.22),CFrame.new(pos+Vector3.new(math.cos(a)*.19,0,math.sin(a)*.19))*CFrame.Angles(0,-a,0),Color3.fromRGB(242,223,181),Enum.Material.SmoothPlastic,Enum.PartType.Ball)end
  part("DaisyHeart",Vector3.new(.16,.12,.16),CFrame.new(pos+Vector3.yAxis*.03),brass,Enum.Material.SmoothPlastic,Enum.PartType.Ball)
 end
end
m.Parent=L
return H:JSONEncode({pavingRetextured=paving,decorParts=count,lanterns=#lamps,wayfinders=5,flowerBeds=4})
