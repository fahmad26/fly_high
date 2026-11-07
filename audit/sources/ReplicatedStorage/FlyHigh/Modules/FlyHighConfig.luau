local FlyHighConfig = {
	-- World & Progression
	MAX_ALTITUDE_KM = 10000,
	SAFE_TAKEOFF_KM = 300,
	GROUND_Y = 12.5,
	STUDS_PER_KM = 0.25,
	CORRIDOR_CENTER_LIMIT = 120,
	PRODUCT_IDS = { EmergencyKit = 3723339056, AK47Upgrade = 3723339246 }, -- Prices are fetched from Roblox, not hard-coded
	TACTICAL_MESSAGES = {"Gas Api Sekarang!", "Awas Tornado Menghindar!", "Tali Saya Mau Habis!", "Saya yang Perbaiki!", "Fokus Tembak Rintangan!"},
	BASE_FLIGHT_DURATION_SEC = 600, -- 10 minutes without delay
	MILESTONE_STEP_KM = 1000,
	BIOME_STEP_KM = 2000,
 -- Gradual regular encounters; shared storm curtain pacing stays independent.
 OBSTACLE_PACING = {
  [1]={speed=22,health=50,enemyInterval=7,enemyWave={1,2,2},hazardInterval=26},
  [2]={speed=24,health=50,enemyInterval=6.5,enemyWave={1,2,2},hazardInterval=25},
  [3]={speed=26,health=70,enemyInterval=6,enemyWave={2,2,3},hazardInterval=24},
  [4]={speed=28,health=70,enemyInterval=6,enemyWave={2,2,3},hazardInterval=23},
  [5]={speed=29,health=70,enemyInterval=5.5,enemyWave={2,2,3},hazardInterval=22},
  [6]={speed=30,health=85,enemyInterval=5,enemyWave={2,3,3},hazardInterval=21},
  [7]={speed=32,health=85,enemyInterval=4.5,enemyWave={2,3,3},hazardInterval=20},
  [8]={speed=34,health=100,enemyInterval=4.5,enemyWave={2,3,3},hazardInterval=19},
  [9]={speed=36,health=100,enemyInterval=4,enemyWave={2,3,3},hazardInterval=18},
 },

	-- Hot Air Balloon
	MAX_HOLES = 5,
	FREEFALL_KM_PER_SEC = 2000/3,
	GROUNDED_TIMEOUT_SEC = 60,
	BALLOON_CLEARANCE_DISTANCE = 60,
	BALLOON_CLEARANCE_HEIGHT = 64,
	PASSIVE_INVULN_DURATION = 5, -- 5 seconds grace period after damage
	CLUTCH_SAVE_INVULN_DURATION = 60, -- 1 minute emergency shield

	-- Local warning mix/pacing; does not alter damage or rope durability.
	AUDIO_WARNINGS = {
		VOLUME = 0.4,
		ROPE_LOW_PERCENT = 30,
		ROPE_CRITICAL_PERCENT = 15,
		PROFILES = {
			Freefall = { priority=60, asset="WarningSiren", gain=1, interval=1, notes={{at=0,pitch=1.3,length=.85}} },
			RopeCritical = { priority=50, asset="WarningTone", gain=.45, interval=1.2, notes={{at=0,pitch=1.5,length=.22},{at=.24,pitch=1.5,length=.22}} },
			Storm = { priority=40, asset="WarningSiren", gain=.9, interval=1.8, notes={{at=0,pitch=1,length=1.1}} },
			Critical = { priority=30, asset="WarningTone", gain=.4, interval=2.6, notes={{at=0,pitch=.8,length=.36},{at=.38,pitch=1,length=.3}} },
			Hazard = { priority=20, asset="WarningSiren", gain=.7, interval=1.5, notes={{at=0,pitch=1.1,length=1}} },
			RopeLow = { priority=10, asset="WarningTone", gain=.35, interval=3, notes={{at=0,pitch=1.1,length=.3}} },
		},
	},

	-- Crew jump impulses and shared storm curtain challenges
 JUMP_DROP_STUDS = 18,
 JUMP_MAX_PENDING_STUDS = 36,
 JUMP_DESCENT_STUDS_PER_SEC = 22,
 JUMP_COOLDOWN_SEC = 1.05,
 JUMP_BASKET_HEIGHT = 18,
 LARGE_CHALLENGE_ZONES = {1800,3600,5400,7200,9000},
 LARGE_WARNING_SEC = 6,
 LARGE_BOTTOM_OFFSET = 14,
 LARGE_WIDTH = 360,
 LARGE_HEIGHT = 120,
 LARGE_DEPTH = 32,
 LARGE_START_Z = 260,
 LARGE_SPEED = 60,
 BALLOON_TOP_CLEARANCE = 54,
 BALLOON_HIT_RADIUS = 25,

	-- Matchmaking Pods
	MAX_PLAYERS_PER_POD = 3,
	COUNTDOWN_DURATION = 0,

	-- Tether / Safety Harness
	ROPE_MAX_DURABILITY = 100,
	ROPE_DECAY_PER_SEC = 5,
 ROPE_BREAK_DEATH_DELAY_SEC = 1.25,
 ROPE_BREAK_OUTWARD_SPEED = 42,
	ROPE_REPAIR_RATE_PER_SEC = 25,
	WINCH_MOVE_DURATION_SEC = 1.3,
	WINCH_SETTLE_DURATION_SEC = 0.3,

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
