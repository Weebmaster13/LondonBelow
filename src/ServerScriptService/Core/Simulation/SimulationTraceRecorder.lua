--!strict

local Config = require(script.Parent.SimulationConfig)

local SimulationTraceRecorder = {}

local traces: { any } = {}

function SimulationTraceRecorder.record(scenarioId: string, eventName: string, details: any?)
	table.insert(traces, {
		at = os.clock(),
		scenarioId = scenarioId,
		event = eventName,
		details = details or {},
	})

	while #traces > Config.MaxTraceEvents do
		table.remove(traces, 1)
	end
end

function SimulationTraceRecorder.forScenario(scenarioId: string): { any }
	local selected = {}

	for _, trace in ipairs(traces) do
		if trace.scenarioId == scenarioId then
			table.insert(selected, trace)
		end
	end

	return selected
end

function SimulationTraceRecorder.inspect()
	return table.clone(traces)
end

function SimulationTraceRecorder.clear()
	table.clear(traces)
end

return SimulationTraceRecorder
