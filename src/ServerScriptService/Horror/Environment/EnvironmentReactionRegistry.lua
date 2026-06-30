--!strict

local Types = require(script.Parent.EnvironmentDirectorTypes)

local EnvironmentReactionRegistry = {}

type ReactionDefinition = Types.ReactionDefinition

local definitions: { ReactionDefinition } = {
	{
		id = "fog.subtle_thicken",
		category = "FogPressure",
		displayName = "Subtle Fog Thicken",
		intensity = 0.25,
		allowedPressureStates = { "Watchful", "Uneasy", "Oppressive" },
		cooldownSeconds = 35,
		zoneCooldownSeconds = 55,
		maxRepeats = 3,
		supportsSolo = true,
		supportsGroup = true,
		requiresApprovalFrom = {},
		suppressionRules = { "SafeRoom", "Release" },
		tags = { "subtle", "fog", "exterior" },
		executionKind = "ApplyFogPressure",
		safeForPuzzle = true,
		safeForChase = true,
		safeForRelease = false,
		description = "Raises fog presence without blocking navigation.",
	},
	{
		id = "rain.soft_shift",
		category = "RainPressure",
		displayName = "Rain Soft Shift",
		intensity = 0.18,
		allowedPressureStates = { "Calm", "Watchful", "Uneasy", "Release" },
		cooldownSeconds = 30,
		zoneCooldownSeconds = 45,
		maxRepeats = 4,
		supportsSolo = true,
		supportsGroup = true,
		requiresApprovalFrom = {},
		suppressionRules = {},
		tags = { "subtle", "rain", "exterior" },
		executionKind = "ApplyRainPressure",
		safeForPuzzle = true,
		safeForChase = true,
		safeForRelease = true,
		description = "Adjusts rain pressure as a gentle pacing support.",
	},
	{
		id = "wind.alley_breath",
		category = "WindPressure",
		displayName = "Alley Breath",
		intensity = 0.22,
		allowedPressureStates = { "Watchful", "Uneasy", "Oppressive" },
		cooldownSeconds = 35,
		zoneCooldownSeconds = 50,
		maxRepeats = 3,
		supportsSolo = true,
		supportsGroup = true,
		requiresApprovalFrom = {},
		suppressionRules = { "SafeRoom" },
		tags = { "wind", "street", "subtle" },
		executionKind = "ApplyWindPressure",
		safeForPuzzle = true,
		safeForChase = true,
		safeForRelease = false,
		description = "Suggests the street is breathing through controlled wind pressure.",
	},
	{
		id = "door.distant_settle",
		category = "DoorReaction",
		displayName = "Distant Door Settle",
		intensity = 0.3,
		allowedPressureStates = { "Uneasy", "Oppressive" },
		cooldownSeconds = 50,
		zoneCooldownSeconds = 75,
		maxRepeats = 2,
		supportsSolo = true,
		supportsGroup = true,
		requiresApprovalFrom = {},
		suppressionRules = { "PuzzleCritical", "SafeRoom" },
		tags = { "door", "distant", "subtle" },
		executionKind = "RequestDoorReaction",
		safeForPuzzle = false,
		safeForChase = true,
		safeForRelease = false,
		description = "Approves a restrained distant door reaction without blocking progress.",
	},
	{
		id = "room.temperature_drop",
		category = "RoomPressure",
		displayName = "Room Temperature Drop",
		intensity = 0.2,
		allowedPressureStates = { "Watchful", "Uneasy", "Oppressive" },
		cooldownSeconds = 40,
		zoneCooldownSeconds = 60,
		maxRepeats = 3,
		supportsSolo = true,
		supportsGroup = true,
		requiresApprovalFrom = {},
		suppressionRules = {},
		tags = { "room", "subtle", "interior" },
		executionKind = "RequestRoomPressure",
		safeForPuzzle = true,
		safeForChase = true,
		safeForRelease = false,
		description = "Approves a non-visual room pressure shift for future presentation systems.",
	},
	{
		id = "building.attention_lift",
		category = "BuildingAttention",
		displayName = "Building Attention Lift",
		intensity = 0.32,
		allowedPressureStates = { "Uneasy", "Oppressive", "Hostile" },
		cooldownSeconds = 60,
		zoneCooldownSeconds = 90,
		maxRepeats = 2,
		supportsSolo = true,
		supportsGroup = true,
		requiresApprovalFrom = { "Narrative" },
		suppressionRules = { "Release", "SafeRoom" },
		tags = { "building", "attention" },
		executionKind = "RequestBuildingAttention",
		safeForPuzzle = true,
		safeForChase = false,
		safeForRelease = false,
		description = "Marks that the building may feel more aware, pending future narrative gates.",
	},
	{
		id = "silence.release_hold",
		category = "ReleaseSupport",
		displayName = "Release Hold",
		intensity = 0.1,
		allowedPressureStates = { "Release", "Calm" },
		cooldownSeconds = 20,
		zoneCooldownSeconds = 20,
		maxRepeats = 6,
		supportsSolo = true,
		supportsGroup = true,
		requiresApprovalFrom = {},
		suppressionRules = {},
		tags = { "silence", "release", "safe" },
		executionKind = "RequestRoomPressure",
		safeForPuzzle = true,
		safeForChase = false,
		safeForRelease = true,
		description = "Chooses stillness as a deliberate environmental release.",
	},
	{
		id = "safe_room.protect",
		category = "SafeRoomProtection",
		displayName = "Safe Room Protection",
		intensity = 0,
		allowedPressureStates = { "Calm", "Release" },
		cooldownSeconds = 10,
		zoneCooldownSeconds = 10,
		maxRepeats = 99,
		supportsSolo = true,
		supportsGroup = true,
		requiresApprovalFrom = {},
		suppressionRules = {},
		tags = { "safe", "fairness" },
		executionKind = "RequestRoomPressure",
		safeForPuzzle = true,
		safeForChase = false,
		safeForRelease = true,
		description = "Protects future safe rooms from unfair environmental pressure.",
	},
}

