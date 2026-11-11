local L=workspace.FlyHighLobby local road=L.DockPromenade local garden=L.PromenadeGarden
local old=L:FindFirstChild("PromenadeSurface")if old then old:Destroy()end
for _,p in road:GetChildren()do if p:IsA("BasePart")then p.Transparency=1 end end
for _,o in garden:GetChildren()do if o.Name=="HandCutPaver"or o.Name:match("^DockWayfinder")or o.Name=="MosaicBorder"or o.Name=="DockGuideStone"then o:Destroy()end end
local m=Instance.new("Model")m.Name="PromenadeSurface"local count=0
local sand=Color3.fromRGB(191,175,143)local edge=Color3.fromRGB(100,109,105)local grout=Color3.fromRGB(144,137,119)
local function make(class,size,cf,color,name)
 local p=Instance.new(class)p.Name=name or "FittedStone"p.Size=size p.CFrame=cf p.Color=color p.Material=Enum.Material.SmoothPlastic
 p.Anchored=true p.CanCollide=false p.CanTouch=false p.CanQuery=false p.CastShadow=false p.TopSurface=Enum.SurfaceType.Smooth p.BottomSurface=Enum.SurfaceType.Smooth p.Parent=m count+=1 return p
end
local function triangle(a,b,c,color,name)
 local ab,ac,bc=b-a,c-a,c-b
 local ab2,ac2,bc2=ab:Dot(ab),ac:Dot(ac),bc:Dot(bc)
 if ab2>ac2 and ab2>bc2 then c,a=a,c elseif ac2>bc2 and ac2>ab2 then a,b=b,a end
 ab,ac,bc=b-a,c-a,c-b
 local right=ac:Cross(ab).Unit local back=bc.Unit local up=bc:Cross(right).Unit local height=math.abs(ab:Dot(up))
 local s1=math.abs(ab:Dot(back))local s2=math.abs(ac:Dot(back))
 if name=="ContinuousBed"then a-=Vector3.yAxis*.09 b-=Vector3.yAxis*.09 c-=Vector3.yAxis*.09 end
 if height>.002 and s1>.002 then make("WedgePart",Vector3.new(.07,height,s1),CFrame.fromMatrix((a+b)/2,right,up,back),color,name)end
 if height>.002 and s2>.002 then make("WedgePart",Vector3.new(.07,height,s2),CFrame.fromMatrix((a+c)/2,-right,up,-back),color,name)end
end
local function point(r,a,y)return Vector3.new(math.sin(a)*r,y or 10.34,15-math.cos(a)*r)end
local function quad(r1,r2,a,b,color,name)
 local p,q,r,s=point(r1,a),point(r2,a),point(r2,b),point(r1,b)
 triangle(p,q,r,color,name)triangle(p,r,s,color,name)
end
-- True annular trapezoids share vertices: no rectangular teeth, no circular junction patch.
local turnRadius=5
local endRadius=math.sqrt(75*75-turnRadius*turnRadius)
local limit=math.acos(turnRadius/75)
local step=2*limit/24
for i=0,23 do
 local a=-limit+i*step local b=a+step
 quad(65.5,74.5,a,b,grout,"ContinuousBed")
 for row=0,2 do
  local r1=65.5+row*3+.045 local r2=r1+2.91
  local shade=(i+row)%3
  quad(r1,r2,a+math.rad(.035),b-math.rad(.035),sand:Lerp(Color3.fromRGB(213,198,170),shade*.13),"CurvedPaver")
 end
 -- Border segments are cut open at branches, rather than running across the intersection.
 local cuts={a,b}
 for _,center in ipairs({-90,-45,0,45,90})do
  for _,off in ipairs({-4.3,4.3})do local v=math.rad(center+off)if v>a and v<b then table.insert(cuts,v)end end
 end
 table.sort(cuts)
 for j=1,#cuts-1 do
  local lo,hi=cuts[j],cuts[j+1]local mid=math.deg((lo+hi)/2)
  local outer=true for _,center in ipairs({-90,-45,0,45,90})do if math.abs(mid-center)<4.3 then outer=false end end
  if outer then quad(74.5,74.95,lo,hi,edge,"OuterCurb")end
  if math.abs(mid)>4.3 then quad(65.05,65.5,lo,hi,edge,"InnerCurb")end
 end
end
local function straight(a,b,label)
 local center=(a+b)/2 local dir=(b-a).Unit local frame=CFrame.lookAt(center,b)
 local len=(b-a).Magnitude local n=math.ceil(len/3.4)
 for j=0,n-1 do for col=0,2 do
  local c=frame*CFrame.new((col-1)*3,0,-len/2+(j+.5)*len/n)
  make("Part",Vector3.new(2.92,.07,len/n-.07),c,sand:Lerp(Color3.fromRGB(213,198,170),(j+col)%3*.13),"StraightPaver")
 end end
 for _,side in ipairs({-1,1})do make("Part",Vector3.new(.45,.07,len),frame*CFrame.new(side*4.72,0,0),edge,"StraightCurb")end
end
-- A/E have only one incoming tangent. Use tangent-matched elbows, not a T branch.
for _,side in ipairs({-1,1})do
 local center=Vector3.new(side*endRadius,10.34,10)
 local start=math.asin(turnRadius/75)
 local function elbow(r,a)
  return center+Vector3.new(-side*math.cos(a)*r,0,math.sin(a)*r)
 end
 local function strip(r1,r2,a,b,color,name)
  local p,q,r,s=elbow(r1,a),elbow(r2,a),elbow(r2,b),elbow(r1,b)
  triangle(p,q,r,color,name)triangle(p,r,s,color,name)
 end
 for n=0,11 do
  local a=start+(math.pi/2-start)*n/12
  local b=start+(math.pi/2-start)*(n+1)/12
  strip(.5,9.5,a,b,grout,"ContinuousBed")
  for row=0,2 do
   strip(.5+row*3+.045,.5+(row+1)*3-.045,a+.0006,b-.0006,
    sand:Lerp(Color3.fromRGB(213,198,170),(n+row)%3*.13),"ElbowPaver")
  end
  strip(.05,.5,a,b,edge,"ElbowCurb")
  strip(9.5,9.95,a,b,edge,"ElbowCurb")
 end
end
straight(Vector3.new(0,10.40,23),Vector3.new(0,10.40,-51),"Main")
for i=1,5 do
 local a=math.rad((i-3)*45)
 local p=point((i==1 or i==5) and endRadius or 73.8,a,10.42)local q=point(81.4,a,10.42)
 straight(p,q,"Branch")
 local mark=make("Part",Vector3.new(2.2,.06,2.2),CFrame.lookAt(point(77.6,a,10.50),point(79,a,10.50)),Color3.fromRGB(48,76,81),"DockLetter_"..i)
 local gui=Instance.new("SurfaceGui")gui.Face=Enum.NormalId.Top gui.CanvasSize=Vector2.new(128,128)gui.Parent=mark
 local t=Instance.new("TextLabel")t.Size=UDim2.fromScale(1,1)t.BackgroundTransparency=1 t.Font=Enum.Font.FredokaOne t.Text=string.char(64+i)t.TextColor3=Color3.fromRGB(251,232,193)t.TextScaled=true t.Parent=gui
end
m.Parent=L return {surfaceParts=count,method="Vertex-matched trapezoids, clipped borders, no CSG",roadColliderWidth=9}
