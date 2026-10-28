local templates=game.ReplicatedStorage.FlyHigh.Templates
local skins=templates:FindFirstChild("BalloonSkins") or Instance.new("Folder") skins.Name="BalloonSkins" skins.Parent=templates
local specifications={
 {"classic teardrop","A",Vector3.new(32,38,32)},
 {"fantasy lotus%-bud","B",Vector3.new(32,38,32)},
 {"koi%-shaped","C",Vector3.new(34,30,40)},
 {"celestial planet","D",Vector3.new(32,32,32)},
 {"royal sky%-lantern","E",Vector3.new(28,38,28)},
}
local out={}
for _,m in ipairs(workspace:GetChildren()) do
 if m:IsA("Model") then
  for _,spec in ipairs(specifications) do
   if string.find(string.lower(m.Name),spec[1]) then
    m.Parent=skins m.Name=spec[2]
    for _,o in ipairs(m:GetDescendants()) do
     if o:IsA("LuaSourceContainer") or o:IsA("ProximityPrompt") then o:Destroy()
     elseif o:IsA("BasePart") then o.Anchored=true o.CanCollide=false o.CanTouch=false o.CanQuery=false o.Massless=true o:SetAttribute("SkinSegment",string.lower(o.Parent.Name)) end
    end
    m.PrimaryPart=nil m:PivotTo(CFrame.identity) m.WorldPivot=CFrame.identity
    local cf,size=m:GetBoundingBox()
    local factor=math.min(spec[3].X/size.X,spec[3].Y/size.Y,spec[3].Z/size.Z)
    m:ScaleTo(m:GetScale()*factor)
    cf,size=m:GetBoundingBox()
    m:PivotTo(m:GetPivot()-cf.Position)
    local root=Instance.new("Part") root.Name="SkinRoot" root.Size=Vector3.new(0.1,0.1,0.1)
    root.Transparency=1 root.Anchored=true root.CanCollide=false root.CanTouch=false root.CanQuery=false root.CFrame=CFrame.identity root.Parent=m m.PrimaryPart=root
    local parts={}
    for _,p in ipairs(m:GetDescendants()) do if p:IsA("BasePart") then table.insert(parts,{name=p.Name,segment=p:GetAttribute("SkinSegment"),pos=tostring(p.Position),size=tostring(p.Size)}) end end
    table.insert(out,{id=spec[2],size=tostring(size),parts=parts})
    break
   end
  end
 end
end
return out
