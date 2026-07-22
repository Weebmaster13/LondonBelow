--!strict

local Serialization = require(script.Parent.DomainSerialization)
local Types = require(script.Parent.DomainCapabilityTypes)

local Budgets = {}

local budget = {
	maximumDomainCapabilities = Types.Limits.MaxDomainCapabilities,
	maximumInterfacesPerDomain = Types.Limits.MaxInterfacesPerDomain,
	maximumDependenciesPerDomain = Types.Limits.MaxDependenciesPerDomain,
	maximumEvidence = Types.Limits.MaxEvidence,
	maximumDiagnostics = 420,
	maximumSnapshots = 80,
}

function Budgets.inspect()
	return Serialization.deepCopy(budget)
end

return Budgets
