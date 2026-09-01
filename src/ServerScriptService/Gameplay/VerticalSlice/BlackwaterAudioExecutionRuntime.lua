--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AudioConfig = require(ReplicatedStorage.Config.BlackwaterAudioExecutionConfig)

local Runtime = {}
local initialized = false
local root: Instance? = nil
local activeSnapshot = "ordinary_london"
local activeZone = "exterior_street"
local activeSilence: string? = nil
local eventLog = {}
local voiceCounters = {
	requested = 0,
	accepted = 0,
	rejected = 0,
	stolen = 0,
	peak = 0,
	leaked = 0,
}
local activeVoices: { { id: string, bus: string, priority: number, critical: boolean } } = {}
local shuffleState: { [string]: number } = {}

local function append(entry: { [string]: any })
	if #eventLog >= 160 then
		table.remove(eventLog, 1)
	end
	eventLog[#eventLog + 1] = table.freeze(entry)
end

local function publish(name: string, value: any)
	if root then
		root:SetAttribute(name, value)
	end
end

local function limitFor(bus: string): number
	return AudioConfig.VoiceLimits[bus] or 4
end

local function countBus(bus: string): number
	local count = 0
	for _, voice in ipairs(activeVoices) do
		if voice.bus == bus then
			count += 1
		end
	end
	return count
end

local function lowestVoice(bus: string): (number?, number)
	local lowestIndex = nil
	local lowestPriority = math.huge
	for index, voice in ipairs(activeVoices) do
		if voice.bus == bus and not voice.critical and voice.priority < lowestPriority then
			lowestIndex = index
			lowestPriority = voice.priority
		end
	end
	return lowestIndex, lowestPriority
end

local function countKeys(source: { [string]: any }): number
	local total = 0
	for _ in pairs(source) do
		total += 1
	end
	return total
end

function Runtime.initialize(worldRoot: Instance?)
	initialized = true
	root = worldRoot
	activeSnapshot = "ordinary_london"
	activeZone = "exterior_street"
	activeSilence = nil
	eventLog = {}
	activeVoices = {}
	shuffleState = {}
	voiceCounters.requested = 0
	voiceCounters.accepted = 0
	voiceCounters.rejected = 0
	voiceCounters.stolen = 0
	voiceCounters.peak = 0
	voiceCounters.leaked = 0
	publish("AudioExecutionIdentity", AudioConfig.AudioIdentity)
	publish("AudioExecutionSnapshot", activeSnapshot)
	publish("AudioExecutionZone", activeZone)
	publish("AudioExecutionAssetsReady", false)
	publish("AudioExecutionEvidenceState", AudioConfig.AssetEvidenceState)
end

function Runtime.selectFootstep(
	surfaceId: string,
	movementState: string,
	userId: number
): (boolean, { [string]: any }?)
	local surface = AudioConfig.SurfaceLibrary[surfaceId]
	local movement = AudioConfig.MovementStates[movementState]
	if not surface or not movement then
		return false, nil
	end
	local key = surfaceId .. ":" .. movementState .. ":" .. tostring(userId)
	local nextIndex = (shuffleState[key] or 0) % 7 + 1
	shuffleState[key] = nextIndex
	local intensity = math.clamp(surface.baseVolume * movement.volumeScale, 0, 1)
	local suspicion = math.clamp(movement.suspicionScale * surface.baseVolume, 0, 2)
	local plan = {
		variation = nextIndex,
		surface = surfaceId,
		movement = movementState,
		overlay = surface.overlay,
		volume = intensity,
		pitchOffset = ((nextIndex - 4) / 4) * surface.pitchWindow,
		suspicion = suspicion,
		assetStatus = AudioConfig.AssetEvidenceState,
	}
	append({
		kind = "footstep",
		surface = surfaceId,
		movement = movementState,
		variation = nextIndex,
	})
	return true, table.freeze(plan)
end

function Runtime.requestVoice(
	id: string,
	bus: string,
	priority: number,
	critical: boolean
): (boolean, string)
	voiceCounters.requested += 1
	local limit = limitFor(bus)
	if countBus(bus) >= limit then
		local stealIndex, stealPriority = lowestVoice(bus)
		if stealIndex ~= nil and priority > stealPriority then
			table.remove(activeVoices, stealIndex)
			voiceCounters.stolen += 1
		else
			voiceCounters.rejected += 1
			append({ kind = "voiceRejected", id = id, bus = bus, priority = priority })
			return false, "VoiceLimitReached"
		end
	end
	activeVoices[#activeVoices + 1] = table.freeze({
		id = id,
		bus = bus,
		priority = math.clamp(priority, 0, 100),
		critical = critical,
	})
	voiceCounters.accepted += 1
	voiceCounters.peak = math.max(voiceCounters.peak, #activeVoices)
	return true, "VoiceAccepted"
end

function Runtime.setAcousticZone(zoneId: string): (boolean, string?)
	if not AudioConfig.AcousticZones[zoneId] then
		return false, "UnknownAcousticZone"
	end
	activeZone = zoneId
	publish("AudioExecutionZone", zoneId)
	append({ kind = "zone", zoneId = zoneId })
	return true, nil
end

function Runtime.setMixSnapshot(snapshotId: string, reason: string): (boolean, string?)
	if not AudioConfig.MixSnapshots[snapshotId] then
		return false, "UnknownMixSnapshot"
	end
	if snapshotId ~= activeSnapshot then
		activeSnapshot = snapshotId
		publish("AudioExecutionSnapshot", snapshotId)
		publish("AudioExecutionMixReason", reason)
		append({ kind = "mix", snapshotId = snapshotId, reason = reason })
	end
	return true, nil
end

function Runtime.enterSilence(silenceId: string, reason: string): (boolean, string?)
	if not AudioConfig.SilenceStates[silenceId] then
		return false, "UnknownSilenceState"
	end
	activeSilence = silenceId
	publish("AudioExecutionSilence", silenceId)
	append({ kind = "silence", silenceId = silenceId, reason = reason })
	return true, nil
end

function Runtime.exitSilence(reason: string)
	if activeSilence then
		append({ kind = "silenceExit", silenceId = activeSilence, reason = reason })
	end
	activeSilence = nil
	publish("AudioExecutionSilence", "")
end

function Runtime.applyBailiffState(state: string, reason: string): { [string]: any }?
	local profile = AudioConfig.BailiffAudioStates[state]
	if not profile then
		return nil
	end
	Runtime.setMixSnapshot(profile.mix, reason)
	publish("BailiffAudioCaption", profile.caption)
	publish("BailiffAudioTelegraph", profile.telegraph)
	append({
		kind = "bailiff",
		state = state,
		caption = profile.caption,
		telegraph = profile.telegraph,
	})
	return profile
end

function Runtime.applyObjective(objectiveId: string, pressure: number)
	if objectiveId == "ignite_lantern" then
		Runtime.setAcousticZone("covered_entrance")
		Runtime.setMixSnapshot("house_noticed_player", "lantern_ignited")
		Runtime.enterSilence("gate_threshold", "lantern_boundary")
		Runtime.requestVoice("lantern-glass", "interactions", 78, true)
	elseif objectiveId == "read_ledger" then
		Runtime.setAcousticZone("gallery")
		Runtime.setMixSnapshot("investigation", "ledger_read")
		Runtime.requestVoice("case-file-paper", "interactions", 72, true)
	elseif objectiveId == "take_seal" then
		Runtime.setMixSnapshot("suspicion", "seal_taken")
		Runtime.requestVoice("brass-seal", "interactions", 78, true)
	elseif string.sub(objectiveId, 1, 5) == "ward_" then
		Runtime.setAcousticZone("ward_chambers")
		Runtime.setMixSnapshot("puzzle_concentration", "ward_attempt")
		Runtime.requestVoice(objectiveId, "interactions", 86, true)
	elseif objectiveId == "open_archive" then
		Runtime.setAcousticZone("archive")
		Runtime.setMixSnapshot("archive_reveal", "archive_opened")
		Runtime.exitSilence("archive_truth")
	elseif objectiveId == "take_heart" then
		Runtime.setAcousticZone("ritual_chamber")
		Runtime.setMixSnapshot("glass_heart_possession", "heart_taken")
		Runtime.enterSilence("glass_heart_removal", "heart_removed")
		Runtime.requestVoice("glass-heart", "interactions", 96, true)
	elseif objectiveId == "escape_gate" then
		Runtime.setAcousticZone(if pressure >= 0.9 then "blackout_house" else "dawn_street")
		Runtime.setMixSnapshot(if pressure >= 0.9 then "escape" else "dawn", "escape")
		Runtime.enterSilence("pre_escape_breath", "escape_gate")
	end
end

function Runtime.captionForWard(wardId: string): string?
	local ward = AudioConfig.WardAudioLanguage[wardId]
	return if ward then ward.caption else nil
end

function Runtime.inspect()
	return {
		initialized = initialized,
		schemaVersion = AudioConfig.SchemaVersion,
		audioIdentity = AudioConfig.AudioIdentity,
		activeSnapshot = activeSnapshot,
		activeZone = activeZone,
		activeSilence = activeSilence,
		surfaceCount = countKeys(AudioConfig.SurfaceLibrary),
		movementStateCount = countKeys(AudioConfig.MovementStates),
		acousticZoneCount = countKeys(AudioConfig.AcousticZones),
		mixSnapshotCount = countKeys(AudioConfig.MixSnapshots),
		musicStemCount = countKeys(AudioConfig.MusicStems),
		voiceCounters = table.clone(voiceCounters),
		activeVoiceCount = #activeVoices,
		eventLog = table.clone(eventLog),
		assetEvidenceState = AudioConfig.AssetEvidenceState,
		certificationState = AudioConfig.CertificationState,
	}
end

function Runtime.runSelfChecks()
	Runtime.initialize(nil)
	local footstepOk, footstep = Runtime.selectFootstep("wet_cobblestone", "walk", -206)
	local repeatOk, repeatFootstep = Runtime.selectFootstep("wet_cobblestone", "walk", -206)
	local invalidFootstep = Runtime.selectFootstep("unknown", "walk", -206)
	local zoneOk = Runtime.setAcousticZone("archive")
	local badZone = Runtime.setAcousticZone("unknown")
	local mixOk = Runtime.setMixSnapshot("active_hunt", "self_check")
	local silenceOk = Runtime.enterSilence("hiding_close_pass", "self_check")
	for index = 1, 8 do
		Runtime.requestVoice("footstep-" .. tostring(index), "footsteps", index, false)
	end
	local rejected = Runtime.requestVoice("quiet-detail", "footsteps", 1, false)
	local stolen = Runtime.requestVoice("critical-step", "footsteps", 99, true)
	local bailiffProfile = Runtime.applyBailiffState("Hunt", "self_check")
	return {
		ok = footstepOk == true
			and repeatOk == true
			and footstep ~= nil
			and repeatFootstep ~= nil
			and footstep.variation ~= repeatFootstep.variation
			and invalidFootstep == false
			and zoneOk == true
			and badZone == false
			and mixOk == true
			and silenceOk == true
			and rejected == true
			and stolen == true
			and bailiffProfile ~= nil
			and bailiffProfile.telegraph == true,
		snapshot = Runtime.inspect(),
	}
end

function Runtime.shutdown()
	initialized = false
	root = nil
	activeSnapshot = "shutdown"
	activeSilence = nil
	eventLog = {}
	activeVoices = {}
	shuffleState = {}
end

return Runtime
