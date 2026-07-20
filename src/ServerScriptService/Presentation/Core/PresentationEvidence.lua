--!strict

local Serialization = require(script.Parent.PresentationSerialization)

local Evidence = {}

local records: { any } = {}

function Evidence.record(event: string, payload: any, limit: number)
	table.insert(records, {
		event = event,
		payload = Serialization.deepCopy(payload),
		recordedAt = os.clock(),
	})
	while #records > limit do
		table.remove(records, 1)
	end
end

function Evidence.inspect()
	return {
		evidenceCount = #records,
		records = Serialization.deepCopy(records),
	}
end

function Evidence.clear()
	table.clear(records)
end

return Evidence
