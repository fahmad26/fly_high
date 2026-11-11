local M=workspace.FlyHighLobby.DockPromenade local junctions={}local paving={}local removed=0
for _,o in M:GetChildren()do if o.Name=="Junction"then table.insert(junctions,o.Position)table.insert(paving,o)elseif o.Name:match("^Paving_")then table.insert(paving,o)end end
for _,o in M:GetChildren()do if o.Name=="FlushStoneBorder"then local near=false for _,q in junctions do if Vector2.new(o.Position.X-q.X,o.Position.Z-q.Z).Magnitude<8 then near=true end end if near then o:Destroy()removed+=1 elseif o.Size.Z>60 then o.Size-=Vector3.new(0,0,7)o.CFrame*=CFrame.new(0,0,3.5)end end end
local root=paving[1]local rest={}for i=2,#paving do table.insert(rest,paving[i])end
local union=root:UnionAsync(rest,Enum.CollisionFidelity.Default,Enum.RenderFidelity.Precise)union.Name="ContinuousPavement"union.Anchored=true union.CanCollide=true union.CanTouch=false union.CanQuery=true union.CastShadow=false union.UsePartColor=true union.Color=Color3.fromRGB(204,190,157)union.Material=Enum.Material.Sandstone union.Parent=M
for _,o in paving do o:Destroy()end
return {pavingCount=#paving,removedCurbSegments=removed,finalParts=#M:GetChildren()}
