assert(not game:GetService("RunService"):IsRunning())
local RS=game.ReplicatedStorage local assets=RS.FlyHigh.EnvironmentAssets local templates=RS.FlyHigh.Templates
local function piece(parent,name,size,cf,color,shape)
 local p=Instance.new(shape=="wedge"and "WedgePart"or "Part")p.Name=name p.Size=size p.CFrame=cf p.Color=color
 if p:IsA("Part")then p.Shape=shape=="ball"and Enum.PartType.Ball or(shape=="cylinder"and Enum.PartType.Cylinder or Enum.PartType.Block)end
 p.Anchored=true p.CanCollide=false p.CanTouch=false p.CanQuery=false p.Massless=true p.Material=Enum.Material.SmoothPlastic p.Parent=parent return p
end
-- Anatomical hen: layered breast, separate neck/head, folded feathered wings,
-- fan tail, comb/wattles, articulated thin legs and three forward toes.
local chicken=Instance.new("Model")chicken.Name="Chicken"
local root=piece(chicken,"NatureRoot",Vector3.new(.1,.1,.1),CFrame.identity,Color3.new())root.Transparency=1 chicken.PrimaryPart=root
local cream=Color3.fromRGB(239,223,188)local rust=Color3.fromRGB(170,102,49)local red=Color3.fromRGB(185,37,34)local gold=Color3.fromRGB(210,148,48)
local function hen(name,size,pos,color,shape,segment,rotation)
 local p=piece(chicken,name,size,CFrame.new(pos)*(rotation or CFrame.identity),color,shape)p:SetAttribute("Segment",segment or "body")p:SetAttribute("RestCFrame",p.CFrame)return p
end
hen("Breast",Vector3.new(1.25,1.45,1.85),Vector3.new(0,1.65,0),cream,"ball")
hen("Neck",Vector3.new(.7,1.25,.72),Vector3.new(0,2.15,-.62),cream,"ball","head",CFrame.Angles(-.2,0,0))
hen("Head",Vector3.new(.65,.7,.7),Vector3.new(0,2.75,-.91),cream,"ball","head")
hen("Beak",Vector3.new(.31,.22,.45),Vector3.new(0,2.69,-1.37),gold,"wedge","head",CFrame.Angles(0,math.pi,0))
for i=0,3 do hen("CombLobe",Vector3.new(.13,.27+(i%2)*.1,.22),Vector3.new(0,3.12,-1.13+i*.16),red,"ball","head")end
for _,s in {-1,1}do
 hen("Wattle",Vector3.new(.17,.35,.22),Vector3.new(s*.1,2.47,-1.13),red,"ball","head")
 hen("EyeRim",Vector3.new(.055,.17,.17),Vector3.new(s*.326,2.84,-1.03),Color3.fromRGB(181,116,39),"ball","head")
 hen("Eye",Vector3.new(.065,.105,.105),Vector3.new(s*.352,2.84,-1.055),Color3.fromRGB(19,14,12),"ball","head")
 hen("EyeGlint",Vector3.new(.025,.028,.028),Vector3.new(s*.38,2.865,-1.07),Color3.new(1,1,1),"ball","head")
 local side=s<0 and "left"or "right"
 hen("FoldedWing",Vector3.new(.35,.85,1.3),Vector3.new(s*.57,1.7,.12),rust,"ball",side.." wing",CFrame.Angles(.2,0,s*.15))
 for i=0,5 do hen("FlightFeather",Vector3.new(.12,.48,.2),Vector3.new(s*.73,1.44+i*.045,-.28+i*.17),cream:Lerp(rust,i/8),"ball",side.." wing",CFrame.Angles(-.45,0,s*.12))end
 hen("Shank",Vector3.new(.72,.12,.12),Vector3.new(s*.29,.61,-.06),gold,"cylinder",side.." leg",CFrame.Angles(0,0,math.pi/2))
 for i=-1,1 do hen("Toe",Vector3.new(.075,.08,.48),Vector3.new(s*.29+i*.1,.18,-.24),gold,nil,side.." leg",CFrame.Angles(0,i*.4,0))end
 hen("RearToe",Vector3.new(.09,.08,.26),Vector3.new(s*.29,.18,.15),gold,nil,side.." leg")
end
for i=-2,2 do hen("TailFeather",Vector3.new(.28,1.15,.24),Vector3.new(i*.18,2.12,1.02),i%2==0 and rust or cream,"ball","body",CFrame.Angles(.58,0,-i*.18))end
chicken:SetAttribute("NatureType","Chicken")chicken:SetAttribute("VisualScale",1)
assets.Chicken:Destroy()chicken.Parent=assets
for _,old in workspace.FlyHighLobby.IslandNature.Chickens:GetChildren()do
 local cf=old:GetPivot()local attrs=old:GetAttributes()local name=old.Name local new=chicken:Clone()
 for _,k in {"Home","Phase","RoamRadius","WalkSpeed"}do if attrs[k]~=nil then new:SetAttribute(k,attrs[k])end end
 new.Name=name new:PivotTo(cf)new.Parent=old.Parent old:Destroy()
