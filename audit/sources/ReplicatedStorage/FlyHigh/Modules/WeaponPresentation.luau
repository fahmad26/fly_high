local Presentation = {}
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Run = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local WEAPON_VISIBILITY_STEP = "FlyHighWeaponVisibility"
local BASE_ARMS_SCALE = 0.045

local viewProfiles = {
	Pistol = {
		armsScale = 0.038,
		-- v2 pistol (21 Nov): arms 0.038 (hand length ~0.81 vs gun length ~0.91, like a real full-size
		-- pistol). Hand pose fitted against the real mesh (EditableMesh distance field): no finger/palm
		-- sample inside the gun; right fingers wrap the front strap, support fingers wrap over them with
		-- a near-straight wrist (forearm-to-hand bend ~30 deg, was 80 deg and read as a bent lump in 1P).
		-- Re-fit with tools/qa/vm_harness.lua if the gun mesh, rig or armsScale changes.
		gunScale = 0.95,
		shoulderOffset = CFrame.new(0.05, -0.62, 0.05),
		gunOffset = CFrame.new(0.30, -0.51, -1.38) * CFrame.Angles(math.rad(1.5), math.rad(6), math.rad(-2)),
		recoilOffset = Vector3.new(0, 0.015, 0.075),
		recoilPitchDeg = 4.2,
		recoilRecovery = 11,
		reloadOffset = CFrame.new(-0.08, -0.18, 0.08) * CFrame.Angles(math.rad(-14), math.rad(18), math.rad(14)),
		hands = {
			R = {
				wristOffset = Vector3.new(0.173, -0.048, 0.298),
				elbowPole = Vector3.new(0.9, -0.8, 0.2),
				fingerDir = Vector3.new(-0.100, 0.201, -0.974),
				backOfHand = Vector3.new(0.993, -0.105, 0.052),
				triggerPoint = {
					Vector3.new(0.05, -0.05, -1.00),
					Vector3.new(-0.30, -0.15, -0.94),
					Vector3.new(-0.60, -0.20, -0.75),
				},
				thumbChain = {
					Vector3.new(-0.88, -0.15, -0.44),
					Vector3.new(-0.33, -0.05, -0.94),
					Vector3.new(-0.32, -0.19, -0.93),
				},
				curls = {
					middle = { { 36, 41, 80 }, 0 },
					ring = { { 36, 41, 80 }, 0 },
					pink = { { 33, 38, 80 }, -3 },
				},
			},
			L = {
				wristOffset = Vector3.new(-0.342, -0.112, 0.153),
				elbowPole = Vector3.new(-0.4, -1.0, 0.2),
				fingerDir = Vector3.new(0.449, 0.100, -0.888),
				backOfHand = Vector3.new(-0.949, 0.300, 0.100),
				thumbChain = {
					Vector3.new(0.33, 0.33, -0.88),
					Vector3.new(-0.05, -0.20, -0.98),
					Vector3.new(0.32, -0.19, -0.93),
				},
				curls = {
					point = { { 36, 41, 80 }, 2 },
					middle = { { 33, 38, 80 }, 0 },
					ring = { { 36, 41, 27 }, 0 },
					pink = { { 95, 105, 80 }, -2 },
				},
			},
		},
	},
	AK47 = {
		armsScale = 0.038,
		-- v2 AK-47 (21 Nov): hip hold, body bladed 25 deg; gunScale 1.15 so the short pistol grip fits the
		-- middle/ring fingers (gun length ~4.5 hand lengths, like a real AK). Pose fitted against the real
		-- mesh like the pistol: right hand on the grip, support fingers wrap the lower handguard.
		gunScale = 1.15,
		shoulderOffset = CFrame.new(0.10, -0.70, 0.0) * CFrame.Angles(0, math.rad(-25), 0),
		gunOffset = CFrame.new(0.34, -0.74, -1.0) * CFrame.Angles(math.rad(2), math.rad(5), math.rad(-4)),
		recoilOffset = Vector3.new(0, 0.012, 0.065),
		recoilPitchDeg = 3.2,
		recoilRecovery = 12,
		reloadOffset = CFrame.new(-0.08, -0.20, 0.06) * CFrame.Angles(math.rad(-16), math.rad(16), math.rad(16)),
		hands = {
			R = {
				wristOffset = Vector3.new(0.159, -0.160, 0.299),
				elbowPole = Vector3.new(0.9, -0.9, 0.1),
				fingerDir = Vector3.new(-0.105, 0.241, -0.965),
				backOfHand = Vector3.new(0.977, -0.206, 0.051),
				triggerPoint = {
					Vector3.new(0.05, 0.10, -1.00),
					Vector3.new(-0.30, -0.15, -0.94),
					Vector3.new(-0.60, -0.30, -0.70),
				},
				thumbChain = {
					Vector3.new(-0.94, -0.10, -0.31),
					Vector3.new(-0.15, -0.05, -0.99),
					Vector3.new(-0.32, -0.19, -0.93),
				},
				curls = {
					middle = { { 45, 52, 80 }, 0 },
					ring = { { 48, 55, 80 }, 0 },
					pink = { { 95, 105, 80 }, -3 },
				},
			},
			L = {
				wristOffset = Vector3.new(-0.196, 0.184, -0.788),
				elbowPole = Vector3.new(-0.7, -1.0, 0.1),
				fingerDir = Vector3.new(0.772, -0.154, -0.617),
				backOfHand = Vector3.new(-0.507, -0.862, 0),
				thumbChain = {
					Vector3.new(0.33, -0.33, -0.88),
					Vector3.new(-0.05, -0.05, -1.00),
					Vector3.new(0.32, -0.19, -0.93),
				},
				curls = {
					point = { { 48, 55, 80 }, 2 },
					middle = { { 45, 52, 34 }, 0 },
					ring = { { 48, 55, 36 }, 0 },
					pink = { { 51, 59, 38 }, -3 },
				},
			},
		},
	},
}

local function makeBasis(dirY, poleHint)
	local y = dirY.Unit
	local x = y:Cross(poleHint)
	if x.Magnitude < 1e-4 then x = y:Cross(Vector3.new(0, 1, 0)) end
	x = x.Unit
	local z = x:Cross(y).Unit
	return CFrame.fromMatrix(Vector3.zero, x, y, z)
end

local function solve2Bone(rootPos, targetPos, l1, l2, bendDir)
	local toTarget = targetPos - rootPos
	local dist = math.clamp(toTarget.Magnitude, math.abs(l1 - l2) + 0.02, l1 + l2 - 0.01)
	local fwd = toTarget.Unit
	local cosAngle = math.clamp((l1 * l1 + dist * dist - l2 * l2) / (2 * l1 * dist), -1, 1)
	local sinAngle = math.sqrt(math.max(0, 1 - cosAngle * cosAngle))
	local orthoPole = bendDir - fwd * bendDir:Dot(fwd)
	if orthoPole.Magnitude < 1e-4 then
		orthoPole = Vector3.new(0, -1, 0)
	else
		orthoPole = orthoPole.Unit
	end
	return rootPos + fwd * (l1 * cosAngle) + orthoPole * (l1 * sinAngle)
end

local function buildRigData(armsMesh)
	local bones = {}
	for _, desc in ipairs(armsMesh:GetDescendants()) do
		if desc:IsA("Bone") then
			desc.Transform = CFrame.new()
			bones[desc.Name] = desc
		end
	end

	-- Compute forward-kinematic rest transforms in mesh-local space so runtime solver never touches stale cached WorldCFrames.
	local restLocal = {}
	local function walk(node, parentCF)
		for _, child in ipairs(node:GetChildren()) do
			if child:IsA("Bone") then
				local cf = parentCF * child.CFrame
				restLocal[child.Name] = cf
				walk(child, cf)
			end
		end
	end
	walk(armsMesh, CFrame.identity)

	local lSh = restLocal["L_arm"].Position
	local rSh = restLocal["R_arm"].Position
	local sides = {}
	for _, side in ipairs({ "R", "L" }) do
		local pfx = side .. "_"
		local sPos = restLocal[pfx .. "arm"].Position
		local ePos = restLocal[pfx .. "elbow"].Position
		local wPos = restLocal[pfx .. "wrist"].Position
		local mPos = restLocal[pfx .. "middle1"].Position
		local pPos = restLocal[pfx .. "point1"].Position
		local kPos = restLocal[pfx .. "pink1"].Position

		local restArmDir = (ePos - sPos).Unit
		local restForeDir = (wPos - ePos).Unit
		local restPlane = restArmDir:Cross(restForeDir)
		local rawCross = (pPos - wPos):Cross(kPos - wPos).Unit
		local restBackOfHand = rawCross.Y >= 0 and rawCross or -rawCross

		sides[side] = {
			l1 = (ePos - sPos).Magnitude,
			l2 = (wPos - ePos).Magnitude,
			restArmDir = restArmDir,
			restForeDir = restForeDir,
			restPlane = restPlane,
			restArmRot = restLocal[pfx .. "arm"].Rotation,
			restElbRot = restLocal[pfx .. "elbow"].Rotation,
			restWriRot = restLocal[pfx .. "wrist"].Rotation,
			restArmFrameInv = makeBasis(restArmDir, restPlane):Inverse(),
			restForeFrameInv = makeBasis(restForeDir, restPlane):Inverse(),
			restBackOfHand = restBackOfHand,
			restHandFrameInv = CFrame.lookAt(Vector3.zero, (mPos - wPos).Unit, restBackOfHand).Rotation:Inverse(),
			chestArmLocal = restLocal[pfx .. "arm"],
		}
	end

	return {
		mesh = armsMesh,
		bones = bones,
		restLocal = restLocal,
		shoulderMidLocal = (lSh + rSh) * 0.5,
		sides = sides,
	}
end

local function curlFinger(rigData, side, fName, anglesDeg, spreadDeg)
	local names = { side .. "_" .. fName .. "1", side .. "_" .. fName .. "2", side .. "_" .. fName .. "3" }
	local backPalmLocal = rigData.sides[side].restBackOfHand
	local b1Pos = rigData.restLocal[names[1]].Position
	local b2Pos = rigData.restLocal[names[2]].Position
	local segDirLocal = (b2Pos - b1Pos).Unit
	local curlAxisRig = backPalmLocal:Cross(segDirLocal).Unit

	for idx, nm in ipairs(names) do
		local bone = rigData.bones[nm]
		if bone then
			local bRotRig = rigData.restLocal[nm].Rotation
			local axisLocal = bRotRig:VectorToObjectSpace(curlAxisRig).Unit
			local rot = CFrame.fromAxisAngle(axisLocal, math.rad(anglesDeg[idx] or 0))
			if idx == 1 and spreadDeg and spreadDeg ~= 0 then
				local spreadAxis = bRotRig:VectorToObjectSpace(backPalmLocal).Unit
				rot = CFrame.fromAxisAngle(spreadAxis, math.rad(spreadDeg)) * rot
			end
			bone.Transform = rot
		end
	end
end

