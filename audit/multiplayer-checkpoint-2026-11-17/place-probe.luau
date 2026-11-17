-- Read-only manifest for comparison before and after opening the saved place.
local H=game:GetService("HttpService")
local SES=game:GetService("ScriptEditorService")
local out={sources={},models={},prompts={},terrain={},environment={}}
local function n(v) return math.round(v*10000)/10000 end
local function cf(v) local a={v:GetComponents()} for i,x in a do a[i]=n(x) end return a end
for _,root in {game.ReplicatedStorage,game.ServerScriptService,game.StarterPlayer} do
 for _,o in root:GetDescendants() do
  if o:IsA("LuaSourceContainer") then
   local source=SES:GetEditorSource(o) local hash=5381
   for i=1,#source do hash=(hash*33+string.byte(source,i))%4294967296 end
   table.insert(out.sources,{path=o:GetFullName(),class=o.ClassName,bytes=#source,checksum=hash})
  end
 end
end
for _,root in {workspace.FlyHighLobby,workspace.CloudPalace,game.ReplicatedStorage.FlyHigh.Templates} do
 local count,parts,hash=0,0,5381
 local rows={}
 for _,o in root:GetDescendants() do
  count+=1
  if o:IsA("BasePart") then
   parts+=1
   local row={o:GetFullName(),o.ClassName,cf(o.CFrame),{n(o.Size.X),n(o.Size.Y),n(o.Size.Z)},o.CanCollide,o.CanTouch,o.CanQuery,o.Anchored,n(o.Transparency),tostring(o.Material),tostring(o.Color)}
   if o:IsA("MeshPart") then table.insert(row,o.MeshId) table.insert(row,o.TextureID) end
   table.insert(rows,H:JSONEncode(row))
  elseif o:IsA("ProximityPrompt") then
   table.insert(out.prompts,{path=o:GetFullName(),style=tostring(o.Style),enabled=o.Enabled,key=tostring(o.KeyboardKeyCode),hold=o.HoldDuration,distance=o.MaxActivationDistance,text=o.ActionText})
  end
 end
 table.sort(rows)
 for _,row in rows do for i=1,#row do hash=(hash*33+string.byte(row,i))%4294967296 end end
 table.insert(out.models,{path=root:GetFullName(),descendants=count,parts=parts,geometryChecksum=hash})
end
table.sort(out.sources,function(a,b)return a.path<b.path end)
table.sort(out.prompts,function(a,b)return a.path<b.path end)
local terrain=workspace.Terrain
local materials,occupancy=terrain:ReadVoxels(Region3.new(Vector3.new(-256,-16,-256),Vector3.new(256,80,256)):ExpandToGrid(4),4)
local hash=5381 local occupied=0
for x=1,#materials do
 for y=1,#materials[x] do
  for z=1,#materials[x][y] do
   local m=materials[x][y][z].Value local occ=math.round(occupancy[x][y][z]*10000)
   hash=(hash*33+m)%4294967296 hash=(hash*33+occ)%4294967296
   if occ>0 then occupied+=1 end
  end
 end
 if x%16==0 then task.wait() end
end
out.terrain={region={-256,-16,-256,256,80,256},resolution=4,occupied=occupied,checksum=hash,decoration=terrain.Decoration,waterTransparency=terrain.WaterTransparency}
out.environment={lightingStyle=tostring(game.Lighting.LightingStyle),brightness=game.Lighting.Brightness,clockTime=game.Lighting.ClockTime,streaming=workspace.StreamingEnabled,autoJump=game.StarterPlayer.AutoJumpEnabled,orientation=tostring(game.StarterGui.ScreenOrientation)}
return H:JSONEncode(out)
