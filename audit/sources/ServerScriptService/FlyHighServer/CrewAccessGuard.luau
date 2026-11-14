local Players=game:GetService("Players")
local Run=game:GetService("RunService")
local U=require(script.Parent.ServerUtils)
local elapsed=0
Run.Heartbeat:Connect(function(dt)
 elapsed+=dt if elapsed<.1 then return end elapsed=0
 local bm=_G.FlyHighBalloonManager if not bm then return end
 for _,p in Players:GetPlayers()do
  local root=p.Character and p.Character:FindFirstChild("HumanoidRootPart")
  if root and U.Alive(p)and not p:GetAttribute("BoardingFlight")then
   local own=U.Flight(p)
   for _,fd in bm.activeFlights do
    if fd~=own and fd.balloon.Parent and not fd.isGameOver and not fd.isVictory then
     local q=fd.root.CFrame:PointToObjectSpace(root.Position)
     local horiz=q.Y<10 and 15.5 or 25
     if math.abs(q.X)<horiz and math.abs(q.Z)<horiz and q.Y> -1 and q.Y<70 then
      U.Unseat(p)
      local target=own and not own.isGameOver and not own.isVictory and own.root.CFrame*CFrame.new(0,5,8)or workspace.FlyHighLobby.LobbySpawn.CFrame*CFrame.new(0,4,0)
      p.Character:PivotTo(target)root.AssemblyLinearVelocity=Vector3.zero
      break
     end
    end
   end
  end
 end
end)
