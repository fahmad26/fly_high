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
local limestoneMat = Enum.Material.Limestone
local sandstoneMat = Enum.Material.Sandstone
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

local function getEnvironmentAssets()
	return script.Parent.Parent:FindFirstChild("EnvironmentAssets")
end

local function getTemplates()
	return script.Parent.Parent:FindFirstChild("Templates")
end

local function landmark(parent, name, cf, scale)
	local environment = getEnvironmentAssets()
	local meshes = environment and environment:FindFirstChild("BiomeLandmarkMeshes")
	local template = meshes and meshes:FindFirstChild(name)
	if not template then return nil end
	local copy = template:Clone()
	if scale then copy:ScaleTo(scale) end
	copy:PivotTo(cf or template:GetAttribute("WorldPlacement") or CFrame.identity)
	copy.Parent = parent
	return copy
end

-- Clone a sculpted nature asset (BroadleafTree, PalmTree, Fern, Boulder, Flower) from EnvironmentAssets
local function natureAsset(parent, templateName, instanceName, cf, scale, customizeFn)
	local environment = getEnvironmentAssets()
	local template = environment and environment:FindFirstChild(templateName)
	if not template then return nil end
	local copy = template:Clone()
	copy.Name = instanceName or templateName
	for _, d in copy:GetDescendants() do
		if d:IsA("BasePart") then
			if d.Name == "TrunkCollider" then
				d:Destroy()
			else
				if d.Name == "NatureRoot" then d.Transparency = 1 end
				d.Anchored = true
				d.CanCollide = false
				d.CanTouch = false
				d.CanQuery = false
				d.CastShadow = false
				if customizeFn then customizeFn(d) end
			end
		end
	end
	if scale and scale ~= 1 then copy:ScaleTo(scale) end
	copy:PivotTo(cf)
	copy.Parent = parent
	return copy
end

-- Clone a sculpted UnionOperation / MeshPart from Templates.FleetGeometry (SaturnRing, DockRim, Star, LotusPetal, LotusLeaf)
local function fleetShape(parent, templateName, partName, cf, size, color, material)
	local templates = getTemplates()
	local fleet = templates and templates:FindFirstChild("FleetGeometry")
	local group = fleet and fleet:FindFirstChild(templateName)
	if group then
		for _, d in group:GetDescendants() do
			if d:IsA("BasePart") and d.Name ~= "GeometryRoot" then
				local copy = d:Clone()
				copy.Name = partName
				copy.Size = size
				copy.CFrame = cf
				copy.Color = color
				copy.Material = material or metalMat
				if copy:IsA("UnionOperation") then copy.UsePartColor = true end
				copy.Anchored = true
				copy.CanCollide = false
				copy.CanTouch = false
				copy.CanQuery = false
				copy.CastShadow = false
				copy.Parent = parent
				return copy
			end
		end
	end
	return part(parent, partName, size, cf, color, material or metalMat, ball)
end

-- Clone a sculpted balloon envelope MeshPart from Templates.BalloonSkins
local function balloonEnvelopeMesh(parent, skinName, partName, cf, size, color, material, keepTexture)
	local templates = getTemplates()
	local skins = templates and templates:FindFirstChild("BalloonSkins")
	local skin = skins and skins:FindFirstChild(skinName)
	if skin then
		for _, d in skin:GetDescendants() do
			if d:IsA("MeshPart") then
				local copy = d:Clone()
				copy.Name = partName
				if not keepTexture then copy.TextureID = "" end
				copy.Size = size
				copy.CFrame = cf
				copy.Color = color
				copy.Material = material or plastic
				copy.Anchored = true
				copy.CanCollide = false
				copy.CanTouch = false
				copy.CanQuery = false
				copy.CastShadow = false
				copy.Parent = parent
				return copy
			end
		end
	end
	return part(parent, partName, size, cf, color, material or plastic, ball)
end

-- Clone pure visual parts of CloudPalace's SummitPhotoPodium (stripped of prompts/lights)
local function clonePalacePodium(parent, name, cf, scale, stoneCol, goldCol, slateCol, ivoryCol, amberCol)
	local palace = workspace:FindFirstChild("CloudPalace")
	local podium = palace and palace:FindFirstChild("SummitPhotoPodium")
	if not podium then return nil end
	local copy = model(parent, name)
	local origin = podium:GetPivot()
	for _, d in podium:GetDescendants() do
		if d:IsA("BasePart") and d.Name ~= "LanternLight" then
			local p = d:Clone()
			p:ClearAllChildren()
			local rel = origin:ToObjectSpace(d.CFrame)
			p.Size = d.Size * scale
			p.CFrame = cf * CFrame.new(rel.Position * scale) * (rel - rel.Position)
			if p.Name == "PhotoStone" or p.Name == "PodiumStep" then
				p.Color = stoneCol or p.Color
			elseif p.Name == "PhotoGold" then
				p.Color = goldCol or p.Color
				p.Material = metalMat
			elseif p.Name == "PhotoSlate" then
				p.Color = slateCol or p.Color
			elseif p.Name == "PhotoIvory" then
				p.Color = ivoryCol or p.Color
			elseif p.Name == "PhotoAmber" then
				p.Color = amberCol or p.Color
				p.Material = neon
			end
			p.Anchored = true
			p.CanCollide = false
			p.CanTouch = false
			p.CanQuery = false
			p.CastShadow = false
			p.Parent = copy
		end
	end
	copy.WorldPivot = cf
	return copy
end

-- Clone pure visual parts of CloudPalace's GardenLantern01
local function clonePalaceLantern(parent, cf, scale, glowColor)
	local palace = workspace:FindFirstChild("CloudPalace")
	local garden = palace and palace:FindFirstChild("PalaceGarden")
	local lantern = garden and garden:FindFirstChild("GardenLantern01")
	if not lantern then return nil end
	local copy = model(parent, "SanctuaryLantern")
	local origin = lantern:GetPivot()
	for _, d in lantern:GetDescendants() do
		if d:IsA("BasePart") then
			local p = d:Clone()
			p:ClearAllChildren()
			local rel = origin:ToObjectSpace(d.CFrame)
			p.Size = d.Size * scale
			p.CFrame = cf * CFrame.new(rel.Position * scale) * (rel - rel.Position)
			if p.Name == "AmberGlass" and glowColor then
				p.Color = glowColor
				p.Material = neon
			end
			p.Anchored = true
			p.CanCollide = false
			p.CanTouch = false
			p.CanQuery = false
			p.CastShadow = false
			p.Parent = copy
		end
	end
	copy.WorldPivot = cf
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

