--!strict

local Scheduler = require(script.Parent.RenderingExecutionScheduler)
local Sessions = require(script.Parent.RenderingExecutionSessionRegistry)
local Types = require(script.Parent.PresentationTypes)

local Validation = {}

function Validation.validate(): (boolean, string?)
	local scheduler = Scheduler.inspect()
	if not Types.isRenderingExecutionSchedulerState(scheduler.state) then
		return false, "invalid scheduler state"
	end
	for _, session in ipairs(Sessions.inspect()) do
		if not Types.isRenderingExecutionState(session.executionState) then
			return false, "invalid execution state"
		end
		if type(session.rendererId) ~= "string" or session.rendererId == "" then
			return false, "execution session missing renderer ownership"
		end
	end
	return true, nil
end

return Validation
