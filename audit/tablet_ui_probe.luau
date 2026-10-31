local p=game.Players.LocalPlayer local g=p.PlayerGui.FlyHighHUD
local function visible(o)
 while o and o~=g do if o:IsA("GuiObject")and not o.Visible then return false end o=o.Parent end
 return o==g and g.Enabled
end
local function bounds(o)local pos=o.AbsolutePosition-g.AbsolutePosition local s=o.AbsoluteSize return {name=o.Name,x=pos.X,y=pos.Y,w=s.X,h=s.Y}end
local report={size={g.AbsoluteSize.X,g.AbsoluteSize.Y},touch=game:GetService("UserInputService").TouchEnabled,tablet=g:GetAttribute("TabletLayout"),compact=g:GetAttribute("CompactLayout"),role=p:GetAttribute("CrewRole"),buttons={},outside={},small={},overlaps={},textOverflow={}}
for _,o in g:GetDescendants()do
 if o:IsA("GuiButton")and visible(o)and o.Name~="HUDModalScrim"then
  local b=bounds(o)table.insert(report.buttons,b)
  if b.x<-.5 or b.y<-.5 or b.x+b.w>g.AbsoluteSize.X+.5 or b.y+b.h>g.AbsoluteSize.Y+.5 then table.insert(report.outside,b.name)end
  if b.w<43.5 or b.h<43.5 then table.insert(report.small,b.name)end
 end
 if(o:IsA("TextLabel")or o:IsA("TextButton"))and visible(o)and o.Text~=""and not o.TextFits then table.insert(report.textOverflow,o.Name)end
end
for i,a in report.buttons do for j=i+1,#report.buttons do local b=report.buttons[j]
 if a.x<b.x+b.w-1 and a.x+a.w>b.x+1 and a.y<b.y+b.h-1 and a.y+a.h>b.y+1 then table.insert(report.overlaps,{a.name,b.name})end
end end
local native=p.PlayerGui:FindFirstChild("TouchGui")local nativeJump=native and native:FindFirstChild("JumpButton",true)
local stick=native and native:FindFirstChild("DynamicThumbstickFrame",true)
report.nativeJumpVisible=nativeJump and nativeJump.Visible
report.nativeThumbstickVisible=stick and stick.Visible
local jump=g.JumpPanel.JumpButton report.jump={visible=visible(jump),active=jump.Active,size={jump.AbsoluteSize.X,jump.AbsoluteSize.Y},corner=jump:FindFirstChildOfClass("UICorner").CornerRadius.Scale}
return report
