local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local RS=game:GetService("ReplicatedStorage")
local player=Players.LocalPlayer
local remotes=RS:WaitForChild("FlyHigh"):WaitForChild("Remotes")
local pods=workspace:WaitForChild("FlyHighLobby"):WaitForChild("MatchmakingPods")
local flights={} local previews={} local attached=false local holes=0
remotes.TetherEvent.OnClientEvent:Connect(function(data) attached=data.isTethered==true end)
remotes.FlightStateSyncEvent.OnClientEvent:Connect(function(data) holes=data.holes or 0 if data.isGameOver or data.isVictory then attached=false end end)
local function register(model)
 if not model:IsA("Model") or flights[model] or not model:GetAttribute("BalloonThemeId") or model:GetAttribute("IsFleetPreview") then return end
 local entry={model=model,prompts={},motors={},connections={}}
 flights[model]=entry
 local function add(o)
  if o:IsA("ProximityPrompt") then entry.prompts[o]=true
  elseif o:IsA("Motor6D") and o:GetAttribute("BalloonMotion") then entry.motors[o]=true end
 end
 for _,o in ipairs(model:GetDescendants()) do add(o) end
 table.insert(entry.connections,model.DescendantAdded:Connect(add))
 table.insert(entry.connections,model.Destroying:Connect(function()
  for _,c in ipairs(entry.connections) do c:Disconnect() end flights[model]=nil
 end))
end
for _,m in ipairs(workspace:GetChildren()) do register(m) end
workspace.ChildAdded:Connect(function(m) task.defer(register,m) end)
for _,pod in ipairs(pods:GetChildren()) do
 local decor=pod:WaitForChild("DockDecor",10)
 local preview=decor and decor:FindFirstChild("PreviewBalloon")
 if preview then previews[preview]=preview:GetAttribute("PreviewBase") end
end
local function inBasket(character,balloon)
 local floor=balloon:FindFirstChild("BasketFloor")
 local hrp=character and character:FindFirstChild("HumanoidRootPart")
 if not floor or not hrp then return false end
 local p=floor.CFrame:PointToObjectSpace(hrp.Position)
 return math.abs(p.X)<=floor.Size.X/2 and math.abs(p.Z)<=floor.Size.Z/2 and p.Y>=0 and p.Y<=8
end
local elapsed=0
RunService.PreSimulation:Connect(function(dt)
 elapsed+=dt if elapsed<1/30 then return end elapsed=0
 local camera=workspace.CurrentCamera if not camera then return end
 local eye=camera.CFrame.Position local t=workspace:GetServerTimeNow()
 for model,base in pairs(previews) do
  if not model.Parent then previews[model]=nil
  elseif base and (base.Position-eye).Magnitude<95 then
   model:PivotTo(base*CFrame.new(0,math.sin(t*0.9)*0.12,0)*CFrame.Angles(0,t*0.16,0))
  end
 end
 for model,entry in pairs(flights) do
  if not model.Parent then
   for _,c in ipairs(entry.connections) do c:Disconnect() end flights[model]=nil
  else
   local root=model.PrimaryPart
   if root and (root.Position-eye).Magnitude<240 then
    for joint in pairs(entry.motors) do
     if not joint.Parent or not joint.Part1 then entry.motors[joint]=nil
     else
      local motion=joint:GetAttribute("BalloonMotion")
      if motion=="KoiTail" then joint.Transform=CFrame.Angles(0,math.sin(t*1.8)*0.12,0)
      elseif motion=="KoiFin" then joint.Transform=CFrame.Angles(math.sin(t*1.6)*0.06,0,0)
      elseif motion=="Tassel" then joint.Transform=CFrame.Angles(math.sin(t*1.9)*0.055,0,math.cos(t*1.4)*0.04)
      elseif motion=="OrbitStar" then joint.Transform=CFrame.Angles(0,t*(joint.Part1:GetAttribute("OrbitSpeed") or 0.1),0) end
     end
    end
   end
  end
 end
end)
local promptElapsed=0
RunService.Heartbeat:Connect(function(dt)
 promptElapsed+=dt if promptElapsed<0.15 then return end promptElapsed=0
 local char=player.Character local hum=char and char:FindFirstChildOfClass("Humanoid")
 local alive=hum and hum.Health>0 and player:GetAttribute("FlightGhost")~=true
 local ref=player:FindFirstChild("FlightBalloon")
 local own=ref and ref.Value
 local active=player:GetAttribute("InFlight")==true
 for model,entry in pairs(flights) do
  local crew=alive and active and own==model
  local inside=crew and inBasket(char,model)
  for prompt in pairs(entry.prompts) do
   if not prompt.Parent then entry.prompts[prompt]=nil
   else
    local enabled=false
    if crew then
     if prompt.Name=="HelmPrompt" then
      local seat=model:FindFirstChild("HelmSeat") enabled=seat~=nil and seat.Occupant==nil
     elseif prompt.Name=="TetherPrompt" then enabled=inside
     elseif prompt.Name=="ClimbPrompt" then enabled=attached and inside
     elseif prompt.Name=="DescendPrompt" then enabled=attached and not inside
     elseif prompt.Name=="PatchPrompt" then enabled=attached and not inside and holes<5 and prompt.Parent.Transparency<0.5
     elseif prompt.Name=="PickupPrompt" then enabled=prompt.Parent:GetAttribute("IsOccupied")==true and char:FindFirstChildOfClass("Tool")==nil end
    end
    prompt.Enabled=enabled==true
   end
  end
 end
 for _,pod in ipairs(pods:GetChildren()) do
  local console=pod:FindFirstChild("Console")
  local prompt=console and console:FindFirstChild("StartPrompt")
  if prompt then prompt.Enabled=alive and not active and player:GetAttribute("CurrentPod")==pod.Name and player:GetAttribute("IsMaster")==true and pod:GetAttribute("LaunchBlocked")~=true end
 end
end)
