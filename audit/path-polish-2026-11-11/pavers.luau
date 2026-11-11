local L=workspace.FlyHighLobby local M=L.PromenadeGarden local junctions={}for _,p in L.DockPromenade:GetChildren()do if p.Name=="Junction"then table.insert(junctions,p.Position)end end
local rng=Random.new(981)local count=0
for _,base in L.DockPromenade:GetChildren()do
 if base.Name:match("^Paving_")then
  base.Color=Color3.fromRGB(107,106,93)
  local near=false for _,q in junctions do if Vector2.new(base.Position.X-q.X,base.Position.Z-q.Z).Magnitude<5 then near=true end end
  if not near then
   local cols=(tonumber(base.Name:match("%d+"))or 0)%2==0 and 3 or 4
   for col=1,cols do
    local width=8.8/cols local t=Instance.new("Part")t.Name="HandCutPaver"t.Size=Vector3.new(width-.07,.028,base.Size.Z-.10)
    t.CFrame=base.CFrame*CFrame.new(-4.4+width*(col-.5),.186,0)t.Color=Color3.fromRGB(188+rng:NextInteger(-15,13),174+rng:NextInteger(-10,12),144+rng:NextInteger(-9,12))t.Material=Enum.Material.Sandstone t.Anchored=true t.CanCollide=false t.CanTouch=false t.CanQuery=false t.CastShadow=false t.Parent=M count+=1
   end
  end
 end
end return {pavers=count}
