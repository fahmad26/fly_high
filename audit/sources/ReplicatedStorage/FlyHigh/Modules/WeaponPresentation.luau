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
  local streak=Instance.new("Part")streak.Name="BulletTracer"streak.Size=Vector3.new(.09,.09,math.min(6,distance))
  streak.Color=Color3.fromRGB(255,211,115)streak.Material=Enum.Material.Neon
  streak.Anchored=true streak.CanCollide=false streak.CanTouch=false streak.CanQuery=false streak.Parent=workspace
  local duration=math.clamp(distance/850,.09,.35)
  table.insert(active,{part=streak,start=start,direction=direction,distance=distance,elapsed=0,duration=duration})
  if #active>32 then active[1].part:Destroy()table.remove(active,1)end
 end)
 local render=Run.RenderStepped:Connect(function(dt)
  for i=#active,1,-1 do local a=active[i]a.elapsed+=dt
   if a.elapsed>=a.duration or not a.part.Parent then a.part:Destroy()table.remove(active,i)
   else
    local fraction=a.elapsed/a.duration local center=a.start+a.direction*(a.distance*fraction)
    a.part.CFrame=CFrame.lookAt(center,center+a.direction)
    a.part.Transparency=.1+fraction*.65
   end
  end
 end)
 owner.Destroying:Connect(function()
  dead=true event:Disconnect()render:Disconnect()
  for _,p in emitters do p:Destroy()end for _,a in active do a.part:Destroy()end
 end)
end
return Presentation
