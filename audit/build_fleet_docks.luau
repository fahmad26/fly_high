assert(game:GetService("RunService"):IsStudio() and not game:GetService("RunService"):IsRunning())
local RS=game.ReplicatedStorage
local Themes=require(RS.FlyHigh.Modules.BalloonThemes)
local pods=workspace.FlyHighLobby.MatchmakingPods
local templates=RS.FlyHigh.Templates
local rng=Random.new(281026)
local function part(parent,name,size,cf,color,material,shape)
 local p=Instance.new("Part") p.Name=name p.Size=size p.CFrame=cf p.Color=color p.Material=material or Enum.Material.Wood
 p.Shape=shape or Enum.PartType.Block p.Anchored=true p.CanCollide=false p.CanTouch=false p.CanQuery=false p.Parent=parent
 return p
end
local function cylinder(parent,name,pos,length,diameter,color,material)
 return part(parent,name,Vector3.new(length,diameter,diameter),CFrame.new(pos)*CFrame.Angles(0,0,math.pi/2),color,material,Enum.PartType.Cylinder)
end
local function label(gui,name,text,x,y,w,h,size,color,font)
 local l=Instance.new("TextLabel") l.Name=name l.Text=text l.Position=UDim2.fromOffset(x,y) l.Size=UDim2.fromOffset(w,h)
 l.BackgroundTransparency=1 l.TextColor3=color l.Font=font or Enum.Font.Gotham l.TextSize=size l.TextXAlignment=Enum.TextXAlignment.Left
 l.TextWrapped=false l.TextTruncate=Enum.TextTruncate.AtEnd l.Parent=gui return l
