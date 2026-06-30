--!strict
--[[
	Psychological Horror Director for London Engine.

	Owns server-authoritative pacing decisions, trusted observation intake,
	scheduled evaluation, diagnostics, snapshots, and the public API future
	systems use to report player behavior or set chapter phase.

	Does not own Monster AI, chapter gameplay, final UI/art, scare presentation,
	or client-trusted fear state. A DirectorDecision is an opportunity contract,
	not an executed scare.

	Future systems should publish DirectorSignals.Observation or call
	HorrorDirector.observe from trusted server code. Clients may later receive
	presentation events only after the server has approved a decision.

	Lifecycle: initialize wires diagnostics/snapshots/EventBus; start creates
	run-local profiles and the evaluation interval; shutdown cancels and
	disconnects everything it created.
]]

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

local Core = ServerScriptService.Core
local Diagnostics = require(Core.Diagnostics)
local EventBus = require(Core.EventBus)
local Logger = require(Core.Logger)
local Scheduler = require(Core.Scheduler)
local SnapshotManager = require(Core.SnapshotManager)

local DirectorDiagnostics = require(script.Parent.DirectorDiagnostics)
local DirectorMemory = require(script.Parent.DirectorMemory)
local DirectorSignals = require(script.Parent.DirectorSignals)
local HorrorDirectorConfig = require(script.Parent.HorrorDirectorConfig)
local PlayerFearProfile = require(script.Parent.PlayerFearProfile)
local ScareCooldowns = require(script.Parent.ScareCooldowns)
local ScareRegistry = require(script.Parent.ScareRegistry)
local ScareSelector = require(script.Parent.ScareSelector)
local TensionModel = require(script.Parent.TensionModel)
local Types = require(script.Parent.HorrorDirectorTypes)

local HorrorDirector = {}

type Observation = Types.Observation
type DirectorDecision = Types.DirectorDecision
type ChapterPhase = Types.ChapterPhase

local log = Logger.scope("HorrorDirector")
local initialized = false
local started = false
local evaluationHandle: Scheduler.TaskHandle? = nil
local eventConnections: { RBXScriptConnection } = {}
local busDisconnects: { () -> () } = {}
local decisionId = 0
local chapterPhase: ChapterPhase = "Opening"
local evaluationCount = 0
local lastEvaluationAt = 0
local lastDecision: DirectorDecision? = nil
local nextPlayerEvaluationIndex = 1

local validChapterPhases = {
	Lobby = true,
	Opening = true,
	Exploration = true,
	Puzzle = true,
	Threat = true,
	Climax = true,
	Escape = true,
}

local function now(): number
	return os.clock()
end

local function copyStringArray(values: any): { string }?
	if type(values) ~= "table" then
		return nil
	end

	local copied = {}

	for _, value in ipairs(values) do
		if type(value) == "string" and value ~= "" then
			table.insert(copied, value)
		end
	end

	return copied
end

local function makeObservation(
	player: Player?,
	kind: string,
	amount: number?,
	metadata: any?
): Observation
	-- Observations are intentionally flexible at the boundary. Future systems can
	-- add metadata without forcing schema churn through the whole Director.
	return {
		player = player,
		userId = if player ~= nil then player.UserId else nil,
		kind = kind,
		amount = amount,
		positionKey = if type(metadata) == "table"
				and type(metadata.positionKey) == "string"
			then metadata.positionKey
			else nil,
		tags = if type(metadata) == "table" then copyStringArray(metadata.tags) else nil,
		metadata = if type(metadata) == "table" then metadata else nil,
		at = now(),
	}
end

local function nextDecisionId(): number
	decisionId += 1
	return decisionId
end

local function makeSilenceDecision(
	player: Player?,
	tension: Types.TensionSnapshot,
	reason: string,
	blocked: { string }
): DirectorDecision
	return {
		id = nextDecisionId(),
		at = now(),
		playerUserId = if player ~= nil then player.UserId else nil,
		scareId = nil,
		category = nil,
		intensity = 0,
		tensionState = tension.state,
		reason = reason,
		silence = true,
		blocked = blocked,
	}
