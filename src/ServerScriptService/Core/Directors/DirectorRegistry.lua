--!strict

local DirectorApproval = require(script.Parent.DirectorApproval)
local DirectorCapabilities = require(script.Parent.DirectorCapabilities)
local Types = require(script.Parent.DirectorTypes)

local DirectorRegistry = {}

type DirectorDescription = Types.DirectorDescription

local descriptions: { DirectorDescription } = {
	{
		name = "PsychologicalHorror",
		displayName = "Psychological Horror Director",
		responsibilities = { "fear pacing interpretation" },
		doesNotOwn = { "monster movement", "final scares" },
		capabilities = {
			{
				id = "Horror.Tension",
				description = "Tension interpretation.",
				requestKinds = { "RequestHorrorPressure" },
			},
		},
	},
	{
		name = "Narrative",
		displayName = "Narrative Director",
		responsibilities = { "narrative beat gates" },
		doesNotOwn = { "lore storage", "execution" },
		capabilities = {
			{
				id = "Narrative.Beat",
				description = "Beat, climax, and reveal windows.",
				requestKinds = { "RequestNarrativeBeat" },
			},
		},
	},
	{
		name = "Story",
		displayName = "Story Director",
		responsibilities = { "story clarity and lore timing" },
		doesNotOwn = { "UI rendering", "puzzle validation" },
		capabilities = {
			{
				id = "Story.Lore",
				description = "Lore trigger timing.",
				requestKinds = { "RequestLoreTrigger" },
			},
		},
	},
	{
		name = "Environment",
		displayName = "Environment Director",
		responsibilities = { "world reaction permission" },
		doesNotOwn = { "lighting values", "audio playback" },
		capabilities = {
			{
				id = "Environment.Reaction",
				description = "Fog, rain, door reaction, prop shift, building reaction.",
				requestKinds = { "RequestEnvironmentReaction" },
			},
		},
	},
	{
		name = "Lighting",
		displayName = "Lighting Director",
		responsibilities = { "visibility pressure permission" },
		doesNotOwn = { "monster attacks", "final rendering" },
		capabilities = {
			{
				id = "Lighting.VisibilityPressure",
				description = "Flicker, dim, restore, shadow, visibility pressure.",
				requestKinds = { "RequestLightingChange" },
			},
		},
	},
	{
		name = "Audio",
		displayName = "Audio Director",
		responsibilities = { "audio pressure permission" },
		doesNotOwn = { "music score", "client fear truth" },
		capabilities = {
			{
				id = "Audio.Pressure",
				description = "Whisper, footsteps, breathing, silence, audio pressure.",
				requestKinds = { "RequestAudioCue" },
			},
		},
	},
	{
		name = "Music",
		displayName = "Music Director",
		responsibilities = { "music state permission" },
		doesNotOwn = { "chase truth", "audio deception" },
		capabilities = {
			{
				id = "Music.State",
				description = "Stinger, chase score, silence, tension bed.",
				requestKinds = { "RequestMusicState" },
			},
		},
	},
	{
		name = "Monster",
		displayName = "Monster Director",
		responsibilities = { "monster permission windows" },
		doesNotOwn = { "pathfinding", "horror pacing ownership" },
		capabilities = {
			{
				id = "Monster.Permission",
				description = "Reveal, stalk, chase, retreat, fake leave, watch.",
				requestKinds = { "RequestMonsterReveal", "RequestMonsterAttack" },
			},
		},
	},
	{
		name = "Puzzle",
		displayName = "Puzzle Director",
		responsibilities = { "puzzle fairness permission" },
		doesNotOwn = { "inventory truth", "door animation" },
		capabilities = {
			{
				id = "Puzzle.Fairness",
				description = "Hint, fairness, lock pressure, puzzle gate.",
				requestKinds = { "RequestPuzzleHint" },
			},
		},
	},
	{
		name = "Save",
		displayName = "Save Director",
		responsibilities = { "checkpoint and recovery policy" },
		doesNotOwn = { "DataStore implementation alone", "UI" },
		capabilities = {
			{
				id = "Save.Policy",
				description = "Checkpoint, recovery, profile write.",
				requestKinds = { "RequestCheckpoint" },
			},
		},
	},
	{
		name = "Difficulty",
		displayName = "Difficulty Director",
		responsibilities = { "adaptive tuning recommendations" },
		doesNotOwn = { "client cheats", "puzzle answers" },
		capabilities = {
			{
				id = "Difficulty.Tuning",
				description = "Assist, tune pressure, scale challenge.",
				requestKinds = { "RequestDifficultyAdjustment" },
			},
		},
	},
	{
		name = "Performance",
		displayName = "Performance Director",
		responsibilities = { "budget and throttle recommendations" },
		doesNotOwn = { "creative pacing", "story truth" },
		capabilities = {
			{
				id = "Performance.Budget",
				description = "Budget, throttle, cleanup.",
				requestKinds = { "RequestPerformanceBudget" },
			},
		},
	},
}

