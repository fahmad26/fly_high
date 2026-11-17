-- Client-side visual and spatial audio effects for Emergency Kit and Turbo Gas on flight balloons.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local ContentProvider = game:GetService("ContentProvider")
local Lighting = game:GetService("Lighting")

local AudioMixer = require(RS.FlyHigh.Modules.AudioMixer)

local BalloonVFX = {}

local TEX_FIRE = "rbxasset://textures/particles/fire_main.dds"
local TEX_SPARKS = "rbxasset://textures/particles/sparkles_main.dds"
local TEX_SMOKE = "rbxasset://textures/particles/smoke_main.dds"

local SFX_CHIME_ID = "rbxasset://sounds/electronicpingshort.wav"
local SFX_PULSE_ID = "rbxasset://sounds/button.wav"
local SFX_WHOOSH_ID = "rbxasset://sounds/volume_slider.ogg"
local SFX_SWITCH_ID = "rbxasset://sounds/switch.wav"

local function resolveAudioAssetId(assetName: string, fallbackId: string): string
	local flyHigh = RS:FindFirstChild("FlyHigh")
	local audioFolder = flyHigh and flyHigh:FindFirstChild("AudioAssets")
	local asset = audioFolder and audioFolder:FindFirstChild(assetName)
	if asset and asset:IsA("Sound") and asset.SoundId ~= "" then
		return asset.SoundId
	end
	return fallbackId
end

local SFX_PUNCTURE_POP_ID = "rbxassetid://9113263649"
local SFX_PUNCTURE_TEAR_ID = "rbxassetid://9113825868"
local SFX_PUNCTURE_CRIT_ID = resolveAudioAssetId("WarningTone", SFX_PULSE_ID)

local KIT_HIGHLIGHT_DURATION = 0.85
local KIT_RING_DURATION = 0.65
local TURBO_RING_DURATION = 0.48
local SHIELD_BLINK_WINDOW = 1.5
local TURBO_COOLDOWN_WINDOW = 5.0
local CULL_DISTANCE = 320
local RING_SEGMENTS = 16
local DECK_GLOW_PLANK_OFFSET = 0.035
local DECK_GLOW_LAYERS = 18
local DECK_GLOW_WARM_COLOR = Color3.fromRGB(255, 162, 62)
local DECK_GLOW_TURBO_COLOR = Color3.fromRGB(64, 200, 255)
local STATIC_LIGHT_CULL_DISTANCE = 380
local STATIC_LIGHT_REFRESH_SEC = 0.5

type StaticLightEntry = {
	light: PointLight,
	pos: Vector3,
	defaultEnabled: boolean,
}

local vfxRootFolder: Folder? = nil
local tracked: { [Model]: any } = {}
local preloaded = false
local nextVfxId = 0
local staticLights: { StaticLightEntry }? = nil
local lastStaticLightCheck = 0

export type RingHandle = {
	setFrame: (radius: number, yOffset: number, width: number, alpha: number) -> (),
	hide: () -> (),
}

local function ensurePreload()
	if preloaded then
		return
	end
	preloaded = true
	task.spawn(function()
		local assets: { Instance } = {}
		for _, id in { SFX_CHIME_ID, SFX_PULSE_ID, SFX_WHOOSH_ID, SFX_SWITCH_ID, SFX_PUNCTURE_POP_ID, SFX_PUNCTURE_TEAR_ID, SFX_PUNCTURE_CRIT_ID } do
			local s = Instance.new("Sound")
			s.SoundId = id
			table.insert(assets, s)
		end
		pcall(ContentProvider.PreloadAsync, ContentProvider, assets)
		for _, s in ipairs(assets) do
			s:Destroy()
		end
	end)
end

local function ensureVfxRoot(): Folder
	if vfxRootFolder and vfxRootFolder.Parent then
		return vfxRootFolder
	end
	local existing = workspace:FindFirstChild("_FlyHighBalloonVFX")
	if existing and existing:IsA("Folder") then
		vfxRootFolder = existing
		return existing
	end
	local folder = Instance.new("Folder")
	folder.Name = "_FlyHighBalloonVFX"
	folder.Parent = workspace
	vfxRootFolder = folder
	return folder
end

local function isReducedMotion(): boolean
	local lp = Players.LocalPlayer
	return lp ~= nil and lp:GetAttribute("ReduceHUDMotion") == true
end

local function makeNonPhysicalPart(
	name: string,
	shape: Enum.PartType,
	size: Vector3,
	material: Enum.Material,
	color: Color3,
	transparency: number,
	parent: Instance,
	cf: CFrame,
	weldTo: BasePart
): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Shape = shape
	part.Size = size
	part.Material = material
	part.Color = color
	part.Transparency = transparency
	part.Anchored = false
	part.Massless = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.CastShadow = false
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	pcall(function()
		part.CollisionGroup = "FlyHighBalloons"
	end)
	part.CFrame = cf
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = weldTo
	weld.Part1 = part
	weld.Parent = part
	part.Parent = parent
	return part
end

export type DeckGlowHandle = {
	setVisual: (enabled: boolean, color: Color3, intensity: number) -> (),
}

