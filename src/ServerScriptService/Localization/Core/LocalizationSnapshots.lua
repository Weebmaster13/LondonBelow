--!strict
-- Snapshot provider for Localization Runtime Foundation.

local Serialization = require(script.Parent.LocalizationSerialization)
local Types = require(script.Parent.LocalizationTypes)

local Snapshots = {}

function Snapshots.capture(state: any)
	local current = state.inspect()
	local snapshot = Serialization.deepCopy({
		mode = Types.Mode,
		counts = current.counts,
		languages = current.languages,
		textKeys = current.textKeys,
		packages = current.packages,
		fallbacks = current.fallbacks,
		subtitles = current.subtitles,
		captions = current.captions,
		textSafetyRules = current.textSafetyRules,
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
	})
	state.recordSnapshot(snapshot)
	return snapshot
end

return Snapshots
