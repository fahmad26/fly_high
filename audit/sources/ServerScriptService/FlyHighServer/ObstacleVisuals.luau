--!strict
-- Original Blender meshes plus restrained native weather volumes.
-- Templates contain no scripts. Gameplay, damage and pacing stay in their managers.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Visuals = {}
local smoke = "rbxasset://textures/particles/smoke_main.dds"
local weatherTexture = "rbxassetid://94436880933325"
local softWhite = Color3.fromRGB(223, 233, 242)

function Visuals.Clone(name: string): Model?
	local templates = ReplicatedStorage.FlyHigh.Templates:FindFirstChild("ObstacleMeshes")
	local source = templates and templates:FindFirstChild(name)
	if not source or not source:IsA("Model") or source:GetAttribute("ImportVerified") ~= true then
		return nil
	end
	local model = source:Clone()
	model:PivotTo(CFrame.identity)
	model:SetAttribute("VisualRevision", 2)
	return model
end

function Visuals.Attach(name: string, target: Model, pose: CFrame, scale: number, role: string?): boolean
	local model = Visuals.Clone(name)
	if not model then return false end
	model:ScaleTo(model:GetScale() * scale)
	model:PivotTo(pose)
	local core = model.PrimaryPart
	for _, child in model:GetChildren() do
		if child:IsA("BasePart") and child ~= core then
			if role then child.Name = role end
			child.Parent = target
		end
	end
	model:Destroy()
	target:SetAttribute("VisualRevision", 2)
	return true
end

function Visuals.Enemy(name: string): Model?
	if name ~= "WildBird" then
		return Visuals.Clone(name)
	end
	local flock = Visuals.Clone("Seagull")
	if not flock then return nil end
	flock.Name = "WildBird"
	for _, side in {-1, 1} do
		local bird = Visuals.Clone(side < 0 and "Seagull" or "Eagle")
		if bird then
			bird:ScaleTo(bird:GetScale() * 0.72)
			local center = Vector3.new(side * 7, side * 1.5, 4)
			bird:PivotTo(CFrame.new(center))
			local core = bird.PrimaryPart
			for _, part in bird:GetChildren() do
				if part:IsA("BasePart") and part ~= core then
					part:SetAttribute("FlockCenter", center)
					part:SetAttribute("JointScale", 0.72)
					part.Parent = flock
				end
			end
			bird:Destroy()
		end
	end
	return flock
end

local function emitter(root: BasePart, name: string, position: Vector3, color: Color3,
	size: number, rate: number, life: number): ParticleEmitter
	local at = Instance.new("Attachment")
	at.Name = name .. "Origin"
	at.Position = position
	at.Parent = root
	local fx = Instance.new("ParticleEmitter")
	fx.Name = name
	fx.Texture = smoke
	fx.Color = ColorSequence.new(color, color:Lerp(softWhite, 0.32))
	fx.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, size * 0.7),
		NumberSequenceKeypoint.new(0.35, size), NumberSequenceKeypoint.new(1, size * 1.35)})
	fx.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.18, 0.46), NumberSequenceKeypoint.new(0.65, 0.65),
		NumberSequenceKeypoint.new(1, 1)})
	fx.Lifetime = NumberRange.new(life * 0.8, life)
	fx.Rate = rate
	fx.Speed = NumberRange.new(0.6, 2.0)
	fx.Rotation = NumberRange.new(-180, 180)
	fx.RotSpeed = NumberRange.new(-18, 18)
	fx.SpreadAngle = Vector2.new(45, 45)
	fx.LightEmission = 0.08
	fx.LightInfluence = 0.5
	fx.LockedToPart = true
	fx.Parent = at
	return fx
end

function Visuals.EnemyEffects(model: Model, name: string)
	local root = model.PrimaryPart
	if not root then return end
	if name == "GuardianDrone" then
		local aperture = model:FindFirstChild("Aperture")
		if aperture and aperture:IsA("MeshPart") then
			aperture.TextureID = ""
			aperture.Color = Color3.fromRGB(129, 224, 255)
			aperture.Material = Enum.Material.Neon
		end
	elseif name == "ShadowPhantom" then
		local fx = emitter(root, "CloakMist", Vector3.new(0, -2, 0.6),
			Color3.fromRGB(117, 84, 151), 0.8, 6, 0.65)
		fx.EmissionDirection = Enum.NormalId.Bottom
	elseif name == "Hailstone" then
		emitter(root, "IceDust", Vector3.new(0, 1, 0), Color3.fromRGB(180, 228, 240), 0.35, 4, 0.45)
	elseif name == "CelestialPhoenix" or name == "FireBee" then
		local fx = emitter(root, "TailEmbers", Vector3.new(0, 0, name == "FireBee" and 2.2 or 5.5),
			Color3.fromRGB(244, 165, 63), 0.5, name == "FireBee" and 4 or 9, 0.5)
		fx.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		fx.EmissionDirection = Enum.NormalId.Back
		fx.Speed = NumberRange.new(1, 3)
		fx.LightEmission = 0.6
		fx.Size = NumberSequence.new(0.45, 0)
		fx.LockedToPart = false
	end