end
-- Proportioned inert weapon models. Mechanical details are decorative only.
for _,tool in templates.Weapons:GetChildren()do
 for _,o in tool:GetChildren()do if o:IsA("BasePart")or o:IsA("JointInstance")or o:IsA("WeldConstraint")then o:Destroy()end end
 local metal=Color3.fromRGB(47,51,54)local wood=Color3.fromRGB(119,65,33)local rifle=tool.Name=="AK47"
 local h=piece(tool,"Handle",Vector3.new(.32,.85,.4),CFrame.new(0,-.35,.13)*CFrame.Angles(-.2,0,0),rifle and wood or Color3.fromRGB(29,31,32))
 local function gun(name,size,pos,color,shape,rot)
  local p=piece(tool,name,size,CFrame.new(pos)*(rot or CFrame.identity),color,shape)p.Material=color==wood and Enum.Material.Wood or Enum.Material.Metal
  p.Anchored=false local w=Instance.new("WeldConstraint")w.Part0=h w.Part1=p w.Parent=p return p
 end
 if rifle then
  gun("StampedReceiver",Vector3.new(.37,.4,1.65),Vector3.new(0,.22,-.37),metal)
  gun("RoundedDustCover",Vector3.new(1.5,.36,.36),Vector3.new(0,.45,-.36),metal,"cylinder",CFrame.Angles(0,math.pi/2,0))
  gun("WoodStock",Vector3.new(.36,.58,1.15),Vector3.new(0,.04,1.02),wood,"wedge",CFrame.Angles(0,math.pi,0))
  gun("ButtPlate",Vector3.new(.4,.67,.1),Vector3.new(0,-.03,1.62),metal)
  gun("WoodHandguard",Vector3.new(.43,.38,.85),Vector3.new(0,.2,-1.38),wood)
  gun("Barrel",Vector3.new(1.34,.15,.15),Vector3.new(0,.27,-2.02),metal,"cylinder",CFrame.Angles(0,math.pi/2,0))
  gun("GasTube",Vector3.new(.97,.13,.13),Vector3.new(0,.49,-1.69),metal,"cylinder",CFrame.Angles(0,math.pi/2,0))
  for i=0,4 do gun("CurvedMagazine",Vector3.new(.28,.25,.46),Vector3.new(0,-.13-i*.19,-.65-i*i*.023),metal,nil,CFrame.Angles(-i*.1,0,0))end
  gun("FrontSight",Vector3.new(.09,.36,.1),Vector3.new(0,.51,-2.47),metal)
  gun("ChargingHandle",Vector3.new(.26,.09,.12),Vector3.new(.28,.31,-.15),metal)
 else
  gun("Slide",Vector3.new(.37,.34,1.57),Vector3.new(0,.31,-.45),metal)
  gun("Frame",Vector3.new(.35,.2,1.3),Vector3.new(0,.04,-.35),Color3.fromRGB(30,32,33))
  gun("MuzzleBore",Vector3.new(.04,.18,.18),Vector3.new(0,.31,-1.25),Color3.new(.025,.025,.025),"cylinder",CFrame.Angles(0,math.pi/2,0))
  gun("EjectionPort",Vector3.new(.01,.17,.29),Vector3.new(.19,.36,-.23),Color3.new(.04,.04,.04))
  for i=0,5 do gun("SlideSerration",Vector3.new(.385,.025,.02),Vector3.new(0,.39,.05+i*.05),Color3.fromRGB(90,93,95))end
 end
 for _,s in {-1,1}do gun("TriggerGuardSide",Vector3.new(.055,.35,.065),Vector3.new(s*.14,-.2,-.38),metal)end
 gun("TriggerGuardBase",Vector3.new(.32,.06,.52),Vector3.new(0,-.38,-.25),metal)
 gun("Trigger",Vector3.new(.06,.2,.08),Vector3.new(0,-.13,-.25),metal,nil,CFrame.Angles(-.2,0,0))
 gun("RearSight",Vector3.new(.3,.1,.1),Vector3.new(0,.55,.24),metal)
 local muzzle=Instance.new("Attachment")muzzle.Name="MuzzleAttachment"muzzle.CFrame=h.CFrame:ToObjectSpace(CFrame.new(0,rifle and .27 or .31,rifle and -2.75 or -1.27))muzzle.Parent=h
 h.Anchored=false tool.Grip=CFrame.identity
end
return {chickenParts=#chicken:GetDescendants(),weapons=2}
