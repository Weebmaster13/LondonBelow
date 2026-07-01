--!strict
-- Pressure budget math. It never executes horror.

local Config = require(script.Parent.Parent.Core.HorrorOrchestrationConfig)

local Model = {}

function Model.fromRequest(previous: any, request: any)
	local pressure = math.clamp(request.pressure or 0, 0, 100)
	local sensory =
		math.clamp((request.metadata and request.metadata.sensoryLoad) or pressure * 0.35, 0, 100)
	local emotional =
		math.clamp((request.metadata and request.metadata.emotionalLoad) or pressure * 0.45, 0, 100)
	local multiplayer =
		math.clamp((request.metadata and request.metadata.multiplayerLoad) or 0, 0, 100)
	local current = math.clamp(previous.currentPressure + pressure * 0.4, 0, Config.MaxPressure)
	return {
		currentPressure = current,
		targetPressure = previous.targetPressure,
		pressureDebt = math.max(0, current - previous.targetPressure),
		releaseNeed = math.clamp(
			math.max(0, current - previous.targetPressure) + emotional * 0.2,
			0,
			100
		),
		silenceNeed = math.clamp(current * 0.45 + sensory * 0.35, 0, 100),
		chaseReadiness = math.clamp(current * 0.6 + pressure * 0.25, 0, 100),
		sensoryLoad = sensory,
		emotionalLoad = emotional,
		multiplayerLoad = multiplayer,
	}
end

return Model
