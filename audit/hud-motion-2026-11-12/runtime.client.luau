-- Temporary runtime fixture; never installed in Edit place.
local p=game.Players.LocalPlayer
local g=p.PlayerGui:WaitForChild("FlyHighHUD")
task.wait(2)
local M=require(game.ReplicatedStorage.FlyHigh.Modules.HUDMotion)
local state=M.Start(g,p)
local results={}
local function test(n,v) results[n]=v end
M.SetVisible(g.WeaponSettingsModal,true) task.wait(.4)
test("open",g.WeaponSettingsModal.Visible)
test("opacitySettled",state.records[g.WeaponSettingsModal].fade.Value==1)
M.SetVisible(g.WeaponSettingsModal,false) task.wait(.3)
test("close",not g.WeaponSettingsModal.Visible)
for i=1,20 do M.SetVisible(g.WeaponSettingsModal,false) M.SetVisible(g.WeaponSettingsModal,true) end
task.wait(.4) test("rapidReopen",g.WeaponSettingsModal.Visible)
local b=g.SettingsToggleButton
local pos,size=b.AbsolutePosition,b.AbsoluteSize
state.records[b].values.Value=.95 task.wait(.03)
test("rootStable",b.AbsolutePosition==pos and b.AbsoluteSize==size)
p:SetAttribute("ReduceHUDMotion",true) task.wait(.1)
test("reduced",p:GetAttribute("ReduceHUDMotion")==true)
p:SetAttribute("ReduceHUDMotion",false)
local total=#g:GetDescendants()
for i=1,10 do M.SetVisible(g.WeaponSettingsModal,false)task.wait(.14)M.SetVisible(g.WeaponSettingsModal,true)task.wait(.22)end
task.wait(.3) test("instanceCountStable",#g:GetDescendants()==total)
M.SetVisible(g.WeaponSettingsModal,false)task.wait(.3)
local fill=g:FindFirstChild("BarFill",true)
fill.Size=UDim2.new(.7,0,1,0)task.wait(.4)
test("barTargetPreserved",math.abs(fill.Size.X.Scale-.7)<.02)
-- Hidden hull does not animate; show a presentation fixture without changing gameplay.
g.StatusFrame.Visible=true
g.StatusFrame:SetAttribute("HoleCount",0)task.wait(.1)
g.StatusFrame:SetAttribute("HoleCount",4)task.wait(.1)
test("noGameplayMutation",p:GetAttribute("InFlight")~=true)
g:SetAttribute("HUDMotionQA",game:GetService("HttpService"):JSONEncode(results))
