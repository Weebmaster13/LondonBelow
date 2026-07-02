--!strict
-- Diagnostics for Security / Anti-Exploit Boundary Runtime.

local Serialization = require(script.Parent.SecuritySerialization)
local Types = require(script.Parent.SecurityTypes)

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
			trustPolicies = state.counts.trustPolicies .. "/" .. Types.Limits.MaxTrustPolicies,
			authorityRules = state.counts.authorityRules .. "/" .. Types.Limits.MaxAuthorityRules,
			exploitSignals = state.counts.exploitSignals .. "/" .. Types.Limits.MaxExploitSignals,
			clientRejections = state.counts.clientRejections
				.. "/"
				.. Types.Limits.MaxClientRejections,
			remoteSafetyContracts = state.counts.remoteSafetyContracts
				.. "/"
				.. Types.Limits.MaxRemoteSafetyContracts,
			rateLimits = state.counts.rateLimits .. "/" .. Types.Limits.MaxRateLimits,
			audits = state.counts.audits .. "/" .. Types.Limits.MaxAudits,
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
		diagnosticsIsolationProof = {
			diagnosticsAreDeepCopies = true,
			rawUnsafePayloadsAreSanitized = true,
			containsNoServiceReferences = true,
			containsNoRemoteInstances = true,
			containsNoLivePlayerData = true,
		},
		noExecutionPosture = {
			noLiveAntiCheat = true,
			noExploitDetectionExecution = true,
			noBanEnforcement = true,
			noKickEnforcement = true,
			noModeration = true,
			noPunishment = true,
			noClientMonitoring = true,
			noRemoteCreation = true,
			noRemoteSignalHandling = true,
			noRemoteRequestHandling = true,
			noDataStoreReads = true,
			noDataStoreWrites = true,
			noAnalyticsCollection = true,
			noTelemetrySending = true,
			noPlayerTracking = true,
			noWorldMutation = true,
			noGameplayExecution = true,
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
	if state.counts.trustPolicies > Types.Limits.MaxTrustPolicies then
		return false, "trust policy count exceeds limit"
	end
	if state.counts.authorityRules > Types.Limits.MaxAuthorityRules then
		return false, "authority rule count exceeds limit"
	end
	if state.counts.exploitSignals > Types.Limits.MaxExploitSignals then
		return false, "exploit signal count exceeds limit"
	end
	if state.counts.clientRejections > Types.Limits.MaxClientRejections then
		return false, "client rejection count exceeds limit"
	end
	if state.counts.remoteSafetyContracts > Types.Limits.MaxRemoteSafetyContracts then
		return false, "remote safety contract count exceeds limit"
	end
	if state.counts.rateLimits > Types.Limits.MaxRateLimits then
		return false, "rate limit policy count exceeds limit"
	end
	if state.counts.audits > Types.Limits.MaxAudits then
		return false, "audit count exceeds limit"
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
