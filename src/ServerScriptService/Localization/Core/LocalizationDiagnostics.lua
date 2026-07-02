--!strict
-- Diagnostics for Localization Runtime Foundation.

local Serialization = require(script.Parent.LocalizationSerialization)
local Types = require(script.Parent.LocalizationTypes)

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
			languages = state.counts.languages .. "/" .. Types.Limits.MaxLanguages,
			textKeys = state.counts.textKeys .. "/" .. Types.Limits.MaxTextKeys,
			packages = state.counts.packages .. "/" .. Types.Limits.MaxPackages,
			fallbacks = state.counts.fallbacks .. "/" .. Types.Limits.MaxFallbacks,
			subtitles = state.counts.subtitles .. "/" .. Types.Limits.MaxSubtitles,
			captions = state.counts.captions .. "/" .. Types.Limits.MaxCaptions,
			textSafetyRules = state.counts.textSafetyRules
				.. "/"
				.. Types.Limits.MaxTextSafetyRules,
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
			containsNoFinalStoryText = true,
			containsNoFinalDialogueText = true,
			containsNoExternalTranslationHandles = true,
		},
		diagnosticsIsolationProof = {
			diagnosticsAreDeepCopies = true,
			rawUnsafePayloadsAreSanitized = true,
			containsNoServiceReferences = true,
			containsNoRemoteReferences = true,
		},
		noExecutionPosture = {
			noFinalTranslatedText = true,
			noFinalDialogue = true,
			noStoryWriting = true,
			noChapterContent = true,
			noAutomaticTranslation = true,
			noExternalTranslationServices = true,
			noExternalHttpAccess = true,
			noExternalMessagingAccess = true,
			noDataStoreReadsWrites = true,
			noSubtitleRendering = true,
			noCaptionRendering = true,
			noVoiceoverPlayback = true,
			noAudioExecution = true,
			noUiRendering = true,
			noClientPresentation = true,
			noRemotes = true,
			noClientAuthority = true,
			noWorldMutation = true,
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
	if state.counts.languages > Types.Limits.MaxLanguages then
		return false, "language count exceeds limit"
	end
	if state.counts.textKeys > Types.Limits.MaxTextKeys then
		return false, "text key count exceeds limit"
	end
	if state.counts.packages > Types.Limits.MaxPackages then
		return false, "package count exceeds limit"
	end
	if state.counts.fallbacks > Types.Limits.MaxFallbacks then
		return false, "fallback count exceeds limit"
	end
	if state.counts.subtitles > Types.Limits.MaxSubtitles then
		return false, "subtitle count exceeds limit"
	end
	if state.counts.captions > Types.Limits.MaxCaptions then
		return false, "caption count exceeds limit"
	end
	if state.counts.textSafetyRules > Types.Limits.MaxTextSafetyRules then
		return false, "text safety rule count exceeds limit"
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
