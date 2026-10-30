local R={}
function R.Build(rack,kind)
 local old=rack:FindFirstChild("RackDisplay")if old then old:Destroy()end
 rack.Material=Enum.Material.Wood rack.Color=Color3.fromRGB(74,47,31)rack.Size=Vector3.new(.28,2.8,3.2)
 local model=Instance.new("Model")model.Name="RackDisplay"
 local side=rack.Name=="WeaponRack1"and 1 or -1
 local function part(name,size,offset,color,shape)
  local p=Instance.new("Part")p.Name=name p.Size=size p.CFrame=rack.CFrame*CFrame.new(offset)
  p.Color=color p.Material=Enum.Material.Metal p.Anchored=rack.Anchored p.Massless=true p.CanCollide=false p.CanTouch=false p.CanQuery=false
  if shape then p.Shape=shape end
  p.Parent=model local weld=Instance.new("WeldConstraint")weld.Part0=rack weld.Part1=p weld.Parent=p return p
 end
 for _,y in {-1.3,1.3}do part("BrassEdge",Vector3.new(.32,.07,3.25),Vector3.new(0,y,0),Color3.fromRGB(153,118,57))end
 for _,z in {-1.55,1.55}do part("BrassEdge",Vector3.new(.32,2.65,.07),Vector3.new(0,0,z),Color3.fromRGB(153,118,57))end
 part("LeatherHolster",Vector3.new(.42,.6,.55),Vector3.new(side*.35,-.6,.45),Color3.fromRGB(64,39,28)).Material=Enum.Material.SmoothPlastic
 part("HolsterStrap",Vector3.new(.06,.12,.6),Vector3.new(side*.59,-.42,.45),Color3.fromRGB(133,96,55))
 for i=-1,1 do
  local case=part("SpareCartridge",Vector3.new(.32,.095,.095),Vector3.new(side*.34,-.92,-.78+i*.18),Color3.fromRGB(183,137,55),Enum.PartType.Cylinder)
  case.CFrame*=CFrame.Angles(0,0,math.pi/2)
  part("CopperTip",Vector3.new(.09,.16,.09),Vector3.new(side*.34,-.69,-.78+i*.18),Color3.fromRGB(165,99,55),Enum.PartType.Ball)
 end
 local tool=game.ReplicatedStorage.FlyHigh.Templates.Weapons:FindFirstChild(kind)
 if tool then
  local h=tool.Handle local scale=kind=="AK47"and .6 or .9
  local mount=rack.CFrame*CFrame.new(side*.45,-.12,.45)
  for _,original in tool:GetChildren()do if original:IsA("BasePart")then
   local p=original:Clone()p:ClearAllChildren()
   for _,c in original:GetChildren()do
    if c:IsA("SurfaceAppearance")or c:IsA("SpecialMesh")or c:IsA("Decal")or c:IsA("Texture")then
     local visual=c:Clone()if visual:IsA("SpecialMesh")then visual.Scale*=scale visual.Offset*=scale end visual.Parent=p
    end
   end
   local relative=h.CFrame:ToObjectSpace(original.CFrame)
   p.CFrame=mount*CFrame.new(relative.Position*scale)*relative.Rotation p.Size*=scale
   p.Anchored=rack.Anchored p.Massless=true p.CanCollide=false p.CanTouch=false p.CanQuery=false
   p:SetAttribute("StoredWeaponVisual",true)p:SetAttribute("StoredTransparency",p.Transparency)
   p.Parent=model local w=Instance.new("WeldConstraint")w.Part0=rack w.Part1=p w.Parent=p
  end end
 end
 model.Parent=rack R.Update(rack)
end
function R.Update(rack)
 local model=rack:FindFirstChild("RackDisplay")if not model then return end
 for _,p in model:GetChildren()do if p:IsA("BasePart")and p:GetAttribute("StoredWeaponVisual")then
  p.Transparency=rack:GetAttribute("IsOccupied")==false and 1 or p:GetAttribute("StoredTransparency")
 end end
end
return R
