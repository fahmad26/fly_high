local Renderer = {}

Renderer.SUMMIT_WEIGHT = 100000
Renderer.MAX_ALTITUDE_KM = 10000
Renderer.MAX_ROWS = 10

local FONT_BOLD = Font.new("rbxasset://fonts/families/FredokaOne.json", Enum.FontWeight.Bold)
local FONT_BODY = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium)
local FONT_BLACK = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold)

local PALETTE = {
	navyDeep = Color3.fromRGB(7, 19, 48),
	navyTop = Color3.fromRGB(16, 42, 94),
	cardBg = Color3.fromRGB(13, 32, 74),
	cardTop1 = Color3.fromRGB(48, 36, 12),
	cardTop2 = Color3.fromRGB(28, 42, 68),
	cardTop3 = Color3.fromRGB(48, 28, 16),
	rowBorder = Color3.fromRGB(46, 82, 148),
	textMain = Color3.fromRGB(248, 250, 252),
	textMuted = Color3.fromRGB(167, 193, 232),
	gold = Color3.fromRGB(250, 204, 21),
	goldBg = Color3.fromRGB(69, 43, 6),
	goldInk = Color3.fromRGB(40, 24, 2),
	silver = Color3.fromRGB(226, 232, 240),
	silverInk = Color3.fromRGB(22, 30, 46),
	bronze = Color3.fromRGB(251, 146, 60),
	bronzeInk = Color3.fromRGB(48, 18, 4),
	cyan = Color3.fromRGB(56, 189, 248),
	cyanBg = Color3.fromRGB(12, 46, 82),
	cyanText = Color3.fromRGB(125, 211, 252),
	slateBadge = Color3.fromRGB(30, 58, 110),
}

function Renderer.FormatKm(value: number): string
	local n = math.max(0, math.floor(tonumber(value) or 0))
	local str = tostring(n)
	while true do
		local nextStr, count = string.gsub(str, "^(%d+)(%d%d%d)", "%1.%2")
		str = nextStr
		if count == 0 then
			break
		end
	end
	return str
end

function Renderer.EncodeScore(summits: number?, maxAltKm: number?): number
	local s = math.max(0, math.floor(tonumber(summits) or 0))
	local a = math.clamp(math.floor(tonumber(maxAltKm) or 0), 0, Renderer.MAX_ALTITUDE_KM)
	return s * Renderer.SUMMIT_WEIGHT + a
end

function Renderer.DecodeScore(score: number?): (number, number)
	local v = math.max(0, math.floor(tonumber(score) or 0))
	local summits = math.floor(v / Renderer.SUMMIT_WEIGHT)
	local alt = math.min(Renderer.MAX_ALTITUDE_KM, v % Renderer.SUMMIT_WEIGHT)
	return summits, alt
end

function Renderer.SortEntries(rawEntries: { any }, limit: number?)
	local cap = math.max(1, math.floor(tonumber(limit) or Renderer.MAX_ROWS))
	local normalized = {}
	for _, entry in ipairs(rawEntries or {}) do
		local summits = tonumber(entry.summits)
		local maxAlt = tonumber(entry.maxAlt)
		local score = tonumber(entry.score)
		if score ~= nil and (summits == nil or maxAlt == nil) then
			local ds, da = Renderer.DecodeScore(score)
			summits = summits or ds
			maxAlt = maxAlt or da
		end
		summits = math.max(0, math.floor(summits or 0))
		maxAlt = math.clamp(math.floor(maxAlt or 0), 0, Renderer.MAX_ALTITUDE_KM)
		if summits > 0 then
			maxAlt = Renderer.MAX_ALTITUDE_KM
		end
		score = Renderer.EncodeScore(summits, maxAlt)
		if score > 0 then
			local uid = math.floor(tonumber(entry.userId) or 0)
			local name = tostring(entry.name or "")
			if name == "" then
				name = uid > 0 and ("Pendaki #" .. tostring(uid)) or "Pendaki"
			end
			table.insert(normalized, {
				userId = uid,
				name = name,
				summits = summits,
				maxAlt = maxAlt,
				score = score,
			})
		end
	end
	table.sort(normalized, function(a, b)
		if a.score ~= b.score then
			return a.score > b.score
		end
		if a.summits ~= b.summits then
			return a.summits > b.summits
		end
		if a.maxAlt ~= b.maxAlt then
			return a.maxAlt > b.maxAlt
		end
		return a.userId < b.userId
	end)
	local out = {}
	for i = 1, math.min(cap, #normalized) do
		out[i] = normalized[i]
	end
	return out
end

local function makeCorner(parent: Instance, px: number)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, px)
	corner.Parent = parent
	return corner
