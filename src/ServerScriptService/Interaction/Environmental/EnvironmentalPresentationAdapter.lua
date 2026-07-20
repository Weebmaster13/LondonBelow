--!strict

local Serialization = require(script.Parent.EnvironmentalSerialization)

local PresentationAdapter = {}

function PresentationAdapter.project(definition: any, state: any, plan: any?)
	local metadata = definition.presentationMetadata or {}
	return Serialization.deepCopy({
		objectId = definition.id,
		family = definition.family,
		state = state.currentState,
		stateRevision = state.revision,
		presentationRevision = state.presentationRevision,
		availableActionDisplayKeys = metadata.actionDisplayKeys or {},
		interactionPromptKey = metadata.promptKey,
		animationStateKey = if plan ~= nil and plan.presentation ~= nil
			then plan.presentation.animationStateKey
			else metadata.animationStateKey,
		audioStateKey = if plan ~= nil and plan.presentation ~= nil
			then plan.presentation.audioStateKey
			else metadata.audioStateKey,
		visualStateKey = if plan ~= nil and plan.presentation ~= nil
			then plan.presentation.visualStateKey
			else metadata.visualStateKey,
		enabled = state.enabled,
		busy = state.activeSessionId ~= nil,
	})
end

return PresentationAdapter
