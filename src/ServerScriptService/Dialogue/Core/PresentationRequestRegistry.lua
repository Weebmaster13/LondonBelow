--!strict

local Evidence = require(script.Parent.PresentationEvidence)
local Metrics = require(script.Parent.PresentationMetrics)
local Serialization = require(script.Parent.DialogueSerialization)
local Types = require(script.Parent.DialoguePresentationTypes)

local Registry = {}
local requests = {}
local order = {}
local nextOrdinal = 0

local terminal = {
	[Types.RequestStatus.Completed] = true,
	[Types.RequestStatus.Closed] = true,
	[Types.RequestStatus.Rejected] = true,
	[Types.RequestStatus.Cancelled] = true,
	[Types.RequestStatus.Expired] = true,
	[Types.RequestStatus.Failed] = true,
}

function Registry.create(request: any)
	if #order >= Types.Limits.MaxPresentationRequests then
		return {
			ok = false,
			code = Types.FailureType.LimitExceeded,
			message = "presentation request limit exceeded",
		}
	end
	if requests[request.presentationId] ~= nil then
		return {
			ok = false,
			code = Types.FailureType.DuplicatePresentation,
			message = "duplicate presentation",
		}
	end
	nextOrdinal += 1
	local stored = Serialization.deepCopy(request)
	stored.createdOrdinal = nextOrdinal
	stored.status = if stored.synchronizationPolicy == Types.SynchronizationPolicy.NoWait
		then Types.RequestStatus.Registered
		else Types.RequestStatus.PendingAcknowledgement
	requests[stored.presentationId] = stored
	order[#order + 1] = stored.presentationId
	Metrics.increment("requestsCreated")
	if stored.status == Types.RequestStatus.PendingAcknowledgement then
		Metrics.increment("requestsPending")
	end
	Evidence.record("presentation request created", {
		presentationId = stored.presentationId,
		status = stored.status,
	})
	return { ok = true, code = "Ok", request = Serialization.deepCopy(stored) }
end

function Registry.get(presentationId: string)
	local request = requests[presentationId]
	return if request then Serialization.deepCopy(request) else nil
end

function Registry.updateStatus(presentationId: string, status: string, metadata: any?)
	local request = requests[presentationId]
	if request == nil then
		return {
			ok = false,
			code = Types.FailureType.UnknownPresentation,
			message = "unknown presentation",
		}
	end
	if terminal[request.status] then
		return {
			ok = false,
			code = Types.FailureType.InvalidLifecycleTransition,
			message = "presentation is terminal",
		}
	end
	request.status = status
	request.lifecycleMetadata = Serialization.deepCopy(metadata or {})
	if status == Types.RequestStatus.Completed then
		Metrics.increment("requestsCompleted")
	elseif status == Types.RequestStatus.Cancelled then
		Metrics.increment("requestsCancelled")
	elseif status == Types.RequestStatus.Rejected then
		Metrics.increment("requestsRejected")
	end
	Evidence.record("presentation request status changed", {
		presentationId = presentationId,
		status = status,
	})
	return { ok = true, code = "Ok", request = Serialization.deepCopy(request) }
end

function Registry.inspect()
	local result = {}
	for index, presentationId in ipairs(order) do
		result[index] = Serialization.deepCopy(requests[presentationId])
	end
	return result
end

function Registry.count(): number
	return #order
end

function Registry.clear()
	table.clear(requests)
	table.clear(order)
	nextOrdinal = 0
end

return Registry
