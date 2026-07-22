--!strict

local Evidence = require(script.Parent.WorkflowEvidence)
local Serialization = require(script.Parent.WorkflowSerialization)
local Types = require(script.Parent.WorkflowTypes)

local Lifecycle = {}
local states: { [string]: string } = {}

local transitions = {
	[Types.LifecycleState.Created] = { [Types.LifecycleState.Registered] = true },
	[Types.LifecycleState.Registered] = { [Types.LifecycleState.Validated] = true },
	[Types.LifecycleState.Validated] = { [Types.LifecycleState.Scheduled] = true },
	[Types.LifecycleState.Scheduled] = {
		[Types.LifecycleState.Running] = true,
		[Types.LifecycleState.Cancelled] = true,
	},
	[Types.LifecycleState.Running] = {
		[Types.LifecycleState.Waiting] = true,
		[Types.LifecycleState.Completed] = true,
		[Types.LifecycleState.Cancelled] = true,
		[Types.LifecycleState.Failed] = true,
	},
	[Types.LifecycleState.Waiting] = {
		[Types.LifecycleState.Running] = true,
		[Types.LifecycleState.Completed] = true,
		[Types.LifecycleState.Cancelled] = true,
		[Types.LifecycleState.Failed] = true,
	},
	[Types.LifecycleState.Completed] = { [Types.LifecycleState.Archived] = true },
	[Types.LifecycleState.Cancelled] = { [Types.LifecycleState.Archived] = true },
	[Types.LifecycleState.Failed] = { [Types.LifecycleState.Archived] = true },
}

function Lifecycle.create(instanceId: string)
	states[instanceId] = Types.LifecycleState.Created
	return Lifecycle.transition(instanceId, Types.LifecycleState.Registered)
end

function Lifecycle.transition(instanceId: string, targetState: string)
	local current = states[instanceId]
	if current == nil then
		return {
			ok = false,
			code = Types.FailureType.UnknownInstance,
			message = "unknown workflow instance",
		}
	end
	if current == Types.LifecycleState.Archived then
		return {
			ok = false,
			code = Types.FailureType.TerminalInstanceMutation,
			message = "archived instance cannot transition",
		}
	end
	if transitions[current] == nil or not transitions[current][targetState] then
		return {
			ok = false,
			code = Types.FailureType.InvalidLifecycleTransition,
			message = current .. " cannot transition to " .. targetState,
		}
	end
	states[instanceId] = targetState
	Evidence.record("workflow lifecycle transition", {
		instanceId = instanceId,
		fromState = current,
		toState = targetState,
	})
	return { ok = true, code = "Ok", instanceId = instanceId, state = targetState }
end

function Lifecycle.get(instanceId: string): string?
	return states[instanceId]
end

function Lifecycle.inspect()
	return Serialization.deepCopy(states)
end

function Lifecycle.clear()
	table.clear(states)
end

return Lifecycle
