local g=game.Players.LocalPlayer.PlayerGui.FlyHighHUD local report={size={g.AbsoluteSize.X,g.AbsoluteSize.Y},compact=g:GetAttribute("CompactLayout"),visible={},outside={},smallButtons={}}
for _,o in g:GetChildren()do
 if o:IsA("GuiObject")and o.Visible then
  local pos=o.AbsolutePosition-g.AbsolutePosition local size=o.AbsoluteSize
  table.insert(report.visible,{name=o.Name,x=pos.X,y=pos.Y,width=size.X,height=size.Y})
  if pos.X<-.5 or pos.Y<-.5 or pos.X+size.X>g.AbsoluteSize.X+.5 or pos.Y+size.Y>g.AbsoluteSize.Y+.5 then table.insert(report.outside,o.Name)end
  if o:IsA("GuiButton")and(size.X<44 or size.Y<44)then table.insert(report.smallButtons,o.Name)end
 end
end
return report