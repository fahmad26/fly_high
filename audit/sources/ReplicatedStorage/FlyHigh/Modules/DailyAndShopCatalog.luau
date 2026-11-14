--!strict
-- Shared catalog and economy constants for Daily Login, Sky Coins, Supply Buffs, and Cosmetics.

local Catalog = {}

Catalog.UTC7_OFFSET_SECONDS = 7 * 3600

Catalog.COINS = {
	BIOME_MILESTONES = {
		[2000] = 20,
		[4000] = 30,
		[6000] = 40,
		[8000] = 50,
	},
	BIOME_ORDER = { 2000, 4000, 6000, 8000 },
	PALACE_ARRIVAL = 150,
	REPAIR_HOLE = 10,
	RESCUE_CREW = 10,
	FLIGHT_ACTION_CAP = 60,
	DAY7_DUPLICATE_BONUS = 250,
}

Catalog.BUFF_RULES = {
	TURBO_DURATION_SEC = 60,
	TURBO_SPEED_MULTIPLIER = 1.25,
	MAX_TURBO_USES_PER_FLIGHT = 2,
	ROPE_DECAY_MULTIPLIER = 0.70, -- 30% reduction: 5 -> 3.5 HP/sec
}

Catalog.DAILY_REWARDS = {
	{
		day = 1,
		coins = 50,
		turboGas = 1,
		ropeBuff = 0,
		kits = 0,
		icon = "art_turbo_gas",
		primaryText = "1× Turbo Gas",
		subText = "+ 50 Koin",
		summary = "+1 Turbo Gas & +50 Sky Coins",
	},
	{
		day = 2,
		coins = 75,
		turboGas = 0,
		ropeBuff = 1,
		kits = 0,
		icon = "art_tali_awet",
		primaryText = "1× Tali Awet",
		subText = "+ 75 Koin",
		summary = "+1 Tali Awet & +75 Sky Coins",
	},
	{
		day = 3,
		coins = 100,
		turboGas = 0,
		ropeBuff = 0,
		kits = 0,
		tempCosmetic = { category = "tracer", id = "cyan_sky", days = 3 },
		icon = "art_cosmetic_tracer",
		primaryText = "Tracer Cyan (3 Hr)",
		subText = "+ 100 Koin",
		summary = "Tracer Cyan Langit (3 Hari) & +100 Sky Coins",
	},
	{
		day = 4,
		coins = 125,
		turboGas = 1,
		ropeBuff = 1,
		kits = 0,
		icon = "both_supply",
		primaryText = "1× Turbo + 1× Tali",
		subText = "+ 125 Koin",
		summary = "+1 Turbo Gas, +1 Tali Awet & +125 Sky Coins",
	},
	{
		day = 5,
		coins = 150,
		turboGas = 0,
		ropeBuff = 0,
		kits = 0,
		tempCosmetic = { category = "frame", id = "gold_cloud", days = 7 },
		icon = "art_cosmetic_frame",
		primaryText = "Bingkai Awan (7 Hr)",
		subText = "+ 150 Koin",
		summary = "Bingkai Tracker Awan Emas (7 Hari) & +150 Sky Coins",
	},
	{
		day = 6,
		coins = 200,
		turboGas = 2,
		ropeBuff = 0,
		kits = 0,
		icon = "art_turbo_gas",
		primaryText = "2× Turbo Gas",
		subText = "+ 200 Koin",
		summary = "+2 Turbo Gas & +200 Sky Coins",
	},
	{
		day = 7,
		coins = 350,
		turboGas = 0,
		ropeBuff = 0,
		kits = 1,
		permCosmetic = { category = "frame", id = "gold_cloud" },
		duplicateCoins = 250,
		icon = "grand_day7",
		primaryText = "1× Emergency Kit + Bingkai Awan Emas",
		subText = "HADIAH BESAR • 350 Koin (Duplikat +250 Koin)",
		summary = "+1 Emergency Kit, Bingkai Awan Emas Permanen & +350 Sky Coins",
	},
}

Catalog.SUPPLIES = {
	{
		id = "turbo_gas",
		name = "Turbo Gas",
		tag = "BUFF KECEPATAN",
		description = "Kecepatan naik & kendali +25% selama 60 detik untuk satu balon.",
		price = 120,
		stockAttribute = "SpeedBoostStock",
		artKey = "art_turbo_gas",
		badgeColor = Color3.fromRGB(14, 165, 233),
	},
	{
		id = "tali_awet",
		name = "Tali Awet",
		tag = "KETAHANAN TALI",
		description = "Kurangi pengikisan tali luar keranjang -30% (3.5 HP/s) sepanjang 1 penerbangan.",
		price = 100,
		stockAttribute = "RopeBuffStock",
		artKey = "art_tali_awet",
		badgeColor = Color3.fromRGB(245, 158, 11),
	},
}

Catalog.SUPPLIES_BY_ID = {}
for _, item in ipairs(Catalog.SUPPLIES) do
	Catalog.SUPPLIES_BY_ID[item.id] = item
