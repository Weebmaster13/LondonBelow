--!strict

local Config = require(script.Parent.EnvironmentDirectorConfig)
local Types = require(script.Parent.EnvironmentDirectorTypes)

local EnvironmentPressureModel = {}

type PressureState = Types.PressureState

local function sanitizeAmount(value: any): number
	if type(value) ~= "number" or value ~= value then
		return 1
	end

	return math.clamp(value, 0, 3)
end

local function stateFromScore(score: number): PressureState
	if score <= Config.ReleaseThreshold then
		return "Release"
	elseif score >= Config.HostileThreshold then
		return "Hostile"
	elseif score >= Config.OppressiveThreshold then
		return "Oppressive"
	elseif score >= Config.UneasyThreshold then
		return "Uneasy"
	elseif score >= Config.WatchfulThreshold then
		return "Watchful"
	end

	return "Calm"
end

function EnvironmentPressureModel.fromObservation(
	observation: any,
	currentScore: number
): (PressureState, number, { string })
	local score = currentScore
	local reasons = {}
	local id = if type(observation) == "table"
		then tostring(observation.id or observation.kind or "")
		else ""
	local amount = if type(observation) == "table" and type(observation.amount) == "number"
		then sanitizeAmount(observation.amount)
		else 1

	if id ~= "" then
		score *= 0.96
	end

	if id == "Social.PartySeparated" or id == "Environment.EnterFog" then
		score += 0.12 * amount
		table.insert(reasons, id)
	elseif id == "Interaction.DoorHesitation" then
		score += 0.08 * amount
		table.insert(reasons, id)
	elseif id == "Player.Overwhelmed" or id == "Horror.Overwhelmed" then
		score -= 0.35
		table.insert(reasons, "release pressure")
	elseif id == "Chase.Started" then
		score += 0.2
		table.insert(reasons, "chase support")
	elseif id == "SafeRoom.Entered" then
		score = math.min(score, -0.5)
		table.insert(reasons, "safe room protection")
	end

	score = math.clamp(score, -1, 1)
	return stateFromScore(score), score, reasons
end

function EnvironmentPressureModel.fromRequest(request: any, fallback: PressureState): PressureState
	if type(request) ~= "table" then
		return fallback
	end

	local context = request.context

	if
		type(context) == "table"
		and type(context.pressureState) == "string"
		and Types.ValidPressureStates[context.pressureState]
	then
		return context.pressureState
	end

	return fallback
end

function EnvironmentPressureModel.validateTransition(
	current: PressureState,
	nextState: PressureState
): (boolean, string?)
	if not Types.ValidPressureStates[current] or not Types.ValidPressureStates[nextState] then
		return false, "Invalid pressure state transition"
	end

	local currentScore = Types.PressureScore[current] or 0
	local nextScore = Types.PressureScore[nextState] or 0

	if math.abs(nextScore - currentScore) > 2 and nextState ~= "Release" then
		return false, "Pressure transition is too abrupt"
	end

	return true, nil
end

return EnvironmentPressureModel
