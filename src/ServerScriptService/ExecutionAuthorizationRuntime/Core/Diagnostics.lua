--!strict

local Serialization = require(script.Parent.Serialization)
local State = require(script.Parent.State)
local Types = require(script.Parent.Types)
local Validation = require(script.Parent.Validation)

local Diagnostics = {}

function Diagnostics.capture(lifecycle: any): any
	local state = State.get()
	local validationOk, validationReason = Validation.validate()
	return {
		runtimeName = Types.RuntimeName,
		providerName = Types.RuntimeProviderName,
		initialized = lifecycle.initialized,
		started = lifecycle.started,
		authorizationLifecycleState = state.lifecycleState,
		loadedPolicyCount = #state.policies,
		loadedRuleCount = #state.rules,
		evaluationStatus = if state.decision ~= nil then "evaluated" else "notEvaluated",
		decisionSummary = if state.decision ~= nil
			then {
				decision = state.decision.decision,
				classification = state.decision.authorizationClassification,
			}
			else {},
		blockedRuntimeTruth = Serialization.deepCopy(Types.RuntimeTruth),
		publicationState = if state.decision ~= nil
			then state.decision.publicationState
			else "UNPUBLISHED",
		runtimeEvidenceState = "notGenerated",
		noExecution = true,
		noPlanningMutation = true,
		noScheduling = true,
		noStudioInvocation = true,
		noRunnerInvocation = true,
		noTransportCreation = true,
		noEnvelopeTransmission = true,
		noAcknowledgementReception = true,
		noNetworking = true,
		noGameplayMutation = true,
		validationOk = validationOk,
		validationReason = validationReason,
		validationFailures = state.validationFailures,
		lastSelfChecks = Serialization.deepCopy(lifecycle.lastSelfChecks),
	}
end

function Diagnostics.validate(): (boolean, string?)
	return Validation.validate()
end

return Diagnostics