local function createDeckGlow(folder: Instance, root: BasePart, basket: Instance?, burner: Instance?): DeckGlowHandle
	local basketRel = if basket and basket:IsA("BasePart")
		then root.CFrame:PointToObjectSpace(basket.Position)
		else Vector3.zero
	local basketSize = if basket and basket:IsA("BasePart")
		then basket.Size
		else Vector3.new(28, 1.2, 28)
	local deckW = math.max(18, basketSize.X - 1.5)
	local deckD = math.max(18, basketSize.Z - 1.5)
	local plateY = basketRel.Y + basketSize.Y * 0.5 + DECK_GLOW_PLANK_OFFSET

	local plate = makeNonPhysicalPart(
		"DeckBurnerGlowPlate",
		Enum.PartType.Block,
		Vector3.new(deckW, 0.01, deckD),
		Enum.Material.SmoothPlastic,
		Color3.new(1, 1, 1),
		1,
		folder,
		root.CFrame * CFrame.new(basketRel.X, plateY, basketRel.Z),
		root
	)

	local burnerRel = if burner and burner:IsA("BasePart")
		then root.CFrame:PointToObjectSpace(burner.Position)
		else Vector3.zero
	local offsetX = math.clamp(burnerRel.X - basketRel.X, -4, 4)
	local offsetZ = math.clamp(burnerRel.Z - basketRel.Z, -4, 4)
	-- On NormalId.Top, UI +U follows +Z and UI +V follows -X.
	local centerU = 0.5 + (offsetZ / deckD)
	local centerV = 0.5 - (offsetX / deckW)

	local gui = Instance.new("SurfaceGui")
	gui.Name = "BurnerDeckGlowGui"
	gui.Face = Enum.NormalId.Top
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 16
	gui.LightInfluence = 0
	gui.Brightness = 1
	gui.AlwaysOnTop = false
	gui.ZOffset = 0.02
	gui.ClipsDescendants = true
	gui.Enabled = false
	gui.Adornee = plate
	gui.Parent = plate

	local layers: { Frame } = table.create(DECK_GLOW_LAYERS)
	for i = 1, DECK_GLOW_LAYERS do
		local t = (i - 1) / math.max(1, DECK_GLOW_LAYERS - 1)
		local diameterScale = 1.08 - t * 0.92
		local frame = Instance.new("Frame")
		frame.Name = "GlowRing" .. tostring(i)
		frame.AnchorPoint = Vector2.new(0.5, 0.5)
		frame.Position = UDim2.fromScale(centerU, centerV)
		frame.Size = UDim2.fromScale(diameterScale, diameterScale)
		frame.SizeConstraint = Enum.SizeConstraint.RelativeXX
		frame.BorderSizePixel = 0
		frame.BackgroundColor3 = DECK_GLOW_WARM_COLOR
		frame.BackgroundTransparency = 1
		frame.ZIndex = i
		frame.Parent = gui

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(1, 0)
		corner.Parent = frame
		layers[i] = frame
	end

	local lastEnabled = false
	local lastColor: Color3? = nil
	local lastIntensity = -1

	return {
		setVisual = function(enabled: boolean, color: Color3, intensity: number)
			local clampedIntensity = math.clamp(intensity, 0, 1.3)
			if
				enabled == lastEnabled
				and lastColor == color
				and math.abs(clampedIntensity - lastIntensity) < 0.006
			then
				return
			end
			lastEnabled = enabled
			lastColor = color
			lastIntensity = clampedIntensity
			gui.Enabled = enabled and clampedIntensity > 0.005
			if not gui.Enabled then
				return
			end
			local layerTrans = 1 - math.clamp(0.041 * clampedIntensity, 0, 0.22)
			for _, frame in ipairs(layers) do
				frame.BackgroundColor3 = color
				frame.BackgroundTransparency = layerTrans
			end
		end,
	}
end

local function collectStaticLights(): { StaticLightEntry }
	if staticLights then
		return staticLights
	end
	local list: { StaticLightEntry } = {}
	local containers = {
		workspace:FindFirstChild("FlyHighLobby"),
		workspace:FindFirstChild("CloudPalace"),
	}
	for _, rootObj in ipairs(containers) do
		if rootObj then
			for _, desc in ipairs(rootObj:GetDescendants()) do
				if desc:IsA("PointLight") then
					local p = desc.Parent
					local pos = if p and p:IsA("BasePart")
						then p.Position
						elseif p and p:IsA("Attachment") then p.WorldPosition
						else nil
					if pos then
						table.insert(list, {
							light = desc,
							pos = pos,
							defaultEnabled = desc.Enabled,
						})
					end
				end
			end
		end
	end
	staticLights = list
	return list
end

local function updateDistantStaticLights(eyePos: Vector3, clockNow: number)
	if (clockNow - lastStaticLightCheck) < STATIC_LIGHT_REFRESH_SEC then
		return
	end
	lastStaticLightCheck = clockNow
	for _, entry in ipairs(collectStaticLights()) do
		if entry.light.Parent then
			local within = (entry.pos - eyePos).Magnitude <= STATIC_LIGHT_CULL_DISTANCE
			local target = if within then entry.defaultEnabled else false
			if entry.light.Enabled ~= target then
				entry.light.Enabled = target
			end
		end
	end
end

local function restoreStaticLights()
	if not staticLights then
		return
	end
	for _, entry in ipairs(staticLights) do
		if entry.light.Parent and entry.light.Enabled ~= entry.defaultEnabled then
			entry.light.Enabled = entry.defaultEnabled
		end
	end
end

local function createBeamRing(name: string, anchorPart: BasePart, colorSeq: ColorSequence): RingHandle
	local attachments: { Attachment } = table.create(RING_SEGMENTS)
	local beams: { Beam } = table.create(RING_SEGMENTS)
	for i = 1, RING_SEGMENTS do
		local att = Instance.new("Attachment")
		att.Name = string.format("%s_Att%d", name, i)
		att.Parent = anchorPart
		attachments[i] = att
	end
	local emptyTrans = NumberSequence.new(1)
	for i = 1, RING_SEGMENTS do
		local nextIdx = (i % RING_SEGMENTS) + 1
		local b = Instance.new("Beam")
		b.Name = string.format("%s_Seg%d", name, i)
		b.Attachment0 = attachments[i]
		b.Attachment1 = attachments[nextIdx]
		b.Color = colorSeq
		b.LightEmission = 1
		b.LightInfluence = 0
		b.FaceCamera = true
		b.Segments = 1
		b.Texture = TEX_SMOKE
		b.TextureMode = Enum.TextureMode.Stretch
		b.TextureSpeed = 0
		b.Transparency = emptyTrans
		b.Width0 = 0.8
		b.Width1 = 0.8
		b.Enabled = false
		b.Parent = anchorPart
		beams[i] = b
	end

	local hidden = true
	return {
		setFrame = function(radius: number, yOffset: number, width: number, alpha: number)
			hidden = false
			local clampedAlpha = math.clamp(alpha, 0, 1)
			local tSeq = NumberSequence.new(clampedAlpha)
			for i = 1, RING_SEGMENTS do
				local theta = ((i - 1) / RING_SEGMENTS) * math.pi * 2
				attachments[i].Position = Vector3.new(math.cos(theta) * radius, yOffset, math.sin(theta) * radius)
				local b = beams[i]
				b.Enabled = clampedAlpha < 0.99
				b.Width0 = width
				b.Width1 = width
				b.Transparency = tSeq
			end
		end,
		hide = function()
			if hidden then
				return
			end
			hidden = true
			for i = 1, RING_SEGMENTS do
				beams[i].Enabled = false
			end
		end,
	}
end

