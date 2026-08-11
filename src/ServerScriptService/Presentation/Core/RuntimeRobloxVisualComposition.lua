--!strict

local Bindings = require(script.Parent.VisualCompositionBindings)
local Definitions = require(script.Parent.VisualCompositionRegistry)
local Diagnostics = require(script.Parent.VisualCompositionDiagnostics)
local Evidence = require(script.Parent.VisualCompositionEvidence)
local Lifecycle = require(script.Parent.VisualCompositionLifecycle)
local Metrics = require(script.Parent.VisualCompositionMetrics)
local Ownership = require(script.Parent.VisualCompositionOwnership)
local Plans = require(script.Parent.VisualCompositionPlanRegistry)
local Profiler = require(script.Parent.VisualCompositionProfiler)
local Resolver = require(script.Parent.VisualCompositionResolver)
local Serialization = require(script.Parent.PresentationSerialization)
local Snapshots = require(script.Parent.VisualCompositionSnapshots)
local Instances = require(script.Parent.VisualCompositionInstanceRegistry)
local Revisions = require(script.Parent.VisualCompositionRevisions)
local Types = require(script.Parent.PresentationTypes)
local Validation = require(script.Parent.VisualCompositionValidation)

local Runtime = {}
local shutdown = false
local counters = {
	definitionsRegistered = 0,
	compositionsCreated = 0,
	compositionsBound = 0,
	compositionsCompiled = 0,
	compositionsActivated = 0,
	compositionsSuperseded = 0,
	compositionsReleased = 0,
	failures = 0,
	lastFailure = nil :: any?,
}
local failures = {}

