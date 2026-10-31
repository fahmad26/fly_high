-- Bright arcade art direction. Presentation never owns gameplay actions.
local Assets=require(script.Parent.HUDImageAssets)
local Glyphs=require(script.Parent.HUDGlyphs)
local Input=game:GetService("UserInputService")
local Content=game:GetService("ContentProvider")
local Theme={}
local palettes={
 blue={Color3.fromRGB(64,215,255),Color3.fromRGB(10,106,219)},
 green={Color3.fromRGB(138,249,73),Color3.fromRGB(24,164,76)},
 gold={Color3.fromRGB(255,220,66),Color3.fromRGB(242,139,20)},
 orange={Color3.fromRGB(255,174,58),Color3.fromRGB(236,73,26)},
 red={Color3.fromRGB(255,110,133),Color3.fromRGB(202,31,71)},
 purple={Color3.fromRGB(170,132,255),Color3.fromRGB(85,64,200)},
 dark={Color3.fromRGB(38,61,96),Color3.fromRGB(12,24,47)},
 disabled={Color3.fromRGB(104,123,148),Color3.fromRGB(49,65,88)},
}
local configs={
 ShopToggleButton={"shop","TOKO","gold","tile"}, EmergencyKitButton={"kit","KIT","green","tile"},
 PingButton={"ping","PING","blue","tile"},WarningAudioToggleButton={"sound","SUARA","purple","tile"},
 MobileShootButton={"fire","TEMBAK","red","round"},JumpButton={"jump","LOMPAT","blue","round"},
 GasButton={"gas","NAIK","orange","tile"},AutoGasButton={"gas","OTOMATIS","blue","wide"},
 ReleaseHelmButton={"release","LEPAS","dark","tile"},ReloadButton={"reload","ISI","blue","tile"},
 DropButton={"drop","LEPAS","dark","tile"},AttachButton={"attach","PASANG TALI","blue","wide"},
 DetachButton={"detach","LEPAS TALI","dark","wide"},ClimbButton={"climb","NAIK KUBAH","blue","wide"},
 DescendButton={"descend","TURUN","blue","wide"},RepairButton={"repair","TAHAN TAMBAL","green","wide"},
 RepairRopeButton={"rope","TAHAN PERBAIKI TALI","green","wide"},PullCrewButton={"rescue","TARIK REKAN","orange","wide"},
 BuyEmergencyKitButton={"kit",nil,"green","wide"},BuyAK47Button={"weapon",nil,"gold","wide"},
 SpotHazardButton={"warning","TANDAI BAHAYA","purple","wide"},CloseButton={"close","","red","round"},
}
local function box(o,x,y,w,h)o.Position=UDim2.fromOffset(x,y)o.Size=UDim2.fromOffset(w,h)end
local function label(parent,name,maxSize)
 local l=Instance.new("TextLabel")l.Name=name l.BackgroundTransparency=1 l.TextColor3=Color3.new(1,1,1)
 l.Font=Enum.Font.FredokaOne l.TextScaled=true l.TextWrapped=true l.TextStrokeColor3=Color3.fromRGB(5,15,32)l.TextStrokeTransparency=.05
 l.Size=UDim2.fromScale(1,1)l.Parent=parent
 local c=Instance.new("UITextSizeConstraint",l)c.MinTextSize=9 c.MaxTextSize=maxSize or 18 return l
end
local function frame(parent,name)
 local f=Instance.new("Frame")f.Name=name f.BorderSizePixel=0 f.BackgroundTransparency=1 f.Size=UDim2.fromScale(1,1)f.Parent=parent return f
end
local function round(o,r)local c=o:FindFirstChildOfClass("UICorner")or Instance.new("UICorner",o)c.CornerRadius=UDim.new(r or 0,r and 0 or 8)end
local function stroke(o,color,width,transparency)
 local s=o:FindFirstChildOfClass("UIStroke")or Instance.new("UIStroke",o)
 s.Color=color s.Thickness=width s.Transparency=transparency or 0 s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border return s