local function makeEmitter(parent: Instance, name: string, props: { [string]: any }): ParticleEmitter
	local em = Instance.new("ParticleEmitter")
	em.Name = name
	em.Enabled = false
	em.LockedToPart = props.LockedToPart == true
	em.Texture = props.Texture or TEX_SPARKS
	em.Color = props.Color or ColorSequence.new(Color3.new(1, 1, 1))
	em.LightEmission = props.LightEmission or 0.9
	em.LightInfluence = props.LightInfluence or 0
	em.Size = props.Size or NumberSequence.new(1, 0)
	em.Transparency = props.Transparency or NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.15),
		NumberSequenceKeypoint.new(0.7, 0.35),
		NumberSequenceKeypoint.new(1, 1),
	})
	em.Rate = props.Rate or 20
	em.Speed = props.Speed or NumberRange.new(8, 14)
	em.Lifetime = props.Lifetime or NumberRange.new(0.4, 0.7)
	em.SpreadAngle = props.SpreadAngle or Vector2.new(25, 25)
	em.RotSpeed = props.RotSpeed or NumberRange.new(-90, 90)
	if props.Acceleration then
		em.Acceleration = props.Acceleration
	end
	if props.Orientation then
		em.Orientation = props.Orientation
	end
	if props.Squash then
		em.Squash = props.Squash
	end
	if props.EmissionDirection then
		em.EmissionDirection = props.EmissionDirection
	end
	em.Parent = parent
	return em
end

local function createSpatialSound(parent: Instance, name: string, soundId: string, volume: number, pitch: number, sfxGroup: SoundGroup, is2D: boolean?): Sound
	local s = Instance.new("Sound")
	s.Name = name
	s.SoundId = soundId
	s.Volume = volume
	s.PlaybackSpeed = pitch
	s.Looped = false
	if not is2D then
		s.RollOffMinDistance = 24
		s.RollOffMaxDistance = 260
		s.RollOffMode = Enum.RollOffMode.InverseTapered
	end
	s.SoundGroup = sfxGroup
	s.Parent = parent
	return s
end

local function playLoadedSound(sound: Sound?, fallback: Sound?)
	if sound and sound.IsLoaded then
		sound.TimePosition = 0
		sound:Play()
		return
	end
	if fallback and fallback.IsLoaded then
		fallback.TimePosition = 0
		fallback:Play()
	end
end

local function isOwnFlightBalloon(model: Model): boolean
	local lp = Players.LocalPlayer
	local ref = lp and lp:FindFirstChild("FlightBalloon")
	return ref ~= nil and ref:IsA("ObjectValue") and ref.Value == model
end

local function positionHoleAudio(state: any, holeIdx: number)
	if not state.holeAudioAtt then
		return
	end
	local rel = state.holeRelPositions and state.holeRelPositions[holeIdx]
	state.holeAudioAtt.Position = rel or Vector3.new(0, state.envRelY, 0)
end

local function triggerPunctureSfx(state: any)
	if AudioMixer.GetSFXScale(Players.LocalPlayer) <= 0 then
		return
	end
	local now = os.clock()
	if now - (state.lastPunctureSoundAt or -99) < 0.14 then
		return
	end
	state.lastPunctureSoundAt = now
	local holeIdx = tonumber(state.model:GetAttribute("LastPunctureHole")) or 0
	positionHoleAudio(state, holeIdx)
	playLoadedSound(state.punctureSpatialThud)
	playLoadedSound(state.punctureSpatialHiss)
	if isOwnFlightBalloon(state.model) then
		playLoadedSound(state.punctureLocalSnap, state.punctureSpatialThud)
		local holes = tonumber(state.model:GetAttribute("Holes")) or 0
		if holes >= 4 then
			playLoadedSound(state.punctureLocalCrit)
		end
	end
end

local function triggerPatchSfx(state: any)
	local now = os.clock()
	if now - (state.kitRingStartedAt or -99) < 0.25 then
		return
	end
	local holeIdx = tonumber(state.model:GetAttribute("LastPatchHole")) or 0
	local em = state.holeEmitters and state.holeEmitters[holeIdx]
	if em then
		em:Emit(isReducedMotion() and 6 or 14)
	end
	if AudioMixer.GetSFXScale(Players.LocalPlayer) <= 0 then
		return
	end
	if now - (state.lastPatchSoundAt or -99) < 0.1 then
		return
	end
	state.lastPatchSoundAt = now
	positionHoleAudio(state, holeIdx)
	playLoadedSound(state.patchSpatialSnap)
	if isOwnFlightBalloon(state.model) then
		playLoadedSound(state.patchLocalChimeLow)
		task.delay(0.09, function()
			if tracked[state.model] == state and AudioMixer.GetSFXScale(Players.LocalPlayer) > 0 then
				playLoadedSound(state.patchLocalChimeHigh)
			end
		end)
	end
end

local function parseRepairedSlots(csv: any): { number }
	if typeof(csv) ~= "string" or csv == "" then
		return {}
	end
	local out = {}
	for token in string.gmatch(csv, "%d+") do
		local n = tonumber(token)
		if n and n >= 1 and n <= 5 then
			table.insert(out, n)
		end
	end
	return out
end

local function triggerKitBurst(state: any)
	local reduced = isReducedMotion()
	local slots = parseRepairedSlots(state.model:GetAttribute("KitRepairedSlots"))
	if #slots > 0 then
		local count = reduced and 12 or 26
		for _, idx in ipairs(slots) do
			local em = state.holeEmitters[idx]
			if em then
				em:Emit(count)
			end
		end
	else
		local count = reduced and 5 or 10
		for _, em in pairs(state.holeEmitters) do
			em:Emit(count)
		end
	end

	state.kitRingStartedAt = os.clock()
	if not reduced and state.kitHighlight then
		state.kitHighlightStartedAt = os.clock()
		state.kitHighlight.Enabled = true
		state.kitHighlight.FillTransparency = 0.65
		state.kitHighlight.OutlineTransparency = 0.12
	end

	if AudioMixer.GetSFXScale(Players.LocalPlayer) > 0 then
		if state.kitSoundChime and state.kitSoundChime.IsLoaded then
			state.kitSoundChime.TimePosition = 0
			state.kitSoundChime:Play()
		end
		if state.kitSoundBody and state.kitSoundBody.IsLoaded then
			state.kitSoundBody.TimePosition = 0
			state.kitSoundBody:Play()
		end
	end
end

local function triggerTurboBurst(state: any)
	local reduced = isReducedMotion()
	if state.turboIgnitionEmitter then
		state.turboIgnitionEmitter:Emit(reduced and 16 or 34)
	end
	state.turboRingStartedAt = os.clock()

	if AudioMixer.GetSFXScale(Players.LocalPlayer) > 0 then
		if state.turboSoundWhoosh and state.turboSoundWhoosh.IsLoaded then
			state.turboSoundWhoosh.TimePosition = 0
			state.turboSoundWhoosh:Play()
		end
		if state.turboSoundPulse and state.turboSoundPulse.IsLoaded then
			state.turboSoundPulse.TimePosition = 0
			state.turboSoundPulse:Play()
		end
	end
