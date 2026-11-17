-- Obstacle sounds (AUDIO-01). Client-only: approach/destroy cues for enemies, telegraph/active
-- cues for hazards and the Storm Curtain. Balloon puncture/patch sounds stay in BalloonVFX.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local ContentProvider = game:GetService("ContentProvider")
local TweenService = game:GetService("TweenService")

local localPlayer = Players.LocalPlayer
local fly = ReplicatedStorage:WaitForChild("FlyHigh")
local modules = fly:WaitForChild("Modules")
local Catalog = require(modules:WaitForChild("ObstacleAudioCatalog"))
local AudioMixer = require(modules:WaitForChild("AudioMixer"))
local Config = require(modules:WaitForChild("FlyHighConfig"))
local remotes = fly:WaitForChild("Remotes")

AudioMixer.Bind(localPlayer)
local sfxGroup = AudioMixer.GetGroup("SFX")

local PRIORITY = { approach = 1, telegraph = 2, destroy = 3, charge = 3, strike = 4, active = 4 }
local mobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local maxVoices = mobile and Catalog.MAX_VOICES_MOBILE or Catalog.MAX_VOICES

local voices = {}
local duck = 1
local cooldown = {}
local tracked = setmetatable({}, { __mode = "k" })

local stats = Instance.new("Folder")
stats.Name = "FlyHighObstacleAudio"
stats:SetAttribute("Played", 0)
stats:SetAttribute("Evicted", 0)
stats:SetAttribute("Active", 0)
stats.Parent = script

