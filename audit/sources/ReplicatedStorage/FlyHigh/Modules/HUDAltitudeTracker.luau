--!strict
-- Vertical right-side server altitude tracker for Fly High (Sky Adventure aesthetic).
-- Displays all flying crews in the server, transparent party display profiles,
-- Party Master crown (master_crest), Istana Awan crest (goal_marker), and dead greyscale state.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local modules = ReplicatedStorage:WaitForChild("FlyHigh"):WaitForChild("Modules")
local Config = require(modules:WaitForChild("FlyHighConfig"))
local AdventureCatalog = require(modules:WaitForChild("HUDAdventureCatalog"))
local DailyAndShopCatalog = require(modules:WaitForChild("DailyAndShopCatalog"))

local Tracker = {}

local MAX_ALT_KM = Config.MAX_ALTITUDE_KM or 10000
local GOLD = Color3.fromRGB(253, 224, 71)
local CYAN = Color3.fromRGB(56, 189, 248)
local NAVY = Color3.fromRGB(6, 19, 46)
local TRACK_BG = Color3.fromRGB(6, 16, 36)
local WHITE_RIM = Color3.fromRGB(226, 232, 240)
local CYAN_RIM = Color3.fromRGB(125, 211, 252)
local DEAD_BG = Color3.fromRGB(48, 56, 70)
local DEAD_RIM = Color3.fromRGB(100, 116, 139)
local DEAD_VEIL = Color3.fromRGB(51, 65, 85)
local DEAD_RED = Color3.fromRGB(239, 68, 68)
local TEXT_CREAM = Color3.fromRGB(254, 249, 231)

local avatarCache: { [number]: string } = {}
local avatarPending: { [number]: boolean } = {}
local avatarFailed: { [number]: boolean } = {}

type MemberSpec = {
	uid: number,
	master: boolean,
	dead: boolean,
	frame: string?,
}

type FlightRecord = {
	id: number,
	targetAltKm: number,
	displayAltKm: number,
	isLocal: boolean,
	members: { MemberSpec },
	ui: any?,
}

local flightsById: { [number]: FlightRecord } = {}
local rowHandles: { [Frame]: any } = setmetatable({}, { __mode = "k" }) :: any
local localAltitudeKm = 0
local localDisplayKm = 0
local hasServerSnapshot = false

local function formatKm(km: number): string
	local n = math.clamp(math.round(km), 0, MAX_ALT_KM)
	local raw = tostring(n)
	local formatted = raw:reverse():gsub("(%d%d%d)", "%1."):reverse():gsub("^%.", "")
	return formatted .. " km"
end

