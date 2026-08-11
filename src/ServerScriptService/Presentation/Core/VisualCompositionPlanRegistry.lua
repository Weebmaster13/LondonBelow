--!strict

local Serialization = require(script.Parent.PresentationSerialization)
local Types = require(script.Parent.PresentationTypes)

local Plans = {}
local plans = {}
local history = {}

function Plans.commit(plan: any)
	local id = plan.compositionInstanceId
	plans[id] = Serialization.deepCopy(plan)
	history[id] = history[id] or {}
	local list = history[id]
	list[#list + 1] = Serialization.deepCopy(plan)
	while #list > Types.VisualCompositionLimits.MaxRevisionHistory do
		table.remove(list, 1)
	end
	return { ok = true, code = "Ok", plan = Serialization.deepCopy(plan) }
end

function Plans.get(compositionInstanceId: string)
	local plan = plans[compositionInstanceId]
	if plan == nil then
		return nil
	end
	return Serialization.deepCopy(plan)
end

function Plans.history(compositionInstanceId: string)
	return Serialization.deepCopy(history[compositionInstanceId] or {})
end

function Plans.inspect()
	local result = {}
	for _, plan in pairs(plans) do
		result[#result + 1] = Serialization.deepCopy(plan)
	end
	table.sort(result, function(left, right)
		return left.compositionInstanceId < right.compositionInstanceId
	end)
	return result
end

function Plans.clear()
	table.clear(plans)
	table.clear(history)
end

return Plans
