-- Temporary fixture, isolated mock data, one player. No production entry-point claim.
local p=game.Players:GetPlayers()[1]
local bm=_G.FlyHighBalloonManager
local pad=workspace.FlyHighLobby.MatchmakingPods.Pod_A.FloorPad
local fd=bm.LaunchBalloon({p},p,pad.Position,"Pod_A")
if not fd then workspace:SetAttribute("HUDMotionFlightQA","launch-failed")return end
fd.groundedSince=os.clock()+600
fd.shieldTime=600
task.wait(3)
local rack=fd.balloon.WeaponRack1
p.Character:PivotTo(rack.CFrame*CFrame.new(0,3,0))
task.wait(.2)
_G.FlyHighWeaponManager.TryEquip(p,fd.balloon,rack)
workspace:SetAttribute("HUDMotionFlightQA","equipped")
