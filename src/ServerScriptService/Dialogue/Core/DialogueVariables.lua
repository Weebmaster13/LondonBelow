--!strict

local Serialization = require(script.Parent.DialogueSerialization)

local Variables = {}

function Variables.defaultVariables(definition: any)
	local values = {}
	for _, variable in ipairs(definition.variables or {}) do
		values[variable.variableId] = Serialization.deepCopy(variable.defaultValue)
	end
	return values
end

function Variables.inspectDefinition(definition: any)
	return Serialization.deepCopy(definition.variables or {})
end

return Variables
