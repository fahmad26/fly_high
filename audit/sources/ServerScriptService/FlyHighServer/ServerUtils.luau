local Players = game:GetService("Players")
local U = {}
function U.FiniteVector(v)
 return typeof(v)=="Vector3" and v.X==v.X and v.Y==v.Y and v.Z==v.Z and math.abs(v.X)<1e7 and math.abs(v.Y)<1e7 and math.abs(v.Z)<1e7
end
function U.Flight(p,finished)
 local m=_G.FlyHighBalloonManager
 for _,fd in ipairs(m and m.activeFlights or {}) do
  if fd.balloon.Parent and table.find(fd.players,p) and (finished or (not fd.isGameOver and not fd.isVictory)) then return fd end
 end
end
function U.Alive(p,fd)
 local c=p.Character
 local h=c and c:FindFirstChildOfClass("Humanoid")
 return p.Parent==Players and h and h.Health>0 and (not fd or (fd.characters[p]==c and not fd.dead[p]))
end
function U.Near(p,part,range)
 local r=p.Character and p.Character:FindFirstChild("HumanoidRootPart")
 return r and part and (r.Position-part.Position).Magnitude<=range
end
function U.CrewNear(p,b,part,range)
 local fd=U.Flight(p)
 return fd and fd.balloon==b and U.Alive(p,fd) and U.Near(p,part,range) and fd
end
function U.Unseat(p)
 local hum=p.Character and p.Character:FindFirstChildOfClass("Humanoid")
 if not hum then return end
 local seat=hum.SeatPart
 hum.Sit=false
 local weld=seat and seat:FindFirstChild("SeatWeld")
 if weld then weld:Destroy() end
end
function U.InBasket(root,floor)
 local p=floor.CFrame:PointToObjectSpace(root.Position)
 return math.abs(p.X)<=floor.Size.X/2 and math.abs(p.Z)<=floor.Size.Z/2 and p.Y>=0 and p.Y<=8
end
function U.RateLimiter(interval)
 local last=setmetatable({},{__mode="k"})
 return function(p)
  local now=os.clock()
  if now-(last[p] or -math.huge)<interval then return false end
  last[p]=now return true
 end
end
return U