local function aimChainWorld(rigData, side, fName, wristWorldCF, refCF, worldDirs)
	local nm1, nm2, nm3 = side .. "_" .. fName .. "1", side .. "_" .. fName .. "2", side .. "_" .. fName .. "3"
	local b1, b2, b3 = rigData.bones[nm1], rigData.bones[nm2], rigData.bones[nm3]
	local r1, r2, r3 = rigData.restLocal[nm1], rigData.restLocal[nm2], rigData.restLocal[nm3]
	if not (b1 and b2 and b3 and r1 and r2 and r3) then return end

	local function alignBone(parentWorld, bone, restL, refPos, goalDirWorld)
		local baseWorld = parentWorld * bone.CFrame
		local segLocal = restL.Rotation:VectorToObjectSpace((refPos - restL.Position).Unit)
		local curDir = baseWorld.Rotation:VectorToWorldSpace(segLocal).Unit
		local goal = goalDirWorld.Unit
		local dot = math.clamp(curDir:Dot(goal), -1, 1)
		local cross = curDir:Cross(goal)
		local delta = (cross.Magnitude > 1e-4) and CFrame.fromAxisAngle(cross.Unit, math.acos(dot)) or CFrame.identity
		bone.Transform = baseWorld.Rotation:Inverse() * (delta * baseWorld.Rotation)
		return baseWorld * bone.Transform
	end

	local g1 = refCF:VectorToWorldSpace(worldDirs[1])
	local g2 = refCF:VectorToWorldSpace(worldDirs[2])
	local g3 = refCF:VectorToWorldSpace(worldDirs[3])
	local p1 = alignBone(wristWorldCF, b1, r1, r2.Position, g1)
	local p2 = alignBone(p1, b2, r2, r3.Position, g2)

	local base3 = p2 * b3.CFrame
	local seg3Local = r3.Rotation:VectorToObjectSpace((r3.Position - r2.Position).Unit)
	local cur3 = base3.Rotation:VectorToWorldSpace(seg3Local).Unit
	local goal3 = g3.Unit
	local dot3 = math.clamp(cur3:Dot(goal3), -1, 1)
	local cross3 = cur3:Cross(goal3)
	local delta3 = (cross3.Magnitude > 1e-4) and CFrame.fromAxisAngle(cross3.Unit, math.acos(dot3)) or CFrame.identity
	b3.Transform = base3.Rotation:Inverse() * (delta3 * base3.Rotation)
end

local function solveArmIK(rigData, side, meshCF, refCF, handSpec)
	local pfx = side .. "_"
	local sd = rigData.sides[side]
	local bArm, bElb, bWri = rigData.bones[pfx .. "arm"], rigData.bones[pfx .. "elbow"], rigData.bones[pfx .. "wrist"]

	-- Express gun/target vectors in armsMesh local space so IK is 100% invariant to any camera pitch/yaw.
	local localRefCF = meshCF:ToObjectSpace(refCF)
	local wristTargetPos = localRefCF * handSpec.wristOffset
	local elbowPole = localRefCF:VectorToWorldSpace(handSpec.elbowPole)
	local fingerDirTarget = localRefCF:VectorToWorldSpace(handSpec.fingerDir)
	local backOfHandTarget = localRefCF:VectorToWorldSpace(handSpec.backOfHand)

	local sBase = sd.chestArmLocal
	local sPos = sBase.Position
	local eTarget = solve2Bone(sPos, wristTargetPos, sd.l1, sd.l2, elbowPole)

	local curArmDir = (eTarget - sPos).Unit
	local curPlane = curArmDir:Cross(elbowPole)

	local shDelta = makeBasis(curArmDir, curPlane) * sd.restArmFrameInv
	bArm.Transform = sBase.Rotation:Inverse() * (shDelta * sd.restArmRot)

	local armPosed = sBase * bArm.Transform
	local elbBase = armPosed * bElb.CFrame
	local curForeActual = (wristTargetPos - elbBase.Position).Unit
	local foreBaseRot = makeBasis(curForeActual, curPlane) * sd.restForeFrameInv

	-- Distribute 60% of axial wrist pronation twist along the forearm to prevent sleeve pinching.
	local unrolledBack = foreBaseRot:VectorToWorldSpace(sd.restBackOfHand)
	local projU = unrolledBack - curForeActual * unrolledBack:Dot(curForeActual)
	local projT = backOfHandTarget - curForeActual * backOfHandTarget:Dot(curForeActual)
	local rollCF = CFrame.identity
	if projU.Magnitude > 1e-3 and projT.Magnitude > 1e-3 then
		projU, projT = projU.Unit, projT.Unit
		local ang = math.acos(math.clamp(projU:Dot(projT), -1, 1))
		local signAxis = projU:Cross(projT)
		if signAxis.Magnitude > 1e-4 then
			rollCF = CFrame.fromAxisAngle(signAxis.Unit, ang * 0.60)
		end
	end

	bElb.Transform = elbBase.Rotation:Inverse() * (rollCF * foreBaseRot * sd.restElbRot)

	local elbPosed = elbBase * bElb.Transform
	local wriBase = elbPosed * bWri.CFrame
	local targetHandRot = CFrame.lookAt(Vector3.zero, fingerDirTarget.Unit, backOfHandTarget.Unit).Rotation
	local wDelta = targetHandRot * sd.restHandFrameInv
	bWri.Transform = wriBase.Rotation:Inverse() * (wDelta * sd.restWriRot)
	return meshCF * wriBase * bWri.Transform
end

local function cloneWeaponModel(template, gunScale)
	local handle = template:FindFirstChild("Handle")
	if not (handle and handle:IsA("BasePart")) then return nil, nil end

	local weaponModel = Instance.new("Model")
	weaponModel.Name = "Weapon"
	local handleCopy
	for _, part in ipairs(template:GetDescendants()) do
		if part:IsA("BasePart") and (part.Transparency < 1 or part == handle) then
			local copy = part:Clone()
			for _, child in ipairs(copy:GetChildren()) do
				if child:IsA("LuaSourceContainer") or child:IsA("Sound") or child:IsA("JointInstance") or child:IsA("Constraint") then
					child:Destroy()
				end
			end
			copy.CFrame = handle.CFrame:ToObjectSpace(part.CFrame)
			copy.Anchored = true
			copy.CanCollide = false
			copy.CanTouch = false
			copy.CanQuery = false
			copy.CastShadow = false
			copy.Massless = true
			copy.LocalTransparencyModifier = 0
			copy.Parent = weaponModel
			if part == handle then
				handleCopy = copy
			end
		end
	end
	if not handleCopy then
		weaponModel:Destroy()
		return nil, nil
	end
	weaponModel.PrimaryPart = handleCopy
	if gunScale and math.abs(gunScale - 1) > 1e-3 then
		weaponModel:ScaleTo(gunScale)
	end
	return weaponModel, handleCopy
end

local function cloneArmsModel(armsScale)
	local templates = ReplicatedStorage:FindFirstChild("FlyHigh") and ReplicatedStorage.FlyHigh:FindFirstChild("Templates")
	local src = templates and templates:FindFirstChild("ViewModelArms")
	if not src then return nil, nil end

	local armsModel = src:Clone()
	armsModel.Name = "ViewModelArms"
	local mesh = armsModel:FindFirstChild("ArmsMesh", true) or armsModel:FindFirstChildWhichIsA("MeshPart", true)
	if not mesh then
		armsModel:Destroy()
		return nil, nil
	end
	for _, desc in ipairs(armsModel:GetDescendants()) do
		if desc:IsA("LuaSourceContainer") or desc:IsA("Camera") then
			desc:Destroy()
		elseif desc:IsA("BasePart") then
			desc.Anchored = true
			desc.CanCollide = false
			desc.CanTouch = false
			desc.CanQuery = false
			desc.CastShadow = false
			desc.Massless = true
			desc.LocalTransparencyModifier = 0
		end
	end
	if armsScale and math.abs(armsScale - BASE_ARMS_SCALE) > 1e-4 then
		armsModel:ScaleTo(armsModel:GetScale() * (armsScale / BASE_ARMS_SCALE))
	end
	return armsModel, mesh
end

