--!strict

local Serialization = require(script.Parent.Serialization)
local State = require(script.Parent.State)
local Types = require(script.Parent.Types)
local Validation = require(script.Parent.Validation)

local Diagnostics = {}

function Diagnostics.capture(lifecycle: any): any
	local state = State.get()
	local validationOk, validationReason = Validation.validate()
	local graph = state.graph or { nodes = {}, dependencies = {} }
	return {
		runtimeName = Types.RuntimeName,
		providerName = Types.RuntimeProviderName,
		initialized = lifecycle.initialized,
		started = lifecycle.started,
		planningLifecycleState = state.lifecycleState,
		graphStatistics = {
			nodes = #graph.nodes,
			dependencies = #graph.dependencies,
		},
		dependencyValidationStatus = if validationOk then "valid" else tostring(validationReason),
		constraintValidationStatus = if state.publication ~= nil then "valid" else "notPublished",
		eligibilitySummary = if state.publication ~= nil
			then state.publication.eligibilitySummary
			else {},
		publicationStatus = if state.publication ~= nil
			then state.publication.publicationState
			else "UNPUBLISHED",
		blockedRuntimeTruth = Serialization.deepCopy(Types.RuntimeTruth),
		runtimeEvidenceStatus = "notGenerated",
		noExecution = true,
		noStudioInvocation = true,
		noRunnerInvocation = true,
		noTransportCreation = true,
		noEnvelopeTransmission = true,
		noAcknowledgementReception = true,
		noNetworking = true,
		noGameplayMutation = true,
		lastSelfChecks = Serialization.deepCopy(lifecycle.lastSelfChecks),
		validationFailures = state.validationFailures,
	}
end

function Diagnostics.validate(): (boolean, string?)
	return Validation.validate()
end

return Diagnostics
