local p=game.Players.LocalPlayer;local part=Instance.new("Part");part.Name="LocalizationCopyQA";part.Anchored=true;part.CanCollide=false;part.Transparency=1;part.Position=p.Character.HumanoidRootPart.Position+Vector3.new(2,1,-2);part.Parent=workspace
local d=Instance.new("LocalScript");d.Name="LocalizationCopyQADriver";d.Source=[[
local p=game.Players.LocalPlayer;local L=require(game.ReplicatedStorage.FlyHigh.Modules.Localization);local rows=L.GetEntries();local report={catalogCases=0,failures={},pickups={},ui={}};local initial=L.GetPreference()
local function argsFor(s,translated) local a={};for spec in s:gmatch("%%([%d%.]*[dfs])") do table.insert(a,if spec:sub(-1)=="s" then (if translated then "Durable Rope" else "Tali Awet") else 3) end return a end
for _,r in rows do
 local a=argsFor(r.source,false);local b=argsFor(r.en,not r.rawCaptures)
 local ok,src=pcall(string.format,r.source,table.unpack(a));local ok2,expected=pcall(string.format,r.en,table.unpack(b))
 if ok and ok2 then report.catalogCases+=1; local actual=L.Translate(src,"en");if actual~=expected then table.insert(report.failures,{source=src,expected=expected,actual=actual})end end
end
local function rendered(o)if o.AutoLocalize and o.RootLocalizationTable then return o.RootLocalizationTable:GetTranslator("en-us"):Translate(o,o.Text)end return o.Text end
for _,lang in {"en","id"} do L.SetPreference(lang);task.wait(.3)
 for _,weapon in {"Handgun","AK-47"} do
 local pr=Instance.new("ProximityPrompt");pr.Name="PickupPrompt";pr.ActionText="Ambil "..weapon;pr.HoldDuration=.2;pr.RequiresLineOfSight=false;pr.MaxActivationDistance=30;pr.Parent=workspace.LocalizationCopyQA;task.wait(.4)
 for _,g in p.PlayerGui:GetChildren()do if g.Name=="HUDInteractionPrompt" and g:GetAttribute("PromptName")=="PickupPrompt" then local label=g.ActionTarget.Action;table.insert(report.pickups,{locale=lang,weapon=weapon,source=label.Text,rendered=rendered(label)})end end;pr:Destroy();task.wait(.1)
 end
end
L.SetPreference("en");task.wait(.3)
for _,root in {p.PlayerGui.FlyHighHUD,workspace.FlyHighLobby,workspace.CloudPalace} do
 for _,o in root:GetDescendants()do
 if (o:IsA("TextLabel")or o:IsA("TextButton")) and o.Text~="" then table.insert(report.ui,{path=o:GetFullName(),source=o.Text,rendered=rendered(o),auto=o.AutoLocalize})end
 end
end
L.SetPreference(initial)
workspace.LocalizationCopyQA:SetAttribute("Result",game:GetService("HttpService"):JSONEncode(report))
]];d.Parent=p.PlayerScripts;return "Catalog and native-rendered pickup checks started"
