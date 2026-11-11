local L=workspace.FlyHighLobby local old=L:FindFirstChild("DockPromenade")if old then old:Destroy()end local M=Instance.new("Model")M.Name="DockPromenade"M.Parent=L local report={paths={}}local routes={}
table.insert(routes,{a=Vector3.new(-70,0,15),b=Vector3.new(-69.85012817382812,0,10.421780586242676),kind="Arc"})
table.insert(routes,{a=Vector3.new(-69.85012817382812,0,10.421780586242676),b=Vector3.new(-69.40113830566406,0,5.863166332244873),kind="Arc"})
table.insert(routes,{a=Vector3.new(-69.40113830566406,0,5.863166332244873),b=Vector3.new(-68.65496826171875,0,1.3436774015426636),kind="Arc"})
table.insert(routes,{a=Vector3.new(-68.65496826171875,0,1.3436774015426636),b=Vector3.new(-67.61480712890625,0,-3.117333173751831),kind="Arc"})
table.insert(routes,{a=Vector3.new(-67.61480712890625,0,-3.117333173751831),b=Vector3.new(-66.28511047363281,0,-7.500762462615967),kind="Arc"})
table.insert(routes,{a=Vector3.new(-66.28511047363281,0,-7.500762462615967),b=Vector3.new(-64.67156982421875,0,-11.787839889526367),kind="Arc"})
table.insert(routes,{a=Vector3.new(-64.67156982421875,0,-11.787839889526367),b=Vector3.new(-62.78109359741211,0,-15.96020793914795),kind="Arc"})
table.insert(routes,{a=Vector3.new(-62.78109359741211,0,-15.96020793914795),b=Vector3.new(-60.62177658081055,0,-20),kind="Arc"})
table.insert(routes,{a=Vector3.new(-60.62177658081055,0,-20),b=Vector3.new(-58.20287322998047,0,-23.889915466308594),kind="Arc"})
table.insert(routes,{a=Vector3.new(-58.20287322998047,0,-23.889915466308594),b=Vector3.new(-55.534732818603516,0,-27.613300323486328),kind="Arc"})
table.insert(routes,{a=Vector3.new(-55.534732818603516,0,-27.613300323486328),b=Vector3.new(-52.628787994384766,0,-31.154207229614258),kind="Arc"})
table.insert(routes,{a=Vector3.new(-52.628787994384766,0,-31.154207229614258),b=Vector3.new(-49.497474670410156,0,-34.497474670410156),kind="Arc"})
table.insert(routes,{a=Vector3.new(-49.497474670410156,0,-34.497474670410156),b=Vector3.new(-46.154205322265625,0,-37.628787994384766),kind="Arc"})
table.insert(routes,{a=Vector3.new(-46.154205322265625,0,-37.628787994384766),b=Vector3.new(-42.61330032348633,0,-40.534732818603516),kind="Arc"})
table.insert(routes,{a=Vector3.new(-42.61330032348633,0,-40.534732818603516),b=Vector3.new(-38.889915466308594,0,-43.20287322998047),kind="Arc"})
table.insert(routes,{a=Vector3.new(-38.889915466308594,0,-43.20287322998047),b=Vector3.new(-35,0,-45.62177658081055),kind="Arc"})
table.insert(routes,{a=Vector3.new(-35,0,-45.62177658081055),b=Vector3.new(-30.960208892822266,0,-47.78109359741211),kind="Arc"})
table.insert(routes,{a=Vector3.new(-30.960208892822266,0,-47.78109359741211),b=Vector3.new(-26.787839889526367,0,-49.671566009521484),kind="Arc"})
table.insert(routes,{a=Vector3.new(-26.787839889526367,0,-49.671566009521484),b=Vector3.new(-22.500762939453125,0,-51.28511047363281),kind="Arc"})
table.insert(routes,{a=Vector3.new(-22.500762939453125,0,-51.28511047363281),b=Vector3.new(-18.117332458496094,0,-52.61480712890625),kind="Arc"})
table.insert(routes,{a=Vector3.new(-18.117332458496094,0,-52.61480712890625),b=Vector3.new(-13.656322479248047,0,-53.65496826171875),kind="Arc"})
table.insert(routes,{a=Vector3.new(-13.656322479248047,0,-53.65496826171875),b=Vector3.new(-9.136833190917969,0,-54.40114212036133),kind="Arc"})
table.insert(routes,{a=Vector3.new(-9.136833190917969,0,-54.40114212036133),b=Vector3.new(-4.578218936920166,0,-54.85012435913086),kind="Arc"})
table.insert(routes,{a=Vector3.new(-4.578218936920166,0,-54.85012435913086),b=Vector3.new(0,0,-55),kind="Arc"})
table.insert(routes,{a=Vector3.new(0,0,-55),b=Vector3.new(4.578218936920166,0,-54.85012435913086),kind="Arc"})
table.insert(routes,{a=Vector3.new(4.578218936920166,0,-54.85012435913086),b=Vector3.new(9.136833190917969,0,-54.40114212036133),kind="Arc"})
table.insert(routes,{a=Vector3.new(9.136833190917969,0,-54.40114212036133),b=Vector3.new(13.656322479248047,0,-53.65496826171875),kind="Arc"})
table.insert(routes,{a=Vector3.new(13.656322479248047,0,-53.65496826171875),b=Vector3.new(18.117332458496094,0,-52.61480712890625),kind="Arc"})
table.insert(routes,{a=Vector3.new(18.117332458496094,0,-52.61480712890625),b=Vector3.new(22.500762939453125,0,-51.28511047363281),kind="Arc"})
table.insert(routes,{a=Vector3.new(22.500762939453125,0,-51.28511047363281),b=Vector3.new(26.787839889526367,0,-49.671566009521484),kind="Arc"})
table.insert(routes,{a=Vector3.new(26.787839889526367,0,-49.671566009521484),b=Vector3.new(30.960208892822266,0,-47.78109359741211),kind="Arc"})
table.insert(routes,{a=Vector3.new(30.960208892822266,0,-47.78109359741211),b=Vector3.new(35,0,-45.62177658081055),kind="Arc"})
table.insert(routes,{a=Vector3.new(35,0,-45.62177658081055),b=Vector3.new(38.889915466308594,0,-43.20287322998047),kind="Arc"})
table.insert(routes,{a=Vector3.new(38.889915466308594,0,-43.20287322998047),b=Vector3.new(42.61330032348633,0,-40.534732818603516),kind="Arc"})
table.insert(routes,{a=Vector3.new(42.61330032348633,0,-40.534732818603516),b=Vector3.new(46.154205322265625,0,-37.628787994384766),kind="Arc"})
table.insert(routes,{a=Vector3.new(46.154205322265625,0,-37.628787994384766),b=Vector3.new(49.497474670410156,0,-34.497474670410156),kind="Arc"})
table.insert(routes,{a=Vector3.new(49.497474670410156,0,-34.497474670410156),b=Vector3.new(52.628787994384766,0,-31.154207229614258),kind="Arc"})
table.insert(routes,{a=Vector3.new(52.628787994384766,0,-31.154207229614258),b=Vector3.new(55.534732818603516,0,-27.613300323486328),kind="Arc"})
table.insert(routes,{a=Vector3.new(55.534732818603516,0,-27.613300323486328),b=Vector3.new(58.20287322998047,0,-23.889915466308594),kind="Arc"})
table.insert(routes,{a=Vector3.new(58.20287322998047,0,-23.889915466308594),b=Vector3.new(60.62177658081055,0,-20),kind="Arc"})
table.insert(routes,{a=Vector3.new(60.62177658081055,0,-20),b=Vector3.new(62.78109359741211,0,-15.96020793914795),kind="Arc"})
table.insert(routes,{a=Vector3.new(62.78109359741211,0,-15.96020793914795),b=Vector3.new(64.67156982421875,0,-11.787839889526367),kind="Arc"})
table.insert(routes,{a=Vector3.new(64.67156982421875,0,-11.787839889526367),b=Vector3.new(66.28511047363281,0,-7.500762462615967),kind="Arc"})
table.insert(routes,{a=Vector3.new(66.28511047363281,0,-7.500762462615967),b=Vector3.new(67.61480712890625,0,-3.117333173751831),kind="Arc"})
table.insert(routes,{a=Vector3.new(67.61480712890625,0,-3.117333173751831),b=Vector3.new(68.65496826171875,0,1.3436774015426636),kind="Arc"})
table.insert(routes,{a=Vector3.new(68.65496826171875,0,1.3436774015426636),b=Vector3.new(69.40113830566406,0,5.863166332244873),kind="Arc"})
table.insert(routes,{a=Vector3.new(69.40113830566406,0,5.863166332244873),b=Vector3.new(69.85012817382812,0,10.421780586242676),kind="Arc"})
table.insert(routes,{a=Vector3.new(69.85012817382812,0,10.421780586242676),b=Vector3.new(70,0,15),kind="Arc"})
table.insert(routes,{a=Vector3.new(0,0,23),b=Vector3.new(0,0,-55),kind="Main"})
table.insert(routes,{a=Vector3.new(-70,0,15),b=Vector3.new(-81,0,15),kind="Branch_Pod_A"})
table.insert(routes,{a=Vector3.new(-49.497474670410156,0,-34.497474670410156),b=Vector3.new(-57.27565002441406,0,-42.27565002441406),kind="Branch_Pod_B"})
table.insert(routes,{a=Vector3.new(0,0,-55),b=Vector3.new(0,0,-66),kind="Branch_Pod_C"})
table.insert(routes,{a=Vector3.new(49.497474670410156,0,-34.497474670410156),b=Vector3.new(57.27565002441406,0,-42.27565002441406),kind="Branch_Pod_D"})
table.insert(routes,{a=Vector3.new(70,0,15),b=Vector3.new(81,0,15),kind="Branch_Pod_E"})
local arc={}for i=0,48 do local a=math.rad(-90+i*180/48)arc[i+1]=Vector3.new(math.sin(a)*70,0,15-math.cos(a)*70)end
local function part(name,size,cf,color,material,collide)
 local p=Instance.new("Part")p.Name=name p.Size=size p.CFrame=cf p.Anchored=true p.Color=color p.Material=material p.CanCollide=collide p.CanTouch=false p.CanQuery=collide p.CastShadow=false p.TopSurface=Enum.SurfaceType.Smooth p.BottomSurface=Enum.SurfaceType.Smooth p.Parent=M return p
