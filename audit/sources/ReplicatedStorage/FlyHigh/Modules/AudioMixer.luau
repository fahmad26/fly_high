-- Shared audio bus mixer (Master, Music, SFX) driving SoundService SoundGroups from player attributes.
local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")

local Mixer = {}

Mixer.CHANNELS = {
	{
		key = "Master",
		label = "Master Volume",
		volumeAttr = "AudioMasterVolume",
		mutedAttr = "AudioMasterMuted",
		defaultVolume = 1,
		accent = Color3.fromRGB(255, 208, 72),
	},
	{
		key = "Music",
		label = "Music Volume",
		volumeAttr = "AudioMusicVolume",
		mutedAttr = "AudioMusicMuted",
		defaultVolume = 0.60,
		accent = Color3.fromRGB(64, 204, 255),
	},
	{
		key = "SFX",
		label = "Sound Effect",
		volumeAttr = "AudioSFXVolume",
		mutedAttr = "AudioSFXMuted",
		defaultVolume = 1,
		accent = Color3.fromRGB(64, 232, 148),
	},
}

local SPEC_BY_KEY = {}
for _, spec in Mixer.CHANNELS do
	SPEC_BY_KEY[spec.key] = spec
end

local BOUND_ATTR = "FlyHighAudioMixerBound"
local LEGACY_WARNING_MUTE_ATTR = "WarningAudioMuted"

local observers: { { player: Player, fn: () -> () } } = {}

local function resolvePlayer(player: Player?): Player?
	return player or Players.LocalPlayer
end

local function ensureMusicSafetyEffects(musicGroup: SoundGroup)
	local limiter = musicGroup:FindFirstChild("MusicSafetyLimiter")
	if not limiter or not limiter:IsA("CompressorSoundEffect") then
		limiter = Instance.new("CompressorSoundEffect")
		limiter.Name = "MusicSafetyLimiter"
		limiter.Threshold = -18
		limiter.Ratio = 5
		limiter.Attack = 0.015
		limiter.Release = 0.28
		limiter.GainMakeup = 0
		limiter.Priority = 1
		limiter.Enabled = true
		limiter.Parent = musicGroup
	end

	local eq = musicGroup:FindFirstChild("MusicVoicePocketEQ")
	if not eq or not eq:IsA("EqualizerSoundEffect") then
		eq = Instance.new("EqualizerSoundEffect")
		eq.Name = "MusicVoicePocketEQ"
		eq.LowGain = -1.0
		eq.MidGain = -2.5
		eq.HighGain = -2.0
		eq.Priority = 0
		eq.Enabled = true
		eq.Parent = musicGroup
	end
end

local function ensureMixerFolder(): (Folder, { [string]: SoundGroup })
	local folder = SoundService:FindFirstChild("FlyHighAudioMixer")
	if not folder or not folder:IsA("Folder") then
		folder = Instance.new("Folder")
		folder.Name = "FlyHighAudioMixer"
		folder.Parent = SoundService
	end

	local groups = {}
	for _, spec in Mixer.CHANNELS do
		local sg = folder:FindFirstChild(spec.key)
		if not sg or not sg:IsA("SoundGroup") then
			sg = Instance.new("SoundGroup")
			sg.Name = spec.key
			sg.Volume = spec.defaultVolume
			sg.Parent = folder
		end
		groups[spec.key] = sg
	end
	if groups.Music then
		ensureMusicSafetyEffects(groups.Music)
	end
	return folder, groups
end

function Mixer.EnsureDefaults(player: Player?)
	local p = resolvePlayer(player)
	if not p then
		return
	end
	for _, spec in Mixer.CHANNELS do
		if typeof(p:GetAttribute(spec.volumeAttr)) ~= "number" then
			p:SetAttribute(spec.volumeAttr, spec.defaultVolume)
		end
		if typeof(p:GetAttribute(spec.mutedAttr)) ~= "boolean" then
			p:SetAttribute(spec.mutedAttr, false)
		end
	end
end

function Mixer.GetSpec(key: string)
	return SPEC_BY_KEY[key]
end

function Mixer.GetVolume(player: Player?, key: string): number
	local spec = SPEC_BY_KEY[key]
	if not spec then
		return 1
	end
	local p = resolvePlayer(player)
	if not p then
		return spec.defaultVolume
	end
	local v = p:GetAttribute(spec.volumeAttr)
	if typeof(v) ~= "number" then
		return spec.defaultVolume
	end
	return math.clamp(v, 0, 1)
