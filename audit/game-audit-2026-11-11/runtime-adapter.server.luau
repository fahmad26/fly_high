local H=game:GetService("HttpService")local bm=_G.FlyHighBalloonManager local wm=_G.FlyHighWeaponManager local dm=_G.FlyHighDataManager
local p=game.Players:GetPlayers()[1]local fd local target local wall local saves=0 local originalSave
local f=Instance.new("BindableFunction")f.Name="__AuditControl"f.Parent=game.ServerStorage
f.OnInvoke=function(action)
 if action=="Launch"then
  fd=assert(bm.LaunchBalloon({p},p,workspace.FlyHighLobby.MatchmakingPods.Pod_C.FloorPad.Position,"Pod_C"))
  for player,item in fd.boarding do bm.FlightAction(player,"BoardReady",item.token)end
  return true
 elseif action=="Equip"then fd.root.Anchored=true return wm.TryEquip(p,fd.balloon,fd.balloon.WeaponRack1)==true
 elseif action=="Target"then
  local tool=wm.held[p].tool local muzzle=tool.Handle.MuzzleAttachment.WorldPosition
  local function part(name,pos,size)local v=Instance.new("Part")v.Name=name v.Anchored=true v.Position=pos v.Size=size v.Parent=workspace return v end
  target=Instance.new("Model")target.Name="__AuditTarget"target:SetAttribute("IsObstacle",true)target:SetAttribute("Shootable",true)target:SetAttribute("Health",10000)target.Parent=workspace.FlyHighObstacles
  local t=part("HitProxy",muzzle+Vector3.new(70,0,0),Vector3.new(5,5,5))t.Parent=target target.PrimaryPart=t
  wall=part("__AuditWall",muzzle+Vector3.new(30,0,0),Vector3.new(3,35,35))
  return {muzzle={muzzle.X,muzzle.Y,muzzle.Z},target={t.Position.X,t.Position.Y,t.Position.Z}}
 elseif action=="Read"then
  local s=wm.held[p]local origin=s.tool.Handle.MuzzleAttachment.WorldPosition local params=RaycastParams.new()params.FilterType=Enum.RaycastFilterType.Include params.FilterDescendantsInstances={wall,target}
  local hit=workspace:Raycast(origin,target.PrimaryPart.Position-origin,params)
  return {health=target:GetAttribute("Health"),ammo=s.ammo,firstHit=hit and hit.Instance.Name,saves=saves}
 elseif action=="RemoveWall"then wall.CanQuery=false return true
 elseif action=="CountSaves"then originalSave=dm.Save dm.Save=function(...)saves+=1 return originalSave(...)end return true
 elseif action=="Finish"then if originalSave then dm.Save=originalSave end return true
 end
end
