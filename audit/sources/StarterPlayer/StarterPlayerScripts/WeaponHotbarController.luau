--!strict
-- Hide only Roblox's native Backpack UI for Fly High weapons. Rack equip,
-- custom combat HUD and server weapon ownership remain with their controllers.
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local RS = game:GetService("ReplicatedStorage")
local Config = require(RS:WaitForChild("FlyHigh"):WaitForChild("Modules"):WaitForChild("FlyHighConfig"))
local player = Players.LocalPlayer
local ok, initial = pcall(StarterGui.GetCoreGuiEnabled, StarterGui, Enum.CoreGuiType.Backpack)
local original = if ok then initial else true
local links: { RBXScriptConnection } = {}
local characterLinks: { RBXScriptConnection } = {}
local backpackLinks: { RBXScriptConnection } = {}
local queued = false
local closed = false
local failures = 0
local queueRefresh: () -> ()

local function hasWeapon(container: Instance?): boolean
	if not container then return false end
	for _, child in container:GetChildren() do
		if child:IsA("Tool") and Config.WEAPONS[child.Name] then return true end
	end
	return false
end

local function refresh()
	queued = false
	if closed then return end
	local desired = original and not (hasWeapon(player.Character) or hasWeapon(player:FindFirstChildOfClass("Backpack")))
	local success, err = pcall(function()
		if StarterGui:GetCoreGuiEnabled(Enum.CoreGuiType.Backpack) ~= desired then
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, desired)
		end
	end)
	if success then
		failures = 0
	elseif failures < 10 then
		failures += 1
		task.delay(0.2, queueRefresh)
	else
		warn("[WeaponHotbarController] Native Backpack UI could not be updated: " .. tostring(err))
	end
end

queueRefresh = function()
	if closed or queued then return end
	queued = true
	task.defer(refresh)
end

local function bind(container: Instance?, connections: { RBXScriptConnection })
	for _, c in connections do c:Disconnect() end
	table.clear(connections)
	if container then
		table.insert(connections, container.ChildAdded:Connect(queueRefresh))
		table.insert(connections, container.ChildRemoved:Connect(queueRefresh))
	end
	queueRefresh()
end

table.insert(links, player.CharacterAdded:Connect(function(character) bind(character, characterLinks) end))
table.insert(links, player.CharacterRemoving:Connect(function() bind(nil, characterLinks) end))
table.insert(links, player.ChildAdded:Connect(function(child)
	if child:IsA("Backpack") then bind(child, backpackLinks) end
end))
-- Refresh after startup as well as container changes; no protected CoreGui signals.
bind(player.Character, characterLinks)
bind(player:FindFirstChildOfClass("Backpack"), backpackLinks)
task.delay(0.5, queueRefresh)
script.Destroying:Connect(function()
	closed = true
	for _, list in { links, characterLinks, backpackLinks } do
		for _, c in list do c:Disconnect() end
	end
	pcall(StarterGui.SetCoreGuiEnabled, StarterGui, Enum.CoreGuiType.Backpack, original)
end)
