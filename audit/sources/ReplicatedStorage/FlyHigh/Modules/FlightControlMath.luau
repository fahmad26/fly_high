local Control={}
function Control.CameraSteer(input,cameraCFrame)
 local forward=Vector3.new(cameraCFrame.LookVector.X,0,cameraCFrame.LookVector.Z)
 if forward.Magnitude<.001 then
  local up=cameraCFrame.UpVector
  forward=Vector3.new(up.X,0,up.Z)
 end
 forward=forward.Magnitude>.001 and forward.Unit or Vector3.new(0,0,-1)
 local right=forward:Cross(Vector3.yAxis)
 local result=right*input.X-forward*input.Z
 return result.Magnitude>1 and result.Unit or result
end
return Control
