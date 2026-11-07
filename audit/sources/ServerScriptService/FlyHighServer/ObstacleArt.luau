local Art = {}
local Motion = require(script.Parent.ObstacleMotion)
local rgb = Color3.fromRGB
local metal = Enum.Material.Metal
local glow = Enum.Material.Neon
local dark = rgb(33, 36, 57)
local ivory = rgb(248, 242, 218)
local gold = rgb(249, 171, 48)
local violet = rgb(124, 91, 206)
local ice = rgb(129, 224, 255)
local Vector = Vector3.new
local smokeTexture = "rbxasset://textures/particles/smoke_main.dds"
local sparkTexture = "rbxasset://textures/particles/sparkles_main.dds"

local function piece(model, name, size, position, color, shape, rotation, material)
	local part = Instance.new(shape == "Wedge" and "WedgePart" or "Part")
	if shape and shape ~= "Wedge" then part.Shape = Enum.PartType[shape] end
	part.Name = name
	part.Size = Vector(size[1], size[2], size[3])
	part.CFrame = CFrame.new(position[1], position[2], position[3])
		* (rotation and CFrame.Angles(math.rad(rotation[1]), math.rad(rotation[2]), math.rad(rotation[3])) or CFrame.identity)
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.CastShadow = false
	part.Parent = model
	return part
end

local function modelWithCore(name, size)
	local model = Instance.new("Model")
	model.Name = name
	local core = piece(model, "Core", size, {0, 0, 0}, dark)
	core.Transparency = 1
	model.PrimaryPart = core
	return model
end

local function particle(parent, position, profile)
	local source = Instance.new("Attachment")
	source.Position = position
	source.Parent = parent
	local effect = Instance.new("ParticleEmitter")
	effect.Name = profile.name or "AtmosphericDetail"
	effect.Texture = profile.texture or smokeTexture
	effect.Color = ColorSequence.new(profile.color, profile.fade or profile.color)
	effect.Size = NumberSequence.new(profile.size, profile.endSize or profile.size * 1.65)
	effect.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, profile.opacity or 0.36),
		NumberSequenceKeypoint.new(0.45, profile.opacity or 0.36),
		NumberSequenceKeypoint.new(1, 1),
	})
	effect.Lifetime = NumberRange.new(profile.life * 0.7, profile.life)
	effect.Rate = profile.rate
	effect.Speed = NumberRange.new(profile.speed * 0.45, profile.speed)
	effect.EmissionDirection = profile.direction or Enum.NormalId.Top
	effect.SpreadAngle = Vector2.new(profile.spread or 28, profile.spread or 28)
	effect.Rotation = NumberRange.new(-180, 180)
	effect.RotSpeed = NumberRange.new(-18, 26)
	effect.LightEmission = profile.emission or 0.2
	effect.LightInfluence = profile.lightInfluence or 0.18
	effect.Enabled = profile.enabled ~= false
	effect.Parent = source
	return effect
end

local function accent(model, name, size, position, color, shape, rotation, material)
	local part = piece(model, name, size, position, color, shape, rotation, material)
	part:SetAttribute("Decoration", true)
	return part
end

local function feathered(model, main, feather, phoenix)
	piece(model, "Body", {2.6, 2, 4.2}, {0, 0, 0}, main, "Ball")
	piece(model, "Head", {1.7, 1.55, 1.8}, {0, 0.5, -1.8}, ivory, "Ball")
	piece(model, "Beak", {0.8, 0.75, 1.35}, {0, 0.24, -2.7}, gold, "Wedge", {0, 180, 0})
	accent(model, "Chest", {2.02, 1.28, 2.67}, {0, -0.43, -0.58}, phoenix and rgb(255, 115, 26) or rgb(218, 218, 203), "Ball")
	for _, side in {-1, 1} do
		piece(model, "Eye", {0.24, 0.24, 0.24}, {0.68 * side, 0.64, -2.12}, dark, "Ball")
		piece(model, "Wing", {4.1, 0.58, 2.3}, {2.55 * side, 0.45, 0.12}, main, "Wedge", {0, side * 22, side * 10})
		for index = 1, 4 do
			piece(model, "FlightFeather", {0.76, 0.28, 2.8 - index * 0.2},
				{(2.1 + index * 0.68) * side, 0.37 + index * 0.10, 0.75},
				index % 2 == 0 and feather or main, "Wedge", {0, side * 28, side * 10})
		end
		accent(model, "FlightFeather", {2.85, 0.12, 0.64}, {side * 2.66, 0.68, -0.52},
			phoenix and gold or ivory, "Wedge", {0, side * 16, side * 8}, phoenix and glow or nil)
	end
	for index = -1, 1 do
		piece(model, "TailFeather", {0.75, 0.22, phoenix and 4.2 or 2.3}, {index * 0.58, 0.12, 2.35},
			feather, "Wedge", {0, index * 15, 0}, phoenix and glow or nil)
	end
