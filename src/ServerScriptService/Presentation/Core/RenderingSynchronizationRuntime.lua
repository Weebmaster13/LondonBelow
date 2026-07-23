--!strict

local Acknowledgements = require(script.Parent.RenderingAcknowledgementProducer)
local Evidence = require(script.Parent.RenderingRuntimeEvidence)
local Metrics = require(script.Parent.RenderingRuntimeMetrics)
local Serialization = require(script.Parent.PresentationSerialization)
local Sessions = require(script.Parent.RenderingSessionRegistry)
local Types = require(script.Parent.PresentationTypes)

local Synchronization = {}
local records = {}
local nextOrdinal = 0

local terminal = {
	Completed = true,
	Cancelled = true,
	Expired = true,
	Failed = true,
	Rejected = true,
	Closed = true,
}

function Synchronization.resolve(sessionId: string)
	if #records >= Types.RenderingRuntimeLimits.MaxSynchronizationRecords then
		return {
			ok = false,
			code = Types.RenderingRuntimeFailureType.LimitExceeded,
			message = "synchronization limit exceeded",
		}
	end
	local session = Sessions.get(sessionId)
	if session == nil then
		return {
			ok = false,
			code = Types.RenderingRuntimeFailureType.UnknownSession,
			message = "unknown rendering session",
		}
	end
	local latest = Acknowledgements.latestForSession(sessionId)
	local satisfied = session.synchronizationPolicy == Types.RenderingSynchronizationPolicy.NoWait
		or session.lifecycleState == Types.RenderingRuntimeLifecycleState.Completed
		or terminal[session.lifecycleState] == true
	nextOrdinal += 1
	local record = {
		renderingSessionId = session.renderingSessionId,
		renderingRequestId = session.renderingRequestId,
		synchronizationPolicy = session.synchronizationPolicy,
		lifecycleState = session.lifecycleState,
		latestAcknowledgement = latest,
		satisfied = satisfied,
		terminal = terminal[session.lifecycleState] == true,
		resolutionOrdinal = nextOrdinal,
	}
	records[#records + 1] = record
	if satisfied then
		Metrics.increment("synchronizationCompletions")
	end
	Evidence.record("synchronization resolved", record)
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
