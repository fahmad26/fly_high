-- Usage (Studio Edit, via command bar / MCP execute_luau):
--   local m=Instance.new("ModuleScript") m.Name="_QA_VMHarness" m.Source=<this file> m.Parent=game.ServerStorage
--   local H=require(m:Clone())
--   local b=H.build("Pistol")                 -- production pose from WeaponPresentation.viewProfiles
--   print(H.analyze2(b,"Pistol",0.032,0.045)) -- finger/palm clearance vs the real gun mesh (inside must be 0)
--   H.fit(tool, P, opts)                      -- grasp fit; see audit/weapon-v2-2026-11-21/README.md
-- Remove ServerStorage._QA_VMHarness and Workspace._QA_VMPreview afterwards.
-- QA viewmodel harness (Edit only). Loads WeaponPresentation internals, fits hand poses against the
-- real gun mesh (EditableMesh distance field) and reports penetration.
local src=game.ReplicatedStorage.FlyHigh.Modules.WeaponPresentation.Source
src=src:gsub("return Presentation%s*$","return {viewProfiles=viewProfiles,buildRigData=buildRigData,solveArmIK=solveArmIK,curlFinger=curlFinger,aimChainWorld=aimChainWorld,cloneWeaponModel=cloneWeaponModel,cloneArmsModel=cloneArmsModel}")
local X=loadstring(src)()
local CAM=CFrame.lookAt(Vector3.new(-60,60,-60),Vector3.new(-60,60,-120))
local H={X=X,CAM=CAM}
local AS=game:GetService("AssetService")
_G.QA_SDF=_G.QA_SDF or {}
local SDFCACHE=_G.QA_SDF

