local Run=game:GetService("RunService") local L=game:GetService("Lighting")
local q={library=require(game.ReplicatedStorage.FlyHigh.Modules.BiomeScenery),results={},root=Instance.new("Folder"),fov=workspace.CurrentCamera.FieldOfView,started=os.clock()}
q.root.Name="_SceneryConsistencyQA" q.root.Parent=workspace _G.HabitatQA=q
function q.show(index,km,position,target)
 if q.scene then q.scene:Destroy() end q.scene,q.update=q.library.Build(index) q.scene.Parent=q.root q.km=km q.target=CFrame.lookAt(position,target)
 local profiles={{6.8,2.5,Color3.fromRGB(150,140,120),Color3.fromRGB(120,120,120)},{19.55,1.3,Color3.fromRGB(107,109,155),Color3.fromRGB(122,123,164)},{17.8,2,Color3.fromRGB(180,96,78),Color3.fromRGB(134,110,108)},{23.5,1.05,Color3.fromRGB(82,101,150),Color3.fromRGB(104,116,153)},{8.55,3.15,Color3.fromRGB(164,152,151),Color3.fromRGB(118,112,130)}}
 local p=profiles[index] L.ClockTime=p[1] L.Brightness=p[2] L.OutdoorAmbient=p[3] L.Ambient=p[4]
 local at=L:FindFirstChildOfClass("Atmosphere") if at then at.Density=.3 at.Haze=0 end
 local stats={index=index,km=km,parts=0,meshes=0,shared=0,families={},badPhysics=0,scripts=0,identityMismatch=0,targetFlags=0,minimumRadius=math.huge,conservativeClearance=math.huge}
 for _,d in q.scene:GetDescendants() do
  if d:IsA("BasePart") then stats.parts+=1 if d:IsA("MeshPart") then stats.meshes+=1 end if d.CanCollide or d.CanTouch or d.CanQuery then stats.badPhysics+=1 end
   if d:GetAttribute("SceneryOnly") then local radius=Vector2.new(d.Position.X,d.Position.Z).Magnitude stats.minimumRadius=math.min(stats.minimumRadius,radius) stats.conservativeClearance=math.min(stats.conservativeClearance,radius-math.sqrt(d.Size.X^2+d.Size.Z^2)/2) end
  elseif d:IsA("LuaSourceContainer") then stats.scripts+=1 end
  if d:GetAttribute("IsObstacle") or d:GetAttribute("Shootable") then stats.targetFlags+=1 end
  if d:IsA("Model") and d:GetAttribute("SharedArtFamily") then
   local family=d:GetAttribute("SharedArtFamily") stats.shared+=1 stats.families[family]=(stats.families[family] or 0)+1
   local template=game.ReplicatedStorage.FlyHigh.Templates.ObstacleMeshes[family]
   local ids={} for _,mesh in template:GetDescendants() do if mesh:IsA("MeshPart") then ids[mesh.MeshId]=true end end
   for _,mesh in d:GetDescendants() do if mesh:IsA("MeshPart") and not ids[mesh.MeshId] then stats.identityMismatch+=1 end end
  end
 end
 table.insert(q.results,stats) return stats
end
Run:BindToRenderStep("_SceneryConsistencyQA",Enum.RenderPriority.Last.Value+1,function() if q.update then q.update(q.km,os.clock()-q.started,1) end local c=workspace.CurrentCamera c.CameraType=Enum.CameraType.Scriptable c.FieldOfView=60 if q.target then c.CFrame=q.target end end)
return "ready"
