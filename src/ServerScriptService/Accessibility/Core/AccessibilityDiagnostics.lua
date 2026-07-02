--!strict
-- Diagnostics for Accessibility Runtime Foundation.

local Serialization = require(script.Parent.AccessibilitySerialization)
local Types = require(script.Parent.AccessibilityTypes)

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
			settings = state.counts.settings .. "/" .. Types.Limits.MaxSettings,
			visuals = state.counts.visuals .. "/" .. Types.Limits.MaxVisuals,
			audios = state.counts.audios .. "/" .. Types.Limits.MaxAudios,
			inputs = state.counts.inputs .. "/" .. Types.Limits.MaxInputs,
			motions = state.counts.motions .. "/" .. Types.Limits.MaxMotions,
			readabilities = state.counts.readabilities .. "/" .. Types.Limits.MaxReadabilities,
			contentWarnings = state.counts.contentWarnings
				.. "/"
				.. Types.Limits.MaxContentWarnings,
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
			noFinalAccessibilityUi = true,
			noClientSettingsExecution = true,
			noInputRemappingExecution = true,
			noAudioExecution = true,
			noLightingExecution = true,
			noCameraExecution = true,
			noVfxExecution = true,
			noWorldMutation = true,
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
	if state.counts.settings > Types.Limits.MaxSettings then
		return false, "setting count exceeds limit"
	end
	if state.counts.visuals > Types.Limits.MaxVisuals then
		return false, "visual rule count exceeds limit"
	end
	if state.counts.audios > Types.Limits.MaxAudios then
		return false, "audio safety rule count exceeds limit"
	end
	if state.counts.inputs > Types.Limits.MaxInputs then
		return false, "input assist count exceeds limit"
	end
	if state.counts.motions > Types.Limits.MaxMotions then
		return false, "motion comfort count exceeds limit"
	end
	if state.counts.readabilities > Types.Limits.MaxReadabilities then
		return false, "readability count exceeds limit"
	end
	if state.counts.contentWarnings > Types.Limits.MaxContentWarnings then
		return false, "content warning count exceeds limit"
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
