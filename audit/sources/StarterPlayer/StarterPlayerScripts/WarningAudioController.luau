-- Local warning channel: fixed sound pool, one active voice, bounded cadence.
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local Run=game:GetService("RunService")
local Content=game:GetService("ContentProvider")
local p=Players.LocalPlayer
local fly=RS:WaitForChild("FlyHigh")
local config=require(fly:WaitForChild("Modules"):WaitForChild("FlyHighConfig")).AUDIO_WARNINGS
local remotes=fly:WaitForChild("Remotes")
local assets=fly:WaitForChild("AudioAssets")
local gui=p:WaitForChild("PlayerGui"):WaitForChild("FlyHighHUD")

-- Script ownership also removes the sound pool if this controller is destroyed.
local folder=Instance.new("Folder")folder.Name="FlyHighWarningAudio"folder.Parent=script
local group=Instance.new("SoundGroup")group.Name="Warnings"group.Volume=config.VOLUME group.Parent=folder
local sounds={}
for _,name in {"WarningTone","WarningSiren"}do
 local sound=assets:WaitForChild(name):Clone()
 sound.Name=name sound.Looped=false sound.Playing=false sound.SoundGroup=group sound.Parent=folder
 sounds[name]=sound
end
local fallback=Instance.new("Sound")fallback.Name="Fallback"fallback.SoundId="rbxasset://sounds/volume_slider.ogg"
fallback.SoundGroup=group fallback.Parent=folder
folder:SetAttribute("CueCount",0)folder:SetAttribute("NoteCount",0)
folder:SetAttribute("ActiveWarning","")folder:SetAttribute("UsingFallback",false)
local preloadTask=task.spawn(function()
 pcall(function()Content:PreloadAsync({sounds.WarningTone,sounds.WarningSiren,fallback})end)
 folder:SetAttribute("LoadedCount",(sounds.WarningTone.IsLoaded and 1 or 0)+(sounds.WarningSiren.IsLoaded and 1 or 0))
end)

local toggle=Instance.new("TextButton")toggle.Name="WarningAudioToggleButton"
toggle.Size=UDim2.fromOffset(150,44)toggle.Position=UDim2.new(0,20,1,-104)
toggle.BackgroundColor3=Color3.fromRGB(35,65,85)toggle.TextColor3=Color3.new(1,1,1)
toggle.Font=Enum.Font.GothamBold toggle.TextSize=13 toggle.TextWrapped=true toggle.Parent=gui
local owner=Instance.new("ObjectValue")owner.Name="ControllerOwner"owner.Value=script owner.Parent=toggle
Instance.new("UICorner",toggle).CornerRadius=UDim.new(0,10)
local muted=p:GetAttribute("WarningAudioMuted")==true
local currentBalloon,previousBalloon,finishedBalloon
local holes=0 local rope,storm local hazardUntil=0
local cycle,voice,stopAt local nextCue={}local key=""
local connections={}
local function connect(signal,callback)table.insert(connections,signal:Connect(callback))end
local function stopVoice()
 for _,sound in sounds do sound:Stop()end fallback:Stop()
 voice=nil stopAt=nil
end
local function clear()
 holes=0 rope=nil storm=nil hazardUntil=0 cycle=nil nextCue={}
 key=""folder:SetAttribute("ActiveWarning","")stopVoice()
end
local function eligible()
 local char=p.Character local hum=char and char:FindFirstChildOfClass("Humanoid")
 local ref=p:FindFirstChild("FlightBalloon")
 return p:GetAttribute("InFlight")==true and p:GetAttribute("FlightGhost")~=true and hum and hum.Health>0 and ref and ref.Value and ref.Value.Parent and ref.Value~=finishedBalloon
end
local function refreshMute()
 muted=p:GetAttribute("WarningAudioMuted")==true
 group.Volume=muted and 0 or config.VOLUME
 toggle.Text=muted and "SUARA PERINGATAN: OFF"or "SUARA PERINGATAN: ON"
 folder:SetAttribute("Muted",muted)
 if muted then cycle=nil stopVoice()end
end
connect(toggle.Activated,function()p:SetAttribute("WarningAudioMuted",not muted)end)
connect(p:GetAttributeChangedSignal("WarningAudioMuted"),refreshMute)
refreshMute()
local function inactive()if not eligible()then clear()end end
connect(p:GetAttributeChangedSignal("InFlight"),inactive)
connect(p:GetAttributeChangedSignal("FlightGhost"),inactive)
connect(p.CharacterAdded,function()finishedBalloon=nil previousBalloon=nil clear()end)

