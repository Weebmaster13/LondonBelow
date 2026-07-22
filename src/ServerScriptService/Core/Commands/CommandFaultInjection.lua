--!strict

local Serialization = require(script.Parent.CommandSerialization)

local FaultInjection = {}

local scenarios = {
	"handler panic",
	"queue overflow",
	"lock acquisition failure",
	"malformed handler result",
	"transaction rollback",
	"instrumentation failure",
	"recovery interruption",
}

function FaultInjection.inspect()
	return Serialization.deepCopy({
		status = "DefinedIsolated",
		productionExecutionEnabled = false,
		expectedOutcome = "normalized deterministic runtime failure",
		scenarios = scenarios,
	})
end

return FaultInjection
