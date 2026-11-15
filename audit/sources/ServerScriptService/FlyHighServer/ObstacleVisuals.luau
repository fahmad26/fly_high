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
	weatherVolume(model, Vector3.new(0, -23, 0), Vector3.new(0, 20, 0),
		storm and 7 or 4, storm and 49 or 36, bodyColor, 0.05)
	weatherVolume(model, Vector3.new(0, -20, 2), Vector3.new(0, 18, 2),
		storm and 6 or 3, storm and 40 or 29, bodyColor:Lerp(softWhite, 0.12), 0.25)
	-- Radius grows upward; the overlapping smoke masses read as one funnel.
	for layer = 0, 4 do
		local y = -18 + layer * 8
		local radius = (storm and 2.8 or 1.8) + layer * (storm and 3.0 or 2.2)
		for arm = 0, 1 do
			local angle = layer * 1.7 + arm * math.pi
			local fx = emitter(root, "FunnelVapor", Vector3.new(math.cos(angle) * radius,
				y, math.sin(angle) * radius), color:Lerp(Color3.fromRGB(43, 53, 77), 0.48),
				7 + layer * 3, 4, 1.5)
			weatherDensity(fx, 0.12)
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
