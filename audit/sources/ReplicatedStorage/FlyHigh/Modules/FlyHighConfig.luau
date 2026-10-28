local FlyHighConfig = {
	-- World & Progression
	MAX_ALTITUDE_KM = 10000,
	SAFE_TAKEOFF_KM = 1200,
	GROUND_Y = 12.5,
	STUDS_PER_KM = 0.25,
	CORRIDOR_CENTER_LIMIT = 120,
	PRODUCT_IDS = { EmergencyKit = 0, AK47Upgrade = 0 }, -- Configure owned Developer Products before publishing
	TACTICAL_MESSAGES = {"Gas Api Sekarang!", "Awas Tornado Menghindar!", "Tali Saya Mau Habis!", "Saya yang Perbaiki!", "Fokus Tembak Rintangan!"},
	BASE_FLIGHT_DURATION_SEC = 600, -- 10 minutes without delay
	MILESTONE_STEP_KM = 1000,
	BIOME_STEP_KM = 2000,

	-- Hot Air Balloon
	MAX_HOLES = 5,
	PASSIVE_INVULN_DURATION = 5, -- 5 seconds grace period after damage
	CLUTCH_SAVE_INVULN_DURATION = 60, -- 1 minute emergency shield
	
	-- Matchmaking Pods
	MAX_PLAYERS_PER_POD = 3,
	COUNTDOWN_DURATION = 0,

	-- Tether / Safety Harness
	ROPE_MAX_DURABILITY = 100,
	ROPE_DECAY_PER_SEC = 5,
	ROPE_REPAIR_RATE_PER_SEC = 25,
	
	-- Weapons
	WEAPONS = {
		Pistol = {
			Name = "Pistol Biasa",
			MagSize = 8,
			ReloadTime = 1.5,
			FireRate = 0.25,
			Damage = 25,
			IsAutomatic = false,
		},
		AK47 = {
			Name = "AK-47 Tactical",
			MagSize = 30,
			ReloadTime = 2.0,
			FireRate = 0.1,
			Damage = 35,
			IsAutomatic = true,
		}
	},

	-- Hole Descent Multipliers
	HOLE_EFFECTS = {
		[0] = { ascend_rate = 1.0, descend_mult = 1.0, can_ascend = true },
		[1] = { ascend_rate = 0.45, descend_mult = 1.0, can_ascend = true },
		[2] = { ascend_rate = 0.0, descend_mult = 1.2, can_ascend = false }, -- Hover only when gassed
		[3] = { ascend_rate = 0.0, descend_mult = 1.5, can_ascend = false }, -- Gas only mitigates descent
		[4] = { ascend_rate = 0.0, descend_mult = 2.5, can_ascend = false },
		[5] = { ascend_rate = 0.0, descend_mult = 5.0, can_ascend = false }, -- Freefall
	}
}

return FlyHighConfig