end


-- Weather must remain readable before particle populations fill and at low quality.
local function weatherDensity(fx: ParticleEmitter, opacity: number)
	fx:SetAttribute("WeatherVapor", true)
	fx.Texture = weatherTexture
	fx.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, math.min(0.4, opacity + 0.2)),
		NumberSequenceKeypoint.new(0.08, opacity),
		NumberSequenceKeypoint.new(0.78, math.min(0.65, opacity + 0.12)),
		NumberSequenceKeypoint.new(1, 1),
	})
	fx.LightInfluence = 0.08
	fx.LightEmission = 0.04
end

local function weatherVolume(model: Model, start: Vector3, finish: Vector3,
	width0: number, width1: number, color: Color3, transparency: number): Beam?
	local root = model.PrimaryPart
	if not root then return nil end
	local a = Instance.new("Attachment")
	a.Name = "WeatherVolumeStart"
	a.Position = start
	a.Parent = root
	local b = Instance.new("Attachment")
	b.Name = "WeatherVolumeEnd"
	b.Position = finish
	b.Parent = root
	local beam = Instance.new("Beam")
	beam.Name = "WeatherVolume"
	beam.Attachment0, beam.Attachment1 = a, b
	beam.FaceCamera = true
	beam.Texture = weatherTexture
	beam.TextureMode = Enum.TextureMode.Stretch
	beam.TextureLength = 1
	beam.TextureSpeed = 0
	beam.Color = ColorSequence.new(color)
	beam.Transparency = NumberSequence.new(transparency)
	beam.Width0, beam.Width1 = width0, width1
	beam.LightInfluence = 0
	beam.LightEmission = 0
	beam.Segments = 12
	beam.Parent = root
	return beam
end

function Visuals.Vortex(model: Model, color: Color3, storm: boolean)
	local root = model.PrimaryPart
	if not root then return end
	model:SetAttribute("WeatherVisualRevision", 3)
	local bodyColor = storm and Color3.fromRGB(174, 121, 47) or Color3.fromRGB(91, 115, 146)
	-- Translucent vapour funnel from the Zone 2 storm kit; the flat camera-facing volume alone read as a
	-- pale blob (review 15 Nov). The model already spins, so the textured sheaths swirl with it.
	local assets = ReplicatedStorage.FlyHigh:FindFirstChild("EnvironmentAssets")
	local kit = assets and assets:FindFirstChild("StormZone2")
	local hasFunnel = false
	if kit and kit:FindFirstChild("FunnelShell") and kit:FindFirstChild("FunnelCore") then
		hasFunnel = true
		local s = storm and 0.24 or 0.2
		for _, spec in {{"FunnelCore", 0.55, 0.3}, {"FunnelShell", 0.85, 0.45}, {"FunnelShell", 1.05, 0.7}} do
			local template = kit[spec[1]] :: MeshPart
			local piece = template:Clone()
			local scale = Vector3.new(s * spec[2], s, s * spec[2])
			piece.Name = "VortexFunnel"
			piece.Size = template.Size * scale
			piece.CFrame = CFrame.new(0, -23, 0) * CFrame.new(((template:GetAttribute("SourceCenter") or Vector3.zero) :: Vector3) * scale)
			piece.Transparency = spec[3]
			piece.Color = storm and Color3.fromRGB(255, 214, 160) or Color3.new(1, 1, 1)
			piece.Anchored = true
			piece.CanCollide, piece.CanTouch, piece.CanQuery = false, false, false
			piece.CastShadow = false
			piece:SetAttribute("Decoration", true)
			piece.Parent = model
		end
	end
	weatherVolume(model, Vector3.new(0, -23, 0), Vector3.new(0, 20, 0),
		storm and 7 or 4, storm and 49 or 36, bodyColor, hasFunnel and 0.7 or 0.05)
	weatherVolume(model, Vector3.new(0, -20, 2), Vector3.new(0, 18, 2),
		storm and 6 or 3, storm and 40 or 29, bodyColor:Lerp(softWhite, 0.12), hasFunnel and 0.8 or 0.25)
	-- Radius grows upward; the overlapping smoke masses read as one funnel.
	for layer = 0, 4 do
		local y = -18 + layer * 8
		local radius = (storm and 2.8 or 1.8) + layer * (storm and 3.0 or 2.2)
		for arm = 0, 1 do
			local angle = layer * 1.7 + arm * math.pi
			local fx = emitter(root, "FunnelVapor", Vector3.new(math.cos(angle) * radius,
				y, math.sin(angle) * radius), color:Lerp(Color3.fromRGB(43, 53, 77), 0.48),
				hasFunnel and 3 + layer * 1.6 or 7 + layer * 3, 4, 1.5)
			weatherDensity(fx, hasFunnel and 0.55 or 0.12)
			fx.Color = ColorSequence.new(bodyColor, bodyColor:Lerp(softWhite, 0.15))
			fx.RotSpeed = NumberRange.new(34, 58)
			local attachment = fx.Parent :: Attachment
			attachment:SetAttribute("SpiralRate", 0.7 + layer * 0.12)
		end
	end
	for _, item in model:GetDescendants() do
		if item:IsA("Beam") and item.Name == "VortexRibbon" then
			item.Texture = weatherTexture
			item.TextureMode = Enum.TextureMode.Stretch
			item.TextureLength = 1
			item.TextureSpeed = 0
			item.Segments = 28
			item.LightEmission = 0.08
			item.LightInfluence = 0
			item.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.48), NumberSequenceKeypoint.new(0.35, 0.08),
				NumberSequenceKeypoint.new(0.78, 0.15), NumberSequenceKeypoint.new(1, 0.65)})
		end
	end
