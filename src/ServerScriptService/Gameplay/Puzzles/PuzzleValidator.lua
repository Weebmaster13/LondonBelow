--!strict

local PuzzleGraph = require(script.Parent.PuzzleGraph)
local Config = require(script.Parent.Parent.Core.GameplayConfig)

local PuzzleValidator = {}

function PuzzleValidator.validateDefinition(definition: any): (boolean, string?)
	if type(definition.id) ~= "string" or definition.id == "" then
		return false, "puzzle id is required"
	end
	if type(definition.displayName) ~= "string" or definition.displayName == "" then
		return false, "puzzle display name is required"
	end
	if type(definition.hints) ~= "table" then
		return false, "puzzle hints must be a table"
	end
	if type(definition.nodes) ~= "table" then
		return false, "puzzle nodes must be a table"
	end
	if #definition.nodes > Config.MaxPuzzleNodes then
		return false, "puzzle exceeds node limit"
	end
	return PuzzleGraph.validate(definition)
end

function PuzzleValidator.validate(): (boolean, string?)
	return true, nil
end

return PuzzleValidator