end
for _,podName in ipairs(Themes.Order) do
 local theme=Themes.Get(podName) local pod=pods[podName]
 pod:SetAttribute("BalloonThemeId",theme.Id) pod:SetAttribute("BalloonTemplate",theme.Template) pod:SetAttribute("ThemeName",theme.Name)
 local base=pod.FloorPad.Position local center=Vector3.new(base.X,10.1,base.Z)
 local old=pod:FindFirstChild("DockDecor") if old then old:Destroy() end
 local decor=Instance.new("Model") decor.Name="DockDecor" decor.Parent=pod
 local stone=cylinder(decor,"StoneFoundation",center-Vector3.new(0,0.42,0),0.9,23,Color3.fromRGB(107,111,107),Enum.Material.Slate)
 stone.CanCollide=true stone.CanQuery=true
 local deck=cylinder(decor,"TimberDeck",center,0.36,22,Color3.fromRGB(133,100,68),Enum.Material.WoodPlanks)
 deck.CanCollide=true deck.CanQuery=true
 local rim=templates.FleetGeometry.DockRim:Clone() rim.Name="BrassRim" rim:PivotTo(CFrame.new(center+Vector3.new(0,0.25,0))) rim.Parent=decor
 for _,p in ipairs(rim:GetDescendants()) do if p:IsA("BasePart") and p.Transparency<1 then p.Color=theme.Accent end end
 for i=-4,4 do
  local x=i*2.15 local length=2*math.sqrt(math.max(0,10.6^2-x*x))
  part(decor,"PlankSeam",Vector3.new(0.045,0.025,length),CFrame.new(center+Vector3.new(x,0.2,0)),Color3.fromRGB(87,65,45))
 end
 for i=2,10 do
  local angle=i*math.pi/6
  local p=center+Vector3.new(math.sin(angle)*10.3,0.54,math.cos(angle)*10.3)
  part(decor,"EdgePost",Vector3.new(0.34,0.75,0.34),CFrame.new(p)*CFrame.Angles(0,angle,0),theme.Dark)
 end
 local pad=pod.FloorPad
 pad.Position=center+Vector3.new(0,0.1,0) pad.Size=Vector3.new(17,0.2,17)
 pad.Transparency=1 pad.CanCollide=false pad.CanTouch=false pad.CanQuery=false
 pod.Border.Transparency=1 pod.Border.CanCollide=false pod.Border.CanTouch=false pod.Border.CanQuery=false
 if pod:FindFirstChild("Screen") then pod.Screen.Transparency=1 pod.Screen.CanCollide=false pod.Screen.CanTouch=false pod.Screen.CanQuery=false end
 local console=pod.Console
 console.Size=Vector3.new(8.1,5.3,0.6)
 console.CFrame=CFrame.new(center+Vector3.new(-7.3,3.4,5.8))*CFrame.Angles(-math.rad(8),0,0)
 console.Material=Enum.Material.Wood console.Color=theme.Dark console.CanCollide=true console.CanQuery=true
 for _,x in ipairs({-10.5,-4.1}) do
  cylinder(decor,"SignPost",Vector3.new(center.X+x,11.4,center.Z+5.9),2.6,0.3,Color3.fromRGB(119,86,53),Enum.Material.Wood)
 end
 local trim=part(decor,"SignTopTrim",Vector3.new(8.6,0.2,0.85),console.CFrame*CFrame.new(0,2.85,0),theme.Accent,Enum.Material.Metal)
 local gui=console:FindFirstChild("StatusGui") if gui then gui:Destroy() end
 gui=Instance.new("SurfaceGui") gui.Name="StatusGui" gui.Face=Enum.NormalId.Back
 gui.SizingMode=Enum.SurfaceGuiSizingMode.FixedSize gui.CanvasSize=Vector2.new(560,380)
 gui.AlwaysOnTop=false gui.LightInfluence=0 gui.Parent=console
 local bg=Instance.new("Frame") bg.Name="Background" bg.Size=UDim2.fromScale(1,1) bg.BackgroundColor3=Color3.fromRGB(26,33,40) bg.BorderSizePixel=0 bg.ZIndex=0 bg.Parent=gui
 local corner=Instance.new("UICorner",bg) corner.CornerRadius=UDim.new(0,16)
 label(gui,"PodTitle","DERMAGA "..theme.Id,26,16,510,30,21,theme.Accent,Enum.Font.GothamBold)
 label(gui,"ThemeTitle",theme.Name,26,53,510,52,34,Color3.fromRGB(246,235,212),Enum.Font.GothamBold)
 label(gui,"CountLabel","0 / 3 KRU",26,116,300,38,26,Color3.fromRGB(226,232,231),Enum.Font.GothamBold)
 for i=1,3 do
  local slot=Instance.new("Frame") slot.Name="CrewSlot"..i slot.Size=UDim2.fromOffset(34,34) slot.Position=UDim2.fromOffset(400+(i-1)*44,117)
  slot.BackgroundColor3=Color3.fromRGB(61,70,76) slot.BorderSizePixel=0 slot.Parent=gui
  local c=Instance.new("UICorner",slot) c.CornerRadius=UDim.new(0.5,0)
 end
 label(gui,"MasterInfo","MASTER • Belum ada",26,168,510,35,22,Color3.fromRGB(202,211,214),Enum.Font.Gotham)
 label(gui,"StatusLabel","Menunggu kru",26,209,510,34,22,Color3.fromRGB(143,171,169),Enum.Font.Gotham)
 local line=Instance.new("Frame") line.Name="Divider" line.Size=UDim2.fromOffset(508,2) line.Position=UDim2.fromOffset(26,257) line.BackgroundColor3=theme.Accent line.BorderSizePixel=0 line.Parent=gui
 label(gui,"StartHint","E  •  MULAI PENERBANGAN",26,275,510,44,24,theme.Accent,Enum.Font.GothamBold)
 label(gui,"Footer","Master memulai • 1–3 pemain",26,327,510,28,17,Color3.fromRGB(159,174,180))
 local prompt=console.StartPrompt prompt.ActionText="Mulai Penerbangan" prompt.ObjectText=theme.Name
 prompt.HoldDuration=0.2 prompt.MaxActivationDistance=12 prompt.RequiresLineOfSight=false
 local lights=Instance.new("Folder") lights.Name="StatusLights" lights.Parent=decor
 for _,x in ipairs({-9.1,9.1}) do
  local p=center+Vector3.new(x,0.8,6)
  cylinder(decor,"LanternStand",p,1.1,0.26,Color3.fromRGB(124,94,59),Enum.Material.Wood)
  local lamp=part(lights,"StatusLamp",Vector3.new(0.48,0.48,0.48),CFrame.new(p+Vector3.new(0,0.7,0)),theme.Accent,Enum.Material.Neon,Enum.PartType.Ball)
  local light=Instance.new("PointLight") light.Color=theme.Accent light.Brightness=0.8 light.Range=5 light.Shadows=false light.Parent=lamp
 end
 local pedestal=center+Vector3.new(6.7,0.45,4.7)
 cylinder(decor,"PreviewPedestal",pedestal,0.65,4.7,Color3.fromRGB(95,93,85),Enum.Material.Slate)
 cylinder(decor,"PreviewPedestalCap",pedestal+Vector3.new(0,0.4,0),0.17,5.0,theme.Accent,Enum.Material.Metal)
 local variants=templates:FindFirstChild("BalloonVariants")
 if variants and variants:FindFirstChild(theme.Template) then
  local preview=variants[theme.Template]:Clone() preview.Name="PreviewBalloon"
  for _,o in ipairs(preview:GetDescendants()) do
   if o:IsA("LuaSourceContainer") or o:IsA("ProximityPrompt") or o:IsA("Constraint") or o:IsA("WeldConstraint") or o:IsA("Motor6D") or o:IsA("Fire") or o:IsA("Light") then o:Destroy()
   elseif o:IsA("BasePart") then o.Anchored=true o.CanCollide=false o.CanTouch=false o.CanQuery=false end
  end
  if preview:FindFirstChild("HoleSlots") then preview.HoleSlots:Destroy() end
  if preview:FindFirstChild("EnvelopeRing") then preview.EnvelopeRing:Destroy() end
  for _,p in ipairs(preview:GetDescendants()) do if p:GetAttribute("FineDetail") then p:Destroy() end end
  for _,name in ipairs({"RailingNorth","RailingSouth","RailingEast","RailingWest"}) do
   local p=preview:FindFirstChild(name) if p then p.Transparency=0 p.Color=theme.Dark end
  end
  preview:ScaleTo(preview:GetScale()*0.105)
  local cf=CFrame.new(pedestal+Vector3.new(0,1.05,0))
  preview:PivotTo(cf) preview:SetAttribute("PreviewBase",cf) preview:SetAttribute("IsFleetPreview",true)
  preview.Parent=decor
 end
 task.wait()
end
game:GetService("ChangeHistoryService"):SetWaypoint("Five themed departure docks")
return "Five docks rebuilt"
