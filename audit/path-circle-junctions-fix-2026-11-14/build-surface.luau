-- Surgical rebuild of Ring junction reveals, 10-tile clean Elbows (1 quad/tile), and FilletPaver 0.08 interior grout reveal
local lobby = workspace:FindFirstChild("FlyHighLobby")
local surface = lobby:FindFirstChild("PromenadeSurface")
local dp = lobby:WaitForChild("DockPromenade")
assert(surface and dp)

local savedLetters = {}
for i = 1, 5 do
	local dl = surface:FindFirstChild("DockLetter_" .. i)
	if dl then
		dl.Parent = nil
		savedLetters[i] = dl
	end
end
surface:ClearAllChildren()

for _, d in ipairs(dp:GetChildren()) do
	if d.Name == "JunctionSupportCollider" then d:Destroy() end
end

local RING_CENTER = Vector3.new(0, 0, 15)
local R_IN, R_OUT, ROAD_HW, CURB_W = 65.50, 74.50, 4.50, 0.45
local LIMIT = math.acos(5 / 75)
local ELBOW_EX = math.sqrt(75 * 75 - 25)
local ELBOW_T0, ELBOW_T1 = math.asin(5 / 75), math.pi / 2

local PAVER_TOP_Y, PAVER_THICK = 10.375, 0.070
local BED_TOP_Y, BED_THICK = 10.335, 0.340
local CURB_TOP_Y, CURB_THICK = 10.375, 0.420

local AG_R, AG_TOP_Y, AG_RAMP_START_Z = 12.00, 10.525, 18.00
local POD_DIST, POD_RIM_R = 90.00, 11.15
local RF_MAIN_T, RF_OUT_T, RF_AG, RF_POD = 2.50, 2.50, 2.50, 1.80

local THETA_MAIN_T = math.atan2(ROAD_HW + RF_MAIN_T, math.sqrt((R_IN - RF_MAIN_T)^2 - (ROAD_HW + RF_MAIN_T)^2))
local THETA_OUT_T = math.atan2(ROAD_HW + RF_OUT_T, math.sqrt((R_OUT + RF_OUT_T)^2 - (ROAD_HW + RF_OUT_T)^2))
local THETA_AG = math.atan2(ROAD_HW + RF_AG, math.sqrt((AG_R + RF_AG)^2 - (ROAD_HW + RF_AG)^2))
local THETA_POD = math.atan2(ROAD_HW + RF_POD, math.sqrt((POD_RIM_R + RF_POD)^2 - (ROAD_HW + RF_POD)^2))

local colSand0 = Color3.fromRGB(191, 175, 143)
local colSand1 = Color3.fromRGB(213, 198, 170)
local colEdge = Color3.fromRGB(100, 109, 105)
local colGrout = Color3.fromRGB(144, 137, 119)

local function shade(idx)
	local f = ((idx * 37) % 100) / 1000
	return colSand0:Lerp(colSand1, f + 0.02)
end

local function drawTriTop(parent, a, b, c, thick, color, name, canCollide, trans)
	local da = a - Vector3.new(0, thick * 0.5, 0)
	local db = b - Vector3.new(0, thick * 0.5, 0)
	local dc = c - Vector3.new(0, thick * 0.5, 0)
	local ab, ac, bc = (db - da).Magnitude, (dc - da).Magnitude, (dc - db).Magnitude
	local maxLen = math.max(ab, ac, bc)
	if maxLen < 1e-4 then return end
	if ac == maxLen then db, dc = dc, db
	elseif bc == maxLen then da, dc = dc, da end
	local baseVec = db - da
	local baseLen = baseVec.Magnitude
	local baseDir = baseVec.Unit
	local t = (dc - da):Dot(baseDir)
	local foot = da + baseDir * t
	local altVec = dc - foot
	local h = altVec.Magnitude
	if h < 1e-4 then return end
	local vY = altVec.Unit

	local function spawnSub(corner, len, zBack)
		if len < 1e-4 then return end
		local vZ = zBack
		local vX = vY:Cross(vZ).Unit
		local w = Instance.new("WedgePart")
		w.Name = name
		w.Anchored = true
		w.CanCollide = canCollide or false
		w.CanTouch = false
		w.CanQuery = false
		w.CastShadow = false
		w.Material = Enum.Material.SmoothPlastic
		w.Color = color
		w.Transparency = trans or 0
		w.TopSurface = Enum.SurfaceType.Smooth
		w.BottomSurface = Enum.SurfaceType.Smooth
		w.Size = Vector3.new(thick, h, len)
		w.CFrame = CFrame.fromMatrix((corner + dc) * 0.5, vX, vY, vZ)
		w.Parent = parent
	end
	spawnSub(da, t, baseDir)
	spawnSub(db, baseLen - t, -baseDir)
end

local function drawQuadTop(parent, p00, p10, p11, p01, thick, color, name, canCollide, trans)
	drawTriTop(parent, p00, p10, p11, thick, color, name, canCollide, trans)
	drawTriTop(parent, p00, p11, p01, thick, color, name, canCollide, trans)
end

local function polarRing(r, a, topY)
	return Vector3.new(math.sin(a) * r, topY, 15 - math.cos(a) * r)
end

local function polarElbow(sideSign, t, re, topY)
	return Vector3.new(sideSign * (ELBOW_EX - re * math.cos(t)), topY, 10.0 + re * math.sin(t))
