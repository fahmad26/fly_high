local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local localPlayer = game:GetService("Players").LocalPlayer

local flyHigh = ReplicatedStorage:WaitForChild("FlyHigh")
local modules = flyHigh:WaitForChild("Modules")
local Config = require(modules:WaitForChild("FlyHighConfig"))
local Scenery = require(modules:WaitForChild("BiomeScenery"))
local remotes = flyHigh:WaitForChild("Remotes")
local flightSyncEvent = remotes:WaitForChild("FlightStateSyncEvent")

local colorGrade = Instance.new("ColorCorrectionEffect")
colorGrade.Name = "FlyHighBiomeGrade"
colorGrade.Parent = Lighting
local baseAmbient = Lighting.Ambient
local baseLatitude = Lighting.GeographicLatitude
local baseShadowSoftness = Lighting.ShadowSoftness
local baseSunTint = Lighting.ColorShift_Top

local sceneryRoot = Instance.new("Folder")
sceneryRoot.Name = "ClientBiomeScenery"
sceneryRoot.Parent = workspace
local scenes = {}
local altitudeKm = 0

local BIOME_COUNT = 5
local TRANSITION_KM = 220

local function biomeAt(km)
	return math.clamp(math.floor(km / Config.BIOME_STEP_KM) + 1, 1, BIOME_COUNT)
end

local function updateScenery(km)
	local opacity = {}
	local step = Config.BIOME_STEP_KM
	local boundary = math.floor((km + TRANSITION_KM) / step)
	local distance = km - boundary * step
	if boundary >= 1 and boundary < BIOME_COUNT and math.abs(distance) < TRANSITION_KM then
		local t = (distance + TRANSITION_KM) / (2 * TRANSITION_KM)
		local blend = math.round(t * t * (3 - 2 * t) * 40) / 40
		if blend < 1 then opacity[boundary] = 1 - blend end
		if blend > 0 then opacity[boundary + 1] = blend end
	else
		opacity[biomeAt(km)] = 1
	end

	for index, entry in scenes do
		if not opacity[index] then
			entry.model:Destroy()
			scenes[index] = nil
		end
	end
	local now = os.clock()
	for index, weight in opacity do
		local entry = scenes[index]
		if not entry then
			local model, update = Scenery.Build(index)
			update(km, now, weight)
			model.Parent = sceneryRoot
			scenes[index] = { model = model, update = update }
		else
			entry.update(km, now, weight)
		end
	end
end

local elapsed = 0
local animation = RunService.Heartbeat:Connect(function(dt)
	elapsed += dt
	if elapsed < 0.1 then return end
	elapsed = 0
	updateScenery(altitudeKm)
end)

script.Destroying:Connect(function()
	animation:Disconnect()
	sceneryRoot:Destroy()
	colorGrade:Destroy()
end)

local currentBiome = 0
local activeTween
local fogVersion = 0
local fogActive = false
local fogTween
local atmosphereTween
local colorGradeTween
local atmosphereColorTween
local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
local clearDensity = atmosphere and atmosphere.Density
local clearHaze = atmosphere and atmosphere.Haze
local clearGlare = atmosphere and atmosphere.Glare
local clearAtmosphereColor = atmosphere and atmosphere.Color
local clearAtmosphereDecay = atmosphere and atmosphere.Decay

local BIOME_SETTINGS = {
	[1] = { -- 0 - 2,000 km: Breezy Dawn Archipelago
		ClockTime = 6.8,
		Brightness = 2.5,
		FogColor = Color3.fromRGB(240, 220, 190),
		FogEnd = 3000,
		OutdoorAmbient = Color3.fromRGB(150, 140, 120),
	},
	[2] = { -- 2,000 - 4,000 km: Indigo Thundercloud
		ClockTime = 0.5,
		Brightness = 1.0,
		FogColor = Color3.fromRGB(35, 25, 60),
		FogEnd = 800,
		OutdoorAmbient = Color3.fromRGB(81, 66, 126),
		Ambient = Color3.fromRGB(102, 94, 139),
		AtmosphereColor = Color3.fromRGB(159, 153, 222),
		AtmosphereDecay = Color3.fromRGB(71, 57, 123),
		Tint = Color3.fromRGB(222, 222, 255),
	},
	[3] = { -- 4,000 - 6,000 km: Sunset of Forgotten Sky Isles
		ClockTime = 17.8,
		Brightness = 2.0,
		FogColor = Color3.fromRGB(200, 100, 80),
		FogEnd = 2000,
		OutdoorAmbient = Color3.fromRGB(180, 96, 78),
		AtmosphereColor = Color3.fromRGB(255, 188, 146),
		AtmosphereDecay = Color3.fromRGB(180, 108, 127),
		Tint = Color3.fromRGB(255, 224, 204),
	},
	[4] = { -- 6,000 - 8,000 km: Bioluminescent Cosmic Exosphere
		ClockTime = 23.5,
		Brightness = 0.8,
		FogColor = Color3.fromRGB(10, 15, 35),
		FogEnd = 4000,
		OutdoorAmbient = Color3.fromRGB(40, 80, 120),
	},
	[5] = { -- 8,000 - 10,000 km: The Celestial Gateway
		ClockTime = 8.55,
		GeographicLatitude = 52,
		Brightness = 3.15,
		ShadowSoftness = 0.68,
		ColorShift_Top = Color3.fromRGB(255, 216, 171),
		FogColor = Color3.fromRGB(255, 232, 202),
		FogEnd = 5000,
		OutdoorAmbient = Color3.fromRGB(164, 152, 151),
		Ambient = Color3.fromRGB(118, 112, 130),
		AtmosphereColor = Color3.fromRGB(255, 224, 193),
		AtmosphereDecay = Color3.fromRGB(240, 204, 185),
		AtmosphereDensity = 0.32,
		AtmosphereHaze = 1.35,
		AtmosphereGlare = 0.16,
		Tint = Color3.fromRGB(255, 247, 235),
		Contrast = 0.04,
	}
}

