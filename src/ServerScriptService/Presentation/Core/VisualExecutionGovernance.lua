--!strict

local Serialization = require(script.Parent.PresentationSerialization)
local Types = require(script.Parent.PresentationTypes)

local Governance = {}

function Governance.inspect()
	return Serialization.deepCopy({
		systemName = "Roblox Visual Composition Execution and Diff Runtime",
		providerName = Types.RobloxVisualCompositionExecutionProviderName,
		status = "ProductionCandidate",
		ownerLayer = "Presentation",
		responsibilities = {
			"diff authority",
			"patch authority",
			"operation model",
			"dependency model",
			"operation ordering",
			"revision fencing",
			"transaction metadata",
			"rollback planning",
			"supersession",
			"replay metadata",
			"recovery metadata",
			"execution diagnostics",
			"execution evidence",
		},
		doesNotOwn = {
			"GUI Instances",
			"GUI property mutation",
			"client rendering",
			"rendering transport",
			"asset loading",
			"animation",
			"audio",
			"camera",
			"input",
			"localization resolution",
			"accessibility execution",
			"networking",
			"persistence",
			"gameplay",
			"Dialogue",
			"AI",
		},
	})
end

return Governance
