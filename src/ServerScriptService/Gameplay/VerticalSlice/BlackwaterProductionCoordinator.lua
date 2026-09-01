--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ProductionConfig = require(ReplicatedStorage.Config.BlackwaterProductionConfig)
local AudioExecutionRuntime = require(script.Parent.BlackwaterAudioExecutionRuntime)
local AudioRuntime = require(script.Parent.BlackwaterAudioRuntime)
local BailiffPhysicalRuntime = require(script.Parent.BlackwaterBailiffPhysicalRuntime)
local ChaseRuntime = require(script.Parent.BlackwaterChaseRuntime)
local CinematicRuntime = require(script.Parent.BlackwaterCinematicRuntime)
local EnvironmentRuntime = require(script.Parent.BlackwaterEnvironmentProductionRuntime)
local InvestigationRuntime = require(script.Parent.BlackwaterInvestigationRuntime)
local MonsterRuntime = require(script.Parent.BlackwaterMonsterRuntime)
local NarrativeRuntime = require(script.Parent.BlackwaterNarrativeRuntime)
local PerceptionRuntime = require(script.Parent.BlackwaterPerceptionRuntime)
local PuzzleRuntime = require(script.Parent.BlackwaterPuzzleRuntime)
local QualityStrikeRuntime = require(script.Parent.BlackwaterQualityStrikeRuntime)
local ReplayRuntime = require(script.Parent.BlackwaterReplayRuntime)
local RunState = require(script.Parent.BlackwaterRunState)
local StealthRuntime = require(script.Parent.BlackwaterStealthRuntime)
local StreetAudioRuntime = require(script.Parent.BlackwaterStreetAudioRuntime)

local Coordinator = {}
local initialized = false
local started = false
local root: Instance? = nil
local noiseByUserId: { [number]: number } = {}

function Coordinator.initialize(worldRoot: Instance?)
	root = worldRoot
	RunState.initialize("Standard")
	EnvironmentRuntime.initialize()
	InvestigationRuntime.initialize()
	PuzzleRuntime.initialize()
	NarrativeRuntime.initialize()
	MonsterRuntime.initialize()
	BailiffPhysicalRuntime.initialize(root)
	QualityStrikeRuntime.initialize(root)
	StealthRuntime.initialize()
	ChaseRuntime.initialize()
	CinematicRuntime.initialize()
	AudioRuntime.initialize()
	StreetAudioRuntime.initialize(root)
	AudioExecutionRuntime.initialize(root)
	ReplayRuntime.initialize("Standard")
	PerceptionRuntime.initialize()
	initialized = true
	started = false
	if root then
		root:SetAttribute("ProductionProgramVersion", ProductionConfig.ProgramVersion)
		root:SetAttribute("RunSeed", ProductionConfig.RunSeed)
		root:SetAttribute("BailiffState", MonsterRuntime.inspect().currentState)
		root:SetAttribute("EndingId", "undecided")
		root:SetAttribute("AudioState", "quiet")
		root:SetAttribute("BailiffPhysicalStatus", "productionProxyReplacementRequired")
		root:SetAttribute("BailiffProductionState", "Dormant")
		root:SetAttribute("BailiffEvidenceSource", "none")
		root:SetAttribute("AudioExecutionEvidenceState", "assetUploadBlocked")
		root:SetAttribute("Phase207QualityState", "implementedUnverified")
	end
end

function Coordinator.start()
	started = true
	RunState.setStage("Running")
end

