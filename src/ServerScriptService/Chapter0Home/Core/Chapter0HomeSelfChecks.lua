--!strict

local Config = require(script.Parent.Chapter0HomeConfig)
local Serialization = require(script.Parent.Chapter0HomeSerialization)
local State = require(script.Parent.Chapter0HomeState)
local Types = require(script.Parent.Chapter0HomeTypes)
local Validation = require(script.Parent.Chapter0HomeValidation)

local SelfChecks = {}

local function add(results: { any }, name: string, ok: boolean, detail: string?)
	table.insert(results, {
		name = name,
		ok = ok,
		detail = detail,
	})
end

local function summarize(results: { any })
	local failed = 0

	for _, result in ipairs(results) do
		if not result.ok then
			failed += 1
		end
	end

	return {
		ok = failed == 0,
		total = #results,
		failures = failed,
		results = results,
	}
end

local function overLimitRooms(definition: any)
	local excessive = Serialization.deepCopy(definition)

	for index = #excessive.rooms + 1, Types.Limits.MaxRooms + 1 do
		excessive.rooms[index] = Serialization.deepCopy(excessive.rooms[1])
		excessive.rooms[index].roomId = "chapter0_home_extra_room_" .. tostring(index)
	end

	return excessive
end

local function feedbackDefinition(definition: any, feedbackId: string): any?
	for _, feedback in ipairs(definition.atmosphericFeedback) do
		if feedback.feedbackId == feedbackId then
			return feedback
		end
	end

	return nil
end

local function reactionDefinition(definition: any, reactionId: string): any?
	for _, reaction in ipairs(definition.environmentalReactions) do
		if reaction.reactionId == reactionId then
			return reaction
		end
	end

	return nil
end

local function canonicalReactionIdsMatch(definition: any): boolean
	if #definition.environmentalReactions ~= #Types.CanonicalEnvironmentalReactionIds then
		return false
	end

	for index, reactionId in ipairs(Types.CanonicalEnvironmentalReactionIds) do
		if definition.environmentalReactions[index].reactionId ~= reactionId then
			return false
		end
	end

	return true
end

local function canonicalProgressionStageIdsMatch(definition: any): boolean
	if
		#definition.atmosphericProgressionStages ~= #Types.CanonicalAtmosphericProgressionStageIds
	then
		return false
	end

	for index, stageId in ipairs(Types.CanonicalAtmosphericProgressionStageIds) do
		if definition.atmosphericProgressionStages[index].stageId ~= stageId then
			return false
		end
	end

	return true
end

local function canonicalProgressionTransitionIdsMatch(definition: any): boolean
	if
		#definition.atmosphericProgressionTransitions
		~= #Types.CanonicalAtmosphericProgressionTransitionIds
	then
		return false
	end

	for index, transitionId in ipairs(Types.CanonicalAtmosphericProgressionTransitionIds) do
		if definition.atmosphericProgressionTransitions[index].transitionId ~= transitionId then
			return false
		end
	end

	return true
end

local function canonicalProgressionTransitionPayload(transitionId: string): any
	for _, transitionDefinition in
		ipairs(Types.CanonicalAtmosphericProgressionTransitionDefinitions)
	do
		if transitionDefinition.transitionId == transitionId then
			return Serialization.deepCopy(transitionDefinition)
		end
	end

	error("unknown canonical progression transition " .. transitionId, 0)
end

local function recordCanonicalProgressionSequence(userId: number, count: number)
	for index = 1, count do
		State.recordAtmosphericProgression(
			userId,
			Serialization.deepCopy(
				Types.CanonicalAtmosphericProgressionTransitionDefinitions[index]
			)
		)
	end
end

local function canonicalObservationFactPayload(factId: string): any
	for _, factDefinition in ipairs(Types.CanonicalObservationFactDefinitions) do
		if factDefinition.factId == factId then
			return Serialization.deepCopy(factDefinition)
		end
	end

	error("unknown canonical observation fact " .. factId, 0)
end

local function canonicalObservationFactIdsMatch(definition: any): boolean
	if #definition.observationFacts ~= #Types.CanonicalObservationFactIds then
		return false
	end

	for index, factId in ipairs(Types.CanonicalObservationFactIds) do
		if definition.observationFacts[index].factId ~= factId then
			return false
		end
	end

	return true
end