local function transitionFog(target, seconds, dense)
	if fogTween then fogTween:Cancel() end
	local info = TweenInfo.new(seconds, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
	fogTween = TweenService:Create(Lighting, info, {FogEnd = target})
	fogTween:Play()
	if atmosphere then
		if atmosphereTween then atmosphereTween:Cancel() end
		local cfg = BIOME_SETTINGS[currentBiome]
		local density = cfg.AtmosphereDensity or clearDensity
		local haze = cfg.AtmosphereHaze or clearHaze
		atmosphereTween = TweenService:Create(atmosphere, info, {
			Density = dense and math.max(density, 0.58) or density,
			Haze = dense and math.max(haze, 3.5) or haze,
			Glare = dense and 0 or cfg.AtmosphereGlare or clearGlare,
		})
		atmosphereTween:Play()
	end
end

local function applyBiome(biomeIndex)
	if currentBiome == biomeIndex then return end
	currentBiome = biomeIndex
	local cfg = BIOME_SETTINGS[biomeIndex]
	if not cfg then return end

	local tweenInfo = TweenInfo.new(5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
	if activeTween then activeTween:Cancel() end
	activeTween = TweenService:Create(Lighting, tweenInfo, {
		ClockTime = cfg.ClockTime,
		GeographicLatitude = cfg.GeographicLatitude or baseLatitude,
		Brightness = cfg.Brightness,
		ShadowSoftness = cfg.ShadowSoftness or baseShadowSoftness,
		ColorShift_Top = cfg.ColorShift_Top or baseSunTint,
		FogColor = cfg.FogColor,
		OutdoorAmbient = cfg.OutdoorAmbient,
		Ambient = cfg.Ambient or baseAmbient,
	})
	activeTween:Play()

	if colorGradeTween then colorGradeTween:Cancel() end
	colorGradeTween = TweenService:Create(colorGrade, tweenInfo, {
		TintColor = cfg.Tint or Color3.new(1, 1, 1),
		Contrast = cfg.Contrast or 0,
	})
	colorGradeTween:Play()

	if atmosphere then
		if atmosphereColorTween then atmosphereColorTween:Cancel() end
		atmosphereColorTween = TweenService:Create(atmosphere, tweenInfo, {
			Color = cfg.AtmosphereColor or clearAtmosphereColor,
			Decay = cfg.AtmosphereDecay or clearAtmosphereDecay,
		})
		atmosphereColorTween:Play()
	end
	if not fogActive then transitionFog(cfg.FogEnd, 5, false) end
end

local function restoreLobbyLighting()
	fogVersion += 1 -- Invalidate delayed fog restoration from the previous flight.
	fogActive = false
	altitudeKm = 0
	currentBiome = 0
	updateScenery(0)
	applyBiome(1)
end

flightSyncEvent.OnClientEvent:Connect(function(data)
	if data.isGameOver then
		restoreLobbyLighting()
		return
	end
	altitudeKm = data.isVictory and Config.MAX_ALTITUDE_KM or data.altitudeKm or 0
	applyBiome(biomeAt(altitudeKm))
end)

-- Initial Dawn
updateScenery(0)
applyBiome(1)

localPlayer.CharacterAdded:Connect(function()
	-- Ghost spotters still belong to the active flight and keep its biome.
	if not localPlayer:GetAttribute("InFlight") then restoreLobbyLighting() end
end)

remotes.HazardAlertEvent.OnClientEvent:Connect(function(data)
	if data.effect ~= "Fog" then return end
	fogVersion += 1
	local version = fogVersion
	fogActive = true
	transitionFog(80, 0.65, true)
	task.delay(data.duration or 5, function()
		if version ~= fogVersion then return end
		fogActive = false
		transitionFog(BIOME_SETTINGS[currentBiome].FogEnd, 1.15, false)
	end)
end)
