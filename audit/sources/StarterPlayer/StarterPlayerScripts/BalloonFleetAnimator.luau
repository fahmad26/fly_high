local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local RS=game:GetService("ReplicatedStorage")
local Input=game:GetService("UserInputService")
local BalloonVFX=require(RS:WaitForChild("FlyHigh"):WaitForChild("Modules"):WaitForChild("BalloonVFX"))
require(RS.FlyHigh.Modules:WaitForChild("HUDRepairPrompts")).Start(Players.LocalPlayer)
local touches={}
local touchBegan=Input.InputBegan:Connect(function(i)if i.UserInputType==Enum.UserInputType.Touch then touches[i]=true end end)
local touchEnded=Input.InputEnded:Connect(function(i)touches[i]=nil end)
script.Destroying:Connect(function()touchBegan:Disconnect()touchEnded:Disconnect()end)
local player=Players.LocalPlayer
local remotes=RS:WaitForChild("FlyHigh"):WaitForChild("Remotes")
local pods=workspace:WaitForChild("FlyHighLobby"):WaitForChild("MatchmakingPods")
local flights={} local previews={} local attached=false local holes=0 local tetherStage local catwalkStandY
local barrierFolder=workspace:FindFirstChild("FlyHighLocalBarriers")
if not barrierFolder then
 barrierFolder=Instance.new("Folder")
 barrierFolder.Name="FlyHighLocalBarriers"
 barrierFolder.Parent=workspace
end
script.Destroying:Connect(function() if barrierFolder and barrierFolder.Parent then barrierFolder:Destroy() end end)
remotes.TetherEvent.OnClientEvent:Connect(function(data)
 local wasWinching=tetherStage=="Climbing"or tetherStage=="Descending"or tetherStage=="Rescuing"
 if not (data.winchLanded or data.rescueLanded) and wasWinching and (data.stage=="Catwalk"or data.stage=="Basket"or data.isTethered==false)then
  local character=player.Character
  local hum=character and character:FindFirstChildOfClass("Humanoid")
  if hum and hum.Health>0 and not character:GetAttribute("FatalRopeFall")then
   hum.Sit=false hum.PlatformStand=false hum.Jump=false
   hum:ChangeState(Enum.HumanoidStateType.Running)
  end
 end
 if data.winchLanded=="Catwalk" and typeof(data.localOffset)=="Vector3" then catwalkStandY=data.localOffset.Y end
 attached = data.isTethered == true
 tetherStage = data.stage
end)
remotes.FlightStateSyncEvent.OnClientEvent:Connect(function(data) holes=data.holes or 0 if data.isGameOver or data.isVictory then attached=false end end)
-- Catwalk guard rails. The balloon tilts up to ~10 degrees toward the engineer, so the invisible guard face
-- leans outward. The humanoid floor sensor then reads that face as ground and lifts the body up the guard and
-- over the ring (tall avatars also stepped straight onto the old 2.5-stud guard). Flight disables jumping, so on
-- the catwalk the root never needs to rise above standing height or reach the guard: steer outward input along
-- the ring, and hold the root down/inside if physics still pushes it there.
local CATWALK_GUIDE_RADIUS=16.2
local CATWALK_MAX_RADIUS=16.9
local CATWALK_HEAD_ROOM=0.6
local function catwalkContext()
 if tetherStage~="Catwalk" then return end
 local character=player.Character
 local hum=character and character:FindFirstChildOfClass("Humanoid")
 local hrp=character and character:FindFirstChild("HumanoidRootPart")
 local ref=player:FindFirstChild("FlightBalloon")
 local root=ref and ref.Value and ref.Value.PrimaryPart
 if not (hum and hrp and root) or hum.Health<=0 or hrp.Anchored or hum.Sit or hum.PlatformStand then return end
 return hum,hrp,root,ref.Value
