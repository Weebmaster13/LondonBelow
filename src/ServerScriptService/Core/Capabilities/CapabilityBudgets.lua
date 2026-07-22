--!strict

local Serialization = require(script.Parent.CapabilitySerialization)
local Types = require(script.Parent.CapabilityTypes)

local Budgets = {}

local budget = {
	maximumCapabilities = Types.Limits.MaxCapabilities,
	maximumInterfaces = Types.Limits.MaxInterfacesPerCapability,
	maximumDependencies = Types.Limits.MaxDependenciesPerCapability,
	maximumDiagnostics = Types.Limits.MaxDiagnostics,
	maximumSnapshots = Types.Limits.MaxSnapshots,
	registrationMs = 2,
	initializationMs = 5,
	discoveryMs = 1,
	diagnosticsOverheadPercent = 5,
}

function Budgets.inspect()
	return Serialization.deepCopy(budget)
end

return Budgets