local function fetchAvatar(uid: number)
	if uid <= 0 or avatarCache[uid] or avatarPending[uid] or avatarFailed[uid] then
		return
	end
	avatarPending[uid] = true
	task.spawn(function()
		local ok, url, ready = pcall(function()
			return Players:GetUserThumbnailAsync(uid, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
		end)
		avatarPending[uid] = nil
		if ok and type(url) == "string" and url ~= "" and ready ~= false then
			avatarCache[uid] = url
		else
			-- Fallback rbxthumb URI works across live clients even if async thumbnail transiently delayed
			if uid > 0 then
				avatarCache[uid] = string.format("rbxthumb://type=AvatarHeadShot&id=%d&w=100&h=100", uid)
			else
				avatarFailed[uid] = true
			end
		end
	end)
end

local function makeRound(parent: GuiObject, radiusScale: number?, radiusOffset: number?): UICorner
	local existing = parent:FindFirstChildOfClass("UICorner")
	if existing then
		existing.CornerRadius = UDim.new(radiusScale or 0, radiusOffset or 0)
		return existing
	end
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(radiusScale or 0, radiusOffset or 0)
	c.Parent = parent
	return c
end

local function makeStroke(parent: GuiObject, color: Color3, thickness: number, transparency: number?): UIStroke
	local s = parent:FindFirstChild("HUDTrackerStroke") :: UIStroke?
	if not s then
		s = Instance.new("UIStroke")
		s.Name = "HUDTrackerStroke"
		s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		s.Parent = parent
	end
	s.Color = color
	s.Thickness = thickness
	s.Transparency = transparency or 0
	return s
end

local function applySprite(img: ImageLabel, key: string)
	local sprite = AdventureCatalog[key]
	if not sprite then
		img.Visible = false
		return
	end
	local assetId, x, y, w, h = table.unpack(sprite)
	if img.Image ~= assetId then
		img.Image = assetId
	end
	if x == 0 and y == 0 then
		img.ImageRectOffset = Vector2.zero
		img.ImageRectSize = Vector2.zero
	else
		img.ImageRectOffset = Vector2.new(x, y)
		img.ImageRectSize = Vector2.new(w, h)
	end
	img.ScaleType = Enum.ScaleType.Fit
	img.Visible = true
end

local function ensureChrome(container: Frame)
	if container:GetAttribute("TrackerBuilt") == true then
		return
	end
	container:SetAttribute("TrackerBuilt", true)
	container.BackgroundTransparency = 1
	container.BorderSizePixel = 0
	container.ClipsDescendants = false
	container.Active = false

	-- 1. Top "10.000 km" pill
	local topPill = Instance.new("Frame")
	topPill.Name = "TopGoalPill"
	topPill.BackgroundColor3 = NAVY
	topPill.BorderSizePixel = 0
	topPill.Active = false
	topPill.Parent = container
	makeRound(topPill, 0.5, 0)
	makeStroke(topPill, GOLD, 1.5, 0)

	local topLabel = Instance.new("TextLabel")
	topLabel.Name = "Label"
	topLabel.Size = UDim2.fromScale(1, 1)
	topLabel.BackgroundTransparency = 1
	topLabel.Font = Enum.Font.GothamBlack
	topLabel.Text = "10.000 km"
	topLabel.TextColor3 = TEXT_CREAM
	topLabel.TextSize = 11
	topLabel.Active = false
	topLabel.Parent = topPill

	-- 2. Outer cyan-gold vertical rail spine
	local railOuter = Instance.new("Frame")
	railOuter.Name = "RailOuter"
	railOuter.BackgroundColor3 = NAVY
	railOuter.BorderSizePixel = 0
	railOuter.Active = false
	railOuter.Parent = container
	makeRound(railOuter, 0.5, 0)
	makeStroke(railOuter, CYAN, 1.6, 0)

	local railGold = Instance.new("Frame")
	railGold.Name = "RailGoldRim"
	railGold.BackgroundColor3 = TRACK_BG
	railGold.BorderSizePixel = 0
	railGold.Active = false
	railGold.Position = UDim2.fromOffset(2, 2)
	railGold.Size = UDim2.new(1, -4, 1, -4)
	railGold.Parent = railOuter
	makeRound(railGold, 0.5, 0)
	makeStroke(railGold, Color3.fromRGB(234, 179, 8), 1.1, 0.08)

	local trackInner = Instance.new("Frame")
	trackInner.Name = "TrackInner"
	trackInner.BackgroundTransparency = 1
	trackInner.BorderSizePixel = 0
	trackInner.Active = false
	trackInner.ClipsDescendants = true
	trackInner.Parent = railOuter

	-- Fill bar anchored at bottom of TrackInner
	local trackFill = Instance.new("Frame")
	trackFill.Name = "TrackFill"
	trackFill.AnchorPoint = Vector2.new(0.5, 1)
	trackFill.Position = UDim2.fromScale(0.5, 1)
	trackFill.Size = UDim2.new(1, 0, 0, 0)
	trackFill.BackgroundColor3 = Color3.new(1, 1, 1)
	trackFill.BorderSizePixel = 0
	trackFill.Active = false
	trackFill.Parent = trackInner
	makeRound(trackFill, 0.5, 0)

	local grad = Instance.new("UIGradient")
	grad.Rotation = 90
	grad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(253, 224, 71)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(56, 189, 248)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(34, 197, 94)),
	})
	grad.Parent = trackFill

	-- Biome ticks at 2k, 4k, 6k, 8k
	local ticksFolder = Instance.new("Frame")
	ticksFolder.Name = "Ticks"
	ticksFolder.Size = UDim2.fromScale(1, 1)
	ticksFolder.BackgroundTransparency = 1
	ticksFolder.Active = false
	ticksFolder.Parent = trackInner

	for _, km in { 2000, 4000, 6000, 8000 } do
		local yScale = 1 - (km / MAX_ALT_KM)
		local tickRow = Instance.new("Frame")
		tickRow.Name = "Tick_" .. tostring(km)
		tickRow.AnchorPoint = Vector2.new(0.5, 0.5)
		tickRow.Position = UDim2.fromScale(0.5, yScale)
		tickRow.Size = UDim2.new(1, 0, 0, 14)
		tickRow.BackgroundTransparency = 1
		tickRow.Active = false
		tickRow.Parent = ticksFolder

		local line = Instance.new("Frame")
		line.Name = "Line"
		line.AnchorPoint = Vector2.new(0.5, 0.5)
		line.Position = UDim2.fromScale(0.5, 0.5)
		line.Size = UDim2.new(0.75, 0, 0, 1)
		line.BackgroundColor3 = Color3.fromRGB(148, 163, 184)
		line.BackgroundTransparency = 0.62
		line.BorderSizePixel = 0
		line.Active = false
		line.Parent = tickRow

		local lbl = Instance.new("TextLabel")
		lbl.Name = "KmText"
		lbl.Size = UDim2.fromScale(1, 1)
		lbl.BackgroundTransparency = 1
		lbl.Font = Enum.Font.GothamBold
		lbl.Text = string.format("%dk", km / 1000)
		lbl.TextSize = 8
		lbl.TextColor3 = Color3.fromRGB(191, 219, 254)
		lbl.TextTransparency = 0.25
		lbl.TextStrokeColor3 = TRACK_BG
		lbl.TextStrokeTransparency = 0.2
		lbl.Active = false
		lbl.Parent = tickRow
	end

	-- 3. Istana Awan summit medallion at top of rail
	local crest = Instance.new("Frame")
	crest.Name = "PalaceCrest"
	crest.AnchorPoint = Vector2.new(0.5, 0.5)
	crest.BackgroundColor3 = NAVY
	crest.BorderSizePixel = 0
	crest.Active = false
	crest.Parent = container
	makeRound(crest, 0.5, 0)
	makeStroke(crest, GOLD, 2, 0)

	local crestImg = Instance.new("ImageLabel")
	crestImg.Name = "CrestIcon"
	crestImg.AnchorPoint = Vector2.new(0.5, 0.5)
	crestImg.Position = UDim2.fromScale(0.5, 0.5)
	crestImg.Size = UDim2.fromScale(0.78, 0.78)
	crestImg.BackgroundTransparency = 1
	crestImg.Active = false
	crestImg.Parent = crest
	applySprite(crestImg, "goal_marker")

	-- 4. Bottom local player altitude pill
	local botPill = Instance.new("Frame")
	botPill.Name = "BottomLocalPill"
	botPill.BackgroundColor3 = NAVY
	botPill.BorderSizePixel = 0
	botPill.Active = false
	botPill.Parent = container
	makeRound(botPill, 0.5, 0)
	makeStroke(botPill, GOLD, 1.5, 0)

	local botLabel = Instance.new("TextLabel")
	botLabel.Name = "Label"
	botLabel.Size = UDim2.fromScale(1, 1)
	botLabel.BackgroundTransparency = 1
	botLabel.Font = Enum.Font.GothamBlack
	botLabel.Text = "0 km"
	botLabel.TextColor3 = TEXT_CREAM
	botLabel.TextSize = 11
	botLabel.Active = false
	botLabel.Parent = botPill

	-- 5. Dynamic markers layer
	local markers = Instance.new("Frame")
	markers.Name = "MarkersLayer"
	markers.Size = UDim2.fromScale(1, 1)
	markers.BackgroundTransparency = 1
	markers.BorderSizePixel = 0
	markers.ClipsDescendants = false
	markers.Active = false
	markers.Parent = container
