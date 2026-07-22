--!strict

local Serialization = require(script.Parent.CommandSerialization)

local Compatibility = {}

function Compatibility.inspect()
	return Serialization.deepCopy({
		status = "Supported",
		schemaVersioning = "required",
		breakingChanges = "explicit versioned migration required",
		deprecationLifecycle = { "Supported", "Deprecated", "Legacy", "Removed" },
		compatibilityGuarantee = "existing command definitions remain compatible unless explicitly versioned",
	})
end

return Compatibility