end

function Visuals.Thunderheads(model: Model, color: Color3)
	model:SetAttribute("WeatherVisualRevision", 3)
	local root = model.PrimaryPart
	if not root then return end
	local blobs = {
		{Vector3.new(0, 35, 0), Vector3.new(40, 11, 24)},
		{Vector3.new(-12, 37, 1), Vector3.new(22, 15, 22)},
		{Vector3.new(9, 40, 0), Vector3.new(25, 18, 23)},
		{Vector3.new(17, 36, 2), Vector3.new(20, 12, 20)},
		{Vector3.new(-4, 42, 2), Vector3.new(28, 13, 22)},
		{Vector3.new(1, 31, -1), Vector3.new(33, 6, 19)},
	}
	-- Semi-realistic cumulus mesh from the Zone 2 storm kit; the primitive balls read as a pale disc.
	local assets = ReplicatedStorage.FlyHigh:FindFirstChild("EnvironmentAssets")
	local kit = assets and assets:FindFirstChild("StormZone2")
	local mesh = kit and kit:FindFirstChild("Congestus")
	if mesh and mesh:IsA("MeshPart") then
		for i, spec in {
			{Vector3.new(0, 38, 0), 0.15, 0, Color3.fromRGB(96, 104, 132)},
			{Vector3.new(-13, 35, 4), 0.1, 2.1, Color3.fromRGB(84, 92, 120)},
			{Vector3.new(14, 36, -3), 0.11, 4.2, Color3.fromRGB(90, 98, 126)},
		} do
			local cloud = mesh:Clone()
			cloud.Name = "Thunderhead"
			local s = spec[2]
			cloud.Size = mesh.Size * s
			local center = (mesh:GetAttribute("SourceCenter") or Vector3.zero) :: Vector3
			-- Kit meshes rest on their base; centre the pieces on the old blob layout.
			cloud.CFrame = CFrame.new(spec[1]) * CFrame.Angles(0, spec[3], 0)
				* CFrame.new((center - Vector3.new(0, mesh.Size.Y * 0.5, 0)) * s)
			cloud.Color = spec[4]:Lerp(color, 0.12)
			cloud.Material = Enum.Material.Fabric
			cloud.Transparency = i == 1 and 0.05 or 0.2
			cloud.Anchored = true
			cloud.CanCollide, cloud.CanTouch, cloud.CanQuery = false, false, false
			cloud.CastShadow = false
			cloud.Parent = model
			-- Small, dim base wisps only; a wide fringe drew a pale disc around the cloud (QA 16 Nov).
			local fringe = emitter(cloud, "CloudFringe", Vector3.new(0, -cloud.Size.Y * 0.4, 0), spec[4]:Lerp(Color3.new(0, 0, 0), 0.25),
				cloud.Size.X * 0.3, 3, 1.9)
			fringe.Speed = NumberRange.new(0.4, 1.2)
			weatherDensity(fringe, 0.5)
		end
		return
	end
	for i, info in blobs do
		local part = Instance.new("Part")
		part.Name = "Thunderhead"
		part.Shape = Enum.PartType.Ball
		part.Size = info[2]
		part.CFrame = CFrame.new(info[1])
		part.Color = i == 6 and Color3.fromRGB(51, 61, 85)
			or Color3.fromRGB(117, 128, 151):Lerp(color, 0.14)
		part.Material = Enum.Material.SmoothPlastic
		part.Transparency = 0.3
		part.Anchored = true
		part.CanCollide, part.CanTouch, part.CanQuery = false, false, false
		part.CastShadow = false
		part.Parent = model
		local fringe = emitter(part, "CloudFringe", Vector3.zero, part.Color,
			math.max(part.Size.X, part.Size.Z) * 0.72, 5, 1.9)
		fringe.Speed = NumberRange.new(0.4, 1.2)
		weatherDensity(fringe, 0.13)
	end
