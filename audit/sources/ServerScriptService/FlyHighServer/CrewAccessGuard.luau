local Players=game:GetService("Players")
local Run=game:GetService("RunService")
local RS=game:GetService("ReplicatedStorage")
local Config=require(RS.FlyHigh.Modules.FlyHighConfig)
local U=require(script.Parent.ServerUtils)

local function inOwnBalloon(p,own,root)
 local tm=_G.FlyHighTetherManager
 local tether=tm and tm.activeTethers[p.UserId]
 if tether and tether.balloon==own.balloon then return true end
 local hum=p.Character and p.Character:FindFirstChildOfClass("Humanoid")
 if hum and hum.SeatPart and hum.SeatPart:IsDescendantOf(own.balloon) then return true end
 local floor=own.balloon:FindFirstChild("BasketFloor")
 if floor then
  local oq=floor.CFrame:PointToObjectSpace(root.Position)
  if math.abs(oq.X)<=floor.Size.X/2+1.5 and math.abs(oq.Z)<=floor.Size.Z/2+1.5 and oq.Y>=-2 and oq.Y<=14 then
   return true
  end
 end
 return false
end

local function pushOutsideBalloon(p,fd,root,flights,q)
 local edge=17.5
 local outLocal
 if math.abs(q.X)<0.05 and math.abs(q.Z)<0.05 then
  outLocal=Vector3.new(0,0,edge)
 elseif math.abs(q.X)>=math.abs(q.Z) then
  outLocal=Vector3.new(q.X>=0 and edge or -edge,0,math.clamp(q.Z,-edge,edge))
 else
  outLocal=Vector3.new(math.clamp(q.X,-edge,edge),0,q.Z>=0 and edge or -edge)
 end
 local worldXZ=fd.root.CFrame:PointToWorldSpace(outLocal)
 local exclude={}
 for _,pl in ipairs(Players:GetPlayers()) do
  if pl.Character then table.insert(exclude,pl.Character) end
 end
 for _,fl in ipairs(flights) do
  if fl.balloon then table.insert(exclude,fl.balloon) end
 end
 local params=RaycastParams.new()
 params.FilterType=Enum.RaycastFilterType.Exclude
 params.FilterDescendantsInstances=exclude
 local origin=Vector3.new(worldXZ.X,math.max(root.Position.Y+6,fd.root.Position.Y+6),worldXZ.Z)
 local hit=workspace:Raycast(origin,Vector3.new(0,-60,0),params)
 local safeY
 if hit and not (hit.Instance:IsA("Terrain") and hit.Material==Enum.Material.Water) and hit.Position.Y>=8 then
  safeY=hit.Position.Y+3.2
 elseif fd.root.Position.Y<=Config.GROUND_Y+12 then
  safeY=math.max(root.Position.Y,Config.GROUND_Y+1.5)
 else
  safeY=root.Position.Y
 end
 U.Unseat(p)
 local targetPos=Vector3.new(worldXZ.X,safeY,worldXZ.Z)
 local targetCF=CFrame.new(targetPos)*(root.CFrame-root.CFrame.Position)
 p.Character:PivotTo(targetCF)
 root.AssemblyLinearVelocity=Vector3.zero
end

local elapsed=0
Run.Heartbeat:Connect(function(dt)
 elapsed+=dt if elapsed<.1 then return end elapsed=0
 local bm=_G.FlyHighBalloonManager if not bm then return end
 for _,p in Players:GetPlayers()do
  local root=p.Character and p.Character:FindFirstChild("HumanoidRootPart")
  if root and U.Alive(p)and not p:GetAttribute("BoardingFlight")then
   local own=U.Flight(p)
   if own and not own.isGameOver and not own.isVictory and inOwnBalloon(p,own,root) then
    continue
   end
   for _,fd in bm.activeFlights do
    if fd~=own and fd.balloon.Parent and not fd.isGameOver and not fd.isVictory then
     local q=fd.root.CFrame:PointToObjectSpace(root.Position)
     local maxY=(fd.profile and fd.profile.maxY or 51)-0.5
     local basketHit=math.abs(q.X)<14.8 and math.abs(q.Z)<14.8 and q.Y>-1.2 and q.Y<11.5
     local upperHit=q.Y>=11.5 and q.Y<=maxY and Vector2.new(q.X,q.Z).Magnitude<21.5
     if basketHit or upperHit then
      if own and not own.isGameOver and not own.isVictory then
       U.Unseat(p)
       p.Character:PivotTo(own.root.CFrame*CFrame.new(0,5,0))
       root.AssemblyLinearVelocity=Vector3.zero
      else
       pushOutsideBalloon(p,fd,root,bm.activeFlights,q)
      end
      break
     end
    end
   end
  end
 end
end)
