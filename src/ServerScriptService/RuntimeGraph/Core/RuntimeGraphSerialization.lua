--!strict
-- Defensive serialization for Runtime Graph schemas, diagnostics, and snapshots.

local Types = require(script.Parent.RuntimeGraphTypes)

local Serialization = {}

local SENSITIVE_DIAGNOSTIC_FIELDS = {
	"adapterReference",
	"analytics",
	"analyticsCollection",
	"assetLoading",
	"callRuntime",
	"callback",
	"chapter0Content",
	"chapterContent",
	"clientAuthority",
	"contentLoading",
	"cutscene",
	"dataStore",
	"dataStoreRead",
	"dataStoreWrite",
	"dependencyInjection",
	"dependencyInjectionExecution",
	"executableCallback",
	"execute",
	"executionAdapter",
	"executionGroup",
	"executionPermission",
	"fireAllClients",
	"fireClient",
	"frameworkMutation",
	"frameworkReplacement",
	"frameworkReference",
	"gameplayExecution",
	"handlerReference",
	"http",
	"httpService",
	"initializationExecution",
	"initializeRuntime",
	"instanceReference",
	"invokeClient",
	"lifecycleExecution",
	"liveSystemMutation",
	"loadModule",
	"mapLoading",
	"messaging",
	"messagingService",
	"moduleLoading",
	"moduleReference",
	"narrativeExecution",
	"orchestrationExecution",
	"presentationExecution",
	"puzzleExecution",
	"remote",
	"remoteEvent",
	"remoteFunction",
	"require",
	"requireCall",
	"resolveService",
	"roomLoading",
	"runtimeApiCall",
	"runtimeObject",
	"savePersistence",
	"serviceReference",
	"serviceResolution",
	"shutdownExecution",
	"shutdownRuntime",
	"startupExecution",
	"startRuntime",
	"telemetry",
	"telemetrySending",
	"workspace",
	"workspacePath",
	"adapterLoading",
	"enforcement",
	"migrationExecution",
	"serviceLookup",
}

local SENSITIVE_LOOKUP: { [string]: boolean } = {}

for _, field in ipairs(SENSITIVE_DIAGNOSTIC_FIELDS) do
	SENSITIVE_LOOKUP[string.lower(field)] = true
end

local function sanitizeString(value: string): string
	if SENSITIVE_LOOKUP[string.lower(value)] == true then
		return "<sanitized:runtime-graph-boundary>"
	end
	return value
end

function Serialization.deepCopy(value: any, seen: { [any]: any }?): any
	if type(value) ~= "table" then
		return value
	end
	local refs = seen or {}
	if refs[value] ~= nil then
		return refs[value]
	end
	local copy = {}
	refs[value] = copy
	for key, nested in pairs(value) do
		copy[Serialization.deepCopy(key, refs)] = Serialization.deepCopy(nested, refs)
	end
	return copy
end

function Serialization.validateSerializable(
	value: any,
	seen: { [any]: boolean }?,
	depth: number?,
	nodeCount: { count: number }?
): (boolean, string?)
	if typeof ~= nil and typeof(value) == "Instance" then
		return false, "Runtime Graph payload cannot contain Roblox Instances"
	end
	local valueType = type(value)
	if valueType == "function" or valueType == "thread" or valueType == "userdata" then
		return false, "Runtime Graph payload cannot contain unsafe runtime values"
	end
	if valueType == "string" and #value > Types.Limits.MaxPayloadStringLength then
		return false, "Runtime Graph payload string exceeds limit"
	end
	if valueType ~= "table" then
		return true, nil
	end
	local currentDepth = depth or 0
	if currentDepth > Types.Limits.MaxPayloadDepth then
		return false, "Runtime Graph payload depth exceeds limit"
	end
	local counter = nodeCount or { count = 0 }
	counter.count += 1
	if counter.count > Types.Limits.MaxPayloadNodes then
		return false, "Runtime Graph payload node count exceeds limit"
	end
	local refs = seen or {}
	if refs[value] == true then
		return false, "Runtime Graph payload cannot contain cyclic tables"
	end
	refs[value] = true
	for key, nested in pairs(value) do
		local keyOk, keyReason =
			Serialization.validateSerializable(key, refs, currentDepth + 1, counter)
		if not keyOk then
			return false, keyReason
		end
		local nestedOk, nestedReason =
			Serialization.validateSerializable(nested, refs, currentDepth + 1, counter)
		if not nestedOk then
			return false, nestedReason
		end
	end
	refs[value] = nil
	return true, nil
end

function Serialization.diagnosticCopy(value: any, seen: { [any]: boolean }?, depth: number?): any
	if typeof ~= nil and typeof(value) == "Instance" then
		return "<RobloxInstance>"
	end
	local valueType = type(value)
	if valueType == "function" or valueType == "thread" or valueType == "userdata" then
		return "<unsafe:" .. valueType .. ">"
	end
	if valueType == "string" and #value > Types.Limits.MaxPayloadStringLength then
		return string.sub(value, 1, Types.Limits.MaxPayloadStringLength) .. "<truncated>"
	end
	if valueType == "string" then
		return sanitizeString(value)
	end
	if valueType ~= "table" then
		return value
	end
	local currentDepth = depth or 0
	if currentDepth > Types.Limits.MaxPayloadDepth then
		return "<max-depth>"
	end
	local refs = seen or {}
	if refs[value] == true then
		return "<cycle>"
	end
	refs[value] = true
	local copy = {}
	local count = 0
	for key, nested in pairs(value) do
		count += 1
		if count > Types.Limits.MaxPayloadNodes then
			copy["<truncated>"] = "max nodes reached"
			break
		end
		local diagnosticKey = Serialization.diagnosticCopy(key, refs, currentDepth + 1)
		if
			type(diagnosticKey) == "string"
			and diagnosticKey == "<sanitized:runtime-graph-boundary>"
		then
			diagnosticKey = "<sanitized-key>"
		end
		copy[diagnosticKey] = Serialization.diagnosticCopy(nested, refs, currentDepth + 1)
	end
	refs[value] = nil
	return copy
end

return Serialization
