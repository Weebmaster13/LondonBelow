--!strict
-- Adaptive scare selection with fairness and silence as a valid outcome.

local HorrorDirectorConfig = require(script.Parent.HorrorDirectorConfig)
local DirectorMemory = require(script.Parent.DirectorMemory)
local ScareCooldowns = require(script.Parent.ScareCooldowns)
local ScareRegistry = require(script.Parent.ScareRegistry)
local Types = require(script.Parent.HorrorDirectorTypes)

local ScareSelector = {}

type Profile = Types.PlayerFearProfile
type TensionSnapshot = Types.TensionSnapshot
type ScareDefinition = Types.ScareDefinition

local function contains(values: { string }, value: string): boolean
	return table.find(values, value) ~= nil
end

local function requirementMet(requirement: string, profile: Profile): boolean
	if requirement == "isolatedOrCautious" then
		return profile.traits.isolated or profile.traits.cautious
	elseif requirement == "notOverwhelmed" then
		return not profile.traits.overwhelmed
	elseif requirement == "darknessOrHiding" then
		return profile.darknessTime > 20 or profile.traits.hidingProne
	elseif requirement == "lanternDependent" then
		return profile.traits.lanternDependent
	elseif requirement == "futureMonsterSystem" or requirement == "chapterClimax" then
		return false
	end

	return true
end

local function scoreScare(
	scare: ScareDefinition,
	profile: Profile,
	tension: TensionSnapshot
): number
	local score = scare.baseWeight * 100

	if profile.traits.lanternDependent and contains(scare.tags, "lantern") then
		score += 35
	end

	if profile.traits.hidingProne and contains(scare.tags, "close") then
		score += 22
	end

	if profile.traits.cautious and contains(scare.tags, "deception") then
		score += 18
	end

	if profile.traits.brave and scare.category == "Ambient" then
		score -= 10
	end

	if DirectorMemory.wasCategoryUsedRecently(scare.category) then
		score -= 25
	end

	score += math.clamp(tension.score - scare.intensity, -20, 20)

	return score
end

function ScareSelector.selectForPlayer(
	profile: Profile,
	tension: TensionSnapshot,
	phase: Types.ChapterPhase,
	currentTime: number,
	partySize: number
): (ScareDefinition?, string, { string })
	local blocked = {}
	local calmTooLong = profile.lastScareAt == 0
		or currentTime - profile.lastScareAt > HorrorDirectorConfig.CalmTooLongSeconds

	if
		profile.traits.overwhelmed
		and math.random() < HorrorDirectorConfig.OverwhelmSilenceChance
	then
		return nil, "silence: player overwhelmed", blocked
	end

	if
		not calmTooLong
		and math.random() < HorrorDirectorConfig.SilenceChance
		and tension.state ~= "Panic"
	then
		return nil, "silence: pacing restraint", blocked
	end

	local best: ScareDefinition? = nil
	local bestScore = -math.huge

	for _, scare in ipairs(ScareRegistry.getAll()) do
		local blockReason: string? = nil

		if not contains(scare.allowedTension, tension.state) then
			blockReason = "tension mismatch"
		elseif not contains(scare.allowedPhases, phase) then
			blockReason = "phase mismatch"
		elseif partySize <= 1 and not scare.supportsSolo then
			blockReason = "solo unsupported"
		elseif partySize > 1 and not scare.supportsGroup then
			blockReason = "group unsupported"
		elseif DirectorMemory.getScareUseCount(scare.id) >= scare.maxRepeats then
			blockReason = "max repeats"
		else
			for _, requirement in ipairs(scare.requirements) do
				if not requirementMet(requirement, profile) then
					blockReason = "requirement: " .. requirement
					break
				end
			end
		end

		if blockReason == nil then
			local cooldownOk, cooldownReason =
				ScareCooldowns.canUse(scare, profile.userId, currentTime)

			if not cooldownOk then
				blockReason = cooldownReason or "cooldown"
			end
		end

		if blockReason ~= nil then
			table.insert(blocked, scare.id .. ": " .. blockReason)
			DirectorMemory.recordBlocked(scare.id, blockReason, currentTime)
		else
			local score = scoreScare(scare, profile, tension)

			if score > bestScore then
				best = scare
				bestScore = score
			end
		end
	end

	if best == nil then
		return nil, "silence: no fair scare available", blocked
	end

	return best, "selected: best fit", blocked
end

return ScareSelector
