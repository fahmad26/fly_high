local SS=game.ServerStorage local Players=game:GetService("Players")
local p=Players:GetPlayers()[1]or Players.PlayerAdded:Wait()
local bm=_G.FlyHighBalloonManager local om=_G.FlyHighObstacleManager local U=require(script.Parent.FlyHighServer.ServerUtils)
local api=Instance.new("BindableFunction")api.Name="ControlsQA"api.Parent=SS
local function fd()return bm.activeFlights[1]end
local function alive()if not p.Character or p.Character:FindFirstChildOfClass("Humanoid").Health<=0 then p:LoadCharacterAsync()task.wait(1)end end
api.OnInvoke=function(action,data)
 if action=="Launch"then
  alive()om.Paused=true
  for _,f in ipairs(table.clone(bm.activeFlights))do f.balloon:Destroy()end
  local f=bm.LaunchBalloon({p},p,Vector3.new(0,10,-38),"Pod_C")
  assert(f,"Launch failed")
  return {theme=f.balloon:GetAttribute("BalloonThemeId"),blocked=bm.LaunchBalloon({p},p,Vector3.new(0,10,-38),"Pod_A")==nil}
 elseif action=="Move"then
  local f=fd()U.Unseat(p)
  f.root:SetNetworkOwner(nil)
  local pos=Vector3.new(0,12.5+(data.km or 0)*.25,-56)
  f.balloon:PivotTo(CFrame.new(pos))f.targetPosition=pos f.alignPos.Position=pos f.altitudeKm=data.km or 0 f.hasLiftedOff=data.km>0
  p.Character:PivotTo(CFrame.new(pos+Vector3.new(4,4,0)))p.Character.HumanoidRootPart:SetNetworkOwner(nil)
  f.boardingUntil=os.clock()+10 f.groundedSince=os.clock()
  return true
 elseif action=="Seat"then
  local f=fd()f.balloon.HelmSeat:Sit(p.Character:FindFirstChildOfClass("Humanoid"))return true
 elseif action=="Action"then return bm.FlightAction(p,data.action,data.value)
 elseif action=="Station"then
  local f=fd()U.Unseat(p)p.Character:PivotTo(f.balloon.TetherStation.CFrame*CFrame.new(0,2,-2))return true
 elseif action=="Puncture"then
  local f=fd()f.invulnTime=0 return bm.ApplyPuncture(f,data)
 elseif action=="Five"then
  local f=fd()for i=1,5 do f.invulnTime=0 bm.ApplyPuncture(f,"SelfShot")end return f.holes
 elseif action=="Kit"then
  _G.FlyHighDataManager.ModifyEmergencyKits(p,1)return bm.UseEmergencyKit(p)
 elseif action=="GroundExpiry"then fd().groundedSince=os.clock()-59.8 return true
 elseif action=="Rack"then
  local f=fd()p.Character:PivotTo(f.balloon.WeaponRack1.CFrame*CFrame.new(3,2,0))return true
 elseif action=="Status"then
  local f=fd()local t=_G.FlyHighTetherManager.activeTethers[p.UserId]
  local held=_G.FlyHighWeaponManager.held[p]
  return {pilot=f and f.pilot==p,autoGas=f and f.autoGas,burning=f and(f.isGasActive or f.autoGas),y=f and f.root.Position.Y,holes=f and f.holes,gameOver=f and f.isGameOver,victory=f and f.isVictory,health=p.Character and p.Character:FindFirstChildOfClass("Humanoid").Health,attached=t~=nil,held=held~=nil,ammo=held and held.ammo,seat=tostring(p.Character:FindFirstChildOfClass("Humanoid").SeatPart)}
 end
end
