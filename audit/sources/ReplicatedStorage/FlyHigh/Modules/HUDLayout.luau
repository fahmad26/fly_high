-- Responsive composition; controllers own actions and role visibility.
local Layout={}
local rigging={"AttachButton","RepairRopeButton","PullCrewButton","DetachButton","ClimbButton","RepairButton","DescendButton"}
local function box(o,x,y,w,h)
 if not o then return end
 o.AnchorPoint=Vector2.zero o.Position=UDim2.fromOffset(math.round(x),math.round(y))o.Size=UDim2.fromOffset(math.round(w),math.round(h))
end
function Layout.Start(gui,player)
 local theme=require(script.Parent.HUDTheme).Start(gui,player)
 local input=game:GetService("UserInputService")
 gui.ScreenInsets=Enum.ScreenInsets.CoreUISafeInsets
 local scrim=Instance.new("TextButton")scrim.Name="HUDModalScrim"scrim.Text=""scrim.BackgroundColor3=Color3.fromRGB(7,15,32)
 scrim.BackgroundTransparency=.24 scrim.BorderSizePixel=0 scrim.Size=UDim2.fromScale(1,1)scrim.Visible=false scrim.ZIndex=20 scrim.Parent=gui
 local function get(name)return gui:FindFirstChild(name)end
 scrim.Activated:Connect(function()for _,name in {"ShopModal","TacticalPingWheel"}do local o=get(name)if o then o.Visible=false end end end)
 local elapsed=1 local connection
 connection=game:GetService("RunService").RenderStepped:Connect(function(dt)
  if not gui.Parent then theme.Destroy()connection:Disconnect()return end
  elapsed+=dt if elapsed<.1 then return end elapsed=0
  local w,h=gui.AbsoluteSize.X,gui.AbsoluteSize.Y if w<1 or h<1 then return end
  local compact=h<500 or w<760
  gui:SetAttribute("CompactLayout",compact)gui:SetAttribute("TabletLayout",input.TouchEnabled and not compact)
  gui:SetAttribute("HUDDesignVersion",2)
  local function place(name,x,y,bw,bh)local o=get(name)box(o,x,y,bw,bh)return o end
  local margin=compact and 14 or 20
  local inFlight=player:GetAttribute("InFlight")==true
  local topW=math.min(compact and 350 or 430,w-32)
  place("AltimeterFrame",(w-topW)/2,8,topW,compact and 60 or 72)
  local statusY=w>=920 and 18 or 84
  local statusW=compact and 190 or 208
  local status=place("StatusFrame",margin,statusY,statusW,compact and 58 or 84)
  local storm=get("StormChallengePanel")
  if status then status.Visible=inFlight and not(storm and storm.Visible)end
  local tile=compact and 48 or 64 local gap=compact and 10 or 12
  local navY=compact and 154 or math.max(statusY+108,math.min(250,h*.34))
  for i,name in {"ShopToggleButton","EmergencyKitButton","PingButton","WarningAudioToggleButton"}do
   local col=compact and i-1 or(i-1)%2 local row=compact and 0 or math.floor((i-1)/2)
   place(name,margin+col*(tile+gap),navY+row*(tile+gap),tile,tile)
  end
  local jumpSize=compact and 72 or 88
  local jump=place("JumpPanel",w-margin-jumpSize,h-margin-jumpSize,jumpSize,jumpSize)
  if jump then jump.BackgroundTransparency=1 jump.JumpHint.Visible=false box(jump.JumpButton,0,0,jumpSize,jumpSize)end
  local fireSize=compact and 68 or 84
  local fireX=compact and w-margin-jumpSize-42-fireSize or w-margin-fireSize
  local fireY=h-margin-jumpSize-18-fireSize
  place("MobileShootButton",fireX,fireY,fireSize,fireSize)
  local utility=compact and 46 or 52
  local utilityY=compact and h-138 or h-162
  place("ReloadButton",compact and math.max(14,w-314)or w-268,utilityY,utility,utility)
  place("DropButton",compact and math.max(70,w-258)or w-204,utilityY,utility,utility)
  local ammoX=compact and (w<500 and 14 or math.max(w/2+36,w-330))or w-382
  local ammoW=compact and (w<500 and math.min(218,w-28)or math.min(218,w-margin-jumpSize-12-ammoX))or 244
  place("WeaponFrame",ammoX,h-(w<500 and 246 or(compact and 66 or 96)),ammoW,compact and 52 or 76)
  place("GasButton",w-margin-(compact and 94 or 104),h-margin-(compact and 78 or 88),compact and 94 or 104,compact and 78 or 88)
  place("AutoGasButton",w-margin-(compact and 256 or 282),h-margin-56,compact and 150 or 166,56)
  place("ReleaseHelmButton",w-margin-(compact and 324 or 350),h-margin-56,56,56)
  if w<500 then
   place("AutoGasButton",margin,h-148,180,56)
   place("ReleaseHelmButton",margin,h-80,56,56)
  end
  local visible={}
  for _,name in rigging do local o=get(name)if o and o.Visible then table.insert(visible,o)end end
  local bw=compact and 138 or 152 local bh=compact and 48 or 54 local perRow=math.min(3,math.max(1,math.floor((w-240)/(bw+10))))
  local rows=math.ceil(#visible/perRow)
  for i,o in visible do
   local row=math.floor((i-1)/perRow)local col=(i-1)%perRow local count=math.min(perRow,#visible-row*perRow)
   box(o,(w-(count*bw+(count-1)*10))/2+col*(bw+10),h-104-(rows-row-1)*(bh+10),bw,bh)
  end
  local ropeW=math.min(250,w-jumpSize-2*margin-12)
  place("TetherFrame",w<500 and margin or(w-ropeW)/2,h-42,ropeW,28)
  local centerX=w<650 and margin or(compact and 250 or math.max(statusW+margin+20,(w-460)/2))
  local alertW=math.min(460,w-centerX-(w<650 and margin or(compact and 100 or 24)))
  local alertY=w<650 and 220 or(compact and 82 or 94)
  place("AlertBanner",centerX,alertY,alertW,72)
  place("StormChallengePanel",centerX,alertY,alertW,90)
  place("GhostSpotterFrame",(w-math.min(340,w-32))/2,compact and 82 or 94,math.min(340,w-32),64)
  place("GroundedCountdown",(w-math.min(430,w-32))/2,compact and 74 or 88,math.min(430,w-32),28)
  local modal=get("ShopModal")local wheel=get("TacticalPingWheel")
  scrim.Visible=(modal and modal.Visible)or(wheel and wheel.Visible)or false
  if modal then
   local mw=math.min(460,w-36)local mh=math.min(410,h-24)
   box(modal,(w-mw)/2,(h-mh)/2,mw,mh)modal.CanvasSize=UDim2.fromOffset(0,390)modal.ZIndex=22
   for _,child in modal:GetDescendants()do if child:IsA("GuiObject")then child.ZIndex=23 end end
  end
  if wheel then
   local mw=math.min(360,w-36)local mh=math.min(290,h-24)
   box(wheel,(w-mw)/2,(h-mh)/2,mw,mh)wheel.ZIndex=22
   for i=1,5 do local b=wheel:FindFirstChild("Ping"..i)if b then box(b,0,(i-1)*54,mw,48)b.ZIndex=23 end end
  end
  theme.Step()
 end)
end
return Layout
