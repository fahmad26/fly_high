local RunService=game:GetService("RunService")
local lobby=workspace:WaitForChild("FlyHighLobby")
local nature=lobby:WaitForChild("IslandNature")
local birds={} local butterflies={} local foliage={}
local function capture(model)
 local root=model:WaitForChild("NatureRoot",10)
 if not root then return nil end
 local entry={model=model,root=root,parts={},smooth=root.CFrame,phase=model:GetAttribute("Phase") or math.random()*6.28}
 for _,p in ipairs(model:GetDescendants()) do
  if p:IsA("BasePart") and p~=root and p:GetAttribute("RestCFrame") then
   table.insert(entry.parts,{part=p,rest=p:GetAttribute("RestCFrame"),segment=string.lower(p:GetAttribute("Segment") or "")})
  end
 end
 return entry
end
local function watch(folder,storage,filter)
 local function add(model)
  if not model:IsA("Model") then return end
  local entry=capture(model)
  if entry then
   if filter then
    local keep={}
    for _,p in ipairs(entry.parts) do if filter(p.segment) then table.insert(keep,p) end end
    entry.parts=keep
   end
   storage[model]=entry
  end
 end
 for _,m in ipairs(folder:GetChildren()) do task.spawn(add,m) end
 folder.ChildAdded:Connect(function(m) task.spawn(add,m) end)
 folder.ChildRemoved:Connect(function(m) storage[m]=nil end)
end
watch(nature:WaitForChild("Chickens"),birds)
watch(nature:WaitForChild("Butterflies"),butterflies)
watch(nature:WaitForChild("Trees"),foliage,function(s) return s=="leaves" or s=="fronds" end)
watch(nature:WaitForChild("Plants"),foliage,function(s) return s=="leaves" or s=="fronds" end)
local function hinge(rest,point,rotation)
 return CFrame.new(point)*rotation*CFrame.new(rest.Position-point)*rest.Rotation
end
local elapsed=0
RunService.RenderStepped:Connect(function(dt)
 elapsed+=dt
 if elapsed<1/30 then return end
 local frame=elapsed elapsed=0
 local time=workspace:GetServerTimeNow()
 local camera=workspace.CurrentCamera
 if not camera then return end
 local eye=camera.CFrame.Position
 for model,e in pairs(birds) do
  if not model.Parent or not e.root.Parent then birds[model]=nil continue end
  if (e.root.Position-eye).Magnitude>180 then continue end
  e.smooth=e.smooth:Lerp(e.root.CFrame,math.min(1,frame*16))
  local walking=model:GetAttribute("Walking")==true
  local pecking=model:GetAttribute("Pecking")==true
  local scale=model:GetAttribute("VisualScale") or 1
  local phase=time*9+e.phase
  local bob=walking and math.sin(phase*2)*0.045*scale or math.sin(time*2+e.phase)*0.012*scale
  local peck=pecking and math.max(0,math.sin(time*6+e.phase))*0.75 or 0
  for _,p in ipairs(e.parts) do
   local rest=p.rest local pose=rest
   local segment=p.segment
   if string.find(segment,"leg") then
    local side=string.find(segment,"left") and 1 or -1
    local stride=walking and math.sin(phase)*side or 0
    local point=Vector3.new(rest.X,(model:GetAttribute("LegPivotY")or 1.12)*scale,-0.24*scale)
    pose=CFrame.new(0,math.max(0,stride)*0.12*scale,0)*hinge(rest,point,CFrame.Angles(stride*0.42,0,0))
   elseif segment=="head" then
    pose=CFrame.new(0,bob,0)*hinge(rest,Vector3.new(0,(model:GetAttribute("HeadPivotY")or 2.2)*scale,(model:GetAttribute("HeadPivotZ")or -.65)*scale),CFrame.Angles(-peck,0,0))
   elseif string.find(segment,"wing") then
    pose=CFrame.new(0,bob,0)*rest*CFrame.Angles(0,0,math.sin(time*3+e.phase)*0.018)
   else pose=CFrame.new(0,bob,0)*rest end
   p.part.CFrame=e.smooth*pose
  end
 end
 for model,e in pairs(butterflies) do
  if not model.Parent or not e.root.Parent then butterflies[model]=nil continue end
  local center=model:GetAttribute("FlightCenter")
  if not center or (center-eye).Magnitude>180 then continue end
  local radius=model:GetAttribute("FlightRadius") or 3
  local u=time*0.55+e.phase
  local position=center+Vector3.new(math.sin(u)*radius,math.sin(u*1.8)*0.65,math.cos(u*0.8)*radius*0.7)
  local direction=Vector3.new(math.cos(u)*radius,math.cos(u*1.8)*1.17,-math.sin(u*0.8)*radius*0.56)
  local cf=CFrame.lookAt(position,position+direction)*CFrame.Angles(0,0,math.sin(u)*0.12)
  local flap=math.sin(time*28+e.phase)*0.8
  -- The root is cosmetic on clients; the server has no continuous butterfly replication.
  e.root.CFrame=cf
  for _,p in ipairs(e.parts) do
   local rest=p.rest
   if string.find(p.segment,"wing") then
    local side=string.find(p.segment,"left") and 1 or -1
    p.part.CFrame=cf*hinge(rest,Vector3.new(0,rest.Y,rest.Z),CFrame.Angles(0,0,flap*side))
   else p.part.CFrame=cf*rest end
  end
 end
 for model,e in pairs(foliage) do
  if not model.Parent or not e.root.Parent then foliage[model]=nil continue end
  if (e.root.Position-eye).Magnitude>150 then continue end
  local tree=model:GetAttribute("NatureType")~="Fern"
  local height=(tree and 12 or 0.5)*(model:GetAttribute("VisualScale") or 1)
  local sway=math.sin(time*1.1+e.phase)*0.015
  for _,p in ipairs(e.parts) do
   p.part.CFrame=e.root.CFrame*hinge(p.rest,Vector3.new(0,height,0),CFrame.Angles(sway*0.4,0,sway))
  end
 end
end)
