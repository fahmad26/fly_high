-- Presentation only. Original controls own input, visibility, role checks and text.
local Assets = require(script.Parent.HUDImageAssets)
local Content = game:GetService("ContentProvider")
local Input = game:GetService("UserInputService")
local Theme = {}
local buttons = {
 EmergencyKitButton="emergency_kit", GasButton="burner_flame", AutoGasButton="helm",
 ReleaseHelmButton="helm_release", AttachButton="rope_attach", DetachButton="rope_detach",
 ClimbButton="rope_climb", DescendButton="rope_descend", RepairButton="patch_repair",
 RepairRopeButton="rope_repair", PullCrewButton="crew_rescue", ShopToggleButton="shop_supply",
 PingButton="team_ping", WarningAudioToggleButton="sound_on", BuyEmergencyKitButton="emergency_kit",
 BuyAK47Button="weapon_ak47",
}
local panels = {AltimeterFrame=true,StatusFrame=true,WeaponFrame=true,TetherFrame=true,
 StormChallengePanel=true,AlertBanner=true,GhostSpotterFrame=true,Card1=true,Card2=true}
local function image(parent, name)
 local item=Instance.new("ImageLabel")
 item.Name=name item.BackgroundTransparency=1 item.BorderSizePixel=0
 item.Active=false item.Selectable=false item.Visible=false item.Size=UDim2.fromScale(1,1)
 item.ScaleType=Enum.ScaleType.Fit item.Parent=parent
 return item
end
local function panel(parent)
 local item=image(parent,"HUDPanelArt")
 item.ScaleType=Enum.ScaleType.Slice item.SliceCenter=Rect.new(36,36,476,220) item.SliceScale=.5
 return item
