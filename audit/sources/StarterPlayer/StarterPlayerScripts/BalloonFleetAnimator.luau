local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local RS=game:GetService("ReplicatedStorage")
local Input=game:GetService("UserInputService")
local touches={}
local touchBegan=Input.InputBegan:Connect(function(i)if i.UserInputType==Enum.UserInputType.Touch then touches[i]=true end end)
local touchEnded=Input.InputEnded:Connect(function(i)touches[i]=nil end)
script.Destroying:Connect(function()touchBegan:Disconnect()touchEnded:Disconnect()end)
local player=Players.LocalPlayer
local remotes=RS:WaitForChild("FlyHigh"):WaitForChild("Remotes")
local pods=workspace:WaitForChild("FlyHighLobby"):WaitForChild("MatchmakingPods")
local flights={} local previews={} local attached=false local holes=0 local tetherStage
remotes.TetherEvent.OnClientEvent:Connect(function(data)
 local wasWinching=tetherStage=="Climbing"or tetherStage=="Descending"or tetherStage=="Rescuing"
 if wasWinching and (data.stage=="Catwalk"or data.stage=="Basket"or data.isTethered==false)then
  local character=player.Character
  local hum=character and character:FindFirstChildOfClass("Humanoid")
  if hum and hum.Health>0 and not character:GetAttribute("FatalRopeFall")then
   hum.Sit=false hum.PlatformStand=false hum.Jump=false
   hum:ChangeState(Enum.HumanoidStateType.GettingUp)
  end
 end
 attached = data.isTethered == true
 tetherStage = data.stage
end)
remotes.FlightStateSyncEvent.OnClientEvent:Connect(function(data) holes=data.holes or 0 if data.isGameOver or data.isVictory then attached=false end end)
local function register(model)
 if not model:IsA("Model") or flights[model] or not model:GetAttribute("BalloonThemeId") or model:GetAttribute("IsFleetPreview") then return end
 local entry={model=model,prompts={},motors={},connections={}}
 flights[model]=entry
 local function add(o)
  if o:IsA("ProximityPrompt") then
   -- Mask new prompts before the first visibility pass; otherwise every
   -- server-enabled station action briefly appears during replication.
   o.Enabled=false entry.prompts[o]=true
   if o.Name=="PatchPrompt"then
    local number=tonumber(o.Parent.Name:match("%d+"))
    if number then
     local function send(action)
      local ref=player:FindFirstChild("FlightBalloon")
      if ref and ref.Value==model then remotes.RepairHoleEvent:FireServer(action,number)end
     end
     local held=false local key local pointer local mouse local pad
     local function stop()
      if held then held=false send("Cancel")end
     end
     local function down()
      return key and Input:IsKeyDown(key)or pointer and touches[pointer]==true
       or mouse and Input:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
       or pad and Input:IsGamepadButtonDown(pad,o.GamepadKeyCode)
     end
     table.insert(entry.connections,o.PromptButtonHoldBegan:Connect(function()
      key=Input:IsKeyDown(o.KeyboardKeyCode)and o.KeyboardKeyCode or nil
      pointer=nil mouse=nil pad=nil
      local camera=workspace.CurrentCamera local target=camera and camera:WorldToScreenPoint(o.Parent.Position)
      local best=math.huge
      for touch in pairs(touches)do
       local d=target and (Vector2.new(touch.Position.X,touch.Position.Y)-Vector2.new(target.X,target.Y)).Magnitude or 0
       if d<best then best=d pointer=touch end
      end
      if not pointer then mouse=Input:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)end
      local kind=Input:GetLastInputType()
      if kind.Name:match("^Gamepad")and Input:IsGamepadButtonDown(kind,o.GamepadKeyCode)then pad=kind end
      held=true send("Begin")
     end))
     table.insert(entry.connections,o.PromptButtonHoldEnded:Connect(function()
      -- Moving world prompts can disappear while the physical input remains held.
      if not down()then stop()end
     end))
     table.insert(entry.connections,Input.InputEnded:Connect(function(i)
      if held and (key and i.KeyCode==key or pointer and i==pointer
       or mouse and i.UserInputType==Enum.UserInputType.MouseButton1
       or pad and i.UserInputType==pad and i.KeyCode==o.GamepadKeyCode)then stop()end
     end))
     table.insert(entry.connections,o.Triggered:Connect(function()send("Finish")end))
    end
   end
  elseif o:IsA("Motor6D") and o:GetAttribute("BalloonMotion") then entry.motors[o]=true end
 end
 for _,o in ipairs(model:GetDescendants()) do add(o) end
 table.insert(entry.connections,model.DescendantAdded:Connect(add))
 table.insert(entry.connections,model.Destroying:Connect(function()
  for _,c in ipairs(entry.connections) do c:Disconnect() end flights[model]=nil
 end))
end
local function observe(model)
 if not model:IsA("Model")then return end
 register(model)
 if flights[model]or model:GetAttribute("IsFleetPreview")then return end
 -- ChildAdded can precede replicated attributes. Do not permanently miss a flight.
 local connection
 connection=model:GetAttributeChangedSignal("BalloonThemeId"):Connect(function()
  register(model)
  if flights[model]then connection:Disconnect()end
 end)
 model.Destroying:Once(function()connection:Disconnect()end)
end
for _,m in ipairs(workspace:GetChildren()) do observe(m) end
workspace.ChildAdded:Connect(function(m) task.defer(observe,m) end)
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
 local alive=hum and hum.Health>0 and char:GetAttribute("FatalRopeFall")~=true and player:GetAttribute("FlightGhost")~=true
 local ref=player:FindFirstChild("FlightBalloon")
 local own=ref and ref.Value
 local active=player:GetAttribute("InFlight")==true
 for model,entry in pairs(flights) do
  local crew=alive and active and own==model and player:GetAttribute("BoardingFlight")~=true
  local free=player:GetAttribute("CrewRole")==nil and hum and not hum.Sit and not char:FindFirstChildOfClass("Tool")
  local inside=crew and inBasket(char,model)
  for prompt in pairs(entry.prompts) do
   if not prompt.Parent then entry.prompts[prompt]=nil
   else
    local enabled=false
    if crew then
     if prompt.Name=="HelmPrompt" then
      local seat=model:FindFirstChild("HelmSeat") enabled=free and seat~=nil and seat.Occupant==nil
     elseif prompt.Name=="RepairRopePrompt" then
      local repairing = player:GetAttribute("RopeRepairing") == true
      enabled = inside and not attached and (repairing or (free and (prompt.Parent:GetAttribute("RepairableRopes") or 0) > 0))
     elseif prompt.Name=="PatchPrompt" then
      enabled = attached and tetherStage == "Catwalk" and not inside and holes < 5 and prompt.Parent.Transparency < 0.5
     elseif prompt.Name=="PickupPrompt" then enabled=free and prompt.Parent:GetAttribute("IsOccupied")==true and char:FindFirstChildOfClass("Tool")==nil end
    end
    local desired=enabled==true
    if prompt.Enabled~=desired then prompt.Enabled=desired end
   end
  end
 end
 for _,pod in ipairs(pods:GetChildren()) do
  local floorPad=pod:FindFirstChild("FloorPad")
  local console=pod:FindFirstChild("Console")
  local prompt=(floorPad and floorPad:FindFirstChild("StartPrompt",true))or(console and console:FindFirstChild("StartPrompt",true))
  if prompt then prompt.Enabled=alive and not active and player:GetAttribute("CurrentPod")==pod.Name and player:GetAttribute("IsMaster")==true and pod:GetAttribute("LaunchBlocked")~=true end
 end
end)