-- Preload every asset once so one-shot lengths are known and the first cue is not late.
task.spawn(function()
	local list = {}
	for name, id in Catalog.Assets do
		local s = Instance.new("Sound")
		s.Name = name
		s.SoundId = id
		s.Parent = stats
		table.insert(list, s)
	end
	pcall(function() ContentProvider:PreloadAsync(list) end)
	local loaded = 0
	for _, s in list do if s.IsLoaded then loaded += 1 end end
	stats:SetAttribute("LoadedAssets", loaded)
	stats:SetAttribute("TotalAssets", #list)
end)

local function pick(value)
	if type(value) == "table" then
		return value[1] + math.random() * (value[2] - value[1])
	end
	return value or 1
end

local function emitterPosition(voice)
	local parent = voice.sound.Parent
	if parent and parent:IsA("BasePart") then return parent.Position end
	if parent and parent:IsA("Attachment") then return parent.WorldPosition end
	return nil
end

local function listener()
	local camera = workspace.CurrentCamera
	return camera and camera.CFrame.Position or Vector3.zero
end

local function score(priority, position)
	local distance = position and (position - listener()).Magnitude or 1e5
	return priority * 100000 - distance
end

local function removeVoice(voice)
	local index = table.find(voices, voice)
	if index then table.remove(voices, index) end
	stats:SetAttribute("Active", #voices)
end

local function stopVoice(voice, fade)
	if voice.stopped then return end
	voice.stopped = true
	removeVoice(voice)
	local sound = voice.sound
	if not sound.Parent then return end
	if fade and fade > 0 then
		local tween = TweenService:Create(sound, TweenInfo.new(fade), { Volume = 0 })
		tween:Play()
		tween.Completed:Connect(function() sound:Destroy() end)
	else
		sound:Destroy()
	end
end

local function makeRoom(priority, position)
	if #voices < maxVoices then return true end
	local wanted = score(priority, position)
	local weakest, weakestScore
	for _, voice in voices do
		local s = score(voice.priority, emitterPosition(voice))
		if not weakestScore or s < weakestScore then weakest, weakestScore = voice, s end
	end
	if weakest and weakestScore < wanted then
		stopVoice(weakest, 0.15)
		stats:SetAttribute("Evicted", stats:GetAttribute("Evicted") + 1)
		return true
	end
	return false
end

local function play(cue, parent, layer)
	local asset = Catalog.Assets[cue.asset]
	if not asset or not parent or not parent.Parent then return nil end
	local priority = PRIORITY[layer] or 1
	local position = parent:IsA("Attachment") and parent.WorldPosition or parent.Position
	if not makeRoom(priority, position) then return nil end
	local sound = Instance.new("Sound")
	sound.Name = "ObstacleCue_" .. cue.asset
	sound.SoundId = asset
	sound.PlaybackSpeed = pick(cue.pitch)
	sound.Volume = cue.volume * duck
	sound.Looped = cue.loop == true
	local range = cue.range or { 10, 220 }
	sound.RollOffMode = Enum.RollOffMode.InverseTapered
	sound.RollOffMinDistance = range[1]
	sound.RollOffMaxDistance = range[2]
	sound.SoundGroup = sfxGroup
	sound.Parent = parent
	local voice = { sound = sound, priority = priority, base = cue.volume }
	table.insert(voices, voice)
	stats:SetAttribute("Active", #voices)
	stats:SetAttribute("Played", stats:GetAttribute("Played") + 1)
	if sound.Looped and sound.TimeLength > 0 then
		sound.TimePosition = math.random() * sound.TimeLength
	end
	sound:Play()
	sound.Destroying:Connect(function() voice.stopped = true removeVoice(voice) end)
	if not sound.Looped then
		local length = sound.TimeLength > 0 and sound.TimeLength / sound.PlaybackSpeed or 4
		local duration = math.min(cue.duration or length, length)
		task.delay(math.max(0.05, duration - (cue.fade or 0)), function() stopVoice(voice, cue.fade or 0.1) end)
	end
	return voice
end

local function playList(list, parent, layer, bucket)
	for _, cue in list or {} do
		if cue.repeatEvery then
			local alive = { stopped = false }
			if bucket then table.insert(bucket, alive) end
			task.spawn(function()
				while not alive.stopped and parent.Parent do
					play(cue, parent, layer)
					task.wait(cue.repeatEvery * (0.8 + math.random() * 0.4))
				end
			end)
		else
			local voice = play(cue, parent, layer)
			if voice and bucket then table.insert(bucket, voice) end
		end
	end
end

local function stopBucket(bucket, fade)
	for _, voice in bucket do
		if voice.sound then stopVoice(voice, fade) else voice.stopped = true end
	end
	table.clear(bucket)
end

-- One-shot at a world point (destroyed enemies keep sounding after the model is gone).
local function playAt(list, position, layer)
	local anchor = Instance.new("Attachment")
	anchor.Name = "ObstacleAudioPoint"
	anchor.WorldPosition = position
	anchor.Parent = workspace.Terrain
	playList(list, anchor, layer, nil)
	task.delay(5, function() anchor:Destroy() end)
end

local function emitterOf(model)
	local part = model.PrimaryPart
	if part then return part end
	return model:FindFirstChildWhichIsA("BasePart", true)
end

local function watch(model, profile, isHazard)
	if tracked[model] then return end
	local entry = { loops = {} }
	tracked[model] = entry
	local emitter = emitterOf(model)
	local deadline = os.clock() + 2
	while not emitter and model.Parent and os.clock() < deadline do
		task.wait(0.1)
		emitter = emitterOf(model)
	end
	if not emitter then return end

	if isHazard then
		local function refresh()
			stopBucket(entry.loops, 0.4)
			local active = model:GetAttribute("HazardActive") == true or model:GetAttribute("Stage") == "Active"
			playList(active and profile.active or profile.telegraph, emitter, active and "active" or "telegraph", entry.loops)
		end
		refresh()
		model:GetAttributeChangedSignal("HazardActive"):Connect(refresh)
		model:GetAttributeChangedSignal("Stage"):Connect(refresh)
		if profile.strike then
			model:GetAttributeChangedSignal("Strike"):Connect(function()
				local strike = model:GetAttribute("Strike")
				if strike and strike > 0 then playList(profile.strike, emitter, "strike", nil) end
			end)
		end
	else
		local effect = model:GetAttribute("ObstacleEffect") or model.Name
		local now = os.clock()
		local allowOneShots = now >= (cooldown[effect] or 0)
		if allowOneShots then cooldown[effect] = now + Catalog.APPROACH_COOLDOWN end
		for _, cue in profile.approach or {} do
			if cue.loop or allowOneShots then
				local voice = play(cue, emitter, "approach")
				if voice and cue.loop then table.insert(entry.loops, voice) end
			end
		end
		if profile.charge then
			model:GetAttributeChangedSignal("Charging"):Connect(function()
				if model:GetAttribute("Charging") == true then playList(profile.charge, emitter, "charge", nil) end
			end)
		end
	end
	model.AncestryChanged:Connect(function(_, parent)
		if not parent then stopBucket(entry.loops, 0.25) end
	end)
end

local function onObstacle(model)
	if not model:IsA("Model") then return end
	local effect = model:GetAttribute("ObstacleEffect")
	if not effect then
		-- Attributes replicate with the instance; a short wait covers streaming order.
		local deadline = os.clock() + 1
		while not effect and model.Parent and os.clock() < deadline do
			task.wait(0.05)
			effect = model:GetAttribute("ObstacleEffect")
		end
	end
	effect = effect or model.Name
	if Catalog.Enemies[effect] then
		watch(model, Catalog.Enemies[effect], false)
	elseif Catalog.Hazards[effect] then
		watch(model, Catalog.Hazards[effect], true)
	end
end

local function bindFolder(name, handler)
	task.spawn(function()
		local folder = workspace:WaitForChild(name, 30)
		if not folder then return end
		for _, child in folder:GetChildren() do task.spawn(handler, child) end
		folder.ChildAdded:Connect(function(child) task.spawn(handler, child) end)
	end)
end

bindFolder("FlyHighObstacles", onObstacle)
bindFolder("FlyHighLargeChallenges", function(model)
	if model:IsA("Model") and model.Name:match("^StormCurtain") then
		watch(model, Catalog.Hazards.StormCurtain, true)
	end
end)

remotes:WaitForChild("WeaponFireEvent").OnClientEvent:Connect(function(_, _, hitPosition, impact)
	if typeof(impact) ~= "table" or impact.kind ~= "Kill" or typeof(hitPosition) ~= "Vector3" then return end
	local profile = Catalog.Enemies[impact.targetName]
	if profile and profile.destroy then playAt(profile.destroy, hitPosition, "destroy") end
end)

-- Duck obstacle sounds under high-priority warnings (Storm, Freefall, RopeCritical).
local profiles = Config.AUDIO_WARNINGS and Config.AUDIO_WARNINGS.PROFILES or {}
local function applyDuck(key)
	local profile = profiles[key or ""]
	local target = (profile and profile.priority >= Catalog.DUCK_PRIORITY) and Catalog.DUCK_GAIN or 1
	if target == duck then return end
	duck = target
	for _, voice in voices do
		if voice.sound.Parent then voice.sound.Volume = voice.base * duck end
	end
	stats:SetAttribute("Duck", duck)
end
task.spawn(function()
	local scripts = localPlayer:WaitForChild("PlayerScripts")
	local controller = scripts:WaitForChild("WarningAudioController", 30)
	local folder = controller and controller:WaitForChild("FlyHighWarningAudio", 30)
	if not folder then return end
	applyDuck(folder:GetAttribute("ActiveWarning"))
	folder:GetAttributeChangedSignal("ActiveWarning"):Connect(function()
		applyDuck(folder:GetAttribute("ActiveWarning"))
	end)
end)