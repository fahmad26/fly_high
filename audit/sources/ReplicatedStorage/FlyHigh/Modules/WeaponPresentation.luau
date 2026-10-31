local Presentation={}
function Presentation.Start(player,remote,owner)
 local RS=game:GetService("ReplicatedStorage")local Run=game:GetService("RunService")local Debris=game:GetService("Debris")
 local poolFolder=Instance.new("Folder")poolFolder.Name="WeaponAudioPool"poolFolder.Parent=owner
 poolFolder:SetAttribute("ShotCount",0)
 local template=RS.FlyHigh.AudioAssets:WaitForChild("PistolShot")
 local emitters={}local index=0 local sounds={}
 for i=1,8 do
  local p=Instance.new("Part")p.Name="ShotEmitter"p.Size=Vector3.new(.1,.1,.1)p.Transparency=1 p.Anchored=true p.CanCollide=false p.CanTouch=false p.CanQuery=false
  p.Parent=workspace
  local s=template:Clone()s.Name="Gunshot"s.Volume=.65 s.RollOffMinDistance=10 s.RollOffMaxDistance=140 s.Looped=false s.Parent=p
  table.insert(emitters,p)table.insert(sounds,s)
 end
 task.spawn(function()pcall(function()game:GetService("ContentProvider"):PreloadAsync(sounds)end)end)
 local active={}local dead=false
 local event=remote.OnClientEvent:Connect(function(shooter,origin,target)
  if dead or typeof(origin)~="Vector3"or typeof(target)~="Vector3"then return end
  local camera=workspace.CurrentCamera
  if not camera or(origin-camera.CFrame.Position).Magnitude>180 then return end
  local start=origin
  -- The true muzzle may be hidden by the avatar in first person. Render the
  -- local flash/streak just below the sight; damage still uses the server ray.
  if shooter==player and player.CameraMode==Enum.CameraMode.LockFirstPerson then start=camera.CFrame:PointToWorldSpace(Vector3.new(.35,-.28,-1.2))end
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
  streak.Parent=workspace
  local duration=math.clamp(distance/160,.25,1.8)
  table.insert(active,{part=streak,start=start,direction=direction,distance=distance,elapsed=0,duration=duration})
  if #active>32 then active[1].part:Destroy()table.remove(active,1)end
 end)
 local render=Run.RenderStepped:Connect(function(dt)
  for i=#active,1,-1 do local a=active[i]a.elapsed+=dt
   if not a.part.Parent then table.remove(active,i)
   elseif a.elapsed>=a.duration then
    a.part.CFrame=CFrame.lookAt(a.start+a.direction*a.distance,a.start+a.direction*(a.distance+1))
    a.part.Transparency=1 a.part.BulletGlow.Enabled=false a.part.BulletTrail.Enabled=false
    Debris:AddItem(a.part,.13)table.remove(active,i)
   else
    local fraction=a.elapsed/a.duration local center=a.start+a.direction*(a.distance*fraction)
    a.part.CFrame=CFrame.lookAt(center,center+a.direction)
    a.part.Transparency=.02+fraction*.12
   end
  end
 end)
 owner.Destroying:Connect(function()
  dead=true event:Disconnect()render:Disconnect()
  for _,p in emitters do p:Destroy()end for _,a in active do a.part:Destroy()end
 end)
end
return Presentation
