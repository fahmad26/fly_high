local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local Debris=game:GetService("Debris")
local Config=require(RS.FlyHigh.Modules.FlyHighConfig)
local U=require(script.Parent.ServerUtils)
local remotes=RS.FlyHigh.Remotes
local Manager={held={},racks=setmetatable({},{__mode="k"})}
_G.FlyHighWeaponManager=Manager
local function state(s)
 s.tool:SetAttribute("CurrentMag",s.ammo)
 s.tool:SetAttribute("Reloading",s.reloading==true)
end
function Manager.CleanupPlayer(p)
 local s=Manager.held[p]
 if not s then return end
 Manager.held[p]=nil
 s.tool:Destroy()
 if s.rack.Parent then
  s.rack:SetAttribute("StoredAmmo",s.ammo)
  s.rack:SetAttribute("StoredLastShot",s.lastShot)
  s.rack:SetAttribute("StoredReloadEnds",s.reloadEnds or 0)
  s.rack:SetAttribute("IsOccupied",true) s.rack.PickupPrompt.Enabled=true
 end
end
function Manager.CleanupBalloon(b)
 for p,s in pairs(table.clone(Manager.held)) do if s.balloon==b then Manager.CleanupPlayer(p) end end
end
function Manager.SetupWeaponRacks(b,upgrade)
 for i=1,2 do
  local rack=b:FindFirstChild("WeaponRack"..i)
  local kind=upgrade and "AK47" or "Pistol"
  if rack:GetAttribute("CurrentWeapon")~=kind then
   rack:SetAttribute("StoredAmmo",nil) rack:SetAttribute("StoredReloadEnds",nil) rack:SetAttribute("StoredLastShot",nil)
  end
  rack:SetAttribute("CurrentWeapon",kind)
  local prompt=rack:FindFirstChild("PickupPrompt") or Instance.new("ProximityPrompt",rack)
  prompt.Name="PickupPrompt" prompt.ActionText="Ambil "..kind prompt.ObjectText="Rak Senjata "..i
  prompt.HoldDuration=0.2 prompt.MaxActivationDistance=8 prompt.RequiresLineOfSight=false
  if Manager.racks[rack] then continue end
  Manager.racks[rack]=true rack:SetAttribute("IsOccupied",true)
  prompt.Triggered:Connect(function(p)
   if not U.CrewNear(p,b,rack,10) or Manager.held[p] or not rack:GetAttribute("IsOccupied") then return end
   local weaponType=rack:GetAttribute("CurrentWeapon")
   local cfg=Config.WEAPONS[weaponType]
   local tool=RS.FlyHigh.Templates.Weapons[weaponType]:Clone()
   tool.CanBeDropped=false
   for k,v in pairs(cfg) do if k~="Name" then tool:SetAttribute(k,v) end end
   tool:SetAttribute("WeaponType",weaponType)
   local s={tool=tool,ammo=rack:GetAttribute("StoredAmmo") or cfg.MagSize,cfg=cfg,rack=rack,balloon=b,lastShot=rack:GetAttribute("StoredLastShot") or -math.huge}
   local deadline=rack:GetAttribute("StoredReloadEnds") or 0
   if deadline>os.clock() then
    s.reloading=true s.reloadEnds=deadline
    task.delay(deadline-os.clock(),function()
     if Manager.held[p]==s then s.ammo=cfg.MagSize s.reloading=false s.reloadEnds=nil state(s) end
    end)
   elseif deadline>0 then s.ammo=cfg.MagSize end
   Manager.held[p]=s state(s)
   rack:SetAttribute("IsOccupied",false) prompt.Enabled=false
   tool.Parent=p.Character
  end)
 end
end
local dropRate=U.RateLimiter(0.2)
remotes.WeaponDropEvent.OnServerEvent:Connect(function(p)
 if dropRate(p) then Manager.CleanupPlayer(p) end
end)
local function reload(p,s)
 if s.reloading or s.ammo==s.cfg.MagSize then return end
 s.reloading=true s.reloadEnds=os.clock()+s.cfg.ReloadTime state(s)
 task.delay(s.cfg.ReloadTime,function()
  if Manager.held[p]~=s or not s.tool.Parent then return end
  s.ammo=s.cfg.MagSize s.reloading=false s.reloadEnds=nil state(s)
 end)
end
local reloadRate=U.RateLimiter(0.25)
remotes.WeaponReloadEvent.OnServerEvent:Connect(function(p)
 local s=Manager.held[p]
 if s and U.Alive(p,U.Flight(p)) and reloadRate(p) then reload(p,s) end
end)
remotes.WeaponFireEvent.OnServerEvent:Connect(function(p,_clientOrigin,target)
 local s=Manager.held[p] local fd=U.Flight(p)
 if not s or not fd or not U.Alive(p,fd) or s.balloon~=fd.balloon or s.tool.Parent~=p.Character or not U.FiniteVector(target) then return end
 if not U.Near(p,fd.root,75) or s.reloading or os.clock()-s.lastShot<s.cfg.FireRate-0.01 then return end
 if s.ammo<=0 then reload(p,s) return end
 local handle=s.tool:FindFirstChild("Handle")
 if not handle then return end
 local muzzle=handle:FindFirstChild("MuzzleAttachment")
 local origin=muzzle and muzzle.WorldPosition or handle.Position
 local delta=target-origin
 if delta.Magnitude<0.01 then return end
 s.lastShot=os.clock() s.ammo-=1 state(s)
 local direction=delta.Unit
 local spread=CFrame.lookAt(Vector3.zero,direction)*CFrame.Angles(math.rad((math.random()-0.5)*1.5),math.rad((math.random()-0.5)*1.5),0)
 direction=spread.LookVector
 local params=RaycastParams.new()
 params.FilterType=Enum.RaycastFilterType.Exclude params.FilterDescendantsInstances={p.Character,fd.balloon}
 local hit=workspace:Raycast(origin,direction*500,params)
 local part=hit and hit.Instance
 local model=part and part:FindFirstAncestorOfClass("Model")
 if model and model:GetAttribute("IsObstacle") and model:GetAttribute("Shootable")==true then
  local hp=(model:GetAttribute("Health") or 50)-s.cfg.Damage
  model:SetAttribute("Health",hp)
  if hp<=0 then model:Destroy() end
 end
 remotes.WeaponFireEvent:FireAllClients(p,origin,hit and hit.Position or origin+direction*500)
 if s.ammo<=0 then reload(p,s) end
end)
Players.PlayerRemoving:Connect(Manager.CleanupPlayer)