local function copyCapabilities(
	capabilities: { Types.DirectorCapability }
): { Types.DirectorCapability }
	local copied = {}

	for _, capability in ipairs(capabilities) do
		table.insert(copied, {
			id = capability.id,
			description = capability.description,
			requestKinds = table.clone(capability.requestKinds),
		})
	end

	return copied
end

local function createFoundationDirector(description: DirectorDescription): Types.Director
	local initialized = false
	local started = false
	local startedAt = 0
	local observationCount = 0
	local approvalCount = 0
	local cancelCount = 0
	local lastObservation: any = nil

	local director = {}

	function director:initialize()
		initialized = true
	end

	function director:start()
		if not initialized then
			self:initialize()
		end

		started = true
		startedAt = os.clock()
	end

	function director:shutdown()
		started = false
	end

	function director:observe(observation: any)
		observationCount += 1
		lastObservation = observation
	end

	function director:requestApproval(request: Types.DirectorRequest): Types.DirectorApproval
		approvalCount += 1
		return DirectorApproval.create(
			request.requestId,
			"Deferred",
			"Foundation Director records request but does not execute behavior.",
			description.name,
			nil,
			{}
		)
	end

	function director:cancelRequest(requestId: string, reason: string?): Types.DirectorApproval
		cancelCount += 1
		return DirectorApproval.create(
			requestId,
			"Cancelled",
			reason or "Request cancelled.",
			description.name,
			nil,
			{}
		)
	end

	function director:getCapabilities()
		return copyCapabilities(description.capabilities)
	end

	function director:getHealth(): Types.DirectorHealth
		return {
			name = description.name,
			status = if started then "Running" elseif initialized then "Ready" else "NotInitialized",
			healthy = true,
			message = nil,
			uptime = if startedAt > 0 then os.clock() - startedAt else 0,
			lastError = nil,
		}
	end

	function director:getSnapshot()
		return {
			description = self:describe(),
			health = self:getHealth(),
			lastObservation = lastObservation,
		}
	end

	function director:getDiagnostics()
		return {
			initialized = initialized,
			started = started,
			observationCount = observationCount,
			approvalCount = approvalCount,
			cancelCount = cancelCount,
		}
	end

	function director:validate(): (boolean, string?)
		if #description.capabilities == 0 then
			return false, "Director requires capabilities"
		end

		return true, nil
	end

	function director:describe(): DirectorDescription
		return {
			name = description.name,
			displayName = description.displayName,
			responsibilities = table.clone(description.responsibilities),
			doesNotOwn = table.clone(description.doesNotOwn),
			capabilities = copyCapabilities(description.capabilities),
		}
	end

	return director :: any
end

function DirectorRegistry.createAll(): { Types.Director }
	local directors = {}

	for _, description in ipairs(descriptions) do
		DirectorCapabilities.register(description.name, description.capabilities)
		table.insert(directors, createFoundationDirector(description))
	end

	return directors
end

return DirectorRegistry
