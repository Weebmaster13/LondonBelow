--!strict
local Coordinator = require(script.Parent.RuleEngineCoordinator)
return { register = Coordinator.registerRuleDefinition }
