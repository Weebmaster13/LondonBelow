--!strict
-- Diagnostics for Data Persistence Boundary Foundation.

local Serialization = require(script.Parent.PersistenceSerialization)
local Types = require(script.Parent.PersistenceTypes)

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
			requests = state.counts.requests .. "/" .. Types.Limits.MaxRequests,
			packages = state.counts.packages .. "/" .. Types.Limits.MaxPackages,
			migrations = state.counts.migrations .. "/" .. Types.Limits.MaxMigrations,
			policies = state.counts.policies .. "/" .. Types.Limits.MaxPolicies,
			failures = state.counts.failures .. "/" .. Types.Limits.MaxFailures,
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
			noDataStoreReads = true,
			noDataStoreWrites = true,
			noLivePersistence = true,
			noProfileLoading = true,
			noCloudSaves = true,
			noMigrationExecution = true,
			noSaveMutation = true,
			noRemotes = true,
			noClientSaveAuthority = true,
			noWorkspaceMutation = true,
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
	if state.counts.requests > Types.Limits.MaxRequests then
		return false, "request count exceeds limit"
	end
	if state.counts.packages > Types.Limits.MaxPackages then
		return false, "package count exceeds limit"
	end
	if state.counts.migrations > Types.Limits.MaxMigrations then
		return false, "migration count exceeds limit"
	end
	if state.counts.policies > Types.Limits.MaxPolicies then
		return false, "policy count exceeds limit"
	end
	if state.counts.failures > Types.Limits.MaxFailures then
		return false, "failure count exceeds limit"
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
