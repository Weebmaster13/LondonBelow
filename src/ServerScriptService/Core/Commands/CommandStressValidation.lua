--!strict

local Serialization = require(script.Parent.CommandSerialization)

local StressValidation = {}

local tiers = {
	{ commandCount = 10, status = "Defined" },
	{ commandCount = 100, status = "Defined" },
	{ commandCount = 1000, status = "Defined" },
	{ commandCount = 10000, status = "Defined" },
	{ commandCount = 100000, status = "Defined" },
}

function StressValidation.inspect()
	return Serialization.deepCopy({
		status = "DefinedNotExecuted",
		tiers = tiers,
		scenarios = {
			"maximum queue occupancy",
			"continuous retries",
			"lock contention",
			"transaction bursts",
			"replay sessions",
			"nested command trees",
		},
	})
end

return StressValidation
