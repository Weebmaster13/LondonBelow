--!strict
-- Main orchestrator for Phase 40 Event Graph schema infrastructure.

local Diagnostics = require(script.Parent.EventGraphDiagnostics)
local EngineDiagnostics = require(script.Parent.Parent.Parent.Core.Diagnostics)
local Logger = require(script.Parent.Parent.Parent.Core.Logger)
local SelfChecks = require(script.Parent.EventGraphSelfChecks)
local SnapshotManager = require(script.Parent.Parent.Parent.Core.SnapshotManager)
local Snapshots = require(script.Parent.EventGraphSnapshots)
local State = require(script.Parent.EventGraphState)
local Serialization = require(script.Parent.EventGraphSerialization)
local Validation = require(script.Parent.EventGraphValidation)

local EventGraphCoordinator = {}

local lifecycle = {
	initialized = false,
	started = false,
	lastSelfChecks = nil :: any,
}

local log = Logger.scope("EventGraph")

local dependencies = {
	Serialization = Serialization,
	State = State,
	Validation = Validation,
}

local function result(ok: boolean, code: string, message: string?)
	return {
		ok = ok,
		code = code,
		message = message,
	}
end

local function register(schema: any, callback: (any) -> (boolean, string?), code: string)
	local ok, reason = callback(schema)
	if not ok then
		State.recordValidationFailure(reason or "unknown Event Graph validation failure", schema)
		return result(false, code, reason)
	end
	return result(true, code, nil)
end

function EventGraphCoordinator.initialize()
	if lifecycle.initialized then
		return result(true, "AlreadyInitialized", nil)
	end
	local ok, reason = Validation.validate()
	if not ok then
		return result(false, "ValidationFailed", reason)
	end
	EngineDiagnostics.registerSampler("eventGraph", function()
		return EventGraphCoordinator.inspect()
	end)
	SnapshotManager.registerProvider("eventGraph", function()
		return EventGraphCoordinator.getSnapshot()
	end)
	lifecycle.initialized = true
	log.info("Event Graph Foundation initialized")
	return result(true, "Initialized", nil)
end

function EventGraphCoordinator.start()
	if not lifecycle.initialized then
		return result(false, "NotInitialized", "Event Graph must initialize before start")
	end
	lifecycle.started = true
	return result(true, "Started", nil)
end

function EventGraphCoordinator.shutdown()
	State.clear()
	lifecycle.initialized = false
	lifecycle.started = false
	lifecycle.lastSelfChecks = nil
	return result(true, "Shutdown", nil)
end

function EventGraphCoordinator.registerEventNode(schema: any)
	return register(schema, State.registerNode, "EventNode")
end

function EventGraphCoordinator.registerEventChannel(schema: any)
	return register(schema, State.registerChannel, "EventChannel")
end

function EventGraphCoordinator.registerEventEdge(schema: any)
	return register(schema, State.registerEdge, "EventEdge")
end

function EventGraphCoordinator.registerEventSource(schema: any)
	return register(schema, State.registerSource, "EventSource")
end

function EventGraphCoordinator.registerEventSink(schema: any)
	return register(schema, State.registerSink, "EventSink")
end

function EventGraphCoordinator.registerEventSubscription(schema: any)
	return register(schema, State.registerSubscription, "EventSubscription")
end

function EventGraphCoordinator.registerEventPropagation(schema: any)
	return register(schema, State.registerPropagation, "EventPropagation")
end

function EventGraphCoordinator.registerEventPriority(schema: any)
	return register(schema, State.registerPriority, "EventPriority")
end

function EventGraphCoordinator.registerEventFilter(schema: any)
	return register(schema, State.registerFilter, "EventFilter")
end

function EventGraphCoordinator.registerEventPayloadContract(schema: any)
	return register(schema, State.registerPayloadContract, "EventPayloadContract")
end

function EventGraphCoordinator.registerEventOrdering(schema: any)
	return register(schema, State.registerOrdering, "EventOrdering")
end

function EventGraphCoordinator.registerEventAudit(schema: any)
	return register(schema, State.registerAudit, "EventAudit")
end

function EventGraphCoordinator.inspect()
	return Diagnostics.capture(lifecycle, dependencies)
end

function EventGraphCoordinator.getSnapshot()
	return Snapshots.capture(lifecycle, dependencies)
end

function EventGraphCoordinator.validate()
	return Diagnostics.validate(dependencies)
end

function EventGraphCoordinator.runSelfChecks()
	if lifecycle.started then
		return result(false, "AlreadyStarted", "Event Graph self-checks must run before start")
	end
	local checks = SelfChecks.run({ Service = EventGraphCoordinator })
	lifecycle.lastSelfChecks = checks
	return checks
end

return EventGraphCoordinator
