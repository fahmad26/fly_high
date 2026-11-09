-- Local scenery only. Models never take part in flight physics or target selection.
local Config = require(script.Parent.FlyHighConfig)
local Scenery = {}

local rgb = Color3.fromRGB
local plastic = Enum.Material.SmoothPlastic
local slate = Enum.Material.Slate
local neon = Enum.Material.Neon
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
		part(island, "PaleReef", Vector3.new(width + 15, 3.4, width * 0.85), cf, reef, Enum.Material.Sand, ball)
		part(island, "Shore", Vector3.new(width, 10, width * 0.68), cf * CFrame.new(0, 2, 0), sand, Enum.Material.Sand, ball)
		local side = i % 2 == 0 and -1 or 1
		local cove = cf * CFrame.new(width * 0.21, 1.8, width * side * 0.19) * CFrame.Angles(0, side * 0.64, 0)
		part(island, "SandSpit", Vector3.new(width * 0.62, 6, width * 0.36), cove, sand, Enum.Material.Sand, ball)
		part(island, "GrassyCrest", Vector3.new(width * 0.71, 10, width * 0.49),
			cf * CFrame.new(-width * 0.08, 4.6, -side * width * 0.05), grass, Enum.Material.Grass, ball)
		part(island, "Headland", Vector3.new(width * 0.39, 7, width * 0.32), cove * CFrame.new(-3, 3.7, -side * 2),
			rgb(109, 155, 99), Enum.Material.Grass, ball)
		for j = 1, 4 do
			local offset = Vector3.new(random:NextNumber(-0.48, 0.48) * width, 2, j % 2 == 0 and width * 0.31 or -width * 0.28)
			part(island, "CoastalRock", Vector3.new(6, random:NextNumber(4, 8), 5),
				cf * CFrame.new(offset) * CFrame.Angles(0, j * 1.2, 0.2), rock, slate, "Wedge")
		end
		local foot = (cf * CFrame.new(-width * 0.13, 8, 0)).Position
		local crown = foot + Vector3.new(2.8, 8 + i % 3, -1.6)
		span(island, "PalmTrunk", foot, crown, 1.3, rgb(152, 108, 73), Enum.Material.Wood)
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
		part(boat, "Hull", Vector3.new(4, 2.4, 13), cf, rgb(104, 65, 54), Enum.Material.Wood, ball)
		column(boat, "Mast", position + Vector3.new(0, 5, 0), 0.36, 10, rgb(151, 98, 62), Enum.Material.Wood)
		part(boat, "MainSail", Vector3.new(0.35, 9, 6), cf * CFrame.new(0, 5.7, 2.8), rgb(255, 246, 217), plastic, "Wedge")
		part(boat, "Jib", Vector3.new(0.3, 6, 4), cf * CFrame.new(0, 4.3, -2.3) * CFrame.Angles(0, math.pi, 0),
			rgb(234, 153, 96), plastic, "Wedge")
		boat.WorldPivot = cf
		boats[i] = { boat = boat, origin = cf }
	end

	local cloudParts = {}
	for i = 1, 9 do
		local angle = i * math.pi * 2 / 9
		local center = Vector3.new(math.cos(angle) * 298, altitude(740 + i * 84), math.sin(angle) * 298)
		for _, cloud in band(parent, "CoastalCloudBank", center, Vector3.new(165, 30, 103),
			{ rgb(254, 247, 230), rgb(226, 237, 250), rgb(240, 243, 251) }, i + 31) do
			cloud.Transparency = 1
			table.insert(cloudParts, cloud)
		end
	end

	local lastCloudOpacity
	return function(km, time)
		local cloudOpacity = 1 - math.clamp((km - 420) / 700, 0, 1)
		if cloudOpacity ~= lastCloudOpacity then
			lastCloudOpacity = cloudOpacity
			for _, cloud in cloudParts do cloud.Transparency = cloudOpacity end
		end
		for i, item in boats do
			item.boat:PivotTo(item.origin * CFrame.new(0, math.sin(time * 0.65 + i) * 0.3, math.sin(time * 0.08 + i) * 10))
		end
	end
end

