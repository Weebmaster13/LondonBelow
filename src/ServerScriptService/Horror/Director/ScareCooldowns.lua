--!strict
--[[
	Cooldown enforcement for fair, non-spammy horror pacing.

	Owns global, category, scare-specific, and per-player cooldown timestamps.

	Does not own scare scoring, memory history, or execution.

	Expected data: ScareDefinition metadata, optional userId, current server time.
	Returns: whether a scare can be used and a diagnostic block reason.

	Future extension points: chapter-specific cooldown multipliers, difficulty
	scaling, and party-wide overrides. Those should still preserve anti-spam
	guarantees.
]]

local HorrorDirectorConfig = require(script.Parent.HorrorDirectorConfig)
local Types = require(script.Parent.HorrorDirectorTypes)

local ScareCooldowns = {}

type ScareDefinition = Types.ScareDefinition

local globalLastAt = 0
local categoryLastAt: { [string]: number } = {}
local scareLastAt: { [string]: number } = {}
local playerLastAt: { [number]: number } = {}

function ScareCooldowns.canUse(
	scare: ScareDefinition,
	userId: number?,
	currentTime: number
): (boolean, string?)
	-- Order matters: global and player cooldowns protect pacing before category
	-- or specific scare checks try to fine-tune repetition.
	if currentTime - globalLastAt < HorrorDirectorConfig.MinimumSecondsBetweenScares then
		return false, "global cooldown"
	end

	if userId ~= nil then
		local lastPlayer = playerLastAt[userId]

		if
			lastPlayer ~= nil
			and currentTime - lastPlayer
				< HorrorDirectorConfig.MinimumPlayerSecondsBetweenScares
		then
			return false, "player cooldown"
		end
	end

	local categoryLast = categoryLastAt[scare.category]

	if
		categoryLast ~= nil
		and currentTime - categoryLast
			< math.max(
				scare.categoryCooldownSeconds,
				HorrorDirectorConfig.MinimumCategorySecondsBetweenScares
			)
	then
		return false, "category cooldown"
	end

	local scareLast = scareLastAt[scare.id]

	if scareLast ~= nil and currentTime - scareLast < scare.cooldownSeconds then
		return false, "scare cooldown"
	end

	return true, nil
end

function ScareCooldowns.record(scare: ScareDefinition, userId: number?, currentTime: number)
	globalLastAt = currentTime
	categoryLastAt[scare.category] = currentTime
	scareLastAt[scare.id] = currentTime

	if userId ~= nil then
		playerLastAt[userId] = currentTime
	end
end

function ScareCooldowns.inspect()
	return {
		globalLastAt = globalLastAt,
		categoryLastAt = table.clone(categoryLastAt),
		scareLastAt = table.clone(scareLastAt),
		playerLastAt = table.clone(playerLastAt),
	}
end

function ScareCooldowns.validate(): (boolean, string?)
	return true, nil
end

return ScareCooldowns
