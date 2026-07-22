--!strict

local Serialization = require(script.Parent.WorkflowSerialization)
local Types = require(script.Parent.WorkflowTypes)

local Pipeline = {}
local records = {}
local activeExecutions: { [string]: boolean } = {}
local sequence = 0

local function supportedStage(value: any): boolean
	for _, stage in pairs(Types.ExecutionStage) do
		if value == stage then
			return true
		end
	end
	return false
end

function Pipeline.begin(instanceId: string)
	if activeExecutions[instanceId] then
		return {
			ok = false,
			code = Types.FailureType.DuplicateExecution,
			message = "workflow execution already active",
		}
	end
	activeExecutions[instanceId] = true
	return Pipeline.record(instanceId, Types.ExecutionStage.Created, {})
end

function Pipeline.finish(instanceId: string)
	activeExecutions[instanceId] = nil
	return Pipeline.record(instanceId, Types.ExecutionStage.Completed, {})
end

function Pipeline.record(instanceId: string, stage: string, payload: any?)
	if type(instanceId) ~= "string" or not supportedStage(stage) then
		return {
			ok = false,
			code = Types.FailureType.ValidationFailure,
			message = "invalid execution pipeline record",
		}
	end
	sequence += 1
	table.insert(records, {
		sequence = sequence,
		instanceId = instanceId,
		stage = stage,
		timestamp = os.clock(),
		payload = Serialization.deepCopy(payload or {}),
	})
	while #records > Types.Limits.MaxPipelineRecords do
		table.remove(records, 1)
	end
	return { ok = true, code = "Ok", sequence = sequence }
end

function Pipeline.inspect()
	return Serialization.copyArray(records)
end

function Pipeline.clear()
	table.clear(records)
	table.clear(activeExecutions)
	sequence = 0
end

return Pipeline
