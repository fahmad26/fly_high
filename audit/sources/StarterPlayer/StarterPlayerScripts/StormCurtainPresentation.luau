local RunService = game:GetService("RunService")
local storms = workspace:WaitForChild("FlyHighLargeChallenges")

local function palette(name, shadow, cloud, rim, glow, accent)
	return {
		name = name,
		shadow = Color3.fromHex(shadow),
		cloud = Color3.fromHex(cloud),
		rim = Color3.fromHex(rim),
		glow = Color3.fromHex(glow),
		accent = Color3.fromHex(accent),
	}
end

local palettes = {
	[1800] = palette("GUGUS TOPAN", "182E45", "365975", "88B3CB", "A6EDFF", "4096C8"),
	[3600] = palette("ARUS ES", "1F3256", "4C6D9D", "B1D1E5", "D9FAFF", "6B8AF3"),
	[5400] = palette("BADAI BARA", "4D242F", "87453F", "E39862", "FFB352", "F34D31"),
	[7200] = palette("PUSARAN AURORA", "282044", "554381", "8B98BC", "7DFFD7", "A26DFF"),
	[9000] = palette("BADAI GERBANG", "342855", "715488", "CFADD0", "FFE497", "F794B7"),
}

local warningColor = Color3.fromRGB(255, 180, 72)
local smokeTexture = "rbxasset://textures/particles/smoke_main.dds"
local visuals = {}

local function attach(root, position)
	local attachment = Instance.new("Attachment")
	attachment.Name = "StormEffect"
	attachment.Position = position
	attachment.Parent = root
	return attachment
end

local function beam(root, start, finish, width, color)
	local line = Instance.new("Beam")
	line.Attachment0 = attach(root, start)
	line.Attachment1 = attach(root, finish)
	line.FaceCamera = true
	line.Width0 = width
	line.Width1 = width
	line.Color = ColorSequence.new(color)
	line.LightInfluence = 0
	line.LightEmission = 0.85
	line.Parent = line.Attachment0
	return line
end

local function mist(root, position, size, colors, rotation)
	local emitter = Instance.new("ParticleEmitter")
	emitter.Texture = smokeTexture
	emitter.Color = ColorSequence.new(colors.cloud, colors.rim)
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, size * 0.8),
		NumberSequenceKeypoint.new(1, size),
	})
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.28),
		NumberSequenceKeypoint.new(0.24, 0.15),
		NumberSequenceKeypoint.new(0.70, 0.45),
		NumberSequenceKeypoint.new(1, 1),
	})
	emitter.Rotation = NumberRange.new(rotation - 30, rotation + 30)
	emitter.RotSpeed = NumberRange.new(-5, 5)
	emitter.Lifetime = NumberRange.new(6, 8)
	emitter.Rate = 0.25
	emitter.Speed = NumberRange.new(1.5, 3)
	emitter.EmissionDirection = Enum.NormalId.Right
	emitter.LightInfluence = 0
	emitter.LightEmission = 0.26
	emitter.LockedToPart = true
	local source = attach(root, position)
	emitter.Parent = source
	emitter:Emit(2)
	return { source = source, position = position }
end

local function title(root, colors, bottom)
	local sign = Instance.new("BillboardGui")
	sign.Name = "StormRouteSign"
	sign.Size = UDim2.fromOffset(290, 50)
	sign.MaxDistance = 390
	sign.StudsOffsetWorldSpace = Vector3.new(0, bottom - 14, 0)
	sign.Adornee = root

	local caption = Instance.new("TextLabel")
	caption.Size = UDim2.fromScale(1, 1)
	caption.BackgroundTransparency = 1
	caption.Text = colors.name .. "\n↓  LEWATI DI BAWAH"
	caption.TextColor3 = colors.glow
	caption.TextStrokeColor3 = Color3.fromRGB(13, 18, 32)
	caption.TextStrokeTransparency = 0.1
	caption.Font = Enum.Font.GothamBold
	caption.TextSize = 16
	caption.Parent = sign
	sign.Parent = root
end

