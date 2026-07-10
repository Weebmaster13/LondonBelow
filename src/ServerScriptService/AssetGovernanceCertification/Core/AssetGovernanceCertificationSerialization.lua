--!strict

local Types = require(script.Parent.AssetGovernanceCertificationTypes)

local Serialization = {}

local FORBIDDEN_MARKERS = {
	"load" .. "Asset",
	"preload" .. "Asset",
	"content" .. "Provider",
	"preload" .. "Async",
	"insert" .. "Service",
	"marketplace" .. "Service",
	"stream" .. "Asset",
	"modelSpawn",
	"assetApplication",
	"assetPlayback",
	"createUI",
	"vfxCreate",
	"particleCreate",
	"animationLoad",
	"soundLoad",
	"meshLoad",
	"textureLoad",
	"materialLoad",
	"decalLoad",
	"work" .. "space",
	"replicated" .. "Storage",
	"server" .. "Storage",
	"remote" .. "Event",
	"remote" .. "Function",
	"fire" .. "Client",
	"fire" .. "AllClients",
	"invoke" .. "Client",
	"clientAuthority",
	"data" .. "Store",
	"http" .. "Service",
	"messaging" .. "Service",
	"ana" .. "lytics",
	"tele" .. "metry",
	"gameplayExecution",
	"presentationExecution",
	"saveExecution",
	"chapterContent",
	"mapLoad",
	"roomLoad",
	"dia" .. "logue",
	"cut" .. "scene",
	"callback",
	"eventListener",
	"serviceHandle",
	"runtimeHandle",
	"assetHandle",
	"loadedAsset",
	"moduleReference",
	"executionAdapter",
	"execute",
	"dispatch",
	"publish",
	"subscribe",
	"orchestrate",
	"schedule",
	"authorizeExecution",
	"repairRuntime",
}

local FORBIDDEN_LOOKUP: { [string]: boolean } = {}
for _, marker in ipairs(FORBIDDEN_MARKERS) do
	FORBIDDEN_LOOKUP[string.lower(marker)] = true
end

local function isForbiddenMarker(value: string): boolean
	return FORBIDDEN_LOOKUP[string.lower(value)] == true
end

local function isInstanceShaped(value: any): boolean
	return type(value) == "table" and type(value.ClassName) == "string" and value.Parent ~= nil
end

local function validateValue(
	value: any,
	depth: number,
	seen: { [any]: boolean },
	count: { value: number }
): (boolean, string?)
	local valueType = type(value)
	if valueType == "nil" or valueType == "boolean" or valueType == "number" then
		return true, nil
	end
	if valueType == "string" then
		if #value > Types.Limits.MaxStringLength then
			return false, "AssetGovernanceCertification payload string exceeds limit"
		end
		if isForbiddenMarker(value) then
			return false, "AssetGovernanceCertification payload contains forbidden marker"
		end
		return true, nil
	end
	if valueType == "function" or valueType == "thread" or valueType == "userdata" then
		return false, "AssetGovernanceCertification payload contains unsafe runtime value"
	end
	if valueType ~= "table" then
		return false, "AssetGovernanceCertification payload contains unsupported value"
	end
	if seen[value] then
		return false, "AssetGovernanceCertification payload contains cycle"
	end
	if isInstanceShaped(value) then
		return false, "AssetGovernanceCertification payload contains instance-shaped table"
	end
	if depth > Types.Limits.MaxPayloadDepth then
		return false, "AssetGovernanceCertification payload depth exceeds limit"
	end
	count.value += 1
	if count.value > Types.Limits.MaxPayloadNodes then
		return false, "AssetGovernanceCertification payload node count exceeds limit"
	end
	seen[value] = true
	for key, nested in pairs(value) do
		if
			type(key) == "string"
			and (#key > Types.Limits.MaxStringLength or isForbiddenMarker(key))
		then
			return false, "AssetGovernanceCertification payload contains unsafe key"
		end
		local ok, reason = validateValue(nested, depth + 1, seen, count)
		if not ok then
			return false, reason
		end
	end
	seen[value] = nil
	return true, nil
end

function Serialization.validateSerializable(value: any): (boolean, string?)
	return validateValue(value, 0, {}, { value = 0 })
end

function Serialization.deepCopy(value: any, seen: { [any]: any }?): any
	if type(value) ~= "table" then
		return value
	end
	local activeSeen = seen or {}
	if activeSeen[value] then
		return activeSeen[value]
	end
	local copy = {}
	activeSeen[value] = copy
	for key, nested in pairs(value) do
		copy[Serialization.deepCopy(key, activeSeen)] = Serialization.deepCopy(nested, activeSeen)
	end
	return copy
end

local function diagnosticCopyValue(
	value: any,
	depth: number,
	seen: { [any]: boolean },
	count: { value: number }
): any
	local valueType = type(value)
	if valueType == "string" then
		if #value > Types.Limits.MaxStringLength then
			return "<oversized-string>"
		end
		if isForbiddenMarker(value) then
			return "<unsafe-marker>"
		end
		return value
	end
	if valueType == "number" or valueType == "boolean" or valueType == "nil" then
		return value
	end
	if valueType == "function" or valueType == "thread" or valueType == "userdata" then
		return "<unsafe-runtime-value>"
	end
	if valueType ~= "table" then
		return "<unsupported-value>"
	end
	if seen[value] then
		return "<cycle>"
	end
	if isInstanceShaped(value) then
		return "<instance-shaped-table>"
	end
	if depth > Types.Limits.MaxPayloadDepth then
		return "<max-depth>"
	end
	count.value += 1
	if count.value > Types.Limits.MaxPayloadNodes then
		return "<max-nodes>"
	end
	seen[value] = true
	local copy = {}
	for key, nested in pairs(value) do
		local safeKey = if type(key) == "string" and isForbiddenMarker(key)
			then "<unsafe-marker>"
			else key
		copy[safeKey] = diagnosticCopyValue(nested, depth + 1, seen, count)
	end
	seen[value] = nil
	return copy
end

function Serialization.diagnosticCopy(value: any): any
	return diagnosticCopyValue(value, 0, {}, { value = 0 })
end

return Serialization