local function thundercloud(parent)
	local banks, rain = {}, {}
	local indigo = { rgb(78, 78, 119), rgb(96, 91, 146), rgb(109, 112, 163) }
	local random = Random.new(2020)
	for i = 1, 10 do
		local angle = i * math.pi * 2 / 10 + random:NextNumber(-0.12, 0.12)
		local radius = random:NextNumber(345, 458)
		local y = altitude(2040 + i * 180) + random:NextNumber(-36, 36)
		local position = Vector3.new(math.cos(angle) * radius, y, math.sin(angle) * radius)
		local size = Vector3.new(random:NextNumber(135, 230), random:NextNumber(70, 160), random:NextNumber(106, 165))
		local clouds = band(parent, "ThunderheadCliff", position, size, indigo, i * 19)
		banks[i] = { lobe = clouds[3], color = clouds[3].Color }
		if i % 2 == 0 then
			local origin = position + Vector3.new(0, -76, 0)
			local carrier = rail(parent, "SlantedRainCurtain", origin)
			carrier.Transparency = 1
			rain[#rain + 1] = { part = carrier, origin = origin }
			for j = 1, 13 do
				local offset = Vector3.new(random:NextNumber(-55, 55), random:NextNumber(-48, 48), random:NextNumber(-27, 27))
				beam(socket(carrier, offset), socket(carrier, offset + Vector3.new(-22, -88, 4)),
					1.3, 0.8, ColorSequence.new(rgb(137, 163, 242)), softFade(1, 0.54))
			end
		end
	end
	local stormTower = Vector3.new(-344, altitude(3070), -185)
	local storm = landmark(parent, "Storm", CFrame.new(stormTower) * CFrame.Angles(0, 0.55, 0), 1.2)
	if storm then
		local crown = storm:FindFirstChild("IndigoLight")
		if crown then banks[#banks + 1] = { lobe = crown, color = crown.Color } end
	else
		band(parent, "StormTowerBase", stormTower, Vector3.new(215, 100, 155), indigo, 139)
		band(parent, "StormTowerAnvil", stormTower + Vector3.new(-30, 98, -18), Vector3.new(238, 105, 173), indigo, 151)
	end
	return function(_, time)
		for i, item in rain do
			item.part.Position = item.origin + Vector3.new(math.sin(time * 0.4 + i) * 9, math.sin(time * 0.78 + i) * 12, 0)
		end
		for i, item in banks do
			local phase = (time + i * 3.19) % 13
			local pulse = math.max(0, 1 - math.abs(phase - 1.3) / 0.85)
			item.lobe.Color = item.color:Lerp(rgb(164, 165, 237), pulse * 0.78)
		end
	end
end

local function skyIsles(parent)
	local stone, grass = rgb(129, 93, 108), rgb(128, 143, 111)
	local masonry, roots = rgb(203, 165, 139), rgb(110, 73, 79)
	local widths = { 48, 95, 63, 133, 47, 98, 57 }
	local depths = { 0.82, 0.58, 0.72, 0.68, 0.9, 0.52, 0.71 }
	for i = 1, 7 do
		local angle = i * math.pi * 2 / 7 + 0.18
		local radius = 308 + i % 3 * 58
		local p = Vector3.new(math.cos(angle) * radius, altitude(4110 + (i - 1) * 290), math.sin(angle) * radius)
		local temple = i == 4
		local island = model(parent, temple and "CloudTempleIsland" or "ForgottenSkyIsle")
		local cf = CFrame.new(p) * CFrame.Angles(0, temple and 0.55 or angle, 0)
		local width, depth = widths[i], widths[i] * depths[i]
		local customTemple = temple and landmark(island, "Sunset", cf)
		if not customTemple then
			part(island, "BasaltShelf", Vector3.new(width, 23 + i * 2, depth), cf, stone, slate, ball)
			part(island, "OvergrownTerrace", Vector3.new(width * 0.92, 12, depth * 0.91),
				cf * CFrame.new(0, 10, 0), grass, Enum.Material.Grass, ball)
			for j = 1, 4 do
				local x = (j - 2.5) * width * 0.17
				part(island, "FracturedStone", Vector3.new(width * 0.35, 34 + j * 4, 27),
					cf * CFrame.new(x, -19, j % 2 * 13 - 7) * CFrame.Angles(math.pi, j * 1.2, 0.21),
					stone:Lerp(rgb(70, 61, 87), j * 0.13), slate, "Wedge")
				local start = (cf * CFrame.new(x, -7, 19)).Position
				local elbow = start + Vector3.new(4, -19 - j * 4, 3)
				span(island, "HangingRoot", start, elbow, 2.8, roots, Enum.Material.Wood)
				span(island, "RootTip", elbow, elbow + Vector3.new(j * 2 - 5, -18 - j * 2, 4), 1.4, roots, Enum.Material.Wood)
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
				span(island, "HangingRoot", start, elbow, 2.7, roots, Enum.Material.Wood)
				span(island, "RootTip", elbow, elbow + Vector3.new(j * 3 - 5, -15, 2), 1.3, roots, Enum.Material.Wood)
			end
		end

		if i == 1 or i == 5 then continue end
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
end

local function exosphere(parent)
	local random = Random.new(607)
	landmark(parent, "Cosmic", CFrame.new(-208, altitude(7160), -356) * CFrame.Angles(0, 0.4, 0))
	landmark(parent, "Cosmic", CFrame.new(270, altitude(7540), -410) * CFrame.Angles(0, -0.8, 0), 0.61)
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
	end
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
		column(landmarks, "BelvedereBase", plinth, 17, 4, gold, Enum.Material.Marble)
		column(landmarks, "BelvedereTower", plinth + Vector3.new(0, 15, 0), 12, 28, marble, Enum.Material.Marble)
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
		{ "HorizonPavilion", Vector3.new(-275, 1, -438), 0.72, -18 },
		{ "HorizonSpire", Vector3.new(323, -12, -558), 0.78, 25 },
		{ "HorizonCloud", Vector3.new(335, -22, 456), 0.83, -18 },
		-- Keep the front pair out of the palace silhouette and fill the side views too.
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
			local haze = math.clamp((offset.Magnitude - 350) / 1800, 0.05, 0.46)
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

	local routes = {
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
		local visibility = math.clamp((km - 8820) / 510, 0, 1)
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
	local clouds = { rgb(252, 232, 179), rgb(255, 244, 210), rgb(246, 221, 162) }
	for i = 1, 12 do
		local tier = math.floor((i - 1) / 4)
		local angle = (i - 1) * math.pi / 2 + 0.48 + tier * 0.32
		local radius = 350 + tier * 54
		local center = Vector3.new(math.cos(angle) * radius, altitude(8170 + tier * 715 + i % 4 * 80), math.sin(angle) * radius)
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
					foot * CFrame.Angles(0.11, math.pi / 4, -0.16), rgb(150, 237, 251), Enum.Material.Glass, "Wedge")
				part(crystals, "CrystalCore", Vector3.new(1.4, 4.8, 1.4),
					foot * CFrame.new(1.2, -0.3, 0.8) * CFrame.Angles(-0.23, 0.8, 0.22), rgb(122, 223, 255), neon, "Wedge")
			end
		end
	end

	return function(km, time)
		if animateSky then animateSky(km, time) end
		local fadeIn = math.clamp((km - 8850) / 430, 0, 1)
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
