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
 game.ReplicatedStorage.FlyHigh.Remotes.FlightStateSyncEvent:FireClient(p,{altitudeKm=0,holes=0,invulnTime=0,shieldTime=0})
end)
