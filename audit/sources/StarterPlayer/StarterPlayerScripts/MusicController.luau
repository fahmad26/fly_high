--!strict
-- Client music manager: gentle multiplayer-safe background music, per-altitude zones,
-- Palace two-stage victory sequence (Jubilation intro -> Happy Ending loop), and alert ducking.
local ContentProvider = game:GetService("ContentProvider")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")

local localPlayer = Players.LocalPlayer
local flyHigh = ReplicatedStorage:WaitForChild("FlyHigh")
local modules = flyHigh:WaitForChild("Modules")
local remotes = flyHigh:WaitForChild("Remotes")
local Config = require(modules:WaitForChild("FlyHighConfig"))
local AudioMixer = require(modules:WaitForChild("AudioMixer"))
local flightSyncEvent = remotes:WaitForChild("FlightStateSyncEvent") :: RemoteEvent

AudioMixer.Bind(localPlayer)
local musicGroup = AudioMixer.GetGroup("Music")

type TrackSpec = {
	assetId: string,
	title: string,
	zoneLabel: string,
	gain: number,
	looped: boolean,
	fadeSec: number,
}

-- Balanced ambient gains (< 0.25 even at 100% slider) so player voices & flight SFX remain clear.
local TRACKS: { [string]: TrackSpec } = {
	Lobby = {
		assetId = "rbxassetid://1845913205",
		title = "Walking On The Beach",
		zoneLabel = "Daratan Awal",
		gain = 0.24,
		looped = true,
		fadeSec = 2.4,
	},
	Biome1 = {
		assetId = "rbxassetid://1842008726",
		title = "Into the Blue Sky (b 60)",
		zoneLabel = "Ketinggian 1 (0 - 2.000 km)",
		gain = 0.22,
		looped = true,
		fadeSec = 2.2,
	},
	Biome2 = {
		assetId = "rbxassetid://9043165011",
		title = "Rising Anguish 60 B",
		zoneLabel = "Ketinggian 2 (2.000 - 4.000 km)",
		gain = 0.19,
		looped = true,
		fadeSec = 2.0,
	},
	Biome3 = {
		assetId = "rbxassetid://1842237732",
		title = "Soft Memories",
		zoneLabel = "Ketinggian 3 (4.000 - 6.000 km)",
		gain = 0.22,
		looped = true,
		fadeSec = 2.2,
	},
	Biome4 = {
		assetId = "rbxassetid://1838007258",
		title = "Dreaming of the Stars (a 60)",
		zoneLabel = "Ketinggian 4 (6.000 - 8.000 km)",
		gain = 0.22,
		looped = true,
		fadeSec = 2.2,
	},
	Biome5 = {
		assetId = "rbxassetid://1837460339",
		title = "A Place for Hope Part 3",
		zoneLabel = "Ketinggian 5 (8.000 - 10.000 km)",
		gain = 0.19,
		looped = true,
		fadeSec = 2.0,
	},
	PalaceIntro = {
		assetId = "rbxassetid://1841079605",
		title = "Jubilation (b)",
		zoneLabel = "Istana Awan (Tiba)",
		gain = 0.20,
		looped = false,
		fadeSec = 1.1,
	},
	PalaceLoop = {
		assetId = "rbxassetid://1841070706",
		title = "Happy Ending (a)",
		zoneLabel = "Istana Awan (Sanctuary)",
		gain = 0.20,
		looped = true,
		fadeSec = 1.6,
	},
}

local TRACK_ORDER = {
	"Lobby",
	"Biome1",
	"Biome2",
	"Biome3",
	"Biome4",
	"Biome5",
	"PalaceIntro",
	"PalaceLoop",
}

local BIOME_COUNT = 5
local HYSTERESIS_KM = 80
local PALACE_Y_THRESHOLD = 2400
local LOWER_WORLD_Y = 1500
local DUCK_ALERT_SCALE = 0.58
local DUCK_DOWN_RATE = 4.5
local DUCK_UP_RATE = 1.4

local musicFolder = Instance.new("Folder")
musicFolder.Name = "FlyHighMusic"
musicFolder.Parent = SoundService

local preloadFolder = Instance.new("Folder")
preloadFolder.Name = "PreloadCache"
preloadFolder.Parent = musicFolder

local preloadSounds: { Sound } = {}
for _, key in TRACK_ORDER do
	local spec = TRACKS[key]
	local s = Instance.new("Sound")
	s.Name = key
	s.SoundId = spec.assetId
	s.Volume = 0
	s.Playing = false
	s.Parent = preloadFolder
	table.insert(preloadSounds, s)
