--!strict
-- Stores normalized execution request schemas only; it never executes gameplay.

local Serialization = require(script.Parent.ExecutionSerialization)
local Types = require(script.Parent.ExecutionTypes)

local RequestRuntime = {}

local requests: { [string]: any } = {}
local requestOrder: { string } = {}
local validationFailures: { any } = {}

local function trimMap(order: { string }, map: { [string]: any }, limit: number)
	while #order > limit do
		local id = table.remove(order, 1)
		if id ~= nil then
			map[id] = nil
		end
	end
end

local function trimList(list: { any }, limit: number)
	while #list > limit do
		table.remove(list, 1)
	end
end

function RequestRuntime.normalize(rawRequest: any, currentTime: number)
	local request = if type(rawRequest) == "table" then rawRequest else {}
	local createdAt = if type(request.createdAt) == "number" then request.createdAt else currentTime
	return {
		executionId = request.executionId,
		requester = request.requester,
		sourceSystem = request.sourceSystem,
		executionType = request.executionType,
		priority = if type(request.priority) == "number"
			then math.clamp(request.priority, 0, Types.Limits.MaxPriority)
			else 0,
		createdAt = createdAt,
		expiresAt = if type(request.expiresAt) == "number"
			then request.expiresAt
			else createdAt + Types.Limits.DefaultExpirationSeconds,
		dependencies = request.dependencies or {},
		approvals = request.approvals or {},
		metadata = request.metadata or {},
		reason = request.reason,
		context = request.context or {},
	}
end

function RequestRuntime.exists(executionId: string): boolean
	return requests[executionId] ~= nil
end

function RequestRuntime.add(request: any)
	requests[request.executionId] = Serialization.deepCopy(request)
	table.insert(requestOrder, request.executionId)
	trimMap(requestOrder, requests, Types.Limits.MaxRequests)
end

function RequestRuntime.recordValidationFailure(reason: string, payload: any?)
	table.insert(validationFailures, {
		reason = reason,
		payload = Serialization.diagnosticCopy(payload),
		createdAt = os.clock(),
	})
	trimList(validationFailures, Types.Limits.MaxValidationFailures)
end

function RequestRuntime.inspect()
	return {
		requestCount = #requestOrder,
		requests = Serialization.deepCopy(requests),
		validationFailureCount = #validationFailures,
		validationFailures = Serialization.deepCopy(validationFailures),
	}
end

function RequestRuntime.clear()
	table.clear(requests)
	table.clear(requestOrder)
	table.clear(validationFailures)
end

return RequestRuntime
