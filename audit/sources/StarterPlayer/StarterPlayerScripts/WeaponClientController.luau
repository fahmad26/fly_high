local Players = game:GetService("Players")
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
local maxAmmo = 8
local isReloading = false
local canFire = true
local isFiringAuto = false

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
ammoLabel.Text = "8 / 8  |  ∞ Cadangan"
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
local reticle=Instance.new("TextLabel")reticle.Name="WeaponReticle"reticle.Size=UDim2.fromOffset(28,28)reticle.AnchorPoint=Vector2.new(.5,.5)reticle.Position=UDim2.fromScale(.5,.5)reticle.BackgroundTransparency=1 reticle.Text="+"reticle.TextColor3=Color3.new(1,1,1)reticle.TextStrokeTransparency=.4 reticle.TextSize=26 reticle.Visible=false reticle.Parent=screenGui
local function updateAmmoUI()
 if not currentWeapon then return end
 currentAmmo=currentWeapon:GetAttribute("CurrentMag") or 0
 maxAmmo=currentWeapon:GetAttribute("MagSize") or 8
 isReloading=currentWeapon:GetAttribute("Reloading")==true
 wNameLabel.Text=currentWeapon.Name
 ammoLabel.Text=isReloading and "RELOADING..." or string.format("%d / %d | ∞ Cadangan",currentAmmo,maxAmmo)
end
local function setWeapon(tool)
 for _,c in ipairs(attrConnections) do c:Disconnect() end attrConnections={}
 local hadWeapon=currentWeapon~=nil
 currentWeapon=tool isFiringAuto=false
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
 weaponFrame.Visible=tool~=nil mobileShootBtn.Visible=tool~=nil
 if tool then
  for _,key in ipairs({"CurrentMag","Reloading"}) do table.insert(attrConnections,tool:GetAttributeChangedSignal(key):Connect(updateAmmoUI)) end
  updateAmmoUI()
 end
end
local function targetPosition()
 local camera=Workspace.CurrentCamera
 local pos
 do
  local ray=camera:ViewportPointToRay(camera.ViewportSize.X/2,camera.ViewportSize.Y/2)
  pos=ray.Origin+ray.Direction*500
  local folder=Workspace:FindFirstChild("FlyHighObstacles")
  local best=100
  for _,model in ipairs(folder and folder:GetChildren() or {}) do
   local part=model.PrimaryPart
   if part and model:GetAttribute("Shootable") then
    local screen,visible=camera:WorldToViewportPoint(part.Position)
    local distance=(Vector2.new(screen.X,screen.Y)-camera.ViewportSize/2).Magnitude
    if visible and distance<best and (part.Position-camera.CFrame.Position).Magnitude<500 then pos=part.Position best=distance end
   end
  end
 end
 return pos
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
 weaponFireEvent:FireServer(handle.Position,targetPosition())
 local camera=Workspace.CurrentCamera
 camera.CFrame*=CFrame.Angles(math.rad(0.2),0,0)
end
local function beginFire()
 if not currentWeapon or isFiringAuto then return end
 fireShot()
 if currentWeapon and currentWeapon:GetAttribute("IsAutomatic") then isFiringAuto=true end
end
mobileShootBtn.InputBegan:Connect(function(input)
 if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then beginFire() end
end)
UserInputService.InputEnded:Connect(function(input)
 if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch or input.KeyCode==Enum.KeyCode.ButtonR2 then isFiringAuto=false end
end)
UserInputService.WindowFocusReleased:Connect(function() isFiringAuto=false end)
local wheel=Instance.new("Frame")
wheel.Name="TacticalPingWheel" wheel.Size=UDim2.fromOffset(440,310) wheel.Position=UDim2.new(0.5,-220,0.5,-155)
wheel.BackgroundTransparency=1 wheel.Visible=false wheel.Parent=screenGui
local function button(name,text,position,callback)
 local b=Instance.new("TextButton") b.Name=name b.Text=text b.Size=UDim2.fromOffset(150,42)
 b.Position=position b.BackgroundColor3=Color3.fromRGB(35,65,85) b.TextColor3=Color3.new(1,1,1)
 b.TextWrapped=true b.TextSize=13 b.Font=Enum.Font.GothamBold b.Parent=screenGui b.Activated:Connect(callback)
 b.BorderSizePixel=0
 local corner=Instance.new("UICorner")corner.CornerRadius=UDim.new(0,10)corner.Parent=b
 return b
