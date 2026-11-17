--!strict
-- Native renderer translations preserve underlying Text for existing HUD parsers.
-- Only Fly High's named screens, owned world signs and tagged overheads are eligible.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalizationService = game:GetService("LocalizationService")
local CollectionService = game:GetService("CollectionService")
local L = require(ReplicatedStorage:WaitForChild("FlyHigh"):WaitForChild("Modules"):WaitForChild("Localization"))
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local records: { [Instance]: any } = {}
local excludedNames = { NameLabel=true, PlayerName=true, Username=true, AvatarLetter=true }
local screens = { FlyHighHUD=true, HUDInteractionPrompt=true, FlyHighCinematic=true }
local worldRoots = { FlyHighLobby=true, CloudPalace=true }

local function eligible(object: Instance): boolean
	local gui = object:FindFirstAncestorWhichIsA("LayerCollector")
	if not gui then return false end
	if gui:IsA("ScreenGui") then return screens[gui.Name] == true end
	if CollectionService:HasTag(gui, "FlyHighPlayerOverhead") then return true end
	for _, root in workspace:GetChildren() do
		if worldRoots[root.Name] and gui:IsDescendantOf(root) then return true end
	end
	return false
end

local function unbind(object: Instance)
	local record = records[object]
	if not record then return end
	records[object] = nil
	for _, connection in record.connections do connection:Disconnect() end
	if record.table then
		local textObject = object :: any
		textObject.RootLocalizationTable = record.nativeRoot
		textObject.AutoLocalize = record.auto
		record.table:Destroy()
	end
end

local function bind(object: Instance)
	if not (object:IsA("TextLabel") or object:IsA("TextButton")) then return end
	if records[object] or not eligible(object) then return end
	if excludedNames[object.Name] or object:GetAttribute("FlyHighNoLocalize") == true then
		object.AutoLocalize = false -- Names must also opt out of the experience's cloud table.
		return
	end
	local properties = { "Text" }
	local guiObject = object :: any
	local record = { connections={}, table=nil, previous=nil, nativeRoot=object.RootLocalizationTable, auto=object.AutoLocalize }
	records[object] = record
	local function translated(source: string, locale: string?): string
		-- H1..H7 are compact Hari labels only inside Daily Login, not arbitrary names/codes.
		local day = if object.Name == "DayText" then source:match("^H([1-7])$") else nil
		if day and (locale or L.GetLocale()) == "en" then return "D" .. day end
		return L.Translate(source, locale)
	end
	local function refresh()
		if records[object] ~= record or not object.Parent then return end
		local displaySource = object:GetAttribute("FlyHighDisplaySource")
		if type(displaySource) == "string" then
			-- This label has a localized writer: never expose the source while the
			-- native renderer waits for a fresh per-string translation entry.
			if record.table then
				guiObject.RootLocalizationTable = record.nativeRoot
				record.table:Destroy()
				record.table = nil
				record.previous = nil
			end
			guiObject.AutoLocalize = false
			guiObject.Text = translated(displaySource)
			object:SetAttribute("FlyHighDisplayText", guiObject.Text)
			return
		end
		local locale = LocalizationService.RobloxLocaleId
		local entries, state = {}, { L.GetLocale(), locale }
		local known = false
		for index, property in properties do
			local source = (object :: any)[property]
			local target = translated(source)
			known = known or translated(source, "en") ~= source
			table.insert(state, source)
			table.insert(state, target)
			if source ~= "" then
				table.insert(entries, { Key=tostring(index), Source=source, Values={ [locale]=target, id=target, ["en-us"]=target } })
			end
		end
		-- Numbers, blank controls and unrecognized copy allocate no translation table.
		if not known and not record.table then return end
		local signature = table.concat(state, "\0")
		if record.previous == signature then return end
		record.previous = signature
		if not record.table then
			local nativeTable = Instance.new("LocalizationTable")
			nativeTable.Name = "FlyHighLocalText"
			nativeTable.SourceLocaleId = "id"
			nativeTable.Parent = object
			record.table = nativeTable
		end
		record.table:SetEntries(entries)
		guiObject.RootLocalizationTable = record.table
		guiObject.AutoLocalize = true
		object:SetAttribute("FlyHighDisplayText", translated(guiObject.Text))
	end
	record.refresh = refresh
	table.insert(record.connections, object:GetAttributeChangedSignal("FlyHighDisplaySource"):Connect(refresh))
	for _, property in properties do table.insert(record.connections, object:GetPropertyChangedSignal(property):Connect(refresh)) end
	table.insert(record.connections, object.Destroying:Connect(function() unbind(object) end))
	table.insert(record.connections, object.AncestryChanged:Connect(function()
		if not eligible(object) then unbind(object) end
	end))
	refresh()
end

local function bindTree(root: Instance)
	bind(root)
	for i, object in root:GetDescendants() do
		bind(object)
		if i % 1000 == 0 then task.wait() end
	end
end
-- Watch known ScreenGuis only; do not traverse Roblox CoreGui, chat or TextBoxes.
playerGui.DescendantAdded:Connect(bind)
for _, gui in playerGui:GetChildren() do if screens[gui.Name] then bindTree(gui) end end
local watched: { [Instance]: boolean } = {}
local function watchWorldRoot(root: Instance)
	if watched[root] or not worldRoots[root.Name] then return end
	watched[root] = true
	root.DescendantAdded:Connect(bind)
	bindTree(root)
end
workspace.ChildAdded:Connect(watchWorldRoot)
for _, root in workspace:GetChildren() do watchWorldRoot(root) end
CollectionService:GetInstanceAddedSignal("FlyHighPlayerOverhead"):Connect(bindTree)
for _, gui in CollectionService:GetTagged("FlyHighPlayerOverhead") do bindTree(gui) end
L.Observe(function()
	for _, record in records do record.refresh() end
end)