end

type Deck = {
	name: string,
	sound: Sound,
	trackKey: string?,
	baseGain: number,
	progress: number,
	dir: number,
	fadeSec: number,
	playSeq: number,
	startedAt: number,
}

local function createDeck(name: string): Deck
	local s = Instance.new("Sound")
	s.Name = name
	s.Volume = 0
	s.Playing = false
	s.SoundGroup = musicGroup
	s.Parent = musicFolder
	return {
		name = name,
		sound = s,
		trackKey = nil,
		baseGain = 0,
		progress = 0,
		dir = 0,
		fadeSec = 2.0,
		playSeq = 0,
		startedAt = 0,
	}
end

local deckA = createDeck("DeckA")
local deckB = createDeck("DeckB")
local activeDeck: Deck = deckA
local standbyDeck: Deck = deckB

local currentBiome = 1
local altitudeKm = 0
local inPalace = false
local palacePhase: "None" | "Intro" | "Loop" = "None"
local palaceSessionToken = 0
local activeTrackKey: string? = nil
local introTriggerSeq = 0
local duckMultiplier = 1.0
local cleaned = false

musicFolder:SetAttribute("ActiveZone", "")
musicFolder:SetAttribute("ActiveTrackTitle", "")
musicFolder:SetAttribute("ActiveAssetId", "")
musicFolder:SetAttribute("PalacePhase", "None")
musicFolder:SetAttribute("DuckMultiplier", 1)
musicFolder:SetAttribute("LoadedCount", 0)

local function syncTelemetry(key: string?)
	local spec = key and TRACKS[key] or nil
	musicFolder:SetAttribute("ActiveZone", key or "")
	musicFolder:SetAttribute("ActiveTrackTitle", spec and spec.title or "")
	musicFolder:SetAttribute("ActiveAssetId", spec and spec.assetId or "")
	musicFolder:SetAttribute("PalacePhase", palacePhase)
end

local function isInFlight(): boolean
	return localPlayer:GetAttribute("InFlight") == true
end

local function isAlertDuckingActive(): boolean
	local warningFolder = localPlayer.PlayerScripts:FindFirstChild("WarningAudioController")
	local warningAudio = warningFolder and warningFolder:FindFirstChild("FlyHighWarningAudio")
	if warningAudio then
		local activeWarning = warningAudio:GetAttribute("ActiveWarning")
		if typeof(activeWarning) == "string" and activeWarning ~= "" then
			return true
		end
	end
	local pg = localPlayer:FindFirstChildOfClass("PlayerGui")
	local hud = pg and pg:FindFirstChild("FlyHighHUD")
	local banner = hud and hud:FindFirstChild("AlertBanner")
	if banner and banner:GetAttribute("HUDAlertActive") == true then
		return true
	end
	return false
end

local function computeBiomeWithHysteresis(km: number): number
	local step = Config.BIOME_STEP_KM
	local raw = math.clamp(math.floor(km / step) + 1, 1, BIOME_COUNT)
	if raw > currentBiome then
		currentBiome = raw
	elseif raw < currentBiome then
		local floorBoundary = (currentBiome - 1) * step
		if km < floorBoundary - HYSTERESIS_KM then
			currentBiome = raw
		end
	end
	return currentBiome
end

local function desiredTrackKey(): string
	if inPalace then
		return palacePhase == "Loop" and "PalaceLoop" or "PalaceIntro"
	end
	if isInFlight() then
		local biome = computeBiomeWithHysteresis(altitudeKm)
		return "Biome" .. tostring(biome)
	end
	return "Lobby"
end

local function applyDeckVolume(deck: Deck)
	local p = math.clamp(deck.progress, 0, 1)
	local smooth = p * p * (3 - 2 * p)
	deck.sound.Volume = deck.baseGain * smooth * duckMultiplier
end