end
local stone={Color3.fromRGB(199,184,148),Color3.fromRGB(206,191,157),Color3.fromRGB(193,180,148)}
local serial=0
for _,r in routes do
 local length=(r.b-r.a).Magnitude local count=math.ceil(length/4.6)
 for j=1,count do
  local a=r.a:Lerp(r.b,(j-1)/count)local b=r.a:Lerp(r.b,j/count)local mid=(a+b)/2 local cf=CFrame.lookAt(Vector3.new(mid.X,10.10,mid.Z),Vector3.new(b.X,10.10,b.Z))
  serial+=1 part("Paving_"..serial,Vector3.new(9,.32,(b-a).Magnitude+.04),cf,Color3.fromRGB(204,190,157),Enum.Material.SmoothPlastic,true)
 end
 -- Low, nonblocking edging: do not make players jump to enter the path.
 local mid=(r.a+r.b)/2 local cf=CFrame.lookAt(Vector3.new(mid.X,10.14,mid.Z),Vector3.new(r.b.X,10.14,r.b.Z))
 for _,side in {-1,1}do part("FlushStoneBorder",Vector3.new(.45,.34,length+.2),cf*CFrame.new(side*4.72,0,0),Color3.fromRGB(139,133,112),Enum.Material.Limestone,false)end
 table.insert(report.paths,{kind=r.kind,a={r.a.X,r.a.Z},b={r.b.X,r.b.Z},width=9,top=10.26})
end
-- Discs hide angled seams and make clear circular junctions at each fork.
for _,i in {1,13,25,37,49}do local q=arc[i]local p=part("Junction",Vector3.new(.34,10,10),CFrame.new(q.X,10.10,q.Z)*CFrame.Angles(0,0,math.pi/2),stone[2],Enum.Material.Sandstone,true)p.Shape=Enum.PartType.Cylinder end

M=workspace.FlyHighLobby.DockPromenade local junctions={}local paving={}local removed=0
for _,o in M:GetChildren()do if o.Name=="Junction"then table.insert(junctions,o.Position)table.insert(paving,o)elseif o.Name:match("^Paving_")then table.insert(paving,o)end end
for _,o in M:GetChildren()do if o.Name=="FlushStoneBorder"then local near=false for _,q in junctions do if Vector2.new(o.Position.X-q.X,o.Position.Z-q.Z).Magnitude<8 then near=true end end if near then o:Destroy()removed+=1 elseif o.Size.Z>60 then o.Size-=Vector3.new(0,0,7)o.CFrame*=CFrame.new(0,0,3.5)end end end

return {parts=#M:GetChildren(),unions=0,reason="Avoid incomplete coplanar CSG render; use solid simple slabs and matte paving"}