end

function BalloonVFX.Attach(model: Model)
	if tracked[model] then
		return
	end
	local root = model.PrimaryPart
	if not root or not root:IsA("BasePart") then
		return
	end

	ensurePreload()
	local lp = Players.LocalPlayer
	if lp then
		AudioMixer.Bind(lp)
	end
	local sfxGroup = AudioMixer.GetGroup("SFX")

	local envelope = model:FindFirstChild("Envelope")
	local basket = model:FindFirstChild("BasketFloor")
	local burner = model:FindFirstChild("Burner")
	local burnerNozzle = burner and burner:FindFirstChild("BurnerNozzle")
	local holeSlots = model:FindFirstChild("HoleSlots")

	nextVfxId += 1
	local folder = Instance.new("Folder")
	folder.Name = "VFX_" .. tostring(nextVfxId) .. "_" .. model.Name
	folder.Parent = ensureVfxRoot()

	local anchor = makeNonPhysicalPart(
		"VfxAnchor",
		Enum.PartType.Block,
		Vector3.new(1, 1, 1),
		Enum.Material.SmoothPlastic,
		Color3.new(1, 1, 1),
		1,
		folder,
		root.CFrame,
		root
	)

	-- Dynamic envelope & shield dome dimensions covering all 6 BalloonVariants accurately.
	local envRelPos = if envelope and envelope:IsA("BasePart")
		then root.CFrame:PointToObjectSpace(envelope.Position)
		else Vector3.new(0, 32, 0)
	local envSize = if envelope and envelope:IsA("BasePart")
		then envelope.Size
		else Vector3.new(32, 38, 32)
	local basketBottomY = if basket and basket:IsA("BasePart")
		then root.CFrame:PointToObjectSpace(basket.Position).Y - basket.Size.Y * 0.5
		else -1
	-- Shield ellipsoid fitted to the balloon's visible geometry (skins differ: lotus/koi/saturn envelopes
	-- reach higher or wider than the hidden Envelope part). A Ball part is always a sphere, which left the
	-- envelope top outside the shield (review 17 Nov), so the shell is an ellipsoid mesh.
	local holeFolder = model:FindFirstChild("HoleSlots")
	-- Points on each part's inscribed ellipsoid: envelopes are round, so box corners would overinflate the shell.
	local directions = {}
	for _, x in { -1, 0, 1 } do
		for _, y in { -1, 0, 1 } do
			for _, z in { -1, 0, 1 } do
				local d = Vector3.new(x, y, z)
				if d.Magnitude > 0 then table.insert(directions, d.Unit) end
			end
		end
	end
	local corners = {}
	for _, x in { -1, 1 } do
		for _, y in { -1, 1 } do
			for _, z in { -1, 1 } do
				table.insert(corners, Vector3.new(x, y, z))
			end
		end
	end
	local samples = {}
	local visTop, visBottom = -math.huge, math.huge
	for _, p in model:GetDescendants() do
		if p:IsA("BasePart") and p ~= root and p.Transparency < 0.95 and not (holeFolder and p:IsDescendantOf(holeFolder)) then
			local cf = root.CFrame:ToObjectSpace(p.CFrame)
			local h = p.Size * 0.5
			-- Block parts (basket floor, rails, posts) are boxes: their corners must stay inside too.
			local boxy = p:IsA("Part") and p.Shape == Enum.PartType.Block
			for _, d in boxy and corners or directions do
				local c = cf * (h * d)
				table.insert(samples, c)
				visTop = math.max(visTop, c.Y)
				visBottom = math.min(visBottom, c.Y)
			end
		end
	end
	if #samples == 0 then
		visTop = envRelPos.Y + envSize.Y * 0.5
		visBottom = basketBottomY
	end
	local domeTopY = visTop + 3
	local domeBottomY = math.min(visBottom, basketBottomY) - 3
	local domeCenterY = (domeTopY + domeBottomY) * 0.5
	local radiusY = (domeTopY - domeBottomY) * 0.5
	local radiusXZ = math.max(envSize.X, envSize.Z, 28) * 0.5 + 6
	local fit = 1
	for _, c in samples do
		local r = Vector2.new(c.X, c.Z).Magnitude
		local dy = c.Y - domeCenterY
		fit = math.max(fit, math.sqrt((r / radiusXZ) ^ 2 + (dy / radiusY) ^ 2))
	end
	-- Grow the horizontal radius first (the shell should hug the height), then both if still needed.
	radiusXZ *= math.min(fit, 1.6)
	fit = 1
	for _, c in samples do
		local r = Vector2.new(c.X, c.Z).Magnitude
		local dy = c.Y - domeCenterY
		fit = math.max(fit, math.sqrt((r / radiusXZ) ^ 2 + (dy / radiusY) ^ 2))
	end
	radiusXZ *= fit * 1.06
	radiusY *= fit * 1.04
	local domeWidth = radiusXZ * 2
	local domeHeight = radiusY * 2

	local shieldShell = makeNonPhysicalPart(
		"ShieldShell",
		Enum.PartType.Block,
		Vector3.new(domeWidth, domeHeight, domeWidth),
		Enum.Material.ForceField,
		Color3.fromRGB(122, 250, 206),
		1,
		folder,
		root.CFrame * CFrame.new(0, domeCenterY, 0),
		root
	)
	local shieldMesh = Instance.new("SpecialMesh")
	shieldMesh.MeshType = Enum.MeshType.Sphere
	shieldMesh.Parent = shieldShell
	shieldShell:SetAttribute("ShieldFit", string.format("%.1fx%.1f@%.1f", domeWidth, domeHeight, domeCenterY))

	local shieldLight = Instance.new("PointLight")
	shieldLight.Name = "ShieldAuraLight"
	shieldLight.Color = Color3.fromRGB(122, 245, 208)
	shieldLight.Range = 48
	shieldLight.Brightness = 0
	shieldLight.Enabled = false
	shieldLight.Parent = shieldShell

	local shieldBeltAnchor = makeNonPhysicalPart(
		"ShieldBeltAnchor",
		Enum.PartType.Cylinder,
		Vector3.new(1, envSize.X * 1.05, envSize.Z * 1.05),
		Enum.Material.SmoothPlastic,
		Color3.new(1, 1, 1),
		1,
		folder,
		root.CFrame * CFrame.new(0, envRelPos.Y - 4, 0) * CFrame.Angles(0, 0, math.rad(90)),
		root
	)
	local shieldIdleEmitter = makeEmitter(shieldBeltAnchor, "ShieldIdleMotes", {
		LockedToPart = true,
		Texture = TEX_SPARKS,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 232, 120)),
			ColorSequenceKeypoint.new(0.55, Color3.fromRGB(110, 248, 198)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(205, 255, 238)),
		}),
		Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(0.25, 1.05),
			NumberSequenceKeypoint.new(1, 0),
		}),
		Rate = 18,
		Speed = NumberRange.new(5, 10),
		Lifetime = NumberRange.new(0.85, 1.35),
		SpreadAngle = Vector2.new(35, 35),
		EmissionDirection = Enum.NormalId.Right,
	})

	-- Per-hole emerald-gold patch burst emitters aligned to Hole1..Hole5 local offsets.
	local holeEmitters: { [number]: ParticleEmitter } = {}
	local holeRelPositions: { [number]: Vector3 } = {}
	if holeSlots then
		for i = 1, 5 do
			local h = holeSlots:FindFirstChild("Hole" .. i)
			if h and h:IsA("BasePart") then
				local relPos = root.CFrame:PointToObjectSpace(h.Position)
				holeRelPositions[i] = relPos
				local outward = Vector3.new(relPos.X, 0, relPos.Z)
				if outward.Magnitude < 0.01 then
					outward = Vector3.new(0, 0, -1)
				else
					outward = outward.Unit
				end
				local att = Instance.new("Attachment")
				att.Name = "KitHoleAtt" .. i
				att.CFrame = CFrame.lookAt(relPos, relPos + outward)
				att.Parent = anchor
				holeEmitters[i] = makeEmitter(att, "KitPatchBurst", {
					LockedToPart = true,
					Texture = TEX_SPARKS,
					Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 246, 178)),
						ColorSequenceKeypoint.new(0.45, Color3.fromRGB(250, 204, 21)),
						ColorSequenceKeypoint.new(1, Color3.fromRGB(74, 222, 128)),
					}),
					Size = NumberSequence.new({
						NumberSequenceKeypoint.new(0, 1.3),
						NumberSequenceKeypoint.new(0.6, 0.7),
						NumberSequenceKeypoint.new(1, 0),
					}),
					Rate = 0,
					Speed = NumberRange.new(7, 15),
					Lifetime = NumberRange.new(0.45, 0.8),
					SpreadAngle = Vector2.new(42, 42),
					EmissionDirection = Enum.NormalId.Front,
				})
			end
		end
	end

	-- Shockwave rings rendered with segmented horizontal Beam halos.
	local kitRing = createBeamRing(
		"KitShockRing",
		anchor,
		ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 245, 178)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(250, 215, 92)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(110, 238, 188)),
		})
	)
	local turboRing = createBeamRing(
		"TurboShockRing",
		anchor,
		ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(235, 252, 255)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(56, 189, 248)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(14, 165, 233)),
		})
	)
	local nozzleHaloRing = createBeamRing(
		"TurboNozzleHalo",
		anchor,
		ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(224, 248, 255)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 204, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(37, 99, 235)),
		})
	)

	-- Brief golden recovery outline/tint on the balloon hull (ShieldShell is external to model).
	local kitHighlight = Instance.new("Highlight")
	kitHighlight.Name = "KitSaveHighlight"
	kitHighlight.Adornee = model
	kitHighlight.DepthMode = Enum.HighlightDepthMode.Occluded
	kitHighlight.FillColor = Color3.fromRGB(255, 224, 118)
	kitHighlight.OutlineColor = Color3.fromRGB(110, 238, 188)
	kitHighlight.FillTransparency = 1
	kitHighlight.OutlineTransparency = 1
	kitHighlight.Enabled = false
	kitHighlight.Parent = folder

	-- Burner nozzle jet layers anchored on Burner.BurnerNozzle world position.
	local nozzleWorldPos = if burnerNozzle and burnerNozzle:IsA("Attachment")
		then burnerNozzle.WorldPosition
		elseif burner and burner:IsA("BasePart") then burner.Position + Vector3.new(0, 1.2, 0)
		else root.Position + Vector3.new(0, 10.8, 0)
	local nozzleRelPos = root.CFrame:PointToObjectSpace(nozzleWorldPos)
	local nozzleAnchor = makeNonPhysicalPart(
		"NozzleVfxAnchor",
		Enum.PartType.Block,
		Vector3.new(0.6, 0.6, 0.6),
		Enum.Material.SmoothPlastic,
		Color3.new(1, 1, 1),
		1,
		folder,
		root.CFrame * CFrame.new(nozzleRelPos),
		root
	)
	local nozzleAtt = Instance.new("Attachment")
	nozzleAtt.Name = "TurboNozzleAtt"
	nozzleAtt.Parent = nozzleAnchor

	local turboCoreJet = makeEmitter(nozzleAtt, "TurboCoreJet", {
		LockedToPart = true,
		Texture = TEX_FIRE,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(245, 253, 255)),
			ColorSequenceKeypoint.new(0.35, Color3.fromRGB(0, 204, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(29, 78, 216)),
		}),
		Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 2.7),
			NumberSequenceKeypoint.new(0.45, 1.8),
			NumberSequenceKeypoint.new(1, 0.35),
		}),
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.04),
			NumberSequenceKeypoint.new(0.6, 0.2),
			NumberSequenceKeypoint.new(1, 1),
		}),
		Rate = 95,
		Speed = NumberRange.new(24, 34),
		Lifetime = NumberRange.new(0.22, 0.34),
		SpreadAngle = Vector2.new(14, 14),
		EmissionDirection = Enum.NormalId.Top,
	})

	local turboEmberSparks = makeEmitter(nozzleAtt, "TurboEmberSparks", {
		LockedToPart = true,
		Texture = TEX_SPARKS,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(224, 248, 255)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(56, 189, 248)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(250, 204, 21)),
		}),
		Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.45),
			NumberSequenceKeypoint.new(1, 0),
		}),
		Rate = 26,
		Speed = NumberRange.new(12, 22),
		Lifetime = NumberRange.new(0.35, 0.65),
		SpreadAngle = Vector2.new(34, 34),
		EmissionDirection = Enum.NormalId.Top,
	})

	local turboIgnitionEmitter = makeEmitter(nozzleAtt, "TurboIgnitionBurst", {
		LockedToPart = true,
		Texture = TEX_FIRE,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(240, 253, 255)),
			ColorSequenceKeypoint.new(0.45, Color3.fromRGB(56, 189, 248)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(14, 165, 233)),
		}),
		Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 2.6),
			NumberSequenceKeypoint.new(0.5, 1.8),
			NumberSequenceKeypoint.new(1, 0.1),
		}),
		Rate = 0,
		Speed = NumberRange.new(16, 28),
		Lifetime = NumberRange.new(0.28, 0.48),
		SpreadAngle = Vector2.new(42, 42),
		EmissionDirection = Enum.NormalId.Top,
	})

	local turboBurnerLight = Instance.new("PointLight")
	turboBurnerLight.Name = "TurboBurnerLight"
	turboBurnerLight.Color = Color3.fromRGB(56, 198, 255)
	turboBurnerLight.Range = 44
	turboBurnerLight.Brightness = 0
	turboBurnerLight.Enabled = false
	turboBurnerLight.Parent = nozzleAnchor

	-- Slipstream wind trails attached around outer envelope equator and poles.
	local trails: { Trail } = {}
	local trailColor = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(245, 253, 255)),
		ColorSequenceKeypoint.new(0.4, Color3.fromRGB(0, 204, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(29, 78, 216)),
	})
	local trailTrans = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.14),
		NumberSequenceKeypoint.new(0.55, 0.45),
		NumberSequenceKeypoint.new(1, 1),
	})
	local function addTrailPoint(label: string, pos: Vector3, halfWidth: number)
		local a0 = Instance.new("Attachment")
		a0.Name = label .. "_A0"
		a0.Position = pos + Vector3.new(0, halfWidth, 0)
		a0.Parent = anchor
		local a1 = Instance.new("Attachment")
		a1.Name = label .. "_A1"
		a1.Position = pos - Vector3.new(0, halfWidth, 0)
		a1.Parent = anchor
		local tr = Instance.new("Trail")
		tr.Name = label
		tr.Attachment0 = a0
		tr.Attachment1 = a1
		tr.Color = trailColor
		tr.Transparency = trailTrans
		tr.LightEmission = 0.85
		tr.LightInfluence = 0
		tr.FaceCamera = true
		tr.Lifetime = 0.85
		tr.MinLength = 0.15
		tr.MaxLength = 28
		tr.Enabled = false
		tr.Parent = anchor
		table.insert(trails, tr)
	end

	local envR = math.max(envSize.X, envSize.Z) * 0.5 + 0.9
	for idx, deg in ipairs({ 45, 135, 225, 315 }) do
		local rad = math.rad(deg)
		addTrailPoint(
			"EnvSlipTrail" .. idx,
			Vector3.new(math.cos(rad) * envR, envRelPos.Y - 2, math.sin(rad) * envR),
			0.72
		)
	end
	addTrailPoint("PoleSlipTrailL", Vector3.new(-13.2, 8.5, 0), 0.48)
	addTrailPoint("PoleSlipTrailR", Vector3.new(13.2, 8.5, 0), 0.48)

	-- Downward rushing wind-streak emitter around canopy for clear speed feedback even at climb/hover.
	local windEmitterAnchor = makeNonPhysicalPart(
		"TurboWindTopAnchor",
		Enum.PartType.Cylinder,
		Vector3.new(0.6, envSize.X * 0.95, envSize.Z * 0.95),
		Enum.Material.SmoothPlastic,
		Color3.new(1, 1, 1),
		1,
		folder,
		root.CFrame * CFrame.new(0, envRelPos.Y + envSize.Y * 0.35, 0) * CFrame.Angles(0, 0, math.rad(90)),
		root
	)
	local turboWindStream = makeEmitter(windEmitterAnchor, "TurboWindStream", {
		Texture = TEX_SMOKE,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(245, 253, 255)),
			ColorSequenceKeypoint.new(0.45, Color3.fromRGB(56, 189, 248)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(30, 64, 175)),
		}),
		Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.72),
			NumberSequenceKeypoint.new(0.5, 0.85),
			NumberSequenceKeypoint.new(1, 0.25),
		}),
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.6),
			NumberSequenceKeypoint.new(0.2, 0.15),
			NumberSequenceKeypoint.new(0.75, 0.38),
			NumberSequenceKeypoint.new(1, 1),
		}),
		Rate = 44,
		Speed = NumberRange.new(28, 40),
		Lifetime = NumberRange.new(0.85, 1.15),
		SpreadAngle = Vector2.new(8, 8),
		Acceleration = Vector3.new(0, -44, 0),
		Orientation = Enum.ParticleOrientation.VelocityParallel,
		Squash = NumberSequence.new(-1.6),
		EmissionDirection = Enum.NormalId.Left,
	})

	local kitSoundChime = createSpatialSound(anchor, "KitSaveChime", SFX_CHIME_ID, 0.38, 1.46, sfxGroup)
	local kitSoundBody = createSpatialSound(anchor, "KitSaveBody", SFX_PULSE_ID, 0.30, 1.18, sfxGroup)
	local turboSoundWhoosh = createSpatialSound(nozzleAnchor, "TurboIgniteWhoosh", SFX_WHOOSH_ID, 0.42, 0.68, sfxGroup)
	local turboSoundPulse = createSpatialSound(nozzleAnchor, "TurboIgnitePulse", SFX_CHIME_ID, 0.24, 1.82, sfxGroup)

	local holeAudioAtt = Instance.new("Attachment")
	holeAudioAtt.Name = "HoleAudioAtt"
	holeAudioAtt.Position = Vector3.new(0, envRelPos.Y, 0)
	holeAudioAtt.Parent = anchor

	local localAudioFolder = Instance.new("Folder")
	localAudioFolder.Name = "VFX2D_" .. tostring(nextVfxId) .. "_" .. model.Name
	localAudioFolder.Parent = game:GetService("SoundService")

	local punctureSpatialThud = createSpatialSound(holeAudioAtt, "PunctureThud", SFX_PUNCTURE_POP_ID, 0.312, 0.95, sfxGroup)
	local punctureSpatialHiss = createSpatialSound(holeAudioAtt, "PunctureHiss", SFX_WHOOSH_ID, 0.273, 1.48, sfxGroup)
	local punctureLocalSnap = createSpatialSound(localAudioFolder, "PunctureCrewSnap", SFX_PUNCTURE_TEAR_ID, 0.234, 1.02, sfxGroup, true)
	local punctureLocalCrit = createSpatialSound(localAudioFolder, "PunctureCrewCrit", SFX_PUNCTURE_CRIT_ID, 0.182, 0.80, sfxGroup, true)
	local patchSpatialSnap = createSpatialSound(holeAudioAtt, "PatchSnap", SFX_SWITCH_ID, 0.46, 1.16, sfxGroup)
	local patchLocalChimeLow = createSpatialSound(localAudioFolder, "PatchCrewChimeLow", SFX_CHIME_ID, 0.28, 1.28, sfxGroup, true)
	local patchLocalChimeHigh = createSpatialSound(localAudioFolder, "PatchCrewChimeHigh", SFX_CHIME_ID, 0.26, 1.60, sfxGroup, true)
	local deckGlow = createDeckGlow(folder, root, basket, burner)

	local state = {
		model = model,
		root = root,
		folder = folder,
		localAudioFolder = localAudioFolder,
		holeAudioAtt = holeAudioAtt,
		holeRelPositions = holeRelPositions,
		nozzleRelY = nozzleRelPos.Y,
		envRelY = envRelPos.Y,
		envR = envR,
		shieldShell = shieldShell,
		shieldLight = shieldLight,
		shieldIdleEmitter = shieldIdleEmitter,
		holeEmitters = holeEmitters,
		kitRing = kitRing,
		turboRing = turboRing,
		nozzleHaloRing = nozzleHaloRing,
		kitHighlight = kitHighlight,
		turboCoreJet = turboCoreJet,
		turboEmberSparks = turboEmberSparks,
		turboIgnitionEmitter = turboIgnitionEmitter,
		turboBurnerLight = turboBurnerLight,
		trails = trails,
		turboWindStream = turboWindStream,
		kitSoundChime = kitSoundChime,
		kitSoundBody = kitSoundBody,
		turboSoundWhoosh = turboSoundWhoosh,
		turboSoundPulse = turboSoundPulse,
		punctureSpatialThud = punctureSpatialThud,
		punctureSpatialHiss = punctureSpatialHiss,
		punctureLocalSnap = punctureLocalSnap,
		punctureLocalCrit = punctureLocalCrit,
		patchSpatialSnap = patchSpatialSnap,
		patchLocalChimeLow = patchLocalChimeLow,
		patchLocalChimeHigh = patchLocalChimeHigh,
		deckGlow = deckGlow,
		kitRingStartedAt = nil :: number?,
		kitHighlightStartedAt = nil :: number?,
		turboRingStartedAt = nil :: number?,
		lastKitSeq = tonumber(model:GetAttribute("KitBurstSeq")) or 0,
		lastTurboSeq = tonumber(model:GetAttribute("TurboBurstSeq")) or 0,
		lastPunctureSeq = tonumber(model:GetAttribute("PunctureSeq")) or 0,
		lastPatchSeq = tonumber(model:GetAttribute("PatchSeq")) or 0,
		lastPunctureSoundAt = -99,
		lastPatchSoundAt = -99,
		lastPos = root.Position,
		lastStepClock = os.clock(),
		connections = {} :: { RBXScriptConnection },
	}

	table.insert(state.connections, model:GetAttributeChangedSignal("KitBurstSeq"):Connect(function()
		local seq = tonumber(model:GetAttribute("KitBurstSeq")) or 0
		if seq > state.lastKitSeq then
			state.lastKitSeq = seq
			triggerKitBurst(state)
		end
	end))

	table.insert(state.connections, model:GetAttributeChangedSignal("TurboBurstSeq"):Connect(function()
		local seq = tonumber(model:GetAttribute("TurboBurstSeq")) or 0
		if seq > state.lastTurboSeq then
			state.lastTurboSeq = seq
			triggerTurboBurst(state)
		end
	end))

	table.insert(state.connections, model:GetAttributeChangedSignal("PunctureSeq"):Connect(function()
		local seq = tonumber(model:GetAttribute("PunctureSeq")) or 0
		if seq > state.lastPunctureSeq then
			state.lastPunctureSeq = seq
			triggerPunctureSfx(state)
		end
	end))

	table.insert(state.connections, model:GetAttributeChangedSignal("PatchSeq"):Connect(function()
		local seq = tonumber(model:GetAttribute("PatchSeq")) or 0
		if seq > state.lastPatchSeq then
			state.lastPatchSeq = seq
			triggerPatchSfx(state)
		end
	end))

	table.insert(state.connections, model.Destroying:Connect(function()
		BalloonVFX.Detach(model)
	end))

	tracked[model] = state
