--!strict

local Evidence = {}

function Evidence.record(state: any, event: string, payload: any)
	state.recordEvidence({
		event = event,
		payload = payload,
		recordedAt = os.clock(),
	})
end

return Evidence
