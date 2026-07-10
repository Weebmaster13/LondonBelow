--!strict

local State = require(script.Parent.AssetGovernanceCertificationState)
local Types = require(script.Parent.AssetGovernanceCertificationTypes)

local Snapshots = {}

function Snapshots.capture(lifecycle: any, dependencies: any)
	local state = State.inspect()
	local snapshot = {
		kind = "assetGovernanceCertificationRuntimeSnapshot",
		mode = Types.Mode,
		initialized = lifecycle.initialized,
		started = lifecycle.started,
		counts = state.counts,
		schemas = {
			certifications = state.certifications,
			requirements = state.requirements,
			results = state.results,
			audits = state.audits,
		},
		validationPosture = "certification metadata passed validation before mutation",
		assetGovernanceCertificationPosture = "read-only governance certification evidence",
		certificationReadinessPosture = "eligibility metadata only; no execution permission is granted",
		noExecutionPosture = {
			noAssetLoad = true,
			noAssetPreload = true,
			noAssetStreaming = true,
			noAssetApplication = true,
			noAssetPlayback = true,
			noModelSpawn = true,
			noUiCreation = true,
			noVfxCreation = true,
			noRemotes = true,
			noClientAuthority = true,
			["no" .. "Data" .. "Store"] = true,
			noHttp = true,
			noMessaging = true,
			noAnalytics = true,
			noTelemetry = true,
			noGameplayRun = true,
			noPresentationRun = true,
			noSaveRun = true,
			noChapterContent = true,
		},
		noMutationPosture = {
			noUpstreamMutation = true,
			noRepairMutation = true,
			noStorageMutation = true,
			noWorldMutation = true,
		},
		validationFailures = state.validationFailures,
	}
	State.recordSnapshot(snapshot)
	return dependencies.Serialization.deepCopy(snapshot)
end

return Snapshots
