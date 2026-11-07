local RunService=game:GetService("RunService")
local RS=game:GetService("ReplicatedStorage")
local Config=require(RS.FlyHigh.Modules.FlyHighConfig)
local remotes=RS.FlyHigh.Remotes
local Art=require(script.Parent.ObstacleArt)
local Motion=require(script.Parent.ObstacleMotion)
local Manager={activeObstacles={},Paused=false}
_G.FlyHighObstacleManager=Manager
local folder=Instance.new("Folder") folder.Name="FlyHighObstacles" folder.Parent=workspace
local bands={
 [1]={enemy="WildBird",hazard="Angin Topan",effect="Tornado",color=Color3.fromRGB(156,189,210)},
 [2]={enemy="StormBat",hazard="Awan Petir",effect="Lightning",color=Color3.fromRGB(110,80,190)},
 [3]={enemy="Hailstone",hazard="Jetstream Crosswind",effect="Wind",color=Color3.fromRGB(160,230,255)},
 [4]={enemy="GuardianDrone",hazard="Puing Kuno",effect="Debris",color=Color3.fromRGB(200,160,90)},
 [5]={enemy="FireBee",hazard="Gelombang Panas",effect="Heat",color=Color3.fromRGB(255,130,30)},
 [6]={enemy="CrystalWyvern",hazard="Anomali Magnetik",effect="Magnetic",color=Color3.fromRGB(80,255,210)},
 [7]={enemy="ShadowPhantom",hazard="Kabut Hampa",effect="Fog",color=Color3.fromRGB(120,80,170)},
 [8]={enemy="SatelliteDebris",hazard="Meteorit Mikro",effect="Meteor",color=Color3.fromRGB(160,170,195)},
 [9]={enemy="CelestialPhoenix",hazard="Badai Gerbang Surgawi",effect="Storm",color=Color3.fromRGB(255,215,70)},
}
function Manager.GetBand(km)
 if km<Config.SAFE_TAKEOFF_KM or km>=Config.MAX_ALTITUDE_KM then return nil end
 return math.clamp(math.floor(km/1000),1,9)
end
local function flights()
 local bm=_G.FlyHighBalloonManager
 local out={}
 for _,fd in ipairs(bm and bm.activeFlights or {}) do
  if not fd.isGameOver and not fd.isVictory and Manager.GetBand(fd.altitudeKm) then table.insert(out,fd) end
 end
 return out
end
local warningSeconds, hazardSeconds = 3, 2.5
local obstacleLimit = 60
local safeY = Config.GROUND_Y + Config.SAFE_TAKEOFF_KM * Config.STUDS_PER_KM
local stormCells = {-28, 0, 28}
local ruinCells = {
	Vector3.new(-28, 0, -36), Vector3.new(24, 0, -9),
	Vector3.new(-33, 0, 19), Vector3.new(31, 0, 45),
}
local trajectories = {
	Tornado = Vector3.new(70, 0, 0),
	Heat = Vector3.new(0, 0, 66),
	Meteor = Vector3.new(54, -58, 92),
}
local wingParts = {Wing = true, FlightFeather = true, Membrane = true, WingTip = true, AmberWing = true, CrystalWing = true}

local function add(model, position, velocity, name, effect, delaySeconds, lifespan, health)
	local shootable = health ~= nil
	model.Name = name
	model:SetAttribute("IsObstacle", true)
	model:SetAttribute("Shootable", shootable)
	model:SetAttribute("Health", health or 0)
	local _, size = model:GetBoundingBox()
	local minY = safeY + size.Y / 2
	local beams = {}
	local fragments = {}
	local animated = {}
	local spirals = {}
	local rails = {}
	for _, object in model:GetDescendants() do
		if object:IsA("BasePart") then
			object.CanQuery = shootable and not object:GetAttribute("Decoration")
			if object.Name == "MeteorFragment" then
				fragments[object] = object.Transparency
				object.Transparency = 1
			end
		elseif object:IsA("Beam") then
			table.insert(beams, object)
			local lane = object:GetAttribute("MeteorLane")
			if lane then
				rails[lane] = rails[lane] or {}
				table.insert(rails[lane], object)
			end
		elseif object:IsA("Attachment") then
			local rate = object:GetAttribute("SpiralRate")
			if rate then table.insert(spirals, {attachment = object, rest = object.CFrame, rate = rate}) end
		end
	end
	position = Vector3.new(position.X, math.max(minY, position.Y), position.Z)
	local pose = (shootable or effect == "Spike") and CFrame.lookAt(position, position + velocity) or CFrame.new(position)
	model:PivotTo(pose)
	for _, part in model:GetChildren() do
		if part:IsA("BasePart") and (wingParts[part.Name] or part:GetAttribute("FlockCenter")
			or part.Name == "Thunderhead" or part.Name == "ChargedCrystal") then
			local center = part:GetAttribute("FlockCenter") or Vector3.zero
			table.insert(animated, { part = part, rest = pose:ToObjectSpace(part.CFrame), center = center })
		end
	end
	model.Parent = folder
	local now = os.clock()
	local item = {
		instance = model, velocity = velocity, shootable = shootable, effect = effect,
		born = now, activeAt = now + delaySeconds, expires = now + delaySeconds + lifespan,
		minY = minY, hit = {}, beams = beams, fragments = fragments, animated = animated, origin = pose,
		spirals = spirals, rails = rails,
	}
	table.insert(Manager.activeObstacles, item)
	return item