end

function BalloonVFX.Detach(model: Model)
	local state = tracked[model]
	if not state then
		return
	end
	tracked[model] = nil
	for _, conn in ipairs(state.connections) do
		conn:Disconnect()
	end
	if state.folder and state.folder.Parent then
		state.folder:Destroy()
	end
	if state.localAudioFolder and state.localAudioFolder.Parent then
		state.localAudioFolder:Destroy()
	end
	if next(tracked) == nil then
		restoreStaticLights()
	end
end

function BalloonVFX.HasActiveEffects(): boolean
	for model, state in pairs(tracked) do
		if not model.Parent then
			return true
		end
		if
			state.kitRingStartedAt
			or state.kitHighlightStartedAt
			or state.turboRingStartedAt
			or model:GetAttribute("ShieldActive") == true
			or model:GetAttribute("TurboActive") == true
		then
			return true
		end
	end
	return false
end

local function updateKitBurstVisuals(state: any, clockNow: number)
	if state.kitRingStartedAt then
		local t = (clockNow - state.kitRingStartedAt) / KIT_RING_DURATION
		if t >= 1 then
			state.kitRingStartedAt = nil
			state.kitRing.hide()
		else
			local eased = 1 - (1 - t) ^ 2
			local radius = 3.5 + eased * (state.envR + 10)
			local riseY = (state.nozzleRelY - 4) + eased * ((state.envRelY + 6) - (state.nozzleRelY - 4))
			local width = 1.6 * (1 - t * 0.55)
			local alpha = math.clamp(0.12 + (t ^ 1.4) * 0.88, 0, 1)
			state.kitRing.setFrame(radius, riseY, width, alpha)
		end
	end

	if state.kitHighlightStartedAt then
		local t = (clockNow - state.kitHighlightStartedAt) / KIT_HIGHLIGHT_DURATION
		if t >= 1 then
			state.kitHighlightStartedAt = nil
			state.kitHighlight.Enabled = false
		else
			local fade = t * t
			state.kitHighlight.FillTransparency = 0.65 + 0.35 * fade
			state.kitHighlight.OutlineTransparency = 0.12 + 0.88 * fade
		end
	end
