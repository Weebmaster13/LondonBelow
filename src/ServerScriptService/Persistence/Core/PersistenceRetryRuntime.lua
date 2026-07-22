--!strict

local Evidence = require(script.Parent.PersistenceEvidence)
local Serialization = require(script.Parent.PersistenceSerialization)
local Types = require(script.Parent.PersistenceTypes)
local Validation = require(script.Parent.PersistenceValidation)

local Retry = {}
local history: { any } = {}

local function remember(record: any)
	table.insert(history, Serialization.deepCopy(record))
	while #history > Types.Limits.MaxRetryHistory do
		table.remove(history, 1)
	end
	Evidence.record("retry", record)
end

function Retry.plan(requestRecord: any)
	local mode = requestRecord.retryMode or Types.RetryMode.Immediate
	if not Validation.retryMode(mode) then
		mode = Types.RetryMode.PermanentFailure
	end
	local attempts = 1
	if mode == Types.RetryMode.LimitedRetry then
		attempts = math.clamp(requestRecord.maxAttempts or 2, 1, Types.Limits.MaxRetryAttempts)
	elseif mode == Types.RetryMode.PermanentFailure then
		attempts = 0
	end
	return { mode = mode, attempts = attempts }
end

function Retry.record(requestRecord: any, attempt: number, status: string)
	remember({
		requestId = requestRecord.requestId,
		operation = requestRecord.operation,
		attempt = attempt,
		status = status,
	})
end

function Retry.inspect()
	return {
		retryCount = #history,
		lastRetry = history[#history],
		history = Serialization.deepCopy(history),
	}
end

function Retry.clear()
	table.clear(history)
end

return Retry
