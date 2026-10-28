local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local remotes = ReplicatedStorage:WaitForChild("FlyHigh"):WaitForChild("Remotes")
local flightSyncEvent = remotes:WaitForChild("FlightStateSyncEvent")

local currentBiome = 0
local activeTween
local fogVersion = 0

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
		FogEnd = cfg.FogEnd,
		OutdoorAmbient = cfg.OutdoorAmbient,
	})
	activeTween:Play()
end

flightSyncEvent.OnClientEvent:Connect(function(data)
	local altKm = data.altitudeKm or 0
	local biomeIndex = math.clamp(math.floor(altKm / 2000) + 1, 1, 5)
	applyBiome(biomeIndex)
end)

-- Initial Dawn
applyBiome(1)

remotes.HazardAlertEvent.OnClientEvent:Connect(function(data)
 if data.effect~="Fog" then return end
 fogVersion+=1 local version=fogVersion
 if activeTween then activeTween:Cancel() end
 Lighting.FogEnd=80
 task.delay(data.duration or 5,function()
  if version~=fogVersion then return end
  local index=currentBiome currentBiome=0 applyBiome(index)
 end)
end)
