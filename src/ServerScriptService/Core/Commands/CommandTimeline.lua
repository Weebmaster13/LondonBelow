--!strict

local Serialization = require(script.Parent.CommandSerialization)
local Types = require(script.Parent.CommandTypes)

local Timeline = {}
local timelines: { [string]: any } = {}
local instrumentationFaults: { any } = {}

local function trimArray(values: { any }, limit: number)
	while #values > limit do
		table.remove(values, 1)
	end
end

function Timeline.record(command: any, state: string, stage: string?)
	local commandId = command.commandId
	if type(commandId) ~= "string" then
		table.insert(
			instrumentationFaults,
			{ stage = stage or state, reason = "missing command id" }
		)
		trimArray(instrumentationFaults, Types.Limits.MaxObservabilityEvents)
		return
	end
	local now = os.clock()
	local timeline = timelines[commandId]
	if timeline == nil then
		timeline = {
			commandId = commandId,
			commandType = command.commandType,
			correlationId = command.correlationId,
			causationId = command.causationId,
			ownerRuntime = command.ownerRuntime,
			events = {},
			stageDurations = {},
		}
		timelines[commandId] = timeline
	end
	local previous = timeline.events[#timeline.events]
	table.insert(timeline.events, {
		timestamp = now,
		previousState = if previous ~= nil then previous.newState else nil,
		newState = state,
		stage = stage or state,
		executionSequence = command.sequence,
		ownerRuntime = command.ownerRuntime,
	})
	if previous ~= nil then
		local duration = math.max(0, now - previous.timestamp)
		timeline.stageDurations[previous.stage] = (timeline.stageDurations[previous.stage] or 0)
			+ duration
	end
	trimArray(timeline.events, Types.Limits.MaxTimelineEventsPerCommand)
end

function Timeline.inspect()
	return Serialization.deepCopy({
		timelines = timelines,
		instrumentationFaults = instrumentationFaults,
	})
end

function Timeline.clear()
	table.clear(timelines)
	table.clear(instrumentationFaults)
end

return Timeline
