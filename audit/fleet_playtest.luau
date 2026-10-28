-- Runtime-only fleet regression; never ship this Script.
local result=Instance.new("StringValue")result.Name="FleetQAResult"result.Parent=game.ServerStorage
local Http=game:GetService("HttpService")
local results={}
local ok,err=xpcall(function()
 local Players=game:GetService("Players")
 local p=Players:GetPlayers()[1]or Players.PlayerAdded:Wait()
 repeat task.wait(.1)until p:GetAttribute("DataReady")and p.Character and p.Character:FindFirstChild("HumanoidRootPart")
 local manager=_G.FlyHighBalloonManager
 _G.FlyHighObstacleManager.Paused=true
 for i,id in ipairs({"A","B","C","D","E"})do
  if p.Character:FindFirstChildOfClass("Humanoid").Health<=0 then p:LoadCharacterAsync()task.wait(1)end
  local fd=assert(manager.LaunchBalloon({p},p,Vector3.new(0,10,-38),"Pod_"..id),"launch failed "..id)
  local b=fd.balloon task.wait(.5)
  assert(b:GetAttribute("BalloonThemeId")==id,"wrong theme")
  assert(b.BasketFloor.Size.X==28 and b.BasketFloor.Size.Z==28,"floor mismatch")
  local roots,anchored=0,0
  for _,part in ipairs(b:GetDescendants())do
   if part:IsA("BasePart")then if part.Anchored then anchored+=1 end
    assert(part.AssemblyRootPart==fd.root,"detached part "..part:GetFullName())
   end
  end
  assert(anchored==0 and fd.root:GetNetworkOwner()==nil,"ownership")
  assert(#b.HoleSlots:GetChildren()==5,"repair points")
  for _,name in ipairs({"HelmSeat","WeaponRack1","WeaponRack2","TetherStation"})do assert(b:FindFirstChild(name),"missing "..name)end
  local before=fd.root.Position
  task.wait(.4)
  local drift=(fd.root.Position-before).Magnitude
  assert(drift<2,"unstable launch")
  fd.altitudeKm=1199 fd.invulnTime=0 assert(not manager.ApplyPuncture(fd),"safe zone damage")
  fd.altitudeKm=1500 fd.invulnTime=0 assert(manager.ApplyPuncture(fd),"puncture")
  assert(fd.holes==1 and manager.RepairHole(fd,1)and fd.holes==0,"repair")
  table.insert(results,{theme=id,name=b:GetAttribute("BalloonThemeName"),floor=tostring(b.BasketFloor.Size),parts=#b:GetDescendants(),launchDrift=drift,serverOwned=true,connectedAssembly=true,safeZone=true,repair=true})
  b:Destroy()task.wait(.3)
  assert(#manager.activeFlights==0,"flight cleanup")
 end
end,debug.traceback)
result.Value=Http:JSONEncode({ok=ok,error=ok and nil or err,results=results})

