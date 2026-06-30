--!strict
--[[
	Adaptive scare selection with fairness and silence as a valid outcome.

	Owns choosing the best ScareDefinition for one player evaluation.

	Does not own execution, replication, audio/visual playback, or Monster AI.
	It returns metadata or nil; HorrorDirector decides how to publish decisions.

	Expected data: PlayerFearProfile, TensionSnapshot, chapter phase, current
	time, and party size.

	Returns: selected scare metadata, a human-readable reason, and blocked scare
	reasons for diagnostics.

	Server-authority rule: client preferences never affect this selector unless
	a trusted server system converts behavior into observations first.
]]

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

local function deterministicRoll(profile: Profile, currentTime: number, salt: number): number
	local evaluationBucket =
		math.floor(currentTime / HorrorDirectorConfig.EvaluationIntervalSeconds)
	local raw = (profile.userId * 1103515245 + evaluationBucket * 12345 + salt * 2654435761) % 10000

	return raw / 10000
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
		-- These definitions are intentionally present but blocked until the
		-- relevant future systems can execute them responsibly.
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
		-- Braver players should not receive only harmless ambience; they need
		-- pressure that respects their confidence without punishing it.
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

	-- Silence is part of the horror grammar. Calm-too-long can override normal
	-- restraint, but overwhelmed players still get protection.
	if
		profile.traits.overwhelmed
		and deterministicRoll(profile, currentTime, 1)
			< HorrorDirectorConfig.OverwhelmSilenceChance
	then
		return nil, "silence: player overwhelmed", blocked
	end

	if
		not calmTooLong
		and deterministicRoll(profile, currentTime, 2) < HorrorDirectorConfig.SilenceChance
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

			if
				score > bestScore
				or (
					score == bestScore
					and best ~= nil
					and DirectorMemory.getScareUseCount(scare.id)
						< DirectorMemory.getScareUseCount(best.id)
				)
			then
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
