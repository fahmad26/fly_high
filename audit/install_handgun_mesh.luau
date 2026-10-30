assert(not game:GetService("RunService"):IsRunning())
local template=game.ReplicatedStorage.FlyHigh.Templates.Weapons.Pistol
local source=game.ServerStorage.PistolVisualSource:FindFirstChildWhichIsA("Tool",true)
assert(source)
local base=source.Handle.CFrame
for _,o in template:GetChildren()do o:Destroy()end
local h=Instance.new("Part")h.Name="Handle"h.Size=Vector3.new(.25,.65,.35)h.Transparency=1 h.CFrame=CFrame.identity
h.Massless=true h.CanCollide=false h.CanTouch=false h.CanQuery=false h.Parent=template
-- Only inert geometry and its mesh/texture are copied, no scripts or effects.
for _,name in {"Body","Mag"}do
 local original=source:FindFirstChild(name,true)assert(original)
 local p=original:Clone()p.Name=name=="Body"and "PistolBody"or "Magazine"
 for _,o in p:GetChildren()do if not (o:IsA("SpecialMesh")or o:IsA("SurfaceAppearance"))then o:Destroy()end end
 p.CFrame=base:ToObjectSpace(original.CFrame)p.Anchored=false p.Massless=true p.CanCollide=false p.CanTouch=false p.CanQuery=false p.Color=Color3.new(1,1,1)p.Parent=template
 local w=Instance.new("WeldConstraint")w.Part0=h w.Part1=p w.Parent=p
end
local muzzle=Instance.new("Attachment")muzzle.Name="MuzzleAttachment"muzzle.Position=base:PointToObjectSpace(source:FindFirstChild("flames",true).Position)muzzle.Parent=h
template.Grip=source.Grip template.Enabled=true template.RequiresHandle=true template.CanBeDropped=false
game.ServerStorage.PistolVisualSource:Destroy()
return true
