local Config=require(game.ReplicatedStorage.FlyHigh.Modules.FlyHighConfig)
local Space={}
function Space.SpawnPosition(padPosition)
 return Vector3.new(padPosition.X,Config.GROUND_Y,padPosition.Z-18)
end
function Space.IsGrounded(fd,flights)
 if fd.root.Position.Y<=Config.GROUND_Y+1 then return true end
 local excluded={}
 for _,flight in ipairs(flights)do table.insert(excluded,flight.balloon)end
 for _,p in ipairs(game.Players:GetPlayers())do if p.Character then table.insert(excluded,p.Character)end end
 local params=RaycastParams.new()params.FilterType=Enum.RaycastFilterType.Exclude params.FilterDescendantsInstances=excluded
 local hit=workspace:Raycast(fd.balloon.BasketFloor.Position,Vector3.new(0,-4,0),params)
 if not hit then return false end
 if hit.Instance:IsA("Terrain")then return hit.Material~=Enum.Material.Water end
 return hit.Instance:IsA("BasePart")and hit.Instance.Anchored and hit.Instance.CanCollide
end
function Space.Blocker(position,flights)
 for _,fd in ipairs(flights)do
  if fd.balloon.Parent and not fd.isVictory then
   local d=fd.root.Position-position
   if math.abs(d.Y)<Config.BALLOON_CLEARANCE_HEIGHT and Vector2.new(d.X,d.Z).Magnitude<Config.BALLOON_CLEARANCE_DISTANCE then return fd end
  end
 end
end
function Space.ClampMovement(fd,position,flights)
 for _,other in ipairs(flights)do
  if other~=fd and other.balloon.Parent and not other.isVictory then
   local d=position-other.root.Position
   if math.abs(d.Y)<Config.BALLOON_CLEARANCE_HEIGHT then
    local flat=Vector3.new(d.X,0,d.Z)
    if flat.Magnitude<Config.BALLOON_CLEARANCE_DISTANCE then
     local previous=fd.root.Position-other.root.Position
     local normal=flat.Magnitude>.01 and flat.Unit or (Vector3.new(previous.X,0,previous.Z).Magnitude>.01 and Vector3.new(previous.X,0,previous.Z).Unit or Vector3.xAxis)
     local safe=other.root.Position+normal*Config.BALLOON_CLEARANCE_DISTANCE
     position=Vector3.new(safe.X,position.Y,safe.Z)
    end
   end
  end
 end
 local limit=Config.CORRIDOR_CENTER_LIMIT
 if math.abs(position.X)>limit or math.abs(position.Z)>limit then return fd.root.Position end
 for _,other in ipairs(flights)do
  if other~=fd and other.balloon.Parent and not other.isVictory then
   local d=position-other.root.Position
   if math.abs(d.Y)<Config.BALLOON_CLEARANCE_HEIGHT and Vector2.new(d.X,d.Z).Magnitude<Config.BALLOON_CLEARANCE_DISTANCE-.01 then return fd.root.Position end
  end
 end
 return position
end
return Space