end

local enemyBuilders = {
	WildBird = function(model)
		feathered(model, ivory, rgb(79, 99, 118), false)
		for _, side in {-1, 1} do
			local companion = Instance.new("Model")
			feathered(companion, side < 0 and ivory or rgb(118, 80, 50), rgb(76, 59, 52), false)
			companion:ScaleTo(0.55)
			local center = Vector(side * 7, side * 1.5, 4)
			companion.WorldPivot = CFrame.identity
			companion:PivotTo(CFrame.new(center))
			for _, part in companion:GetChildren() do
				part:SetAttribute("FlockCenter", center)
				part.Parent = model
			end
			companion:Destroy()
		end
	end,
	StormBat = function(model)
		piece(model, "Fur", {2.1, 2.5, 3.1}, {0, 0, 0}, dark, "Ball")
		piece(model, "Muzzle", {1.6, 1.4, 1.65}, {0, 0.55, -1.4}, rgb(67, 53, 97), "Ball")
		for _, side in {-1, 1} do
			piece(model, "Ear", {0.6, 1.15, 0.75}, {side * 0.55, 1.48, -1.35}, violet, "Wedge", {0, 180, side * -12})
			piece(model, "Eye", {0.25, 0.24, 0.28}, {side * 0.49, 0.69, -2.02}, ice, "Ball", nil, glow)
			piece(model, "Membrane", {3.45, 0.23, 2.95}, {side * 2.35, 0.4, 0.48}, rgb(88, 58, 144), "Wedge", {0, side * -21, side * 12})
			piece(model, "WingTip", {2.9, 0.20, 1.95}, {side * 4.47, 0.79, 0.46}, rgb(61, 40, 102), "Wedge", {0, side * 42, side * 19})
			for index = 1, 3 do
				accent(model, "Membrane", {1.28, 0.11, 0.37}, {side * (1.47 + index * 0.72), 0.55 + index * 0.11, 0.15 + index * 0.15},
					rgb(151, 107, 209), "Wedge", {0, side * (30 + index * 8), side * 11})
			end
			accent(model, "Fang", {0.19, 0.36, 0.21}, {side * 0.32, 0.18, -2.03}, ivory, "Wedge", {0, 180, side * 12})
		end
	end,
	Hailstone = function(model)
		for index = 1, 5 do
			piece(model, "IceShard", {2.1, 3.3 - index * 0.18, 2.3}, {(index - 3) * 0.43, 0, 0},
				index % 2 == 0 and ivory or ice, "Wedge", {index * 67, index * 77, index * 39}, Enum.Material.Ice)
		end
		accent(model, "FrozenCore", {1.5, 2.2, 1.44}, {0, 0.15, 0}, rgb(70, 168, 221), "Wedge", {21, 29, -15}, Enum.Material.Glass)
		particle(model.PrimaryPart, Vector3.zero, {
			color = ice, fade = ivory, size = 0.9, life = 0.45, rate = 12, speed = 2.5, spread = 70,
		})
	end,
	GuardianDrone = function(model)
		piece(model, "ArmoredChassis", {4.1, 1.9, 3.35}, {0, 0, 0}, rgb(99, 78, 64), "Ball", nil, metal)
		piece(model, "Aperture", {1.55, 1.15, 0.45}, {0, 0.12, -1.53}, gold, "Ball", nil, glow)
		accent(model, "ApertureFrame", {0.38, 1.55, 1.85}, {0, 0.1, -1.47},
			rgb(113, 76, 39), "Cylinder", {0, 90, 0}, metal)
		accent(model, "AperturePupil", {0.72, 0.66, 0.24}, {0, 0.12, -1.84}, ivory, "Ball", nil, glow)
		for _, side in {-1, 1} do
			piece(model, "Shoulder", {2.35, 0.7, 2.4}, {side * 2.34, 0.08, 0.17}, rgb(163, 130, 86), "Wedge", {0, side * 14, 0}, metal)
			piece(model, "Jet", {0.9, 1.1, 1.1}, {side * 2.4, -0.32, 0.65}, ice, "Cylinder", {0, 0, 90}, glow)
			for index = 1, 3 do
				accent(model, "InlaidPanel", {0.34, 0.08, 1.22}, {side * (1.62 + index * 0.38), 0.36, -0.18},
					rgb(236, 184, 104), "Wedge", {0, side * 14, 0}, metal)
			end
			particle(model.PrimaryPart, Vector(side * 2.4, -0.32, 0.93), {
				color = ice, fade = rgb(116, 106, 211), size = 0.58, life = 0.35, rate = 9, speed = 8,
				direction = Enum.NormalId.Back, emission = 0.75,
			})
		end
	end,
	FireBee = function(model)
		piece(model, "Thorax", {2.65, 2.5, 2.8}, {0, 0, -0.66}, dark, "Ball")
		for index = 0, 3 do
			piece(model, "AbdomenBand", {2.35 - index * 0.37, 2.18 - index * 0.34, 1.5},
				{0, 0, 0.62 + index * 0.5}, index % 2 == 0 and gold or dark, "Ball")
		end
		for _, side in {-1, 1} do
			local wing = piece(model, "AmberWing", {3.45, 0.23, 1.48}, {side * 1.9, 0.76, 0},
				rgb(255, 195, 113), "Ball", {0, side * 27, side * 22})
			wing.Transparency = 0.26
			accent(model, "AmberWing", {2.62, 0.1, 0.34}, {side * 1.92, 0.91, -0.19},
				rgb(255, 217, 145), "Wedge", {0, side * 27, side * 22}, glow)
			piece(model, "Eye", {0.55, 0.6, 0.47}, {side * 0.75, 0.35, -1.82}, gold, "Ball", nil, glow)
			accent(model, "Antenna", {0.17, 0.74, 0.19}, {side * 0.62, 1.17, -1.43}, gold, "Wedge", {-20, 0, side * -25})
		end
	end,
	CrystalWyvern = function(model)
		piece(model, "ScaledBody", {2.4, 2.3, 4.2}, {0, 0, 0}, rgb(38, 111, 124), "Ball")
		piece(model, "Jaw", {1.8, 1.55, 2.2}, {0, 0.45, -2.1}, rgb(38, 111, 124), "Wedge", {0, 180, 0})
		for _, side in {-1, 1} do
			piece(model, "CrystalWing", {5, 0.46, 3.1}, {side * 3.12, 0.37, 0.7}, rgb(83, 195, 206),
				"Wedge", {0, side * 22, side * 18}, Enum.Material.Glass)
			piece(model, "Horn", {0.55, 1.65, 0.6}, {side * 0.7, 1.35, -1.4}, ice, "Wedge", {0, 180, -20 * side})
			piece(model, "Eye", {0.26, 0.29, 0.28}, {side * 0.8, 0.52, -2.55}, ice, "Ball", nil, glow)
			for index = 1, 3 do
				accent(model, "CrystalWing", {1.45, 0.16, 1.18}, {side * (2.14 + index * 0.75), 0.55 + index * 0.17, 0.7 + index * 0.13},
					index % 2 == 0 and ice or rgb(121, 234, 178), "Wedge", {0, side * 24, side * 18}, Enum.Material.Glass)
			end
		end
		for index = 1, 4 do
			piece(model, "TailCrystal", {1.3 - index * 0.22, 0.7, 1.7}, {0, index * 0.18, 1.4 + index * 0.74},
				index % 2 == 0 and ice or rgb(62, 149, 166), "Wedge", {index * 8, 0, 0})
		end
	end,
	ShadowPhantom = function(model)
		piece(model, "Hood", {2.5, 3.1, 2.45}, {0, 0.34, -0.8}, rgb(45, 34, 72), "Ball")
		for _, side in {-1, 1} do
			piece(model, "Eye", {0.46, 0.28, 0.26}, {side * 0.5, 0.62, -1.94}, violet, "Ball", nil, glow)
			for index = 1, 3 do
				piece(model, "Cloak", {1.4, 0.35, 4.35 - index * 0.5},
					{side * index * 0.83, -index * 0.32, 0.65}, rgb(49 + index * 10, 34, 81),
					"Wedge", {20, side * 18 * index, side * 11})
			end
		end
		particle(model.PrimaryPart, Vector(0, -0.8, 0.85), {
			color = rgb(103, 70, 159), fade = rgb(191, 139, 244), size = 1.15, life = 0.48, rate = 16,
			speed = 4.5, direction = Enum.NormalId.Back, emission = 0.5,
		})
	end,
	SatelliteDebris = function(model)
		piece(model, "Bus", {2.8, 2.2, 2.4}, {0, 0, 0}, rgb(204, 167, 92), "Block", {18, 14, 12}, metal)
		for _, side in {-1, 1} do
			for index = 1, side > 0 and 2 or 3 do
				piece(model, "SolarPanel", {1.05, 0.16, 2.0}, {side * (1.8 + index * 1.07), 0.2, 0.1},
					rgb(54, 106 + index * 12, 190), "Block", {18, 0, 0}, metal)
				for _, seam in {-0.45, 0, 0.45} do
					accent(model, "PanelCellEdge", {0.95, 0.04, 0.065},
						{side * (1.8 + index * 1.07), 0.3 - seam * 0.3, 0.1 + seam}, ice, "Block", {18, 0, 0})
				end
			end
		end
		piece(model, "Dish", {0.33, 2.15, 2.15}, {0.2, 1.05, -0.37}, ivory, "Cylinder", {0, 0, 64}, metal)
		accent(model, "WarningDiode", {0.26, 0.26, 0.26}, {1.13, 0.61, -0.83}, rgb(255, 128, 60), "Ball", nil, glow)
	end,
	CelestialPhoenix = function(model)
		feathered(model, rgb(233, 75, 29), gold, true)
		piece(model, "Crest", {0.68, 0.87, 1.1}, {0, 1.45, -1.54}, gold, "Wedge", {-18, 0, 0}, glow)
		accent(model, "FlameCrest", {0.47, 1.42, 0.55}, {0, 1.62, -1.15}, rgb(255, 114, 31), "Wedge", {-30, 0, 0}, glow)
		accent(model, "ForkedTail", {0.48, 0.19, 3.45}, {-0.46, 0.12, 3.0}, gold, "Wedge", {0, -13, 0}, glow)
		accent(model, "ForkedTail", {0.48, 0.19, 3.45}, {0.46, 0.12, 3.0}, rgb(255, 93, 17), "Wedge", {0, 13, 0}, glow)
		local embers = Instance.new("ParticleEmitter")
		embers.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		embers.Color = ColorSequence.new(gold, rgb(217, 44, 17))
		embers.Lifetime = NumberRange.new(0.25, 0.65)
		embers.Size = NumberSequence.new(0.75, 0.15)
		embers.LightEmission = 0.8
		embers.EmissionDirection = Enum.NormalId.Back
		embers.Speed = NumberRange.new(4, 7)
		embers.Rate = 18
		embers.Parent = model.PrimaryPart
	end,
}

