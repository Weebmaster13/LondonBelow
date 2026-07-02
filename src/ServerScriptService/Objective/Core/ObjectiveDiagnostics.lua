--!strict
-- Diagnostics for Objective Runtime Foundation.

local Serialization = require(script.Parent.ObjectiveSerialization)
local Types = require(script.Parent.ObjectiveTypes)

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
			objectives = state.counts.objectives .. "/" .. Types.Limits.MaxObjectives,
			tasks = state.counts.tasks .. "/" .. Types.Limits.MaxTasks,
			requirements = state.counts.requirements .. "/" .. Types.Limits.MaxRequirements,
			dependencies = state.counts.dependencies .. "/" .. Types.Limits.MaxDependencies,
			progressRecords = state.counts.progressRecords
				.. "/"
				.. Types.Limits.MaxProgressRecords,
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
			diagnosticsAreDeepCopies = true,
			unsafeRuntimeValuesAreSanitized = true,
		},
		noExecutionPosture = {
			noObjectiveCompletionExecution = true,
			noQuestExecution = true,
			noGameplayExecution = true,
			noUi = true,
			noWorkspaceMutation = true,
			noRemotes = true,
			noClientAuthority = true,
			noSavePersistence = true,
			noNarrativeOwnership = true,
			noHorrorPacingOwnership = true,
			noChapterContent = true,
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
	if state.counts.objectives > Types.Limits.MaxObjectives then
		return false, "objective count exceeds limit"
	end
	if state.counts.progressRecords > Types.Limits.MaxProgressRecords then
		return false, "progress record count exceeds limit"
	end
	return true, nil
end

return Diagnostics