end

local function buildPortraitSlot(parent: Frame, idx: number, baseZ: number)
	local slot = Instance.new("Frame")
	slot.Name = "MemberSlot" .. tostring(idx)
	slot.BackgroundTransparency = 1
	slot.BorderSizePixel = 0
	slot.ClipsDescendants = false
	slot.Active = false
	slot.ZIndex = baseZ
	slot.Parent = parent

	local auraHalo = Instance.new("Frame")
	auraHalo.Name = "CosmeticAuraHalo"
	auraHalo.AnchorPoint = Vector2.new(0.5, 0.5)
	auraHalo.Position = UDim2.fromScale(0.5, 0.5)
	auraHalo.Size = UDim2.new(1, 8, 1, 8)
	auraHalo.BackgroundColor3 = GOLD
	auraHalo.BackgroundTransparency = 0.62
	auraHalo.BorderSizePixel = 0
	auraHalo.Active = false
	auraHalo.Visible = false
	auraHalo.ZIndex = baseZ
	auraHalo.Parent = slot
	makeRound(auraHalo, 0.5, 0)
	local auraStroke = makeStroke(auraHalo, GOLD, 2, 0.15)

	local circle = Instance.new("Frame")
	circle.Name = "Ring"
	circle.Size = UDim2.fromScale(1, 1)
	circle.BackgroundColor3 = Color3.fromRGB(30, 64, 115)
	circle.BorderSizePixel = 0
	circle.ClipsDescendants = true
	circle.Active = false
	circle.ZIndex = baseZ + 1
	circle.Parent = slot
	makeRound(circle, 0.5, 0)
	local ringStroke = makeStroke(circle, WHITE_RIM, 2, 0)

	local img = Instance.new("ImageLabel")
	img.Name = "Avatar"
	img.Size = UDim2.fromScale(1, 1)
	img.BackgroundTransparency = 1
	img.ScaleType = Enum.ScaleType.Fit
	img.Active = false
	img.ZIndex = baseZ + 2
	img.Parent = circle
	makeRound(img, 0.5, 0)

	local fallback = Instance.new("TextLabel")
	fallback.Name = "FallbackGlyph"
	fallback.Size = UDim2.fromScale(1, 1)
	fallback.BackgroundTransparency = 1
	fallback.Font = Enum.Font.GothamBlack
	fallback.Text = "P" .. tostring(idx)
	fallback.TextColor3 = Color3.fromRGB(224, 242, 254)
	fallback.TextSize = 11
	fallback.ZIndex = baseZ + 2
	fallback.Visible = false
	fallback.Parent = circle

	-- Desaturating greyscale slate veil for dead players
	local veil = Instance.new("Frame")
	veil.Name = "DeadVeil"
	veil.Size = UDim2.fromScale(1, 1)
	veil.BackgroundColor3 = DEAD_VEIL
	veil.BackgroundTransparency = 0.55
	veil.BorderSizePixel = 0
	veil.Active = false
	veil.Visible = false
	veil.ZIndex = baseZ + 3
	veil.Parent = circle
	makeRound(veil, 0.5, 0)

	-- Dead corner X badge (outside clipped circle)
	local badge = Instance.new("Frame")
	badge.Name = "DeadBadge"
	badge.AnchorPoint = Vector2.new(1, 1)
	badge.Position = UDim2.new(1, 2, 1, 2)
	badge.Size = UDim2.fromOffset(12, 12)
	badge.BackgroundColor3 = Color3.fromRGB(15, 23, 42)
	badge.BorderSizePixel = 0
	badge.Visible = false
	badge.ZIndex = baseZ + 5
	badge.Parent = slot
	makeRound(badge, 0.5, 0)
	makeStroke(badge, DEAD_RED, 1.4, 0)

	local badgeX = Instance.new("TextLabel")
	badgeX.Name = "X"
	badgeX.Size = UDim2.fromScale(1, 1)
	badgeX.BackgroundTransparency = 1
	badgeX.Font = Enum.Font.GothamBlack
	badgeX.Text = "X"
	badgeX.TextColor3 = Color3.fromRGB(248, 113, 113)
	badgeX.TextSize = 9
	badgeX.ZIndex = baseZ + 6
	badgeX.Parent = badge

	-- Party Master crown above portrait ring
	local crown = Instance.new("ImageLabel")
	crown.Name = "MasterCrown"
	crown.AnchorPoint = Vector2.new(0.5, 1)
	crown.Position = UDim2.new(0.5, 0, 0, 2)
	crown.Size = UDim2.fromOffset(18, 13)
	crown.BackgroundTransparency = 1
	crown.Active = false
	crown.Visible = false
	crown.ZIndex = baseZ + 6
	crown.Parent = slot
	applySprite(crown, "master_crest")

	return {
		slot = slot,
		auraHalo = auraHalo,
		auraStroke = auraStroke,
		circle = circle,
		stroke = ringStroke,
		img = img,
		fallback = fallback,
		veil = veil,
		badge = badge,
		crown = crown,
	}