end

function Mixer.IsMuted(player: Player?, key: string): boolean
	local spec = SPEC_BY_KEY[key]
	if not spec then
		return false
	end
	local p = resolvePlayer(player)
	if not p then
		return false
	end
	if p:GetAttribute(spec.mutedAttr) == true then
		return true
	end
	if key == "SFX" and p:GetAttribute(LEGACY_WARNING_MUTE_ATTR) == true then
		return true
	end
	return false
end

function Mixer.GetChannelRawGain(player: Player?, key: string): number
	if Mixer.IsMuted(player, key) then
		return 0
	end
	return Mixer.GetVolume(player, key)
end

function Mixer.GetMasterGain(player: Player?): number
	return Mixer.GetChannelRawGain(player, "Master")
end

function Mixer.GetMusicScale(player: Player?): number
	return Mixer.GetMasterGain(player) * Mixer.GetChannelRawGain(player, "Music")
end

function Mixer.GetSFXScale(player: Player?): number
	return Mixer.GetMasterGain(player) * Mixer.GetChannelRawGain(player, "SFX")
end

function Mixer.IsOverallMuted(player: Player?): boolean
	return Mixer.GetMusicScale(player) <= 0 and Mixer.GetSFXScale(player) <= 0
end

function Mixer.SetVolume(player: Player?, key: string, volume: number)
	local spec = SPEC_BY_KEY[key]
	local p = resolvePlayer(player)
	if not spec or not p then
		return
	end
	local snapped = math.round(math.clamp(volume, 0, 1) * 100) / 100
	p:SetAttribute(spec.volumeAttr, snapped)
end

function Mixer.SetMuted(player: Player?, key: string, muted: boolean)
	local spec = SPEC_BY_KEY[key]
	local p = resolvePlayer(player)
	if not spec or not p then
		return
	end
	local flag = muted == true
	p:SetAttribute(spec.mutedAttr, flag)
	-- Keep legacy warning attribute cleared when unmuting SFX/Master from the popup.
	if not flag and (key == "SFX" or key == "Master") and p:GetAttribute(LEGACY_WARNING_MUTE_ATTR) == true then
		if key == "SFX" or p:GetAttribute("AudioSFXMuted") ~= true then
			p:SetAttribute(LEGACY_WARNING_MUTE_ATTR, false)
		end
	end
end

function Mixer.ToggleMuted(player: Player?, key: string)
	Mixer.SetMuted(player, key, not Mixer.IsMuted(player, key))
end

function Mixer.GetGroup(key: string): SoundGroup
	local _, groups = ensureMixerFolder()
	return groups[key] or groups.SFX
end

function Mixer.Sync(player: Player?)
	local p = resolvePlayer(player)
	local _, groups = ensureMixerFolder()
	if not p then
		return
	end
	groups.Master.Volume = Mixer.GetMasterGain(p)
	groups.Music.Volume = Mixer.GetMusicScale(p)
	groups.SFX.Volume = Mixer.GetSFXScale(p)
end

function Mixer.Bind(player: Player?)
	local p = resolvePlayer(player)
	if not p then
		return
	end
	Mixer.EnsureDefaults(p)
	Mixer.Sync(p)

	if p:GetAttribute(BOUND_ATTR) then
		return
	end
	p:SetAttribute(BOUND_ATTR, true)

	local function notifyAll()
		Mixer.Sync(p)
		for i = #observers, 1, -1 do
			local entry = observers[i]
			if entry.player == p then
				task.spawn(entry.fn)
			end
		end
	end

	for _, spec in Mixer.CHANNELS do
		p:GetAttributeChangedSignal(spec.volumeAttr):Connect(notifyAll)
		p:GetAttributeChangedSignal(spec.mutedAttr):Connect(notifyAll)
	end
	p:GetAttributeChangedSignal(LEGACY_WARNING_MUTE_ATTR):Connect(notifyAll)
end

function Mixer.Observe(player: Player?, callback: () -> ())
	local p = resolvePlayer(player)
	if p then
		Mixer.Bind(p)
	end
	local entry = { player = p :: Player, fn = callback }
	table.insert(observers, entry)
	task.spawn(callback)

	local active = true
	return {
		Disconnect = function()
			if not active then
				return
			end
			active = false
			local idx = table.find(observers, entry)
			if idx then
				table.remove(observers, idx)
			end
		end,
	}
end

return Mixer