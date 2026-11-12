-- Runtime-only: record actual pointer hover at the final render priority.
local Run=game:GetService("RunService")
local p=game.Players.LocalPlayer
local g=p.PlayerGui:WaitForChild("FlyHighHUD")
local M=require(game.ReplicatedStorage.FlyHigh.Modules.HUDMotion)
local state=M.Start(g,p)
local b=g.ShopToggleButton
local samples={}
local busy=false
b.MouseEnter:Connect(function()
 if busy then return end busy=true
 local start=os.clock()
 local basePos,baseSize=b.AbsolutePosition,b.AbsoluteSize
 local binding="HUDMotionHoverSamples"
 Run:BindToRenderStep(binding,Enum.RenderPriority.Last.Value+30,function()
  local r=state.records[b]
  table.insert(samples,{t=os.clock()-start,scale=r.visualScale.Scale,y=r.host.Position.Y.Offset,
   stable=b.AbsolutePosition==basePos and b.AbsoluteSize==baseSize})
  if os.clock()-start>.7 then
   Run:UnbindFromRenderStep(binding)
   local monotonic=true local stable=true
   for i,v in samples do
    stable=stable and v.stable
    if i>1 and v.scale+0.0001<samples[i-1].scale then monotonic=false end
   end
   g:SetAttribute("HoverSequenceQA",game:GetService("HttpService"):JSONEncode({samples=samples,
    monotonic=monotonic,rootStable=stable,settled=math.abs(samples[#samples].scale-1.08)<.001}))
  end
 end)
end)