-- Volumetric cloud bank built from sculpted marching-tetrahedra cloud meshes (PalaceCloud / HorizonCloud / UpperSkyCloud / ZenithCloud)
local function band(parent, name, center, size, colors, seed)
	local group = model(parent, name)
	local random = Random.new(seed)
	local lobes = {}
	local templates = { "PalaceCloud", "HorizonCloud", "UpperSkyCloud", "ZenithCloud" }
	local choice = templates[(seed % #templates) + 1]
	local baseScale = math.clamp(size.X / 240, 0.28, 1.15)
	local yaw = random:NextNumber(0, math.pi * 2)
	local primary = landmark(group, choice, CFrame.new(center) * CFrame.Angles(0, yaw, 0), baseScale)
	if primary then
		local idx = 1
		for _, d in primary:GetDescendants() do
			if d:IsA("BasePart") then
				d.Color = colors[(idx - 1) % #colors + 1]
				d.Material = plastic
				lobes[#lobes + 1] = d
				idx += 1
			end
		end
	end
	local subScale = math.clamp(size.X / 280, 0.22, 0.85)
	local subOffset = Vector3.new(random:NextNumber(-0.18, 0.18) * size.X, random:NextNumber(-0.12, 0.14) * size.Y, random:NextNumber(-0.16, 0.16) * size.Z)
	local secondary = landmark(group, "PalaceCloud", CFrame.new(center + subOffset) * CFrame.Angles(0, yaw + 1.4, 0), subScale)
	if secondary then
		local idx = 2
		for _, d in secondary:GetDescendants() do
			if d:IsA("BasePart") then
				d.Color = colors[(idx - 1) % #colors + 1]
				d.Material = plastic
				lobes[#lobes + 1] = d
				idx += 1
			end
		end
	end
	if #lobes == 0 then
		for i = 1, 6 do
			local angle = (i - 1) * math.pi / 3
			local offset = Vector3.new(math.cos(angle) * size.X * 0.22, random:NextNumber(-0.12, 0.18) * size.Y, math.sin(angle) * size.Z * 0.22)
			lobes[i] = part(group, "CloudLobe", size * Vector3.new(0.62, 0.74, 0.64),
				CFrame.new(center + offset), colors[(i - 1) % #colors + 1], plastic, ball)
		end
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

-- Sculpted floating island terrain base built from BiomeLandmarkMeshes.Sunset's organic crag & terrace meshes
local function buildSculptedIslandTerrain(parent, cf, scale, palette, keepTempleRuins)
	local base = landmark(parent, "Sunset", cf, scale)
	if not base then return nil end
	base.Name = "SculptedIslandTerrain"
	local mossPart = base:FindFirstChild("Moss")
	local basaltPart = base:FindFirstChild("Basalt")
	local terraPart = base:FindFirstChild("TerraCotta")
	local sandPart = base:FindFirstChild("Sandstone")
	local ivoryPart = base:FindFirstChild("Ivory")
	local goldPart = base:FindFirstChild("Gold")

	if basaltPart then
		basaltPart.Color = palette.basalt or rgb(82, 98, 108)
		basaltPart.Material = palette.rockMat or slate
	end
	if mossPart then
		mossPart.Color = palette.moss or rgb(82, 148, 88)
		mossPart.Material = palette.turfMat or grassMat
		local cliffRim = mossPart:Clone()
		cliffRim.Name = "SculptedCliffRim"
		cliffRim.Size = mossPart.Size * Vector3.new(1.04, 1.18, 1.04)
		cliffRim.CFrame = mossPart.CFrame * CFrame.new(0, -4.8 * scale, 0)
		cliffRim.Color = palette.cliff or rgb(166, 148, 124)
		cliffRim.Material = palette.cliffMat or sandstoneMat
		cliffRim.Parent = base
	end

	if keepTempleRuins then
		if terraPart then
			terraPart.Color = palette.cliff or rgb(196, 134, 98)
			terraPart.Material = palette.cliffMat or sandstoneMat
		end
		if sandPart then
			sandPart.Color = palette.sandstone or rgb(182, 138, 104)
			sandPart.Material = sandstoneMat
		end
		if ivoryPart then
			ivoryPart.Color = palette.ivory or rgb(236, 220, 188)
			ivoryPart.Material = limestoneMat
		end
		if goldPart then
			goldPart.Color = palette.gold or rgb(242, 182, 74)
			goldPart.Material = metalMat
		end
	else
		if terraPart then terraPart:Destroy() end
		if sandPart then sandPart:Destroy() end
		if ivoryPart then ivoryPart:Destroy() end
		if goldPart then goldPart:Destroy() end
	end

	-- Soft sculpted PalaceCloud collar hugging the floating island underside
	if palette.cloudColor then
		local collarCf = cf * CFrame.new(0, -8 * scale, 0) * CFrame.Angles(0, 0.8, 0)
		local collar = landmark(parent, "PalaceCloud", collarCf, scale * 0.56)
		if collar then
			collar.Name = "IslandCloudCollar"
			for _, d in collar:GetDescendants() do
				if d:IsA("BasePart") then
					d.Color = d.Name == "CloudShadow" and (palette.cloudShadow or palette.cloudColor) or palette.cloudColor
					d.Transparency = palette.cloudTransparency or 0.18
				end
			end
		end
	end
	return base
end

-- Attach a sculpted waterfall cascade
local function attachSculptedWaterfall(parent, lipCf, dropHeight, scale, waterColor, foamColor, mistColor)
	local wColor = waterColor or rgb(98, 196, 238)
	local fColor = foamColor or rgb(214, 244, 255)
	local mColor = mistColor or rgb(238, 246, 255)

	part(parent, "SpringPool", Vector3.new(18, 1.8, 14) * scale,
		lipCf * CFrame.new(0, 0.4 * scale, -4 * scale), wColor, glassMat, ball)
	for _, side in { -1, 1 } do
		natureAsset(parent, "Boulder", "SpillwayBoulder",
			lipCf * CFrame.new(side * 6.5 * scale, -0.5 * scale, -1.5 * scale) * CFrame.Angles(0, side * 0.8, 0),
			1.25 * scale)
	end

	local carrier = rail(parent, "ThinWaterfall", lipCf.Position)
	carrier.Transparency = 1
	for j = -1, 1 do
		local off = Vector3.new(j * 2.6 * scale, 0, 0)
		local stream = beam(
			socket(carrier, off, Vector3.new(0.15, -1, 0.22)),
			socket(carrier, off + Vector3.new(j * 1.4 * scale, -dropHeight, 9 * scale), Vector3.new(0.08, -1, 0.15)),
			(3.6 + (1 - math.abs(j)) * 1.2) * scale,
			(8.2 + (1 - math.abs(j)) * 2.0) * scale,
			ColorSequence.new(wColor, fColor),
			softFade(0.86, 0.18),
			14 * scale
		)
		stream.LightEmission = 0.42
	end

	local mistCloud = landmark(parent, "PalaceCloud",
		lipCf * CFrame.new(0, -dropHeight * 0.78, 8 * scale) * CFrame.Angles(0, 0.5, 0),
		math.clamp(scale * 0.22, 0.14, 0.34))
	if mistCloud then
		mistCloud.Name = "WaterfallMistCloud"
		for _, d in mistCloud:GetDescendants() do
			if d:IsA("BasePart") then
				d.Color = mColor
				d.Transparency = 0.42
			end
		end
	end
end

local function buildFloatingRockIslet(parent, name, cf, width, hasWaterfall, seed)
	local islet = model(parent, name)
	local random = Random.new(seed)
	local scale = math.clamp(width / 108, 0.32, 0.68)

	buildSculptedIslandTerrain(islet, cf, scale, {
		basalt = rgb(86, 106, 118),
		cliff = rgb(168, 150, 124),
		moss = rgb(80, 148, 86),
		cloudColor = rgb(252, 246, 232),
		cloudShadow = rgb(216, 228, 244),
		cloudTransparency = 0.16,
	}, false)

	local topY = 12.5 * scale
	natureAsset(islet, "BroadleafTree", "CanopyTree",
		cf * CFrame.new(-8 * scale, topY, -4 * scale) * CFrame.Angles(0, random:NextNumber(0, 6.28), 0),
		math.clamp(scale * 1.45, 0.55, 0.95))

	if width >= 42 then
		natureAsset(islet, "PalmTree", "IslandPalm",
			cf * CFrame.new(14 * scale, topY - 1 * scale, 6 * scale) * CFrame.Angles(0.06, random:NextNumber(0, 6.28), -0.05),
			math.clamp(scale * 1.25, 0.48, 0.82))
	end

	for i = 1, 3 do
		local a = (i - 1) * math.pi * 2 / 3 + random:NextNumber(-0.3, 0.3)
		local r = (16 + i * 4) * scale
		local spot = cf * CFrame.new(math.cos(a) * r, topY - 0.5 * scale, math.sin(a) * r) * CFrame.Angles(0, a, 0)
		natureAsset(islet, "Boulder", "TerraceBoulder", spot, (0.9 + (i % 2) * 0.45) * scale)
		natureAsset(islet, "Fern", "TerraceFern", spot * CFrame.new(2.2 * scale, 0, 1.5 * scale), (1.1 + (i % 2) * 0.3) * scale)
		natureAsset(islet, "Flower", "TerraceFlower", spot * CFrame.new(-1.8 * scale, 0.2 * scale, 1.8 * scale), 1.15 * scale)
	end

	if hasWaterfall then
		local lipCf = cf * CFrame.new(32 * scale, topY - 1.5 * scale, 12 * scale) * CFrame.Angles(0, 0.35, 0)
		attachSculptedWaterfall(islet, lipCf, 95 * scale, scale * 1.35,
			rgb(94, 198, 240), rgb(220, 246, 255), rgb(242, 248, 255))
	end

	islet.WorldPivot = cf
	return islet
end

local function buildWeatherBalloon(parent, cf, scale)
	local wb = model(parent, "WeatherBalloon")
	local royalBlue = rgb(44, 104, 198)
	local skyBlue = rgb(86, 158, 236)
	local gold = rgb(242, 192, 78)
	local brass = rgb(206, 156, 68)
	local copper = rgb(168, 108, 62)

	local envCenter = cf * CFrame.new(0, 16 * scale, 0)
	balloonEnvelopeMesh(wb, "D", "EnvelopeMain", envCenter,
		Vector3.new(25.5, 31.0, 25.5) * scale, royalBlue, plastic, false)
	balloonEnvelopeMesh(wb, "E", "EnvelopeGoldGores", envCenter * CFrame.Angles(0, math.pi / 8, 0),
		Vector3.new(26.2, 30.2, 26.2) * scale, gold, metalMat, false)
	balloonEnvelopeMesh(wb, "E", "EnvelopeSkyGores", envCenter * CFrame.Angles(0, math.pi / 4, 0),
		Vector3.new(25.9, 30.6, 25.9) * scale, skyBlue, plastic, false)

	fleetShape(wb, "SaturnRing", "EquatorialGoldBand",
		envCenter * CFrame.new(0, 3.2 * scale, 0) * CFrame.Angles(0, 0, math.pi / 2),
		Vector3.new(0.9, 27.6, 27.6) * scale, gold, metalMat)
	fleetShape(wb, "DockRim", "UpperLatitudeCollar",
		envCenter * CFrame.new(0, 11.2 * scale, 0) * CFrame.Angles(0, 0, math.pi / 2),
		Vector3.new(0.7, 21.4, 21.4) * scale, brass, metalMat)
	fleetShape(wb, "DockRim", "NeckTrimRing",
		cf * CFrame.new(0, 1.2 * scale, 0) * CFrame.Angles(0, 0, math.pi / 2),
		Vector3.new(0.8, 9.2, 9.2) * scale, brass, metalMat)

	for _, side in { -1, 1 } do
		fleetShape(wb, "Star", "SunEmblem",
			envCenter * CFrame.new(0, 3.2 * scale, side * 13.4 * scale) * CFrame.Angles(math.pi / 2, 0, 0),
			Vector3.new(0.6, 6.8, 6.8) * scale, gold, neon)
	end

	column(wb, "TopMast", (cf * CFrame.new(0, 34.5 * scale, 0)).Position, 0.75 * scale, 7.2 * scale, brass, metalMat)
	fleetShape(wb, "DockRim", "AnemometerHalo",
		cf * CFrame.new(0, 36.2 * scale, 0) * CFrame.Angles(0, 0, math.pi / 2),
		Vector3.new(0.4, 6.2, 6.2) * scale, gold, metalMat)
	part(wb, "TopBeacon", Vector3.one * (2.2 * scale), cf * CFrame.new(0, 38.6 * scale, 0), rgb(255, 232, 136), neon, ball)

	local podCenter = (cf * CFrame.new(0, -8.5 * scale, 0)).Position
	for i = 1, 4 do
		local a = (i - 1) * math.pi / 2 + math.pi / 4
		local topAttach = (cf * CFrame.new(math.cos(a) * 4.2 * scale, 1.2 * scale, math.sin(a) * 4.2 * scale)).Position
		local botAttach = podCenter + Vector3.new(math.cos(a) * 3.1 * scale, 2.8 * scale, math.sin(a) * 3.1 * scale)
		span(wb, "RiggingCable", topAttach, botAttach, 0.28 * scale, brass, metalMat)
	end
	column(wb, "SondeCapsule", podCenter, 5.8 * scale, 5.4 * scale, copper, metalMat)
	fleetShape(wb, "DockRim", "SondeGuardRing",
		CFrame.new(podCenter) * CFrame.Angles(0, 0, math.pi / 2),
		Vector3.new(0.6, 8.6, 8.6) * scale, gold, metalMat)
	part(wb, "SondeSensorDome", Vector3.new(4.6, 3.8, 4.6) * scale, cf * CFrame.new(0, -11.4 * scale, 0), skyBlue, glassMat, ball)
	part(wb, "SondeGlowCore", Vector3.new(2.8, 2.2, 2.8) * scale, cf * CFrame.new(0, -11.4 * scale, 0), rgb(138, 224, 255), neon, ball)
	column(wb, "VaneBoom", podCenter + Vector3.new(0, -4.8 * scale, 0), 0.45 * scale, 5.2 * scale, brass, metalMat)

	local tailCarrier = rail(wb, "TailRibbons", podCenter)
	tailCarrier.Transparency = 1
	local s1 = socket(tailCarrier, Vector3.new(-2.4 * scale, 0, 0), Vector3.new(-1, -0.3, 0.2))
	local f1 = socket(tailCarrier, Vector3.new(-17 * scale, -8.5 * scale, 5.5 * scale), Vector3.new(-1, -0.1, 0.3))
	beam(s1, f1, 2.1 * scale, 0.55 * scale, ColorSequence.new(skyBlue, gold), softFade(0.18, 0.04), 7.5 * scale)

	local s2 = socket(tailCarrier, Vector3.new(2.4 * scale, -0.8 * scale, 0), Vector3.new(-1, -0.4, -0.2))
	local f2 = socket(tailCarrier, Vector3.new(-14.5 * scale, -11.5 * scale, -4.8 * scale), Vector3.new(-1, -0.2, -0.2))
	beam(s2, f2, 1.8 * scale, 0.48 * scale, ColorSequence.new(gold, royalBlue), softFade(0.18, 0.04), -6.8 * scale)

	wb.WorldPivot = cf
	return wb
end

local function buildSeabirdFlock(parent, centerCf, birdCount, scale)
	local flock = model(parent, "DistantSeabirdFlock")
	local plumage = rgb(248, 249, 252)
	local chestCol = rgb(232, 238, 246)
	local wingTip = rgb(52, 68, 92)
	local beakColor = rgb(242, 178, 68)

	for i = 1, birdCount do
		local side = i == 1 and 0 or (i % 2 == 0 and 1 or -1)
		local rank = math.floor(i / 2)
		local offset = Vector3.new(side * rank * 8.2 * scale, math.abs(rank) * 1.5 * scale + (i % 2) * 0.9, rank * 6.8 * scale)
		local bcf = centerCf * CFrame.new(offset)
		local bird = model(flock, "Seabird")

		part(bird, "Body", Vector3.new(2.1, 1.6, 4.9) * scale, bcf, plumage, plastic, ball)
		part(bird, "Chest", Vector3.new(1.8, 1.35, 2.7) * scale, bcf * CFrame.new(0, -0.18 * scale, -0.95 * scale), chestCol, plastic, ball)
		part(bird, "Head", Vector3.new(1.45, 1.35, 1.75) * scale, bcf * CFrame.new(0, 0.42 * scale, -2.25 * scale), plumage, plastic, ball)
		part(bird, "Beak", Vector3.new(0.55, 0.48, 1.65) * scale,
			bcf * CFrame.new(0, 0.28 * scale, -3.35 * scale) * CFrame.Angles(math.rad(8), 0, 0), beakColor, plastic, "Wedge")

		for _, wSide in { -1, 1 } do
			local innerCf = bcf * CFrame.new(wSide * 2.5 * scale, 0.35 * scale, -0.15 * scale)
				* CFrame.Angles(0, wSide * -0.1, wSide * 0.24)
			local outerCf = innerCf * CFrame.new(wSide * 2.9 * scale, 0.28 * scale, 0.45 * scale)
				* CFrame.Angles(0, wSide * -0.16, wSide * -0.32)
			part(bird, "InnerWing", Vector3.new(5.2, 0.42, 2.2) * scale, innerCf, plumage, plastic, "Wedge")
			part(bird, "OuterWing", Vector3.new(4.4, 0.34, 1.7) * scale, outerCf, wingTip, plastic, "Wedge")
			for f = 1, 3 do
				part(bird, "FlightFeather", Vector3.new(1.8, 0.18, 0.65) * scale,
					outerCf * CFrame.new(wSide * (0.6 + f * 0.48) * scale, -0.05 * scale, (0.35 + f * 0.22) * scale)
						* CFrame.Angles(0, wSide * 0.18, 0),
					f == 3 and wingTip or chestCol, plastic)
			end
		end
		for t = -1, 1 do
			part(bird, "TailFeather", Vector3.new(0.58, 0.18, 1.95) * scale,
				bcf * CFrame.new(t * 0.42 * scale, 0.08 * scale, 2.85 * scale)
					* CFrame.Angles(math.rad(-8), math.rad(t * 12), 0),
				math.abs(t) == 1 and wingTip or plumage, plastic, "Wedge")
		end
	end
	flock.WorldPivot = centerCf
	return flock
end

local function dawn(parent)
	local random = Random.new(802)
	local headland = landmark(parent, "Dawn", CFrame.new(115, -5, -308) * CFrame.Angles(0, 0.32, 0))
	if headland then
		local hCf = headland:GetPivot()
		natureAsset(headland, "PalmTree", "HeadlandPalm1", hCf * CFrame.new(-14, 14, -4) * CFrame.Angles(0.05, 0.8, -0.04), 0.92)
		natureAsset(headland, "PalmTree", "HeadlandPalm2", hCf * CFrame.new(8, 13, 6) * CFrame.Angles(-0.04, 2.4, 0.06), 0.84)
		natureAsset(headland, "BroadleafTree", "HeadlandTree", hCf * CFrame.new(-4, 15, 2) * CFrame.Angles(0, 1.5, 0), 0.78)
		natureAsset(headland, "Boulder", "HeadlandBoulder", hCf * CFrame.new(18, 10, -8) * CFrame.Angles(0, 0.9, 0), 1.45)
		natureAsset(headland, "Fern", "HeadlandFern", hCf * CFrame.new(-8, 14, 4), 1.25)
	end

	for i = 1, 9 do
		local angle = (i - 1) * math.pi * 2 / 9 + 0.2
		local direction = Vector3.new(math.cos(angle), 0, math.sin(angle))
		local position = direction * random:NextNumber(245, 365)
		if headland and i == 8 then continue end
		local island = model(parent, "CoastalIslet")
		local cf = CFrame.new(position + Vector3.new(0, -1.5, 0)) * CFrame.Angles(0, angle + random:NextNumber(-0.4, 0.4), 0)
		local width = random:NextNumber(34, 58)
		local meshScale = math.clamp(width / 96, 0.36, 0.62)

		local sculptedDawn = landmark(island, "Dawn", cf, meshScale)
		if sculptedDawn then
			sculptedDawn.Name = "SculptedAtoll"
		end

		local crestY = 14.5 * meshScale
		natureAsset(island, "PalmTree", "CoastalPalm",
			cf * CFrame.new(-6 * meshScale, crestY, -2 * meshScale) * CFrame.Angles(0.06, angle + i, -0.05),
			math.clamp(meshScale * 1.45, 0.56, 0.88))
		if i % 2 == 0 then
			natureAsset(island, "BroadleafTree", "CoastalBroadleaf",
				cf * CFrame.new(10 * meshScale, crestY - 1 * meshScale, 4 * meshScale) * CFrame.Angles(0, i * 1.3, 0),
				math.clamp(meshScale * 1.25, 0.48, 0.76))
		end
		natureAsset(island, "Boulder", "CoastalBoulder",
			cf * CFrame.new(18 * meshScale, 6 * meshScale, -8 * meshScale) * CFrame.Angles(0, i * 0.9, 0),
			1.35 * meshScale)
		natureAsset(island, "Fern", "CoastalFern",
			cf * CFrame.new(-2 * meshScale, crestY, 3 * meshScale) * CFrame.Angles(0, i * 1.7, 0),
			1.2 * meshScale)
		natureAsset(island, "Flower", "CoastalFlower",
			cf * CFrame.new(4 * meshScale, crestY, -3 * meshScale) * CFrame.Angles(0, i * 2.1, 0),
			1.15 * meshScale)
		island.WorldPivot = cf
	end

	local boats = {}
	for i = 1, 4 do
		local angle = i * math.pi / 2 + 0.65
		local position = Vector3.new(math.cos(angle) * 258, 1.6, math.sin(angle) * 258)
		local boat = model(parent, "DistantSailboat")
		local cf = CFrame.new(position) * CFrame.Angles(0, angle, 0)
		local cutter = landmark(boat, i % 2 == 0 and "CloudCutter" or "CloudSailer", cf, 0.24)
		if cutter then
			cutter.Name = "SculptedSchooner"
		end
		boat.WorldPivot = cf
		boats[i] = { boat = boat, origin = cf }
	end

	local isletSpecs = {
		{ km = 480, x = -112, z = -238, width = 44, yaw = 0.35, waterfall = false },
		{ km = 520, x = 246, z = -28, width = 42, yaw = -1.2, waterfall = false },
		{ km = 590, x = -248, z = 24, width = 38, yaw = 1.4, waterfall = false },
		{ km = 780, x = 68, z = -252, width = 46, yaw = -0.4, waterfall = false },
		{ km = 1170, x = 128, z = -236, width = 50, yaw = -0.35, waterfall = false },
		{ km = 1210, x = 244, z = -22, width = 46, yaw = -1.35, waterfall = false },
		{ km = 1260, x = -246, z = -18, width = 40, yaw = 1.25, waterfall = false },
		{ km = 1520, x = 58, z = -262, width = 42, yaw = -0.5, waterfall = false },
		{ km = 1660, x = -134, z = -248, width = 64, yaw = 0.32, waterfall = true },
		{ km = 1860, x = -68, z = -234, width = 58, yaw = 0.28, waterfall = true },
		{ km = 1890, x = 245, z = -24, width = 44, yaw = -1.4, waterfall = false },
		{ km = 1940, x = -246, z = 22, width = 38, yaw = 1.5, waterfall = false },
	}
	for idx, spec in isletSpecs do
		local cf = CFrame.new(spec.x, altitude(spec.km), spec.z) * CFrame.Angles(0, spec.yaw, 0)
		local name = spec.waterfall and "DawnWaterfallIsle" or "LowFloatingIslet"
		buildFloatingRockIslet(parent, name, cf, spec.width, spec.waterfall, 900 + idx * 17)
	end

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

	local cloudColors = { rgb(254, 248, 234), rgb(228, 238, 250), rgb(242, 245, 252) }
	local cloudLayers = {
		{ count = 8, minKm = 320, stepKm = 205, radius = 268, size = Vector3.new(135, 26, 88), phase = 0.15 },
		{ count = 9, minKm = 440, stepKm = 180, radius = 348, size = Vector3.new(178, 34, 112), phase = 0.52 },
		{ count = 7, minKm = 260, stepKm = 245, radius = 460, size = Vector3.new(235, 42, 142), phase = 0.88 },
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
				cloud.Transparency = 0.1
				table.insert(cloudParts, cloud)
			end
		end
	end

	local lastCloudTransparency
	return function(km, time)
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
	local colors = {
		rgb(52, 46, 94),
		rgb(68, 62, 118),
		rgb(86, 78, 142),
		rgb(108, 98, 174),
	}

	local topAnvil = landmark(vortex, "Storm",
		CFrame.new(basePos + Vector3.new(0, height * 0.52, 0)) * CFrame.Angles(0, seed * 0.7, 0),
		math.clamp(topWidth / 165, 0.52, 0.95))
	if topAnvil then
		topAnvil.Name = "VortexAnvilCrown"
	end

	local rings = {}
	local tierAttachments = {}
	for i = 1, ringCount do
		local t = (i - 1) / (ringCount - 1)
		local eased = t * t * (3 - 2 * t)
		local w = bottomWidth + (topWidth - bottomWidth) * eased
		local y = basePos.Y + (t - 0.5) * height
		local bendX = math.sin(t * math.pi * 1.25) * (topWidth * 0.15)
		local bendZ = math.cos(t * math.pi * 1.1) * (topWidth * 0.09)
		local ringCenter = Vector3.new(basePos.X + bendX, y, basePos.Z + bendZ)
		local ringModel = model(vortex, "VortexTier")
		local ringCf = CFrame.new(ringCenter) * CFrame.Angles(0, i * 0.65, 0)

		local cloudScale = math.clamp(w / 185, 0.12, 0.82)
		local sculptedTier = landmark(ringModel, "PalaceCloud", ringCf * CFrame.new(0, 14 * cloudScale, 0), cloudScale)
		if sculptedTier then
			sculptedTier.Name = "FunnelCloudMesh"
			for idx, d in sculptedTier:GetDescendants() do
				if d:IsA("BasePart") then
					d.Color = colors[(i + idx) % #colors + 1]
					d.Transparency = 0.08 + (1 - t) * 0.08
				end
			end
		end

		if i % 3 == 0 then
			local glow = part(ringModel, "VortexLightningCore", Vector3.new(w * 0.42, 12 + eased * 10, w * 0.42),
				ringCf, rgb(172, 158, 255), neon, ball)
			glow.Transparency = 0.56
		end

		local carrier = rail(ringModel, "RibbonAnchor", ringCenter)
		carrier.Transparency = 1
		tierAttachments[i] = { part = carrier, width = w }

		ringModel.WorldPivot = ringCf
		rings[i] = { model = ringModel, origin = ringCf, radius = 3.2 + (1 - t) * 5.2, phase = i * 0.55 }
	end

	for strand = 1, 4 do
		local isLightning = strand == 4
		local seq = isLightning
			and ColorSequence.new(rgb(186, 174, 255), rgb(132, 118, 238))
			or ColorSequence.new(rgb(88, 82, 146), rgb(138, 132, 204))
		for i = 1, ringCount - 1 do
			local a0 = (strand - 1) * math.pi / 2 + i * 0.85
			local a1 = a0 + 0.95
			local r0 = tierAttachments[i].width * 0.42
			local r1 = tierAttachments[i + 1].width * 0.42
			local s0 = socket(tierAttachments[i].part,
				Vector3.new(math.cos(a0) * r0, 0, math.sin(a0) * r0),
				Vector3.new(-math.sin(a0), 0.55, math.cos(a0)))
			local s1 = socket(tierAttachments[i + 1].part,
				Vector3.new(math.cos(a1) * r1, 0, math.sin(a1) * r1),
				Vector3.new(-math.sin(a1), 0.55, math.cos(a1)))
			local rib = beam(
				s0, s1,
				isLightning and 2.6 or (5.5 + i * 0.6),
				isLightning and 3.2 or (6.2 + i * 0.65),
				seq,
				isLightning and softFade(0.75, 0.18) or softFade(0.84, 0.36),
				r0 * 0.55
			)
			rib.LightEmission = isLightning and 0.95 or 0.45
		end
	end

	return rings
end

local function buildStormRockFragment(parent, cf, scale, seed)
	local frag = model(parent, "StormEdgeFragment")
	local darkSlate = rgb(48, 44, 78)
	local midSlate = rgb(66, 60, 104)
	local glowColor = seed % 2 == 0 and rgb(244, 152, 86) or rgb(168, 126, 255)

	local crag = landmark(frag, "Cosmic", cf * CFrame.Angles(0.18, seed * 0.7, -0.14), 0.25 * scale)
	if crag then
		crag.Name = "SculptedStormCrag"
		for _, d in crag:GetDescendants() do
			if d:IsA("BasePart") then
				if d.Name == "Astral" then
					d.Color = darkSlate
					d.Material = slate
				elseif d.Name == "Violet" then
					d.Color = midSlate
					d.Material = slate
				elseif d.Name == "Crystal" then
					d.Color = glowColor
					d.Material = neon
					d.Transparency = 0.12
				end
			end
		end
	end

	for _, side in { -1, 1 } do
		natureAsset(frag, "Boulder", "StormBoulder",
			cf * CFrame.new(side * 5.5 * scale, -2.5 * scale, side * 2.2 * scale) * CFrame.Angles(0.4, side * 1.2, 0.2),
			1.85 * scale,
			function(d)
				if d:IsA("MeshPart") then d.TextureID = "" end
				if d.Name:find("moss") then
					d.Color = glowColor
					d.Material = neon
				else
					d.Color = darkSlate
					d.Material = slate
				end
			end)
	end
	fleetShape(frag, "DockRim", "ChargedArcRing",
		cf * CFrame.Angles(0.35, 0.4, 0.8),
		Vector3.new(0.45, 16.5, 16.5) * scale, glowColor, neon)

	frag.WorldPivot = cf
	return frag
end

local function thundercloud(parent)
	local banks, rain = {}, {}
	local indigo = { rgb(72, 68, 116), rgb(92, 86, 144), rgb(112, 108, 168) }
	local anvilPalette = { rgb(64, 58, 108), rgb(88, 82, 146), rgb(118, 114, 182) }
	local random = Random.new(2020)

	for i = 1, 12 do
		local angle = (i - 1) * math.pi * 2 / 12 + random:NextNumber(-0.1, 0.1)
		local radius = random:NextNumber(305, 395)
		local y = altitude(2060 + i * 150) + random:NextNumber(-28, 28)
		local position = Vector3.new(math.cos(angle) * radius, y, math.sin(angle) * radius)
		local size = Vector3.new(random:NextNumber(155, 235), random:NextNumber(72, 155), random:NextNumber(110, 168))
		local clouds = band(parent, "ThunderheadCliff", position, size, indigo, i * 19)
		if clouds[1] then
			banks[#banks + 1] = { lobe = clouds[1], color = clouds[1].Color }
		end

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

	local anvilSpecs = {
		{ km = 2380, pos = Vector3.new(255, altitude(2380), -220), yaw = -0.45, scale = 0.95 },
		{ km = 3040, pos = Vector3.new(-235, altitude(3040), -225), yaw = 0.55, scale = 1.15 },
		{ km = 3020, pos = Vector3.new(285, altitude(3020), -25), yaw = -1.45, scale = 1.05 },
		{ km = 3520, pos = Vector3.new(-45, altitude(3520), -285), yaw = 0.15, scale = 1.1 },
	}
	for idx, spec in anvilSpecs do
		local storm = landmark(parent, "Storm", CFrame.new(spec.pos) * CFrame.Angles(0, spec.yaw, 0), spec.scale)
		if storm then
			local crown = storm:FindFirstChild("IndigoLight")
			if crown then banks[#banks + 1] = { lobe = crown, color = crown.Color } end
		end
		local anvilTop = spec.pos + Vector3.new(0, 76 * spec.scale, 0)
		local anvilLobes = band(parent, "SeparateStormAnvil", anvilTop,
			Vector3.new(245, 58, 185) * spec.scale, anvilPalette, 300 + idx * 29)
		if anvilLobes[1] then
			banks[#banks + 1] = { lobe = anvilLobes[1], color = anvilLobes[1].Color }
		end
	end

	local vortexRings = {}
	for _, r in buildStormVortex(
		parent, "WideStormVortex",
		Vector3.new(-138, altitude(2980), -295),
		154, 22, 210, 12, 2401
	) do
		table.insert(vortexRings, r)
	end
	for _, r in buildStormVortex(
		parent, "SlenderStormVortex",
		Vector3.new(128, altitude(3110), -288),
		90, 14, 232, 13, 2402
	) do
		table.insert(vortexRings, r)
	end

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
	local trunkColor = rgb(104, 62, 72)
	local sakuraMain = rgb(252, 134, 172)
	local sakuraLight = rgb(255, 182, 208)
	local sakuraDeep = rgb(232, 96, 142)

	local mainTree = natureAsset(tree, "BroadleafTree", "SakuraPrimary", baseCf, scale * 1.25, function(d)
		if d:IsA("MeshPart") then
			d.TextureID = ""
			if d.Name == "leaves_geom" then
				d.Color = sakuraMain
				d.Material = plastic
			else
				d.Color = trunkColor
				d.Material = woodMat
			end
		end
	end)

	if mainTree then
		local leaves = mainTree:FindFirstChild("leaves_geom", true)
		if leaves and leaves:IsA("MeshPart") then
			local upperCrown = leaves:Clone()
			upperCrown.Name = "BlossomHighlightCrown"
			upperCrown.Size = leaves.Size * Vector3.new(0.84, 0.78, 0.84)
			upperCrown.CFrame = leaves.CFrame * CFrame.new(0, 4.2 * scale, 0) * CFrame.Angles(0.08, 1.8, -0.06)
			upperCrown.Color = sakuraLight
			upperCrown.Parent = tree

			local sideBough = leaves:Clone()
			sideBough.Name = "BlossomLowerBough"
			sideBough.Size = leaves.Size * Vector3.new(0.76, 0.68, 0.76)
			sideBough.CFrame = leaves.CFrame * CFrame.new(5.5 * scale, -2.2 * scale, -3.5 * scale) * CFrame.Angles(-0.1, -1.2, 0.12)
			sideBough.Color = sakuraDeep
			sideBough.Parent = tree
		end
	end

	for i = 1, 4 do
		local a = (i - 1) * math.pi / 2 + 0.4
		natureAsset(tree, "Flower", "RootBlossom",
			baseCf * CFrame.new(math.cos(a) * 4.5 * scale, 0.2 * scale, math.sin(a) * 4.5 * scale) * CFrame.Angles(0, a, 0),
			1.35 * scale,
			function(d)
				if d.Name == "PetalCorolla" then d.Color = i % 2 == 0 and sakuraLight or sakuraMain end
			end)
	end
	tree.WorldPivot = baseCf
	return tree
end

local function buildWindChimeRuin(parent, baseCf, scale, chimeList)
	local shrine = model(parent, "WindChimeRuin")
	local masonry = rgb(228, 198, 168)
	local sandstone = rgb(188, 138, 108)
	local timber = rgb(116, 68, 64)
	local gold = rgb(244, 192, 86)
	local ribbonColor = rgb(252, 124, 148)

	clonePalacePodium(shrine, "ShrinePlinth", baseCf, 0.52 * scale, masonry, gold, sandstone, masonry, gold)
	clonePalaceLantern(shrine, baseCf * CFrame.new(-4.5 * scale, 1.2 * scale, 3.5 * scale), 1.45 * scale, rgb(255, 214, 138))

	for _, side in { -1, 1 } do
		local colX = (side == -1 and 0 or 18) * scale
		local colH = (side == -1 and 25 or 21) * scale
		part(shrine, "PillarBase", Vector3.new(6.8, 2.8, 6.8) * scale, baseCf * CFrame.new(colX, 2.4 * scale, 0), sandstone, sandstoneMat)
		column(shrine, "ShrinePillar", (baseCf * CFrame.new(colX, 2.8 * scale + colH * 0.5, 0)).Position, 4.6 * scale, colH, masonry, limestoneMat)
		part(shrine, "PillarCapital", Vector3.new(7.4, 2.6, 7.4) * scale, baseCf * CFrame.new(colX, 3.2 * scale + colH, 0), gold, metalMat)
	end

	part(shrine, "CrossBeam", Vector3.new(28, 2.4, 3.6) * scale, baseCf * CFrame.new(9 * scale, 25.5 * scale, 0), timber, woodMat)
	part(shrine, "UpperRidgeBeam", Vector3.new(31, 1.6, 4.4) * scale, baseCf * CFrame.new(9 * scale, 27.2 * scale, 0), gold, metalMat)
	fleetShape(shrine, "LotusPetal", "WestEaveFinial",
		baseCf * CFrame.new(-6.5 * scale, 28.2 * scale, 0) * CFrame.Angles(0, 0, 0.65),
		Vector3.new(1.8, 3.8, 6.5) * scale, gold, metalMat)
	fleetShape(shrine, "LotusPetal", "EastEaveFinial",
		baseCf * CFrame.new(24.5 * scale, 28.2 * scale, 0) * CFrame.Angles(0, math.pi, 0.65),
		Vector3.new(1.8, 3.8, 6.5) * scale, gold, metalMat)

	for i = 1, 4 do
		local xOff = (2.2 + i * 3.6) * scale
		local topPos = (baseCf * CFrame.new(xOff, 24.2 * scale, 0)).Position
		local chimeLen = (8.2 + (i % 2) * 3.0) * scale
		local chimeModel = model(shrine, "HangingWindChime")
		local pivotCf = CFrame.new(topPos)

		span(chimeModel, "ChimeCord", topPos, topPos + Vector3.new(0, -3.2 * scale, 0), 0.28 * scale, gold, metalMat)
		fleetShape(chimeModel, "DockRim", "ChimeCanopyRing",
			CFrame.new(topPos + Vector3.new(0, -3.2 * scale, 0)) * CFrame.Angles(0, 0, math.pi / 2),
			Vector3.new(0.45, 3.8, 3.8) * scale, gold, metalMat)
		for t = -1, 1, 2 do
			column(chimeModel, "GoldenTube",
				topPos + Vector3.new(t * 0.65 * scale, -(3.4 + chimeLen * 0.5) * scale, 0),
				0.82 * scale, chimeLen, gold, metalMat)
		end
		fleetShape(chimeModel, "Star", "ChimeStarOrnament",
			CFrame.new(topPos + Vector3.new(0, -(4.2 + chimeLen) * scale, 0)) * CFrame.Angles(math.pi / 2, 0, 0),
			Vector3.new(0.35, 2.8, 2.8) * scale, gold, neon)
		part(chimeModel, "ChimeTag", Vector3.new(0.32, 5.2, 1.65) * scale,
			CFrame.new(topPos + Vector3.new(0, -(7.6 + chimeLen) * scale, 0)), ribbonColor, neon)

		chimeModel.WorldPivot = pivotCf
		table.insert(chimeList, { model = chimeModel, origin = pivotCf, phase = i * 1.1 })
	end
	shrine.WorldPivot = baseCf
	return shrine
end

local function buildBrokenStoneBridge(parent, startPos, finishPos, seed)
	local bridge = model(parent, "BrokenStoneBridge")
	local masonry = rgb(224, 194, 164)
	local sandstone = rgb(182, 134, 106)
	local darkStone = rgb(134, 96, 108)
	local gold = rgb(236, 182, 82)
	local roots = rgb(108, 70, 76)

	local delta = finishPos - startPos
	local totalLen = delta.Magnitude
	local dir = delta.Unit
	local segLen = totalLen * 0.35

	for idx, side in { -1, 1 } do
		local anchorPos = side == -1 and startPos or finishPos
		local inward = side == -1 and dir or -dir
		local segCenter = anchorPos + inward * (segLen * 0.5)
		local segCf = CFrame.lookAt(segCenter, segCenter + inward)

		part(bridge, "BridgeDeck", Vector3.new(13.5, 3.6, segLen), segCf, masonry, limestoneMat)
		part(bridge, "DeckCornice", Vector3.new(14.6, 1.1, segLen * 0.98), segCf * CFrame.new(0, 1.6, 0), sandstone, sandstoneMat)
		part(bridge, "GoldInlayRoad", Vector3.new(3.2, 0.4, segLen * 0.92), segCf * CFrame.new(0, 2.0, 0), gold, metalMat)

		for _, railSide in { -1, 1 } do
			part(bridge, "Parapet", Vector3.new(1.6, 2.8, segLen * 0.9),
				segCf * CFrame.new(railSide * 5.6, 3.2, -segLen * 0.03), masonry, limestoneMat)
			for post = 1, 3 do
				local zOff = (post - 2) * segLen * 0.34
				part(bridge, "BalustradePost", Vector3.new(2.4, 4.2, 2.4),
					segCf * CFrame.new(railSide * 5.6, 3.8, zOff), sandstone, sandstoneMat)
				part(bridge, "PostFinial", Vector3.new(1.8, 1.8, 1.8),
					segCf * CFrame.new(railSide * 5.6, 6.2, zOff), gold, metalMat, ball)
			end
		end

		local tipCf = CFrame.lookAt(anchorPos + inward * (segLen + 3.2), anchorPos + inward * (segLen + 10))
			* CFrame.Angles(-0.16, idx * 0.22, side * 0.1)
		part(bridge, "BrokenSpanTip", Vector3.new(11.2, 3.2, 8.2), tipCf, darkStone, slate)
		natureAsset(bridge, "Boulder", "ChasmRubble", tipCf * CFrame.new(2.2, 1.8, 0), 1.45, function(d)
			if d:IsA("MeshPart") then d.TextureID = "" end
			d.Color = sandstone
			d.Material = sandstoneMat
		end)
		natureAsset(bridge, "Fern", "BridgeOvergrowth", segCf * CFrame.new(3.2, 2.2, 4), 1.35)

		for p = 1, 2 do
			local pierFrac = p == 1 and 0.32 or 0.76
			local pierTop = anchorPos + inward * (segLen * pierFrac)
			local pierH = p == 1 and 28 or 20
			column(bridge, "BridgePier", pierTop + Vector3.new(0, -pierH * 0.5 - 1.5, 0), 5.8, pierH, darkStone, slate)
			part(bridge, "PierCapital", Vector3.new(7.8, 2.4, 7.8), CFrame.new(pierTop + Vector3.new(0, -2.2, 0)), sandstone, sandstoneMat)
			part(bridge, "ArchRib", Vector3.new(9.2, 4.8, 15),
				CFrame.lookAt(pierTop + inward * 6 + Vector3.new(0, -5.5, 0), pierTop + inward * 14)
					* CFrame.Angles(0.42, 0, 0), masonry, limestoneMat)
		end

		local rootStart = anchorPos + inward * (segLen * 0.82) + Vector3.new(0, -3, 0)
		local rootMid = rootStart + Vector3.new(side * 2.5, -16 - seed % 5, 2)
		span(bridge, "BridgeRoot", rootStart, rootMid, 1.6, roots, woodMat)
		span(bridge, "BridgeRootTip", rootMid, rootMid + Vector3.new(-side * 1.5, -12, -1.5), 0.85, roots, woodMat)
	end
	return bridge
end

local function skyIsles(parent)
	local basaltCol = rgb(92, 62, 82)
	local cliffCol = rgb(198, 128, 92)
	local mossCol = rgb(118, 142, 104)
	local sandstoneCol = rgb(184, 136, 102)
	local ivoryCol = rgb(238, 220, 186)
	local goldCol = rgb(242, 182, 74)
	local roots = rgb(110, 73, 79)

	local islandSpecs = {
		{ km = 4180, pos = Vector3.new(-105, altitude(4180), -252), width = 62, yaw = 0.35, temple = false, ruin = true },
		{ km = 4520, pos = Vector3.new(112, altitude(4520), -258), width = 96, yaw = -0.42, temple = false, ruin = false },
		{ km = 4780, pos = Vector3.new(-262, altitude(4780), 28), width = 72, yaw = 1.45, temple = false, ruin = true },
		{ km = 4960, pos = Vector3.new(-118, altitude(4960), -255), width = 134, yaw = 0.52, temple = true, ruin = true },
		{ km = 5020, pos = Vector3.new(258, altitude(5020), -24), width = 82, yaw = -1.35, temple = false, ruin = false },
		{ km = 5060, pos = Vector3.new(115, altitude(5060), -248), width = 102, yaw = -0.38, temple = false, ruin = true },
		{ km = 5480, pos = Vector3.new(-88, altitude(5480), -265), width = 74, yaw = 0.25, temple = false, ruin = false },
	}
	local islandPositions = {}
	local chimes = {}

	for i, spec in islandSpecs do
		local p = spec.pos
		islandPositions[i] = p
		local temple = spec.temple
		local island = model(parent, temple and "CloudTempleIsland" or "ForgottenSkyIsle")
		local cf = CFrame.new(p) * CFrame.Angles(0, spec.yaw, 0)
		local scale = math.clamp(spec.width / 128, 0.48, 1.05)

		buildSculptedIslandTerrain(island, cf, scale, {
			basalt = basaltCol,
			cliff = cliffCol,
			moss = mossCol,
			sandstone = sandstoneCol,
			ivory = ivoryCol,
			gold = goldCol,
			cloudColor = rgb(255, 224, 192),
			cloudShadow = rgb(218, 172, 168),
			cloudTransparency = 0.16,
		}, temple or spec.ruin)

		local topY = 13.5 * scale
		for j = 1, 3 do
			local a = (j - 1) * math.pi * 2 / 3 + i * 0.5
			natureAsset(island, "Boulder", "SunsetBoulder",
				cf * CFrame.new(math.cos(a) * 26 * scale, topY - 1 * scale, math.sin(a) * 22 * scale) * CFrame.Angles(0, a, 0),
				1.45 * scale)
			natureAsset(island, "Fern", "SunsetFern",
				cf * CFrame.new(math.cos(a) * 22 * scale, topY, math.sin(a) * 18 * scale),
				1.3 * scale)
			local start = (cf * CFrame.new((j - 2) * 22 * scale, -8 * scale, 28 * scale)).Position
			local elbow = start + Vector3.new(4, -18 * scale - j * 3, 2)
			span(island, "HangingRoot", start, elbow, 2.2 * scale, roots, woodMat)
			span(island, "RootTip", elbow, elbow + Vector3.new(j * 2 - 4, -14 * scale, 2), 1.1 * scale, roots, woodMat)
		end

		if i == 2 or i == 4 or i == 5 or i == 6 or i == 7 then
			local treeSpot = cf * CFrame.new(-28 * scale, topY, -12 * scale) * CFrame.Angles(0, i * 1.1, 0)
			buildBlossomTree(island, treeSpot, math.clamp(scale * 1.15, 0.78, 1.25))
		end

		if i == 2 or i == 5 or i == 6 then
			local chimeSpot = cf * CFrame.new(12 * scale, topY, -6 * scale)
			buildWindChimeRuin(island, chimeSpot, math.clamp(scale * 1.05, 0.78, 1.12), chimes)
		end

		if i ~= 1 then
			local lipCf = cf * CFrame.new(48 * scale, topY - 2 * scale, 6 * scale) * CFrame.Angles(0, 0.25, 0)
			local drop = temple and 132 or (72 + i * 8)
			attachSculptedWaterfall(island, lipCf, drop, scale * 1.15,
				rgb(78, 172, 224), rgb(208, 238, 252), rgb(244, 216, 208))
		end
		island.WorldPivot = cf
	end

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
		local anchorCf = CFrame.new(pair.finish + Vector3.new(0, -10, 0)) * CFrame.Angles(0, idx * 0.9, 0)
		local anchorIsle = model(parent, "BridgeAnchorIsle")
		buildSculptedIslandTerrain(anchorIsle, anchorCf, 0.42, {
			basalt = basaltCol,
			cliff = cliffCol,
			moss = mossCol,
			sandstone = sandstoneCol,
			ivory = ivoryCol,
			gold = goldCol,
			cloudColor = rgb(255, 224, 192),
			cloudTransparency = 0.2,
		}, idx == 1)
		if idx == 2 then
			buildBlossomTree(anchorIsle, anchorCf * CFrame.new(4, 7, -4), 0.82)
		end
		anchorIsle.WorldPivot = anchorCf
	end

	local distantSpecs = {
		{ km = 4120, angle = -1.25, radius = 415, width = 42, waterfall = false },
		{ km = 4420, angle = -1.85, radius = 438, width = 50, waterfall = true },
		{ km = 4720, angle = -1.48, radius = 425, width = 38, waterfall = false },
		{ km = 4920, angle = -1.62, radius = 412, width = 52, waterfall = true },
		{ km = 5140, angle = -0.15, radius = 420, width = 44, waterfall = true },
		{ km = 5320, angle = -1.42, radius = 435, width = 48, waterfall = true },
		{ km = 5680, angle = -1.75, radius = 445, width = 40, waterfall = false },
		{ km = 5890, angle = -1.32, radius = 425, width = 46, waterfall = true },
	}
	for idx, spec in distantSpecs do
		local pos = Vector3.new(math.cos(spec.angle) * spec.radius, altitude(spec.km), math.sin(spec.angle) * spec.radius)
		local cf = CFrame.new(pos) * CFrame.Angles(0, spec.angle, 0)
		local distIsle = model(parent, "DistantSkyIslet")
		local sc = math.clamp(spec.width / 128, 0.32, 0.46)
		buildSculptedIslandTerrain(distIsle, cf, sc, {
			basalt = basaltCol,
			cliff = cliffCol,
			moss = mossCol,
			sandstone = sandstoneCol,
			ivory = ivoryCol,
			gold = goldCol,
		}, idx % 2 == 0)
		if spec.waterfall then
			attachSculptedWaterfall(distIsle, cf * CFrame.new(42 * sc, 5 * sc, 0), 54, sc * 1.1,
				rgb(84, 172, 225), rgb(198, 232, 248), rgb(242, 214, 206))
		end
		distIsle.WorldPivot = cf
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
	local astralObsidian = rgb(38, 36, 72)
	local astralSlate = rgb(62, 56, 108)
	local bioTeal = rgb(58, 162, 178)
	local crystalColors = {
		rgb(218, 92, 255),
		rgb(88, 232, 255),
		rgb(156, 114, 255),
		rgb(255, 128, 224),
	}

	buildSculptedIslandTerrain(island, cf, scale * 0.78, {
		basalt = astralObsidian,
		cliff = astralSlate,
		moss = bioTeal,
		turfMat = slate,
		cloudColor = rgb(86, 72, 152),
		cloudShadow = rgb(54, 118, 164),
		cloudTransparency = 0.24,
	}, false)

	local clusterSpecs = {
		{ pos = Vector3.new(0, 16, 0), rot = Vector3.new(0, 0, 0), sc = 1.05, col = 2 },
		{ pos = Vector3.new(-22, 14, -8), rot = Vector3.new(0.16, 1.2, 0.18), sc = 0.72, col = 1 },
		{ pos = Vector3.new(24, 15, 6), rot = Vector3.new(-0.14, -1.1, -0.2), sc = 0.76, col = 3 },
		{ pos = Vector3.new(4, 12, 18), rot = Vector3.new(0.22, 2.4, -0.12), sc = 0.58, col = 4 },
	}
	for _, cs in clusterSpecs do
		local cColor = crystalColors[cs.col]
		local cCf = cf * CFrame.new(cs.pos * scale) * CFrame.Angles(cs.rot.X, cs.rot.Y, cs.rot.Z)
		local cluster = landmark(island, "Cosmic", cCf, cs.sc * scale)
		if cluster then
			cluster.Name = "FacetedCrystalCluster"
			for _, d in cluster:GetDescendants() do
				if d:IsA("BasePart") then
					if d.Name == "Astral" then
						d.Color = astralObsidian
						d.Material = slate
					elseif d.Name == "Violet" then
						d.Color = cColor:Lerp(astralSlate, 0.35)
						d.Material = glassMat
					elseif d.Name == "Crystal" then
						d.Color = cColor
						d.Material = neon
					end
				end
			end
		end
	end

	for i = 1, 4 do
		local a = (i - 1) * math.pi / 2 + 0.5
		local spot = cf * CFrame.new(math.cos(a) * 24 * scale, 10 * scale, math.sin(a) * 20 * scale)
		natureAsset(island, "Flower", "BioluminescentFlora", spot, 1.45 * scale, function(d)
			if d.Name == "PetalCorolla" then
				d.Color = crystalColors[(i % #crystalColors) + 1]
				d.Material = neon
			elseif d.Name == "CurvedStemAndLeaves" then
				d.Color = bioTeal
			end
		end)
	end

	for i = 1, 4 do
		local a = (i - 1) * math.pi / 2 + random:NextNumber(-0.2, 0.2)
		local satDist = (58 + i * 7) * scale
		local satOrigin = cf * CFrame.new(math.cos(a) * satDist, (6 + (i % 2) * 12) * scale, math.sin(a) * satDist)
		local sat = model(island, "CrystalSatellite")
		local cCol = crystalColors[(i % #crystalColors) + 1]
		local satMesh = landmark(sat, "Cosmic", satOrigin * CFrame.Angles(0.15, i * 0.8, -0.12), 0.24 * scale)
		if satMesh then
			for _, d in satMesh:GetDescendants() do
				if d:IsA("BasePart") and d.Name == "Crystal" then
					d.Color = cCol
					d.Material = neon
				end
			end
		end
		fleetShape(sat, "DockRim", "SatOrbitalHalo",
			satOrigin * CFrame.Angles(0.3, i, math.pi / 2),
			Vector3.new(0.35, 14, 14) * scale, cCol, neon)
		sat.WorldPivot = satOrigin
		table.insert(satellites, { model = sat, origin = satOrigin, phase = seed + i * 1.3 })
	end

	island.WorldPivot = cf
	return island
end

local function buildFloatingObservatory(parent, cf, scale, armillaryRings)
	local obs = model(parent, "FloatingObservatory")
	local astralObsidian = rgb(40, 38, 74)
	local astralSlate = rgb(66, 62, 114)
	local bioTeal = rgb(68, 164, 182)
	local marble = rgb(238, 230, 216)
	local gold = rgb(246, 194, 84)
	local royalBanner = rgb(42, 86, 188)
	local cyanGlow = rgb(104, 238, 255)

	buildSculptedIslandTerrain(obs, cf, scale * 0.86, {
		basalt = astralObsidian,
		cliff = astralSlate,
		moss = bioTeal,
		sandstone = astralSlate,
		ivory = marble,
		gold = gold,
		turfMat = slate,
		cloudColor = rgb(84, 74, 156),
		cloudShadow = rgb(52, 112, 162),
		cloudTransparency = 0.22,
	}, true)

	local terraceCf = cf * CFrame.new(0, 12.5 * scale, 0)
	clonePalacePodium(obs, "ObservatoryCompassTerrace", terraceCf, 2.35 * scale,
		marble, gold, astralObsidian, marble, cyanGlow)

	for i = 1, 4 do
		local a = (i - 1) * math.pi / 2 + math.pi / 4
		clonePalaceLantern(obs,
			terraceCf * CFrame.new(math.cos(a) * 24 * scale, 1.5 * scale, math.sin(a) * 24 * scale),
			1.8 * scale, cyanGlow)
	end

	for _, xSide in { -1, 1 } do
		local bannerCf = cf * CFrame.new(xSide * 22 * scale, 4 * scale, 32 * scale)
		part(obs, "BannerTrim", Vector3.new(7.5, 18, 1.2) * scale, bannerCf, gold, metalMat)
		part(obs, "AstralBanner", Vector3.new(6.2, 16.5, 1.5) * scale, bannerCf, royalBanner, plastic)
		fleetShape(obs, "Star", "BannerStar",
			bannerCf * CFrame.new(0, 1 * scale, 0.9 * scale) * CFrame.Angles(math.pi / 2, 0, 0),
			Vector3.new(0.45, 4.4, 4.4) * scale, gold, neon)
	end

	local sphereCenterCf = cf * CFrame.new(0, 52 * scale, -2 * scale)
	column(obs, "ArmillaryPedestal", (cf * CFrame.new(0, 24 * scale, -2 * scale)).Position, 11 * scale, 18 * scale, marble, marbleMat)
	fleetShape(obs, "DockRim", "PedestalGoldCollar",
		cf * CFrame.new(0, 33 * scale, -2 * scale) * CFrame.Angles(0, 0, math.pi / 2),
		Vector3.new(1.2, 16, 16) * scale, gold, metalMat)

	part(obs, "AstralCoreStar", Vector3.one * (8.2 * scale), sphereCenterCf, cyanGlow, neon, ball)
	fleetShape(obs, "Star", "AstralStarHorizontal",
		sphereCenterCf, Vector3.new(0.8, 13.5, 13.5) * scale, gold, neon)
	fleetShape(obs, "Star", "AstralStarVertical",
		sphereCenterCf * CFrame.Angles(math.pi / 2, 0, 0), Vector3.new(0.8, 13.5, 13.5) * scale, cyanGlow, neon)

	local ringSpecs = {
		{ diameter = 48 * scale, thickness = 1.35 * scale, template = "SaturnRing", speed = Vector3.new(0.28, 0.42, 0.12) },
		{ diameter = 38 * scale, thickness = 1.15 * scale, template = "DockRim", speed = Vector3.new(-0.36, 0.22, 0.38) },
		{ diameter = 28 * scale, thickness = 0.95 * scale, template = "DockRim", speed = Vector3.new(0.18, -0.48, -0.26) },
	}
	for rIdx, rSpec in ringSpecs do
		local ringModel = model(obs, "ArmillaryRing_" .. rIdx)
		local ringOrigin = sphereCenterCf * CFrame.Angles(0.38 * rIdx, 0.52 * rIdx, 0.24 * rIdx)

		fleetShape(ringModel, rSpec.template, "PrimaryGyroRing",
			ringOrigin,
			Vector3.new(rSpec.thickness, rSpec.diameter, rSpec.diameter),
			gold, metalMat)
		fleetShape(ringModel, "DockRim", "InnerBezelRing",
			ringOrigin,
			Vector3.new(rSpec.thickness * 1.3, rSpec.diameter * 0.94, rSpec.diameter * 0.94),
			rIdx == 2 and cyanGlow or gold, rIdx == 2 and neon or metalMat)

		local r = rSpec.diameter * 0.5
		for n = 1, 4 do
			local a = (n - 1) * math.pi / 2
			local nodeCf = ringOrigin * CFrame.new(0, math.cos(a) * r, math.sin(a) * r)
			part(ringModel, "AstrolabeNode", Vector3.one * (2.4 * scale), nodeCf, n % 2 == 0 and cyanGlow or gold, neon, ball)
		end

		ringModel.WorldPivot = ringOrigin
		table.insert(armillaryRings, { model = ringModel, origin = ringOrigin, speed = rSpec.speed })
	end

	obs.WorldPivot = cf
	return obs
end

local function buildDistantCosmicArch(parent, cf, scale)
	local arch = model(parent, "DistantCosmicArch")
	local stone = rgb(66, 62, 118)
	local runeGlow = rgb(104, 232, 255)
	local violetGlow = rgb(206, 112, 255)
	local nebulaDark = rgb(52, 46, 94)

	local sculptedArch = landmark(arch, "HorizonArch", cf, 0.22 * scale)
	if sculptedArch then
		sculptedArch.Name = "SculptedAstralArch"
		for _, d in sculptedArch:GetDescendants() do
			if d:IsA("BasePart") then
				if d.Name == "HorizonStone" then
					d.Color = stone
					d.Material = slate
				elseif d.Name == "HorizonGold" then
					d.Color = runeGlow
					d.Material = neon
				elseif d.Name == "VistaIvory" then
					d.Color = rgb(78, 72, 134)
				elseif d.Name == "VistaShadow" then
					d.Color = nebulaDark
				end
			end
		end
	end

	local crown = landmark(arch, "Cosmic", cf * CFrame.new(0, 18 * scale, 0), 0.18 * scale)
	if crown then
		crown.Name = "ArchCrystalCrown"
		for _, d in crown:GetDescendants() do
			if d:IsA("BasePart") and d.Name == "Crystal" then
				d.Color = violetGlow
				d.Material = neon
			end
		end
	end
	arch.WorldPivot = cf
	return arch
end

local function exosphere(parent)
	local random = Random.new(607)
	local satellites = {}
	local armillaryRings = {}

	buildCosmicCrystalIsland(parent, CFrame.new(-115, altitude(6960), -248) * CFrame.Angles(0, 0.38, 0), 1.04, satellites, 610)
	buildCosmicCrystalIsland(parent, CFrame.new(258, altitude(6980), -22) * CFrame.Angles(0, -1.25, 0), 0.85, satellites, 620)
	buildCosmicCrystalIsland(parent, CFrame.new(-88, altitude(7480), -262) * CFrame.Angles(0, 0.45, 0), 0.84, satellites, 630)

	buildFloatingObservatory(parent, CFrame.new(118, altitude(7040), -242) * CFrame.Angles(0, -0.42, 0), 1.02, armillaryRings)

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

	for i = 1, 9 do
		local t = (i - 1) / 8
		local arcPos = Vector3.new(-155 + t * 285, altitude(6720 + t * 560) + math.sin(t * math.pi) * 28, -315 - math.sin(t * math.pi) * 45)
		local cf = CFrame.new(arcPos) * CFrame.Angles(0, i * 0.5, 0)
		local pebble = model(parent, "CosmicArcStone")
		local sc = 0.55 + (1 - math.abs(t - 0.5)) * 0.45
		local ringCol = i % 2 == 0 and rgb(92, 232, 255) or rgb(216, 112, 255)
		local crag = landmark(pebble, "Cosmic", cf, 0.2 * sc)
		if crag then
			for _, d in crag:GetDescendants() do
				if d:IsA("BasePart") and d.Name == "Crystal" then
					d.Color = ringCol
					d.Material = neon
				end
			end
		end
		fleetShape(pebble, "SaturnRing", "GlowRing",
			cf * CFrame.Angles(0.25, 0, math.pi / 2),
			Vector3.new(0.4, 15, 15) * sc, ringCol, neon)
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
	local ivory = rgb(246, 236, 214)
	local gold = rgb(236, 186, 82)
	local warmStone = rgb(186, 174, 156)
	local grass = rgb(94, 152, 108)
	local cyanCrystal = rgb(88, 236, 255)
	local deepCyan = rgb(44, 182, 232)

	buildSculptedIslandTerrain(gate, cf, scale * 0.68, {
		basalt = warmStone,
		cliff = rgb(214, 198, 176),
		moss = grass,
		rockMat = limestoneMat,
		cliffMat = limestoneMat,
		cloudColor = rgb(252, 236, 198),
		cloudShadow = rgb(222, 198, 176),
		cloudTransparency = 0.08,
	}, false)

	local daisCf = cf * CFrame.new(0, 9.5 * scale, 0)
	clonePalacePodium(gate, "SanctuaryMarbleDais", daisCf, 2.15 * scale,
		ivory, gold, deepCyan, ivory, cyanCrystal)

	local archClone = landmark(gate, "HorizonArch", daisCf * CFrame.new(0, 6 * scale, 0), 0.26 * scale)
	if archClone then
		archClone.Name = "SculptedSanctuaryArchway"
		for _, d in archClone:GetDescendants() do
			if d:IsA("BasePart") then
				if d.Name == "HorizonStone" then
					d.Color = ivory
					d.Material = limestoneMat
				elseif d.Name == "HorizonGold" then
					d.Color = gold
					d.Material = metalMat
				elseif d.Name == "VistaIvory" or d.Name == "VistaShadow" then
					d:Destroy()
				end
			end
		end
	end

	for _, side in { -1, 1 } do
		natureAsset(gate, "BroadleafTree", "SanctuaryTree",
			daisCf * CFrame.new(side * 24 * scale, 0.5 * scale, -6 * scale) * CFrame.Angles(0, side * 0.8, 0),
			0.68 * scale)
		natureAsset(gate, "Fern", "SanctuaryFern",
			daisCf * CFrame.new(side * 18 * scale, 1.0 * scale, 8 * scale),
			1.25 * scale)
		natureAsset(gate, "Flower", "SanctuaryFlower",
			daisCf * CFrame.new(side * 15 * scale, 1.2 * scale, 10 * scale),
			1.35 * scale)
		clonePalaceLantern(gate,
			daisCf * CFrame.new(side * 14 * scale, 1.2 * scale, 14 * scale),
			1.65 * scale, cyanCrystal)
	end

	local crystalOrigin = daisCf * CFrame.new(0, 18.5 * scale, 3 * scale)
	local diamond = model(gate, "SuspendedDiamondCrystal")
	local crystalMesh = landmark(diamond, "Cosmic", crystalOrigin, 0.24 * scale)
	if crystalMesh then
		crystalMesh.Name = "FacetedSanctuaryCrystal"
		for _, d in crystalMesh:GetDescendants() do
			if d:IsA("BasePart") then
				if d.Name == "Crystal" then
					d.Color = cyanCrystal
					d.Material = neon
				elseif d.Name == "Violet" then
					d.Color = deepCyan
					d.Material = glassMat
				elseif d.Name == "Astral" then
					d.Color = gold
					d.Material = metalMat
				end
			end
		end
	end
	fleetShape(diamond, "DockRim", "CrystalHaloHorizontal",
		crystalOrigin * CFrame.Angles(0, 0, math.pi / 2),
		Vector3.new(0.65, 19.5, 19.5) * scale, gold, neon)
	fleetShape(diamond, "DockRim", "CrystalHaloInclined",
		crystalOrigin * CFrame.Angles(0.65, 0.4, 0),
		Vector3.new(0.55, 16.5, 16.5) * scale, cyanCrystal, neon)
	fleetShape(diamond, "Star", "CrystalCrestStar",
		crystalOrigin * CFrame.new(0, 11.5 * scale, 0) * CFrame.Angles(math.pi / 2, 0, 0),
		Vector3.new(0.55, 5.2, 5.2) * scale, gold, neon)
	diamond.WorldPivot = crystalOrigin
	table.insert(gateCrystals, { model = diamond, origin = crystalOrigin })

	attachSculptedWaterfall(gate, daisCf * CFrame.new(0, -1 * scale, 22 * scale), 68 * scale, scale * 1.1,
		rgb(108, 214, 252), rgb(228, 248, 255), rgb(252, 244, 226))

	gate.WorldPivot = cf
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
		{ "HorizonPavilion", Vector3.new(-165, -510, -255), 0.52, -16 },
		{ "HorizonArch", Vector3.new(-195, -455, -295), 0.66, -12 },
		{ "HorizonSpire", Vector3.new(185, -420, -265), 0.58, 22 },
		{ "HorizonPavilion", Vector3.new(265, -345, -35), 0.54, 28 },
		{ "HorizonPavilion", Vector3.new(-145, -325, -265), 0.62, -14 },
		{ "HorizonSpire", Vector3.new(-285, -295, -45), 0.64, -24 },
		{ "HorizonArch", Vector3.new(215, -245, -310), 0.72, 18 },
		{ "HorizonPavilion", Vector3.new(-175, -185, -295), 0.48, -8 },
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

	local routes = {
		{ "CloudSailer", Vector3.new(-85, -335, -225), Vector3.new(42, 6, 30), 84, 0.35, 1.08 },
		{ "CloudKetch", Vector3.new(242, -315, -25), Vector3.new(36, 7, 44), 96, 2.1, 0.98 },
		{ "CloudCutter", Vector3.new(95, -210, -255), Vector3.new(48, 8, 36), 108, 4.2, 0.94 },
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
