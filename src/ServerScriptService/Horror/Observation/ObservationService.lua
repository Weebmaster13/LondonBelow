--!strict
--[[
	ObservationService is the living sensory nervous system of London Engine.

	Owns lifecycle, authoritative observation intake, validation, enrichment,
	aggregation, memory, timeline recording, pattern recognition, diagnostics,
	and forwarding enriched facts into downstream systems.

	Does not own gameplay rules, Monster AI, Horror Director interpretation,
	story logic, final UI/art, analytics, or client networking.

	Future systems should call ObservationService.observe() or publish
	ObservationSignals.Submitted from trusted server code. They should not report
	raw facts directly to the Horror Director, Monster AI, or story systems.
]]

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

local Core = ServerScriptService.Core
local Diagnostics = require(Core.Diagnostics)
local EventBus = require(Core.EventBus)
local Logger = require(Core.Logger)
local Scheduler = require(Core.Scheduler)
local SnapshotManager = require(Core.SnapshotManager)

local DirectorSignals = require(script.Parent.Parent.Director.DirectorSignals)
local ObservationAggregator = require(script.Parent.ObservationAggregator)
local ObservationConfig = require(script.Parent.ObservationConfig)
local ObservationContext = require(script.Parent.ObservationContext)
local ObservationDiagnostics = require(script.Parent.ObservationDiagnostics)
local ObservationMemory = require(script.Parent.ObservationMemory)
local ObservationPatternRecognizer = require(script.Parent.ObservationPatternRecognizer)
local ObservationProfiler = require(script.Parent.ObservationProfiler)
local ObservationRegistry = require(script.Parent.ObservationRegistry)
local ObservationSignals = require(script.Parent.ObservationSignals)
local ObservationTimeline = require(script.Parent.ObservationTimeline)
local ObservationValidator = require(script.Parent.ObservationValidator)
local Types = require(script.Parent.ObservationTypes)

local ObservationService = {}

type ObservationInput = Types.ObservationInput
type Observation = Types.Observation
type ObservationDefinition = Types.ObservationDefinition

local log = Logger.scope("ObservationService")
local initialized = false
local started = false
local sequence = 0
local acceptedCount = 0
local rejectedCount = 0
local lastObservation: Observation? = nil
local busDisconnects: { () -> () } = {}
local eventConnections: { RBXScriptConnection } = {}
local profileHandle: Scheduler.TaskHandle? = nil

local function now(): number
	return os.clock()
end

local function nextSequence(): number
	sequence += 1
	return sequence
end

local function copyMetadata(metadata: { [string]: any }?): { [string]: any }
	if metadata == nil then
		return {}
	end

	return table.clone(metadata)
end

local function expirationAt(definition: ObservationDefinition, at: number): number?
	local seconds = Types.ExpirationSeconds[definition.expiration]

	if seconds == nil or seconds <= 0 then
		return at
	end

	return at + seconds
end

local function buildObservation(
	input: ObservationInput,
	definition: ObservationDefinition
): Observation
	local metadata = copyMetadata(input.metadata)
	local observedAt = input.at or now()

	return {
		sequence = nextSequence(),
		id = definition.id,
		category = definition.category,
		player = input.player,
		userId = if input.player ~= nil then input.player.UserId else nil,
		amount = input.amount or 1,
		weight = definition.weight,
		priority = definition.priority,
		expiration = definition.expiration,
		metadata = metadata,
		source = input.source or "Server",
		at = observedAt,
		expiresAt = expirationAt(definition, observedAt),
		context = ObservationContext.build(metadata),
	}
end

local function metadataNumber(metadata: { [string]: any }, key: string): number?
	local value = metadata[key]

	if type(value) == "number" and value == value then
		return value
	end

	return nil
end

local function directorAmount(observation: Observation): number
	return metadataNumber(observation.metadata, "duration")
		or metadataNumber(observation.metadata, "progress")
		or metadataNumber(observation.metadata, "distance")
		or observation.amount
end

local function directorMetadata(observation: Observation)
	local metadata = copyMetadata(observation.metadata)

	metadata.positionKey = metadata.positionKey or metadata.roomId or observation.context.roomId
	metadata.tags = metadata.tags or observation.context.roomTags
	metadata.observationId = observation.id
	metadata.observationSequence = observation.sequence
	metadata.context = observation.context

	return metadata
end

local function forwardToDirector(observation: Observation, definition: ObservationDefinition)
	if definition.directorKind == nil then
		return
	end

	EventBus.publishDeferred(DirectorSignals.Observation, {
		player = observation.player,
		kind = definition.directorKind,
		amount = directorAmount(observation),
		metadata = directorMetadata(observation),
	})

	EventBus.publishDeferred(ObservationSignals.DirectorForwarded, {
		observation = observation,
		directorKind = definition.directorKind,
	})
end

local function reject(input: any, code: string, message: string)
	rejectedCount += 1
	ObservationProfiler.recordRejected(code, message)

	EventBus.publishDeferred(ObservationSignals.Rejected, {
		input = input,
		code = code,
		message = message,
	})

	log.withContext("WARN", "Observation rejected", {
		id = if type(input) == "table" then tostring(input.id) else "<malformed>",
		code = code,
		message = message,
	})
end

