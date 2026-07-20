--!strict

local Types = require(script.Parent.GameplayFlowTypes)

local DiagnosticsRuntime = {}

function DiagnosticsRuntime.capture(runtimeState: any, registry: any, state: any, evidence: any)
	local stateInspection = state.inspect()
	return {
		gameplayFlowRuntimePosture = {
			available = runtimeState.initialized == true,
			started = runtimeState.started == true,
			serverAuthoritative = true,
			ownsGameplayProgression = true,
			ownsInteractionValidation = false,
			ownsEnvironmentalState = false,
			ownsPresentationExecution = false,
			ownsNetworking = false,
			ownsPersistence = false,
			ownsClientAuthority = false,
			providerName = Types.ProviderName,
		},
		activeObjective = stateInspection.activeObjective,
		completedObjectives = stateInspection.completedObjectives,
		failedObjectives = stateInspection.failedObjectives,
		queuedEvaluations = stateInspection.queuedEvaluations,
		conditionEvaluations = stateInspection.conditionEvaluations,
		objectiveTransitions = stateInspection.objectiveTransitions,
		checkpointEligible = stateInspection.checkpointEligible,
		registry = registry.inspect(),
		evidenceCount = evidence.count(),
		lastSelfChecks = runtimeState.lastSelfChecks,
		health = {
			healthy = runtimeState.initialized == true,
			status = if runtimeState.initialized == true then "Ready" else "NotInitialized",
			message = "Gameplay Flow Runtime owns Chapter 0 objective progression only.",
		},
	}
end

function DiagnosticsRuntime.validate(registry: any): (boolean, string?)
	return registry.validate()
end

return DiagnosticsRuntime
