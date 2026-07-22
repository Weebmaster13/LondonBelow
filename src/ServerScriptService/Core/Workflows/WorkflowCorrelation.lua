--!strict

local Serialization = require(script.Parent.WorkflowSerialization)
local Types = require(script.Parent.WorkflowTypes)

local Correlation = {}
local records: { [string]: any } = {}
local order = {}

local function isId(value: any): boolean
	return type(value) == "string" and value:match("^[%w%.:%-_]+$") ~= nil and #value <= 128
end

function Correlation.create(record: any)
	if type(record) ~= "table" then
		return {
			ok = false,
			code = Types.FailureType.ValidationFailure,
			message = "correlation record must be a table",
		}
	end
	if
		not isId(record.correlationId)
		or not isId(record.workflowId)
		or not isId(record.instanceId)
	then
		return {
			ok = false,
			code = Types.FailureType.ValidationFailure,
			message = "invalid correlation identifiers",
		}
	end
	if records[record.correlationId] ~= nil then
		return {
			ok = false,
			code = Types.FailureType.DuplicateCorrelation,
			message = "duplicate correlation id",
		}
	end
	while #order >= Types.Limits.MaxCorrelationRecords do
		records[table.remove(order, 1)] = nil
	end
	records[record.correlationId] = Serialization.deepCopy({
		correlationId = record.correlationId,
		causationId = record.causationId,
		workflowId = record.workflowId,
		instanceId = record.instanceId,
		rootWorkflowId = record.rootWorkflowId or record.workflowId,
		parentWorkflowId = record.parentWorkflowId,
		sourceKind = record.sourceKind or "Workflow",
		sourceId = record.sourceId or record.instanceId,
		createdAt = os.clock(),
		metadata = Serialization.deepCopy(record.metadata or {}),
	})
	table.insert(order, record.correlationId)
	table.sort(order)
	return { ok = true, code = "Ok", correlationId = record.correlationId }
end

function Correlation.get(correlationId: string): any?
	local record = records[correlationId]
	return if record ~= nil then Serialization.deepCopy(record) else nil
end

function Correlation.inspect()
	local snapshot = {}
	for _, correlationId in ipairs(order) do
		snapshot[correlationId] = Serialization.deepCopy(records[correlationId])
	end
	return snapshot
end

function Correlation.clear()
	table.clear(records)
	table.clear(order)
end

return Correlation
