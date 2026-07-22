--!strict

local Evidence = require(script.Parent.WorkflowEvidence)
local Instances = require(script.Parent.WorkflowInstances)
local Registry = require(script.Parent.WorkflowRegistry)
local Serialization = require(script.Parent.WorkflowSerialization)
local Types = require(script.Parent.WorkflowTypes)

local Transitions = {}

local function supportedSource(source: string): boolean
	for _, value in pairs(Types.TransitionSource) do
		if value == source then
			return true
		end
	end
	return false
end

function Transitions.apply(instanceId: string, source: string, variables: any?)
	if not supportedSource(source) then
		return {
			ok = false,
			code = Types.FailureType.InvalidTransitionSource,
			message = "invalid transition source",
		}
	end
	local instance = Instances.get(instanceId)
	if instance == nil then
		return { ok = false, code = Types.FailureType.UnknownInstance, message = "unknown instance" }
	end
	local definition = Registry.get(instance.workflowId)
	if definition == nil then
		return { ok = false, code = Types.FailureType.UnknownWorkflow, message = "unknown workflow" }
	end
	for _, transition in ipairs(definition.transitions) do
		if transition.fromState == instance.state and transition.source == source then
			local result = Instances.setState(
				instanceId,
				transition.toState,
				source,
				variables or instance.variables
			)
			if result.ok then
				Evidence.record("workflow transition applied", {
					instanceId = instanceId,
					fromState = instance.state,
					toState = transition.toState,
					source = source,
				})
			end
			return result
		end
	end
	return {
		ok = false,
		code = Types.FailureType.InvalidTransition,
		message = "no matching transition",
	}
end

function Transitions.inspect()
	return {
		transitionRuntime = "Passive",
		transitionSources = Serialization.deepCopy(Types.TransitionSource),
	}
end

return Transitions
