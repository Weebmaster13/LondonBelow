--!strict

local Serialization = require(script.Parent.PresentationSerialization)
local Types = require(script.Parent.PresentationTypes)

local Evidence = {}
local events = {}

function Evidence.record(eventKind: string, payload: any?)
	local event = {
		evidenceId = "visual.execution.evidence." .. tostring(#events + 1),
		eventKind = eventKind,
		sequence = #events + 1,
		payload = Serialization.diagnosticCopy(payload or {}),
	}
	events[#events + 1] = event
	while #events > Types.VisualExecutionLimits.MaxEvidence do
		table.remove(events, 1)
	end
	return Serialization.deepCopy(event)
end

function Evidence.inspect()
	return Serialization.deepCopy(events)
end

function Evidence.clear()
	table.clear(events)
end

return Evidence
