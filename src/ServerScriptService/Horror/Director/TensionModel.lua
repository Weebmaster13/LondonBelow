--!strict
--[[
	Tension model for per-player and party psychological pacing.

	Owns converting PlayerFearProfile counters into TensionSnapshot values.
	It also models release moments after scares/chases and aggregates party
	pressure.

	Does not own observation collection, scare selection, chapter phase, or
	persistent player data.

	Expected data: run-local PlayerFearProfile records.
	Returns: score/state/release snapshots with diagnostic reasons.

	Design intent: tension is a curve, not a punishment meter. Recent scares lower
	pressure so silence and release remain possible.
]]

local HorrorDirectorConfig = require(script.Parent.HorrorDirectorConfig)
local Types = require(script.Parent.HorrorDirectorTypes)

local TensionModel = {}

type Profile = Types.PlayerFearProfile
type TensionSnapshot = Types.TensionSnapshot

local function stateForScore(score: number, release: number): Types.TensionState
	if release > 0.55 then
		return "Release"
	end

	local thresholds = HorrorDirectorConfig.TensionThresholds

	if score <= thresholds.Calm then
		return "Calm"
	elseif score <= thresholds.Uneasy then
		return "Uneasy"
	elseif score <= thresholds.Tense then
		return "Tense"
	elseif score <= thresholds.Dread then
		return "Dread"
	end

	return "Panic"
end

function TensionModel.calculateForProfile(profile: Profile, currentTime: number): TensionSnapshot
	local weights = HorrorDirectorConfig.ObservationWeights
	local reasons = {}
	local score = 18

	score += math.min(26, profile.timeAlone * weights.TimeAlone)
	score += math.max(-12, profile.timeWithParty * weights.TimeWithParty)
	score += math.min(16, profile.sprintCount * weights.Sprint)
	score += math.min(14, profile.hideCount * weights.Hide)
	score += math.min(12, profile.lanternUseCount * weights.LanternUse)
	score += math.min(18, profile.darknessTime * weights.Darkness / 10)
	score += math.min(12, profile.lookBehindCount * weights.LookBehind)
	score += math.min(12, profile.doorHesitationCount * weights.DoorHesitation)
	score += math.min(10, profile.repeatedRouteCount * weights.RepeatedRoute)
	score += math.min(10, profile.repeatedHidingSpotCount * weights.RepeatedHidingSpot)
	score += math.min(8, profile.objectiveProgress * weights.ObjectiveProgress)
	score += math.min(8, profile.puzzleProgress * weights.PuzzleProgress)

	local sinceScare = if profile.lastScareAt > 0 then currentTime - profile.lastScareAt else 999
	local sinceChase = if profile.lastChaseAt > 0 then currentTime - profile.lastChaseAt else 999

	if sinceScare < 35 then
		score += weights.RecentScareRelief
		table.insert(reasons, "recent scare relief")
	end

	if sinceChase < 60 then
		score += weights.RecentChaseRelief
		table.insert(reasons, "recent chase relief")
	end

	if profile.traits.isolated then
		table.insert(reasons, "isolated")
	end

	if profile.traits.hidingProne then
		table.insert(reasons, "hiding prone")
	end

	if profile.traits.lanternDependent then
		table.insert(reasons, "lantern dependent")
	end

	if profile.overwhelm > 0.65 then
		-- Overwhelmed players are capped below runaway panic so selector logic can
		-- choose silence/release instead of escalating forever.
		score = math.min(score, HorrorDirectorConfig.PanicSoftCap)
		table.insert(reasons, "overwhelm soft cap")
	end

	local release = if sinceScare < 20 or sinceChase < 40 then 0.75 else 0
	local clampedScore = math.clamp(score, 0, HorrorDirectorConfig.MaxTensionScore)
	local state = stateForScore(clampedScore, release)

	return {
		state = state,
		score = clampedScore,
		pressure = profile.fearPressure,
		release = release,
		partyState = state,
		partyScore = clampedScore,
		reasons = reasons,
	}
end

function TensionModel.calculateParty(
	profiles: { [number]: Profile },
	currentTime: number
): TensionSnapshot
	local total = 0
	local count = 0
	local highest: TensionSnapshot? = nil
	local reasons = {}

	for _, profile in pairs(profiles) do
		local snapshot = TensionModel.calculateForProfile(profile, currentTime)
		total += snapshot.score
		count += 1

		if highest == nil or snapshot.score > highest.score then
			highest = snapshot
		end

		for _, reason in ipairs(snapshot.reasons) do
			table.insert(reasons, reason)
		end
	end

	if count == 0 then
		return {
			state = "Calm",
			score = 0,
			pressure = 0,
			release = 0,
			partyState = "Calm",
			partyScore = 0,
			reasons = {},
		}
	end

	-- Party tension respects the average but still notices one highly pressured
	-- player, which helps future systems avoid abandoning isolated teammates.
	local partyScore = math.max(total / count, if highest ~= nil then highest.score * 0.75 else 0)
	local partyState = stateForScore(partyScore, if highest ~= nil then highest.release else 0)

	return {
		state = partyState,
		score = partyScore,
		pressure = if highest ~= nil then highest.pressure else 0,
		release = if highest ~= nil then highest.release else 0,
		partyState = partyState,
		partyScore = partyScore,
		reasons = reasons,
	}
end

return TensionModel
