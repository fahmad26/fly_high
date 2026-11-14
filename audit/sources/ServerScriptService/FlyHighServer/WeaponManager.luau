local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local Debris=game:GetService("Debris")
local Config=require(RS.FlyHigh.Modules.FlyHighConfig)
local U=require(script.Parent.ServerUtils)
local RackArt=require(script.Parent.WeaponRackPresentation)
local remotes=RS.FlyHigh.Remotes
local Manager={held={},racks=setmetatable({},{__mode="k"})}
_G.FlyHighWeaponManager=Manager
local IK_AIM_NAME="FlyHighRightAimIK"
local IK_SUPPORT_NAME="FlyHighLeftSupportIK"
local HOLD_PROFILES={
 AK47={
  reachRatio=0.24,minZ=0.34,maxZ=0.62,
  offsetXRatio=0.32,offsetYRatio=-0.22,offsetYConst=-0.08,
  pitchDeg=-11.5,yawDeg=15,
  leftPart="WoodHandguard",leftTargetOffset=Vector3.new(-0.04,-0.16,0.35),
 },
 Pistol={
  useBoneReach=true,
  reachRatio=0.72,frontMargin=0.14,maxZ=1.35,
  shoulderXRatio=0.42,offsetXRatio=0.14,offsetYRatio=-0.08,offsetYConst=0,
  pitchDeg=0,yawDeg=-12,
  leftPart="Handle",leftTargetOffset=Vector3.new(-0.06,-0.10,0.04),
 },
}
local function cleanupTwoHandIK(character)
 if not character then return end
 local hum=character:FindFirstChildOfClass("Humanoid")
 if hum then
  for _,child in ipairs(hum:GetChildren()) do
   if child:IsA("IKControl") and (child.Name==IK_AIM_NAME or child.Name==IK_SUPPORT_NAME) then
    child:Destroy()
   end
  end
 end
 local torso=character:FindFirstChild("UpperTorso")
 local aimAtt=torso and torso:FindFirstChild("RightAimTarget")
 if aimAtt then aimAtt:Destroy() end
end
local function measureArmReach(torso,rUA,rLA)
 local sAtt=rUA:FindFirstChild("RightShoulderRigAttachment")
 local eAtt=rUA:FindFirstChild("RightElbowRigAttachment")
 local wAtt=rLA and rLA:FindFirstChild("RightWristRigAttachment")
 if sAtt and eAtt and wAtt then
  return (eAtt.WorldPosition-sAtt.WorldPosition).Magnitude+(wAtt.WorldPosition-eAtt.WorldPosition).Magnitude,
   torso.CFrame:PointToObjectSpace(sAtt.WorldPosition)
 end
 return rUA.Size.Y+(rLA and rLA.Size.Y or rUA.Size.Y),
  Vector3.new(torso.Size.X*0.5,torso.Size.Y*0.35,0)
