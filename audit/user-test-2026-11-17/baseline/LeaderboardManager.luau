local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Catalog = require(RS.FlyHigh.Modules.DailyAndShopCatalog)
local Renderer = require(RS.FlyHigh.Modules.LeaderboardBoardRenderer)

local Manager = {}
_G.FlyHighLeaderboardManager = Manager

local offline = RunService:IsStudio() and game.GameId == 0
local ALL_TIME_STORE_NAME = "FlyHigh_TopSummits_AllTime_v1"
local MONTH_STORE_PREFIX = "FlyHigh_TopSummits_Month_"
local REFRESH_INTERVAL_SEC = 30
local FLUSH_MIN_INTERVAL_SEC = 20

local simulatedUnixTime: number? = nil
local function nowUnix(): number
	return simulatedUnixTime or os.time()
end

local allTimeStore = not offline and DataStoreService:GetOrderedDataStore(ALL_TIME_STORE_NAME) or nil
local activeMonthKey, activeYear, activeMonth = Catalog.GetUTC7YearMonth(nowUnix())
local activeMonthLabel = Catalog.FormatMonthLabelWIB(activeYear, activeMonth)
local monthlyStore = not offline and DataStoreService:GetOrderedDataStore(MONTH_STORE_PREFIX .. tostring(activeMonthKey)) or nil

local nameCache: { [number]: string } = {}
local sessionAllTime: { [number]: any } = {}
local sessionMonthly: { [number]: any } = {}
local odsAllTimeCache: { any } = {}
local odsMonthlyCache: { any } = {}
local pendingFlush: { [number]: { allScore: number, monthScore: number, monthKey: number } } = {}
local lastFlushAt: { [number]: number } = {}

local qaFixtureMode = false
local qaFixtures = { allTime = {}, monthly = {} }
local lastDisplayedAllTime: { any } = {}
local lastDisplayedMonthly: { any } = {}

local allTimeGui: SurfaceGui? = nil
local monthlyGui: SurfaceGui? = nil
local dirtyRender = true

local function resolvePlayerName(userId: number): string
	if userId <= 0 then
		return "Pendaki"
	end
	local live = Players:GetPlayerByUserId(userId)
	if live then
		local display = (live.DisplayName ~= "" and live.DisplayName) or live.Name
		nameCache[userId] = display
		return display
	end
	if nameCache[userId] then
		return nameCache[userId]
	end
	local ok, fetched = pcall(function()
		return Players:GetNameFromUserIdAsync(userId)
	end)
	if ok and type(fetched) == "string" and fetched ~= "" then
		nameCache[userId] = fetched
		return fetched
	end
	return "Pendaki #" .. tostring(userId)
end

local function monthlySubtitle(): string
	return string.format("Reset Tgl 1 WIB · %s", activeMonthLabel)
end

local function ensureBoardsBound(): boolean
	if allTimeGui and allTimeGui.Parent and monthlyGui and monthlyGui.Parent then
		return true
	end
	local lobby = workspace:FindFirstChild("FlyHighLobby")
	local group = lobby and lobby:FindFirstChild("SpawnLeaderboards")
	if not group then
		return false
	end
	local allModel = group:FindFirstChild("LeaderboardAllTime")
	local monthModel = group:FindFirstChild("LeaderboardMonthly")
	local allScreen = allModel and allModel:FindFirstChild("BoardScreen")
	local monthScreen = monthModel and monthModel:FindFirstChild("BoardScreen")
	if not (allScreen and allScreen:IsA("BasePart") and monthScreen and monthScreen:IsA("BasePart")) then
		return false
	end
	allTimeGui = Renderer.BuildBoardGui(allScreen, {
		title = "TOP 10 PUNCAK · ALL TIME",
		subtitle = "Semua Waktu · Puncak > Rekor km",
		footer = "Pencapai 10.000 km selalu berada di peringkat atas",
		accent = Color3.fromRGB(250, 204, 21),
		badgeText = "ALL",
	})
	monthlyGui = Renderer.BuildBoardGui(monthScreen, {
		title = "TOP 10 PUNCAK · 1 BULAN",
		subtitle = monthlySubtitle(),
		footer = "Otomatis di-reset setiap tanggal 1 pukul 00:00 WIB",
		accent = Color3.fromRGB(56, 189, 248),
		badgeText = "BLN",
	})
	return true
