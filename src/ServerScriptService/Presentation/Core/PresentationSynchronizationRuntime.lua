--!strict

local Acknowledgements = require(script.Parent.PresentationAcknowledgementProducer)
local Evidence = require(script.Parent.PresentationEvidence)
local Metrics = require(script.Parent.PresentationMetrics)
local Serialization = require(script.Parent.PresentationSerialization)
local Sessions = require(script.Parent.PresentationSessionRegistry)
local Types = require(script.Parent.PresentationTypes)

local Runtime = {}
local records = {}

local terminal = {
	[Types.RuntimeSessionState.Completed] = true,
	[Types.RuntimeSessionState.Cancelled] = true,
	[Types.RuntimeSessionState.Expired] = true,
	[Types.RuntimeSessionState.Failed] = true,
	[Types.RuntimeSessionState.Closed] = true,
}

function Runtime.resolve(sessionId: string)
	local session = Sessions.get(sessionId)
	if session == nil then
		return {
			ok = false,
			code = Types.RuntimeFailureType.UnknownSession,
			message = "unknown session",
		}
	end
	local latest = Acknowledgements.latestForSession(sessionId)
	local satisfied = terminal[session.lifecycleState] == true
		or session.lifecycleState == Types.RuntimeSessionState.Acknowledged
	local record = {
		presentationSessionId = sessionId,
		presentationId = session.presentationId,
		executionId = session.executionId,
		lifecycleState = session.lifecycleState,
		latestAcknowledgement = latest,
		satisfied = satisfied,
	}
	records[#records + 1] = Serialization.deepCopy(record)
	if #records > Types.Limits.MaxRuntimeSynchronizationRecords then
		table.remove(records, 1)
	end
	if satisfied then
		Metrics.increment("synchronizationCompletions")
		Evidence.record("PresentationSynchronizationCompleted", record, Types.Limits.MaxEvidence)
	end
	return { ok = true, code = "Ok", synchronization = record }
end

function Runtime.inspect()
	return Serialization.deepCopy(records)
end

function Runtime.clear()
	table.clear(records)
end

return Runtime
