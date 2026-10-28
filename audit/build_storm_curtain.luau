assert(not game:GetService("RunService"):IsRunning())
local templates=game.ReplicatedStorage.FlyHigh.Templates.Obstacles
local old=templates:FindFirstChild("StormCurtain")if old then old:Destroy()end
local temp=Instance.new("Folder")temp.Name="CloudSculptTemporary"temp.Parent=workspace
local offset=Vector3.new(0,2400,0)
local model=Instance.new("Model")model.Name="StormCurtain"
local root=Instance.new("Part")root.Name="StormCore"root.Size=Vector3.new(360,120,32)root.CFrame=CFrame.new(offset)
root.Transparency=1 root.Anchored=true root.CanCollide=false root.CanTouch=false root.CanQuery=false root.Parent=model model.PrimaryPart=root
local function bank(name,y,size,color,phase,z)
 local parts={}
 for i=0,11 do
  local r=20+(i*7%9)
  local p=Instance.new("Part")p.Shape=Enum.PartType.Ball p.Size=Vector3.one*r*2
  p.CFrame=CFrame.new(offset+Vector3.new((i-5.5)*29,math.sin(i*1.7+phase)*9,math.cos(i)*3))
  p.Anchored=true p.Parent=temp table.insert(parts,p)
 end
 local first=table.remove(parts,1)
 local cloud=first:UnionAsync(parts,Enum.CollisionFidelity.Box,Enum.RenderFidelity.Automatic)
 cloud.Name=name cloud.UsePartColor=true cloud.Color=color cloud.Material=Enum.Material.SmoothPlastic
 cloud.Size=size cloud.CFrame=CFrame.new(offset+Vector3.new(0,y,z))
 cloud.Anchored=true cloud.CanCollide=false cloud.CanTouch=false cloud.CanQuery=false cloud.Parent=model
 first:Destroy()for _,p in ipairs(parts)do p:Destroy()end
end
bank("RearBillowingRidge",10,Vector3.new(360,100,20),Color3.fromRGB(84,116,132),1.4,7)
task.wait()
bank("SculptedStormFront",-7.5,Vector3.new(360,105,27),Color3.fromRGB(49,76,96),.2,-1)
task.wait()
bank("SilverCloudCrown",43,Vector3.new(350,34,13),Color3.fromRGB(148,180,185),2.2,15)
local function rod(name,a,b,width,color)
 local d=b-a local p=Instance.new("Part")p.Name=name p.Shape=Enum.PartType.Cylinder p.Size=Vector3.new(d.Magnitude,width,width)
 p.CFrame=CFrame.lookAt(offset+(a+b)/2,offset+b)*CFrame.Angles(0,math.pi/2,0)
 p.Material=Enum.Material.Neon p.Color=color p.Anchored=true p.CanCollide=false p.CanTouch=false p.CanQuery=false p.Parent=model
end
for i=-2,2 do
 local x=i*62 local pts={Vector3.new(x-7,35,-19),Vector3.new(x+4,9,-20),Vector3.new(x-5,11,-20),Vector3.new(x+7,-27,-19)}
 for n=1,3 do rod("Lightning_"..i.."_"..n,pts[n],pts[n+1],1.25,Color3.fromRGB(224,192,116))end
end
for _,p in ipairs(model:GetChildren())do
 if p:IsA("BasePart")and p.Name:find("Lightning")then local back=p:Clone()back.Name=p.Name.."_Reverse"back.CFrame=p.CFrame+Vector3.new(0,0,40)back.Parent=model end
end
for _,side in ipairs({-1,1})do
 local w=model.SilverCloudCrown:Clone()w.Name="CurledCloudWisp"w.Size=Vector3.new(80,16,18)
 w.CFrame=CFrame.new(offset+Vector3.new(side*177,-22,9))*CFrame.Angles(0,0,math.rad(side*18))w.Parent=model
end
local att=Instance.new("Attachment")att.Position=Vector3.new(0,75,0)att.Parent=root
local bill=Instance.new("BillboardGui")bill.Name="StormSign"bill.Size=UDim2.fromOffset(410,64)bill.MaxDistance=650 bill.AlwaysOnTop=false bill.Parent=att
local label=Instance.new("TextLabel")label.Size=UDim2.fromScale(1,1)label.BackgroundTransparency=1 label.Text="DINDING BADAI\n↓ TURUN KE BAWAH AWAN"
label.TextColor3=Color3.fromRGB(248,222,155)label.TextStrokeTransparency=.4 label.Font=Enum.Font.GothamBold label.TextSize=23 label.Parent=bill
model:PivotTo(CFrame.identity)model.Parent=templates temp:Destroy()
return {name=model:GetFullName(),parts=#model:GetDescendants()}
