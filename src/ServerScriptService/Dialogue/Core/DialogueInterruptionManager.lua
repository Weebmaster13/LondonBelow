--!strict

local Evidence = require(script.Parent.InteractionEvidence)
local Metrics = require(script.Parent.InteractionMetrics)
local Serialization = require(script.Parent.DialogueSerialization)
local Types = require(script.Parent.DialogueInteractionTypes)

local Interruption = {}
local records = {}

function Interruption.interrupt(executionId: string, reason: string, priority: number)
	if #records >= Types.Limits.MaxInterruptions then
		return {
			ok = false,
			code = Types.FailureType.LimitExceeded,
			message = "interruption limit exceeded",
		}
	end
	records[#records + 1] = {
		executionId = executionId,
		reason = reason,
		priority = priority,
		status = "Interrupted",
	}
	Metrics.increment("interruptions")
	Evidence.record(
		"interruption",
		{ executionId = executionId, reason = reason, priority = priority }
	)
	return { ok = true, code = "Ok" }
end

function Interruption.resume(executionId: string)
	for _, record in ipairs(records) do
		if record.executionId == executionId and record.status == "Interrupted" then
			record.status = "Resumed"
			Metrics.increment("resumes")
			Evidence.record("resume", { executionId = executionId })
			return { ok = true, code = "Ok" }
		end
	end
	return {
		ok = false,
		code = Types.FailureType.InvalidInterruption,
		message = "execution is not interrupted",
	}
end

function Interruption.inspect()
	return Serialization.deepCopy(records)
end

function Interruption.clear()
	table.clear(records)
end

return Interruption