local function switchTrack(nextKey: string)
	if cleaned or nextKey == activeTrackKey then
		return
	end
	local spec = TRACKS[nextKey]
	if not spec then
		return
	end
	activeTrackKey = nextKey

	-- Fade out current active deck smoothly on standby.
	if activeDeck.trackKey ~= nil and activeDeck.progress > 0 then
		activeDeck.dir = -1
		activeDeck.fadeSec = math.max(0.6, spec.fadeSec * 0.85)
	else
		activeDeck.sound:Stop()
		activeDeck.trackKey = nil
		activeDeck.progress = 0
		activeDeck.dir = 0
	end

	activeDeck, standbyDeck = standbyDeck, activeDeck

	activeDeck.playSeq += 1
	local mySeq = activeDeck.playSeq
	activeDeck.trackKey = nextKey
	activeDeck.baseGain = spec.gain
	activeDeck.progress = 0
	activeDeck.dir = 1
	activeDeck.fadeSec = spec.fadeSec
	activeDeck.startedAt = os.clock()

	local s = activeDeck.sound
	s:Stop()
	s.SoundId = spec.assetId
	s.Looped = spec.looped
	s.TimePosition = 0
	s.Volume = 0
	s:Play()

	if nextKey == "PalaceIntro" then
		introTriggerSeq = mySeq
	end

	syncTelemetry(nextKey)
end

local function refreshMusicZone()
	if cleaned then
		return
	end
	switchTrack(desiredTrackKey())
end

local function enterPalace()
	if not inPalace then
		inPalace = true
		palaceSessionToken += 1
		palacePhase = "Intro"
	elseif palacePhase == "None" then
		palacePhase = "Intro"
	end
	refreshMusicZone()
end

local function exitPalaceToLobby()
	if not inPalace and palacePhase == "None" then
		return
	end
	inPalace = false
	palacePhase = "None"
	palaceSessionToken += 1
	introTriggerSeq = 0
	altitudeKm = 0
	currentBiome = 1
	refreshMusicZone()
end

local function completePalaceIntro()
	if cleaned or not inPalace or palacePhase ~= "Intro" then
		return
	end
	palacePhase = "Loop"
	refreshMusicZone()
end

local function getRootY(): number?
	local char = localPlayer.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		return root.Position.Y
	end
	return nil
end

local function evaluatePalaceStateFromAttributes()
	local pendingArrival = localPlayer:GetAttribute("ArrivalPending") == true
	local palaceArrival = localPlayer:GetAttribute("PalaceArrival")
	if isInFlight() then
		inPalace = false
		palacePhase = "None"
		refreshMusicZone()
		return
	end
	if pendingArrival or typeof(palaceArrival) == "Vector3" then
		enterPalace()
		return
	end
	local y = getRootY()
	if y and y >= PALACE_Y_THRESHOLD then
		enterPalace()
		return
	end
	if inPalace and not pendingArrival and palaceArrival == nil and (not y or y < LOWER_WORLD_Y) then
		exitPalaceToLobby()
	else
		refreshMusicZone()
	end
end

local connections: { RBXScriptConnection } = {}
local function trackConn(c: RBXScriptConnection)
	table.insert(connections, c)
end

local function bindDeckEnded(deck: Deck)
	trackConn(deck.sound.Ended:Connect(function()
		if deck == activeDeck and deck.trackKey == "PalaceIntro" and deck.playSeq == introTriggerSeq then
			completePalaceIntro()
		end
	end))
end
bindDeckEnded(deckA)
bindDeckEnded(deckB)

trackConn(flightSyncEvent.OnClientEvent:Connect(function(data)
	if typeof(data) ~= "table" then
		return
	end
	if data.isVictory then
		altitudeKm = Config.MAX_ALTITUDE_KM
		currentBiome = BIOME_COUNT
		enterPalace()
		return
	end
	if data.isGameOver then
		altitudeKm = 0
		currentBiome = 1
		exitPalaceToLobby()
		return
	end
	local km = tonumber(data.altitudeKm) or 0
	altitudeKm = km
	if inPalace and not isInFlight() and localPlayer:GetAttribute("ArrivalPending") ~= true then
		local palaceArrival = localPlayer:GetAttribute("PalaceArrival")
		local y = getRootY()
		if palaceArrival == nil and km == 0 and (not y or y < LOWER_WORLD_Y) then
			exitPalaceToLobby()
			return
		end
	end
	refreshMusicZone()
end))

trackConn(localPlayer:GetAttributeChangedSignal("InFlight"):Connect(function()
	if isInFlight() then
		inPalace = false
		palacePhase = "None"
		altitudeKm = 0
		currentBiome = 1
	end
	evaluatePalaceStateFromAttributes()
end))

trackConn(localPlayer:GetAttributeChangedSignal("ArrivalPending"):Connect(evaluatePalaceStateFromAttributes))
trackConn(localPlayer:GetAttributeChangedSignal("PalaceArrival"):Connect(evaluatePalaceStateFromAttributes))

