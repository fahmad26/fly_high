-- Read-only runtime snapshot; Text intentionally stays Indonesian, native table renders target.
local player = game:GetService("Players").LocalPlayer
local gui = player.PlayerGui:WaitForChild("FlyHighHUD")
local viewport = workspace.CurrentCamera.ViewportSize
local function visible(object)
	if object.TextTransparency >= 0.99 then return false end
	local p, size = object.AbsolutePosition, object.AbsoluteSize
	if size.X < 1 or size.Y < 1 then return false end
	if p.X + size.X < 0 or p.Y + size.Y < 0 or p.X > viewport.X or p.Y > viewport.Y then return false end
	local cursor = object
	while cursor and cursor ~= player.PlayerGui do
		if cursor:IsA("GuiObject") then
			if not cursor.Visible then return false end
			if cursor.ClipsDescendants then
				local cp, cs = cursor.AbsolutePosition, cursor.AbsoluteSize
				if p.X + size.X <= cp.X or p.Y + size.Y <= cp.Y or p.X >= cp.X + cs.X or p.Y >= cp.Y + cs.Y then return false end
			end
		elseif cursor:IsA("LayerCollector") and not cursor.Enabled then return false end
		cursor = cursor.Parent
	end
	return true
end
local rows, issues = {}, {}
for _, object in player.PlayerGui:GetDescendants() do
	if (object:IsA("TextLabel") or object:IsA("TextButton")) and object.Text ~= "" and visible(object) then
		local rendered = object.Text
		if object.RootLocalizationTable then
			rendered = object.RootLocalizationTable:GetTranslator(game:GetService("LocalizationService").RobloxLocaleId):Translate(object, object.Text)
		end
		local row = { path=object:GetFullName(), source=object.Text, rendered=rendered, fits=object.TextFits,
			position={object.AbsolutePosition.X,object.AbsolutePosition.Y}, size={object.AbsoluteSize.X,object.AbsoluteSize.Y} }
		table.insert(rows, row)
		if not object.TextFits then table.insert(issues, row) end
	end
end
local controls = {}
for _, name in {"LanguageButton","LanguageAuto","LanguageIndonesian","LanguageEnglish"} do
	local button = gui:FindFirstChild(name,true)
	controls[name] = {width=button.AbsoluteSize.X,height=button.AbsoluteSize.Y}
end
return game:GetService("HttpService"):JSONEncode({ viewport={viewport.X,viewport.Y}, preference=player:GetAttribute("LanguagePreference") or "auto",
	locale=game:GetService("LocalizationService").RobloxLocaleId, orientation=tostring(game:GetService("StarterGui").ScreenOrientation),
	rows=rows, issues=issues, controls=controls })
