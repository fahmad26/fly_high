local STS=game:GetService("StudioTestService")if STS:GetTestArgs()~="FlyHighBiomeLifecycleQA"then return end
local P=game.Players local R=game.ReplicatedStorage.FlyHigh.Remotes
local qa=R.BiomeLifecycleQAEvent local pending={}local serial=0 local ready={}local report={checks={},logs={},fixtures="native client; controlled lighting sync, fog and character respawn"}
game:GetService("LogService").MessageOut:Connect(function(m,k)if k==Enum.MessageType.MessageError or k==Enum.MessageType.MessageWarning then table.insert(report.logs,m)end end)
qa.OnServerEvent:Connect(function(p,id,value)if id=="Ready"then ready[p]=true else local t=pending[id]if t and t.player==p then t.value=value end end end)
local function waitFor(fn,seconds)local stop=os.clock()+seconds repeat local v=fn()if v then return v end task.wait(.05)until os.clock()>stop end
local function need(name,value,detail)table.insert(report.checks,{name=name,passed=value==true,detail=detail})assert(value,name)end
local ok,err=xpcall(function()
 local p=assert(waitFor(function()for who in ready do if who:GetAttribute("DataReady") and who.Character and who.Character:FindFirstChild("HumanoidRootPart")then return who end end end,60))task.wait(1)
 local function snap()serial+=1 local id=tostring(serial)local t={player=p}pending[id]=t qa:FireClient(p,id)assert(waitFor(function()return t.value end,10))pending[id]=nil return t.value end
 local function send(km,ending)local d={altitudeKm=km,holes=0,invulnTime=0,shieldTime=0,verticalSpeedKmPerSec=0,isVictory=ending=="Victory",isGameOver=ending=="GameOver"}R.FlightStateSyncEvent:FireClient(p,d)end
 local function expect(name,clock,brightness,fog)
  local s local good=waitFor(function()s=snap()return math.abs(s.clock-clock)<.03 and math.abs(s.brightness-brightness)<.03 and math.abs(s.fog-fog)<2 end,8)
  need(name,good==true,s)
 end
 send(2500)expect("Indigo lighting",.5,1,800)
 send(2500,"GameOver")expect("Game Over restores lobby Dawn",6.8,2.5,3000)
 send(10000,"Victory")expect("Victory keeps Celestial palace",14,3.5,5000)
 p:LoadCharacterAsync()expect("respawn restores Dawn",6.8,2.5,3000)
 p:SetAttribute("InFlight",true)p:SetAttribute("FlightGhost",true)
 send(2500)expect("ghost uses team biome",.5,1,800)
 p:LoadCharacterAsync()expect("ghost respawn preserves team biome",.5,1,800)
 p:SetAttribute("InFlight",false)
 R.HazardAlertEvent:FireClient(p,{effect="Fog",duration=6})task.wait(.25)
 need("fog applies",snap().fog==80)
 send(2500,"GameOver")task.wait(6.4)local s=snap()
 need("stale fog timer cannot restore failed flight biome",math.abs(s.clock-6.8)<.03 and math.abs(s.fog-3000)<2,s)
 send(10000,"Victory")expect("second Victory",14,3.5,5000)
 send(0)expect("return portal restores Dawn",6.8,2.5,3000)
 need("clean client logs",#snap().logs==0,snap().logs)
 need("clean server logs",#report.logs==0,report.logs)
end,debug.traceback)
report.ok=ok report.error=not ok and err or nil
STS:EndTest(game:GetService("HttpService"):JSONEncode(report))