end
local function ztree(root,z)
 root.ZIndex=z for _,o in root:GetDescendants()do if o:IsA("GuiObject")then o.ZIndex=z end end
end
local function surface(parent,circular)
 local shadow=frame(parent,"HUDShadow")shadow.BackgroundTransparency=.12 shadow.BackgroundColor3=Color3.fromRGB(3,9,20)
 shadow.Position=UDim2.fromOffset(0,4)round(shadow,circular and .5 or nil)
 local face=frame(parent,"HUDSurface")face.BackgroundTransparency=0 round(face,circular and .5 or nil)
 stroke(face,Color3.fromRGB(5,15,32),3)
 local gradient=Instance.new("UIGradient",face)gradient.Rotation=90
 local inset=frame(face,"HUDInset")inset.Position=UDim2.fromOffset(3,3)inset.Size=UDim2.new(1,-6,1,-6)
 round(inset,circular and .5 or nil)stroke(inset,Color3.new(1,1,1),1,.48)
 local shine=frame(face,"HUDShine")shine.Position=UDim2.new(0,6,0,5)shine.Size=UDim2.new(1,-12,0,2)
 shine.BackgroundTransparency=.64 shine.BackgroundColor3=Color3.new(1,1,1)
 shine.Visible=not circular
 return {face=face,shadow=shadow,gradient=gradient,shine=shine}
end
local function paint(s,palette,z,pressed)
 local colors=palettes[palette]or palettes.blue
 s.face.BackgroundColor3=Color3.new(1,1,1)
 local shade=pressed and .18 or 0
 s.gradient.Color=ColorSequence.new(colors[1]:Lerp(Color3.new(0,0,0),shade),colors[2]:Lerp(Color3.new(0,0,0),shade))
 s.face.Position=UDim2.fromOffset(0,pressed and 3 or 0)
 s.shadow.Visible=not pressed ztree(s.shadow,math.max(1,z))ztree(s.face,z+1)