local byId: { [string]: ReactionDefinition } = {}

local function cloneDefinition(definition: ReactionDefinition): ReactionDefinition
	return {
		id = definition.id,
		category = definition.category,
		displayName = definition.displayName,
		intensity = definition.intensity,
		allowedPressureStates = table.clone(definition.allowedPressureStates),
		cooldownSeconds = definition.cooldownSeconds,
		zoneCooldownSeconds = definition.zoneCooldownSeconds,
		maxRepeats = definition.maxRepeats,
		supportsSolo = definition.supportsSolo,
		supportsGroup = definition.supportsGroup,
		requiresApprovalFrom = table.clone(definition.requiresApprovalFrom),
		suppressionRules = table.clone(definition.suppressionRules),
		tags = table.clone(definition.tags),
		executionKind = definition.executionKind,
		safeForPuzzle = definition.safeForPuzzle,
		safeForChase = definition.safeForChase,
		safeForRelease = definition.safeForRelease,
		description = definition.description,
	}
end

for _, definition in ipairs(definitions) do
	byId[definition.id] = definition
end

function EnvironmentReactionRegistry.getAll(): { ReactionDefinition }
	local copied = {}

	for _, definition in ipairs(definitions) do
		table.insert(copied, cloneDefinition(definition))
	end

	return copied
end

function EnvironmentReactionRegistry.get(id: string): ReactionDefinition?
	local definition = byId[id]

	if definition == nil then
		return nil
	end

	return cloneDefinition(definition)
end

function EnvironmentReactionRegistry.validate(): (boolean, string?)
	local seen = {}

	for _, definition in ipairs(definitions) do
		if type(definition.id) ~= "string" or definition.id == "" then
			return false, "Reaction missing id"
		end

		if seen[definition.id] then
			return false, "Duplicate environment reaction: " .. definition.id
		end

		if not Types.ValidReactionCategories[definition.category] then
			return false, "Invalid reaction category: " .. definition.id
		end

		if not Types.ValidExecutionKinds[definition.executionKind] then
			return false, "Invalid execution kind for reaction: " .. definition.id
		end

		if definition.intensity < 0 or definition.intensity > 1 then
			return false, "Reaction intensity out of range: " .. definition.id
		end

		if #definition.allowedPressureStates == 0 then
			return false, "Reaction missing pressure states: " .. definition.id
		end

		for _, pressureState in ipairs(definition.allowedPressureStates) do
			if not Types.ValidPressureStates[pressureState] then
				return false, "Reaction has invalid pressure state: " .. definition.id
			end
		end

		if definition.cooldownSeconds <= 0 or definition.zoneCooldownSeconds <= 0 then
			return false, "Reaction cooldowns must be positive: " .. definition.id
		end

		if definition.maxRepeats <= 0 then
			return false, "Reaction maxRepeats must be positive: " .. definition.id
		end

		if type(definition.displayName) ~= "string" or definition.displayName == "" then
			return false, "Reaction missing displayName: " .. definition.id
		end

		if type(definition.description) ~= "string" or definition.description == "" then
			return false, "Reaction missing description: " .. definition.id
		end

		seen[definition.id] = true
	end

	return true, nil
end

return EnvironmentReactionRegistry