end
local function applyTwoHandIK(character,tool,weaponType)
 local profile=HOLD_PROFILES[weaponType]
 if not (character and tool and profile) then return end
 cleanupTwoHandIK(character)
 local hum=character:FindFirstChildOfClass("Humanoid")
 local torso=character:FindFirstChild("UpperTorso")
 local rUA=character:FindFirstChild("RightUpperArm")
 local rLA=character:FindFirstChild("RightLowerArm")
 local rH=character:FindFirstChild("RightHand")
 local lUA=character:FindFirstChild("LeftUpperArm")
 local lH=character:FindFirstChild("LeftHand")
 local rGripAtt=rH and rH:FindFirstChild("RightGripAttachment")
 if not (hum and torso and rUA and rH and lUA and lH and rGripAtt) then return end
 if not hum:FindFirstChildOfClass("Animator") then Instance.new("Animator",hum) end
 local torsoW,torsoH=torso.Size.X,torso.Size.Y
 local distZ,posX
 if profile.useBoneReach then
  local boneReach,sRel=measureArmReach(torso,rUA,rLA)
  distZ=-math.clamp(-sRel.Z+boneReach*profile.reachRatio,torso.Size.Z*0.5+profile.frontMargin,profile.maxZ)
  posX=sRel.X*profile.shoulderXRatio
 else
  local armReach=rUA.Size.Y+(rLA and rLA.Size.Y or rUA.Size.Y)
  distZ=-math.clamp(armReach*profile.reachRatio,profile.minZ,profile.maxZ)
  posX=torsoW*profile.offsetXRatio
 end
 local handleRelTorso=CFrame.new(posX,torsoH*profile.offsetYRatio+profile.offsetYConst,distZ)
  *CFrame.Angles(0,math.rad(profile.yawDeg),0)
  *CFrame.Angles(math.rad(profile.pitchDeg),0,0)
 local aimAtt=Instance.new("Attachment")
 aimAtt.Name="RightAimTarget"
 aimAtt.CFrame=handleRelTorso*tool.Grip*rGripAtt.CFrame:Inverse()
 aimAtt.Parent=torso
 local gripPart=tool:FindFirstChild(profile.leftPart) or tool:FindFirstChild("Handle")
 local leftTarget=gripPart and gripPart:FindFirstChild("LeftHandGripTarget")
 if gripPart and not leftTarget then
  leftTarget=Instance.new("Attachment")
  leftTarget.Name="LeftHandGripTarget"
  leftTarget.Position=profile.leftTargetOffset
  leftTarget.Parent=gripPart
 end
 local rIK=Instance.new("IKControl")
 rIK.Name=IK_AIM_NAME
 rIK.Type=Enum.IKControlType.Transform
 rIK.ChainRoot=rUA
 rIK.EndEffector=rH
 rIK.Target=aimAtt
 rIK.SmoothTime=0.08
 rIK.Weight=1
 rIK.Parent=hum
 if leftTarget then
  local lIK=Instance.new("IKControl")
  lIK.Name=IK_SUPPORT_NAME
  lIK.Type=Enum.IKControlType.Position
  lIK.ChainRoot=lUA
  lIK.EndEffector=lH
  lIK.Target=leftTarget
  lIK.SmoothTime=0.08
  lIK.Weight=1
  lIK.Parent=hum
 end
end
local function state(s)
 s.tool:SetAttribute("CurrentMag",s.ammo)
 s.tool:SetAttribute("Reloading",s.reloading==true)
end
function Manager.CleanupPlayer(p)
 local s=Manager.held[p]
 if not s then return end
 Manager.held[p]=nil
 if s.unequipped then s.unequipped:Disconnect() end
 if s.died then s.died:Disconnect() end
 if s.charRemoving then s.charRemoving:Disconnect() end
 cleanupTwoHandIK(s.character or p.Character)
 if p.Parent==Players then p:SetAttribute("CrewRole",nil) end
 s.tool:Destroy()
 if s.rack.Parent then
  s.rack:SetAttribute("StoredAmmo",s.ammo)
  s.rack:SetAttribute("StoredLastShot",s.lastShot)
  s.rack:SetAttribute("StoredReloadEnds",s.reloadEnds or 0)
  s.rack:SetAttribute("IsOccupied",true) s.rack.PickupPrompt.Enabled=true
  RackArt.Update(s.rack)
 end
end
function Manager.CleanupBalloon(b)
 for p,s in pairs(table.clone(Manager.held)) do if s.balloon==b then Manager.CleanupPlayer(p) end end
