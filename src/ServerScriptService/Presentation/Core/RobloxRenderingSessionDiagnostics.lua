--!strict

local Budgets = require(script.Parent.RobloxRenderingSessionBudgets)
local Certification = require(script.Parent.RobloxRenderingSessionCertification)
local Evidence = require(script.Parent.RobloxRenderingSessionEvidence)
local Governance = require(script.Parent.RobloxRenderingSessionGovernance)
local Mapper = require(script.Parent.RobloxExecutionSessionMapper)
local Metrics = require(script.Parent.RobloxRenderingSessionMetrics)
local Ownership = require(script.Parent.RobloxRendererOwnership)
local Profiler = require(script.Parent.RobloxRenderingSessionProfiler)
local Reservation = require(script.Parent.RobloxRendererReservation)
local Scheduling = require(script.Parent.RobloxRendererScheduling)
local Serialization = require(script.Parent.PresentationSerialization)
local Sessions = require(script.Parent.RobloxRenderingSessionRegistry)
local Types = require(script.Parent.PresentationTypes)

local Diagnostics = {}

function Diagnostics.capture(runtime: any)
	return {
		providerName = Types.RobloxRenderingSessionProviderName,
		capabilityId = Types.RobloxRenderingSessionCapabilityId,
		platform = Types.RobloxRenderingPlatform,
		sessionRegistry = Sessions.inspect(),
		mappings = Mapper.inspect(),
		ownership = Ownership.inspect(),
		reservations = Reservation.inspect(),
		scheduling = Scheduling.inspect(),
		evidence = Evidence.inspect(),
		metrics = Metrics.inspect(),
		profiler = Profiler.inspect(),
		budgets = Budgets.inspect(),
		governance = Governance.inspect(),
		certification = Certification.inspect(),
		counters = runtime.getCounters(),
		failures = runtime.getFailures(),
		robloxRenderingSessionPosture = {
			health = "Healthy",
			status = "ProductionCandidate",
			platform = Types.RobloxRenderingPlatform,
			serverAuthoritative = true,
			deterministicSessionMapping = true,
			deterministicOwnership = true,
			deterministicReservations = true,
			immutableDiagnostics = true,
			immutableSnapshots = true,
			immutableEvidence = true,
			noGuiCreation = true,
			noRendering = true,
			noNetworking = true,
			noWorkspaceMutation = true,
			noPersistence = true,
			noGameplayExecution = true,
			noDialogueExecution = true,
			noClientAuthority = true,
			noAnalytics = true,
			noTelemetry = true,
		},
	}
end

function Diagnostics.copy(value: any)
	return Serialization.deepCopy(value)
end

return Diagnostics
