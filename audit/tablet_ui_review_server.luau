-- Temporary Studio-only UI fixture. Remove before saving the production place.
assert(game:GetService("RunService"):IsStudio()and game.GameId==0)
local Players=game.Players local p
repeat p=Players:GetPlayers()[1]task.wait(.1)until p and p:GetAttribute("DataReady")and p.Character and p.Character:FindFirstChild("HumanoidRootPart")and _G.FlyHighBalloonManager
local bm=_G.FlyHighBalloonManager local tm=_G.FlyHighTetherManager local wm=_G.FlyHighWeaponManager
local U=require(game.ServerScriptService.FlyHighServer.ServerUtils)
_G.FlyHighObstacleManager.Paused=true _G.FlyHighLargeChallengeManager.Paused=true
local fd
-- This is a stationary UI fixture, not a durability or flight-physics test.
task.spawn(function()while task.wait(.1)do
 local tether=tm.activeTethers[p.UserId]
 if tether then tether.durability=100 tether.slot.value.Value=100 end
end end)
local function idle()
 wm.CleanupPlayer(p)tm.CleanupPlayer(p)U.Unseat(p)
 p.Character:PivotTo(fd.root.CFrame*CFrame.new(0,4,0))p.Character.HumanoidRootPart.AssemblyLinearVelocity=Vector3.zero
 task.wait(.25)
end
local control=Instance.new("BindableFunction")control.Name="TabletUIQAControl"control.Parent=game.ServerStorage
control.OnInvoke=function(action)
 if action=="Launch"then
  fd=assert(bm.LaunchBalloon({p},p,workspace.FlyHighLobby.MatchmakingPods.Pod_B.FloorPad.Position,"Pod_B"))
  local stop=os.clock()+20 repeat task.wait(.05)until not fd.boarding or os.clock()>stop assert(not fd.boarding,"boarding timeout")
  local pos=Vector3.new(0,12.5+253*.25,0)local delta=pos-fd.root.Position
  fd.balloon:PivotTo(fd.balloon:GetPivot()+delta)p.Character:PivotTo(p.Character:GetPivot()+delta)
  fd.root.Anchored=true fd.targetPosition=pos fd.alignPos.Position=pos fd.altitudeKm=253 fd.boardingUntil=os.clock()+600
  idle()
 elseif action=="Idle"then idle()
 elseif action=="Equip"then
  idle()p.Character:PivotTo(fd.balloon.WeaponRack1.CFrame*CFrame.new(3,2,0))task.wait(.25)
  assert(wm.TryEquip(p,fd.balloon,fd.balloon.WeaponRack1),"equip rejected")
 elseif action=="Pilot"then
  idle()p.Character:PivotTo(fd.balloon.HelmSeat.CFrame*CFrame.new(0,3,1))task.wait(.2)fd.balloon.HelmSeat:Sit(p.Character.Humanoid)task.wait(.25)
  assert(fd.pilot==p,"helm rejected")
 elseif action=="Engineer"then
  idle()p.Character:PivotTo(fd.root.CFrame*CFrame.new(0,4,6))task.wait(.2)assert(tm.attachHandlers[fd.balloon](p))
 elseif action=="Storm"then
  game.ReplicatedStorage.FlyHigh.Remotes.LargeChallengeEvent:FireClient(p,{kind="Warning",id="TabletUIFixture",zoneKm=1800,safeRootY=fd.root.Position.Y-40,warningEndsAt=workspace:GetServerTimeNow()+6,endsAt=workspace:GetServerTimeNow()+45})
 elseif action=="Damage"then
  while fd.holes<4 do fd.invulnTime=0 assert(bm.ApplyPuncture(fd,"SelfShot"))end
 elseif action=="Kit"then assert(_G.FlyHighDataManager.ModifyEmergencyKits(p,1))
 end
 return {role=p:GetAttribute("CrewRole"),holes=fd and fd.holes,jumps=fd and fd.jumpCount or 0,autoGas=fd and fd.autoGas,health=p.Character.Humanoid.Health}
end