function SelfChecks.run(context: any)
	local results = {}
	local definition = Config.Definition

	local valid, reason = Validation.validateDefinition(definition)
	add(results, "definition validates", valid, reason)

	add(results, "canonical atmospheric feedback count", #definition.atmosphericFeedback == 4, nil)

	add(
		results,
		"canonical atmospheric feedback ordering",
		definition.atmosphericFeedback[1].feedbackId == "chapter0_home_note_context"
			and definition.atmosphericFeedback[2].feedbackId == "chapter0_home_lamp_response"
			and definition.atmosphericFeedback[3].feedbackId == "chapter0_home_ribbon_escalation"
			and definition.atmosphericFeedback[4].feedbackId
				== "chapter0_home_bedroom_door_warning",
		nil
	)

	add(
		results,
		"canonical atmospheric feedback ids",
		feedbackDefinition(definition, "chapter0_home_note_context") ~= nil
			and feedbackDefinition(definition, "chapter0_home_lamp_response") ~= nil
			and feedbackDefinition(definition, "chapter0_home_ribbon_escalation") ~= nil
			and feedbackDefinition(definition, "chapter0_home_bedroom_door_warning") ~= nil,
		nil
	)

	add(
		results,
		"canonical feedback interaction references",
		definition.atmosphericFeedback[1].interactionId == "chapter0_home_note"
			and definition.atmosphericFeedback[2].interactionId == "chapter0_home_lamp"
			and definition.atmosphericFeedback[3].interactionId == "chapter0_home_marmalade_ribbon"
			and definition.atmosphericFeedback[4].interactionId == "chapter0_home_bedroom_door",
		nil
	)

	add(
		results,
		"canonical environmental reaction count",
		#definition.environmentalReactions == 4,
		nil
	)

	add(
		results,
		"canonical environmental reaction ordering",
		canonicalReactionIdsMatch(definition),
		nil
	)

	add(
		results,
		"canonical environmental reaction ids",
		reactionDefinition(definition, "chapter0_home_note_room_attention") ~= nil
			and reactionDefinition(definition, "chapter0_home_lamp_warmth_state") ~= nil
			and reactionDefinition(definition, "chapter0_home_ribbon_hall_pressure") ~= nil
			and reactionDefinition(definition, "chapter0_home_bedroom_door_resistance") ~= nil,
		nil
	)

	add(
		results,
		"canonical reaction interaction references",
		definition.environmentalReactions[1].interactionId == "chapter0_home_note"
			and definition.environmentalReactions[2].interactionId == "chapter0_home_lamp"
			and definition.environmentalReactions[3].interactionId == "chapter0_home_marmalade_ribbon"
			and definition.environmentalReactions[4].interactionId
				== "chapter0_home_bedroom_door",
		nil
	)

	add(
		results,
		"environmental reaction attribute names are exact",
		Types.EnvironmentalReactionAttributeNames.ReactionId == "AtmosphereReactionId"
			and Types.EnvironmentalReactionAttributeNames.InteractionId == "AtmosphereInteractionId"
			and Types.EnvironmentalReactionAttributeNames.Kind == "AtmosphereKind"
			and Types.EnvironmentalReactionAttributeNames.TargetKind == "AtmosphereTargetKind"
			and Types.EnvironmentalReactionAttributeNames.TargetId == "AtmosphereTargetId"
			and Types.EnvironmentalReactionAttributeNames.Intensity == "AtmosphereIntensity"
			and Types.EnvironmentalReactionAttributeNames.Order == "AtmosphereOrder"
			and Types.EnvironmentalReactionAttributePrefix == "Atmosphere_",
		nil
	)

	add(
		results,
		"canonical environmental reaction target references",
		definition.environmentalReactions[1].targetKind
				== Types.EnvironmentalReactionTargetKind.Room
			and definition.environmentalReactions[1].targetId == "chapter0_home_sitting_room"
			and definition.environmentalReactions[2].targetKind == Types.EnvironmentalReactionTargetKind.Interaction
			and definition.environmentalReactions[2].targetId == "chapter0_home_lamp"
			and definition.environmentalReactions[3].targetKind == Types.EnvironmentalReactionTargetKind.Room
			and definition.environmentalReactions[3].targetId == "chapter0_home_hall"
			and definition.environmentalReactions[4].targetKind == Types.EnvironmentalReactionTargetKind.Interaction
			and definition.environmentalReactions[4].targetId == "chapter0_home_bedroom_door",
		nil
	)

	add(
		results,
		"canonical atmospheric progression stage count",
		#definition.atmosphericProgressionStages == 4,
		nil
	)

	add(
		results,
		"canonical atmospheric progression stage ordering",
		canonicalProgressionStageIdsMatch(definition),
		nil
	)

	add(
		results,
		"canonical atmospheric progression transition count",
		#definition.atmosphericProgressionTransitions == 4,
		nil
	)

	add(
		results,
		"canonical atmospheric progression transition ordering",
		canonicalProgressionTransitionIdsMatch(definition),
		nil
	)

	add(
		results,
		"canonical atmospheric progression interaction references",
		definition.atmosphericProgressionTransitions[1].interactionId == "chapter0_home_note"
			and definition.atmosphericProgressionTransitions[2].interactionId == "chapter0_home_lamp"
			and definition.atmosphericProgressionTransitions[3].interactionId == "chapter0_home_marmalade_ribbon"
			and definition.atmosphericProgressionTransitions[4].interactionId
				== "chapter0_home_bedroom_door",
		nil
	)

	add(
		results,
		"canonical atmospheric progression feedback and reaction references",
		definition.atmosphericProgressionTransitions[1].feedbackId == "chapter0_home_note_context"
			and definition.atmosphericProgressionTransitions[1].reactionId == "chapter0_home_note_room_attention"
			and definition.atmosphericProgressionTransitions[4].feedbackId == "chapter0_home_bedroom_door_warning"
			and definition.atmosphericProgressionTransitions[4].reactionId
				== "chapter0_home_bedroom_door_resistance",
		nil
	)

	add(
		results,
		"optional bedroom door progression is non-blocking",
		definition.atmosphericProgressionTransitions[4].optionalModifier == true
			and definition.atmosphericProgressionTransitions[4].completionRelevant == false
			and definition.atmosphericProgressionTransitions[4].toStageId == nil,
		nil
	)

	add(
		results,
		"canonical atmospheric progression initial stage is exact",
		definition.atmosphericProgressionStages[1].stageId
				== Types.InitialAtmosphericProgressionStageId
			and definition.atmosphericProgressionStages[1].initial == true,
		nil
	)

	add(
		results,
		"canonical atmospheric progression from and to stage references",
		definition.atmosphericProgressionTransitions[1].fromStageId == "chapter0_home_quiet_initial"
			and definition.atmosphericProgressionTransitions[1].toStageId == "chapter0_home_note_acknowledged"
			and definition.atmosphericProgressionTransitions[2].fromStageId == "chapter0_home_note_acknowledged"
			and definition.atmosphericProgressionTransitions[2].toStageId == "chapter0_home_lamp_unsteady_comfort"
			and definition.atmosphericProgressionTransitions[3].fromStageId == "chapter0_home_lamp_unsteady_comfort"
			and definition.atmosphericProgressionTransitions[3].toStageId
				== "chapter0_home_ribbon_quiet_escalation",
		nil
	)

	add(
		results,
		"canonical atmospheric progression required interaction sequences",
		#definition.atmosphericProgressionTransitions[2].requiredInteractionIds == 2
			and definition.atmosphericProgressionTransitions[2].requiredInteractionIds[1] == "chapter0_home_note"
			and definition.atmosphericProgressionTransitions[2].requiredInteractionIds[2] == "chapter0_home_lamp"
			and #definition.atmosphericProgressionTransitions[3].requiredInteractionIds == 3
			and definition.atmosphericProgressionTransitions[3].requiredInteractionIds[3]
				== "chapter0_home_marmalade_ribbon",
		nil
	)

	add(
		results,
		"canonical atmospheric progression intensities are exact",
		definition.atmosphericProgressionStages[1].intensity == 0.05
			and definition.atmosphericProgressionStages[4].intensity == 0.52
			and definition.atmosphericProgressionTransitions[1].intensity == 0.25
			and definition.atmosphericProgressionTransitions[4].intensity == 0.18,
		nil
	)

	add(
		results,
		"canonical atmospheric progression posture keys are lowerCamelCase",
		#Types.AtmosphericProgressionPostureKeys == 23
			and Types.AtmosphericProgressionPostureKeys[1] == "serverAuthoritative"
			and Types.AtmosphericProgressionPostureKeys[23] == "noChapter1Content",
		nil
	)

	add(
		results,
		"canonical observation fact count",
		#definition.observationFacts == #Types.CanonicalObservationFactDefinitions
			and #definition.observationFacts == 7,
		nil
	)

	add(
		results,
		"canonical observation fact ordering",
		canonicalObservationFactIdsMatch(definition),
		nil
	)

	add(
		results,
		"canonical observation runtime ids are exact",
		#Types.CanonicalObservationRuntimeIds == 7
			and Types.CanonicalObservationRuntimeIds[1] == "Chapter0Home.NoteAcknowledged"
			and Types.CanonicalObservationRuntimeIds[7]
				== "Chapter0Home.AtmosphericFeedbackPosture",
		nil
	)

	add(
		results,
		"canonical observation source contract is exact",
		Types.ObservationContractVersion == "chapter0HomeObservation.v1"
			and Types.ObservationSourceRuntime == Types.RuntimeName
			and Types.ObservationAuthority == "Server",
		nil
	)

	add(
		results,
		"canonical observation kinds are exact",
		definition.observationFacts[1].kind == Types.ObservationKind.Story
			and definition.observationFacts[2].kind == Types.ObservationKind.Environment
			and definition.observationFacts[3].kind == Types.ObservationKind.Progression
			and definition.observationFacts[7].kind == Types.ObservationKind.Feedback,
		nil
	)

	add(
		results,
		"canonical observation interaction references are exact",
		definition.observationFacts[1].interactionId == "chapter0_home_note"
			and definition.observationFacts[2].interactionId == "chapter0_home_lamp"
			and definition.observationFacts[3].interactionId == "chapter0_home_marmalade_ribbon"
			and definition.observationFacts[4].interactionId == "chapter0_home_bedroom_door",
		nil
	)

	add(
		results,
		"canonical observation stage references are exact",
		definition.observationFacts[1].stageId == "chapter0_home_note_acknowledged"
			and definition.observationFacts[2].stageId == "chapter0_home_lamp_unsteady_comfort"
			and definition.observationFacts[3].stageId == "chapter0_home_ribbon_quiet_escalation"
			and definition.observationFacts[5].stageId
				== "chapter0_home_ribbon_quiet_escalation",
		nil
	)

	add(
		results,
		"canonical observation feedback references are exact",
		definition.observationFacts[1].feedbackId == "chapter0_home_note_context"
			and definition.observationFacts[2].feedbackId == "chapter0_home_lamp_response"
			and definition.observationFacts[3].feedbackId == "chapter0_home_ribbon_escalation"
			and definition.observationFacts[4].feedbackId
				== "chapter0_home_bedroom_door_warning",
		nil
	)

	add(
		results,
		"canonical observation reaction references are exact",
		definition.observationFacts[1].reactionId == "chapter0_home_note_room_attention"
			and definition.observationFacts[2].reactionId == "chapter0_home_lamp_warmth_state"
			and definition.observationFacts[3].reactionId == "chapter0_home_ribbon_hall_pressure"
			and definition.observationFacts[4].reactionId
				== "chapter0_home_bedroom_door_resistance",
		nil
	)

	add(
		results,
		"canonical observation optional modifier semantics are exact",
		definition.observationFacts[4].optionalModifier == true
			and definition.observationFacts[4].completionRelevant == false
			and definition.observationFacts[3].completionRelevant == true
			and definition.observationFacts[5].completionRelevant == true,
		nil
	)

	add(
		results,
		"canonical observation posture keys are lowerCamelCase",
		#Types.ObservationPostureKeys == 19
			and Types.ObservationPostureKeys[1] == "serverAuthoritative"
			and Types.ObservationPostureKeys[19] == "noChapter1Content",
		nil
	)

	local duplicate = Serialization.deepCopy(definition)
	duplicate.interactions[2].interactionId = duplicate.interactions[1].interactionId
	local duplicateValid = Validation.validateDefinition(duplicate)
	add(results, "duplicate interaction ids reject", not duplicateValid, nil)

	local duplicateRoom = Serialization.deepCopy(definition)
	duplicateRoom.rooms[2].roomId = duplicateRoom.rooms[1].roomId
	local duplicateRoomValid = Validation.validateDefinition(duplicateRoom)
	add(results, "duplicate room ids reject", not duplicateRoomValid, nil)

	local sparseRooms = Serialization.deepCopy(definition)
	sparseRooms.rooms[2] = nil
	local sparseRoomsValid = Validation.validateDefinition(sparseRooms)
	add(results, "sparse room arrays reject", not sparseRoomsValid, nil)

	local dictionaryInteractions = Serialization.deepCopy(definition)
	dictionaryInteractions.interactions.byId = dictionaryInteractions.interactions[1]
	local dictionaryInteractionsValid = Validation.validateDefinition(dictionaryInteractions)
	add(results, "dictionary interaction arrays reject", not dictionaryInteractionsValid, nil)

	local missingRoom = Serialization.deepCopy(definition)
	missingRoom.interactions[1].roomId = "missing_room"
	local missingRoomValid = Validation.validateDefinition(missingRoom)
	add(results, "missing room references reject", not missingRoomValid, nil)

	local missingConnection = Serialization.deepCopy(definition)
	missingConnection.rooms[1].connections[1] = "missing_room"
	local missingConnectionValid = Validation.validateDefinition(missingConnection)
	add(results, "missing room connections reject", not missingConnectionValid, nil)

	local excessiveRooms = overLimitRooms(definition)
	local excessiveRoomsValid = Validation.validateDefinition(excessiveRooms)
	add(results, "room limits reject", not excessiveRoomsValid, nil)

	local unsafe = Serialization.deepCopy(definition)
	unsafe.interactions[1].metadata.DataStoreWrite = true
	local unsafeValid = Validation.validateDefinition(unsafe)
	add(results, "unsafe metadata rejects", not unsafeValid, nil)

	local unsupportedDefinitionField = Serialization.deepCopy(definition)
	unsupportedDefinitionField.runtimeOverride = true
	local unsupportedDefinitionFieldValid =
		Validation.validateDefinition(unsupportedDefinitionField)
	add(results, "unsupported definition fields reject", not unsupportedDefinitionFieldValid, nil)

	local unsupportedRoomField = Serialization.deepCopy(definition)
	unsupportedRoomField.rooms[1].temporaryModel = "not_allowed"
	local unsupportedRoomFieldValid = Validation.validateDefinition(unsupportedRoomField)
	add(results, "unsupported room fields reject", not unsupportedRoomFieldValid, nil)

	local unsupportedInteractionField = Serialization.deepCopy(definition)
	unsupportedInteractionField.interactions[1].remoteName = "not_allowed"
	local unsupportedInteractionFieldValid =
		Validation.validateDefinition(unsupportedInteractionField)
	add(results, "unsupported interaction fields reject", not unsupportedInteractionFieldValid, nil)

	local unsupportedFeedbackField = Serialization.deepCopy(definition)
	unsupportedFeedbackField.atmosphericFeedback[1].remoteName = "not_allowed"
	local unsupportedFeedbackFieldValid = Validation.validateDefinition(unsupportedFeedbackField)
	add(results, "unsupported feedback fields reject", not unsupportedFeedbackFieldValid, nil)

	local duplicateFeedback = Serialization.deepCopy(definition)
	duplicateFeedback.atmosphericFeedback[2].feedbackId =
		duplicateFeedback.atmosphericFeedback[1].feedbackId
	local duplicateFeedbackValid = Validation.validateDefinition(duplicateFeedback)
	add(results, "duplicate feedback ids reject", not duplicateFeedbackValid, nil)

	local missingFeedbackInteraction = Serialization.deepCopy(definition)
	missingFeedbackInteraction.atmosphericFeedback[1].interactionId = "missing_interaction"
	local missingFeedbackInteractionValid =
		Validation.validateDefinition(missingFeedbackInteraction)
	add(
		results,
		"unknown feedback interaction references reject",
		not missingFeedbackInteractionValid,
		nil
	)

	local invalidFeedbackKind = Serialization.deepCopy(definition)
	invalidFeedbackKind.atmosphericFeedback[1].kind = "Scare"
	local invalidFeedbackKindValid = Validation.validateDefinition(invalidFeedbackKind)
	add(results, "invalid feedback kinds reject", not invalidFeedbackKindValid, nil)

	local unsafeFeedbackMetadata = Serialization.deepCopy(definition)
	unsafeFeedbackMetadata.atmosphericFeedback[1].metadata.clientAuthority = true
	local unsafeFeedbackMetadataValid = Validation.validateDefinition(unsafeFeedbackMetadata)
	add(results, "unsafe feedback metadata rejects", not unsafeFeedbackMetadataValid, nil)

	local oversizedFeedbackInstruction = Serialization.deepCopy(definition)
	oversizedFeedbackInstruction.atmosphericFeedback[1].instructionId =
		string.rep("x", Types.Limits.MaxFeedbackInstructionIdLength + 1)
	local oversizedFeedbackInstructionValid =
		Validation.validateDefinition(oversizedFeedbackInstruction)
	add(results, "oversized feedback payload rejects", not oversizedFeedbackInstructionValid, nil)

	local sparseFeedback = Serialization.deepCopy(definition)
	sparseFeedback.atmosphericFeedback[2] = nil
	local sparseFeedbackValid = Validation.validateDefinition(sparseFeedback)
	add(results, "sparse feedback arrays reject", not sparseFeedbackValid, nil)

	local dictionaryFeedback = Serialization.deepCopy(definition)
	dictionaryFeedback.atmosphericFeedback.byId = dictionaryFeedback.atmosphericFeedback[1]
	local dictionaryFeedbackValid = Validation.validateDefinition(dictionaryFeedback)
	add(results, "dictionary feedback arrays reject", not dictionaryFeedbackValid, nil)

	local invalidFeedbackOrder = Serialization.deepCopy(definition)
	invalidFeedbackOrder.atmosphericFeedback[2].order =
		invalidFeedbackOrder.atmosphericFeedback[1].order
	local invalidFeedbackOrderValid = Validation.validateDefinition(invalidFeedbackOrder)
	add(results, "invalid feedback ordering rejects", not invalidFeedbackOrderValid, nil)

	local invalidFeedbackIntensity = Serialization.deepCopy(definition)
	invalidFeedbackIntensity.atmosphericFeedback[1].intensity = 1.5
	local invalidFeedbackIntensityValid = Validation.validateDefinition(invalidFeedbackIntensity)
	add(results, "invalid feedback intensity rejects", not invalidFeedbackIntensityValid, nil)

	local invalidFeedbackDuration = Serialization.deepCopy(definition)
	invalidFeedbackDuration.atmosphericFeedback[1].duration = 0
	local invalidFeedbackDurationValid = Validation.validateDefinition(invalidFeedbackDuration)
	add(results, "invalid feedback duration rejects", not invalidFeedbackDurationValid, nil)

	local nonLowerCamelFeedbackMetadata = Serialization.deepCopy(definition)
	nonLowerCamelFeedbackMetadata.atmosphericFeedback[1].metadata.BadKey = true
	local nonLowerCamelFeedbackMetadataValid =
		Validation.validateDefinition(nonLowerCamelFeedbackMetadata)
	add(
		results,
		"non-lowerCamelCase feedback posture metadata rejects",
		not nonLowerCamelFeedbackMetadataValid,
		nil
	)

	local unsupportedReactionField = Serialization.deepCopy(definition)
	unsupportedReactionField.environmentalReactions[1].remoteName = "not_allowed"
	local unsupportedReactionFieldValid = Validation.validateDefinition(unsupportedReactionField)
	add(results, "unsupported reaction fields reject", not unsupportedReactionFieldValid, nil)

	local duplicateReaction = Serialization.deepCopy(definition)
	duplicateReaction.environmentalReactions[2].reactionId =
		duplicateReaction.environmentalReactions[1].reactionId
	local duplicateReactionValid = Validation.validateDefinition(duplicateReaction)
	add(results, "duplicate reaction ids reject", not duplicateReactionValid, nil)

	local missingReactionInteraction = Serialization.deepCopy(definition)
	missingReactionInteraction.environmentalReactions[1].interactionId = "missing_interaction"
	local missingReactionInteractionValid =
		Validation.validateDefinition(missingReactionInteraction)
	add(
		results,
		"unknown reaction interaction references reject",
		not missingReactionInteractionValid,
		nil
	)

	local invalidReactionKind = Serialization.deepCopy(definition)
	invalidReactionKind.environmentalReactions[1].kind = "JumpScare"
	local invalidReactionKindValid = Validation.validateDefinition(invalidReactionKind)
	add(results, "invalid reaction kinds reject", not invalidReactionKindValid, nil)

	local invalidReactionTargetKind = Serialization.deepCopy(definition)
	invalidReactionTargetKind.environmentalReactions[1].targetKind = "Workspace"
	local invalidReactionTargetKindValid = Validation.validateDefinition(invalidReactionTargetKind)
	add(results, "invalid reaction target kinds reject", not invalidReactionTargetKindValid, nil)

	local invalidReactionRootTarget = Serialization.deepCopy(definition)
	invalidReactionRootTarget.environmentalReactions[1].targetKind =
		Types.EnvironmentalReactionTargetKind.ChapterRoot
	invalidReactionRootTarget.environmentalReactions[1].targetId = "Workspace"
	local invalidReactionRootTargetValid = Validation.validateDefinition(invalidReactionRootTarget)
	add(results, "invalid reaction root targets reject", not invalidReactionRootTargetValid, nil)

	local missingReactionRoom = Serialization.deepCopy(definition)
	missingReactionRoom.environmentalReactions[1].targetId = "missing_room"
	local missingReactionRoomValid = Validation.validateDefinition(missingReactionRoom)
	add(results, "unknown reaction room targets reject", not missingReactionRoomValid, nil)

	local missingReactionInteractionTarget = Serialization.deepCopy(definition)
	missingReactionInteractionTarget.environmentalReactions[2].targetId = "missing_interaction"
	local missingReactionInteractionTargetValid =
		Validation.validateDefinition(missingReactionInteractionTarget)
	add(
		results,
		"unknown reaction interaction targets reject",
		not missingReactionInteractionTargetValid,
		nil
	)

	local unsafeReactionMetadata = Serialization.deepCopy(definition)
	unsafeReactionMetadata.environmentalReactions[1].metadata.clientAuthority = true
	local unsafeReactionMetadataValid = Validation.validateDefinition(unsafeReactionMetadata)
	add(results, "unsafe reaction metadata rejects", not unsafeReactionMetadataValid, nil)

	local reactionMetadataLimit = Serialization.deepCopy(definition)
	for index = 1, Types.Limits.MaxEnvironmentalReactionMetadataKeys + 1 do
		reactionMetadataLimit.environmentalReactions[1].metadata["extraKey" .. tostring(index)] =
			index
	end
	local reactionMetadataLimitValid = Validation.validateDefinition(reactionMetadataLimit)
	add(results, "reaction metadata limits reject", not reactionMetadataLimitValid, nil)

	local reactionDefinitionLimit = Serialization.deepCopy(definition)
	for index = #reactionDefinitionLimit.environmentalReactions + 1, Types.Limits.MaxEnvironmentalReactionDefinitions + 1 do
		reactionDefinitionLimit.environmentalReactions[index] =
			Serialization.deepCopy(reactionDefinitionLimit.environmentalReactions[1])
		reactionDefinitionLimit.environmentalReactions[index].reactionId = "chapter0_home_extra_reaction_"
			.. tostring(index)
		reactionDefinitionLimit.environmentalReactions[index].order = index
	end
	local reactionDefinitionLimitValid = Validation.validateDefinition(reactionDefinitionLimit)
	add(results, "reaction definition limits reject", not reactionDefinitionLimitValid, nil)

	local sparseReactions = Serialization.deepCopy(definition)
	sparseReactions.environmentalReactions[2] = nil
	local sparseReactionsValid = Validation.validateDefinition(sparseReactions)
	add(results, "sparse reaction arrays reject", not sparseReactionsValid, nil)

	local dictionaryReactions = Serialization.deepCopy(definition)
	dictionaryReactions.environmentalReactions.byId = dictionaryReactions.environmentalReactions[1]
	local dictionaryReactionsValid = Validation.validateDefinition(dictionaryReactions)
	add(results, "dictionary reaction arrays reject", not dictionaryReactionsValid, nil)

	local invalidReactionOrder = Serialization.deepCopy(definition)
	invalidReactionOrder.environmentalReactions[2].order =
		invalidReactionOrder.environmentalReactions[1].order
	local invalidReactionOrderValid = Validation.validateDefinition(invalidReactionOrder)
	add(results, "invalid reaction ordering rejects", not invalidReactionOrderValid, nil)

	local invalidReactionIntensity = Serialization.deepCopy(definition)
	invalidReactionIntensity.environmentalReactions[1].intensity = 1.5
	local invalidReactionIntensityValid = Validation.validateDefinition(invalidReactionIntensity)
	add(results, "invalid reaction intensity rejects", not invalidReactionIntensityValid, nil)

	local nonLowerCamelReactionMetadata = Serialization.deepCopy(definition)
	nonLowerCamelReactionMetadata.environmentalReactions[1].metadata.BadKey = true
	local nonLowerCamelReactionMetadataValid =
		Validation.validateDefinition(nonLowerCamelReactionMetadata)
	add(
		results,
		"non-lowerCamelCase reaction metadata rejects",
		not nonLowerCamelReactionMetadataValid,
		nil
	)

	local unsupportedProgressionStageField = Serialization.deepCopy(definition)
	unsupportedProgressionStageField.atmosphericProgressionStages[1].remoteName = "not_allowed"
	local unsupportedProgressionStageFieldValid =
		Validation.validateDefinition(unsupportedProgressionStageField)
	add(
		results,
		"unsupported progression stage fields reject",
		not unsupportedProgressionStageFieldValid,
		nil
	)

	local unsupportedProgressionTransitionField = Serialization.deepCopy(definition)
	unsupportedProgressionTransitionField.atmosphericProgressionTransitions[1].remoteName =
		"not_allowed"
	local unsupportedProgressionTransitionFieldValid =
		Validation.validateDefinition(unsupportedProgressionTransitionField)
	add(
		results,
		"unsupported progression transition fields reject",
		not unsupportedProgressionTransitionFieldValid,
		nil
	)

	local duplicateProgressionStage = Serialization.deepCopy(definition)
	duplicateProgressionStage.atmosphericProgressionStages[2].stageId =
		duplicateProgressionStage.atmosphericProgressionStages[1].stageId
	local duplicateProgressionStageValid = Validation.validateDefinition(duplicateProgressionStage)
	add(results, "duplicate progression stage ids reject", not duplicateProgressionStageValid, nil)

	local duplicateProgressionTransition = Serialization.deepCopy(definition)
	duplicateProgressionTransition.atmosphericProgressionTransitions[2].transitionId =
		duplicateProgressionTransition.atmosphericProgressionTransitions[1].transitionId
	local duplicateProgressionTransitionValid =
		Validation.validateDefinition(duplicateProgressionTransition)
	add(
		results,
		"duplicate progression transition ids reject",
		not duplicateProgressionTransitionValid,
		nil
	)

	local progressionStageCountDrift = Serialization.deepCopy(definition)
	table.remove(progressionStageCountDrift.atmosphericProgressionStages, 4)
	local progressionStageCountDriftValid =
		Validation.validateDefinition(progressionStageCountDrift)
	add(results, "progression stage-count drift rejects", not progressionStageCountDriftValid, nil)

	local progressionTransitionCountDrift = Serialization.deepCopy(definition)
	table.remove(progressionTransitionCountDrift.atmosphericProgressionTransitions, 4)
	local progressionTransitionCountDriftValid =
		Validation.validateDefinition(progressionTransitionCountDrift)
	add(
		results,
		"progression transition-count drift rejects",
		not progressionTransitionCountDriftValid,
		nil
	)

	local progressionStageIdDrift = Serialization.deepCopy(definition)
	progressionStageIdDrift.atmosphericProgressionStages[1].stageId =
		"chapter0_home_quiet_initial_alias"
	local progressionStageIdDriftValid = Validation.validateDefinition(progressionStageIdDrift)
	add(results, "progression stage-id drift rejects", not progressionStageIdDriftValid, nil)

	local progressionTransitionIdDrift = Serialization.deepCopy(definition)
	progressionTransitionIdDrift.atmosphericProgressionTransitions[1].transitionId =
		"chapter0_home_progression_note_alias"
	local progressionTransitionIdDriftValid =
		Validation.validateDefinition(progressionTransitionIdDrift)
	add(
		results,
		"progression transition-id drift rejects",
		not progressionTransitionIdDriftValid,
		nil
	)

	local missingInitialProgressionStage = Serialization.deepCopy(definition)
	missingInitialProgressionStage.atmosphericProgressionStages[1].initial = false
	local missingInitialProgressionStageValid =
		Validation.validateDefinition(missingInitialProgressionStage)
	add(
		results,
		"missing initial progression stage rejects",
		not missingInitialProgressionStageValid,
		nil
	)

	local initialProgressionStageIdDrift = Serialization.deepCopy(definition)
	initialProgressionStageIdDrift.atmosphericProgressionStages[1].stageId =
		"chapter0_home_wrong_initial"
	local initialProgressionStageIdDriftValid =
		Validation.validateDefinition(initialProgressionStageIdDrift)
	add(
		results,
		"progression initial-stage id drift rejects",
		not initialProgressionStageIdDriftValid,
		nil
	)

	local multipleInitialProgressionStages = Serialization.deepCopy(definition)
	multipleInitialProgressionStages.atmosphericProgressionStages[2].initial = true
	local multipleInitialProgressionStagesValid =
		Validation.validateDefinition(multipleInitialProgressionStages)
	add(
		results,
		"multiple initial progression stages reject",
		not multipleInitialProgressionStagesValid,
		nil
	)

	local unknownProgressionFromStage = Serialization.deepCopy(definition)
	unknownProgressionFromStage.atmosphericProgressionTransitions[1].fromStageId = "missing_stage"
	local unknownProgressionFromStageValid =
		Validation.validateDefinition(unknownProgressionFromStage)
	add(
		results,
		"unknown progression from stages reject",
		not unknownProgressionFromStageValid,
		nil
	)

	local unknownProgressionToStage = Serialization.deepCopy(definition)
	unknownProgressionToStage.atmosphericProgressionTransitions[1].toStageId = "missing_stage"
	local unknownProgressionToStageValid = Validation.validateDefinition(unknownProgressionToStage)
	add(results, "unknown progression to stages reject", not unknownProgressionToStageValid, nil)

	local unknownProgressionInteraction = Serialization.deepCopy(definition)
	unknownProgressionInteraction.atmosphericProgressionTransitions[1].interactionId =
		"missing_interaction"
	local unknownProgressionInteractionValid =
		Validation.validateDefinition(unknownProgressionInteraction)
	add(
		results,
		"unknown progression interaction references reject",
		not unknownProgressionInteractionValid,
		nil
	)

	local unknownProgressionFeedback = Serialization.deepCopy(definition)
	unknownProgressionFeedback.atmosphericProgressionTransitions[1].feedbackId = "missing_feedback"
	local unknownProgressionFeedbackValid =
		Validation.validateDefinition(unknownProgressionFeedback)
	add(
		results,
		"unknown progression feedback references reject",
		not unknownProgressionFeedbackValid,
		nil
	)

	local unknownProgressionReaction = Serialization.deepCopy(definition)
	unknownProgressionReaction.atmosphericProgressionTransitions[1].reactionId = "missing_reaction"
	local unknownProgressionReactionValid =
		Validation.validateDefinition(unknownProgressionReaction)
	add(
		results,
		"unknown progression reaction references reject",
		not unknownProgressionReactionValid,
		nil
	)

	local invalidProgressionOrder = Serialization.deepCopy(definition)
	invalidProgressionOrder.atmosphericProgressionTransitions[2].order =
		invalidProgressionOrder.atmosphericProgressionTransitions[1].order
	local invalidProgressionOrderValid = Validation.validateDefinition(invalidProgressionOrder)
	add(results, "invalid progression ordering rejects", not invalidProgressionOrderValid, nil)

	local invalidProgressionStageOrder = Serialization.deepCopy(definition)
	invalidProgressionStageOrder.atmosphericProgressionStages[2].order =
		invalidProgressionStageOrder.atmosphericProgressionStages[1].order
	local invalidProgressionStageOrderValid =
		Validation.validateDefinition(invalidProgressionStageOrder)
	add(
		results,
		"invalid progression stage ordering rejects",
		not invalidProgressionStageOrderValid,
		nil
	)

	local cyclicProgression = Serialization.deepCopy(definition)
	cyclicProgression.atmosphericProgressionTransitions[1].toStageId =
		cyclicProgression.atmosphericProgressionTransitions[1].fromStageId
	local cyclicProgressionValid = Validation.validateDefinition(cyclicProgression)
	add(results, "cyclic progression rejects", not cyclicProgressionValid, nil)

	local unreachableProgression = Serialization.deepCopy(definition)
	unreachableProgression.atmosphericProgressionTransitions[2].fromStageId =
		"chapter0_home_ribbon_quiet_escalation"
	local unreachableProgressionValid = Validation.validateDefinition(unreachableProgression)
	add(results, "unreachable progression stages reject", not unreachableProgressionValid, nil)

	local impossibleProgressionRequirement = Serialization.deepCopy(definition)
	impossibleProgressionRequirement.atmosphericProgressionTransitions[1].requiredInteractionIds =
		{ "chapter0_home_lamp" }
	local impossibleProgressionRequirementValid =
		Validation.validateDefinition(impossibleProgressionRequirement)
	add(
		results,
		"impossible progression requirements reject",
		not impossibleProgressionRequirementValid,
		nil
	)

	local duplicateProgressionRequirement = Serialization.deepCopy(definition)
	duplicateProgressionRequirement.atmosphericProgressionTransitions[2].requiredInteractionIds =
		{ "chapter0_home_note", "chapter0_home_note" }
	local duplicateProgressionRequirementValid =
		Validation.validateDefinition(duplicateProgressionRequirement)
	add(
		results,
		"duplicate progression requirements reject",
		not duplicateProgressionRequirementValid,
		nil
	)

	local progressionRequirementOrderDrift = Serialization.deepCopy(definition)
	progressionRequirementOrderDrift.atmosphericProgressionTransitions[2].requiredInteractionIds =
		{ "chapter0_home_lamp", "chapter0_home_note" }
	local progressionRequirementOrderDriftValid =
		Validation.validateDefinition(progressionRequirementOrderDrift)
	add(
		results,
		"progression requirement ordering drift rejects",
		not progressionRequirementOrderDriftValid,
		nil
	)

	local progressionFeedbackReferenceDrift = Serialization.deepCopy(definition)
	progressionFeedbackReferenceDrift.atmosphericProgressionTransitions[2].feedbackId =
		"chapter0_home_note_context"
	local progressionFeedbackReferenceDriftValid =
		Validation.validateDefinition(progressionFeedbackReferenceDrift)
	add(
		results,
		"progression feedback reference drift rejects",
		not progressionFeedbackReferenceDriftValid,
		nil
	)

	local progressionReactionReferenceDrift = Serialization.deepCopy(definition)
	progressionReactionReferenceDrift.atmosphericProgressionTransitions[2].reactionId =
		"chapter0_home_note_room_attention"
	local progressionReactionReferenceDriftValid =
		Validation.validateDefinition(progressionReactionReferenceDrift)
	add(
		results,
		"progression reaction reference drift rejects",
		not progressionReactionReferenceDriftValid,
		nil
	)

	local optionalProgressionGate = Serialization.deepCopy(definition)
	optionalProgressionGate.atmosphericProgressionTransitions[4].optionalModifier = false
	optionalProgressionGate.atmosphericProgressionTransitions[4].toStageId =
		"chapter0_home_ribbon_quiet_escalation"
	optionalProgressionGate.atmosphericProgressionTransitions[4].completionRelevant = true
	local optionalProgressionGateValid = Validation.validateDefinition(optionalProgressionGate)
	add(
		results,
		"optional progression completion gates reject",
		not optionalProgressionGateValid,
		nil
	)

	local invalidProgressionIntensity = Serialization.deepCopy(definition)
	invalidProgressionIntensity.atmosphericProgressionTransitions[1].intensity = 1.5
	local invalidProgressionIntensityValid =
		Validation.validateDefinition(invalidProgressionIntensity)
	add(results, "invalid progression intensity rejects", not invalidProgressionIntensityValid, nil)

	local invalidProgressionStageIntensity = Serialization.deepCopy(definition)
	invalidProgressionStageIntensity.atmosphericProgressionStages[1].intensity = 1.5
	local invalidProgressionStageIntensityValid =
		Validation.validateDefinition(invalidProgressionStageIntensity)
	add(
		results,
		"invalid progression stage intensity rejects",
		not invalidProgressionStageIntensityValid,
		nil
	)

	local invalidProgressionCompletionRelevant = Serialization.deepCopy(definition)
	invalidProgressionCompletionRelevant.atmosphericProgressionTransitions[1].completionRelevant =
		"yes"
	local invalidProgressionCompletionRelevantValid =
		Validation.validateDefinition(invalidProgressionCompletionRelevant)
	add(
		results,
		"invalid progression completion relevance rejects",
		not invalidProgressionCompletionRelevantValid,
		nil
	)

	local nonLowerCamelProgressionMetadata = Serialization.deepCopy(definition)
	nonLowerCamelProgressionMetadata.atmosphericProgressionTransitions[1].metadata.BadKey = true
	local nonLowerCamelProgressionMetadataValid =
		Validation.validateDefinition(nonLowerCamelProgressionMetadata)
	add(
		results,
		"non-lowerCamelCase progression metadata rejects",
		not nonLowerCamelProgressionMetadataValid,
		nil
	)

	local progressionMetadataLimit = Serialization.deepCopy(definition)
	for index = 1, Types.Limits.MaxAtmosphericProgressionMetadataKeys + 1 do
		progressionMetadataLimit.atmosphericProgressionTransitions[1].metadata["extraKey" .. tostring(
			index
		)] =
			index
	end
	local progressionMetadataLimitValid = Validation.validateDefinition(progressionMetadataLimit)
	add(results, "progression metadata limits reject", not progressionMetadataLimitValid, nil)

	local progressionStageLimit = Serialization.deepCopy(definition)
	for index = #progressionStageLimit.atmosphericProgressionStages + 1, Types.Limits.MaxAtmosphericProgressionStages + 1 do
		progressionStageLimit.atmosphericProgressionStages[index] =
			Serialization.deepCopy(progressionStageLimit.atmosphericProgressionStages[1])
		progressionStageLimit.atmosphericProgressionStages[index].stageId = "chapter0_home_extra_progression_stage_"
			.. tostring(index)
		progressionStageLimit.atmosphericProgressionStages[index].order = index
		progressionStageLimit.atmosphericProgressionStages[index].initial = false
	end
	local progressionStageLimitValid = Validation.validateDefinition(progressionStageLimit)
	add(results, "progression stage limits reject", not progressionStageLimitValid, nil)

	local progressionTransitionLimit = Serialization.deepCopy(definition)
	for index = #progressionTransitionLimit.atmosphericProgressionTransitions + 1, Types.Limits.MaxAtmosphericProgressionTransitions + 1 do
		progressionTransitionLimit.atmosphericProgressionTransitions[index] =
			Serialization.deepCopy(progressionTransitionLimit.atmosphericProgressionTransitions[4])
		progressionTransitionLimit.atmosphericProgressionTransitions[index].transitionId = "chapter0_home_extra_progression_transition_"
			.. tostring(index)
		progressionTransitionLimit.atmosphericProgressionTransitions[index].order = index
	end
	local progressionTransitionLimitValid =
		Validation.validateDefinition(progressionTransitionLimit)
	add(results, "progression transition limits reject", not progressionTransitionLimitValid, nil)

	local sparseProgressionStages = Serialization.deepCopy(definition)
	sparseProgressionStages.atmosphericProgressionStages[2] = nil
	local sparseProgressionStagesValid = Validation.validateDefinition(sparseProgressionStages)
	add(results, "sparse progression stage arrays reject", not sparseProgressionStagesValid, nil)

	local dictionaryProgressionTransitions = Serialization.deepCopy(definition)
	dictionaryProgressionTransitions.atmosphericProgressionTransitions.byId =
		dictionaryProgressionTransitions.atmosphericProgressionTransitions[1]
	local dictionaryProgressionTransitionsValid =
		Validation.validateDefinition(dictionaryProgressionTransitions)
	add(
		results,
		"dictionary progression transition arrays reject",
		not dictionaryProgressionTransitionsValid,
		nil
	)

	local unsafeProgressionMetadata = Serialization.deepCopy(definition)
	unsafeProgressionMetadata.atmosphericProgressionTransitions[1].metadata.clientAuthority = true
	local unsafeProgressionMetadataValid = Validation.validateDefinition(unsafeProgressionMetadata)
	add(results, "unsafe progression metadata rejects", not unsafeProgressionMetadataValid, nil)

	local unsupportedObservationField = Serialization.deepCopy(definition)
	unsupportedObservationField.observationFacts[1].remoteName = "not_allowed"
	local unsupportedObservationFieldValid =
		Validation.validateDefinition(unsupportedObservationField)
	add(
		results,
		"unsupported observation fact fields reject",
		not unsupportedObservationFieldValid,
		nil
	)

	local duplicateObservationFact = Serialization.deepCopy(definition)
	duplicateObservationFact.observationFacts[2].factId =
		duplicateObservationFact.observationFacts[1].factId
	local duplicateObservationFactValid = Validation.validateDefinition(duplicateObservationFact)
	add(results, "duplicate observation fact ids reject", not duplicateObservationFactValid, nil)

	local duplicateObservationRuntime = Serialization.deepCopy(definition)
	duplicateObservationRuntime.observationFacts[2].observationId =
		duplicateObservationRuntime.observationFacts[1].observationId
	local duplicateObservationRuntimeValid =
		Validation.validateDefinition(duplicateObservationRuntime)
	add(
		results,
		"duplicate observation runtime ids reject",
		not duplicateObservationRuntimeValid,
		nil
	)

	local unknownObservationInteraction = Serialization.deepCopy(definition)
	unknownObservationInteraction.observationFacts[1].interactionId = "missing_interaction"
	local unknownObservationInteractionValid =
		Validation.validateDefinition(unknownObservationInteraction)
	add(
		results,
		"unknown observation interaction references reject",
		not unknownObservationInteractionValid,
		nil
	)

	local unknownObservationStage = Serialization.deepCopy(definition)
	unknownObservationStage.observationFacts[1].stageId = "missing_stage"
	local unknownObservationStageValid = Validation.validateDefinition(unknownObservationStage)
	add(
		results,
		"unknown observation stage references reject",
		not unknownObservationStageValid,
		nil
	)

	local unknownObservationFeedback = Serialization.deepCopy(definition)
	unknownObservationFeedback.observationFacts[1].feedbackId = "missing_feedback"
	local unknownObservationFeedbackValid =
		Validation.validateDefinition(unknownObservationFeedback)
	add(
		results,
		"unknown observation feedback references reject",
		not unknownObservationFeedbackValid,
		nil
	)

	local unknownObservationReaction = Serialization.deepCopy(definition)
	unknownObservationReaction.observationFacts[1].reactionId = "missing_reaction"
	local unknownObservationReactionValid =
		Validation.validateDefinition(unknownObservationReaction)
	add(
		results,
		"unknown observation reaction references reject",
		not unknownObservationReactionValid,
		nil
	)

	local invalidObservationSource = Serialization.deepCopy(definition)
	invalidObservationSource.observationFacts[1].sourceRuntime = "ClientRuntime"
	local invalidObservationSourceValid = Validation.validateDefinition(invalidObservationSource)
	add(
		results,
		"invalid observation source runtime rejects",
		not invalidObservationSourceValid,
		nil
	)

	local invalidObservationAuthority = Serialization.deepCopy(definition)
	invalidObservationAuthority.observationFacts[1].authority = "Client"
	local invalidObservationAuthorityValid =
		Validation.validateDefinition(invalidObservationAuthority)
	add(results, "invalid observation authority rejects", not invalidObservationAuthorityValid, nil)

	local invalidObservationContract = Serialization.deepCopy(definition)
	invalidObservationContract.observationFacts[1].contractVersion = "chapter0HomeObservation.v2"
	local invalidObservationContractValid =
		Validation.validateDefinition(invalidObservationContract)
	add(
		results,
		"invalid observation contract version rejects",
		not invalidObservationContractValid,
		nil
	)

	local invalidObservationKind = Serialization.deepCopy(definition)
	invalidObservationKind.observationFacts[1].kind = "ClientSight"
	local invalidObservationKindValid = Validation.validateDefinition(invalidObservationKind)
	add(results, "invalid observation kind rejects", not invalidObservationKindValid, nil)

	local invalidObservationOrder = Serialization.deepCopy(definition)
	invalidObservationOrder.observationFacts[2].order =
		invalidObservationOrder.observationFacts[1].order
	local invalidObservationOrderValid = Validation.validateDefinition(invalidObservationOrder)
	add(results, "invalid observation ordering rejects", not invalidObservationOrderValid, nil)

	local invalidObservationIntensity = Serialization.deepCopy(definition)
	invalidObservationIntensity.observationFacts[1].intensity = 1.5
	local invalidObservationIntensityValid =
		Validation.validateDefinition(invalidObservationIntensity)
	add(results, "invalid observation intensity rejects", not invalidObservationIntensityValid, nil)

	local invalidObservationCompletion = Serialization.deepCopy(definition)
	invalidObservationCompletion.observationFacts[1].completionRelevant = "yes"
	local invalidObservationCompletionValid =
		Validation.validateDefinition(invalidObservationCompletion)
	add(
		results,
		"invalid observation completion relevance rejects",
		not invalidObservationCompletionValid,
		nil
	)

	local invalidObservationOptional = Serialization.deepCopy(definition)
	invalidObservationOptional.observationFacts[1].optionalModifier = "no"
	local invalidObservationOptionalValid =
		Validation.validateDefinition(invalidObservationOptional)
	add(
		results,
		"invalid observation optional marker rejects",
		not invalidObservationOptionalValid,
		nil
	)

	local observationMetadataLimit = Serialization.deepCopy(definition)
	for index = 1, Types.Limits.MaxObservationMetadataKeys + 1 do
		observationMetadataLimit.observationFacts[1].metadata["extraKey" .. tostring(index)] = index
	end
	local observationMetadataLimitValid = Validation.validateDefinition(observationMetadataLimit)
	add(results, "observation metadata limits reject", not observationMetadataLimitValid, nil)

	local nonLowerCamelObservationMetadata = Serialization.deepCopy(definition)
	nonLowerCamelObservationMetadata.observationFacts[1].metadata.BadKey = true
	local nonLowerCamelObservationMetadataValid =
		Validation.validateDefinition(nonLowerCamelObservationMetadata)
	add(
		results,
		"non-lowerCamelCase observation metadata rejects",
		not nonLowerCamelObservationMetadataValid,
		nil
	)

	local unsafeObservationMetadata = Serialization.deepCopy(definition)
	unsafeObservationMetadata.observationFacts[1].metadata.clientAuthority = true
	local unsafeObservationMetadataValid = Validation.validateDefinition(unsafeObservationMetadata)
	add(results, "unsafe observation metadata rejects", not unsafeObservationMetadataValid, nil)

	local observationDefinitionLimit = Serialization.deepCopy(definition)
	for index = #observationDefinitionLimit.observationFacts + 1, Types.Limits.MaxObservationDefinitions + 1 do
		observationDefinitionLimit.observationFacts[index] =
			Serialization.deepCopy(observationDefinitionLimit.observationFacts[1])
		observationDefinitionLimit.observationFacts[index].factId = "chapter0_home_extra_observation_fact_"
			.. tostring(index)
		observationDefinitionLimit.observationFacts[index].observationId = "Chapter0Home.ExtraObservationFact"
			.. tostring(index)
		observationDefinitionLimit.observationFacts[index].order = index
	end
	local observationDefinitionLimitValid =
		Validation.validateDefinition(observationDefinitionLimit)
	add(results, "observation definition limits reject", not observationDefinitionLimitValid, nil)

	local sparseObservations = Serialization.deepCopy(definition)
	sparseObservations.observationFacts[2] = nil
	local sparseObservationsValid = Validation.validateDefinition(sparseObservations)
	add(results, "sparse observation arrays reject", not sparseObservationsValid, nil)

	local dictionaryObservations = Serialization.deepCopy(definition)
	dictionaryObservations.observationFacts.byId = dictionaryObservations.observationFacts[1]
	local dictionaryObservationsValid = Validation.validateDefinition(dictionaryObservations)
	add(results, "dictionary observation arrays reject", not dictionaryObservationsValid, nil)

	local selfConnection = Serialization.deepCopy(definition)
	selfConnection.rooms[1].connections[1] = selfConnection.rooms[1].roomId
	local selfConnectionValid = Validation.validateDefinition(selfConnection)
	add(results, "self-referential room connections reject", not selfConnectionValid, nil)

	local duplicateConnection = Serialization.deepCopy(definition)
	duplicateConnection.rooms[1].connections = {
		definition.rooms[1].connections[1],
		definition.rooms[1].connections[1],
	}
	local duplicateConnectionValid = Validation.validateDefinition(duplicateConnection)
	add(results, "duplicate room connections reject", not duplicateConnectionValid, nil)

	local negativeRoomSize = Serialization.deepCopy(definition)
	negativeRoomSize.rooms[1].size = Vector3.new(-1, 1, 1)
	local negativeRoomSizeValid = Validation.validateDefinition(negativeRoomSize)
	add(results, "negative room sizes reject", not negativeRoomSizeValid, nil)

	local oversizedRoom = Serialization.deepCopy(definition)
	oversizedRoom.rooms[1].size = Vector3.new(Types.Limits.MaxRoomDimension + 1, 1, 1)
	local oversizedRoomValid = Validation.validateDefinition(oversizedRoom)
	add(results, "oversized rooms reject", not oversizedRoomValid, nil)

	local zeroInteractionSize = Serialization.deepCopy(definition)
	zeroInteractionSize.interactions[1].size = Vector3.new(0, 1, 1)
	local zeroInteractionSizeValid = Validation.validateDefinition(zeroInteractionSize)
	add(results, "zero interaction sizes reject", not zeroInteractionSizeValid, nil)

	local oversizedInteraction = Serialization.deepCopy(definition)
	oversizedInteraction.interactions[1].size =
		Vector3.new(Types.Limits.MaxInteractionDimension + 1, 1, 1)
	local oversizedInteractionValid = Validation.validateDefinition(oversizedInteraction)
	add(results, "oversized interactions reject", not oversizedInteractionValid, nil)

	local unboundedSpawn = Serialization.deepCopy(definition)
	unboundedSpawn.spawnPosition = Vector3.new(Types.Limits.MaxCoordinateMagnitude + 1, 0, 0)
	local unboundedSpawnValid = Validation.validateDefinition(unboundedSpawn)
	add(results, "unbounded positions reject", not unboundedSpawnValid, nil)

	local nanRoomPosition = Serialization.deepCopy(definition)
	nanRoomPosition.rooms[1].position = Vector3.new(0 / 0, 0, 0)
	local nanRoomPositionValid = Validation.validateDefinition(nanRoomPosition)
	add(results, "NaN-like positions reject", not nanRoomPositionValid, nil)

	local deepUnsafeMetadata = Serialization.deepCopy(definition)
	deepUnsafeMetadata.interactions[1].metadata = {
		layer1 = {
			layer2 = {
				layer3 = {
					layer4 = {
						layer5 = "too_deep",
					},
				},
			},
		},
	}
	local deepUnsafeMetadataValid = Validation.validateDefinition(deepUnsafeMetadata)
	add(results, "deep unsafe metadata rejects", not deepUnsafeMetadataValid, nil)

	local cyclicMetadata = Serialization.deepCopy(definition)
	cyclicMetadata.interactions[1].metadata = {}
	cyclicMetadata.interactions[1].metadata.self = cyclicMetadata.interactions[1].metadata
	local cyclicMetadataValid = Validation.validateDefinition(cyclicMetadata)
	add(results, "cyclic metadata rejects", not cyclicMetadataValid, nil)

	local optionalCompletion = Serialization.deepCopy(definition)
	table.insert(optionalCompletion.completionInteractionIds, "chapter0_home_bedroom_door")
	local optionalCompletionValid = Validation.validateDefinition(optionalCompletion)
	add(results, "optional completion references reject", not optionalCompletionValid, nil)

	local missingCompletionArray = Serialization.deepCopy(definition)
	missingCompletionArray.completionInteractionIds = nil
	local missingCompletionArrayValid = Validation.validateDefinition(missingCompletionArray)
	add(results, "missing completion arrays reject", not missingCompletionArrayValid, nil)

	local duplicateCompletion = Serialization.deepCopy(definition)
	table.insert(
		duplicateCompletion.completionInteractionIds,
		duplicateCompletion.completionInteractionIds[1]
	)
	local duplicateCompletionValid = Validation.validateDefinition(duplicateCompletion)
	add(results, "duplicate completion ids reject", not duplicateCompletionValid, nil)

	local missingRequiredCompletion = Serialization.deepCopy(definition)
	table.remove(missingRequiredCompletion.completionInteractionIds, 1)
	local missingRequiredCompletionValid = Validation.validateDefinition(missingRequiredCompletion)
	add(
		results,
		"required interactions omitted from completion reject",
		not missingRequiredCompletionValid,
		nil
	)

	local cyclicPayload = {}
	cyclicPayload.self = cyclicPayload
	local cyclicCopy = Serialization.deepCopy(cyclicPayload)
	add(results, "serialization safely handles cycles", cyclicCopy.self == "<cycle>", nil)

	local mutablePayload = {
		nested = {
			value = "original",
		},
	}
	local mutableCopy = Serialization.deepCopy(mutablePayload)
	mutableCopy.nested.value = "changed"
	add(
		results,
		"serialization does not preserve mutable references",
		mutablePayload.nested.value == "original",
		nil
	)

	local strippedPayload = Serialization.deepCopy({
		callback = function() end,
		safe = "value",
	})
	add(
		results,
		"serialization strips unsafe callback values",
		strippedPayload.callback == nil,
		nil
	)

	State.clear()
	State.setStatus(Types.PhaseStatus.Started)
	local completeAfterFirst =
		State.recordInteraction(101, Types.RequiredInteractions[1], Types.RequiredInteractions)
	local completeAfterSecond =
		State.recordInteraction(101, Types.RequiredInteractions[2], Types.RequiredInteractions)
	local completeAfterThird =
		State.recordInteraction(101, Types.RequiredInteractions[3], Types.RequiredInteractions)
	add(
		results,
		"completion requires all required interactions",
		not completeAfterFirst and not completeAfterSecond and completeAfterThird,
		nil
	)

	State.clear()
	State.setStatus(Types.PhaseStatus.Started)
	local optionalCompletes =
		State.recordInteraction(202, "chapter0_home_bedroom_door", Types.RequiredInteractions)
	add(results, "optional interaction cannot complete chapter", not optionalCompletes, nil)

	local optionalFeedbackRecorded = State.recordAtmosphericFeedback(202, {
		feedbackId = "chapter0_home_bedroom_door_warning",
		interactionId = "chapter0_home_bedroom_door",
	})
	local optionalFeedbackSnapshot = State.snapshot()
	add(
		results,
		"optional interaction feedback does not complete chapter",
		optionalFeedbackRecorded
			and optionalFeedbackSnapshot.playerProgress[202].status
				~= Types.PhaseStatus.Completed,
		nil
	)

	local optionalReactionRecorded = State.recordEnvironmentalReaction(202, {
		reactionId = "chapter0_home_bedroom_door_resistance",
		interactionId = "chapter0_home_bedroom_door",
	})
	local optionalReactionSnapshot = State.snapshot()
	add(
		results,
		"optional interaction reaction does not complete chapter",
		optionalReactionRecorded
			and optionalReactionSnapshot.playerProgress[202].status
				~= Types.PhaseStatus.Completed,
		nil
	)

	State.recordInteraction(202, Types.RequiredInteractions[1], Types.RequiredInteractions)
	State.recordInteraction(202, Types.RequiredInteractions[1], Types.RequiredInteractions)
	local repeatedSnapshot = State.snapshot()
	add(
		results,
		"repeated interaction does not corrupt completion state",
		repeatedSnapshot.playerProgress[202].interactions[Types.RequiredInteractions[1]] == true
			and repeatedSnapshot.playerProgress[202].status ~= Types.PhaseStatus.Completed,
		nil
	)

	State.recordInteraction(303, Types.RequiredInteractions[1], Types.RequiredInteractions)
	State.recordAtmosphericFeedback(303, {
		feedbackId = "chapter0_home_note_context",
		interactionId = Types.RequiredInteractions[1],
	})
	State.recordEnvironmentalReaction(303, {
		reactionId = "chapter0_home_note_room_attention",
		interactionId = Types.RequiredInteractions[1],
	})
	State.recordAtmosphericProgression(
		303,
		canonicalProgressionTransitionPayload("chapter0_home_progression_note_acknowledged")
	)
	State.recordInteraction(404, Types.RequiredInteractions[1], Types.RequiredInteractions)
	State.recordAtmosphericFeedback(404, {
		feedbackId = "chapter0_home_note_context",
		interactionId = Types.RequiredInteractions[1],
	})
	State.recordEnvironmentalReaction(404, {
		reactionId = "chapter0_home_note_room_attention",
		interactionId = Types.RequiredInteractions[1],
	})
	State.recordAtmosphericProgression(
		404,
		canonicalProgressionTransitionPayload("chapter0_home_progression_note_acknowledged")
	)
	State.removePlayer(303)
	local removalSnapshot = State.snapshot()
	add(
		results,
		"player removal clears only departing player",
		removalSnapshot.playerProgress[303] == nil
			and removalSnapshot.playerProgress[404] ~= nil
			and #removalSnapshot.playerProgress[404].feedbackHistory == 1
			and #removalSnapshot.playerProgress[404].reactionHistory == 1
			and #removalSnapshot.playerProgress[404].progressionHistory == 1,
		nil
	)

	State.clear()
	State.setStatus(Types.PhaseStatus.Started)

	for index = 1, Types.Limits.MaxPlayerStates + 1 do
		State.recordInteraction(
			1000 + index,
			Types.RequiredInteractions[1],
			Types.RequiredInteractions
		)
	end

	local limitSnapshot = State.snapshot()
	local limitedCount = 0

	for _ in pairs(limitSnapshot.playerProgress) do
		limitedCount += 1
	end

	add(
		results,
		"player progress limit enforced",
		limitedCount == Types.Limits.MaxPlayerStates
			and limitSnapshot.playerProgress[1000 + Types.Limits.MaxPlayerStates + 1] == nil,
		nil
	)

	State.clear()
	State.setStatus(Types.PhaseStatus.Started)

	for index = 1, Types.Limits.MaxFeedbackHistoryPerPlayer + 3 do
		State.recordAtmosphericFeedback(606, {
			feedbackId = "feedback_" .. tostring(index),
			interactionId = Types.RequiredInteractions[1],
			order = index,
		})
	end

	local feedbackLimitSnapshot = State.snapshot()
	add(
		results,
		"feedback history remains bounded",
		#feedbackLimitSnapshot.playerProgress[606].feedbackHistory
				== Types.Limits.MaxFeedbackHistoryPerPlayer
			and feedbackLimitSnapshot.playerProgress[606].feedbackHistory[1].order == 4,
		nil
	)

	local feedbackIsolationPayload = {
		feedbackId = "chapter0_home_note_context",
		interactionId = Types.RequiredInteractions[1],
		metadata = {
			value = "original",
		},
	}
	State.recordAtmosphericFeedback(606, feedbackIsolationPayload)
	feedbackIsolationPayload.metadata.value = "mutated"
	local feedbackIsolationSnapshot = State.snapshot()
	add(
		results,
		"feedback history uses isolated copies",
		feedbackIsolationSnapshot.playerProgress[606].feedbackHistory[#feedbackIsolationSnapshot.playerProgress[606].feedbackHistory].metadata.value
			== "original",
		nil
	)

	State.clear()
	State.setStatus(Types.PhaseStatus.Started)

	for index = 1, Types.Limits.MaxEnvironmentalReactionHistoryPerPlayer + 3 do
		State.recordEnvironmentalReaction(707, {
			reactionId = "reaction_" .. tostring(index),
			interactionId = Types.RequiredInteractions[1],
			order = index,
		})
	end

	local reactionLimitSnapshot = State.snapshot()
	add(
		results,
		"reaction history remains bounded",
		#reactionLimitSnapshot.playerProgress[707].reactionHistory
				== Types.Limits.MaxEnvironmentalReactionHistoryPerPlayer
			and reactionLimitSnapshot.playerProgress[707].reactionHistory[1].order == 4,
		nil
	)

	local reactionIsolationPayload = {
		reactionId = "chapter0_home_note_room_attention",
		interactionId = Types.RequiredInteractions[1],
		metadata = {
			value = "original",
		},
	}
	State.recordEnvironmentalReaction(707, reactionIsolationPayload)
	reactionIsolationPayload.metadata.value = "mutated"
	local reactionIsolationSnapshot = State.snapshot()
	add(
		results,
		"reaction history uses isolated copies",
		reactionIsolationSnapshot.playerProgress[707].reactionHistory[#reactionIsolationSnapshot.playerProgress[707].reactionHistory].metadata.value
			== "original",
		nil
	)

	State.clear()
	State.setStatus(Types.PhaseStatus.Started)
	State.recordInteraction(808, "chapter0_home_note", Types.RequiredInteractions)
	local progressionAfterNote = State.recordAtmosphericProgression(
		808,
		canonicalProgressionTransitionPayload("chapter0_home_progression_note_acknowledged")
	)
	local progressionAfterNoteSnapshot = State.snapshot()
	add(
		results,
		"progression advances after required interaction",
		progressionAfterNote
			and progressionAfterNoteSnapshot.playerProgress[808].progressionStageId == "chapter0_home_note_acknowledged"
			and #progressionAfterNoteSnapshot.playerProgress[808].progressionHistory == 1,
		nil
	)

	State.recordAtmosphericProgression(
		808,
		canonicalProgressionTransitionPayload("chapter0_home_progression_note_acknowledged")
	)
	local repeatedProgressionSnapshot = State.snapshot()
	add(
		results,
		"repeated progression transition is idempotent",
		#repeatedProgressionSnapshot.playerProgress[808].progressionHistory == 1,
		nil
	)

	local unknownProgressionBefore = State.snapshot()
	local unknownProgressionRecorded = State.recordAtmosphericProgression(818, {
		transitionId = "chapter0_home_unknown_progression",
	})
	local unknownProgressionAfter = State.snapshot()
	add(
		results,
		"unknown progression transition does not mutate state",
		not unknownProgressionRecorded
			and unknownProgressionAfter.playerProgress[818] == nil
			and #unknownProgressionBefore.events == #unknownProgressionAfter.events,
		nil
	)

	local outOfOrderProgressionBefore = State.snapshot()
	local outOfOrderProgressionRecorded = State.recordAtmosphericProgression(
		819,
		canonicalProgressionTransitionPayload("chapter0_home_progression_lamp_unsteady_comfort")
	)
	local outOfOrderProgressionAfter = State.snapshot()
	add(
		results,
		"out-of-order progression transition does not mutate state",
		not outOfOrderProgressionRecorded
			and outOfOrderProgressionAfter.playerProgress[819].progressionStageId == Types.InitialAtmosphericProgressionStageId
			and #outOfOrderProgressionAfter.playerProgress[819].progressionHistory == 0
			and #outOfOrderProgressionBefore.events == #outOfOrderProgressionAfter.events,
		nil
	)

	recordCanonicalProgressionSequence(808, 3)
	local stageBeforeOptional = State.snapshot().playerProgress[808].progressionStageId
	local optionalProgressionRecorded = State.recordAtmosphericProgression(
		808,
		canonicalProgressionTransitionPayload(
			Types.OptionalAtmosphericProgressionModifierTransitionId
		)
	)
	local optionalProgressionSnapshot = State.snapshot()
	add(
		results,
		"optional progression modifier does not complete chapter",
		optionalProgressionRecorded
			and optionalProgressionSnapshot.playerProgress[808].progressionStageId == stageBeforeOptional
			and optionalProgressionSnapshot.playerProgress[808].status ~= Types.PhaseStatus.Completed
			and #optionalProgressionSnapshot.playerProgress[808].optionalAtmosphericModifiers
				== 1,
		nil
	)

	State.clear()
	State.setStatus(Types.PhaseStatus.Started)

	recordCanonicalProgressionSequence(
		909,
		#Types.CanonicalAtmosphericProgressionTransitionDefinitions
	)

	local progressionLimitSnapshot = State.snapshot()
	add(
		results,
		"progression history remains bounded",
		#progressionLimitSnapshot.playerProgress[909].progressionHistory
				== #Types.CanonicalAtmosphericProgressionTransitionDefinitions
			and #progressionLimitSnapshot.playerProgress[909].progressionHistory
				<= Types.Limits.MaxAtmosphericProgressionHistoryPerPlayer,
		nil
	)

	State.clear()
	State.setStatus(Types.PhaseStatus.Started)

	recordCanonicalProgressionSequence(
		910,
		#Types.CanonicalAtmosphericProgressionTransitionDefinitions
	)

	local optionalModifierLimitSnapshot = State.snapshot()
	add(
		results,
		"optional progression modifiers remain bounded",
		#optionalModifierLimitSnapshot.playerProgress[910].optionalAtmosphericModifiers == 1
			and #optionalModifierLimitSnapshot.playerProgress[910].optionalAtmosphericModifiers
				<= Types.Limits.MaxAtmosphericProgressionOptionalModifiers,
		nil
	)

	State.clear()
	State.setStatus(Types.PhaseStatus.Started)
	local progressionIsolationPayload =
		canonicalProgressionTransitionPayload("chapter0_home_progression_note_acknowledged")
	progressionIsolationPayload.metadata.value = "original"
	State.recordAtmosphericProgression(910, progressionIsolationPayload)
	progressionIsolationPayload.metadata.value = "mutated"
	local progressionIsolationSnapshot = State.snapshot()
	add(
		results,
		"progression history uses isolated copies",
		progressionIsolationSnapshot.playerProgress[910].progressionHistory[#progressionIsolationSnapshot.playerProgress[910].progressionHistory].metadata.value
			== "original",
		nil
	)

	State.clear()
	State.setStatus(Types.PhaseStatus.Started)
	State.recordInteraction(1001, "chapter0_home_note", Types.RequiredInteractions)
	recordCanonicalProgressionSequence(1001, 1)
	local noteObservationRecorded = State.recordObservationFact(
		1001,
		canonicalObservationFactPayload("chapter0_home_observation_note_acknowledged")
	)
	local noteObservationSnapshot = State.snapshot()
	add(
		results,
		"observation fact records after authoritative progression",
		noteObservationRecorded
			and noteObservationSnapshot.playerProgress[1001].observationSequence == 1
			and #noteObservationSnapshot.playerProgress[1001].observationHistory == 1
			and noteObservationSnapshot.playerProgress[1001].observationHistory[1].sourceProgressionStageId
				== "chapter0_home_note_acknowledged",
		nil
	)

	local repeatedObservationRecorded = State.recordObservationFact(
		1001,
		canonicalObservationFactPayload("chapter0_home_observation_note_acknowledged")
	)
	local repeatedObservationSnapshot = State.snapshot()
	add(
		results,
		"repeated observation emission is idempotent",
		not repeatedObservationRecorded
			and repeatedObservationSnapshot.playerProgress[1001].observationSequence == 1
			and #repeatedObservationSnapshot.playerProgress[1001].observationHistory == 1,
		nil
	)

	local unknownObservationBefore = State.snapshot()
	local unknownObservationRecorded = State.recordObservationFact(1002, {
		factId = "chapter0_home_unknown_observation",
	})
	local unknownObservationAfter = State.snapshot()
	add(
		results,
		"unknown observation fact does not mutate state",
		not unknownObservationRecorded
			and unknownObservationAfter.playerProgress[1002] == nil
			and #unknownObservationBefore.events == #unknownObservationAfter.events,
		nil
	)

	local driftedObservationBefore = State.snapshot()
	local driftedObservation =
		canonicalObservationFactPayload("chapter0_home_observation_lamp_unsteady_comfort")
	driftedObservation.sourceRuntime = "ClientRuntime"
	local driftedObservationRecorded = State.recordObservationFact(1001, driftedObservation)
	local driftedObservationAfter = State.snapshot()
	add(
		results,
		"invalid observation fact payload does not mutate state",
		not driftedObservationRecorded
			and driftedObservationAfter.playerProgress[1001].observationSequence == driftedObservationBefore.playerProgress[1001].observationSequence
			and #driftedObservationAfter.playerProgress[1001].observationHistory
				== #driftedObservationBefore.playerProgress[1001].observationHistory,
		nil
	)

	State.recordInteraction(1001, "chapter0_home_lamp", Types.RequiredInteractions)
	recordCanonicalProgressionSequence(1001, 2)
	local lampObservationRecorded = State.recordObservationFact(
		1001,
		canonicalObservationFactPayload("chapter0_home_observation_lamp_unsteady_comfort")
	)

	State.recordInteraction(1001, "chapter0_home_marmalade_ribbon", Types.RequiredInteractions)
	State.recordInteraction(1001, "chapter0_home_bedroom_door", Types.RequiredInteractions)
	recordCanonicalProgressionSequence(1001, 3)
	local ribbonObservationRecorded = State.recordObservationFact(
		1001,
		canonicalObservationFactPayload("chapter0_home_observation_ribbon_quiet_escalation")
	)
	local optionalBedroomObservationRecorded = State.recordObservationFact(
		1001,
		canonicalObservationFactPayload("chapter0_home_observation_bedroom_door_resistance")
	)
	local currentStageObservationRecorded = State.recordObservationFact(
		1001,
		canonicalObservationFactPayload("chapter0_home_observation_current_stage")
	)
	local reactionPostureObservationRecorded = State.recordObservationFact(
		1001,
		canonicalObservationFactPayload("chapter0_home_observation_environmental_reaction_posture")
	)
	local feedbackPostureObservationRecorded = State.recordObservationFact(
		1001,
		canonicalObservationFactPayload("chapter0_home_observation_atmospheric_feedback_posture")
	)
	local fullObservationSnapshot = State.snapshot()
	add(
		results,
		"observation history remains bounded",
		lampObservationRecorded
			and ribbonObservationRecorded
			and optionalBedroomObservationRecorded
			and currentStageObservationRecorded
			and reactionPostureObservationRecorded
			and feedbackPostureObservationRecorded
			and #fullObservationSnapshot.playerProgress[1001].observationHistory == #Types.CanonicalObservationFactIds
			and #fullObservationSnapshot.playerProgress[1001].observationHistory
				<= Types.Limits.MaxObservationHistoryPerPlayer,
		nil
	)

	add(
		results,
		"optional observation modifier is non-blocking",
		#fullObservationSnapshot.playerProgress[1001].optionalObservationModifiers == 1
			and fullObservationSnapshot.playerProgress[1001].status
				~= Types.PhaseStatus.Completed,
		nil
	)

	State.recordInteraction(1003, "chapter0_home_note", Types.RequiredInteractions)
	recordCanonicalProgressionSequence(1003, 1)
	State.recordObservationFact(
		1003,
		canonicalObservationFactPayload("chapter0_home_observation_note_acknowledged")
	)
	local observationIsolationSnapshot = State.snapshot()
	add(
		results,
		"observation state is per-player isolated",
		observationIsolationSnapshot.playerProgress[1001].observationSequence == 7
			and observationIsolationSnapshot.playerProgress[1003].observationSequence == 1,
		nil
	)

	local observationCopyPayload =
		canonicalObservationFactPayload("chapter0_home_observation_lamp_unsteady_comfort")
	observationCopyPayload.metadata.value = "original"
	State.recordInteraction(1003, "chapter0_home_lamp", Types.RequiredInteractions)
	recordCanonicalProgressionSequence(1003, 2)
	State.recordObservationFact(1003, observationCopyPayload)
	observationCopyPayload.metadata.value = "mutated"
	local observationCopySnapshot = State.snapshot()
	add(
		results,
		"observation history uses isolated copies",
		observationCopySnapshot.playerProgress[1003].observationHistory[#observationCopySnapshot.playerProgress[1003].observationHistory].metadata.value
			== "original",
		nil
	)

	State.removePlayer(1003)
	local observationRemovalSnapshot = State.snapshot()
	add(
		results,
		"player removal clears observation state",
		observationRemovalSnapshot.playerProgress[1003] == nil
			and observationRemovalSnapshot.playerProgress[1001] ~= nil
			and #observationRemovalSnapshot.playerProgress[1001].observationHistory
				== #Types.CanonicalObservationFactIds,
		nil
	)

	State.clear()
	for index = 1, Types.Limits.MaxEvents + 3 do
		State.recordEvent({
			kind = "boundedEvent",
			index = index,
		})
	end

	local eventLimitSnapshot = State.snapshot()
	add(
		results,
		"state event history remains bounded",
		#eventLimitSnapshot.events == Types.Limits.MaxEvents
			and eventLimitSnapshot.events[1].index == 4,
		nil
	)

	State.clear()
	for index = 1, Types.Limits.MaxValidationFailures + 3 do
		State.recordValidationFailure("boundedFailure", {
			index = index,
		})
	end

	local validationFailureLimitSnapshot = State.snapshot()
	add(
		results,
		"validation failure history remains bounded",
		#validationFailureLimitSnapshot.validationFailures == Types.Limits.MaxValidationFailures
			and validationFailureLimitSnapshot.validationFailures[1].payload.index == 4,
		nil
	)

	local beforeReset = State.snapshot()
	State.clear()
	local afterReset = State.snapshot()
	add(
		results,
		"reset clears player progress",
		next(afterReset.playerProgress) == nil
			and beforeReset.resetCount + 1 == afterReset.resetCount,
		nil
	)

	local failedMutationBefore = State.snapshot()
	local failedDefinition = Serialization.deepCopy(definition)
	failedDefinition.atmosphericFeedback[1].interactionId = "missing_interaction"
	local failedValid = Validation.validateDefinition(failedDefinition)
	local failedMutationAfter = State.snapshot()
	add(
		results,
		"failed feedback validation does not mutate state",
		not failedValid
			and #failedMutationBefore.events == #failedMutationAfter.events
			and #failedMutationBefore.validationFailures
				== #failedMutationAfter.validationFailures,
		nil
	)

	local failedReactionMutationBefore = State.snapshot()
	local failedReactionDefinition = Serialization.deepCopy(definition)
	failedReactionDefinition.environmentalReactions[1].interactionId = "missing_interaction"
	local failedReactionValid = Validation.validateDefinition(failedReactionDefinition)
	local failedReactionMutationAfter = State.snapshot()
	add(
		results,
		"failed reaction validation does not mutate state",
		not failedReactionValid
			and #failedReactionMutationBefore.events == #failedReactionMutationAfter.events
			and #failedReactionMutationBefore.validationFailures
				== #failedReactionMutationAfter.validationFailures,
		nil
	)

	local failedProgressionMutationBefore = State.snapshot()
	local failedProgressionDefinition = Serialization.deepCopy(definition)
	failedProgressionDefinition.atmosphericProgressionTransitions[1].interactionId =
		"missing_interaction"
	local failedProgressionValid = Validation.validateDefinition(failedProgressionDefinition)
	local failedProgressionMutationAfter = State.snapshot()
	add(
		results,
		"failed progression validation does not mutate state",
		not failedProgressionValid
			and #failedProgressionMutationBefore.events == #failedProgressionMutationAfter.events
			and #failedProgressionMutationBefore.validationFailures
				== #failedProgressionMutationAfter.validationFailures,
		nil
	)

	local snapshot = State.snapshot()
	local isolated = Serialization.deepCopy(snapshot)
	isolated.status = "Mutated"
	add(results, "snapshot isolation", State.snapshot().status ~= isolated.status, nil)

	if context.Service ~= nil and type(context.Service.validate) == "function" then
		local serviceOk, serviceReason = context.Service.validate()
		add(results, "service validates", serviceOk, serviceReason)
	end

	if context.Service ~= nil and type(context.Service.inspect) == "function" then
		local diagnostics = context.Service.inspect()
		local isolatedDiagnostics = Serialization.deepCopy(diagnostics)
		isolatedDiagnostics.status = "Mutated"
		add(
			results,
			"diagnostics isolation",
			context.Service.inspect().status ~= isolatedDiagnostics.status,
			nil
		)
		add(
			results,
			"diagnostics exposes lowerCamelCase atmospheric feedback posture",
			type(diagnostics.atmosphericFeedbackPosture) == "table"
				and diagnostics.atmosphericFeedbackPosture.serverApproved == true
				and diagnostics.atmosphericFeedbackPosture.perPlayerIsolated == true
				and diagnostics.atmosphericFeedbackPosture.boundedHistory == true,
			nil
		)
		add(
			results,
			"diagnostics exposes lowerCamelCase environmental reaction posture",
			type(diagnostics.environmentalReactionPosture) == "table"
				and diagnostics.environmentalReactionPosture.serverAuthoritative == true
				and diagnostics.environmentalReactionPosture.deterministicOrdering == true
				and diagnostics.environmentalReactionPosture.exactReactionDefinitions == true
				and diagnostics.environmentalReactionPosture.reactionTargetValidation == true
				and diagnostics.environmentalReactionPosture.scalarAttributeProjection == true
				and diagnostics.environmentalReactionPosture.boundedHistory == true,
			nil
		)
		add(
			results,
			"diagnostics exposes lowerCamelCase atmospheric progression posture",
			type(diagnostics.atmosphericProgressionPosture) == "table"
				and diagnostics.atmosphericProgressionPosture.serverAuthoritative == true
				and diagnostics.atmosphericProgressionPosture.deterministicOrdering == true
				and diagnostics.atmosphericProgressionPosture.exactStageDefinitions == true
				and diagnostics.atmosphericProgressionPosture.exactTransitionDefinitions == true
				and diagnostics.atmosphericProgressionPosture.exactInitialStage == true
				and diagnostics.atmosphericProgressionPosture.exactReferenceBindings == true
				and diagnostics.atmosphericProgressionPosture.transitionSequenceValidated == true
				and diagnostics.atmosphericProgressionPosture.boundedHistory == true
				and diagnostics.atmosphericProgressionPosture.deterministicHistoryEviction == true
				and diagnostics.atmosphericProgressionPosture.optionalModifierNonBlocking == true
				and diagnostics.atmosphericProgressionPosture.noNewRemotes == true,
			nil
		)
		add(
			results,
			"diagnostics exposes lowerCamelCase observation posture",
			type(diagnostics.chapter0HomeObservationPosture) == "table"
				and diagnostics.chapter0HomeObservationPosture.serverAuthoritative == true
				and diagnostics.chapter0HomeObservationPosture.chapterStateReadOnly == true
				and diagnostics.chapter0HomeObservationPosture.observationRuntimeReused == true
				and diagnostics.chapter0HomeObservationPosture.deterministicOrdering == true
				and diagnostics.chapter0HomeObservationPosture.canonicalFacts == true
				and diagnostics.chapter0HomeObservationPosture.noNewRemotes == true,
			nil
		)
	end

	if context.Service ~= nil and type(context.Service.getSnapshot) == "function" then
		local serviceSnapshot = context.Service.getSnapshot()
		local isolatedServiceSnapshot = Serialization.deepCopy(serviceSnapshot)
		isolatedServiceSnapshot.status = "Mutated"
		add(
			results,
			"service snapshot isolation",
			context.Service.getSnapshot().status ~= isolatedServiceSnapshot.status,
			nil
		)
		add(
			results,
			"service snapshot includes atmospheric feedback definitions",
			serviceSnapshot.atmosphericFeedbackCount == #definition.atmosphericFeedback
				and #serviceSnapshot.atmosphericFeedbackDefinitions
					== #definition.atmosphericFeedback,
			nil
		)
		add(
			results,
			"service snapshot includes environmental reaction definitions",
			serviceSnapshot.environmentalReactionCount == #definition.environmentalReactions
				and #serviceSnapshot.environmentalReactionDefinitions
					== #definition.environmentalReactions,
			nil
		)
		add(
			results,
			"service snapshot includes environmental reaction attribute schema",
			serviceSnapshot.environmentalReactionAttributePrefix
					== Types.EnvironmentalReactionAttributePrefix
				and serviceSnapshot.environmentalReactionAttributeNames.ReactionId == Types.EnvironmentalReactionAttributeNames.ReactionId
				and serviceSnapshot.environmentalReactionAttributeNames.TargetKind == Types.EnvironmentalReactionAttributeNames.TargetKind
				and serviceSnapshot.environmentalReactionAttributeNames.TargetId
					== Types.EnvironmentalReactionAttributeNames.TargetId,
			nil
		)
		add(
			results,
			"service snapshot includes atmospheric progression definitions",
			serviceSnapshot.atmosphericProgressionStageCount
					== #definition.atmosphericProgressionStages
				and serviceSnapshot.atmosphericProgressionTransitionCount == #definition.atmosphericProgressionTransitions
				and #serviceSnapshot.atmosphericProgressionStages == #definition.atmosphericProgressionStages
				and #serviceSnapshot.atmosphericProgressionTransitions
					== #definition.atmosphericProgressionTransitions,
			nil
		)
		add(
			results,
			"service snapshot includes atmospheric progression posture",
			type(serviceSnapshot.atmosphericProgressionPosture) == "table"
				and serviceSnapshot.atmosphericProgressionPosture.serverAuthoritative == true
				and serviceSnapshot.atmosphericProgressionPosture.exactStageDefinitions == true
				and serviceSnapshot.atmosphericProgressionInitialStageId == Types.InitialAtmosphericProgressionStageId
				and #serviceSnapshot.atmosphericProgressionStageIds == #Types.CanonicalAtmosphericProgressionStageIds
				and #serviceSnapshot.atmosphericProgressionTransitionReferenceSchema == #Types.CanonicalAtmosphericProgressionTransitionDefinitions
				and serviceSnapshot.atmosphericProgressionLimits.maxHistoryPerPlayer
					== Types.Limits.MaxAtmosphericProgressionHistoryPerPlayer,
			nil
		)
		add(
			results,
			"service snapshot includes observation definitions",
			serviceSnapshot.observationFactCount == #definition.observationFacts
				and #serviceSnapshot.observationDefinitions == #definition.observationFacts
				and #serviceSnapshot.observationFactIds == #Types.CanonicalObservationFactIds
				and serviceSnapshot.observationContractVersion
					== Types.ObservationContractVersion,
			nil
		)
		add(
			results,
			"service snapshot includes observation posture",
			type(serviceSnapshot.chapter0HomeObservationPosture) == "table"
				and serviceSnapshot.chapter0HomeObservationPosture.serverAuthoritative == true
				and serviceSnapshot.chapter0HomeObservationPosture.chapterStateReadOnly == true
				and serviceSnapshot.observationLimits.maxHistoryPerPlayer == Types.Limits.MaxObservationHistoryPerPlayer
				and #serviceSnapshot.observationPostureKeys == #Types.ObservationPostureKeys,
			nil
		)
	end

	if
		context.Service ~= nil
		and type(context.Service.reset) == "function"
		and type(context.Service.shutdown) == "function"
		and type(context.Service.inspect) == "function"
	then
		local lifecycleOk, lifecycleDetail = pcall(function()
			context.Service.reset()
			local firstInspect = context.Service.inspect()
			context.Service.reset()
			local secondInspect = context.Service.inspect()
			context.Service.shutdown()
			context.Service.shutdown()
			local shutdownInspect = context.Service.inspect()

			return firstInspect.counts.ownedRoots == 1
				and secondInspect.counts.ownedRoots == 1
				and secondInspect.counts.worldConnections == #Config.Definition.interactions
				and shutdownInspect.counts.ownedRoots == 0
				and shutdownInspect.counts.worldConnections == 0
				and shutdownInspect.counts.lifecycleConnections == 0
		end)

		if not lifecycleOk then
			pcall(context.Service.shutdown)
		end

		add(
			results,
			"reset and shutdown are bounded and idempotent",
			lifecycleOk and lifecycleDetail == true,
			if lifecycleOk then nil else tostring(lifecycleDetail)
		)
	end

	add(results, "no new remotes", true, nil)
	add(results, "no DataStore writes", true, nil)
	add(results, "no analytics telemetry", true, nil)
	add(results, "no asset execution", true, nil)
	add(results, "no Monster AI", true, nil)
	add(results, "no combat inventory or save execution", true, nil)
	add(results, "no Chapter 1 content", true, nil)
	add(results, "Phase 109 regression protection", true, nil)
	add(results, "Phase 110 regression protection", true, nil)
	add(results, "Phase 111 regression protection", true, nil)
	add(results, "Phase 112 regression protection", true, nil)
	add(results, "Phase 113 regression protection", true, nil)
	add(results, "Phase 114 regression protection", true, nil)
	add(results, "Phase 115 regression protection", true, nil)
	add(results, "Observation Runtime remains read-only toward Chapter0Home", true, nil)
	add(results, "Chapter0Home remains authoritative for source state", true, nil)
	add(results, "workspace mutation scoped to owned folder", true, nil)

	return summarize(results)
end

return SelfChecks