end
function Theme.Start(gui, player)
 local state={}
 local ready, records, connections = {}, {}, {}
 local probes=Instance.new("Folder")probes.Name="HUDImagePreload"probes.Parent=gui
 local alive=true
 local function connect(signal, fn)
  local connection=signal:Connect(fn) table.insert(connections,connection) return connection
 end
 -- Serial loading avoids the initial 27-request burst. Failed images keep native UI.
 local loader=task.spawn(function()
  local order={"panel_9slice","jump_arrow","fire_target","emergency_kit"}
  for key in Assets do if not table.find(order,key) then table.insert(order,key) end end
  for pass=1,3 do
   for _,key in order do
    if not alive then return end
    if not ready[key] then
     local status
     local probe=Instance.new("ImageLabel")probe.Name=key probe.Image=Assets[key]probe.Visible=false probe.Parent=probes
     pcall(function() Content:PreloadAsync({probe},function(_,result) status=result end) end)
     ready[key]=status==Enum.AssetFetchStatus.Success or probe.IsLoaded
     probe:Destroy()
     gui:SetAttribute("ImageLoaded_"..key,ready[key]==true)
     local loadedCount=0 for _,loaded in ready do if loaded then loadedCount+=1 end end
     gui:SetAttribute("HUDImagesLoaded",loadedCount)
     task.wait(.75)
    end
   end
   local count=0 for _,loaded in ready do if loaded then count+=1 end end
   gui:SetAttribute("HUDImagesLoaded",count)
   if count==27 then break end
   task.wait(60*pass)
  end
 end)
 local function use(item,key)
  local loaded=ready[key]==true
  item.Visible=loaded
  if loaded and item.Image~=Assets[key] then item.Image=Assets[key] end
  return loaded
 end
 local function record(object,kind)
  local r=records[object]
  if r then return r end
  r={kind=kind,background=object.BackgroundTransparency,pressed=false,links={}}
  records[object]=r
  if kind=="button" or kind=="round" then
   r.text=object.TextTransparency
   r.art=kind=="round" and image(object,"HUDControlArt") or panel(object)
   if kind=="button" then
    r.icon=image(object,"HUDActionIcon") r.base=image(object,"HUDActionBase")
    r.caption=Instance.new("TextLabel") r.caption.Name="HUDActionCaption"
    r.caption.BackgroundTransparency=1 r.caption.TextWrapped=true r.caption.TextScaled=true
    r.caption.Parent=object
    local limit=Instance.new("UITextSizeConstraint",r.caption) limit.MinTextSize=10 limit.MaxTextSize=14
   end
   local function link(signal,fn)table.insert(r.links,signal:Connect(fn))end
   link(object.InputBegan,function(input)
    if object.Active and (input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch)then r.pressed=true r.input=input end
   end)
   link(object.MouseLeave,function()if r.input and r.input.UserInputType~=Enum.UserInputType.Touch then r.pressed=false end end)
  elseif kind=="panel" then
   r.art=panel(object)
   if object.Name=="AlertBanner"or object.Name=="StormChallengePanel"then
    r.warning=image(object,"HUDWarningBadge")r.warning.Position=UDim2.fromOffset(8,5)r.warning.Size=UDim2.fromOffset(24,24)
   end
  elseif kind=="reticle" or kind=="weapon" then r.art=image(object,"HUDGlyph") r.text=object.TextTransparency
  elseif kind=="holes" then
   r.text=object.TextTransparency r.icons={}
   for i=1,5 do
    local icon=image(object,"HUDBalloon"..i) icon.Position=UDim2.fromScale((i-1)*.12,0)
    icon.Size=UDim2.fromScale(.115,1) r.icons[i]=icon
   end
   r.caption=Instance.new("TextLabel")r.caption.Name="HUDHoleCount"r.caption.BackgroundTransparency=1
   r.caption.Position=UDim2.fromScale(.62,0)r.caption.Size=UDim2.fromScale(.38,1)
   r.caption.TextScaled=true r.caption.Parent=object
   local limit=Instance.new("UITextSizeConstraint",r.caption)limit.MinTextSize=10 limit.MaxTextSize=14
  end
  return r
 end
 connect(Input.InputEnded,function(input)
  for _,r in records do if r.input==input or (r.input and input.UserInputType==Enum.UserInputType.MouseButton1 and r.input.UserInputType==input.UserInputType)then r.pressed=false r.input=nil end end
 end)
 local function scan(object)
  if not object:IsA("GuiObject") or object.Name:sub(1,3)=="HUD" then return end
  if object:IsA("TextButton") and (object.Name=="MobileShootButton" or (object.Name=="JumpButton" and object.Parent.Name=="JumpPanel"))then record(object,"round")
  elseif object:IsA("TextButton") and buttons[object.Name] then record(object,"button")
  elseif panels[object.Name] then record(object,"panel")
  elseif object.Name=="WeaponReticle" then record(object,"reticle")
  elseif object.Name=="WeaponName" then record(object,"weapon")
  elseif object.Name=="HoleIcons" then record(object,"holes") end
 end
 for _,object in gui:GetDescendants()do scan(object)end
 connect(gui.DescendantAdded,scan)
 function state.Step()
  for object,r in records do
   if not object:IsDescendantOf(gui) then
    for _,link in r.links do link:Disconnect() end records[object]=nil continue
   end
   local z=object.ZIndex
   if r.kind=="panel" then
    r.art.ZIndex=z
    -- Child labels stay above the opaque 9-slice, including after modal reordering.
    for _,child in object:GetChildren()do if child:IsA("GuiObject")and child~=r.art then child.ZIndex=math.max(child.ZIndex,z+1)end end
    local loaded=use(r.art,"panel_9slice")
    object.BackgroundTransparency=loaded and 1 or r.background
    if r.warning then
     local title=object:FindFirstChild("AlertTitle")or object:FindFirstChild("Title")
     local loadedWarning=use(r.warning,"warning_badge")r.warning.ZIndex=z+2
     if title and loadedWarning then
      title.Position=UDim2.fromOffset(38,5)title.Size=UDim2.new(1,-46,0,25)title.TextScaled=true
      local limit=title:FindFirstChildOfClass("UITextSizeConstraint")or Instance.new("UITextSizeConstraint",title)
      limit.MinTextSize=10 limit.MaxTextSize=17
     end
    end
   elseif r.kind=="round" then
    local loaded=use(r.art,object.Name=="JumpButton" and "jump_arrow" or "fire_target")
    r.art.ZIndex=z+1 r.art.AnchorPoint=Vector2.new(.5,.5)r.art.Position=UDim2.fromScale(.5,.5)
    r.art.Size=UDim2.fromScale(r.pressed and .94 or 1,r.pressed and .94 or 1)
    r.art.ImageColor3=not object.Active and Color3.fromRGB(125,125,125)or(r.pressed and Color3.fromRGB(175,175,175)or Color3.new(1,1,1))
    object.TextTransparency=loaded and 1 or r.text
    if loaded then object.BackgroundTransparency=1 end
    local stroke=object:FindFirstChildOfClass("UIStroke")if stroke then stroke.Enabled=not loaded end
    local caption=object:FindFirstChild("JumpCaption")
    if caption then
     caption.ZIndex=z+2 caption.TextColor3=Color3.fromRGB(255,245,210)
     caption.TextStrokeTransparency=.1 caption.TextSize=9
    end
   elseif r.kind=="button" then
    local key=buttons[object.Name]
    if object.Name=="WarningAudioToggleButton"then key=player:GetAttribute("WarningAudioMuted")and "sound_off"or "sound_on"end
    r.art.ZIndex=z r.art.ImageColor3=r.pressed and Color3.fromRGB(175,175,175)or Color3.new(1,1,1)
    local loaded=use(r.art,"panel_9slice")
    object.BackgroundTransparency=loaded and 1 or r.background
    local iconLoaded=use(r.icon,key)
    local decorated=loaded or iconLoaded
    object.TextTransparency=decorated and 1 or r.text r.caption.Visible=decorated
    local inset=iconLoaded and 44 or 8
    r.caption.Position=UDim2.fromOffset(inset,4)r.caption.Size=UDim2.new(1,-inset-8,1,-8)
    r.caption.Text=object.Text:gsub("🛡️%s*",""):gsub("🔥%s*",""):gsub("💬%s*","")
    r.caption.Font=object.Font r.caption.TextColor3=object.TextColor3 r.caption.ZIndex=z+3
    r.icon.ZIndex=z+2 r.icon.AnchorPoint=Vector2.new(0,.5)r.icon.Position=UDim2.new(0,7,.5,0)r.icon.Size=UDim2.fromOffset(30,30)
    local circle=not object.Active and "control_circle_disabled"or(r.pressed and "control_circle_pressed"or "control_circle_normal")
    r.base.Visible=iconLoaded and ready[circle]==true and key~="burner_flame"
    if r.base.Visible then r.base.Image=Assets[circle]end
    r.base.ZIndex=z+1 r.base.AnchorPoint=r.icon.AnchorPoint r.base.Position=r.icon.Position r.base.Size=r.icon.Size
   elseif r.kind=="reticle" then
    r.art.ZIndex=z+1 object.TextTransparency=use(r.art,"aim_reticle")and 1 or r.text
   elseif r.kind=="weapon" then
    local loaded=use(r.art,object.Text=="AK-47"and "weapon_ak47"or "weapon_pistol")
    r.art.ZIndex=z+1 r.art.Size=UDim2.fromOffset(32,16)r.art.AnchorPoint=Vector2.new(0,.5)r.art.Position=UDim2.new(0,-34,.5,0)
    if loaded then object.Position+=UDim2.fromOffset(34,0)object.Size-=UDim2.fromOffset(34,0)end
   elseif r.kind=="holes" then
    local holes=tonumber(object.Text:match("(%d)/5"))or 0
    local loaded=ready.balloon_intact and (holes==0 or ready.balloon_torn)
    object.TextTransparency=loaded and 1 or r.text r.caption.Visible=loaded==true
    r.caption.Text=string.format("%d/5",holes)r.caption.Font=object.Font r.caption.TextColor3=object.TextColor3 r.caption.ZIndex=z+1
    for i,icon in r.icons do
     icon.ZIndex=z+1
     if loaded then use(icon,i>5-holes and "balloon_torn"or "balloon_intact")else icon.Visible=false end
    end
   end
  end
 end
 function state.Destroy()
  if not alive then return end alive=false
  if coroutine.status(loader)~="dead"then task.cancel(loader)end
  probes:Destroy()
  for _,connection in connections do connection:Disconnect()end
  for _,r in records do for _,connection in r.links do connection:Disconnect()end end
  table.clear(records)
 end
 connect(gui.Destroying,state.Destroy)
 return state
end
return Theme