end

local function mergeTop(odsList: { any }, liveMap: { [number]: any }): { any }
	local byId: { [number]: any } = {}
	for _, entry in ipairs(odsList) do
		byId[entry.userId] = entry
	end
	for uid, entry in pairs(liveMap) do
		local existing = byId[uid]
		if not existing or entry.score > existing.score then
			byId[uid] = entry
		end
	end
	local combined = {}
	for _, entry in pairs(byId) do
		table.insert(combined, entry)
	end
	return Renderer.SortEntries(combined, Renderer.MAX_ROWS)
end

local function renderBoards()
	if not ensureBoardsBound() then
		return
	end
	if qaFixtureMode then
		lastDisplayedAllTime = Renderer.SortEntries(qaFixtures.allTime, Renderer.MAX_ROWS)
		lastDisplayedMonthly = Renderer.SortEntries(qaFixtures.monthly, Renderer.MAX_ROWS)
	else
		lastDisplayedAllTime = mergeTop(odsAllTimeCache, sessionAllTime)
		lastDisplayedMonthly = mergeTop(odsMonthlyCache, sessionMonthly)
	end
	if allTimeGui then
		Renderer.RenderBoard(allTimeGui, lastDisplayedAllTime)
	end
	if monthlyGui then
		Renderer.RenderBoard(monthlyGui, lastDisplayedMonthly, monthlySubtitle())
	end
	dirtyRender = false
end

local function fetchOrderedTop(store: OrderedDataStore?): { any }
	if not store then
		return {}
	end
	local ok, pages = pcall(function()
		return store:GetSortedAsync(false, Renderer.MAX_ROWS)
	end)
	if not ok or not pages then
		return {}
	end
	local pageOk, items = pcall(function()
		return pages:GetCurrentPage()
	end)
	if not pageOk or type(items) ~= "table" then
		return {}
	end
	local out = {}
	for _, item in ipairs(items) do
		local uid = tonumber(item.key)
		local score = tonumber(item.value) or 0
		if uid and uid > 0 and score > 0 then
			local summits, maxAlt = Renderer.DecodeScore(score)
			table.insert(out, {
				userId = uid,
				name = resolvePlayerName(uid),
				summits = summits,
				maxAlt = maxAlt,
				score = score,
			})
		end
	end
	return out
end

local function checkMonthRollover(): boolean
	local monthKey, year, month = Catalog.GetUTC7YearMonth(nowUnix())
	if monthKey == activeMonthKey then
		return false
	end
	activeMonthKey = monthKey
	activeYear = year
	activeMonth = month
	activeMonthLabel = Catalog.FormatMonthLabelWIB(year, month)
	monthlyStore = not offline and DataStoreService:GetOrderedDataStore(MONTH_STORE_PREFIX .. tostring(monthKey)) or nil
	odsMonthlyCache = {}
	sessionMonthly = {}
	for uid, pend in pairs(pendingFlush) do
		if pend.monthKey ~= monthKey then
			pend.monthKey = monthKey
			pend.monthScore = 0
		end
	end
	if qaFixtureMode then
		local filtered = {}
		for _, item in ipairs(qaFixtures.monthly) do
			if item.monthKey == monthKey then
				table.insert(filtered, item)
			end
		end
		qaFixtures.monthly = filtered
	end
	if not qaFixtureMode and _G.FlyHighDataManager and _G.FlyHighDataManager.RolloverMonthly then
		_G.FlyHighDataManager.RolloverMonthly(monthKey)
	end
	dirtyRender = true
	return true