end
RunService:BindToRenderStep("FlyHighCatwalkGuide",Enum.RenderPriority.Input.Value+1,function()
 local hum,hrp,root=catwalkContext()
 if not hum then return end
 local move=hum.MoveDirection
 if move.Magnitude<0.01 then return end
 local rel=root.CFrame:PointToObjectSpace(hrp.Position)
 local flat=Vector3.new(rel.X,0,rel.Z)
 local radius=flat.Magnitude
 if radius<=CATWALK_GUIDE_RADIUS or radius>24 then return end
 local outward=root.CFrame:VectorToWorldSpace(flat/radius)
 local push=move:Dot(outward)
 if push<=0 then return end
 local along=move-outward*push
 along=Vector3.new(along.X,0,along.Z)
 hum:Move(along.Magnitude>0.05 and along.Unit*move.Magnitude or Vector3.zero,false)
end)
script.Destroying:Connect(function() RunService:UnbindFromRenderStep("FlyHighCatwalkGuide") end)
RunService.Heartbeat:Connect(function()
 local hum,hrp,root,model=catwalkContext()
 if not hum then return end
 local frame=root.CFrame
 local standY=catwalkStandY
 local walkway=model:FindFirstChild("EnvelopeWalkway")
 if walkway then standY=frame:PointToObjectSpace(walkway.Position).Y+walkway.Size.X/2+hum.HipHeight+hrp.Size.Y/2 end
 if not standY then return end
 local rel=frame:PointToObjectSpace(hrp.Position)
 -- Already well below the deck: a genuine fall, leave it to the server rope/hang logic.
 if rel.Y<standY-3 then return end
 local flat=Vector3.new(rel.X,0,rel.Z)
 local radius=flat.Magnitude
 local maxY=standY+CATWALK_HEAD_ROOM
 if rel.Y<=maxY and radius<=CATWALK_MAX_RADIUS then return end
 local clamped=radius>CATWALK_MAX_RADIUS and flat*(CATWALK_MAX_RADIUS/radius) or flat
 hrp.CFrame=hrp.CFrame.Rotation+frame:PointToWorldSpace(Vector3.new(clamped.X,math.min(rel.Y,maxY),clamped.Z))
 local base=root:GetVelocityAtPosition(hrp.Position)
 local v=frame:VectorToObjectSpace(hrp.AssemblyLinearVelocity-base)
 local outward=radius>0.01 and flat/radius or Vector3.zero
 local out=math.max(0,v:Dot(outward))
 v=v-outward*out
 hrp.AssemblyLinearVelocity=base+frame:VectorToWorldSpace(Vector3.new(v.X,math.min(v.Y,0),v.Z))
end)
local function restoreHullCollide(entry)
 if not entry.hullDisabled then return end
 for part,orig in pairs(entry.hullOriginalCollide) do
  if part.Parent then part.CanCollide=orig end
 end
 table.clear(entry.hullOriginalCollide)
 entry.hullDisabled=false
end
local function disableHullCollide(entry)
 if entry.hullDisabled then return end
 for _,part in ipairs(entry.model:GetDescendants()) do
  if part:IsA("BasePart") and part.CanCollide then
   entry.hullOriginalCollide[part]=true
   part.CanCollide=false
  end
 end
 entry.hullDisabled=true
