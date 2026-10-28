local RunService=game:GetService("RunService")
local Players=game:GetService("Players")
local lobby=workspace:WaitForChild("FlyHighLobby")
local nature=lobby:WaitForChild("IslandNature")
local chickens=nature:WaitForChild("Chickens")
local rng=Random.new()
local cast=RaycastParams.new()
cast.FilterType=Enum.RaycastFilterType.Include
cast.FilterDescendantsInstances={workspace.Terrain}
cast.IgnoreWater=false
local flock={}
local function ground(x,z)
 local hit=workspace:Raycast(Vector3.new(x,65,z),Vector3.new(0,-120,0),cast)
 if not hit or hit.Material==Enum.Material.Water then return nil end
 return hit.Position.Y
end
local function blocked(x,z)
 if (Vector2.new(x,z)-Vector2.new(0,35)).Magnitude<13 then return true end
 for _,tree in ipairs(nature.Trees:GetChildren()) do
  local r=tree.PrimaryPart
  if r and (Vector2.new(x,z)-Vector2.new(r.Position.X,r.Position.Z)).Magnitude<3.1 then return true end
 end
 for _,rock in ipairs(nature.Rocks:GetChildren()) do
  local r=rock.PrimaryPart
  if r and (Vector2.new(x,z)-Vector2.new(r.Position.X,r.Position.Z)).Magnitude<3.8 then return true end
 end
 for _,pod in ipairs(lobby.MatchmakingPods:GetChildren()) do
  if (Vector2.new(x,z)-Vector2.new(pod.FloorPad.Position.X,pod.FloorPad.Position.Z)).Magnitude<17 then return true end
 end
 for _,p in ipairs(Players:GetPlayers()) do
  local r=p.Character and p.Character:FindFirstChild("HumanoidRootPart")
  if r and math.abs(r.Position.Y-12)<10 and (Vector2.new(x,z)-Vector2.new(r.Position.X,r.Position.Z)).Magnitude<2.7 then return true end
 end
 return false
end
local function state(bird,name,duration)
 bird.state=name bird.next=os.clock()+duration
 bird.model:SetAttribute("Walking",name=="Walk")
 bird.model:SetAttribute("Pecking",name=="Peck")
 bird.model:SetAttribute("Behaviour",name)
end
local function register(model)
 if not model:IsA("Model") then return end
 local root=model:WaitForChild("NatureRoot",10)
 if not root or flock[model] then return end
 local bird={model=model,root=root,home=model:GetAttribute("Home") or root.Position,target=root.Position,yaw=root.CFrame,steps=0}
 flock[model]=bird state(bird,"Idle",rng:NextNumber(0.2,1.5))
end
for _,model in ipairs(chickens:GetChildren()) do register(model) end
chickens.ChildAdded:Connect(register)
chickens.ChildRemoved:Connect(function(model) flock[model]=nil end)
local function destination(bird)
 local radius=bird.model:GetAttribute("RoamRadius") or 8
 for _=1,12 do
  local angle=rng:NextNumber(0,math.pi*2)
  local r=rng:NextNumber(2,radius)
  local x=bird.home.X+math.cos(angle)*r local z=bird.home.Z+math.sin(angle)*r
  local y=ground(x,z)
  if y and not blocked(x,z) then return Vector3.new(x,y-0.04,z) end
 end
 return nil
end
local elapsed=0
RunService.Heartbeat:Connect(function(dt)
 elapsed+=dt
 if elapsed<0.05 then return end
 local step=math.min(elapsed,0.15) elapsed=0
 for model,bird in pairs(flock) do
  if not model.Parent or not bird.root.Parent then flock[model]=nil continue end
  if os.clock()>=bird.next then
   if bird.state=="Walk" then
    state(bird,rng:NextNumber()<0.65 and "Peck" or "Idle",rng:NextNumber(0.8,2))
   else
    local target=destination(bird)
    if target then bird.target=target state(bird,"Walk",rng:NextNumber(3,7))
    else state(bird,"Idle",1) end
   end
  end
  if bird.state=="Walk" then
   local p=bird.root.Position
   local delta=Vector3.new(bird.target.X-p.X,0,bird.target.Z-p.Z)
   if delta.Magnitude<0.4 then
    state(bird,"Peck",rng:NextNumber(0.7,1.5))
   else
    local speed=model:GetAttribute("WalkSpeed") or 2
    local nextPos=p+delta.Unit*math.min(delta.Magnitude,speed*step)
    local y=ground(nextPos.X,nextPos.Z)
    if not y or blocked(nextPos.X,nextPos.Z) then state(bird,"Idle",0.5)
    else
     nextPos=Vector3.new(nextPos.X,y-0.04,nextPos.Z)
     local targetCF=CFrame.lookAt(nextPos,nextPos+delta.Unit)
     local rotation=bird.root.CFrame.Rotation:Lerp(targetCF.Rotation,math.min(1,step*6))
     -- Replicate one root transform; clients pose the cosmetic mesh segments.
     bird.root.CFrame=CFrame.new(nextPos)*rotation
     bird.steps+=1
     if bird.steps%20==0 then model:SetAttribute("WalkUpdates",bird.steps) end
    end
   end
  end
 end
end)