end

local function hazardDirection(fd, position)
	local relative = fd.root.CFrame:PointToObjectSpace(position)
	if math.abs(relative.X) > math.abs(relative.Z) then
		return relative.X > 0 and "kanan" or "kiri"
	end
	return relative.Z > 0 and "belakang" or "depan"
end

local function stormBlocksSpawn(fd, now)
	return fd.largeChallengeUntil and now < fd.largeChallengeUntil
end

local function predictedEnvelope(fd)
	return fd.balloon.Envelope.Position + Vector3.new(0, (fd.isGasActive or fd.autoGas) and 12.5 or 0, 0)
end

local function spawnEnemy(spec, pacing, aim, bearing, slot)
	local outward = Vector3.new(math.sin(bearing), 0, -math.cos(bearing))
	local range = math.max(95, pacing.speed * 3.15) + (slot - 1) * pacing.speed * 0.75
	local height = spec.enemy == "Hailstone" and 42 or 10
	local start = aim + outward * range + Vector3.yAxis * height
	local travel = aim - start
	local approach = travel.Magnitude / pacing.speed
	local item = add(Art.Enemy(spec.enemy), start, travel.Unit * pacing.speed,
		spec.enemy, spec.enemy, 0, approach + 4, pacing.health)
	item.approach = approach
	return item
end

local function spawnEnemyWave(index, fd, count)
	local spec, pacing = bands[index], Config.OBSTACLE_PACING[index]
	local velocity = fd.root.AssemblyLinearVelocity
	local lead = Vector3.new(velocity.X, 0, velocity.Z) * 0.9
	if lead.Magnitude > 24 then lead = lead.Unit * 24 end
	local aim = predictedEnvelope(fd) + lead
	local heading = count == 1 and math.rad(math.random(-25, 25)) or math.random() * math.pi * 2
	local flank = math.rad(68) * (math.random(0, 1) == 0 and -1 or 1)
	local bearings = {heading, heading + flank, heading - flank}
	local sideways = Vector3.new(math.cos(heading), 0, math.sin(heading)) * 8
	local offsets = {Vector3.zero, sideways, -sideways}
	for slot = 1, count do
		spawnEnemy(spec, pacing, aim + offsets[slot], bearings[slot], slot)
	end
end

function Manager.SpawnBand(index, fd, hazard)
	local spec = bands[index]
	local pacing = Config.OBSTACLE_PACING[index]
	if not spec or stormBlocksSpawn(fd, os.clock())
		or not Manager.GetBand(fd.altitudeKm) or #Manager.activeObstacles >= obstacleLimit then return nil end

	local predicted = predictedEnvelope(fd)
	if not hazard then
		return spawnEnemy(spec, pacing, predicted, math.rad(math.random(-25, 25)), 1)
	end

	local path = trajectories[spec.effect] or Vector3.zero
	local impact = predicted + Vector3.new(0, 0, -12)
	local start = impact - path / 2
	local cells = spec.effect == "Storm" and stormCells or ruinCells
	local model = Art.Hazard(spec.effect, spec.color, path, cells)
	local item = add(model, start, path / hazardSeconds, spec.hazard, spec.effect, warningSeconds, hazardSeconds)
	if path.Magnitude > 0 then item.path = path end
	if spec.effect == "Meteor" or spec.effect == "Debris" then
		item.groups = {}
		for index = 1, spec.effect == "Meteor" and 3 or #ruinCells do
			local prefix = spec.effect == "Meteor" and "MeteorLane" or "Ruin"
			item.groups[index] = model[prefix .. index]
		end
	end
	for _, crewFlight in ipairs(flights()) do
		if math.abs(crewFlight.balloon.Envelope.Position.Y - impact.Y) >= 90 then continue end
		crewFlight.hazardUntil = math.max(crewFlight.hazardUntil or 0, item.activeAt)
		local direction = hazardDirection(crewFlight, item.instance.PrimaryPart.Position)
		for _, player in ipairs(crewFlight.players) do
			if player.Parent == game.Players then
				remotes.HazardAlertEvent:FireClient(player, {
					hazardName = spec.hazard, direction = direction, duration = warningSeconds,
				})
			end
		end
	end
	return item
