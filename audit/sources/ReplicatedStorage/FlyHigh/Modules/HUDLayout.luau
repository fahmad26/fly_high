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
	local motion = require(script.Parent.HUDMotion).Start(gui, player)
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
		for _, name in { "ShopModal", "TacticalPingWheel", "WeaponSettingsModal" } do
			local o = get(name)
			if o then require(script.Parent.HUDMotion).SetVisible(o, false) end
		end
		-- Scrim stays active until the closing animation completes.
	end)

	local activeModal
	local elapsed = 1
	local render = game:GetService("RunService")
	local layoutStep = "FlyHighHUDLayout_" .. game:GetService("HttpService"):GenerateGUID(false)
	local connection = {Disconnect = function() render:UnbindFromRenderStep(layoutStep) end}
	render:BindToRenderStep(layoutStep, Enum.RenderPriority.Last.Value + 10, function(dt)
		if not gui.Parent then
			motion.Destroy()
			theme.Destroy()
			connection:Disconnect()
			return
		end

		elapsed = (elapsed or 0) + dt
		if elapsed < 0.04 then return end
		elapsed = 0
		motion.BeforeLayout()

		local w, h = gui.AbsoluteSize.X, gui.AbsoluteSize.Y
		if w < 1 or h < 1 then return end

		local compact = h < 520 or w < 760
		local textBoost = math.min(preferredTextGrowth[guiService.PreferredTextSize] or 0, compact and 3 or 6)
		gui:SetAttribute("HUDTextBoost", textBoost)
		gui:SetAttribute("CompactLayout", compact)
		gui:SetAttribute("TabletLayout", input.TouchEnabled and not compact)
		gui:SetAttribute("HUDDesignVersion", 11)

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
		for _, name in { "EmergencyKitButton", "PingButton", "WarningAudioToggleButton", "ShopToggleButton", "SettingsToggleButton" } do
			local item = get(name)
			if item then
				item.Visible = inFlight or name == "ShopToggleButton" or name == "SettingsToggleButton"
				if item.Visible then
					local moveToTop = input.TouchEnabled and compact and not portrait
						and (name == "ShopToggleButton" or name == "WarningAudioToggleButton" or name == "SettingsToggleButton")
						and topUtilitySpace >= (topSlots + 1) * (tileW + gap)
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
			local shoulderMuzzleX = weaponView:GetAttribute("ShoulderMuzzleX")
			local touchLandscape = shoulderMuzzleX and compact and input.TouchEnabled and not portrait
			local scale = shoulderMuzzleX and 0.86 or 0.68
			if compact and not touchLandscape then scale = weaponView:GetAttribute("CompactScale") end
			local side = math.min(h * scale, w * weaponView:GetAttribute("WidthCap"))
			if shoulderMuzzleX then
				-- Frame the muzzle just right of the reticle and let the stock run below the screen.
				local muzzleX = w * 0.63
				if touchLandscape then
					-- Keep the muzzle above the touch controls on short screens.
					muzzleX = w * 0.69
				elseif compact then
					muzzleX = math.clamp(fireX - 0.33 * side, w * 0.54, w * 0.64)
				end
				local bottomAnchor = touchLandscape and 0.93 or 0.80
				box(weaponView, muzzleX - shoulderMuzzleX * side, h - bottomAnchor * side, side, side)
			else
				local aboveAmmo = ammoAlongsideFire or portrait
				local gunRight = aboveAmmo and fireX or math.min(fireX, ammoX)
				local gunBottom = aboveAmmo and ammoY + 4 or h
				-- Align the visible weapon with the HUD, accounting for viewport padding.
				local gunLeft = gunRight - 8 - weaponView:GetAttribute("RightEdge") * side
				box(weaponView, math.max(0, gunLeft), gunBottom - 0.90 * side, side, side)
			end
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
		local settings = get("WeaponSettingsModal")
		local popups = { modal, wheel, settings }
		local shown = activeModal and activeModal.Visible and activeModal or nil
		for _, popup in popups do
			if popup.Visible and popup ~= activeModal then shown = popup end
		end
		for _, popup in popups do
			if popup ~= shown then popup.Visible = false end
		end
		activeModal = shown
		scrim.Visible = activeModal ~= nil
		local pingOpen = wheel ~= nil and activeModal == wheel
		local topInset, bottomInset = guiService:GetGuiInset()
		local top = pingOpen and topInset or Vector2.zero
		local bottom = pingOpen and bottomInset or Vector2.zero
		scrim.Position = UDim2.fromOffset(-top.X, -top.Y)
		scrim.Size = UDim2.new(1, top.X + bottom.X, 1, top.Y + bottom.Y)
		scrimImage.Visible = not pingOpen
		scrim.BackgroundTransparency = not pingOpen and scrimImage.IsLoaded and 1 or 0.35
		if settings then
			local mw, mh = math.min(448, w - 24), math.min(374, h - 16)
			box(settings, (w - mw) / 2, (h - mh) / 2, mw, mh)
			-- Align the controls inside the artwork's navy area, below the compass.
			local pad = math.round(mw * .13)
			local innerWidth = mw - pad * 2
			local innerTop, innerBottom = math.round(mh * .22), math.round(mh * .82)
			local available = innerBottom - innerTop
			local short = available < 243
			local titleH, inventoryH = short and 22 or 25, short and 18 or 20
			local sectionGap, rowGap = short and 5 or 10, short and 5 or 8
			local footerH = short and 26 or 30
			local contentH = titleH + inventoryH + sectionGap * 2 + 44 * 3 + rowGap * 2 + footerH
			local top = innerTop + math.max(0, math.floor((available - contentH) / 2))
			box(settings:FindFirstChild("Title"), pad, top, innerWidth, titleH)
			box(settings:FindFirstChild("SettingsCloseButton"), mw - pad - 32, math.round(mh * .10), 44, 44)
			box(settings:FindFirstChild("InventoryCount"), pad, top + titleH, innerWidth, inventoryH)
			local labelW = 49
			local choiceW = math.floor((innerWidth - labelW - 8) / 2)
			local firstRow = top + titleH + inventoryH + sectionGap
			for slot = 1, 2 do
				local row = firstRow + (slot - 1) * (44 + rowGap)
				box(settings:FindFirstChild("SlotLabel" .. slot), pad, row, labelW, 44)
				box(settings:FindFirstChild("HandgunSlot" .. slot), pad + labelW, row, choiceW, 44)
				box(settings:FindFirstChild("AK47Slot" .. slot), pad + labelW + choiceW + 8, row, choiceW, 44)
			end
			local labelRow = firstRow + 2 * (44 + rowGap)
			local labelsTitle = settings:FindFirstChild("PlayerLabelsLabel")
			if labelsTitle then labelsTitle.Visible = false end
			local generalW = math.floor((innerWidth - 8) / 2)
			box(settings:FindFirstChild("ReduceMotionToggle"), pad + generalW + 8, labelRow, generalW, 44)
			box(settings:FindFirstChild("PlayerLabelsToggle"), pad, labelRow, generalW, 44)
			local footerY = labelRow + 44 + sectionGap
			box(settings:FindFirstChild("LaunchNote"), pad, footerY, innerWidth, footerH)
			box(settings:FindFirstChild("SettingsFeedback"), pad, footerY, innerWidth, footerH)
		end

		if modal then
			local mw = math.min(w - 24, 610)
			local mh = math.min(h - 16, 430)
			box(modal, (w - mw) / 2, (h - mh) / 2, mw, mh)
			modal.ZIndex = 22

			local cBtn = modal:FindFirstChild("CloseButton", true)
			if cBtn then
				box(cBtn, mw - math.round(mw * .11) - 28, math.round(mh * .065), 44, 44)
				cBtn.ZIndex = 26
			end

			local card1 = modal:FindFirstChild("Card1")
			local card2 = modal:FindFirstChild("Card2")
			local cardGap = math.max(10, math.round(mw * .025))
			local cardY = math.max(52, math.round(mh * .205))
			local cardH = mh - cardY - math.max(44, math.round(mh * .15))
			local cardW = math.min(208, math.round(cardH * .75), math.floor((mw * .78 - cardGap) / 2))
			local cardX = (mw - cardW * 2 - cardGap) / 2

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
			local columns = h < 416 and w >= 360 and 2 or 1
			local mh = math.min(420, h - 20)
			local mw = math.min(columns == 2 and math.round(mh * 1.45) or 382, w - 24)
			box(wheel, (w - mw) / 2, (h - mh) / 2, mw, mh)
			wheel.ZIndex = 22

			local pad = math.ceil(mw * 0.11)
			local header = math.ceil(mh * 0.23)
			local title = wheel:FindFirstChild("PingTitle")
			local close = wheel:FindFirstChild("PingCloseButton")
			box(title, pad, header, mw - 2 * pad - 50, 24)
			box(close, mw - pad - 44, header - 24, 44, 44)
			if title then title.ZIndex = 24 end
			if close then close.ZIndex = 25 end

			local firstRow = header + 27
			local rows = math.ceil(5 / columns)
			local gap = 4
			local rowHeight = math.floor((math.floor(mh * 0.90) - firstRow - (rows - 1) * gap) / rows)
			local rowWidth = math.floor((mw - 2 * pad - (columns - 1) * gap) / columns)
			for i = 1, 5 do
				local b = wheel:FindFirstChild("Ping" .. i)
				if b then
					local column = (i - 1) % columns
					local row = math.floor((i - 1) / columns)
					local width = columns == 2 and i == 5 and mw - 2 * pad or rowWidth
					box(b, pad + column * (rowWidth + gap), firstRow + row * (rowHeight + gap), width, rowHeight)
					b.ZIndex = 23
				end
			end
		end

		theme.Step()
		motion.Capture()
	end)
end

return Layout
