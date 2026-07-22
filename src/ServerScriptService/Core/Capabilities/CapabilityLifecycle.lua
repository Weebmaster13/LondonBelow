--!strict

local Evidence = require(script.Parent.CapabilityEvidence)
local Serialization = require(script.Parent.CapabilitySerialization)
local Types = require(script.Parent.CapabilityTypes)

local Lifecycle = {}
local states: { [string]: string } = {}

local transitions = {
	[Types.LifecycleState.Created] = { [Types.LifecycleState.Registered] = true },
	[Types.LifecycleState.Registered] = { [Types.LifecycleState.Validated] = true },
	[Types.LifecycleState.Validated] = { [Types.LifecycleState.Initialized] = true },
	[Types.LifecycleState.Initialized] = { [Types.LifecycleState.Ready] = true },
	[Types.LifecycleState.Ready] = {
		[Types.LifecycleState.Running] = true,
		[Types.LifecycleState.Suspended] = true,
		[Types.LifecycleState.Shutdown] = true,
	},
	[Types.LifecycleState.Running] = {
		[Types.LifecycleState.Suspended] = true,
		[Types.LifecycleState.Shutdown] = true,
	},
	[Types.LifecycleState.Suspended] = {
		[Types.LifecycleState.Ready] = true,
		[Types.LifecycleState.Running] = true,
		[Types.LifecycleState.Shutdown] = true,
	},
}

function Lifecycle.create(capabilityId: string)
	states[capabilityId] = Types.LifecycleState.Created
	return Lifecycle.transition(capabilityId, Types.LifecycleState.Registered)
end

function Lifecycle.transition(capabilityId: string, targetState: string)
	local current = states[capabilityId]
	if current == nil then
		return {
			ok = false,
			code = Types.FailureType.UnknownCapability,
			message = "unknown capability",
		}
	end
	if current == Types.LifecycleState.Shutdown then
		return {
			ok = false,
			code = Types.FailureType.InvalidLifecycleTransition,
			message = "shutdown capability cannot transition",
		}
	end
	if transitions[current] == nil or not transitions[current][targetState] then
		return {
			ok = false,
			code = Types.FailureType.InvalidLifecycleTransition,
			message = current .. " cannot transition to " .. targetState,
		}
	end
	states[capabilityId] = targetState
	Evidence.record("capability lifecycle transition", {
		capabilityId = capabilityId,
		fromState = current,
		toState = targetState,
	})
	return { ok = true, code = "Ok", capabilityId = capabilityId, state = targetState }
end

function Lifecycle.get(capabilityId: string): string?
	return states[capabilityId]
end

function Lifecycle.inspect()
	return Serialization.deepCopy(states)
end

function Lifecycle.clear()
	table.clear(states)
end

return Lifecycle
