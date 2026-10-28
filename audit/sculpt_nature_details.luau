-- Supplemental sculpted details for the generated chicken mesh template.
local assets=game.ReplicatedStorage.FlyHigh.EnvironmentAssets
-- Recognizable red serrated comb and golden beak supplement the generated hen.
local chicken=assets.Chicken
if chicken:GetAttribute("CustomDetailsVersion")==1 then return "already sculpted" end
local folder=chicken:FindFirstChild("head")
local function detail(class,name,size,cf,color)
 local p=Instance.new(class) p.Name=name p.Size=size p.CFrame=cf p.Color=color p.Material=Enum.Material.SmoothPlastic
 p.Anchored=true p.CanCollide=false p.CanTouch=false p.CanQuery=false p.Parent=folder
 p:SetAttribute("RestCFrame",cf) p:SetAttribute("Segment","head") return p
end
for i=0,2 do
 detail("WedgePart","Comb"..i,Vector3.new(0.13,0.23+(i%2)*0.08,0.20),CFrame.new(0.01,3.0,-0.99+i*0.18),Color3.fromRGB(194,51,45))
end
detail("WedgePart","GoldenBeak",Vector3.new(0.27,0.18,0.33),CFrame.new(0.01,2.54,-1.28)*CFrame.Angles(0,math.pi,0),Color3.fromRGB(229,166,50))
for _,s in ipairs({-1,1}) do
 local eye=detail("Part","Eye",Vector3.new(0.1,0.1,0.1),CFrame.new(s*0.223,2.73,-0.96),Color3.fromRGB(24,20,22))
 eye.Shape=Enum.PartType.Ball
end
chicken:SetAttribute("CustomDetailsVersion",1)
return {chickenDetails=#folder:GetChildren()}
