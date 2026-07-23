--!strict

local Evidence = require(script.Parent.RenderingExecutionEvidence)
local Lifecycle = require(script.Parent.RenderingExecutionLifecycle)
local Metrics = require(script.Parent.RenderingExecutionMetrics)
local Serialization = require(script.Parent.PresentationSerialization)
local Sessions = require(script.Parent.RenderingExecutionSessionRegistry)
local Types = require(script.Parent.PresentationTypes)

local Acknowledgements = {}
local records = {}
local order = {}
local nextOrdinal = 0

function Acknowledgements.receive(input: any)
	if #order >= Types.RenderingExecutionLimits.MaxAcknowledgements then
		return {
			ok = false,
			code = Types.RenderingExecutionFailureType.LimitExceeded,
			message = "acknowledgement limit exceeded",
		}
	end
	if type(input) ~= "table" then
		return {
			ok = false,
			code = Types.RenderingExecutionFailureType.ValidationFailure,
			message = "acknowledgement must be a table",
		}
	end
	for _, field in ipairs({
		"acknowledgementId",
		"renderingExecutionSessionId",
		"rendererId",
		"kind",
	}) do
		if type(input[field]) ~= "string" or input[field] == "" then
			return {
				ok = false,
				code = Types.RenderingExecutionFailureType.ValidationFailure,
				message = "invalid field " .. field,
			}
		end
	end
	if not Types.isRenderingExecutionAcknowledgementKind(input.kind) then
		return {
			ok = false,
			code = Types.RenderingExecutionFailureType.ValidationFailure,
			message = "unsupported acknowledgement kind",
		}
	end
	if records[input.acknowledgementId] ~= nil then
		return {
			ok = false,
			code = Types.RenderingExecutionFailureType.DuplicateAcknowledgement,
			message = "duplicate acknowledgement",
		}
	end
	local session = Sessions.get(input.renderingExecutionSessionId)
	if session == nil then
		return {
			ok = false,
			code = Types.RenderingExecutionFailureType.UnknownExecutionSession,
			message = "unknown execution session",
		}
	end
	if session.rendererId ~= input.rendererId then
		return {
			ok = false,
			code = Types.RenderingExecutionFailureType.OwnershipMismatch,
			message = "renderer ownership mismatch",
		}
	end
	local waiting = Lifecycle.transition(
		input.renderingExecutionSessionId,
		Types.RenderingExecutionState.WaitingAcknowledgement
	)
	if
		not waiting.ok
		and session.executionState ~= Types.RenderingExecutionState.WaitingAcknowledgement
	then
		return waiting
	end
	local acknowledged = Lifecycle.transition(
		input.renderingExecutionSessionId,
		Types.RenderingExecutionState.Acknowledged
	)
	if not acknowledged.ok then
		return acknowledged
	end
	nextOrdinal += 1
	local record = {
		acknowledgementId = input.acknowledgementId,
		renderingExecutionSessionId = input.renderingExecutionSessionId,
		rendererId = input.rendererId,
		kind = input.kind,
		ordinal = nextOrdinal,
		runtimeMetadata = Serialization.deepCopy(input.runtimeMetadata or {}),
	}
	records[record.acknowledgementId] = record
	order[#order + 1] = record.acknowledgementId
	Metrics.increment("acknowledgements")
	Evidence.record("acknowledgement received", record)
	return { ok = true, code = "Ok", acknowledgement = Serialization.deepCopy(record) }
end

function Acknowledgements.latestForSession(sessionId: string)
	for index = #order, 1, -1 do
		local record = records[order[index]]
		if record.renderingExecutionSessionId == sessionId then
			return Serialization.deepCopy(record)
		end
	end
	return nil
end

function Acknowledgements.inspect()
	local result = {}
	for index, id in ipairs(order) do
		result[index] = Serialization.deepCopy(records[id])
	end
	return result
end

function Acknowledgements.clear()
	table.clear(records)
	table.clear(order)
	nextOrdinal = 0
end

return Acknowledgements
