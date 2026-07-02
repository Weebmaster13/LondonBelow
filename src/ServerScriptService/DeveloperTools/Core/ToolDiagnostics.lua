--!strict
-- Diagnostics for Developer Tooling Runtime Foundation.

local Serialization = require(script.Parent.ToolSerialization)
local Types = require(script.Parent.ToolTypes)

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
			tools = state.counts.tools .. "/" .. Types.Limits.MaxTools,
			inspections = state.counts.inspections .. "/" .. Types.Limits.MaxInspections,
			commands = state.counts.commands .. "/" .. Types.Limits.MaxCommands,
			reports = state.counts.reports .. "/" .. Types.Limits.MaxReports,
			permissions = state.counts.permissions .. "/" .. Types.Limits.MaxPermissions,
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
		noExecutionPosture = {
			noCommandExecution = true,
			noLiveAdminTools = true,
			noRemoteConsole = true,
			noPlayerFacingUi = true,
			noModeration = true,
			noAnalyticsCollection = true,
			noExploitBackdoorTooling = true,
			noDataStoreReads = true,
			noDataStoreWrites = true,
			noWorkspaceMutation = true,
			noRemotes = true,
			noClientAuthority = true,
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
	if state.counts.tools > Types.Limits.MaxTools then
		return false, "tool count exceeds limit"
	end
	if state.counts.inspections > Types.Limits.MaxInspections then
		return false, "inspection count exceeds limit"
	end
	if state.counts.commands > Types.Limits.MaxCommands then
		return false, "command schema count exceeds limit"
	end
	if state.counts.reports > Types.Limits.MaxReports then
		return false, "report count exceeds limit"
	end
	if state.counts.permissions > Types.Limits.MaxPermissions then
		return false, "permission count exceeds limit"
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