end
function Manager.TryEquip(p,b,rack)
 local prompt=rack.PickupPrompt
   if not U.CrewNear(p,b,rack,10) or not U.CanStartRole(p) or not rack:GetAttribute("IsOccupied") then return end
   local weaponType=rack:GetAttribute("CurrentWeapon")
   local cfg=Config.WEAPONS[weaponType]
   local tool=RS.FlyHigh.Templates.Weapons[weaponType]:Clone()
   tool.CanBeDropped=false
   tool.ManualActivationOnly=true
   for k,v in pairs(cfg) do if k~="Name" then tool:SetAttribute(k,v) end end
   tool:SetAttribute("WeaponType",weaponType)
   local s={tool=tool,ammo=rack:GetAttribute("StoredAmmo") or cfg.MagSize,cfg=cfg,rack=rack,balloon=b,lastShot=rack:GetAttribute("StoredLastShot") or -math.huge}
   local deadline=rack:GetAttribute("StoredReloadEnds") or 0
   if deadline>os.clock() then
    s.reloading=true s.reloadEnds=deadline
    task.delay(deadline-os.clock(),function()
     if Manager.held[p]==s then s.ammo=cfg.MagSize s.reloading=false s.reloadEnds=nil state(s) end
    end)
   elseif deadline>0 then s.ammo=cfg.MagSize end
   Manager.held[p]=s state(s)
   rack:SetAttribute("IsOccupied",false) prompt.Enabled=false
   RackArt.Update(rack)
   p:SetAttribute("CrewRole","Gunner")
   tool.Parent=p.Backpack
   local char=p.Character
   local hum=char and char:FindFirstChildOfClass("Humanoid")
   if not hum then Manager.CleanupPlayer(p) return false end
   s.character=char
   hum:EquipTool(tool)
   applyTwoHandIK(char,tool,weaponType)
   -- Roblox's number key/backpack unequip must return the gun to its rack too.
   s.unequipped=tool.Unequipped:Connect(function()
    task.defer(function()if Manager.held[p]==s and tool.Parent~=p.Character then Manager.CleanupPlayer(p)end end)
   end)
   s.died=hum.Died:Connect(function()
    if Manager.held[p]==s then Manager.CleanupPlayer(p) end
   end)
   s.charRemoving=p.CharacterRemoving:Connect(function(oldChar)
    if Manager.held[p]==s and oldChar==s.character then Manager.CleanupPlayer(p) end
   end)
 return true
end
function Manager.SetupWeaponRacks(b,slot1AK,slot2AK)
 if slot2AK==nil then slot2AK=slot1AK end
 local rifleByRack={slot1AK,slot2AK}
 for i=1,2 do
  local rack=b:FindFirstChild("WeaponRack"..i)
  local kind=rifleByRack[i] and "AK47" or "Pistol"
  if rack:GetAttribute("CurrentWeapon")~=kind then
   rack:SetAttribute("StoredAmmo",nil) rack:SetAttribute("StoredReloadEnds",nil) rack:SetAttribute("StoredLastShot",nil)
  end
  rack:SetAttribute("CurrentWeapon",kind)
  RackArt.Build(rack,kind)
  local prompt=rack:FindFirstChild("PickupPrompt") or Instance.new("ProximityPrompt",rack)
  prompt.Name="PickupPrompt" prompt.ActionText=rifleByRack[i] and "Ambil AK-47" or "Ambil Handgun" prompt.ObjectText="Rak Senjata "..i
  prompt.KeyboardKeyCode=Enum.KeyCode.E prompt.GamepadKeyCode=Enum.KeyCode.ButtonX
  prompt.HoldDuration=0.2 prompt.MaxActivationDistance=8 prompt.RequiresLineOfSight=false
  if Manager.racks[rack] then continue end
  Manager.racks[rack]=true rack:SetAttribute("IsOccupied",true)
  prompt.Triggered:Connect(function(p)Manager.TryEquip(p,b,rack)end)
 end
end
-- Only server-managed, live obstacle models may receive weapon damage.
local function liveObstacle(model)
 if typeof(model)~="Instance" or not model:IsA("Model")
  or model.Parent~=workspace:FindFirstChild("FlyHighObstacles")
  or model:GetAttribute("IsObstacle")~=true or model:GetAttribute("Shootable")~=true then return false end
 local hp=model:GetAttribute("Health")
 if type(hp)~="number" or hp~=hp or hp<=0 or hp==math.huge then return false end
 local manager=_G.FlyHighObstacleManager
 for _,item in ipairs(manager and manager.activeObstacles or {})do
  if item.instance==model and item.shootable and os.clock()>=item.activeAt and os.clock()<item.expires then return true end
 end
 return false
end
local dropRate=U.RateLimiter(0.2)
remotes.WeaponDropEvent.OnServerEvent:Connect(function(p)
 if dropRate(p) then Manager.CleanupPlayer(p) end
end)
local function reload(p,s)
 if s.reloading or s.ammo==s.cfg.MagSize then return end
 s.reloading=true s.reloadEnds=os.clock()+s.cfg.ReloadTime state(s)
 task.delay(s.cfg.ReloadTime,function()
  if Manager.held[p]~=s or not s.tool.Parent then return end
  s.ammo=s.cfg.MagSize s.reloading=false s.reloadEnds=nil state(s)
 end)
