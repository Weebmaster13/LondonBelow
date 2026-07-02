--!strict
-- Puzzle dependency schema validation helpers.

local Validation = require(script.Parent.PuzzleValidation)

local Dependencies = {}

function Dependencies.validate(dependencies: any): (boolean, string?)
	return Validation.dependencies(dependencies)
end

return Dependencies