end

local function agRampY(x, z)
	if z <= AG_RAMP_START_Z then return PAVER_TOP_Y end
	local cx = math.clamp(math.abs(x), 0, AG_R - 0.05)
	local zEnd = 35 - math.sqrt(AG_R * AG_R - cx * cx)
	local denom = math.max(0.5, zEnd - AG_RAMP_START_Z)
	local alpha = math.clamp((z - AG_RAMP_START_Z) / denom, 0, 1)
	return PAVER_TOP_Y + (AG_TOP_Y - PAVER_TOP_Y) * alpha
end

local chunks = {}
local function newChunk()
	local f = Instance.new("Folder")
	table.insert(chunks, f)
	return f
end

-- CHUNK 1: Ring (clean 0.05 setback at Main_T and B/C/D -> crisp 0.10 continuous reveal!)
do
	local f = newChunk()
	local N_RING = 48
	local bAngles = {-math.pi/4, 0, math.pi/4}

	local function ringInRadius(a, li)
		if li ~= 1 then return (li == 2) and 68.54 or 71.54 end
		if math.abs(a) <= THETA_MAIN_T + 1e-4 then return R_IN + 0.05 end
		return R_IN
	end
	local function ringOutRadius(a, li)
		if li ~= 3 then return (li == 1) and 68.46 or 71.46 end
		for _, ba in ipairs(bAngles) do
			if math.abs(a - ba) <= THETA_OUT_T + 1e-4 then return R_OUT - 0.05 end
		end
		return R_OUT
	end
	local function touchesJunction(a0, a1)
		if a1 >= -THETA_MAIN_T - 0.05 and a0 <= THETA_MAIN_T + 0.05 then return true end
		for _, ba in ipairs(bAngles) do
			if a1 >= ba - THETA_OUT_T - 0.05 and a0 <= ba + THETA_OUT_T + 0.05 then return true end
		end
		return false
	end

	for i = 1, N_RING do
		local a0 = -LIMIT + (i - 1) * (2 * LIMIT / N_RING)
		local a1 = -LIMIT + i * (2 * LIMIT / N_RING)
		local nBedSub = touchesJunction(a0, a1) and 4 or 1
		for bi = 1, nBedSub do
			local sa0 = a0 + (bi - 1) * (a1 - a0) / nBedSub
			local sa1 = a0 + bi * (a1 - a0) / nBedSub
			drawQuadTop(f, polarRing(R_IN, sa0, BED_TOP_Y), polarRing(R_OUT, sa0, BED_TOP_Y), polarRing(R_OUT, sa1, BED_TOP_Y), polarRing(R_IN, sa1, BED_TOP_Y), BED_THICK, colGrout, "ContinuousBed")
		end
		for li = 1, 3 do
			local r0_nom = (li == 1 and R_IN) or (li == 2 and 68.54) or 71.54
			local r1_nom = (li == 1 and 68.46) or (li == 2 and 71.46) or R_OUT
			local rMid = (r0_nom + r1_nom) * 0.5
			local dA = 0.04 / rMid
			local pa0, pa1 = a0 + dA, a1 - dA
			local isJunc = (li == 1 or li == 3) and touchesJunction(a0, a1)
			local nSub = isJunc and 6 or 1
			local col = shade(i + li * 7)
			for si = 1, nSub do
				local ca0 = pa0 + (si - 1) * (pa1 - pa0) / nSub
				local ca1 = pa0 + si * (pa1 - pa0) / nSub
				drawQuadTop(f,
					polarRing(ringInRadius(ca0, li), ca0, PAVER_TOP_Y),
					polarRing(ringOutRadius(ca0, li), ca0, PAVER_TOP_Y),
					polarRing(ringOutRadius(ca1, li), ca1, PAVER_TOP_Y),
					polarRing(ringInRadius(ca1, li), ca1, PAVER_TOP_Y),
					PAVER_THICK, col, "CurvedPaver")
			end
		end
	end

	local function addCurbArc(aStart, aEnd, rA, rB, segs, name)
		for i = 1, segs do
			local a0 = aStart + (i - 1) * (aEnd - aStart) / segs
			local a1 = aStart + i * (aEnd - aStart) / segs
			drawQuadTop(f, polarRing(rA, a0, CURB_TOP_Y), polarRing(rB, a0, CURB_TOP_Y), polarRing(rB, a1, CURB_TOP_Y), polarRing(rA, a1, CURB_TOP_Y), CURB_THICK, colEdge, name)
		end
	end
	addCurbArc(-LIMIT, -THETA_MAIN_T, R_IN - CURB_W, R_IN, 24, "InnerCurb")
	addCurbArc(THETA_MAIN_T, LIMIT, R_IN - CURB_W, R_IN, 24, "InnerCurb")
	local cur = -LIMIT
	for _, ba in ipairs(bAngles) do
		addCurbArc(cur, ba - THETA_OUT_T, R_OUT, R_OUT + CURB_W, 12, "OuterCurb")
		cur = ba + THETA_OUT_T
	end
	addCurbArc(cur, LIMIT, R_OUT, R_OUT + CURB_W, 12, "OuterCurb")
end

