-- One layout owner: scale positions and dimensions together, never touch hitboxes.
local Layout = {}
local actions = {"AttachButton", "ClimbButton", "DescendButton", "RepairButton", "DetachButton", "RepairRopeButton", "ReloadButton", "DropButton", "PingButton", "WarningAudioToggleButton"}
local riggingActions = {"AttachButton", "RepairRopeButton", "DetachButton", "ClimbButton", "RepairButton", "DescendButton"}

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
   local jump = place("JumpPanel", w / 2 - (showAutoGas and 182 or 106), h - 56, 100, 48)
   if jump then
    jump.JumpHint.Visible = false
    box(jump.JumpButton, 0, 0, 100, 48)
   end
   place("ReleaseHelmButton", w / 2 - 202, h - 56, 140, 48)
   place("AutoGasButton", w / 2 - (showRelease and 54 or 74), h - 56, 140, 48)
   box(toggle, w / 2 + (showRelease and 94 or(showAutoGas and 74 or 6)), h - 56, 108, 48)
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