end

local function touches(item, center, first, last, age)
	local offset = center - last
	local effect = item.effect
	if effect == "Lightning" then
		return Motion.InColumn(offset, Motion.LightningLow, Motion.LightningHigh)
	elseif effect == "Storm" then
		if offset.Magnitude < Motion.StormRadius then return true end
		local x = stormCells[item.strike]
		return x ~= nil and Motion.InColumn(offset - Vector3.new(x, 0, 0), -28, 54)
	elseif effect == "Debris" then
		for _, ruin in ipairs(item.groups) do
			if (center - ruin:GetPivot().Position).Magnitude <= 23 then return true end
		end
		return false
	elseif effect == "Meteor" then
		for _, sweep in pairs(item.laneSweeps) do
			if Motion.DistanceToPath(center, sweep.first, sweep.last) <= Motion.MeteorRadius then return true end
		end
		return false
	elseif effect == "Wind" or effect == "Heat" then
		return math.abs(offset.X) <= 41 and math.abs(offset.Y) <= 23
			and (math.abs(offset.Z) <= 23 or Motion.DistanceToPath(center, first, last) <= 23)
	elseif effect == "Magnetic" and age < 0.35 then
		return false
	end
	local radius = (item.shootable or effect == "Spike") and 18 or 33
	return Motion.DistanceToPath(center, first, last) < radius
end

local function applyHazard(item, flight, now)
	if flight.invulnTime > 0 then return end
	local effect = item.effect
	if effect == "Magnetic" then
		flight.reverseUntil = now + 4
	elseif effect == "Wind" or effect == "Tornado" then
		if flight.windSource ~= item.born or now >= (flight.windUntil or 0) then flight.windSince = now end
		flight.windSource = item.born
		local distance = (flight.balloon.Envelope.Position - item.instance.PrimaryPart.Position).Magnitude
		local strength = effect == "Tornado" and 25 * math.clamp(1 - distance / 33, 0, 1) or 25
		flight.wind = Vector3.new(strength, 0, 0)
		flight.windUntil = now + (effect == "Tornado" and 0.6 or 3)
	elseif effect == "Fog" then
		for _, player in ipairs(flight.players) do
			if player.Parent == game.Players then
				remotes.HazardAlertEvent:FireClient(player, {hazardName = "Kabut Hampa", effect = "Fog", duration = 5})
			end
		end
	else
		_G.FlyHighBalloonManager.ApplyPuncture(flight)
	end
end

local function activate(item)
	for _, beam in ipairs(item.beams) do
		if beam.Name == "ActiveBeam" then
			beam.Enabled = item.effect ~= "Storm"
		elseif beam.Name == "PathBeam" or (item.effect == "Lightning" and beam.Name == "WarningBeam") then
			beam.Enabled = false
		end
	end
end

local function animateParts(item, pose, age)
	if #item.spirals > 0 and age >= (item.nextSpiralUpdate or 0) then
		item.nextSpiralUpdate = age + 1 / 24
		for _, ribbon in ipairs(item.spirals) do
			ribbon.attachment.CFrame = CFrame.Angles(0, age * ribbon.rate, 0) * ribbon.rest
		end
	end
	for index, data in ipairs(item.animated) do
		local part, rest, center = data.part, data.rest, data.center
		local phase = math.sign(center.X) * 1.6
		if item.shootable then
			local spread = Vector3.xAxis * math.sign(center.X) * math.abs(math.sin(age * 1.55)) * 1.3
			local transform = CFrame.new(spread)
			if wingParts[part.Name] then
				local side = math.sign(rest.Position.X - center.X)
				local joint = center + Vector3.new(side * 0.68, 0.35, 0)
				local flap = side * Motion.WingAngle(item.effect, age, phase)
				transform *= CFrame.new(joint) * CFrame.Angles(0, 0, flap) * CFrame.new(-joint)
			end
			part.CFrame = pose * transform * rest
		elseif part.Name == "Thunderhead" then
			part.CFrame = pose * (rest + Vector3.new(math.sin(age * 1.1 + index) * 2.5, math.sin(age * 1.3 + index) * 1.2, 0))
		else
			part.CFrame = pose * rest * CFrame.Angles(age * 0.45, age * 0.8, 0)
		end
	end
