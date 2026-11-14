local Presentation = {}
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Run = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local WEAPON_VISIBILITY_STEP = "FlyHighWeaponVisibility"
local BASE_ARMS_SCALE = 0.045

local viewProfiles = {
	Pistol = {
		armsScale = 0.042,
		gunScale = 0.76,
		shoulderOffset = CFrame.new(0.04, -0.58, 0.12),
		gunOffset = CFrame.new(0.46, -0.38, -1.48) * CFrame.Angles(math.rad(1.5), math.rad(5.5), math.rad(-2.0)),
		recoilOffset = Vector3.new(0, 0.015, 0.075),
		recoilPitchDeg = 4.2,
		recoilRecovery = 11,
		reloadOffset = CFrame.new(-0.08, -0.18, 0.08) * CFrame.Angles(math.rad(-14), math.rad(18), math.rad(14)),
		hands = {
			R = {
				wristOffset = Vector3.new(0.16, -0.17, 0.34),
				elbowPole = Vector3.new(0.95, -0.78, 0.2),
				fingerDir = Vector3.new(-0.22, 0.14, -0.96),
				backOfHand = Vector3.new(0.96, 0.16, 0.22),
				triggerPoint = {
					Vector3.new(0.24, 0.08, -0.97),
					Vector3.new(-0.25, -0.05, -0.97),
					Vector3.new(-0.55, -0.12, -0.82),
				},
				thumbChain = {
					Vector3.new(-0.14, 0.15, -0.98),
					Vector3.new(0.10, -0.22, -0.97),
					Vector3.new(0.22, -0.34, -0.91),
				},
				curls = {
					middle = { { 76, 86, 62 }, 0 },
					ring = { { 78, 86, 62 }, 0 },
					pink = { { 80, 86, 64 }, -3 },
				},
			},
			L = {
				wristOffset = Vector3.new(-0.13, -0.20, 0.18),
				elbowPole = Vector3.new(-0.90, -0.82, 0.2),
				fingerDir = Vector3.new(0.46, 0.34, -0.82),
				backOfHand = Vector3.new(-0.92, -0.20, 0.34),
				thumbChain = {
					Vector3.new(0.36, 0.14, -0.92),
					Vector3.new(0.32, -0.02, -0.95),
					Vector3.new(0.26, -0.08, -0.96),
				},
				curls = {
					point = { { 60, 72, 50 }, 2 },
					middle = { { 64, 76, 52 }, 0 },
					ring = { { 66, 78, 54 }, 0 },
					pink = { { 68, 80, 56 }, -2 },
				},
			},
		},
	},
	AK47 = {
		armsScale = 0.048,
		gunScale = 0.46,
		shoulderOffset = CFrame.new(0.10, -0.78, 0.18),
		gunOffset = CFrame.new(0.56, -0.88, -1.62) * CFrame.Angles(math.rad(1.0), math.rad(6.5), math.rad(-2.5)),
		recoilOffset = Vector3.new(0, 0.012, 0.065),
		recoilPitchDeg = 3.2,
		recoilRecovery = 12,
		reloadOffset = CFrame.new(-0.08, -0.20, 0.06) * CFrame.Angles(math.rad(-16), math.rad(16), math.rad(16)),
		hands = {
			R = {
				wristOffset = Vector3.new(0.17, -0.13, 0.28),
				elbowPole = Vector3.new(0.95, -0.80, 0.22),
				fingerDir = Vector3.new(-0.22, 0.20, -0.95),
				backOfHand = Vector3.new(0.96, 0.18, 0.22),
				triggerPoint = {
					Vector3.new(0.22, 0.14, -0.96),
					Vector3.new(-0.24, 0.00, -0.97),
					Vector3.new(-0.56, -0.08, -0.82),
				},
				thumbChain = {
					Vector3.new(-0.14, 0.12, -0.98),
					Vector3.new(0.18, -0.22, -0.96),
					Vector3.new(0.26, -0.35, -0.90),
				},
				curls = {
					middle = { { 76, 86, 62 }, 0 },
					ring = { { 78, 86, 62 }, 0 },
					pink = { { 80, 86, 64 }, -3 },
				},
			},
			L = {
				wristOffset = Vector3.new(-0.14, 0.05, -0.56),
				elbowPole = Vector3.new(-0.62, -1.00, 0.14),
				fingerDir = Vector3.new(0.76, 0.42, -0.49),
				backOfHand = Vector3.new(-0.52, -0.84, 0.14),
				thumbChain = {
					Vector3.new(0.14, -0.01, -0.99),
					Vector3.new(0.22, -0.14, -0.96),
					Vector3.new(0.28, -0.25, -0.92),
				},
				curls = {
					point = { { 72, 82, 60 }, 2 },
					middle = { { 74, 84, 62 }, 0 },
					ring = { { 76, 86, 64 }, 0 },
					pink = { { 78, 88, 64 }, -3 },
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
			rayParams.FilterDescendantsInstances = { char, vmRoot }
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

function Presentation.Start(player, remote, owner, _hud)
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

	local shotTemplate = audioAssets:WaitForChild("PistolShot")
	local emitters = {}
	local sounds = {}
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
		table.insert(sounds, s)
	end

	local preload = table.clone(sounds)
	if reloadSound then table.insert(preload, reloadSound) end
	task.spawn(function()
		pcall(function() game:GetService("ContentProvider"):PreloadAsync(preload) end)
	end)

	local active = {}
	local dead = false
	local event = remote.OnClientEvent:Connect(function(shooter, origin, target)
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

		index = index % #emitters + 1
		emitters[index].Position = start
		local sound = sounds[index]
		sound:Stop()
		sound.TimePosition = 0
		local tool = shooter and shooter.Character and shooter.Character:FindFirstChildOfClass("Tool")
		sound.PlaybackSpeed = tool and tool.Name == "AK47" and 0.9 or 1
		sound:Play()
		poolFolder:SetAttribute("ShotCount", poolFolder:GetAttribute("ShotCount") + 1)

		local tracerAttr = shooter and shooter:GetAttribute("EquippedTracer")
		local tracerDef = if type(tracerAttr) == "string" and tracerAttr ~= ""
			then DailyAndShopCatalog.GetCosmetic("tracer", tracerAttr)
			else nil

		local flash = Instance.new("Part")
		flash.Name = "WeaponMuzzleFlash"
		flash.Shape = Enum.PartType.Ball
		flash.Size = firstPersonShot and Vector3.new(0.18, 0.18, 0.18) or Vector3.new(0.26, 0.26, 0.26)
		flash.Color = if tracerDef then tracerDef.primaryColor else Color3.fromRGB(255, 215, 130)
		flash.Material = Enum.Material.Neon
		flash.Position = start
		flash.Anchored = true
		flash.CanCollide = false
		flash.CanTouch = false
		flash.CanQuery = false
		flash.Parent = Workspace
		Debris:AddItem(flash, 0.07)
		local light = Instance.new("PointLight")
		light.Color = flash.Color
		light.Brightness = 1.3
		light.Range = 5
		light.Parent = flash

		local streak = Instance.new("Part")
		streak.Name = "FlyingBullet"
		streak.Shape = Enum.PartType.Ball
		streak.Size = Vector3.new(0.24, 0.24, 0.85)
		streak.Color = if tracerDef then tracerDef.primaryColor else Color3.fromRGB(255, 208, 86)
		streak.Material = Enum.Material.Neon
		streak.Anchored = true
		streak.CanCollide = false
		streak.CanTouch = false
		streak.CanQuery = false
		streak.CFrame = CFrame.lookAt(start, start + direction)

		local a0 = Instance.new("Attachment", streak)
		a0.Position = Vector3.new(-0.12, 0, 0.3)
		local a1 = Instance.new("Attachment", streak)
		a1.Position = Vector3.new(0.12, 0, 0.3)
		local trail = Instance.new("Trail", streak)
		trail.Name = "BulletTrail"
		trail.Attachment0 = a0
		trail.Attachment1 = a1
		trail.FaceCamera = true
		trail.Lifetime = 0.12
		trail.MinLength = 0.05
		trail.LightEmission = 1
		trail.Color = ColorSequence.new(streak.Color, if tracerDef then tracerDef.secondaryColor else Color3.fromRGB(195, 116, 37))
		trail.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.05), NumberSequenceKeypoint.new(1, 1) })

		local glow = Instance.new("BillboardGui", streak)
		glow.Name = "BulletGlow"
		glow.Size = UDim2.fromOffset(6, 6)
		glow.AlwaysOnTop = false
		glow.MaxDistance = 520
		glow.LightInfluence = 0
		local dot = Instance.new("Frame", glow)
		dot.Size = UDim2.fromScale(1, 1)
		dot.BackgroundColor3 = streak.Color
		dot.BorderSizePixel = 0
		Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)

		streak.Parent = Workspace
		local duration = math.clamp(distance / 160, 0.25, 1.8)
		table.insert(active, { part = streak, start = start, direction = direction, distance = distance, elapsed = 0, duration = duration })
		if #active > 32 then
			local oldest = table.remove(active, 1)
			oldest.part:Destroy()
		end
	end)

	local render = Run.RenderStepped:Connect(function(dt)
		for i = #active, 1, -1 do
			local a = active[i]
			a.elapsed += dt
			if not a.part.Parent then
				table.remove(active, i)
			elseif a.elapsed >= a.duration then
				a.part.CFrame = CFrame.lookAt(a.start + a.direction * a.distance, a.start + a.direction * (a.distance + 1))
				a.part.Transparency = 1
				a.part.BulletGlow.Enabled = false
				a.part.BulletTrail.Enabled = false
				Debris:AddItem(a.part, 0.13)
				table.remove(active, i)
			else
				local fraction = a.elapsed / a.duration
				local center = a.start + a.direction * (a.distance * fraction)
				a.part.CFrame = CFrame.lookAt(center, center + a.direction)
				a.part.Transparency = 0.02 + fraction * 0.12
			end
		end
	end)

	owner.Destroying:Connect(function()
		setWeapon(nil)
		dead = true
		event:Disconnect()
		render:Disconnect()
		for _, p in emitters do p:Destroy() end
		for _, a in active do a.part:Destroy() end
	end)

	return setWeapon
end

return Presentation
