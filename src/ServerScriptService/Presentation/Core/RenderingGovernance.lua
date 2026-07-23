--!strict

local Types = require(script.Parent.PresentationTypes)

local Governance = {}

function Governance.inspect()
	return {
		systemName = "Presentation Rendering Contract Foundation",
		owner = "Presentation",
		domain = "PresentationRendering",
		providerName = Types.RenderingContractProviderName,
		responsibilities = {
			"rendering contract registration",
			"rendering request construction",
			"data-only descriptor validation",
			"renderer capability declarations",
			"renderer compatibility metadata",
			"rendering acknowledgement records",
			"rendering synchronization metadata",
			"localization, accessibility, and asset reference preservation",
			"diagnostics, snapshots, evidence, metrics, profiler metadata, budgets, validation, governance, and certification posture",
		},
		nonResponsibilities = {
			"ScreenGui creation",
			"PlayerGui mutation",
			"CoreGui mutation",
			"TextLabel creation",
			"ImageLabel creation",
			"Frame creation",
			"camera control",
			"animation playback",
			"audio playback",
			"subtitle rendering",
			"localization resolution",
			"accessibility implementation",
			"asset loading",
			"networking",
			"RemoteEvents",
			"RemoteFunctions",
			"Workspace mutation",
			"persistence",
			"gameplay execution",
			"dialogue execution",
			"AI execution",
			"analytics",
			"telemetry",
			"client authority",
		},
	}
end

return Governance
