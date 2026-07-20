--!strict

local Serialization = require(script.Parent.EnvironmentalSerialization)
local Types = require(script.Parent.EnvironmentalTypes)

local Validation = {}

local function id(value: any): boolean
	return type(value) == "string"
		and value ~= ""
		and #value <= 140
		and string.match(value, "^[%w%._%-:]+$") ~= nil
end

local function family(value: any): boolean
	for _, familyId in pairs(Types.Family) do
		if value == familyId then
			return true
		end
	end
	return false
end

local function action(value: any): boolean
	for _, actionId in pairs(Types.Action) do
		if value == actionId then
			return true
		end
	end
	return false
end

function Validation.id(value: any): boolean
	return id(value)
end

function Validation.definition(definition: any): (boolean, string?)
	if type(definition) ~= "table" then
		return false, Types.ResultCode.EnvironmentConfigurationInvalid
	end
	local safe, reason = Serialization.validate(definition)
	if not safe then
		return false, reason
	end
	if not id(definition.id) or not id(definition.interactionTargetId) then
		return false, Types.ResultCode.EnvironmentConfigurationInvalid
	end
	if not family(definition.family) then
		return false, Types.ResultCode.EnvironmentFamilyNotFound
	end
	if
		type(definition.supportedActions) ~= "table"
		or #definition.supportedActions == 0
		or #definition.supportedActions > Types.Limits.MaxActions
	then
		return false, Types.ResultCode.EnvironmentActionUnsupported
	end
	for _, actionId in ipairs(definition.supportedActions) do
		if not action(actionId) then
			return false, Types.ResultCode.EnvironmentActionUnsupported
		end
	end
	if type(definition.initialState) ~= "string" then
		return false, Types.ResultCode.EnvironmentStateInvalid
	end
	if
		definition.presentationMetadata ~= nil
		and type(definition.presentationMetadata) ~= "table"
	then
		return false, Types.ResultCode.EnvironmentConfigurationInvalid
	end
	if definition.dependency ~= nil and type(definition.dependency) ~= "table" then
		return false, Types.ResultCode.EnvironmentDependencyMissing
	end
	return true, nil
end

function Validation.request(request: any): (boolean, string?)
	if type(request) ~= "table" then
		return false, Types.ResultCode.EnvironmentConfigurationInvalid
	end
	if not id(request.objectId) or not id(request.actionId) or not id(request.requestId) then
		return false, Types.ResultCode.EnvironmentConfigurationInvalid
	end
	return true, nil
end

return Validation