end

local function updateTurboBurstVisuals(state: any, clockNow: number)
	if state.turboRingStartedAt then
		local t = (clockNow - state.turboRingStartedAt) / TURBO_RING_DURATION
		if t >= 1 then
			state.turboRingStartedAt = nil
			state.turboRing.hide()
		else
			local eased = 1 - (1 - t) ^ 2
			local radius = 2.5 + eased * 23.5
			local riseY = state.nozzleRelY + eased * 12
			local width = 1.25 * (1 - t * 0.5)
			local alpha = math.clamp(0.08 + (t ^ 1.3) * 0.92, 0, 1)
			state.turboRing.setFrame(radius, riseY, width, alpha)
		end
	end
end

local function updateShieldState(state: any, serverNow: number, clockNow: number, inRange: boolean, reduced: boolean)
	local model = state.model
	local shieldUntil = tonumber(model:GetAttribute("ShieldUntil")) or 0
	local shieldActive = model:GetAttribute("ShieldActive") == true
	local remaining = if shieldUntil > 0 then math.max(0, shieldUntil - serverNow) elseif shieldActive then 5 else 0
	local active = shieldActive and remaining > 0

	if not active then
		if state.shieldShell.Transparency < 0.99 then
			state.shieldShell.Transparency = 1
		end
		state.shieldLight.Enabled = false
		state.shieldIdleEmitter.Enabled = false
		return
	end

	local pulse = 0.5 + 0.5 * math.sin(clockNow * 4.2)
	local trans = 0.48 - 0.08 * pulse
	if remaining <= SHIELD_BLINK_WINDOW then
		local blink = 0.5 + 0.5 * math.sin(clockNow * 16)
		trans = 0.45 + 0.45 * blink
	end
	state.shieldShell.Transparency = trans
	state.shieldLight.Enabled = inRange
	state.shieldLight.Brightness = 1.6 + 0.5 * pulse
	state.shieldIdleEmitter.Enabled = inRange
	state.shieldIdleEmitter.Rate = if reduced then 6 else 18