function H.buildSDF(toolName,vox)
 if SDFCACHE[toolName] then return SDFCACHE[toolName] end
 vox=vox or 0.014
 local tmpl=game.ReplicatedStorage.FlyHigh.Templates.Weapons[toolName]
 local handle=tmpl.Handle
 local tris={}
 local bmin=Vector3.new(1e9,1e9,1e9) local bmax=-bmin
 for _,p in tmpl:GetDescendants() do
  if p:IsA("MeshPart") and p.Transparency<1 then
   local em=AS:CreateEditableMeshAsync(Content.fromUri(p.MeshId))
   local pos={} local vmin=Vector3.new(1e9,1e9,1e9) local vmax=-vmin
   for _,id in em:GetVertices() do local v=em:GetPosition(id) pos[id]=v vmin=vmin:Min(v) vmax=vmax:Max(v) end
   local c=(vmin+vmax)/2 local k=p.Size/p.MeshSize
   local rel=handle.CFrame:ToObjectSpace(p.CFrame)
   local L={} for id,v in pos do L[id]=rel*((v-c)*k) end
   for _,f in em:GetFaces() do
    local vs=em:GetFaceVertices(f)
    local a,b,cc=L[vs[1]],L[vs[2]],L[vs[3]]
    table.insert(tris,{a,b,cc})
    bmin=bmin:Min(a):Min(b):Min(cc) bmax=bmax:Max(a):Max(b):Max(cc)
   end
   em:Destroy()
  end
 end
 local pad=0.2
 bmin-=Vector3.new(pad,pad,pad) bmax+=Vector3.new(pad,pad,pad)
 local nx=math.ceil((bmax.X-bmin.X)/vox) local ny=math.ceil((bmax.Y-bmin.Y)/vox) local nz=math.ceil((bmax.Z-bmin.Z)/vox)
 local N=nx*ny*nz
 local D=buffer.create(N*4)
 for i=0,N-1 do buffer.writef32(D,i*4,1e6) end
 local function idx(i,j,k) return (k*ny+j)*nx+i end
 local cs=0.05 local buckets={}
 for ti,t in tris do
  local a,b,c=t[1],t[2],t[3]
  local y0=math.floor((math.min(a.Y,b.Y,c.Y)-bmin.Y)/cs) local y1=math.floor((math.max(a.Y,b.Y,c.Y)-bmin.Y)/cs)
  local z0=math.floor((math.min(a.Z,b.Z,c.Z)-bmin.Z)/cs) local z1=math.floor((math.max(a.Z,b.Z,c.Z)-bmin.Z)/cs)
  for yy=y0,y1 do for zz=z0,z1 do local key=yy*100000+zz local bk=buckets[key] if not bk then bk={} buckets[key]=bk end table.insert(bk,ti) end end
 end
 local solid=0
 for k=0,nz-1 do
  local z=bmin.Z+(k+0.5)*vox
  for j=0,ny-1 do
   local y=bmin.Y+(j+0.5)*vox
   local bk=buckets[math.floor((y-bmin.Y)/cs)*100000+math.floor((z-bmin.Z)/cs)]
   if bk then
    local hits={}
    for _,ti in bk do
     local t=tris[ti] local a,b,c=t[1],t[2],t[3]
     local d=(b.Y-a.Y)*(c.Z-a.Z)-(c.Y-a.Y)*(b.Z-a.Z)
     if math.abs(d)>1e-12 then
      local u=((y-a.Y)*(c.Z-a.Z)-(c.Y-a.Y)*(z-a.Z))/d
      local v=((b.Y-a.Y)*(z-a.Z)-(y-a.Y)*(b.Z-a.Z))/d
      if u>=0 and v>=0 and u+v<=1 then
       table.insert(hits,{a.X+u*(b.X-a.X)+v*(c.X-a.X),((b-a):Cross(c-a).X<0) and 1 or -1})
      end
     end
    end
    if #hits>0 then
     table.sort(hits,function(p,q) return p[1]<q[1] end)
     local w=0 local hi=1
     for i=0,nx-1 do
      local x=bmin.X+(i+0.5)*vox
      while hi<=#hits and hits[hi][1]<=x do w+=hits[hi][2] hi+=1 end
      if w~=0 then buffer.writef32(D,idx(i,j,k)*4,0) solid+=1 end
     end
    end
   end
  end
  if k%20==0 then task.wait() end
 end
 local s2,s3=math.sqrt(2),math.sqrt(3)
 local fwd={} local bwd={}
 for dk=-1,1 do for dj=-1,1 do for di=-1,1 do
  if not (di==0 and dj==0 and dk==0) then
   local w=({1,s2,s3})[math.abs(di)+math.abs(dj)+math.abs(dk)]
   if (dk*ny+dj)*nx+di<0 then table.insert(fwd,{di,dj,dk,w}) else table.insert(bwd,{di,dj,dk,w}) end
  end
 end end end
 local function pass(list,i0,i1,st,j0,j1,k0,k1)
  for k=k0,k1,st do
   for j=j0,j1,st do
    for i=i0,i1,st do
     local id=idx(i,j,k)*4
     local best=buffer.readf32(D,id)
     if best>0 then
      for _,n in list do
       local ii,jj,kk=i+n[1],j+n[2],k+n[3]
       if ii>=0 and ii<nx and jj>=0 and jj<ny and kk>=0 and kk<nz then
        local v=buffer.readf32(D,idx(ii,jj,kk)*4)+n[4]
        if v<best then best=v end
       end
      end
      buffer.writef32(D,id,best)
     end
    end
   end
   if k%10==0 then task.wait() end
  end
 end
 pass(fwd,0,nx-1,1,0,ny-1,0,nz-1)
 pass(bwd,nx-1,0,-1,ny-1,0,nz-1,0)
 local G={nx=nx,ny=ny,nz=nz,vox=vox,bmin=bmin,ntri=#tris,solid=solid}
 function G.dist(lp)
  local i=math.floor((lp.X-bmin.X)/vox) local j=math.floor((lp.Y-bmin.Y)/vox) local k=math.floor((lp.Z-bmin.Z)/vox)
  if i<0 or j<0 or k<0 or i>=nx or j>=ny or k>=nz then return 1 end
  local d=buffer.readf32(D,idx(i,j,k)*4)
  if d==0 then return -vox*0.5 end
  return (d-0.5)*vox
 end
 SDFCACHE[toolName]=G
 return G
end

-- production-path preview (uses the module's own viewProfiles unless P given)
function H.build(toolName,P)
 local old=workspace:FindFirstChild("_QA_VMPreview") if old then old:Destroy() end
 P=P or X.viewProfiles[toolName]
 local tmpl=game.ReplicatedStorage.FlyHigh.Templates.Weapons[toolName]
 local weaponModel=X.cloneWeaponModel(tmpl,P.gunScale)
 local armsModel,armsMesh=X.cloneArmsModel(P.armsScale)
 local root=Instance.new("Model") root.Name="_QA_VMPreview"
 weaponModel.Parent=root armsModel.Parent=root
 local rig=X.buildRigData(armsMesh)
 local idGun=P.gunOffset local idMesh=P.shoulderOffset*CFrame.new(-rig.shoulderMidLocal)
 armsMesh.CFrame=idMesh weaponModel:PivotTo(idGun)
 for _,side in {"R","L"} do
  local hs=P.hands[side]
  local w=X.solveArmIK(rig,side,idMesh,idGun,hs)
  for fn,c in hs.curls do X.curlFinger(rig,side,fn,c[1],c[2]) end
  if hs.triggerPoint then X.aimChainWorld(rig,side,"point",w,idGun,hs.triggerPoint) end
  if hs.thumbChain then X.aimChainWorld(rig,side,"thumb",w,idGun,hs.thumbChain) end
 end
 local meshCF=CAM*idMesh local gunCF=CAM*idGun
 armsMesh.CFrame=meshCF weaponModel:PivotTo(gunCF)
 X.solveArmIK(rig,"R",meshCF,gunCF,P.hands.R) X.solveArmIK(rig,"L",meshCF,gunCF,P.hands.L)
 root.Parent=workspace
 return {root=root,rig=rig,gunCF=gunCF,weapon=weaponModel,scale=P.gunScale}
end

local function segDist(p,a,b)
 local ab=b-a local t=math.clamp((p-a):Dot(ab)/math.max(ab:Dot(ab),1e-9),0,1)
 return (p-(a+ab*t)).Magnitude
end

-- grasp fit. P.hands[side] = {K (middle knuckle, gun-local unscaled), fingerDir, back, elbowPole,
--  trigger?, thumb?, spreads?, settle?}. Returns per side wristOffset/curls/stats.
function H.fit(toolName,P,opts)
 opts=opts or {}
 local rF=opts.rFinger or 0.035
 local rP=opts.rPalm or 0.05
 local capK=opts.capScale or 1
 local G=H.buildSDF(toolName)
 local old=workspace:FindFirstChild("_QA_VMPreview") if old then old:Destroy() end
 local tmpl=game.ReplicatedStorage.FlyHigh.Templates.Weapons[toolName]
 local weaponModel=X.cloneWeaponModel(tmpl,P.gunScale)
 local armsModel,armsMesh=X.cloneArmsModel(P.armsScale)
 local root=Instance.new("Model") root.Name="_QA_VMPreview"
 weaponModel.Parent=root armsModel.Parent=root
 local rig=X.buildRigData(armsMesh)
 local s=P.gunScale
 local idMesh=P.shoulderOffset*CFrame.new(-rig.shoulderMidLocal)
 local meshCF=CAM*idMesh local gunCF=CAM*P.gunOffset
 armsMesh.CFrame=meshCF weaponModel:PivotTo(gunCF)
 root.Parent=workspace
 local caps={}
 local function gunD(pt) return G.dist(gunCF:PointToObjectSpace(pt)/s)*s end
 local function blocked(pt,r)
  if gunD(pt)<r then return true end
  for _,c in caps do if segDist(pt,c[1],c[2])<r+c[3] then return true end end
  return false
 end
 local bones=rig.bones
 local function Pp(n) return bones[n].TransformedWorldCFrame.Position end
 local function V(t) return Vector3.new(t[1],t[2],t[3]) end
 local result={stats={}}
 local log={}
 local fingers={"point","middle","ring","pink"}
 for _,side in {"R","L"} do
  local h=P.hands[side]
  local fd=V(h.fingerDir).Unit local back=V(h.back).Unit
  local Lwm=(rig.restLocal[side.."_middle1"].Position-rig.restLocal[side.."_wrist"].Position).Magnitude
  local K=V(h.K)*s
  local function solve()
   return X.solveArmIK(rig,side,meshCF,gunCF,{wristOffset=K-fd*Lwm,elbowPole=V(h.elbowPole),fingerDir=fd,backOfHand=back})
  end
  local spreads=h.spreads or {}
  for _,f in fingers do X.curlFinger(rig,side,f,{0,0,0},spreads[f] or 0) end
  X.curlFinger(rig,side,"thumb",{0,0,0},0)
  solve()
  local function palmPts()
   local w=Pp(side.."_wrist") local pts={}
   for _,f in fingers do for _,t in {0.4,0.75,1.0} do table.insert(pts,w:Lerp(Pp(side.."_"..f.."1"),t)) end end
   return pts
  end
  local function palmClear() for _,pt in palmPts() do if blocked(pt,rP) then return false end end return true end
  local pushed=0
  for i=1,40 do if palmClear() then break end K=K+back*0.005 pushed+=0.005 solve() end
  if h.settle then
   for i=1,30 do
    local saveK=K K=K-back*0.005 solve()
    if not palmClear() then K=saveK solve() break end
    pushed-=0.005
   end
  end
  solve()
  local closeSet=table.clone(fingers)
  if h.trigger then
   X.aimChainWorld(rig,side,"point",bones[side.."_wrist"].TransformedWorldCFrame,gunCF,{V(h.trigger[1]),V(h.trigger[2]),V(h.trigger[3])})
   closeSet={"middle","ring","pink"}
  end
  if h.thumb then X.aimChainWorld(rig,side,"thumb",bones[side.."_wrist"].TransformedWorldCFrame,gunCF,{V(h.thumb[1]),V(h.thumb[2]),V(h.thumb[3])}) end
  local maxA={95,105,80}
  local ratio={1,1.15,0.75}
  local curls={} local starts=0
  for _,f in closeSet do
   local a={0,0,0} local active={true,true,true}
   local function linkHit()
    local p1,p2,p3=Pp(side.."_"..f.."1"),Pp(side.."_"..f.."2"),Pp(side.."_"..f.."3")
    local tip=p3+(p3-p2)*0.85
    local L={{p1,p2},{p2,p3},{p3,tip}}
    for i=1,3 do for _,t in {0.25,0.6,1.0} do if blocked(L[i][1]:Lerp(L[i][2],t),rF) then return i end end end
    return nil
   end
   local startHit=linkHit()
   if startHit then starts+=1 end
   for step=1,60 do
    local any=false
    local prev={a[1],a[2],a[3]}
    for j=1,3 do if active[j] and a[j]<maxA[j] then a[j]=math.min(maxA[j],a[j]+3*ratio[j]) any=true end end
    if not any then break end
    X.curlFinger(rig,side,f,a,spreads[f] or 0)
    local hi=linkHit()
    if hi and not startHit then
     a={prev[1],prev[2],prev[3]} X.curlFinger(rig,side,f,a,spreads[f] or 0)
     for j=1,hi do active[j]=false end
     local remaining=false for j=1,3 do if active[j] then remaining=true end end
     if not remaining then break end
    end
   end
   curls[f]={{math.floor(a[1]+0.5),math.floor(a[2]+0.5),math.floor(a[3]+0.5)},spreads[f] or 0}
   table.insert(log,string.format("%s_%s curl %d %d %d%s",side,f,curls[f][1][1],curls[f][1][2],curls[f][1][3],startHit and " STARTHIT"..startHit or ""))
  end
  local touch,bad,curlSum=0,0,0
  for _,f in {"thumb","point","middle","ring","pink"} do
   local p1,p2,p3=Pp(side.."_"..f.."1"),Pp(side.."_"..f.."2"),Pp(side.."_"..f.."3")
   local tip=p3+(p3-p2)*0.85
   for _,pt in {p1,(p1+p2)/2,p2,(p2+p3)/2,p3,(p3+tip)/2,tip} do
    if blocked(pt,rF*0.9) then bad+=1 elseif blocked(pt,rF+0.03) then touch+=1 end
   end
  end
  for _,pt in palmPts() do if blocked(pt,rP*0.9) then bad+=1 elseif blocked(pt,rP+0.03) then touch+=1 end end
  for _,c in curls do curlSum+=c[1][1]+c[1][2]+c[1][3] end
  local fore=(Pp(side.."_wrist")-Pp(side.."_elbow")).Unit
  local hand=(Pp(side.."_middle1")-Pp(side.."_wrist")).Unit
  local bend=math.deg(math.acos(math.clamp(fore:Dot(hand),-1,1)))
  local upper=(Pp(side.."_elbow")-Pp(side.."_arm")).Unit
  local elbowAng=math.deg(math.acos(math.clamp(upper:Dot(fore),-1,1)))
  result.stats[side]={touch=touch,bad=bad,curlSum=curlSum,starts=starts,pushed=pushed,bend=bend,elbow=elbowAng}
  for _,f in {"thumb","point","middle","ring","pink"} do
   local p1,p2,p3=Pp(side.."_"..f.."1"),Pp(side.."_"..f.."2"),Pp(side.."_"..f.."3")
   local tip=p3+(p3-p2)*0.85
   table.insert(caps,{p1,p2,rF*capK}) table.insert(caps,{p2,p3,rF*capK}) table.insert(caps,{p3,tip,rF*0.9*capK})
  end
  local w=Pp(side.."_wrist") for _,f in fingers do table.insert(caps,{w,Pp(side.."_"..f.."1"),rP*capK}) end
  local wo=K-fd*Lwm
  result[side]={wristOffset=wo,curls=curls,pushed=pushed,fd=fd,back=back}
  table.insert(log,string.format("%s pushed %.3f wristOffset (%.3f,%.3f,%.3f)",side,pushed,wo.X,wo.Y,wo.Z))
 end
 H.last={root=root,rig=rig,gunCF=gunCF,weapon=weaponModel,scale=s}
 return result,table.concat(log,"\n")
end

function H.analyze2(b,toolName,rF,rP)
 rF=rF or 0.035 rP=rP or 0.05
 local G=H.buildSDF(toolName)
 local s=b.scale local g=b.gunCF
 local function cl(pt) return math.min(G.dist(g:PointToObjectSpace(pt)/s)*s,0.2) end
 local bones=b.rig.bones
 local function P(n) return bones[n].TransformedWorldCFrame.Position end
 local lines={} local bad=0 local inside=0
 for _,side in {"R","L"} do
  for _,f in {"thumb","point","middle","ring","pink"} do
   local p1,p2,p3=P(side.."_"..f.."1"),P(side.."_"..f.."2"),P(side.."_"..f.."3")
   local tip=p3+(p3-p2)*0.85
   local row={}
   for _,pt in {p1,(p1+p2)/2,p2,(p2+p3)/2,p3,(p3+tip)/2,tip} do local c=cl(pt) if c<rF then bad+=1 end if c<0 then inside+=1 end table.insert(row,string.format("%.2f",c)..((c<rF) and "!" or "")) end
   table.insert(lines,side.."_"..f..": "..table.concat(row," "))
  end
  local w=P(side.."_wrist") local row={}
  for _,f in {"point","middle","ring","pink"} do for _,t in {0.4,0.75,1.0} do local c=cl(w:Lerp(P(side.."_"..f.."1"),t)) if c<rP then bad+=1 end if c<0 then inside+=1 end table.insert(row,string.format("%.2f",c)..((c<rP) and "!" or "")) end end
  table.insert(lines,side.."_palm: "..table.concat(row," "))
 end
 return "bad="..bad.." inside="..inside.."\n"..table.concat(lines,"\n")
end

-- proportions: hand vs gun (world studs, as rendered)
function H.bends(b)
 local bones=b.rig.bones
 local function P(n) return bones[n].TransformedWorldCFrame.Position end
 local out={}
 for _,side in {"R","L"} do
  local fore=(P(side.."_wrist")-P(side.."_elbow")).Unit
  local hand=(P(side.."_middle1")-P(side.."_wrist")).Unit
  out[side]=math.deg(math.acos(math.clamp(fore:Dot(hand),-1,1)))
 end
 return out
end
function H.measure(b)
 local bones=b.rig.bones
 local function P(n) return bones[n].TransformedWorldCFrame.Position end
 local L=(P("R_middle1")-P("R_wrist")).Magnitude+(P("R_middle2")-P("R_middle1")).Magnitude+(P("R_middle3")-P("R_middle2")).Magnitude*1.85
 local W=(P("R_point1")-P("R_pink1")).Magnitude
 return L,W
end
return H
