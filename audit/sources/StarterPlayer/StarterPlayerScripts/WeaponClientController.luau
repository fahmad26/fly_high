local HUDMotion = require(game:GetService("ReplicatedStorage"):WaitForChild("FlyHigh"):WaitForChild("Modules"):WaitForChild("HUDMotion"))
local Players = game:GetService("Players")
local GuiService = game:GetService("GuiService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local localPlayer = Players.LocalPlayer
local mouse = localPlayer:GetMouse()
local playerGui = localPlayer:WaitForChild("PlayerGui")

local remotes = ReplicatedStorage:WaitForChild("FlyHigh"):WaitForChild("Remotes")
local weaponFireEvent = remotes:WaitForChild("WeaponFireEvent")
local weaponDropEvent = remotes:WaitForChild("WeaponDropEvent")
local tetherEvent = remotes:WaitForChild("TetherEvent")
local tacticalPingEvent = remotes:WaitForChild("TacticalPingEvent")

local currentWeapon = nil
local currentAmmo = 8
local isReloading = false
local canFire = true
local isFiringAuto = false
local fireButtonInput
local lockedTarget
local lastCameraDrag = -math.huge
local beginFire

-- 1. Create Combat & Tether HUD
local screenGui = playerGui:WaitForChild("FlyHighHUD", 10) or Instance.new("ScreenGui")
screenGui.Name = "FlyHighHUD"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

-- Weapon Frame (Bottom Right)
local weaponFrame = Instance.new("Frame")
weaponFrame.Name = "WeaponFrame"
weaponFrame.Size = UDim2.new(0, 240, 0, 75)
weaponFrame.Position = UDim2.new(1, -260, 1, -85)
weaponFrame.BackgroundColor3 = Color3.fromRGB(25, 30, 40)
weaponFrame.BackgroundTransparency = 0.25
weaponFrame.BorderSizePixel = 0
weaponFrame.Visible = false
weaponFrame.Parent = screenGui

local wCorner = Instance.new("UICorner")
wCorner.CornerRadius = UDim.new(0, 10)
wCorner.Parent = weaponFrame

local wNameLabel = Instance.new("TextLabel")
wNameLabel.Name = "WeaponName"
wNameLabel.Size = UDim2.new(1, -20, 0, 24)
wNameLabel.Position = UDim2.new(0, 10, 0, 6)
wNameLabel.BackgroundTransparency = 1
wNameLabel.Text = "🔫 Pistol (Semi-Otomatis)"
wNameLabel.TextColor3 = Color3.fromRGB(255, 230, 100)
wNameLabel.Font = Enum.Font.FredokaOne
wNameLabel.TextSize = 16
wNameLabel.TextXAlignment = Enum.TextXAlignment.Left
wNameLabel.Parent = weaponFrame

local ammoLabel = Instance.new("TextLabel")
ammoLabel.Name = "AmmoLabel"
ammoLabel.Size = UDim2.new(1, -20, 0, 24)
ammoLabel.Position = UDim2.new(0, 10, 0, 30)
ammoLabel.BackgroundTransparency = 1
ammoLabel.Text = "8 / ∞"
ammoLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
ammoLabel.Font = Enum.Font.GothamBold
ammoLabel.TextSize = 18
ammoLabel.TextXAlignment = Enum.TextXAlignment.Left
ammoLabel.Parent = weaponFrame

local dropTip = Instance.new("TextLabel")
dropTip.Name = "DropTip"
dropTip.Size = UDim2.new(1, -20, 0, 16)
dropTip.Position = UDim2.new(0, 10, 0, 54)
dropTip.BackgroundTransparency = 1
dropTip.Text = "[G] Drop ke Rak  |  [R] Reload"
dropTip.TextColor3 = Color3.fromRGB(180, 200, 220)
dropTip.Font = Enum.Font.Gotham
dropTip.TextSize = 12
dropTip.TextXAlignment = Enum.TextXAlignment.Left
dropTip.Parent = weaponFrame

-- Mobile Shoot Button
local mobileShootBtn = Instance.new("TextButton")
mobileShootBtn.Name = "MobileShootButton"
mobileShootBtn.Size = UDim2.new(0, 80, 0, 80)
mobileShootBtn.Position = UDim2.new(1, -100, 1, -175)
mobileShootBtn.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
mobileShootBtn.Text = "🎯\nTEMBAK"
mobileShootBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
mobileShootBtn.Font = Enum.Font.FredokaOne
mobileShootBtn.TextSize = 15
mobileShootBtn.BorderSizePixel = 0
mobileShootBtn.Visible = false
mobileShootBtn.Parent = screenGui

local shootCorner = Instance.new("UICorner")
shootCorner.CornerRadius = UDim.new(1, 0)
shootCorner.Parent = mobileShootBtn

-- Tether Durability Bar (Center Bottom)
local tetherFrame = Instance.new("Frame")
tetherFrame.Name = "TetherFrame"
tetherFrame.Size = UDim2.new(0, 320, 0, 44)
tetherFrame.Position = UDim2.new(0.5, -160, 1, -65)
tetherFrame.BackgroundColor3 = Color3.fromRGB(20, 25, 35)
tetherFrame.BackgroundTransparency = 0.25
tetherFrame.BorderSizePixel = 0
tetherFrame.Visible = false
tetherFrame.Parent = screenGui

local tCorner = Instance.new("UICorner")
tCorner.CornerRadius = UDim.new(0, 8)
tCorner.Parent = tetherFrame

local tetherLabel = Instance.new("TextLabel")
tetherLabel.Name = "TetherLabel"
tetherLabel.Size = UDim2.new(1, -16, 0, 20)
tetherLabel.Position = UDim2.new(0, 8, 0, 4)
tetherLabel.BackgroundTransparency = 1
tetherLabel.Text = "Tali Pengaman: 100% Durabilitas"
tetherLabel.TextColor3 = Color3.fromRGB(255, 220, 100)
tetherLabel.Font = Enum.Font.FredokaOne
tetherLabel.TextSize = 14
tetherLabel.Parent = tetherFrame

local tBarBg = Instance.new("Frame")
tBarBg.Name = "TBarBg"
tBarBg.Size = UDim2.new(1, -16, 0, 10)
tBarBg.Position = UDim2.new(0, 8, 0, 26)
tBarBg.BackgroundColor3 = Color3.fromRGB(45, 50, 60)
tBarBg.BorderSizePixel = 0
tBarBg.Parent = tetherFrame

local tBarFill = Instance.new("Frame")
tBarFill.Name = "TBarFill"
tBarFill.Size = UDim2.new(1, 0, 1, 0)
tBarFill.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
tBarFill.BorderSizePixel = 0
tBarFill.Parent = tBarBg

-- Ghost Spotter HUD (Shown when player dies)
local ghostFrame = Instance.new("Frame")
ghostFrame.Name = "GhostSpotterFrame"
ghostFrame.Size = UDim2.new(0, 340, 0, 65)
ghostFrame.Position = UDim2.new(0.5, -170, 0, 80)
ghostFrame.BackgroundColor3 = Color3.fromRGB(30, 20, 40)
ghostFrame.BackgroundTransparency = 0.2
ghostFrame.BorderSizePixel = 0
ghostFrame.Visible = false
ghostFrame.Parent = screenGui

local gCorner = Instance.new("UICorner")
gCorner.CornerRadius = UDim.new(0, 10)
gCorner.Parent = ghostFrame

local ghostSpotBtn = Instance.new("TextButton")
ghostSpotBtn.Name = "SpotHazardButton"
ghostSpotBtn.Size = UDim2.new(1, -20, 0, 44)
ghostSpotBtn.Position = UDim2.new(0, 10, 0, 10)
ghostSpotBtn.BackgroundColor3 = Color3.fromRGB(240, 180, 20)
ghostSpotBtn.Text = "👁️ SPOT BAHAYA UNTUK TIM (KLIK DI SINI)"
ghostSpotBtn.TextColor3 = Color3.fromRGB(20, 20, 20)
ghostSpotBtn.Font = Enum.Font.FredokaOne
ghostSpotBtn.TextSize = 14
ghostSpotBtn.BorderSizePixel = 0
ghostSpotBtn.Parent = ghostFrame

local gBtnCorner = Instance.new("UICorner")
gBtnCorner.CornerRadius = UDim.new(0, 8)
gBtnCorner.Parent = ghostSpotBtn

local Config=require(ReplicatedStorage.FlyHigh.Modules.FlyHighConfig)
local reloadRemote=remotes:WaitForChild("WeaponReloadEvent")
local attrConnections={}
local lastShot=0
local previousCameraMode
local savedZoomMin,savedZoomMax
local cameraToken=0
local setWeaponPresentation
local reticle=Instance.new("TextLabel")reticle.Name="WeaponReticle"reticle.Size=UDim2.fromOffset(28,28)reticle.AnchorPoint=Vector2.new(.5,.5)reticle.Position=UDim2.fromScale(.5,.5)reticle.BackgroundTransparency=1 reticle.Text="+"reticle.TextColor3=Color3.new(1,1,1)reticle.TextStrokeTransparency=.4 reticle.TextSize=26 reticle.Visible=false reticle.Parent=screenGui
local function updateAmmoUI()
 if not currentWeapon then return end
 currentAmmo=currentWeapon:GetAttribute("CurrentMag") or 0
 local magazineCapacity=currentWeapon:GetAttribute("MagSize") or Config.WEAPONS[currentWeapon.Name].MagSize
 isReloading=currentWeapon:GetAttribute("Reloading")==true
 wNameLabel.Text=currentWeapon.Name
 ammoLabel:SetAttribute("MagazineCapacity",magazineCapacity)
 ammoLabel.Text=isReloading and "RELOADING..." or string.format("%d / ∞",currentAmmo)
end
local function setWeapon(tool)
 for _,c in ipairs(attrConnections) do c:Disconnect() end attrConnections={}
 local hadWeapon=currentWeapon~=nil
 currentWeapon=tool isFiringAuto=false
 fireButtonInput=nil lockedTarget=nil
 reticle:SetAttribute("AimLocked",false)
 cameraToken+=1 local token=cameraToken
 reticle.Visible=tool~=nil
 if tool then
  if previousCameraMode==nil then previousCameraMode=localPlayer.CameraMode if savedZoomMin==nil then savedZoomMin=localPlayer.CameraMinZoomDistance savedZoomMax=localPlayer.CameraMaxZoomDistance end end
  localPlayer.CameraMode=Enum.CameraMode.LockFirstPerson
 elseif hadWeapon then
  localPlayer.CameraMode=Enum.CameraMode.Classic
  local maximum=math.max(savedZoomMax or 128,10)
  localPlayer.CameraMaxZoomDistance=maximum localPlayer.CameraMinZoomDistance=10
  local hum=localPlayer.Character and localPlayer.Character:FindFirstChildOfClass("Humanoid")
  local camera=workspace.CurrentCamera
  if camera and hum and hum.Health>0 then camera.CameraType=Enum.CameraType.Custom camera.CameraSubject=hum end
  task.delay(.25,function()if token==cameraToken and not currentWeapon then localPlayer.CameraMinZoomDistance=savedZoomMin or .5 localPlayer.CameraMaxZoomDistance=maximum savedZoomMin=nil savedZoomMax=nil end end)
  previousCameraMode=nil
 end
 setWeaponPresentation(tool)
 weaponFrame.Visible=tool~=nil mobileShootBtn.Visible=tool~=nil
 if tool then
  table.insert(attrConnections,tool.Activated:Connect(function() if beginFire then beginFire() end end))
  table.insert(attrConnections,tool.Deactivated:Connect(function() isFiringAuto=false end))
  for _,key in ipairs({"CurrentMag","MagSize","Reloading"}) do table.insert(attrConnections,tool:GetAttributeChangedSignal(key):Connect(updateAmmoUI)) end
  updateAmmoUI()
 else
  reticle.Text="+" reticle.TextColor3=Color3.new(1,1,1) reticle.TextSize=26
 end
end
local function usesTouchAim()
 local preferred=UserInputService.PreferredInput
 return preferred==Enum.PreferredInput.Touch
  or (UserInputService.TouchEnabled and preferred~=Enum.PreferredInput.Gamepad
   and (fireButtonInput~=nil or not UserInputService.KeyboardEnabled))
end
local function findAutoAimTarget(camera,touchAim,weapon)
 if not camera then return nil,nil end
 local folder=Workspace:FindFirstChild("FlyHighObstacles")
 if not folder then return nil,nil end
 local camPos=camera.CFrame.Position
 local lookVec=camera.CFrame.LookVector
 local vp=camera.ViewportSize
 local center=vp/2
 local minDim=math.min(vp.X,vp.Y)
 local minDot=math.cos(math.rad(touchAim and 40 or 18))
 local desktopRadius=math.max(120,minDim*0.22)
 local screenRadius=touchAim and Vector2.new(vp.X*0.46,vp.Y*0.45) or Vector2.new(desktopRadius,desktopRadius)
 if screenRadius.X<1 or screenRadius.Y<1 then return nil,nil end
 local balloonRef=localPlayer:FindFirstChild("FlightBalloon")
 local balloon=balloonRef and balloonRef.Value
 local envelope=balloon and balloon:FindFirstChild("Envelope")
 local envelopeParams
 if envelope then
  envelopeParams=RaycastParams.new()
  envelopeParams.FilterType=Enum.RaycastFilterType.Include
  envelopeParams.FilterDescendantsInstances={envelope}
  -- Looking straight at the envelope preserves a deliberate self-shot.
  if touchAim and Workspace:Raycast(camPos,lookVec*500,envelopeParams) then return nil,nil end
 end
 local handle=touchAim and weapon and weapon:FindFirstChild("Handle")
 local muzzle=handle and handle:FindFirstChild("MuzzleAttachment")
 local muzzlePos=muzzle and muzzle.WorldPosition or handle and handle.Position
 local bestPos=nil
 local bestModel=nil
 local bestScore=math.huge
 for _,model in ipairs(folder:GetChildren()) do
  if model:IsA("Model") and model:GetAttribute("Shootable")==true then
   local part=model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
   if part then
    local targetPos=part.Position
    local toTarget=targetPos-camPos
    local dist=toTarget.Magnitude
    if dist>2 and dist<500 then
     local dir=toTarget/dist
     local dot=lookVec:Dot(dir)
     if dot>=minDot then
      local screenPt,inFrustum=camera:WorldToViewportPoint(targetPos)
      if inFrustum and screenPt.Z>0 then
       local screenDist=((Vector2.new(screenPt.X,screenPt.Y)-center)/screenRadius).Magnitude
       if screenDist<=1 then
        local score=screenDist+(1-dot)*0.8+dist*0.00015
        if touchAim and model==lockedTarget then score*=0.78 end
        if score<bestScore and (not envelopeParams
         or (not Workspace:Raycast(camPos,toTarget,envelopeParams)
          and (not muzzlePos or not Workspace:Raycast(muzzlePos,targetPos-muzzlePos,envelopeParams)))) then
         bestScore=score
         bestPos=targetPos
         bestModel=model
        end
       end
      end
     end
    end
   end
  end
 end
 return bestPos,bestModel
end
local function targetPosition(touchAim,weapon)
 local camera=Workspace.CurrentCamera
 if not camera then return nil,nil end
 if touchAim==nil then touchAim=usesTouchAim() end
 local autoPos,autoModel=findAutoAimTarget(camera,touchAim,weapon)
 if autoPos then return autoPos,autoModel end
 local ray=camera:ViewportPointToRay(camera.ViewportSize.X/2,camera.ViewportSize.Y/2)
 return ray.Origin+ray.Direction*500,nil
end
local function fireShot()
 local tool=currentWeapon
 if not tool or isReloading then return end
 local rate=tool:GetAttribute("FireRate") or 0.25
 if os.clock()-lastShot<rate then return end
 lastShot=os.clock()
 if currentAmmo<=0 then reloadRemote:FireServer() return end
 local handle=tool:FindFirstChild("Handle")
 if not handle then return end
 local targetPos,targetModel=targetPosition(usesTouchAim(),tool)
 if not targetPos then return end
 weaponFireEvent:FireServer(handle.Position,targetPos,targetModel)
 local camera=Workspace.CurrentCamera
 camera.CFrame*=CFrame.Angles(math.rad(0.2),0,0)
end
beginFire = function()
 if not currentWeapon or isFiringAuto then return end
 fireShot()
 if currentWeapon and currentWeapon:GetAttribute("IsAutomatic") then isFiringAuto=true end
end
mobileShootBtn.InputBegan:Connect(function(input)
 if fireButtonInput or (input.UserInputType~=Enum.UserInputType.MouseButton1 and input.UserInputType~=Enum.UserInputType.Touch) then return end
 fireButtonInput=input
 beginFire()
end)
UserInputService.TouchMoved:Connect(function(input,processed)
 if not processed and input~=fireButtonInput and input.Delta.Magnitude>0 then lastCameraDrag=os.clock() end
end)
UserInputService.InputEnded:Connect(function(input)
 if fireButtonInput then
  local sameMouse=input.UserInputType==Enum.UserInputType.MouseButton1 and fireButtonInput.UserInputType==input.UserInputType
  if input~=fireButtonInput and not sameMouse then return end
  fireButtonInput=nil
  isFiringAuto=false
 elseif input.UserInputType==Enum.UserInputType.MouseButton1 or input.KeyCode==Enum.KeyCode.ButtonR2 then
  isFiringAuto=false
 end
end)
UserInputService.WindowFocusReleased:Connect(function() fireButtonInput=nil isFiringAuto=false end)
local wheel=Instance.new("Frame")
wheel.Name="TacticalPingWheel" wheel.Size=UDim2.fromOffset(440,310) wheel.Position=UDim2.new(0.5,-220,0.5,-155)
wheel.BackgroundColor3=Color3.fromRGB(7,22,55)
wheel.BackgroundTransparency=1 wheel.Visible=false wheel.Active=true wheel.Parent=screenGui
local pingTitle=Instance.new("TextLabel")
pingTitle.Name="PingTitle"
pingTitle.BackgroundTransparency=1
pingTitle.Font=Enum.Font.FredokaOne
pingTitle.Text="PING KRU"
pingTitle.TextSize=20
pingTitle.TextColor3=Color3.fromRGB(255,224,142)
pingTitle.TextXAlignment=Enum.TextXAlignment.Left
pingTitle.Parent=wheel
local function button(name,text,position,callback)
 if UserInputService.TouchEnabled then text=text:gsub("%s*%[[^%]]+%]","")end
 local b=Instance.new("TextButton") b.Name=name b.Text=text b.Size=UDim2.fromOffset(150,42)
 b.Position=position b.BackgroundColor3=Color3.fromRGB(35,65,85) b.TextColor3=Color3.new(1,1,1)
 b.TextWrapped=true b.TextSize=13 b.Font=Enum.Font.GothamBold b.Parent=screenGui b.Activated:Connect(callback)
 b.BorderSizePixel=0
 local corner=Instance.new("UICorner")corner.CornerRadius=UDim.new(0,10)corner.Parent=b
 return b
end
local pingButton=button("PingButton","💬 PING [V]",UDim2.new(0,20,1,-155),function() HUDMotion.Toggle(wheel) end)
local reloadButton=button("ReloadButton","RELOAD [R / X]",UDim2.new(1,-260,1,-225),function() if currentWeapon then reloadRemote:FireServer() end end)
local dropButton=button("DropButton","DROP [G / B]",UDim2.new(1,-260,1,-270),function() weaponDropEvent:FireServer() end)
local pingClose=button("PingCloseButton","Tutup",UDim2.fromOffset(0,0),function() HUDMotion.SetVisible(wheel,false) end)
pingClose.Parent=wheel
for i,message in ipairs(Config.TACTICAL_MESSAGES) do
 local b=button("Ping"..i,message,UDim2.fromOffset(0,0),function()
  local root=localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
  if root then tacticalPingEvent:FireServer("QuickPing",root.Position,message) end
  HUDMotion.SetVisible(wheel,false)
 end)
 b.Parent=wheel
end
UserInputService.InputBegan:Connect(function(input,gpe)
 if gpe then return end
 if input.UserInputType==Enum.UserInputType.MouseButton1 or input.KeyCode==Enum.KeyCode.ButtonR2 then beginFire()
 elseif input.KeyCode==Enum.KeyCode.R or input.KeyCode==Enum.KeyCode.ButtonX then
  if currentWeapon then reloadRemote:FireServer() end
 elseif input.KeyCode==Enum.KeyCode.G or input.KeyCode==Enum.KeyCode.ButtonB then weaponDropEvent:FireServer()
 elseif input.KeyCode==Enum.KeyCode.V or input.KeyCode==Enum.KeyCode.DPadUp then HUDMotion.Toggle(wheel) end
end)
local function onCharacter(char)
 setWeapon(nil)
 local hum=char:WaitForChild("Humanoid")hum.Died:Connect(function()setWeapon(nil)end)
 char.ChildAdded:Connect(function(child)
  if child:IsA("Tool") and Config.WEAPONS[child.Name] then setWeapon(child) end
 end)
 char.ChildRemoved:Connect(function(child) if child==currentWeapon then setWeapon(nil) end end)
 for _,child in ipairs(char:GetChildren()) do if child:IsA("Tool") and Config.WEAPONS[child.Name] then setWeapon(child) end end
end
setWeaponPresentation=require(ReplicatedStorage.FlyHigh.Modules.WeaponPresentation).Start(localPlayer,weaponFireEvent,script,screenGui)
if localPlayer.Character then onCharacter(localPlayer.Character) end
localPlayer.CharacterAdded:Connect(onCharacter)
tetherEvent.OnClientEvent:Connect(function(data)
 tetherFrame.Visible=data.isTethered==true
 local dur=math.clamp(data.durability or 0,0,100)
 tetherLabel.Text=string.format("Tali Pengaman: %d%%",math.floor(dur))
 if data.stage=="Hanging"then tetherLabel.Text=string.format("TALI %d%% | MINTA REKAN MENARIK",math.floor(dur))elseif data.stage=="Rescuing"then tetherLabel.Text="SEDANG DITARIK KE KERANJANG"end
 local low=Config.AUDIO_WARNINGS.ROPE_LOW_PERCENT
 local critical=Config.AUDIO_WARNINGS.ROPE_CRITICAL_PERCENT
 if data.insideBasket==false and data.stage~="Descending"and data.stage~="Hanging"and data.stage~="Rescuing"then
  if dur<=critical then tetherLabel.Text=string.format("TALI %d%% | SEGERA TURUN [Q]",math.floor(dur))
  elseif dur<=low then tetherLabel.Text=string.format("TALI MENIPIS: %d%%",math.floor(dur))end
 end
 tBarFill.Size=UDim2.fromScale(dur/100,1)
 tBarFill.BackgroundColor3=dur<=critical and Color3.fromRGB(255,40,40)or(dur<=low and Color3.fromRGB(255,160,55)or Color3.fromRGB(255,215,0))
end)
ghostSpotBtn.Activated:Connect(function()
 tacticalPingEvent:FireServer("GhostSpot",targetPosition(),"")
end)
local wasGhost=false
local aimRenderStep="FlyHighWeaponAim"
RunService:BindToRenderStep(aimRenderStep,Enum.RenderPriority.Camera.Value+1,function(dt)
 local camera=Workspace.CurrentCamera
 if currentWeapon and camera then
  local center=camera.ViewportSize/2-GuiService:GetGuiInset()
  reticle.Position=UDim2.fromOffset(center.X,center.Y)
  local touchAim=usesTouchAim()
  local targetPos,targetModel=findAutoAimTarget(camera,touchAim,currentWeapon)
  lockedTarget=targetModel
  local locked=targetModel~=nil
  if reticle:GetAttribute("AimLocked")~=locked then
   reticle:SetAttribute("AimLocked",locked)
   reticle.Text=locked and "[ + ]" or "+"
   reticle.TextSize=locked and 24 or 26
   reticle.TextColor3=locked and Color3.fromRGB(255,90,83) or Color3.new(1,1,1)
  end
  if touchAim and targetPos and camera.CameraType==Enum.CameraType.Custom and os.clock()-lastCameraDrag>0.14 then
   local goal=CFrame.lookAt(camera.CFrame.Position,targetPos)
   camera.CFrame=camera.CFrame:Lerp(goal,1-math.exp(-7*math.min(dt,0.05)))
  end
 end
 if isFiringAuto then fireShot() end
 reloadButton.Visible=currentWeapon~=nil dropButton.Visible=currentWeapon~=nil
 local ghost=localPlayer:GetAttribute("FlightGhost")==true and localPlayer:GetAttribute("InFlight")==true
 ghostFrame.Visible=ghost
 if ghost then
  local ref=localPlayer:FindFirstChild("FlightBalloon")
  if ref and ref.Value and ref.Value.PrimaryPart then Workspace.CurrentCamera.CameraSubject=ref.Value.PrimaryPart end
 elseif wasGhost then
  local hum=localPlayer.Character and localPlayer.Character:FindFirstChildOfClass("Humanoid")
  if hum then Workspace.CurrentCamera.CameraSubject=hum end
 end
 wasGhost=ghost
end)
script.Destroying:Connect(function() RunService:UnbindFromRenderStep(aimRenderStep) end)

tacticalPingEvent.OnClientEvent:Connect(function(pos,message,name)
 local marker=Instance.new("Part") marker.Name="TeamSpotterMarker" marker.Shape=Enum.PartType.Ball
 marker.Size=Vector3.new(3,3,3) marker.Position=pos marker.Material=Enum.Material.Neon marker.Color=Color3.fromRGB(255,230,50)
 marker.Anchored=true marker.CanCollide=false marker.CanTouch=false marker.CanQuery=false marker.Parent=Workspace
 local bill=Instance.new("BillboardGui",marker) bill.Size=UDim2.fromOffset(260,60) bill.AlwaysOnTop=true bill.StudsOffset=Vector3.new(0,4,0)
 local label=Instance.new("TextLabel",bill) label.Size=UDim2.fromScale(1,1) label.BackgroundTransparency=1
 label.Text=name..": "..message label.TextColor3=Color3.new(1,1,0.5) label.TextStrokeTransparency=0.2 label.TextSize=16 label.TextWrapped=true
 game:GetService("Debris"):AddItem(marker,3.5)
end)

-- Accessible rigging controls also work when a 3D prompt is outside the camera.
local tethered=false
local outside=false
local travelling=false
local hanging=false
local attachButton=button("AttachButton","PASANG TALI [E]",UDim2.new(0.5,-75,1,-165),function() tetherEvent:FireServer("Attach") end)
local detachButton=button("DetachButton","LEPAS TALI [T]",UDim2.new(0.5,-75,1,-255),function()tetherEvent:FireServer("Detach")end)
local climbButton=button("ClimbButton","NAIK KE KUBAH [F]",UDim2.new(0.5,-75,1,-210),function() tetherEvent:FireServer("Climb") end)
local descendButton=button("DescendButton","TURUN & LEPAS TALI [Q]",UDim2.new(0.5,-75,1,-210),function() tetherEvent:FireServer("Descend") end)
local pullButton=button("PullCrewButton","TARIK REKAN [B / R1]",UDim2.new(0.5,-75,1,-300),function()tetherEvent:FireServer("PullCrew")end)
tetherEvent.OnClientEvent:Connect(function(data)
 tethered=data.isTethered==true outside=data.insideBasket==false travelling=data.stage=="Climbing"or data.stage=="Descending"or data.stage=="Rescuing"
 hanging=data.stage=="Hanging"
end)
UserInputService.InputBegan:Connect(function(input, processed)
 if processed or UserInputService:GetFocusedTextBox() then return end
 local key = input.KeyCode
 if attachButton.Visible and key == Enum.KeyCode.E then
  tetherEvent:FireServer("Attach")
 elseif pullButton.Visible and (key == Enum.KeyCode.B or key == Enum.KeyCode.ButtonR1) then
  tetherEvent:FireServer("PullCrew")
 elseif detachButton.Visible and (key == Enum.KeyCode.T or key == Enum.KeyCode.ButtonL2) then
  tetherEvent:FireServer("Detach")
 elseif descendButton.Visible and key == Enum.KeyCode.Q then
  tetherEvent:FireServer("Descend")
 elseif climbButton.Visible and key == Enum.KeyCode.F then
  tetherEvent:FireServer("Climb")
 end
end)
RunService.RenderStepped:Connect(function()
 local ref=localPlayer:FindFirstChild("FlightBalloon")
 local b=ref and ref.Value
 local root=localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
 -- The flight reference can arrive before the model's descendants on a busy client.
 local station=b and b.Parent and b:FindFirstChild("TetherStation")
 local nearStation=station~=nil and root~=nil and localPlayer:GetAttribute("InFlight")==true and (root.Position-station.Position).Magnitude<=10 and not outside
 local hum=localPlayer.Character and localPlayer.Character:FindFirstChildOfClass("Humanoid")
 local free=not currentWeapon and hum and localPlayer.Character:GetAttribute("FatalRopeFall")~=true and not hum.Sit and localPlayer:GetAttribute("CrewRole")==nil and localPlayer:GetAttribute("BoardingFlight")~=true
 attachButton.Visible=free and nearStation and not tethered and localPlayer:GetAttribute("RopeRepairing")~=true and (station:GetAttribute("AvailableRopes")or 0)>0
 local inFlight = localPlayer:GetAttribute("InFlight") == true
 detachButton.Visible = inFlight and tethered and not outside and not travelling
 climbButton.Visible=tethered and not outside and nearStation and not travelling
 descendButton.Visible = inFlight and tethered and outside and not travelling and not hanging
 local floor=b and b:FindFirstChild("BasketFloor")
 local q=floor and root and floor.CFrame:PointToObjectSpace(root.Position)
 pullButton.Visible=free and q~=nil and math.abs(q.X)<=floor.Size.X/2 and math.abs(q.Z)<=floor.Size.Z/2 and q.Y>=0 and q.Y<=8 and station~=nil and (station:GetAttribute("RescueWaiting")or 0)>0
end)
