--!strict

local EnvironmentMemory = require(script.Parent.EnvironmentMemory)
local EnvironmentState = require(script.Parent.EnvironmentState)
local Registry = require(script.Parent.EnvironmentReactionRegistry)
local Types = require(script.Parent.EnvironmentDirectorTypes)

local EnvironmentReactionSelector = {}

type ReactionDefinition = Types.ReactionDefinition
type SelectionContext = Types.SelectionContext
type ReactionDecision = Types.ReactionDecision

local function arrayContains(values: { string }, needle: string): boolean
	return table.find(values, needle) ~= nil
end

local function isAllowed(
	definition: ReactionDefinition,
	context: SelectionContext
): (boolean, string?)
	if not arrayContains(definition.allowedPressureStates, context.pressureState) then
		return false, "pressure state not allowed"
	end

	if context.partySize <= 1 and not definition.supportsSolo then
		return false, "reaction does not support solo"
	end

	if context.partySize > 1 and not definition.supportsGroup then
		return false, "reaction does not support group"
	end

	if context.zoneKind == "SafeRoom" and not definition.safeForRelease then
		return false, "safe room protection"
	end

	if context.zoneKind == "PuzzleRoom" and not definition.safeForPuzzle then
		return false, "puzzle fairness"
	end

	if context.zoneKind == "ChaseRoute" and not definition.safeForChase then
		return false, "chase fairness"
	end

	if EnvironmentState.isReactionCoolingDown(definition.id, context.now) then
		return false, "reaction cooldown"
	end

	if EnvironmentState.isZoneCoolingDown(definition.id, context.zoneId, context.now) then
		return false, "zone cooldown"
	end

	if EnvironmentMemory.getRepeatCount(definition.id) >= definition.maxRepeats then
		return false, "repeat limit"
	end

	if
		context.preferredCategory ~= nil
		and definition.category ~= context.preferredCategory
		and not arrayContains(definition.tags, "safe")
	then
		return false, "category mismatch"
	end

	return true, nil
end

local function score(definition: ReactionDefinition, context: SelectionContext): number
	local value = definition.intensity

	if context.partySize <= 1 and definition.supportsSolo then
		value += 0.08
	end

	if
		(context.zoneKind == "Street" and arrayContains(definition.tags, "exterior"))
		or (context.zoneKind == "Interior" and arrayContains(definition.tags, "interior"))
	then
		value += 0.05
	end

	if context.pressureState == "Release" and definition.safeForRelease then
		value += 0.2
	end

	return value
end

function EnvironmentReactionSelector.select(context: SelectionContext): ReactionDecision
	local blocked = {}
	local best: ReactionDefinition? = nil
	local bestScore = -math.huge

	for _, definition in ipairs(Registry.getAll()) do
		local allowed, reason = isAllowed(definition, context)

		if allowed then
			local candidateScore = score(definition, context)

			if candidateScore > bestScore then
				best = definition
				bestScore = candidateScore
			end
		else
			table.insert(blocked, definition.id .. ": " .. tostring(reason))
		end
	end

	if best == nil then
		return {
			requestId = nil,
			reactionId = nil,
			category = nil,
			status = "Silence",
			reason = "Environment Director chose stillness; no fair reaction was available.",
			blocked = blocked,
			executionKind = nil,
			createdAt = context.now,
			context = context,
		}
	end

	return {
		requestId = nil,
		reactionId = best.id,
		category = best.category,
		status = "Selected",
		reason = "Selected " .. best.displayName .. " as a fair environmental reaction.",
		blocked = blocked,
		executionKind = best.executionKind,
		createdAt = context.now,
		context = context,
	}
end

return EnvironmentReactionSelector
