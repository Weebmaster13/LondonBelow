--!strict
--[[
	Psychological Horror Director for London Engine.

	The Director controls pacing. It decides when to apply pressure, when to
	release, when to select a scare opportunity, and when silence is stronger.
	It does not implement monster AI, chapter gameplay, final UI, or final art.
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

local function now(): number
	return os.clock()
end

local function makeObservation(
	player: Player?,
	kind: string,
	amount: number?,
	metadata: any?
): Observation
	return {
		player = player,
		userId = if player ~= nil then player.UserId else nil,
		kind = kind,
		amount = amount,
		positionKey = if type(metadata) == "table" then metadata.positionKey else nil,
		tags = if type(metadata) == "table" and type(metadata.tags) == "table"
			then metadata.tags
			else nil,
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
	assert(type(kind) == "string" and kind ~= "", "observation kind is required")

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

	local selectedPlayer = players[math.random(1, #players)]

	return HorrorDirector.evaluatePlayer(selectedPlayer)
end

function HorrorDirector.setChapterPhase(phase: ChapterPhase)
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
		ScareRegistry = ScareRegistry,
	})
end

return HorrorDirector
