local STS=game:GetService("StudioTestService")
local args=STS:GetTestArgs()
if type(args)~="table" or args.kind~="CoreGuiImpact" then return end
local Players=game:GetService("Players")
local H=game:GetService("HttpService")
local remote=game:GetService("ReplicatedStorage"):WaitForChild("_QA_CoreImpact")
local report={case=args.case,base="de8c273",startedUTC=DateTime.now():ToIsoDate(),environment="Windows Studio, 2 real local clients, isolated GameId=0, default desktop; no metadata injection",clients={},serverErrors={}}
local finished=false
local log=game:GetService("LogService").MessageOut:Connect(function(message,kind)
 if kind==Enum.MessageType.MessageError then table.insert(report.serverErrors,message) end
end)
local function finish()
 if finished then return end finished=true report.finishedUTC=DateTime.now():ToIsoDate()log:Disconnect()
 STS:EndTest(H:JSONEncode(report))
end
remote.OnServerEvent:Connect(function(player,result)
 if type(result)~="table" or result.player~=player.Name then return end
 report.clients[player.Name]=result
 local count=0 for _ in report.clients do count+=1 end
 if count==2 then task.delay(args.captureSeconds or 1,finish) end
end)
task.delay(180,function()report.timeout=true finish()end)