end

local function updateMeteor(item, age)
	item.laneSweeps = item.laneSweeps or {}
	for index, lane in ipairs(item.groups) do
		local previous = Motion.MeteorProgress(index, item.previousAge or 0, hazardSeconds)
		local progress = Motion.MeteorProgress(index, age, hazardSeconds)
		local visible = progress >= 0 and progress <= 1
		if lane:GetAttribute("Visible") ~= visible then
			lane:SetAttribute("Visible", visible)
			for _, part in lane:GetDescendants() do
				if item.fragments[part] ~= nil then part.Transparency = visible and item.fragments[part] or 1 end
				if part:IsA("Beam") then part.Enabled = visible end
				if part:IsA("ParticleEmitter") then
					part.Enabled = visible
					if visible then part:Emit(5) end
				end
			end
		end
		local railPhase = progress < 0 and "Waiting" or visible and "Passing" or "Passed"
		if lane:GetAttribute("RailPhase") ~= railPhase then
			lane:SetAttribute("RailPhase", railPhase)
			for _, rail in ipairs(item.rails[index]) do
				rail.Transparency = NumberSequence.new(visible and 0.63 or 0.32)
				rail.Enabled = railPhase ~= "Passed"
			end
		end
		if progress >= 0 and previous <= 1 then
			local start = item.origin.Position + Motion.MeteorOffset(item.path, index)
			local last = start + item.path * math.clamp(progress, 0, 1)
			local first = start + item.path * math.clamp(previous, 0, 1)
			item.laneSweeps[index] = { first = first, last = last }
			lane:PivotTo(CFrame.new(last) * CFrame.Angles(age * 2.6, age * 1.7, age * 1.2))
			-- The tail follows the flight path while the fragments tumble.
			local wake = lane:FindFirstChild("MeteorWake", true)
			wake.Attachment1.WorldPosition = last - item.path.Unit * 26
		else
			item.laneSweeps[index] = nil
		end
	end
