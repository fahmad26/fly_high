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
		local prompt = console:WaitForChild("StartPrompt")
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

local Themes=require(ReplicatedStorage.FlyHigh.Modules.BalloonThemes)
local function updatePodVisuals(data)
 local gui=data.statusGui
 local count=#data.players
 local theme=Themes.Get(data.model.Name)
 local color=data.isStarting and Color3.fromRGB(235,185,83) or (count>0 and Color3.fromRGB(112,191,147) or theme.Accent)
 local countLabel=gui:FindFirstChild("CountLabel")
 if countLabel then countLabel.Text=string.format("%d / %d KRU",count,FlyHighConfig.MAX_PLAYERS_PER_POD) countLabel.TextColor3=color end
 local master=gui:FindFirstChild("MasterInfo")
 if master then master.Text=data.master and ("MASTER • "..data.master.DisplayName) or "MASTER • Belum ada" end
 local label=gui:FindFirstChild("StatusLabel")
 if label then
  label.Text=data.isStarting and "Menyiapkan balon..." or (count>0 and "Siap berangkat bersama Master" or "Masuk ke dermaga untuk bergabung")
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
local function playersOnPad(data)
 local found={}
 for _,p in ipairs(Players:GetPlayers()) do
  local root=p.Character and p.Character:FindFirstChild("HumanoidRootPart")
  if root and U.Alive(p) and p:GetAttribute("DataReady") and not U.Flight(p,true) then
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
 for _,p in ipairs(newcomers) do if #ordered<FlyHighConfig.MAX_PLAYERS_PER_POD then table.insert(ordered,p) end end
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
   if not U.Flight(p) then p:SetAttribute("IsMaster",false) end
  end
 end
 updatePodVisuals(data)
end
for name,data in pairs(podStates) do
 data.prompt.Triggered:Connect(function(p)
  if data.isStarting or not U.Near(p,data.console,12) then return end
  refresh(data,name)
  if data.master~=p then return end
  local bm=_G.FlyHighBalloonManager
  if not bm then return end
  for _,fd in ipairs(bm.activeFlights) do
   local a=fd.root.Position
   local delta=Vector2.new(a.X-data.pad.Position.X,a.Z-data.pad.Position.Z)
   if delta.Magnitude<26 and a.Y<60 then return end
  end
  data.isStarting=true data.prompt.Enabled=false updatePodVisuals(data)
  local fd=bm.LaunchBalloon(data.players,data.master,data.pad.Position,name)
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