function Coordinator.beforeInteraction(
	player: Player,
	interactionId: string,
	pressure: number
): (boolean, string?)
	local magnitude, radius = StealthRuntime.calculateNoise(
		if string.sub(interactionId, 1, 5) == "ward_" then "puzzle_failure" else "walk",
		pressure
	)
	noiseByUserId[player.UserId] = magnitude
	RunState.recordNoise(player.UserId, magnitude, "interaction:" .. interactionId, radius)
	AudioExecutionRuntime.selectFootstep(
		if pressure >= 0.85 then "shallow_puddle" else "wet_cobblestone",
		if magnitude >= 0.65 then "stumble" else "walk",
		player.UserId
	)
	local exposure = StealthRuntime.calculateExposure(0.35, nil, pressure)
	RunState.recordExposure(player.UserId, exposure)
	PerceptionRuntime.sample(player.UserId, 24, 0.35, magnitude, exposure, pressure)
	local character = player.Character
	local playerRoot = character and character:FindFirstChild("HumanoidRootPart")
	if playerRoot and playerRoot:IsA("BasePart") then
		BailiffPhysicalRuntime.recordLastKnownPosition(player.UserId, playerRoot.Position)
	end
	BailiffPhysicalRuntime.recordPerceptionEvidence({
		evidenceType = if interactionId == "ignite_lantern"
			then "lanternActivation"
			elseif string.sub(interactionId, 1, 5) == "ward_" then "wardDisturbance"
			else "playerGeneratedSound",
		position = if playerRoot and playerRoot:IsA("BasePart")
			then playerRoot.Position
			else Vector3.zero,
		strength = magnitude,
		confidence = math.clamp(magnitude * 0.7 + pressure * 0.3, 0, 1),
		priority = math.clamp(pressure, 0, 1),
		expirationSeconds = 9,
		userId = player.UserId,
	})
	if string.sub(interactionId, 1, 5) == "ward_" then
		local ok, reason = PuzzleRuntime.validateWard(interactionId)
		if not ok then
			RunState.recordFailure(reason or "PuzzleRejected", { interactionId = interactionId })
			return false, reason
		end
	end
	return true, nil
end

function Coordinator.afterInteraction(_player: Player, interactionId: string, pressure: number)
	RunState.recordObjective(interactionId)
	RunState.setPressure(pressure)
	local storyBeat = NarrativeRuntime.recordObjective(interactionId)
	local optionalEvidence = InvestigationRuntime.pickForObjective(interactionId)
	if optionalEvidence then
		local recorded, clue = InvestigationRuntime.record(optionalEvidence)
		if recorded then
			RunState.recordDiscovery(optionalEvidence)
			if root then
				root:SetAttribute("OptionalDiscovery", clue)
			end
		end
	end
	if interactionId == "ignite_lantern" then
		BailiffPhysicalRuntime.runEncounterPass("street_sighting")
		RunState.recordRelic("watchman_lantern")
	elseif interactionId == "take_seal" then
		BailiffPhysicalRuntime.runEncounterPass("ward_interruption")
		RunState.recordRelic("blackwater_brass_seal")
	elseif interactionId == "take_heart" then
		BailiffPhysicalRuntime.runEncounterPass("blackout_pursuit")
		RunState.recordRelic("glass_heart")
	end
	EnvironmentRuntime.applyObjective(root, interactionId)
	QualityStrikeRuntime.applyObjective(interactionId)
	MonsterRuntime.reactToObjective(interactionId, pressure)
	RunState.setBailiffState(MonsterRuntime.inspect().currentState, interactionId)
	BailiffPhysicalRuntime.setMode(MonsterRuntime.inspect().currentState)
	StreetAudioRuntime.applyProgress(pressure)
	AudioExecutionRuntime.applyObjective(interactionId, pressure)
	AudioExecutionRuntime.applyBailiffState(MonsterRuntime.inspect().currentState, interactionId)
	if interactionId == "ignite_lantern" then
		StreetAudioRuntime.trigger("breathing_architecture", "front_gate_crossed")
	elseif interactionId == "read_ledger" then
		BailiffPhysicalRuntime.runEncounterPass("first_house_search")
		StreetAudioRuntime.trigger("wrong_bell", "house_reveal")
	elseif interactionId == "take_seal" then
		StreetAudioRuntime.trigger("source_less_carriage", "seal_taken")
	elseif interactionId == "ward_crypt" then
		StreetAudioRuntime.trigger("impossible_footsteps", "buried_ward")
	elseif interactionId == "open_archive" then
		BailiffPhysicalRuntime.runEncounterPass("archive_hunt")
		StreetAudioRuntime.trigger("constable_vale_presence", "archive_opened")
	elseif interactionId == "take_heart" then
		BailiffPhysicalRuntime.safeReposition(CFrame.new(0, 4, -104), "glass_heart_climax")
		BailiffPhysicalRuntime.telegraphAttack(-1, "glass_heart_climax")
	end
	if MonsterRuntime.inspect().currentState == "Suspicious" then
		local target = MonsterRuntime.selectTarget(Players:GetPlayers(), noiseByUserId)
		if target then
			BailiffPhysicalRuntime.telegraphAttack(target.UserId, "archive_pressure")
		end
		ChaseRuntime.start(target, "archive_pressure")
	end
	if interactionId == "escape_gate" then
		ChaseRuntime.resolve("escaped")
		BailiffPhysicalRuntime.resolveAttack(false, "escape_route")
		BailiffPhysicalRuntime.recover("dawn_escape")
		RunState.recordHuntSurvived()
		local endingId = RunState.chooseEnding()
		ReplayRuntime.buildSummary(RunState.inspect())
		if root then
			root:SetAttribute("EndingId", endingId)
			root:SetAttribute("EndingText", NarrativeRuntime.endingText(endingId))
		end
	end
	CinematicRuntime.playForObjective(root, interactionId, true)
	AudioRuntime.apply(
		root,
		if pressure >= 0.9 then "escape" elseif pressure >= 0.7 then "archive" else "foyer",
		pressure,
		MonsterRuntime.inspect().currentState
	)
	if root then
		root:SetAttribute("BailiffState", MonsterRuntime.inspect().currentState)
		root:SetAttribute(
			"BailiffProductionState",
			BailiffPhysicalRuntime.inspect().productionState
		)
		root:SetAttribute("BailiffEvidenceSource", interactionId)
		root:SetAttribute("StoryBeat", storyBeat)
	end