end

local function ensureFlightUI(markersLayer: Frame, flightId: number, baseZ: number)
	local row = markersLayer:FindFirstChild("FlightRow_" .. tostring(flightId)) :: Frame?
	if row and rowHandles[row] then
		return rowHandles[row]
	elseif row then
		row:Destroy()
	end

	row = Instance.new("Frame")
	row.Name = "FlightRow_" .. tostring(flightId)
	row.Size = UDim2.fromScale(1, 1)
	row.BackgroundTransparency = 1
	row.BorderSizePixel = 0
	row.ClipsDescendants = false
	row.Active = false
	row.Parent = markersLayer

	local dot = Instance.new("Frame")
	dot.Name = "RailDot"
	dot.AnchorPoint = Vector2.new(0.5, 0.5)
	dot.BorderSizePixel = 0
	dot.Active = false
	dot.Parent = row
	makeRound(dot, 0.5, 0)
	local dotStroke = makeStroke(dot, NAVY, 1.6, 0)

	local stemMain = Instance.new("Frame")
	stemMain.Name = "StemMain"
	stemMain.AnchorPoint = Vector2.new(0, 0.5)
	stemMain.BorderSizePixel = 0
	stemMain.Active = false
	stemMain.Parent = row
	makeRound(stemMain, 0.5, 0)
	local stemStroke1 = makeStroke(stemMain, NAVY, 0.8, 0.4)

	local stemV = Instance.new("Frame")
	stemV.Name = "StemElbow"
	stemV.AnchorPoint = Vector2.new(0.5, 0)
	stemV.BorderSizePixel = 0
	stemV.Active = false
	stemV.Visible = false
	stemV.Parent = row
	makeRound(stemV, 0.5, 0)
	local stemStrokeV = makeStroke(stemV, NAVY, 0.8, 0.4)

	local stemHead = Instance.new("Frame")
	stemHead.Name = "StemHead"
	stemHead.AnchorPoint = Vector2.new(0, 0.5)
	stemHead.BorderSizePixel = 0
	stemHead.Active = false
	stemHead.Visible = false
	stemHead.Parent = row
	makeRound(stemHead, 0.5, 0)
	local stemStrokeH = makeStroke(stemHead, NAVY, 0.8, 0.4)

	local arrowTip = Instance.new("Frame")
	arrowTip.Name = "ArrowTip"
	arrowTip.AnchorPoint = Vector2.new(0.5, 0.5)
	arrowTip.Size = UDim2.fromOffset(7, 7)
	arrowTip.Rotation = 45
	arrowTip.BorderSizePixel = 0
	arrowTip.Active = false
	arrowTip.Parent = row
	makeStroke(arrowTip, NAVY, 1.2, 0.1)

	local portraits = Instance.new("Frame")
	portraits.Name = "Portraits"
	portraits.AnchorPoint = Vector2.new(1, 0.5)
	portraits.BackgroundTransparency = 1
	portraits.BorderSizePixel = 0
	portraits.ClipsDescendants = false
	portraits.Active = false
	portraits.Parent = row

	local slots = {}
	for i = 1, 3 do
		slots[i] = buildPortraitSlot(portraits, i, baseZ + 2)
	end

	local handles = {
		row = row,
		dot = dot,
		dotStroke = dotStroke,
		stemMain = stemMain,
		stemV = stemV,
		stemHead = stemHead,
		stemStrokes = { stemStroke1, stemStrokeV, stemStrokeH },
		arrowTip = arrowTip,
		portraits = portraits,
		slots = slots,
	}
	rowHandles[row] = handles
	return handles
