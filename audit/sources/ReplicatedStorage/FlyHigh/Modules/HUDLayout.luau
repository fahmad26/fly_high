-- Responsive Arcade HUD Layout (UI Designer Pass) for "Fly High"
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
		gui:SetAttribute("HUDDesignVersion", 5)

		local function place(name, x, y, bw, bh)
			local o = get(name)
			box(o, x, y, bw, bh)
			return o
		end

		local margin = compact and 12 or 16
		local inFlight = player:GetAttribute("InFlight") == true

		-- Top Center: Hero Flight Dashboard Banner (Sleek 58px capsule)
		local topW = math.min(compact and 380 or 480, w - 32)
		local topH = compact and 54 or 58
		place("AltimeterFrame", (w - topW) / 2, 8, topW, topH)

		-- Grounded Countdown: Narrower sleek hazard ribbon (NOT a cloned double bar!)
		local noticeW = math.min(340, w - 32)
		place("GroundedCountdown", (w - noticeW) / 2, topH + 14, noticeW, 28)

		-- Top Left: Hull Condition Card (Aligned at Y = 8 with Altimeter)
		local statusY = (w >= 920 and 8) or (topH + 14)
		local statusW = compact and 176 or 196
		local statusH = compact and 48 or 52
		local status = place("StatusFrame", margin, statusY, statusW, statusH)
		local storm = get("StormChallengePanel")
		if status then
			status.Visible = inFlight and not (storm and storm.Visible)
		end

		-- Left Side: Clean Vertical Utility Dock (TOKO, KIT, PING, SUARA)
		local tileW = 50
		local tileH = 56
		local gap = 8
		local navY = compact and 130 or math.max(statusY + statusH + 14, math.min(180, h * 0.25))

		for i, name in { "ShopToggleButton", "EmergencyKitButton", "PingButton", "WarningAudioToggleButton" } do
			local col = compact and (i - 1) or 0
			local row = compact and 0 or (i - 1)
			place(name, margin + col * (tileW + gap), navY + row * (tileH + gap), tileW, tileH)
		end

		-- Bottom Right: Circular Arcade Jump Button
		local jumpSize = compact and 70 or 80
		local jump = place("JumpPanel", w - margin - jumpSize, h - margin - jumpSize, jumpSize, jumpSize)
		if jump then
			jump.BackgroundTransparency = 1
			if jump:FindFirstChild("JumpHint") then
				jump.JumpHint.Visible = false
			end
			box(jump.JumpButton, 0, 0, jumpSize, jumpSize)
		end

		-- Gunner Shoot Button & Utilities
		local fireSize = compact and 68 or 80
		local fireX = compact and (w - margin - jumpSize - 40 - fireSize) or (w - margin - fireSize)
		local fireY = h - margin - jumpSize - 16 - fireSize
		place("MobileShootButton", fireX, fireY, fireSize, fireSize)

		local utility = compact and 44 or 50
		local utilityY = compact and (h - 130) or (h - 156)
		place("ReloadButton", compact and math.max(12, w - 290) or (w - 250), utilityY, utility, utility)
		place("DropButton", compact and math.max(64, w - 238) or (w - 192), utilityY, utility, utility)

		-- Ammo HUD Card
		local ammoX = compact and (w < 500 and 12 or math.max(w / 2 + 20, w - 310)) or (w - 360)
		local ammoW = compact and (w < 500 and math.min(200, w - 24) or math.min(200, w - margin - jumpSize - 10 - ammoX)) or 230
		place("WeaponFrame", ammoX, h - (w < 500 and 230 or (compact and 60 or 90)), ammoW, compact and 50 or 70)

		-- Pilot Controls (Gas, AutoGas, Release)
		place("GasButton", w - margin - (compact and 92 or 104), h - margin - (compact and 76 or 88), compact and 92 or 104, compact and 76 or 88)
		place("AutoGasButton", w - margin - (compact and 246 or 272), h - margin - 52, compact and 144 or 160, 52)
		place("ReleaseHelmButton", w - margin - (compact and 310 or 336), h - margin - 52, 52, 52)

		if w < 500 then
			place("AutoGasButton", margin, h - 140, 160, 52)
			place("ReleaseHelmButton", margin, h - 76, 52, 52)
		end

		-- Rigging & Action Buttons (Contextual row)
		local visible = {}
		for _, name in rigging do
			local o = get(name)
			if o and o.Visible then
				table.insert(visible, o)
			end
		end
		local bw = compact and 136 or 150
		local bh = compact and 44 or 50
		local perRow = math.min(3, math.max(1, math.floor((w - 220) / (bw + 10))))
		local rows = math.ceil(#visible / perRow)
		for i, o in visible do
			local row = math.floor((i - 1) / perRow)
			local col = (i - 1) % perRow
			local count = math.min(perRow, #visible - row * perRow)
			box(o, (w - (count * bw + (count - 1) * 10)) / 2 + col * (bw + 10), h - 96 - (rows - row - 1) * (bh + 10), bw, bh)
		end

		-- Tether Gauge Bar
		local ropeW = math.min(250, w - jumpSize - 2 * margin - 12)
		place("TetherFrame", w < 500 and margin or (w - ropeW) / 2, h - 40, ropeW, 28)

		-- Early Warning Hazards
		local centerX = w < 650 and margin or (compact and 220 or math.max(statusW + margin + 16, (w - 440) / 2))
		local alertW = math.min(440, w - centerX - (w < 650 and margin or (compact and 80 or 20)))
		local alertY = w < 650 and 200 or (compact and 76 or 86)
		place("AlertBanner", centerX, alertY, alertW, 68)
		place("StormChallengePanel", centerX, alertY, alertW, 86)
		place("GhostSpotterFrame", (w - math.min(320, w - 32)) / 2, compact and 76 or 86, math.min(320, w - 32), 60)

		-- Modals: ShopModal (Clean rectangular window, NOT an oval!)
		local modal = get("ShopModal")
		local wheel = get("TacticalPingWheel")
		scrim.Visible = (modal and modal.Visible) or (wheel and wheel.Visible) or false

		if modal then
			local mw = math.min(450, w - 24)
			local mh = math.min(370, h - 20)
			box(modal, (w - mw) / 2, (h - mh) / 2, mw, mh)
			modal.CanvasSize = UDim2.fromOffset(0, 350)
			modal.ZIndex = 22

			local closeBtn = modal:FindFirstChild("CloseButton")
			if closeBtn then
				box(closeBtn, mw - 38, 6, 30, 30)
				closeBtn.ZIndex = 26
			end

			local card1 = modal:FindFirstChild("Card1")
			if card1 then
				box(card1, 14, 48, mw - 28, 138)
				card1.ZIndex = 23
			end

			local card2 = modal:FindFirstChild("Card2")
			if card2 then
				box(card2, 14, 196, mw - 28, 138)
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
