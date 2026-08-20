--!strict

local Catalog = require(script.Parent.RobloxGuiAnimationCatalog)
local Decoder = require(script.Parent.RobloxGuiValueDecoder)
local Types = require(script.Parent.RobloxGuiAnimationTypes)

local Validator = {}
local fields = table.freeze({ schemaVersion = true, animationId = true, targetNodeId = true, targetRevision = true, duration = true, delay = true, easingStyle = true, easingDirection = true, repeatCount = true, reverses = true, restoreOnCancel = true, motionEssential = true, goals = true })

local function finite(value: any): boolean
	return type(value) == "number" and value == value and value ~= math.huge and value ~= -math.huge
end

local function identifier(value: any): boolean
	return type(value) == "string" and value ~= "" and #value <= Types.Limits.maxIdentifierLength
end

function Validator.validate(contract: any, instance: Instance?): (boolean, string?, any?)
	if type(contract) ~= "table" or not instance then return false, Types.FailureType.InvalidContract end
	for key in pairs(contract) do if type(key) ~= "string" or not fields[key] then return false, Types.FailureType.InvalidContract end end
	if contract.schemaVersion ~= Types.SchemaVersion or not identifier(contract.animationId) or not identifier(contract.targetNodeId) then return false, Types.FailureType.InvalidContract end
	if type(contract.targetRevision) ~= "number" or contract.targetRevision < 0 or contract.targetRevision % 1 ~= 0 then return false, Types.FailureType.InvalidRevision end
	if not finite(contract.duration) or contract.duration < 0 or contract.duration > Types.Limits.maxDurationSeconds then return false, Types.FailureType.InvalidContract end
	if not finite(contract.delay) or contract.delay < 0 or contract.delay > Types.Limits.maxDelaySeconds then return false, Types.FailureType.InvalidContract end
	if type(contract.repeatCount) ~= "number" or contract.repeatCount < 0 or contract.repeatCount > Types.Limits.maxRepeatCount or contract.repeatCount % 1 ~= 0 then return false, Types.FailureType.InvalidContract end
	if type(contract.reverses) ~= "boolean" or type(contract.restoreOnCancel) ~= "boolean" or type(contract.motionEssential) ~= "boolean" then return false, Types.FailureType.InvalidContract end
	if type(contract.easingStyle) ~= "string" or (Enum.EasingStyle :: any)[contract.easingStyle] == nil then return false, Types.FailureType.InvalidContract end
	if type(contract.easingDirection) ~= "string" or (Enum.EasingDirection :: any)[contract.easingDirection] == nil then return false, Types.FailureType.InvalidContract end
	if type(contract.goals) ~= "table" then return false, Types.FailureType.InvalidGoal end
	local decoded = {}
	local count = 0
	for propertyName, descriptor in pairs(contract.goals) do
		count += 1
		if count > Types.Limits.maxGoalsPerAnimation then return false, Types.FailureType.BudgetExceeded end
		if type(propertyName) ~= "string" or not Catalog.supports(instance.ClassName, propertyName) then return false, Types.FailureType.UnsupportedProperty end
		local ok, value = pcall(Decoder.decodeProperty, propertyName, descriptor)
		if not ok then return false, Types.FailureType.InvalidGoal end
		local valueType = typeof(value)
		if valueType ~= "number" and valueType ~= "Color3" and valueType ~= "UDim2" and valueType ~= "Vector2" then return false, Types.FailureType.InvalidGoal end
		decoded[propertyName] = value
	end
	if count == 0 then return false, Types.FailureType.InvalidGoal end
	return true, nil, decoded
end

return table.freeze(Validator)
