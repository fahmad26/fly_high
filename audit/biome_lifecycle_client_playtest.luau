local player=game.Players.LocalPlayer
local event=game.ReplicatedStorage.FlyHigh.Remotes.BiomeLifecycleQAEvent
local logs={}
game:GetService("LogService").MessageOut:Connect(function(message,kind)
 if kind==Enum.MessageType.MessageError or kind==Enum.MessageType.MessageWarning then table.insert(logs,{message=message,kind=kind.Name})end
end)
event.OnClientEvent:Connect(function(id)
 local l=game.Lighting
 event:FireServer(id,{clock=l.ClockTime,brightness=l.Brightness,fog=l.FogEnd,logs=logs,alive=player.Character and player.Character:FindFirstChildOfClass("Humanoid") and player.Character.Humanoid.Health>0})
end)
event:FireServer("Ready")
