-- Server-owned FIFO. Winning flights are protected while queued, docking and departing.
local Players=game:GetService("Players")
local Run=game:GetService("RunService")
local U=require(script.Parent.ServerUtils)
local Arrival={queue={},busy=false}
local function move(fd,target,seconds,passengers)
 local start=fd.root.CFrame
 local elapsed=0
 while elapsed<seconds and fd.balloon.Parent do
  elapsed+=Run.Heartbeat:Wait()
  local a=math.clamp(elapsed/seconds,0,1)
  local cf=start:Lerp(target,a*a*(3-2*a))
  fd.balloon:PivotTo(cf)
  for p,item in pairs(passengers)do
   if p.Parent==Players and p.Character==item.character and item.root.Parent then item.root.CFrame=cf*item.offset end
  end
 end
end
local function release(passengers)
 for p,item in pairs(passengers)do
  if item.root.Parent then item.root.Anchored=item.anchored end
 end
end
local function land(fd)
 local dock=workspace.CloudPalace.CloudHavenDock
 local keep=workspace.CloudPalace.CastleKeep
 fd.balloon:SetAttribute("ArrivalState","Docking")
 local origin=fd.root.Position
 -- Slower approach gives the client arrival cutscene (CINE-01) time to frame the palace; ~4.8 s total.
 move(fd,CFrame.new(origin.X,dock.Position.Y+20,120),1.6,fd.arrivalPassengers)
 move(fd,CFrame.new(dock.Position.X,dock.Position.Y+20,120),1.8,fd.arrivalPassengers)
 move(fd,CFrame.new(dock.Position+Vector3.new(0,1.7,0)),1.4,fd.arrivalPassengers)
 -- Each player loads independently; a departing/disconnected player cannot stall the queue.
 local pending=0
 local open=true
 for i,p in ipairs(fd.players)do
  if p.Parent~=Players then continue end
  pending+=1
  task.spawn(function()
   local ok,err=pcall(function()
    local revived=fd.dead[p] or not U.Alive(p)
    if revived then p:LoadCharacterAsync()end
    local character=p.Character
    local root=character and character:WaitForChild("HumanoidRootPart",8)
    if not open or p.Parent~=Players or not root or p.Character~=character then return end
    U.Unseat(p)
    local arrival=dock.Position+Vector3.new((i-(#fd.players+1)/2)*5,5,-8)
    local target=CFrame.lookAt(arrival,Vector3.new(keep.Position.X,arrival.Y,keep.Position.Z))
    local item=fd.arrivalPassengers[p]
    if not revived and item and item.root==root and root.Anchored then
     -- Crew hop from the deck onto the dock (CINE-01) instead of teleporting; root stays anchored.
     local from=root.CFrame
     local rootToPivot=root.CFrame:ToObjectSpace(character:GetPivot())
     local hop,elapsed=0.75,0
     while elapsed<hop and open and p.Parent==Players and p.Character==character and root.Parent do
      elapsed+=Run.Heartbeat:Wait()
      local a=math.clamp(elapsed/hop,0,1)
      local cf=from:Lerp(target,a*a*(3-2*a))+Vector3.new(0,4*7*a*(1-a),0)
      character:PivotTo(cf*rootToPivot)
     end
     if not open or p.Parent~=Players or p.Character~=character or not root.Parent then return end
    end
    character:PivotTo(target)
    root.Anchored=item and item.root==root and item.anchored or false
    root.AssemblyLinearVelocity=Vector3.zero
    p:SetAttribute("FlightGhost",false)
    p:SetAttribute("ArrivalPending",nil)
    p:SetAttribute("PalaceArrival",nil)
    p:SetAttribute("PalaceArrival",arrival)
    -- Fallen crew rise at the dock (CINE-01): clients play the revival effect for this character.
    if revived then
     p:SetAttribute("ArrivalRevived",true)
     task.delay(12,function()if p.Parent==Players and p.Character==character then p:SetAttribute("ArrivalRevived",nil)end end)
    end
   end)
   if not ok then warn("Palace arrival: "..tostring(err))end
   pending-=1
  end)
 end
 local deadline=os.clock()+12
 while pending>0 and os.clock()<deadline do task.wait(.1)end
 open=false
 release(fd.arrivalPassengers)
 -- Do not carry unloaded players away with the departing balloon.
 fd.arrivalPassengers={}
 fd.balloon:SetAttribute("ArrivalState","Departing")
 move(fd,fd.root.CFrame+Vector3.new(0,180,0),1.4,{})
end
function Arrival.Enqueue(fd)
 fd.arrivalPassengers={}
 fd.root.Anchored=true
 fd.alignPos.Enabled=false fd.alignOri.Enabled=false
 fd.balloon:SetAttribute("ArrivalProtected",true)
 fd.balloon:SetAttribute("ArrivalState","Queued")
 for _,part in ipairs(fd.balloon:GetDescendants())do if part:IsA("BasePart")then part.CanCollide=false part.CanTouch=false end end
 for _,p in ipairs(fd.players)do
  if p.Parent==Players then
   p:SetAttribute("ArrivalPending",true)
   if U.Alive(p,fd)then
    U.Unseat(p)
    local root=p.Character.HumanoidRootPart
    fd.arrivalPassengers[p]={root=root,character=p.Character,offset=fd.root.CFrame:ToObjectSpace(root.CFrame),anchored=root.Anchored}
    root.Anchored=true
   end
  end
 end
 table.insert(Arrival.queue,fd)
 if Arrival.busy then return end
 Arrival.busy=true
 task.spawn(function()
  while #Arrival.queue>0 do
   local nextFlight=table.remove(Arrival.queue,1)
   if nextFlight.balloon.Parent then
    local ok,err=xpcall(function()land(nextFlight)end,debug.traceback)
    release(nextFlight.arrivalPassengers)
    for _,p in ipairs(nextFlight.players)do if p.Parent==Players then p:SetAttribute("ArrivalPending",nil)end end
    if not ok then warn("Palace queue: "..tostring(err))end
    if nextFlight.balloon.Parent then nextFlight.balloon:Destroy()end
   else
    release(nextFlight.arrivalPassengers)
   end
  end
  Arrival.busy=false
 end)
end
return Arrival