end

local CHEVRON = "rbxassetid://124478271519029" -- FH_HazardChevron (decal 92852486345537)
local FLOW = "rbxassetid://85832877682740" -- FH_HazardFlow (decal 128396373801839)

-- Shimmering, non-colliding volume that matches the hazard's hit area. Decoration keeps it out of queries.
local function dangerField(parent: Instance, name: string, shape: Enum.PartType, size: Vector3, cf: CFrame,
	color: Color3, transparency: number): Part
	local field = Instance.new("Part")
	field.Name = name
	field.Shape = shape
	field.Size = size
	field.CFrame = cf
	field.Color = color
	field.Material = Enum.Material.ForceField
	-- Faint shimmer only; the weather/particle art carries the look (semi-realistic pass, 16 Nov).
	field.Transparency = math.max(transparency, 0.35)
	if shape == Enum.PartType.Block then
		-- Soft energy bubble instead of a hard glass box: the box read as a glass crate (QA 16 Nov).
		local bubble = Instance.new("SpecialMesh")
		bubble.MeshType = Enum.MeshType.Sphere
		bubble.Parent = field
	end
	field.Anchored = true
	field.CanCollide, field.CanTouch, field.CanQuery = false, false, false
	field.CastShadow = false
	field:SetAttribute("Decoration", true)
	field.Parent = parent
	return field
end

-- Wide chevron ribbon along the travel path. Named PathBeam so it switches off when the hazard goes live.
local function travelLane(model: Model, start: Vector3, finish: Vector3, width: number, color: Color3,
	name: string?): Beam?
	local root = model.PrimaryPart
	if not root then return nil end
	local a = Instance.new("Attachment")
	a.Name = "LaneStart"
	a.Position = start
	a.Parent = root
	local b = Instance.new("Attachment")
	b.Name = "LaneEnd"
	b.Position = finish
	b.Parent = root
	local beam = Instance.new("Beam")
	beam.Name = name or "PathBeam"
	beam.Attachment0, beam.Attachment1 = a, b
	beam.FaceCamera = true
	beam.Texture = CHEVRON
	beam.TextureMode = Enum.TextureMode.Wrap
	-- Narrow, bright chevrons: a full hitbox-wide ribbon read as huge faint zig-zags (QA 16 Nov).
	local lane = math.min(width, 18)
	beam.TextureLength = lane * 0.9
	beam.TextureSpeed = 0.9
	beam.Color = ColorSequence.new(color:Lerp(Color3.new(1, 1, 1), 0.35))
	beam.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.9), NumberSequenceKeypoint.new(0.12, 0.15),
		NumberSequenceKeypoint.new(0.88, 0.15), NumberSequenceKeypoint.new(1, 0.9)})
	beam.Width0, beam.Width1 = lane, lane
	beam.LightEmission = 0.55
	beam.LightInfluence = 0
	beam.Segments = 1
	beam.Parent = a
	return beam
end

local function flowSheet(model: Model, start: Vector3, finish: Vector3, width: number, color: Color3,
	speed: number, transparency: number): Beam?
	local beam = travelLane(model, start, finish, width, color, "HazardFlow")
	if not beam then return nil end
	beam.Texture = FLOW
	beam.Width0, beam.Width1 = width, width
	beam.TextureLength = math.max(20, (finish - start).Magnitude * 0.6)
	beam.TextureSpeed = speed
	beam.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.2, transparency),
		NumberSequenceKeypoint.new(0.8, transparency), NumberSequenceKeypoint.new(1, 1)})
	return beam
