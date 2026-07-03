--!strict
-- Snapshot builder for immutable Asset Manifest schema state.

local State = require(script.Parent.AssetManifestState)
local Types = require(script.Parent.AssetManifestTypes)

local Snapshots = {}

function Snapshots.capture(lifecycle: any, dependencies: any)
	local state = State.inspect()
	local snapshot = {
		kind = "AssetManifestRuntimeSnapshot",
		mode = Types.Mode,
		initialized = lifecycle.initialized,
		started = lifecycle.started,
		counts = state.counts,
		schemas = {
			definitions = state.definitions,
			categories = state.categories,
			packages = state.packages,
			references = state.references,
			variants = state.variants,
			dependencies = state.dependencies,
			ownership = state.ownership,
			budgets = state.budgets,
			compatibility = state.compatibility,
			audits = state.audits,
		},
		integrityPosture = {
			assets = "records, not loaded assets",
			categories = "taxonomy only",
			packages = "manifest groups only",
			references = "symbolic or id/path records only",
			variants = "metadata only",
			dependencies = "metadata only",
			ownership = "documentation only",
			budgets = "declared constraints only",
			compatibility = "metadata only",
			audits = "review summaries only",
		},
		noLoadingPosture = {
			assetLoad = false,
			assetPreload = false,
			contentBoundaryRun = false,
			insertBoundaryRun = false,
			marketplaceBoundaryRun = false,
			animationLoad = false,
			soundLoad = false,
			modelSpawn = false,
			contentStreaming = false,
		},
		noExecutionPosture = {
			workspaceChange = false,
			replicatedStorageChange = false,
			serverStorageChange = false,
			remotes = false,
			clientAuthority = false,
			runtimeOrchestration = false,
			gameplayRun = false,
			presentationRun = false,
			saveRun = false,
			chapterContent = false,
		},
		validationFailures = state.validationFailures,
	}
	State.recordSnapshot(snapshot)
	return dependencies.Serialization.deepCopy(snapshot)
end

return Snapshots
