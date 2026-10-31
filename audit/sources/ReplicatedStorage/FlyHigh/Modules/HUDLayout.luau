-- One layout owner: scale positions and dimensions together, never touch hitboxes.
local Layout = {}
local actions = {"AttachButton", "ClimbButton", "DescendButton", "RepairButton", "DetachButton", "RepairRopeButton", "ReloadButton", "DropButton", "PingButton", "WarningAudioToggleButton"}
local riggingActions = {"AttachButton", "RepairRopeButton", "PullCrewButton", "DetachButton", "ClimbButton", "RepairButton", "DescendButton"}

local function box(object, x, y, w, h)
 object.AnchorPoint = Vector2.zero
 object.Position = UDim2.fromOffset(math.round(x), math.round(y))
 object.Size = UDim2.fromOffset(math.round(w), math.round(h))
end

function Layout.Start(gui, player)
 local Run = game:GetService("RunService")
 local Input = game:GetService("UserInputService")
 gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
 local originals = {}
 local tray = Instance.new("ScrollingFrame")
 tray.Name = "FlightActionTray"
 tray.BackgroundColor3 = Color3.fromRGB(22, 36, 47)
 tray.BackgroundTransparency = .06
 tray.BorderSizePixel = 0
 tray.ScrollBarThickness = 5
 tray.ScrollingDirection = Enum.ScrollingDirection.Y
 tray.Visible = false
 tray.ZIndex = 21
 tray.Parent = gui
 local toggle = Instance.new("TextButton")
 toggle.Name = "FlightActionsButton"
 toggle.Text = "AKSI ▴"
 toggle.TextSize = 14
 toggle.Font = Enum.Font.GothamBold
 toggle.TextColor3 = Color3.new(1, 1, 1)
 toggle.BackgroundColor3 = Color3.fromRGB(35, 65, 85)
 toggle.ZIndex = 23
 toggle.Visible = false
 toggle.Parent = gui
 Instance.new("UICorner", toggle).CornerRadius = UDim.new(0, 10)
 local scrim = Instance.new("TextButton")
 scrim.Name = "HUDModalScrim"
 scrim.Text = ""
 scrim.BackgroundColor3 = Color3.new(0, 0, 0)
 scrim.BackgroundTransparency = .35
 scrim.Size = UDim2.fromScale(1, 1)
 scrim.Visible = false
 scrim.ZIndex = 20
 scrim.Parent = gui
 local opened = false
 toggle.Activated:Connect(function() opened = not opened end)
 scrim.Activated:Connect(function()
  opened = false
  for _, name in {"ShopModal", "TacticalPingWheel"} do
   local f = gui:FindFirstChild(name)
   if f then f.Visible = false end
  end
 end)
 local function get(name) return gui:FindFirstChild(name) or tray:FindFirstChild(name) end
 local function remember(f)
  local owner=f:FindFirstChild("ControllerOwner")
  if owner and owner:IsA("ObjectValue")and(not owner.Value or not owner.Value:IsDescendantOf(player.PlayerScripts))then
   originals[f]=nil f:Destroy()return
  end
  if not originals[f] then
   originals[f] = {position=f.Position, size=f.Size, anchor=f.AnchorPoint}
   local s = f:FindFirstChild("ResponsiveScale")
   if s then s:Destroy() end
  end
 end
 local elapsed = 1
 local connection
 connection = Run.RenderStepped:Connect(function(dt)
  if not gui.Parent then connection:Disconnect() return end
  elapsed += dt
  if elapsed < .1 then return end
  elapsed = 0
  local w, h = gui.AbsoluteSize.X, gui.AbsoluteSize.Y
  if w < 1 or h < 1 then return end
  local compact = h < 600 or w < 760
  gui:SetAttribute("CompactLayout", compact)
  for _, f in gui:GetChildren() do
   if f:IsA("GuiObject") and f ~= tray and f ~= toggle and f ~= scrim then remember(f) end
  end
  for _, f in tray:GetChildren() do if f:IsA("GuiObject") then remember(f) end end
  -- Full-size desktop/tablet HUD retains the original arrangement with correct anchors.
  local scale = math.clamp(math.min(w / 1100, h / 720), .7, 1)
  for f, original in originals do
   if f.Parent then
    f.AnchorPoint = original.anchor
    f.Position = UDim2.new(original.position.X.Scale, original.position.X.Offset * scale, original.position.Y.Scale, original.position.Y.Offset * scale)
    f.Size = UDim2.new(original.size.X.Scale, original.size.X.Offset * scale, original.size.Y.Scale, original.size.Y.Offset * scale)
    local ui = f:FindFirstChild("ResponsiveScale") or Instance.new("UIScale", f)
    ui.Name = "ResponsiveScale"
    -- Children use original pixel dimensions; parent dimensions stay in design units.
    f.Size = original.size
    ui.Scale = scale
    if Input.TouchEnabled and f:IsA("GuiButton") then
     f.Size = UDim2.fromOffset(math.max(original.size.X.Offset, 44 / scale), math.max(original.size.Y.Offset, 44 / scale))
    end
   else
    originals[f]=nil
   end
  end
  local function place(name, x, y, bw, bh)
   local f = get(name)
   if f then
    local ui = f:FindFirstChild("ResponsiveScale")
    if ui then ui.Scale = 1 end
    box(f, x, y, bw, bh)
   end
   return f
  end
  local rescue=get("PullCrewButton")
  if rescue then rescue.Parent=gui rescue.ZIndex=2 end
  local jumpPanel = get("JumpPanel")
  if jumpPanel then
   jumpPanel.JumpHint.Visible = true
   box(jumpPanel.JumpButton, 171, 8, 82, 56)
  end
  local stormPanel = get("StormChallengePanel")
  if stormPanel then
   stormPanel.Title.TextSize = 17
   stormPanel.Detail.TextSize = 13
   stormPanel.Detail.Size = UDim2.new(1, -20, 0, 44)
  end
  local statusPanel = get("StatusFrame")
  if statusPanel then
   statusPanel.HoleTitle.TextSize = 15 statusPanel.HoleIcons.TextSize = 16
   statusPanel.HolePenalty.TextSize = 13 statusPanel.InvulnLabel.TextSize = 14
   statusPanel.HolePenalty.Position = UDim2.fromOffset(10, 58)
   statusPanel.HolePenalty.Size = UDim2.new(1, -16, 0, 20)
   statusPanel.InvulnLabel.Position = UDim2.fromOffset(10, 80)
  end
  local modal = get("ShopModal")
  local wheel = get("TacticalPingWheel")
  local modalVisible = (modal and modal.Visible) or (wheel and wheel.Visible)
  if modalVisible then opened = false end
  toggle.Visible = compact and not modalVisible and player:GetAttribute("InFlight") == true
  if not toggle.Visible then opened = false end
  tray.Visible = compact and opened
  toggle.Text = opened and "TUTUP AKSI ▾" or "AKSI ▴"
  scrim.Visible = modalVisible or tray.Visible
  local row = 0
  for _, name in actions do
   local f = get(name)
   if f then
    f.Parent = compact and tray or gui
    f.ZIndex = compact and 22 or 1
    if compact and f.Visible then
     place(name, 8, 8 + row * 50, 224, 44)
     f.TextSize = 14
     row += 1
    end
   end
  end
  if not compact then
   -- Stack only visible rigging actions. Attach/rope repair and
   -- patch/descend can be available together and must never share a slot.
   local visible={}
   for _,name in riggingActions do local f=get(name)if f and f.Visible then table.insert(visible,name)end end
   for i,name in visible do
    local bw,bh=math.max(150*scale,Input.TouchEnabled and 150 or 0),math.max(42*scale,Input.TouchEnabled and 44 or 0)
    place(name,(w-bw)/2,h-120*scale-(#visible-i)*(bh+8),bw,bh)
   end
  end
  if compact then
   place("AltimeterFrame", 202, 4, math.max(220, w - 326), 44)
   local kit = place("EmergencyKitButton", 8, 4, 186, 44)
   if kit then kit.TextWrapped = true kit.TextSize = 13 end
   local shop = place("ShopToggleButton", w - 116, 4, 108, 44)
   if shop then shop.TextWrapped = true end
   place("StatusFrame", 8, 56, 186, 92)
   local status = get("StatusFrame")
   if status then
    for _, f in status:GetChildren() do
     if f:IsA("TextLabel") then f.TextSize = 12 f.TextWrapped = true end
    end
    status.HoleIcons.TextSize = 13
    status.InvulnLabel.Position = UDim2.fromOffset(8, 72)
    status.HolePenalty.Position = UDim2.fromOffset(8, 48)
    status.HolePenalty.Size = UDim2.new(1, -16, 0, 26)
   end
   place("GroundedCountdown", 202, 51, math.max(220, w - 326), 30)
   -- Helm release and auto gas are primary controls, reachable in one tap.
   local release = get("ReleaseHelmButton")
   local showRelease = release and release.Visible
   local autoGas = get("AutoGasButton")
   local showAutoGas = autoGas and autoGas.Visible
   local showRescue=rescue and rescue.Visible
   local jump = place("JumpPanel", w / 2 - ((showAutoGas or showRescue) and 182 or 106), h - 56, 100, 48)
   if jump then
    jump.JumpHint.Visible = false
    box(jump.JumpButton, 0, 0, 100, 48)
   end
   place("ReleaseHelmButton", w / 2 - 202, h - 56, 140, 48)
   place("AutoGasButton", w / 2 - (showRelease and 54 or 74), h - 56, 140, 48)
   place("PullCrewButton",w/2-74,h-56,140,48)
   box(toggle, w / 2 + (showRelease and 94 or((showAutoGas or showRescue) and 74 or 6)), h - 56, 108, 48)
   box(tray, w / 2 - 120, 8, 240, h - 72)
   tray.CanvasSize = UDim2.fromOffset(0, row * 50 + 8)
   place("GasButton", w - 116, 58, 108, 64)
   place("MobileShootButton", w - 88, 58, 80, 64)
   place("WeaponFrame", w - 194, h - 170, 186, 75)
   place("TetherFrame", w / 2 - 120, h - 108, 240, 44)
   place("GhostSpotterFrame", w / 2 - 170, 58, 340, 65)
   local storm = place("StormChallengePanel", 202, 56, math.max(220, w - 326), 94)
   if storm then
    storm.Title.TextSize = 14
    storm.Detail.TextSize = 13
    storm.Detail.Size = UDim2.new(1, -20, 0, 60)
   end
   place("AlertBanner", 202, 56, math.max(220, w - 326), 85)
  end
  -- Tablets need their own touch layout, rather than desktop offsets and key hints.
  local tablet = Input.TouchEnabled and not compact
  gui:SetAttribute("TabletLayout",tablet)
  local margin = compact and 12 or 20
  if tablet then
   place("AltimeterFrame",(w-math.min(460,w-32))/2,12,math.min(460,w-32),52)
   place("StatusFrame",16,80,256,112)
   place("EmergencyKitButton",16,204,256,52)
   place("ShopToggleButton",16,268,124,48)
   place("PingButton",148,268,124,48)
   place("WarningAudioToggleButton",16,328,256,48)
   local centerWidth=math.min(520,w-304)
   local centerX=math.max(288,(w-centerWidth)/2)
   place("GroundedCountdown",centerX,80,math.min(460,centerWidth),32)
   place("StormChallengePanel",centerX,144,centerWidth,104)
   place("AlertBanner",centerX,144,centerWidth,96)
   place("GhostSpotterFrame",centerX,144,math.min(340,centerWidth),65)
   place("TetherFrame",(w-300)/2,h-72,300,48)
   place("GasButton",w-148,h-92,128,72)
   place("ReleaseHelmButton",w-468,h-80,148,48)
   place("AutoGasButton",w-308,h-80,148,48)
  end
  -- One circular jump target, clear of shoot, inventory and the native thumbstick.
  local jumpSize=tablet and 96 or(compact and 72 or 80)
  local jumpY=h-margin-jumpSize
  local jump=place("JumpPanel",w-margin-jumpSize,jumpY,jumpSize,jumpSize)
  if jump then
   jump.BackgroundTransparency=1
   jump.JumpHint.Visible=false
   box(jump.JumpButton,0,0,jumpSize,jumpSize)
   jump.JumpButton.TextSize=compact and 30 or 36
  end
  local fireSize=tablet and 88 or(compact and 64 or 80)
  local fireY=jumpY-12-fireSize
  local fireX=compact and(w-margin-jumpSize-12-fireSize)or(w-margin-fireSize)
  place("MobileShootButton",fireX,fireY,fireSize,fireSize)
  if not compact then
   place("WeaponFrame",w-margin-240,fireY-92,240,80)
   place("ReloadButton",w-margin-fireSize-132,fireY,120,44)
   place("DropButton",w-margin-fireSize-132,fireY+52,120,44)
  else
   place("WeaponFrame",w/2-90,h-(Input.TouchEnabled and 128 or 144),180,Input.TouchEnabled and 48 or 80)
   local pilot=get("ReleaseHelmButton")
   if pilot and pilot.Visible then
    place("GasButton",w-116,h-80,104,64)
    place("AutoGasButton",w-268,h-64,140,48)
    place("ReleaseHelmButton",w-420,h-64,140,48)
    box(toggle,w-268,h-120,140,48)
   else
    box(toggle,w-margin-jumpSize-120,h-60,108,48)
   end
   place("PullCrewButton",w-margin-jumpSize-152,h-116,140,48)
  end
  local kit=get("EmergencyKitButton")
  if kit then kit.TextWrapped=true kit.TextSize=compact and 12 or 14 end
  local altimeter=get("AltimeterFrame")
  if altimeter then
   altimeter.AltLabel.TextScaled=true
   local limit=altimeter.AltLabel:FindFirstChildOfClass("UITextSizeConstraint")or Instance.new("UITextSizeConstraint",altimeter.AltLabel)
   limit.MinTextSize=10 limit.MaxTextSize=16
   altimeter.BarBg.Size=UDim2.new(1,-144,0,10)
   altimeter.VerticalSpeedLabel.TextScaled=true
  end
  if statusPanel then
   statusPanel.HoleIcons.TextScaled=true
   statusPanel.HolePenalty.TextWrapped=true
  end
  local weapon=get("WeaponFrame")
  if weapon then
   weapon.WeaponName.TextSize=compact and 14 or 16
   weapon.AmmoLabel.TextSize=compact and 14 or 16
   weapon.DropTip.Visible=not Input.TouchEnabled
   weapon.AmmoLabel.Size=UDim2.new(1,-20,0,24)
   if compact and Input.TouchEnabled then
    box(weapon.WeaponName,8,2,164,20)
    box(weapon.AmmoLabel,8,24,164,20)
   else
    weapon.WeaponName.Position=UDim2.fromOffset(10,6)
    weapon.WeaponName.Size=UDim2.new(1,-20,0,24)
    weapon.AmmoLabel.Position=UDim2.fromOffset(10,30)
   end
  end
  -- Scroll content instead of shrinking purchase/close targets below 44 pixels.
  if modal then
   place("ShopModal", (w - math.min(440, w - 24)) / 2, 8, math.min(440, w - 24), math.min(390, h - 16))
   modal.ZIndex = 21
   for _, child in modal:GetDescendants() do if child:IsA("GuiObject") then child.ZIndex = 22 end end
  end
  if wheel then
   local bw = math.min(400, w - 24)
   place("TacticalPingWheel", (w - bw) / 2, math.max(8, (h - 250) / 2), bw, 250)
   wheel.ZIndex = 21
   for i = 1, 5 do
    local b = wheel:FindFirstChild("Ping" .. i)
    if b then box(b, 0, (i - 1) * 50, bw, 44) b.ZIndex = 22 b.TextSize = 14 end
   end
  end
 end)
end

return Layout
