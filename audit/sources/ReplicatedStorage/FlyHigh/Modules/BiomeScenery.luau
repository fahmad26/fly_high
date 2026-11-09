-- Local scenery only. Models never take part in flight physics or target selection.
local Config = require(script.Parent.FlyHighConfig)
local Scenery = {}

local rgb = Color3.fromRGB
local plastic = Enum.Material.SmoothPlastic
local slate = Enum.Material.Slate
local neon = Enum.Material.Neon
local grassMat = Enum.Material.Grass
local woodMat = Enum.Material.Wood
local marbleMat = Enum.Material.Marble
local glassMat = Enum.Material.Glass
local metalMat = Enum.Material.Metal
local sandMat = Enum.Material.Sand
local ball = Enum.PartType.Ball
local cylinder = Enum.PartType.Cylinder

local function altitude(km)
	return Config.GROUND_Y + km * Config.STUDS_PER_KM
end

local function part(parent, name, size, cf, color, material, shape)
	local item = Instance.new(shape == "Wedge" and "WedgePart" or "Part")
	item.Name = name
	item.Size = shape == ball and Vector3.one or size
	item.CFrame = cf
	item.Color = color
	item.Material = material or plastic
	item.Anchored = true
	item.CanCollide = false
	item.CanTouch = false
	item.CanQuery = false
	item.CastShadow = false
	if shape == ball then
		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.Sphere
		mesh.Scale = size
		mesh.Parent = item
	elseif shape and shape ~= "Wedge" then
		item.Shape = shape
	end
	item.Parent = parent
	return item
end

local function model(parent, name)
	local group = Instance.new("Model")
	group.Name = name
	group.Parent = parent
	return group
end

local function landmark(parent, name, cf, scale)
	local environment = script.Parent.Parent:FindFirstChild("EnvironmentAssets")
	local meshes = environment and environment:FindFirstChild("BiomeLandmarkMeshes")
	local template = meshes and meshes:FindFirstChild(name)
	if not template then return nil end
	local copy = template:Clone()
	if scale then copy:ScaleTo(scale) end
	copy:PivotTo(cf or template:GetAttribute("WorldPlacement") or CFrame.identity)
	copy.Parent = parent
	return copy
end

local function span(parent, name, start, finish, width, color, material)
	local delta = finish - start
	local cf = CFrame.lookAt(start:Lerp(finish, 0.5), finish) * CFrame.Angles(0, math.pi / 2, 0)
	return part(parent, name, Vector3.new(delta.Magnitude, width, width), cf, color, material, cylinder)
end

local function column(parent, name, center, width, height, color, material)
	return part(parent, name, Vector3.new(height, width, width),
		CFrame.new(center) * CFrame.Angles(0, 0, math.pi / 2), color, material, cylinder)
end

