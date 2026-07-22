--!strict

local Serialization = require(script.Parent.WorkflowSerialization)

local Resumption = {}
local resumptions = {}

function Resumption.record(instanceId: string, messageId: string)
	table.insert(resumptions, {
		instanceId = instanceId,
		messageId = messageId,
		resumedAt = os.clock(),
	})
	return { ok = true, code = "Ok", instanceId = instanceId }
end

function Resumption.inspect()
	return Serialization.copyArray(resumptions)
end

function Resumption.clear()
	table.clear(resumptions)
end

return Resumption
