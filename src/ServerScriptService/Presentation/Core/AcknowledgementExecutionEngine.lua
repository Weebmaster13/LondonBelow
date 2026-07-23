--!strict

local Evidence = require(script.Parent.PresentationExecutionEvidence)
local Lifecycle = require(script.Parent.LifecycleExecutionEngine)
local Metrics = require(script.Parent.PresentationExecutionMetrics)
local Serialization = require(script.Parent.PresentationSerialization)
local Sessions = require(script.Parent.SessionExecutionEngine)
local Types = require(script.Parent.PresentationTypes)

local Engine = {}
local acknowledgements = {}
local order = {}
local nextOrdinal = 0

function Engine.produce(request: any)
	if #order >= Types.ExecutionLimits.MaxExecutionAcknowledgements then
		return {
			ok = false,
			code = Types.ExecutionFailureType.LimitExceeded,
			message = "acknowledgement limit exceeded",
		}
	end
	if type(request) ~= "table" then
		return {
			ok = false,
			code = Types.ExecutionFailureType.InvalidAcknowledgement,
			message = "acknowledgement must be a table",
		}
	end
	for _, field in ipairs({ "acknowledgementId", "executionSessionId", "acknowledgementKind" }) do
		if type(request[field]) ~= "string" or request[field] == "" then
			return {
				ok = false,
				code = Types.ExecutionFailureType.InvalidAcknowledgement,
				message = "invalid field " .. field,
			}
		end
	end
	if not Types.isRuntimeAcknowledgementKind(request.acknowledgementKind) then
		return {
			ok = false,
			code = Types.ExecutionFailureType.InvalidAcknowledgement,
			message = "invalid acknowledgement kind",
		}
	end
	if acknowledgements[request.acknowledgementId] ~= nil then
		return {
			ok = false,
			code = Types.ExecutionFailureType.DuplicateAcknowledgement,
			message = "duplicate acknowledgement",
		}
	end
	local execution = Sessions.get(request.executionSessionId)
	if execution == nil then
		return {
			ok = false,
			code = Types.ExecutionFailureType.UnknownExecution,
			message = "unknown execution",
		}
	end
	local transition = if request.acknowledgementKind == "Accepted"
			or request.acknowledgementKind == "Started"
		then Types.ExecutionState.WaitingForAcknowledgement
		elseif request.acknowledgementKind == "Completed" then Types.ExecutionState.Acknowledged
		elseif request.acknowledgementKind == "Cancelled" then Types.ExecutionState.Cancelled
		elseif request.acknowledgementKind == "Expired" then Types.ExecutionState.Expired
		else Types.ExecutionState.Failed
	local transitioned = Lifecycle.transition(request.executionSessionId, transition)
	if not transitioned.ok then
		return transitioned
	end
	nextOrdinal += 1
	local acknowledgement = {
		acknowledgementId = request.acknowledgementId,
		executionSessionId = request.executionSessionId,
		presentationSessionId = execution.presentationSessionId,
		acknowledgementKind = request.acknowledgementKind,
		createdOrdinal = nextOrdinal,
		runtimeMetadata = Serialization.deepCopy(request.runtimeMetadata or {}),
	}
	acknowledgements[acknowledgement.acknowledgementId] = acknowledgement
	order[#order + 1] = acknowledgement.acknowledgementId
	Metrics.increment("acknowledgementsProduced")
	Evidence.record("acknowledgement produced", acknowledgement)
	return { ok = true, code = "Ok", acknowledgement = Serialization.deepCopy(acknowledgement) }
end

function Engine.latestForExecution(executionId: string)
	for index = #order, 1, -1 do
		local acknowledgement = acknowledgements[order[index]]
		if acknowledgement.executionSessionId == executionId then
			return Serialization.deepCopy(acknowledgement)
		end
	end
	return nil
end

function Engine.inspect()
	local result = {}
	for index, acknowledgementId in ipairs(order) do
		result[index] = Serialization.deepCopy(acknowledgements[acknowledgementId])
	end
	return result
end

function Engine.clear()
	table.clear(acknowledgements)
	table.clear(order)
	nextOrdinal = 0
end

return Engine
