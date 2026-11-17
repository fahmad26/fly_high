local p=game.Players.LocalPlayer
local h=p.PlayerGui:WaitForChild("FlyHighHUD")
h.DailyLoginModal.Visible=false
h.HUDModalScrim.Visible=false
local L=require(game.ReplicatedStorage.FlyHigh.Modules.Localization)
L.SetPreference("en")
local root=p.Character.HumanoidRootPart
local part=Instance.new("Part"); part.Name="PromptAlignmentQA"; part.Anchored=true; part.CanCollide=false; part.CanQuery=false; part.Transparency=1
part.Position=root.Position+Vector3.new(3,1,-3); part.Parent=workspace
local cam=workspace.CurrentCamera; cam.CameraType=Enum.CameraType.Scriptable; cam.CFrame=CFrame.lookAt(root.Position+Vector3.new(0,7,12),part.Position)
_G.PromptQA={part=part,results={},L=L,hud=h}
function _G.PromptQA.show(name,hold)
 if _G.PromptQA.prompt then _G.PromptQA.prompt:Destroy() end
 local pr=Instance.new("ProximityPrompt"); pr.Name=name; pr.ActionText="Ambil AK-47"
 pr.MaxActivationDistance=50; pr.RequiresLineOfSight=false; pr.Exclusivity=Enum.ProximityPromptExclusivity.AlwaysShow; pr.HoldDuration=hold or 0; pr.Parent=part
 _G.PromptQA.prompt=pr
 task.wait(.25)
 for _,g in p.PlayerGui:GetChildren() do if g.Name=="HUDInteractionPrompt" and g:GetAttribute("PromptName")==name then return g.ActionTarget end end
 error("Prompt missing: "..name)
end
function _G.PromptQA.measure(b)
 local a=b.Action; local d=b.ActionDetail; local k=b.InputRing.InputKey
 local blockTop=a.AbsolutePosition.Y; local blockBottom=d.AbsolutePosition.Y+d.AbsoluteSize.Y
 local centerError=(blockTop+blockBottom)/2-(b.AbsolutePosition.Y+b.AbsoluteSize.Y/2)
 local function rendered(o) local ok,t=pcall(function()return o.RootLocalizationTable:GetTranslator("en-us"):Translate(o,o.Text)end);return if ok then t else o.Text end
 return {prompt=_G.PromptQA.prompt.Name,locale=L.GetLocale(),height=b.AbsoluteSize.Y,width=b.AbsoluteSize.X,centerError=centerError,
 top=blockTop-b.AbsolutePosition.Y,bottom=b.AbsolutePosition.Y+b.AbsoluteSize.Y-blockBottom,
 titleFits=a.TextBounds.Y<=a.AbsoluteSize.Y and a.TextBounds.X<=a.AbsoluteSize.X,
 detailFits=d.TextBounds.Y<=d.AbsoluteSize.Y and d.TextBounds.X<=d.AbsoluteSize.X,
 keyFits=k.TextBounds.X<=k.AbsoluteSize.X and k.TextBounds.Y<=k.AbsoluteSize.Y,title=rendered(a),hint=rendered(d),key=rendered(k)}
end
return "Fixture ready; no server actions/rewards"