local function band(parent, name, center, size, colors, seed)
	local group = model(parent, name)
	local random = Random.new(seed)
	local lobes = {}
	for i = 1, 8 do
		local angle = (i - 1) * math.pi / 4
		local radius = i <= 2 and 0.12 or 0.27
		local offset = Vector3.new(math.cos(angle) * size.X * radius,
			random:NextNumber(-0.14, 0.21) * size.Y, math.sin(angle) * size.Z * radius)
		local scale = random:NextNumber(0.78, 1.14)
		lobes[i] = part(group, "CloudLobe", size * Vector3.new(0.64, 0.78, 0.66) * scale,
			CFrame.new(center + offset), colors[(i - 1) % #colors + 1], plastic, ball)
	end
	return lobes
end

local function rail(parent, name, center)
	return part(parent, name, Vector3.one, CFrame.new(center), Color3.new(1, 1, 1))
end

local function socket(parent, offset, tangent)
	local attachment = Instance.new("Attachment")
	attachment.Position = offset
	if tangent then attachment.Axis = tangent.Unit end
	attachment.Parent = parent
	return attachment
end

local function beam(start, finish, width0, width1, color, transparency, curve)
	local ribbon = Instance.new("Beam")
	ribbon.Attachment0 = start
	ribbon.Attachment1 = finish
	ribbon.Width0 = width0
	ribbon.Width1 = width1
	ribbon.Color = color
	ribbon.Transparency = transparency
	ribbon.FaceCamera = true
	ribbon.LightEmission = 0.85
	ribbon.LightInfluence = 0
	ribbon.CurveSize0 = curve or 0
	ribbon.CurveSize1 = curve or 0
	ribbon.Segments = curve and 16 or 4
	ribbon.Parent = start.Parent
	return ribbon
end

local function softFade(edge, middle)
	return NumberSequence.new({
		NumberSequenceKeypoint.new(0, edge),
		NumberSequenceKeypoint.new(0.35, middle),
		NumberSequenceKeypoint.new(0.72, middle),
		NumberSequenceKeypoint.new(1, edge),
	})
end

local function buildCanopyTree(parent, baseCf, scale, leafColors, trunkColor)
	local tree = model(parent, "CanopyTree")
	local p0 = baseCf.Position
	local trunkTop = (baseCf * CFrame.new(1.2 * scale, 11.5 * scale, -0.8 * scale)).Position
	span(tree, "Trunk", p0, trunkTop, 2.2 * scale, trunkColor, woodMat)
	for i, branchOffset in {
		Vector3.new(-4.5, 4.2, 2.2),
		Vector3.new(4.8, 3.8, -1.8),
		Vector3.new(0.5, 5.4, 3.6),
	} do
		local tip = trunkTop + branchOffset * scale
		span(tree, "Branch", trunkTop - Vector3.new(0, 1.5 * scale, 0), tip, 1.1 * scale, trunkColor, woodMat)
		part(tree, "CanopyCluster", Vector3.new(13, 7.5, 11.5) * scale,
			CFrame.new(tip + Vector3.new(0, 1.4 * scale, 0)), leafColors[(i - 1) % #leafColors + 1], plastic, ball)
	end
	part(tree, "MainCrown", Vector3.new(17.5, 9.2, 15.5) * scale,
		CFrame.new(trunkTop + Vector3.new(0, 4.2 * scale, 0)), leafColors[1], plastic, ball)
	part(tree, "CrownHighlight", Vector3.new(12.5, 6.5, 11) * scale,
		CFrame.new(trunkTop + Vector3.new(-1.5 * scale, 6.8 * scale, 1.2 * scale)), leafColors[#leafColors], plastic, ball)
	return tree
end

local function buildFloatingRockIslet(parent, name, cf, width, hasWaterfall, seed)
	local islet = model(parent, name)
	local random = Random.new(seed)
	local rockColor = rgb(104, 122, 132)
	local darkRock = rgb(76, 92, 104)
	local rimColor = rgb(162, 148, 126)
	local grassColor = rgb(86, 156, 92)
	local leafPalette = { rgb(82, 158, 88), rgb(114, 182, 98), rgb(64, 134, 78) }
	local depth = width * random:NextNumber(0.74, 0.92)
	local height = width * random:NextNumber(0.42, 0.56)

	part(islet, "RockCore", Vector3.new(width, height, depth), cf, rockColor, slate, ball)
	part(islet, "SandstoneRim", Vector3.new(width * 0.96, height * 0.42, depth * 0.94),
		cf * CFrame.new(0, height * 0.24, 0), rimColor, slate, ball)
	part(islet, "GrassyCap", Vector3.new(width * 0.9, height * 0.36, depth * 0.88),
		cf * CFrame.new(0, height * 0.42, 0), grassColor, grassMat, ball)

	for i = 1, 5 do
		local a = (i - 1) * math.pi * 2 / 5 + random:NextNumber(-0.2, 0.2)
		local r = width * 0.26
		local spikeH = height * random:NextNumber(0.85, 1.35)
		part(islet, "UnderCrag", Vector3.new(width * 0.36, spikeH, depth * 0.34),
			cf * CFrame.new(math.cos(a) * r, -height * 0.48, math.sin(a) * r)
				* CFrame.Angles(math.pi, a + 0.4, random:NextNumber(-0.22, 0.22)),
			i % 2 == 0 and darkRock or rockColor, slate, "Wedge")
	end
	part(islet, "KeelTip", Vector3.new(width * 0.38, height * 1.15, depth * 0.38),
		cf * CFrame.new(0, -height * 0.72, 0) * CFrame.Angles(math.pi, 0.6, 0.15), darkRock, slate, "Wedge")

	for i = 1, 3 do
		local vineStart = (cf * CFrame.new((i - 2) * width * 0.26, -height * 0.12, depth * 0.32)).Position
		local vineMid = vineStart + Vector3.new(i - 2, -height * 0.55, 1.5)
		span(islet, "HangingVine", vineStart, vineMid, 1.1, rgb(74, 132, 78), grassMat)
		span(islet, "VineTip", vineMid, vineMid + Vector3.new(0.8, -height * 0.45, -0.8), 0.65, rgb(98, 158, 88), grassMat)
	end

	local treeScale = math.clamp(width / 38, 0.62, 1.35)
	buildCanopyTree(islet, cf * CFrame.new(-width * 0.08, height * 0.48, -depth * 0.06), treeScale, leafPalette, rgb(138, 96, 68))

	if hasWaterfall then
		local lipCf = cf * CFrame.new(width * 0.34, height * 0.44, depth * 0.12)
		part(islet, "SpringPool", Vector3.new(width * 0.38, 2.2, depth * 0.32),
			cf * CFrame.new(width * 0.22, height * 0.46, depth * 0.1), rgb(112, 208, 235), plastic, ball)
		local carrier = rail(islet, "ThinWaterfall", lipCf.Position)
		carrier.Transparency = 1
		local drop = height * 2.5
		for j = -1, 1 do
			local off = Vector3.new(j * 2.1, 0, 0)
			local stream = beam(
				socket(carrier, off, Vector3.new(0.25, -1, 0.15)),
				socket(carrier, off + Vector3.new(5, -drop, 6), Vector3.new(0.1, -1, 0.15)),
				3.2, 7.5,
				ColorSequence.new(rgb(96, 192, 240), rgb(215, 244, 255)),
				softFade(0.9, 0.24),
				12
			)
			stream.LightEmission = 0.35
		end
		for j = 1, 3 do
			local mist = part(islet, "WaterfallMist", Vector3.new(12 + j * 4, 5 + j * 1.5, 12 + j * 4),
				CFrame.new(lipCf.Position + Vector3.new(5, -drop + j * 3, 6)), rgb(238, 246, 255), plastic, ball)
			mist.Transparency = 0.48 + j * 0.1
		end
	end
	islet.WorldPivot = cf
	return islet
end

local function buildWeatherBalloon(parent, cf, scale)
	local wb = model(parent, "WeatherBalloon")
	local royalBlue = rgb(48, 106, 198)
	local skyBlue = rgb(82, 152, 232)
	local gold = rgb(244, 192, 78)
	local brass = rgb(208, 154, 64)
	local navy = rgb(34, 64, 128)

	-- Distinct spherical-teardrop meteorological envelope with gold meridian bands and instrument sonde
	part(wb, "EnvelopeMain", Vector3.new(26, 30, 26) * scale, cf * CFrame.new(0, 16 * scale, 0), royalBlue, plastic, ball)
	part(wb, "EnvelopeCrown", Vector3.new(21, 12, 21) * scale, cf * CFrame.new(0, 27 * scale, 0), skyBlue, plastic, ball)
	part(wb, "EnvelopeCone", Vector3.new(16, 14, 16) * scale, cf * CFrame.new(0, 4 * scale, 0), navy, plastic, ball)
	part(wb, "EquatorialGoldBand", Vector3.new(27.2, 3.6, 27.2) * scale, cf * CFrame.new(0, 16 * scale, 0), gold, plastic, ball)

	for i = 1, 4 do
		local angle = (i - 1) * math.pi / 4
		part(wb, "GoldMeridian", Vector3.new(2.2, 29.5, 26.8) * scale,
			cf * CFrame.new(0, 16 * scale, 0) * CFrame.Angles(0, angle, 0), gold, plastic, ball)
	end
	for _, side in { -1, 1 } do
		part(wb, "SunEmblem", Vector3.new(7.5, 7.5, 1.8) * scale,
			cf * CFrame.new(0, 16 * scale, side * 13.2 * scale), gold, neon, ball)
	end

	-- Top meteorological mast & anemometer ring
	column(wb, "TopMast", (cf * CFrame.new(0, 35 * scale, 0)).Position, 0.8 * scale, 8 * scale, brass, metalMat)
	part(wb, "TopBeacon", Vector3.one * (2.6 * scale), cf * CFrame.new(0, 39.5 * scale, 0), rgb(255, 224, 118), neon, ball)

	-- Suspended brass weather sonde pod (compact octagonal/cylindrical instrument capsule, not a passenger basket)
	local podCenter = (cf * CFrame.new(0, -8 * scale, 0)).Position
	for i = 1, 4 do
		local a = (i - 1) * math.pi / 2 + math.pi / 4
		local topAttach = (cf * CFrame.new(math.cos(a) * 6.5 * scale, 1 * scale, math.sin(a) * 6.5 * scale)).Position
		local botAttach = podCenter + Vector3.new(math.cos(a) * 2.8 * scale, 2.5 * scale, math.sin(a) * 2.8 * scale)
		span(wb, "RiggingCable", topAttach, botAttach, 0.35 * scale, brass, metalMat)
	end
	column(wb, "SondeCapsule", podCenter, 6.2 * scale, 5.2 * scale, brass, metalMat)
	part(wb, "SondeSensorDome", Vector3.new(4.8, 3.6, 4.8) * scale, cf * CFrame.new(0, -11 * scale, 0), royalBlue, plastic, ball)
	column(wb, "VaneBoom", podCenter + Vector3.new(0, -4.5 * scale, 0), 0.5 * scale, 5 * scale, brass, metalMat)

	-- Fluttering tail ribbons / pennants
	local tailCarrier = rail(wb, "TailRibbons", podCenter)
	tailCarrier.Transparency = 1
	local s1 = socket(tailCarrier, Vector3.new(-2 * scale, 0, 0), Vector3.new(-1, -0.3, 0.2))
	local f1 = socket(tailCarrier, Vector3.new(-18 * scale, -9 * scale, 6 * scale), Vector3.new(-1, -0.1, 0.3))
	beam(s1, f1, 2.4 * scale, 0.7 * scale, ColorSequence.new(skyBlue, gold), softFade(0.2, 0.05), 8 * scale)

	local s2 = socket(tailCarrier, Vector3.new(2 * scale, -1 * scale, 0), Vector3.new(-1, -0.4, -0.2))
	local f2 = socket(tailCarrier, Vector3.new(-15 * scale, -12 * scale, -5 * scale), Vector3.new(-1, -0.2, -0.2))
	beam(s2, f2, 2.0 * scale, 0.6 * scale, ColorSequence.new(gold, royalBlue), softFade(0.2, 0.05), -7 * scale)

	wb.WorldPivot = cf
	return wb
end

local function buildSeabirdFlock(parent, centerCf, birdCount, scale)
	local flock = model(parent, "DistantSeabirdFlock")
	local plumage = rgb(250, 250, 252)
	local wingTip = rgb(58, 74, 98)
	local beakColor = rgb(242, 178, 72)

	for i = 1, birdCount do
		local side = i == 1 and 0 or (i % 2 == 0 and 1 or -1)
		local rank = math.floor(i / 2)
		local offset = Vector3.new(side * rank * 7.5 * scale, math.abs(rank) * 1.4 * scale + (i % 2) * 0.8, rank * 6.2 * scale)
		local bcf = centerCf * CFrame.new(offset)
		local bird = model(flock, "Seabird")
		part(bird, "Body", Vector3.new(1.8, 1.3, 4.8) * scale, bcf, plumage, plastic, ball)
		part(bird, "Beak", Vector3.new(0.7, 0.6, 1.6) * scale, bcf * CFrame.new(0, 0.1 * scale, -2.6 * scale), beakColor, plastic, "Wedge")
		for _, wSide in { -1, 1 } do
			local innerCf = bcf * CFrame.new(wSide * 2.6 * scale, 0.4 * scale, 0.2 * scale)
				* CFrame.Angles(0, wSide * -0.12, wSide * 0.28)
			local outerCf = innerCf * CFrame.new(wSide * 2.8 * scale, 0.3 * scale, 0.5 * scale)
				* CFrame.Angles(0, wSide * -0.18, wSide * -0.36)
			part(bird, "InnerWing", Vector3.new(5.4, 0.45, 2.1) * scale, innerCf, plumage, plastic, ball)
			part(bird, "OuterWing", Vector3.new(4.2, 0.38, 1.6) * scale, outerCf, wingTip, plastic, ball)
		end
	end
	flock.WorldPivot = centerCf
	return flock
end

local function dawn(parent)
	local sand, grass, reef = rgb(241, 218, 168), rgb(80, 142, 94), rgb(170, 215, 194)
	local rock = rgb(108, 139, 139)
	local random = Random.new(802)
	local headland = landmark(parent, "Dawn", CFrame.new(115, -5, -308) * CFrame.Angles(0, 0.32, 0))
	for i = 1, 9 do
		local angle = (i - 1) * math.pi * 2 / 9 + 0.2
		local direction = Vector3.new(math.cos(angle), 0, math.sin(angle))
		local position = direction * random:NextNumber(235, 365)
		if headland and i == 8 then continue end
		local island = model(parent, "CoastalIslet")
		local cf = CFrame.new(position) * CFrame.Angles(0, angle, 0)
		local width = random:NextNumber(29, 60)
		part(island, "PaleReef", Vector3.new(width + 15, 3.4, width * 0.85), cf, reef, sandMat, ball)
		part(island, "Shore", Vector3.new(width, 10, width * 0.68), cf * CFrame.new(0, 2, 0), sand, sandMat, ball)
		local side = i % 2 == 0 and -1 or 1
		local cove = cf * CFrame.new(width * 0.21, 1.8, width * side * 0.19) * CFrame.Angles(0, side * 0.64, 0)
		part(island, "SandSpit", Vector3.new(width * 0.62, 6, width * 0.36), cove, sand, sandMat, ball)
		part(island, "GrassyCrest", Vector3.new(width * 0.71, 10, width * 0.49),
			cf * CFrame.new(-width * 0.08, 4.6, -side * width * 0.05), grass, grassMat, ball)
		part(island, "Headland", Vector3.new(width * 0.39, 7, width * 0.32), cove * CFrame.new(-3, 3.7, -side * 2),
			rgb(109, 155, 99), grassMat, ball)
		for j = 1, 4 do
			local offset = Vector3.new(random:NextNumber(-0.48, 0.48) * width, 2, j % 2 == 0 and width * 0.31 or -width * 0.28)
			part(island, "CoastalRock", Vector3.new(6, random:NextNumber(4, 8), 5),
				cf * CFrame.new(offset) * CFrame.Angles(0, j * 1.2, 0.2), rock, slate, "Wedge")
		end
		local foot = (cf * CFrame.new(-width * 0.13, 8, 0)).Position
		local crown = foot + Vector3.new(2.8, 8 + i % 3, -1.6)
		span(island, "PalmTrunk", foot, crown, 1.3, rgb(152, 108, 73), woodMat)
		for j = 1, 5 do
			local bearing = angle + j * math.pi * 2 / 5
			local tip = crown + Vector3.new(math.cos(bearing) * 5.6, -1.1, math.sin(bearing) * 5.6)
			part(island, "PalmFrond", Vector3.new(2.3, 0.65, 6.9), CFrame.lookAt(crown:Lerp(tip, 0.45), tip),
				j % 2 == 0 and rgb(75, 141, 88) or rgb(102, 165, 92), plastic, ball)
		end
	end

	local boats = {}
	for i = 1, 4 do
		local angle = i * math.pi / 2 + 0.65
		local position = Vector3.new(math.cos(angle) * 255, 2, math.sin(angle) * 255)
		local boat = model(parent, "DistantSailboat")
		local cf = CFrame.new(position) * CFrame.Angles(0, angle, 0)
		part(boat, "Hull", Vector3.new(4, 2.4, 13), cf, rgb(104, 65, 54), woodMat, ball)
		column(boat, "Mast", position + Vector3.new(0, 5, 0), 0.36, 10, rgb(151, 98, 62), woodMat)
		part(boat, "MainSail", Vector3.new(0.35, 9, 6), cf * CFrame.new(0, 5.7, 2.8), rgb(255, 246, 217), plastic, "Wedge")
		part(boat, "Jib", Vector3.new(0.3, 6, 4), cf * CFrame.new(0, 4.3, -2.3) * CFrame.Angles(0, math.pi, 0),
			rgb(234, 153, 96), plastic, "Wedge")
		boat.WorldPivot = cf
		boats[i] = { boat = boat, origin = cf }
	end

	-- P1 & P2: Low floating rock/island kits with plant tops + waterfall variant transitioning to cloud layer
	local isletSpecs = {
		-- Around 500 km (staggered horizontally across lanes so upward & forward sightlines never stack)
		{ km = 480, x = -112, z = -238, width = 42, yaw = 0.35, waterfall = false },
		{ km = 520, x = 246, z = -28, width = 40, yaw = -1.2, waterfall = false },
		{ km = 590, x = -248, z = 24, width = 36, yaw = 1.4, waterfall = false },
		{ km = 780, x = 68, z = -252, width = 44, yaw = -0.4, waterfall = false },
		-- Around 1,200 km (staggered lanes across forward, side, and upper-forward layers)
		{ km = 1170, x = 128, z = -236, width = 48, yaw = -0.35, waterfall = false },
		{ km = 1210, x = 244, z = -22, width = 44, yaw = -1.35, waterfall = false },
		{ km = 1260, x = -246, z = -18, width = 38, yaw = 1.25, waterfall = false },
		{ km = 1520, x = 58, z = -262, width = 40, yaw = -0.5, waterfall = false },
		-- P2: Waterfall floating island variant near upper transition (visible looking up at 1,200 km & forward at 1,800-1,900 km)
		{ km = 1660, x = -134, z = -248, width = 64, yaw = 0.32, waterfall = true },
		-- Around 1,900 km (distinct horizontal lane from 1,660 km waterfall island)
		{ km = 1860, x = -68, z = -234, width = 56, yaw = 0.28, waterfall = true },
		{ km = 1890, x = 245, z = -24, width = 42, yaw = -1.4, waterfall = false },
		{ km = 1940, x = -246, z = 22, width = 36, yaw = 1.5, waterfall = false },
	}
	for idx, spec in isletSpecs do
		local cf = CFrame.new(spec.x, altitude(spec.km), spec.z) * CFrame.Angles(0, spec.yaw, 0)
		local name = spec.waterfall and "DawnWaterfallIsle" or "LowFloatingIslet"
		buildFloatingRockIslet(parent, name, cf, spec.width, spec.waterfall, 900 + idx * 17)
	end

	-- P1: Decorative weather balloons with distinct round/teardrop blue-gold silhouette
	local balloonSpecs = {
		{ km = 540, pos = Vector3.new(98, altitude(540), -225), yaw = -0.35, scale = 1.12 },
		{ km = 1230, pos = Vector3.new(-74, altitude(1230), -222), yaw = 0.38, scale = 1.16 },
		{ km = 1320, pos = Vector3.new(236, altitude(1320), 42), yaw = -1.25, scale = 1.08 },
		{ km = 1910, pos = Vector3.new(104, altitude(1910), -224), yaw = -0.28, scale = 1.12 },
	}
	local weatherBalloons = {}
	for idx, spec in balloonSpecs do
		local cf = CFrame.new(spec.pos) * CFrame.Angles(0, spec.yaw, 0)
		local wb = buildWeatherBalloon(parent, cf, spec.scale)
		weatherBalloons[idx] = { model = wb, origin = cf }
	end

	-- P1: Distant decorative seabird flocks gliding outside the flight corridor
	local flockSpecs = {
		{ km = 510, radius = 232, baseAngle = -1.62, speed = 0.045, count = 6, scale = 1.2 },
		{ km = 860, radius = 242, baseAngle = -0.15, speed = -0.048, count = 5, scale = 1.2 },
		{ km = 1240, radius = 235, baseAngle = -1.52, speed = 0.042, count = 6, scale = 1.22 },
		{ km = 1880, radius = 236, baseAngle = -1.58, speed = -0.044, count = 6, scale = 1.2 },
	}
	local birdFlocks = {}
	for idx, spec in flockSpecs do
		local y = altitude(spec.km)
		local pos = Vector3.new(math.cos(spec.baseAngle) * spec.radius, y, math.sin(spec.baseAngle) * spec.radius)
		local cf = CFrame.new(pos)
		local flock = buildSeabirdFlock(parent, cf, spec.count, spec.scale)
		birdFlocks[idx] = { flock = flock, spec = spec, y = y }
	end

	-- Polish: Re-arrange coastal clouds into Near, Mid, and Far depth layers spanning takeoff to 2,000 km
	local cloudColors = { rgb(254, 247, 230), rgb(226, 237, 250), rgb(240, 243, 251) }
	local cloudLayers = {
		-- Near layer (camera-level silhouettes around corridor)
		{ count = 8, minKm = 320, stepKm = 205, radius = 258, size = Vector3.new(135, 26, 88), phase = 0.15 },
		-- Mid layer
		{ count = 9, minKm = 440, stepKm = 180, radius = 342, size = Vector3.new(178, 34, 112), phase = 0.52 },
		-- Far horizon layer
		{ count = 7, minKm = 260, stepKm = 245, radius = 455, size = Vector3.new(235, 42, 142), phase = 0.88 },
	}
	local cloudParts = {}
	local seedCounter = 31
	for _, layer in cloudLayers do
		for i = 1, layer.count do
			seedCounter += 1
			local angle = (i - 1) * math.pi * 2 / layer.count + layer.phase
			local y = altitude(layer.minKm + (i - 1) * layer.stepKm)
			local center = Vector3.new(math.cos(angle) * layer.radius, y, math.sin(angle) * layer.radius)
			for _, cloud in band(parent, "CoastalCloudBank", center, layer.size, cloudColors, seedCounter) do
				cloud.Transparency = 0.12
				table.insert(cloudParts, cloud)
			end
		end
	end

	local lastCloudTransparency
	return function(km, time)
		-- Keep coastal clouds readable all the way from 0 km to 2,000 km
		local cloudTransparency = math.round((0.08 + math.clamp((km - 1550) / 550, 0, 1) * 0.22) * 50) / 50
		if cloudTransparency ~= lastCloudTransparency then
			lastCloudTransparency = cloudTransparency
			for _, cloud in cloudParts do cloud.Transparency = cloudTransparency end
		end
		for i, item in boats do
			item.boat:PivotTo(item.origin * CFrame.new(0, math.sin(time * 0.65 + i) * 0.3, math.sin(time * 0.08 + i) * 10))
		end
		for i, item in weatherBalloons do
			local bob = math.sin(time * 0.55 + i * 1.7) * 3.2
			local drift = math.cos(time * 0.28 + i) * 4.5
			local sway = math.sin(time * 0.42 + i) * 0.05
			item.model:PivotTo(item.origin * CFrame.new(drift, bob, 0) * CFrame.Angles(0, sway, sway * 0.5))
		end
		for i, item in birdFlocks do
			local s = item.spec
			local angle = s.baseAngle + math.sin(time * s.speed + i) * 0.35
			local nextAngle = angle + (s.speed >= 0 and 0.08 or -0.08)
			local p0 = Vector3.new(math.cos(angle) * s.radius, item.y + math.sin(time * 0.5 + i) * 3.5, math.sin(angle) * s.radius)
			local p1 = Vector3.new(math.cos(nextAngle) * s.radius, item.y, math.sin(nextAngle) * s.radius)
			item.flock:PivotTo(CFrame.lookAt(p0, p1) * CFrame.Angles(0, 0, math.sin(time * 0.9 + i) * 0.08))
		end
	end
end

local function buildStormVortex(parent, name, basePos, topWidth, bottomWidth, height, ringCount, seed)
	local vortex = model(parent, name)
	local random = Random.new(seed)
	local colors = {
		rgb(62, 56, 106),
		rgb(82, 76, 134),
		rgb(98, 92, 158),
		rgb(122, 116, 192),
	}
	local rings = {}
	for i = 1, ringCount do
		local t = (i - 1) / (ringCount - 1)
		local eased = t * t * (3 - 2 * t)
		local w = bottomWidth + (topWidth - bottomWidth) * eased
		local h = 14 + eased * 18
		local y = basePos.Y + (t - 0.5) * height
		local bendX = math.sin(t * math.pi * 1.2) * (topWidth * 0.14)
		local bendZ = math.cos(t * math.pi * 1.1) * (topWidth * 0.08)
		local ringCenter = Vector3.new(basePos.X + bendX, y, basePos.Z + bendZ)
		local ringModel = model(vortex, "VortexTier")
		local ringCf = CFrame.new(ringCenter)
		part(ringModel, "FunnelCore", Vector3.new(w, h, w * 0.88), ringCf, colors[(i - 1) % #colors + 1], plastic, ball)
		for j = 1, 4 do
			local a = (j - 1) * math.pi / 2 + i * 0.35
			local lobeOff = Vector3.new(math.cos(a) * w * 0.34, random:NextNumber(-2, 2), math.sin(a) * w * 0.3)
			part(ringModel, "FunnelSwirl", Vector3.new(w * 0.55, h * 0.82, w * 0.44),
				ringCf * CFrame.new(lobeOff) * CFrame.Angles(0, a, 0.12),
				colors[(i + j) % #colors + 1], plastic, ball)
		end
		if i % 3 == 0 then
			local glow = part(ringModel, "VortexLightningCore", Vector3.new(w * 0.62, h * 0.38, w * 0.62),
				ringCf, rgb(164, 152, 248), neon, ball)
			glow.Transparency = 0.52
		end
		ringModel.WorldPivot = ringCf
		rings[i] = { model = ringModel, origin = ringCf, radius = 3.5 + (1 - t) * 5.5, phase = i * 0.55 }
	end
	return rings
end

local function buildStormRockFragment(parent, cf, scale, seed)
	local frag = model(parent, "StormEdgeFragment")
	local random = Random.new(seed)
	local darkSlate = rgb(54, 48, 82)
	local glowColor = seed % 2 == 0 and rgb(238, 148, 86) or rgb(168, 124, 248)
	part(frag, "SlateBody", Vector3.new(15, 19, 13) * scale, cf * CFrame.Angles(0.25, 0.4, -0.18), darkSlate, slate, "Wedge")
	part(frag, "SlateShoulder", Vector3.new(11, 14, 10) * scale,
		cf * CFrame.new(4 * scale, -3 * scale, 2 * scale) * CFrame.Angles(math.pi, 1.1, 0.22), darkSlate, slate, "Wedge")
	for i = 1, 3 do
		local veinCf = cf * CFrame.new((i - 2) * 3.2 * scale, (i % 2 - 0.5) * 4 * scale, -2.5 * scale)
			* CFrame.Angles(random:NextNumber(-0.4, 0.4), i * 0.8, 0.3)
		local vein = part(frag, "ChargedVein", Vector3.new(2.4, 8.5, 2.4) * scale, veinCf, glowColor, neon, "Wedge")
		vein.Transparency = 0.22
	end
	frag.WorldPivot = cf
	return frag
end

local function thundercloud(parent)
	local banks, rain = {}, {}
	local indigo = { rgb(78, 78, 119), rgb(96, 91, 146), rgb(109, 112, 163) }
	local anvilPalette = { rgb(68, 64, 110), rgb(92, 86, 148), rgb(118, 114, 178) }
	local random = Random.new(2020)

	for i = 1, 12 do
		local angle = (i - 1) * math.pi * 2 / 12 + random:NextNumber(-0.1, 0.1)
		local radius = random:NextNumber(295, 395)
		local y = altitude(2060 + i * 150) + random:NextNumber(-28, 28)
		local position = Vector3.new(math.cos(angle) * radius, y, math.sin(angle) * radius)
		local size = Vector3.new(random:NextNumber(145, 235), random:NextNumber(72, 155), random:NextNumber(110, 168))
		local clouds = band(parent, "ThunderheadCliff", position, size, indigo, i * 19)
		banks[#banks + 1] = { lobe = clouds[3], color = clouds[3].Color }

		-- Polish: Clearer slanted rain curtains visible from the balloon gondola
		if i % 2 == 0 or i == 3 or i == 9 then
			local origin = position + Vector3.new(0, -68, 0)
			local carrier = rail(parent, "SlantedRainCurtain", origin)
			carrier.Transparency = 1
			rain[#rain + 1] = { part = carrier, origin = origin }
			for j = 1, 16 do
				local offset = Vector3.new(random:NextNumber(-64, 64), random:NextNumber(-42, 42), random:NextNumber(-32, 32))
				local streak = beam(
					socket(carrier, offset),
					socket(carrier, offset + Vector3.new(-32, -132, 8)),
					2.8, 1.8,
					ColorSequence.new(rgb(172, 196, 255), rgb(132, 158, 242)),
					softFade(0.92, 0.26)
				)
				streak.LightEmission = 0.92
			end
		end
	end

	-- Polish: Reuse cloud cliffs and storm towers to create separate anvil formations
	local anvilSpecs = {
		{ km = 2380, pos = Vector3.new(245, altitude(2380), -210), yaw = -0.45, scale = 0.95 },
		{ km = 3040, pos = Vector3.new(-225, altitude(3040), -215), yaw = 0.55, scale = 1.15 },
		{ km = 3020, pos = Vector3.new(275, altitude(3020), -25), yaw = -1.45, scale = 1.05 },
		{ km = 3520, pos = Vector3.new(-45, altitude(3520), -275), yaw = 0.15, scale = 1.1 },
	}
	for idx, spec in anvilSpecs do
		local storm = landmark(parent, "Storm", CFrame.new(spec.pos) * CFrame.Angles(0, spec.yaw, 0), spec.scale)
		if storm then
			local crown = storm:FindFirstChild("IndigoLight")
			if crown then banks[#banks + 1] = { lobe = crown, color = crown.Color } end
		end
		-- Separate spreading anvil top crowning the tower
		local anvilTop = spec.pos + Vector3.new(0, 76 * spec.scale, 0)
		local anvilLobes = band(parent, "SeparateStormAnvil", anvilTop,
			Vector3.new(245, 58, 185) * spec.scale, anvilPalette, 300 + idx * 29)
		banks[#banks + 1] = { lobe = anvilLobes[1], color = anvilLobes[1].Color }
	end

	-- P1: Two background storm vortex silhouettes (1 wide profile, 1 slender profile) outside corridor with slow motion
	local vortexRings = {}
	for _, r in buildStormVortex(
		parent, "WideStormVortex",
		Vector3.new(-138, altitude(2980), -285),
		154, 22, 210, 12, 2401
	) do
		table.insert(vortexRings, r)
	end
	for _, r in buildStormVortex(
		parent, "SlenderStormVortex",
		Vector3.new(128, altitude(3110), -278),
		90, 14, 232, 13, 2402
	) do
		table.insert(vortexRings, r)
	end

	-- P2: Dimly glowing rock fragments at the storm edges for extra visual depth
	local fragmentSpecs = {
		{ km = 2320, x = -155, z = -225, scale = 1.1 },
		{ km = 2640, x = 165, z = -230, scale = 1.0 },
		{ km = 2940, x = -58, z = -232, scale = 1.25 },
		{ km = 3040, x = 56, z = -238, scale = 1.2 },
		{ km = 3030, x = 238, z = 38, scale = 1.15 },
		{ km = 3070, x = -238, z = -42, scale = 1.1 },
		{ km = 3380, x = 92, z = -242, scale = 1.15 },
		{ km = 3740, x = -125, z = -235, scale = 1.05 },
	}
	local fragments = {}
	for idx, spec in fragmentSpecs do
		local cf = CFrame.new(spec.x, altitude(spec.km), spec.z) * CFrame.Angles(0, idx * 1.1, 0)
		local frag = buildStormRockFragment(parent, cf, spec.scale, 2600 + idx)
		fragments[idx] = { model = frag, origin = cf }
	end

	return function(_, time)
		for i, item in rain do
			item.part.Position = item.origin + Vector3.new(math.sin(time * 0.4 + i) * 9, math.sin(time * 0.78 + i) * 12, 0)
		end
		for i, item in banks do
			local phase = (time + i * 3.19) % 13
			local pulse = math.max(0, 1 - math.abs(phase - 1.3) / 0.85)
			item.lobe.Color = item.color:Lerp(rgb(174, 175, 248), pulse * 0.82)
		end
		for _, ring in vortexRings do
			local a = time * 0.38 + ring.phase
			local shift = Vector3.new(math.cos(a) * ring.radius, math.sin(a * 0.7) * 1.8, math.sin(a) * ring.radius)
			ring.model:PivotTo(ring.origin * CFrame.new(shift) * CFrame.Angles(0, a * 0.35, 0))
		end
		for i, frag in fragments do
			frag.model:PivotTo(frag.origin * CFrame.new(0, math.sin(time * 0.48 + i) * 3.5, 0)
				* CFrame.Angles(math.sin(time * 0.25 + i) * 0.06, time * 0.08, 0))
		end
	end
end

local function buildBlossomTree(parent, baseCf, scale)
	local tree = model(parent, "SunsetBlossomTree")
	local trunkColor = rgb(96, 58, 68)
	local blossomColors = {
		rgb(248, 122, 162),
		rgb(255, 162, 192),
		rgb(228, 92, 138),
	}
	local p0 = baseCf.Position
	local p1 = (baseCf * CFrame.new(2.2 * scale, 13.5 * scale, -1.2 * scale)).Position
	span(tree, "GnarledTrunk", p0, p1, 2.8 * scale, trunkColor, woodMat)
	for i, bOff in {
		Vector3.new(-6.5, 5.2, 2.4),
		Vector3.new(6.2, 4.6, -2.2),
		Vector3.new(0.8, 6.8, 4.5),
		Vector3.new(-2.4, 3.8, -5.2),
	} do
		local tip = p1 + bOff * scale
		span(tree, "BlossomBough", p1 - Vector3.new(0, 2 * scale, 0), tip, 1.4 * scale, trunkColor, woodMat)
		part(tree, "BlossomCanopy", Vector3.new(15.5, 8.2, 13.5) * scale,
			CFrame.new(tip + Vector3.new(0, 1.8 * scale, 0)), blossomColors[(i - 1) % #blossomColors + 1], plastic, ball)
	end
	part(tree, "BlossomCrown", Vector3.new(21, 9.8, 18) * scale,
		CFrame.new(p1 + Vector3.new(0, 5.2 * scale, 0)), blossomColors[1], plastic, ball)
	part(tree, "BlossomHighlight", Vector3.new(14, 6.8, 12.5) * scale,
		CFrame.new(p1 + Vector3.new(-2 * scale, 8.2 * scale, 1.5 * scale)), blossomColors[2], plastic, ball)
	return tree
end

local function buildWindChimeRuin(parent, baseCf, scale, chimeList)
	local shrine = model(parent, "WindChimeRuin")
	local masonry = rgb(208, 168, 142)
	local timber = rgb(118, 74, 68)
	local gold = rgb(242, 192, 92)
	local ribbonColor = rgb(238, 112, 128)

	column(shrine, "ShrinePillar", (baseCf * CFrame.new(0, 13 * scale, 0)).Position, 5.2 * scale, 26 * scale, masonry, slate)
	part(shrine, "PillarCap", Vector3.new(8.2, 3.2, 8.2) * scale, baseCf * CFrame.new(0, 26.5 * scale, 0), masonry, slate)
	part(shrine, "CrossBeam", Vector3.new(28, 2.8, 3.4) * scale, baseCf * CFrame.new(9 * scale, 24.5 * scale, 0), timber, woodMat)
	part(shrine, "BeamBrace", Vector3.new(2.4, 11, 2.6) * scale,
		baseCf * CFrame.new(4.5 * scale, 19.5 * scale, 0) * CFrame.Angles(0, 0, -0.68), timber, woodMat)

	for i = 1, 4 do
		local xOff = (4 + i * 4.6) * scale
		local topPos = (baseCf * CFrame.new(xOff, 23 * scale, 0)).Position
		local chimeLen = (8.5 + (i % 2) * 3.2) * scale
		local chimeModel = model(shrine, "HangingWindChime")
		local pivotCf = CFrame.new(topPos)
		span(chimeModel, "ChimeCord", topPos, topPos + Vector3.new(0, -3.5 * scale, 0), 0.35 * scale, timber, woodMat)
		column(chimeModel, "GoldenTube", topPos + Vector3.new(0, -(3.5 + chimeLen * 0.5) * scale, 0),
			1.5 * scale, chimeLen, gold, metalMat)
		part(chimeModel, "ChimeTag", Vector3.new(0.4, 5.5, 1.8) * scale,
			CFrame.new(topPos + Vector3.new(0, -(4.5 + chimeLen) * scale, 0)), ribbonColor, neon)
		chimeModel.WorldPivot = pivotCf
		table.insert(chimeList, { model = chimeModel, origin = pivotCf, phase = i * 1.1 })
	end
	return shrine
end

local function buildBrokenStoneBridge(parent, startPos, finishPos, seed)
	local bridge = model(parent, "BrokenStoneBridge")
	local masonry = rgb(206, 166, 140)
	local darkStone = rgb(146, 108, 118)
	local moss = rgb(124, 144, 106)
	local roots = rgb(110, 73, 79)

	local delta = finishPos - startPos
	local totalLen = delta.Magnitude
	local dir = delta.Unit
	local segLen = totalLen * 0.34

	for idx, side in { -1, 1 } do
		local anchorPos = side == -1 and startPos or finishPos
		local inward = side == -1 and dir or -dir
		local segCenter = anchorPos + inward * (segLen * 0.5)
		local segCf = CFrame.lookAt(segCenter, segCenter + inward)

		part(bridge, "BridgeDeck", Vector3.new(12, 3.8, segLen), segCf, masonry, slate)
		part(bridge, "MossTop", Vector3.new(10.8, 1.2, segLen * 0.92), segCf * CFrame.new(0, 2.1, 0), moss, grassMat)
		for _, railSide in { -1, 1 } do
			part(bridge, "Parapet", Vector3.new(1.6, 2.8, segLen * 0.88),
				segCf * CFrame.new(railSide * 5.1, 2.8, -segLen * 0.04), masonry, slate)
		end

		-- Broken jagged tip slabs near the central chasm
		local tipCf = CFrame.lookAt(anchorPos + inward * (segLen + 3.5), anchorPos + inward * (segLen + 10))
			* CFrame.Angles(-0.18, idx * 0.25, side * 0.12)
		part(bridge, "BrokenSpanTip", Vector3.new(10.5, 3.4, 8.5), tipCf, darkStone, slate)

		-- Support piers & arch ribs underneath
		for p = 1, 2 do
			local pierFrac = p == 1 and 0.32 or 0.76
			local pierTop = anchorPos + inward * (segLen * pierFrac)
			local pierH = p == 1 and 26 or 19
			column(bridge, "BridgePier", pierTop + Vector3.new(0, -pierH * 0.5 - 1.5, 0), 5.6, pierH, darkStone, slate)
			part(bridge, "ArchRib", Vector3.new(8.5, 5.2, 14),
				CFrame.lookAt(pierTop + inward * 6 + Vector3.new(0, -5.5, 0), pierTop + inward * 14)
					* CFrame.Angles(0.42, 0, 0), masonry, slate)
		end

		-- Hanging roots under the broken bridge
		local rootStart = anchorPos + inward * (segLen * 0.82) + Vector3.new(0, -3, 0)
		local rootMid = rootStart + Vector3.new(side * 2.5, -16 - seed % 5, 2)
		span(bridge, "BridgeRoot", rootStart, rootMid, 1.8, roots, woodMat)
		span(bridge, "BridgeRootTip", rootMid, rootMid + Vector3.new(-side * 1.5, -12, -1.5), 0.95, roots, woodMat)
	end
	return bridge
end

local function skyIsles(parent)
	local stone, grass = rgb(129, 93, 108), rgb(128, 143, 111)
	local masonry, roots = rgb(203, 165, 139), rgb(110, 73, 79)
	-- Staggered island placements so forward, side, and upward views at 5,000 km read in distinct depth layers
	local islandSpecs = {
		{ km = 4180, pos = Vector3.new(-105, altitude(4180), -252), width = 56, depthRatio = 0.82, yaw = 0.35, temple = false },
		{ km = 4520, pos = Vector3.new(112, altitude(4520), -258), width = 94, depthRatio = 0.62, yaw = -0.42, temple = false },
		{ km = 4780, pos = Vector3.new(-262, altitude(4780), 28), width = 66, depthRatio = 0.74, yaw = 1.45, temple = false },
		{ km = 4960, pos = Vector3.new(-118, altitude(4960), -255), width = 134, depthRatio = 0.68, yaw = 0.52, temple = true },
		{ km = 5020, pos = Vector3.new(258, altitude(5020), -24), width = 76, depthRatio = 0.78, yaw = -1.35, temple = false },
		{ km = 5060, pos = Vector3.new(115, altitude(5060), -248), width = 98, depthRatio = 0.58, yaw = -0.38, temple = false },
		{ km = 5480, pos = Vector3.new(-88, altitude(5480), -265), width = 68, depthRatio = 0.72, yaw = 0.25, temple = false },
	}
	local islandPositions = {}
	local chimes = {}

	for i, spec in islandSpecs do
		local p = spec.pos
		islandPositions[i] = p
		local temple = spec.temple
		local island = model(parent, temple and "CloudTempleIsland" or "ForgottenSkyIsle")
		local cf = CFrame.new(p) * CFrame.Angles(0, spec.yaw, 0)
		local width, depth = spec.width, spec.width * spec.depthRatio
		local customTemple = temple and landmark(island, "Sunset", cf)
		if not customTemple then
			part(island, "BasaltShelf", Vector3.new(width, 23 + i * 2, depth), cf, stone, slate, ball)
			part(island, "OvergrownTerrace", Vector3.new(width * 0.92, 12, depth * 0.91),
				cf * CFrame.new(0, 10, 0), grass, grassMat, ball)
			for j = 1, 4 do
				local x = (j - 2.5) * width * 0.17
				part(island, "FracturedStone", Vector3.new(width * 0.35, 34 + j * 4, 27),
					cf * CFrame.new(x, -19, j % 2 * 13 - 7) * CFrame.Angles(math.pi, j * 1.2, 0.21),
					stone:Lerp(rgb(70, 61, 87), j * 0.13), slate, "Wedge")
				local start = (cf * CFrame.new(x, -7, 19)).Position
				local elbow = start + Vector3.new(4, -19 - j * 4, 3)
				span(island, "HangingRoot", start, elbow, 2.8, roots, woodMat)
				span(island, "RootTip", elbow, elbow + Vector3.new(j * 2 - 5, -18 - j * 2, 4), 1.4, roots, woodMat)
			end
			local ruin = cf * CFrame.new(-7, 10, -2)
			if temple then
				part(island, "TempleStair", Vector3.new(58, 3, 28), ruin * CFrame.new(0, 3, 13), masonry, slate)
				part(island, "TempleDais", Vector3.new(48, 4, 23), ruin * CFrame.new(0, 6, 7), masonry, slate)
				for _, z in { 5, -9 } do
					for _, side in { -1, 1 } do
						column(island, "TempleColumn", (ruin * CFrame.new(side * 18, 22, z)).Position, 8, 31, masonry, slate)
						part(island, "TempleArchShoulder", Vector3.new(22, 7, 9),
							ruin * CFrame.new(side * 11, 39, z) * CFrame.Angles(0, 0, side * -0.56), masonry, slate)
					end
					part(island, "TempleKeystone", Vector3.new(12, 8, 9), ruin * CFrame.new(0, 44, z), rgb(234, 191, 153), slate)
				end
			else
				local side = i % 2 == 0 and 1 or -1
				local height = 15 + (i % 3) * 7
				part(island, "RuinedPillar", Vector3.new(8, height, 8), ruin * CFrame.new(side * 9, height / 2, 0), masonry, slate)
				part(island, "BrokenArch", Vector3.new(13, 7, 8),
					ruin * CFrame.new(side * 5, height + 2, 0) * CFrame.Angles(0, 0, side * -0.6), masonry, slate)
			end
			part(island, "FallenMasonry", Vector3.new(12, 5, 7),
				ruin * CFrame.new(7, 3, 9) * CFrame.Angles(0.22, 1.3, 0), masonry, slate)
		else
			for j = 1, 3 do
				local start = (cf * CFrame.new(j * 20 - 42, -6, 35 - j * 2)).Position
				local elbow = start + Vector3.new(5, -18 - j * 5, 1)
				span(island, "HangingRoot", start, elbow, 2.7, roots, woodMat)
				span(island, "RootTip", elbow, elbow + Vector3.new(j * 3 - 5, -15, 2), 1.3, roots, woodMat)
			end
		end

		-- P2: Flowering blossom tree silhouette marker on key islands
		if i == 2 or i == 4 or i == 5 or i == 6 or i == 7 then
			local treeSpot = cf * CFrame.new(-width * 0.22, customTemple and 12 or 14, -depth * 0.14)
			buildBlossomTree(island, treeSpot, math.clamp(width / 68, 0.85, 1.45))
		end

		-- P2: Mid-sized ruin variant with hanging wind chimes / ornaments
		if i == 2 or i == 5 or i == 6 then
			local chimeSpot = cf * CFrame.new(width * 0.12, 12, -depth * 0.08)
			buildWindChimeRuin(island, chimeSpot, math.clamp(width / 72, 0.85, 1.25), chimes)
		end

		if i == 1 then continue end
		local waterLevel = customTemple and 9 or 13
		local lip = (cf * CFrame.new(width * 0.46, waterLevel, 4)).Position
		part(island, "SpringPool", Vector3.new(24, 2, 16), cf * CFrame.new(width * 0.34, waterLevel, 4),
			rgb(114, 200, 228), plastic, ball)
		local waterfall = rail(island, "Waterfall", lip)
		waterfall.Transparency = 1
		local drop = temple and 132 or 66 + i * 7
		for j = -1, 1 do
			local offset = Vector3.new(j * 3.8, 0, 0)
			local stream = beam(socket(waterfall, offset, Vector3.new(0.3, -1, 0.2)),
				socket(waterfall, offset + Vector3.new(9, -drop, 12), Vector3.new(0.15, -1, 0.2)),
				5.5, 13, ColorSequence.new(rgb(64, 156, 215), rgb(184, 225, 245)), softFade(0.92, 0.32), 22)
			stream.LightEmission = 0.28
		end
		for j = 1, 4 do
			local mist = part(island, "WaterfallMist", Vector3.new(18 + j * 7, 7 + j * 1.8, 20 + j * 3),
				CFrame.new(lip + Vector3.new(8 + j * 3, 5 - drop + j * 2, 11)), rgb(234, 206, 201), plastic, ball)
			mist.Transparency = 0.54 + j * 0.07
		end
	end

	-- P1: Broken stone bridge kits spanning between landmarks along the corridor sides (strictly outside corridor)
	local bridgePairs = {
		{
			start = islandPositions[4] + Vector3.new(-38, 6, 12),
			finish = Vector3.new(-235, altitude(4980), -205),
			seed = 401,
		},
		{
			start = islandPositions[6] + Vector3.new(34, 8, 10),
			finish = Vector3.new(235, altitude(5040), -198),
			seed = 402,
		},
		{
			start = islandPositions[5] + Vector3.new(0, 8, 28),
			finish = Vector3.new(252, altitude(5080), 96),
			seed = 403,
		},
	}
	for idx, pair in bridgePairs do
		buildBrokenStoneBridge(parent, pair.start, pair.finish, pair.seed)
		-- Companion anchor islet at the far end of each broken bridge
		local anchorCf = CFrame.new(pair.finish + Vector3.new(0, -10, 0)) * CFrame.Angles(0, idx * 0.9, 0)
		local anchorIsle = model(parent, "BridgeAnchorIsle")
		part(anchorIsle, "BasaltShelf", Vector3.new(44, 18, 36), anchorCf, stone, slate, ball)
		part(anchorIsle, "OvergrownTerrace", Vector3.new(40, 9, 32), anchorCf * CFrame.new(0, 7, 0), grass, grassMat, ball)
		column(anchorIsle, "GatePillar", (anchorCf * CFrame.new(-8, 18, 0)).Position, 5.5, 20, masonry, slate)
		column(anchorIsle, "GatePillar", (anchorCf * CFrame.new(8, 16, 0)).Position, 5.5, 16, masonry, slate)
		if idx == 2 then
			buildBlossomTree(anchorIsle, anchorCf * CFrame.new(4, 11, -4), 0.95)
		end
	end

	-- Polish: Reuse island & waterfall kit for smaller distant islands at varied heights & sizes
	local distantSpecs = {
		{ km = 4120, angle = -1.25, radius = 415, width = 34, waterfall = false },
		{ km = 4420, angle = -1.85, radius = 438, width = 42, waterfall = true },
		{ km = 4720, angle = -1.48, radius = 425, width = 30, waterfall = false },
		{ km = 4920, angle = -1.62, radius = 412, width = 44, waterfall = true },
		{ km = 5140, angle = -0.15, radius = 420, width = 36, waterfall = true },
		{ km = 5320, angle = -1.42, radius = 435, width = 40, waterfall = true },
		{ km = 5680, angle = -1.75, radius = 445, width = 32, waterfall = false },
		{ km = 5890, angle = -1.32, radius = 425, width = 38, waterfall = true },
	}
	for idx, spec in distantSpecs do
		local pos = Vector3.new(math.cos(spec.angle) * spec.radius, altitude(spec.km), math.sin(spec.angle) * spec.radius)
		local cf = CFrame.new(pos) * CFrame.Angles(0, spec.angle, 0)
		local distIsle = model(parent, "DistantSkyIslet")
		local w = spec.width
		local d = w * 0.78
		part(distIsle, "BasaltShelf", Vector3.new(w, 15, d), cf, stone, slate, ball)
		part(distIsle, "OvergrownTerrace", Vector3.new(w * 0.9, 8, d * 0.88), cf * CFrame.new(0, 6, 0), grass, grassMat, ball)
		part(distIsle, "KeelWedge", Vector3.new(w * 0.42, 22, d * 0.42),
			cf * CFrame.new(0, -13, 0) * CFrame.Angles(math.pi, idx * 0.7, 0.15), stone, slate, "Wedge")
		column(distIsle, "DistantRuinPillar", (cf * CFrame.new(0, 14, 0)).Position, 4.5, 14, masonry, slate)
		if spec.waterfall then
			local lip = (cf * CFrame.new(w * 0.4, 7, 0)).Position
			local wf = rail(distIsle, "DistantWaterfall", lip)
			wf.Transparency = 1
			beam(
				socket(wf, Vector3.zero, Vector3.new(0.2, -1, 0.1)),
				socket(wf, Vector3.new(5, -48, 6), Vector3.new(0.1, -1, 0.1)),
				3.5, 8.5,
				ColorSequence.new(rgb(84, 172, 225), rgb(198, 232, 248)),
				softFade(0.92, 0.35),
				12
			)
		end
	end

	return function(_, time)
		for _, chime in chimes do
			local swayX = math.sin(time * 1.15 + chime.phase) * 0.08
			local swayZ = math.cos(time * 0.92 + chime.phase) * 0.06
			chime.model:PivotTo(chime.origin * CFrame.Angles(swayX, 0, swayZ))
		end
	end
end

local function buildCosmicCrystalIsland(parent, cf, scale, satellites, seed)
	local island = model(parent, "CosmicCrystalIsland")
	local random = Random.new(seed)
	local astralRock = rgb(58, 56, 98)
	local deepSlate = rgb(38, 36, 68)
	local bioMoss = rgb(72, 168, 178)
	local crystalColors = {
		rgb(218, 92, 255),
		rgb(96, 228, 255),
		rgb(162, 118, 255),
		rgb(255, 132, 224),
	}

	-- Stone shelf base & craggy underside
	part(island, "AstralStoneBase", Vector3.new(92, 24, 72) * scale, cf, astralRock, slate, ball)
	part(island, "BioluminescentTerrace", Vector3.new(84, 10, 64) * scale,
		cf * CFrame.new(0, 9 * scale, 0), bioMoss, slate, ball)
	for i = 1, 5 do
		local a = (i - 1) * math.pi * 2 / 5 + 0.3
		part(island, "AstralUnderCrag", Vector3.new(32, 38 + i * 4, 28) * scale,
			cf * CFrame.new(math.cos(a) * 24 * scale, -18 * scale, math.sin(a) * 18 * scale)
				* CFrame.Angles(math.pi, a, 0.2), deepSlate, slate, "Wedge")
	end

	-- Core landmark mesh if available
	landmark(island, "Cosmic", cf * CFrame.new(0, 14 * scale, 0), scale)

	-- Readable faceted crystal spires around the island crown
	local spireSpecs = {
		{ pos = Vector3.new(-16, 26, -6), size = Vector3.new(11, 42, 11), rot = Vector3.new(0.18, 0.4, 0.22), col = 1 },
		{ pos = Vector3.new(14, 28, -4), size = Vector3.new(12, 46, 12), rot = Vector3.new(-0.15, 1.1, -0.24), col = 2 },
		{ pos = Vector3.new(0, 32, 8), size = Vector3.new(13, 52, 13), rot = Vector3.new(0.08, 2.1, -0.08), col = 3 },
		{ pos = Vector3.new(-26, 20, 8), size = Vector3.new(8.5, 30, 8.5), rot = Vector3.new(0.28, -0.6, 0.32), col = 4 },
		{ pos = Vector3.new(25, 19, 10), size = Vector3.new(9, 32, 9), rot = Vector3.new(-0.22, 0.8, -0.28), col = 1 },
	}
	for _, s in spireSpecs do
		local cColor = crystalColors[s.col]
		local spireCf = cf * CFrame.new(s.pos * scale) * CFrame.Angles(s.rot.X, s.rot.Y, s.rot.Z)
		part(island, "FacetedCrystal", s.size * scale, spireCf, cColor, glassMat, "Wedge")
		local core = part(island, "CrystalGlowCore", s.size * Vector3.new(0.55, 0.82, 0.55) * scale,
			spireCf, cColor, neon, "Wedge")
		core.Transparency = 0.25
	end

	-- Slow-orbiting mini crystal satellites around the island
	for i = 1, 4 do
		local a = (i - 1) * math.pi / 2 + random:NextNumber(-0.2, 0.2)
		local satDist = (56 + i * 7) * scale
		local satOrigin = cf * CFrame.new(math.cos(a) * satDist, (6 + (i % 2) * 12) * scale, math.sin(a) * satDist)
		local sat = model(island, "CrystalSatellite")
		part(sat, "SatRock", Vector3.new(12, 7, 10) * scale, satOrigin, astralRock, slate, ball)
		part(sat, "SatKeel", Vector3.new(7, 11, 7) * scale,
			satOrigin * CFrame.new(0, -5 * scale, 0) * CFrame.Angles(math.pi, i, 0.15), deepSlate, slate, "Wedge")
		part(sat, "SatCrystal", Vector3.new(4.5, 13, 4.5) * scale,
			satOrigin * CFrame.new(0, 6 * scale, 0) * CFrame.Angles(0.15, i * 0.7, -0.18),
			crystalColors[(i % #crystalColors) + 1], neon, "Wedge")
		sat.WorldPivot = satOrigin
		table.insert(satellites, { model = sat, origin = satOrigin, phase = seed + i * 1.3 })
	end

	return island
end

local function buildFloatingObservatory(parent, cf, scale, armillaryRings)
	local obs = model(parent, "FloatingObservatory")
	local astralStone = rgb(64, 62, 106)
	local marble = rgb(232, 224, 214)
	local gold = rgb(244, 192, 82)
	local royalBanner = rgb(44, 88, 186)
	local cyanGlow = rgb(104, 236, 255)

	-- Floating stone base & ruined steps
	part(obs, "ObservatoryIslandBase", Vector3.new(108, 26, 86) * scale, cf, astralStone, slate, ball)
	part(obs, "AstralTurf", Vector3.new(98, 10, 78) * scale, cf * CFrame.new(0, 10 * scale, 0), rgb(78, 136, 148), grassMat, ball)
	for i = 1, 5 do
		local a = (i - 1) * math.pi * 2 / 5 + 0.2
		part(obs, "ObservatoryUnderCrag", Vector3.new(36, 42 + i * 4, 30) * scale,
			cf * CFrame.new(math.cos(a) * 28 * scale, -20 * scale, math.sin(a) * 22 * scale)
				* CFrame.Angles(math.pi, a, 0.18), rgb(44, 42, 76), slate, "Wedge")
	end

	-- Stepped marble ruin dais & colonnade
	part(obs, "DaisLower", Vector3.new(68, 5, 56) * scale, cf * CFrame.new(0, 15 * scale, 0), marble, marbleMat)
	part(obs, "DaisUpper", Vector3.new(54, 5, 44) * scale, cf * CFrame.new(0, 19.5 * scale, 0), marble, marbleMat)
	part(obs, "GrandStair", Vector3.new(22, 8, 24) * scale,
		cf * CFrame.new(-18 * scale, 13 * scale, 28 * scale) * CFrame.Angles(0.32, 0, 0), marble, marbleMat)

	for idx, colPos in {
		Vector3.new(-22, 34, -16),
		Vector3.new(22, 36, -16),
		Vector3.new(26, 32, 6),
		Vector3.new(-25, 29, 10),
	} do
		local h = (idx <= 2 and 26 or 18) * scale
		column(obs, "RuinedColumn", (cf * CFrame.new(colPos * scale)).Position, 5.8 * scale, h, marble, marbleMat)
	end
	part(obs, "BrokenArchitrave", Vector3.new(32, 5.5, 7.5) * scale,
		cf * CFrame.new(12 * scale, 49 * scale, -16 * scale) * CFrame.Angles(0, 0, -0.12), marble, marbleMat)

	-- Royal astral banners hanging on the front cliff
	for _, xSide in { -1, 1 } do
		local bannerCf = cf * CFrame.new(xSide * 24 * scale, 6 * scale, 36 * scale)
		part(obs, "BannerTrim", Vector3.new(7.5, 18, 1.2) * scale, bannerCf, gold, metalMat)
		part(obs, "AstralBanner", Vector3.new(6.2, 16.5, 1.5) * scale, bannerCf, royalBanner, plastic)
		part(obs, "BannerStar", Vector3.one * (2.6 * scale), bannerCf * CFrame.new(0, 1 * scale, 0.8 * scale), gold, neon, ball)
	end

	-- Central pedestal & rotating multi-ring Golden Armillary Sphere
	local sphereCenterCf = cf * CFrame.new(-2 * scale, 48 * scale, -2 * scale)
	column(obs, "ArmillaryPedestal", (cf * CFrame.new(-2 * scale, 27 * scale, -2 * scale)).Position, 11 * scale, 12 * scale, marble, marbleMat)
	part(obs, "PedestalGoldCollar", Vector3.new(14, 3.5, 14) * scale, cf * CFrame.new(-2 * scale, 33 * scale, -2 * scale), gold, metalMat, ball)
	part(obs, "AstralCoreStar", Vector3.one * (8.5 * scale), sphereCenterCf, cyanGlow, neon, ball)

	local ringRadii = { 23 * scale, 18.5 * scale, 14 * scale }
	local ringSpeeds = {
		Vector3.new(0.28, 0.42, 0.12),
		Vector3.new(-0.36, 0.22, 0.38),
		Vector3.new(0.18, -0.48, -0.26),
	}
	for rIdx, radius in ringRadii do
		local ringModel = model(obs, "ArmillaryRing_" .. rIdx)
		local ringOrigin = sphereCenterCf * CFrame.Angles(0.38 * rIdx, 0.52 * rIdx, 0.24 * rIdx)
		local segments = 12
		local segLen = 2 * radius * math.sin(math.pi / segments) * 1.08
		for s = 1, segments do
			local a = (s - 1) * math.pi * 2 / segments
			local p = Vector3.new(math.cos(a) * radius, math.sin(a) * radius, 0)
			local segCf = ringOrigin * CFrame.new(p) * CFrame.Angles(0, 0, a)
			part(ringModel, "RingArc", Vector3.new(1.8 * scale, segLen, 2.2 * scale), segCf, gold, metalMat)
		end
		ringModel.WorldPivot = ringOrigin
		table.insert(armillaryRings, { model = ringModel, origin = ringOrigin, speed = ringSpeeds[rIdx] })
	end

	return obs
end

local function buildDistantCosmicArch(parent, cf, scale)
	local arch = model(parent, "DistantCosmicArch")
	local stone = rgb(66, 62, 112)
	local runeGlow = rgb(112, 232, 255)
	local violetGlow = rgb(206, 112, 255)

	part(arch, "ArchBase", Vector3.new(44, 12, 28) * scale, cf, stone, slate, ball)
	for _, side in { -1, 1 } do
		column(arch, "ArchPillar", (cf * CFrame.new(side * 13 * scale, 16 * scale, 0)).Position, 5.5 * scale, 24 * scale, stone, slate)
		part(arch, "ArchShoulder", Vector3.new(15, 5.2, 6.2) * scale,
			cf * CFrame.new(side * 7.5 * scale, 29 * scale, 0) * CFrame.Angles(0, 0, side * -0.52), stone, slate)
		part(arch, "RuneNode", Vector3.one * (3.2 * scale),
			cf * CFrame.new(side * 13 * scale, 18 * scale, 3 * scale), runeGlow, neon, ball)
	end
	part(arch, "ArchCrown", Vector3.new(11, 5.5, 6.8) * scale, cf * CFrame.new(0, 32.5 * scale, 0), stone, slate)
	part(arch, "CrownCrystal", Vector3.new(3.8, 8.5, 3.8) * scale,
		cf * CFrame.new(0, 36.5 * scale, 0) * CFrame.Angles(0, 0.6, 0), violetGlow, neon, "Wedge")
	return arch
end

local function exosphere(parent)
	local random = Random.new(607)
	local satellites = {}
	local armillaryRings = {}

	-- Polish: Rework Cosmic crystal templates into primary crystal islands with stone bases, faceted crystals, and slow satellites
	buildCosmicCrystalIsland(parent, CFrame.new(-115, altitude(6960), -248) * CFrame.Angles(0, 0.38, 0), 1.04, satellites, 610)
	buildCosmicCrystalIsland(parent, CFrame.new(258, altitude(6980), -22) * CFrame.Angles(0, -1.25, 0), 0.85, satellites, 620)
	buildCosmicCrystalIsland(parent, CFrame.new(-88, altitude(7480), -262) * CFrame.Angles(0, 0.45, 0), 0.84, satellites, 630)

	-- P1: Floating Astral Observatory with rotating armillary sphere rings and ruined stone base
	buildFloatingObservatory(parent, CFrame.new(118, altitude(7040), -242) * CFrame.Angles(0, -0.42, 0), 1.02, armillaryRings)

	-- P2: Small glowing stone arches in the distance as a third depth layer
	local archSpecs = {
		{ km = 6280, angle = -1.35, radius = 425, scale = 0.92 },
		{ km = 6680, angle = -1.78, radius = 445, scale = 1.02 },
		{ km = 6940, angle = -1.55, radius = 415, scale = 0.96 },
		{ km = 7060, angle = -0.12, radius = 395, scale = 0.95 },
		{ km = 7420, angle = -1.38, radius = 428, scale = 1.0 },
		{ km = 7820, angle = -1.68, radius = 435, scale = 0.88 },
	}
	for _, spec in archSpecs do
		local pos = Vector3.new(math.cos(spec.angle) * spec.radius, altitude(spec.km), math.sin(spec.angle) * spec.radius)
		local cf = CFrame.new(pos) * CFrame.Angles(0, spec.angle + math.pi / 2, 0)
		buildDistantCosmicArch(parent, cf, spec.scale)
	end

	-- Sweeping arc of small glowing cosmic pebbles/satellites in the background (slow gentle float)
	for i = 1, 9 do
		local t = (i - 1) / 8
		local arcPos = Vector3.new(-155 + t * 285, altitude(6720 + t * 560) + math.sin(t * math.pi) * 28, -315 - math.sin(t * math.pi) * 45)
		local cf = CFrame.new(arcPos) * CFrame.Angles(0, i * 0.5, 0)
		local pebble = model(parent, "CosmicArcStone")
		local sc = 0.55 + (1 - math.abs(t - 0.5)) * 0.45
		part(pebble, "Stone", Vector3.new(11, 6, 9) * sc, cf, rgb(64, 62, 108), slate, ball)
		part(pebble, "GlowRing", Vector3.new(13, 1.8, 11) * sc, cf, i % 2 == 0 and rgb(92, 232, 255) or rgb(216, 112, 255), neon, ball)
		pebble.WorldPivot = cf
		table.insert(satellites, { model = pebble, origin = cf, phase = 700 + i * 0.8 })
	end

	local ribbons = {
		{ color = ColorSequence.new(rgb(61, 255, 174), rgb(133, 254, 233)), z = -335, km = 6960 },
		{ color = ColorSequence.new(rgb(217, 83, 255), rgb(250, 146, 207)), z = -440, km = 7370 },
	}
	local nodes, dust = {}, {}
	for index, ribbon in ribbons do
		local y = altitude(ribbon.km)
		local left = Vector3.new(-390, y + 66, ribbon.z)
		local right = Vector3.new(390, y + 108, ribbon.z - 34)
		local from = rail(parent, "AuroraStart", left)
		local to = rail(parent, "AuroraEnd", right)
		from.Transparency, to.Transparency = 1, 1
		table.insert(nodes, { part = from, origin = left })
		table.insert(nodes, { part = to, origin = right })

		local start = socket(from, Vector3.zero, Vector3.new(1, -0.83, -0.15))
		local finish = socket(to, Vector3.zero, Vector3.new(1, index == 1 and 0.75 or 0.39, 0.19))
		-- One continuous curve per layer keeps the ribbons joined from every camera angle.
		for layer = 1, 5 do
			local width = 87 - (layer - 1) * 17
			local glow = beam(start, finish, width, width * 0.83, ribbon.color, softFade(1, 0.87 - layer * 0.045), 275)
			glow.Segments = 40
		end
	end

	local starColors = { rgb(235, 242, 255), rgb(139, 185, 245), rgb(227, 171, 246) }
	for i = 1, 68 do
		local angle = random:NextNumber(0, math.pi * 2)
		local radius = random:NextNumber(410, 680)
		local origin = Vector3.new(math.cos(angle) * radius, altitude(random:NextNumber(5700, 8400)), math.sin(angle) * radius)
		local size = random:NextNumber(1.4, i % 7 == 0 and 4.2 or 2.5)
		local point = part(parent, i <= 14 and "DriftingStardust" or "DistantStar", Vector3.one * size,
			CFrame.new(origin), starColors[i % #starColors + 1], neon, ball)
		point.Transparency = i <= 14 and 0.22 or 0.06
		if i <= 14 then dust[i] = { part = point, origin = origin } end
	end

	return function(_, time)
		for i, node in nodes do
			node.part.Position = node.origin + Vector3.new(0, math.sin(time * 0.24 + i * 0.7) * 12, math.cos(time * 0.18 + i) * 9)
		end
		for i, mote in dust do
			mote.part.Position = mote.origin + Vector3.new(math.sin(time * 0.14 + i) * 22, math.cos(time * 0.17 + i) * 9, 0)
		end
		for _, sat in satellites do
			local bob = math.sin(time * 0.32 + sat.phase) * 3.8
			local drift = math.cos(time * 0.22 + sat.phase) * 2.5
			sat.model:PivotTo(sat.origin * CFrame.new(drift, bob, 0) * CFrame.Angles(0, time * 0.09, 0))
		end
		for _, ring in armillaryRings do
			local s = ring.speed
			ring.model:PivotTo(ring.origin * CFrame.Angles(time * s.X, time * s.Y, time * s.Z))
		end
	end
end

local function buildFloatingCrystalGate(parent, cf, scale, gateCrystals)
	local gate = model(parent, "FloatingCrystalGate")
	local ivory = rgb(248, 238, 218)
	local gold = rgb(238, 188, 84)
	local stone = rgb(164, 152, 146)
	local grass = rgb(104, 162, 108)
	local cyanCrystal = rgb(88, 234, 255)
	local deepCyan = rgb(42, 178, 226)

	-- Floating sanctuary island base with greenery and waterfall (distinct from ReturnPortal)
	part(gate, "SanctuaryStone", Vector3.new(78, 22, 62) * scale, cf, stone, slate, ball)
	part(gate, "SanctuaryLawn", Vector3.new(72, 9, 56) * scale, cf * CFrame.new(0, 8.5 * scale, 0), grass, grassMat, ball)
	part(gate, "MarblePlinth", Vector3.new(56, 5, 38) * scale, cf * CFrame.new(0, 13 * scale, 0), ivory, marbleMat)
	for i = 1, 4 do
		local a = (i - 1) * math.pi / 2 + 0.4
		part(gate, "UnderSpire", Vector3.new(26, 36 + i * 4, 24) * scale,
			cf * CFrame.new(math.cos(a) * 18 * scale, -18 * scale, math.sin(a) * 14 * scale)
				* CFrame.Angles(math.pi, a, 0.16), stone, slate, "Wedge")
	end

	-- Ornate twin-column golden & ivory archway
	for _, side in { -1, 1 } do
		column(gate, "OuterColumn", (cf * CFrame.new(side * 19 * scale, 29 * scale, 0)).Position, 5.2 * scale, 28 * scale, ivory, marbleMat)
		column(gate, "InnerColumn", (cf * CFrame.new(side * 13 * scale, 27 * scale, 0)).Position, 3.8 * scale, 24 * scale, gold, metalMat)
		part(gate, "PillarCapital", Vector3.new(14, 4, 10) * scale, cf * CFrame.new(side * 16 * scale, 43 * scale, 0), gold, metalMat)
		part(gate, "ArchVault", Vector3.new(19, 6.5, 8.5) * scale,
			cf * CFrame.new(side * 10 * scale, 51 * scale, 0) * CFrame.Angles(0, 0, side * -0.55), ivory, marbleMat)
		part(gate, "ArchGoldTrim", Vector3.new(18, 3.2, 9.2) * scale,
			cf * CFrame.new(side * 9.5 * scale, 53.5 * scale, 0) * CFrame.Angles(0, 0, side * -0.55), gold, metalMat)
	end
	part(gate, "ArchKeystone", Vector3.new(12, 7.5, 9.5) * scale, cf * CFrame.new(0, 56.5 * scale, 0), gold, metalMat)
	column(gate, "KeystoneFinial", (cf * CFrame.new(0, 63 * scale, 0)).Position, 2.2 * scale, 8 * scale, gold, metalMat)

	-- Hovering diamond crystal suspended inside the arch (rotating & bobbing)
	local crystalOrigin = cf * CFrame.new(0, 34 * scale, 0)
	local diamond = model(gate, "SuspendedDiamondCrystal")
	part(diamond, "UpperPyramid", Vector3.new(9.5, 13, 9.5) * scale,
		crystalOrigin * CFrame.new(0, 6.5 * scale, 0) * CFrame.Angles(0, math.pi / 4, 0), cyanCrystal, neon, "Wedge")
	part(diamond, "LowerPyramid", Vector3.new(9.5, 13, 9.5) * scale,
		crystalOrigin * CFrame.new(0, -6.5 * scale, 0) * CFrame.Angles(math.pi, math.pi / 4, 0), deepCyan, neon, "Wedge")
	part(diamond, "CrystalHaloRing", Vector3.new(18, 1.6, 18) * scale, crystalOrigin, gold, neon, ball)
	diamond.WorldPivot = crystalOrigin
	table.insert(gateCrystals, { model = diamond, origin = crystalOrigin })

	-- Small cascading waterfall off the sanctuary lip
	local lip = (cf * CFrame.new(0, 9 * scale, 26 * scale)).Position
	local wf = rail(gate, "GateWaterfall", lip)
	wf.Transparency = 1
	beam(
		socket(wf, Vector3.zero, Vector3.new(0, -1, 0.25)),
		socket(wf, Vector3.new(0, -52 * scale, 10 * scale), Vector3.new(0, -1, 0.15)),
		5.2 * scale, 11 * scale,
		ColorSequence.new(rgb(112, 218, 255), rgb(228, 248, 255)),
		softFade(0.88, 0.25),
		10 * scale
	)
	return gate
end

local function palaceApproach(parent, palace)
	local island = palace:FindFirstChild("CloudIsland")
	if not island then return end

	local base = island.Position
	local cloudBed = model(parent, "PalaceCloudBed")
	local ivory, honey = rgb(255, 243, 214), rgb(224, 192, 147)
	local random = Random.new(9012)
	for i = 1, 15 do
		local angle = (i - 1) * math.pi * 2 / 15 + random:NextNumber(-0.14, 0.14)
		local radius = random:NextNumber(69, 88)
		local height = random:NextNumber(22, 29)
		local cloudTop = island.Size.Y * 0.5 + random:NextNumber(-1.9, 0.65)
		local center = base + Vector3.new(math.cos(angle) * radius, cloudTop - height * 0.5, math.sin(angle) * radius)
		part(cloudBed, "CloudScallop", Vector3.new(random:NextNumber(44, 66), height, random:NextNumber(40, 58)),
			CFrame.new(center) * CFrame.Angles(0, angle + 0.7, 0), ivory:Lerp(honey, random:NextNumber(0, 0.48)), plastic, ball)
	end
	for i, offset in { Vector3.new(-29, -33, 13), Vector3.new(16, -32, -19), Vector3.new(26, -37, 24) } do
		part(cloudBed, "CloudUnderside", Vector3.new(112 - i * 11, 24, 85), CFrame.new(base + offset),
			ivory:Lerp(honey, i * 0.18), plastic, ball)
	end

	local landmarks = model(parent, "PalaceLandmarks")
	local marble, gold = rgb(249, 237, 218), rgb(229, 181, 83)
	local top = island.Size.Y * 0.5
	for _, side in { -1, 1 } do
		local plinth = base + Vector3.new(side * (island.Size.X * 0.42), top + 2, -22)
		column(landmarks, "BelvedereBase", plinth, 17, 4, gold, marbleMat)
		column(landmarks, "BelvedereTower", plinth + Vector3.new(0, 15, 0), 12, 28, marble, marbleMat)
		column(landmarks, "BelvedereCornice", plinth + Vector3.new(0, 29, 0), 16, 3, gold)
		part(landmarks, "BelvedereDome", Vector3.new(15, 13, 15),
			CFrame.new(plinth + Vector3.new(0, 34, 0)), gold, plastic, ball)
		column(landmarks, "BelvedereFinial", plinth + Vector3.new(0, 42, 0), 2, 9, gold)
	end

	local dome = palace:FindFirstChild("GoldenDome")
	if dome then
		local crest = dome.Position + Vector3.new(0, dome.Size.Y * 0.5, 0)
		column(landmarks, "PalaceCrest", crest + Vector3.new(0, 5, 0), 3, 13, gold)
		part(landmarks, "PalaceCrestTip", Vector3.one * 3.5, CFrame.new(crest + Vector3.new(0, 12, 0)), marble, plastic, ball)
	end
end

local function palaceHorizon(parent, anchor)
	local horizon = model(parent, "PalaceHorizon")
	local layouts = {
		-- Polish: Multi-layered ascent pavilions, arches & spires distributed from 8,150 km to 9,600 km
		{ "HorizonPavilion", Vector3.new(-165, -510, -255), 0.52, -16 },
		{ "HorizonArch", Vector3.new(-195, -455, -295), 0.66, -12 },
		{ "HorizonSpire", Vector3.new(185, -420, -265), 0.58, 22 },
		{ "HorizonPavilion", Vector3.new(265, -345, -35), 0.54, 28 },
		{ "HorizonPavilion", Vector3.new(-145, -325, -265), 0.62, -14 },
		{ "HorizonSpire", Vector3.new(-285, -295, -45), 0.64, -24 },
		{ "HorizonArch", Vector3.new(215, -245, -310), 0.72, 18 },
		{ "HorizonPavilion", Vector3.new(-175, -185, -295), 0.48, -8 },
		-- Upper summit horizon ring around the Cloud Palace
		{ "HorizonPavilion", Vector3.new(-275, 1, -438), 0.72, -18 },
		{ "HorizonSpire", Vector3.new(323, -12, -558), 0.78, 25 },
		{ "HorizonCloud", Vector3.new(335, -22, 456), 0.83, -18 },
		{ "HorizonArch", Vector3.new(-765, 67, -965), 1.22, -14 },
		{ "HorizonSpire", Vector3.new(810, 58, -1050), 1.28, 18 },
		{ "HorizonSpire", Vector3.new(-1090, 150, 805), 1.16, -25 },
		{ "HorizonPavilion", Vector3.new(1230, 165, 690), 1.21, 27 },
		{ "HorizonPavilion", Vector3.new(-520, -22, 1280), 1.34, 24 },
		{ "HorizonArch", Vector3.new(695, 14, 1370), 1.17, -21 },
		{ "HorizonCloud", Vector3.new(-190, -69, -1740), 1.52, 8 },
		{ "HorizonCloud", Vector3.new(1475, -58, -965), 1.37, -20 },
		{ "HorizonCloud", Vector3.new(-1530, -59, 865), 1.32, 10 },
		{ "HorizonCloud", Vector3.new(120, -92, 1890), 1.45, -16 },
	}
	for _, layout in layouts do
		local name, offset, scale, turn = table.unpack(layout)
		local position = anchor:PointToWorldSpace(offset)
		local target = Vector3.new(anchor.Position.X, position.Y, anchor.Position.Z)
		local facing = CFrame.lookAt(position, target) * CFrame.Angles(0, math.pi + math.rad(turn), 0)
		local vista = landmark(horizon, name, facing, scale)
		if vista then
			local haze = math.clamp((offset.Magnitude - 320) / 1800, 0.06, 0.46)
			for _, piece in vista:GetChildren() do
				if piece:IsA("BasePart") then piece.Color = piece.Color:Lerp(rgb(198, 211, 229), haze) end
			end
		end
	end
end

local function palaceUpperSky(parent, anchor)
	local sky = model(parent, "PalaceUpperSky")
	local clouds = {
		{ Vector3.new(-600, 510, -810), 1.12, -18, 9 },
		{ Vector3.new(355, 331.5, -460), 0.72, 14, 7 },
		{ Vector3.new(-370, 380, 1060), 1.14, -24, 9 },
	}
	for _, cloud in clouds do
		local offset, scale, yaw, tilt = table.unpack(cloud)
		local facing = anchor * CFrame.new(offset) * CFrame.Angles(0, math.rad(yaw), math.rad(tilt))
		landmark(sky, "UpperSkyCloud", facing, scale)
	end
	local overhead = model(sky, "OverheadClouds")
	local ceiling = {
		{ "ZenithCloud", Vector3.new(-15, 345, 104), 0.85, -20 },
		{ "ZenithCloud", Vector3.new(221, 490, -116), 0.69, 76 },
		{ "ZenithCloud", Vector3.new(-294, 570, 244), 0.72, 39 },
		{ "UpperSkyCloud", Vector3.new(-155, 411, -333), 0.72, -31 },
		{ "UpperSkyCloud", Vector3.new(185, 159, -196), 0.63, -13 },
		{ "UpperSkyCloud", Vector3.new(-178, 141, -228), 0.54, 18 },
	}
	local driftingClouds = {}
	for _, layout in ceiling do
		local name, offset, scale, yaw = table.unpack(layout)
		local placement = anchor * CFrame.new(offset) * CFrame.Angles(0, math.rad(yaw), 0)
		local cloud = landmark(overhead, name, placement, scale)
		if cloud then table.insert(driftingClouds, { cloud = cloud, placement = placement }) end
		if name == "ZenithCloud" then
			local mistPlacement = placement * CFrame.new(19, -13, 52 * scale) * CFrame.Angles(0, 0.18, 0)
			local mist = landmark(overhead, "UpperSkyCloud", mistPlacement, scale * 0.53)
			if mist then
				mist.Name = "CloudEdgeMist"
				for _, piece in mist:GetChildren() do
					piece.Transparency = 0.83
					piece.Color = piece.Color:Lerp(rgb(242, 239, 238), 0.65)
				end
				table.insert(driftingClouds, { cloud = mist, placement = mistPlacement })
			end
		end
	end

	local lightTop = Vector3.new(300, 311.5, -445)
	local lightDirection = Vector3.new(-124, -111, -185)
	local shaft = rail(sky, "UpperSunshafts", anchor:PointToWorldSpace(lightTop))
	shaft.CFrame = anchor * CFrame.new(lightTop)
	shaft.Transparency = 1
	for _, rayStyle in {
		{ Vector3.new(-54, -3, -6), Vector3.new(-23, -5, 8), 19, 48, 0.69 },
		{ Vector3.new(4, 2, -3), Vector3.zero, 25, 60, 0.58 },
		{ Vector3.new(68, 12, -14), Vector3.new(29, 14, -20), 13, 46, 0.73 },
	} do
		local offset, spread, narrow, wide, centerAlpha = table.unpack(rayStyle)
		local start = socket(shaft, offset)
		local finish = socket(shaft, offset + lightDirection + spread)
		local fade = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.87),
			NumberSequenceKeypoint.new(0.25, centerAlpha),
			NumberSequenceKeypoint.new(0.62, centerAlpha + 0.13),
			NumberSequenceKeypoint.new(1, 1),
		})
		local ray = beam(start, finish, narrow, wide, ColorSequence.new(rgb(255, 232, 190)), fade)
		ray.Name = "CloudSunshaft"
		ray.LightEmission = 0.18
	end

	-- Polish: Adjust ship distances & routes so multiple ship layers are readable during the 8,000–10,000 km climb as well as at the summit
	local routes = {
		-- Mid-ascent patrol ships (8,400 km – 9,350 km, visible around 9,000 km forward & side)
		{ "CloudSailer", Vector3.new(-85, -335, -225), Vector3.new(42, 6, 30), 84, 0.35, 1.08 },
		{ "CloudKetch", Vector3.new(242, -315, -25), Vector3.new(36, 7, 44), 96, 2.1, 0.98 },
		{ "CloudCutter", Vector3.new(95, -210, -255), Vector3.new(48, 8, 36), 108, 4.2, 0.94 },
		-- Summit patrol ships around the Cloud Palace
		{ "CloudSailer", Vector3.new(57, 79, -131), Vector3.new(138, 6, 43), 88, 0.12, 1.04 },
		{ "CloudKetch", Vector3.new(425, 278, -715), Vector3.new(160, 13, 70), 133, 2.9, 0.92 },
		{ "CloudCutter", Vector3.new(170, 460, 630), Vector3.new(122, 13, 69), 151, 5.2, 0.90 },
	}
	local fleet = {}
	for _, route in routes do
		local name, center, excursion, period, phase, scale = table.unpack(route)
		local ship = landmark(sky, name, anchor * CFrame.new(center), scale)
		if ship then
			local sail = ship:FindFirstChild("SkySail")
			table.insert(fleet, {
				ship = ship, center = center, excursion = excursion, period = period, phase = phase,
				sail = sail, sailColor = sail and sail.Color,
			})
		end
	end

	local epoch, lastVisibility
	return function(km, time)
		local visibility = math.clamp((km - 7920) / 380, 0, 1)
		if visibility > 0 and not epoch then epoch = time end
		local elapsed = epoch and time - epoch or 0
		for index, layer in driftingClouds do
			local shift = Vector3.new(math.sin(elapsed * 0.018 + index) * 14, 0, math.sin(elapsed * 0.013 + index) * 9)
			layer.cloud:PivotTo(layer.placement + shift)
		end
		for _, flight in fleet do
			if lastVisibility ~= visibility then
				for _, piece in flight.ship:GetChildren() do piece.Transparency = 1 - visibility end
			end
			if visibility > 0 then
				local angle = elapsed * (2 * math.pi / flight.period) + flight.phase
				local drift = flight.excursion * Vector3.new(math.sin(angle), math.sin(angle * 2), math.cos(angle))
				local position = flight.center + drift
				local dx = flight.excursion.X * math.cos(angle)
				local dz = -flight.excursion.Z * math.sin(angle)
				local yaw = math.atan2(-dz, dx)
				local roll = math.sin(angle * 2) * 0.035
				flight.ship:PivotTo(anchor * CFrame.new(position) * CFrame.Angles(0, yaw, 0) * CFrame.Angles(roll, 0, 0))
				if flight.sail then
					local toShip = position - lightTop
					local progress = math.clamp(toShip:Dot(lightDirection) / lightDirection:Dot(lightDirection), 0, 1)
					local distance = (toShip - lightDirection * progress).Magnitude
					local light = math.clamp(1 - distance / 155, 0, 1)
					flight.sail.Color = flight.sailColor:Lerp(rgb(255, 254, 240), light * 0.75)
				end
			end
		end
		lastVisibility = visibility
	end
end

local function gateway(parent)
	local vista = landmark(parent, "PalaceVista")
	local animateSky
	if vista then
		local anchor = vista:GetPivot()
		palaceHorizon(parent, anchor)
		animateSky = palaceUpperSky(parent, anchor)
	end

	-- P2: Floating crystal gate landmark in the distance, distinct in shape & color from ReturnPortal
	local gateCrystals = {}
	buildFloatingCrystalGate(parent, CFrame.new(112, altitude(8980), -238) * CFrame.Angles(0, -0.35, 0), 1.04, gateCrystals)

	local clouds = { rgb(252, 232, 179), rgb(255, 244, 210), rgb(246, 221, 162) }
	for i = 1, 12 do
		local tier = math.floor((i - 1) / 4)
		local angle = (i - 1) * math.pi / 2 + 0.48 + tier * 0.32
		local radius = 335 + tier * 52
		local center = Vector3.new(math.cos(angle) * radius, altitude(8120 + tier * 680 + i % 4 * 85), math.sin(angle) * radius)
		local cloud = landmark(parent, "PalaceCloud", CFrame.new(center) * CFrame.Angles(0, angle, 0), 0.73 + tier * 0.15)
		if not cloud then band(parent, "GoldenCloudTerrace", center, Vector3.new(208, 58 + tier * 10, 145), clouds, i * 21) end
		if i % 2 == 0 then
			local source = rail(parent, "Sunshaft", center + Vector3.new(0, 52, 0))
			source.Transparency = 1
			for j = 1, 2 do
				local offset = Vector3.new(j * 21, 0, j * -11)
				beam(socket(source, offset), socket(source, offset + Vector3.new(-69, -205, 36)),
					14, 63, ColorSequence.new(rgb(255, 239, 174)), softFade(1, 0.73))
			end
		end
	end

	-- The far silhouette is an atmospheric preview. Victory still uses the real palace.
	local silhouette = model(parent, "PalaceSilhouette")
	local at = CFrame.new(0, altitude(9450), -398)
	local shadow, gold = rgb(129, 104, 134), rgb(187, 151, 130)
	if landmark(silhouette, "Palace", at, 0.75) then
		if not landmark(silhouette, "PalaceFoundation", at, 0.75) then
			landmark(silhouette, "PalaceCloud", at, 0.75)
		end
		landmark(silhouette, "PalaceApproach", at, 0.75)
	else
		part(silhouette, "CloudPlinth", Vector3.new(124, 20, 49), at, shadow, plastic, ball)
		part(silhouette, "Keep", Vector3.new(48, 33, 28), at * CFrame.new(0, 17, 0), shadow)
		part(silhouette, "Dome", Vector3.new(49, 28, 41), at * CFrame.new(0, 36, 0), gold, plastic, ball)
		for _, x in { -36, 36 } do
			column(silhouette, "Tower", (at * CFrame.new(x, 22, 0)).Position, 16, 42, shadow)
			part(silhouette, "Spire", Vector3.new(17, 23, 17),
				at * CFrame.new(x, 48, 0) * CFrame.Angles(0, math.pi / 4, 0), gold, plastic, "Wedge")
		end
	end
	local silhouetteParts = {}
	for _, piece in silhouette:GetDescendants() do
		if piece:IsA("BasePart") then
			if piece:IsA("MeshPart") then
				local accent = piece.Name:match("^Dome") or piece.Name:match("^Cascade")
				piece.Color = piece.Color:Lerp(shadow, accent and 0.23 or 0.44)
			end
			silhouetteParts[piece] = piece.Transparency
			piece.Transparency = 1
		end
	end

	local palace = workspace:FindFirstChild("CloudPalace")
	local needsFallback = palace and not palace:FindFirstChild("CustomArchitecture")
	local dock = needsFallback and palace:FindFirstChild("CloudHavenDock")
	if needsFallback then palaceApproach(parent, palace) end
	if dock then
		local crystals = model(parent, "CrystalDockAccents")
		local side = dock.Size.X * 0.5
		local front = dock.Size.Z * 0.3
		for _, x in { -side, side } do
			for _, z in { -front, front } do
				local foot = dock.CFrame * CFrame.new(x, dock.Size.Y * 0.5 + 1.8, z)
				part(crystals, "Crystal", Vector3.new(3.5, 7.5, 3.5),
					foot * CFrame.Angles(0.11, math.pi / 4, -0.16), rgb(150, 237, 251), glassMat, "Wedge")
				part(crystals, "CrystalCore", Vector3.new(1.4, 4.8, 1.4),
					foot * CFrame.new(1.2, -0.3, 0.8) * CFrame.Angles(-0.23, 0.8, 0.22), rgb(122, 223, 255), neon, "Wedge")
			end
		end
	end

	return function(km, time)
		if animateSky then animateSky(km, time) end
		for i, item in gateCrystals do
			item.model:PivotTo(item.origin * CFrame.new(0, math.sin(time * 0.65 + i) * 2.8, 0) * CFrame.Angles(0, time * 0.45, 0))
		end
		local fadeIn = math.clamp((km - 8150) / 520, 0, 1)
		local fadeOut = math.clamp((9860 - km) / 370, 0, 1)
		for piece, transparency in silhouetteParts do
			piece.Transparency = 1 - (1 - transparency) * fadeIn * fadeOut * 0.82
		end
	end
end

local builders = { dawn, thundercloud, skyIsles, exosphere, gateway }
local names = { "DawnArchipelago", "IndigoThundercloud", "ForgottenSkyIsles", "CosmicExosphere", "CelestialGateway" }

function Scenery.Build(index)
	local scene = model(nil, names[index])
	local animate = builders[index](scene)
	local parts, beams = {}, {}
	for _, object in scene:GetDescendants() do
		if object:IsA("BasePart") then
			object.Anchored = true
			object.CanCollide = false
			object.CanTouch = false
			object.CanQuery = false
			object.CastShadow = false
			table.insert(parts, object)
		elseif object:IsA("Beam") then
			beams[object] = object.Transparency
		end
	end

	local lastOpacity
	return scene, function(km, time, opacity)
		if animate then animate(km, time) end
		if opacity == lastOpacity then return end
		lastOpacity = opacity
		for _, object in parts do object.LocalTransparencyModifier = 1 - opacity end
		for object, original in beams do
			local points = {}
			for i, point in original.Keypoints do
				points[i] = NumberSequenceKeypoint.new(point.Time, 1 - (1 - point.Value) * opacity)
			end
			object.Transparency = NumberSequence.new(points)
		end
	end
end

return Scenery
