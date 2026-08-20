--!strict

local FailureInjection = {}
local allowed = table.freeze({
	ImmediateApply = true,
	TweenCreate = true,
	TweenPlay = true,
	Restore = true,
	Cancel = true,
	Disconnect = true,
})
local remaining = {}

function FailureInjection.setForTest(stage: any, count: any): (boolean, string?)
	if type(stage) ~= "string" or not allowed[stage] then
		return false, "InvalidFailureInjectionStage"
	end
	if type(count) ~= "number" or count % 1 ~= 0 or count < 0 or count > 32 then
		return false, "InvalidFailureInjectionCount"
	end
	remaining[stage] = count
	return true
end

function FailureInjection.consume(stage: string): boolean
	local count = remaining[stage] or 0
	if count <= 0 then
		return false
	end
	remaining[stage] = count - 1
	return true
end

function FailureInjection.reset()
	remaining = {}
end

function FailureInjection.snapshot()
	local result = {}
	for stage, count in pairs(remaining) do
		if count > 0 then
			result[stage] = count
		end
	end
	return table.freeze(result)
end

return FailureInjection
