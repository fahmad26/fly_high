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
-- Balloon-vs-balloon contact uses each balloon's visible silhouette, not a fixed
-- 60-stud cylinder (playtest 17 Nov: balloons took collision damage while still
-- clearly apart). A profile stores, per 4-stud height band, how far the visible
-- parts reach in 16 horizontal directions (root space, measured once per flight;
-- balloons never yaw). Two balloons touch when, along the line between them, the
-- reaches of any height-overlapping bands add up to their distance.
local PROFILE_STEP=4
local DIRECTIONS=16
local unitDirs={}
for lat=-6,6 do
 local phi=lat/6*math.pi/2
 for lon=0,15 do
  local theta=lon/16*math.pi*2
  table.insert(unitDirs,Vector3.new(math.cos(phi)*math.cos(theta),math.sin(phi),math.cos(phi)*math.sin(theta)))
 end
end
local headings={}
for k=0,DIRECTIONS-1 do local t=k/DIRECTIONS*math.pi*2 headings[k]=Vector2.new(math.cos(t),math.sin(t)) end
function Space.Profile(model,root)
 local bands,lo,hi={},math.huge,-math.huge
 local rootCf=root.CFrame
 for _,part in ipairs(model:GetDescendants())do
  if part:IsA("BasePart")and part.Transparency<0.95 and part.Name~="Envelope"and not part.Name:find("Hole")then
   local cf=rootCf:ToObjectSpace(part.CFrame)
   local half=part.Size/2
   local points={}
   if part:IsA("Part")and part.Shape==Enum.PartType.Block or part:IsA("WedgePart")or part:IsA("CornerWedgePart")then
    for _,sx in ipairs({-1,1})do for _,sy in ipairs({-1,1})do for _,sz in ipairs({-1,1})do
     table.insert(points,cf*Vector3.new(sx*half.X,sy*half.Y,sz*half.Z))
    end end end
   else
    -- Meshes, balls and cylinders: the inscribed ellipsoid follows the visible shape.
    for _,dir in ipairs(unitDirs)do table.insert(points,cf*(dir*half))end
   end
   for _,point in ipairs(points)do
    local bin=math.floor(point.Y/PROFILE_STEP)
    local band=bands[bin]
    if not band then band={} for k=0,DIRECTIONS-1 do band[k]=0 end bands[bin]=band end
    local flat=Vector2.new(point.X,point.Z)
    for k=0,DIRECTIONS-1 do
     local reach=flat:Dot(headings[k])
     if reach>band[k]then band[k]=reach end
    end
    if bin<lo then lo=bin end
    if bin>hi then hi=bin end
   end
  end
 end
 if lo>hi then return nil end
 return {lo=lo,hi=hi,bands=bands}
end
local function profileOf(fd)
 if fd.profile==nil and fd.balloon and fd.root then fd.profile=Space.Profile(fd.balloon,fd.root)or false end
 return fd.profile or nil
end
-- Reach of a band toward a horizontal heading (nil = widest reach).
local function reach(band,heading)
 if not heading then
  local best=0 for k=0,DIRECTIONS-1 do if band[k]>best then best=band[k] end end return best
 end
 local angle=math.atan2(heading.Y,heading.X)%(math.pi*2)
 local k=math.floor(angle/(math.pi*2)*DIRECTIONS)%DIRECTIONS
 -- Upper bound between two sampled headings, so contact is never missed.
 return math.max(band[k],band[(k+1)%DIRECTIONS])/math.cos(math.pi/DIRECTIONS)
end
-- Horizontal distance at which two balloons touch along the line between them,
-- or nil when their heights do not overlap. offset = b root minus a root.
function Space.ContactDistance(a,b,offset)
 local pa,pb=profileOf(a),profileOf(b)
 local dy=offset.Y
 if not pa or not pb then
  if math.abs(dy)<Config.BALLOON_CLEARANCE_HEIGHT then return Config.BALLOON_CLEARANCE_DISTANCE end
  return nil
 end
 local flat=Vector2.new(offset.X,offset.Z)
 local toward=flat.Magnitude>0.01 and flat.Unit or nil
 local away=toward and -toward or nil
 local need=nil
 local shift=dy/PROFILE_STEP
 for bin=pa.lo,pa.hi do
  local bandA=pa.bands[bin]
  if bandA then
   local ra=reach(bandA,toward)
   -- a's band [bin, bin+1) in b's bin space is [bin-shift, bin+1-shift).
   for other=math.max(pb.lo,math.floor(bin-shift)),math.min(pb.hi,math.ceil(bin+1-shift)-1)do
    local bandB=pb.bands[other]
    if bandB then
     local total=ra+reach(bandB,away)
     if total>(need or 0)then need=total end
    end
   end
  end
 end
 return need
end
function Space.ClampMovement(fd,position,flights)
 for _,other in ipairs(flights)do
  if other~=fd and other.balloon.Parent and not other.isVictory then
   local d=position-other.root.Position
   local touch=Space.ContactDistance(fd,other,-d)
   if touch then
    local flat=Vector3.new(d.X,0,d.Z)
    if flat.Magnitude<touch then
     local previous=fd.root.Position-other.root.Position
     local normal=flat.Magnitude>.01 and flat.Unit or (Vector3.new(previous.X,0,previous.Z).Magnitude>.01 and Vector3.new(previous.X,0,previous.Z).Unit or Vector3.xAxis)
     local safe=other.root.Position+normal*touch
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
   local touch=Space.ContactDistance(fd,other,-d)
   if touch and Vector2.new(d.X,d.Z).Magnitude<touch-.01 then return fd.root.Position end
  end
 end
 return position
end
return Space
