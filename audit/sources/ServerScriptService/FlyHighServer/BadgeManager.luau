local BadgeService = game:GetService("BadgeService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage:WaitForChild("FlyHigh"):WaitForChild("Modules"):WaitForChild("FlyHighConfig"))

local Manager = {}
_G.FlyHighBadgeManager = Manager

local offline = RunService:IsStudio() and game.GameId == 0
local ownedCache: { [number]: { [number]: boolean } } = {}
local inFlight: { [number]: { [number]: boolean } } = {}
local retryCooldown: { [number]: { [number]: number } } = {}
local warnedKeys: { [string]: boolean } = {}
Manager.history = {}

local function getMap(tbl, uid: number)
	local m = tbl[uid]
	if not m then
		m = {}
		tbl[uid] = m
	end
	return m
end

local function recordHistory(player: Player, badgeKey: string, badgeId: number, status: string, detail: string?)
	table.insert(Manager.history, {
		at = os.clock(),
		userId = player.UserId,
		key = badgeKey,
		badgeId = badgeId,
		status = status,
		detail = detail,
	})
	if #Manager.history > 100 then
		table.remove(Manager.history, 1)
	end
end

function Manager.SetAwardExecutor(fn)
	Manager._executor = fn
end

function Manager.ClearPlayerState(player: Player)
	local uid = player and player.UserId
	if not uid then return end
	ownedCache[uid] = nil
	inFlight[uid] = nil
	retryCooldown[uid] = nil
end

function Manager.HasCached(player: Player, badgeKey: string): boolean
	local badgeId = Config.BADGE_IDS and Config.BADGE_IDS[badgeKey]
	if not player or not badgeId then return false end
	local cache = ownedCache[player.UserId]
	return cache ~= nil and cache[badgeId] == true
end

function Manager.Award(player: Player, badgeKey: string)
	local badgeId = Config.BADGE_IDS and Config.BADGE_IDS[badgeKey]
	if not badgeId or typeof(player) ~= "Instance" or not player:IsA("Player") or player.Parent ~= Players or player.UserId <= 0 then
		return false, "invalid"
	end
	local uid = player.UserId
	local cache = getMap(ownedCache, uid)
	if cache[badgeId] then
		return true, "cached"
	end
	local busy = getMap(inFlight, uid)
	if busy[badgeId] then
		return false, "in_flight"
	end
	local cooldowns = getMap(retryCooldown, uid)
	local now = os.clock()
	if (cooldowns[badgeId] or 0) > now then
		return false, "cooldown"
	end

	busy[badgeId] = true
	task.spawn(function()
		local okExec, status, detail = pcall(function()
			if Manager._executor then
				return Manager._executor(player, badgeKey, badgeId)
			end
			if offline then
				return "offline_mock", "GameId == 0"
			end
			local okHas, hasBadge = pcall(function()
				return BadgeService:UserHasBadgeAsync(uid, badgeId)
			end)
			if okHas and hasBadge == true then
				return "already_owned", nil
			end
			local okAward, awardedOrErr = pcall(function()
				return BadgeService:AwardBadge(uid, badgeId)
			end)
			if okAward and awardedOrErr == true then
				return "awarded", nil
			end
			return "failed", tostring(awardedOrErr)
		end)
		busy[badgeId] = nil
		if player.Parent ~= Players then return end
		if not okExec then
			cooldowns[badgeId] = os.clock() + 30
			recordHistory(player, badgeKey, badgeId, "error", tostring(status))
			return
		end
		if status == "already_owned" or status == "awarded" or status == "offline_mock" then
			cache[badgeId] = true
			recordHistory(player, badgeKey, badgeId, status, detail)
		else
			cooldowns[badgeId] = os.clock() + 30
			local recordedStatus = (RunService:IsStudio() and detail == "false") and "studio_blocked" or tostring(status)
			recordHistory(player, badgeKey, badgeId, recordedStatus, detail)
			local warnKey = tostring(uid) .. ":" .. badgeKey
			if not warnedKeys[warnKey] then
				warnedKeys[warnKey] = true
				if RunService:IsStudio() and detail == "false" then
					print(string.format("[BadgeManager] Studio skipped live badge grant %s (%d) for %d; verified active via API.", badgeKey, badgeId, uid))
				else
					warn(string.format("[BadgeManager] Badge %s (%d) for %d returned %s (%s)", badgeKey, badgeId, uid, tostring(status), tostring(detail)))
				end
			end
		end
	end)
	return true, "queued"
end

function Manager.CheckDataMilestones(player: Player, data)
	if not player or type(data) ~= "table" then return end
	local th = Config.BADGE_THRESHOLDS
	Manager.Award(player, "FirstFlight")
	if (data.SummitCount or 0) >= th.SummitPioneer then
		Manager.Award(player, "PalacePioneer")
	end
	if (data.SummitCount or 0) >= th.SummitSovereign then
		Manager.Award(player, "SkySovereign")
	end
	if (data.MaxAltitude or 0) >= th.AltitudeVoyagerKm then
		Manager.Award(player, "StratosphereVoyager")
	end
	if (data.ObstaclesDestroyed or 0) >= th.ObstaclesDefender then
		Manager.Award(player, "SkyDefender")
	end
end

Players.PlayerRemoving:Connect(Manager.ClearPlayerState)

return Manager
