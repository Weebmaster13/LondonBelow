--!strict

local Serialization = require(script.Parent.CommandSerialization)

local PerformanceBudgets = {}

function PerformanceBudgets.inspect()
	return Serialization.deepCopy({
		validationMs = 1,
		schedulingMs = 1,
		queueAdmissionMs = 1,
		routingMs = 1,
		executionOverheadMs = 2,
		observabilityOverheadPercent = 5,
		status = "TargetsDefined",
	})
end

return PerformanceBudgets
