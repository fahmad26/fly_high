assert(not game:GetService("RunService"):IsRunning())
local lobby=workspace.FlyHighLobby local spawn=lobby.LobbySpawn
local old=lobby:FindFirstChild("ArrivalGarden")if old then old:Destroy()end
local model=Instance.new("Model")model.Name="ArrivalGarden"model.Parent=lobby
local center=Vector3.new(0,10,35)
local function part(name,size,cf,color,material,shape,collision)
 local p=Instance.new("Part")p.Name=name p.Size=size p.CFrame=cf p.Color=color p.Material=material p.Shape=shape or Enum.PartType.Block
 p.Anchored=true p.CanCollide=collision==true p.CanQuery=false p.CanTouch=false p.Parent=model return p
end
local function disc(name,y,d,h,color,material)
 return part(name,Vector3.new(h,d,d),CFrame.new(center+Vector3.new(0,y,0))*CFrame.Angles(0,0,math.pi/2),color,material,Enum.PartType.Cylinder,true)
end
disc("SculptedStoneBase",.2,24,.65,Color3.fromRGB(105,113,103),Enum.Material.Slate)
disc("WarmTimberDeck",.65,21,.55,Color3.fromRGB(146,104,65),Enum.Material.WoodPlanks)
local rim=game.ReplicatedStorage.FlyHigh.Templates.FleetGeometry.DockRim:Clone()rim.Name="BrassArrivalRim"rim:PivotTo(CFrame.new(center+Vector3.new(0,.96,0)))rim.Parent=model
for _,p in ipairs(rim:GetDescendants())do if p:IsA("BasePart")then p.Anchored=true p.CanCollide=false p.CanQuery=false p.CanTouch=false end end
for i=0,7 do
 local a=i*math.pi/4 local cf=CFrame.new(center+Vector3.new(math.sin(a)*4.2,.96,math.cos(a)*4.2))*CFrame.Angles(0,a,0)
 part("CompassInlay",Vector3.new(.11,.03,7.5),cf,Color3.fromRGB(224,190,112),Enum.Material.SmoothPlastic)
end
for i=0,1 do
 local star=game.ReplicatedStorage.FlyHigh.Templates.FleetGeometry.Star:Clone()star.Name="CompassRose"
 star:ScaleTo(star:GetScale()*(i==0 and 2.1 or 1.55))
 star:PivotTo(CFrame.new(center+Vector3.new(0,.99+i*.02,0))*CFrame.Angles(math.pi/2,0,i*math.pi))
 for _,p in ipairs(star:GetDescendants())do if p:IsA("BasePart")then p.Anchored=true p.CanCollide=false p.CanQuery=false p.CanTouch=false if p.Transparency<1 then p.Color=i==0 and Color3.fromRGB(228,190,104)or Color3.fromRGB(65,105,97)end end end
 star.Parent=model
end
for i=0,11 do
 local a=i*math.pi/6
 part("CoastalEdging",Vector3.new(3,.65,1.25),CFrame.new(center+Vector3.new(math.sin(a)*11.7,.05,math.cos(a)*11.7))*CFrame.Angles(0,a,math.rad(i%2==0 and 6 or -5)),Color3.fromRGB(116+i%3*8,121+i%3*6,108),Enum.Material.Slate,nil,true)
end
for _,x in ipairs({-12.5,12.5})do
 local fern=game.ReplicatedStorage.FlyHigh.EnvironmentAssets.Fern:Clone()fern.Name="ArrivalFern"fern:PivotTo(CFrame.new(center+Vector3.new(x,0,4)))fern.Parent=model
 for _,p in ipairs(fern:GetDescendants())do if p:IsA("BasePart")then p.Anchored=true p.CanCollide=false p.CanQuery=false p.CanTouch=false end end
end
local sign=lobby.WelcomeSign
sign.Size=Vector3.new(11,4.3,.55)sign.CFrame=CFrame.lookAt(Vector3.new(-15,14,35),Vector3.new(spawn.Position.X,14,spawn.Position.Z))
sign.SurfaceGui.Face=Enum.NormalId.Front
sign.Color=Color3.fromRGB(42,77,71)sign.Material=Enum.Material.Wood sign.CanCollide=true
local label=sign:FindFirstChildWhichIsA("TextLabel",true)
if label then label.Text="FLY HIGH\nPilih dermaga • Bentuk kru • Terbang!"label.TextColor3=Color3.fromRGB(249,222,157)label.BackgroundTransparency=1 label.TextScaled=true
 local pad=label:FindFirstChildOfClass("UIPadding")or Instance.new("UIPadding")pad.PaddingLeft=UDim.new(0,12)pad.PaddingRight=UDim.new(0,12)pad.PaddingTop=UDim.new(0,10)pad.PaddingBottom=UDim.new(0,10)pad.Parent=label
end
for _,x in ipairs({-4.6,4.6})do
 part("WelcomePost",Vector3.new(.35,4.8,.35),sign.CFrame*CFrame.new(x,-3.1,0),Color3.fromRGB(115,82,51),Enum.Material.Wood,nil,true)
end
for _,y in ipairs({-2.25,2.25})do
 part("WelcomeBrassFrame",Vector3.new(11.35,.12,.68),sign.CFrame*CFrame.new(0,y,0),Color3.fromRGB(203,165,91),Enum.Material.Metal)
end
spawn.Transparency=1 spawn.CanCollide=false spawn.Duration=0 spawn.Size=Vector3.new(10,1,10)
for _,o in ipairs(spawn:GetDescendants())do if o:IsA("Decal")or o:IsA("Texture")then o.Transparency=1 end end
return {spawn=spawn:GetFullName(),decorParts=#model:GetDescendants()}
