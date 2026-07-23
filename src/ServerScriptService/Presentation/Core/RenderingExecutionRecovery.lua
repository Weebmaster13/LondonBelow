--!strict

local Evidence = require(script.Parent.RenderingExecutionEvidence)
local Scheduler = require(script.Parent.RenderingExecutionScheduler)

local Recovery = {}

function Recovery.recover()
	local result = Scheduler.recover()
	Evidence.record("execution recovery metadata captured", result)
	return result
end

return Recovery