end
local nextEnemy, nextHazard, waveStep = {}, {}, {}
local nextHazardCheck = os.clock() + 2.5
task.spawn(function()
	while true do
		task.wait(0.5)
		if Manager.Paused then continue end
		local now = os.clock()
		local checkHazards = now >= nextHazardCheck
		if checkHazards then nextHazardCheck = now + 2.5 end

		local occupied = {}
		for _, fd in ipairs(flights()) do
			local band = Manager.GetBand(fd.altitudeKm)
			occupied[band] = occupied[band] or {}
			table.insert(occupied[band], fd)
		end
		for band, crew in pairs(occupied) do
			local pacing = Config.OBSTACLE_PACING[band]
			if now >= (nextEnemy[band] or 0) then
				local eligible = {}
				for _, fd in ipairs(crew) do
					if not stormBlocksSpawn(fd, now) then table.insert(eligible, fd) end
				end
				local step = waveStep[band] or 1
				local count = pacing.enemyWave[step]
				if #eligible > 0 and #Manager.activeObstacles + count <= obstacleLimit then
					spawnEnemyWave(band, eligible[math.random(1, #eligible)], count)
					waveStep[band] = step % #pacing.enemyWave + 1
					nextEnemy[band] = now + pacing.enemyInterval
				end
			end
			if checkHazards then
				nextHazard[band] = nextHazard[band] or now + pacing.hazardInterval
				if now >= nextHazard[band] then
					Manager.SpawnBand(band, crew[math.random(1, #crew)], true)
					nextHazard[band] = now + pacing.hazardInterval
				end
			end
		end
	end
end)
RunService.Heartbeat:Connect(function(dt)
	local current = flights()
	local now = os.clock()
	for index = #Manager.activeObstacles, 1, -1 do
		local item = Manager.activeObstacles[index]
		local model = item.instance
		if not model.Parent or now >= item.expires or #current == 0 then
			model:Destroy()
			table.remove(Manager.activeObstacles, index)
			continue
		end
		local age = now - item.activeAt
		if age < 0 then
			animateParts(item, model:GetPivot(), now - item.born)
			continue
		end
		if not item.activated then
			item.activated = true
			activate(item)
		end

		local previous = model:GetPivot()
		local nextPose = previous + item.velocity * math.min(dt, 0.1)
		if item.shootable then
			local flightAge = age
			if item.chargeAge then
				local charge = math.clamp(age - item.chargeAge, 0, 0.65)
				local slowdown = math.min(charge, 0.18)
				flightAge -= charge - slowdown * (1 - slowdown / 0.36)
			end
			nextPose = Motion.EnemyPose(item.effect, item.origin, item.velocity, item.approach, flightAge, previous)
			if item.chargeAge and not item.fired then
				local aim = item.chargeTarget - nextPose.Position
				if aim.Magnitude > 0.01 then
					nextPose = CFrame.new(nextPose.Position) * previous.Rotation:Lerp(
						CFrame.lookAt(Vector3.zero, aim).Rotation, math.min(dt * 9, 1))
				end
			end
		elseif item.effect == "Meteor" then
			updateMeteor(item, age)
		elseif item.path then
			nextPose = CFrame.new(item.origin.Position + item.velocity * age)
		end
		if nextPose.Position.Y < item.minY then
			model:Destroy()
			table.remove(Manager.activeObstacles, index)
			continue
		end
		if item.effect == "Tornado" then
			nextPose *= CFrame.Angles(0, age * 1.4, 0)
		end
		if nextPose ~= previous then model:PivotTo(nextPose) end
		animateParts(item, nextPose, now - item.born)

		if item.effect == "Storm" then
			local index = math.floor(age / 0.8) + 1
			local strike = index <= #stormCells and age % 0.8 >= 0.23 and index or nil
			local warning = index <= #stormCells and index or nil
			if strike ~= item.strike or warning ~= item.strikeWarning then
				item.strike, item.strikeWarning = strike, warning
				for _, beam in ipairs(item.beams) do
					local number = beam:GetAttribute("Strike")
					if number then beam.Enabled = number == strike end
					local preview = beam:GetAttribute("StrikeWarning")
					if preview then
						beam.Enabled = preview == warning
						if beam.Name == "StrikeRing" then
							beam.Transparency = NumberSequence.new(strike == preview and 0.49 or 0.12)
						end
					end
				end
			end
		elseif item.effect == "Debris" then
			for number, ruin in ipairs(item.groups) do
				local shift = ruinCells[number] + Motion.RuinDrift(number, age)
				ruin:PivotTo(nextPose * CFrame.new(shift) * CFrame.Angles(0, math.sin(age + number) * 0.16, 0))
			end
		elseif item.effect == "Magnetic" then
			for _, beam in ipairs(item.beams) do
				if beam.Name == "MagneticPulse" then
					beam.Width0 = 0.65 + math.max(0, 1 - math.abs(age - 0.2) * 5) * 2.5
					beam.Width1 = beam.Width0
				end
			end
		elseif item.effect == "GuardianDrone" and not item.fired then
			if item.chargeAge and age >= item.chargeAge + 0.65 then
				local delta = item.chargeTarget - nextPose.Position
				item.fired = true
				model:SetAttribute("Charging", false)
				model.Aperture.Color = Color3.fromRGB(249, 171, 48)
				if delta.Magnitude > 0.01 and #Manager.activeObstacles < obstacleLimit then
					add(Art.Spike(), nextPose.Position, delta.Unit * 43, "Paku Sihir", "Spike", 0, 2.2)
				end
			elseif not item.chargeAge and age > 0.9 and #Manager.activeObstacles < obstacleLimit then
				for _, flight in ipairs(current) do
					local target = flight.balloon.Envelope.Position
					local distance = (target - nextPose.Position).Magnitude
					if distance > 22 and distance < 76 then
						item.chargeAge = age
						item.chargeTarget = target
						model:SetAttribute("Charging", true)
						model.Aperture.Color = Color3.fromRGB(255, 245, 189)
						break
					end
				end
			end
		end

		for _, flight in ipairs(current) do
			if (item.effect == "Tornado" or not item.hit[flight])
				and touches(item, flight.balloon.Envelope.Position, previous.Position, nextPose.Position, age) then
				item.hit[flight] = true
				applyHazard(item, flight, now)
				if item.shootable or item.effect == "Spike" then model:Destroy() break end
			end
		end
		item.previousAge = age
	end
end)
