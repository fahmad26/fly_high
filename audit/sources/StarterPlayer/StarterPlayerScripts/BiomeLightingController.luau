local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local localPlayer = game:GetService("Players").LocalPlayer

local remotes = ReplicatedStorage:WaitForChild("FlyHigh"):WaitForChild("Remotes")
local flightSyncEvent = remotes:WaitForChild("FlightStateSyncEvent")

local currentBiome = 0
local activeTween
local fogVersion = 0
local fogActive = false
local fogTween
local atmosphereTween
local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
local clearDensity = atmosphere and atmosphere.Density
local clearHaze = atmosphere and atmosphere.Haze

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
		OutdoorAmbient = Color3.fromRGB(60, 40, 90),
	},
	[3] = { -- 4,000 - 6,000 km: Sunset of Forgotten Sky Isles
		ClockTime = 17.8,
		Brightness = 2.0,
		FogColor = Color3.fromRGB(200, 100, 80),
		FogEnd = 2000,
		OutdoorAmbient = Color3.fromRGB(180, 80, 70),
	},
	[4] = { -- 6,000 - 8,000 km: Bioluminescent Cosmic Exosphere
		ClockTime = 23.5,
		Brightness = 0.8,
		FogColor = Color3.fromRGB(10, 15, 35),
		FogEnd = 4000,
		OutdoorAmbient = Color3.fromRGB(40, 80, 120),
	},
	[5] = { -- 8,000 - 10,000 km: The Celestial Gateway
		ClockTime = 14.0,
		Brightness = 3.5,
		FogColor = Color3.fromRGB(255, 245, 210),
		FogEnd = 5000,
		OutdoorAmbient = Color3.fromRGB(255, 230, 160),
	}
}

local function transitionFog(target, seconds, dense)
	if fogTween then fogTween:Cancel() end
	local info = TweenInfo.new(seconds, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
	fogTween = TweenService:Create(Lighting, info, {FogEnd = target})
	fogTween:Play()
	if atmosphere then
		if atmosphereTween then atmosphereTween:Cancel() end
		atmosphereTween = TweenService:Create(atmosphere, info, {
			Density = dense and math.max(clearDensity, 0.58) or clearDensity,
			Haze = dense and math.max(clearHaze, 3.5) or clearHaze,
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
		Brightness = cfg.Brightness,
		FogColor = cfg.FogColor,
		OutdoorAmbient = cfg.OutdoorAmbient,
	})
	activeTween:Play()
	if not fogActive then transitionFog(cfg.FogEnd, 5, false) end
end

local function restoreLobbyLighting()
	fogVersion += 1 -- Invalidate delayed fog restoration from the previous flight.
	fogActive = false
	currentBiome = 0
	applyBiome(1)
end

flightSyncEvent.OnClientEvent:Connect(function(data)
	if data.isGameOver then
		restoreLobbyLighting()
		return
	end
	local altKm = data.altitudeKm or 0
	local biomeIndex = math.clamp(math.floor(altKm / 2000) + 1, 1, 5)
	applyBiome(biomeIndex)
end)

-- Initial Dawn
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
