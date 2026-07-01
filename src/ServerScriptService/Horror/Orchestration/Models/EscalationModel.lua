--!strict
-- Escalation eligibility, approval-only.

local Config = require(script.Parent.Parent.Core.HorrorOrchestrationConfig)

local Model = {}

function Model.evaluate(budget: any, request: any)
	local reasons = {}
	if request.metadata and request.metadata.playerOverloaded == true then
		return false, { "player overload suppresses escalation" }
	end
	if budget.currentPressure >= Config.HighPressureThreshold then
		return false, { "pressure already high" }
	end
	if request.pressure >= 45 and request.meaning ~= nil then
		table.insert(reasons, "meaningful pressure supports escalation")
		return true, reasons
	end
	return false, { "escalation not earned" }
end

return Model