end

local function updateTurboState(
	state: any,
	serverNow: number,
	speedMag: number,
	inRange: boolean,
	reduced: boolean
)
	local model = state.model
	local turboUntil = tonumber(model:GetAttribute("TurboUntil")) or 0
	local turboActive = model:GetAttribute("TurboActive") == true
	local burnerActive = model:GetAttribute("BurnerActive") == true
	local remaining = if turboUntil > 0 then math.max(0, turboUntil - serverNow) elseif turboActive then 10 else 0
	local active = turboActive and remaining > 0

	if not active or not inRange then
		state.turboCoreJet.Enabled = false
		state.turboEmberSparks.Enabled = false
		state.turboWindStream.Enabled = false
		state.turboBurnerLight.Enabled = false
		state.nozzleHaloRing.hide()
		for _, tr in ipairs(state.trails) do
			tr.Enabled = false
		end
		return
	end

	local fadeScale = if remaining < TURBO_COOLDOWN_WINDOW
		then math.clamp(remaining / TURBO_COOLDOWN_WINDOW, 0.25, 1)
		else 1
	local motionScale = if reduced then 0.5 else 1

	state.turboCoreJet.Enabled = true
	state.turboEmberSparks.Enabled = true
	state.turboBurnerLight.Enabled = true

	if burnerActive then
		state.turboCoreJet.Rate = 95 * fadeScale * motionScale
		state.turboCoreJet.Speed = NumberRange.new(22 + 4 * fadeScale, 32 + 4 * fadeScale)
		state.turboEmberSparks.Rate = 28 * fadeScale * motionScale
		state.turboBurnerLight.Brightness = 3.6 * fadeScale
		state.turboWindStream.Enabled = true
		state.turboWindStream.Rate = 44 * fadeScale * motionScale
		state.nozzleHaloRing.setFrame(2.9, state.nozzleRelY + 0.5, 0.55, 1 - 0.82 * fadeScale)
	else
		state.turboCoreJet.Rate = 20 * fadeScale * motionScale
		state.turboCoreJet.Speed = NumberRange.new(4.5, 7.5)
		state.turboEmberSparks.Rate = 9 * fadeScale * motionScale
		state.turboBurnerLight.Brightness = 1.4 * fadeScale
		local drifting = speedMag > 5
		state.turboWindStream.Enabled = drifting
		state.turboWindStream.Rate = 14 * fadeScale * motionScale
		state.nozzleHaloRing.setFrame(2.3, state.nozzleRelY + 0.4, 0.35, 1 - 0.45 * fadeScale)
	end

	local showTrails = (speedMag > 1.5 or burnerActive) and (not reduced or burnerActive)
	for _, tr in ipairs(state.trails) do
		tr.Enabled = showTrails
	end
