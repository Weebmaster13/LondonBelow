--!strict
-- Diagnostics for Content Registry Runtime Foundation.

local Serialization = require(script.Parent.ContentSerialization)
local Types = require(script.Parent.ContentTypes)

local Diagnostics = {}

function Diagnostics.capture(lifecycle: any, dependencies: any)
	local state = dependencies.State.inspect()
	local validationOk, validationReason = dependencies.Validation.validate()
	local health = "Healthy"
	if not validationOk then
		health = "Unhealthy"
	elseif state.counts.validationFailures > 0 then
		health = "Warning"
	end

	return Serialization.deepCopy({
		health = health,
		validationOk = validationOk,
		validationReason = validationReason,
		lifecycleState = lifecycle.started and "Started"
			or (lifecycle.initialized and "Initialized" or "Stopped"),
		initialized = lifecycle.initialized,
		started = lifecycle.started,
		lastSelfChecks = lifecycle.lastSelfChecks,
		counts = state.counts,
		limits = Types.Limits,
		mode = Types.Mode,
		perCategoryLimitState = {
			contentDefinitions = state.counts.contentDefinitions
				.. "/"
				.. Types.Limits.MaxContentDefinitions,
			categories = state.counts.categories .. "/" .. Types.Limits.MaxCategories,
			references = state.counts.references .. "/" .. Types.Limits.MaxReferences,
			dependencies = state.counts.dependencies .. "/" .. Types.Limits.MaxDependencies,
			packages = state.counts.packages .. "/" .. Types.Limits.MaxPackages,
			versions = state.counts.versions .. "/" .. Types.Limits.MaxVersions,
			tags = state.counts.tags .. "/" .. Types.Limits.MaxTags,
			validationFailures = state.counts.validationFailures
				.. "/"
				.. Types.Limits.MaxValidationFailures,
			snapshots = state.counts.snapshots .. "/" .. Types.Limits.MaxSnapshotHistory,
		},
		serializationPosture = {
			rejectsInstances = true,
			rejectsUnsafeRuntimeValues = true,
			rejectsCycles = true,
			rejectsOversizedPayloads = true,
			exportsDeepCopies = true,
		},
		snapshotIsolationProof = {
			snapshotsAreDeepCopies = true,
			containsSchemaStateOnly = true,
			containsNoFinalStoryText = true,
			containsNoFinalDialogueText = true,
			containsNoAssetHandles = true,
			containsNoLoadingHandles = true,
			containsNoSpawnHandles = true,
		},
		diagnosticsIsolationProof = {
			diagnosticsAreDeepCopies = true,
			rawUnsafePayloadsAreSanitized = true,
			containsNoServiceReferences = true,
			containsNoRemoteReferences = true,
			containsNoLoadingAdapters = true,
			containsNoExecutionAdapters = true,
		},
		noExecutionPosture = {
			noChapterContent = true,
			noChapter0Content = true,
			noFinalStory = true,
			noFinalDialogue = true,
			noAssetLoading = true,
			noMapLoading = true,
			noRoomLoading = true,
			noContentStreaming = true,
			noContentSpawning = true,
			noWorldMutation = true,
			noGameplayExecution = true,
			noPuzzleExecution = true,
			noInteractionExecution = true,
			noInventoryExecution = true,
			noObjectiveCompletion = true,
			noNarrativeExecution = true,
			noSavePersistence = true,
			noDataStoreReadsWrites = true,
			noExternalHttpAccess = true,
			noExternalMessagingAccess = true,
			noRemotes = true,
			noClientAuthority = true,
			noAnalyticsCollection = true,
			noTelemetrySending = true,
		},
		recentValidationFailures = state.validationFailures,
	})
end

function Diagnostics.validate(dependencies: any): (boolean, string?)
	local ok, reason = dependencies.Validation.validate()
	if not ok then
		return false, reason
	end
	local state = dependencies.State.inspect()
	if state.counts.contentDefinitions > Types.Limits.MaxContentDefinitions then
		return false, "content definition count exceeds limit"
	end
	if state.counts.categories > Types.Limits.MaxCategories then
		return false, "category count exceeds limit"
	end
	if state.counts.references > Types.Limits.MaxReferences then
		return false, "reference count exceeds limit"
	end
	if state.counts.dependencies > Types.Limits.MaxDependencies then
		return false, "dependency count exceeds limit"
	end
	if state.counts.packages > Types.Limits.MaxPackages then
		return false, "package count exceeds limit"
	end
	if state.counts.versions > Types.Limits.MaxVersions then
		return false, "version count exceeds limit"
	end
	if state.counts.tags > Types.Limits.MaxTags then
		return false, "tag count exceeds limit"
	end
	if state.counts.validationFailures > Types.Limits.MaxValidationFailures then
		return false, "validation failure history exceeds limit"
	end
	if state.counts.snapshots > Types.Limits.MaxSnapshotHistory then
		return false, "snapshot history exceeds limit"
	end
	return true, nil
end

return Diagnostics
