if not game:GetService("RunService"):IsStudio()then return end
local p=game.Players.LocalPlayer local qa=game.ReplicatedStorage.FlyHigh.Remotes:WaitForChild("WarningAudioQAEvent")
local logs={}
local function folder()local controller=p.PlayerScripts:FindFirstChild("WarningAudioController")return controller and controller:FindFirstChild("FlyHighWarningAudio")end
game:GetService("LogService").MessageOut:Connect(function(m,k)if k==Enum.MessageType.MessageError or k==Enum.MessageType.MessageWarning then table.insert(logs,{message=m,kind=k.Name})end end)
local function snapshot()
 local f=folder()local playing=0 local loaded={}
 if f then for _,s in f:GetChildren()do if s:IsA("Sound")then if s.IsPlaying then playing+=1 end loaded[s.Name]={loaded=s.IsLoaded,length=s.TimeLength}end end end
 local g=p.PlayerGui:FindFirstChild("FlyHighHUD")
 return {state=f and f:GetAttribute("ActiveWarning"),cues=f and f:GetAttribute("CueCount"),notes=f and f:GetAttribute("NoteCount"),muted=f and f:GetAttribute("Muted"),loaded=f and f:GetAttribute("LoadedCount"),fallback=f and f:GetAttribute("UsingFallback"),playing=playing,children=f and #f:GetDescendants(),volume=f and f.Warnings.Volume,assets=loaded,folder=f~=nil,toggle=g and g:FindFirstChild("WarningAudioToggleButton",true)~=nil,logs=logs}
end
qa.OnClientEvent:Connect(function(id,action,data)
 local ok,value=xpcall(function()
  if action=="Ready"then
   local f=p.PlayerScripts:WaitForChild("WarningAudioController",20):WaitForChild("FlyHighWarningAudio",20)local stop=os.clock()+20
   repeat task.wait(.1)until f:GetAttribute("LoadedCount")==2 or os.clock()>stop
   return snapshot()
  elseif action=="Snapshot"then return snapshot()
  elseif action=="Idle"then
   local hum=p.Character.Humanoid local before=tostring(hum.MoveDirection)
   local module=p.PlayerScripts:FindFirstChild("PlayerModule")if module then require(module):GetControls():Disable()end
   game:GetService("RunService"):BindToRenderStep("WarningAudioQAIdle",Enum.RenderPriority.Last.Value-1,function()
    local char=p.Character local h=char and char:FindFirstChildOfClass("Humanoid")if h then h:Move(Vector3.zero,false)end
   end)
   hum:Move(Vector3.zero,false)
   return {moveBefore=before,rig=hum.RigType.Name,hip=hum.HipHeight}
  elseif action=="Tether"then game.ReplicatedStorage.FlyHigh.Remotes.TetherEvent:FireServer(data.action)return true
  elseif action=="Mute"then p:SetAttribute("WarningAudioMuted",data.value)task.wait(.1)return snapshot()
  elseif action=="Monitor"then
   local first=snapshot()local maxPlaying=0 local peak=0 local progress=0 local stop=os.clock()+data.duration
   repeat
    local f=folder()local playing=0
    if f then for _,s in f:GetChildren()do if s:IsA("Sound")and s.IsPlaying then playing+=1 peak=math.max(peak,s.PlaybackLoudness)progress=math.max(progress,s.TimePosition)end end end
    maxPlaying=math.max(maxPlaying,playing)task.wait(.02)
   until os.clock()>stop
   return {first=first,last=snapshot(),maxPlaying=maxPlaying,peak=peak,progress=progress}
  elseif action=="Destroy"then
   p.PlayerScripts:FindFirstChild("WarningAudioController"):Destroy()task.wait(.15)return snapshot()
  end
  error("unknown action "..action)
 end,debug.traceback)
 qa:FireServer(id,ok,value)
end)
