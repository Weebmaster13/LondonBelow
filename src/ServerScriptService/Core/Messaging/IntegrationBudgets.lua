--!strict

local Serialization = require(script.Parent.MessagingSerialization)
local Types = require(script.Parent.MessagingTypes)

local Budgets = {}

local resourceBudgets = {
	maxConsumers = Types.Limits.MaxConsumers,
	maxDependenciesPerConsumer = Types.Limits.MaxDependenciesPerConsumer,
	maxSubscriptions = Types.Limits.MaxSubscriptions,
	maxInterfacesPerConsumer = Types.Limits.MaxInterfacesPerConsumer,
}

local performanceBudgets = {
	initializationMsPerConsumer = 10,
	shutdownMsPerConsumer = 10,
	dependencyValidationMs = 2,
	subscriptionResolutionMs = 2,
	observabilityOverheadPercent = 5,
}

function Budgets.inspect()
	return {
		resourceBudgets = Serialization.deepCopy(resourceBudgets),
		performanceBudgets = Serialization.deepCopy(performanceBudgets),
	}
end

return Budgets
