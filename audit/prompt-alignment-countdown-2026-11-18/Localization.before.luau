--!strict
-- Client presentation: source Text/ActionText stays unchanged for existing HUD state readers.
local LocalizationService = game:GetService("LocalizationService")
local Rows = require(script.Parent.LocalizationCatalog)
local Localization = {}
local changed = Instance.new("BindableEvent")
local preference = "auto"
local exact: { [string]: string } = {}
local formats = {}
for _, row in Rows do
	exact[row.source] = row.en
	if row.pattern then table.insert(formats, row) end
end
table.sort(formats, function(a, b) return #a.source > #b.source end)

function Localization.Resolve(preferred: string, robloxLocale: string): string
	if preferred == "id" or preferred == "en" then return preferred end
	return if robloxLocale:lower():match("^id") then "id" else "en"
end

function Localization.GetLocale(): string
	return Localization.Resolve(preference, LocalizationService.RobloxLocaleId)
end

function Localization.GetPreference(): string
	return preference
end

function Localization.SetPreference(value: string): boolean
	if value ~= "auto" and value ~= "id" and value ~= "en" then return false end
	if preference == value then return true end
	preference = value
	changed:Fire()
	return true
end

function Localization.Observe(callback: () -> ()): RBXScriptConnection
	return changed.Event:Connect(callback)
end

local translate: (string, number) -> string
translate = function(source: string, depth: number): string
	if exact[source] then return exact[source] end
	if depth > 3 or #source > 4096 then return source end
	for _, row in formats do
		local captures = { source:match(row.pattern) }
		if #captures > 0 then
			return (row.template:gsub("{(%d+)}", function(index)
				local value = captures[tonumber(index)] or ""
				return if row.rawCaptures then value else translate(value, depth + 1)
			end))
		end
	end
	-- Translate composed copy only at known boundaries, never arbitrary words/player names.
	for _, separator in { "\n", " · ", " • ", " | " } do
		if source:find(separator, 1, true) then
			local parts = string.split(source, separator)
			for i, part in parts do parts[i] = translate(part, depth + 1) end
			return table.concat(parts, separator)
		end
	end
	-- Preserve exact whitespace and RichText markup while translating known inner content.
	local leading, body, trailing = source:match("^(%s*)(.-)(%s*)$")
	if body and body ~= source then return leading .. translate(body, depth + 1) .. trailing end
	return source
end

function Localization.Translate(source: string, locale: string?): string
	return if (locale or Localization.GetLocale()) == "id" then source else translate(source, 0)
end

function Localization.GetEntries(): { any }
	return Rows
end

LocalizationService:GetPropertyChangedSignal("RobloxLocaleId"):Connect(function()
	if preference == "auto" then changed:Fire() end
end)

return Localization
