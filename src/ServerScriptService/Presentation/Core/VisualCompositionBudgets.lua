--!strict

local Serialization = require(script.Parent.PresentationSerialization)
local Types = require(script.Parent.PresentationTypes)

local Budgets = {}

function Budgets.inspect()
	return Serialization.deepCopy(Types.VisualCompositionLimits)
end

return Budgets
