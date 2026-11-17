local p=game.Players.LocalPlayer
local part=workspace.PromptAlignmentQA
local L=require(game.ReplicatedStorage.FlyHigh.Modules.Localization)
local hud=p.PlayerGui.FlyHighHUD
local previous=p:GetAttribute("InFlight")
p:SetAttribute("InFlight",true)
local stats={frames=0,checks=0,failures={},sources={},switches=0}
local watched={hud.GroundedCountdown:FindFirstChild("HUDCountdownNotice",true),hud.AlertBanner.AlertTitle,hud.AlertBanner.AlertDesc,hud.StormChallengePanel.Title}
local con=game:GetService("RunService").RenderStepped:Connect(function()
 stats.frames+=1
 for _,o in watched do local src=o and o:GetAttribute("FlyHighDisplaySource")
  if type(src)=="string" then
   stats.checks+=1;stats.sources[o.Name]=src
   if o.AutoLocalize or o.Text~=L.Translate(src) then
    if #stats.failures<20 then table.insert(stats.failures,{label=o.Name,source=src,text=o.Text,expected=L.Translate(src),locale=L.GetLocale()})end
   end
  end
 end
end)
for tick=1,120 do hud:SetAttribute("HUDGroundedSeconds",61-math.ceil(tick/2)); task.wait(.05) end
-- Language switch on an already displayed countdown; both round trips use the original source.
for _,locale in {"id","en","id","en"} do
 L.SetPreference(locale);stats.switches+=1;task.wait(.15)
 local o=watched[1]; if o.Text~=L.Translate(o:GetAttribute("FlyHighDisplaySource"))then table.insert(stats.failures,{switch=locale,text=o.Text})end
end
con:Disconnect()
hud:SetAttribute("HUDGroundedSeconds",nil)
p:SetAttribute("InFlight",previous)
part:SetAttribute("CountdownResult",game:GetService("HttpService"):JSONEncode(stats))
