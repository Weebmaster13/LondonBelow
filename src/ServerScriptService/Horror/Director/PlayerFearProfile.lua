--!strict
--[[
	Run-local player behavior profiles for adaptive psychological horror.

	Owns per-player counters, derived traits, and short memory lists for the
	current server run.

	Does not own permanent personal data, scare selection, monetization,
	moderation, or client-trusted truth.

	Expected data: trusted server observations from HorrorDirector.observe or
	DirectorSignals.Observation.

	Returns: PlayerFearProfile records consumed by TensionModel and ScareSelector.

	Edge case: profiles are removed when players leave. Do not persist these
	traits unless a future privacy-reviewed save design explicitly requires it.
]]

local HorrorDirectorConfig = require(script.Parent.HorrorDirectorConfig)
local Types = require(script.Parent.HorrorDirectorTypes)

local PlayerFearProfile = {}

type Observation = Types.Observation
type Profile = Types.PlayerFearProfile

local profiles: { [number]: Profile } = {}

local function now(): number
	return os.clock()
end

local function clamp01(value: number): number
	return math.clamp(value, 0, 1)
end

local function pushLimited(values: { string }, value: string, limit: number)
	table.insert(values, value)

	while #values > limit do
		table.remove(values, 1)
	end
end

local function recomputeTraits(profile: Profile)
	-- Traits are deliberately coarse pacing hints. They should guide flavor,
	-- not become rigid labels that punish one-off player choices.
	profile.traits.cautious = profile.caution >= 0.62
	profile.traits.brave = profile.confidence >= 0.62 and profile.fearPressure < 0.55
	profile.traits.isolated = profile.timeAlone > profile.timeWithParty + 30
	profile.traits.lanternDependent = profile.lanternUseCount >= 8
	profile.traits.darknessTolerant = profile.darknessTime >= 45 and profile.lanternUseCount <= 3
	profile.traits.hidingProne = profile.hideCount >= 4
	profile.traits.sprintHeavy = profile.sprintCount >= 8
	profile.traits.curious = profile.curiosity >= 0.6
	profile.traits.avoidant = profile.caution >= 0.7 and profile.explorationDistance < 20
	profile.traits.overwhelmed = profile.overwhelm >= 0.7
end

local function createProfile(player: Player): Profile
	local profile: Profile = {
		userId = player.UserId,
		name = player.Name,
		createdAt = now(),
		updatedAt = now(),
		timeAlone = 0,
		timeWithParty = 0,
		sprintCount = 0,
		hideCount = 0,
		lanternUseCount = 0,
		darknessTime = 0,
		lookBehindCount = 0,
		doorHesitationCount = 0,
		puzzleProgress = 0,
		objectiveProgress = 0,
		explorationDistance = 0,
		repeatedRouteCount = 0,
		repeatedHidingSpotCount = 0,
		scaresSeen = 0,
		lastScareAt = 0,
		lastChaseAt = 0,
		lastObservationAt = now(),
		confidence = 0.45,
		caution = 0.45,
		curiosity = 0.45,
		fearPressure = 0,
		overwhelm = 0,
		traits = {},
		recentPositions = {},
		recentHidingSpots = {},
		recentScareIds = {},
	}

	recomputeTraits(profile)

	return profile
end

function PlayerFearProfile.ensure(player: Player): Profile
	local profile = profiles[player.UserId]

	if profile == nil then
		profile = createProfile(player)
		profiles[player.UserId] = profile
	end

	return profile
end

function PlayerFearProfile.remove(player: Player)
	profiles[player.UserId] = nil
end

