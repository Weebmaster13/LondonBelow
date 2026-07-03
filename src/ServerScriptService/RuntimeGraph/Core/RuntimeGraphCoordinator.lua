--!strict
--[[
	Phase 37 Runtime Dependency Graph Coordinator.

	Server-authoritative dependency graph schema foundation. It records runtime
	nodes, dependency edges, capabilities, requirements, compatibility records,
	ordering rules, startup/shutdown plan schemas, dependency groups, and graph
	validation summaries. It does not start, stop, initialize, load, resolve,
	call, inject, orchestrate, or mutate any runtime.
]]

local ServerScriptService = game:GetService("ServerScriptService")

local Core = ServerScriptService.Core
local Diagnostics = require(Core.Diagnostics)
local EventBus = require(Core.EventBus)
local Logger = require(Core.Logger)
local SnapshotManager = require(Core.SnapshotManager)

local CapabilityRuntime = require(script.Parent.RuntimeCapabilityRuntime)
local CompatibilityRuntime = require(script.Parent.RuntimeCompatibilityRuntime)
local DependencyRuntime = require(script.Parent.RuntimeDependencyRuntime)
local GraphDiagnostics = require(script.Parent.RuntimeGraphDiagnostics)
local GraphValidationRuntime = require(script.Parent.RuntimeGraphValidationRuntime)
local GroupRuntime = require(script.Parent.RuntimeGroupRuntime)
local NodeRuntime = require(script.Parent.RuntimeNodeRuntime)
local OrderingRuntime = require(script.Parent.RuntimeOrderingRuntime)
local RequirementRuntime = require(script.Parent.RuntimeRequirementRuntime)
local SelfChecks = require(script.Parent.RuntimeGraphSelfChecks)
local Serialization = require(script.Parent.RuntimeGraphSerialization)
local ShutdownPlanRuntime = require(script.Parent.RuntimeShutdownPlanRuntime)
local Signals = require(script.Parent.RuntimeGraphSignals)
local Snapshots = require(script.Parent.RuntimeGraphSnapshots)
local StartupPlanRuntime = require(script.Parent.RuntimeStartupPlanRuntime)
local State = require(script.Parent.RuntimeGraphState)
local Types = require(script.Parent.RuntimeGraphTypes)
local Validation = require(script.Parent.RuntimeGraphValidation)

local RuntimeGraphCoordinator = {}

local log = Logger.scope("RuntimeGraph")
local initialized = false
local started = false
local lastSelfChecks: any = nil

local dependencies = {
	State = State,
	Validation = Validation,
}

local function result(ok: boolean, code: string, message: string?, extra: any?)
	local payload = extra or {}
	payload.ok = ok
	payload.code = code
	payload.message = message
	return payload
end

local function codeFor(reason: string?): string
	if reason == "duplicate nodeId" then
		return Types.ResultCode.DuplicateNode
	elseif reason == "duplicate dependencyId" then
		return Types.ResultCode.DuplicateDependency
	elseif reason == "duplicate capabilityId" then
		return Types.ResultCode.DuplicateCapability
	elseif reason == "duplicate requirementId" then
		return Types.ResultCode.DuplicateRequirement
	elseif reason == "duplicate compatibilityId" then
		return Types.ResultCode.DuplicateCompatibility
	elseif reason == "duplicate orderingId" then
		return Types.ResultCode.DuplicateOrdering
	elseif reason == "duplicate startupPlanId" then
		return Types.ResultCode.DuplicateStartupPlan
	elseif reason == "duplicate shutdownPlanId" then
		return Types.ResultCode.DuplicateShutdownPlan
	elseif reason == "duplicate groupId" then
		return Types.ResultCode.DuplicateGroup
	elseif reason == "duplicate validationId" then
		return Types.ResultCode.DuplicateValidationRecord
	elseif
		reason ~= nil
		and (
			string.find(reason, "payload", 1, true)
			or string.find(reason, "forbidden", 1, true)
			or string.find(reason, "unsafe runtime", 1, true)
			or string.find(reason, "cyclic", 1, true)
		)
	then
		return Types.ResultCode.UnsafePayload
	end
	return Types.ResultCode.InvalidRequest
end

local function recordFailure(reason: string, payload: any?)
	State.recordValidationFailure(reason, payload)
	EventBus.publishDeferred(Signals.ValidationFailed, { reason = reason })
end

local function register(
	schema: any,
	runtime: any,
	signal: string,
	signalPayload: any,
	successMessage: string
)
	local ok, reason = runtime.register(State, schema)
	if not ok then
		recordFailure(reason or "runtime graph schema rejected", schema)
		return result(false, codeFor(reason), reason)
	end
	EventBus.publishDeferred(signal, signalPayload)
	return result(true, Types.ResultCode.Ok, successMessage)
