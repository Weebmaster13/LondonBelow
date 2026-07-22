--!strict

local Serialization = require(script.Parent.DomainSerialization)

local Governance = {}

local posture = {
	ownerLayer = "Core",
	contract = "Runtime Domain Capability Foundation",
	owns = {
		"domain capability contracts",
		"domain identity",
		"domain authority model",
		"service contracts",
		"interface ownership",
		"communication contracts",
	},
	doesNotOwn = {
		"gameplay rules",
		"concrete domain implementation",
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