end

local function flushPlayer(userId: number)
	if offline then
		pendingFlush[userId] = nil
		return
	end
	local pend = pendingFlush[userId]
	if not pend then
		return
	end
	pendingFlush[userId] = nil
	lastFlushAt[userId] = os.clock()

	if allTimeStore and pend.allScore > 0 then
		pcall(function()
			allTimeStore:UpdateAsync(tostring(userId), function(oldVal)
				local prev = tonumber(oldVal) or 0
				return math.max(prev, pend.allScore)
			end)
		end)
	end
	if monthlyStore and pend.monthKey == activeMonthKey and pend.monthScore > 0 then
		pcall(function()
			monthlyStore:UpdateAsync(tostring(userId), function(oldVal)
				local prev = tonumber(oldVal) or 0
				return math.max(prev, pend.monthScore)
			end)
		end)
	end
end

function Manager.RecordPlayer(player: Player, data: { [string]: any }, immediate: boolean?)
	if not player or player.UserId <= 0 or type(data) ~= "table" then
		return
	end
	checkMonthRollover()
	local uid = player.UserId
	local displayName = (player.DisplayName ~= "" and player.DisplayName) or player.Name
	nameCache[uid] = displayName

	local allSummits = math.max(0, math.floor(tonumber(data.SummitCount) or 0))
	local allAlt = math.clamp(math.floor(tonumber(data.MaxAltitude) or 0), 0, Renderer.MAX_ALTITUDE_KM)
	local allScore = Renderer.EncodeScore(allSummits, allAlt)
	if allScore > 0 then
		sessionAllTime[uid] = {
			userId = uid,
			name = displayName,
			summits = allSummits,
			maxAlt = allSummits > 0 and Renderer.MAX_ALTITUDE_KM or allAlt,
			score = allScore,
		}
	end

	local mKey = tonumber(data.MonthlyKey) or activeMonthKey
	local monthScore = 0
	if mKey == activeMonthKey then
		local mSummits = math.max(0, math.floor(tonumber(data.MonthlySummitCount) or 0))
		local mAlt = math.clamp(math.floor(tonumber(data.MonthlyMaxAltitude) or 0), 0, Renderer.MAX_ALTITUDE_KM)
		monthScore = Renderer.EncodeScore(mSummits, mAlt)
		if monthScore > 0 then
			sessionMonthly[uid] = {
				userId = uid,
				name = displayName,
				summits = mSummits,
				maxAlt = mSummits > 0 and Renderer.MAX_ALTITUDE_KM or mAlt,
				score = monthScore,
			}
		end
	end

	if not offline then
		local existing = pendingFlush[uid]
		pendingFlush[uid] = {
			allScore = math.max(existing and existing.allScore or 0, allScore),
			monthScore = math.max(existing and existing.monthKey == activeMonthKey and existing.monthScore or 0, monthScore),
			monthKey = activeMonthKey,
		}
		if immediate then
			task.spawn(flushPlayer, uid)
		end
	end
	dirtyRender = true
	renderBoards()
end

local function syncPlayerFromDataManager(player: Player)
	if _G.FlyHighDataManager and _G.FlyHighDataManager.GetLeaderboardData then
		local lb = _G.FlyHighDataManager.GetLeaderboardData(player)
		if lb then
			Manager.RecordPlayer(player, {
				SummitCount = lb.allTime.summits,
				MaxAltitude = lb.allTime.maxAlt,
				MonthlyKey = lb.monthly.key,
				MonthlySummitCount = lb.monthly.summits,
				MonthlyMaxAltitude = lb.monthly.maxAlt,
			}, false)
		end
	end
end

local function hookPlayer(player: Player)
	if player:GetAttribute("DataReady") == true then
		syncPlayerFromDataManager(player)
	end
	player:GetAttributeChangedSignal("DataReady"):Connect(function()
		if player:GetAttribute("DataReady") == true then
			syncPlayerFromDataManager(player)
		end
	end)