end

local function normalizeMembers(raw: any): { MemberSpec }
	local out: { MemberSpec } = {}
	if type(raw) ~= "table" then
		return out
	end
	for _, m in ipairs(raw) do
		if type(m) == "table" and type(m.uid) == "number" then
			table.insert(out, {
				uid = m.uid,
				master = m.master == true,
				dead = m.dead == true,
				frame = type(m.frame) == "string" and m.frame ~= "" and m.frame or nil,
			})
			fetchAvatar(m.uid)
		end
	end
	table.sort(out, function(a, b)
		if a.master ~= b.master then
			return a.master
		end
		return a.uid < b.uid
	end)
	return out
end

function Tracker.SetServerFlights(snapshot: any)
	hasServerSnapshot = true
	local seen: { [number]: boolean } = {}
	local localUid = Players.LocalPlayer and Players.LocalPlayer.UserId or 0

	if type(snapshot) == "table" then
		for _, item in ipairs(snapshot) do
			if type(item) == "table" and type(item.id) == "number" then
				local id = item.id
				seen[id] = true
				local members = normalizeMembers(item.members)
				if #members > 0 then
					local isLocal = false
					for _, m in ipairs(members) do
						if m.uid == localUid then
							isLocal = true
							break
						end
					end
					local existing = flightsById[id]
					local alt = math.clamp(tonumber(item.alt) or 0, 0, MAX_ALT_KM)
					if isLocal and localAltitudeKm > 0 and math.abs(localAltitudeKm - alt) < 80 then
						alt = localAltitudeKm
					end
					if existing then
						existing.targetAltKm = alt
						existing.isLocal = isLocal
						existing.members = members
					else
						flightsById[id] = {
							id = id,
							targetAltKm = alt,
							displayAltKm = alt,
							isLocal = isLocal,
							members = members,
						}
					end
				end
			end
		end
	end

	for id in pairs(flightsById) do
		if not seen[id] then
			flightsById[id] = nil
		end
	end
end

function Tracker.SetLocalAltitude(altKm: number)
	local clamped = math.clamp(tonumber(altKm) or 0, 0, MAX_ALT_KM)
	localAltitudeKm = clamped
	for _, rec in pairs(flightsById) do
		if rec.isLocal then
			rec.targetAltKm = clamped
		end
	end
end

function Tracker.Reset()
	hasServerSnapshot = false
	localAltitudeKm = 0
	localDisplayKm = 0
	table.clear(flightsById)
end

