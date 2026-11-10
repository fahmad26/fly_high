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

-- A cloud bank has one silhouette and a small, matched set of rounded lobes.
local function band(parent, name, center, size, colors, seed, profile, heading)
	local group = model(parent, name)
	local random = Random.new(seed)
	local angle = math.atan2(center.Z, center.X) + math.pi / 2
	local base = CFrame.new(center) * CFrame.Angles(0, heading or angle + random:NextNumber(-0.18, 0.18), 0)
	local lobes = {}
	local function puff(x, y, z, width, height, depth, color, transparency)
		local shape = part(group, "CloudLobe", size * Vector3.new(width, height, depth),
			base * CFrame.new(size * Vector3.new(x, y, z)), color, plastic, ball)
		shape.Transparency = transparency or 0
		table.insert(lobes, shape)
	end
	local shade, light, body = colors[1], colors[2] or colors[1], colors[3] or colors[1]
	local function veil(offset, width, height, color, transparency)
		local holder = part(group, "MistAnchor", Vector3.one, base * CFrame.new(size * offset), body)
		holder.Transparency = 1
		local sprite = Instance.new("BillboardGui")
		sprite.Name = "SoftCloudMist"
		sprite.Size = UDim2.fromScale(width, height)
		sprite.MaxDistance = 2600
		sprite.LightInfluence = 0.18
		sprite.Parent = holder
		local texture = Instance.new("ImageLabel")
		texture.Name = "MistTexture"
		texture.Size = UDim2.fromScale(1, 1)
		texture.BackgroundTransparency = 1
		texture.Image = "rbxasset://textures/particles/smoke_main.dds"
		texture.ImageColor3 = color
		texture.ImageTransparency = transparency
		texture.Parent = sprite
	end

	if profile == "mist" then
		veil(Vector3.zero, size.X, size.Y * 1.55, body:Lerp(light, 0.35), 0.50)
	elseif profile == "stormAnvil" then
		-- Broad contiguous body, leeward shelf and a scalloped underside feeding the funnel.
		puff(-0.03, 0.04, 0, 0.90, 0.75, 0.92, body)
		puff(0.28, 0.04, -0.04, 0.58, 0.62, 0.76, body)
		puff(-0.30, 0.21, 0.02, 0.48, 0.91, 0.81, body:Lerp(light, 0.17))
		puff(-0.12, 0.28, -0.04, 0.49, 0.91, 0.78, body:Lerp(light, 0.23))
		puff(0.11, 0.19, 0.07, 0.48, 0.74, 0.70, body:Lerp(light, 0.15))
		puff(-0.20, -0.20, 0.13, 0.50, 0.56, 0.65, body:Lerp(shade, 0.26))
		puff(0.10, -0.21, 0.10, 0.58, 0.57, 0.65, body:Lerp(shade, 0.30))
		veil(Vector3.new(-0.05, -0.19, 0.21), size.X * 0.69, size.Y, light, 0.86)
	elseif profile == "stormWake" then
		-- One low, stretched wake with a fading tail where the funnel meets it.
		puff(0.12, 0.19, 0.02, 0.41, 0.69, 0.53, body, 0.34)
		puff(-0.06, 0.05, 0.08, 0.59, 0.53, 0.51, body:Lerp(shade, 0.18), 0.63)
		veil(Vector3.new(-0.30, -0.03, 0.14), size.X * 1.35, size.Y * 1.28, body, 0.43)
		veil(Vector3.new(0.12, 0.29, -0.01), size.X * 0.90, size.Y * 1.45, light, 0.70)
	elseif profile == "foundation" then
		-- Interlocked tiers: broad shoulders support masonry; a tapered keel breaks the plate silhouette.
		puff(0, 0.04, 0, 0.88, 0.83, 0.82, body)
		puff(-0.29, 0.08, 0.04, 0.44, 0.77, 0.77, body:Lerp(light, 0.22))
		puff(0.30, 0.03, -0.07, 0.46, 0.87, 0.73, body:Lerp(light, 0.16))
		puff(-0.09, -0.24, 0.06, 0.68, 0.90, 0.65, body:Lerp(shade, 0.27))
		puff(0.13, -0.46, -0.03, 0.41, 0.74, 0.46, body:Lerp(shade, 0.40))
		puff(-0.19, 0.21, 0.24, 0.36, 0.47, 0.38, body:Lerp(light, 0.25))
		puff(0.20, 0.17, 0.25, 0.43, 0.51, 0.40, body:Lerp(light, 0.32))
		veil(Vector3.new(-0.06, -0.50, 0.06), size.X * 0.85, size.Y * 1.1, shade, 0.80)
	elseif profile == "wisp" then
		veil(Vector3.new(-0.12, 0.02, 0), size.X * 0.85, size.Y * 1.46, body, 0.24)
		veil(Vector3.new(0.26, -0.12, 0.09), size.X * 0.68, size.Y * 1.06, light, 0.45)
	else
		local crest = random:NextNumber(-0.17, 0.15)
		puff(0, -0.09, 0.04, 0.90, 0.68, 0.84, body:Lerp(shade, 0.21))
		puff(-0.31, 0.00, 0.06, 0.47, 0.55, 0.65, body)
		puff(0.29, 0.04, -0.06, 0.48, 0.68, 0.74, body)
		puff(crest - 0.15, 0.15, -0.12, 0.47, 0.86, 0.77, body:Lerp(light, 0.33))
		puff(crest + 0.14, 0.23, 0.03, 0.52, random:NextNumber(0.79, 0.99), 0.75, body:Lerp(light, 0.39))
		puff(-0.04, -0.02, 0.23, 0.50, 0.58, 0.62, body:Lerp(shade, 0.17))
	end
	group.WorldPivot = base
	return lobes, group
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
		if palette.rockProfile then
			local profile = palette.rockProfile
			local depth = basaltPart.Size.Y
			basaltPart.Size *= profile
			basaltPart.CFrame += Vector3.new(0, (1 - profile.Y) * depth / 2, 0)
		end
		for _, ledge in palette.rockLedges or {} do
			local offset, proportion, lean = table.unpack(ledge)
			local shard = basaltPart:Clone()
			shard.Name = "CliffLedge"
			shard.Size = basaltPart.Size * proportion
			shard.CFrame = cf * CFrame.new(offset * scale) * CFrame.Angles(lean * 0.38, 0.35, lean)
			shard.Color = basaltPart.Color:Lerp(palette.cliff, 0.26)
			shard.Parent = base
		end
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
		local center = cf:PointToWorldSpace(Vector3.new(19, -33, 19) * scale)
		local shadow = palette.cloudShadow or palette.cloudColor
		band(parent, "IslandCloudMist", center, Vector3.new(90, 15, 48) * scale,
			{ shadow, palette.cloudColor, shadow:Lerp(palette.cloudColor, 0.4) }, math.floor(cf.Position.Y), "mist")
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
	carrier.CFrame = lipCf
	carrier.Transparency = 1
	for j = -1, 1 do
		local off = Vector3.new(j * 2.65 * scale, 0, 0)
		local fade = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.29),
			NumberSequenceKeypoint.new(0.32, 0.30 + math.abs(j) * 0.07),
			NumberSequenceKeypoint.new(0.67, 0.47),
			NumberSequenceKeypoint.new(0.86, 0.73),
			NumberSequenceKeypoint.new(1, 1),
		})
		local stream = beam(
			socket(carrier, off, Vector3.new(0, -0.36, 1)),
			socket(carrier, off + Vector3.new(j * 0.72 * scale, -dropHeight * (1 - math.abs(j) * 0.11), 13 * scale),
				Vector3.new(0, -1, 0.10)),
			(3.2 + (1 - math.abs(j)) * 1.25) * scale, 1.8 * scale,
			ColorSequence.new(wColor, fColor), fade, 9 * scale
		)
		stream.LightEmission = 0.22
	end

	local mistCenter = lipCf:PointToWorldSpace(Vector3.new(0, -dropHeight * 0.89, 12 * scale))
	band(parent, "WaterfallMistCloud", mistCenter, Vector3.new(25, 12, 19) * scale,
		{ mColor, fColor, mColor }, math.floor(lipCf.Y), "mist")
