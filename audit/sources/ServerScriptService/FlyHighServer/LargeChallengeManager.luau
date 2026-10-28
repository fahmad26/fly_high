local Run=game:GetService("RunService")local RS=game:GetService("ReplicatedStorage")
local Players=game:GetService("Players")local Http=game:GetService("HttpService")
local C=require(RS.FlyHigh.Modules.FlyHighConfig)
local event=RS.FlyHigh.Remotes.LargeChallengeEvent
local folder=Instance.new("Folder")folder.Name="FlyHighLargeChallenges"folder.Parent=workspace
local Manager={active={},byZone={},Paused=false}
_G.FlyHighLargeChallengeManager=Manager
local function live()
 local bm=_G.FlyHighBalloonManager local list={}
 for _,fd in ipairs(bm and bm.activeFlights or {})do
  if fd.balloon.Parent and not fd.isGameOver and not fd.isVictory then table.insert(list,fd)end
 end return list
end
local function notify(fd,data)
 for _,p in ipairs(fd.players)do if p.Parent==Players then event:FireClient(p,data)end end
end
local function warnFlight(item,fd)
 if item.warned[fd]then return end
 item.warned[fd]=os.clock()+C.LARGE_WARNING_SEC
 fd.largeChallengeSeen=fd.largeChallengeSeen or {}fd.largeChallengeSeen[item.zone]=true
 fd.hazardUntil=math.max(fd.hazardUntil or 0,math.min(item.expires,os.clock()+C.LARGE_WARNING_SEC))
 fd.largeChallengeUntil=math.max(fd.largeChallengeUntil or 0,item.expires)fd.largeChallengeId=item.id
 notify(fd,{kind="Warning",id=item.id,zoneKm=item.zone,safeRootY=item.bottom-C.BALLOON_TOP_CLEARANCE,
  warningEndsAt=workspace:GetServerTimeNow()+C.LARGE_WARNING_SEC,endsAt=workspace:GetServerTimeNow()+math.max(0,item.expires-os.clock())})
end
function Manager.Spawn(zone,fd)
 if not table.find(C.LARGE_CHALLENGE_ZONES,zone)or not fd or fd.isGameOver or fd.isVictory or not fd.balloon.Parent or fd.altitudeKm<C.SAFE_TAKEOFF_KM or fd.altitudeKm<zone-.1 or Manager.byZone[zone]or #Manager.active>=2 then return nil end
 local template=RS.FlyHigh.Templates.Obstacles:FindFirstChild("StormCurtain")if not template then return nil end
 local bottom=fd.root.Position.Y+C.LARGE_BOTTOM_OFFSET
 local model=template:Clone()model.Name="StormCurtain_"..zone
 local center=Vector3.new(0,bottom+C.LARGE_HEIGHT/2,-C.LARGE_START_Z)
 model:PivotTo(CFrame.new(center))
 local id=Http:GenerateGUID(false)
 model:SetAttribute("ChallengeId",id)model:SetAttribute("ZoneKm",zone)model:SetAttribute("Stage","Warning")
 model:SetAttribute("IsObstacle",true)model:SetAttribute("Shootable",false)
 for _,p in ipairs(model:GetDescendants())do if p:IsA("BasePart")then
  p.Anchored=true p.CanCollide=false p.CanTouch=false p.CanQuery=false
  if p~=model.PrimaryPart then p.Transparency=.5 end
 end end
 model.Parent=folder
 local now=os.clock()
 local item={id=id,model=model,zone=zone,bottom=bottom,top=bottom+C.LARGE_HEIGHT,
  born=now,activeAt=now+C.LARGE_WARNING_SEC,expires=now+C.LARGE_WARNING_SEC+C.LARGE_START_Z*2/C.LARGE_SPEED,
  warned=setmetatable({},{__mode="k"}),hit=setmetatable({},{__mode="k"}),lastZ=-C.LARGE_START_Z}
 table.insert(Manager.active,item)Manager.byZone[zone]=item
 for _,other in ipairs(live())do
  if other.root.Position.Y+C.BALLOON_TOP_CLEARANCE>bottom-60 and other.root.Position.Y<item.top+30 then warnFlight(item,other)end
 end
 return item
end
function Manager.Intersects(item,fd,fromZ,toZ)
 local p=fd.root.Position
 return fd.altitudeKm>=C.SAFE_TAKEOFF_KM and math.abs(p.X)<=C.LARGE_WIDTH/2+C.BALLOON_HIT_RADIUS
  and p.Y+C.BALLOON_TOP_CLEARANCE>item.bottom and p.Y-2<item.top
  and p.Z+C.BALLOON_HIT_RADIUS>=math.min(fromZ,toZ)-C.LARGE_DEPTH/2
  and p.Z-C.BALLOON_HIT_RADIUS<=math.max(fromZ,toZ)+C.LARGE_DEPTH/2
end
function Manager.Clear(item)
 if item.model.Parent then item.model:Destroy()end
 if Manager.byZone[item.zone]==item then Manager.byZone[item.zone]=nil end
 local i=table.find(Manager.active,item)if i then table.remove(Manager.active,i)end
 for fd in pairs(item.warned)do
  if fd.largeChallengeId==item.id then fd.largeChallengeUntil=nil fd.largeChallengeId=nil end
  notify(fd,{kind="Ended",id=item.id})
 end
end
local nextSchedule=0
Run.Heartbeat:Connect(function()
 local now=os.clock()local current=live()
 if now>=nextSchedule then
  nextSchedule=now+.2
  local om=_G.FlyHighObstacleManager
  if not Manager.Paused and om and not om.Paused then
   for _,fd in ipairs(current)do
    fd.largeChallengeSeen=fd.largeChallengeSeen or {}
    for _,zone in ipairs(C.LARGE_CHALLENGE_ZONES)do
     if fd.altitudeKm>=zone and fd.altitudeKm<=zone+350 and not fd.largeChallengeSeen[zone]and not Manager.byZone[zone]then Manager.Spawn(zone,fd)end
    end
   end
  end
 end
 for i=#Manager.active,1,-1 do
  local item=Manager.active[i]
  if not item.model.Parent or now>=item.expires or #current==0 then Manager.Clear(item)continue end
  for _,fd in ipairs(current)do
   if fd.root.Position.Y+C.BALLOON_TOP_CLEARANCE>item.bottom-60 and fd.root.Position.Y<item.top+30 then warnFlight(item,fd)end
  end
  if now<item.activeAt then continue end
  if not item.activated then
   item.activated=true item.model:SetAttribute("Stage","Active")
   for _,p in ipairs(item.model:GetDescendants())do if p:IsA("BasePart")and p~=item.model.PrimaryPart then p.Transparency=p.Name:find("Lightning")and .05 or .08 end end
  end
  local z=-C.LARGE_START_Z+C.LARGE_SPEED*(now-item.activeAt)
  item.model:PivotTo(CFrame.new(0,item.bottom+C.LARGE_HEIGHT/2,z))
  for _,fd in ipairs(current)do
   if not item.hit[fd]and item.warned[fd]and now>=item.warned[fd]and Manager.Intersects(item,fd,item.lastZ,z)then
    item.hit[fd]=true
    if _G.FlyHighBalloonManager.ApplyPuncture(fd)then
     fd.balloon:SetAttribute("StormHits",(fd.balloon:GetAttribute("StormHits")or 0)+1)
    end
   end
  end
  item.lastZ=z
 end
end)
