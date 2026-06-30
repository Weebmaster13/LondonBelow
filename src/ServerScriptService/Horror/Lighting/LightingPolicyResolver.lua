--!strict
--[[
	Resolves World Intelligence lighting policy into Director-safe permissions.

	This module turns world context into yes/no/reason checks. It does not apply
	lighting changes or create effects.
]]

local ServerScriptService = game:GetService("ServerScriptService")

local WorldZoneContext = require(ServerScriptService.World.WorldZoneContext)

local LightingPolicyResolver = {}

local function hasAffordance(worldContext: any, affordance: string): boolean
	if type(worldContext.affordances) ~= "table" then
		return false
	end

	for _, value in ipairs(worldContext.affordances) do
		if value == affordance then
			return true
		end
	end

	return false
end

function LightingPolicyResolver.fromPayload(payload: any)
	return WorldZoneContext.fromPayload(payload)
end

function LightingPolicyResolver.evaluate(definition: any, context: any): (boolean, string?, string?)
	local worldContext = context.worldContext
	local lightingPolicy = worldContext.lightingPolicy or {}
	local puzzleProtection = worldContext.puzzleProtection or {}
	local monsterPolicy = worldContext.monsterPolicy or {}

	if definition.requiresKnownZone and not worldContext.isKnown then
		return false, "Policy", "Unknown zone denies major or specialized lighting pressure."
	end

	if definition.requiresFlickerPolicy and lightingPolicy.allowsFlicker ~= true then
		return false, "Policy", "World lighting policy denies flicker."
	end

	if definition.requiresBlackoutPolicy and lightingPolicy.allowsBlackout ~= true then
		return false, "Policy", "World lighting policy denies blackout."
	end

	if definition.requestKind == "ShadowPressure" and lightingPolicy.allowsBlackout == true then
		return false,
			"Policy",
			"Blackout-capable pressure is reserved until a future execution system exists."
	end

	if worldContext.isKnown == false and definition.majorPressure then
		return false, "Policy", "Unknown zone denies major lighting pressure."
	end

	if worldContext.zoneKind == "SafeRoom" or hasAffordance(worldContext, "ProtectSafeRoom") then
		if not definition.supportsSafeRoom then
			return false, "SafeRoom", "Safe room suppresses hostile lighting pressure."
		end
	end

	if
		worldContext.zoneKind == "PuzzleRoom"
		or puzzleProtection.protectsActivePuzzle == true
		or hasAffordance(worldContext, "ProtectPuzzleFocus")
	then
		if definition.majorPressure or not definition.supportsPuzzleRoom then
			return false, "Puzzle", "Puzzle room protects comprehension and cooperation."
		end
	end

	if definition.requestKind == "ChaseSupport" then
		if monsterPolicy.allowsChaseStart ~= true and worldContext.zoneKind ~= "ChaseRoute" then
			return false, "Policy", "Chase-support lighting requires a chase-capable world profile."
		end

		if not definition.supportsChase then
			return false, "Policy", "Lighting definition does not support chase pressure."
		end
	end

	if definition.requestKind == "Dim" and not hasAffordance(worldContext, "AllowLightDimming") then
		return false, "Policy", "World affordances do not allow light dimming."
	end

	return true, nil, nil
end

function LightingPolicyResolver.validate(): (boolean, string?)
	local unknown = WorldZoneContext.fromPayload({})

	if unknown.monsterPolicy.allowsMainMonsterReveal then
		return false, "Unknown world context allows monster reveal."
	end

	if unknown.monsterPolicy.allowsChaseStart then
		return false, "Unknown world context allows chase start."
	end

	if unknown.lightingPolicy.allowsBlackout then
		return false, "Unknown world context allows blackout."
	end

	if unknown.puzzleProtection.allowsMajorInterruptions then
		return false, "Unknown world context allows major puzzle interruptions."
	end

	return true, nil
end

return LightingPolicyResolver