end

Players.PlayerAdded:Connect(hookPlayer)
for _, p in ipairs(Players:GetPlayers()) do
	hookPlayer(p)
end

Players.PlayerRemoving:Connect(function(player)
	if not offline and pendingFlush[player.UserId] then
		task.spawn(flushPlayer, player.UserId)
	end
end)

-- Server-only QA / administrative inspection control under ServerScriptService (never accessible to clients)
local control = Instance.new("BindableFunction")
control.Name = "Control"
control.OnInvoke = function(action: string, payload: any)
	if action == "GetState" then
		return {
			offline = offline,
			monthKey = activeMonthKey,
			monthLabel = activeMonthLabel,
			qaFixtureMode = qaFixtureMode,
			allTime = lastDisplayedAllTime,
			monthly = lastDisplayedMonthly,
		}
	end
	if not (RunService:IsStudio() or offline) then
		return { ok = false, reason = "Studio only" }
	end
	if action == "SetSimulatedTime" then
		simulatedUnixTime = type(payload) == "number" and payload or nil
		local rolled = checkMonthRollover()
		renderBoards()
		return {
			ok = true,
			rolled = rolled,
			monthKey = activeMonthKey,
			monthLabel = activeMonthLabel,
			monthly = lastDisplayedMonthly,
		}
	elseif action == "SetFixtures" then
		qaFixtureMode = true
		if type(payload) == "table" then
			qaFixtures.allTime = type(payload.allTime) == "table" and payload.allTime or {}
			qaFixtures.monthly = type(payload.monthly) == "table" and payload.monthly or {}
			if payload.simulatedUnix ~= nil then
				simulatedUnixTime = type(payload.simulatedUnix) == "number" and payload.simulatedUnix or nil
				checkMonthRollover()
			end
		end
		renderBoards()
		return {
			ok = true,
			monthKey = activeMonthKey,
			monthLabel = activeMonthLabel,
			allTime = lastDisplayedAllTime,
			monthly = lastDisplayedMonthly,
		}
	elseif action == "ClearFixtures" then
		qaFixtureMode = false
		qaFixtures = { allTime = {}, monthly = {} }
		simulatedUnixTime = nil
		checkMonthRollover()
		renderBoards()
		return { ok = true, monthKey = activeMonthKey, allTime = lastDisplayedAllTime, monthly = lastDisplayedMonthly }
	end
	return { ok = false, reason = "Unknown action" }
end
control.Parent = script

task.spawn(function()
	local waited = 0
	while not ensureBoardsBound() and waited < 10 do
		task.wait(0.25)
		waited += 0.25
	end
	if not offline then
		odsAllTimeCache = fetchOrderedTop(allTimeStore)
		odsMonthlyCache = fetchOrderedTop(monthlyStore)
	end
	renderBoards()

	local nextOdsPoll = os.clock() + REFRESH_INTERVAL_SEC
	while true do
		task.wait(2)
		checkMonthRollover()
		local nowClock = os.clock()
		if not offline then
			for uid in pairs(pendingFlush) do
				if not lastFlushAt[uid] or nowClock - lastFlushAt[uid] >= FLUSH_MIN_INTERVAL_SEC then
					task.spawn(flushPlayer, uid)
				end
			end
			if nowClock >= nextOdsPoll then
				odsAllTimeCache = fetchOrderedTop(allTimeStore)
				odsMonthlyCache = fetchOrderedTop(monthlyStore)
				dirtyRender = true
				nextOdsPoll = nowClock + REFRESH_INTERVAL_SEC
			end
		end
		if dirtyRender then
			renderBoards()
		end
	end
end)

game:BindToClose(function()
	if offline then
		return
	end
	for uid in pairs(pendingFlush) do
		flushPlayer(uid)
	end
end)

return Manager