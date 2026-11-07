local Motion = {}

Motion.LightningRadius = 17
Motion.LightningLow = -37
Motion.LightningHigh = 49
Motion.StormRadius = 25
Motion.MeteorRadius = 18
Motion.MeteorSpacing = 56
Motion.MeteorStagger = 0.23

function Motion.DistanceToPath(point, first, last)
	local travel = last - first
	local lengthSquared = travel:Dot(travel)
	if lengthSquared == 0 then return (point - first).Magnitude end
	local progress = math.clamp((point - first):Dot(travel) / lengthSquared, 0, 1)
	return (point - (first + travel * progress)).Magnitude
end

function Motion.InColumn(offset, low, high)
	return offset.Y >= low and offset.Y <= high
		and Vector2.new(offset.X, offset.Z).Magnitude <= Motion.LightningRadius
end

function Motion.MeteorOffset(path, index)
	local lateral = Vector3.new(path.Z, 0, -path.X).Unit
	return lateral * ((index - 2) * Motion.MeteorSpacing)
end

function Motion.MeteorProgress(index, age, duration)
	return (age - (index - 1) * Motion.MeteorStagger) / (duration - 2 * Motion.MeteorStagger)
end

function Motion.RuinDrift(index, age)
	return Vector3.new(math.sin(age * 1.15 + index) * 1.7, math.sin(age * 1.55 + index * 1.7) * 2.3,
		math.cos(age * 0.8 + index) * 1.6)
end

local function arc(age, duration)
	return math.sin(math.pi * math.clamp(age / duration, 0, 1))
end

local offsets = {
	WildBird = function(age)
		return Vector3.new(math.sin(age * 1.55) * 4, math.sin(age * 2.2) * 1.9, 0)
	end,
	StormBat = function(age)
		return Vector3.new(arc(age, 3.7) * 11, arc(age, 3.35) * 6, 0)
	end,
	Hailstone = function(age, approach)
		return Vector3.new(0, 8 * age * (1 - age / approach), 0)
	end,
	FireBee = function(age)
		return Vector3.new(math.sin(age * 4.5) * 3.4, math.sin(age * 5.8) * 2.2, math.sin(age * 3.8) * 2.7)
	end,
	CrystalWyvern = function(age)
		return Vector3.new(arc(age, 5.4) * -10, math.sin(age * 1.7) * 3, 0)
	end,
	ShadowPhantom = function(age)
		return Vector3.new(math.sin(age * 1.4) * 4, math.sin(age * 1.8) * 5.2, 0)
	end,
	CelestialPhoenix = function(age)
		return Vector3.new(arc(age, 3.2) * 15, arc(age, 3.0) * 11, 0)
	end,
}

function Motion.EnemyPose(effect, origin, velocity, approach, age, previous)
	local position = origin.Position + velocity * age
	local offset = offsets[effect]
	if offset then
		local amount = offset(age, approach)
		position += origin.RightVector * amount.X + Vector3.yAxis * amount.Y + origin.LookVector * amount.Z
	end
	if effect == "Hailstone" or effect == "SatelliteDebris" then
		local rate = effect == "Hailstone" and 1.9 or 0.65
		return CFrame.new(position) * origin.Rotation * CFrame.Angles(age * rate, age * rate * 0.61, age * rate * 0.38)
	end
	local delta = position - previous.Position
	if delta.Magnitude < 0.001 then return CFrame.new(position) * previous.Rotation end
	local bank = offset and math.clamp(delta.Unit:Dot(origin.RightVector) * -0.47, -0.4, 0.4) or 0
	return CFrame.lookAt(position, position + delta) * CFrame.Angles(0, 0, bank)
end

local wingRates = {WildBird = 2.2, StormBat = 4.1, FireBee = 8.5, CrystalWyvern = 1.55, CelestialPhoenix = 2.35}

function Motion.WingAngle(effect, age, phase)
	local wave = math.sin(age * wingRates[effect] * 2 * math.pi + phase)
	if effect == "WildBird" or effect == "CrystalWyvern" or effect == "CelestialPhoenix" then
		wave *= math.clamp(math.cos(age * 2.1 + phase) * 1.45, 0.12, 1)
	end
	return wave * (effect == "FireBee" and 0.29 or 0.48)
end

return Motion
