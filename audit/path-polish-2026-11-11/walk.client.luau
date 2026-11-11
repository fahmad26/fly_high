local p=game.Players.LocalPlayer local goal local results={}local R=game:GetService("RunService")
R:BindToRenderStep("PathPolishQA",201,function()local c=p.Character local root=c and c:FindFirstChild("HumanoidRootPart")local hum=c and c:FindFirstChildOfClass("Humanoid")if hum and root and goal then local d=Vector3.new(goal.X-root.Position.X,0,goal.Z-root.Position.Z)hum:Move(d.Magnitude>.6 and d.Unit*math.min(1,d.Magnitude)or Vector3.zero,false)end end)
local function walk(v)local c=p.Character local root=c.HumanoidRootPart local began=os.clock()goal=v repeat task.wait(.05)until Vector2.new(root.Position.X-v.X,root.Position.Z-v.Z).Magnitude<1.2 or os.clock()-began>18 goal=nil c.Humanoid:Move(Vector3.zero,false)return Vector2.new(root.Position.X-v.X,root.Position.Z-v.Z).Magnitude<1.2 end
task.wait(2)
for i=1,5 do
 p.Character:PivotTo(CFrame.new(0,14,35))task.wait(.4)
 local ok=walk(Vector3.new(0,10,20))and walk(Vector3.new(0,10,-55))
 local angle=(i-3)*45 local n=math.max(1,math.ceil(math.abs(angle)/9))
 for j=1,n do local a=math.rad(angle*j/n)ok=walk(Vector3.new(math.sin(a)*70,10,15-math.cos(a)*70))and ok end
 local name="Pod_"..string.char(64+i)ok=walk(workspace.FlyHighLobby.MatchmakingPods[name].FloorPad.Position)and ok task.wait(.5)
 table.insert(results,{pod=name,reached=ok,currentPod=p:GetAttribute("CurrentPod"),alive=p.Character.Humanoid.Health>0,position=tostring(p.Character.HumanoidRootPart.Position)})
 local result=script:FindFirstChild("Results")or Instance.new("StringValue",script)result.Name="Results"result.Value=game:GetService("HttpService"):JSONEncode(results)
end
R:UnbindFromRenderStep("PathPolishQA")script:SetAttribute("Done",true)