local function createWeaponView(player, tool, template, profile)
	local weaponModel, handleCopy = cloneWeaponModel(template, profile.gunScale)
	local armsModel, armsMesh = cloneArmsModel(profile.armsScale)
	if not (weaponModel and armsModel) then
		if weaponModel then weaponModel:Destroy() end
		if armsModel then armsModel:Destroy() end
		return nil
	end

	local vmRoot = Instance.new("Model")
	vmRoot.Name = "FlyHighWeaponViewModel"
	weaponModel.Parent = vmRoot
	armsModel.Parent = vmRoot

	local rigData = buildRigData(armsMesh)
	local muzzleAtt = handleCopy:FindFirstChild("MuzzleAttachment")

	-- Apply finger/thumb bone transforms once in identity space (finger bones inherit wrist transforms automatically).
	local idGunCF = profile.gunOffset
	local idMeshCF = profile.shoulderOffset * CFrame.new(-rigData.shoulderMidLocal)
	armsMesh.CFrame = idMeshCF
	weaponModel:PivotTo(idGunCF)
	for _, side in ipairs({ "R", "L" }) do
		local handSpec = profile.hands[side]
		local wCF = solveArmIK(rigData, side, idMeshCF, idGunCF, handSpec)
		for fingerName, curlCfg in pairs(handSpec.curls) do
			curlFinger(rigData, side, fingerName, curlCfg[1], curlCfg[2])
		end
		if handSpec.triggerPoint then
			aimChainWorld(rigData, side, "point", wCF, idGunCF, handSpec.triggerPoint)
		end
		if handSpec.thumbChain then
			aimChainWorld(rigData, side, "thumb", wCF, idGunCF, handSpec.thumbChain)
		end
	end

	-- Hide the shooter's live 3P Tool locally; the camera-attached ViewModel replaces it cleanly in first person.
	local originalOpacity = {}
	local function hidePart(part)
		if part:IsA("BasePart") and originalOpacity[part] == nil then
			originalOpacity[part] = part.LocalTransparencyModifier
			part.LocalTransparencyModifier = 1
		end
	end
	local function restorePart(part)
		local opacity = originalOpacity[part]
		if opacity ~= nil then
			part.LocalTransparencyModifier = opacity
			originalOpacity[part] = nil
		end
	end
	for _, part in ipairs(tool:GetDescendants()) do hidePart(part) end
	local partAdded = tool.DescendantAdded:Connect(hidePart)
	local partRemoving = tool.DescendantRemoving:Connect(restorePart)

	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.RespectCanCollide = true
	rayParams.IgnoreWater = true

	local recoilWeight = 0
	local reloadBlend = 0
	local reloadingActive = false
	local walkPhase = 0
	local walkWeight = 0
	local swayYaw = 0
	local swayPitch = 0
	local wallPush = 0
	local prevLook
	local lastTick = os.clock()
	local isMountedFirstPerson = false

	local function updateViewModel()
		local camera = Workspace.CurrentCamera
		if not camera then
			vmRoot.Parent = nil
			isMountedFirstPerson = false
			return
		end

		local firstPerson = camera.CameraType == Enum.CameraType.Custom
			and (camera.Focus.Position - camera.CFrame.Position).Magnitude < 1.25
		isMountedFirstPerson = firstPerson
		if not firstPerson then
			vmRoot.Parent = nil
			prevLook = nil
			return
		end
		if vmRoot.Parent ~= camera then
			vmRoot.Parent = camera
		end

		local now = os.clock()
		local dt = math.clamp(now - lastTick, 0, 0.1)
		lastTick = now

		local camCF = camera.CFrame
		local look = camCF.LookVector
		if prevLook then
			local localPrev = camCF:VectorToObjectSpace(prevLook)
			swayYaw = math.clamp(swayYaw + localPrev.X * 0.45, -0.055, 0.055)
			swayPitch = math.clamp(swayPitch - localPrev.Y * 0.45, -0.045, 0.045)
		end
		prevLook = look
		local swayDecay = math.exp(-dt * 12)
		swayYaw *= swayDecay
		swayPitch *= swayDecay

		local char = player.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		local moving = (hum and hum.MoveDirection.Magnitude or 0) > 0.08
		local targetWalk = moving and 1 or 0
		walkWeight += (targetWalk - walkWeight) * math.min(1, dt * 8)
		walkPhase += dt * (moving and 9.5 or 1.6)

		-- Soft CQB pull-back keeps long barrels from poking visually through gondola railings flush against the player.
		local targetPush = 0
		if char then
			local excluded = { char, vmRoot }
			local obsFolder = Workspace:FindFirstChild("FlyHighObstacles")
			if obsFolder then table.insert(excluded, obsFolder) end
			local largeFolder = Workspace:FindFirstChild("FlyHighLargeChallenges")
			if largeFolder then table.insert(excluded, largeFolder) end
			rayParams.FilterDescendantsInstances = excluded
			local hit = Workspace:Raycast(camCF.Position, look * 2.05, rayParams)
			if hit then
				targetPush = math.clamp((2.05 - hit.Distance) * 0.28, 0, 0.24)
			end
		end
		wallPush += (targetPush - wallPush) * math.min(1, dt * 14)

		recoilWeight = math.max(0, recoilWeight - dt * (profile.recoilRecovery or 10))
		local targetReload = reloadingActive and 1 or 0
		reloadBlend += (targetReload - reloadBlend) * math.min(1, dt * 10)

		local idleX = math.cos(now * 1.6) * 0.003
		local idleY = math.sin(now * 3.2) * 0.004
		local bobX = math.cos(walkPhase) * 0.012 * walkWeight
		local bobY = math.abs(math.sin(walkPhase)) * -0.014 * walkWeight
		local motionCF = CFrame.new(idleX + bobX + swayYaw * 0.45, idleY + bobY + swayPitch * 0.35, wallPush)
			* CFrame.Angles(swayPitch + math.rad(wallPush * 16), -swayYaw, swayYaw * 0.65)

		local rec = profile.recoilOffset * recoilWeight
		local recoilCF = CFrame.new(rec) * CFrame.Angles(math.rad((profile.recoilPitchDeg or 3.5) * recoilWeight), 0, 0)

		local rTarget = profile.reloadOffset
		local reloadCF = CFrame.identity:Lerp(rTarget, reloadBlend)

		local finalGunCF = camCF * profile.gunOffset * motionCF * recoilCF * reloadCF
		local shoulderSway = CFrame.new(swayYaw * 0.12, idleY * 0.5 + bobY * 0.35, 0)
		local finalMeshCF = camCF * profile.shoulderOffset * shoulderSway * CFrame.new(-rigData.shoulderMidLocal)

		armsMesh.CFrame = finalMeshCF
		weaponModel:PivotTo(finalGunCF)
		solveArmIK(rigData, "R", finalMeshCF, finalGunCF, profile.hands.R)
		solveArmIK(rigData, "L", finalMeshCF, finalGunCF, profile.hands.L)
	end

	Run:BindToRenderStep(WEAPON_VISIBILITY_STEP, Enum.RenderPriority.Camera.Value + 5, updateViewModel)
	updateViewModel()

	local function muzzleWorldPosition()
		if not isMountedFirstPerson then return nil end
		if muzzleAtt and muzzleAtt:IsA("Attachment") then
			return muzzleAtt.WorldPosition
		end
		return (handleCopy.CFrame * CFrame.new(0, 0.25, -0.9)).Position
	end

	local function triggerShot()
		recoilWeight = 1
	end

	local function setReloading(active)
		reloadingActive = active == true
	end

	local function destroy()
		Run:UnbindFromRenderStep(WEAPON_VISIBILITY_STEP)
		partAdded:Disconnect()
		partRemoving:Disconnect()
		for part in originalOpacity do restorePart(part) end
		vmRoot:Destroy()
	end

	return {
		muzzleWorldPosition = muzzleWorldPosition,
		triggerShot = triggerShot,
		setReloading = setReloading,
		destroy = destroy,
	}
end