local function accept(
	observation: Observation,
	definition: ObservationDefinition,
	startedAt: number
)
	acceptedCount += 1
	lastObservation = observation

	ObservationAggregator.record(observation)
	ObservationMemory.record(observation)
	ObservationTimeline.record(observation)

	local patterns = ObservationPatternRecognizer.record(observation)

	EventBus.publishDeferred(ObservationSignals.Accepted, {
		observation = observation,
		patterns = patterns,
	})

	EventBus.publishDeferred(ObservationSignals.TimelineRecorded, {
		observation = observation,
	})

	for _, pattern in ipairs(patterns) do
		EventBus.publishDeferred(ObservationSignals.PatternDetected, {
			pattern = pattern,
			observation = observation,
		})
	end

	forwardToDirector(observation, definition)
	ObservationProfiler.recordAccepted(now() - startedAt)
end

function ObservationService.observe(input: ObservationInput | any): (boolean, string, Observation?)
	local startedAt = now()
	local validation, definition = ObservationValidator.validate(input)

	if not validation.ok or definition == nil then
		reject(input, validation.code, validation.message)
		return false, validation.code, nil
	end

	local observation = buildObservation(input, definition)
	accept(observation, definition, startedAt)

	return true, "OK", observation
end

function ObservationService.updateContext(partial: { [string]: any })
	ObservationContext.update(partial)
	EventBus.publishDeferred(ObservationSignals.ContextUpdated, {
		context = ObservationContext.inspect(),
	})
end

function ObservationService.queryTimeline(query: Types.TimelineQuery): { Observation }
	return ObservationTimeline.query(query)
end

function ObservationService.initialize()
	if initialized then
		return
	end

	Diagnostics.registerSampler("ObservationEngine", ObservationService.inspect)
	SnapshotManager.registerProvider("observationEngine", ObservationService.inspect)

	table.insert(
		busDisconnects,
		EventBus.subscribe(ObservationSignals.Submitted, function(event)
			if event.payload == nil then
				return
			end

			ObservationService.observe(event.payload :: ObservationInput)
		end)
	)

	local ok, err = ObservationService.validate()

	if not ok then
		error("ObservationService validation failed: " .. tostring(err), 0)
	end

	initialized = true
	log.success("ObservationService initialized")
end

function ObservationService.start()
	if started then
		return
	end

	if not initialized then
		ObservationService.initialize()
	end

	table.insert(
		eventConnections,
		Players.PlayerRemoving:Connect(function(player)
			ObservationAggregator.removePlayer(player.UserId)
			ObservationTimeline.removePlayer(player.UserId)
			ObservationPatternRecognizer.removePlayer(player.UserId)
		end)
	)

	profileHandle = Scheduler.interval(ObservationConfig.ProfileIntervalSeconds, function()
		log.withContext("DEBUG", "Observation Engine profile", ObservationProfiler.inspect())
	end, "ObservationEngineProfile", "Observation", { "Horror", "Observation" })

	started = true
	log.success("ObservationService started")
end

function ObservationService.shutdown()
	if profileHandle ~= nil then
		Scheduler.cancel(profileHandle)
		profileHandle = nil
	end

	for _, connection in ipairs(eventConnections) do
		connection:Disconnect()
	end

	for _, disconnect in ipairs(busDisconnects) do
		disconnect()
	end

	table.clear(eventConnections)
	table.clear(busDisconnects)
	ObservationAggregator.clear()
	ObservationMemory.clear()
	ObservationTimeline.clear()
	ObservationPatternRecognizer.clear()
	ObservationProfiler.clear()
	lastObservation = nil
	started = false
end

function ObservationService.inspect()
	return ObservationDiagnostics.capture({
		initialized = initialized,
		started = started,
		acceptedCount = acceptedCount,
		rejectedCount = rejectedCount,
		lastObservation = lastObservation,
	}, {
		ObservationRegistry = ObservationRegistry,
		ObservationContext = ObservationContext,
		ObservationMemory = ObservationMemory,
		ObservationTimeline = ObservationTimeline,
		ObservationAggregator = ObservationAggregator,
		ObservationPatternRecognizer = ObservationPatternRecognizer,
		ObservationProfiler = ObservationProfiler,
	})
end

function ObservationService.validate(): (boolean, string?)
	return ObservationDiagnostics.validate({
		ObservationConfig = ObservationConfig,
		ObservationRegistry = ObservationRegistry,
		ObservationContext = ObservationContext,
		ObservationMemory = ObservationMemory,
		ObservationTimeline = ObservationTimeline,
		ObservationAggregator = ObservationAggregator,
		ObservationPatternRecognizer = ObservationPatternRecognizer,
		ObservationProfiler = ObservationProfiler,
	})
end

function ObservationService.runSelfChecks()
	local beforeAccepted = acceptedCount
	local ok, code = ObservationService.observe({
		id = "Camera.LookBehind",
		source = "ObservationSelfCheck",
		metadata = {
			roomId = "self_check_room",
		},
	})
	local unknownOk = ObservationService.observe({
		id = "Invalid.Unknown",
		source = "ObservationSelfCheck",
	})

	return {
		ok = ok and code == "OK" and not unknownOk,
		acceptedDelta = acceptedCount - beforeAccepted,
	}
end

return ObservationService
