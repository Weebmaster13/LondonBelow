--!strict
-- Bounded queue records for presentation plans. No client routing occurs here.

local Serialization = require(script.Parent.PresentationSerialization)
local Types = require(script.Parent.PresentationTypes)

local QueueRuntime = {}

local queue: { any } = {}

local function trim()
	while #queue > Types.Limits.MaxQueue do
		table.remove(queue, 1)
	end
end

function QueueRuntime.enqueue(request: any): (boolean, string?)
	if #queue >= Types.Limits.MaxQueue then
		return false, "presentation queue is full"
	end
	table.insert(queue, {
		presentationId = request.presentationId,
		presentationType = request.presentationType,
		priority = request.priority,
		status = Types.Status.Queued,
		createdAt = os.clock(),
		expiresAt = request.expiresAt,
	})
	trim()
	return true, nil
end

function QueueRuntime.inspect()
	return {
		queueCount = #queue,
		queue = Serialization.deepCopy(queue),
	}
end

function QueueRuntime.clear()
	table.clear(queue)
end

return QueueRuntime
