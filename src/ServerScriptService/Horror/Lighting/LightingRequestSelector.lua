--!strict

local Config = require(script.Parent.LightingDirectorConfig)
local PolicyResolver = require(script.Parent.LightingPolicyResolver)
local State = require(script.Parent.LightingState)
local Types = require(script.Parent.LightingDirectorTypes)

local LightingRequestSelector = {}

type LightingContext = Types.LightingContext
type LightingDecision = Types.LightingDecision
type LightingRequestDefinition = Types.LightingRequestDefinition

local function requestKindMatches(
	definition: LightingRequestDefinition,
	context: LightingContext
): boolean
	return context.requestKind == nil or definition.requestKind == context.requestKind
end

local function score(definition: LightingRequestDefinition, context: LightingContext): number
	local value = definition.intensity

	if context.pressureState == "Release" and definition.requestKind == "ReleaseLighting" then
		value += 0.4
	elseif context.pressureState == "Oppressive" and definition.majorPressure then
		value += 0.2
	elseif context.pressureState == "Calm" and definition.majorPressure then
		value -= 0.4
	end

	if context.partySize > 1 and table.find(definition.tags, "support") ~= nil then
		value += 0.05
	end

	return value
end

function LightingRequestSelector.select(context: LightingContext): LightingDecision
	local blocked = {}
	local best: LightingRequestDefinition? = nil
	local bestScore = -math.huge

	for _, definition in ipairs(Config.Requests :: { LightingRequestDefinition }) do
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
			reason = "Lighting Director deferred; no fair lighting pressure was available.",
			blocked = blocked,
			intensity = 0,
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
		createdAt = context.now,
		context = context,
	}
end

function LightingRequestSelector.validate(): (boolean, string?)
	for _, definition in ipairs(Config.Requests :: { LightingRequestDefinition }) do
		if type(definition.id) ~= "string" or definition.id == "" then
			return false, "Lighting request definition missing id"
		end

		if not Types.ValidRequestKinds[definition.requestKind] then
			return false, "Invalid Lighting request kind: " .. tostring(definition.requestKind)
		end

		if type(definition.reason) == "string" then
			return false, "Lighting request definitions must not include pre-decided reasons"
		end
	end

	return PolicyResolver.validate()
end

return LightingRequestSelector
