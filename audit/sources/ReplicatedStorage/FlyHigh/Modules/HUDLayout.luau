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
	gui.ClipToDeviceSafeArea = false

	local scrim = Instance.new("TextButton")
	scrim.Name = "HUDModalScrim"
	scrim.Text = ""
	scrim.AutoButtonColor = false
	scrim.Selectable = false
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

	local function syncScrimBounds(w, h)
		local topInset, bottomInset = guiService:GetGuiInset()
		local cam = workspace.CurrentCamera
		local vp = cam and cam.ViewportSize or Vector2.new(w, h)
		local extraX = w > 0 and math.max(0, vp.X - w - topInset.X - bottomInset.X) or 0
		local extraY = h > 0 and math.max(0, vp.Y - h - topInset.Y - bottomInset.Y) or 0
		local leftPad = topInset.X + math.floor(extraX * 0.5)
		local rightPad = bottomInset.X + math.ceil(extraX * 0.5)
		local topPad = topInset.Y + math.floor(extraY * 0.5)
		local bottomPad = bottomInset.Y + math.ceil(extraY * 0.5)
		scrim.Position = UDim2.fromOffset(-leftPad, -topPad)
		scrim.Size = UDim2.new(1, leftPad + rightPad, 1, topPad + bottomPad)
		scrimImage.Visible = false
		scrim.BackgroundTransparency = 0.35
	end
	syncScrimBounds(gui.AbsoluteSize.X, gui.AbsoluteSize.Y)

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

		local qaSize = gui:GetAttribute("QA_ViewportSize")
		local w, h = gui.AbsoluteSize.X, gui.AbsoluteSize.Y
		if typeof(qaSize) == "Vector2" and qaSize.X > 0 and qaSize.Y > 0 then
			w, h = qaSize.X, qaSize.Y
		end
		if w < 1 or h < 1 then return end
		local qaTouch = gui:GetAttribute("QA_Touch")
		local touchEnabled = if typeof(qaTouch) == "boolean" then qaTouch else input.TouchEnabled

		local compact = h < 520 or w < 760
		local textBoost = math.min(preferredTextGrowth[guiService.PreferredTextSize] or 0, compact and 3 or 6)
		gui:SetAttribute("HUDTextBoost", textBoost)
		gui:SetAttribute("CompactLayout", compact)
		gui:SetAttribute("TabletLayout", touchEnabled and not compact)
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
		local touchUtilityGutter = touchEnabled and compact and not portrait and w >= 680 and h >= 300
		local utilityRight = touchUtilityGutter and fireX - 8 or right

		-- 1. Altitude / Zone Capsule (Top Center Option B Hero HUD)
		local altY = 8
		local topW = inFlight
			and math.min(w - 2 * margin, math.clamp(w * 0.34, 340, 412) + 8 * textBoost)
			or math.min(w - 2 * margin, math.clamp(w * 0.30, 300, 376) + 8 * textBoost)
		local topH = (topW < 340 and inFlight and 62 or 58) + 2 * textBoost
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

		local tileH = (compact and 54 or 58) + textBoost
		local gap = 8
		local navY = portrait and warningY + 68 or (wide and statusY + statusH + 8 or statusY)
		if not inFlight then navY = headerBottom + 12 end
		local slot = 0
		local topSlots = 0
		local topUtilitySpace = (w - topW) / 2 - margin
		local maxRows = math.max(1, math.floor((h - navY - 12 + gap) / (tileH + gap)))
		local dockOrder = {
			"DailyToggleButton",
			"EmergencyKitButton",
			"TurboGasButton",
			"RopeBuffButton",
			"PingButton",
			"WarningAudioToggleButton",
			"ShopToggleButton",
			"SettingsToggleButton",
		}
		for _, name in dockOrder do
			local item = get(name)
			if item then
				local isVisible
				if name == "DailyToggleButton" then
					isVisible = not inFlight
				elseif name == "TurboGasButton" or name == "RopeBuffButton" then
					isVisible = inFlight and item:GetAttribute("HUDAvailable") == true
				else
					isVisible = inFlight or name == "ShopToggleButton" or name == "SettingsToggleButton" or name == "WarningAudioToggleButton"
				end
				item.Visible = isVisible
				if isVisible then
					local moveToTop = touchEnabled and compact and not portrait
						and (name == "ShopToggleButton" or name == "WarningAudioToggleButton" or name == "SettingsToggleButton")
						and topUtilitySpace >= (topSlots + 1) * (tileW + gap)
					if moveToTop then
						place(name, w - margin - tileW - topSlots * (tileW + gap), altY, tileW, tileH)
						topSlots += 1
					else
						local col = math.floor(slot / maxRows)
						local row = slot % maxRows
						place(name, margin + col * (tileW + gap), navY + row * (tileH + gap), tileW, tileH)
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
			local touchLandscape = shoulderMuzzleX and compact and touchEnabled and not portrait
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

		local ghostFrame = place("GhostSpotterFrame", warningX, warningY + 68, math.min(320, warningW), 60)

		-- 11. Crew Tactical Ping & Ghost Spot Banner
		local pingBanner = get("CrewPingBanner")
		if pingBanner then
			local expiresAt = pingBanner:GetAttribute("PingExpiresAt") or 0
			if not inFlight or (expiresAt > 0 and os.clock() >= expiresAt) then
				if pingBanner.Visible and pingBanner:GetAttribute("HUDMotionClosing") ~= true then
					require(script.Parent.HUDMotion).SetVisible(pingBanner, false)
				elseif not inFlight then
					pingBanner.Visible = false
				end
			end
			local activeWarnH = ((storm and storm.Visible) or (alert and alert.Visible)) and 68
				or ((notice and notice.Visible) and (46 + textBoost) or 0)
			if ghostFrame and ghostFrame.Visible then
				activeWarnH = math.max(activeWarnH, 68) + 68
			end
			local pingH = (compact and 52 or 56) + textBoost
			local pingW, pingX, pingY
			local besideRight = not wide and not portrait and (w - (statusX + statusW + 10) - margin) >= 240
			if besideRight then
				local availW = w - (statusX + statusW + 10) - margin
				pingW = math.min(340, availW)
				pingX = statusX + statusW + 10
				pingY = statusY + math.round((statusH - pingH) / 2)
			elseif portrait then
				local startX = activeWarnH > 0 and (margin + tileW + 10) or margin
				pingW = math.max(200, w - startX - margin)
				pingX = startX
				pingY = warningY + activeWarnH
			else
				pingW = math.min(380, warningW)
				pingX = wide and math.round((w - pingW) / 2) or warningX
				pingY = warningY + activeWarnH
			end
			local toast = get("HUDMotionToast")
			if not besideRight and toast and toast.Visible then
				local toastBottom = toast.AbsolutePosition.Y + toast.AbsoluteSize.Y - gui.AbsolutePosition.Y
				if toast.AbsoluteSize.Y > 4 and pingY < toastBottom + 8 then
					pingY = toastBottom + 8
				end
			end
			if portrait and pingY + pingH > warningY + 64 then
				pingX = math.max(pingX, margin + tileW + 10)
				pingW = math.max(180, w - pingX - margin)
			end
			box(pingBanner, pingX, pingY, pingW, pingH)
			pingBanner.ZIndex = 16
		end

		-- 12. Modals (ShopModal, WeaponSettingsModal, AudioSettingsModal & TacticalPingWheel)
		local modal = get("ShopModal")
		local wheel = get("TacticalPingWheel")
		local settings = get("WeaponSettingsModal")
		local audioModal = get("AudioSettingsModal")
		-- 10. Right-Side Vertical Server Altitude Tracker (All-flyers, non-overlapping across devices)
		local tracker = get("ServerAltitudeTracker")
		if tracker then
			tracker.Visible = inFlight
			if inFlight then
				local smallScreen = compact or w < 760
				local avatarSize = portrait and 22 or (smallScreen and (h < 420 and 20 or 24) or 30)
				local avatarGap = (portrait or smallScreen) and 3 or 5
				local crownH = math.max(9, math.round(avatarSize * 0.45))
				local stemW = (portrait or smallScreen) and 10 or 14
				local railOuterW = compact and 18 or 22
				local pillHalfW = (compact or portrait) and (39 + textBoost) or (44 + textBoost)
				local trackerW = pillHalfW + math.ceil(railOuterW / 2) + stemW + 6 + 3 * avatarSize + 2 * avatarGap + 4
				local bandLeft = w - margin - trackerW

				local safeTop = portrait and navY or (altY + 6)
				for _, topBlocker in {
					"AltimeterFrame", "StatusFrame", "AlertBanner", "StormChallengePanel",
					"GroundedCountdown", "CrewPingBanner", "GhostSpotterFrame",
					"ShopToggleButton", "WarningAudioToggleButton", "SettingsToggleButton",
					"EmergencyKitButton", "PingButton",
				} do
					local obj = get(topBlocker)
					if obj and obj.Visible then
						local ox = obj.Position.X.Offset
						local oy = obj.Position.Y.Offset
						local ow = obj.Size.X.Offset
						local oh = obj.Size.Y.Offset
						if ow > 0 and oh > 0 and ox + ow > bandLeft - 8 and ox < w and (oy + oh) <= h * 0.62 then
							safeTop = math.max(safeTop, oy + oh + 8)
						end
					end
				end

				local safeBottom = h - math.max(jumpSize + jumpMarginB, touchEnabled and (fireSize + jumpMarginB) or 0) - 12
				local botBlockers = {
					"JumpPanel", "MobileShootButton", "ReloadButton", "DropButton",
					"WeaponFrame", "GasButton", "AutoGasButton", "ReleaseHelmButton", "TetherFrame",
				}
				for _, name in rigging do
					table.insert(botBlockers, name)
				end
				for _, botName in botBlockers do
					local obj = get(botName)
					if obj and obj.Visible then
						local ox = obj.Position.X.Offset
						local oy = obj.Position.Y.Offset
						local ow = obj.Size.X.Offset
						local oh = obj.Size.Y.Offset
						if ow > 0 and oh > 0 and ox + ow > bandLeft - 8 and ox < w and oy >= altY + topH + 16 then
							safeBottom = math.min(safeBottom, oy - 10)
						end
					end
				end

				local maxTrackerH = (compact or portrait) and 320 or 430
				local availH = safeBottom - safeTop
				local minTrackerH = 72
				local trackerH
				if availH < minTrackerH then
					safeTop = math.max(altY + 4, safeBottom - minTrackerH)
					trackerH = math.max(60, safeBottom - safeTop)
				else
					trackerH = math.min(maxTrackerH, availH)
				end
				if trackerH < 135 and avatarSize > 20 then
					avatarSize = 20
					crownH = 9
				end
				tracker:SetAttribute("AvatarSize", avatarSize)
				tracker:SetAttribute("AvatarGap", avatarGap)
				tracker:SetAttribute("CrownHeight", crownH)
				tracker:SetAttribute("StemWidth", stemW)
				place("ServerAltitudeTracker", bandLeft, safeTop, trackerW, trackerH)
				tracker.ZIndex = 6
			end
		end

		local popups = {}
		for _, name in { "DailyLoginModal", "ShopModal", "TacticalPingWheel", "WeaponSettingsModal", "AudioSettingsModal" } do
			local popup = get(name)
			if popup then table.insert(popups, popup) end
		end
		local dailyModal = get("DailyLoginModal")
		local shown = activeModal and activeModal.Visible and activeModal or nil
		for _, popup in popups do
			if popup.Visible and popup ~= activeModal then shown = popup end
		end
		for _, popup in popups do
			if popup ~= shown then popup.Visible = false end
		end
		activeModal = shown
		scrim.Visible = activeModal ~= nil
		syncScrimBounds(w, h)
		local function placeModalFrame(popup, targetW, targetH, closeName)
			local topReserve = h < 420 and 28 or 34
			local mw = math.min(w - 24, targetW)
			local mh = math.min(h - topReserve - 12, targetH)
			local mx = (w - mw) / 2
			local my = topReserve + math.max(0, math.floor((h - topReserve - 12 - mh) / 2))
			box(popup, mx, my, mw, mh)
			popup.ZIndex = 22
			popup.ClipsDescendants = false

			local closeBtn = closeName and popup:FindFirstChild(closeName, true)
			if closeBtn then
				box(closeBtn, mw - 40, -2, 44, 44)
				closeBtn.ZIndex = 28
			end
			local padX = math.clamp(math.round(mw * 0.056), 18, 30)
			local topPad = h < 420 and 42 or 48
			local bottomPad = h < 420 and 18 or 26
			return mw, mh, padX, topPad, bottomPad
		end

		if settings then
			local mw, mh, pad, topPad, bottomPad = placeModalFrame(settings, 500, 448, "SettingsCloseButton")
			local innerWidth = mw - pad * 2
			local innerTop, innerBottom = topPad, mh - bottomPad
			local available = innerBottom - innerTop
			local tight = available < 285
			local titleH = tight and 22 or 26
			local titleGap = tight and 3 or 5
			local inventoryH = tight and 20 or 24
			local sectionGap = tight and 6 or 12
			local rowGap = tight and 5 or 10
			local footerH = tight and 22 or 30
			local prefGap = tight and 6 or 12
			local toggleH = math.max(44, math.min(48, available - (titleH + titleGap + inventoryH + sectionGap + prefGap + sectionGap + footerH + rowGap + 2 * 44) - (tight and 6 or 12)))
			local rackH = math.clamp(math.floor((available - (titleH + titleGap + inventoryH + sectionGap + prefGap + toggleH + sectionGap + footerH + rowGap)) / 2), 48, 60)
			local rowH = tight and 44 or 46
			local contentH = titleH + titleGap + inventoryH + sectionGap + rackH * 2 + rowGap + prefGap + toggleH + sectionGap + footerH
			local top = innerTop + math.max(0, math.floor((available - contentH) / 2))

			box(settings:FindFirstChild("Title"), pad, top, innerWidth, titleH)
			local invY = top + titleH + titleGap
			local invPillW = math.min(innerWidth, 300)
			box(settings:FindFirstChild("HUDInventoryPill"), (mw - invPillW) / 2, invY, invPillW, inventoryH)
			box(settings:FindFirstChild("InventoryCount"), (mw - invPillW) / 2 + 8, invY, invPillW - 16, inventoryH)

			local rowInnerPad = tight and 8 or 14
			local labelW = math.clamp(46 + textBoost, 46, 62)
			local labelGap = 8
			local colGap = tight and 8 or 12
			local choiceAreaX = pad + rowInnerPad + labelW + labelGap
			local choiceW = math.floor((innerWidth - rowInnerPad * 2 - labelW - labelGap - colGap) / 2)
			local firstRackY = invY + inventoryH + sectionGap
			for slot = 1, 2 do
				local ry = firstRackY + (slot - 1) * (rackH + rowGap)
				local btnY = ry + math.floor((rackH - rowH) / 2)
				box(settings:FindFirstChild("HUDRackRow" .. slot), pad, ry, innerWidth, rackH)
				box(settings:FindFirstChild("SlotLabel" .. slot), pad + rowInnerPad, btnY, labelW, rowH)
				box(settings:FindFirstChild("HandgunSlot" .. slot), choiceAreaX, btnY, choiceW, rowH)
				box(settings:FindFirstChild("AK47Slot" .. slot), choiceAreaX + choiceW + colGap, btnY, choiceW, rowH)
			end
			local divY = firstRackY + 2 * rackH + rowGap + math.floor(prefGap / 2)
			box(settings:FindFirstChild("HUDWeaponDivider"), pad + 8, divY, innerWidth - 16, 1)

			local labelRow = firstRackY + 2 * rackH + rowGap + prefGap
			local labelsTitle = settings:FindFirstChild("PlayerLabelsLabel")
			if labelsTitle then labelsTitle.Visible = false end
			local generalW = math.floor((innerWidth - colGap) / 2)
			box(settings:FindFirstChild("PlayerLabelsToggle"), pad, labelRow, generalW, toggleH)
			box(settings:FindFirstChild("ReduceMotionToggle"), pad + generalW + colGap, labelRow, generalW, toggleH)

			local footerY = labelRow + toggleH + sectionGap
			local footerW = math.min(innerWidth, 340)
			box(settings:FindFirstChild("HUDWeaponFooterPill"), (mw - footerW) / 2, footerY, footerW, footerH)
			box(settings:FindFirstChild("LaunchNote"), (mw - footerW) / 2 + 10, footerY, footerW - 20, footerH)
			box(settings:FindFirstChild("SettingsFeedback"), (mw - footerW) / 2 + 10, footerY, footerW - 20, footerH)
		end

		if audioModal then
			local mw, mh, pad, topPad, bottomPad = placeModalFrame(audioModal, 500, 448, "AudioCloseButton")
			local innerWidth = mw - pad * 2
			local innerTop, innerBottom = topPad, mh - bottomPad
			local available = innerBottom - innerTop
			local tight = available < 275
			local titleH = tight and 22 or 26
			local subH = tight and 15 or 18
			local headerGap = tight and 6 or 12
			local rowGap = tight and 6 or 10
			local showFooter = available >= 255
			local footerGap = showFooter and (tight and 6 or 10) or 0
			local footerH = showFooter and 18 or 0
			local rowH = math.clamp(math.floor((available - titleH - 3 - subH - headerGap - footerGap - footerH - rowGap * 2) / 3), 50, 66)
			local contentH = titleH + 3 + subH + headerGap + rowH * 3 + rowGap * 2 + footerGap + footerH
			local top = innerTop + math.max(0, math.floor((available - contentH) / 2))

			box(audioModal:FindFirstChild("AudioTitle"), pad, top, innerWidth, titleH)
			box(audioModal:FindFirstChild("AudioSubtitle"), pad, top + titleH + 3, innerWidth, subH)

			local muteSize = 44
			local firstRow = top + titleH + 3 + subH + headerGap
			for i, key in { "Master", "Music", "SFX" } do
				local row = audioModal:FindFirstChild("AudioRow" .. key)
				if row then
					local ry = firstRow + (i - 1) * (rowH + rowGap)
					box(row, pad, ry, innerWidth, rowH)
					local leftPad = 14
					local rightPad = 12
					local gapX = 16
					local leftW = math.max(80, innerWidth - leftPad - muteSize - gapX - rightPad)
					local valueW = math.clamp(56 + textBoost, 52, 74)
					local lblH = tight and 15 or 18
					local lblY = math.max(4, math.min(8, math.floor((rowH - 44) / 2)))
					box(row:FindFirstChild("ChannelLabel"), leftPad, lblY, math.max(40, leftW - valueW - 6), lblH)
					box(row:FindFirstChild("ChannelValue"), leftPad + leftW - valueW, lblY, valueW, lblH)
					local hitH = math.min(rowH, 44)
					box(row:FindFirstChild("SliderHit"), leftPad, rowH - hitH, leftW, hitH)
					local track = row:FindFirstChild("SliderTrack", true)
					if track then
						local bottomPadTrack = math.max(6, math.floor((rowH - (lblY + lblH) - 12) / 2))
						track.AnchorPoint = Vector2.new(0, 1)
						track.Position = UDim2.new(0, 0, 1, -bottomPadTrack)
						track.Size = UDim2.new(1, 0, 0, 12)
					end
					box(row:FindFirstChild("AudioMute" .. key), innerWidth - rightPad - muteSize, math.floor((rowH - muteSize) / 2), muteSize, muteSize)
				end
			end
			local footerHint = audioModal:FindFirstChild("AudioFooterHint")
			if footerHint then
				footerHint.Visible = showFooter
				box(footerHint, pad, firstRow + rowH * 3 + rowGap * 2 + footerGap, innerWidth, footerH)
			end
		end

		if modal then
			local phoneStack = w < 540 and h >= 430
			local targetW = phoneStack and 392 or 620
			local targetH = phoneStack and 576 or 528
			local mw, mh, pad, topPad, bottomPad = placeModalFrame(modal, targetW, targetH, "CloseButton")
			local innerW = mw - pad * 2
			local available = mh - topPad - bottomPad
			local tight = available < 310
			local titleH = tight and 22 or 26
			local subH = tight and 0 or 16
			local twoRowToolbar = mw < 460
			local toolbarH = twoRowToolbar and 60 or 34
			local headerGap = tight and 6 or 10
			local footerGap = tight and 5 or 8
			local footerH = 20

			modal:SetAttribute("HUDCompactCard", phoneStack or mh < 380)
			box(modal:FindFirstChild("ModalTitle"), pad, topPad, innerW, titleH)
			local sub = modal:FindFirstChild("ShopSubtitle")
			if sub then
				sub.Visible = subH > 0
				box(sub, pad, topPad + titleH + 2, innerW, subH)
			end

			local toolbarY = topPad + titleH + (subH > 0 and (2 + subH) or 0) + 6
			local toolbar = modal:FindFirstChild("ShopToolbar")
			if toolbar then
				box(toolbar, pad, toolbarY, innerW, toolbarH)
				toolbar.ZIndex = 24
				local tabsBar = toolbar:FindFirstChild("TabButtonsBar")
				local coinPill = toolbar:FindFirstChild("ShopCoinPill")
				if twoRowToolbar then
					if tabsBar then box(tabsBar, 0, 0, innerW, 32) end
					if coinPill then box(coinPill, math.floor((innerW - 124) / 2), 36, 124, 24) end
				else
					local pillW = 128
					if tabsBar then box(tabsBar, 0, 0, math.max(180, innerW - pillW - 10), 34) end
					if coinPill then box(coinPill, innerW - pillW, 4, pillW, 26) end
				end
			end

			local cardY = toolbarY + toolbarH + headerGap
			local cardAreaH = math.max(120, (mh - bottomPad - footerH - footerGap) - cardY)
			local card1 = modal:FindFirstChild("Card1")
			local card2 = modal:FindFirstChild("Card2")
			local activeTab = modal:GetAttribute("ActiveShopTab") or "robux"

			if card1 then card1.Visible = (activeTab == "robux") end
			if card2 then card2.Visible = (activeTab == "robux") end

			if phoneStack then
				local cardGap = 10
				local cardH = math.floor((cardAreaH - cardGap) / 2)
				if card1 then
					box(card1, pad, cardY, innerW, cardH)
					card1.ZIndex = 23
				end
				if card2 then
					box(card2, pad, cardY + cardH + cardGap, innerW, cardH)
					card2.ZIndex = 23
				end
			else
				local cardGap = math.max(12, math.round(mw * .026))
				local cardW = math.floor((innerW - cardGap) / 2)
				if card1 then
					box(card1, pad, cardY, cardW, cardAreaH)
					card1.ZIndex = 23
				end
				if card2 then
					box(card2, pad + cardW + cardGap, cardY, cardW, cardAreaH)
					card2.ZIndex = 23
				end
			end

			local supplies = modal:FindFirstChild("SuppliesContainer")
			if supplies then
				supplies.Visible = (activeTab == "perbekalan")
				box(supplies, pad, cardY, innerW, cardAreaH)
				supplies.ZIndex = 23
			end
			local cosScroll = modal:FindFirstChild("CosmeticsScroll")
			if cosScroll then
				cosScroll.Visible = (activeTab == "kosmetik")
				box(cosScroll, pad, cardY, innerW, cardAreaH)
				cosScroll.ZIndex = 23
			end

			local fb = modal:FindFirstChild("ShopFeedback")
			if fb then
				box(fb, pad, mh - bottomPad - footerH, innerW, footerH)
				fb.ZIndex = 24
			end
		end

		if dailyModal then
			local phoneStack = w < 540 and h >= 430
			local targetW = phoneStack and 392 or 680
			local targetH = phoneStack and 536 or 520
			local mw, mh, pad, topPad, bottomPad = placeModalFrame(dailyModal, targetW, targetH, "DailyCloseButton")
			local innerW = mw - pad * 2
			local available = mh - topPad - bottomPad
			local tight = available < 310
			local titleH = tight and 22 or 26
			local stackedHead = mw < 470
			local infoH = stackedHead and 44 or 26
			local ctaH = 44
			local footerH = tight and 14 or 18
			local gapA = tight and 4 or 8
			local gapB = tight and 6 or 10

			box(dailyModal:FindFirstChild("DailyTitle"), pad, topPad, innerW, titleH)
			local coinPill = dailyModal:FindFirstChild("DailyCoinPill")
			local dSub = dailyModal:FindFirstChild("DailySubtitle")
			local infoY = topPad + titleH + 3
			if stackedHead then
				if coinPill then box(coinPill, math.floor((mw - 122) / 2), infoY, 122, 24) end
				if dSub then
					dSub.Visible = true
					box(dSub, pad, infoY + 26, innerW, 16)
					dSub.TextXAlignment = Enum.TextXAlignment.Center
				end
			else
				local pillW = 128
				if coinPill then box(coinPill, mw - pad - pillW, infoY, pillW, 26) end
				if dSub then
					dSub.Visible = true
					box(dSub, pad, infoY + 4, math.max(120, innerW - pillW - 10), 18)
					dSub.TextXAlignment = Enum.TextXAlignment.Left
				end
			end

			local gridY = infoY + infoH + gapA
			local gridH = math.max(130, (mh - bottomPad - footerH - ctaH - gapB - 4) - gridY)
			local grid = dailyModal:FindFirstChild("DailyCardsContainer")
			if grid then
				box(grid, pad, gridY, innerW, gridH)
				local landscape2Row = gridH < 250 and innerW >= 500
				if landscape2Row then
					local colGap, rowGap = 8, 8
					local colW = math.floor((innerW - colGap * 3) / 4)
					local rowH = math.floor((gridH - rowGap) / 2)
					for day = 1, 7 do
						local card = grid:FindFirstChild("DayCard" .. day)
						if card then
							local col = day <= 4 and (day - 1) or (day == 5 and 0 or (day == 6 and 1 or 2))
							local row = day <= 4 and 0 or 1
							local cw = day == 7 and (colW * 2 + colGap) or colW
							box(card, col * (colW + colGap), row * (rowH + rowGap), cw, rowH)
							local dayPill = card:FindFirstChild("DayPill")
							local st = card:FindFirstChild("StatusTag")
							local art = card:FindFirstChild("RewardArt")
							local pri = card:FindFirstChild("RewardPrimary")
							local sub = card:FindFirstChild("RewardSub")
							if dayPill then box(dayPill, 8, 6, 46, 16) end
							if st then box(st, 58, 6, cw - 66, 16) end
							local dayText = dayPill and dayPill:FindFirstChild("DayText")
							if dayText then dayText.Text = "HARI " .. tostring(day) end
							if day == 7 then
								if art then box(art, 8, 25, 68, math.max(36, rowH - 32)) end
								if pri then box(pri, 84, 24, cw - 92, 20) pri.TextXAlignment = Enum.TextXAlignment.Left end
								if sub then box(sub, 84, 46, cw - 92, math.max(18, rowH - 50)) sub.TextXAlignment = Enum.TextXAlignment.Left end
							else
								local artH = math.clamp(rowH - 58, 22, 34)
								if art then box(art, math.floor((cw - artH) / 2), 22, artH, artH) end
								if pri then box(pri, 5, 23 + artH, cw - 10, 15) pri.TextXAlignment = Enum.TextXAlignment.Center end
								if sub then box(sub, 5, 38 + artH, cw - 10, math.max(13, rowH - (42 + artH))) sub.TextXAlignment = Enum.TextXAlignment.Center end
							end
						end
					end
				else
					local colGap = phoneStack and 7 or 10
					local rowGap = phoneStack and 7 or 9
					local rowH = math.floor((gridH - rowGap * 2) / 3)
					local smallW = math.floor((innerW - colGap * 2) / 3)
					for day = 1, 6 do
						local card = grid:FindFirstChild("DayCard" .. day)
						if card then
							local rIdx = day <= 3 and 0 or 1
							local cIdx = (day - 1) % 3
							box(card, cIdx * (smallW + colGap), rIdx * (rowH + rowGap), smallW, rowH)
							local dayPill = card:FindFirstChild("DayPill")
							local st = card:FindFirstChild("StatusTag")
							local art = card:FindFirstChild("RewardArt")
							local pri = card:FindFirstChild("RewardPrimary")
							local sub = card:FindFirstChild("RewardSub")
							local compactDays = phoneStack or smallW < 116
							local pillW = compactDays and 30 or 48
							local stX = 6 + pillW + 4
							if dayPill then box(dayPill, 6, 6, pillW, 16) end
							if st then box(st, stX, 6, smallW - stX - 6, 16) end
							local dayText = dayPill and dayPill:FindFirstChild("DayText")
							if dayText then dayText.Text = (compactDays and "H" or "HARI ") .. tostring(day) end
							local artSize = math.clamp(rowH - 58, 32, phoneStack and 48 or 56)
							if art then box(art, math.floor((smallW - artSize * 1.15) / 2), 25, math.round(artSize * 1.15), artSize) end
							local textTop = 27 + artSize
							local priH = phoneStack and 15 or 16
							if pri then box(pri, 5, textTop, smallW - 10, priH) pri.TextXAlignment = Enum.TextXAlignment.Center end
							if sub then box(sub, 5, textTop + priH, smallW - 10, math.max(13, rowH - textTop - priH - 3)) sub.TextXAlignment = Enum.TextXAlignment.Center end
						end
					end
					local card7 = grid:FindFirstChild("DayCard7")
					if card7 then
						box(card7, 0, (rowH + rowGap) * 2, innerW, gridH - (rowH + rowGap) * 2)
						local c7h = gridH - (rowH + rowGap) * 2
						local dayPill = card7:FindFirstChild("DayPill")
						local st = card7:FindFirstChild("StatusTag")
						local art = card7:FindFirstChild("RewardArt")
						local pri = card7:FindFirstChild("RewardPrimary")
						local sub = card7:FindFirstChild("RewardSub")
						local artW = math.clamp(c7h - 14, 52, phoneStack and 68 or 96)
						if art then box(art, 10, math.floor((c7h - artW) / 2), artW, artW) end
						local tx = 18 + artW
						local tw = math.max(90, innerW - tx - 10)
						if dayPill then box(dayPill, tx, 8, 56, 17) end
						if st then box(st, tx + 60, 8, tw - 60, 17) end
						if pri then box(pri, tx, 28, tw, 24) pri.TextXAlignment = Enum.TextXAlignment.Left end
						if sub then box(sub, tx, 52, tw, math.max(16, c7h - 58)) sub.TextXAlignment = Enum.TextXAlignment.Left end
					end
				end
			end

			local claimBtn = dailyModal:FindFirstChild("ClaimDailyButton")
			if claimBtn then
				box(claimBtn, pad, mh - bottomPad - footerH - ctaH - 4, innerW, ctaH)
				claimBtn.ZIndex = 24
			end
			local footerLbl = dailyModal:FindFirstChild("DailyFooterNote")
			if footerLbl then
				box(footerLbl, pad, mh - bottomPad - footerH, innerW, footerH)
				footerLbl.ZIndex = 24
			end
		end

		if wheel then
			local columns = h < 420 and w >= 520 and 2 or 1
			local targetW = columns == 2 and 620 or 460
			local targetH = columns == 2 and 344 or 476
			local mw, mh, pad, topPad, bottomPad = placeModalFrame(wheel, targetW, targetH, "PingCloseButton")
			local innerW = mw - pad * 2
			local available = mh - topPad - bottomPad
			local tight = available < 260
			local titleH = tight and 22 or 26
			local subH = tight and 0 or 18
			local headerGap = tight and 6 or 12
			local showFooter = available >= 280
			local footerGap = showFooter and 8 or 0
			local footerH = showFooter and 18 or 0

			local title = wheel:FindFirstChild("PingTitle")
			box(title, pad, topPad, innerW, titleH)
			if title then title.ZIndex = 24 end
			local pSub = wheel:FindFirstChild("PingSubtitle")
			if pSub then
				pSub.Visible = subH > 0
				box(pSub, pad, topPad + titleH + 2, innerW, subH)
				pSub.ZIndex = 24
			end

			local firstRow = topPad + titleH + (subH > 0 and (2 + subH) or 0) + headerGap
			local rows = math.ceil(5 / columns)
			local gap = columns == 2 and 8 or (tight and 6 or 9)
			local bottomLimit = mh - bottomPad - footerH - footerGap
			local rowHeight = math.clamp(math.floor((bottomLimit - firstRow - (rows - 1) * gap) / rows), 44, 54)
			local rowWidth = math.floor((innerW - (columns - 1) * gap) / columns)
			for i = 1, 5 do
				local b = wheel:FindFirstChild("Ping" .. i)
				if b then
					local column = (i - 1) % columns
					local row = math.floor((i - 1) / columns)
					local width = columns == 2 and i == 5 and innerW or rowWidth
					box(b, pad + column * (rowWidth + gap), firstRow + row * (rowHeight + gap), width, rowHeight)
					b.ZIndex = 23
				end
			end
			local pFooter = wheel:FindFirstChild("PingFooterHint")
			if pFooter then
				pFooter.Visible = showFooter
				box(pFooter, pad, firstRow + rows * rowHeight + (rows - 1) * gap + footerGap, innerW, footerH)
				pFooter.ZIndex = 24
			end
		end

		theme.Step()
		motion.Capture()
	end)
end

return Layout