end

function Coordinator.recordDeath()
	RunState.recordDeath()
	ChaseRuntime.resolve("death")
	CinematicRuntime.cancel("death")
end

function Coordinator.inspect()
	return {
		initialized = initialized,
		started = started,
		config = {
			programVersion = ProductionConfig.ProgramVersion,
			roomCount = #ProductionConfig.Rooms,
			evidenceCount = #ProductionConfig.OptionalEvidence,
			endingCount = #ProductionConfig.Endings,
		},
		runState = RunState.inspect(),
		environment = EnvironmentRuntime.inspect(),
		monster = MonsterRuntime.inspect(),
		perception = PerceptionRuntime.inspect(),
		stealth = StealthRuntime.inspect(),
		chase = ChaseRuntime.inspect(),
		puzzle = PuzzleRuntime.inspect(),
		qualityStrike = QualityStrikeRuntime.inspect(),
		investigation = InvestigationRuntime.inspect(),
		narrative = NarrativeRuntime.inspect(),
		cinematic = CinematicRuntime.inspect(),
		audio = AudioRuntime.inspect(),
		streetAudio = StreetAudioRuntime.inspect(),
		audioExecution = AudioExecutionRuntime.inspect(),
		bailiffPhysical = BailiffPhysicalRuntime.inspect(),
		replay = ReplayRuntime.inspect(),
	}
end

function Coordinator.runSelfChecks()
	Coordinator.initialize(nil)
	Coordinator.start()
	local fakePlayer = { UserId = -204 } :: any
	local before = Coordinator.beforeInteraction(fakePlayer, "ward_west", 0.5)
	Coordinator.afterInteraction(fakePlayer, "take_heart", 1)
	local snapshot = Coordinator.inspect()
	return {
		ok = before == true
			and snapshot.config.roomCount >= 15
			and snapshot.config.endingCount == 3
			and snapshot.runState.relicCount >= 1
			and snapshot.streetAudio.candidateCount == 10
			and snapshot.audioExecution.mixSnapshotCount == 15
			and snapshot.audioExecution.surfaceCount == 11
			and snapshot.qualityStrike.signatureMoments == 10
			and snapshot.bailiffPhysical.initialized == true,
		snapshot = snapshot,
	}
end

function Coordinator.shutdown()
	AudioExecutionRuntime.shutdown()
	StreetAudioRuntime.shutdown()
	AudioRuntime.shutdown()
	CinematicRuntime.shutdown()
	ChaseRuntime.shutdown()
	StealthRuntime.shutdown()
	MonsterRuntime.shutdown()
	BailiffPhysicalRuntime.shutdown()
	PerceptionRuntime.shutdown()
	QualityStrikeRuntime.shutdown()
	PuzzleRuntime.shutdown()
	InvestigationRuntime.shutdown()
	NarrativeRuntime.shutdown()
	EnvironmentRuntime.shutdown()
	ReplayRuntime.shutdown()
	RunState.clear()
	noiseByUserId = {}
	root = nil
	initialized = false
	started = false
end

return Coordinator
