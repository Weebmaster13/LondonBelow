--!strict

local PuzzleGraph = require(script.Parent.PuzzleGraph)

local PuzzleValidator = {}

function PuzzleValidator.validateDefinition(definition: any): (boolean, string?)
	if type(definition.id) ~= "string" or definition.id == "" then
		return false, "puzzle id is required"
	end
	if type(definition.displayName) ~= "string" or definition.displayName == "" then
		return false, "puzzle display name is required"
	end
	return PuzzleGraph.validate(definition)
end

function PuzzleValidator.validate(): (boolean, string?)
	return true, nil
end

return PuzzleValidator