end

local dawnRockStyles = {
	{ name = "ReefShelf", profile = Vector3.new(1.16, 0.48, 0.88), rim = Vector3.new(1.14, 0.78, 0.91),
		canopy = false, stone = rgb(157, 171, 157), cliff = rgb(215, 198, 163),
		ledges = { { Vector3.new(-19, -13, 17), Vector3.new(0.62, 0.64, 0.60), -0.07 } } },
	{ name = "TerracedCliff", profile = Vector3.new(0.93, 0.90, 1.03), rim = Vector3.new(1, 1.08, 1),
		stone = rgb(95, 119, 131), cliff = rgb(167, 158, 134),
		ledges = {
			{ Vector3.new(-30, -19, 13), Vector3.new(0.58, 0.65, 0.57), -0.17 },
			{ Vector3.new(16, -29, 19), Vector3.new(0.54, 0.63, 0.51), 0.08 },
		} },
	{ name = "SplitCrag", profile = Vector3.new(0.70, 1.24, 0.89), rim = Vector3.new(0.84, 1.12, 0.92),
		stone = rgb(80, 103, 122), cliff = rgb(161, 154, 135),
		ledges = { { Vector3.new(27, -24, 9), Vector3.new(0.62, 0.88, 0.64), -0.24 } } },
}

local dawnSpillwayStyle = {
	name = "DawnWaterfallIsle",
	profile = Vector3.new(0.86, 1.19, 1.10),
	rim = Vector3.new(0.97, 1.03, 1.10),
	stone = rgb(94, 119, 125),
	cliff = rgb(185, 168, 131),
	ledges = {
		{ Vector3.new(31, -10, 14), Vector3.new(0.61, 0.58, 0.72), 0.12 },
		{ Vector3.new(-22, -28, -12), Vector3.new(0.65, 0.68, 0.55), -0.14 },
	},
}