local enemyTemplates = {}

function Art.Enemy(name)
	local template = enemyTemplates[name]
	if not template then
		template = modelWithCore(name, {3.2, 2.6, 3.5})
		enemyBuilders[name](template)
		enemyTemplates[name] = template
	end
	return template:Clone()
end

local function streak(model, start, finish, color, width, active)
	local root = model.PrimaryPart
	local a = Instance.new("Attachment")
	a.Position = start
	a.Parent = root
	local b = Instance.new("Attachment")
	b.Position = finish
	b.Parent = root
	local beam = Instance.new("Beam")
	beam.Name = active and "ActiveBeam" or "WarningBeam"
	beam.Attachment0 = a
	beam.Attachment1 = b
	beam.FaceCamera = true
	beam.LightEmission = 0.65
	beam.LightInfluence = 0
	beam.Color = ColorSequence.new(color)
	beam.Width0 = width
	beam.Width1 = width
	beam.Transparency = NumberSequence.new(active and 0.12 or 0.32)
	beam.Enabled = not active
	beam.Parent = a
	return beam
end

local function ring(model, center, radius, color, name, strike)
	for quarter = 0, 3 do
		local a = quarter * math.pi / 2
		local b = a + math.pi / 2
		local line = streak(model, center + Vector(math.cos(a), 0, math.sin(a)) * radius,
			center + Vector(math.cos(b), 0, math.sin(b)) * radius, color, 0.63)
		line.Attachment0.Axis = Vector(-math.sin(a), 0, math.cos(a))
		line.Attachment1.Axis = Vector(-math.sin(b), 0, math.cos(b))
		line.CurveSize0 = radius * 0.5523
		line.CurveSize1 = radius * 0.5523
		line.Segments = 9
		line.Name = name
		line.LightEmission = 0.38
		if strike then line:SetAttribute("StrikeWarning", strike) end
	end