end

function RuntimeGraphCoordinator.registerNode(schema: any)
	return register(
		schema,
		NodeRuntime,
		Signals.NodeRegistered,
		{ nodeId = schema.nodeId },
		"runtime node registered"
	)
end

function RuntimeGraphCoordinator.registerDependency(schema: any)
	return register(
		schema,
		DependencyRuntime,
		Signals.DependencyRegistered,
		{ dependencyId = schema.dependencyId },
		"runtime dependency registered"
	)
end

function RuntimeGraphCoordinator.registerCapability(schema: any)
	return register(
		schema,
		CapabilityRuntime,
		Signals.CapabilityRegistered,
		{ capabilityId = schema.capabilityId },
		"runtime capability registered"
	)
end

function RuntimeGraphCoordinator.registerRequirement(schema: any)
	return register(
		schema,
		RequirementRuntime,
		Signals.RequirementRegistered,
		{ requirementId = schema.requirementId },
		"runtime requirement registered"
	)
end

function RuntimeGraphCoordinator.registerCompatibility(schema: any)
	return register(
		schema,
		CompatibilityRuntime,
		Signals.CompatibilityRegistered,
		{ compatibilityId = schema.compatibilityId },
		"runtime compatibility registered"
	)
end

function RuntimeGraphCoordinator.registerOrdering(schema: any)
	return register(
		schema,
		OrderingRuntime,
		Signals.OrderingRegistered,
		{ orderingId = schema.orderingId },
		"runtime ordering registered"
	)
end

function RuntimeGraphCoordinator.registerStartupPlan(schema: any)
	return register(
		schema,
		StartupPlanRuntime,
		Signals.StartupPlanRegistered,
		{ startupPlanId = schema.startupPlanId },
		"runtime startup plan registered"
	)
end

function RuntimeGraphCoordinator.registerShutdownPlan(schema: any)
	return register(
		schema,
		ShutdownPlanRuntime,
		Signals.ShutdownPlanRegistered,
		{ shutdownPlanId = schema.shutdownPlanId },
		"runtime shutdown plan registered"
	)
end

function RuntimeGraphCoordinator.registerGroup(schema: any)
	return register(
		schema,
		GroupRuntime,
		Signals.GroupRegistered,
		{ groupId = schema.groupId },
		"runtime group registered"
	)
end

function RuntimeGraphCoordinator.registerValidationRecord(schema: any)
	return register(
		schema,
		GraphValidationRuntime,
		Signals.ValidationRecordRegistered,
		{ validationId = schema.validationId },
		"runtime graph validation record registered"
	)
end

function RuntimeGraphCoordinator.initialize()
	if initialized then
		return
	end
	local valid, reason = RuntimeGraphCoordinator.validate()
	if not valid then
		error("RuntimeGraphCoordinator validation failed: " .. tostring(reason), 0)
	end
	Diagnostics.registerSampler("runtimeGraph", RuntimeGraphCoordinator.inspect)
	SnapshotManager.registerProvider("runtimeGraph", RuntimeGraphCoordinator.getSnapshot)
	initialized = true
	log.success("Runtime Graph initialized")
end

function RuntimeGraphCoordinator.start()
	if started then
		return
	end
	if not initialized then
		RuntimeGraphCoordinator.initialize()
	end
	started = true
end

function RuntimeGraphCoordinator.shutdown()
	State.clear()
	started = false
	initialized = false
end

function RuntimeGraphCoordinator.inspect()
	return GraphDiagnostics.capture({
		initialized = initialized,
		started = started,
		lastSelfChecks = lastSelfChecks,
	}, dependencies)
end

function RuntimeGraphCoordinator.getSnapshot()
	local snapshot = Snapshots.capture(State)
	EventBus.publishDeferred(
		Signals.SnapshotCaptured,
		{ snapshot = Serialization.deepCopy(snapshot) }
	)
	return snapshot
end

function RuntimeGraphCoordinator.validate(): (boolean, string?)
	return GraphDiagnostics.validate(dependencies)
end

function RuntimeGraphCoordinator.runSelfChecks()
	if started then
		lastSelfChecks = {
			ok = false,
			reason = "Runtime Graph self-checks are destructive and may only run before start.",
		}
		return lastSelfChecks
	end
	lastSelfChecks = SelfChecks.run({ Service = RuntimeGraphCoordinator })
	return lastSelfChecks
end

return RuntimeGraphCoordinator
