-- Responsive Arcade HUD Layout v4 (Pass 2 Refinement) for "Fly High"
-- Positions all HUD elements responsively across desktop, tablet, and mobile screens.

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
	end)

	local elapsed = 1
	local connection
	connection = game:GetService("RunService").RenderStepped:Connect(function(dt)
		if not gui.Parent then
			theme.Destroy()
			connection:Disconnect()
			return
		end

		elapsed = (elapsed or 0) + dt
		if elapsed < 0.08 then return end
		elapsed = 0

		local w, h = gui.AbsoluteSize.X, gui.AbsoluteSize.Y
		if w < 1 or h < 1 then return end

		local compact = h < 520 or w < 760
		gui:SetAttribute("CompactLayout", compact)
		gui:SetAttribute("TabletLayout", input.TouchEnabled and not compact)
		gui:SetAttribute("HUDDesignVersion", 4)

		local function place(name, x, y, bw, bh)
			local o = get(name)
			box(o, x, y, bw, bh)
			return o
		end

		local margin = compact and 14 or 20
		local inFlight = player:GetAttribute("InFlight") == true

		-- Top Center: Hero Flight Dashboard Banner
		local topW = math.min(compact and 380 or 460, w - 32)
		local topH = compact and 62 or 68
		place("AltimeterFrame", (w - topW) / 2, 8, topW, topH)

		-- Grounded Countdown / Hazard Notice: Attached directly below Altimeter
		place("GroundedCountdown", (w - topW) / 2, topH + 12, topW, 32)

		-- Top Left: Hull Condition Card (Aligned at Y = 8 to match Altimeter!)
		local statusY = (w >= 960 and 8) or 84
		local statusW = compact and 200 or 224
		local status = place("StatusFrame", margin, statusY, statusW, compact and 60 or 68)
		local storm = get("StormChallengePanel")
		if status then
			status.Visible = inFlight and not (storm and storm.Visible)
		end

		-- Left Side: Clean Vertical Utility Dock (TOKO, KIT, PING, SUARA)
		local tileW = compact and 48 or 56
		local tileH = compact and 54 or 64
		local gap = compact and 8 or 10
		local navY = compact and 150 or math.max(statusY + 82, math.min(220, h * 0.28))

		for i, name in { "ShopToggleButton", "EmergencyKitButton", "PingButton", "WarningAudioToggleButton" } do
			local col = compact and (i - 1) or 0
			local row = compact and 0 or (i - 1)
			place(name, margin + col * (tileW + gap), navY + row * (tileH + gap), tileW, tileH)
		end

		-- Bottom Right: Circular Arcade Jump Button
		local jumpSize = compact and 74 or 86
		local jump = place("JumpPanel", w - margin - jumpSize, h - margin - jumpSize, jumpSize, jumpSize)
		if jump then
			jump.BackgroundTransparency = 1
			if jump:FindFirstChild("JumpHint") then
				jump.JumpHint.Visible = false
			end
			box(jump.JumpButton, 0, 0, jumpSize, jumpSize)
		end

		-- Gunner Shoot Button & Utilities
		local fireSize = compact and 70 or 84
		local fireX = compact and (w - margin - jumpSize - 44 - fireSize) or (w - margin - fireSize)
		local fireY = h - margin - jumpSize - 18 - fireSize
		place("MobileShootButton", fireX, fireY, fireSize, fireSize)

		local utility = compact and 46 or 52
		local utilityY = compact and (h - 138) or (h - 164)
		place("ReloadButton", compact and math.max(14, w - 314) or (w - 268), utilityY, utility, utility)
		place("DropButton", compact and math.max(70, w - 258) or (w - 204), utilityY, utility, utility)

		-- Ammo HUD Card
		local ammoX = compact and (w < 500 and 14 or math.max(w / 2 + 36, w - 330)) or (w - 386)
		local ammoW = compact and (w < 500 and math.min(220, w - 28) or math.min(220, w - margin - jumpSize - 12 - ammoX)) or 248
		place("WeaponFrame", ammoX, h - (w < 500 and 246 or (compact and 66 or 98)), ammoW, compact and 54 or 76)

		-- Pilot Controls (Gas, AutoGas, Release)
		place("GasButton", w - margin - (compact and 96 or 108), h - margin - (compact and 80 or 90), compact and 96 or 108, compact and 80 or 90)
		place("AutoGasButton", w - margin - (compact and 258 or 286), h - margin - 56, compact and 152 or 168, 56)
		place("ReleaseHelmButton", w - margin - (compact and 326 or 354), h - margin - 56, 56, 56)

		if w < 500 then
			place("AutoGasButton", margin, h - 148, 180, 56)
			place("ReleaseHelmButton", margin, h - 80, 56, 56)
		end

		-- Rigging & Action Buttons (Contextual row)
		local visible = {}
		for _, name in rigging do
			local o = get(name)
			if o and o.Visible then
				table.insert(visible, o)
			end
		end
		local bw = compact and 140 or 156
		local bh = compact and 48 or 54
		local perRow = math.min(3, math.max(1, math.floor((w - 240) / (bw + 10))))
		local rows = math.ceil(#visible / perRow)
		for i, o in visible do
			local row = math.floor((i - 1) / perRow)
			local col = (i - 1) % perRow
			local count = math.min(perRow, #visible - row * perRow)
			box(o, (w - (count * bw + (count - 1) * 10)) / 2 + col * (bw + 10), h - 104 - (rows - row - 1) * (bh + 10), bw, bh)
		end

		-- Tether Gauge Bar
		local ropeW = math.min(260, w - jumpSize - 2 * margin - 14)
		place("TetherFrame", w < 500 and margin or (w - ropeW) / 2, h - 44, ropeW, 30)

		-- Early Warning Hazards
		local centerX = w < 650 and margin or (compact and 250 or math.max(statusW + margin + 20, (w - 460) / 2))
		local alertW = math.min(460, w - centerX - (w < 650 and margin or (compact and 100 or 24)))
		local alertY = w < 650 and 220 or (compact and 82 or 94)
		place("AlertBanner", centerX, alertY, alertW, 74)
		place("StormChallengePanel", centerX, alertY, alertW, 92)
		place("GhostSpotterFrame", (w - math.min(340, w - 32)) / 2, compact and 82 or 94, math.min(340, w - 32), 64)

		-- Modals
		local modal = get("ShopModal")
		local wheel = get("TacticalPingWheel")
		scrim.Visible = (modal and modal.Visible) or (wheel and wheel.Visible) or false

		if modal then
			local mw = math.min(480, w - 32)
			local mh = math.min(430, h - 24)
			box(modal, (w - mw) / 2, (h - mh) / 2, mw, mh)
			modal.CanvasSize = UDim2.fromOffset(0, 370)
			modal.ZIndex = 22

			local closeBtn = modal:FindFirstChild("CloseButton")
			if closeBtn then
				box(closeBtn, mw - 46, 8, 36, 36)
				closeBtn.ZIndex = 26
			end

			local card1 = modal:FindFirstChild("Card1")
			if card1 then
				box(card1, 16, 52, mw - 32, 142)
				card1.ZIndex = 23
			end

			local card2 = modal:FindFirstChild("Card2")
			if card2 then
				box(card2, 16, 206, mw - 32, 142)
				card2.ZIndex = 23
			end
		end

		if wheel then
			local mw = math.min(380, w - 32)
			local mh = 310
			box(wheel, (w - mw) / 2, (h - mh) / 2, mw, mh)
			wheel.ZIndex = 22
			for i = 1, 5 do
				local b = wheel:FindFirstChild("Ping" .. i)
				if b then
					box(b, 0, (i - 1) * 58, mw, 50)
					b.ZIndex = 23
				end
			end
		end

		theme.Step()
	end)
end

return Layout