local function present(model)
	if visuals[model] or not model:IsA("Model") then return end
	local root = model:WaitForChild("StormCore", 5)
	local zone = model:GetAttribute("ZoneKm")
	local colors = palettes[zone]
	if not root or model.Parent ~= storms or not colors or visuals[model] then return end

	local random = Random.new(zone)
	local halfWidth, halfHeight, halfDepth = root.Size.X / 2, root.Size.Y / 2, root.Size.Z / 2
	local bottom = -halfHeight
	local edge = {}
	local bolts = {}
	local clouds = {}
	local mistSources = {}
	local gusts = {}
	for _, part in model:GetChildren() do
		if not part:IsA("BasePart") or part == root then continue end
		part.CastShadow = false
		local front = part.Name == "SculptedStormFront"
		local crown = part.Name == "SilverCloudCrown"
		part.Color = front and colors.shadow or crown and colors.rim or colors.cloud
		table.insert(clouds, { part = part, opacity = front and 0.79 or crown and 0.90 or 0.83 })
	end

	for _, side in { -1, 1 } do
		local depth = side * halfDepth
		local left = Vector3.new(-halfWidth, bottom, depth)
		local right = Vector3.new(halfWidth, bottom, depth)
		local outline = beam(root, left, right, 3.2, colors.shadow)
		outline.LightEmission = 0
		outline.Transparency = NumberSequence.new(0.18)
		local border = beam(root, left + Vector3.new(0, 0, side), right + Vector3.new(0, 0, side), 1.4, warningColor)
		border.LightEmission = 0.33
		table.insert(edge, border)
		local haze = beam(root, left, right, 5, warningColor)
		haze.Transparency = NumberSequence.new(0.87)
		table.insert(edge, haze)
		for _, fraction in { -0.68, 0, 0.68 } do
			local x = halfWidth * fraction
			local tip = Vector3.new(x, bottom - 9, depth)
			for _, direction in { -1, 1 } do
				local wing = tip + Vector3.new(direction * 8, 6, 0)
				local arrow = beam(root, wing, tip, 1.25, warningColor)
				arrow.LightEmission = 0.33
				table.insert(edge, arrow)
			end
		end

		for i = -3, 3 do
			local x = i * halfWidth * 0.27 + random:NextNumber(-10, 10)
			table.insert(mistSources, mist(root, Vector3.new(x, random:NextNumber(-10, 31), depth + side * 9),
				random:NextNumber(82, 110), colors, random:NextNumber(-180, 180)))
		end

		for i = -1, 1 do
			local x = i * halfWidth * 0.59
			local z = depth + side * 10
			table.insert(mistSources, mist(root, Vector3.new(x, -34, z), 48, colors, random:NextNumber(-180, 180)))
			local sweep = beam(root, Vector3.new(x - 53, -25, z), Vector3.new(x + 55, -21, z), 1, colors.glow)
			sweep.Attachment0.Axis = Vector3.new(0.87, 0.5, 0)
			sweep.Attachment1.Axis = Vector3.new(0.87, -0.5, 0)
			sweep.Width1 = 4
			sweep.CurveSize0 = 39
			sweep.CurveSize1 = 24
			sweep.Segments = 12
			sweep.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, colors.cloud),
				ColorSequenceKeypoint.new(0.42, colors.accent),
				ColorSequenceKeypoint.new(0.72, colors.glow),
				ColorSequenceKeypoint.new(1, colors.accent),
			})
			sweep.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(0.45, 0.38),
				NumberSequenceKeypoint.new(0.72, 0.18),
				NumberSequenceKeypoint.new(1, 1),
			})
			local wake = sweep:Clone()
			wake.Width0 = 3
			wake.Width1 = 13
			wake.LightEmission = 0.32
			wake.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(0.65, 0.78),
				NumberSequenceKeypoint.new(1, 1),
			})
			wake.Parent = sweep.Parent
			table.insert(gusts, { sweep = sweep, wake = wake })
		end

		for i = -1, 1 do
			local x = i * halfWidth * 0.56 + random:NextNumber(-13, 13)
			local z = depth + side * 14
			local point = Vector3.new(x, halfHeight * 0.68, z)
			local strike = {}
			for step = 1, 5 do
				local nextPoint = Vector3.new(x + random:NextNumber(-17, 17), point.Y - 14, z)
				table.insert(strike, beam(root, point, nextPoint, 1.1 - step * 0.12, colors.glow))
				if step == 2 or step == 3 then
					local branch = nextPoint + Vector3.new(random:NextNumber(12, 24) * side, -12, 0)
					table.insert(strike, beam(root, nextPoint, branch, 0.35, colors.glow))
				end
				point = nextPoint
			end
			for _, line in strike do line.Transparency = NumberSequence.new(0.90) end
			table.insert(bolts, strike)
		end
	end

	title(root, colors, bottom)
	visuals[model] = {
		clouds = clouds, edge = edge, bolts = bolts, color = colors.glow,
		zone = zone, mist = mistSources, gusts = gusts,
	}
end

storms.ChildAdded:Connect(present)
storms.ChildRemoved:Connect(function(model)
	visuals[model] = nil
end)
for _, model in storms:GetChildren() do
	task.spawn(present, model)
end

local nextUpdate = 0
RunService.Heartbeat:Connect(function()
	if not next(visuals) then return end
	local now = workspace:GetServerTimeNow()
	if now < nextUpdate then return end
	nextUpdate = now + 0.07
	for model, visual in visuals do
		local active = model:GetAttribute("Stage") == "Active"
		for index, bank in ipairs(visual.mist) do
			local swirl = (now % 60) * 1.1 + index * 0.85
			bank.source.Position = bank.position + Vector3.new(math.cos(swirl) * 5, math.sin(swirl) * 3, math.sin(swirl) * 3)
		end
		for index, gust in ipairs(visual.gusts) do
			local curl = math.sin((now % 60) * math.pi / 3 + index * 1.4) * 9
			gust.sweep.CurveSize0 = 39 + curl
			gust.sweep.CurveSize1 = 24 - curl * 0.55
			gust.wake.CurveSize0 = gust.sweep.CurveSize0
			gust.wake.CurveSize1 = gust.sweep.CurveSize1
		end
		if visual.active ~= active then
			visual.active = active
			for _, cloud in visual.clouds do
				cloud.part.Transparency = cloud.opacity + (active and 0 or 0.07)
			end
			for _, line in visual.edge do
				line.Color = ColorSequence.new(active and visual.color or warningColor)
			end
		end

		-- Brief, localized strikes. The sky and camera lighting are left alone.
		local phase = (now + visual.zone) / (active and 1.6 or 2.7)
		local cycle = math.floor(phase)
		local strike = cycle % #visual.bolts + 1
		if visual.strike and visual.strike ~= strike then
			for _, line in visual.bolts[visual.strike] do line.Transparency = NumberSequence.new(0.90) end
		end
		visual.strike = strike
		local decay = math.clamp((phase - cycle) * 2.4, 0, 1)
		local opacity = (active and 0.03 or 0.53) + decay * (active and 0.87 or 0.37)
		for _, line in visual.bolts[strike] do line.Transparency = NumberSequence.new(opacity) end
	end
end)
