--!strict
-- Health-only diagnostics for the Event Graph schema runtime.

local State = require(script.Parent.EventGraphState)
local Types = require(script.Parent.EventGraphTypes)

local Diagnostics = {}

local function limitUsage(count: number, limit: number)
	return {
		count = count,
		limit = limit,
		remaining = math.max(limit - count, 0),
	}
end

function Diagnostics.capture(lifecycle: any, dependencies: any)
	local state = State.inspect()
	local counts = state.counts
	local validationOk, validationReason = dependencies.Validation.validate()
	return {
		initialized = lifecycle.initialized,
		started = lifecycle.started,
		lifecycleState = if lifecycle.started
			then "Started"
			elseif lifecycle.initialized then "Initialized"
			else "Cold",
		health = if validationOk then "Healthy" else "Unhealthy",
		validationOk = validationOk,
		validationReason = validationReason,
		counts = counts,
		limitUsage = {
			nodes = limitUsage(counts.nodes, Types.Limits.MaxEventNodes),
			channels = limitUsage(counts.channels, Types.Limits.MaxChannels),
			edges = limitUsage(counts.edges, Types.Limits.MaxEdges),
			sources = limitUsage(counts.sources, Types.Limits.MaxSources),
			sinks = limitUsage(counts.sinks, Types.Limits.MaxSinks),
			subscriptions = limitUsage(counts.subscriptions, Types.Limits.MaxSubscriptions),
			propagations = limitUsage(counts.propagations, Types.Limits.MaxPropagations),
			priorities = limitUsage(counts.priorities, Types.Limits.MaxPriorities),
			filters = limitUsage(counts.filters, Types.Limits.MaxFilters),
			payloadContracts = limitUsage(
				counts.payloadContracts,
				Types.Limits.MaxPayloadContracts
			),
			orderings = limitUsage(counts.orderings, Types.Limits.MaxOrderings),
			audits = limitUsage(counts.audits, Types.Limits.MaxAudits),
		},
		runtimeLimits = Types.Limits,
		serializationPosture = "rejects unsafe runtime values, cycles, deep payloads, oversized strings, and oversized node counts",
		snapshotIsolationProof = "snapshots are deep copied schema data",
		diagnosticsIsolationProof = "diagnostics are deep copied health data",
		integrityPosture = {
			eventGraph = "schemas only",
			node = "records only",
			channel = "schema channels only",
			edge = "relationships only",
			source = "origin schemas only",
			sink = "recipient schemas only",
			subscription = "relationship schemas only",
			propagation = "policy only",
			priority = "policy value only",
			filter = "shape constraint only",
			payloadContract = "shape description only",
			ordering = "metadata only",
			audit = "review summary only",
		},
		noExecutionPosture = {
			noBusExecution = true,
			noEventDispatch = true,
			noSignalFire = true,
			noRemoteConstructors = true,
			noRemoteCommunication = true,
			noLiveSubscriptions = true,
			noListenerExecution = true,
			noCallbackRun = true,
			noPayloadDelivery = true,
			noRoutingRun = true,
			noPropagationRun = true,
			noQueueProcessing = true,
			noFilterRun = true,
			noPriorityRun = true,
			noGameplayEventRun = true,
			noSchedulerRun = true,
			noLifecycleRun = true,
			noRuntimeOrchestration = true,
			noWorkspaceMutation = true,
			noRemotes = true,
			noClientAuthority = true,
			noDataStore = true,
			noHttp = true,
			noMessaging = true,
			noAnalytics = true,
			noTelemetry = true,
			noChapterContent = true,
		},
		recentValidationFailures = state.validationFailures,
		lastSelfCheckResult = lifecycle.lastSelfChecks,
	}
end

function Diagnostics.validate(dependencies: any): (boolean, string?)
	local ok, reason = dependencies.Validation.validate()
	if not ok then
		return false, reason
	end
	return true, nil
end

return Diagnostics
