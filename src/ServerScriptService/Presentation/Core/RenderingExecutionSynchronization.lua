--!strict

local Acknowledgements = require(script.Parent.RenderingExecutionAcknowledgements)
local Evidence = require(script.Parent.RenderingExecutionEvidence)
local Metrics = require(script.Parent.RenderingExecutionMetrics)
local Serialization = require(script.Parent.PresentationSerialization)
local Scheduler = require(script.Parent.RenderingExecutionScheduler)
local Sessions = require(script.Parent.RenderingExecutionSessionRegistry)
local Types = require(script.Parent.PresentationTypes)

local Synchronization = {}
local records = {}
local nextOrdinal = 0

local terminal =
	{ Completed = true, Cancelled = true, Failed = true, Expired = true, Closed = true }

function Synchronization.resolve(sessionId: string)
	if #records >= Types.RenderingExecutionLimits.MaxSynchronizationRecords then
		return {
			ok = false,
			code = Types.RenderingExecutionFailureType.LimitExceeded,
			message = "synchronization limit exceeded",
		}
	end
	local session = Sessions.get(sessionId)
	if session == nil then
		return {
			ok = false,
			code = Types.RenderingExecutionFailureType.UnknownExecutionSession,
			message = "unknown execution session",
		}
	end
	local latest = Acknowledgements.latestForSession(sessionId)
	local scheduler = Scheduler.inspect()
	local satisfied = session.executionState == Types.RenderingExecutionState.Completed
		or terminal[session.executionState] == true
	nextOrdinal += 1
	local record = {
		renderingExecutionSessionId = sessionId,
		schedulerState = scheduler.state,
		executionState = session.executionState,
		latestAcknowledgement = latest,
		satisfied = satisfied,
		terminal = terminal[session.executionState] == true,
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
