local Players=game:GetService("Players")
local U=require(script.Parent.ServerUtils)
local portal=workspace:WaitForChild("CloudPalace"):WaitForChild("ReturnPortal")
local prompt=portal:FindFirstChild("ReturnPrompt") or Instance.new("ProximityPrompt",portal)
prompt.Name="ReturnPrompt" prompt.ActionText="Kembali ke Pulau Awal" prompt.HoldDuration=0.3
prompt.MaxActivationDistance=12 prompt.RequiresLineOfSight=false
prompt.Triggered:Connect(function(p)
 if not U.Alive(p) or not U.Near(p,portal,14) or U.Flight(p) then return end
 p.Character:PivotTo(workspace.FlyHighLobby.LobbySpawn.CFrame+Vector3.new(0,4,0))
 p:SetAttribute("FlightGhost",false)
 p:SetAttribute("PalaceArrival",nil)
 game.ReplicatedStorage.FlyHigh.Remotes.FlightStateSyncEvent:FireClient(p,{altitudeKm=0,holes=0,invulnTime=0,shieldTime=0})
end)

-- Palace furniture uses real seats so dismounting follows the player's normal jump controls.
local furniture=workspace.CloudPalace:WaitForChild("PalaceFurniture")
local function bindSeat(seat)
 local prompt=seat.SitPrompt
 local function updatePrompt()
  prompt.Enabled=seat.Occupant==nil
 end
 seat:GetPropertyChangedSignal("Occupant"):Connect(updatePrompt)
 prompt.Triggered:Connect(function(player)
  if seat.Occupant or not U.Alive(player) or U.Flight(player) or not U.Near(player,seat,prompt.MaxActivationDistance) then return end
  local humanoid=player.Character:FindFirstChildOfClass("Humanoid")
  if humanoid and not humanoid.SeatPart then seat:Sit(humanoid) end
 end)
 updatePrompt()
end

local sofa=furniture.RoyalSofa
bindSeat(sofa.LeftSeat)
bindSeat(sofa.RightSeat)

local function bindSwing(swing)
 local seat=swing.Carriage.SitSeat
 local hinge=swing.Frame.Pivot.SwingHinge
 swing.Carriage.MovingRoot:SetNetworkOwner(nil)
 bindSeat(seat)

 local motionId=0
 local function updateSwing()
  motionId+=1
  local thisMotion=motionId
  if not seat.Occupant then
   hinge.TargetAngle=0
   return
  end
  local started=os.clock()
  task.spawn(function()
   while thisMotion==motionId and seat.Occupant do
    hinge.TargetAngle=18*math.sin((os.clock()-started)*1.42)
    task.wait(0.05)
   end
  end)
 end
 seat:GetPropertyChangedSignal("Occupant"):Connect(updateSwing)
 updateSwing()
end

bindSwing(furniture.RoyalSwingLeft)
bindSwing(furniture.RoyalSwingRight)