end
local pingButton=button("PingButton","💬 PING [V]",UDim2.new(0,20,1,-155),function() wheel.Visible=not wheel.Visible end)
local reloadButton=button("ReloadButton","RELOAD [R / X]",UDim2.new(1,-260,1,-225),function() if currentWeapon then reloadRemote:FireServer() end end)
local dropButton=button("DropButton","DROP [G / B]",UDim2.new(1,-260,1,-270),function() weaponDropEvent:FireServer() end)
for i,message in ipairs(Config.TACTICAL_MESSAGES) do
 local angle=math.rad(-90+(i-1)*72)
 local b=button("Ping"..i,message,UDim2.fromOffset(145+math.cos(angle)*140,130+math.sin(angle)*110),function()
  tacticalPingEvent:FireServer("QuickPing",targetPosition(),message) wheel.Visible=false
 end)
 b.Parent=wheel
end
UserInputService.InputBegan:Connect(function(input,gpe)
 if gpe then return end
 if input.UserInputType==Enum.UserInputType.MouseButton1 or input.KeyCode==Enum.KeyCode.ButtonR2 then beginFire()
 elseif input.KeyCode==Enum.KeyCode.R or input.KeyCode==Enum.KeyCode.ButtonX then
  if currentWeapon then reloadRemote:FireServer() end
 elseif input.KeyCode==Enum.KeyCode.G or input.KeyCode==Enum.KeyCode.ButtonB then weaponDropEvent:FireServer()
 elseif input.KeyCode==Enum.KeyCode.V or input.KeyCode==Enum.KeyCode.DPadUp then wheel.Visible=not wheel.Visible end
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
RunService.RenderStepped:Connect(function()
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
require(ReplicatedStorage.FlyHigh.Modules.WeaponPresentation).Start(localPlayer,weaponFireEvent,script)

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
local holdingRepair
local holdingRopeRepair
local repairRemote=remotes:WaitForChild("RepairHoleEvent")
local function nearestHole()
 local ref=localPlayer:FindFirstChild("FlightBalloon")
 local b=ref and ref.Value
 local root=localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
 if not b or not b.Parent or not root or not tethered or not outside then return nil end
 local slots=b:FindFirstChild("HoleSlots")
 if not slots then return nil end
 local best local distance=10
 for _,hole in ipairs(slots:GetChildren()) do
  local prompt=hole:FindFirstChild("PatchPrompt")
  if hole:IsA("BasePart") and prompt and prompt.Enabled then
   local d=(hole.Position-root.Position).Magnitude
   if d<distance then best=hole distance=d end
  end
 end
 return best
end
local function beginRepair(input)
 if holdingRepair then return end
 local hole=nearestHole() if not hole then return end
 local token={input=input} holdingRepair=token
 repairRemote:FireServer("Begin",tonumber(hole.Name:match("%d+")))
 task.delay(hole.PatchPrompt.HoldDuration+0.15,function()
  if holdingRepair==token then repairRemote:FireServer("Finish") holdingRepair=nil end
 end)
end
local function matches(input,token)
 return not input or not token.input or input==token.input or (input.KeyCode~=Enum.KeyCode.Unknown and input.KeyCode==token.input.KeyCode)
end
local function cancelRepair(input)
 if holdingRepair and matches(input,holdingRepair) then holdingRepair=nil repairRemote:FireServer("Cancel") end
end
local attachButton=button("AttachButton","PASANG TALI [E]",UDim2.new(0.5,-75,1,-165),function() tetherEvent:FireServer("Attach") end)
local detachButton=button("DetachButton","LEPAS TALI [T]",UDim2.new(0.5,-75,1,-255),function()tetherEvent:FireServer("Detach")end)
local climbButton=button("ClimbButton","NAIK KE KUBAH [F]",UDim2.new(0.5,-75,1,-210),function() tetherEvent:FireServer("Climb") end)
local descendButton=button("DescendButton","TURUN & LEPAS TALI [Q]",UDim2.new(0.5,-75,1,-210),function() tetherEvent:FireServer("Descend") end)
local repairButton=button("RepairButton","TAHAN TAMBAL [E]",UDim2.new(0.5,-75,1,-165),function() end)
local pullButton=button("PullCrewButton","TARIK REKAN [B / R1]",UDim2.new(0.5,-75,1,-300),function()tetherEvent:FireServer("PullCrew")end)
local repairRopeButton=button("RepairRopeButton","TAHAN PERBAIKI TALI [C]",UDim2.new(0.5,-75,1,-165),function()end)
local function beginRopeRepair(input)
 if holdingRopeRepair or tethered then return end
 local ref=localPlayer:FindFirstChild("FlightBalloon")local b=ref and ref.Value
 local station=b and b:FindFirstChild("TetherStation")local prompt=station and station:FindFirstChild("RepairRopePrompt")
 if not prompt then return end
 local token={input=input,start=os.clock(),duration=prompt.HoldDuration}holdingRopeRepair=token
 tetherEvent:FireServer("BeginRopeRepair")
 task.delay(prompt.HoldDuration+.15,function()
  if holdingRopeRepair==token then tetherEvent:FireServer("FinishRopeRepair")holdingRopeRepair=nil end
 end)
end
local function cancelRopeRepair(input)
 if holdingRopeRepair and matches(input,holdingRopeRepair)then
  local complete=os.clock()-holdingRopeRepair.start>=holdingRopeRepair.duration
  holdingRopeRepair=nil tetherEvent:FireServer(complete and "FinishRopeRepair"or "CancelRopeRepair")
 end
end
repairRopeButton.InputBegan:Connect(function(input)
 if input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1 then beginRopeRepair(input)end
end)
repairButton.InputBegan:Connect(function(input)
 if input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1 then beginRepair(input) end
end)
tetherEvent.OnClientEvent:Connect(function(data)
 tethered=data.isTethered==true outside=data.insideBasket==false travelling=data.stage=="Climbing"or data.stage=="Descending"or data.stage=="Rescuing"
 hanging=data.stage=="Hanging"
 if not tethered then holdingRepair=nil end
 if data.isRepairingRope==false then holdingRopeRepair=nil end
end)
UserInputService.InputBegan:Connect(function(input,gpe)
 if UserInputService:GetFocusedTextBox() then return end
 if input.KeyCode==Enum.KeyCode.B or input.KeyCode==Enum.KeyCode.ButtonR1 then tetherEvent:FireServer("PullCrew")end
 if input.KeyCode==Enum.KeyCode.T or input.KeyCode==Enum.KeyCode.ButtonL2 then tetherEvent:FireServer("Detach")
 elseif input.KeyCode==Enum.KeyCode.Q then tetherEvent:FireServer("Descend")
 elseif input.KeyCode==Enum.KeyCode.F then tetherEvent:FireServer("Climb")
 elseif input.KeyCode==Enum.KeyCode.C or input.KeyCode==Enum.KeyCode.ButtonR3 then beginRopeRepair(input)
 elseif input.KeyCode==Enum.KeyCode.E then
  if tethered and outside then beginRepair(input) end -- Native E prompt owns attach/pickup/helm; do not send a second action.
 end
end)
UserInputService.InputEnded:Connect(function(input)
 cancelRepair(input)cancelRopeRepair(input)
end)
UserInputService.WindowFocusReleased:Connect(function()cancelRepair()cancelRopeRepair()end)
RunService.RenderStepped:Connect(function()
 local ref=localPlayer:FindFirstChild("FlightBalloon")
 local b=ref and ref.Value
 local root=localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
 -- The flight reference can arrive before the model's descendants on a busy client.
 local station=b and b.Parent and b:FindFirstChild("TetherStation")
 local nearStation=station~=nil and root~=nil and localPlayer:GetAttribute("InFlight")==true and (root.Position-station.Position).Magnitude<=10 and not outside
 local hum=localPlayer.Character and localPlayer.Character:FindFirstChildOfClass("Humanoid")
 local free=not currentWeapon and hum and not hum.Sit and localPlayer:GetAttribute("CrewRole")==nil and localPlayer:GetAttribute("BoardingFlight")~=true
 attachButton.Visible=free and nearStation and not tethered and localPlayer:GetAttribute("RopeRepairing")~=true and (station:GetAttribute("AvailableRopes")or 0)>0
 repairRopeButton.Visible=(free or localPlayer:GetAttribute("RopeRepairing")==true) and nearStation and not tethered and ((station:GetAttribute("RepairableRopes")or 0)>0 or localPlayer:GetAttribute("RopeRepairing")==true)
 detachButton.Visible=tethered and not travelling and localPlayer:GetAttribute("InFlight")==true
 climbButton.Visible=tethered and not outside and nearStation and not travelling
 descendButton.Visible=tethered and outside and not travelling and not hanging
 repairButton.Visible=not travelling and not hanging and nearestHole()~=nil
 local floor=b and b:FindFirstChild("BasketFloor")
 local q=floor and root and floor.CFrame:PointToObjectSpace(root.Position)
 pullButton.Visible=free and q~=nil and math.abs(q.X)<=floor.Size.X/2 and math.abs(q.Z)<=floor.Size.Z/2 and q.Y>=0 and q.Y<=8 and station~=nil and (station:GetAttribute("RescueWaiting")or 0)>0
end)
