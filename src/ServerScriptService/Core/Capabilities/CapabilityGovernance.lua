--!strict

local Serialization = require(script.Parent.CapabilitySerialization)

local Governance = {}

local posture = {
	ownerLayer = "Core",
	contract = "Runtime Capability Framework",
	owns = {
		"capability registration",
		"capability discovery",
		"capability lifecycle",
		"capability dependency validation",
		"capability health metadata",
	},
	doesNotOwn = {
		"gameplay execution",
		"command execution",
		"event publication",
		"query execution",
		"networking",
		"client authority",
	},
}

function Governance.inspect()
	return Serialization.deepCopy(posture)
end

return Governance