trackConn(localPlayer.CharacterAdded:Connect(function(char)
	task.defer(function()
		if cleaned or localPlayer.Character ~= char then
			return
		end
		char:WaitForChild("HumanoidRootPart", 5)
		task.wait(0.15)
		if not cleaned then
			evaluatePalaceStateFromAttributes()
		end
	end)
end))

-- Initial state evaluation: starts Daratan Awal cleanly with gentle fade-in (or restores Palace/InFlight if rejoining).
evaluatePalaceStateFromAttributes()
refreshMusicZone()

-- Background preload for remaining zones without delaying initial Daratan Awal playback.
local preloadTask = task.spawn(function()
	task.wait(0.8)
	if cleaned then
		return
	end
	pcall(function()
		ContentProvider:PreloadAsync(preloadSounds)
	end)
	if cleaned then
		return
	end
	local loaded = 0
	for _, s in preloadSounds do
		if s.IsLoaded then
			loaded += 1
		end
	end
	musicFolder:SetAttribute("LoadedCount", loaded)
end)

local function updateDeckFade(deck: Deck, dt: number)
	if deck.dir ~= 0 then
		local step = dt / math.max(0.25, deck.fadeSec)
		deck.progress = math.clamp(deck.progress + deck.dir * step, 0, 1)
		if deck.dir > 0 and deck.progress >= 1 then
			deck.progress = 1
			deck.dir = 0
		elseif deck.dir < 0 and deck.progress <= 0 then
			deck.progress = 0
			deck.dir = 0
			deck.sound:Stop()
			deck.trackKey = nil
		end
	end
	applyDeckVolume(deck)
end

local lastSyncCheck = 0
trackConn(RunService.Heartbeat:Connect(function(dt: number)
	if cleaned then
		return
	end
	local clDt = math.min(dt, 0.1)

	-- Smoothly duck music during active flight alarms/warnings so teammates and sirens stand out.
	local targetDuck = isAlertDuckingActive() and DUCK_ALERT_SCALE or 1.0
	if math.abs(targetDuck - duckMultiplier) > 0.0005 then
		local duckRate = targetDuck < duckMultiplier and DUCK_DOWN_RATE or DUCK_UP_RATE
		local nextDuck = duckMultiplier + (targetDuck - duckMultiplier) * math.clamp(clDt * duckRate, 0, 1)
		if math.abs(targetDuck - nextDuck) <= 0.002 then
			nextDuck = targetDuck
		end
		duckMultiplier = nextDuck
		musicFolder:SetAttribute("DuckMultiplier", math.round(duckMultiplier * 1000) / 1000)
	elseif duckMultiplier ~= targetDuck then
		duckMultiplier = targetDuck
		musicFolder:SetAttribute("DuckMultiplier", targetDuck)
	end

	updateDeckFade(deckA, clDt)
	updateDeckFade(deckB, clDt)

	-- Near-end seamless crossfade / stall guard for Palace Jubilation -> Happy Ending loop.
	if inPalace and palacePhase == "Intro" and activeDeck.trackKey == "PalaceIntro" then
		local s = activeDeck.sound
		local elapsed = os.clock() - activeDeck.startedAt
		local nearNaturalEnd = s.IsLoaded and s.TimeLength > 2 and s.TimePosition >= (s.TimeLength - 0.35)
		local timedOut = (not s.IsLoaded and elapsed > 8) or elapsed > math.max(70, (s.TimeLength > 1 and s.TimeLength + 3) or 70)
		if nearNaturalEnd or timedOut then
			completePalaceIntro()
		end
	end

	lastSyncCheck += clDt
	if lastSyncCheck >= 0.25 then
		lastSyncCheck = 0
		if inPalace and localPlayer:GetAttribute("ArrivalPending") ~= true and localPlayer:GetAttribute("PalaceArrival") == nil and not isInFlight() then
			local y = getRootY()
			if y and y < LOWER_WORLD_Y then
				exitPalaceToLobby()
			end
		end
	end
end))

local function cleanup()
	if cleaned then
		return
	end
	cleaned = true
	if coroutine.status(preloadTask) ~= "dead" then
		task.cancel(preloadTask)
	end
	for _, c in connections do
		c:Disconnect()
	end
	table.clear(connections)
	deckA.sound:Stop()
	deckB.sound:Stop()
	musicFolder:Destroy()
end

script.Destroying:Connect(cleanup)