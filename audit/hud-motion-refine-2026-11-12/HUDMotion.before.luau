--!strict
-- Presentation only: layout/input roots never move. No gameplay callbacks/remotes.
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Input = game:GetService("UserInputService")
local Players = game:GetService("Players")
local Art = require(script.Parent.HUDAdventureArt)
local RopeWarnings = require(script.Parent.FlyHighConfig).AUDIO_WARNINGS
local Motion = {}
local sessions: {[ScreenGui]: any} = setmetatable({}, {__mode = "k"}) :: any
local panels = {ShopModal=true, WeaponSettingsModal=true, TacticalPingWheel=true,
	AlertBanner=true, StormChallengePanel=true, GroundedCountdown=true, StatusFrame=true, WeaponFrame=true, TetherFrame=true, HUDMotionToast=true}

function Motion.Start(gui: ScreenGui, player: Player): any
	if sessions[gui] then return sessions[gui] end
	local state: any = {records={}, base={}, links={}, dead=false}
	sessions[gui] = state
	local function reduced(): boolean return player:GetAttribute("ReduceHUDMotion") == true end
	local function link(signal: any, callback: any)
		table.insert(state.links, signal:Connect(callback))
	end
	local function tween(r: any, scale: number, opacity: number, duration: number)
		if r.tween then r.tween:Cancel() end
		r.tween = TweenService:Create(r.values, TweenInfo.new(duration, if r.button and scale==1 and not reduced() then Enum.EasingStyle.Back else Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{Value=if reduced() then 1 else scale})
		r.tween:Play()
		if r.fadeTween then r.fadeTween:Cancel() end
		r.fadeTween = TweenService:Create(r.fade, TweenInfo.new(duration), {Value=opacity})
		r.fadeTween:Play()
	end
	local function neutral(r: any)
		r.pressed=false r.input=nil r.hover=false
		tween(r,1,1,.12)
	end
	local function bind(o: Instance)
		if state.dead then return end
		if not o:IsA("GuiObject") or state.records[o] then return end
		local button = o:IsA("GuiButton") and o.Name ~= "HUDModalScrim"
		if not button and not panels[o.Name] and not o.Name:match("^HUDHull%d$") then return end
		local r: any = {button=button, visible=false, links={}, values=Instance.new("NumberValue"), fade=Instance.new("NumberValue")}
		r.values.Value=1 r.fade.Value=1 state.records[o]=r
		if button then
			local function link(signal: any, fn: any) table.insert(r.links, signal:Connect(fn)) end
			link((o :: GuiButton).InputBegan,function(i: InputObject)
				if o.Active and (i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 or i.KeyCode==Enum.KeyCode.ButtonA) then
					r.pressed=true r.input=i tween(r,.95,1,.075)
				end
			end)
			link(o.MouseEnter,function() r.hover=true if not r.pressed and o.Active then tween(r,1.015,1,.12) end end)
			link(o.MouseLeave,function() r.hover=false if not r.input or r.input.UserInputType~=Enum.UserInputType.Touch then neutral(r) end end)
			link(o.SelectionGained,function() if o.Active then tween(r,1.015,1,.12) end end)
			link(o.SelectionLost,function() neutral(r) end)
		end
	end
	for _,o in gui:GetDescendants() do bind(o) end
	link(gui.DescendantAdded,bind)
	link(Input.InputEnded,function(i: InputObject)
		for _,r in state.records do if r.input==i then neutral(r) end end
	end)
	link(Input.WindowFocusReleased,function() for _,r in state.records do neutral(r) end end)
	-- Restore exact base properties before HUDLayout/HUDTheme calculate geometry.
	function state.BeforeLayout()
		for o,b in state.base do
			if o.Parent then
				if o.Position==b.appliedPosition then o.Position=b.position end
				if o.Size==b.appliedSize then o.Size=b.size end
				o.BackgroundTransparency=b.bg
				if b.image~=nil then o.ImageTransparency=b.image end
				if b.text~=nil then o.TextTransparency=b.text o.TextStrokeTransparency=b.stroke end
			end
		end
	end
	function state.Pulse(name: string)
		local o=gui:FindFirstChild(name,true) local r=o and state.records[o]
		if r and o.Visible and not reduced() and os.clock()-(r.pulseAt or 0)>.22 then
			r.pulseAt=os.clock() r.values.Value=1.025 tween(r,1,1,.24)
		end
	end
	function state.Capture()
		local base={}
		for _,o in gui:GetDescendants() do
			if o:IsA("GuiObject") then
				local b: any = {position=o.Position,size=o.Size,bg=o.BackgroundTransparency}
				if o:IsA("ImageLabel") or o:IsA("ImageButton") then b.image=o.ImageTransparency end
				if o:IsA("TextLabel") or o:IsA("TextButton") then b.text=o.TextTransparency b.stroke=o.TextStrokeTransparency end
				base[o]=b
			end
		end
		state.base=base
		for o,r in state.records do
			if not o:IsDescendantOf(gui) then
				if r.tween then r.tween:Cancel() end if r.fadeTween then r.fadeTween:Cancel() end
				if r.closeTask then task.cancel(r.closeTask) end
				for _,c in r.links do c:Disconnect() end
				r.values:Destroy() r.fade:Destroy() state.records[o]=nil
			else
				local visible=o.Visible and gui.Enabled
				if visible and not r.visible and not r.button then
					r.values.Value=if reduced() then 1 else .97 r.fade.Value=.15 tween(r,1,1,.20)
				elseif (not visible and r.visible) or (r.button and not o.Active and r.pressed) then neutral(r) end
				r.visible=visible
			end
		end
	end

 local toast=Instance.new("Frame")
 toast.Name="HUDMotionToast" toast.BackgroundTransparency=1 toast.AnchorPoint=Vector2.new(.5,0)
 toast.Size=UDim2.new(.8,0,0,44) toast.Position=UDim2.new(.5,0,0,145) toast.Visible=false toast.ZIndex=18 toast.Parent=gui
 local constraint=Instance.new("UISizeConstraint",toast) constraint.MaxSize=Vector2.new(440,44)
 Art.Draw(toast,"warning_amber",18,"wide")
 local caption=Instance.new("TextLabel") caption.Name="Caption" caption.BackgroundTransparency=1
 caption.Size=UDim2.new(1,-48,1,-8) caption.Position=UDim2.fromOffset(24,4) caption.Font=Enum.Font.FredokaOne
 caption.TextSize=18 caption.TextColor3=Color3.new(1,1,1) caption.TextStrokeTransparency=.3 caption.TextWrapped=true caption.ZIndex=19 caption.Parent=toast
 local stars={}
 for i=1,8 do
  local star=Instance.new("TextLabel") star.Name="Spark"..i star.Text="✦" star.Font=Enum.Font.FredokaOne
  star.TextColor3=Color3.fromRGB(255,222,123) star.BackgroundTransparency=1 star.Size=UDim2.fromOffset(18,18)
  star.TextSize=16 star.Active=false star.ZIndex=20 star.Parent=toast table.insert(stars,star)
 end
 local expires=0 local born=0
 link(gui:GetAttributeChangedSignal("HUDMotionNotice"),function()
  caption.Text=gui:GetAttribute("HUDMotionNotice") or "" toast.Visible=true born=os.clock() expires=born+1.5
 end)
 local lastRope: number? = nil
 local lastHoles: number? = nil
	local lastAmmo: string? = nil
	link(player:GetAttributeChangedSignal("InFlight"),function() lastHoles=nil lastAmmo=nil lastRope=nil end)
	local smoothed: {[Instance]: number} = {}
	local function render(dt: number)
		if state.dead then return end
		if toast.Visible and os.clock()>=expires then toast.Visible=false end
		for o,b in state.base do
			if not o.Parent then continue end
			if b.appliedSize and o.Size~=b.appliedSize then b.size=o.Size end
			if b.appliedPosition and o.Position~=b.appliedPosition then b.position=o.Position end
			local r=state.records[o.Parent]
			local scale=if r and not reduced() then r.values.Value else 1
			local p,s=b.position,b.size
			if scale~=1 then
				o.Position=UDim2.new(.5+(p.X.Scale-.5)*scale,p.X.Offset*scale,.5+(p.Y.Scale-.5)*scale,p.Y.Offset*scale)
				o.Size=UDim2.new(s.X.Scale*scale,s.X.Offset*scale,s.Y.Scale*scale,s.Y.Offset*scale)
			else o.Position=p o.Size=s end
			if o.Name=="BarFill" or o.Name=="TBarFill" then
				local goal=s.X.Scale
				local display=smoothed[o] or goal
				display=if reduced() then goal else display+(goal-display)*(1-math.exp(-dt/0.10))
				smoothed[o]=display o.Size=UDim2.new(display,s.X.Offset,s.Y.Scale,s.Y.Offset)
			end
			local opacity=1 local ancestor: Instance?=o
			while ancestor and ancestor~=gui do
				local record=state.records[ancestor] if record then opacity*=record.fade.Value end
				ancestor=ancestor.Parent
			end
			o.BackgroundTransparency=1-(1-b.bg)*opacity
			if b.image~=nil then o.ImageTransparency=1-(1-b.image)*opacity end
			if b.text~=nil then o.TextTransparency=1-(1-b.text)*opacity o.TextStrokeTransparency=1-(1-b.stroke)*opacity end
			b.appliedPosition=o.Position b.appliedSize=o.Size
		end
		
 local banner=gui:FindFirstChild("AlertBanner")
 local scrim=gui:FindFirstChild("HUDModalScrim")
 if toast.Visible then
  local age=os.clock()-born
  local blocked=(banner and banner.Visible) or (scrim and scrim.Visible)
  toast.Position=UDim2.new(.5,0,0,math.min(gui.AbsoluteSize.Y*.32,145))
  caption.Visible=not blocked
  for i,star in stars do
   star.Visible=not reduced() and not blocked and age<.8
   local angle=i*math.pi/4
   star.Position=UDim2.new(.5,math.cos(angle)*(28+age*90),.5,math.sin(angle)*(15+age*30))
   star.TextTransparency=math.clamp(age/.8,0,1)
  end
  local art=toast:FindFirstChild("HUDAdventureRaster") if art then art.Visible=not blocked end
 end
 local hull=gui:FindFirstChild("StatusFrame")
		local holes=hull and hull:GetAttribute("HoleCount")
		if typeof(holes)=="number" then if lastHoles~=nil and lastHoles~=holes then
 for i=math.min(5-lastHoles,5-holes)+1,math.max(5-lastHoles,5-holes) do state.Pulse("HUDHull"..i) end
 end lastHoles=holes end
		
 local rope=gui:FindFirstChild("TetherLabel",true)
 local durability=rope and tonumber((rope :: TextLabel).Text:match("(%d+)%%"))
 if durability then
  if lastRope and ((lastRope>RopeWarnings.ROPE_LOW_PERCENT and durability<=RopeWarnings.ROPE_LOW_PERCENT) or (lastRope>RopeWarnings.ROPE_CRITICAL_PERCENT and durability<=RopeWarnings.ROPE_CRITICAL_PERCENT)) then state.Pulse("TetherFrame") end
  lastRope=durability
 else lastRope=nil end
 local ammo=gui:FindFirstChild("AmmoLabel",true)
		if ammo and ammo:IsA("TextLabel") then
			if lastAmmo and lastAmmo~=ammo.Text then state.Pulse("WeaponFrame") end lastAmmo=ammo.Text
		end
		for o in smoothed do if not o:IsDescendantOf(gui) then smoothed[o]=nil end end
	end
	link(RunService.RenderStepped,render)
	function state.Destroy()
		if state.dead then return end state.dead=true state.BeforeLayout()
		for _,c in state.links do c:Disconnect() end
		for _,r in state.records do
			if r.tween then r.tween:Cancel() end if r.fadeTween then r.fadeTween:Cancel() end
			for _,c in r.links do c:Disconnect() end
			if r.closeTask then task.cancel(r.closeTask) end
			r.values:Destroy() r.fade:Destroy()
		end
		table.clear(state.base) table.clear(state.records) table.clear(smoothed)
		toast:Destroy()
		sessions[gui]=nil
	end
	link(gui.Destroying,state.Destroy)
	return state
end

function Motion.SetVisible(o: GuiObject, visible: boolean)
 local gui=o:FindFirstAncestorWhichIsA("ScreenGui")
 if not gui then o.Visible=visible return end
 local state=Motion.Start(gui,Players.LocalPlayer)
 local r=state.records[o]
 if not r then o.Visible=visible return end
 if r.closeTask then task.cancel(r.closeTask) r.closeTask=nil end
 o:SetAttribute("HUDMotionClosing",not visible)
 if visible then
  o.Visible=true r.visible=false
 else
  if r.tween then r.tween:Cancel() end if r.fadeTween then r.fadeTween:Cancel() end
  r.fadeTween=TweenService:Create(r.fade,TweenInfo.new(.12),{Value=0}) r.fadeTween:Play()
  r.closeTask=task.delay(.12,function()
   r.closeTask=nil
   if o.Parent then o.Visible=false end
  end)
 end
end
function Motion.Toggle(o: GuiObject)
 Motion.SetVisible(o, not o.Visible or o:GetAttribute("HUDMotionClosing")==true)
end
return Motion
