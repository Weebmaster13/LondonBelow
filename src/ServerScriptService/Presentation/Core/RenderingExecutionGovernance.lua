--!strict

local Types = require(script.Parent.PresentationTypes)

local Governance = {}

function Governance.inspect()
	return {
		systemName = "Presentation Rendering Runtime Execution and Renderer Session Management",
		owner = "Presentation",
		domain = "PresentationRendering",
		providerName = Types.RenderingExecutionProviderName,
		responsibilities = {
			"execution runtime identity",
			"renderer execution sessions",
			"execution scheduler",
			"execution queues",
			"execution lifecycle",
			"acknowledgement execution",
			"synchronization execution",
			"execution suspension, resumption, cancellation, expiration, and recovery metadata",
			"diagnostics, snapshots, evidence, metrics, profiler metadata, budgets, validation, governance, and certification posture",
		},
		nonResponsibilities = {
			"GUI creation",
			"ScreenGui instantiation",
			"TextLabel instantiation",
			"ImageLabel instantiation",
			"Frame instantiation",
			"camera manipulation",
			"animation playback",
			"sound playback",
			"asset loading",
			"localization resolution",
			"accessibility implementation",
			"networking",
			"RemoteEvents",
			"RemoteFunctions",
			"Workspace mutation",
			"save persistence",
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