connect(remotes.FlightStateSyncEvent.OnClientEvent,function(data)
 if data.isGameOver or data.isVictory then
  local ref=p:FindFirstChild("FlightBalloon")finishedBalloon=ref and ref.Value
  clear()return
 end
 if not eligible()then return end
 holes=data.holes or 0
end)
connect(remotes.TetherEvent.OnClientEvent,function(data)
 if eligible()and data.isTethered==true then rope=data else rope=nil end
end)
connect(remotes.HazardAlertEvent.OnClientEvent,function(data)
 if eligible()and not data.effect then hazardUntil=math.max(hazardUntil,workspace:GetServerTimeNow()+math.clamp(data.duration or 3,0,10))end
end)
connect(remotes.LargeChallengeEvent.OnClientEvent,function(data)
 if data.kind=="Ended"then if storm and data.id==storm.id then storm=nil end
 elseif data.kind=="Warning"and eligible()then
  if not storm or storm.id~=data.id then storm=data end
 end
end)

local function choose(now)
 local selected=""local priority=-1
 local function add(name,active)
  if active and config.PROFILES[name].priority>priority then selected=name priority=config.PROFILES[name].priority end
 end
 local unsafe=false
 if storm then
  if now>=storm.endsAt then storm=nil
  else local root=currentBalloon and currentBalloon.PrimaryPart unsafe=root and root.Position.Y>storm.safeRootY+.1 end
 end
 local outside=rope and rope.insideBasket==false and rope.stage~="Descending"
 add("RopeLow",outside and rope.durability<=config.ROPE_LOW_PERCENT)
 add("Hazard",now<hazardUntil)
 add("Critical",holes==4)
 add("Storm",unsafe)
 add("RopeCritical",outside and rope.durability<=config.ROPE_CRITICAL_PERCENT)
 add("Freefall",holes>=5)
 return selected
end
local function note(profile,item,now)
 local sound=sounds[profile.asset]
 if not sound.IsLoaded then sound=fallback folder:SetAttribute("UsingFallback",true)end
 if not sound.IsLoaded then return end
 stopVoice()
 sound.Volume=profile.gain sound.PlaybackSpeed=item.pitch sound.TimePosition=0 sound:Play()
 voice=sound stopAt=now+item.length
 folder:SetAttribute("NoteCount",folder:GetAttribute("NoteCount")+1)
 folder:SetAttribute("LastNote",profile.asset)
end
local elapsed=0
local connection
local cleaned=false
local function cleanup()
 if cleaned then return end cleaned=true
 if coroutine.status(preloadTask)~="dead"then task.cancel(preloadTask)end
 if connection then connection:Disconnect()end
 for _,c in connections do c:Disconnect()end table.clear(connections)
 stopVoice()toggle:Destroy()folder:Destroy()
end
connect(script.Destroying,cleanup)
connection=Run.Heartbeat:Connect(function(dt)
 if not script.Parent or not gui.Parent then
  cleanup()return
 end
 elapsed+=dt if elapsed<.04 then return end elapsed=0
 local ref=p:FindFirstChild("FlightBalloon")currentBalloon=ref and ref.Value
 if currentBalloon~=previousBalloon then
  previousBalloon=currentBalloon finishedBalloon=nil clear()
 end
 toggle.Visible=p:GetAttribute("InFlight")==true
 if not eligible()then if key~=""or cycle or voice then clear()end return end
 local now=workspace:GetServerTimeNow()
 local wanted=choose(now)
 if wanted~=key then key=wanted cycle=nil stopVoice()folder:SetAttribute("ActiveWarning",key)end
 if muted or key==""then return end
 if voice and now>=stopAt then stopVoice()end
 local profile=config.PROFILES[key]
 if not cycle and now>=(nextCue[key]or 0)then
  cycle={start=now,index=1}nextCue[key]=now+profile.interval
  folder:SetAttribute("CueCount",folder:GetAttribute("CueCount")+1)
  folder:SetAttribute("LastCue",key)
 end
 if cycle then
  local item=profile.notes[cycle.index]
  if item and now-cycle.start>=item.at then note(profile,item,now)cycle.index+=1 end
  if cycle.index>#profile.notes then cycle=nil end
 end
end)