local function buildFloatingRockIslet(parent, cf, width, hasWaterfall, seed, style)
	if hasWaterfall then style = dawnSpillwayStyle end
	local islet = model(parent, style.name)
	local random = Random.new(seed)
	local scale = math.clamp(width / 108, 0.32, 0.68)

	local terrain = buildSculptedIslandTerrain(islet, cf, scale, {
		basalt = style.stone,
		cliff = style.cliff,
		moss = rgb(80, 148, 86),
		cloudColor = rgb(252, 246, 232),
		cloudShadow = rgb(216, 228, 244),
		rockProfile = style.profile,
		rockLedges = style.ledges,
	}, false)

	if terrain then
		local rim = terrain:FindFirstChild("SculptedCliffRim")
		local moss = terrain:FindFirstChild("Moss")
		if rim then
			rim.Size *= style.rim
			for layer = 1, 2 do
				local stratum = rim:Clone()
				stratum.Name = "WeatheredLimestoneLayer"
				stratum.Size = rim.Size * Vector3.new(1.02 - layer * 0.08, 0.65, 1.03 - layer * 0.08)
				stratum.CFrame = rim.CFrame * CFrame.new((layer - 1) * -4 * scale, (-1 - layer * 5.5) * scale, layer * scale)
				stratum.Color = style.cliff:Lerp(style.stone, 0.15 + layer * 0.18)
				stratum.Material = limestoneMat
				stratum.Parent = terrain
			end
		end
		if moss then
			moss.Size *= Vector3.new(style.rim.X, 1, style.rim.Z)
			local soil = moss:Clone()
			soil.Name = "WeatheredTurfLip"
			soil.Size = moss.Size * Vector3.new(1.012, 0.86, 1.012)
			soil.CFrame = moss.CFrame * CFrame.new(0, -2.3 * scale, 0)
			soil.Color = rgb(124, 131, 94)
			soil.Material = sandstoneMat
			soil.Parent = terrain
		end
	end

	local topY = 12.5 * scale
	if style.canopy ~= false then
		natureAsset(islet, "BroadleafTree", "CanopyTree",
			cf * CFrame.new(-8 * scale, topY, -4 * scale) * CFrame.Angles(0, random:NextNumber(0, 6.28), 0),
			math.clamp(scale * 1.45, 0.55, 0.95))
	end

	if width >= 42 or style.canopy == false then
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
	local headland = landmark(parent, "Dawn", CFrame.new(115, -5, -308) * CFrame.Angles(0, 0.32, 0), 1.24)
	if headland then
		headland.Name = "DawnHeadland"
		local hCf = headland:GetPivot()
		natureAsset(headland, "PalmTree", "HeadlandPalm1", hCf * CFrame.new(-17.4, 17.4, -5) * CFrame.Angles(0.05, 0.8, -0.04), 0.92)
		natureAsset(headland, "PalmTree", "HeadlandPalm2", hCf * CFrame.new(9.9, 16.1, 7.4) * CFrame.Angles(-0.04, 2.4, 0.06), 0.84)
		natureAsset(headland, "BroadleafTree", "HeadlandTree", hCf * CFrame.new(-5, 18.6, 2.5) * CFrame.Angles(0, 1.5, 0), 0.78)
		natureAsset(headland, "Boulder", "HeadlandBoulder", hCf * CFrame.new(22.3, 12.4, -9.9) * CFrame.Angles(0, 0.9, 0), 1.45)
		natureAsset(headland, "Fern", "HeadlandFern", hCf * CFrame.new(-9.9, 17.4, 5), 1.25)
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
		{ km = 1170, x = 193, z = -310, width = 43, yaw = -0.35, waterfall = false },
		{ km = 1210, x = 244, z = -22, width = 46, yaw = -1.35, waterfall = false },
		{ km = 1520, x = 58, z = -262, width = 42, yaw = -0.5, waterfall = false },
		{ km = 1660, x = -134, z = -267, width = 81, yaw = 0.32, waterfall = true },
		{ km = 1890, x = 245, z = -24, width = 44, yaw = -1.4, waterfall = false },
		{ km = 1940, x = -246, z = 22, width = 38, yaw = 1.5, waterfall = false },
	}
	for idx, spec in isletSpecs do
		local cf = CFrame.new(spec.x, altitude(spec.km), spec.z) * CFrame.Angles(0, spec.yaw, 0)
		local style = dawnRockStyles[(idx - 1) % #dawnRockStyles + 1]
		buildFloatingRockIslet(parent, cf, spec.width, spec.waterfall, 900 + idx * 17, style)
	end

	local balloonSpecs = {
		{ pos = Vector3.new(105, altitude(680), -250), yaw = -0.35, scale = 1.54 },
		{ pos = Vector3.new(-180, altitude(1250), -375), yaw = 0.38, scale = 0.88 },
		{ pos = Vector3.new(303, altitude(1320), 72), yaw = -1.25, scale = 0.92 },
		{ pos = Vector3.new(104, altitude(1910), -310), yaw = -0.28, scale = 0.9 },
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

	local cloudColors = { rgb(195, 215, 240), rgb(255, 251, 235), rgb(231, 242, 253) }
	local cloudLayers = {
		{ count = 5, minKm = 360, stepKm = 290, radius = 292, size = Vector3.new(102, 37, 61), phase = 0.57 },
		{ count = 6, minKm = 510, stepKm = 235, radius = 380, size = Vector3.new(155, 22, 82), phase = 0.91, profile = "wisp" },
		{ count = 5, minKm = 620, stepKm = 260, radius = 525, size = Vector3.new(186, 37, 108), phase = 0.22, profile = "mist" },
	}
	local cloudParts = {}
	local seedCounter = 31
	for _, layer in cloudLayers do
		for i = 1, layer.count do
			seedCounter += 1
			local angle = (i - 1) * math.pi * 2 / layer.count + layer.phase
			local y = altitude(layer.minKm + (i - 1) * layer.stepKm)
			local center = Vector3.new(math.cos(angle) * layer.radius, y, math.sin(angle) * layer.radius)
			for _, cloud in band(parent, "CoastalCloudBank", center, layer.size, cloudColors, seedCounter, layer.profile) do
				table.insert(cloudParts, { part = cloud, base = cloud.Transparency })
			end
		end
	end

	local lastCloudTransparency
	return function(km, time)
		local cloudTransparency = math.round(math.clamp((km - 1680) / 520, 0, 1) * 12) / 50
		if cloudTransparency ~= lastCloudTransparency then
			lastCloudTransparency = cloudTransparency
			for _, cloud in cloudParts do cloud.part.Transparency = cloud.base + (1 - cloud.base) * cloudTransparency end
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

local function buildStormVortex(parent, name, basePos, topWidth, bottomWidth, height, seed)
	local vortex = model(parent, name)
	local base = CFrame.new(basePos)
	vortex.WorldPivot = base
	local shade, body, top = rgb(55, 53, 87), rgb(81, 83, 126), rgb(129, 130, 172)
	local function section(t)
		local radius = (bottomWidth + (topWidth - bottomWidth) * t ^ 1.62) / 2
		local center = basePos + Vector3.new(math.sin(t * 2.9) * topWidth * 0.14,
			(t - 0.5) * height, math.sin(t * 3.3) * topWidth * 0.07)
		return center, radius
	end

	-- Closely spaced volumes give the funnel a continuous edge, even in profile.
	local funnel = {}
	for i = 0, 28 do
		local t = i / 28
		local center, radius = section(t)
		local verticalSize = math.min(height * 0.29, 18 + radius * 0.82)
		local tone = shade:Lerp(body, t ^ 0.75)
		local volume = part(vortex, "FunnelVolume", Vector3.new(radius * 2, verticalSize, radius * 1.76),
			CFrame.new(center) * CFrame.Angles(0, 0.2, -0.06 - t * 0.10), tone, plastic, ball)
		table.insert(funnel, { part = volume, tone = tone })
	end
	local crown, _ = section(1)
	local cap = band(vortex, "StormAnvilCrown", crown + Vector3.new(-topWidth * 0.10, height * 0.025, 0),
		Vector3.new(topWidth * 1.78, height * 0.36, topWidth * 1.20),
		{ shade, top, body:Lerp(top, 0.32) }, seed, "stormAnvil", -0.26)
	for _, volume in cap do table.insert(funnel, { part = volume, tone = volume.Color }) end

	-- Wrap a shallow wake around the foot and feather the end into airborne mist.
	local foot = section(0)
	band(vortex, "VortexFootCloud", foot + Vector3.new(-5, 0, 4),
		Vector3.new(bottomWidth * 3.9, height * 0.13, bottomWidth * 2.6),
		{ shade, body, shade:Lerp(body, 0.38) }, seed + 41, "stormWake", 0.58)
	-- One faint band suggests rotation without tracing every tier in neon.
	local carrier = rail(vortex, "WindShearAnchors", basePos)
	carrier.Transparency = 1
	local previous
	for i = 0, 8 do
		local t = i / 8
		local center, radius = section(t)
		local angle = t * 8.5 + seed % 4
		local offset = center - basePos + Vector3.new(math.cos(angle) * radius * 1.04, 0, math.sin(angle) * radius)
		local node = socket(carrier, offset, Vector3.new(-math.sin(angle), 0.7, math.cos(angle)))
		if previous then
			local ribbon = beam(previous, node, 1.5 + t, 1.8 + t,
				ColorSequence.new(rgb(123, 130, 178)), softFade(0.98, 0.76), radius * 0.36)
			ribbon.LightEmission = 0.12
		end
		previous = node
	end
	return { model = vortex, origin = base, phase = seed % 7, funnel = funnel }
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
	local indigo = { rgb(55, 59, 100), rgb(107, 115, 170), rgb(81, 89, 136) }
	local anvilPalette = { rgb(64, 58, 108), rgb(88, 82, 146), rgb(118, 114, 182) }
	local random = Random.new(2020)

	-- Leave a low cloud layer under the flight corridor after the distant ocean fades.
	local undercast = { rgb(46, 46, 82), rgb(85, 80, 116), rgb(67, 63, 103) }
	for i = 1, 10 do
		local angle = (i - 1) * math.pi / 5
		local radius = 480 + (i % 3) * 64
		local center = Vector3.new(math.cos(angle) * radius, altitude(1380 + (i % 4) * 95), math.sin(angle) * radius)
		band(parent, "StormUndercast", center, Vector3.new(475, 164, 220), undercast, 2800 + i, "wisp")
	end

	for i = 1, 9 do
		local angle = (i - 1) * math.pi * 2 / 9 + 0.36 + random:NextNumber(-0.1, 0.1)
		local radius = random:NextNumber(390, 520)
		local y = altitude(2060 + i * 188) + random:NextNumber(-28, 28)
		local position = Vector3.new(math.cos(angle) * radius, y, math.sin(angle) * radius)
		local size = Vector3.new(random:NextNumber(155, 235), random:NextNumber(72, 155), random:NextNumber(110, 168))
		local clouds = band(parent, "ThunderheadCliff", position, size, indigo, i * 19)
		if clouds[1] then
			banks[#banks + 1] = { lobes = clouds, colors = table.create(#clouds) }
			for n, cloud in clouds do banks[#banks].colors[n] = cloud.Color end
		end

		if i % 2 == 0 or i == 3 or i == 9 then
			local origin = position + Vector3.new(0, -68, 0)
			local carrier = rail(parent, "SlantedRainCurtain", origin)
			carrier.Transparency = 1
			rain[#rain + 1] = { part = carrier, origin = origin }
			local wind = Vector3.new(-28 + math.sin(angle) * 21, 0, 10 + math.cos(angle) * 21)
			for j = 1, 13 do
				local offset = Vector3.new(random:NextNumber(-66, 66), random:NextNumber(-33, 34), random:NextNumber(-36, 36))
				local drift = wind * random:NextNumber(0.65, 1.3) + Vector3.new(0, -random:NextNumber(88, 167), j % 3 * 4)
				local streak = beam(
					socket(carrier, offset),
					socket(carrier, offset + drift),
					random:NextNumber(0.7, 1.6), 0.38,
					ColorSequence.new(rgb(158, 183, 232), rgb(116, 133, 194)),
					softFade(1, random:NextNumber(0.69, 0.86))
				)
				streak.LightEmission = 0.25
			end
		end
	end

	local anvilSpecs = {
		{ Vector3.new(301, altitude(2480), -270), 0.82 },
		{ Vector3.new(-348, altitude(3620), -345), 1.0 },
		{ Vector3.new(94, altitude(3750), -480), 1.08 },
	}
	for i, spec in anvilSpecs do
		local center, scale = table.unpack(spec)
		local anvilLobes = band(parent, "StormAnvil", center,
			Vector3.new(255, 89, 153) * scale, anvilPalette, 300 + i * 29)
		banks[#banks + 1] = { lobes = anvilLobes, colors = table.create(#anvilLobes) }
		for n, cloud in anvilLobes do banks[#banks].colors[n] = cloud.Color end
	end

	local vortex = buildStormVortex(parent, "WideStormVortex",
		Vector3.new(-161, altitude(2960), -322), 175, 19, 237, 2401)

	local fragmentSpecs = {
		{ km = 2320, x = -155, z = -225, scale = 1.1 },
		{ km = 2640, x = 165, z = -230, scale = 1.0 },
		{ km = 3040, x = 136, z = -288, scale = 0.94 },
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

	local lastRimLight = 0
	return function(_, time)
		for i, item in rain do
			item.part.Position = item.origin + Vector3.new(math.sin(time * 0.4 + i) * 9, math.sin(time * 0.78 + i) * 12, 0)
		end
		for i, item in banks do
			local phase = (time + i * 3.19) % 13
			local pulse = math.max(0, 1 - math.abs(phase - 1.3) / 0.85)
			for n, cloud in item.lobes do
				cloud.Color = item.colors[n]:Lerp(rgb(174, 175, 248), pulse * (0.19 + n * 0.025))
			end
		end
		local crestPhase = (time + 2.6) % 17
		local rimLight = math.max(0, 1 - math.abs(crestPhase - 2) / 1.3)
		if rimLight ~= lastRimLight then
			lastRimLight = rimLight
			for i, volume in vortex.funnel do
				local strength = (i - 1) / (#vortex.funnel - 1)
				volume.part.Color = volume.tone:Lerp(rgb(157, 164, 222), rimLight * strength * 0.24)
			end
		end
		local sway = math.sin(time * 0.2 + vortex.phase)
		vortex.model:PivotTo(vortex.origin * CFrame.Angles(0, sway * 0.09, sway * 0.015))
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

local function ruinRelief(parent, cf, scale)
	local carved = rgb(156, 101, 76)
	for _, side in { -1, 1 } do
		part(parent, "TempleRelief", Vector3.new(0.9, 3.2, 0.22) * scale,
			cf * CFrame.new(side * 0.72 * scale, 0, 0) * CFrame.Angles(0, 0, side * 0.52),
			carved, sandstoneMat)
	end
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
	local shortSide = seed % 2 == 0 and 1 or -1

	for idx, side in { -1, 1 } do
		local worn = side == shortSide
		local segLen = totalLen * (worn and 0.24 or 0.41)
		local anchorPos = side == -1 and startPos or finishPos
		local inward = side == -1 and dir or -dir
		local segCenter = anchorPos + inward * (segLen * 0.5)
		local segCf = CFrame.lookAt(segCenter, segCenter + inward)
		local approachCf = CFrame.lookAt(anchorPos, anchorPos + inward)
		-- Broad masonry is embedded into a sculpted buttress at both island connections.
		part(bridge, "EmbeddedApproach", Vector3.new(17, 4.8, 21),
			approachCf * CFrame.new(0, -1.2, 5.5), sandstone, sandstoneMat)
		local terrainTemplate = getEnvironmentAssets()
		local meshes = terrainTemplate and terrainTemplate:FindFirstChild("BiomeLandmarkMeshes")
		local sunset = meshes and meshes:FindFirstChild("Sunset")
		local basalt = sunset and sunset:FindFirstChild("Basalt")
		if basalt then
			local footing = basalt:Clone()
			footing.Name = "EmbeddedCliffButtress"
			footing.Size = Vector3.new(26, 25, 31)
			footing.CFrame = approachCf * CFrame.new(0, -12, 6)
			footing.Color = darkStone:Lerp(sandstone, 0.25)
			footing.Material = slate
			footing.Parent = bridge
		end

		part(bridge, "BridgeDeck", Vector3.new(13.5, 3.6, segLen), segCf, masonry, limestoneMat)
		part(bridge, "DeckCornice", Vector3.new(14.6, 1.1, segLen * 0.98), segCf * CFrame.new(0, 1.6, 0), sandstone, sandstoneMat)
		part(bridge, "GoldInlayRoad", Vector3.new(3.2, 0.4, segLen * 0.92), segCf * CFrame.new(0, 2.0, 0), gold, metalMat)

		for _, railSide in { -1, 1 } do
			local parapetLength = worn and (railSide == side and 0.41 or 0.23) or 0.84
			part(bridge, "Parapet", Vector3.new(1.6, 2.8, segLen * parapetLength),
				segCf * CFrame.new(railSide * 5.6, 3.2, segLen * (1 - parapetLength) * 0.39), masonry, limestoneMat)
			for post = 1, (worn and 1 or 3) do
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
		for chip = 1, 3 do
			local offset = Vector3.new((chip - 2) * 2.4, -3.5 - chip * 3, -1.5 - chip * 0.6)
			part(bridge, "FracturedFallingMasonry", Vector3.new(5.4 - chip, 3.7 - chip * 0.5, 5 - chip * 0.65),
				tipCf * CFrame.new(offset) * CFrame.Angles(0.23 * chip, 0.6 * chip, -0.35 * chip),
				sandstone:Lerp(darkStone, chip * 0.18), sandstoneMat, "Wedge")
		end
		natureAsset(bridge, "Fern", "BridgeOvergrowth", segCf * CFrame.new(3.2, 2.2, 4), 1.35)

		-- Assemble a readable arch from the springing blocks up to the crown under the deck.
		local run = segLen * 0.58
		local rise = math.clamp(run * 0.42, 3.8, 12.5)
		local spring = -3.4 - rise
		local archOrigin = approachCf * CFrame.new(0, spring, -segLen * 0.49)
		for p = 1, (worn and 1 or 2) do
			local along = p == 1 and run * 0.5 or -run * 0.5
			local pierCf = archOrigin * CFrame.new(0, 0, along)
			part(bridge, "BridgePier", Vector3.new(6.4, rise + 10, 5.6),
				pierCf * CFrame.new(0, -(rise + 10) * 0.5, 0), darkStone, slate)
			part(bridge, "PierCapital", Vector3.new(8.8, 2.8, 7.1), pierCf, sandstone, sandstoneMat)
			for _, side in { -1, 1 } do
				ruinRelief(bridge, pierCf * CFrame.new(side * 4.43, 0, 0)
					* CFrame.Angles(0, side * math.pi / 2, 0), 0.70)
			end
		end
		local segments = 9
		for stone = 1, (worn and 5 or segments) do
			local a0 = math.pi * (stone - 1) / segments
			local a1 = math.pi * stone / segments
			local a = Vector3.new(0, math.sin(a0) * rise, math.cos(a0) * run * 0.5)
			local b = Vector3.new(0, math.sin(a1) * rise, math.cos(a1) * run * 0.5)
			local start = archOrigin:PointToWorldSpace(a)
			local finish = archOrigin:PointToWorldSpace(b)
			local center = start:Lerp(finish, 0.5)
			part(bridge, "ArchVoussoir", Vector3.new(8.5, 3.2, (finish - start).Magnitude + 0.22),
				CFrame.lookAt(center, finish), masonry:Lerp(sandstone, (stone % 3) * 0.10), limestoneMat)
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
	local cliffCol = rgb(145, 101, 91)
	local mossCol = rgb(118, 142, 104)
	local sandstoneCol = rgb(184, 136, 102)
	local ivoryCol = rgb(238, 220, 186)
	local goldCol = rgb(242, 182, 74)
	local roots = rgb(110, 73, 79)

	local islandSpecs = {
		{ pos = Vector3.new(-105, altitude(4180), -252), width = 62, yaw = 0.35, rock = Vector3.new(1.05, 0.58, 0.95) },
		{ pos = Vector3.new(112, altitude(4520), -258), width = 96, yaw = -0.42, rock = Vector3.new(1.10, 0.42, 0.93), shelf = true,
			ledges = {
				{ Vector3.new(-46, -16, 18), Vector3.new(0.49, 1.06, 0.55), -0.34 },
				{ Vector3.new(22, -24, 28), Vector3.new(0.39, 0.80, 0.49), 0.36 },
			} },
		{ pos = Vector3.new(-262, altitude(4780), 28), width = 72, yaw = 1.45, rock = Vector3.new(0.87, 1.22, 0.91) },
		{ pos = Vector3.new(-139, altitude(4960), -291), width = 186, yaw = 0.23, temple = true, rock = Vector3.new(1, 1.04, 1) },
		{ pos = Vector3.new(258, altitude(5020), -24), width = 82, yaw = -1.35, rock = Vector3.new(1.13, 0.62, 1.01),
			ledges = { { Vector3.new(-39, -16, 24), Vector3.new(0.55, 1.26, 0.50), 0.40 } } },
		{ pos = Vector3.new(142, altitude(5140), -307), width = 96, yaw = -0.31, rock = Vector3.new(1.02, 0.64, 1), twinPeaks = true,
			ledges = {
				{ Vector3.new(42, -16, 14), Vector3.new(0.59, 1.07, 0.53), -0.44 },
				{ Vector3.new(-28, -38, 20), Vector3.new(0.21, 0.31, 0.29), 0.61 },
			} },
		{ pos = Vector3.new(-88, altitude(5480), -265), width = 74, yaw = 0.25, rock = Vector3.new(1.03, 0.55, 1.16) },
	}
	local islandPositions = {}
	local chimes = {}

	for i, spec in islandSpecs do
		local p = spec.pos
		islandPositions[i] = p
		local temple = spec.temple
		local name = temple and "CloudTempleIsland" or spec.shelf and "StratifiedCliffIsland" or spec.twinPeaks and "TwinPeakIsland" or "ForgottenSkyIsle"
		local island = model(parent, name)
		local cf = CFrame.new(p) * CFrame.Angles(0, spec.yaw, 0)
		local scale = spec.width / 128

		local terrain = buildSculptedIslandTerrain(island, cf, scale, {
			basalt = basaltCol,
			cliff = cliffCol,
			moss = mossCol,
			sandstone = sandstoneCol,
			ivory = ivoryCol,
			gold = goldCol,
			cloudColor = rgb(255, 224, 192),
			cloudShadow = rgb(182, 142, 154),
			rockProfile = spec.rock,
			rockLedges = spec.ledges,
		}, temple)
		if temple then
			-- The same carving appears on the temple's freestanding approach stones.
			for _, side in { -1, 1 } do
				local marker = cf * CFrame.new(side * 18 * scale, 16.5 * scale, 27 * scale)
				part(island, "ProcessionalMarker", Vector3.new(5.2, 8, 4.6) * scale, marker, sandstoneCol, sandstoneMat)
				ruinRelief(island, marker * CFrame.new(0, 0.45 * scale, 2.33 * scale), 1.25 * scale)
			end
		end
		if i == 3 then
			for _, columnSpec in { { -26, 23, -1, -0.15 }, { -8, 11, 2, 0.09 }, { 16, 16, 0, 0.22 } } do
				local x, height, z, tilt = table.unpack(columnSpec)
				local base = cf * CFrame.new(x * scale, 12 * scale, z * scale)
				local ruined = base * CFrame.Angles(0, 0, tilt)
				part(island, "RuinPedestal", Vector3.new(10, 3.4, 10) * scale, base, sandstoneCol, sandstoneMat)
				part(island, "BrokenPillar", Vector3.new(height, 6.3, 6.3) * scale,
					ruined * CFrame.new(0, height * scale * 0.5, 0) * CFrame.Angles(0, 0, math.pi / 2),
					ivoryCol:Lerp(cliffCol, 0.28), limestoneMat, cylinder)
				part(island, "FracturedCapital", Vector3.new(7, 3.4, 6.4) * scale,
					ruined * CFrame.new(0.4 * scale, height * scale, 0) * CFrame.Angles(0, 0.30, tilt),
					sandstoneCol, sandstoneMat, "Wedge")
			end
		end
		if terrain and spec.shelf then
			local rim = terrain:FindFirstChild("SculptedCliffRim")
			if rim then
				for layer, dimensions in { Vector3.new(1.02, 0.39, 0.98), Vector3.new(0.93, 0.45, 0.89) } do
					local shelf = rim:Clone()
					shelf.Name = "SandstoneStratum"
					shelf.Size = rim.Size * dimensions
					shelf.CFrame = rim.CFrame * CFrame.new((layer - 1) * -4 * scale, (-8 - layer * 5) * scale, 0)
					shelf.Color = cliffCol:Lerp(sandstoneCol, layer == 1 and 0.68 or 0.22)
					shelf.Parent = terrain
				end
			end
		elseif terrain and spec.twinPeaks then
			local basalt = terrain:FindFirstChild("Basalt")
			if basalt then
				for _, peak in {
					{ Vector3.new(-34, 28, -12), Vector3.new(54, 51, 47), -0.22 },
					{ Vector3.new(35, 21, -8), Vector3.new(42, 38, 39), 0.20 },
				} do
					local offset, size, lean = table.unpack(peak)
					local tower = basalt:Clone()
					tower.Name = "WeatheredPeak"
					tower.Size = size * scale
					tower.CFrame = cf * CFrame.new(offset * scale) * CFrame.Angles(0.14, lean, math.pi + lean)
					tower.Color = basaltCol:Lerp(sandstoneCol, 0.32)
					tower.Parent = terrain
				end
			end
		end

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

		if i == 2 or i == 4 or i == 5 then
			local chimeSpot = cf * CFrame.new(12 * scale, topY, temple and 17 * scale or -6 * scale)
			buildWindChimeRuin(island, chimeSpot, temple and 1.62 or math.clamp(scale * 1.05, 0.78, 1.12), chimes)
		end

		if i == 2 or i == 4 or i == 6 or i == 7 then
			local lipCf = cf * CFrame.new(49 * scale, topY - 2 * scale, 9 * scale) * CFrame.Angles(0, math.pi / 2, 0)
			local drop = temple and 153 or (66 + i * 6)
			attachSculptedWaterfall(island, lipCf, drop, scale * 1.15,
				rgb(78, 172, 224), rgb(208, 238, 252), rgb(244, 216, 208))
		end
		island.WorldPivot = cf
	end

	local bridgePairs = {
		{
			start = islandPositions[4] + Vector3.new(-38, 6, 12),
			finish = Vector3.new(-283, altitude(4980), -218),
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
		}, false)
		if idx == 1 then
			local arch = anchorCf * CFrame.new(-2, 6, 0) * CFrame.Angles(0, -0.4, 0)
			part(anchorIsle, "ArchRemnantPier", Vector3.new(6, 13, 7),
				arch * CFrame.new(-10, 6.5, 0), sandstoneCol, sandstoneMat)
			for segment = 0, 4 do
				local angle = math.pi - segment * 0.24
				local stone = arch * CFrame.new(math.cos(angle) * 10, 13 + math.sin(angle) * 10, 0)
					* CFrame.Angles(0, 0, angle - math.pi / 2)
				part(anchorIsle, "BrokenArchVoussoir", Vector3.new(3.1, 4.4, 5.8), stone,
					ivoryCol:Lerp(sandstoneCol, segment * 0.10), limestoneMat)
			end
			ruinRelief(anchorIsle, arch * CFrame.new(-10, 10, 3.55), 1.1)
			local rootStart = (arch * CFrame.new(-8, -1, 2)).Position
			local rootMid = (arch * CFrame.new(-13, -12, 5)).Position
			span(anchorIsle, "HangingRoot", rootStart, rootMid, 1.65, roots, woodMat)
			span(anchorIsle, "RootTip", rootMid, rootMid + Vector3.new(-3, -8, 2), 0.82, roots, woodMat)
		elseif idx == 2 then
			buildBlossomTree(anchorIsle, anchorCf * CFrame.new(4, 7, -4), 0.82)
		end
		anchorIsle.WorldPivot = anchorCf
	end

	local distantSpecs = {
		{ km = 4120, angle = -1.25, radius = 415, width = 42, waterfall = false },
		{ km = 4420, angle = -1.85, radius = 438, width = 50, waterfall = true },
		{ km = 4720, angle = -1.12, radius = 525, width = 35, waterfall = false },
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
			rockProfile = idx % 3 == 0 and Vector3.new(0.95, 1.18, 1) or Vector3.new(1.05, 0.67, 1.08),
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
	local astralObsidian = rgb(76, 80, 123)
	local astralSlate = rgb(102, 106, 152)
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
	local astralObsidian = rgb(89, 108, 143)
	local astralSlate = rgb(108, 112, 155)
	local bioTeal = rgb(68, 164, 182)
	local marble = rgb(238, 230, 216)
	local gold = rgb(246, 194, 84)
	local royalBanner = rgb(42, 86, 188)
	local cyanGlow = rgb(104, 238, 255)

	local observatoryTerrain = buildSculptedIslandTerrain(obs, cf, scale * 0.86, {
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

	-- Reuse carved rock for broad reflected colour; no extra point lights or glowing outline.
	if observatoryTerrain then
		local rock = observatoryTerrain:FindFirstChild("Basalt")
		if rock then
			for _, spec in {
				{ Vector3.new(-32, -16, 13), Vector3.new(29, 35, 27), -0.17 },
				{ Vector3.new(23, -20, 20), Vector3.new(33, 39, 24), 0.22 },
				{ Vector3.new(0, -38, 5), Vector3.new(25, 31, 22), -0.08 },
			} do
				local reflected = rock:Clone()
				reflected.Name = "CyanReflectedCrag"
				reflected.Size = spec[2] * scale
				reflected.CFrame = cf * CFrame.new(spec[1] * scale) * CFrame.Angles(0.08, 0.1, spec[3])
				reflected.Color = astralObsidian:Lerp(bioTeal, 0.32)
				reflected.Parent = observatoryTerrain
			end
		end
	end

	local terraceCf = cf * CFrame.new(0, 12.5 * scale, 0)
	fleetShape(obs, "DockRim", "ObservatoryStoneCornice",
		terraceCf * CFrame.new(0, -1.8 * scale, 2 * scale) * CFrame.Angles(0, 0, math.pi / 2),
		Vector3.new(3.6, 78, 58) * scale, astralSlate:Lerp(marble, 0.21), slate)
	fleetShape(obs, "DockRim", "ObservatoryMetalInlay",
		terraceCf * CFrame.new(0, 0.1 * scale, 2 * scale) * CFrame.Angles(0, 0, math.pi / 2),
		Vector3.new(0.75, 77.4, 57.4) * scale, bioTeal:Lerp(marble, 0.30), metalMat)
	for i = 1, 7 do
		local a = math.pi * (i - 1) / 6
		local ledge = terraceCf * CFrame.new(math.cos(a) * 39 * scale, -3.4 * scale, (2 + math.sin(a) * 29) * scale)
			* CFrame.Angles(0, -a - math.pi / 2, 0)
		part(obs, "CrystalInlay", Vector3.new(3.1, 1.4, 1.05) * scale, ledge, bioTeal:Lerp(cyanGlow, 0.25), neon)
	end
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
	local runeInlay = rgb(73, 138, 167)
	local crownCrystal = rgb(115, 82, 160)
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
					d.Color = runeInlay
					d.Material = metalMat
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
				d.Color = crownCrystal
				d.Material = glassMat
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

	buildCosmicCrystalIsland(parent, CFrame.new(-226, altitude(6900), -355) * CFrame.Angles(0, 0.38, 0), 0.92, satellites, 610)
	buildCosmicCrystalIsland(parent, CFrame.new(258, altitude(6980), -22) * CFrame.Angles(0, -1.25, 0), 0.85, satellites, 620)
	buildCosmicCrystalIsland(parent, CFrame.new(-88, altitude(7480), -262) * CFrame.Angles(0, 0.45, 0), 0.84, satellites, 630)

	buildFloatingObservatory(parent, CFrame.new(112, altitude(7040), -290) * CFrame.Angles(0, -0.28, 0), 1.48, armillaryRings)

	local archSpecs = {
		{ km = 6280, angle = -1.35, radius = 425, scale = 0.92 },
		{ km = 6680, angle = -1.78, radius = 445, scale = 1.02 },
		{ km = 7060, angle = -0.12, radius = 395, scale = 0.95 },
		{ km = 7420, angle = -0.73, radius = 492, scale = 0.87 },
		{ km = 7820, angle = -1.68, radius = 435, scale = 0.88 },
	}
	for _, spec in archSpecs do
		local pos = Vector3.new(math.cos(spec.angle) * spec.radius, altitude(spec.km), math.sin(spec.angle) * spec.radius)
		local cf = CFrame.new(pos) * CFrame.Angles(0, spec.angle + math.pi / 2, 0)
		buildDistantCosmicArch(parent, cf, spec.scale)
	end

	for i = 1, 6 do
		local t = (i - 1) / 5
		local arcPos = Vector3.new(-295 + t * 185, altitude(6720 + t * 560) + math.sin(t * math.pi) * 28, -380 - math.sin(t * math.pi) * 38)
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
		local curtain = model(parent, "AuroraCurtain")
		local direction = index == 1 and 1 or -1
		-- Overlap soft-edged curtains with different widths, heights and depth.
		for i, fold in {
			{ -400, 30, -182, 9, 23, 71, -0.15, 0.18, 0.56 },
			{ -260, 15, 24, 73, 45, 121, 0.11, 0.42, 0.38 },
			{ -77, 59, 156, 50, 74, 29, 0.31, -0.32, 0.53 },
			{ 83, 54, 398, 133, 27, 90, -0.22, 0.49, 0.47 },
			{ 245, 99, 459, 115, 59, 12, 0.33, -0.11, 0.66 },
		} do
			local x0, y0, x1, y1, width0, width1, pitch0, pitch1, alpha = table.unpack(fold)
			local depth = ({ -54, 34, 92, 22, -86 })[i] * (index == 1 and 1 or -0.6)
			local base = Vector3.new(0, y, ribbon.z + depth)
			local carrier = rail(curtain, "AuroraFold", base)
			carrier.Transparency = 1
			table.insert(nodes, { part = carrier, origin = base, phase = i * 1.14 + index * 2.2 })
			local start = socket(carrier, Vector3.new(x0 * direction, y0, i * 7),
				Vector3.new(direction, pitch0, -0.13))
			local finish = socket(carrier, Vector3.new(x1 * direction, y1, i * -10),
				Vector3.new(direction, pitch1, 0.19))
			local glow = beam(start, finish, width0, width1, ribbon.color, softFade(1, alpha), 67 + i * 5)
			glow.Segments = 24
			glow.Texture = "rbxasset://textures/particles/smoke_main.dds"
			glow.TextureMode = Enum.TextureMode.Stretch
			glow.TextureSpeed = 0
			glow.LightEmission = 0.63
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
		for _, node in nodes do
			local phase = node.phase
			node.part.Position = node.origin + Vector3.new(
				math.sin(time * 0.11 + phase) * 12,
				math.sin(time * 0.16 + phase) * 9,
				math.cos(time * 0.12 + phase) * 12)
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
	local cloudPalette = { rgb(183, 195, 222), rgb(255, 244, 223), rgb(232, 232, 237) }
	local layouts = {
		{ "HorizonPavilion", Vector3.new(-256, -532, -260), 0.48, -16 },
		{ "HorizonPavilion", Vector3.new(-310, -448, -318), 0.57, -12, "WestArcade" },
		{ "HorizonSpire", Vector3.new(280, -435, -270), 0.53, 22 },
		{ "HorizonPavilion", Vector3.new(265, -345, -35), 0.54, 28 },
		{ "HorizonPavilion", Vector3.new(-276, -320, -302), 0.49, -14, "WestArcade" },
		{ "HorizonSpire", Vector3.new(-285, -295, -45), 0.64, -24 },
		{ "HorizonArch", Vector3.new(339, -232, -344), 0.67, 18, "EastCauseway" },
		{ "HorizonSpire", Vector3.new(-344, -188, -396), 0.39, -8 },
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
	for index, layout in layouts do
		local name, offset, scale, turn, style = table.unpack(layout)
		local position = anchor:PointToWorldSpace(offset)
		local target = Vector3.new(anchor.Position.X, position.Y, anchor.Position.Z)
		local facing = CFrame.lookAt(position, target) * CFrame.Angles(0, math.pi + math.rad(turn), 0)
		if name == "HorizonCloud" then
			band(horizon, "FarCloudVeil", position, Vector3.new(420, 78, 190) * scale,
				cloudPalette, 151 + index, "wisp")
			continue
		end

		local vista = landmark(horizon, name, facing, scale)
		if vista then
			local haze = math.clamp((offset.Magnitude - 130) / 1420, 0.24, 0.79)
			local warm = offset.X < 0
			local mistColor = warm and rgb(231, 222, 224) or rgb(193, 211, 233)
			local cloudTones = { cloudPalette[1]:Lerp(mistColor, haze), cloudPalette[2]:Lerp(mistColor, haze), cloudPalette[3]:Lerp(mistColor, haze) }
			for _, piece in vista:GetChildren() do
				if piece.Name == "VistaIvory" or piece.Name == "VistaShadow" then
					piece:Destroy()
				elseif piece:IsA("BasePart") then
					piece.Color = piece.Color:Lerp(mistColor, haze)
					if style == "WestArcade" then
						local rel = facing:PointToObjectSpace(piece.Position)
						piece.Size *= Vector3.new(1.18, 0.70, 1.08)
						piece.Position = facing:PointToWorldSpace(rel * Vector3.new(1.18, 0.70, 1.08))
					end
				end
			end
			local _, heading = facing:ToOrientation()
			local arch = name == "HorizonArch"
			local baseWidth = arch and 284 or style == "WestArcade" and 284 or 242
			local cloudHeight = style == "WestArcade" and 72 or 86
			band(vista, "HorizonCloudBase", position - Vector3.new(0, (cloudHeight * 0.45 + 6) * scale, 0),
				Vector3.new(baseWidth, cloudHeight, 124) * scale, cloudTones, 151 + index, "foundation", heading)
			if style == "WestArcade" then
				for terrace = 1, 2 do
					local shelf = facing * CFrame.new(terrace * 53 * scale, (-9 - terrace * 4) * scale, 18 * scale)
					part(vista, "OpenTerrace", Vector3.new(56, 4, 39) * scale, shelf,
						rgb(244, 219, 170):Lerp(mistColor, haze), limestoneMat)
				end
			end
			if arch then
				local plinthColor = rgb(220, 214, 205):Lerp(rgb(183, 199, 220), haze)
				for _, side in { -1, 1 } do
					local footing = facing * CFrame.new(side * 98 * scale, -19 * scale, 0)
					part(vista, "ArchFooting", Vector3.new(44, 13, 47) * scale, footing, plinthColor, limestoneMat)
					band(vista, "FootingCloud", footing.Position - Vector3.new(0, 9 * scale, 0),
						Vector3.new(117, style == "EastCauseway" and 66 or 54, 91) * scale, cloudTones, 175 + index + side, "foundation", heading)
				end
			end
		end
	end
end

local function palaceUpperSky(parent, anchor)
	local sky = model(parent, "PalaceUpperSky")
	local overhead = model(sky, "OverheadClouds")
	local ceiling = {
		{ Vector3.new(-455, 278, -280), Vector3.new(240, 36, 126), "wisp" },
		{ Vector3.new(460, 305, -330), Vector3.new(260, 45, 141), "wisp" },
		{ Vector3.new(-340, 435, 360), Vector3.new(235, 42, 113), "wisp" },
		{ Vector3.new(374, 560, 125), Vector3.new(235, 69, 125), "mist" },
		{ Vector3.new(16, 627, -416), Vector3.new(215, 30, 121), "mist" },
	}
	local colors = { rgb(220, 220, 232), rgb(253, 242, 223), rgb(242, 231, 221) }
	local driftingClouds = {}
	for i, layout in ceiling do
		local offset, size, profile = table.unpack(layout)
		local _, cloud = band(overhead, "UpperCloudDrift", anchor:PointToWorldSpace(offset), size, colors, 810 + i, profile)
		table.insert(driftingClouds, { cloud = cloud, placement = cloud:GetPivot() })
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
		{ "CloudSailer", Vector3.new(-356, -300, -296), Vector3.new(42, 6, 32), 84, 0.35, 1.08 },
		{ "CloudKetch", Vector3.new(242, -315, -25), Vector3.new(36, 7, 44), 96, 2.1, 0.98 },
		{ "CloudCutter", Vector3.new(397, -190, -362), Vector3.new(38, 8, 40), 108, 4.2, 0.88 },
		{ "CloudSailer", Vector3.new(187, 66, -159), Vector3.new(42, 6, 39), 88, 0.12, 1.04 },
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
		-- Keep only the placement from the old full-width backdrop.
		vista:Destroy()
		palaceHorizon(parent, anchor)
		animateSky = palaceUpperSky(parent, anchor)
	end

	local gateCrystals = {}
	buildFloatingCrystalGate(parent, CFrame.new(168, altitude(8980), -253) * CFrame.Angles(0, -0.35, 0), 1.04, gateCrystals)

	local clouds = { rgb(252, 232, 179), rgb(255, 244, 210), rgb(246, 221, 162) }
	for i = 1, 12 do
		local tier = math.floor((i - 1) / 4)
		local angle = (i - 1) * math.pi / 2 + 0.48 + tier * 0.32
		local radius = 390 + tier * 55
		local x, z = math.cos(angle) * radius, math.sin(angle) * radius
		-- Frame the palace vista from either side of the central ascent.
		if z < 0 and math.abs(x) < 260 then
			x = (x < 0 and -1 or 1) * 310
		end
		local center = Vector3.new(x, altitude(8120 + tier * 680 + i % 4 * 85), z)
		band(parent, "GoldenCloudTerrace", center, Vector3.new(185 + tier * 13, 46, 112), clouds, i * 21,
			i % 3 == 0 and "wisp" or nil)
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

	local palace = workspace:FindFirstChild("CloudPalace")
	local silhouette = model(parent, "PalaceSilhouette")
	local at = CFrame.new(0, altitude(9450), -398)
	local scale = 0.75
	local architecture = palace and palace:FindFirstChild("CustomArchitecture")
	local summitDock = palace and palace:FindFirstChild("CloudHavenDock")
	local ribbons = {}
	if architecture and summitDock then
		-- Project the actual palace in a clear side view for the steep lower approach.
		-- Use the world-aligned plaza datum so the facade and spills keep their handedness.
		local island = palace:FindFirstChild("CloudIsland")
		local center = island and island.Position or summitDock.Position
		local plaza = CFrame.new(center.X, summitDock.Position.Y, center.Z)
		local function atVista(cf)
			local relative = plaza:ToObjectSpace(cf)
			return at * CFrame.new(relative.Position * scale) * relative.Rotation
		end
		local summitScenery = palace:FindFirstChild("SummitScenery")
		local models = { architecture, palace:FindFirstChild("CloudCascades") }
		local spillway = summitScenery and summitScenery:FindFirstChild("PalaceWaterfall")
		if spillway then table.insert(models, spillway) end
		for _, source in models do
			for _, piece in source:GetDescendants() do
				if piece:IsA("BasePart") and piece.Transparency < 1 and piece.Name ~= "PortalGlow" then
					local copy = piece:Clone()
					copy:ClearAllChildren()
					copy.Size = piece.Size * scale
					copy.CFrame = atVista(piece.CFrame)
					copy.Parent = silhouette
				end
			end
		end
		local cascades = palace:FindFirstChild("CascadesAndMist")
		if cascades then
			local waterFade = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.28),
				NumberSequenceKeypoint.new(0.45, 0.33),
				NumberSequenceKeypoint.new(0.78, 0.63),
				NumberSequenceKeypoint.new(1, 1),
			})
			for _, outlet in cascades:GetChildren() do
				if outlet.Name == "FallingWater" and outlet:IsA("BasePart") then
					local carrier = rail(silhouette, "VistaWaterfall", atVista(outlet.CFrame).Position)
					carrier.Transparency = 1
					local drop = (outlet.Position.Y > summitDock.Position.Y + 25 and 36 or 97) * scale
					local width = outlet.Size.X * scale
					local water = beam(socket(carrier, Vector3.zero), socket(carrier, Vector3.new(0, -drop, 1.4)),
						width, width * 0.68, ColorSequence.new(rgb(136, 220, 243), rgb(217, 246, 253)), waterFade)
					water.LightEmission = 0.28
					table.insert(ribbons, water)
				end
			end
		end
	else
		landmark(silhouette, "Palace", at, scale)
		local foundation = landmark(silhouette, "PalaceFoundation", at, scale)
		if foundation then
			for _, name in { "CloudIvory", "CloudShade" } do
				local backing = foundation:FindFirstChild(name)
				if backing then backing:Destroy() end
			end
		end
	end
	band(silhouette, "PalaceCloudPlinth", at.Position - Vector3.new(0, 17, 0),
		Vector3.new(202, 57, 162), { rgb(170, 157, 184), rgb(247, 235, 224), rgb(221, 220, 230) }, 1403)
	silhouette.WorldPivot = at
	local silhouetteParts = {}
	for _, piece in silhouette:GetDescendants() do
		if piece:IsA("BasePart") then
			silhouetteParts[piece] = piece.Transparency
			piece.Transparency = 1
		end
	end
	local lastVistaVisibility

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
		local fadeIn = math.clamp((km - 8075) / 470, 0, 1)
		local fadeOut = math.clamp((9880 - km) / 480, 0, 1)
		local visibility = math.round(fadeIn * fadeOut * fadeOut * 40) / 40
		if lastVistaVisibility == visibility then return end
		lastVistaVisibility = visibility
		for piece, transparency in silhouetteParts do
			piece.Transparency = 1 - (1 - transparency) * visibility
		end
		for _, water in ribbons do water.LocalTransparencyModifier = 1 - visibility end
	end
end

local builders = { dawn, thundercloud, skyIsles, exosphere, gateway }
local names = { "DawnArchipelago", "IndigoThundercloud", "ForgottenSkyIsles", "CosmicExosphere", "CelestialGateway" }

function Scenery.Build(index)
	local scene = model(nil, names[index])
	local animate = builders[index](scene)
	local groups = {}
	for index, root in scene:GetChildren() do
		local group = { parts = {}, beams = {}, mist = {}, delay = ((index * 7) % 13) / 12 * 0.48 }
		local objects = root:GetDescendants()
		table.insert(objects, root)
		for _, object in objects do
			if object:IsA("BasePart") then
				object.Anchored = true
				object.CanCollide = false
				object.CanTouch = false
				object.CanQuery = false
				object.CastShadow = false
				table.insert(group.parts, object)
			elseif object:IsA("Beam") then
				group.beams[object] = object.Transparency
			elseif object:IsA("ImageLabel") and object.Name == "MistTexture" then
				group.mist[object] = object.ImageTransparency
			end
		end
		table.insert(groups, group)
	end

	local lastOpacity
	return scene, function(km, time, opacity)
		if animate then animate(km, time) end
		if opacity == lastOpacity then return end
		lastOpacity = opacity
		for _, group in groups do
			-- Fade landmarks in sequence to limit the number of transparent silhouettes at once.
			local t = math.clamp((opacity - group.delay) / 0.52, 0, 1)
			local weight = t * t * (3 - 2 * t)
			for _, object in group.parts do object.LocalTransparencyModifier = 1 - weight end
			for sprite, base in group.mist do sprite.ImageTransparency = 1 - (1 - base) * weight end
			for object, original in group.beams do
				local points = {}
				for i, point in original.Keypoints do
					points[i] = NumberSequenceKeypoint.new(point.Time, 1 - (1 - point.Value) * weight)
				end
				object.Transparency = NumberSequence.new(points)
			end
		end
	end
end

return Scenery
