--!strict

local Config = require(script.Parent.AudioDirectorConfig)
local PolicyResolver = require(script.Parent.AudioPolicyResolver)
local State = require(script.Parent.AudioState)
local Types = require(script.Parent.AudioDirectorTypes)

local AudioRequestSelector = {}

type AudioContext = Types.AudioContext
type AudioDecision = Types.AudioDecision
type AudioRequestDefinition = Types.AudioRequestDefinition

local function requestKindMatches(
	definition: AudioRequestDefinition,
	context: AudioContext
): boolean
	return context.requestKind == nil or definition.requestKind == context.requestKind
end

local function score(definition: AudioRequestDefinition, context: AudioContext): number
	local value = definition.intensity

	if context.pressureState == "Release" and table.find(definition.tags, "protection") ~= nil then
		value += 0.3
	elseif context.pressureState == "Oppressive" and definition.majorPressure then
		value += 0.15
	elseif context.pressureState == "Calm" and definition.majorPressure then
		value -= 0.4
	end

	if context.partySize > 1 and definition.requestKind == "RoomAmbience" then
		value += 0.05
	end

	return value
end

function AudioRequestSelector.select(context: AudioContext): AudioDecision
	local blocked = {}
	local best: AudioRequestDefinition? = nil
	local bestScore = -math.huge

	for _, definition in ipairs(Config.Requests :: { AudioRequestDefinition }) do
		if not requestKindMatches(definition, context) then
			table.insert(blocked, definition.id .. ": request kind mismatch")
			continue
		end

		if State.isCoolingDown(definition.id, context.now) then
			table.insert(blocked, definition.id .. ": cooldown")
			continue
		end

		local allowed, suppressionKind, reason = PolicyResolver.evaluate(definition, context)

		if not allowed then
			table.insert(blocked, definition.id .. ": " .. tostring(reason))
			State.recordSuppression(
				suppressionKind or "Policy",
				reason or "Policy denied",
				context.zoneId
			)
			continue
		end

		local candidateScore = score(definition, context)
		if candidateScore > bestScore then
			best = definition
			bestScore = candidateScore
		end
	end

	if best == nil then
		return {
			requestId = nil,
			definitionId = nil,
			requestKind = context.requestKind,
			status = "Deferred",
			reason = "Audio Director deferred; no fair audio pressure was available.",
			blocked = blocked,
			intensity = 0,
			cooldownSeconds = 0,
			createdAt = context.now,
			context = context,
		}
	end

	return {
		requestId = nil,
		definitionId = best.id,
		requestKind = best.requestKind,
		status = "Approved",
		reason = "Approved future " .. best.displayName .. " within World Intelligence policy.",
		blocked = blocked,
		intensity = best.intensity,
		cooldownSeconds = best.cooldownSeconds,
		createdAt = context.now,
		context = context,
	}
end

function AudioRequestSelector.validate(): (boolean, string?)
	for _, definition in ipairs(Config.Requests :: { AudioRequestDefinition }) do
		if type(definition.id) ~= "string" or definition.id == "" then
			return false, "Audio request definition missing id"
		end

		if not Types.ValidRequestKinds[definition.requestKind] then
			return false, "Invalid Audio request kind: " .. tostring(definition.requestKind)
		end

		if
			type(definition.intensity) ~= "number"
			or definition.intensity < 0
			or definition.intensity > 1
		then
			return false, "Audio request intensity must be between 0 and 1"
		end

		if
			type(definition.cooldownSeconds) ~= "number"
			or definition.cooldownSeconds < Config.MinCooldownSeconds
			or definition.cooldownSeconds > Config.MaxCooldownSeconds
		then
			return false, "Audio request cooldown is out of bounds"
		end
	end

	return PolicyResolver.validate()
end

return AudioRequestSelector
