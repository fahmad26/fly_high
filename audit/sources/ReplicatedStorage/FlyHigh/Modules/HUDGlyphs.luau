-- Resolution-independent HUD silhouettes; no web asset is required for input icons.
local Glyphs={}
function Glyphs.Draw(parent,key)
 local root=Instance.new("Frame")root.Name="HUDGlyph"root.Size=UDim2.fromScale(1,1)root.BackgroundTransparency=1 root.Parent=parent
 local white=Color3.fromRGB(250,253,255)
 local function rect(x,y,w,h,rotation,round)
  local f=Instance.new("Frame")f.BorderSizePixel=0 f.BackgroundColor3=white
  f.AnchorPoint=Vector2.new(.5,.5)f.Position=UDim2.fromScale(x,y)f.Size=UDim2.fromScale(w,h)f.Rotation=rotation or 0 f.Parent=root
  if round then local c=Instance.new("UICorner",f)c.CornerRadius=UDim.new(round,0)end return f
 end
 local function ring(x,y,w,h)
  local f=rect(x,y,w,h,0,.5)f.BackgroundTransparency=1
  local s=Instance.new("UIStroke",f)s.Color=white s.Thickness=2.3 return f
 end
 local function arrow(down)
  local y=down and .67 or .33
  rect(.5,.51,.12,.52,0,.2)
  rect(.38,y,.12,.34,down and -45 or 45,.2)rect(.62,y,.12,.34,down and 45 or -45,.2)
 end
 if key=="jump"or key=="climb"then arrow(false)
 elseif key=="descend"or key=="drop"then arrow(true)if key=="drop"then rect(.5,.9,.65,.08,0,.3)end
 elseif key=="fire"or key=="aim"then
  ring(.5,.5,.52,.52)for _,v in {{.5,.18,.07,.24},{.5,.82,.07,.24},{.18,.5,.24,.07},{.82,.5,.24,.07}}do rect(table.unpack(v))end
  rect(.5,.5,.1,.1,0,.5)
 elseif key=="shop"then
  local b=rect(.5,.58,.65,.57,0,.12)b.BackgroundTransparency=1 local s=Instance.new("UIStroke",b)s.Color=white s.Thickness=2.8
  ring(.5,.31,.3,.3)rect(.5,.58,.13,.38,0,.2)rect(.5,.58,.38,.13,0,.2)
 elseif key=="kit"then
  ring(.5,.5,.78,.78)rect(.5,.5,.18,.52,0,.1)rect(.5,.5,.52,.18,0,.1)
 elseif key=="ping"then
  local b=rect(.5,.45,.76,.58,0,.2)b.BackgroundTransparency=1 local s=Instance.new("UIStroke",b)s.Color=white s.Thickness=2.6
  rect(.29,.8,.1,.25,24,.1)for _,x in {.29,.5,.71}do rect(x,.45,.08,.08,0,.5)end
 elseif key=="sound"or key=="muted"then
  rect(.25,.5,.19,.26,0,.1)rect(.42,.5,.31,.43,45,.1)
  if key=="muted"then rect(.72,.5,.08,.43,40,.1)rect(.72,.5,.08,.43,-40,.1)
  else
   local t=Instance.new("TextLabel")t.Text="))"t.Font=Enum.Font.GothamBold t.TextScaled=true t.BackgroundTransparency=1 t.TextColor3=white t.Size=UDim2.fromScale(.4,.75)t.Position=UDim2.fromScale(.58,.1)t.Parent=root
  end
 elseif key=="helm"then
  ring(.5,.5,.55,.55)rect(.5,.5,.13,.13,0,.5)
  for _,a in {0,60,120}do rect(.5,.5,.07,.92,a,.2)end
 elseif key=="release"then
  rect(.27,.5,.08,.67,0,.2)rect(.5,.5,.62,.1,0,.2)rect(.71,.38,.1,.36,-45,.2)rect(.71,.62,.1,.36,45,.2)
 elseif key=="gas"then
  rect(.5,.66,.62,.53,0,.5)rect(.48,.35,.35,.52,20,.15)
  rect(.31,.54,.29,.33,-25,.12)rect(.67,.47,.26,.43,30,.12)
  rect(.5,.72,.2,.29,20,.5).BackgroundColor3=Color3.fromRGB(255,157,41)
 elseif key=="reload"then
  ring(.5,.5,.63,.63)rect(.72,.21,.3,.1,35,.2)rect(.82,.32,.1,.3,-10,.2)
 elseif key=="attach"or key=="detach"or key=="rope"then
  local a=ring(.38,.4,.4,.6)a.Rotation=35 local b=ring(.62,.62,.4,.6)b.Rotation=35
  if key=="detach"then rect(.5,.5,.1,1,45,.1)end
 elseif key=="repair"then
  rect(.5,.5,.8,.37,-35,.2)for _,x in {.3,.7}do rect(x,.5,.04,.04,0,.5).BackgroundColor3=Color3.fromRGB(50,125,180)end
 elseif key=="rescue"then
  ring(.28,.62,.28,.28)ring(.71,.62,.28,.28)rect(.5,.4,.12,.5,0,.1)rect(.4,.24,.1,.28,-45,.1)rect(.6,.24,.1,.28,45,.1)
 elseif key=="weapon"then
  rect(.5,.38,.79,.24,0,.1)rect(.3,.63,.18,.4,-12,.1)rect(.59,.56,.25,.06,0,.2)
 elseif key=="warning"then
  ring(.5,.5,.84,.84)rect(.5,.4,.12,.4,0,.4)rect(.5,.73,.12,.12,0,.5)
 elseif key=="close"then rect(.5,.5,.12,.8,45,.2)rect(.5,.5,.12,.8,-45,.2)
 else ring(.5,.5,.7,.7)end
 return root
end
return Glyphs