end

local function updateDeckGlow(state: any, clockNow: number, inRange: boolean, reduced: boolean)
	if not inRange then
		state.deckGlow.setVisual(false, DECK_GLOW_WARM_COLOR, 0)
		return
	end
	local model = state.model
	local burnerActive = model:GetAttribute("BurnerActive") == true
	local turboActive = model:GetAttribute("TurboActive") == true
	local nightWeight = math.clamp(1 - (Lighting.Brightness / 3.2), 0.28, 1)
	local shimmer = if reduced then 0 else math.sin(clockNow * 7.2) * 0.025

	if turboActive then
		local base = if burnerActive then 0.56 + 0.18 * nightWeight else 0.24 + 0.12 * nightWeight
		state.deckGlow.setVisual(true, DECK_GLOW_TURBO_COLOR, base + shimmer)
	elseif burnerActive then
		local base = 0.44 + 0.16 * nightWeight
		state.deckGlow.setVisual(true, DECK_GLOW_WARM_COLOR, base + shimmer)
	else
		local base = 0.11 + 0.13 * nightWeight
		state.deckGlow.setVisual(true, DECK_GLOW_WARM_COLOR, base + shimmer * 0.5)
	end
end

function BalloonVFX.Step(serverNow: number, eyePos: Vector3)
	local clockNow = os.clock()
	local reduced = isReducedMotion()
	updateDistantStaticLights(eyePos, clockNow)
	for model, state in pairs(tracked) do
		if not model.Parent or not state.root.Parent then
			BalloonVFX.Detach(model)
		else
			local pos = state.root.Position
			local dt = math.max(1e-3, clockNow - state.lastStepClock)
			local speedMag = (pos - state.lastPos).Magnitude / dt
			state.lastPos = pos
			state.lastStepClock = clockNow

			local inRange = (pos - eyePos).Magnitude <= CULL_DISTANCE
			updateKitBurstVisuals(state, clockNow)
			updateTurboBurstVisuals(state, clockNow)
			updateShieldState(state, serverNow, clockNow, inRange, reduced)
			updateTurboState(state, serverNow, speedMag, inRange, reduced)
			updateDeckGlow(state, clockNow, inRange, reduced)
		end
	end
end

return BalloonVFX