end

-- Readable telegraphs on top of the weather art (review 15 Nov: hazards read as single laser lines).
-- Volumes mirror ObstacleManager.touches / ObstacleMotion radii; gameplay is unchanged.
function Visuals.Telegraph(model: Model, effect: string, color: Color3, path: Vector3)
	local root = model.PrimaryPart
	if not root then return end
	model:SetAttribute("TelegraphRevision", 1)
	local hot = color:Lerp(Color3.new(1, 1, 1), 0.15)
	-- Thin straight guide lines are replaced by the chevron lane.
	for _, item in model:GetDescendants() do
		if item:IsA("Beam") and item.Name == "PathBeam" then item.Enabled = false end
	end
	if effect == "Wind" or effect == "Heat" then
		dangerField(model, "DangerVolume", Enum.PartType.Block, Vector3.new(86, 50, 50), CFrame.identity, hot, 0)
		if path.Magnitude > 1 then travelLane(model, Vector3.zero, path, 46, hot) end
		if effect == "Wind" then
			-- Wind-borne dust and petals make the crosswind read as weather rather than an energy field.
			local gust = emitter(root, "WindDebris", Vector3.new(-40, 0, 0), Color3.fromRGB(235, 228, 205), 0.8, 14, 2.2)
			gust.Texture = "rbxasset://textures/particles/sparkles_main.dds"
			gust.EmissionDirection = Enum.NormalId.Right
			gust.Speed = NumberRange.new(36, 48)
			gust.SpreadAngle = Vector2.new(10, 18)
			gust.RotSpeed = NumberRange.new(-220, 220)
			gust.LightEmission = 0.1
			gust.LockedToPart = false
			for _, y in {-14, 0, 14} do
				flowSheet(model, Vector3.new(-41, y, 0), Vector3.new(41, y + 2, 0), 18, Color3.fromRGB(205, 240, 255), 2.4, 0.35)
			end
		else
			for _, x in {-28, 0, 28} do
				flowSheet(model, Vector3.new(x, -23, 0), Vector3.new(x, 24, 0), 26, Color3.fromRGB(255, 196, 120), 1.6, 0.45)
			end
		end
	elseif effect == "Fog" then
		dangerField(model, "DangerVolume", Enum.PartType.Ball, Vector3.one * 66, CFrame.identity, Color3.fromRGB(170, 130, 235), 0)
		if path.Magnitude > 1 then travelLane(model, Vector3.zero, path, 50, Color3.fromRGB(170, 130, 230)) end
	elseif effect == "Tornado" then
		if path.Magnitude > 1 then travelLane(model, Vector3.new(0, -14, 0), path + Vector3.new(0, -14, 0), 30, Color3.fromRGB(190, 225, 245)) end
	elseif effect == "Magnetic" then
		dangerField(model, "DangerVolume", Enum.PartType.Ball, Vector3.one * 66, CFrame.identity, Color3.fromRGB(90, 255, 215), 0)
	elseif effect == "Lightning" then
		-- Strike column: radius 17, from -37 to +49 (Motion.LightningRadius/Low/High).
		dangerField(model, "DangerVolume", Enum.PartType.Block, Vector3.new(36, 90, 36),
			CFrame.new(0, 6, 0), Color3.fromRGB(255, 130, 170), 0)
	elseif effect == "Storm" then
		dangerField(model, "DangerVolume", Enum.PartType.Ball, Vector3.one * 50, CFrame.identity, Color3.fromRGB(255, 150, 70), 0)
	elseif effect == "Debris" then
		for _, ruin in model:GetChildren() do
			if ruin:IsA("Model") and ruin.Name:match("^Ruin%d") then
				local halo = dangerField(ruin, "DangerHalo", Enum.PartType.Ball, Vector3.one * 46, ruin:GetPivot(),
					Color3.fromRGB(255, 200, 120), 0.3)
				local dust = emitter(halo, "RuinDust", Vector3.zero, Color3.fromRGB(176, 150, 118), 9, 6, 1.6)
				weatherDensity(dust, 0.4)
			end
		end
	elseif effect == "Meteor" then
		local lateral = Vector3.new(path.Z, 0, -path.X).Unit
		for index = 1, 3 do
			local offset = lateral * ((index - 2) * 56)
			local lane = travelLane(model, offset, offset + path, 36, Color3.fromRGB(255, 150, 80), "MeteorRail")
			if lane then
				lane:SetAttribute("MeteorLane", index)
			end
		end
	end
