--!strict

local Evidence = require(script.Parent.MessagingEvidence)
local Serialization = require(script.Parent.MessagingSerialization)
local Types = require(script.Parent.MessagingTypes)

local Lifecycle = {}
local states: { [string]: string } = {}

local transitions = {
	[Types.LifecycleState.Created] = { [Types.LifecycleState.Registered] = true },
	[Types.LifecycleState.Registered] = { [Types.LifecycleState.Validated] = true },
	[Types.LifecycleState.Validated] = { [Types.LifecycleState.Initialized] = true },
	[Types.LifecycleState.Initialized] = { [Types.LifecycleState.Ready] = true },
	[Types.LifecycleState.Ready] = { [Types.LifecycleState.Running] = true },
	[Types.LifecycleState.Running] = {
		[Types.LifecycleState.Suspended] = true,
		[Types.LifecycleState.Shutdown] = true,
	},
	[Types.LifecycleState.Suspended] = {
		[Types.LifecycleState.Running] = true,
		[Types.LifecycleState.Shutdown] = true,
	},
}

function Lifecycle.create(consumerId: string)
	states[consumerId] = Types.LifecycleState.Created
	return Lifecycle.transition(consumerId, Types.LifecycleState.Registered)
end

function Lifecycle.transition(consumerId: string, targetState: string)
	local current = states[consumerId]
	if current == nil then
		return {
			ok = false,
			code = Types.FailureType.UnknownConsumer,
			message = "unknown lifecycle consumer",
		}
	end
	if current == Types.LifecycleState.Shutdown then
		return {
			ok = false,
			code = Types.FailureType.InvalidLifecycleTransition,
			message = "terminal consumer cannot transition",
		}
	end
	if transitions[current] == nil or not transitions[current][targetState] then
		return {
			ok = false,
			code = Types.FailureType.InvalidLifecycleTransition,
			message = current .. " cannot transition to " .. targetState,
		}
	end
	states[consumerId] = targetState
	Evidence.record("consumer lifecycle transition", {
		consumerId = consumerId,
		fromState = current,
		toState = targetState,
	})
	return { ok = true, code = "Ok", consumerId = consumerId, state = targetState }
end

function Lifecycle.get(consumerId: string): string?
	return states[consumerId]
end

function Lifecycle.inspect()
	return Serialization.deepCopy(states)
end

function Lifecycle.clear()
	table.clear(states)
end

return Lifecycle
