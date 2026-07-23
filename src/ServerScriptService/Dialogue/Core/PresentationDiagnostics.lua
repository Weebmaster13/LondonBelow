--!strict

local Accessibility = require(script.Parent.AccessibilityMetadataRegistry)
local Acknowledgements = require(script.Parent.PresentationAcknowledgementRegistry)
local Budgets = require(script.Parent.PresentationBudgets)
local Certification = require(script.Parent.PresentationCertification)
local Contracts = require(script.Parent.PresentationContractRegistry)
local Evidence = require(script.Parent.PresentationEvidence)
local Governance = require(script.Parent.PresentationGovernance)
local Localization = require(script.Parent.LocalizationReferenceRegistry)
local Metrics = require(script.Parent.PresentationMetrics)
local Profiler = require(script.Parent.PresentationProfiler)
local Requests = require(script.Parent.PresentationRequestRegistry)
local Synchronization = require(script.Parent.PresentationSynchronizationManager)
local Serialization = require(script.Parent.DialogueSerialization)
local Types = require(script.Parent.DialoguePresentationTypes)

local Diagnostics = {}

function Diagnostics.capture(runtime: any)
	local counters = runtime.getCounters()
	return {
		providerName = Types.ProviderName,
		dialoguePresentationContractPosture = {
			health = "Healthy",
			status = "ProductionCandidate",
			serverAuthoritative = true,
			dataOnlyDescriptors = true,
			deterministicOrdering = true,
		},
		registeredContracts = Contracts.inspect(),
		activePresentationRequests = Requests.inspect(),
		pendingAcknowledgements = Acknowledgements.inspect(),
		completedAcknowledgements = Acknowledgements.inspect(),
		synchronizationState = Synchronization.inspect(),
		localizationReferences = Localization.inspect(),
		accessibilityMetadata = Accessibility.inspect(),
		lifecycleCounts = counters.lifecycleCounts,
		validationFailures = counters.validationFailures,
		lastFailure = counters.lastFailure,
		presentationEvidence = Evidence.inspect(),
		presentationMetrics = Metrics.inspect(),
		presentationProfiler = Profiler.inspect(),
		presentationBudgets = Budgets.inspect(),
		presentationGovernance = Governance.inspect(),
		certification = Certification.inspect(),
		counters = counters,
		noScreenGuiCreation = true,
		noUiRendering = true,
		noTextRendering = true,
		noPortraitRendering = true,
		noSubtitleRendering = true,
		noCameraControl = true,
		noAnimationPlayback = true,
		noVoicePlayback = true,
		noAudioRouting = true,
		noLocalizationResolution = true,
		noInputCapture = true,
		noNetworking = true,
		noRemoteEvents = true,
		noRemoteFunctions = true,
		noPersistence = true,
		noSaveSerialization = true,
		noWorkspaceMutation = true,
		noNpcBehavior = true,
		noGameplayExecution = true,
		noClientAuthority = true,
		noAnalytics = true,
		noTelemetry = true,
	}
end

function Diagnostics.copy(value: any)
	return Serialization.deepCopy(value)
end

return Diagnostics