end

local function makeStroke(parent: Instance, color: Color3, thickness: number, transparency: number?)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color
	stroke.Thickness = thickness
	stroke.Transparency = transparency or 0
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = parent
	return stroke
end

function Renderer.BuildBoardGui(
	adornPart: BasePart,
	options: { title: string, subtitle: string, footer: string, accent: Color3, badgeText: string }
): SurfaceGui
	for _, child in ipairs(adornPart:GetChildren()) do
		if child:IsA("SurfaceGui") then
			child:Destroy()
		end
	end

	local gui = Instance.new("SurfaceGui")
	gui.Name = "LeaderboardSurfaceGui"
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.FixedSize
	gui.CanvasSize = Vector2.new(680, 740)
	gui.LightInfluence = 0.08
	gui.Brightness = 1.15
	gui.ClipsDescendants = true
	gui.AlwaysOnTop = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = adornPart

	local root = Instance.new("Frame")
	root.Name = "Panel"
	root.Size = UDim2.fromScale(1, 1)
	root.BackgroundColor3 = PALETTE.navyDeep
	root.BorderSizePixel = 0
	root.Parent = gui
	makeCorner(root, 18)
	makeStroke(root, options.accent, 6, 0)

	local grad = Instance.new("UIGradient")
	grad.Color = ColorSequence.new(PALETTE.navyTop, PALETTE.navyDeep)
	grad.Rotation = 90
	grad.Parent = root

	local header = Instance.new("Frame")
	header.Name = "Header"
	header.Position = UDim2.fromOffset(18, 16)
	header.Size = UDim2.new(1, -36, 0, 92)
	header.BackgroundColor3 = Color3.fromRGB(10, 26, 62)
	header.BorderSizePixel = 0
	header.Parent = root
	makeCorner(header, 14)
	makeStroke(header, options.accent, 2.5, 0.35)

	local badge = Instance.new("Frame")
	badge.Name = "CrestBadge"
	badge.Position = UDim2.fromOffset(14, 14)
	badge.Size = UDim2.fromOffset(64, 64)
	badge.BackgroundColor3 = options.accent
	badge.BorderSizePixel = 0
	badge.Parent = header
	makeCorner(badge, 12)

	local badgeLabel = Instance.new("TextLabel")
	badgeLabel.Name = "BadgeGlyph"
	badgeLabel.Size = UDim2.fromScale(1, 1)
	badgeLabel.BackgroundTransparency = 1
	badgeLabel.Text = options.badgeText
	badgeLabel.FontFace = FONT_BOLD
	badgeLabel.TextSize = 24
	badgeLabel.TextColor3 = PALETTE.goldInk
	badgeLabel.Parent = badge

	local title = Instance.new("TextLabel")
	title.Name = "TitleLabel"
	title.Position = UDim2.fromOffset(92, 12)
	title.Size = UDim2.new(1, -106, 0, 36)
	title.BackgroundTransparency = 1
	title.Text = options.title
	title.FontFace = FONT_BOLD
	title.TextSize = 29
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextColor3 = options.accent
	title.TextTruncate = Enum.TextTruncate.AtEnd
	title.Parent = header

	local subtitle = Instance.new("TextLabel")
	subtitle.Name = "SubtitleLabel"
	subtitle.Position = UDim2.fromOffset(92, 50)
	subtitle.Size = UDim2.new(1, -106, 0, 28)
	subtitle.BackgroundTransparency = 1
	subtitle.Text = options.subtitle
	subtitle.FontFace = FONT_BLACK
	subtitle.TextSize = 19
	subtitle.TextXAlignment = Enum.TextXAlignment.Left
	subtitle.TextColor3 = PALETTE.textMuted
	subtitle.TextTruncate = Enum.TextTruncate.AtEnd
	subtitle.Parent = header

	local colBar = Instance.new("Frame")
	colBar.Name = "Columns"
	colBar.Position = UDim2.fromOffset(22, 114)
	colBar.Size = UDim2.new(1, -44, 0, 24)
	colBar.BackgroundTransparency = 1
	colBar.Parent = root

	local function makeColLabel(name: string, text: string, pos: UDim2, size: UDim2, align: Enum.TextXAlignment)
		local lbl = Instance.new("TextLabel")
		lbl.Name = name
		lbl.Position = pos
		lbl.Size = size
		lbl.BackgroundTransparency = 1
		lbl.Text = text
		lbl.FontFace = FONT_BLACK
		lbl.TextSize = 14
		lbl.TextXAlignment = align
		lbl.TextColor3 = PALETTE.textMuted
		lbl.Parent = colBar
	end
	makeColLabel("ColRank", "#", UDim2.fromOffset(14, 0), UDim2.fromOffset(36, 24), Enum.TextXAlignment.Center)
	makeColLabel("ColName", "PENDAKI", UDim2.fromOffset(110, 0), UDim2.fromOffset(260, 24), Enum.TextXAlignment.Left)
	makeColLabel("ColScore", "PUNCAK / REKOR", UDim2.new(1, -210, 0, 0), UDim2.fromOffset(196, 24), Enum.TextXAlignment.Right)

	local rowsContainer = Instance.new("Frame")
	rowsContainer.Name = "RowsContainer"
	rowsContainer.Position = UDim2.fromOffset(18, 140)
	rowsContainer.Size = UDim2.new(1, -36, 0, 558)
	rowsContainer.BackgroundTransparency = 1
	rowsContainer.Parent = root

	local emptyBanner = Instance.new("TextLabel")
	emptyBanner.Name = "EmptyBanner"
	emptyBanner.AnchorPoint = Vector2.new(0.5, 0.5)
	emptyBanner.Position = UDim2.fromScale(0.5, 0.45)
	emptyBanner.Size = UDim2.new(0.86, 0, 0, 150)
	emptyBanner.BackgroundColor3 = PALETTE.cardBg
	emptyBanner.BorderSizePixel = 0
	emptyBanner.FontFace = FONT_BLACK
	emptyBanner.TextSize = 23
	emptyBanner.TextWrapped = true
	emptyBanner.TextColor3 = PALETTE.textMain
	emptyBanner.Text = "Belum ada catatan pendakian.\nTerbangkan balonmu untuk merebut Peringkat #1!"
	emptyBanner.Visible = true
	emptyBanner.ZIndex = 4
	emptyBanner.Parent = rowsContainer
	makeCorner(emptyBanner, 14)
	makeStroke(emptyBanner, options.accent, 2, 0.45)

	for i = 1, Renderer.MAX_ROWS do
		local row = Instance.new("Frame")
		row.Name = "Row" .. tostring(i)
		row.Position = UDim2.fromOffset(0, (i - 1) * 56)
		row.Size = UDim2.new(1, 0, 0, 51)
		row.BackgroundColor3 = PALETTE.cardBg
		row.BackgroundTransparency = 0.08
		row.BorderSizePixel = 0
		row.Visible = false
		row.Parent = rowsContainer
		makeCorner(row, 11)
		local rStroke = makeStroke(row, PALETTE.rowBorder, 1.5, 0.4)
		rStroke.Name = "RowStroke"

		local rankFrame = Instance.new("Frame")
		rankFrame.Name = "RankBadge"
		rankFrame.AnchorPoint = Vector2.new(0, 0.5)
		rankFrame.Position = UDim2.new(0, 10, 0.5, 0)
		rankFrame.Size = UDim2.fromOffset(42, 37)
		rankFrame.BackgroundColor3 = PALETTE.slateBadge
		rankFrame.BorderSizePixel = 0
		rankFrame.Parent = row
		makeCorner(rankFrame, 9)

		local rankLabel = Instance.new("TextLabel")
		rankLabel.Name = "RankLabel"
		rankLabel.Size = UDim2.fromScale(1, 1)
		rankLabel.BackgroundTransparency = 1
		rankLabel.Text = "#" .. tostring(i)
		rankLabel.FontFace = FONT_BOLD
		rankLabel.TextSize = 20
		rankLabel.TextColor3 = PALETTE.textMain
		rankLabel.Parent = rankFrame

		local avatar = Instance.new("ImageLabel")
		avatar.Name = "AvatarImage"
		avatar.AnchorPoint = Vector2.new(0, 0.5)
		avatar.Position = UDim2.new(0, 62, 0.5, 0)
		avatar.Size = UDim2.fromOffset(38, 38)
		avatar.BackgroundColor3 = Color3.fromRGB(22, 46, 98)
		avatar.BorderSizePixel = 0
		avatar.Image = ""
		avatar.Parent = row
		makeCorner(avatar, 19)
		makeStroke(avatar, PALETTE.rowBorder, 1.5, 0.25)

		local initial = Instance.new("TextLabel")
		initial.Name = "AvatarInitial"
		initial.Size = UDim2.fromScale(1, 1)
		initial.BackgroundTransparency = 1
		initial.Text = ""
		initial.FontFace = FONT_BOLD
		initial.TextSize = 18
		initial.TextColor3 = PALETTE.textMain
		initial.Visible = false
		initial.Parent = avatar

		local nameLabel = Instance.new("TextLabel")
		nameLabel.Name = "NameLabel"
		nameLabel.AnchorPoint = Vector2.new(0, 0.5)
		nameLabel.Position = UDim2.new(0, 110, 0.5, 0)
		nameLabel.Size = UDim2.new(1, -310, 0, 34)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Text = ""
		nameLabel.FontFace = FONT_BLACK
		nameLabel.TextSize = 21
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.TextColor3 = PALETTE.textMain
		nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
		nameLabel.Parent = row

		local statPill = Instance.new("Frame")
		statPill.Name = "StatPill"
		statPill.AnchorPoint = Vector2.new(1, 0.5)
		statPill.Position = UDim2.new(1, -10, 0.5, 0)
		statPill.Size = UDim2.fromOffset(186, 36)
		statPill.BackgroundColor3 = PALETTE.cyanBg
		statPill.BorderSizePixel = 0
		statPill.Parent = row
		makeCorner(statPill, 10)
		local pStroke = makeStroke(statPill, PALETTE.cyan, 1.5, 0.25)
		pStroke.Name = "PillStroke"

		local statLabel = Instance.new("TextLabel")
		statLabel.Name = "StatLabel"
		statLabel.Size = UDim2.new(1, -12, 1, 0)
		statLabel.Position = UDim2.fromOffset(6, 0)
		statLabel.BackgroundTransparency = 1
		statLabel.Text = ""
		statLabel.FontFace = FONT_BOLD
		statLabel.TextSize = 19
		statLabel.TextXAlignment = Enum.TextXAlignment.Center
		statLabel.TextColor3 = PALETTE.cyanText
		statLabel.TextTruncate = Enum.TextTruncate.AtEnd
		statLabel.Parent = statPill
	end

	local footer = Instance.new("TextLabel")
	footer.Name = "FooterLabel"
	footer.Position = UDim2.fromOffset(18, 704)
	footer.Size = UDim2.new(1, -36, 0, 26)
	footer.BackgroundTransparency = 1
	footer.Text = options.footer
	footer.FontFace = FONT_BODY
	footer.TextSize = 15
	footer.TextColor3 = PALETTE.textMuted
	footer.TextTruncate = Enum.TextTruncate.AtEnd
	footer.Parent = root

	return gui
