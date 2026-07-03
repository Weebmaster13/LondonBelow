--!strict
-- Snapshot builder for immutable Event Graph schema state.

local State = require(script.Parent.EventGraphState)
local Types = require(script.Parent.EventGraphTypes)

local Snapshots = {}

function Snapshots.capture(lifecycle: any, dependencies: any)
	local state = State.inspect()
	local snapshot = {
		kind = "EventGraphSnapshot",
		mode = Types.Mode,
		initialized = lifecycle.initialized,
		started = lifecycle.started,
		counts = state.counts,
		schemas = {
			nodes = state.nodes,
			channels = state.channels,
			edges = state.edges,
			sources = state.sources,
			sinks = state.sinks,
			subscriptions = state.subscriptions,
			propagations = state.propagations,
			priorities = state.priorities,
			filters = state.filters,
			payloadContracts = state.payloadContracts,
			orderings = state.orderings,
			audits = state.audits,
		},
		integrityPosture = {
			nodes = "records, not live events",
			channels = "schema channels, not bus channels",
			edges = "relationships, not propagation",
			sources = "origin schemas, not publishers",
			sinks = "recipient schemas, not listeners",
			subscriptions = "relationship schemas, not live subscriptions",
			propagations = "policies, not propagation execution",
			priorities = "policy values, not dispatch order",
			filters = "schema constraints, not live filtering",
			payloadContracts = "shape descriptions, not delivery",
			orderings = "metadata, not sequencing execution",
			audits = "review summaries, not enforcement",
		},
		noExecutionPosture = {
			busExecution = false,
			eventDispatch = false,
			signalFire = false,
			remoteCommunication = false,
			liveSubscriptions = false,
			listenerExecution = false,
			callbackRun = false,
			payloadDelivery = false,
			routingRun = false,
			propagationRun = false,
			queueProcessing = false,
			workspaceMutation = false,
			clientAuthority = false,
		},
		validationFailures = state.validationFailures,
	}
	State.recordSnapshot(snapshot)
	return dependencies.Serialization.deepCopy(snapshot)
end

return Snapshots
