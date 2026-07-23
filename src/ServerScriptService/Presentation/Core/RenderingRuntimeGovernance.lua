--!strict

local Types = require(script.Parent.PresentationTypes)

local Governance = {}

function Governance.inspect()
	return {
		systemName = "Presentation Rendering Runtime Capability Foundation",
		owner = "Presentation",
		domain = "PresentationRendering",
		providerName = Types.RenderingRuntimeProviderName,
		responsibilities = {
			"runtime capability identity",
			"renderer registration metadata",
			"renderer availability metadata",
			"rendering request intake metadata",
			"rendering session registry",
			"deterministic renderer assignment metadata",
			"rendering lifecycle metadata",
			"acknowledgement production metadata",
			"synchronization metadata",
			"diagnostics, snapshots, evidence, metrics, profiler metadata, budgets, validation, governance, and certification posture",
		},
		nonResponsibilities = {
			"ScreenGui creation",
			"Frame creation",
			"TextLabel creation",
			"ImageLabel creation",
			"ViewportFrame creation",
			"BillboardGui creation",
			"SurfaceGui creation",
			"camera movement",
			"animation playback",
			"sound playback",
			"asset loading",
			"localization resolution",
			"accessibility implementation",
			"RemoteEvents",
			"RemoteFunctions",
			"Workspace mutation",
			"persistence",
			"gameplay execution",
			"dialogue execution",
			"AI execution",
			"client authority",
			"analytics",
			"telemetry",
		},
	}
end

return Governance