local function fail(code: string, message: string, payload: any?)
	counters.failures += 1
	counters.lastFailure = {
		code = code,
		message = message,
		payload = Serialization.diagnosticCopy(payload or {}),
	}
	failures[#failures + 1] = counters.lastFailure
	Metrics.increment("validationFailures")
	Metrics.increment("runtimeFailures")
	Evidence.record("runtime failure", counters.lastFailure)
	return { ok = false, code = code, message = message }
end

local function ensureOpen(input: any)
	if shutdown then
		return fail(
			Types.VisualCompositionFailureType.RuntimeShutdown,
			"runtime is shut down",
			input
		)
	end
	return nil
end

local function transition(compositionInstanceId: string, toState: string)
	local composition = Instances.get(compositionInstanceId)
	if composition == nil then
		return fail(Types.VisualCompositionFailureType.UnknownComposition, "unknown composition", {
			compositionInstanceId = compositionInstanceId,
		})
	end
	if not Lifecycle.canTransition(composition.lifecycleState, toState) then
		return fail(
			Types.VisualCompositionFailureType.InvalidLifecycleTransition,
			"invalid lifecycle transition",
			{
				compositionInstanceId = compositionInstanceId,
				fromState = composition.lifecycleState,
				toState = toState,
			}
		)
	end
	Lifecycle.record(compositionInstanceId, composition.lifecycleState, toState)
	return Instances.update(compositionInstanceId, { lifecycleState = toState })
end

function Runtime.registerDefinition(input: any)
	local closed = ensureOpen(input)
	if closed ~= nil then
		return closed
	end
	local result = Definitions.register(input)
	if not result.ok then
		return fail(result.code, result.message, input)
	end
	counters.definitionsRegistered += 1
	Profiler.record(result.definition.compositionId, "definitionValidation", 0)
	return result
end

function Runtime.unregisterDefinition(compositionId: string)
	local closed = ensureOpen({ compositionId = compositionId })
	if closed ~= nil then
		return closed
	end
	return Definitions.unregister(compositionId)
end

function Runtime.createComposition(input: any)
	local closed = ensureOpen(input)
	if closed ~= nil then
		return closed
	end
	if Definitions.get(input.compositionId) == nil then
		return fail(
			Types.VisualCompositionFailureType.UnknownDefinition,
			"unknown definition",
			input
		)
	end
	local result = Instances.create(input)
	if not result.ok then
		return fail(result.code, result.message, input)
	end
	counters.compositionsCreated += 1
	Profiler.record(result.composition.compositionInstanceId, "compositionCreation", 0)
	return result
end

function Runtime.bindComposition(compositionInstanceId: string)
	local closed = ensureOpen({ compositionInstanceId = compositionInstanceId })
	if closed ~= nil then
		return closed
	end
	local composition = Instances.get(compositionInstanceId)
	if composition == nil then
		return fail(Types.VisualCompositionFailureType.UnknownComposition, "unknown composition", {
			compositionInstanceId = compositionInstanceId,
		})
	end
	local binding = Bindings.bind(composition)
	if not binding.ok then
		return fail(binding.code, binding.message, composition)
	end
	local ownership = Ownership.claim(composition, composition.revision)
	if not ownership.ok then
		return fail(ownership.code, ownership.message, composition)
	end
	local transitioned = transition(compositionInstanceId, Types.VisualCompositionState.Bound)
	if not transitioned.ok then
		return transitioned
	end
	counters.compositionsBound += 1
	return binding
end

function Runtime.compileComposition(compositionInstanceId: string, expectedRevision: number)
	local closed = ensureOpen({ compositionInstanceId = compositionInstanceId })
	if closed ~= nil then
		return closed
	end
	local composition = Instances.get(compositionInstanceId)
	if composition == nil then
		return fail(Types.VisualCompositionFailureType.UnknownComposition, "unknown composition", {
			compositionInstanceId = compositionInstanceId,
		})
	end
	local definition = Definitions.get(composition.compositionId)
	if definition == nil then
		return fail(
			Types.VisualCompositionFailureType.UnknownDefinition,
			"unknown definition",
			composition
		)
	end
	local binding = Bindings.get(compositionInstanceId)
	if binding == nil then
		return fail(
			Types.VisualCompositionFailureType.BindingConflict,
			"composition is not bound",
			composition
		)
	end
	local resolving = transition(compositionInstanceId, Types.VisualCompositionState.Resolving)
	if not resolving.ok then
		return resolving
	end
	Evidence.record(
		"composition compile started",
		{ compositionInstanceId = compositionInstanceId }
	)
	local revisionResult = Revisions.commit(compositionInstanceId, expectedRevision)
	if not revisionResult.ok then
		Instances.update(compositionInstanceId, { lifecycleState = composition.lifecycleState })
		return fail(revisionResult.code, revisionResult.message, composition)
	end
	local plan = Resolver.resolve(definition, composition, binding, revisionResult.revision)
	local committed = Plans.commit(plan)
	Instances.update(compositionInstanceId, {
		revision = revisionResult.revision,
		lifecycleState = Types.VisualCompositionState.Resolved,
	})
	Metrics.increment("compositionsResolved")
	Metrics.increment("nodesCompiled", #plan.orderedNodes)
	Metrics.increment("layersCompiled", #plan.layers)
	Metrics.increment("regionsCompiled", #plan.regions)
	counters.compositionsCompiled += 1
	Profiler.record(compositionInstanceId, "compositionCompilation", 0)
	Evidence.record("composition compiled", plan)
	return committed
end

function Runtime.resolveComposition(compositionInstanceId: string, expectedRevision: number)
	return Runtime.compileComposition(compositionInstanceId, expectedRevision)
end

function Runtime.activateComposition(compositionInstanceId: string)
	local closed = ensureOpen({ compositionInstanceId = compositionInstanceId })
	if closed ~= nil then
		return closed
	end
	local result = transition(compositionInstanceId, Types.VisualCompositionState.Active)
	if result.ok then
		Metrics.increment("compositionsActivated")
		counters.compositionsActivated += 1
		Evidence.record("composition activated", { compositionInstanceId = compositionInstanceId })
	end
	return result
end

function Runtime.supersedeComposition(compositionInstanceId: string)
	local closed = ensureOpen({ compositionInstanceId = compositionInstanceId })
	if closed ~= nil then
		return closed
	end
	local result = transition(compositionInstanceId, Types.VisualCompositionState.Superseded)
	if result.ok then
		Metrics.increment("compositionsSuperseded")
		counters.compositionsSuperseded += 1
		Evidence.record("composition superseded", { compositionInstanceId = compositionInstanceId })
	end
	return result
end

function Runtime.releaseComposition(compositionInstanceId: string)
	local closed = ensureOpen({ compositionInstanceId = compositionInstanceId })
	if closed ~= nil then
		return closed
	end
	local result = transition(compositionInstanceId, Types.VisualCompositionState.Released)
	if result.ok then
		Metrics.increment("compositionsReleased")
		counters.compositionsReleased += 1
		Evidence.record("composition released", { compositionInstanceId = compositionInstanceId })
	end
	return result
end

function Runtime.cancelComposition(compositionInstanceId: string)
	local closed = ensureOpen({ compositionInstanceId = compositionInstanceId })
	if closed ~= nil then
		return closed
	end
	return transition(compositionInstanceId, Types.VisualCompositionState.Cancelled)
end

function Runtime.getDefinition(compositionId: string)
	return Definitions.get(compositionId)
end

function Runtime.getComposition(compositionInstanceId: string)
	return Instances.get(compositionInstanceId)
end

function Runtime.getResolvedPlan(compositionInstanceId: string)
	return Plans.get(compositionInstanceId)
end

function Runtime.inspect()
	Profiler.record(Types.RobloxVisualCompositionProviderName, "diagnosticsLatency", 0)
	return Diagnostics.capture(Runtime)
end

function Runtime.getSnapshot()
	Profiler.record(Types.RobloxVisualCompositionProviderName, "snapshotLatency", 0)
	return Snapshots.capture(Runtime)
end

function Runtime.validate(): (boolean, string?)
	return Validation.validateRuntime(Definitions.inspect(), Instances.inspect())
end

function Runtime.shutdown()
	shutdown = true
	Evidence.record("runtime shutdown", {})
end

function Runtime.reset()
	shutdown = false
	for key in pairs(counters) do
		if key == "lastFailure" then
			counters[key] = nil
		else
			counters[key] = 0
		end
	end
	table.clear(failures)
	Bindings.clear()
	Definitions.clear()
	Evidence.clear()
	Instances.clear()
	Metrics.clear()
	Ownership.clear()
	Plans.clear()
	Profiler.clear()
	Revisions.clear()
	Evidence.record("runtime reset", {})
end

function Runtime.getCounters()
	return Serialization.deepCopy(counters)
end

function Runtime.getFailures()
	return Serialization.deepCopy(failures)
end

Runtime.reset()

return Runtime
