-- Presentation fixture only: does not award a summit or alter flight progress.
local p=game.Players.LocalPlayer
local g=p.PlayerGui.FlyHighHUD
local M=require(game.ReplicatedStorage.FlyHigh.Modules.HUDMotion)
M.SetVisible(g.WeaponSettingsModal,false)
task.wait(.25)
p:SetAttribute("ReduceHUDMotion",false)
g:SetAttribute("HUDMotionNotice","✦ Bioma baru · 2000 km")
task.wait(.15)
local toast=g.HUDMotionToast
local function visibleStars()
 local n=0
 for _,o in toast:GetChildren()do if o.Name:match("^Spark") and o.Visible then n+=1 end end
 return n
end
local results={burstBounded=visibleStars()==8,noticeVisible=toast.Visible}
p:SetAttribute("ReduceHUDMotion",true)task.wait(.1)
results.reducedHidesStars=visibleStars()==0
task.wait(1.5)
results.noticeExpires=not toast.Visible
p:SetAttribute("ReduceHUDMotion",false)
local temporary=Instance.new("ScreenGui")temporary.Name="HUDMotionCleanupFixture"temporary.Parent=p.PlayerGui
local state=M.Start(temporary,p)
temporary:Destroy()
task.wait(.1) -- Studio uses deferred signals; allow Destroying to be delivered.
results.destroyCleanup=state.dead and next(state.records)==nil
g:SetAttribute("HUDMotionPresentationQA",game:GetService("HttpService"):JSONEncode(results))