end

local function boundaryPosts(model, center, radius, color)
	for _, direction in {Vector3.xAxis, -Vector3.xAxis, Vector3.zAxis, -Vector3.zAxis} do
		local foot = center + direction * radius
		local post = streak(model, foot - Vector(0, 3, 0), foot + Vector(0, 11, 0), color, 1.05)
		post.Name = "BoundaryPost"
		post.Width1 = 0.26
		post.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.55),
			NumberSequenceKeypoint.new(0.3, 0.12),
			NumberSequenceKeypoint.new(1, 0.9),
		})
	end
end

local function vortex(model, color, radius, height)
	local root = model.PrimaryPart
	local shadow = color:Lerp(dark, 0.58)
	for layer = 1, 4 do
		local r = radius * (0.32 + layer * 0.16)
		local y = (layer / 4 - 0.56) * height
		for arm = 0, 1 do
			local startAngle = layer * 1.28 + arm * math.pi
			local a = Vector(math.cos(startAngle) * r, y, math.sin(startAngle) * r)
			local endAngle = startAngle + 2.05
			local b = Vector(math.cos(endAngle) * (r + 2), y + 5.5, math.sin(endAngle) * (r + 2))
			local ribbon = streak(model, a, b, color, 4.7 + layer * 0.7)
			ribbon.Name = "VortexRibbon"
			ribbon.Attachment0.Axis = Vector(-math.sin(startAngle), 0.19, math.cos(startAngle))
			ribbon.Attachment1.Axis = Vector(-math.sin(endAngle), 0.17, math.cos(endAngle))
			ribbon.CurveSize0 = r * 0.76
			ribbon.CurveSize1 = r * 0.85
			ribbon.Width1 = ribbon.Width0 * 0.42
			ribbon.Segments = 18
			ribbon.LightEmission = 0.46
			ribbon.Color = ColorSequence.new(shadow:Lerp(color, 0.45), color:Lerp(ivory, 0.42))
			ribbon.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.86),
				NumberSequenceKeypoint.new(0.37, 0.27),
				NumberSequenceKeypoint.new(1, 1),
			})
			for _, endpoint in {ribbon.Attachment0, ribbon.Attachment1} do
				endpoint:SetAttribute("SpiralRate", layer * 0.33 + arm * 0.17)
			end
		end
		local fog = particle(root, Vector(0, y, 0), {
			color = shadow, fade = color, size = 8 + layer * 3.6, life = 1.2, rate = 7,
			speed = 7, spread = 90, opacity = 0.43, emission = 0.28,
		})
		fog.LockedToPart = true
	end
