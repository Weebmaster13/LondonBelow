--!strict

local Serialization = require(script.Parent.DialogueSerialization)
local Types = require(script.Parent.DialoguePresentationTypes)

local Budgets = {}

function Budgets.inspect()
	return Serialization.deepCopy(Types.Limits)
end

return Budgets