function PlayerFearProfile.observe(observation: Observation): Profile?
	local player = observation.player

	if player == nil then
		return nil
	end

	local profile = PlayerFearProfile.ensure(player)
	local amount = observation.amount or 1
	local kind = observation.kind

	-- Unknown observation kinds are safe to ignore. This keeps the Director
	-- forward-compatible while chapter systems are still being designed.
	if kind == "TimeAlone" then
		profile.timeAlone += amount
	elseif kind == "TimeWithParty" then
		profile.timeWithParty += amount
	elseif kind == "Sprint" then
		profile.sprintCount += amount
		profile.confidence = clamp01(profile.confidence + 0.015 * amount)
	elseif kind == "Hide" then
		profile.hideCount += amount
		profile.caution = clamp01(profile.caution + 0.025 * amount)
	elseif kind == "LanternUse" then
		profile.lanternUseCount += amount
	elseif kind == "Darkness" then
		profile.darknessTime += amount
	elseif kind == "LookBehind" then
		profile.lookBehindCount += amount
		profile.caution = clamp01(profile.caution + 0.012 * amount)
	elseif kind == "DoorHesitation" then
		profile.doorHesitationCount += amount
		profile.caution = clamp01(profile.caution + 0.02 * amount)
	elseif kind == "PuzzleProgress" then
		profile.puzzleProgress = math.max(profile.puzzleProgress, amount)
		profile.curiosity = clamp01(profile.curiosity + 0.015)
	elseif kind == "ObjectiveProgress" then
		profile.objectiveProgress = math.max(profile.objectiveProgress, amount)
		profile.confidence = clamp01(profile.confidence + 0.01)
	elseif kind == "Exploration" then
		profile.explorationDistance += amount
		profile.curiosity = clamp01(profile.curiosity + 0.01 * amount)
	elseif kind == "ScareSeen" then
		profile.scaresSeen += 1
		profile.lastScareAt = observation.at
		profile.fearPressure = clamp01(profile.fearPressure + 0.18)
	elseif kind == "ChaseSeen" then
		profile.lastChaseAt = observation.at
		profile.fearPressure = clamp01(profile.fearPressure + 0.25)
	end

	if observation.positionKey ~= nil then
		if table.find(profile.recentPositions, observation.positionKey) ~= nil then
			profile.repeatedRouteCount += 1
		end

		pushLimited(
			profile.recentPositions,
			observation.positionKey,
			HorrorDirectorConfig.RouteMemoryLimit
		)
	end

	if observation.metadata ~= nil and type(observation.metadata.hidingSpotId) == "string" then
		local hidingSpotId = observation.metadata.hidingSpotId

		if table.find(profile.recentHidingSpots, hidingSpotId) ~= nil then
			profile.repeatedHidingSpotCount += 1
		end

		pushLimited(
			profile.recentHidingSpots,
			hidingSpotId,
			HorrorDirectorConfig.HidingSpotMemoryLimit
		)
	end

	local sinceScare = if profile.lastScareAt > 0 then observation.at - profile.lastScareAt else 999
	profile.overwhelm = clamp01((profile.fearPressure * 0.65) + if sinceScare < 30 then 0.25 else 0)
	profile.updatedAt = observation.at
	profile.lastObservationAt = observation.at
	recomputeTraits(profile)

	return profile
end

function PlayerFearProfile.recordScare(player: Player, scareId: string, at: number)
	local profile = PlayerFearProfile.ensure(player)

	profile.scaresSeen += 1
	profile.lastScareAt = at
	profile.fearPressure = clamp01(profile.fearPressure + 0.16)
	pushLimited(profile.recentScareIds, scareId, HorrorDirectorConfig.RecentScareMemoryLimit)
	recomputeTraits(profile)
end

function PlayerFearProfile.get(userId: number): Profile?
	return profiles[userId]
end

function PlayerFearProfile.getAll(): { [number]: Profile }
	return profiles
end

function PlayerFearProfile.inspect()
	return table.clone(profiles)
end

function PlayerFearProfile.validate(): (boolean, string?)
	for userId, profile in pairs(profiles) do
		if profile.userId ~= userId then
			return false, "Fear profile user id mismatch"
		end
	end

	return true, nil
end

return PlayerFearProfile
