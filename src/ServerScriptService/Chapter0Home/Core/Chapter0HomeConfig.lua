--!strict

local Types = require(script.Parent.Chapter0HomeTypes)

local Config = {}

local function deepCopy(value: any): any
	if type(value) ~= "table" then
		return value
	end

	local copied = {}

	for key, child in pairs(value) do
		copied[key] = deepCopy(child)
	end

	return copied
end

Config.Definition = {
	chapterId = Types.ChapterId,
	displayName = "Chapter 0: Home",
	spawnPosition = Vector3.new(0, 4, 0),
	rooms = {
		{
			roomId = "chapter0_home_sitting_room",
			displayName = "Sitting Room",
			kind = Types.RoomKind.Apartment,
			position = Vector3.new(0, 0, 0),
			size = Vector3.new(28, 1, 20),
			connections = { "chapter0_home_hall" },
		},
		{
			roomId = "chapter0_home_hall",
			displayName = "Hall",
			kind = Types.RoomKind.Hall,
			position = Vector3.new(0, 0, -18),
			size = Vector3.new(12, 1, 16),
			connections = { "chapter0_home_sitting_room", "chapter0_home_bedroom" },
		},
		{
			roomId = "chapter0_home_bedroom",
			displayName = "Bedroom Door",
			kind = Types.RoomKind.Bedroom,
			position = Vector3.new(0, 0, -34),
			size = Vector3.new(18, 1, 14),
			connections = { "chapter0_home_hall" },
		},
	},
	interactions = {
		{
			interactionId = "chapter0_home_note",
			roomId = "chapter0_home_sitting_room",
			kind = Types.InteractionKind.Note,
			prompt = "Read Mum's note",
			position = Vector3.new(-6, 2, -2),
			size = Vector3.new(3, 0.25, 2),
			requiredForCompletion = true,
			metadata = {
				dialogueKey = "chapter0.home.mum_note",
				presentationCue = "note_open",
			},
		},
		{
			interactionId = "chapter0_home_lamp",
			roomId = "chapter0_home_sitting_room",
			kind = Types.InteractionKind.Switch,
			prompt = "Turn the gas lamp",
			position = Vector3.new(7, 3, 3),
			size = Vector3.new(2, 3, 2),
			requiredForCompletion = true,
			metadata = {
				assetReference = "chapter0.home.gas_lamp.placeholder",
				presentationCue = "switch_state_changed",
			},
		},
		{
			interactionId = "chapter0_home_marmalade_ribbon",
			roomId = "chapter0_home_hall",
			kind = Types.InteractionKind.Collectible,
			prompt = "Pick up Marmalade's ribbon",
			position = Vector3.new(3, 1.5, -18),
			size = Vector3.new(1.5, 0.25, 1.5),
			requiredForCompletion = true,
			metadata = {
				dialogueKey = "chapter0.home.marmalade_ribbon",
				assetReference = "chapter0.home.ribbon.placeholder",
			},
		},
		{
			interactionId = "chapter0_home_bedroom_door",
			roomId = "chapter0_home_bedroom",
			kind = Types.InteractionKind.Door,
			prompt = "Open the bedroom door",
			position = Vector3.new(0, 3, -28),
			size = Vector3.new(5, 6, 0.75),
			requiredForCompletion = false,
			metadata = {
				dialogueKey = "chapter0.home.bedroom_door",
				presentationCue = "door_state_changed",
			},
		},
	},
	completionInteractionIds = Types.RequiredInteractions,
	atmosphericFeedback = {
		{
			feedbackId = "chapter0_home_note_context",
			interactionId = "chapter0_home_note",
			kind = Types.FeedbackKind.Prompt,
			instructionId = "chapter0_home_note_read",
			intensity = 0.35,
			duration = 2.5,
			order = 1,
			metadata = {
				atmosphereBeat = "home_remembers_mum_note",
				emotionalContext = "absence_acknowledged",
				presentationCue = "note_read_acknowledged",
			},
		},
		{
			feedbackId = "chapter0_home_lamp_response",
			interactionId = "chapter0_home_lamp",
			kind = Types.FeedbackKind.Visual,
			instructionId = "chapter0_home_gas_lamp_breath",
			intensity = 0.4,
			duration = 1.2,
			order = 2,
			metadata = {
				atmosphereBeat = "gas_lamp_answers",
				lightState = "restrained_warmth",
				presentationCue = "lamp_state_feedback",
			},
		},
		{
			feedbackId = "chapter0_home_ribbon_escalation",
			interactionId = "chapter0_home_marmalade_ribbon",
			kind = Types.FeedbackKind.Prompt,
			instructionId = "chapter0_home_ribbon_found",
			intensity = 0.45,
			duration = 2,
			order = 3,
			metadata = {
				atmosphereBeat = "marmalade_absence_noticed",
				escalation = "quiet",
				presentationCue = "ribbon_collected_feedback",
			},
		},
		{
			feedbackId = "chapter0_home_bedroom_door_warning",
			interactionId = "chapter0_home_bedroom_door",
			kind = Types.FeedbackKind.ScreenEffect,
			instructionId = "chapter0_home_bedroom_door_resists",
			intensity = 0.25,
			duration = 0.8,
			order = 4,
			metadata = {
				atmosphereBeat = "bedroom_door_optional_warning",
				completesChapter = false,
				presentationCue = "bedroom_door_feedback",
			},
		},
	},
	environmentalReactions = {
		{
			reactionId = "chapter0_home_note_room_attention",
			interactionId = "chapter0_home_note",
			kind = Types.EnvironmentalReactionKind.RoomPressure,
			targetKind = Types.EnvironmentalReactionTargetKind.Room,
			targetId = "chapter0_home_sitting_room",
			order = 1,
			intensity = 0.25,
			metadata = {
				environmentalBeat = "sitting_room_listens",
				narrativePressure = "mum_note_read",
				presentationCue = "room_attention_shift",
			},
		},
		{
			reactionId = "chapter0_home_lamp_warmth_state",
			interactionId = "chapter0_home_lamp",
			kind = Types.EnvironmentalReactionKind.AttributeShift,
			targetKind = Types.EnvironmentalReactionTargetKind.Interaction,
			targetId = "chapter0_home_lamp",
			order = 2,
			intensity = 0.35,
			metadata = {
				environmentalBeat = "lamp_warmth_settles",
				lightState = "warmButUnsteady",
				presentationCue = "lamp_environment_state",
			},
		},
		{
			reactionId = "chapter0_home_ribbon_hall_pressure",
			interactionId = "chapter0_home_marmalade_ribbon",
			kind = Types.EnvironmentalReactionKind.RoomPressure,
			targetKind = Types.EnvironmentalReactionTargetKind.Room,
			targetId = "chapter0_home_hall",
			order = 3,
			intensity = 0.4,
			metadata = {
				environmentalBeat = "hall_notices_ribbon",
				narrativePressure = "marmalade_absent",
				presentationCue = "hall_pressure_shift",
			},
		},
		{
			reactionId = "chapter0_home_bedroom_door_resistance",
			interactionId = "chapter0_home_bedroom_door",
			kind = Types.EnvironmentalReactionKind.PromptState,
			targetKind = Types.EnvironmentalReactionTargetKind.Interaction,
			targetId = "chapter0_home_bedroom_door",
			order = 4,
			intensity = 0.3,
			metadata = {
				environmentalBeat = "door_resists",
				completesChapter = false,
				presentationCue = "bedroom_door_resistance_state",
			},
		},
	},
	atmosphericProgressionStages = deepCopy(Types.CanonicalAtmosphericProgressionStageDefinitions),
	atmosphericProgressionTransitions = deepCopy(
		Types.CanonicalAtmosphericProgressionTransitionDefinitions
	),
}

return Config
