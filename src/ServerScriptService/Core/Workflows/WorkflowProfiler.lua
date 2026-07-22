--!strict

local Serialization = require(script.Parent.WorkflowSerialization)

local Profiler = {}
local profile = {
	longestWorkflow = nil :: any?,
	slowestTransition = nil :: any?,
	busiestWorkflowType = nil :: any?,
	highestRetryRate = nil :: any?,
	longestWaitState = nil :: any?,
}

function Profiler.recordWorkflow(instanceId: string, workflowId: string, duration: number)
	if profile.longestWorkflow == nil or duration > profile.longestWorkflow.duration then
		profile.longestWorkflow =
			{ instanceId = instanceId, workflowId = workflowId, duration = duration }
	end
end

function Profiler.recordTransition(instanceId: string, duration: number)
	if profile.slowestTransition == nil or duration > profile.slowestTransition.duration then
		profile.slowestTransition = { instanceId = instanceId, duration = duration }
	end
end

function Profiler.inspect()
	return Serialization.deepCopy(profile)
end

function Profiler.clear()
	profile.longestWorkflow = nil
	profile.slowestTransition = nil
	profile.busiestWorkflowType = nil
	profile.highestRetryRate = nil
	profile.longestWaitState = nil
end

return Profiler
