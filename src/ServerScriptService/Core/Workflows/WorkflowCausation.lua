--!strict

local Serialization = require(script.Parent.WorkflowSerialization)
local Types = require(script.Parent.WorkflowTypes)

local Causation = {}
local records = {}
local sequence = 0

local function supportedMessageKind(value: any): boolean
	for _, messageKind in pairs(Types.MessageKind) do
		if value == messageKind then
			return true
		end
	end
	return false
end

function Causation.record(record: any)
	if type(record) ~= "table" then
		return {
			ok = false,
			code = Types.FailureType.ValidationFailure,
			message = "causation record must be a table",
		}
	end
	if
		type(record.causationId) ~= "string"
		or type(record.correlationId) ~= "string"
		or type(record.instanceId) ~= "string"
		or not supportedMessageKind(record.messageKind)
	then
		return {
			ok = false,
			code = Types.FailureType.InvalidMessage,
			message = "invalid causation record",
		}
	end
	sequence += 1
	local stored = Serialization.deepCopy({
		sequence = sequence,
		causationId = record.causationId,
		parentCausationId = record.parentCausationId,
		correlationId = record.correlationId,
		instanceId = record.instanceId,
		messageKind = record.messageKind,
		sourceRuntime = record.sourceRuntime,
		targetRuntime = record.targetRuntime,
		createdAt = os.clock(),
		metadata = record.metadata or {},
	})
	table.insert(records, stored)
	while #records > Types.Limits.MaxCausationRecords do
		table.remove(records, 1)
	end
	return { ok = true, code = "Ok", sequence = sequence }
end

function Causation.inspect()
	return Serialization.copyArray(records)
end

function Causation.clear()
	table.clear(records)
	sequence = 0
end

return Causation
