--!strict

local Evidence = require(script.Parent.WorkflowEvidence)
local Serialization = require(script.Parent.WorkflowSerialization)

local Retries = {}
local retryRecords = {}

function Retries.record(instanceId: string, reason: string, attempt: number, maxAttempts: number)
	local record = {
		instanceId = instanceId,
		reason = reason,
		attempt = attempt,
		maxAttempts = maxAttempts,
	}
	table.insert(retryRecords, record)
	Evidence.record("workflow retry recorded", record)
	return { ok = true, code = "Ok", exhausted = attempt >= maxAttempts }
end

function Retries.inspect()
	return Serialization.copyArray(retryRecords)
end

function Retries.clear()
	table.clear(retryRecords)
end

return Retries
