--!strict
-- Diagnostics for Data Persistence Boundary Foundation.

local Serialization = require(script.Parent.PersistenceSerialization)
local Types = require(script.Parent.PersistenceTypes)

local Diagnostics = {}

function Diagnostics.capture(lifecycle: any, dependencies: any)
	local state = dependencies.State.inspect()
	local runtimeState = dependencies.Runtime.inspect()
	local validationOk, validationReason = dependencies.Validation.validate()
	local health = "Healthy"
	if not validationOk then
		health = "Unhealthy"
	elseif state.counts.validationFailures > 0 then
		health = "Warning"
	end
	local requestPipeline = runtimeState.requestPipeline
	local registry = runtimeState.registry
	local retryRuntime = runtimeState.retryRuntime

	return Serialization.deepCopy({
		health = health,
		persistenceRuntimePosture = health,
		validationOk = validationOk,
		validationReason = validationReason,
		lifecycleState = lifecycle.started and "Started"
			or (lifecycle.initialized and "Initialized" or "Stopped"),
		initialized = lifecycle.initialized,
		started = lifecycle.started,
		lastSelfChecks = lifecycle.lastSelfChecks,
		counts = state.counts,
		registeredProviders = registry.registeredProviders,
		activeProvider = registry.defaultProvider,
		saveRequests = requestPipeline.lastRequest ~= nil
				and requestPipeline.lastRequest.operation == Types.Operation.Save
				and requestPipeline.requests
			or 0,
		loadRequests = requestPipeline.lastRequest ~= nil
				and requestPipeline.lastRequest.operation == Types.Operation.Load
				and requestPipeline.requests
			or 0,
		deleteRequests = requestPipeline.lastRequest ~= nil
				and requestPipeline.lastRequest.operation == Types.Operation.Delete
				and requestPipeline.requests
			or 0,
		retryCount = retryRuntime.retryCount,
		failureCount = requestPipeline.failures,
		persistenceRuntime = runtimeState,
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
			providers = registry.count .. "/" .. Types.Limits.MaxProviders,
			requestHistory = requestPipeline.requests .. "/" .. Types.Limits.MaxRequestHistory,
			adapterFailures = requestPipeline.failures .. "/" .. Types.Limits.MaxFailures,
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
			noGameplayAuthority = true,
			noSchemaOwnership = true,
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
	local runtimeState = dependencies.Runtime.inspect()
	if runtimeState.registry.count > Types.Limits.MaxProviders then
		return false, "provider count exceeds limit"
	end
	if runtimeState.requestPipeline.requests > Types.Limits.MaxRequestHistory then
		return false, "request history exceeds limit"
	end
	return true, nil
end

return Diagnostics
