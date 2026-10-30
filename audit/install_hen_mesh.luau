assert(not game:GetService("RunService"):IsRunning())
local assets=game.ReplicatedStorage.FlyHigh.EnvironmentAssets
local source
for _,m in workspace:GetChildren()do if m.Name:sub(1,14)=="A recognizable"then source=m break end end
assert(source,"generated hen missing")
local chicken=Instance.new("Model")chicken.Name="Chicken"
local bounds,size=source:GetBoundingBox()
local base=CFrame.new(bounds.Position-Vector3.new(0,size.Y/2,0))*source:GetPivot().Rotation
local root=Instance.new("Part")root.Name="NatureRoot"root.Size=Vector3.new(.1,.1,.1)root.Transparency=1 root.Anchored=true root.CanCollide=false root.CanTouch=false root.CanQuery=false root.Parent=chicken chicken.PrimaryPart=root
for _,p in source:GetDescendants()do if p:IsA("BasePart")then
 local clone=p:Clone()clone:ClearAllChildren()
 for _,c in p:GetChildren()do if c:IsA("SurfaceAppearance")then c:Clone().Parent=clone end end
 clone.CFrame=base:ToObjectSpace(p.CFrame)clone.Anchored=true clone.CanCollide=false clone.CanTouch=false clone.CanQuery=false
 clone:SetAttribute("Segment",p.Parent.Name)clone:SetAttribute("RestCFrame",clone.CFrame)clone.Parent=chicken
end end
chicken:SetAttribute("VisualScale",1)chicken:SetAttribute("NatureType","Chicken")
chicken:SetAttribute("LegPivotY",.6)chicken:SetAttribute("HeadPivotY",1.25)chicken:SetAttribute("HeadPivotZ",-.45)
assets.Chicken:Destroy()chicken.Parent=assets
for _,old in workspace.FlyHighLobby.IslandNature.Chickens:GetChildren()do
 local new=chicken:Clone()new.Name=old.Name
 for _,k in {"Home","Phase","RoamRadius","WalkSpeed"}do new:SetAttribute(k,old:GetAttribute(k))end
 new:PivotTo(old:GetPivot())new.Parent=old.Parent old:Destroy()
end
source:Destroy()
return #chicken:GetDescendants()