-- CHUNK 2: Elbows - 10 clean single-quad tiles per lane (NO sub-quad spoke hairlines!) + 24 smooth curbs & beds
do
	local f = newChunk()
	local N_EL_BED = 24
	local N_EL_PAVER = 10
	local elLanes = { {0.50, 3.46}, {3.54, 6.46}, {6.54, 9.50} }
	for _, sideSign in ipairs({-1, 1}) do
		for i = 1, N_EL_BED do
			local t0 = ELBOW_T0 + (i - 1) * (ELBOW_T1 - ELBOW_T0) / N_EL_BED
			local t1 = ELBOW_T0 + i * (ELBOW_T1 - ELBOW_T0) / N_EL_BED
			drawQuadTop(f, polarElbow(sideSign, t0, 0.50, BED_TOP_Y), polarElbow(sideSign, t0, 9.50, BED_TOP_Y), polarElbow(sideSign, t1, 9.50, BED_TOP_Y), polarElbow(sideSign, t1, 0.50, BED_TOP_Y), BED_THICK, colGrout, "ContinuousBed")
			drawQuadTop(f, polarElbow(sideSign, t0, 0.05, CURB_TOP_Y), polarElbow(sideSign, t0, 0.50, CURB_TOP_Y), polarElbow(sideSign, t1, 0.50, CURB_TOP_Y), polarElbow(sideSign, t1, 0.05, CURB_TOP_Y), CURB_THICK, colEdge, "ElbowCurb")
			drawQuadTop(f, polarElbow(sideSign, t0, 9.50, CURB_TOP_Y), polarElbow(sideSign, t0, 9.95, CURB_TOP_Y), polarElbow(sideSign, t1, 9.95, CURB_TOP_Y), polarElbow(sideSign, t1, 9.50, CURB_TOP_Y), CURB_THICK, colEdge, "ElbowCurb")
		end
		for i = 1, N_EL_PAVER do
			local t0 = ELBOW_T0 + (i - 1) * (ELBOW_T1 - ELBOW_T0) / N_EL_PAVER
			local t1 = ELBOW_T0 + i * (ELBOW_T1 - ELBOW_T0) / N_EL_PAVER
			for li, er in ipairs(elLanes) do
				local r0, r1 = er[1], er[2]
				local rm = (r0 + r1) * 0.5
				local dt = math.min(0.04 / rm, (t1 - t0) * 0.16)
				local pt0, pt1 = t0 + dt, t1 - dt
				drawQuadTop(f,
					polarElbow(sideSign, pt0, r0, PAVER_TOP_Y),
					polarElbow(sideSign, pt0, r1, PAVER_TOP_Y),
					polarElbow(sideSign, pt1, r1, PAVER_TOP_Y),
					polarElbow(sideSign, pt1, r0, PAVER_TOP_Y),
					PAVER_THICK, shade(i * 3 + li * 5), "ElbowPaver")
			end
		end
	end
end