end

local function bolt(model, start, finish, color, strike)
	local previous = start
	for index = 1, 6 do
		local point = start:Lerp(finish, index / 6)
		if index < 6 then point += Vector(math.sin(index * 3.5) * 6, 0, math.cos(index * 2.6) * 4) end
		local main = streak(model, previous, point, color, 1.18, true)
		if strike then main:SetAttribute("Strike", strike) end
		if index == 2 or index == 4 then
			local branch = streak(model, point, point + Vector(index == 2 and -11 or 9, -9, 5), color, 0.48, true)
			branch.Width1 = 0.1
			if strike then branch:SetAttribute("Strike", strike) end
		end
		previous = point
	end
end

local function ruinModel(index, offset)
	local ruin = modelWithCore("Ruin" .. index, {1, 1, 1})
	local slate = rgb(77, 87, 103)
	local stone = index % 2 == 0 and rgb(168, 143, 112) or rgb(195, 171, 134)
	local trim = rgb(218, 174, 99)
	piece(ruin, "FracturedFoundation", {15, 3.6, 13}, {0, -8, 0}, slate, "Wedge", {0, index * 37, -12}, Enum.Material.Slate)
	piece(ruin, "LowerPlinth", {12.4, 1.9, 10.2}, {0, -6, 0}, stone, "Block", {0, index * 8, 6}, Enum.Material.Sandstone)
	piece(ruin, "UpperPlinth", {9.5, 1.6, 7.4}, {0.8, -4.8, -0.5}, slate, "Block", {0, index * 8, 7}, Enum.Material.Slate)
	local lean = 76 + index * 7
	local lastCourse = index == 2 and 2 or 3
	for section = 0, lastCourse do
		local size = 4.15 - section * 0.29
		piece(ruin, "ColumnCourse", {2.5, size, size}, {-2.8 + section * 0.35, -4.2 + section * 2.3, 0},
			section % 2 == 0 and stone or slate:Lerp(stone, 0.68), "Cylinder", {0, 0, lean}, Enum.Material.Sandstone)
	end
	local crownY = index == 2 and 2 or 4.2
	piece(ruin, "BrokenCapital", {6.6, 2.1, 5.1}, {-0.9, crownY, 0.25}, stone, "Wedge",
		{13, index * 22, -13}, Enum.Material.Sandstone)
	piece(ruin, "LintelFragment", {8, 2.35, 4.1}, {1.1, crownY + 1.25, 0.25}, slate, "Wedge",
		{15, index * 16, -14}, Enum.Material.Slate)
	for _, side in {-1, 1} do
		accent(ruin, "TempleInlay", {10.6, 0.16, 0.26}, {0, -5.15, side * 4.96}, trim, "Block",
			{0, index * 8, 6}, glow)
		accent(ruin, "Fracture", {2.7, 1.8, 3.3}, {side * 5.9, -7 + side * 1.4, side * 3.1},
			slate, "Wedge", {index * 61, side * 29, side * 14}, Enum.Material.Slate)
	end
	accent(ruin, "Keystone", {0.56, 0.67, 0.26}, {-1.15, crownY - 0.35, -2.3}, trim, "Wedge", {0, 180, 22}, glow)
	ruin:PivotTo(CFrame.new(offset))
	return ruin
