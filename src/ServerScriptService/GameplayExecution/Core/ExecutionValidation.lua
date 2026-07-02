--!strict
-- Request validation for the dry-run-only Gameplay Execution Bridge.

local Serialization = require(script.Parent.ExecutionSerialization)
local Types = require(script.Parent.ExecutionTypes)

local Validation = {}

local FORBIDDEN_FIELDS = {
	"animation",
	"attack",
	"audio",
	"chapter",
	"chapter0",
	"chapter1",
	"client",
	"combat",
	"cutscene",
	"damage",
	"dialogue",
	"door",
	"finalDialogue",
	"finalStory",
	"horrorPacing",
	"instance",
	"lighting",
	"monster",
	"monsterAI",
	"move",
	"movement",
	"path",
	"pathfinding",
	"physics",
	"play",
	"remote",
	"save",
	"sound",
	"spawn",
	"story",
	"teleport",
	"ui",
	"workspace",
}

local function validId(value: any): boolean
	return type(value) == "string"
		and value ~= ""
		and #value <= 140
		and string.match(value, "^[%w%._%-:]+$") ~= nil
end

local function forbidden(payload: any, depth: number): (boolean, string?)
	if type(payload) ~= "table" then
		return true, nil
	end
	if depth > Types.Limits.MaxPayloadDepth then
		return false, "execution payload depth exceeds limit"
	end
	for _, field in ipairs(FORBIDDEN_FIELDS) do
		if payload[field] ~= nil then
			return false, "execution payload contains forbidden field: " .. field
		end
	end
	for _, nested in pairs(payload) do
		local ok, reason = forbidden(nested, depth + 1)
		if not ok then
			return false, reason
		end
	end
	return true, nil
end

function Validation.safePayload(payload: any): (boolean, string?)
	local ok, reason = Serialization.validateSerializable(payload)
	if not ok then
		return false, reason
	end
	return forbidden(payload, 0)
end

function Validation.id(value: any): boolean
	return validId(value)
end

function Validation.request(request: any, currentTime: number): (boolean, string?)
	if type(request) ~= "table" then
		return false, "execution request must be a table"
	end
	local safe, safeReason = Validation.safePayload(request)
	if not safe then
		return false, safeReason
	end
	if not validId(request.executionId) then
		return false, "executionId is required"
	end
	if not validId(request.requester) then
		return false, "requester is required"
	end
	if not validId(request.sourceSystem) then
		return false, "sourceSystem is required"
	end
	if
		not validId(request.executionType)
		or not Types.SupportedExecutionTypes[request.executionType]
	then
		return false, "unsupported execution type"
	end
	if type(request.priority) ~= "number" or request.priority ~= request.priority then
		return false, "priority must be a number"
	end
	if request.priority < 0 or request.priority > Types.Limits.MaxPriority then
		return false, "priority is outside bounds"
	end
	if type(request.createdAt) ~= "number" or request.createdAt ~= request.createdAt then
		return false, "createdAt must be a number"
	end
	if type(request.expiresAt) ~= "number" or request.expiresAt ~= request.expiresAt then
		return false, "expiresAt must be a number"
	end
	if request.expiresAt <= currentTime then
		return false, "execution request is expired"
	end
	if type(request.approvals) ~= "table" or next(request.approvals) == nil then
		return false, "missing approvals"
	end
	if type(request.dependencies) ~= "table" or next(request.dependencies) == nil then
		return false, "missing dependencies"
	end
	return true, nil
end

function Validation.validate(): (boolean, string?)
	if Types.Mode ~= "ServerAuthoritativeDryRunGateway" then
		return false, "Gameplay Execution Bridge must remain server-authoritative dry-run gateway"
	end
	return true, nil
end

return Validation
