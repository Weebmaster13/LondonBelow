--!strict
--[[
	Resolves World Intelligence audio policy into Director-safe permissions.

	This module never plays sounds. It only explains whether future audio
	pressure is fair for the current world context.
]]

local ServerScriptService = game:GetService("ServerScriptService")

local WorldZoneContext = require(ServerScriptService.World.WorldZoneContext)

local AudioPolicyResolver = {}

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

function AudioPolicyResolver.fromPayload(payload: any)
	return WorldZoneContext.fromPayload(payload)
end

function AudioPolicyResolver.evaluate(definition: any, context: any): (boolean, string?, string?)
	local worldContext = context.worldContext
	local audioPolicy = worldContext.audioPolicy or {}
	local puzzleProtection = worldContext.puzzleProtection or {}
	local monsterPolicy = worldContext.monsterPolicy or {}

	if definition.requiresKnownZone and not worldContext.isKnown then
		return false, "Policy", "Unknown zone denies specialized audio pressure."
	end

	if worldContext.isKnown == false and definition.majorPressure then
		return false, "Policy", "Unknown zone denies major audio pressure."
	end

	if definition.requiresWhisperPolicy and audioPolicy.allowsWhispers ~= true then
		return false, "Policy", "World audio policy denies whispers."
	end

	if definition.requiresFakeSoundPolicy and audioPolicy.allowsFakeSounds ~= true then
		return false, "Policy", "World audio policy denies fake sounds."
	end

	if definition.requiresHeartbeatPolicy and audioPolicy.allowsHeartbeat ~= true then
		return false, "Policy", "World audio policy denies heartbeat pressure."
	end

	if definition.requiresBreathingPolicy and audioPolicy.allowsBreathing ~= true then
		return false, "Policy", "World audio policy denies breathing pressure."
	end

	if definition.requiresSilencePolicy and audioPolicy.allowsSilenceDrop ~= true then
		return false, "Policy", "World audio policy denies silence drops."
	end

	if
		definition.requiresRainMufflePolicy and not hasAffordance(worldContext, "AllowRainMuffle")
	then
		return false, "Policy", "World audio policy denies rain muffling in unknown or dry spaces."
	end

	if worldContext.zoneKind == "SafeRoom" or hasAffordance(worldContext, "ProtectSafeRoom") then
		if not definition.supportsSafeRoom then
			return false, "SafeRoom", "Safe room suppresses hostile audio pressure."
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

	if
		(definition.requestKind == "FakeFootstep" or definition.requestKind == "Whisper")
		and monsterPolicy.allowsMainMonsterPresence == false
	then
		return false, "Policy", "Monster-support audio pressure is denied by world policy."
	end

	return true, nil, nil
end

function AudioPolicyResolver.validate(): (boolean, string?)
	local unknown = WorldZoneContext.fromPayload({})

	if unknown.audioPolicy.allowsWhispers then
		return false, "Unknown world context allows whispers."
	end

	if unknown.audioPolicy.allowsFakeSounds then
		return false, "Unknown world context allows fake sounds."
	end

	if unknown.audioPolicy.allowsSilenceDrop then
		return false, "Unknown world context allows silence drops."
	end

	if unknown.puzzleProtection.allowsMajorInterruptions then
		return false, "Unknown world context allows major puzzle interruptions."
	end

	return true, nil
end

return AudioPolicyResolver
