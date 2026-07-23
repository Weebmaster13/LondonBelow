--!strict

local Serialization = require(script.Parent.PresentationSerialization)
local Types = require(script.Parent.PresentationTypes)

local Limits = {}

function Limits.inspect()
	return Serialization.deepCopy(Types.RobloxRenderingLimits)
end

return Limits
