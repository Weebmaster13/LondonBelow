--!strict

local RenderingRuntime = require(script.Parent.RobloxGuiRenderingRuntime)
local Types = require(script.Parent.RobloxGuiComponentTypes)
local Validator = require(script.Parent.RobloxGuiComponentValidator)

local Runtime = {}
local state = Types.RuntimeState.Idle
local busy = false
local sequence = 0
local activeComposition = nil
local audit = {}
local failures = {}
local counters = {
	composeRequests = 0,
	validationFailures = 0,
	renderCommits = 0,
	renderFailures = 0,
	idempotent = 0,
}

local function append(target: { any }, value: any, limit: number)
	if #target >= limit then
		table.remove(target, 1)
	end
	target[#target + 1] = value
end

local function record(kind: string, detail: any?)
	sequence += 1
	append(
		audit,
		table.freeze({ sequence = sequence, kind = kind, detail = detail or {} }),
		Types.Limits.maxAuditRecords
	)
end

local function fail(code: string, detail: any?)
	state = Types.RuntimeState.Failed
	local failure = table.freeze({ sequence = sequence + 1, code = code, detail = detail })
	append(failures, failure, Types.Limits.maxFailures)
	record("Failure", failure)
	return { ok = false, code = code, detail = detail }
end

function Runtime.configure(target: Instance)
	return RenderingRuntime.configure(target)
end

function Runtime.compose(composition: any)
	counters.composeRequests += 1
	if state == Types.RuntimeState.Shutdown then
		return fail(Types.FailureType.RuntimeShutdown)
	end
	if busy then
		return fail(Types.FailureType.RuntimeBusy)
	end
	if
		activeComposition
		and type(composition) == "table"
		and activeComposition.compositionId == composition.compositionId
		and activeComposition.revision == composition.targetRevision
	then
		counters.idempotent += 1
		return {
			ok = true,
			idempotent = true,
			compositionId = activeComposition.compositionId,
			revision = activeComposition.revision,
		}
	end
	local valid, reason, renderContract = Validator.validate(composition)
	if not valid or not renderContract then
		counters.validationFailures += 1
		return fail(reason or Types.FailureType.InvalidComposition)
	end
	busy = true
	state = Types.RuntimeState.Composing
	local result = RenderingRuntime.render(renderContract)
	busy = false
	if not result.ok then
		counters.renderFailures += 1
		return fail(Types.FailureType.RenderRejected, result)
	end
	activeComposition = table.freeze({
		compositionId = composition.compositionId,
		revision = composition.targetRevision,
		rootComponentId = composition.rootComponentId,
		componentCount = #composition.components,
	})
	counters.renderCommits += 1
	state = Types.RuntimeState.Committed
	record("CompositionCommitted", activeComposition)
	return {
		ok = true,
		idempotent = false,
		compositionId = activeComposition.compositionId,
		revision = activeComposition.revision,
		componentCount = activeComposition.componentCount,
		render = result,
	}
end

function Runtime.unmount()
	activeComposition = nil
	return RenderingRuntime.unmount()
end

function Runtime.inspect()
	return {
		runtimeVersion = Types.RuntimeVersion,
		schemaVersion = Types.SchemaVersion,
		state = state,
		busy = busy,
		activeComposition = activeComposition and table.clone(activeComposition) or nil,
		counters = table.clone(counters),
		failures = table.clone(failures),
		rendering = RenderingRuntime.inspect(),
		posture = {
			clientPresentationOnly = true,
			declarativeCompositionOnly = true,
			usesExistingRenderingRuntime = true,
			noGameplayAuthority = true,
			noNetworking = true,
			noPersistence = true,
			noWorkspaceMutation = true,
			noAnalytics = true,
			noTelemetry = true,
		},
	}
end

function Runtime.getSnapshot()
	return {
		diagnostics = Runtime.inspect(),
		audit = table.clone(audit),
		rendering = RenderingRuntime.getSnapshot(),
	}
end

function Runtime.shutdown()
	Runtime.unmount()
	RenderingRuntime.shutdown()
	activeComposition = nil
	state = Types.RuntimeState.Shutdown
	record("Shutdown")
end

return Runtime
