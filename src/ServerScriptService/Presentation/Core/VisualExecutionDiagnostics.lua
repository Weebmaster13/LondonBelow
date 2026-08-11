--!strict

local Runtime = require(script.Parent.RuntimeRobloxVisualCompositionExecution)
local Serialization = require(script.Parent.PresentationSerialization)

local Diagnostics = {}

function Diagnostics.capture()
	return Runtime.inspect()
end

function Diagnostics.copy(value: any)
	return Serialization.deepCopy(value)
end

return Diagnostics