end

Catalog.COSMETICS = {
	{
		id = "gold_cloud",
		category = "frame",
		key = "frame:gold_cloud",
		name = "Bingkai Awan Emas",
		tag = "BINGKAI TRACKER",
		description = "Lingkaran aura emas berkilau pada profilmu di Tracker Ketinggian seluruh server.",
		price = 300,
		artKey = "art_cosmetic_frame",
		primaryColor = Color3.fromRGB(251, 191, 36),
		secondaryColor = Color3.fromRGB(254, 240, 138),
	},
	{
		id = "aurora_teal",
		category = "frame",
		key = "frame:aurora_teal",
		name = "Bingkai Aurora Langit",
		tag = "BINGKAI TRACKER",
		description = "Cincin cahaya cyan-zamrud futuristik di Tracker Ketinggian.",
		price = 350,
		artKey = "art_cosmetic_frame_teal",
		primaryColor = Color3.fromRGB(45, 212, 191),
		secondaryColor = Color3.fromRGB(165, 243, 252),
	},
	{
		id = "cyan_sky",
		category = "tracer",
		key = "tracer:cyan_sky",
		name = "Tracer Cyan Langit",
		tag = "TRACER PELURU 1P/3P",
		description = "Jejak peluru biru langit terang (juga hadiah uji 3 hari di Hari ke-3).",
		price = 350,
		artKey = "art_cosmetic_tracer",
		primaryColor = Color3.fromRGB(56, 189, 248),
		secondaryColor = Color3.fromRGB(2, 132, 199),
	},
	{
		id = "dawn_gold",
		category = "tracer",
		key = "tracer:dawn_gold",
		name = "Tracer Emas Fajar",
		tag = "TRACER PELURU 1P/3P",
		description = "Lintasan tembakan cahaya surya keemasan menyala di angkasa.",
		price = 400,
		artKey = "art_cosmetic_tracer_gold",
		primaryColor = Color3.fromRGB(250, 204, 21),
		secondaryColor = Color3.fromRGB(249, 115, 22),
	},
	{
		id = "aurora_violet",
		category = "tracer",
		key = "tracer:aurora_violet",
		name = "Tracer Ungu Aurora",
		tag = "TRACER PELURU 1P/3P",
		description = "Jejak plasma ungu nebula dengan kilau magenta.",
		price = 450,
		artKey = "art_cosmetic_tracer_violet",
		primaryColor = Color3.fromRGB(192, 132, 252),
		secondaryColor = Color3.fromRGB(236, 72, 153),
	},
	{
		id = "faithful_explorer",
		category = "title",
		key = "title:faithful_explorer",
		titleText = "Penjelajah Setia",
		name = "Gelar: Penjelajah Setia",
		tag = "GELAR OVERHEAD",
		description = "Label kehormatan emas di bawah Rekor & Puncak kepala pemain.",
		price = 500,
		artKey = "art_cosmetic_title",
		primaryColor = Color3.fromRGB(254, 240, 138),
		secondaryColor = Color3.fromRGB(180, 83, 9),
	},
	{
		id = "cloud_conqueror",
		category = "title",
		key = "title:cloud_conqueror",
		titleText = "Penakluk Awan",
		name = "Gelar: Penakluk Awan",
		tag = "GELAR OVERHEAD",
		description = "Label biru kristal bergengsi bagi penembus badai tertinggi.",
		price = 650,
		artKey = "art_cosmetic_title_cyan",
		primaryColor = Color3.fromRGB(103, 232, 249),
		secondaryColor = Color3.fromRGB(14, 116, 144),
	},
}

Catalog.COSMETICS_BY_KEY = {}
Catalog.COSMETICS_BY_CATEGORY = { frame = {}, tracer = {}, title = {} }
for _, item in ipairs(Catalog.COSMETICS) do
	Catalog.COSMETICS_BY_KEY[item.key] = item
	Catalog.COSMETICS_BY_CATEGORY[item.category][item.id] = item
end

function Catalog.CosmeticKey(category: string, id: string): string
	return string.format("%s:%s", category, id)
end

function Catalog.GetCosmetic(category: string, id: string)
	local cat = Catalog.COSMETICS_BY_CATEGORY[category]
	return cat and cat[id] or nil
end

function Catalog.GetUTC7Day(unixTime: number?): number
	local t = unixTime or os.time()
	return math.floor((t + Catalog.UTC7_OFFSET_SECONDS) / 86400)
end

function Catalog.SecondsUntilNextUTC7Day(unixTime: number?): number
	local t = unixTime or os.time()
	local shifted = t + Catalog.UTC7_OFFSET_SECONDS
	local remainder = shifted % 86400
	return math.max(1, 86400 - remainder)
end

function Catalog.FormatDurationHMS(seconds: number): string
	local s = math.max(0, math.floor(seconds))
	local h = math.floor(s / 3600)
	local m = math.floor((s % 3600) / 60)
	local rem = s % 60
	return string.format("%02d:%02d:%02d", h, m, rem)
end

return Catalog