end

local function publishDecision(decision: DirectorDecision)
	lastDecision = decision
	DirectorMemory.recordDecision(decision)
	EventBus.publishDeferred(DirectorSignals.DecisionMade, {
		decision = decision,
	})

	if decision.silence then
		EventBus.publishDeferred(DirectorSignals.SilenceSelected, {
			decision = decision,
		})
	else
		EventBus.publishDeferred(DirectorSignals.ScareSelected, {
			decision = decision,
		})
	end
end

function HorrorDirector.observe(player: Player?, kind: string, amount: number?, metadata: any?)
	if type(kind) ~= "string" or kind == "" then
		log.withContext("WARN", "Ignored malformed Horror Director observation", {
			kind = tostring(kind),
		})
		return
	end

	-- Main trusted server intake: update run-local profile, update Director
	-- memory, then publish a profile signal for debugging/future systems.
	local observation = makeObservation(player, kind, amount, metadata)
	local profile = PlayerFearProfile.observe(observation)

	DirectorMemory.observe(observation)

	if profile ~= nil then
		EventBus.publishDeferred(DirectorSignals.ProfileUpdated, {
			userId = profile.userId,
			kind = kind,
		})
	end
end

function HorrorDirector.evaluatePlayer(player: Player): DirectorDecision?
	-- Silence is still a real decision. Recording it makes pacing explainable in
	-- diagnostics and prevents "nothing happened" from looking like no work.
	local profile = PlayerFearProfile.ensure(player)
	local currentTime = now()
	local tension = TensionModel.calculateForProfile(profile, currentTime)
	local scare, reason, blocked = ScareSelector.selectForPlayer(
		profile,
		tension,
		chapterPhase,
		currentTime,
		#Players:GetPlayers()
	)

	if scare == nil then
		local decision = makeSilenceDecision(player, tension, reason, blocked)
		publishDecision(decision)
		return decision
	end

	local decision: DirectorDecision = {
		id = nextDecisionId(),
		at = currentTime,
		playerUserId = player.UserId,
		scareId = scare.id,
		category = scare.category,
		intensity = scare.intensity,
		tensionState = tension.state,
		reason = reason,
		silence = false,
		blocked = blocked,
	}

	ScareCooldowns.record(scare, player.UserId, currentTime)
	PlayerFearProfile.recordScare(player, scare.id, currentTime)
	publishDecision(decision)

	log.withContext("INFO", "Horror Director selected scare opportunity", {
		userId = player.UserId,
		scareId = scare.id,
		category = scare.category,
		tension = tension.state,
	})

	return decision
end

function HorrorDirector.evaluateNow(): DirectorDecision?
	evaluationCount += 1
	lastEvaluationAt = now()

	local players = Players:GetPlayers()

	if #players == 0 then
		return nil
	end

	table.sort(players, function(left, right)
		if left.UserId == right.UserId then
			return left.Name < right.Name
		end

		return left.UserId < right.UserId
	end)

	if nextPlayerEvaluationIndex > #players then
		nextPlayerEvaluationIndex = 1
	end

	local selectedPlayer = players[nextPlayerEvaluationIndex]
	nextPlayerEvaluationIndex += 1

	-- Evaluate one player per tick to avoid synchronized party-wide scare spam.
	-- Future chapters can request targeted evaluations for authored beats.
	return HorrorDirector.evaluatePlayer(selectedPlayer)
end

function HorrorDirector.setChapterPhase(phase: ChapterPhase)
	if not validChapterPhases[phase] then
		log.withContext("WARN", "Ignored invalid Horror Director chapter phase", {
			phase = tostring(phase),
		})
		return
	end

	chapterPhase = phase
	EventBus.publishDeferred(DirectorSignals.PhaseChanged, {
		phase = phase,
	})
