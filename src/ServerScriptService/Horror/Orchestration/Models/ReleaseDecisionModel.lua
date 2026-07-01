--!strict
-- Release lowers pressure intentionally after sustained or meaningful tension.

local Config = require(script.Parent.Parent.Core.HorrorOrchestrationConfig)

local Model = {}

function Model.evaluate(budget: any, request: any)
	local reasons = {}
	local shouldRelease = false
	if budget.releaseNeed >= Config.ReleaseNeedThreshold then
		shouldRelease = true
		table.insert(reasons, "release need is high")
	end
	if request.requestKind == "ReleaseRequest" then
		shouldRelease = true
		table.insert(reasons, "explicit release request")
	end
	if request.metadata and request.metadata.repeatedFailure == true then
		shouldRelease = true
		table.insert(reasons, "repeated player failure needs release")
	end
	return shouldRelease, reasons
end

return Model
