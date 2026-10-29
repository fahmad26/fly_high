-- Temporary Studio-only device review driver. Never include in the saved place.
assert(game:GetService("RunService"):IsStudio() and game.GameId==0)
local p=game.Players:GetPlayers()[1]
repeat task.wait(.1)until p:GetAttribute("DataReady")and _G.FlyHighBalloonManager and _G.FlyHighLargeChallengeManager
local bm=_G.FlyHighBalloonManager
_G.FlyHighObstacleManager.Paused=true _G.FlyHighLargeChallengeManager.Paused=true
local f=assert(bm.LaunchBalloon({p},p,workspace.FlyHighLobby.MatchmakingPods.Pod_C.FloorPad.Position,"Pod_C"))
local function move()
 local pos=Vector3.new(0,467.5,-56)
 require(game.ServerScriptService.FlyHighServer.ServerUtils).Unseat(p)
 f.balloon:PivotTo(CFrame.new(pos))f.targetPosition=pos f.alignPos.Position=pos
 f.altitudeKm=1820 f.root.AssemblyLinearVelocity=Vector3.zero f.boardingUntil=os.clock()+600
 p.Character:PivotTo(CFrame.new(pos+Vector3.new(0,4,0)))
end
move()
local control=Instance.new("BindableFunction")control.Name="DeviceQAControl"control.Parent=game.ServerStorage
control.OnInvoke=function(action)
 if action=="Seat"then p.Character:PivotTo(f.balloon.HelmSeat.CFrame*CFrame.new(2,3,0))f.balloon.HelmSeat:Sit(p.Character.Humanoid)
 elseif action=="Reset"then move()
 elseif action=="Storm"then move()return _G.FlyHighLargeChallengeManager.Spawn(1800,f)~=nil
 elseif action=="NearRack"then p.Character:PivotTo(f.balloon.WeaponRack1.CFrame*CFrame.new(0,4,2))
 elseif action=="NearStation"then p.Character:PivotTo(f.balloon.TetherStation.CFrame*CFrame.new(2,3,0))
 end
 return {holes=f.holes,altitude=f.altitudeKm,jumps=f.jumpCount or 0,autoGas=f.autoGas}
end