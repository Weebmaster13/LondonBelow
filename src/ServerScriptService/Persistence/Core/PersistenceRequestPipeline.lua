--!strict

local Evidence = require(script.Parent.PersistenceEvidence)
local FailureRuntime = require(script.Parent.PersistenceFailureRuntime)
local Registry = require(script.Parent.PersistenceAdapterRegistry)
local ResponsePipeline = require(script.Parent.PersistenceResponsePipeline)
local RetryRuntime = require(script.Parent.PersistenceRetryRuntime)
local Serialization = require(script.Parent.PersistenceSerialization)
local Types = require(script.Parent.PersistenceTypes)
local Validation = require(script.Parent.PersistenceValidation)

local Pipeline = {}
local history: { any } = {}
local failures: { any } = {}

local function remember(list: { any }, record: any, limit: number)
	table.insert(list, Serialization.deepCopy(record))
	while #list > limit do
		table.remove(list, 1)
	end
end

local function failureResponse(requestRecord: any, providerId: string, reason: string)
	local response = {
		success = false,
		provider = providerId,
		duration = 0,
		result = nil,
		failureReason = reason,
	}
	remember(failures, {
		requestId = requestRecord.requestId,
		operation = requestRecord.operation,
		failureKind = FailureRuntime.classify(reason),
		failureReason = reason,
	}, Types.Limits.MaxFailures)
	Evidence.record("failure", failures[#failures])
	return response
end

function Pipeline.execute(requestRecord: any): (boolean, string?, any?)
	local ok, reason = Validation.runtimeRequest(requestRecord)
	if not ok then
		Evidence.record("validation", { stage = "request", reason = reason })
		local rejected =
			failureResponse(requestRecord or {}, "unresolved", reason or "ValidationFailure")
		ResponsePipeline.validate(rejected)
		return false, reason, rejected
	end
	local requestCopy = Serialization.deepCopy(requestRecord)
	remember(history, requestCopy, Types.Limits.MaxRequestHistory)
	Evidence.record(
		"save request",
		if requestCopy.operation == Types.Operation.Save then requestCopy else nil
	)
	Evidence.record(
		"load request",
		if requestCopy.operation == Types.Operation.Load then requestCopy else nil
	)
	Evidence.record(
		"delete request",
		if requestCopy.operation == Types.Operation.Delete then requestCopy else nil
	)

	local provider, providerReason = Registry.resolveProvider(requestCopy.provider)
	if provider == nil then
		local rejected = failureResponse(
			requestCopy,
			requestCopy.provider or "unresolved",
			providerReason or "missing provider"
		)
		ResponsePipeline.validate(rejected)
		return false, providerReason, rejected
	end
	if provider.supportedOperations[requestCopy.operation] ~= true then
		local rejected = failureResponse(requestCopy, provider.providerId, "UnsupportedOperation")
		ResponsePipeline.validate(rejected)
		return false, "UnsupportedOperation", rejected
	end

	local plan = RetryRuntime.plan(requestCopy)
	if plan.attempts <= 0 then
		local rejected = failureResponse(requestCopy, provider.providerId, "PermanentFailure")
		ResponsePipeline.validate(rejected)
		return false, "PermanentFailure", rejected
	end

	local lastResponse: any = nil
	for attempt = 1, plan.attempts do
		RetryRuntime.record(requestCopy, attempt, "attempted")
		local response = provider.execute(requestCopy)
		response.duration = response.duration or 0
		lastResponse = response
		local responseOk, responseReason = ResponsePipeline.validate(response)
		if not responseOk then
			return false, responseReason, response
		end
		if response.success then
			RetryRuntime.record(requestCopy, attempt, "succeeded")
			return true, nil, response
		end
		RetryRuntime.record(requestCopy, attempt, "failed")
	end

	local exhausted = failureResponse(
		requestCopy,
		provider.providerId,
		lastResponse.failureReason or "RetryExhausted"
	)
	ResponsePipeline.validate(exhausted)
	return false, exhausted.failureReason, exhausted
end

function Pipeline.inspect()
	return {
		requests = #history,
		failures = #failures,
		lastRequest = history[#history],
		lastFailure = failures[#failures],
		requestHistory = Serialization.deepCopy(history),
		failureHistory = Serialization.deepCopy(failures),
	}
end

function Pipeline.clear()
	table.clear(history)
	table.clear(failures)
end

return Pipeline
