-- Obstacle sound catalog (AUDIO-01, design/features/obstacle-audio/design.md).
-- Assets are Roblox-licensed Pro Sound Effects / APM library sounds, except WindGust (creator-synthesized).
-- Every key may be swapped after a listening pass; only this table needs to change.
local Catalog = {}

Catalog.Assets = {
	SeagullCall = "rbxassetid://9118858259", -- Seagull Squawks 3 (PSE)
	BirdFlap = "rbxassetid://9113443901", -- Bird Flying 1 (PSE)
	HawkFlapCall = "rbxassetid://9114787449", -- Hawk Bird Wings Flap Flutter 1 (PSE)
	PigeonFlap = "rbxassetid://9113444620", -- Bird Wing Flaps Pigeon Two 1 (PSE)
	IceShatter = "rbxassetid://9114855870", -- Ice Block Drop To Concrete Shatter 1 (PSE)
	WindGust = "rbxassetid://88352118429536", -- Wind Gust (synthesized, no third-party samples)
	DroneHum = "rbxassetid://9114037089", -- Deep Synthetic Drone 8 (PSE)
	Beep = "rbxassetid://9119100090", -- Shortwave Bleep Beeps 9 (PSE)
	Zap = "rbxassetid://9116277954", -- Lightning Flashes Quick Electrical Bursts 32 (PSE)
	ZapShort = "rbxassetid://9116276051", -- Lightning Flashes Quick Electrical Bursts 11 (PSE)
	BeeBuzz = "rbxassetid://9113414621", -- Bee Various Buzzing Actions 10 (PSE)
	MetalCreak = "rbxassetid://9126282474", -- Wood Strain Stress Metal Creaking (PSE)
	MetalClang = "rbxassetid://9125819197", -- Robot Impact Metal Clangs 1 (PSE)
	RockHit = "rbxassetid://9118608146", -- Rock Hits Rock On Rock 8 (PSE)
	RockBreak = "rbxassetid://9118588165", -- Rock Drop On Concrete Breaks 10 (PSE)
	Thunder = "rbxassetid://9126099928", -- Thunder Constant Huge Hissing Strikes 2 (PSE)
	Boom = "rbxassetid://9125484743", -- Deep Hits Big Reverberant Booms 3 (PSE)
	CreatureRoar = "rbxassetid://9113980319", -- Creature Mix Giant Monster Roar Growl 1 (PSE)
	Waterphone = "rbxassetid://9120574965", -- Waterphone Burst 3 (PSE)
	Swish = "rbxassetid://9126283592", -- Wood Swish Whoosh Fast Movement 17 (PSE)
	SynthWhomp = "rbxassetid://9119873304", -- Synth Whomps 17 (PSE)
	FieryBlaze = "rbxassetid://9116316301", -- Swooshing Whisps Fiery Blaze 1 (PSE)
	Pixies = "rbxassetid://1847063040", -- Pixies C (APM)
}

-- A cue: { asset, volume, pitch = {min,max} | number, loop, duration (one-shot cut), fade, range = {min,max}, priority }
-- Priorities follow the design: active 4 > destroy 3 > telegraph 2 > approach 1.
local function cue(asset, volume, pitch, extra)
	local c = { asset = asset, volume = volume, pitch = pitch or 1 }
	for k, v in extra or {} do c[k] = v end
	return c
end

local SMALL, MEDIUM, LARGE, HUGE = { 8, 140 }, { 12, 220 }, { 20, 320 }, { 30, 520 }

-- Enemies are keyed by the server model name (ObstacleManager bands[].enemy).
Catalog.Enemies = {
	WildBird = {
		approach = { cue("SeagullCall", 0.55, { 0.95, 1.12 }, { range = MEDIUM }), cue("BirdFlap", 0.28, { 0.95, 1.1 }, { loop = true, range = SMALL }) },
		destroy = { cue("PigeonFlap", 0.6, { 1.1, 1.3 }, { range = MEDIUM }) },
	},
	StormBat = {
		approach = { cue("HawkFlapCall", 0.42, { 1.55, 1.75 }, { duration = 2.2, range = MEDIUM }), cue("PigeonFlap", 0.3, { 1.5, 1.7 }, { loop = true, range = SMALL }) },
		destroy = { cue("HawkFlapCall", 0.5, { 1.9, 2.1 }, { duration = 0.9, range = MEDIUM }) },
	},
	Hailstone = {
		approach = { cue("WindGust", 0.5, { 1.25, 1.45 }, { duration = 2.6, fade = 0.6, range = MEDIUM }) },
		destroy = { cue("IceShatter", 0.75, { 0.95, 1.1 }, { range = MEDIUM }) },
	},
	GuardianDrone = {
		approach = { cue("DroneHum", 0.32, { 1.5, 1.7 }, { loop = true, range = MEDIUM }) },
		charge = { cue("Beep", 0.5, 1.35, { range = MEDIUM }) },
		destroy = { cue("Zap", 0.6, 1, { range = MEDIUM }), cue("Boom", 0.35, 2.1, { duration = 1.4, range = MEDIUM }) },
	},
	FireBee = {
		approach = { cue("BeeBuzz", 0.42, { 0.75, 0.85 }, { loop = true, range = SMALL }) },
		destroy = { cue("Boom", 0.4, 2.3, { duration = 1.1, range = MEDIUM }), cue("FieryBlaze", 0.35, 1.6, { duration = 0.9, fade = 0.5, range = SMALL }) },
	},
	CrystalWyvern = {
		approach = { cue("CreatureRoar", 0.5, { 1.05, 1.2 }, { duration = 2.6, range = LARGE }), cue("BirdFlap", 0.32, 0.6, { loop = true, range = MEDIUM }) },
		destroy = { cue("CreatureRoar", 0.55, 1.35, { duration = 1.4, range = LARGE }), cue("IceShatter", 0.55, 0.8, { range = MEDIUM }) },
	},
	ShadowPhantom = {
		approach = { cue("Waterphone", 0.38, { 0.75, 0.85 }, { loop = true, range = MEDIUM }) },
		destroy = { cue("Waterphone", 0.55, 1.45, { duration = 1.6, fade = 0.8, range = MEDIUM }) },
	},
	SatelliteDebris = {
		approach = { cue("MetalCreak", 0.45, { 0.65, 0.75 }, { loop = true, range = MEDIUM }) },
		destroy = { cue("MetalClang", 0.65, 0.9, { range = MEDIUM }) },
	},
	CelestialPhoenix = {
		approach = { cue("HawkFlapCall", 0.55, { 0.72, 0.8 }, { duration = 3, range = LARGE }), cue("FieryBlaze", 0.3, 1, { loop = true, range = MEDIUM }) },
		destroy = { cue("HawkFlapCall", 0.6, 0.9, { duration = 1.5, range = LARGE }), cue("Boom", 0.4, 1.6, { duration = 1.6, range = LARGE }) },
	},
	-- Guardian drone projectile.
	Spike = {
		approach = { cue("Swish", 0.6, { 1.2, 1.35 }, { range = MEDIUM }) },
	},
}