end
function Theme.Start(gui,player)
 local state={}local alive=true local records,links,ready={},{},{}
 gui:SetAttribute("HUDArtDirection","Sky Arcade")
 local probes=Instance.new("Folder")probes.Name="HUDImagePreload"probes.Parent=gui
 -- Secondary illustrations only. Core controls render immediately without image downloads.
 local wanted={"balloon_intact","emergency_kit","weapon_pistol","weapon_ak47"}
 local worker=task.spawn(function()
  for pass=1,2 do
   for _,key in wanted do
    if not alive then return end
    if not ready[key]then
     local probe=Instance.new("ImageLabel")probe.Name=key probe.Visible=false probe.Image=Assets[key]probe.Parent=probes
     local status
     pcall(function()Content:PreloadAsync({probe},function(_,result)status=result end)end)
     ready[key]=status==Enum.AssetFetchStatus.Success or probe.IsLoaded probe:Destroy()
     gui:SetAttribute("ImageLoaded_"..key,ready[key]==true)task.wait(1)
    end
   end
   if pass<2 then task.wait(60)end
  end
 end)
 local function connect(signal,fn)local c=signal:Connect(fn)table.insert(links,c)return c end
 local function art(parent)
  local a=Instance.new("ImageLabel")a.Name="HUDIllustration"a.BackgroundTransparency=1 a.Active=false a.Selectable=false
  a.ScaleType=Enum.ScaleType.Fit a.Size=UDim2.fromScale(1,1)a.Visible=false a.Parent=parent return a
 end
 local function use(a,key)
  a.Visible=ready[key]==true if a.Visible then a.Image=Assets[key]end return a.Visible
 end
 local function build(o,kind,config)
  if records[o]then return end
  local r={kind=kind,config=config,pressed=false,links={}}records[o]=r
  if kind~="reticle"then r.skin=surface(o,config and config[4]=="round")o.BackgroundTransparency=1 end
  if kind=="button"then
   o.TextTransparency=1
   local oldStroke=o:FindFirstChildOfClass("UIStroke")if oldStroke then oldStroke.Enabled=false end
   o.AutoButtonColor=false
   r.glyphBox=frame(o,"HUDIconBox")r.glyph=Glyphs.Draw(r.glyphBox,config[1])
   r.caption=label(o,"HUDCaption",config[4]=="wide"and 16 or 13)
   r.hint=label(o,"HUDKeyHint",10)r.hint.BackgroundTransparency=.18 r.hint.BackgroundColor3=Color3.fromRGB(5,18,40)round(r.hint,nil)
   r.badge=label(o,"HUDBadge",12)r.badge.BackgroundTransparency=0 r.badge.BackgroundColor3=Color3.fromRGB(240,53,77)round(r.badge,.5)
   local function link(signal,fn)table.insert(r.links,signal:Connect(fn))end
   link(o.InputBegan,function(i)if o.Active and(i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1)then r.pressed=true r.input=i end end)
   link(o.MouseLeave,function()if r.input and r.input.UserInputType~=Enum.UserInputType.Touch then r.pressed=false end end)
  elseif kind=="alt"then
   r.head=label(o,"HUDAltitude",28)r.goal=label(o,"HUDGoal",11)r.percent=label(o,"HUDProgress",11)
   r.emblem=frame(o,"HUDEmblem")r.glyph=Glyphs.Draw(r.emblem,"climb")
   r.art=art(r.emblem)
  elseif kind=="status"then
   r.head=label(o,"HUDCondition",15)r.count=label(o,"HUDDamageCount",16)r.detail=label(o,"HUDConditionDetail",11)r.pips={}
   for i=1,5 do local pip=frame(o,"HUDHull"..i)pip.BackgroundTransparency=0 round(pip,nil)r.pips[i]=pip end
  elseif kind=="weapon"then
   r.head=label(o,"HUDWeapon",13)r.ammo=label(o,"HUDAmmo",29)r.reserve=label(o,"HUDReserve",11)
   r.emblem=frame(o,"HUDWeaponIcon")r.glyph=Glyphs.Draw(r.emblem,"weapon")r.art=art(r.emblem)
  elseif kind=="tether"then
   r.head=label(o,"HUDRopeState",11)
  elseif kind=="alert"then
   r.emblem=frame(o,"HUDWarningIcon")r.glyph=Glyphs.Draw(r.emblem,"warning")
  elseif kind=="reticle"then
   o.TextTransparency=1 r.glyph=Glyphs.Draw(o,"aim")
  elseif kind=="card"then r.art=art(o)end
 end
 local function scan(o)
  if not o:IsA("GuiObject")or o.Name:sub(1,3)=="HUD"then return end
  if o:IsA("TextButton")then
   if configs[o.Name]then build(o,"button",configs[o.Name])
   elseif o.Name:match("^Ping%d$")then build(o,"button",{"ping",nil,"blue","wide"})end
  elseif o.Name=="AltimeterFrame"then build(o,"alt")
  elseif o.Name=="StatusFrame"then build(o,"status")
  elseif o.Name=="WeaponFrame"then build(o,"weapon")
  elseif o.Name=="TetherFrame"then build(o,"tether")
  elseif o.Name=="AlertBanner"or o.Name=="StormChallengePanel"then build(o,"alert")
  elseif o.Name=="WeaponReticle"then build(o,"reticle")
  elseif o.Name=="Card1"or o.Name=="Card2"then build(o,"card")
  elseif o.Name=="ShopModal"or o.Name=="GhostSpotterFrame"then build(o,"panel")end
 end
 for _,o in gui:GetDescendants()do scan(o)end connect(gui.DescendantAdded,scan)
 connect(Input.InputEnded,function(i)for _,r in records do if r.input==i or(r.input and i.UserInputType==Enum.UserInputType.MouseButton1 and r.input.UserInputType==i.UserInputType)then r.pressed=false r.input=nil end end end)
 connect(Input.WindowFocusReleased,function()for _,r in records do r.pressed=false r.input=nil end end)
 local function hide(o)if o and(o:IsA("TextLabel")or o:IsA("TextButton"))then o.TextTransparency=1 end end
 local function textStyle(o,maxSize)
  o.Font=Enum.Font.FredokaOne o.TextColor3=Color3.new(1,1,1)o.TextStrokeColor3=Color3.fromRGB(5,15,32)o.TextStrokeTransparency=.1
  o.TextScaled=true local c=o:FindFirstChildOfClass("UITextSizeConstraint")or Instance.new("UITextSizeConstraint",o)c.MinTextSize=10 c.MaxTextSize=maxSize or 16
 end
 function state.Step()
  local compact=gui:GetAttribute("CompactLayout")==true
  for o,r in records do
   if not o:IsDescendantOf(gui)then for _,c in r.links do c:Disconnect()end records[o]=nil continue end
   local z=o.ZIndex local w,h=o.AbsoluteSize.X,o.AbsoluteSize.Y
   if r.skin then paint(r.skin,"dark",z,false)o.BackgroundTransparency=1 end
   if r.kind=="button"then
    local cfg=r.config local key=cfg[1]local palette=cfg[3]local title=cfg[2]or o.Text
    if o.Name=="WarningAudioToggleButton"then
     key=player:GetAttribute("WarningAudioMuted")and "muted"or "sound"
     if r.lastKey~=key then r.glyph:Destroy()r.glyph=Glyphs.Draw(r.glyphBox,key)r.lastKey=key end
    elseif o.Name=="AutoGasButton"then
     local on=o.Text:find(": ON",1,true)~=nil title="OTOMATIS: "..(on and "ON"or "OFF")palette=on and "green"or "blue"
    elseif o.Name=="EmergencyKitButton"then
     if o.Text:find("CLUTCH",1,true)then palette="red"title="SAVE!"end
    end
    if not o.Active then palette="disabled"if o.Name=="JumpButton"then title="TERKUNCI"end end
    paint(r.skin,palette,z,r.pressed)
    local style=cfg[4]
    if style=="wide"then
     box(r.glyphBox,9,(h-28)/2,28,28)box(r.caption,43,5,w-51,h-10)
    else
     local size=math.min(w,h)*.51
     box(r.glyphBox,(w-size)/2,h*.12,size,size)box(r.caption,3,h*.71,w-6,h*.23)
    end
    ztree(r.glyphBox,z+3)r.caption.ZIndex=z+4 r.caption.Text=title r.caption.TextColor3=Color3.new(1,1,1)
    local hint=o.Text:match("%[([^%]]+)%]")
    r.hint.Visible=not Input.TouchEnabled and hint~=nil and #hint<=7 and hint~="GUNAKAN"
    if r.hint.Visible then r.hint.Text=hint:match("^%w+")or ""box(r.hint,w-21,3,18,14)end r.hint.ZIndex=z+5
    local cooldown=math.max(0,(player:GetAttribute("FlightJumpReadyAt")or 0)-workspace:GetServerTimeNow())
    r.badge.Visible=o.Name=="EmergencyKitButton"or(o.Name=="JumpButton"and player:GetAttribute("InFlight")==true and cooldown>0)
    if r.badge.Visible then
     r.badge.Text=o.Name=="EmergencyKitButton"and tostring(player:GetAttribute("EmergencyKits")or 0)or(math.ceil(cooldown).."s")
     box(r.badge,w-19,-5,23,23)
    end r.badge.ZIndex=z+5
    o.TextTransparency=1
    local jumpCaption=o:FindFirstChild("JumpCaption")if jumpCaption then jumpCaption.Visible=false end
   elseif r.kind=="alt"then
    paint(r.skin,"blue",z,false)
    local original=o:FindFirstChild("AltLabel")local bar=o:FindFirstChild("BarBg")local speed=o:FindFirstChild("VerticalSpeedLabel")
    if original and bar and speed then
     local altitude=original.Text:match("Ketinggian:%s*(%d+)")or "0"
     hide(original)r.head.Text=player:GetAttribute("InFlight")and (altitude.." KM")or "FLY HIGH"
     box(r.head,59,5,w-170,compact and 28 or 34)r.head.TextXAlignment=Enum.TextXAlignment.Left
     r.goal.Text="ISTANA AWAN  /  10.000 KM"box(r.goal,60,compact and 31 or 39,w-142,14)r.goal.TextXAlignment=Enum.TextXAlignment.Left
     r.percent.Text=original.Text:match("%((.-)%)")or "0%"box(r.percent,w-65,h-16,52,10)
     box(r.emblem,9,9,compact and 35 or 43,compact and 35 or 43)
     local loaded=use(r.art,"balloon_intact")r.glyph.Visible=not loaded ztree(r.emblem,z+3)
     box(bar,12,h-12,w-87,5)bar.ZIndex=z+3 bar.BackgroundColor3=Color3.fromRGB(6,33,80)bar.BackgroundTransparency=0
     local fill=bar:FindFirstChild("BarFill")if fill then fill.BackgroundColor3=Color3.fromRGB(144,255,68)fill.ZIndex=z+4 end
     box(speed,w-102,8,92,24)textStyle(speed,12)speed.ZIndex=z+4 speed.TextWrapped=true
     r.head.ZIndex=z+4 r.goal.ZIndex=z+4 r.percent.ZIndex=z+4
    end
   elseif r.kind=="status"then
    local holesLabel=o:FindFirstChild("HoleIcons")local penalty=o:FindFirstChild("HolePenalty")local invuln=o:FindFirstChild("InvulnLabel")
    if holesLabel and penalty then
     local holes=tonumber(holesLabel.Text:match("(%d)/5"))or 0
     paint(r.skin,holes>=4 and "red"or "dark",z,false)
     for _,name in {"HoleTitle","HoleIcons","HolePenalty","InvulnLabel"}do hide(o:FindFirstChild(name))end
     r.head.Text=holes==0 and "BALON AMAN"or "KONDISI BALON"r.count.Text=holes.."/5"
     box(r.head,10,5,w-60,18)box(r.count,w-44,4,34,20)
     r.head.TextXAlignment=Enum.TextXAlignment.Left
     local py=compact and 29 or 34 local pipW=(w-28)/5
     for i,pip in r.pips do box(pip,10+(i-1)*(pipW+2),py,pipW,compact and 6 or 10)pip.BackgroundColor3=i<=5-holes and Color3.fromRGB(126,246,81)or Color3.fromRGB(111,24,45)pip.ZIndex=z+3 end
     local details={[0]="Naik optimal",[1]="Naik melambat",[2]="Tidak bisa naik",[3]="Bahaya - turun 1.5x",[4]="Kritis - turun 2.5x",[5]="TERJUN BEBAS! PAKAI KIT"}
     r.detail.Text=(invuln and invuln.Visible and invuln.Text:gsub("🛡️%s*",""))or details[holes]
     box(r.detail,10,compact and 41 or 55,w-20,compact and 12 or 18)r.detail.TextXAlignment=Enum.TextXAlignment.Left
     r.head.ZIndex=z+3 r.count.ZIndex=z+3 r.detail.ZIndex=z+3
    end
   elseif r.kind=="weapon"then
    local name=o:FindFirstChild("WeaponName")local ammo=o:FindFirstChild("AmmoLabel")
    if name and ammo then
     hide(name)hide(ammo)hide(o:FindFirstChild("DropTip"))
     local weaponName=name.Text:find("AK",1,true)and "AK-47"or "PISTOL"
     r.head.Text=weaponName r.head.TextXAlignment=Enum.TextXAlignment.Left
     r.ammo.Text=ammo.Text:match("^(%d+%s*/%s*%d+)")or "MENGISI"
     r.ammo.TextXAlignment=Enum.TextXAlignment.Right r.reserve.Text="TAK TERBATAS"
     box(r.head,52,5,w-60,14)box(r.ammo,w-math.min(102,w-54),compact and 21 or 23,math.min(92,w-64),compact and 25 or 38)
     box(r.reserve,12,h-16,w-118,11)r.reserve.TextXAlignment=Enum.TextXAlignment.Left
     r.reserve.Visible=w>=190
     box(r.emblem,10,compact and 9 or 18,34,25)
     r.glyph.Visible=not use(r.art,weaponName=="AK-47"and "weapon_ak47"or "weapon_pistol")ztree(r.emblem,z+3)
     r.head.ZIndex=z+3 r.ammo.ZIndex=z+3 r.reserve.ZIndex=z+3
    end
   elseif r.kind=="tether"then
    local original=o:FindFirstChild("TetherLabel")local bar=o:FindFirstChild("TBarBg")
    if original and bar then
     hide(original)r.head.Text=original.Text:gsub("Tali Pengaman: ","TALI  ")
     box(r.head,8,2,w-16,13)r.head.ZIndex=z+3
     box(bar,8,h-9,w-16,4)bar.ZIndex=z+3 local fill=bar:FindFirstChild("TBarFill")if fill then fill.ZIndex=z+4 end
    end
   elseif r.kind=="alert"then
    paint(r.skin,o.Name=="AlertBanner"and "red"or "orange",z,false)
    box(r.emblem,9,9,25,25)ztree(r.emblem,z+3)
    local title=o:FindFirstChild("AlertTitle")or o:FindFirstChild("Title")
    local detail=o:FindFirstChild("AlertDesc")or o:FindFirstChild("Detail")
    if title then box(title,42,6,w-50,24)textStyle(title,16)title.ZIndex=z+3 end
    if detail then box(detail,10,34,w-20,h-40)textStyle(detail,12)detail.ZIndex=z+3 end
   elseif r.kind=="card"then
    for _,child in o:GetChildren()do if child:IsA("GuiObject")and child.Name:sub(1,3)~="HUD"then child.ZIndex=math.max(child.ZIndex,z+2)end end
    r.art.Position=UDim2.fromOffset(w-63,6)r.art.Size=UDim2.fromOffset(52,52)r.art.ZIndex=z+3
    use(r.art,o.Name=="Card1"and "emergency_kit"or "weapon_ak47")
    for _,child in o:GetChildren()do
     if child:IsA("TextLabel")and child.Name:sub(1,3)~="HUD"then
      child.ZIndex=z+3
      if child.Position.Y.Offset<20 then child.Size=UDim2.new(1,-72,0,24)textStyle(child,15)else child.TextColor3=Color3.fromRGB(212,232,255)end
     end
    end
   elseif r.kind=="reticle"then ztree(r.glyph,z+2)
   elseif r.kind=="panel"then
    for _,child in o:GetChildren()do if child:IsA("GuiObject")and child.Name:sub(1,3)~="HUD"then child.ZIndex=math.max(child.ZIndex,z+2)end end
    local title=o:FindFirstChild("ModalTitle")if title then title.Text="PERBEKALAN PENERBANGAN"textStyle(title,21)end
   end
  end
 end
 function state.Destroy()
  if not alive then return end alive=false
  if coroutine.status(worker)~="dead"then task.cancel(worker)end probes:Destroy()
  for _,c in links do c:Disconnect()end for _,r in records do for _,c in r.links do c:Disconnect()end end table.clear(records)
 end
 connect(gui.Destroying,state.Destroy)
 return state
end
return Theme
