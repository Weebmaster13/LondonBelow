--!strict
-- Silence is a valid horror decision.

local Config = require(script.Parent.Parent.Core.HorrorOrchestrationConfig)

local Model = {}

function Model.evaluate(budget: any, request: any)
	local reasons = {}
	local shouldSilence = false
	if budget.silenceNeed >= Config.SilenceNeedThreshold then
		shouldSilence = true
		table.insert(reasons, "silence need is high")
	end
	if request.requestKind == "MonsterIntent" and request.metadata.intentKind == "Waiting" then
		shouldSilence = true
		table.insert(reasons, "monster intent supports waiting")
	end
	return shouldSilence, reasons
end

return Model