end

function Renderer.RenderBoard(gui: SurfaceGui, rawEntries: { any }, subtitleOverride: string?)
	local root = gui and gui:FindFirstChild("Panel")
	if not root then
		return
	end
	if subtitleOverride then
		local header = root:FindFirstChild("Header")
		local subtitle = header and header:FindFirstChild("SubtitleLabel")
		if subtitle then
			subtitle.Text = subtitleOverride
		end
	end
	local rowsContainer = root:FindFirstChild("RowsContainer")
	if not rowsContainer then
		return
	end
	local entries = Renderer.SortEntries(rawEntries, Renderer.MAX_ROWS)
	local emptyBanner = rowsContainer:FindFirstChild("EmptyBanner")
	if emptyBanner then
		emptyBanner.Visible = #entries == 0
	end

	for i = 1, Renderer.MAX_ROWS do
		local row = rowsContainer:FindFirstChild("Row" .. tostring(i))
		if not row then
			continue
		end
		local entry = entries[i]
		if not entry then
			row.Visible = false
			continue
		end
		row.Visible = true
		local rankBadge = row.RankBadge
		local rankLabel = rankBadge.RankLabel
		local rowStroke = row.RowStroke
		if i == 1 then
			row.BackgroundColor3 = PALETTE.cardTop1
			rowStroke.Color = PALETTE.gold
			rowStroke.Transparency = 0.15
			rankBadge.BackgroundColor3 = PALETTE.gold
			rankLabel.TextColor3 = PALETTE.goldInk
		elseif i == 2 then
			row.BackgroundColor3 = PALETTE.cardTop2
			rowStroke.Color = PALETTE.silver
			rowStroke.Transparency = 0.3
			rankBadge.BackgroundColor3 = PALETTE.silver
			rankLabel.TextColor3 = PALETTE.silverInk
		elseif i == 3 then
			row.BackgroundColor3 = PALETTE.cardTop3
			rowStroke.Color = PALETTE.bronze
			rowStroke.Transparency = 0.28
			rankBadge.BackgroundColor3 = PALETTE.bronze
			rankLabel.TextColor3 = PALETTE.bronzeInk
		else
			row.BackgroundColor3 = PALETTE.cardBg
			rowStroke.Color = PALETTE.rowBorder
			rowStroke.Transparency = 0.45
			rankBadge.BackgroundColor3 = PALETTE.slateBadge
			rankLabel.TextColor3 = PALETTE.textMain
		end
		rankLabel.Text = "#" .. tostring(i)

		local avatar = row.AvatarImage
		local initial = avatar.AvatarInitial
		if entry.userId and entry.userId > 0 then
			avatar.Image = string.format("rbxthumb://type=AvatarHeadShot&id=%d&w=100&h=100", entry.userId)
			initial.Visible = false
		else
			avatar.Image = ""
			initial.Text = string.upper(string.sub(entry.name, 1, 1))
			initial.Visible = true
		end

		row.NameLabel.Text = entry.name

		local pill = row.StatPill
		local pillStroke = pill.PillStroke
		local statLabel = pill.StatLabel
		if entry.summits > 0 then
			pill.BackgroundColor3 = PALETTE.goldBg
			pillStroke.Color = PALETTE.gold
			pillStroke.Transparency = 0.12
			statLabel.TextColor3 = PALETTE.gold
			statLabel.Text = string.format("* %dx Puncak", entry.summits)
		else
			pill.BackgroundColor3 = PALETTE.cyanBg
			pillStroke.Color = PALETTE.cyan
			pillStroke.Transparency = 0.22
			statLabel.TextColor3 = PALETTE.cyanText
			statLabel.Text = string.format("^ %s km", Renderer.FormatKm(entry.maxAlt))
		end
	end
end

return Renderer
