--!strict

local Serialization = require(script.Parent.CommandSerialization)

local Migration = {}

function Migration.inspect()
	return Serialization.deepCopy({
		status = "MetadataDefined",
		ownedMetadata = {
			"replay metadata",
			"command definitions",
			"diagnostics",
			"snapshots",
			"evidence",
			"transaction metadata",
		},
		invariant = "migrations preserve constitutional ownership and validation",
	})
end

return Migration
