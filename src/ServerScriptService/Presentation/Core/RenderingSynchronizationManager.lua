--!strict

local Acknowledgements = require(script.Parent.RendererAcknowledgementRegistry)
local Evidence = require(script.Parent.RenderingEvidence)
local Metrics = require(script.Parent.RenderingMetrics)
local Requests = require(script.Parent.RenderingRequestRegistry)
local Serialization = require(script.Parent.PresentationSerialization)
local Types = require(script.Parent.PresentationTypes)

local Synchronization = {}
local records = {}
local nextOrdinal = 0

local terminal = {
	Completed = true,
	Cancelled = true,
	Rejected = true,
	Expired = true,
	Failed = true,
	Closed = true,
}

local function isSatisfied(policy: string, status: string, latest: any?): boolean
	if policy == Types.RenderingSynchronizationPolicy.NoWait then
		return true
	end
	if latest == nil then
		return false
	end
	if policy == Types.RenderingSynchronizationPolicy.WaitForAccepted then
		return latest.acknowledgementKind == Types.RenderingAcknowledgementKind.Accepted
	end
	if policy == Types.RenderingSynchronizationPolicy.WaitForAssigned then
		return latest.acknowledgementKind == Types.RenderingAcknowledgementKind.Assigned
	end
	if policy == Types.RenderingSynchronizationPolicy.WaitForReady then
		return latest.acknowledgementKind == Types.RenderingAcknowledgementKind.Ready
	end
	if policy == Types.RenderingSynchronizationPolicy.WaitForStarted then
		return latest.acknowledgementKind == Types.RenderingAcknowledgementKind.Started
	end
	if policy == Types.RenderingSynchronizationPolicy.WaitForCompleted then
		return status == Types.RenderingRequestStatus.Completed
	end
	if policy == Types.RenderingSynchronizationPolicy.WaitForCancelled then
		return status == Types.RenderingRequestStatus.Cancelled
	end
	return terminal[status] == true
end

function Synchronization.resolve(requestId: string)
	if #records >= Types.RenderingContractLimits.MaxSynchronizationRecords then
		return {
			ok = false,
			code = Types.RenderingContractFailureType.LimitExceeded,
			message = "synchronization record limit exceeded",
		}
	end
	local request = Requests.get(requestId)
	if request == nil then
		return {
			ok = false,
			code = Types.RenderingContractFailureType.UnknownRenderingRequest,
			message = "unknown rendering request",
		}
	end
	local latest = Acknowledgements.latestForRequest(requestId)
	nextOrdinal += 1
	local satisfied = isSatisfied(request.synchronizationPolicy, request.status, latest)
	local record = {
		renderingRequestId = request.renderingRequestId,
		executionSessionId = request.executionSessionId,
		presentationSessionId = request.presentationSessionId,
		synchronizationPolicy = request.synchronizationPolicy,
		requestStatus = request.status,
		latestAcknowledgement = latest,
		satisfied = satisfied,
		terminal = terminal[request.status] == true,
		resolutionOrdinal = nextOrdinal,
		runtimeMetadata = {},
	}
	records[#records + 1] = record
	Metrics.increment("synchronizationResolutions")
	if satisfied then
		Metrics.increment("synchronizationCompletions")
		Evidence.record("synchronization satisfied", record)
	else
		Evidence.record("synchronization resolved", record)
	end
	return { ok = true, code = "Ok", synchronization = Serialization.deepCopy(record) }
end

function Synchronization.inspect()
	return Serialization.deepCopy(records)
end

function Synchronization.clear()
	table.clear(records)
	nextOrdinal = 0
end

return Synchronization
