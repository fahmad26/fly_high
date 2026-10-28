local b=game.ReplicatedStorage.FlyHigh.Templates.HotAirBalloon
if not b:GetAttribute("GondolaExpandedV2") then
 local welds={}
 for _,o in ipairs(b:GetDescendants()) do if o:IsA("WeldConstraint") then o.Enabled=false table.insert(welds,o) end end
 local root=b.RootPart
 local base=root.Position
 b.BasketFloor.Size=Vector3.new(28,1.2,28) root.Size=Vector3.new(28,2,28)
 local positions={
  RailingNorth=Vector3.new(0,2.5,-13.5),RailingSouth=Vector3.new(0,2.5,13.5),
  RailingEast=Vector3.new(13.5,2.5,0),RailingWest=Vector3.new(-13.5,2.5,0),
  HelmSeat=Vector3.new(0,1.8,-10),WeaponRack1=Vector3.new(-12,2.5,-4),
  WeaponRack2=Vector3.new(12,2.5,-4),TetherStation=Vector3.new(0,2,11),
  EmergencySiren=Vector3.new(0,5.2,-13.5),
  SupportPole1=Vector3.new(-12,5,-12),SupportPole2=Vector3.new(12,5,-12),
  SupportPole3=Vector3.new(-12,5,12),SupportPole4=Vector3.new(12,5,12),
 }
 for name,offset in pairs(positions) do b[name].Position=base+offset end
 b.RailingNorth.Size=Vector3.new(28,4,1) b.RailingSouth.Size=Vector3.new(28,4,1)
 b.RailingEast.Size=Vector3.new(1,4,26) b.RailingWest.Size=Vector3.new(1,4,26)
 -- Replace solid blocking cylinders with a walkable ring and a hollow outer railing.
 b.EnvelopeWalkway.Transparency=1 b.EnvelopeWalkway.CanCollide=false b.EnvelopeWalkway.CanQuery=false
 b.WalkwayRailing.Transparency=1 b.WalkwayRailing.CanCollide=false b.WalkwayRailing.CanQuery=false
 b.EnvelopeWalkway.DescendPrompt.MaxActivationDistance=26
 local ring=Instance.new("Folder") ring.Name="EnvelopeRing" ring.Parent=b
 for i=0,15 do
  local angle=math.rad(i*22.5)
  local cf=CFrame.new(base)*CFrame.Angles(0,angle,0)
  for _,spec in ipairs({{name="Walkway",radius=20,y=18,size=Vector3.new(8.4,1.2,6)},
    {name="Rail",radius=23.1,y=20,size=Vector3.new(9.4,3,0.5)}}) do
   local part=Instance.new("Part") part.Name=spec.name..i part.Size=spec.size
   part.CFrame=cf*CFrame.new(0,spec.y,-spec.radius) part.Material=Enum.Material.WoodPlanks
   part.Color=Color3.fromRGB(140,100,65) part.Parent=ring
   local weld=Instance.new("WeldConstraint") weld.Part0=root weld.Part1=part weld.Parent=part
  end
 end
 for i=1,5 do
  local angle=math.rad((i-1)*72)
  b.HoleSlots["Hole"..i].CFrame=CFrame.new(base+Vector3.new(math.sin(angle)*20,22,-math.cos(angle)*20))*CFrame.Angles(0,-angle,0)
 end
 for _,o in ipairs(b:GetDescendants()) do
  if o:IsA("BasePart") and o~=root then o.Massless=true end
 end
 root.AlignPosition.MaxForce=1e8 root.AlignPosition.MaxVelocity=100 root.AlignPosition.Responsiveness=25
 root.AlignOrientation.MaxTorque=1e8 root.AlignOrientation.Responsiveness=20
 for _,w in ipairs(welds) do w.Enabled=true end
 b:SetAttribute("GondolaExpandedV2",true)
end
b.RootPart.RootPriority=127
b.RootPart.AlignPosition.RigidityEnabled=true
b.RootPart.AlignPosition.ApplyAtCenterOfMass=true
b.HelmSeat.CanTouch=false
b.HelmSeat.HelmPrompt.MaxActivationDistance=5
b.TetherStation.ClimbPrompt.KeyboardKeyCode=Enum.KeyCode.F
b.TetherStation.ClimbPrompt.GamepadKeyCode=Enum.KeyCode.ButtonY
b.EnvelopeWalkway.DescendPrompt.KeyboardKeyCode=Enum.KeyCode.Q
b.EnvelopeWalkway.DescendPrompt.GamepadKeyCode=Enum.KeyCode.ButtonB
local palace=workspace.CloudPalace
if not palace:GetAttribute("AuditPositioned") then
 for _,part in ipairs(palace:GetDescendants()) do
  if part:IsA("BasePart") then part.CFrame+=Vector3.new(0,80,-2000) end
 end
 palace:SetAttribute("AuditPositioned",true)
end
if palace:IsA("Folder") then
 local model=Instance.new("Model") model.Name="CloudPalace"
 for _,child in ipairs(palace:GetChildren()) do child.Parent=model end
 palace:Destroy() model.Parent=workspace palace=model
 palace:SetAttribute("AuditPositioned",true)
end
palace.ModelStreamingMode=Enum.ModelStreamingMode.Persistent
local walls=workspace.FlyHighLobby.InvisibleBoundaryCorridor
for _,o in ipairs(walls:GetChildren()) do o:Destroy() end
-- Parts are capped at 2048 studs per dimension; use two segments per wall.
for _,spec in ipairs({
 {n="North",p=Vector3.new(0,0,-150),s=Vector3.new(304,1,4)},
 {n="South",p=Vector3.new(0,0,150),s=Vector3.new(304,1,4)},
 {n="East",p=Vector3.new(150,0,0),s=Vector3.new(4,1,304)},
 {n="West",p=Vector3.new(-150,0,0),s=Vector3.new(4,1,304)}}) do
 for segment=1,2 do
  local part=Instance.new("Part") part.Name="Wall"..spec.n..segment
  part.Size=Vector3.new(spec.s.X,1300,spec.s.Z)
  part.Position=spec.p+Vector3.new(0,(segment-1)*1300+650,0)
  part.Anchored=true part.Transparency=1 part.Parent=walls
 end
end
local rs=game.ReplicatedStorage.FlyHigh.Remotes
for _,name in ipairs({"WeaponReloadEvent"}) do
 if not rs:FindFirstChild(name) then local r=Instance.new("RemoteEvent") r.Name=name r.Parent=rs end
end
game:GetService("ChangeHistoryService"):SetWaypoint("Fly High audit geometry")
return {basket=tostring(b.BasketFloor.Size),palace=tostring(palace.CloudIsland.Position),walls=#walls:GetChildren()}