-- CHUNK 3: Main + Main_T + ArrivalGarden
do
	local f = newChunk()
	local fc = Instance.new("Folder", dp)
	fc.Name = "JunctionSupportCollider"
	local cols = { {-4.50, -1.54}, {-1.46, 1.46}, {1.54, 4.50} }
	local function zNorth(x) return 15.0 - math.sqrt(R_IN * R_IN - x * x) end
	local function zSouth(x) return 35.0 - math.sqrt(AG_R * AG_R - x * x) end

	local rowBreaks = {-50.34, -47.61}
	local curZ = -47.61
	while curZ < 14.5 do
		curZ += 3.45
		if curZ > 17.8 then break end
		table.insert(rowBreaks, curZ)
	end
	table.insert(rowBreaks, 18.00)
	table.insert(rowBreaks, 20.30)
	table.insert(rowBreaks, 22.3016)

	for ci, xr in ipairs(cols) do
		local x0, x1 = xr[1], xr[2]
		local xm = (x0 + x1) * 0.5
		local zn0, znm, zn1 = zNorth(x0), zNorth(xm), zNorth(x1)
		local zEnd = rowBreaks[2]
		drawQuadTop(f, Vector3.new(x0, BED_TOP_Y, zn0), Vector3.new(x1, BED_TOP_Y, zn1), Vector3.new(x1, BED_TOP_Y, zEnd), Vector3.new(x0, BED_TOP_Y, zEnd), BED_THICK, colGrout, "ContinuousBed")
		local col = shade(ci * 3 + 1)
		drawQuadTop(f, Vector3.new(x0, PAVER_TOP_Y, zn0 - 0.05), Vector3.new(xm, PAVER_TOP_Y, znm - 0.05), Vector3.new(xm, PAVER_TOP_Y, zEnd - 0.04), Vector3.new(x0, PAVER_TOP_Y, zEnd - 0.04), PAVER_THICK, col, "StraightPaver")
		drawQuadTop(f, Vector3.new(xm, PAVER_TOP_Y, znm - 0.05), Vector3.new(x1, PAVER_TOP_Y, zn1 - 0.05), Vector3.new(x1, PAVER_TOP_Y, zEnd - 0.04), Vector3.new(xm, PAVER_TOP_Y, zEnd - 0.04), PAVER_THICK, col, "StraightPaver")
	end
	drawQuadTop(f, Vector3.new(-1.54, BED_TOP_Y, zNorth(-1.54)), Vector3.new(-1.46, BED_TOP_Y, zNorth(-1.46)), Vector3.new(-1.46, BED_TOP_Y, zSouth(-1.46)), Vector3.new(-1.54, BED_TOP_Y, zSouth(-1.54)), BED_THICK, colGrout, "ContinuousBed")
	drawQuadTop(f, Vector3.new(1.46, BED_TOP_Y, zNorth(1.46)), Vector3.new(1.54, BED_TOP_Y, zNorth(1.54)), Vector3.new(1.54, BED_TOP_Y, zSouth(1.54)), Vector3.new(1.46, BED_TOP_Y, zSouth(1.46)), BED_THICK, colGrout, "ContinuousBed")

	for ri = 2, #rowBreaks - 1 do
		local zA, zB = rowBreaks[ri], rowBreaks[ri + 1]
		for ci, xr in ipairs(cols) do
			local x0, x1 = xr[1], xr[2]
			local yA0, yA1 = agRampY(x0, zA), agRampY(x1, zA)
			local yB0, yB1 = agRampY(x0, zB), agRampY(x1, zB)
			drawQuadTop(f, Vector3.new(x0, math.max(yA0,yA1)-0.04, zA), Vector3.new(x1, math.max(yA0,yA1)-0.04, zA), Vector3.new(x1, math.max(yB0,yB1)-0.04, zB), Vector3.new(x0, math.max(yB0,yB1)-0.04, zB), BED_THICK, colGrout, "ContinuousBed")
			drawQuadTop(f, Vector3.new(x0, yA0, zA + 0.04), Vector3.new(x1, yA1, zA + 0.04), Vector3.new(x1, yB1, zB - 0.04), Vector3.new(x0, yB0, zB - 0.04), PAVER_THICK, shade(ri * 5 + ci), "StraightPaver")
		end
	end

	local zF_ag = 22.3016
	for ci, xr in ipairs(cols) do
		local x0, x1 = xr[1], xr[2]
		local zs0, zs1 = zSouth(x0), zSouth(x1)
		local yA0, yA1 = agRampY(x0, zF_ag), agRampY(x1, zF_ag)
		drawQuadTop(f, Vector3.new(x0, yA0-0.04, zF_ag), Vector3.new(x1, yA1-0.04, zF_ag), Vector3.new(x1, AG_TOP_Y-0.04, zs1), Vector3.new(x0, AG_TOP_Y-0.04, zs0), BED_THICK, colGrout, "ContinuousBed")
		drawQuadTop(f, Vector3.new(x0, yA0, zF_ag+0.04), Vector3.new(x1, yA1, zF_ag+0.04), Vector3.new(x1, AG_TOP_Y, zs1), Vector3.new(x0, AG_TOP_Y, zs0), PAVER_THICK, shade(90 + ci), "StraightPaver")
	end

	local curbSegs = { {-47.61, 18.00}, {18.00, 20.30}, {20.30, 22.3016} }
	for _, sSide in ipairs({-1, 1}) do
		local xIn = sSide * 4.50
		local xOut = sSide * (4.50 + CURB_W)
		if xIn > xOut then xIn, xOut = xOut, xIn end
		for _, seg in ipairs(curbSegs) do
			drawQuadTop(f, Vector3.new(xIn, agRampY(4.5,seg[1]), seg[1]), Vector3.new(xOut, agRampY(4.5,seg[1]), seg[1]), Vector3.new(xOut, agRampY(4.5,seg[2]), seg[2]), Vector3.new(xIn, agRampY(4.5,seg[2]), seg[2]), 0.58, colEdge, "StraightCurb")
		end
	end
	drawQuadTop(fc, Vector3.new(-4.50, 10.260, 19.00), Vector3.new(4.50, 10.260, 19.00), Vector3.new(4.50, 10.500, zSouth(4.50)), Vector3.new(-4.50, 10.500, zSouth(-4.50)), 0.32, colGrout, "JunctionSupportCollider", true, 1)

	local dz_f_mt = math.sqrt((R_IN - RF_MAIN_T)^2 - (ROAD_HW + RF_MAIN_T)^2)
	local zf_mt = 15.0 - dz_f_mt
	local N_FIL = 10
	for _, sSide in ipairs({-1, 1}) do
		local xf = sSide * (ROAD_HW + RF_MAIN_T)
		local ang0, ang1 = math.pi, 1.5 * math.pi + THETA_MAIN_T
		for i = 1, N_FIL do
			local t0, t1 = (i - 1) / N_FIL, i / N_FIL
			local a0, a1 = ang0 + (ang1 - ang0) * t0, ang0 + (ang1 - ang0) * t1
			local pIn0 = Vector3.new(xf + sSide * RF_MAIN_T * math.cos(a0), 0, zf_mt + RF_MAIN_T * math.sin(a0))
			local pIn1 = Vector3.new(xf + sSide * RF_MAIN_T * math.cos(a1), 0, zf_mt + RF_MAIN_T * math.sin(a1))
			local rOut = RF_MAIN_T - CURB_W
			local pOut0 = Vector3.new(xf + sSide * rOut * math.cos(a0), CURB_TOP_Y, zf_mt + rOut * math.sin(a0))
			local pOut1 = Vector3.new(xf + sSide * rOut * math.cos(a1), CURB_TOP_Y, zf_mt + rOut * math.sin(a1))
			drawQuadTop(f, Vector3.new(pIn0.X, CURB_TOP_Y, pIn0.Z), pOut0, pOut1, Vector3.new(pIn1.X, CURB_TOP_Y, pIn1.Z), CURB_THICK, colEdge, "FilletCurb")

			local function cornerBedRef(t)
				local cAngStart = math.atan2(4.50, math.sqrt(R_IN*R_IN - 20.25))
				if t < 0.5 then
					return Vector3.new(sSide * 4.50, 0, zf_mt + (zNorth(4.50) - zf_mt) * (t * 2))
				else
					local ca = cAngStart + (THETA_MAIN_T - cAngStart) * ((t - 0.5) * 2)
					return Vector3.new(sSide * R_IN * math.sin(ca), 0, 15.0 - R_IN * math.cos(ca))
				end
			end
			local function cornerPaverRef(t)
				local cAngStart = math.atan2(4.58, math.sqrt((R_IN-0.05)^2 - 4.58^2))
				if t < 0.5 then
					local k = t * 2
					return Vector3.new(sSide * 4.58, 0, zf_mt + ((zNorth(4.58) - 0.05) - zf_mt) * k)
				else
					local k = (t - 0.5) * 2
					local ca = cAngStart + (THETA_MAIN_T - cAngStart) * k
					return Vector3.new(sSide * (R_IN - 0.05) * math.sin(ca), 0, 15.0 - (R_IN - 0.05) * math.cos(ca))
				end
			end
			local b0, b1 = cornerBedRef(t0), cornerBedRef(t1)
			local q0, q1 = cornerPaverRef(t0), cornerPaverRef(t1)
			drawQuadTop(f, Vector3.new(b0.X, BED_TOP_Y, b0.Z), Vector3.new(pIn0.X, BED_TOP_Y, pIn0.Z), Vector3.new(pIn1.X, BED_TOP_Y, pIn1.Z), Vector3.new(b1.X, BED_TOP_Y, b1.Z), BED_THICK, colGrout, "ContinuousBed")
			if i > 1 then -- Skip degenerate apex wedge at t=0 where 4.58 is wider than 4.50
				drawQuadTop(f, Vector3.new(q0.X, PAVER_TOP_Y, q0.Z), Vector3.new(pIn0.X, PAVER_TOP_Y, pIn0.Z), Vector3.new(pIn1.X, PAVER_TOP_Y, pIn1.Z), Vector3.new(q1.X, PAVER_TOP_Y, q1.Z), PAVER_THICK, shade(200 + i), "FilletPaver")
			end
			drawQuadTop(fc, Vector3.new(b0.X, 10.260, b0.Z), Vector3.new(pIn0.X, 10.260, pIn0.Z), Vector3.new(pIn1.X, 10.260, pIn1.Z), Vector3.new(b1.X, 10.260, b1.Z), 0.32, colGrout, "JunctionSupportCollider", true, 1)
		end
	end

	local dz_f_ag = math.sqrt((AG_R + RF_AG)^2 - (ROAD_HW + RF_AG)^2)
	local zf_ag = 35.0 - dz_f_ag
	for _, sSide in ipairs({-1, 1}) do
		local xf = sSide * (ROAD_HW + RF_AG)
		local ang0, ang1 = math.pi, 0.5 * math.pi + THETA_AG
		for i = 1, N_FIL do
			local t0, t1 = (i - 1) / N_FIL, i / N_FIL
			local a0, a1 = ang0 + (ang1 - ang0) * t0, ang0 + (ang1 - ang0) * t1
			local pIn0 = Vector3.new(xf + sSide * RF_AG * math.cos(a0), 0, zf_ag + RF_AG * math.sin(a0))
			local pIn1 = Vector3.new(xf + sSide * RF_AG * math.cos(a1), 0, zf_ag + RF_AG * math.sin(a1))
			local rOut = RF_AG - CURB_W
			local pOut0 = Vector3.new(xf + sSide * rOut * math.cos(a0), 0, zf_ag + rOut * math.sin(a0))
			local pOut1 = Vector3.new(xf + sSide * rOut * math.cos(a1), 0, zf_ag + rOut * math.sin(a1))
			local yIn0, yIn1 = agRampY(pIn0.X, pIn0.Z), agRampY(pIn1.X, pIn1.Z)
			local yOut0, yOut1 = yIn0, yIn1
			if t1 > 0.99 then yIn1 = AG_TOP_Y; yOut1 = AG_TOP_Y end
			drawQuadTop(f, Vector3.new(pIn0.X, yIn0, pIn0.Z), Vector3.new(pOut0.X, yOut0, pOut0.Z), Vector3.new(pOut1.X, yOut1, pOut1.Z), Vector3.new(pIn1.X, yIn1, pIn1.Z), 0.58, colEdge, "ArrivalFilletCurb")

			local function cornerBedAG(t)
				local cAngStart = math.atan2(4.50, math.sqrt(AG_R*AG_R - 20.25))
				if t < 0.5 then return Vector3.new(sSide * 4.50, 0, zf_ag + (zSouth(4.50) - zf_ag) * (t * 2))
				else
					local ca = cAngStart + (THETA_AG - cAngStart) * ((t - 0.5) * 2)
					return Vector3.new(sSide * AG_R * math.sin(ca), 0, 35.0 - AG_R * math.cos(ca))
				end
			end
			local function cornerPaverAG(t)
				local cAngStart = math.atan2(4.58, math.sqrt(AG_R*AG_R - 4.58^2))
				if t < 0.5 then return Vector3.new(sSide * 4.58, 0, zf_ag + (zSouth(4.58) - zf_ag) * (t * 2))
				else
					local ca = cAngStart + (THETA_AG - cAngStart) * ((t - 0.5) * 2)
					return Vector3.new(sSide * AG_R * math.sin(ca), 0, 35.0 - AG_R * math.cos(ca))
				end
			end
			local b0, b1 = cornerBedAG(t0), cornerBedAG(t1)
			local q0, q1 = cornerPaverAG(t0), cornerPaverAG(t1)
			local yb0, yb1 = agRampY(b0.X, b0.Z), agRampY(b1.X, b1.Z)
			local yq0, yq1 = agRampY(q0.X, q0.Z), agRampY(q1.X, q1.Z)
			drawQuadTop(f, Vector3.new(b0.X, yb0-0.04, b0.Z), Vector3.new(pIn0.X, yIn0-0.04, pIn0.Z), Vector3.new(pIn1.X, yIn1-0.04, pIn1.Z), Vector3.new(b1.X, yb1-0.04, b1.Z), BED_THICK, colGrout, "ContinuousBed")
			if i > 1 then
				drawQuadTop(f, Vector3.new(q0.X, yq0, q0.Z), Vector3.new(pIn0.X, yIn0, pIn0.Z), Vector3.new(pIn1.X, yIn1, pIn1.Z), Vector3.new(q1.X, yq1, q1.Z), PAVER_THICK, shade(220 + i), "FilletPaver")
			end
			drawQuadTop(fc, Vector3.new(b0.X, yb0-0.05, b0.Z), Vector3.new(pIn0.X, yIn0-0.05, pIn0.Z), Vector3.new(pIn1.X, yIn1-0.05, pIn1.Z), Vector3.new(b1.X, yb1-0.05, b1.Z), 0.32, colGrout, "JunctionSupportCollider", true, 1)
		end
	end

	local N_AG_ARC = 36
	local agSpan = (2 * math.pi - THETA_AG) - THETA_AG
	for i = 1, N_AG_ARC do
		local a0 = THETA_AG + (i - 1) * agSpan / N_AG_ARC
		local a1 = THETA_AG + i * agSpan / N_AG_ARC
		local function agPt(r, a) return Vector3.new(r * math.sin(a), AG_TOP_Y, 35.0 - r * math.cos(a)) end
		drawQuadTop(f, agPt(AG_R, a0), agPt(AG_R + CURB_W, a0), agPt(AG_R + CURB_W, a1), agPt(AG_R, a1), 0.58, colEdge, "ArrivalCurb")
	end
