--!strict

local Config = require(script.Parent.GameplayExecutionConfig)

local GameplayExecutionValidator = {}

local trustedSources = {
	GameplayCoordinator = true,
	DoorService = true,
	ObjectRuntime = true,
	PuzzleService = true,
	ObjectiveService = true,
	InventoryService = true,
	KeyService = true,
	DirectorCoordinator = true,
	SimulationService = true,
	SelfCheck = true,
}

local function validatePlainValue(value: any, depth: number): boolean
	if depth > Config.MaxPayloadDepth then
		return false
	end
	local valueType = typeof(value)
	if valueType == "string" then
		return #value <= 300
	elseif valueType == "number" then
		return value == value and math.abs(value) < 1000000
	elseif valueType == "boolean" or value == nil then
		return true
	elseif valueType == "table" then
		local count = 0
		for key, child in pairs(value) do
			count += 1
			if count > Config.MaxPayloadKeys then
				return false
			end
			if type(key) ~= "string" and type(key) ~= "number" then
				return false
			end
			if not validatePlainValue(child, depth + 1) then
				return false
			end
		end
		return true
	end
	return false
end

function GameplayExecutionValidator.validateAdapter(adapter: any): (boolean, string?)
	if type(adapter) ~= "table" then
		return false, "adapter must be a table"
	end
	for _, methodName in ipairs({
		"canApply",
		"apply",
		"rollback",
		"getHealth",
		"getDiagnostics",
		"describe",
	}) do
		if type(adapter[methodName]) ~= "function" then
			return false, "adapter missing method: " .. methodName
		end
	end
	return true, nil
end

function GameplayExecutionValidator.validateRequest(request: any, now: number): (boolean, string?)
	if type(request) ~= "table" then
		return false, "execution request must be a table"
	end
	if type(request.executionId) ~= "string" or request.executionId == "" then
		return false, "executionId is required"
	end
	if type(request.sourceSystem) ~= "string" or trustedSources[request.sourceSystem] ~= true then
		return false, "sourceSystem is not a trusted server source"
	end
	if type(request.targetObjectId) ~= "string" or request.targetObjectId == "" then
		return false, "targetObjectId is required"
	end
	if
		type(request.executionKind) ~= "string"
		or Config.AllowedExecutionKinds[request.executionKind] ~= true
	then
		return false, "executionKind is not allowed"
	end
	if
		Config.ApprovalRequiredKinds[request.executionKind]
		and (type(request.approvedBy) ~= "string" or request.approvedBy == "")
	then
		return false, "executionKind requires Director approval metadata"
	end
	if type(request.createdAt) ~= "number" then
		return false, "createdAt is required"
	end
	if type(request.expiresAt) ~= "number" then
		return false, "expiresAt is required"
	end
	if request.expiresAt <= now then
		return false, "execution request is expired"
	end
	if request.expiresAt < request.createdAt then
		return false, "expiresAt must be after createdAt"
	end
	if type(request.priority) ~= "number" then
		return false, "priority is required"
	end
	if not validatePlainValue(request.payload or {}, 0) then
		return false, "payload contains unsafe values"
	end
	if not validatePlainValue(request.metadata or {}, 0) then
		return false, "metadata contains unsafe values"
	end
	if type(request.tags) ~= "table" then
		return false, "tags must be an array"
	end
	return true, nil
end

function GameplayExecutionValidator.validate(): (boolean, string?)
	if
		Config.DefaultMode ~= "Disabled"
		and Config.DefaultMode ~= "DryRun"
		and Config.DefaultMode ~= "Enabled"
	then
		return false, "DefaultMode is invalid"
	end
	if Config.PhysicalMutationEnabled == true and Config.DefaultMode ~= "Enabled" then
		return false, "PhysicalMutationEnabled requires Enabled mode"
	end
	return true, nil
end

return GameplayExecutionValidator
