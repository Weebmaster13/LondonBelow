--!strict

local Authorization = require(script.Parent.Authorization)

local Runtime = {}

function Runtime.authorize(input: any): any
	return Authorization.evaluate(input)
end

return Runtime
