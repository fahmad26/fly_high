local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FlyHighConfig = require(ReplicatedStorage:WaitForChild("FlyHigh"):WaitForChild("Modules"):WaitForChild("FlyHighConfig"))

local lobbyFolder = Workspace:WaitForChild("FlyHighLobby")
local podsFolder = lobbyFolder:WaitForChild("MatchmakingPods")

local podStates = {}

for _, podModel in ipairs(podsFolder:GetChildren()) do
	if podModel:IsA("Model") then
		local floorPad = podModel:WaitForChild("FloorPad")
		local console = podModel:WaitForChild("Console")
		local prompt = floorPad:FindFirstChild("StartPrompt", true) or console:FindFirstChild("StartPrompt", true) or console:WaitForChild("StartPrompt")
		local statusGui = console:WaitForChild("StatusGui")

		podStates[podModel.Name] = {
			model = podModel,
			pad = floorPad,
			console = console,
			prompt = prompt,
			statusGui = statusGui,
			players = {},
			master = nil,
			isStarting = false,
		}
	end
end

local Space=require(script.Parent.FlightSpace)
local function blocked(data)
 local bm=_G.FlyHighBalloonManager
 return bm and Space.Blocker(Space.SpawnPosition(data.pad, data.model.Name),bm.activeFlights)~=nil
end
local Themes=require(ReplicatedStorage.FlyHigh.Modules.BalloonThemes)
local function updatePodVisuals(data)
 local gui=data.statusGui
 local count=#data.players
 local theme=Themes.Get(data.model.Name)
 local busy=blocked(data)
 data.model:SetAttribute("LaunchBlocked",busy==true)
 local color=data.isStarting and Color3.fromRGB(235,185,83) or (count>0 and Color3.fromRGB(112,191,147) or theme.Accent)
 local countLabel=gui:FindFirstChild("CountLabel")
 if countLabel then countLabel.Text=string.format("%d / %d KRU",count,FlyHighConfig.MAX_PLAYERS_PER_POD) countLabel.TextColor3=color end
 local master=gui:FindFirstChild("MasterInfo")
 if master then master.Text=data.master and ("MASTER • "..data.master.DisplayName) or "MASTER • Belum ada" end
 local label=gui:FindFirstChild("StatusLabel")
 if label then
  label.Text=data.isStarting and "Menyiapkan balon..." or (busy and "Tunggu balon di dermaga menjauh" or nil) or (count>0 and "Siap berangkat bersama Master" or "Masuk ke dermaga untuk bergabung")
  label.TextColor3=color
 end
 for i=1,FlyHighConfig.MAX_PLAYERS_PER_POD do
  local slot=gui:FindFirstChild("CrewSlot"..i)
  if slot then slot.BackgroundColor3=i<=count and color or Color3.fromRGB(61,70,76) end
 end
 local decor=data.model:FindFirstChild("DockDecor")
 local lights=decor and decor:FindFirstChild("StatusLights")
 for _,lamp in ipairs(lights and lights:GetChildren() or {}) do
  if lamp:IsA("BasePart") then
   lamp.Color=color
   local light=lamp:FindFirstChildOfClass("PointLight")
   if light then light.Color=color end
  end
 end
 data.pad.Color=color
end

local U=require(script.Parent.ServerUtils)
local function isPlayerBusyInFlight(p)
 if U.Flight(p,true) then return true end
 if p:GetAttribute("InFlight")==true or p:GetAttribute("BoardingFlight")==true then return true end
 local fb=p:FindFirstChild("FlightBalloon")
 return fb and fb:IsA("ObjectValue") and fb.Value~=nil and fb.Value.Parent~=nil or false
end
local function playersOnPad(data)
 local found={}
 for _,p in ipairs(Players:GetPlayers()) do
  local root=p.Character and p.Character:FindFirstChild("HumanoidRootPart")
  if root and U.Alive(p) and p:GetAttribute("DataReady") and not isPlayerBusyInFlight(p) then
   local v=data.pad.CFrame:PointToObjectSpace(root.Position)
   if math.abs(v.X)<=data.pad.Size.X/2+1 and math.abs(v.Z)<=data.pad.Size.Z/2+1 and v.Y>=0 and v.Y<=10 then found[p]=true end
  end
 end
 -- Keep entry order so master handoff goes to the next waiting player.
 local ordered={}
 for _,p in ipairs(data.players) do if found[p] then table.insert(ordered,p) found[p]=nil end end
 local newcomers={}
 for p in pairs(found) do table.insert(newcomers,p) end
 table.sort(newcomers,function(a,b) return a.UserId<b.UserId end)
 for _,p in ipairs(newcomers) do
  if #ordered<FlyHighConfig.MAX_PLAYERS_PER_POD then table.insert(ordered,p)
  else
   local root=p.Character and p.Character:FindFirstChild("HumanoidRootPart")
   if root then
    local v=data.pad.CFrame:PointToObjectSpace(root.Position)
    local edge=data.pad.Size/2+Vector3.new(4,0,4)
    local axis=math.abs(v.X)/edge.X>math.abs(v.Z)/edge.Z
    local exit=axis and Vector3.new(v.X<0 and -edge.X or edge.X,4,v.Z)or Vector3.new(v.X,4,v.Z<0 and -edge.Z or edge.Z)
    p.Character:PivotTo(data.pad.CFrame*CFrame.new(exit))root.AssemblyLinearVelocity=Vector3.zero
   end
  end
 end
 return ordered
end
local function refresh(data,name)
 data.players=playersOnPad(data)
 data.master=data.players[1]
 for _,p in ipairs(Players:GetPlayers()) do
  if table.find(data.players,p) then
   p:SetAttribute("CurrentPod",name) p:SetAttribute("IsMaster",p==data.master)
  elseif p:GetAttribute("CurrentPod")==name then
   p:SetAttribute("CurrentPod",nil)
   if not isPlayerBusyInFlight(p) then p:SetAttribute("IsMaster",false) end
  end
 end
 updatePodVisuals(data)
end
for name,data in pairs(podStates) do
 data.prompt.Triggered:Connect(function(p)
  if data.isStarting or isPlayerBusyInFlight(p) or not U.Near(p,data.pad,14) then return end
  refresh(data,name)
  if data.master~=p then return end
  local bm=_G.FlyHighBalloonManager
  if not bm then return end
  if blocked(data)then return end
  data.isStarting=true data.prompt.Enabled=false updatePodVisuals(data)
  local fd=bm.LaunchBalloon(data.players,data.master,data.pad,name)
  if fd then
   data.players={} data.master=nil
  end
  data.isStarting=false data.prompt.Enabled=true updatePodVisuals(data)
 end)
end
task.spawn(function()
 while true do
  for name,data in pairs(podStates) do if not data.isStarting then refresh(data,name) end end
  task.wait(0.2)
 end
end)
