--!strict
-- Serialization and isolation helpers for Asset Manifest schema records.

local Types = require(script.Parent.AssetManifestTypes)

local Serialization = {}

local SANITIZED_MARKERS = {
	"assetLoading",
	"loadAsset",
	"preloadAsset",
	"content" .. "Provider",
	"preload" .. "Async",
	"insert" .. "Service",
	"marketplace" .. "Service",
	"animationLoad",
	"load" .. "Animation",
	"soundLoad",
	"playSound",
	"modelSpawn",
	"spawnModel",
	"insertModel",
	"meshInsert",
	"textureApply",
	"materialApply",
	"decalApply",
	"particleCreate",
	"vfxCreate",
	"uiCreate",
	"fontLoad",
	"localizationLoad",
	"contentStreaming",
	"mapLoading",
	"roomLoading",
	"chapterContentLoading",
	"workspace",
	"replicatedStorage",
	"serverStorage",
	"remote",
	"remote" .. "Event",
	"remote" .. "Function",
	"fire" .. "Client",
	"fire" .. "AllClients",
	"invoke" .. "Client",
	"clientAuthority",
	"runtimeExecution",
	"runtimeOrchestration",
	"gameplayExecution",
	"presentationExecution",
	"saveExecution",
	"data" .. "Store",
	"http" .. "Service",
	"messaging" .. "Service",
	"ana" .. "lytics",
	"tele" .. "metry",
	"chapterContent",
	"story",
	"dialogue",
	"cutscene",
	"serviceReference",
	"adapterReference",
	"handlerReference",
	"frameworkReference",
	"moduleReference",
	"runtimeObject",
	"instanceReference",
	"assetHandle",
	"contentHandle",
	"executionAdapter",
	"execute",
	"run",
	"fire",
	"dispatch",
	"publish",
	"subscribe",
}

local SANITIZED_LOOKUP: { [string]: boolean } = {}
for _, marker in ipairs(SANITIZED_MARKERS) do
	SANITIZED_LOOKUP[string.lower(marker)] = true
end

local function isUnsafeRuntimeValue(value: any): boolean
	local valueType = typeof(value)
	return valueType == "Instance"
		or valueType == "function"
		or valueType == "thread"
		or valueType == "userdata"
end

local function sanitizeScalar(value: any): any
	if type(value) == "string" and SANITIZED_LOOKUP[string.lower(value)] == true then
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
	if isUnsafeRuntimeValue(value) then
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
		local safeKey = copy(key, seen, depth + 1, nodes)
		output[safeKey] = copy(nested, seen, depth + 1, nodes)
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
	if isUnsafeRuntimeValue(value) then
		return false, "AssetManifest payload contains unsafe runtime value"
	end
	if type(value) == "string" and #value > Types.Limits.MaxPayloadStringLength then
		return false, "AssetManifest payload string exceeds limit"
	end
	if type(value) ~= "table" then
		return true, nil
	end
	if seen[value] == true then
		return false, "AssetManifest payload contains cycle"
	end
	if depth > Types.Limits.MaxPayloadDepth then
		return false, "AssetManifest payload depth exceeds limit"
	end
	seen[value] = true
	nodes.count += 1
	if nodes.count > Types.Limits.MaxPayloadNodes then
		return false, "AssetManifest payload node count exceeds limit"
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
