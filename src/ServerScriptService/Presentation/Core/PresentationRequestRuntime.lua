--!strict
-- Bounded storage for presentation request schemas.

local Serialization = require(script.Parent.PresentationSerialization)
local Types = require(script.Parent.PresentationTypes)

local RequestRuntime = {}

local requests: { [string]: any } = {}
local requestOrder: { string } = {}
local validationFailures: { any } = {}

local function trimMap()
	while #requestOrder > Types.Limits.MaxRequests do
		local id = table.remove(requestOrder, 1)
		if id ~= nil then
			requests[id] = nil
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
		presentationId = request.presentationId,
		requester = request.requester,
		sourceSystem = request.sourceSystem,
		presentationType = request.presentationType,
		priority = if type(request.priority) == "number"
			then math.clamp(request.priority, 0, Types.Limits.MaxPriority)
			else 0,
		createdAt = createdAt,
		expiresAt = if type(request.expiresAt) == "number"
			then request.expiresAt
			else createdAt + Types.Limits.DefaultExpirationSeconds,
		approvals = request.approvals or {},
		channels = request.channels or {},
		metadata = request.metadata or {},
		context = request.context or {},
		reason = request.reason,
	}
end

function RequestRuntime.exists(presentationId: string): boolean
	return requests[presentationId] ~= nil
end

function RequestRuntime.add(request: any)
	requests[request.presentationId] = Serialization.deepCopy(request)
	table.insert(requestOrder, request.presentationId)
	trimMap()
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
