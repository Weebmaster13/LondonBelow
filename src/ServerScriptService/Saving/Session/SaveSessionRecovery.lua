--!strict

local Evidence = require(script.Parent.SaveSessionEvidence)
local Serialization = require(script.Parent.SaveSessionSerialization)
local Types = require(script.Parent.SaveSessionTypes)

local Recovery = {}
local history: { any } = {}

function Recovery.recover(registry: any, lifecycle: any, sessionId: string): (boolean, string?)
	local session = registry.get(sessionId)
	if session == nil then
		return false, "unknown session"
	end
	if session.state ~= Types.State.Failed then
		return false, "recovery requires failed session"
	end
	local recoveringOk, recoveringReason =
		lifecycle.transition(registry, sessionId, Types.State.Recovering)
	if not recoveringOk then
		return false, recoveringReason
	end
	local activeOk, activeReason = lifecycle.transition(registry, sessionId, Types.State.Active)
	if not activeOk then
		return false, activeReason
	end
	local event = { sessionId = sessionId, recovered = true }
	table.insert(history, Serialization.deepCopy(event))
	Evidence.record("recovery", event)
	return true, nil
end

function Recovery.inspect()
	return { recoverySnapshot = Serialization.deepCopy(history), recoveries = #history }
end

function Recovery.clear()
	table.clear(history)
end

return Recovery
