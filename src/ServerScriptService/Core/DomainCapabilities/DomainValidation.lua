--!strict

local Serialization = require(script.Parent.DomainSerialization)
local Types = require(script.Parent.DomainCapabilityTypes)

local Validation = {}

local definitionFields = {
	authority = true,
	capabilityId = true,
	dependencies = true,
	diagnosticsProvider = true,
	domain = true,
	healthProvider = true,
	interfaces = true,
	metadata = true,
	owner = true,
	snapshotProvider = true,
	version = true,
	workflowParticipation = true,
}

local interfaceFields = {
	interfaceId = true,
	methods = true,
	version = true,
}

local dependencyFields = {
	capabilityId = true,
	interfaceId = true,
	minVersion = true,
	required = true,
}

local unsafeKeys = {
	analytics = true,
	clientauthority = true,
	commandexecutor = true,
	datastore = true,
	fireclient = true,
	fireevent = true,
	fireserver = true,
	http = true,
	implementation = true,
	instance = true,
	messagingservice = true,
	mutateworkspace = true,
	remote = true,
	telemetry = true,
	workspace = true,
}

local function isId(value: any): boolean
	return type(value) == "string" and value:match("^[%w%.:%-_]+$") ~= nil and #value <= 128
end

local function boundedString(value: any): boolean
	return type(value) == "string" and #value > 0 and #value <= Types.Limits.MaxStringLength
end

local function isList(value: any): boolean
	if type(value) ~= "table" then
		return false
	end
	local count = 0
	for key in pairs(value) do
		if type(key) ~= "number" or key < 1 or key % 1 ~= 0 then
			return false
		end
		count += 1
	end
	return count == #value
end

local function supported(map: { [string]: string }, value: any): boolean
	for _, item in pairs(map) do
		if value == item then
			return true
		end
	end
	return false
end

local function scanUnsafe(value: any, depth: number, nodes: { count: number }): (boolean, string?)
	if depth > Types.Limits.MaxPayloadDepth then
		return false, "payload depth exceeded"
	end
	if type(value) ~= "table" then
		if type(value) == "function" or type(value) == "thread" or type(value) == "userdata" then
			return false, "unsafe value type"
		end
		if type(value) == "string" and #value > Types.Limits.MaxStringLength then
			return false, "string length exceeded"
		end
		return true, nil
	end
	nodes.count += 1
	if nodes.count > Types.Limits.MaxPayloadNodes then
		return false, "payload node limit exceeded"
	end
	for key, item in pairs(value) do
		if type(key) == "string" and unsafeKeys[string.lower(key)] then
			return false, Types.FailureType.UnsafePayload
		end
		local ok, reason = scanUnsafe(item, depth + 1, nodes)
		if not ok then
			return false, reason
		end
	end
	return true, nil
end

local function validateInterface(record: any): (boolean, string?)
	if type(record) ~= "table" then
		return false, "interface must be a table"
	end
	for key in pairs(record) do
		if not interfaceFields[key] then
			return false, "unknown interface field: " .. tostring(key)
		end
	end
	for key in pairs(interfaceFields) do
		if record[key] == nil then
			return false, "missing interface field: " .. key
		end
	end
	if not isId(record.interfaceId) or not boundedString(record.version) then
		return false, "invalid interface id or version"
	end
	if
		not isList(record.methods)
		or #record.methods > Types.Limits.MaxServiceMethodsPerInterface
	then
		return false, "methods must be a bounded array"
	end
	local seen = {}
	for _, method in ipairs(record.methods) do
		if not isId(method) or seen[method] then
			return false, "invalid or duplicate service method"
		end
		seen[method] = true
	end
	return true, nil
end

local function validateDependency(record: any): (boolean, string?)
	if type(record) ~= "table" then
		return false, "dependency must be a table"
	end
	for key in pairs(record) do
		if not dependencyFields[key] then
			return false, "unknown dependency field: " .. tostring(key)
		end
	end
	for key in pairs(dependencyFields) do
		if record[key] == nil then
			return false, "missing dependency field: " .. key
		end
	end
	if
		not isId(record.capabilityId)
		or not isId(record.interfaceId)
		or not boundedString(record.minVersion)
		or type(record.required) ~= "boolean"
	then
		return false, "invalid dependency"
	end
	return true, nil
end

function Validation.definition(definition: any): (boolean, string?)
	if type(definition) ~= "table" then
		return false, "domain capability definition must be a table"
	end
	for key in pairs(definition) do
		if not definitionFields[key] then
			return false, "unknown domain capability field: " .. tostring(key)
		end
	end
	for key in pairs(definitionFields) do
		if definition[key] == nil then
			return false, "missing domain capability field: " .. key
		end
	end
	if
		not isId(definition.capabilityId)
		or not boundedString(definition.version)
		or not boundedString(definition.owner)
	then
		return false, "invalid capability id, version, or owner"
	end
	if not supported(Types.Domain, definition.domain) then
		return false, Types.FailureType.UnsupportedDomain
	end
	if not supported(Types.Authority, definition.authority) then
		return false, Types.FailureType.UnsupportedAuthority
	end
	if not supported(Types.WorkflowParticipation, definition.workflowParticipation) then
		return false, Types.FailureType.UnsupportedWorkflowParticipation
	end
	if type(definition.metadata) ~= "table" then
		return false, "metadata must be a table"
	end
	if
		not boundedString(definition.healthProvider)
		or not boundedString(definition.diagnosticsProvider)
		or not boundedString(definition.snapshotProvider)
	then
		return false, "provider names must be strings"
	end
	if
		not isList(definition.interfaces)
		or #definition.interfaces == 0
		or #definition.interfaces > Types.Limits.MaxInterfacesPerDomain
	then
		return false, "interfaces must be a bounded non-empty array"
	end
	local interfaceIds = {}
	for _, interfaceRecord in ipairs(definition.interfaces) do
		local ok, reason = validateInterface(interfaceRecord)
		if not ok then
			return false, reason
		end
		if interfaceIds[interfaceRecord.interfaceId] then
			return false, "duplicate interface id"
		end
		interfaceIds[interfaceRecord.interfaceId] = true
	end
	if
		not isList(definition.dependencies)
		or #definition.dependencies > Types.Limits.MaxDependenciesPerDomain
	then
		return false, "dependencies must be a bounded array"
	end
	for _, dependency in ipairs(definition.dependencies) do
		local ok, reason = validateDependency(dependency)
		if not ok then
			return false, reason
		end
	end
	return scanUnsafe(definition, 0, { count = 0 })
end

function Validation.copy(value: any): any
	return Serialization.freezeCopy(value)
end

return Validation
