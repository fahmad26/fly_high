local Config=require(game.ReplicatedStorage.FlyHigh.Modules.FlyHighConfig)
local Space={}
local SPAWN_FORWARD_DISTANCE = 0

local function resolvePadCFrame(origin, podName)
 if typeof(origin) == "Instance" and origin:IsA("BasePart") then
  return origin.CFrame
 elseif typeof(origin) == "CFrame" then
  return origin
 elseif typeof(origin) == "Vector3" then
  local lobby = workspace:FindFirstChild("FlyHighLobby")
  local pods = lobby and lobby:FindFirstChild("MatchmakingPods")
  local pod = podName and pods and pods:FindFirstChild(podName)
  local pad = pod and pod:FindFirstChild("FloorPad")
  if pad and pad:IsA("BasePart") then
   return pad.CFrame
  end
  return CFrame.new(origin)
 end
 return CFrame.new(0, Config.GROUND_Y, 0)
end

function Space.SpawnPosition(origin, podName)
 local cf = resolvePadCFrame(origin, podName)
 local look = Vector3.new(cf.LookVector.X, 0, cf.LookVector.Z)
 look = look.Magnitude > 0.01 and look.Unit or -Vector3.zAxis
 local raw = cf.Position + look * SPAWN_FORWARD_DISTANCE
 local limit = Config.CORRIDOR_CENTER_LIMIT
 return Vector3.new(math.clamp(raw.X, -limit, limit), Config.GROUND_Y, math.clamp(raw.Z, -limit, limit))
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