function Tracker.Step(container: Frame, dt: number, compact: boolean, textBoost: number)
	ensureChrome(container)

	local w = math.max(1, container.AbsoluteSize.X)
	local h = math.max(1, container.AbsoluteSize.Y)
	local z = container.ZIndex

	local topPillH = h >= 220 and 20 or (h >= 150 and 16 or 14)
	local botPillH = h >= 220 and 22 or (h >= 150 and 18 or 16)
	local crestD = (not compact and h >= 280) and 42 or (h >= 200 and 34 or (h >= 140 and 28 or 22))
	local topPillW = math.clamp(compact and 66 or 76, 56, 84) + textBoost * 2
	local botPillW = math.clamp(compact and 72 or 84, 62, 92) + textBoost * 2
	local railOuterW = compact and 18 or 22

	local railCenterX = w - math.max(crestD, botPillW, topPillW) / 2
	local railLeftX = railCenterX - railOuterW / 2
	local avatarSize = container:GetAttribute("AvatarSize") or (compact and 22 or (h >= 260 and 30 or 26))
	local avatarGap = container:GetAttribute("AvatarGap") or (compact and 3 or 5)
	local crownH = container:GetAttribute("CrownHeight") or math.round(avatarSize * 0.46)
	local crownW = math.round(crownH * (128 / 97))
	local stemW = container:GetAttribute("StemWidth") or (compact and 10 or 14)

	local railTopY = topPillH + 4 + math.round(crestD * 0.55)
	local railBottomY = h - botPillH - 3
	local railH = math.max(20, railBottomY - railTopY)
	local trackTopPad = math.round(crestD * 0.45) + (h >= 140 and 5 or 3)
	local trackBottomPad = h >= 140 and 7 or 4
	local trackSpanH = math.max(12, railH - trackTopPad - trackBottomPad)
	local trackTopAbsY = railTopY + trackTopPad
	local trackBottomAbsY = trackTopAbsY + trackSpanH

	local topPill = container:FindFirstChild("TopGoalPill") :: Frame?
	local railOuter = container:FindFirstChild("RailOuter") :: Frame?
	local crest = container:FindFirstChild("PalaceCrest") :: Frame?
	local botPill = container:FindFirstChild("BottomLocalPill") :: Frame?
	local markersLayer = container:FindFirstChild("MarkersLayer") :: Frame?

	if topPill then
		topPill.Position = UDim2.fromOffset(math.round(railCenterX - topPillW / 2), 0)
		topPill.Size = UDim2.fromOffset(topPillW, topPillH)
		topPill.ZIndex = z + 3
		local lbl = topPill:FindFirstChild("Label") :: TextLabel?
		if lbl then
			lbl.ZIndex = z + 4
			lbl.TextSize = topPillH >= 19 and 11 or 9
		end
	end

	if railOuter then
		railOuter.Position = UDim2.fromOffset(math.round(railLeftX), railTopY)
		railOuter.Size = UDim2.fromOffset(railOuterW, railH)
		railOuter.ZIndex = z + 1
		local goldRim = railOuter:FindFirstChild("RailGoldRim") :: Frame?
		if goldRim then goldRim.ZIndex = z + 2 end
		local trackInner = railOuter:FindFirstChild("TrackInner") :: Frame?
		if trackInner then
			trackInner.Position = UDim2.fromOffset(4, trackTopPad)
			trackInner.Size = UDim2.fromOffset(railOuterW - 8, trackSpanH)
			trackInner.ZIndex = z + 3
			local fill = trackInner:FindFirstChild("TrackFill") :: Frame?
			local showFillKm = localAltitudeKm
			for _, rec in pairs(flightsById) do
				if rec.isLocal then
					showFillKm = rec.displayAltKm
					break
				end
			end
			local rate = 1 - math.exp(-dt * 10)
			localDisplayKm = hasServerSnapshot and showFillKm or (localDisplayKm + (localAltitudeKm - localDisplayKm) * rate)
			if fill then
				fill.Size = UDim2.fromScale(1, math.clamp(localDisplayKm / MAX_ALT_KM, 0, 1))
				fill.ZIndex = z + 4
			end
			local ticks = trackInner:FindFirstChild("Ticks") :: Frame?
			if ticks then
				ticks.ZIndex = z + 5
				local showTickLabels = trackSpanH >= 110
				for _, child in ipairs(ticks:GetChildren()) do
					local kmLbl = child:FindFirstChild("KmText") :: TextLabel?
					if kmLbl then
						kmLbl.Visible = showTickLabels
						kmLbl.ZIndex = z + 5
					end
				end
			end
		end
	end

	if crest then
		crest.Position = UDim2.fromOffset(math.round(railCenterX), topPillH + 4 + math.round(crestD / 2))
		crest.Size = UDim2.fromOffset(crestD, crestD)
		crest.ZIndex = z + 5
		local img = crest:FindFirstChild("CrestIcon") :: ImageLabel?
		if img then img.ZIndex = z + 6 end
	end

	if botPill then
		botPill.Position = UDim2.fromOffset(math.round(railCenterX - botPillW / 2), h - botPillH)
		botPill.Size = UDim2.fromOffset(botPillW, botPillH)
		botPill.ZIndex = z + 4
		local lbl = botPill:FindFirstChild("Label") :: TextLabel?
		if lbl then
			lbl.ZIndex = z + 5
			lbl.TextSize = botPillH >= 20 and 12 or 10
			lbl.Text = formatKm(localAltitudeKm)
		end
	end

	if not markersLayer then
		return
	end
	markersLayer.ZIndex = z + 6

	-- If no server snapshot arrived yet during solo startup, synthesize a clean fallback entry for local player
	local displayRecords: { FlightRecord } = {}
	local hasAnyFlight = false
	for _, rec in pairs(flightsById) do
		hasAnyFlight = true
		local stepRate = 1 - math.exp(-dt * 10)
		rec.displayAltKm += (rec.targetAltKm - rec.displayAltKm) * stepRate
		table.insert(displayRecords, rec)
	end

	if not hasAnyFlight and Players.LocalPlayer and Players.LocalPlayer:GetAttribute("InFlight") == true and not hasServerSnapshot then
		local p = Players.LocalPlayer
		fetchAvatar(p.UserId)
		table.insert(displayRecords, {
			id = 0,
			targetAltKm = localAltitudeKm,
			displayAltKm = localAltitudeKm,
			isLocal = true,
			members = {
				{
					uid = p.UserId,
					master = p:GetAttribute("IsMaster") ~= false,
					dead = p:GetAttribute("FlightGhost") == true,
					frame = type(p:GetAttribute("EquippedFrame")) == "string" and p:GetAttribute("EquippedFrame") ~= "" and (p:GetAttribute("EquippedFrame") :: string) or nil,
				},
			},
		})
	end

	-- Sort top-to-bottom on rail (highest altitude first -> smallest Y first)
	table.sort(displayRecords, function(a, b)
		if math.abs(a.displayAltKm - b.displayAltKm) > 0.05 then
			return a.displayAltKm > b.displayAltKm
		end
		return a.id < b.id
	end)

	-- Clean up rows for ended flights
	local keepRowNames: { [string]: boolean } = {}
	for _, rec in ipairs(displayRecords) do
		keepRowNames["FlightRow_" .. tostring(rec.id)] = true
	end
	for _, child in ipairs(markersLayer:GetChildren()) do
		if child:IsA("GuiObject") and not keepRowNames[child.Name] then
			rowHandles[child :: Frame] = nil
			child:Destroy()
		end
	end

	-- Compute exact dotY + anti-overlap portraitY stagger
	local portraitHalfTop = math.ceil(avatarSize / 2 + crownH + 2)
	local portraitHalfBot = math.ceil(avatarSize / 2 + 4)
	local minPortraitY = math.max(portraitHalfTop, trackTopAbsY)
	local maxPortraitY = math.max(minPortraitY, math.min(h - botPillH - portraitHalfBot, trackBottomAbsY))
	local baseRowSpacing = avatarSize + crownH + 4
	local minRowSpacing = #displayRecords > 1
		and math.min(baseRowSpacing, math.max(10, math.floor((maxPortraitY - minPortraitY) / (#displayRecords - 1))))
		or baseRowSpacing

	local rowYs: { { rec: FlightRecord, dotY: number, portraitY: number } } = {}
	for _, rec in ipairs(displayRecords) do
		local frac = math.clamp(rec.displayAltKm / MAX_ALT_KM, 0, 1)
		local dotY = trackBottomAbsY - frac * trackSpanH
		table.insert(rowYs, {
			rec = rec,
			dotY = dotY,
			portraitY = math.clamp(dotY, minPortraitY, maxPortraitY),
		})
	end

	-- Push overlapping portrait rows downward first, then clamp/push upward if crowded at bottom
	for i = 2, #rowYs do
		local prevY = rowYs[i - 1].portraitY
		if rowYs[i].portraitY < prevY + minRowSpacing then
			rowYs[i].portraitY = prevY + minRowSpacing
		end
	end
	if #rowYs > 0 and rowYs[#rowYs].portraitY > maxPortraitY then
		rowYs[#rowYs].portraitY = maxPortraitY
		for i = #rowYs - 1, 1, -1 do
			if rowYs[i].portraitY > rowYs[i + 1].portraitY - minRowSpacing then
				rowYs[i].portraitY = math.max(minPortraitY, rowYs[i + 1].portraitY - minRowSpacing)
			end
		end
	end

	-- Render each active flight
	local badgeSize = math.clamp(math.round(avatarSize * 0.44), 10, 14)
	for _, entry in ipairs(rowYs) do
		local rec = entry.rec
		local rowBaseZ = z + (rec.isLocal and 14 or 7)
		local handles = ensureFlightUI(markersLayer, rec.id, rowBaseZ)
		local accent = rec.isLocal and GOLD or CYAN
		local dotSize = rec.isLocal and (compact and 10 or 12) or (compact and 8 or 9)
		local dotY = math.round(entry.dotY)
		local pY = math.round(entry.portraitY)
		local arrowGapRight = 3
		local stemLeft = railLeftX - stemW
		local portraitsRight = stemLeft - arrowGapRight

		handles.row.ZIndex = rowBaseZ
		handles.dot.Size = UDim2.fromOffset(dotSize, dotSize)
		handles.dot.Position = UDim2.fromOffset(math.round(railCenterX), dotY)
		handles.dot.BackgroundColor3 = accent
		handles.dot.ZIndex = rowBaseZ + 2
		handles.dotStroke.Color = rec.isLocal and Color3.fromRGB(255, 255, 255) or NAVY

		-- Stem & pointer triangle
		local dy = pY - dotY
		if math.abs(dy) <= 2 then
			local mainLeft = portraitsRight + 1
			local mainRight = math.round(railCenterX - dotSize / 2)
			local mainW = math.max(4, mainRight - mainLeft)
			handles.stemMain.Position = UDim2.fromOffset(mainLeft, dotY)
			handles.stemMain.Size = UDim2.fromOffset(mainW, 2)
			handles.stemMain.BackgroundColor3 = accent
			handles.stemMain.ZIndex = rowBaseZ + 1
			handles.stemV.Visible = false
			handles.stemHead.Visible = false
		else
			local elbowX = math.round(railLeftX - math.max(4, math.round(stemW * 0.35)))
			local dotRight = math.round(railCenterX - dotSize / 2)
			handles.stemMain.Position = UDim2.fromOffset(elbowX, dotY)
			handles.stemMain.Size = UDim2.fromOffset(math.max(2, dotRight - elbowX), 2)
			handles.stemMain.BackgroundColor3 = accent
			handles.stemMain.ZIndex = rowBaseZ + 1

			handles.stemV.Position = UDim2.fromOffset(elbowX, math.min(dotY, pY))
			handles.stemV.Size = UDim2.fromOffset(2, math.max(2, math.abs(dy)))
			handles.stemV.BackgroundColor3 = accent
			handles.stemV.Visible = true
			handles.stemV.ZIndex = rowBaseZ + 1

			local headLeft = portraitsRight + 1
			handles.stemHead.Position = UDim2.fromOffset(headLeft, pY)
			handles.stemHead.Size = UDim2.fromOffset(math.max(2, elbowX - headLeft), 2)
			handles.stemHead.BackgroundColor3 = accent
			handles.stemHead.Visible = true
			handles.stemHead.ZIndex = rowBaseZ + 1
		end

		handles.arrowTip.Position = UDim2.fromOffset(math.round(portraitsRight + 2), pY)
		handles.arrowTip.Size = UDim2.fromOffset(compact and 6 or 7, compact and 6 or 7)
		handles.arrowTip.BackgroundColor3 = accent
		handles.arrowTip.ZIndex = rowBaseZ + 3

		-- Transparent horizontally aligned party portraits (max 3)
		local count = math.min(#rec.members, 3)
		local groupW = count * avatarSize + math.max(0, count - 1) * avatarGap
		handles.portraits.Position = UDim2.fromOffset(math.round(portraitsRight - arrowGapRight), pY)
		handles.portraits.Size = UDim2.fromOffset(groupW, avatarSize)
		handles.portraits.ZIndex = rowBaseZ + 2

		for i = 1, 3 do
			local s = handles.slots[i]
			local m = rec.members[i]
			if not m then
				s.slot.Visible = false
			else
				s.slot.Visible = true
				local sx = (i - 1) * (avatarSize + avatarGap)
				s.slot.Position = UDim2.fromOffset(sx, 0)
				s.slot.Size = UDim2.fromOffset(avatarSize, avatarSize)
				s.slot.ZIndex = rowBaseZ + 3

				local isDead = m.dead == true
				local frameDef = if not isDead and type(m.frame) == "string" and m.frame ~= ""
					then DailyAndShopCatalog.GetCosmetic("frame", m.frame)
					else nil
				if frameDef then
					s.auraHalo.Visible = true
					s.auraHalo.BackgroundColor3 = frameDef.primaryColor
					s.auraHalo.ZIndex = rowBaseZ + 2
					s.auraStroke.Color = frameDef.secondaryColor
				else
					s.auraHalo.Visible = false
				end
				s.circle.BackgroundColor3 = isDead and DEAD_BG or (rec.isLocal and Color3.fromRGB(30, 80, 150) or Color3.fromRGB(24, 58, 110))
				s.circle.ZIndex = rowBaseZ + 3
				s.stroke.Color = if isDead then DEAD_RIM elseif frameDef then frameDef.primaryColor elseif m.master then GOLD elseif rec.isLocal then WHITE_RIM else CYAN_RIM
				s.stroke.Thickness = if not isDead and frameDef then 2.4 elseif (not isDead and m.master and rec.isLocal) then 2.3 else 1.9

				local cachedUrl = avatarCache[m.uid]
				s.img.ZIndex = rowBaseZ + 4
				s.fallback.ZIndex = rowBaseZ + 4
				s.veil.ZIndex = rowBaseZ + 5
				if cachedUrl then
					if s.img.Image ~= cachedUrl then
						s.img.Image = cachedUrl
					end
					s.img.Visible = true
					s.fallback.Visible = false
				else
					s.img.Visible = false
					s.fallback.Visible = true
					s.fallback.TextSize = math.max(8, math.round(avatarSize * 0.42))
					s.fallback.TextColor3 = isDead and Color3.fromRGB(160, 174, 192) or Color3.fromRGB(224, 242, 254)
				end

				-- Greyscale effect for dead players
				if isDead then
					s.img.ImageColor3 = Color3.fromRGB(130, 140, 155)
					s.img.ImageTransparency = 0.50
					s.veil.Visible = true
					s.badge.Visible = true
					s.badge.Size = UDim2.fromOffset(badgeSize, badgeSize)
					s.badge.ZIndex = rowBaseZ + 7
					local xLbl = s.badge:FindFirstChild("X") :: TextLabel?
					if xLbl then
						xLbl.ZIndex = rowBaseZ + 8
						xLbl.TextSize = badgeSize <= 11 and 7 or 9
					end
				else
					s.img.ImageColor3 = Color3.new(1, 1, 1)
					s.img.ImageTransparency = 0
					s.veil.Visible = false
					s.badge.Visible = false
				end

				-- Party Master Crown (preserved in muted silver tone even if dead)
				if m.master then
					s.crown.Visible = true
					s.crown.Size = UDim2.fromOffset(crownW, crownH)
					s.crown.ImageColor3 = isDead and Color3.fromRGB(170, 180, 195) or Color3.new(1, 1, 1)
					s.crown.ImageTransparency = isDead and 0.15 or 0
					s.crown.ZIndex = rowBaseZ + 8
				else
					s.crown.Visible = false
				end
			end
		end
	end
end

return Tracker
