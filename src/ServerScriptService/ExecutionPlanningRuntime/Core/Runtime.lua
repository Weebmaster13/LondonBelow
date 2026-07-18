--!strict

local Planner = require(script.Parent.Planner)

local Runtime = {}

function Runtime.plan(input: any): any
	return Planner.plan(input)
end

return Runtime
