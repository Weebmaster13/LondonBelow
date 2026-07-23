--!strict

local Evidence = require(script.Parent.PresentationExecutionEvidence)
local Scheduler = require(script.Parent.PresentationExecutionScheduler)

local Recovery = {}

function Recovery.recover()
	Scheduler.recover()
	Evidence.record("execution recovery completed", {})
	return { ok = true, code = "Ok" }
end

return Recovery