end

function Art.Hazard(effect, color, path, cells)
	local model = modelWithCore(effect, {1, 1, 1})
	if effect == "Tornado" or effect == "Storm" then
		vortex(model, color, effect == "Storm" and 22 or 15, 43)
		if effect == "Tornado" then
			streak(model, Vector(0, -13, 0), path + Vector(0, -13, 0), ice, 0.6).Name = "PathBeam"
		else
			local coreColor = rgb(255, 109, 47)
			ring(model, Vector3.zero, Motion.StormRadius, coreColor, "StormCoreWarning")
			boundaryPosts(model, Vector3.zero, Motion.StormRadius, coreColor)
			for index, x in ipairs(cells) do
				local point = Vector(x, 0, 0)
				local warning = streak(model, point + Vector(0, 39, 0), point - Vector(0, 13, 0), gold, 0.45)
				warning:SetAttribute("StrikeWarning", index)
				ring(model, point, Motion.LightningRadius, gold, "StrikeRing", index)
				bolt(model, point + Vector(0, 39, 0), point - Vector(0, 13, 0), ivory, index)
			end
		end
	elseif effect == "Lightning" then
		for index = -2, 2 do
			local cloud = piece(model, "Thunderhead", {26, 7 + index % 3 * 3, 17},
				{index * 7, 34 + index % 2 * 3, index % 2 * 6}, color:Lerp(dark, 0.45), "Ball",
				{index * 4, index * 12, index * -6})
			cloud.Transparency = 0.62
			particle(cloud, Vector3.zero, {
				color = dark, fade = color, size = 18, endSize = 27, life = 1.7, rate = 5,
				speed = 3.2, spread = 75, opacity = 0.24, emission = 0.25,
			})
		end
		local warning = rgb(255, 100, 134)
		streak(model, Vector(0, 34, 0), Vector(0, -22, 0), warning, 0.46)
		ring(model, Vector3.zero, Motion.LightningRadius, warning, "LightningBoundary")
		boundaryPosts(model, Vector3.zero, Motion.LightningRadius, warning)
		bolt(model, Vector(0, 34, 0), Vector(0, -22, 0), ice)
	elseif effect == "Debris" then
		for index, offset in ipairs(cells) do
			ruinModel(index, offset).Parent = model
		end
	elseif effect == "Meteor" then
		local lateral = Vector(path.Z, 0, -path.X).Unit
		for index = 1, 3 do
			local offset = Motion.MeteorOffset(path, index)
			local lane = modelWithCore("MeteorLane" .. index, {1, 1, 1})
			for _, side in {-1, 1} do
				local edge = offset + lateral * (Motion.MeteorRadius * side)
				local rail = streak(model, edge, edge + path, rgb(255, 127, 68), 0.74)
				rail.Name = "MeteorRail"
				rail.LightEmission = 0.4
				rail:SetAttribute("MeteorLane", index)
			end
			local center = streak(model, offset, offset + path, gold, 0.36)
			center.Name = "PathBeam"
			for _, along in {0.19, 0.55, 0.83} do
				local tip = offset + path * along
				for _, side in {-1, 1} do
					local arrow = streak(model, tip - path.Unit * 6 + lateral * (side * 4), tip, gold, 0.46)
					arrow.Name = "PathBeam"
				end
			end
			for fragment = 1, 5 do
				local basalt = fragment % 2 == 0 and rgb(96, 44, 36) or rgb(55, 42, 51)
				piece(lane, "MeteorFragment", {4.65, 5.3 - fragment * 0.23, 4.1},
					{(fragment - 3) * 0.67, (fragment % 2) * 0.65, 0}, basalt,
					"Wedge", {index * 31, fragment * 89, fragment * 39}, Enum.Material.Basalt)
				piece(lane, "MeteorFragment", {0.46, 2.4, 1.5},
					{(fragment - 3) * 1.2, 0.9 + (fragment % 2) * 1.3, fragment % 2 == 0 and -1.25 or 1.25},
					fragment % 2 == 0 and gold or rgb(255, 92, 36),
					"Wedge", {index * 31, fragment * 89, fragment * 39}, glow)
			end
			local wake = streak(lane, Vector3.zero, -path.Unit * 26, rgb(255, 135, 49), 6, true)
			wake.Name = "MeteorWake"
			wake.Width1 = 0.2
			wake.Color = ColorSequence.new(rgb(255, 224, 142), rgb(238, 61, 19))
			wake.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.12),
				NumberSequenceKeypoint.new(0.35, 0.42),
				NumberSequenceKeypoint.new(1, 1),
			})
			particle(lane.PrimaryPart, Vector3.zero, {
				name = "MeteorTrail", texture = sparkTexture, color = rgb(255, 191, 89), fade = rgb(255, 73, 28),
				size = 1.18, endSize = 0.17, life = 0.52, rate = 28, speed = 6, spread = 85,
				opacity = 0.04, emission = 0.86, enabled = false,
			})
			particle(lane.PrimaryPart, Vector3.zero, {
				name = "MeteorTrail", color = rgb(91, 64, 79), fade = rgb(119, 82, 64), size = 3.15, endSize = 6,
				life = 0.68, rate = 13, speed = 3, spread = 90, opacity = 0.53, emission = 0.13, enabled = false,
			})
			lane:PivotTo(CFrame.new(offset))
			lane.Parent = model
		end
	elseif effect == "Fog" then
		for index = -2, 2 do
			particle(model.PrimaryPart, Vector(index * 11, index % 2 * 3 - 6, (index % 3 - 1) * 9), {
				color = color:Lerp(dark, 0.45), fade = rgb(144, 118, 173), size = 24, endSize = 32,
				life = 2.25, rate = 5, speed = 6, direction = Enum.NormalId.Right, spread = 50,
				opacity = 0.39, emission = 0.22,
			})
		end
	else
		if effect == "Wind" then
			local wind = Instance.new("ParticleEmitter")
			wind.Texture = "rbxasset://textures/particles/smoke_main.dds"
			wind.Color = ColorSequence.new(color, ivory)
			wind.LightEmission = 0.35
			wind.Size = NumberSequence.new(4, 9)
			wind.Transparency = NumberSequence.new(0.28, 1)
			wind.Lifetime = NumberRange.new(0.5, 0.9)
			wind.EmissionDirection = Enum.NormalId.Right
			wind.Speed = NumberRange.new(29, 42)
			wind.SpreadAngle = Vector2.new(12, 20)
			wind.Rate = 14
			local nozzle = Instance.new("Attachment")
			nozzle.Position = Vector(-31, 0, 0)
			nozzle.Parent = model.PrimaryPart
			wind.Parent = nozzle
		end
		if effect == "Heat" then
			streak(model, Vector(0, -12, 0), path + Vector(0, -12, 0), gold, 0.6).Name = "PathBeam"
			local front = streak(model, Vector(-41, 0, 23), Vector(41, 0, 23), gold, 2.1, true)
			front.Color = ColorSequence.new(rgb(255, 88, 30), gold)
			for _, x in {-27, 0, 27} do
				particle(model.PrimaryPart, Vector(x, -3, 17), {
					texture = sparkTexture, color = gold, fade = rgb(255, 59, 35), size = 1.75, endSize = 0.25,
					life = 0.6, rate = 12, speed = 9, opacity = 0.17, emission = 0.7,
				})
			end
		end
		if effect == "Magnetic" then ring(model, Vector3.zero, 33, color, "MagneticPulse") end
		for index = -2, 2 do
			local start = Vector(-31, index * 4, index * 5)
			local finish = Vector(31, index * 4 + 5, index * 5)
			local line = streak(model, start, finish, color, effect == "Heat" and 4 or 2.2)
			line.Attachment0.Axis = Vector(0.91, 0.42, 0)
			line.Attachment1.Axis = Vector(0.91, -0.42, 0)
			line.CurveSize0 = 27
			line.CurveSize1 = 24
			line.Segments = 12
			line.LightEmission = effect == "Heat" and 0.48 or 0.29
			line.Color = ColorSequence.new(color:Lerp(dark, 0.35), color:Lerp(ivory, 0.36))
			line.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.9),
				NumberSequenceKeypoint.new(0.42, 0.28),
				NumberSequenceKeypoint.new(1, 0.94),
			})
			if effect == "Magnetic" then
				piece(model, "ChargedCrystal", {2.4, 7.8, 2.7}, {index * 10, 0, index * 4},
					color, "Wedge", {index * 30, index * 45, index * 18}, glow)
				particle(model.PrimaryPart, Vector(index * 10, 2, index * 4), {
					texture = sparkTexture, color = color, fade = ice, size = 1.25, endSize = 0.2, life = 0.46,
					rate = 4, speed = 5, opacity = 0.28, emission = 0.72,
				})
			end
		end
	end
	return model
end

function Art.Spike()
	local model = modelWithCore("Paku Sihir", {1, 1, 1})
	piece(model, "Spike", {0.7, 0.8, 4.4}, {0, 0, 0}, violet, "Wedge", {0, 180, 0}, glow)
	accent(model, "SpikeFacet", {0.42, 0.35, 2.7}, {0, 0.3, -0.42}, rgb(217, 193, 255), "Wedge", {0, 180, 0}, glow)
	local wake = streak(model, Vector(0, 0, 1), Vector(0, 0, 12), violet, 1.2)
	wake.Width1 = 0.06
	wake.Color = ColorSequence.new(rgb(236, 219, 255), violet)
	wake.Transparency = NumberSequence.new(0.14, 1)
	particle(model.PrimaryPart, Vector(0, 0, 1), {
		texture = sparkTexture, color = rgb(212, 181, 255), fade = violet, size = 0.48, endSize = 0.12,
		life = 0.33, rate = 18, speed = 4, direction = Enum.NormalId.Back, opacity = 0.20, emission = 0.62,
	})
	return model
end

return Art
