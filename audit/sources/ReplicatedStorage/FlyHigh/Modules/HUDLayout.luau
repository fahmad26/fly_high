-- Responsive Arcade HUD Layout (UI Designer Polish Pass 4) for "Fly High"
-- Positions all HUD elements with proper hierarchy, visual breathing room,
-- and clean non-overlapping geometry across mobile, tablet, and desktop.

local Layout = {}

local rigging = {
	"AttachButton",
	"RepairRopeButton",
	"PullCrewButton",
	"DetachButton",
	"ClimbButton",
	"RepairButton",
	"DescendButton",
}

local function box(o, x, y, w, h)
	if not o then return end
	o.AnchorPoint = Vector2.zero
	o.Position = UDim2.fromOffset(math.round(x), math.round(y))
	o.Size = UDim2.fromOffset(math.round(w), math.round(h))
end

function Layout.Start(gui, player)
	local theme = require(script.Parent.HUDTheme).Start(gui, player)
	local input = game:GetService("UserInputService")
	gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets

	local scrim = Instance.new("TextButton")
	scrim.Name = "HUDModalScrim"
	scrim.Text = ""
	scrim.BackgroundColor3 = Color3.fromRGB(4, 10, 22)
	scrim.BackgroundTransparency = 0.35
	scrim.BorderSizePixel = 0
	scrim.Size = UDim2.fromScale(1, 1)
	scrim.Visible = false
	scrim.ZIndex = 20
	scrim.Parent = gui

	local function get(name)
		return gui:FindFirstChild(name)
	end

	scrim.Activated:Connect(function()
		for _, name in { "ShopModal", "TacticalPingWheel" } do
			local o = get(name)
			if o then o.Visible = false end
		end
		scrim.Visible = false
	end)

	local function showModal(target)
		for _, name in { "ShopModal", "TacticalPingWheel" } do
			local o = get(name)
			if o and o ~= target then o.Visible = false end
		end
		if target then
			target.Visible = not target.Visible
			scrim.Visible = target.Visible
		else
			scrim.Visible = false
		end
	end

	local shopBtn = get("ShopToggleButton")
	if shopBtn and shopBtn:IsA("GuiButton") then
		shopBtn.Activated:Connect(function()
			showModal(get("ShopModal"))
		end)
	end

	local pingBtn = get("PingButton")
	if pingBtn and pingBtn:IsA("GuiButton") then
		pingBtn.Activated:Connect(function()
			showModal(get("TacticalPingWheel"))
		end)
	end

	local closeBtn = gui:FindFirstChild("CloseButton", true)
	if closeBtn and closeBtn:IsA("GuiButton") then
		closeBtn.Activated:Connect(function()
			local modal = get("ShopModal")
			if modal then modal.Visible = false end
			scrim.Visible = false
		end)
	end

	local elapsed = 1
	local connection
	connection = game:GetService("RunService").RenderStepped:Connect(function(dt)
		if not gui.Parent then
			theme.Destroy()
			connection:Disconnect()
			return
		end

		elapsed = (elapsed or 0) + dt
		if elapsed < 0.04 then return end
		elapsed = 0

		local w, h = gui.AbsoluteSize.X, gui.AbsoluteSize.Y
		if w < 1 or h < 1 then return end

		local compact = h < 520 or w < 760
		gui:SetAttribute("CompactLayout", compact)
		gui:SetAttribute("TabletLayout", input.TouchEnabled and not compact)
		gui:SetAttribute("HUDDesignVersion", 6)

		local function place(name, x, y, bw, bh)
			local o = get(name)
			box(o, x, y, bw, bh)
			return o
		end

		local margin = compact and 12 or 18
		local inFlight = player:GetAttribute("InFlight") == true

		-- 1. Altitude Capsule (Top Center Hero HUD)
		local altY = 8
		local topW = math.clamp(w * 0.44, 400, 500)
		local topH = compact and 56 or 62
		place("AltimeterFrame", (w - topW) / 2, altY, topW, topH)

		-- 2. Grounded Countdown Ribbon (Strictly below Altimeter with comfortable 12px breathing room)
		local noticeW = math.clamp(topW - 40, 300, 420)
		local noticeH = 30
		local noticeY = altY + topH + 12
		place("GroundedCountdown", (w - noticeW) / 2, noticeY, noticeW, noticeH)

		-- 3. Hull Condition Card (Top Left)
		local statusY = (w >= 960 and 8) or (noticeY + noticeH + 10)
		local statusW = compact and 180 or 196
		local statusH = 56
		local status = place("StatusFrame", margin, statusY, statusW, statusH)
		local storm = get("StormChallengePanel")
		if status then
			status.Visible = inFlight and not (storm and storm.Visible)
	end

		-- 4. Left Dock Toolbar (Clean vertical column on left edge)
		local tileW = 50
		local tileH = 56
		local gap = 8
		local navY = compact and 120 or math.max(statusY + statusH + 14, math.min(180, h * 0.25))

		for i, name in { "ShopToggleButton", "EmergencyKitButton", "PingButton", "WarningAudioToggleButton" } do
			place(name, margin, navY + (i - 1) * (tileH + gap), tileW, tileH)
		end

		-- 5. Jump Button (Bottom Right - Circular Arcade Button inside JumpPanel)
		local jumpSize = compact and 84 or 90
		local jumpMarginR = compact and 24 or 28
		local jumpMarginB = compact and 24 or 28
		local jump = place("JumpPanel", w - jumpMarginR - jumpSize, h - jumpMarginB - jumpSize, jumpSize, jumpSize)
		if jump then
			jump.BackgroundTransparency = 1
			local btn = jump:FindFirstChild("JumpButton")
			if btn then box(btn, 0, 0, jumpSize, jumpSize) end
			local hint = jump:FindFirstChild("JumpHint")
			if hint then hint.Visible = false end
		end

		-- 6. Gunner Shoot Button & Utilities (Right thumb zone)
		local fireSize = compact and 74 or 84
		local fireX = compact and (w - jumpMarginR - jumpSize - 16 - fireSize) or (w - jumpMarginR - fireSize)
		local fireY = h - jumpMarginB - jumpSize - 16 - fireSize
		place("MobileShootButton", fireX, fireY, fireSize, fireSize)

		local utility = compact and 46 or 52
		local utilityY = compact and (h - 134) or (h - 160)
		place("ReloadButton", compact and math.max(12, w - 300) or (w - 260), utilityY, utility, utility)
		place("DropButton", compact and math.max(68, w - 244) or (w - 200), utilityY, utility, utility)

		-- 7. Ammo HUD Card (Bottom Right / Center)
		local ammoX = compact and (w < 500 and 12 or math.max(w / 2 + 20, w - 320)) or (w - 370)
		local ammoW = compact and (w < 500 and math.min(210, w - 24) or math.min(210, w - margin - jumpSize - 10 - ammoX)) or 240
		place("WeaponFrame", ammoX, h - (w < 500 and 230 or (compact and 64 or 94)), ammoW, compact and 54 or 72)

		-- 8. Pilot Controls (Gas, AutoGas, Release)
		local gasW = compact and 96 or 108
		local gasH = compact and 80 or 90
		place("GasButton", w - margin - gasW, h - margin - gasH, gasW, gasH)

		local autoW = compact and 160 or 176
		local autoH = compact and 54 or 56
		place("AutoGasButton", w - margin - gasW - 12 - autoW, h - margin - autoH, autoW, autoH)
		place("ReleaseHelmButton", w - margin - gasW - 12 - autoW - 10 - 54, h - margin - autoH, 54, 54)

		if w < 500 then
			place("AutoGasButton", margin, h - 144, 160, 54)
			place("ReleaseHelmButton", margin, h - 80, 54, 54)
		end

		-- 9. Rigging & Action Buttons (Contextual row)
		local visible = {}
		for _, name in rigging do
			local o = get(name)
			if o and o.Visible then
				table.insert(visible, o)
			end
		end
		local bw = compact and 140 or 156
		local bh = compact and 46 or 52
		local perRow = math.min(3, math.max(1, math.floor((w - 220) / (bw + 10))))
		local rows = math.ceil(#visible / perRow)
		for i, o in visible do
			local row = math.floor((i - 1) / perRow)
			local col = (i - 1) % perRow
			local count = math.min(perRow, #visible - row * perRow)
			box(o, (w - (count * bw + (count - 1) * 10)) / 2 + col * (bw + 10), h - 100 - (rows - row - 1) * (bh + 10), bw, bh)
		end

		-- 10. Tether Gauge Bar
		local ropeW = math.min(260, w - jumpSize - 2 * margin - 12)
		place("TetherFrame", w < 500 and margin or (w - ropeW) / 2, h - 42, ropeW, 30)

		-- 11. Early Warning Hazards
		local centerX = w < 650 and margin or (compact and 220 or math.max(statusW + margin + 16, (w - 440) / 2))
		local alertW = math.min(440, w - centerX - (w < 650 and margin or (compact and 80 or 20)))
		local alertY = w < 650 and 200 or (compact and 78 or 88)
		place("AlertBanner", centerX, alertY, alertW, 68)
		place("StormChallengePanel", centerX, alertY, alertW, 86)
		place("GhostSpotterFrame", (w - math.min(320, w - 32)) / 2, compact and 78 or 88, math.min(320, w - 32), 60)

		-- 12. Modals (ShopModal & TacticalPingWheel)
		local modal = get("ShopModal")
		local wheel = get("TacticalPingWheel")
		scrim.Visible = (modal and modal.Visible) or (wheel and wheel.Visible) or false

		if modal then
			local mw = math.clamp(w * 0.52, 460, 560)
			local mh = math.clamp(h * 0.74, 380, 440)
			box(modal, (w - mw) / 2, (h - mh) / 2, mw, mh)
			modal.CanvasSize = UDim2.fromOffset(0, 360)
			modal.ZIndex = 22

			local cBtn = modal:FindFirstChild("CloseButton", true)
			if cBtn then
				box(cBtn, mw - 42, 8, 32, 32)
				cBtn.ZIndex = 26
			end

			local card1 = modal:FindFirstChild("Card1")
			local card2 = modal:FindFirstChild("Card2")
			local cardW = mw - 32
			local cardH = 140

			if card1 then
				box(card1, 16, 50, cardW, cardH)
				card1.ZIndex = 23
			end
			if card2 then
				box(card2, 16, 50 + cardH + 12, cardW, cardH)
				card2.ZIndex = 23
			end
		end

		if wheel then
			local mw = math.min(340, w - 24)
			local mh = 290
			box(wheel, (w - mw) / 2, (h - mh) / 2, mw, mh)
			wheel.ZIndex = 22
			for i = 1, 5 do
				local b = wheel:FindFirstChild("Ping" .. i)
				if b then
					box(b, 0, (i - 1) * 54, mw, 46)
					b.ZIndex = 23
				end
			end
		end

		theme.Step()
	end)
end

return Layout