end
local function register(model)
 if not model:IsA("Model") or flights[model] or not model:GetAttribute("BalloonThemeId") or model:GetAttribute("IsFleetPreview") then return end
 local barrier=Instance.new("Part")
 barrier.Name="Barrier_"..model.Name
 barrier.Size=Vector3.new(30.4,15.5,30.4)
 barrier.Anchored=true
 barrier.CanCollide=false
 barrier.CanQuery=false
 barrier.CanTouch=false
 barrier.Transparency=1
 barrier.CastShadow=false
 local entry={model=model,prompts={},motors={},connections={},barrier=barrier,hullOriginalCollide={},hullDisabled=false}
 flights[model]=entry
 BalloonVFX.Attach(model)
 local function add(o)
  if o:IsA("ProximityPrompt") then
   -- Mask new prompts before the first visibility pass; otherwise every
   -- server-enabled station action briefly appears during replication.
   o.Enabled=false entry.prompts[o]=true
   if o.Name=="PatchPrompt" or o.Name=="RepairRopePrompt" then o.Style=Enum.ProximityPromptStyle.Custom end
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
  BalloonVFX.Detach(model)
  restoreHullCollide(entry)
  if entry.barrier and entry.barrier.Parent then entry.barrier:Destroy() else entry.barrier:Destroy() end
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
 local camera=workspace.CurrentCamera
 local tickVfx=BalloonVFX.HasActiveEffects()
 elapsed+=dt
 local runSlow=elapsed>=1/30
 if runSlow then elapsed=0 end
 if not camera then return end
 local eye=camera.CFrame.Position local t=workspace:GetServerTimeNow()
 if tickVfx or runSlow then BalloonVFX.Step(t,eye) end
 if not runSlow then return end
 for model,base in pairs(previews) do
  if not model.Parent then previews[model]=nil
  elseif base and (base.Position-eye).Magnitude<95 then
   model:PivotTo(base*CFrame.new(0,math.sin(t*0.9)*0.12,0)*CFrame.Angles(0,t*0.16,0))
  end
 end
 for model,entry in pairs(flights) do
  if not model.Parent then
   BalloonVFX.Detach(model)
   restoreHullCollide(entry)
   if entry.barrier then entry.barrier:Destroy() end
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
-- Airborne crew keeps moving with their balloon. On the floor the humanoid
-- follows the moving basket kinematically (its own world velocity stays ~0), but
-- in the air nothing carries it, so a jump while the pilot steered landed players
-- 7-12 studs off and often over the rail (playtest 17 Nov). While airborne near
-- the own balloon, move the character by the balloon's horizontal velocity each
-- physics step. The replicated velocity is smooth; the replicated CFrame steps.
local AIR_STATES={[Enum.HumanoidStateType.Jumping]=true,[Enum.HumanoidStateType.Freefall]=true,
 [Enum.HumanoidStateType.GettingUp]=true,[Enum.HumanoidStateType.FallingDown]=true}
local lastFollowModel,lastFollowRootPos=nil,nil
RunService.PreSimulation:Connect(function(dt)
 local char=player.Character
 local hum=char and char:FindFirstChildOfClass("Humanoid")
 local hrp=char and char:FindFirstChild("HumanoidRootPart")
 local ref=player:FindFirstChild("FlightBalloon")
 local model=ref and ref.Value
 local inFlight=player:GetAttribute("InFlight")==true
 for bModel,entry in pairs(flights) do
  local bRoot=bModel.PrimaryPart
  local isOther=bModel.Parent~=nil and bRoot~=nil and bModel~=model and bModel:GetAttribute("ArrivalState")==nil
  if not isOther then
   entry.barrier.CanCollide=false
   entry.barrier.Parent=nil
   restoreHullCollide(entry)
  else
   if inFlight and model~=nil then
    disableHullCollide(entry)
   else
    restoreHullCollide(entry)
   end
   entry.barrier.CFrame=bRoot.CFrame*CFrame.new(0,6.5,0)
   entry.barrier.Parent=barrierFolder
   local trappedInside=false
   if hrp then
    local rel=bRoot.CFrame:PointToObjectSpace(hrp.Position)
    trappedInside=math.abs(rel.X)<14.6 and math.abs(rel.Z)<14.6 and rel.Y>-1.0 and rel.Y<13.8
   end
   entry.barrier.CanCollide=not trappedInside
  end
 end
 local root=model and model.PrimaryPart
 local deltaXZ=Vector3.zero
 if inFlight and model and root then
  local rootPos=root.Position
  if lastFollowModel==model and lastFollowRootPos then
   local diff=rootPos-lastFollowRootPos
   deltaXZ=Vector3.new(diff.X,0,diff.Z)
  end
  lastFollowModel=model
  lastFollowRootPos=rootPos
 else
  lastFollowModel=nil
  lastFollowRootPos=nil
 end
 if not (hum and hrp and root) or hum.Health<=0 or not inFlight
  or player:GetAttribute("FlightGhost")==true or hrp.Anchored or hum.Sit or hum.PlatformStand then return end
 if hum.FloorMaterial~=Enum.Material.Air or (not AIR_STATES[hum:GetState()] and tetherStage~="Catwalk") then return end
 local rel=root.CFrame:PointToObjectSpace(hrp.Position)
 if Vector2.new(rel.X,rel.Z).Magnitude>36 or rel.Y<-8 or rel.Y>72 then return end
 if deltaXZ.Magnitude>0 and deltaXZ.Magnitude<12 then hrp.CFrame+=deltaXZ end
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