end

function Visuals.Weather(model: Model, effect: string, color: Color3)
	if effect == "Heat" or effect == "Wind" or effect == "Fog" then
		model:SetAttribute("WeatherVisualRevision", 3)
	end
	local root = model.PrimaryPart
	if not root then return end
	if effect == "Heat" then
		weatherVolume(model, Vector3.new(-42, -1, 19), Vector3.new(42, -1, 19),
			29, 29, Color3.fromRGB(218, 126, 43), 0.18)
		for _, x in {-24, 0, 24} do
			local fx = emitter(root, "HeatHaze", Vector3.new(x, 0, 19),
				Color3.fromRGB(228, 158, 96), 17, 3, 1.15)
			weatherDensity(fx, 0.32)
			fx.LightEmission = 0.12
		end
	elseif effect == "Wind" then
		for _, y in {-7, 1, 9} do
			local stream = weatherVolume(model, Vector3.new(-34, y, 0), Vector3.new(34, y + 3, 0),
				6, 10, Color3.fromRGB(92, 175, 215), 0.12)
			if stream then
				stream.TextureMode = Enum.TextureMode.Stretch
				stream.TextureLength = 1
				stream.TextureSpeed = 0
			end
			local fx = emitter(root, "CrosswindMist", Vector3.new(-31, y, 0), color, 5, 4, 1.65)
			weatherDensity(fx, 0.2)
			fx.EmissionDirection = Enum.NormalId.Right
			fx.Speed = NumberRange.new(34, 46)
			fx.SpreadAngle = Vector2.new(5, 9)
			fx.LockedToPart = false
		end
	elseif effect == "Fog" then
		weatherVolume(model, Vector3.new(-41, -2, -4), Vector3.new(41, -2, -4),
			42, 42, Color3.fromRGB(92, 66, 131), 0.15)
		weatherVolume(model, Vector3.new(-35, 6, 8), Vector3.new(35, 6, 8),
			34, 34, Color3.fromRGB(120, 91, 159), 0.32)
		for _, x in {-24, 0, 24} do
			local fx = emitter(root, "VoidFogLayers", Vector3.new(x, -2, x * 0.2),
				Color3.fromRGB(99, 84, 126), 26, 4, 1.9)
			fx.Speed = NumberRange.new(2, 4)
			fx.EmissionDirection = Enum.NormalId.Right
			weatherDensity(fx, 0.24)
		end
	end
	for _, item in model:GetDescendants() do
		if item:IsA("Beam") and item.Name == "WarningBeam" and item.CurveSize0 > 20 then
			item.Texture = smoke
			item.TextureMode = Enum.TextureMode.Stretch
			item.TextureLength = 1
			item.TextureSpeed = 0
			item.LightEmission = 0.08
			item.LightInfluence = 0
			item.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.65), NumberSequenceKeypoint.new(0.25, 0.12),
				NumberSequenceKeypoint.new(0.75, 0.18), NumberSequenceKeypoint.new(1, 0.7)})
			item.Segments = 24
		end
	end
end

function Visuals.PolishStorm(model: Model)
	model:SetAttribute("WeatherVisualRevision", 3)
	for _, object in model:GetDescendants() do
		if object:IsA("BasePart") and object ~= model.PrimaryPart then
			if object.Name == "SculptedStormFront" then
				object.Color = Color3.fromRGB(61, 75, 105)
				object:SetAttribute("WeatherOpacity", 0.4)
			elseif object.Name == "RearBillowingRidge" then
				object.Color = Color3.fromRGB(85, 95, 125)
				object:SetAttribute("WeatherOpacity", 0.5)
			elseif object.Name == "SilverCloudCrown" then
				object.Color = Color3.fromRGB(163, 178, 199)
				object:SetAttribute("WeatherOpacity", 0.58)
			end
		end
	end
	local root = model.PrimaryPart
	if root then
		for _, x in {-144, -72, 0, 72, 144} do
			local crown = emitter(root, "StormCloudCrown", Vector3.new(x, 24, -12),
				Color3.fromRGB(137, 151, 173), 80, 4, 1.7)
			weatherDensity(crown, 0.16)
			local underside = emitter(root, "StormCloudEdges", Vector3.new(x, -24, -16),
				Color3.fromRGB(83, 99, 129), 70, 4, 1.7)
			weatherDensity(underside, 0.12)
		end
	end
end

return Visuals
