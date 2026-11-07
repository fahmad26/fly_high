local Presentation = {}
local Run = game:GetService("RunService")
local WEAPON_VISIBILITY_STEP = "FlyHighWeaponVisibility"
local LAUNCH_TIME = 0.10
local viewProfiles = {
	Pistol = {
		pose = CFrame.lookAt(Vector3.new(-1.45, 0.68, 2.65), Vector3.new(0, -0.03, -0.15)),
		rightEdge = 0.74,
		widthCap = 0.48,
		compactScale = 0.49,
	},
	AK47 = {
		pose = CFrame.lookAt(Vector3.new(-2.95, 2.18, 5.15), Vector3.new(0, 0.47, -0.48)),
		rightEdge = 0.88,
		widthCap = 0.39,
		compactScale = 0.44,
	},
}

local function createWeaponView(tool, template, hud, profile)
	local handle = template:FindFirstChild("Handle")
	if not handle or not handle:IsA("BasePart") then return nil end

	-- A separate camera keeps the weapon stable on screen and out of world geometry.
	local view = Instance.new("ViewportFrame")
	view.Name = "WeaponView"
	view:SetAttribute("RightEdge", profile.rightEdge)
	view:SetAttribute("WidthCap", profile.widthCap)
	view:SetAttribute("CompactScale", profile.compactScale)
	view.BackgroundTransparency = 1
	view.Size = UDim2.fromOffset(0, 0)
	view.ZIndex = 0
	view.Ambient = Color3.fromRGB(190, 193, 205)
	view.LightColor = Color3.fromRGB(239, 238, 230)
	view.LightDirection = Vector3.new(0.4, -1, -0.6)

	local viewCamera = Instance.new("Camera")
	viewCamera.FieldOfView = 35
	viewCamera.CFrame = profile.pose
	viewCamera.Parent = view
	view.CurrentCamera = viewCamera

	for _, part in template:GetDescendants() do
		if part:IsA("BasePart") and part.Transparency < 1 then
			local copy = part:Clone()
			for _, child in copy:GetChildren() do
				if not (child:IsA("DataModelMesh") or child:IsA("Decal") or child:IsA("SurfaceAppearance")) then
					child:Destroy()
				end
			end
			copy.CFrame = handle.CFrame:ToObjectSpace(part.CFrame)
			copy.Anchored = true
			copy.CanCollide = false
			copy.CanTouch = false
			copy.CanQuery = false
			copy.LocalTransparencyModifier = 0
			copy.Parent = view
		end
	end

	view.Parent = hud

	-- Only the shooter sees the replacement. The actual Tool stays equipped.
	local originalOpacity = {}
	local function hidePart(part)
		if part:IsA("BasePart") and originalOpacity[part] == nil then
			originalOpacity[part] = part.LocalTransparencyModifier
			part.LocalTransparencyModifier = 1
		end
	end
	local function restorePart(part)
		local opacity = originalOpacity[part]
		if opacity ~= nil then
			part.LocalTransparencyModifier = opacity
			originalOpacity[part] = nil
		end
	end
	for _, part in tool:GetDescendants() do hidePart(part) end
	local partAdded = tool.DescendantAdded:Connect(hidePart)
	local partRemoving = tool.DescendantRemoving:Connect(restorePart)
	Run:BindToRenderStep(WEAPON_VISIBILITY_STEP, Enum.RenderPriority.Camera.Value + 1, function()
		for part in originalOpacity do
			if part.LocalTransparencyModifier ~= 1 then
				part.LocalTransparencyModifier = 1
			end
		end
	end)

	local muzzle = handle:FindFirstChild("MuzzleAttachment")
	local muzzleOffset = muzzle and muzzle:IsA("Attachment") and muzzle.Position
	local function muzzleScreenPoint()
		if not muzzleOffset or not hud.Enabled or view.AbsoluteSize.X <= 0 then return nil end
		local projected = viewCamera:WorldToViewportPoint(muzzleOffset)
		return view.AbsolutePosition + Vector2.new(projected.X, projected.Y) * view.AbsoluteSize
	end

	local function destroy()
		Run:UnbindFromRenderStep(WEAPON_VISIBILITY_STEP)
		partAdded:Disconnect()
		partRemoving:Disconnect()
		for part in originalOpacity do restorePart(part) end
		view:Destroy()
	end
	return { muzzleScreenPoint = muzzleScreenPoint, destroy = destroy }
end

