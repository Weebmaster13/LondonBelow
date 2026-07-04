--!strict

local Types = require(script.Parent.AssetRuntimeGateTypes)

local Serialization = {}

local BLOCKED = {
	"load" .. "Asset",
	"preload" .. "Asset",
	"content" .. "Provider",
	"preload" .. "Async",
	"insert" .. "Service",
	"marketplace" .. "Service",
	"animationLoad",
	"soundLoad",
	"meshLoad",
	"textureLoad",
	"materialLoad",
	"decalLoad",
	"modelSpawn",
	"assetApplication",
	"assetPlayback",
	"create" .. "Instance",
	"createUI",
	"vfxCreate",
	"particleCreate",
	"work" .. "space",
	"replicated" .. "Storage",
	"server" .. "Storage",
	"data" .. "Store",
	"http" .. "Service",
	"messaging" .. "Service",
	"remote" .. "Event",
	"remote" .. "Function",
	"fire" .. "Client",
	"fire" .. "AllClients",
	"invoke" .. "Client",
	"clientAuthority",
	"gameplayExecution",
	"presentationExecution",
	"saveExecution",
	"chapterContent",
	"cutscene",
	"dialogue",
	"mapLoad",
	"roomLoad",
	"ana" .. "lytics",
	"tele" .. "metry",
	"runtimeObject",
	"serviceHandle",
	"assetHandle",
	"loadedAsset",
	"moduleReference",
	"callback",
	"eventListener",
	"executionAdapter",
	"execute",
	"dispatch",
	"publish",
	"subscribe",
}

local BLOCKED_LOOKUP: { [string]: boolean } = {}
for _, marker in ipairs(BLOCKED) do
	BLOCKED_LOOKUP[string.lower(marker)] = true
end

local function isUnsafeRuntimeValue(value: any): boolean
	local valueType = typeof(value)
	return valueType == "Instance"
		or valueType == "function"
		or valueType == "thread"
		or valueType == "userdata"
end

local function isInstanceShaped(value: any): boolean
	return type(value) == "table"
		and type(value.ClassName) == "string"
		and (value.Parent ~= nil or value.IsA ~= nil or value.GetFullName ~= nil)
end

local function sanitizeScalar(value: any): any
	if type(value) == "string" and BLOCKED_LOOKUP[string.lower(value)] == true then
		return "<unsafe-marker>"
	end
	return value
end

local function copy(
	value: any,
	seen: { [any]: boolean },
	depth: number,
	nodes: { count: number }
): any
	if isUnsafeRuntimeValue(value) or isInstanceShaped(value) then
		return "<unsafe-runtime-value>"
	end
	if type(value) ~= "table" then
		return sanitizeScalar(value)
	end
	if seen[value] == true or depth > Types.Limits.MaxPayloadDepth then
		return "<unsafe-table>"
	end
	seen[value] = true
	nodes.count += 1
	if nodes.count > Types.Limits.MaxPayloadNodes then
		return "<oversized-table>"
	end
	local output = {}
	for key, nested in pairs(value) do
		output[copy(key, seen, depth + 1, nodes)] = copy(nested, seen, depth + 1, nodes)
	end
	seen[value] = nil
	return output
end

local function validate(
	value: any,
	seen: { [any]: boolean },
	depth: number,
	nodes: { count: number }
): (boolean, string?)
	if isUnsafeRuntimeValue(value) or isInstanceShaped(value) then
		return false, "AssetRuntimeGate payload contains unsafe runtime value"
	end
	if type(value) == "string" and #value > Types.Limits.MaxStringLength then
		return false, "AssetRuntimeGate payload string exceeds limit"
	end
	if type(value) ~= "table" then
		return true, nil
	end
	if seen[value] == true then
		return false, "AssetRuntimeGate payload contains cycle"
	end
	if depth > Types.Limits.MaxPayloadDepth then
		return false, "AssetRuntimeGate payload depth exceeds limit"
	end
	seen[value] = true
	nodes.count += 1
	if nodes.count > Types.Limits.MaxPayloadNodes then
		return false, "AssetRuntimeGate payload node count exceeds limit"
	end
	for key, nested in pairs(value) do
		local keyOk, keyReason = validate(key, seen, depth + 1, nodes)
		if not keyOk then
			return false, keyReason
		end
		local nestedOk, nestedReason = validate(nested, seen, depth + 1, nodes)
		if not nestedOk then
			return false, nestedReason
		end
	end
	seen[value] = nil
	return true, nil
end

function Serialization.validateSerializable(value: any): (boolean, string?)
	return validate(value, {}, 0, { count = 0 })
end

function Serialization.deepCopy(value: any): any
	return copy(value, {}, 0, { count = 0 })
end

function Serialization.diagnosticCopy(value: any): any
	return copy(value, {}, 0, { count = 0 })
end

return Serialization