end

-- CHUNK 4: Branches A..E + Fillets + Pod Ends
do
	local f = newChunk()
	local fc = dp:FindFirstChild("JunctionSupportCollider") or Instance.new("Folder", dp)
	fc.Name = "JunctionSupportCollider"
	local cols = { {-4.50, -1.54}, {-1.46, 1.46}, {1.54, 4.50} }
	local specs = {
		{idx = 1, angle = -math.pi/2, isElbow = true},
		{idx = 2, angle = -math.pi/4, isElbow = false},
		{idx = 3, angle =  0,         isElbow = false},
		{idx = 4, angle =  math.pi/4, isElbow = false},
		{idx = 5, angle =  math.pi/2, isElbow = true},
	}

	for _, sp in ipairs(specs) do
		local a = sp.angle
		local dir = Vector3.new(math.sin(a), 0, -math.cos(a))
		local right = Vector3.new(math.cos(a), 0, math.sin(a))
		local function uvPt(u, v, topY)
			local base = RING_CENTER + dir * v + right * u
			return Vector3.new(base.X, topY, base.Z)
		end
		local function vStart(u)
			if sp.isElbow then return ELBOW_EX end
			return math.sqrt(R_OUT * R_OUT - u * u)
		end
		local function vEnd(u) return POD_DIST - math.sqrt(POD_RIM_R * POD_RIM_R - u * u) end

		local vf_pod = POD_DIST - math.sqrt((POD_RIM_R + RF_POD)^2 - (ROAD_HW + RF_POD)^2)
		local vf_ring = sp.isElbow and ELBOW_EX or math.sqrt((R_OUT + RF_OUT_T)^2 - (ROAD_HW + RF_OUT_T)^2)
		local vSplit = sp.isElbow and 76.85 or 76.6812
		local startSetback = sp.isElbow and 0.04 or 0.05

		for ci, ur in ipairs(cols) do
			local u0, u1 = ur[1], ur[2]
			local um = (u0 + u1) * 0.5
			local vs0, vsm, vs1 = vStart(u0), vStart(um), vStart(u1)
			local ve0, vem, ve1 = vEnd(u0), vEnd(um), vEnd(u1)
			drawQuadTop(f, uvPt(u0, vs0, BED_TOP_Y), uvPt(u1, vs1, BED_TOP_Y), uvPt(u1, ve1, BED_TOP_Y), uvPt(u0, ve0, BED_TOP_Y), BED_THICK, colGrout, "ContinuousBed")
			local col1 = shade(sp.idx * 10 + ci)
			drawQuadTop(f, uvPt(u0, vs0 + startSetback, PAVER_TOP_Y), uvPt(um, vsm + startSetback, PAVER_TOP_Y), uvPt(um, vSplit - 0.04, PAVER_TOP_Y), uvPt(u0, vSplit - 0.04, PAVER_TOP_Y), PAVER_THICK, col1, "StraightPaver")
			drawQuadTop(f, uvPt(um, vsm + startSetback, PAVER_TOP_Y), uvPt(u1, vs1 + startSetback, PAVER_TOP_Y), uvPt(u1, vSplit - 0.04, PAVER_TOP_Y), uvPt(um, vSplit - 0.04, PAVER_TOP_Y), PAVER_THICK, col1, "StraightPaver")
			local col2 = shade(sp.idx * 10 + ci + 3)
			drawQuadTop(f, uvPt(u0, vSplit + 0.04, PAVER_TOP_Y), uvPt(um, vSplit + 0.04, PAVER_TOP_Y), uvPt(um, vem, PAVER_TOP_Y), uvPt(u0, ve0, PAVER_TOP_Y), PAVER_THICK, col2, "StraightPaver")
			drawQuadTop(f, uvPt(um, vSplit + 0.04, PAVER_TOP_Y), uvPt(u1, vSplit + 0.04, PAVER_TOP_Y), uvPt(u1, ve1, PAVER_TOP_Y), uvPt(um, vem, PAVER_TOP_Y), PAVER_THICK, col2, "StraightPaver")
		end
		drawQuadTop(f, uvPt(-1.54, vStart(-1.54), BED_TOP_Y), uvPt(-1.46, vStart(-1.46), BED_TOP_Y), uvPt(-1.46, vEnd(-1.46), BED_TOP_Y), uvPt(-1.54, vEnd(-1.54), BED_TOP_Y), BED_THICK, colGrout, "ContinuousBed")
		drawQuadTop(f, uvPt(1.46, vStart(1.46), BED_TOP_Y), uvPt(1.54, vStart(1.54), BED_TOP_Y), uvPt(1.54, vEnd(1.54), BED_TOP_Y), uvPt(1.46, vEnd(1.46), BED_TOP_Y), BED_THICK, colGrout, "ContinuousBed")

		for _, sSide in ipairs({-1, 1}) do
			local uA = sSide * ROAD_HW
			local uB = sSide * (ROAD_HW + CURB_W)
			if uA > uB then uA, uB = uB, uA end
			drawQuadTop(f, uvPt(uA, vf_ring, CURB_TOP_Y), uvPt(uB, vf_ring, CURB_TOP_Y), uvPt(uB, vf_pod, CURB_TOP_Y), uvPt(uA, vf_pod, CURB_TOP_Y), CURB_THICK, colEdge, "StraightCurb")
		end

		local N_FIL = 10
		if not sp.isElbow then
			for _, sSide in ipairs({-1, 1}) do
				local uf = sSide * (ROAD_HW + RF_OUT_T)
				local ang0, ang1 = math.pi, 1.5 * math.pi - THETA_OUT_T
				for i = 1, N_FIL do
					local t0, t1 = (i - 1) / N_FIL, i / N_FIL
					local a0, a1 = ang0 + (ang1 - ang0) * t0, ang0 + (ang1 - ang0) * t1
					local pu0, pv0 = uf + sSide * RF_OUT_T * math.cos(a0), vf_ring + RF_OUT_T * math.sin(a0)
					local pu1, pv1 = uf + sSide * RF_OUT_T * math.cos(a1), vf_ring + RF_OUT_T * math.sin(a1)
					local rOut = RF_OUT_T - CURB_W
					local cu0, cv0 = uf + sSide * rOut * math.cos(a0), vf_ring + rOut * math.sin(a0)
					local cu1, cv1 = uf + sSide * rOut * math.cos(a1), vf_ring + rOut * math.sin(a1)
					drawQuadTop(f, uvPt(pu0, pv0, CURB_TOP_Y), uvPt(cu0, cv0, CURB_TOP_Y), uvPt(cu1, cv1, CURB_TOP_Y), uvPt(pu1, pv1, CURB_TOP_Y), CURB_THICK, colEdge, "FilletCurb")

					local function refBedOut(t)
						local cAngStart = math.atan2(ROAD_HW, math.sqrt(R_OUT*R_OUT - ROAD_HW*ROAD_HW))
						if t < 0.5 then return sSide * ROAD_HW, vf_ring + (vStart(ROAD_HW) - vf_ring) * (t * 2)
						else
							local ca = cAngStart + (THETA_OUT_T - cAngStart) * ((t - 0.5) * 2)
							return sSide * R_OUT * math.sin(ca), R_OUT * math.cos(ca)
						end
					end
					local function refPaverOut(t)
						local cAngStart = math.atan2(4.58, math.sqrt((R_OUT+0.05)^2 - 4.58^2))
						if t < 0.5 then return sSide * 4.58, vf_ring + ((vStart(4.58) + 0.05) - vf_ring) * (t * 2)
						else
							local ca = cAngStart + (THETA_OUT_T - cAngStart) * ((t - 0.5) * 2)
							return sSide * (R_OUT + 0.05) * math.sin(ca), (R_OUT + 0.05) * math.cos(ca)
						end
					end
					local bu0, bv0 = refBedOut(t0)
					local bu1, bv1 = refBedOut(t1)
					local qu0, qv0 = refPaverOut(t0)
					local qu1, qv1 = refPaverOut(t1)
					drawQuadTop(f, uvPt(bu0, bv0, BED_TOP_Y), uvPt(pu0, pv0, BED_TOP_Y), uvPt(pu1, pv1, BED_TOP_Y), uvPt(bu1, bv1, BED_TOP_Y), BED_THICK, colGrout, "ContinuousBed")
					if i > 1 then
						drawQuadTop(f, uvPt(qu0, qv0, PAVER_TOP_Y), uvPt(pu0, pv0, PAVER_TOP_Y), uvPt(pu1, pv1, PAVER_TOP_Y), uvPt(qu1, qv1, PAVER_TOP_Y), PAVER_THICK, shade(240 + sp.idx * 5 + i), "FilletPaver")
					end
					drawQuadTop(fc, uvPt(bu0, bv0, 10.260), uvPt(pu0, pv0, 10.260), uvPt(pu1, pv1, 10.260), uvPt(bu1, bv1, 10.260), 0.32, colGrout, "JunctionSupportCollider", true, 1)
				end
			end
		end

		for _, sSide in ipairs({-1, 1}) do
			local uf = sSide * (ROAD_HW + RF_POD)
			local ang0, ang1 = math.pi, 0.5 * math.pi + THETA_POD
			for i = 1, N_FIL do
				local t0, t1 = (i - 1) / N_FIL, i / N_FIL
				local a0, a1 = ang0 + (ang1 - ang0) * t0, ang0 + (ang1 - ang0) * t1
				local pu0, pv0 = uf + sSide * RF_POD * math.cos(a0), vf_pod + RF_POD * math.sin(a0)
				local pu1, pv1 = uf + sSide * RF_POD * math.cos(a1), vf_pod + RF_POD * math.sin(a1)
				local function curbWAt(t)
					if t < 0.80 then return CURB_W - 0.10 * (t / 0.80)
					else return 0.35 * (1 - (t - 0.80) / 0.20) + 0.02 * ((t - 0.80) / 0.20) end
				end
				local rOut0, rOut1 = RF_POD - curbWAt(t0), RF_POD - curbWAt(t1)
				local cu0, cv0 = uf + sSide * rOut0 * math.cos(a0), vf_pod + rOut0 * math.sin(a0)
				local cu1, cv1 = uf + sSide * rOut1 * math.cos(a1), vf_pod + rOut1 * math.sin(a1)
				drawQuadTop(f, uvPt(pu0, pv0, CURB_TOP_Y), uvPt(cu0, cv0, CURB_TOP_Y), uvPt(cu1, cv1, CURB_TOP_Y), uvPt(pu1, pv1, CURB_TOP_Y), CURB_THICK, colEdge, "PodFilletCurb")

				local function refBedPod(t)
					local cAngStart = math.atan2(ROAD_HW, math.sqrt(POD_RIM_R*POD_RIM_R - ROAD_HW*ROAD_HW))
					if t < 0.5 then return sSide * ROAD_HW, vf_pod + (vEnd(ROAD_HW) - vf_pod) * (t * 2)
					else
						local ca = cAngStart + (THETA_POD - cAngStart) * ((t - 0.5) * 2)
						return sSide * POD_RIM_R * math.sin(ca), POD_DIST - POD_RIM_R * math.cos(ca)
					end
				end
				local function refPaverPod(t)
					local cAngStart = math.atan2(4.58, math.sqrt(POD_RIM_R*POD_RIM_R - 4.58^2))
					if t < 0.5 then return sSide * 4.58, vf_pod + (vEnd(4.58) - vf_pod) * (t * 2)
					else
						local ca = cAngStart + (THETA_POD - cAngStart) * ((t - 0.5) * 2)
						return sSide * POD_RIM_R * math.sin(ca), POD_DIST - POD_RIM_R * math.cos(ca)
					end
				end
				local bu0, bv0 = refBedPod(t0)
				local bu1, bv1 = refBedPod(t1)
				local qu0, qv0 = refPaverPod(t0)
				local qu1, qv1 = refPaverPod(t1)
				drawQuadTop(f, uvPt(bu0, bv0, BED_TOP_Y), uvPt(pu0, pv0, BED_TOP_Y), uvPt(pu1, pv1, BED_TOP_Y), uvPt(bu1, bv1, BED_TOP_Y), BED_THICK, colGrout, "ContinuousBed")
				if i > 1 then
					drawQuadTop(f, uvPt(qu0, qv0, PAVER_TOP_Y), uvPt(pu0, pv0, PAVER_TOP_Y), uvPt(pu1, pv1, PAVER_TOP_Y), uvPt(qu1, qv1, PAVER_TOP_Y), PAVER_THICK, shade(260 + sp.idx * 5 + i), "FilletPaver")
				end
				drawQuadTop(fc, uvPt(bu0, bv0, 10.260), uvPt(pu0, pv0, 10.260), uvPt(pu1, pv1, 10.260), uvPt(bu1, bv1, 10.260), 0.32, colGrout, "JunctionSupportCollider", true, 1)
			end
		end

		local dl = savedLetters[sp.idx]
		if dl then
			local lPos = RING_CENTER + dir * 76.95
			dl.Position = Vector3.new(lPos.X, 10.380, lPos.Z)
			dl.CFrame = CFrame.new(dl.Position) * CFrame.Angles(0, -a, 0)
			dl.Parent = f
		end
	end
end

for _, chunk in ipairs(chunks) do
	for _, child in ipairs(chunk:GetChildren()) do
		child.Parent = surface
	end
	chunk:Destroy()
	task.wait()
end

return "v3 final surface children=" .. #surface:GetChildren()