function Presentation.Start(player, remote, owner, _hud, onLocalImpact)
	local AudioMixer = require(script.Parent.AudioMixer)
	local DailyAndShopCatalog = require(script.Parent:WaitForChild("DailyAndShopCatalog"))
	AudioMixer.Bind(player)
	local sfxGroup = AudioMixer.GetGroup("SFX")
	local templates = ReplicatedStorage.FlyHigh.Templates.Weapons
	local audioAssets = ReplicatedStorage.FlyHigh.AudioAssets
	local reloadTemplate = audioAssets:FindFirstChild("WeaponReload")
	local reloadSound = reloadTemplate and reloadTemplate:Clone()
	if reloadSound then
		reloadSound.SoundGroup = sfxGroup
		reloadSound.Parent = owner
	end

	local reloadConnection
	local weaponView
	local function setWeapon(tool)
		if reloadConnection then
			reloadConnection:Disconnect()
			reloadConnection = nil
		end
		if reloadSound then reloadSound:Stop() end
		if weaponView then
			weaponView.destroy()
			weaponView = nil
		end
		local profile = tool and viewProfiles[tool.Name]
		local template = profile and templates:FindFirstChild(tool.Name)
		if template then
			weaponView = createWeaponView(player, tool, template, profile)
		end
		if tool then
			local wasReloading = false
			local function syncReload()
				local reloading = tool:GetAttribute("Reloading") == true
				if reloading == wasReloading then return end
				wasReloading = reloading
				if weaponView then weaponView.setReloading(reloading) end
				if reloadSound then
					if reloading then
						reloadSound.TimePosition = 0
						reloadSound:Play()
					else
						reloadSound:Stop()
					end
				end
			end
			reloadConnection = tool:GetAttributeChangedSignal("Reloading"):Connect(syncReload)
			syncReload()
		end
	end

	local poolFolder = Instance.new("Folder")
	poolFolder.Name = "WeaponAudioPool"
	poolFolder.Parent = owner
	poolFolder:SetAttribute("ShotCount", 0)
	local dead = false

	local function makePoolSound(name, soundId, speed, volume, parent, rangeMin, rangeMax)
		local s = Instance.new("Sound")
		s.Name = name
		s.SoundId = soundId
		s.PlaybackSpeed = speed
		s.Volume = volume
		s.RollOffMinDistance = rangeMin or 12
		s.RollOffMaxDistance = rangeMax or 240
		s.Looped = false
		s.SoundGroup = sfxGroup
		s.Parent = parent
		return s
	end

	local function playTrimmedSound(snd, slot, token, speed, volume, cutSec)
		if not snd then return end
		snd:Stop()
		snd.PlaybackSpeed = speed
		snd.Volume = volume
		snd.TimePosition = 0
		snd:Play()
		if cutSec and cutSec > 0 then
			task.delay(cutSec, function()
				if not dead and slot.token == token and snd.Parent then
					snd:Stop()
				end
			end)
		end
	end

	local shotTemplate = audioAssets:WaitForChild("PistolShot")
	local emitters = {}
	local shotAudioBank = {}
	local index = 0
	for _ = 1, 8 do
		local p = Instance.new("Part")
		p.Name = "ShotEmitter"
		p.Size = Vector3.new(0.1, 0.1, 0.1)
		p.Transparency = 1
		p.Anchored = true
		p.CanCollide = false
		p.CanTouch = false
		p.CanQuery = false
		p.Parent = Workspace
		local s = shotTemplate:Clone()
		s.Name = "Gunshot"
		s.Volume = 0.65
		s.RollOffMinDistance = 10
		s.RollOffMaxDistance = 140
		s.Looped = false
		s.SoundGroup = sfxGroup
		s.Parent = p
		table.insert(emitters, p)
		table.insert(shotAudioBank, {
			token = 0,
			baseShot = s,
			cyanZap = makePoolSound("CyanShotZapSFX", "rbxassetid://9116276051", 1.75, 0.56, p, 10, 140),
			cyanZip = makePoolSound("CyanShotZipSFX", "rbxasset://sounds/electronicpingshort.wav", 2.0, 0.22, p, 10, 140),
			goldBlaze = makePoolSound("GoldShotBlazeSFX", "rbxassetid://9116316301", 1.95, 0.54, p, 10, 140),
			goldSwish = makePoolSound("GoldShotSwishSFX", "rbxassetid://9126283592", 1.72, 0.36, p, 10, 140),
			violetWhomp = makePoolSound("VioletShotWhompSFX", "rbxassetid://9119873304", 1.85, 0.52, p, 10, 140),
			violetPulse = makePoolSound("VioletShotBeepSFX", "rbxassetid://9119100090", 1.62, 0.30, p, 10, 140),
		})
	end

	local impactEmitters = {}
	local impactAudioBank = {}
	local impactIndex = 0
	for _ = 1, 6 do
		local p = Instance.new("Part")
		p.Name = "ImpactEmitter"
		p.Size = Vector3.new(0.1, 0.1, 0.1)
		p.Transparency = 1
		p.Anchored = true
		p.CanCollide = false
		p.CanTouch = false
		p.CanQuery = false
		p.Parent = Workspace
		local killBoom = shotTemplate:Clone()
		killBoom.Name = "KillBoomSFX"
		killBoom.PlaybackSpeed = 0.54
		killBoom.Volume = 0.78
		killBoom.RollOffMinDistance = 16
		killBoom.RollOffMaxDistance = 260
		killBoom.Looped = false
		killBoom.SoundGroup = sfxGroup
		killBoom.Parent = p
		table.insert(impactEmitters, p)
		table.insert(impactAudioBank, {
			token = 0,
			hitTick = makePoolSound("HitTickSFX", "rbxasset://sounds/clickfast.wav", 1.28, 0.62, p),
			hitPunch = makePoolSound("HitPunchSFX", "rbxasset://sounds/switch.wav", 0.72, 0.52, p),
			killBoom = killBoom,
			killChime = makePoolSound("KillChimeSFX", "rbxasset://sounds/electronicpingshort.wav", 1.38, 0.48, p),
			immunePing = makePoolSound("ImmunePingSFX", "rbxasset://sounds/button.wav", 1.9, 0.6, p),
			immuneClank = makePoolSound("ImmuneClankSFX", "rbxasset://sounds/switch.wav", 2.35, 0.68, p),
			cyanZap = makePoolSound("CyanImpactZapSFX", "rbxassetid://9116276051", 1.85, 0.48, p),
			cyanKillZap = makePoolSound("CyanKillZapSFX", "rbxassetid://9116277954", 1.25, 0.58, p),
			cyanShatter = makePoolSound("CyanImpactShatterSFX", "rbxassetid://9114855870", 1.85, 0.28, p),
			goldBlaze = makePoolSound("GoldImpactBlazeSFX", "rbxassetid://9116316301", 1.90, 0.46, p),
			goldChime = makePoolSound("GoldImpactChimeSFX", "rbxasset://sounds/electronicpingshort.wav", 1.55, 0.30, p),
			goldBoom = makePoolSound("GoldKillBoomSFX", "rbxassetid://9125484743", 1.55, 0.45, p),
			violetWhomp = makePoolSound("VioletImpactWhompSFX", "rbxassetid://9119873304", 2.05, 0.46, p),
			violetSparkle = makePoolSound("VioletImpactPixiesSFX", "rbxassetid://1847063040", 1.65, 0.36, p),
		})
	end

	local preload = {}
	if reloadSound then table.insert(preload, reloadSound) end
	for _, slot in ipairs(shotAudioBank) do
		for k, s in pairs(slot) do
			if k ~= "token" and typeof(s) == "Instance" and s:IsA("Sound") then table.insert(preload, s) end
		end
	end
	for _, slot in ipairs(impactAudioBank) do
		for k, s in pairs(slot) do
			if k ~= "token" and typeof(s) == "Instance" and s:IsA("Sound") then table.insert(preload, s) end
		end
	end
	task.spawn(function()
		pcall(function() game:GetService("ContentProvider"):PreloadAsync(preload) end)
	end)

	local function playShotSound(pos, weaponName, tracerId)
		if #emitters == 0 then return end
		index = index % #emitters + 1
		emitters[index].Position = pos
		local bank = shotAudioBank[index]
		bank.token += 1
		local token = bank.token
		local isAK = weaponName == "AK47"
		local jitter = (math.random() - 0.5) * 0.06
		local tid = tracerId or "default"
		local played = {}

		if tid == "cyan_sky" then
			playTrimmedSound(bank.baseShot, bank, token, (isAK and 1.12 or 1.24) + jitter, 0.42, nil)
			playTrimmedSound(bank.cyanZap, bank, token, 1.65 + math.random() * 0.2, 0.56, 0.22)
			playTrimmedSound(bank.cyanZip, bank, token, 1.95 + math.random() * 0.15, 0.22, nil)
			played = { bank.baseShot.Name, bank.cyanZap.Name, bank.cyanZip.Name }
		elseif tid == "dawn_gold" then
			playTrimmedSound(bank.baseShot, bank, token, (isAK and 0.78 or 0.85) + jitter, 0.52, nil)
			playTrimmedSound(bank.goldBlaze, bank, token, 1.85 + math.random() * 0.2, 0.54, 0.20)
			playTrimmedSound(bank.goldSwish, bank, token, 1.65 + math.random() * 0.15, 0.36, 0.20)
			played = { bank.baseShot.Name, bank.goldBlaze.Name, bank.goldSwish.Name }
		elseif tid == "aurora_violet" then
			playTrimmedSound(bank.baseShot, bank, token, (isAK and 0.72 or 0.78) + jitter, 0.38, nil)
			playTrimmedSound(bank.violetWhomp, bank, token, 1.75 + math.random() * 0.2, 0.52, 0.24)
			playTrimmedSound(bank.violetPulse, bank, token, 1.55 + math.random() * 0.17, 0.30, 0.16)
			played = { bank.baseShot.Name, bank.violetWhomp.Name, bank.violetPulse.Name }
		else
			playTrimmedSound(bank.baseShot, bank, token, isAK and 0.90 or 1.00, 0.65, nil)
			played = { bank.baseShot.Name }
		end

		poolFolder:SetAttribute("ShotCount", (poolFolder:GetAttribute("ShotCount") or 0) + 1)
		poolFolder:SetAttribute("LastShotTracer", tid)
		poolFolder:SetAttribute("LastShotSoundIds", table.concat(played, ","))
	end

	local function playImpactSound(kind, pos, tracerId)
		if #impactEmitters == 0 then return end
		impactIndex = impactIndex % #impactEmitters + 1
		impactEmitters[impactIndex].Position = pos
		local bank = impactAudioBank[impactIndex]
		bank.token += 1
		local token = bank.token
		local tid = tracerId or "default"
		local played = {}
		local function playOne(snd, speed, vol, cutSec)
			if not snd then return end
			playTrimmedSound(snd, bank, token, speed or snd.PlaybackSpeed, vol or snd.Volume, cutSec)
			table.insert(played, snd.Name)
		end

		if kind == "Immune" then
			playOne(bank.immunePing, 1.9, 0.6, nil)
			playOne(bank.immuneClank, 2.35, 0.68, nil)
		elseif kind == "Kill" then
			playOne(bank.killBoom, 0.54, 0.78, nil)
			playOne(bank.killChime, 1.38, 0.48, nil)
			if tid == "cyan_sky" then
				playOne(bank.cyanKillZap, 1.25, 0.58, 0.45)
				playOne(bank.cyanShatter, 1.35, 0.46, 0.55)
			elseif tid == "dawn_gold" then
				playOne(bank.goldBoom, 1.55, 0.45, 0.65)
				playOne(bank.goldBlaze, 1.35, 0.55, 0.55)
			elseif tid == "aurora_violet" then
				playOne(bank.violetWhomp, 1.25, 0.55, 0.58)
				playOne(bank.violetSparkle, 1.35, 0.48, 0.58)
			end
		elseif kind == "Hit" then
			playOne(bank.hitTick, 1.28, 0.62, nil)
			playOne(bank.hitPunch, 0.72, 0.52, nil)
			if tid == "cyan_sky" then
				playOne(bank.cyanZap, 1.85, 0.48, 0.22)
				playOne(bank.cyanShatter, 1.85, 0.28, 0.22)
			elseif tid == "dawn_gold" then
				playOne(bank.goldBlaze, 1.90, 0.46, 0.24)
				playOne(bank.goldChime, 1.55, 0.30, nil)
			elseif tid == "aurora_violet" then
				playOne(bank.violetWhomp, 2.05, 0.46, 0.24)
				playOne(bank.violetSparkle, 1.65, 0.36, 0.26)
			end
		end

		poolFolder:SetAttribute("LastImpactTracer", tid)
		poolFolder:SetAttribute("LastImpactKind", kind)
		poolFolder:SetAttribute("LastImpactSoundIds", table.concat(played, ","))
	end

	local function flashModelHighlight(model, fillColor, outlineColor, durationSec)
		if typeof(model) ~= "Instance" or not model:IsA("Model") or not model.Parent then return end
		local prev = model:FindFirstChild("FlyHighImpactHighlight")
		if prev then prev:Destroy() end
		local hl = Instance.new("Highlight")
		hl.Name = "FlyHighImpactHighlight"
		hl.Adornee = model
		hl.DepthMode = Enum.HighlightDepthMode.Occluded
		hl.FillColor = fillColor
		hl.OutlineColor = outlineColor
		hl.FillTransparency = 0.36
		hl.OutlineTransparency = 0.05
		hl.Parent = model
		TweenService:Create(hl, TweenInfo.new(durationSec, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			FillTransparency = 1,
			OutlineTransparency = 1,
		}):Play()
		Debris:AddItem(hl, durationSec + 0.03)
	end

	local function makeVfxPart(name, shape, size, cf, color, transparency)
		local p = Instance.new("Part")
		p.Name = name
		p.Shape = shape
		p.Size = size
		p.CFrame = cf
		p.Color = color
		p.Material = Enum.Material.Neon
		p.Transparency = transparency or 0.1
		p.Anchored = true
		p.CanCollide = false
		p.CanTouch = false
		p.CanQuery = false
		p.CastShadow = false
		p.Parent = Workspace
		return p
	end

	local function emitBurstParticles(pos, color, secondaryColor, sparkCount, smokeCount, sizeScale)
		local host = Instance.new("Part")
		host.Name = "WeaponImpactParticles"
		host.Size = Vector3.new(0.2, 0.2, 0.2)
		host.Transparency = 1
		host.Anchored = true
		host.CanCollide = false
		host.CanTouch = false
		host.CanQuery = false
		host.Position = pos
		host.Parent = Workspace

		local sparks = Instance.new("ParticleEmitter")
		sparks.Name = "ImpactSparks"
		sparks.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		sparks.Color = ColorSequence.new(color, secondaryColor)
		sparks.LightEmission = 1
		sparks.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.45 * sizeScale),
			NumberSequenceKeypoint.new(1, 0),
		})
		sparks.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(1, 1),
		})
		sparks.Speed = NumberRange.new(14 * sizeScale, 32 * sizeScale)
		sparks.Lifetime = NumberRange.new(0.18, 0.34)
		sparks.SpreadAngle = Vector2.new(180, 180)
		sparks.Rate = 0
		sparks.Enabled = false
		sparks.Parent = host
		sparks:Emit(sparkCount)

		if smokeCount > 0 then
			local smoke = Instance.new("ParticleEmitter")
			smoke.Name = "ImpactSmoke"
			smoke.Texture = "rbxasset://textures/particles/smoke_main.dds"
			smoke.Color = ColorSequence.new(secondaryColor, Color3.fromRGB(70, 78, 95))
			smoke.Size = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1.4 * sizeScale),
				NumberSequenceKeypoint.new(1, 3.6 * sizeScale),
			})
			smoke.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.38),
				NumberSequenceKeypoint.new(1, 1),
			})
			smoke.Speed = NumberRange.new(4, 12)
			smoke.Lifetime = NumberRange.new(0.32, 0.58)
			smoke.SpreadAngle = Vector2.new(180, 180)
			smoke.Rate = 0
			smoke.Enabled = false
			smoke.Parent = host
			smoke:Emit(smokeCount)
		end

		Debris:AddItem(host, 0.85)
	end

	local function spawnLightningArc(originPos, endPos, color, duration)
		local p1 = originPos:Lerp(endPos, 0.33) + Vector3.new(math.random(-11, 11) / 10, math.random(-11, 11) / 10, math.random(-11, 11) / 10)
		local p2 = originPos:Lerp(endPos, 0.67) + Vector3.new(math.random(-11, 11) / 10, math.random(-11, 11) / 10, math.random(-11, 11) / 10)
		local pts = { originPos, p1, p2, endPos }
		for s = 1, 3 do
			local a, b = pts[s], pts[s + 1]
			local segVec = b - a
			local segLen = math.max(0.1, segVec.Magnitude)
			local seg = makeVfxPart("WeaponTracerArc", Enum.PartType.Block, Vector3.new(0.11, 0.11, segLen), CFrame.lookAt(a:Lerp(b, 0.5), b), color, 0.04)
			TweenService:Create(seg, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Size = Vector3.new(0.03, 0.03, segLen),
				Transparency = 1,
			}):Play()
			Debris:AddItem(seg, duration + 0.03)
		end
	end

	local function spawnTracerPulseRing(cf, primaryColor, secondaryColor, tracerId, alt)
		if player:GetAttribute("ReduceHUDMotion") == true then return end
		local cam = Workspace.CurrentCamera
		if not cam or (cf.Position - cam.CFrame.Position).Magnitude > 160 then return end
		local col = primaryColor
		local initW = 0.55
		local endW = 2.3
		local thickness = 0.10
		local dur = 0.18
		local ringCF = cf * CFrame.Angles(0, math.pi / 2, 0)
		if tracerId == "dawn_gold" then
			initW = 0.60
			endW = 2.5
			thickness = 0.12
			dur = 0.20
			col = alt and secondaryColor or primaryColor
		elseif tracerId == "aurora_violet" then
			initW = 0.65
			endW = 2.6
			thickness = 0.11
			dur = 0.22
			col = alt and secondaryColor or primaryColor
			ringCF = cf * CFrame.Angles(math.rad(alt and -25 or 25), math.pi / 2, 0)
		end
		local ring = makeVfxPart("TracerPulseRing", Enum.PartType.Cylinder, Vector3.new(thickness, initW, initW), ringCF, col, 0.18)
		TweenService:Create(ring, TweenInfo.new(dur, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = Vector3.new(0.05, endW, endW),
			Transparency = 1,
		}):Play()
		Debris:AddItem(ring, dur + 0.03)
	end

	local function spawnImpactEffect(pos, shotDir, impact, tracerId)
		if type(impact) ~= "table" or type(impact.kind) ~= "string" then return end
		local kind = impact.kind
		local normal = (typeof(impact.normal) == "Vector3" and impact.normal.Magnitude > 0.01) and impact.normal.Unit or (-shotDir)
		local accent = typeof(impact.color) == "Color3" and impact.color or Color3.fromRGB(255, 196, 70)
		local tid = tracerId or "default"
		local reduceMotion = player:GetAttribute("ReduceHUDMotion") == true

		playImpactSound(kind, pos, tid)

		local refAxis = math.abs(normal.Y) > 0.9 and Vector3.xAxis or Vector3.yAxis
		local t1 = normal:Cross(refAxis).Unit
		local t2 = normal:Cross(t1).Unit

		if kind == "Hit" then
			if tid == "cyan_sky" then
				local core = makeVfxPart("TracerImpactCore", Enum.PartType.Ball, Vector3.new(0.5, 0.5, 0.5), CFrame.new(pos), Color3.fromRGB(224, 249, 255), 0.05)
				TweenService:Create(core, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = Vector3.new(3.0, 3.0, 3.0), Transparency = 1 }):Play()
				Debris:AddItem(core, 0.20)
				if not reduceMotion then
					local ring = makeVfxPart("TracerImpactRing", Enum.PartType.Cylinder, Vector3.new(0.14, 1.1, 1.1), CFrame.lookAt(pos, pos + normal) * CFrame.Angles(0, math.pi / 2, 0), Color3.fromRGB(56, 189, 248), 0.12)
					TweenService:Create(ring, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = Vector3.new(0.06, 5.8, 5.8), Transparency = 1 }):Play()
					Debris:AddItem(ring, 0.24)
					for a = 1, 4 do
						local ang = (a / 4) * math.pi * 2 + math.random() * 0.5
						local radial = (normal * 0.35 + t1 * math.cos(ang) + t2 * math.sin(ang)).Unit
						spawnLightningArc(pos, pos + radial * (4.5 + math.random() * 2.0), a % 2 == 0 and Color3.fromRGB(224, 249, 255) or Color3.fromRGB(56, 189, 248), 0.20)
					end
				end
				for s = 1, 6 do
					local sd = (normal + Vector3.new(math.random(-80, 80) / 100, math.random(-80, 80) / 100, math.random(-80, 80) / 100)).Unit
					local shard = makeVfxPart("TracerImpactShard", Enum.PartType.Block, Vector3.new(0.16, 0.16, 0.72), CFrame.lookAt(pos, pos + sd), s % 2 == 0 and Color3.fromRGB(224, 249, 255) or Color3.fromRGB(56, 189, 248), 0.05)
					TweenService:Create(shard, TweenInfo.new(0.20, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
						CFrame = CFrame.lookAt(pos + sd * 4.2, pos + sd * 5.2),
						Size = Vector3.new(0.04, 0.04, 0.22),
						Transparency = 1,
					}):Play()
					Debris:AddItem(shard, 0.22)
				end
				emitBurstParticles(pos, Color3.fromRGB(224, 249, 255), Color3.fromRGB(2, 132, 199), 14, 0, 1.05)
				flashModelHighlight(impact.target, Color3.fromRGB(56, 189, 248), Color3.fromRGB(224, 249, 255), 0.15)
			elseif tid == "dawn_gold" then
				local core = makeVfxPart("TracerImpactCore", Enum.PartType.Ball, Vector3.new(0.55, 0.55, 0.55), CFrame.new(pos), Color3.fromRGB(255, 250, 214), 0.04)
				TweenService:Create(core, TweenInfo.new(0.20, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = Vector3.new(3.2, 3.2, 3.2), Transparency = 1 }):Play()
				Debris:AddItem(core, 0.22)
				if not reduceMotion then
					local ring = makeVfxPart("TracerImpactRing", Enum.PartType.Cylinder, Vector3.new(0.16, 1.0, 1.0), CFrame.lookAt(pos, pos + normal) * CFrame.Angles(0, math.pi / 2, 0), Color3.fromRGB(249, 115, 22), 0.12)
					TweenService:Create(ring, TweenInfo.new(0.24, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = Vector3.new(0.06, 5.6, 5.6), Transparency = 1 }):Play()
					Debris:AddItem(ring, 0.26)
					for b = 0, 3 do
						local ang = b * (math.pi / 4)
						local rayDir = (t1 * math.cos(ang) + t2 * math.sin(ang)).Unit
						local w = (b % 2 == 0) and 0.20 or 0.14
						local ray = makeVfxPart("TracerImpactStarRay", Enum.PartType.Block, Vector3.new(w, w, 0.6), CFrame.lookAt(pos, pos + rayDir), b % 2 == 0 and Color3.fromRGB(255, 248, 200) or Color3.fromRGB(250, 204, 21), 0.04)
						TweenService:Create(ray, TweenInfo.new(0.24, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
							Size = Vector3.new(0.04, 0.04, 7.2),
							Transparency = 1,
						}):Play()
						Debris:AddItem(ray, 0.26)
					end
				end
				for s = 1, 6 do
					local sd = (normal + Vector3.new(math.random(-80, 80) / 100, math.random(-80, 80) / 100, math.random(-80, 80) / 100)).Unit
					local ember = makeVfxPart("TracerImpactEmber", Enum.PartType.Block, Vector3.new(0.18, 0.18, 0.75), CFrame.lookAt(pos, pos + sd), s % 2 == 0 and Color3.fromRGB(250, 204, 21) or Color3.fromRGB(249, 115, 22), 0.05)
					TweenService:Create(ember, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
						CFrame = CFrame.lookAt(pos + sd * 4.4, pos + sd * 5.4),
						Size = Vector3.new(0.05, 0.05, 0.24),
						Transparency = 1,
					}):Play()
					Debris:AddItem(ember, 0.24)
				end
				emitBurstParticles(pos, Color3.fromRGB(254, 240, 138), Color3.fromRGB(249, 115, 22), 15, 3, 1.1)
				flashModelHighlight(impact.target, Color3.fromRGB(250, 204, 21), Color3.fromRGB(255, 248, 214), 0.16)
			elseif tid == "aurora_violet" then
				local core = makeVfxPart("TracerImpactCore", Enum.PartType.Ball, Vector3.new(0.5, 0.5, 0.5), CFrame.new(pos), Color3.fromRGB(245, 224, 255), 0.04)
				TweenService:Create(core, TweenInfo.new(0.20, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = Vector3.new(3.0, 3.0, 3.0), Transparency = 1 }):Play()
				Debris:AddItem(core, 0.22)
				if not reduceMotion then
					for rIdx, spec in ipairs({ { 32, Color3.fromRGB(192, 132, 252) }, { -32, Color3.fromRGB(236, 72, 153) } }) do
						local tilt = (CFrame.lookAt(pos, pos + normal) * CFrame.Angles(math.rad(spec[1]), 0, math.rad(rIdx * 35)) * CFrame.Angles(0, math.pi / 2, 0))
						local ring = makeVfxPart("TracerImpactRiftRing", Enum.PartType.Cylinder, Vector3.new(0.14, 0.9, 0.9), tilt, spec[2], 0.10)
						TweenService:Create(ring, TweenInfo.new(0.26, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
							Size = Vector3.new(0.06, 6.0, 6.0),
							CFrame = tilt * CFrame.Angles(math.rad(65), 0, 0),
							Transparency = 1,
						}):Play()
						Debris:AddItem(ring, 0.28)
					end
				end
				for s = 1, 6 do
					local sd = (normal + Vector3.new(math.random(-85, 85) / 100, math.random(-85, 85) / 100, math.random(-85, 85) / 100)).Unit
					local col = s % 3 == 0 and Color3.fromRGB(255, 240, 255) or (s % 2 == 0 and Color3.fromRGB(236, 72, 153) or Color3.fromRGB(192, 132, 252))
					local crystal = makeVfxPart("TracerImpactCrystal", Enum.PartType.Block, Vector3.new(0.32, 0.32, 0.32), CFrame.new(pos) * CFrame.Angles(math.pi / 4, math.pi / 4, 0), col, 0.05)
					TweenService:Create(crystal, TweenInfo.new(0.24, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
						CFrame = CFrame.new(pos + sd * 4.5) * CFrame.Angles(math.pi * 1.4, math.pi * 1.1, 0),
						Size = Vector3.new(0.08, 0.08, 0.08),
						Transparency = 1,
					}):Play()
					Debris:AddItem(crystal, 0.26)
				end
				emitBurstParticles(pos, Color3.fromRGB(232, 196, 255), Color3.fromRGB(236, 72, 153), 15, 2, 1.1)
				flashModelHighlight(impact.target, Color3.fromRGB(192, 132, 252), Color3.fromRGB(236, 72, 153), 0.16)
			else
				local core = makeVfxPart("WeaponHitBurst", Enum.PartType.Ball, Vector3.new(0.45, 0.45, 0.45), CFrame.new(pos), Color3.fromRGB(255, 226, 112), 0.08)
				TweenService:Create(core, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					Size = Vector3.new(2.6, 2.6, 2.6),
					Transparency = 1,
				}):Play()
				Debris:AddItem(core, 0.18)

				for s = 1, 5 do
					local spreadDir = (normal + Vector3.new(math.random(-70, 70) / 100, math.random(-70, 70) / 100, math.random(-70, 70) / 100)).Unit
					local shard = makeVfxPart("WeaponHitSpark", Enum.PartType.Block, Vector3.new(0.16, 0.16, 0.65), CFrame.lookAt(pos, pos + spreadDir), s % 2 == 0 and Color3.fromRGB(255, 240, 150) or accent, 0.05)
					TweenService:Create(shard, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
						CFrame = CFrame.lookAt(pos + spreadDir * 3.4, pos + spreadDir * 4.4),
						Size = Vector3.new(0.05, 0.05, 0.25),
						Transparency = 1,
					}):Play()
					Debris:AddItem(shard, 0.2)
				end
				emitBurstParticles(pos, Color3.fromRGB(255, 232, 128), accent, 9, 0, 0.9)
				flashModelHighlight(impact.target, Color3.fromRGB(255, 224, 102), Color3.new(1, 1, 1), 0.13)
			end

		elseif kind == "Kill" then
			if tid == "cyan_sky" then
				local inner = makeVfxPart("TracerImpactKillCore", Enum.PartType.Ball, Vector3.new(1.0, 1.0, 1.0), CFrame.new(pos), Color3.fromRGB(232, 252, 255), 0.04)
				TweenService:Create(inner, TweenInfo.new(0.24, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = Vector3.new(6.0, 6.0, 6.0), Transparency = 1 }):Play()
				Debris:AddItem(inner, 0.26)
				local outer = makeVfxPart("TracerImpactKillNova", Enum.PartType.Ball, Vector3.new(1.4, 1.4, 1.4), CFrame.new(pos), Color3.fromRGB(56, 189, 248), 0.18)
				TweenService:Create(outer, TweenInfo.new(0.34, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = Vector3.new(10.5, 10.5, 10.5), Transparency = 1 }):Play()
				Debris:AddItem(outer, 0.36)
				if not reduceMotion then
					for rIdx, spec in ipairs({ { 18, Color3.fromRGB(224, 249, 255) }, { -26, Color3.fromRGB(2, 132, 199) } }) do
						local rcf = CFrame.lookAt(pos, pos + normal) * CFrame.Angles(math.rad(spec[1]), 0, math.rad(rIdx * 40)) * CFrame.Angles(0, math.pi / 2, 0)
						local ring = makeVfxPart("TracerImpactKillRing", Enum.PartType.Cylinder, Vector3.new(0.24, 1.6, 1.6), rcf, spec[2], 0.14)
						TweenService:Create(ring, TweenInfo.new(0.34, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = Vector3.new(0.08, 13.5, 13.5), Transparency = 1 }):Play()
						Debris:AddItem(ring, 0.36)
					end
					for a = 1, 6 do
						local phi = (a / 6) * math.pi * 2 + math.random() * 0.35
						local radial = Vector3.new(math.cos(phi), (math.random() - 0.3) * 0.85, math.sin(phi)).Unit
						spawnLightningArc(pos, pos + radial * math.random(8, 12), a % 2 == 0 and Color3.fromRGB(224, 249, 255) or Color3.fromRGB(56, 189, 248), 0.28)
					end
				end
				for k = 1, 10 do
					local phi = (k / 10) * math.pi * 2 + math.random() * 0.4
					local radial = Vector3.new(math.cos(phi), (math.random() - 0.35) * 0.9, math.sin(phi)).Unit
					local piece = makeVfxPart("TracerImpactKillShard", Enum.PartType.Block, Vector3.new(0.55, 0.45, 0.85), CFrame.lookAt(pos, pos + radial), k % 2 == 0 and Color3.fromRGB(224, 249, 255) or Color3.fromRGB(56, 189, 248), 0.05)
					TweenService:Create(piece, TweenInfo.new(0.40, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
						CFrame = CFrame.new(pos + radial * math.random(8, 14)) * CFrame.Angles(math.random() * 4, math.random() * 4, math.random() * 4),
						Size = Vector3.new(0.12, 0.12, 0.12),
						Transparency = 1,
					}):Play()
					Debris:AddItem(piece, 0.42)
				end
				emitBurstParticles(pos, Color3.fromRGB(224, 249, 255), Color3.fromRGB(56, 189, 248), 24, 6, 1.5)
			elseif tid == "dawn_gold" then
				local inner = makeVfxPart("TracerImpactKillCore", Enum.PartType.Ball, Vector3.new(1.2, 1.2, 1.2), CFrame.new(pos), Color3.fromRGB(255, 252, 224), 0.04)
				TweenService:Create(inner, TweenInfo.new(0.26, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = Vector3.new(6.6, 6.6, 6.6), Transparency = 1 }):Play()
				Debris:AddItem(inner, 0.28)
				local outer = makeVfxPart("TracerImpactKillNova", Enum.PartType.Ball, Vector3.new(1.5, 1.5, 1.5), CFrame.new(pos), Color3.fromRGB(249, 115, 22), 0.18)
				TweenService:Create(outer, TweenInfo.new(0.36, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = Vector3.new(11.2, 11.2, 11.2), Transparency = 1 }):Play()
				Debris:AddItem(outer, 0.38)
				if not reduceMotion then
					local ring = makeVfxPart("TracerImpactKillRing", Enum.PartType.Cylinder, Vector3.new(0.24, 1.8, 1.8), CFrame.lookAt(pos, pos + normal) * CFrame.Angles(0, math.pi / 2, 0), Color3.fromRGB(250, 204, 21), 0.12)
					TweenService:Create(ring, TweenInfo.new(0.34, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = Vector3.new(0.08, 14.2, 14.2), Transparency = 1 }):Play()
					Debris:AddItem(ring, 0.36)
					for b = 1, 6 do
						local phi = (b / 6) * math.pi * 2
						local rayDir = (t1 * math.cos(phi) + t2 * math.sin(phi) + normal * (b % 2 == 0 and 0.35 or -0.25)).Unit
						local rayLen = 13 + (b % 2) * 3
						local ray = makeVfxPart("TracerImpactKillStarRay", Enum.PartType.Block, Vector3.new(0.28, 0.28, 1.0), CFrame.lookAt(pos + rayDir * 0.5, pos + rayDir * 1.5), b % 2 == 0 and Color3.fromRGB(255, 248, 200) or Color3.fromRGB(250, 204, 21), 0.04)
						TweenService:Create(ray, TweenInfo.new(0.32, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
							CFrame = CFrame.lookAt(pos + rayDir * (rayLen * 0.5), pos + rayDir * rayLen),
							Size = Vector3.new(0.05, 0.05, rayLen),
							Transparency = 1,
						}):Play()
						Debris:AddItem(ray, 0.34)
					end
				end
				for k = 1, 10 do
					local phi = (k / 10) * math.pi * 2 + math.random() * 0.4
					local radial = Vector3.new(math.cos(phi), (math.random() - 0.35) * 0.9, math.sin(phi)).Unit
					local piece = makeVfxPart("TracerImpactKillDebris", Enum.PartType.Block, Vector3.new(0.6, 0.5, 0.8), CFrame.lookAt(pos, pos + radial), k % 2 == 0 and Color3.fromRGB(250, 204, 21) or Color3.fromRGB(249, 115, 22), 0.05)
					TweenService:Create(piece, TweenInfo.new(0.42, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
						CFrame = CFrame.new(pos + radial * math.random(8, 14)) * CFrame.Angles(math.random() * 4, math.random() * 4, math.random() * 4),
						Size = Vector3.new(0.14, 0.14, 0.14),
						Transparency = 1,
					}):Play()
					Debris:AddItem(piece, 0.44)
				end
				emitBurstParticles(pos, Color3.fromRGB(254, 240, 138), Color3.fromRGB(249, 115, 22), 24, 8, 1.55)
			elseif tid == "aurora_violet" then
				local inner = makeVfxPart("TracerImpactKillCore", Enum.PartType.Ball, Vector3.new(1.1, 1.1, 1.1), CFrame.new(pos), Color3.fromRGB(248, 228, 255), 0.04)
				TweenService:Create(inner, TweenInfo.new(0.24, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = Vector3.new(6.4, 6.4, 6.4), Transparency = 1 }):Play()
				Debris:AddItem(inner, 0.26)
				local outer = makeVfxPart("TracerImpactKillNova", Enum.PartType.Ball, Vector3.new(1.5, 1.5, 1.5), CFrame.new(pos), Color3.fromRGB(192, 132, 252), 0.20)
				TweenService:Create(outer, TweenInfo.new(0.36, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = Vector3.new(11.2, 11.2, 11.2), Transparency = 1 }):Play()
				Debris:AddItem(outer, 0.38)
				if not reduceMotion then
					for rIdx, spec in ipairs({ { 30, 0, Color3.fromRGB(192, 132, 252) }, { -35, 55, Color3.fromRGB(236, 72, 153) }, { 65, -40, Color3.fromRGB(240, 210, 255) } }) do
						local tilt = CFrame.lookAt(pos, pos + normal) * CFrame.Angles(math.rad(spec[1]), math.rad(spec[2]), 0) * CFrame.Angles(0, math.pi / 2, 0)
						local ring = makeVfxPart("TracerImpactKillGyroRing", Enum.PartType.Cylinder, Vector3.new(0.20, 1.4, 1.4), tilt, spec[3], 0.10)
						TweenService:Create(ring, TweenInfo.new(0.36, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
							Size = Vector3.new(0.06, 14.5, 14.5),
							CFrame = tilt * CFrame.Angles(math.rad(80), math.rad(rIdx * 30), 0),
							Transparency = 1,
						}):Play()
						Debris:AddItem(ring, 0.38)
					end
				end
				for k = 1, 10 do
					local phi = (k / 10) * math.pi * 2 + math.random() * 0.4
					local radial = Vector3.new(math.cos(phi), (math.random() - 0.35) * 0.9, math.sin(phi)).Unit
					local col = k % 3 == 0 and Color3.fromRGB(255, 240, 255) or (k % 2 == 0 and Color3.fromRGB(236, 72, 153) or Color3.fromRGB(192, 132, 252))
					local crystal = makeVfxPart("TracerImpactKillCrystal", Enum.PartType.Block, Vector3.new(0.65, 0.65, 0.65), CFrame.new(pos) * CFrame.Angles(math.pi / 4, math.pi / 4, 0), col, 0.05)
					TweenService:Create(crystal, TweenInfo.new(0.42, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
						CFrame = CFrame.new(pos + radial * math.random(8, 14)) * CFrame.Angles(math.pi * 1.8, math.pi * 1.4, 0),
						Size = Vector3.new(0.12, 0.12, 0.12),
						Transparency = 1,
					}):Play()
					Debris:AddItem(crystal, 0.44)
				end
				emitBurstParticles(pos, Color3.fromRGB(240, 210, 255), Color3.fromRGB(236, 72, 153), 24, 8, 1.55)
			else
				local inner = makeVfxPart("WeaponKillCore", Enum.PartType.Ball, Vector3.new(0.9, 0.9, 0.9), CFrame.new(pos), Color3.fromRGB(255, 248, 210), 0.05)
				TweenService:Create(inner, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					Size = Vector3.new(5.2, 5.2, 5.2),
					Transparency = 1,
				}):Play()
				Debris:AddItem(inner, 0.24)

				local outer = makeVfxPart("WeaponKillExplosion", Enum.PartType.Ball, Vector3.new(1.2, 1.2, 1.2), CFrame.new(pos), accent, 0.22)
				TweenService:Create(outer, TweenInfo.new(0.32, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					Size = Vector3.new(9.2, 9.2, 9.2),
					Transparency = 1,
				}):Play()
				Debris:AddItem(outer, 0.34)

				local ring = makeVfxPart("WeaponKillShockRing", Enum.PartType.Cylinder, Vector3.new(0.22, 1.6, 1.6), CFrame.lookAt(pos, pos + normal) * CFrame.Angles(0, math.pi / 2, 0), Color3.fromRGB(255, 214, 102), 0.18)
				TweenService:Create(ring, TweenInfo.new(0.30, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					Size = Vector3.new(0.08, 11.5, 11.5),
					Transparency = 1,
				}):Play()
				Debris:AddItem(ring, 0.32)

				for k = 1, 9 do
					local phi = (k / 9) * math.pi * 2 + math.random() * 0.4
					local radial = Vector3.new(math.cos(phi), (math.random() - 0.35) * 0.9, math.sin(phi)).Unit
					local piece = makeVfxPart("WeaponKillDebris", Enum.PartType.Block, Vector3.new(0.55, 0.45, 0.75), CFrame.lookAt(pos, pos + radial), k % 3 == 0 and Color3.fromRGB(255, 210, 88) or accent, 0.05)
					TweenService:Create(piece, TweenInfo.new(0.38, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
						CFrame = CFrame.new(pos + radial * math.random(7, 13)) * CFrame.Angles(math.random() * 4, math.random() * 4, math.random() * 4),
						Size = Vector3.new(0.12, 0.12, 0.12),
						Transparency = 1,
					}):Play()
					Debris:AddItem(piece, 0.4)
				end
				emitBurstParticles(pos, Color3.fromRGB(255, 232, 130), accent, 18, 8, 1.45)
			end

		elseif kind == "Immune" then
			local shieldCF = CFrame.lookAt(pos, pos + normal) * CFrame.Angles(0, math.pi / 2, 0)
			local disc = makeVfxPart("WeaponImmuneShieldDisc", Enum.PartType.Cylinder, Vector3.new(0.16, 1.1, 1.1), shieldCF, Color3.fromRGB(125, 211, 252), 0.25)
			TweenService:Create(disc, TweenInfo.new(0.24, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Size = Vector3.new(0.08, 5.4, 5.4),
				Transparency = 1,
			}):Play()
			Debris:AddItem(disc, 0.26)

			local outerRing = makeVfxPart("WeaponImmuneShieldHalo", Enum.PartType.Cylinder, Vector3.new(0.12, 1.3, 1.3), shieldCF, Color3.fromRGB(224, 242, 254), 0.15)
			TweenService:Create(outerRing, TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Size = Vector3.new(0.06, 6.8, 6.8),
				Transparency = 1,
			}):Play()
			Debris:AddItem(outerRing, 0.3)

			local reflect = shotDir - 2 * shotDir:Dot(normal) * normal
			local rDir = reflect.Magnitude > 0.05 and reflect.Unit or normal
			local ricochetStart = pos + normal * 0.25
			local ricochetEnd = ricochetStart + rDir * 16
			local bolt = makeVfxPart("WeaponRicochetBolt", Enum.PartType.Ball, Vector3.new(0.2, 0.2, 1.15), CFrame.lookAt(ricochetStart, ricochetEnd), Color3.fromRGB(224, 242, 254), 0.02)
			local ra0 = Instance.new("Attachment", bolt)
			ra0.Position = Vector3.new(-0.08, 0, 0.35)
			local ra1 = Instance.new("Attachment", bolt)
			ra1.Position = Vector3.new(0.08, 0, 0.35)
			local rTrail = Instance.new("Trail", bolt)
			rTrail.Attachment0 = ra0
			rTrail.Attachment1 = ra1
			rTrail.FaceCamera = true
			rTrail.Lifetime = 0.14
			rTrail.LightEmission = 1
			rTrail.Color = ColorSequence.new(Color3.fromRGB(224, 242, 254), Color3.fromRGB(56, 189, 248))
			rTrail.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.08), NumberSequenceKeypoint.new(1, 1) })
			TweenService:Create(bolt, TweenInfo.new(0.16, Enum.EasingStyle.Linear), {
				CFrame = CFrame.lookAt(ricochetEnd, ricochetEnd + rDir),
				Transparency = 1,
			}):Play()
			Debris:AddItem(bolt, 0.22)

			for r = 1, 6 do
				local coneDir = (rDir + Vector3.new(math.random(-65, 65) / 100, math.random(-65, 65) / 100, math.random(-65, 65) / 100)).Unit
				local spark = makeVfxPart("WeaponImmuneSpark", Enum.PartType.Block, Vector3.new(0.14, 0.14, 0.72), CFrame.lookAt(ricochetStart, ricochetStart + coneDir), r % 2 == 0 and Color3.fromRGB(240, 249, 255) or Color3.fromRGB(56, 189, 248), 0.04)
				TweenService:Create(spark, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					CFrame = CFrame.lookAt(ricochetStart + coneDir * 4.8, ricochetStart + coneDir * 5.8),
					Size = Vector3.new(0.05, 0.05, 0.2),
					Transparency = 1,
				}):Play()
				Debris:AddItem(spark, 0.24)
			end
			emitBurstParticles(pos, Color3.fromRGB(224, 242, 254), Color3.fromRGB(56, 189, 248), 12, 0, 1.05)
			flashModelHighlight(impact.target, Color3.fromRGB(125, 211, 252), Color3.fromRGB(224, 242, 254), 0.16)
		end
	end

	local active = {}
	local event = remote.OnClientEvent:Connect(function(shooter, origin, target, impact)
		if dead or typeof(origin) ~= "Vector3" or typeof(target) ~= "Vector3" then return end
		local camera = Workspace.CurrentCamera
		if not camera or (origin - camera.CFrame.Position).Magnitude > 180 then return end

		local start = origin
		local firstPersonShot = false
		if shooter == player then
			if weaponView then weaponView.triggerShot() end
			if player.CameraMode == Enum.CameraMode.LockFirstPerson then
				local vmMuzzle = weaponView and weaponView.muzzleWorldPosition()
				if vmMuzzle then
					start = vmMuzzle
					firstPersonShot = true
				end
			end
		end

		local delta = target - start
		if delta.Magnitude < 0.01 then return end
		local direction = delta.Unit
		local distance = delta.Magnitude

		local tracerAttr = shooter and shooter:GetAttribute("EquippedTracer")
		local tracerDef = if type(tracerAttr) == "string" and tracerAttr ~= ""
			then DailyAndShopCatalog.GetCosmetic("tracer", tracerAttr)
			else nil
		local tracerId = tracerDef and tracerDef.id or "default"
		local isCosmetic = tracerDef ~= nil
		local tool = shooter and shooter.Character and shooter.Character:FindFirstChildOfClass("Tool")
		playShotSound(start, tool and tool.Name or "Pistol", tracerId)

		local primaryColor = if tracerDef then tracerDef.primaryColor else Color3.fromRGB(255, 206, 72)
		local secondaryColor = if tracerDef then tracerDef.secondaryColor else Color3.fromRGB(224, 108, 24)
		local coreColor = if tracerDef
			then primaryColor:Lerp(Color3.new(1, 1, 1), 0.62)
			else Color3.fromRGB(255, 248, 214)

		local flashSize = firstPersonShot and Vector3.new(0.20, 0.20, 0.20) or Vector3.new(0.32, 0.32, 0.32)
		local flash = Instance.new("Part")
		flash.Name = "WeaponMuzzleFlash"
		flash.Shape = Enum.PartType.Ball
		flash.Size = flashSize
		flash.Color = coreColor
		flash.Material = Enum.Material.Neon
		flash.Transparency = 0.05
		flash.Position = start
		flash.Anchored = true
		flash.CanCollide = false
		flash.CanTouch = false
		flash.CanQuery = false
		flash.CastShadow = false
		flash.Parent = Workspace
		local flashHalo = Instance.new("Part")
		flashHalo.Name = "WeaponMuzzleHalo"
		flashHalo.Shape = Enum.PartType.Ball
		flashHalo.Size = flashSize * 1.9
		flashHalo.Color = primaryColor
		flashHalo.Material = Enum.Material.Neon
		flashHalo.Transparency = 0.35
		flashHalo.Position = start
		flashHalo.Anchored = true
		flashHalo.CanCollide = false
		flashHalo.CanTouch = false
		flashHalo.CanQuery = false
		flashHalo.CastShadow = false
		flashHalo.Parent = Workspace
		local light = Instance.new("PointLight")
		light.Color = primaryColor
		light.Brightness = 2.0
		light.Range = 8
		light.Parent = flash
		TweenService:Create(flash, TweenInfo.new(0.07, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = flashSize * 0.35,
			Transparency = 1,
		}):Play()
		TweenService:Create(flashHalo, TweenInfo.new(0.07, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = flashSize * 2.35,
			Transparency = 1,
		}):Play()
		Debris:AddItem(flash, 0.09)
		Debris:AddItem(flashHalo, 0.09)

		local upAxis = math.abs(direction.Y) > 0.995 and Vector3.xAxis or Vector3.yAxis
		local originCF = CFrame.lookAt(start, start + direction, upAxis)
		local minStart = math.min(0.35, distance * 0.1)

		local root = Instance.new("Part")
		root.Name = "FlyingBulletTracer"
		root.Size = Vector3.new(0.1, 0.1, 0.1)
		root.Transparency = 1
		root.Anchored = true
		root.CanCollide = false
		root.CanTouch = false
		root.CanQuery = false
		root.CastShadow = false
		root.CFrame = originCF

		local originAtt = Instance.new("Attachment", root)
		originAtt.Name = "TracerOrigin"
		originAtt.Position = Vector3.new(0, 0, -minStart)
		local tailAtt = Instance.new("Attachment", root)
		tailAtt.Name = "TracerTail"
		tailAtt.Position = originAtt.Position
		local headAtt = Instance.new("Attachment", root)
		headAtt.Name = "TracerHead"
		headAtt.Position = originAtt.Position

		local coreW0 = 0.07
		local coreW1 = isCosmetic and 0.34 or 0.26
		local coreBeam = Instance.new("Beam")
		coreBeam.Name = "BulletCoreBeam"
		coreBeam.Attachment0 = tailAtt
		coreBeam.Attachment1 = headAtt
		coreBeam.FaceCamera = true
		coreBeam.LightEmission = 1
		coreBeam.LightInfluence = 0
		coreBeam.Segments = 1
		coreBeam.Width0 = coreW0
		coreBeam.Width1 = coreW1
		coreBeam.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, primaryColor),
			ColorSequenceKeypoint.new(0.55, coreColor),
			ColorSequenceKeypoint.new(1, Color3.new(1, 1, 1)),
		})
		coreBeam.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.22, 0.08),
			NumberSequenceKeypoint.new(0.9, 0),
			NumberSequenceKeypoint.new(1, 0.05),
		})
		coreBeam.Parent = root

		local auraW0 = 0.16
		local auraW1 = isCosmetic and 0.96 or 0.72
		local auraBeam = Instance.new("Beam")
		auraBeam.Name = "BulletAuraBeam"
		auraBeam.Attachment0 = tailAtt
		auraBeam.Attachment1 = headAtt
		auraBeam.FaceCamera = true
		auraBeam.LightEmission = 0.42
		auraBeam.LightInfluence = 0
		auraBeam.Segments = 1
		auraBeam.Width0 = auraW0
		auraBeam.Width1 = auraW1
		auraBeam.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, secondaryColor),
			ColorSequenceKeypoint.new(0.55, primaryColor),
			ColorSequenceKeypoint.new(1, coreColor),
		})
		auraBeam.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.2, 0.45),
			NumberSequenceKeypoint.new(0.8, 0.18),
			NumberSequenceKeypoint.new(1, 0.32),
		})
		auraBeam.Parent = root

		local traceW0 = 0.07
		local traceW1 = isCosmetic and 0.22 or 0.16
		local traceBeam = Instance.new("Beam")
		traceBeam.Name = "BulletTraceBeam"
		traceBeam.Attachment0 = originAtt
		traceBeam.Attachment1 = headAtt
		traceBeam.FaceCamera = true
		traceBeam.LightEmission = 0.55
		traceBeam.LightInfluence = 0
		traceBeam.Segments = 1
		traceBeam.Width0 = traceW0
		traceBeam.Width1 = traceW1
		traceBeam.Color = ColorSequence.new(secondaryColor, primaryColor)
		traceBeam.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.82),
			NumberSequenceKeypoint.new(0.35, 0.48),
			NumberSequenceKeypoint.new(1, 0.62),
		})
		traceBeam.Parent = root

		local streak = Instance.new("Part")
		streak.Name = "FlyingBullet"
		streak.Shape = Enum.PartType.Ball
		local boltW = isCosmetic and 0.28 or 0.22
		streak.Size = Vector3.new(boltW, boltW, 0.65)
		streak.Color = coreColor
		streak.Material = Enum.Material.Neon
		streak.Anchored = true
		streak.CanCollide = false
		streak.CanTouch = false
		streak.CanQuery = false
		streak.CastShadow = false
		streak.CFrame = originCF * CFrame.new(0, 0, -minStart)
		streak.Parent = root

		local glow = Instance.new("BillboardGui")
		glow.Name = "BulletGlow"
		glow.Size = if tracerId == "dawn_gold"
			then UDim2.fromOffset(14, 14)
			elseif isCosmetic then UDim2.fromOffset(12, 12)
			else UDim2.fromOffset(10, 10)
		glow.AlwaysOnTop = false
		glow.MaxDistance = 520
		glow.LightInfluence = 0
		local dotHalo = Instance.new("Frame", glow)
		dotHalo.Name = "GlowHalo"
		dotHalo.Size = UDim2.fromScale(1, 1)
		dotHalo.BackgroundColor3 = primaryColor
		dotHalo.BackgroundTransparency = 0.35
		dotHalo.BorderSizePixel = 0
		Instance.new("UICorner", dotHalo).CornerRadius = UDim.new(1, 0)
		local dotInner = Instance.new("Frame", dotHalo)
		dotInner.Name = "GlowCore"
		dotInner.AnchorPoint = Vector2.new(0.5, 0.5)
		dotInner.Position = UDim2.fromScale(0.5, 0.5)
		dotInner.Size = UDim2.fromScale(0.55, 0.55)
		dotInner.BackgroundColor3 = coreColor
		dotInner.BorderSizePixel = 0
		Instance.new("UICorner", dotInner).CornerRadius = UDim.new(1, 0)
		if tracerId == "dawn_gold" then
			for _, barSize in ipairs({ UDim2.fromScale(1.15, 0.16), UDim2.fromScale(0.16, 1.15) }) do
				local flareBar = Instance.new("Frame", glow)
				flareBar.Name = "SunFlareCross"
				flareBar.AnchorPoint = Vector2.new(0.5, 0.5)
				flareBar.Position = UDim2.fromScale(0.5, 0.5)
				flareBar.Size = barSize
				flareBar.BackgroundColor3 = coreColor
				flareBar.BackgroundTransparency = 0.15
				flareBar.BorderSizePixel = 0
				Instance.new("UICorner", flareBar).CornerRadius = UDim.new(1, 0)
			end
		end
		glow.Parent = streak

		local sparks
		if isCosmetic and distance <= 520 and (start - camera.CFrame.Position).Magnitude <= 140
			and player:GetAttribute("ReduceHUDMotion") ~= true then
			sparks = Instance.new("ParticleEmitter")
			sparks.Name = "TracerSparks"
			sparks.Texture = "rbxasset://textures/particles/sparkles_main.dds"
			sparks.Color = ColorSequence.new(coreColor, secondaryColor)
			sparks.LightEmission = 0.9
			sparks.Size = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.42),
				NumberSequenceKeypoint.new(1, 0),
			})
			sparks.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.1),
				NumberSequenceKeypoint.new(1, 1),
			})
			sparks.Lifetime = NumberRange.new(0.12, 0.2)
			sparks.Rate = 48
			sparks.Speed = NumberRange.new(1, 4)
			sparks.SpreadAngle = Vector2.new(180, 180)
			sparks.LockedToPart = false
			sparks.Parent = streak
		end

		root.Parent = Workspace
		local duration = math.clamp(distance / 360, 0.04, 0.62)
		local fadeDuration = isCosmetic and 0.24 or 0.18
		local streakLen = math.clamp(distance * (isCosmetic and 0.28 or 0.24), isCosmetic and 18 or 14, isCosmetic and 54 or 46)
		table.insert(active, {
			root = root,
			originCF = originCF,
			originAtt = originAtt,
			tailAtt = tailAtt,
			headAtt = headAtt,
			coreBeam = coreBeam,
			auraBeam = auraBeam,
			traceBeam = traceBeam,
			coreW0 = coreW0,
			coreW1 = coreW1,
			auraW0 = auraW0,
			auraW1 = auraW1,
			traceW0 = traceW0,
			traceW1 = traceW1,
			bolt = streak,
			boltW = boltW,
			glow = glow,
			sparks = sparks,
			isCosmetic = isCosmetic,
			tracerId = tracerId,
			primaryColor = primaryColor,
			secondaryColor = secondaryColor,
			pulseStage = 0,
			start = start,
			direction = direction,
			minStart = minStart,
			distance = distance,
			streakLen = streakLen,
			elapsed = 0,
			duration = duration,
			fadeDuration = fadeDuration,
			impacted = false,
			impactTailDist = minStart,
			impactScale = 1,
			impact = impact,
			isLocalShooter = shooter == player,
		})
		if #active > 36 then
			local oldest = table.remove(active, 1)
			oldest.root:Destroy()
		end
	end)

	local render = Run.RenderStepped:Connect(function(dt)
		for i = #active, 1, -1 do
			local a = active[i]
			a.elapsed += dt
			if not a.root.Parent then
				table.remove(active, i)
			elseif a.elapsed >= a.duration then
				if not a.impacted then
					a.impacted = true
					a.impactTailDist = math.max(a.minStart, a.distance - a.streakLen)
					a.impactScale = math.clamp(1 + a.distance / 260, 1, 2.2)
					a.headAtt.Position = Vector3.new(0, 0, -a.distance)
					a.bolt.Transparency = 1
					a.glow.Enabled = false
					if a.sparks then a.sparks.Enabled = false end
					if a.impact then
						local endPos = a.start + a.direction * a.distance
						spawnImpactEffect(endPos, a.direction, a.impact, a.tracerId)
						if a.isLocalShooter and type(onLocalImpact) == "function" then
							task.spawn(onLocalImpact, a.impact)
						end
					end
				end
				local fadeT = math.clamp((a.elapsed - a.duration) / a.fadeDuration, 0, 1)
				if fadeT >= 1 then
					a.root:Destroy()
					table.remove(active, i)
				else
					local eased = 1 - (1 - fadeT) ^ 2
					local tailDist = a.impactTailDist + (a.distance - a.impactTailDist) * eased
					local shrink = 1 - fadeT
					a.tailAtt.Position = Vector3.new(0, 0, -tailDist)
					a.coreBeam.Width0 = a.coreW0 * a.impactScale * shrink
					a.coreBeam.Width1 = a.coreW1 * a.impactScale * shrink
					a.auraBeam.Width0 = a.auraW0 * a.impactScale * shrink
					a.auraBeam.Width1 = a.auraW1 * a.impactScale * shrink
					a.traceBeam.Width0 = a.traceW0 * shrink
					a.traceBeam.Width1 = a.traceW1 * shrink
					a.traceBeam.Transparency = NumberSequence.new(0.48 + 0.52 * fadeT, 1)
				end
			else
				local fraction = a.elapsed / a.duration
				local headDist = a.distance * fraction
				local tailDist = math.max(a.minStart, headDist - a.streakLen)
				local distScale = math.clamp(1 + headDist / 260, 1, 2.2)
				a.headAtt.Position = Vector3.new(0, 0, -headDist)
				a.tailAtt.Position = Vector3.new(0, 0, -tailDist)
				a.coreBeam.Width0 = a.coreW0 * distScale
				a.coreBeam.Width1 = a.coreW1 * distScale
				a.auraBeam.Width0 = a.auraW0 * distScale
				a.auraBeam.Width1 = a.auraW1 * distScale
				local boltLen = math.min(a.distance, math.clamp(headDist * 0.45, 0.55, a.isCosmetic and 3.8 or 3.0))
				local boltPosCF = a.originCF * CFrame.new(0, 0, -math.max(a.minStart, headDist - boltLen * 0.35))
				a.bolt.Size = Vector3.new(a.boltW, a.boltW, boltLen)
				a.bolt.CFrame = boltPosCF
				a.bolt.Transparency = 0.02 + fraction * 0.08
				if a.isCosmetic and a.distance >= 24 then
					if a.pulseStage == 0 and fraction >= 0.28 then
						a.pulseStage = 1
						spawnTracerPulseRing(boltPosCF, a.primaryColor, a.secondaryColor, a.tracerId, false)
					elseif a.pulseStage == 1 and fraction >= 0.62 then
						a.pulseStage = 2
						spawnTracerPulseRing(boltPosCF, a.primaryColor, a.secondaryColor, a.tracerId, true)
					end
				end
			end
		end
	end)

	owner.Destroying:Connect(function()
		setWeapon(nil)
		dead = true
		event:Disconnect()
		render:Disconnect()
		for _, p in emitters do p:Destroy() end
		for _, p in impactEmitters do p:Destroy() end
		for _, a in active do a.root:Destroy() end
	end)

	return setWeapon
end

return Presentation
