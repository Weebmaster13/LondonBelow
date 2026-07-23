--!strict

local Acknowledgements = require(script.Parent.RendererAcknowledgementRegistry)
local AssetReferences = require(script.Parent.RenderingAssetReferenceRegistry)
local AccessibilityReferences = require(script.Parent.RenderingAccessibilityReferenceRegistry)
local Budgets = require(script.Parent.RenderingBudgets)
local Certification = require(script.Parent.RenderingCertification)
local Contracts = require(script.Parent.RenderingContractRegistry)
local Evidence = require(script.Parent.RenderingEvidence)
local Governance = require(script.Parent.RenderingGovernance)
local LocalizationReferences = require(script.Parent.RenderingLocalizationReferenceRegistry)
local Metrics = require(script.Parent.RenderingMetrics)
local Profiler = require(script.Parent.RenderingProfiler)
local RendererCapabilities = require(script.Parent.RendererCapabilityRegistry)
local Requests = require(script.Parent.RenderingRequestRegistry)
local Serialization = require(script.Parent.PresentationSerialization)
local Synchronization = require(script.Parent.RenderingSynchronizationManager)
local Types = require(script.Parent.PresentationTypes)

local Diagnostics = {}

function Diagnostics.capture(runtime: any)
	return {
		providerName = Types.RenderingContractProviderName,
		contractId = Types.RenderingContractId,
		contracts = Contracts.inspect(),
		rendererCapabilities = RendererCapabilities.inspect(),
		renderingRequests = Requests.inspect(),
		acknowledgements = Acknowledgements.inspect(),
		synchronizationRecords = Synchronization.inspect(),
		localizationReferences = LocalizationReferences.inspect(),
		accessibilityReferences = AccessibilityReferences.inspect(),
		assetReferences = AssetReferences.inspect(),
		evidence = Evidence.inspect(),
		metrics = Metrics.inspect(),
		profiler = Profiler.inspect(),
		budgets = Budgets.inspect(),
		governance = Governance.inspect(),
		certification = Certification.inspect(),
		counters = runtime.getCounters(),
		failures = runtime.getFailures(),
		renderingContractPosture = {
			health = "Healthy",
			status = "ProductionCandidate",
			serverAuthoritative = true,
			dataOnly = true,
			immutableRequests = true,
			immutableAcknowledgements = true,
			deterministicRequestOrdering = true,
			deterministicAcknowledgementOrdering = true,
			deterministicSynchronization = true,
			noRendering = true,
			noGui = true,
			noPlayerGuiMutation = true,
			noCoreGuiMutation = true,
			noCameraControl = true,
			noAnimationPlayback = true,
			noAudioPlayback = true,
			noAssetLoading = true,
			noLocalizationResolution = true,
			noAccessibilityImplementation = true,
			noNetworking = true,
			noRemoteEvents = true,
			noRemoteFunctions = true,
			noPersistence = true,
			noWorkspaceMutation = true,
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