local function launchTracer(hud, muzzle)
	local marker = Instance.new("Frame")
	marker.Name = "WeaponLaunchTracer"
	marker.AnchorPoint = Vector2.new(0.5, 0.5)
	marker.Position = UDim2.fromOffset(math.round(muzzle.X), math.round(muzzle.Y))
	marker.Size = UDim2.fromOffset(10, 4)
	marker.BackgroundColor3 = Color3.fromRGB(255, 213, 116)
	marker.BorderSizePixel = 0
	marker.ZIndex = 2
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = marker
	marker.Parent = hud
	return { marker = marker, muzzle = muzzle }
end

function Presentation.Start(player,remote,owner,hud)
 local RS=game:GetService("ReplicatedStorage")local Debris=game:GetService("Debris")
 local templates=RS.FlyHigh.Templates.Weapons
 local audioAssets=RS.FlyHigh.AudioAssets
 local reloadTemplate=audioAssets:FindFirstChild("WeaponReload")
 local reloadSound=reloadTemplate and reloadTemplate:Clone()
 if reloadSound then reloadSound.Parent=owner end
 local reloadConnection
 local weaponView
 local function setWeapon(tool)
  if reloadConnection then
   reloadConnection:Disconnect()
   reloadConnection=nil
  end
  if reloadSound then reloadSound:Stop()end
  if weaponView then
   weaponView.destroy()
   weaponView=nil
  end
  local profile=tool and viewProfiles[tool.Name]
  local template=profile and templates:FindFirstChild(tool.Name)
  if template then weaponView=createWeaponView(tool,template,hud,profile)end
  if tool and reloadSound then
   local wasReloading=false
   local function syncReload()
    local reloading=tool:GetAttribute("Reloading")==true
    if reloading==wasReloading then return end
    wasReloading=reloading
    if reloading then
     reloadSound.TimePosition=0
     reloadSound:Play()
    else
     reloadSound:Stop()
    end
   end
   reloadConnection=tool:GetAttributeChangedSignal("Reloading"):Connect(syncReload)
   syncReload()
  end
 end
 local poolFolder=Instance.new("Folder")poolFolder.Name="WeaponAudioPool"poolFolder.Parent=owner
 poolFolder:SetAttribute("ShotCount",0)
 local template=audioAssets:WaitForChild("PistolShot")
 local emitters={}local index=0 local sounds={}
 for i=1,8 do
  local p=Instance.new("Part")p.Name="ShotEmitter"p.Size=Vector3.new(.1,.1,.1)p.Transparency=1 p.Anchored=true p.CanCollide=false p.CanTouch=false p.CanQuery=false
  p.Parent=workspace
  local s=template:Clone()s.Name="Gunshot"s.Volume=.65 s.RollOffMinDistance=10 s.RollOffMaxDistance=140 s.Looped=false s.Parent=p
  table.insert(emitters,p)table.insert(sounds,s)
 end
 local preload=table.clone(sounds)
 if reloadSound then table.insert(preload,reloadSound)end
 task.spawn(function()pcall(function()game:GetService("ContentProvider"):PreloadAsync(preload)end)end)
 local active={}local dead=false
 local function clearLaunch(shot)
  if shot.launch then
   shot.launch.marker:Destroy()
   shot.launch=nil
  end
 end
 local event=remote.OnClientEvent:Connect(function(shooter,origin,target)
  if dead or typeof(origin)~="Vector3"or typeof(target)~="Vector3"then return end
  local camera=workspace.CurrentCamera
  if not camera or(origin-camera.CFrame.Position).Magnitude>180 then return end
  local start=origin
  local muzzle
  if shooter==player and player.CameraMode==Enum.CameraMode.LockFirstPerson then
   muzzle=weaponView and weaponView.muzzleScreenPoint()
   if muzzle then start=camera:ScreenPointToRay(muzzle.X,muzzle.Y,1.2).Origin end
  end
  local delta=target-start if delta.Magnitude<.01 then return end
  local direction=delta.Unit local distance=delta.Magnitude
  index=index%#emitters+1 emitters[index].Position=start
  local sound=sounds[index]sound:Stop()sound.TimePosition=0
  local tool=shooter and shooter.Character and shooter.Character:FindFirstChildOfClass("Tool")
  sound.PlaybackSpeed=tool and tool.Name=="AK47"and .9 or 1 sound:Play()
  poolFolder:SetAttribute("ShotCount",poolFolder:GetAttribute("ShotCount")+1)
  local flash=Instance.new("Part")flash.Name="WeaponMuzzleFlash"flash.Shape=Enum.PartType.Ball flash.Size=Vector3.new(.26,.26,.26)
  flash.Color=Color3.fromRGB(255,215,130)flash.Material=Enum.Material.Neon flash.Position=start
  flash.Anchored=true flash.CanCollide=false flash.CanTouch=false flash.CanQuery=false flash.Parent=workspace Debris:AddItem(flash,.07)
  local light=Instance.new("PointLight")light.Color=flash.Color light.Brightness=1.3 light.Range=5 light.Parent=flash
  local streak=Instance.new("Part")streak.Name="FlyingBullet"streak.Shape=Enum.PartType.Ball streak.Size=Vector3.new(.24,.24,.85)
  streak.Color=Color3.fromRGB(255,208,86)streak.Material=Enum.Material.Neon
  streak.Anchored=true streak.CanCollide=false streak.CanTouch=false streak.CanQuery=false
  streak.CFrame=CFrame.lookAt(start,start+direction)
  local a0=Instance.new("Attachment",streak)a0.Position=Vector3.new(-.12,0,.3)
  local a1=Instance.new("Attachment",streak)a1.Position=Vector3.new(.12,0,.3)
  local trail=Instance.new("Trail",streak)trail.Name="BulletTrail"trail.Attachment0=a0 trail.Attachment1=a1
  trail.FaceCamera=true trail.Lifetime=.12 trail.MinLength=.05 trail.LightEmission=1
  trail.Color=ColorSequence.new(streak.Color,Color3.fromRGB(195,116,37))
  trail.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,.05),NumberSequenceKeypoint.new(1,1)})
  -- A six-pixel core keeps the moving bullet readable when its 3D body becomes
  -- subpixel at range. World occlusion still applies; it is not a HUD reticle.
  local glow=Instance.new("BillboardGui",streak)glow.Name="BulletGlow"glow.Size=UDim2.fromOffset(6,6)glow.AlwaysOnTop=false glow.MaxDistance=520 glow.LightInfluence=0
  local dot=Instance.new("Frame",glow)dot.Size=UDim2.fromScale(1,1)dot.BackgroundColor3=streak.Color dot.BorderSizePixel=0
  Instance.new("UICorner",dot).CornerRadius=UDim.new(1,0)
  -- The weapon viewport can cover the world bullet at the muzzle. Draw the first
  -- tenth of a second above the viewport, then hand off to the same world path.
  local launch=muzzle and launchTracer(hud,muzzle)
  if launch then
   streak.Transparency=1
   glow.Enabled=false
   trail.Enabled=false
  end
  streak.Parent=workspace
  local duration=math.clamp(distance/160,.25,1.8)
  table.insert(active,{part=streak,start=start,direction=direction,distance=distance,elapsed=0,duration=duration,launch=launch})
  if #active>32 then
   local oldest=table.remove(active,1)
   clearLaunch(oldest)
   oldest.part:Destroy()
  end
 end)
 local render=Run.RenderStepped:Connect(function(dt)
  for i=#active,1,-1 do
   local a=active[i]
   if a.launch and not a.launch.rendered then
    a.launch.rendered=true
    continue -- Keep the first rendered frame on the muzzle, even at low FPS.
   end
   a.elapsed+=dt
   if not a.part.Parent then clearLaunch(a)table.remove(active,i)
   elseif a.elapsed>=a.duration then
    clearLaunch(a)
    a.part.CFrame=CFrame.lookAt(a.start+a.direction*a.distance,a.start+a.direction*(a.distance+1))
    a.part.Transparency=1 a.part.BulletGlow.Enabled=false a.part.BulletTrail.Enabled=false
    Debris:AddItem(a.part,.13)table.remove(active,i)
   else
    local fraction=a.elapsed/a.duration local center=a.start+a.direction*(a.distance*fraction)
    a.part.CFrame=CFrame.lookAt(center,center+a.direction)
    if a.launch and a.elapsed<LAUNCH_TIME then
     local camera=workspace.CurrentCamera
     if camera then
      local projected=camera:WorldToScreenPoint(center)
      if projected.Z>0 then
       local delta=Vector2.new(projected.X,projected.Y)-a.launch.muzzle
       local point=a.launch.muzzle+delta*(a.elapsed/LAUNCH_TIME)
       a.launch.marker.Position=UDim2.fromOffset(point.X,point.Y)
       a.launch.marker.Rotation=math.deg(math.atan2(delta.Y,delta.X))
      end
     end
    else
     if a.launch then
      clearLaunch(a)
      a.part.BulletGlow.Enabled=true
      a.part.BulletTrail.Enabled=true
     end
     a.part.Transparency=.02+fraction*.12
    end
   end
  end
 end)
 owner.Destroying:Connect(function()
  setWeapon(nil)
  dead=true event:Disconnect()render:Disconnect()
  for _,p in emitters do p:Destroy()end
  for _,a in active do clearLaunch(a)a.part:Destroy()end
 end)
 return setWeapon
end
return Presentation