end

function HorrorDirector.getChapterPhase(): ChapterPhase
	return chapterPhase
end

function HorrorDirector.initialize()
	if initialized then
		return
	end

	Diagnostics.registerSampler("HorrorDirector", HorrorDirector.inspect)
	SnapshotManager.registerProvider("horrorDirector", HorrorDirector.inspect)

	table.insert(
		busDisconnects,
		EventBus.subscribe(DirectorSignals.Observation, function(event)
			if event.payload == nil then
				return
			end

			local payload = event.payload
			local player = payload.player

			if
				player ~= nil
				and (typeof(player) ~= "Instance" or not (player :: Instance):IsA("Player"))
			then
				-- EventBus is server-local, but malformed payloads should not turn
				-- into trusted player-specific fear data.
				player = nil
			end

			HorrorDirector.observe(
				player :: Player?,
				tostring(payload.kind or "Unknown"),
				if type(payload.amount) == "number" then payload.amount else nil,
				if type(payload.metadata) == "table" then payload.metadata else payload
			)
		end)
	)

	local ok, err = HorrorDirector.validate()

	if not ok then
		error("HorrorDirector validation failed: " .. tostring(err), 0)
	end

	initialized = true
	log.success("HorrorDirector initialized")
end

function HorrorDirector.start()
	if started then
		return
	end

	if not initialized then
		HorrorDirector.initialize()
	end

	for _, player in ipairs(Players:GetPlayers()) do
		PlayerFearProfile.ensure(player)
	end

	table.insert(
		eventConnections,
		Players.PlayerAdded:Connect(function(player)
			PlayerFearProfile.ensure(player)
		end)
	)

	table.insert(
		eventConnections,
		Players.PlayerRemoving:Connect(function(player)
			PlayerFearProfile.remove(player)
			ScareCooldowns.removePlayer(player.UserId)
		end)
	)

	evaluationHandle = Scheduler.interval(
		HorrorDirectorConfig.EvaluationIntervalSeconds,
		HorrorDirector.evaluateNow,
		"HorrorDirectorEvaluation",
		"HorrorDirector",
		{ "Horror", "Director" }
	)

	started = true
	log.success("HorrorDirector started")
end

function HorrorDirector.shutdown()
	if evaluationHandle ~= nil then
		Scheduler.cancel(evaluationHandle)
		evaluationHandle = nil
	end

	for _, connection in ipairs(eventConnections) do
		connection:Disconnect()
	end

	for _, disconnect in ipairs(busDisconnects) do
		disconnect()
	end

	table.clear(eventConnections)
	table.clear(busDisconnects)
	PlayerFearProfile.clear()
	DirectorMemory.reset()
	ScareCooldowns.reset()
	lastDecision = nil
	nextPlayerEvaluationIndex = 1
	started = false
end

function HorrorDirector.inspect()
	local profiles = PlayerFearProfile.getAll()
	local currentTime = now()

	return DirectorDiagnostics.capture({
		started = started,
		chapterPhase = chapterPhase,
		evaluationCount = evaluationCount,
		lastEvaluationAt = lastEvaluationAt,
		lastDecision = lastDecision,
		partyTension = TensionModel.calculateParty(profiles, currentTime),
	}, {
		PlayerFearProfile = PlayerFearProfile,
		DirectorMemory = DirectorMemory,
		ScareCooldowns = ScareCooldowns,
		ScareRegistry = ScareRegistry,
	})
end

function HorrorDirector.validate(): (boolean, string?)
	return DirectorDiagnostics.validate({
		PlayerFearProfile = PlayerFearProfile,
		HorrorDirectorConfig = HorrorDirectorConfig,
		ScareRegistry = ScareRegistry,
		DirectorMemory = DirectorMemory,
		ScareCooldowns = ScareCooldowns,
	})
end

return HorrorDirector
