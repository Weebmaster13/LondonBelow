--!strict
-- Validation for orchestration contracts and decision safety.

local Config = require(script.Parent.HorrorOrchestrationConfig)

local Validator = {}

local function validId(value: any): boolean
	return type(value) == "string" and value ~= "" and #value <= 140
end

function Validator.isValidId(value: any): boolean
	return validId(value)
end

function Validator.validateScore(value: any, name: string): (boolean, string?)
	if type(value) ~= "number" or value ~= value then
		return false, name .. " must be a number"
	end
	if value < 0 or value > 100 then
		return false, name .. " must be between 0 and 100"
	end
	return true, nil
end

function Validator.validateRequest(request: any, currentTime: number): (boolean, string?)
	if type(request) ~= "table" then
		return false, "pressure request must be a table"
	end
	if not validId(request.requestId) then
		return false, "requestId is required"
	end
	if not validId(request.sourceSystem) then
		return false, "sourceSystem is required"
	end
	if Config.ValidRequestKinds[request.requestKind] ~= true then
		return false, "requestKind is not allowed"
	end
	local pressureOk, pressureReason = Validator.validateScore(request.pressure, "pressure")
	if not pressureOk then
		return false, pressureReason
	end
	local priorityOk, priorityReason = Validator.validateScore(request.priority, "priority")
	if not priorityOk then
		return false, priorityReason
	end
	if type(request.createdAt) ~= "number" or type(request.expiresAt) ~= "number" then
		return false, "createdAt and expiresAt are required"
	end
	if request.expiresAt <= currentTime then
		return false, "pressure request is expired"
	end
	if currentTime - request.createdAt > Config.MaxRequestAgeSeconds then
		return false, "pressure request is stale"
	end
	if request.workspace ~= nil or request.pathfinding ~= nil or request.remote ~= nil then
		return false, "pressure request contains unsafe execution fields"
	end
	return true, nil
end

function Validator.validateBundle(bundle: any): (boolean, string?)
	if type(bundle) ~= "table" then
		return false, "coordination bundle must be a table"
	end
	if Config.ValidActions[bundle.action] ~= true then
		return false, "orchestration action is not allowed"
	end
	if type(bundle.reasons) ~= "table" or #bundle.reasons == 0 then
		return false, "coordination bundle requires reasons"
	end
	if type(bundle.requests) ~= "table" then
		return false, "coordination bundle requires approval-only requests"
	end
	for _, item in ipairs(bundle.requests) do
		if type(item) ~= "table" or item.approvalOnly ~= true then
			return false, "coordination bundle item must be approval-only"
		end
		if item.executionAllowed ~= false then
			return false, "coordination bundle item must explicitly disallow execution"
		end
		if
			item.execute ~= nil
			or item.apply ~= nil
			or item.mutate ~= nil
			or item.workspace ~= nil
			or item.remote ~= nil
		then
			return false, "coordination bundle item contains execution fields"
		end
	end
	return true, nil
end

function Validator.validate(): (boolean, string?)
	if Config.DefaultMode ~= "ApprovalOnly" then
		return false, "Horror Orchestration must remain approval-only"
	end
	if Config.MaxPressure ~= 100 or Config.MinPressure ~= 0 then
		return false, "pressure bounds must remain 0..100"
	end
	return true, nil
end

return Validator