end
local reloadRate=U.RateLimiter(0.25)
remotes.WeaponReloadEvent.OnServerEvent:Connect(function(p)
 local s=Manager.held[p]
 if s and U.Alive(p,U.Flight(p)) and reloadRate(p) then reload(p,s) end
end)
remotes.WeaponFireEvent.OnServerEvent:Connect(function(p,_clientOrigin,target,clientTargetModel)
 local s=Manager.held[p] local fd=U.Flight(p)
 if not s or not fd or not U.Alive(p,fd) or s.balloon~=fd.balloon or s.tool.Parent~=p.Character or not U.FiniteVector(target) then return end
 if not U.Near(p,fd.root,75) or s.reloading or os.clock()-s.lastShot<s.cfg.FireRate-0.01 then return end
 if s.ammo<=0 then reload(p,s) return end
 local handle=s.tool:FindFirstChild("Handle")
 if not handle then return end
 local muzzle=handle:FindFirstChild("MuzzleAttachment")
 local origin=muzzle and muzzle.WorldPosition or handle.Position
 local targetPos=target
 if clientTargetModel~=nil and not liveObstacle(clientTargetModel) then return end
 if clientTargetModel then
  local targetPart=clientTargetModel.PrimaryPart or clientTargetModel:FindFirstChildWhichIsA("BasePart")
  if targetPart then targetPos=targetPart.Position end
 end
 local delta=targetPos-origin
 if not U.FiniteVector(delta) or delta.Magnitude<0.01 then return end
 if clientTargetModel and delta.Magnitude>500 then return end
 s.lastShot=os.clock() s.ammo-=1 state(s)
 local direction=delta.Unit
 local spread=CFrame.lookAt(Vector3.zero,direction)*CFrame.Angles(math.rad((math.random()-0.5)*1.5),math.rad((math.random()-0.5)*1.5),0)
 direction=spread.LookVector
 local params=RaycastParams.new()
 params.FilterType=Enum.RaycastFilterType.Exclude
 local excluded={p.Character}
 for _,other in ipairs(_G.FlyHighBalloonManager.activeFlights)do
  if other~=fd then table.insert(excluded,other.balloon)end
 end
 for _,piece in ipairs(fd.balloon:GetDescendants())do
  if piece:IsA("BasePart")and piece~=fd.balloon.Envelope then table.insert(excluded,piece)end
 end
 params.FilterDescendantsInstances=excluded
 local hit=workspace:Raycast(origin,direction*500,params)
 -- Aim tolerance may widen a miss, but must never cross a world blocker.
 if not hit then
  local sphereHit=workspace:Spherecast(origin,2.5,direction*500,params)
  if sphereHit then
   local candidate=sphereHit.Instance:FindFirstAncestorOfClass("Model")
   if sphereHit.Instance==fd.balloon.Envelope then
    hit=sphereHit
   elseif liveObstacle(candidate) then
    local targetPart=candidate.PrimaryPart or candidate:FindFirstChildWhichIsA("BasePart")
    local sight=targetPart and workspace:Raycast(origin,targetPart.Position-origin,params)
    if sight and sight.Instance:IsDescendantOf(candidate) then hit=sphereHit end
   end
  end
 end
 local part=hit and hit.Instance
 if part==fd.balloon.Envelope then _G.FlyHighBalloonManager.ApplyPuncture(fd,"SelfShot")end
 local model=part and part:FindFirstAncestorOfClass("Model")
 if liveObstacle(model) then
  local hp=(model:GetAttribute("Health") or 50)-s.cfg.Damage
  model:SetAttribute("Health",hp)
  if hp<=0 then model:Destroy() end
 end
 remotes.WeaponFireEvent:FireAllClients(p,origin,hit and hit.Position or origin+direction*500)
 if s.ammo<=0 then reload(p,s) end
end)
Players.PlayerRemoving:Connect(Manager.CleanupPlayer)
