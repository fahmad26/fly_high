-- Responsive Arcade HUD Layout (UI Designer Polish Pass 4) for "Fly High"
-- Positions all HUD elements with proper hierarchy, visual breathing room,
-- and clean non-overlapping geometry across mobile, tablet, and desktop.

local Layout = {}
local preferredTextGrowth = {
	[Enum.PreferredTextSize.Medium] = 0,
	[Enum.PreferredTextSize.Large] = 2,
	[Enum.PreferredTextSize.Larger] = 4,
	[Enum.PreferredTextSize.Largest] = 6,
}

local rigging = {
	"AttachButton",
	"PullCrewButton",
	"DetachButton",
	"ClimbButton",
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
	local assets = require(script.Parent.HUDImageAssets)
	local input = game:GetService("UserInputService")
	local guiService = game:GetService("GuiService")
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
	local scrimImage = assets.Mount(scrim, "meter_scrim")

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

	local activeModal
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
		local textBoost = math.min(preferredTextGrowth[guiService.PreferredTextSize] or 0, compact and 3 or 6)
		gui:SetAttribute("HUDTextBoost", textBoost)
		gui:SetAttribute("CompactLayout", compact)
		gui:SetAttribute("TabletLayout", input.TouchEnabled and not compact)
		gui:SetAttribute("HUDDesignVersion", 11)
		scrim.BackgroundTransparency = scrimImage.IsLoaded and 1 or 0.35

		local function place(name, x, y, bw, bh)
			local o = get(name)
			box(o, x, y, bw, bh)
			return o
		end

		local margin = compact and 12 or 18
		local inFlight = player:GetAttribute("InFlight") == true
		local portrait = w < h and w < 620
		local jumpSize = compact and 84 or 90
		local jumpMarginR = compact and 24 or 28
		local jumpMarginB = compact and 24 or 28
		local fireSize = compact and 74 or 84
		local utility = (compact and 46 or 52) + textBoost
		local right = w - jumpMarginR
		local jumpY = h - jumpMarginB - jumpSize
		local fireX = portrait and right - fireSize or right - jumpSize - 8 - fireSize
		local fireY = portrait and jumpY - fireSize - 8 or h - jumpMarginB - fireSize
		local touchUtilityGutter = input.TouchEnabled and compact and not portrait and w >= 680 and h >= 300
		local utilityRight = touchUtilityGutter and fireX - 8 or right

		-- 1. Altitude Capsule (Top Center Hero HUD)
		local altY = 8
		local topW = math.min(w - 2 * margin, math.clamp(w * 0.44, 400, 500) + 8 * textBoost)
		local topH = (topW < 380 and (inFlight and 78 or 66) or 62) + 2 * textBoost
		place("AltimeterFrame", (w - topW) / 2, altY, topW, topH)

		local statusW = portrait and w - 2 * margin or 224 + 6 * textBoost
		local wide = w >= 960 and (w - topW) / 2 >= margin + statusW + 12
		local headerBottom = altY + topH
		local statusY = wide and altY or headerBottom + 8
		local statusH = 64 + 2 * textBoost
		local tileW = 50 + textBoost
		local statusX = portrait and margin or wide and margin or margin + tileW + 8
		local status = place("StatusFrame", statusX, statusY, statusW, statusH)
		if status then status.Visible = inFlight end

		-- Keep hull telemetry visible and reserve one separate lane for priority messages.
		local storm = get("StormChallengePanel")
		local alert = get("AlertBanner")
		if alert then
			alert.Visible = inFlight and alert:GetAttribute("HUDAlertActive") == true and not (storm and storm.Visible)
		end
		local warningX = wide and (w - topW) / 2 or statusX
		local warningY = (wide and headerBottom or statusY + statusH) + 8
		local warningW = wide and topW or math.min(430, w - warningX - margin)
		if touchUtilityGutter and get("WeaponFrame") and get("WeaponFrame").Visible then
			warningW = math.min(warningW, utilityRight - utility * 2 - 16 - warningX)
		end
		place("StormChallengePanel", warningX, warningY, warningW, 60)
		place("AlertBanner", warningX, warningY, warningW, 60)
		local notice = place("GroundedCountdown", warningX, warningY, warningW, 38 + textBoost)
		local seconds = gui:GetAttribute("HUDGroundedSeconds")
		if notice then
			notice.Visible = inFlight and seconds ~= nil and not (storm and storm.Visible) and not (alert and alert.Visible)
			if notice.Visible then
				local gas = get("GasButton")
				local pilot = gas and gas.Visible
				notice.Text = (pilot and "Tahan gas untuk lepas landas" or "Pilot belum lepas landas")
					.. " · " .. seconds .. " dtk"
			end
		end

		local tileH = (compact and 50 or 56) + textBoost
		local gap = 8
		local navY = portrait and warningY + 68 or (wide and statusY + statusH + 8 or statusY)
		if not inFlight then navY = headerBottom + 12 end
		local slot = 0
		local topSlots = 0
		local topUtilitySpace = (w - topW) / 2 - margin
		for _, name in { "EmergencyKitButton", "PingButton", "WarningAudioToggleButton", "ShopToggleButton" } do
			local item = get(name)
			if item then
				item.Visible = inFlight or name == "ShopToggleButton"
				if item.Visible then
					local slotsNeeded = name == "WarningAudioToggleButton" and 2 or 1
					local moveToTop = input.TouchEnabled and compact and not portrait
						and (name == "ShopToggleButton" or name == "WarningAudioToggleButton")
						and topUtilitySpace >= slotsNeeded * (tileW + gap)
					if moveToTop then
						place(name, w - margin - tileW - topSlots * (tileW + gap), altY, tileW, tileH)
						topSlots += 1
					else
						place(name, margin, navY + slot * (tileH + gap), tileW, tileH)
						slot += 1
					end
				end
			end
		end

		-- 5. Jump Button (Bottom Right - Circular Arcade Button inside JumpPanel)
		local jump = place("JumpPanel", w - jumpMarginR - jumpSize, h - jumpMarginB - jumpSize, jumpSize, jumpSize)
		if jump then
			jump.BackgroundTransparency = 1
			local btn = jump:FindFirstChild("JumpButton")
			if btn then box(btn, 0, 0, jumpSize, jumpSize) end
			local hint = jump:FindFirstChild("JumpHint")
			if hint then hint.Visible = false end
		end

		-- 6. Gunner Shoot Button & Utilities (Right thumb zone)
		place("MobileShootButton", fireX, fireY, fireSize, fireSize)
		local utilityY = math.min(jumpY, fireY) - utility - 8
		place("ReloadButton", utilityRight - utility * 2 - 8, utilityY, utility, utility)
		place("DropButton", utilityRight - utility, utilityY, utility, utility)
		local ammoW = (compact and 212 or 248) + 9 * textBoost
		local ammoH = (compact and 56 or 60) + 2 * textBoost
		local ammoX, ammoY = right - ammoW, utilityY - ammoH - 8
		local ammoAlongsideFire = compact and not portrait and w >= 540
		-- Short landscapes have room beside the utility buttons, preserving the playfield above.
		if ammoAlongsideFire then
			ammoX = fireX - 8 - ammoW
			ammoY = touchUtilityGutter and jumpY or h - jumpMarginB - ammoH
		end
		place("WeaponFrame", ammoX, ammoY, ammoW, ammoH)

		local weaponView = get("WeaponView")
		if weaponView then
			local scale = compact and weaponView:GetAttribute("CompactScale") or 0.68
			local side = math.min(h * scale, w * weaponView:GetAttribute("WidthCap"))
			local aboveAmmo = ammoAlongsideFire or portrait
			local gunRight = aboveAmmo and fireX or math.min(fireX, ammoX)
			local gunBottom = aboveAmmo and ammoY + 4 or h
			-- Align the visible weapon with the HUD, accounting for viewport padding.
			local gunLeft = gunRight - 8 - weaponView:GetAttribute("RightEdge") * side
			box(weaponView, math.max(0, gunLeft), gunBottom - 0.90 * side, side, side)
		end

		-- 8. Pilot Controls (Gas, AutoGas, Release)
		local gasW = compact and 96 or 108
		local gasH = compact and 80 or 90
		place("GasButton", w - margin - gasW, h - margin - gasH, gasW, gasH)

		local autoW = (compact and 160 or 176) + 4 * textBoost
		local autoH = compact and 54 or 56
		local releaseSize = 54 + textBoost
		place("AutoGasButton", w - margin - gasW - 12 - autoW, h - margin - autoH, autoW, autoH)
		place("ReleaseHelmButton", w - margin - gasW - 12 - autoW - 10 - releaseSize, h - margin - releaseSize, releaseSize, releaseSize)

		if w < 500 then
			local pilotY = h - margin - gasH - math.max(autoH, releaseSize) - 8
			place("AutoGasButton", w - margin - autoW, pilotY, autoW, autoH)
			place("ReleaseHelmButton", w - margin - autoW - releaseSize - 8, pilotY, releaseSize, releaseSize)
		end

		-- 9. Rigging & Action Buttons (Contextual row)
		local visible = {}
		for _, name in rigging do
			local o = get(name)
			if o and o.Visible then
				table.insert(visible, o)
			end
		end
		local bw = (compact and 140 or 156) + 4 * textBoost
		local bh = compact and 46 or 52
		local perRow = math.min(3, math.max(1, math.floor((w - 220) / (bw + 10))))
		if compact and not portrait and w >= math.max(540, 3 * bw + 20 + 2 * margin) then perRow = 3 end
		local rows = math.ceil(#visible / perRow)
		for i, o in visible do
			local row = math.floor((i - 1) / perRow)
			local col = (i - 1) % perRow
			local count = math.min(perRow, #visible - row * perRow)
			local baseline = portrait and jumpY - bh - 8 or h - 100 - textBoost
			box(o, (w - (count * bw + (count - 1) * 10)) / 2 + col * (bw + 10), baseline - (rows - row - 1) * (bh + 10), bw, bh)
		end

		-- 10. Tether Gauge Bar
		local ropeW = math.min(260, w - jumpSize - 2 * margin - 12)
		place("TetherFrame", w < 500 and margin or (w - ropeW) / 2, h - 42 - textBoost, ropeW, 30 + textBoost)

		place("GhostSpotterFrame", warningX, warningY + 68, math.min(320, warningW), 60)

		-- 12. Modals (ShopModal & TacticalPingWheel)
		local modal = get("ShopModal")
		local wheel = get("TacticalPingWheel")
		-- The shop and weapon controllers own their buttons. Only reconcile visibility here.
		if modal and modal.Visible and wheel and wheel.Visible then
			if activeModal == modal then modal.Visible = false else wheel.Visible = false end
		end
		activeModal = (modal and modal.Visible and modal) or (wheel and wheel.Visible and wheel) or nil
		scrim.Visible = activeModal ~= nil

		if modal then
			local mw = math.min(w - 24, math.clamp(w * 0.52, 460, 560))
			local mh = math.min(h - 24, math.clamp(h * 0.74, 380, 440))
			box(modal, (w - mw) / 2, (h - mh) / 2, mw, mh)
			modal.ZIndex = 22

			local cBtn = modal:FindFirstChild("CloseButton", true)
			if cBtn then
				box(cBtn, mw - 67, 18, 44, 44)
				cBtn.ZIndex = 26
			end

			local card1 = modal:FindFirstChild("Card1")
			local card2 = modal:FindFirstChild("Card2")
			local cardGap = 10
			local shortModal = mh < 330
			local cardW = math.min(shortModal and 150 or 185, math.floor((mw - 62 - cardGap) / 2))
			local cardY = shortModal and 57 or 72
			local cardH = shortModal and math.max(206, math.min(236, mh - cardY - 10))
				or math.max(236, math.round(cardW * 1.65))
			local cardX = (mw - cardW * 2 - cardGap) / 2
			modal.CanvasSize = UDim2.fromOffset(0, math.max(mh, cardY + cardH + 40))

			if card1 then
				box(card1, cardX, cardY, cardW, cardH)
				card1.ZIndex = 23
			end
			if card2 then
				box(card2, cardX + cardW + cardGap, cardY, cardW, cardH)
				card2.ZIndex = 23
			end
		end

		if wheel then
			local mw = math.min(340, w - 24)
			local mh = math.min(286, h - 20)
			local row = math.min(54, math.floor((mh - 14) / 5))
			box(wheel, (w - mw) / 2, (h - mh) / 2, mw, mh)
			wheel.ZIndex = 22
			for i = 1, 5 do
				local b = wheel:FindFirstChild("Ping" .. i)
				if b then
					box(b, 8, 7 + (i - 1) * row, mw - 16, row - 4)
					b.ZIndex = 23
				end
			end
		end

		theme.Step()
	end)
end

return Layout