-- Hazards are keyed by ObstacleManager effect. telegraph plays during the warning window,
-- active from HazardActive=true. Both play whether or not the balloon is hit.
Catalog.Hazards = {
	Tornado = {
		telegraph = { cue("WindGust", 0.4, 0.7, { loop = true, range = LARGE }) },
		active = { cue("WindGust", 0.65, 0.62, { loop = true, range = LARGE }) },
	},
	Lightning = {
		telegraph = { cue("ZapShort", 0.35, { 0.7, 0.8 }, { loop = true, range = LARGE }) },
		active = { cue("Thunder", 0.75, 1, { duration = 3.4, fade = 1, range = HUGE }) },
	},
	Wind = {
		telegraph = { cue("WindGust", 0.35, 1.15, { duration = 2.5, fade = 0.6, range = LARGE }) },
		active = { cue("WindGust", 0.55, 0.9, { loop = true, range = LARGE }) },
	},
	Debris = {
		telegraph = { cue("RockHit", 0.45, 0.6, { repeatEvery = 0.9, range = LARGE }) },
		active = { cue("RockHit", 0.55, { 0.55, 0.8 }, { repeatEvery = 0.7, range = LARGE }) },
	},
	Heat = {
		telegraph = { cue("FieryBlaze", 0.3, 0.7, { loop = true, range = LARGE }) },
		active = { cue("FieryBlaze", 0.55, 0.9, { loop = true, range = LARGE }), cue("WindGust", 0.35, 0.75, { loop = true, range = LARGE }) },
	},
	Magnetic = {
		telegraph = { cue("DroneHum", 0.28, 1.9, { loop = true, range = LARGE }) },
		active = { cue("SynthWhomp", 0.6, 1, { range = LARGE }), cue("ZapShort", 0.45, 1.3, { range = LARGE }) },
	},
	Fog = {
		telegraph = { cue("Waterphone", 0.3, 0.6, { duration = 3, fade = 1, range = HUGE }) },
		active = { cue("DroneHum", 0.4, 0.5, { loop = true, range = HUGE }) },
	},
	Meteor = {
		telegraph = { cue("DroneHum", 0.35, 0.42, { loop = true, range = HUGE }) },
		active = { cue("Swish", 0.6, 0.55, { range = HUGE }), cue("Boom", 0.55, 1, { duration = 3, fade = 1.2, range = HUGE }) },
	},
	Storm = {
		telegraph = { cue("WindGust", 0.4, 0.55, { loop = true, range = HUGE }) },
		active = { cue("DroneHum", 0.4, 0.38, { loop = true, range = HUGE }) },
		strike = { cue("Thunder", 0.7, { 0.9, 1.05 }, { duration = 2.4, fade = 0.8, range = HUGE }) },
	},
	-- Storm Curtain (LargeChallengeManager): Stage Warning -> Active.
	StormCurtain = {
		telegraph = { cue("WindGust", 0.5, 0.5, { loop = true, range = { 60, 900 } }) },
		active = { cue("WindGust", 0.8, 0.45, { loop = true, range = { 60, 900 } }), cue("Boom", 0.5, 0.7, { duration = 4, fade = 1.5, range = { 60, 900 } }) },
	},
}

Catalog.MAX_VOICES = 6
Catalog.MAX_VOICES_MOBILE = 4
Catalog.APPROACH_COOLDOWN = 1.5
Catalog.DUCK_PRIORITY = 40 -- WarningAudio profiles with priority >= this duck obstacle sounds
Catalog.DUCK_GAIN = 0.6

return Catalog