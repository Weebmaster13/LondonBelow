--!strict

local Types = require(script.Parent.AssetExecutionAdapterTypes)

local Serialization = {}

local FORBIDDEN_MARKERS = {
	"load" .. "Asset",
	"preload" .. "Asset",
	"stream" .. "Asset",
	"spawn" .. "Asset",
	"apply" .. "Asset",
	"display" .. "Asset",
	"play" .. "Asset",
	"asset" .. "Handle",
	"asset" .. "Operation",
	"work" .. "space",
	"storage" .. "Mutation",
	"remote" .. "Event",
	"remote" .. "Function",
	"net" .. "work" .. "Runtime",
	"net" .. "working",
	"client" .. "Authority",
	"network" .. "Ownership",
	"physics" .. "Execution",
	"data" .. "Store",
	"persist" .. "ence",
	"http" .. "Service",
	"messaging" .. "Service",
	"ana" .. "lytics",
	"tele" .. "metry",
	"gameplay" .. "Run",
	"presentation" .. "Run",
	"save" .. "Run",
	"chapter" .. "Content",
	"map" .. "Content",
	"room" .. "Content",
	"dia" .. "logue" .. "Content",
	"cutscene" .. "Content",
	"approval" .. "Token",
	"permission" .. "Token",
	"execution" .. "Token",
	"execution" .. "Grant",
	"execution" .. "Command",
	"routing" .. "Table",
	"dispatch" .. "Target",
	"dispatcher" .. "Handle",
	"scheduler" .. "Handle",
	"orchestrator" .. "Handle",
	"scheduler" .. "Queue",
	"execution" .. "Queue",
	"execution" .. "Route",
	"execution" .. "Dispatch",
	"execution" .. "Scheduling",
	"execution" .. "Orchestration",
	"runtime" .. "Reference",
	"registry" .. "Reference",
	"execution" .. "Reference",
	"executable" .. "Reference",
	"asset" .. "Operation" .. "Reference",
	"gameplay" .. "Reference",
	"presentation" .. "Reference",
	"save" .. "Reference",
	"chapter" .. "Reference",
	"adapter" .. "Implementation",
	"adapter" .. "Callback",
	"adapter" .. "Listener",
	"adapter" .. "Registry",
	"adapter" .. "Activation",
	"adapter" .. "Resolution",
	"adapter" .. "Service",
	"adapter" .. "Manager",
	"adapter" .. "Loader",
	"adapter" .. "Factory",
	"runtime" .. "Handle",
	"execution" .. "Handle",
	"registry" .. "Handle",
	"service" .. "Reference",
	"manager" .. "Reference",
	"loader" .. "Reference",
	"factory" .. "Reference",
	"callback",
	"listener",
	"handler",
}

local forbiddenLookup: { [string]: boolean } = {}
for _, marker in ipairs(FORBIDDEN_MARKERS) do
	forbiddenLookup[string.lower(marker)] = true
end

local function isForbiddenMarker(value: string): boolean
	return forbiddenLookup[string.lower(value)] == true
end

local function isInstanceShaped(value: any): boolean
	return type(value) == "table"
		and type(value.ClassName) == "string"
		and value["Par" .. "ent"] ~= nil
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
			return false, "AssetExecutionAdapter payload string exceeds limit"
		end
		if isForbiddenMarker(value) then
			return false, "AssetExecutionAdapter payload contains forbidden marker"
		end
		return true, nil
	end
	if valueType == "function" or valueType == "thread" or valueType == "userdata" then
		return false, "AssetExecutionAdapter payload contains unsafe runtime value"
	end
	if valueType ~= "table" then
		return false, "AssetExecutionAdapter payload contains unsupported value"
	end
	if getmetatable(value) ~= nil then
		return false, "AssetExecutionAdapter payload contains metatable"
	end
	if seen[value] then
		return false, "AssetExecutionAdapter payload contains cycle"
	end
	if isInstanceShaped(value) then
		return false, "AssetExecutionAdapter payload contains instance-shaped table"
	end
	if depth > Types.Limits.MaxPayloadDepth then
		return false, "AssetExecutionAdapter payload depth exceeds limit"
	end
	count.value += 1
	if count.value > Types.Limits.MaxPayloadNodes then
		return false, "AssetExecutionAdapter payload node count exceeds limit"
	end
	seen[value] = true
	for key, nested in pairs(value) do
		if type(key) == "string" then
			if #key > Types.Limits.MaxStringLength or isForbiddenMarker(key) then
				return false, "AssetExecutionAdapter payload contains unsafe key"
			end
		elseif type(key) ~= "number" then
			return false, "AssetExecutionAdapter payload contains unsafe key"
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

function Serialization.diagnosticCopy(value: any): any
	local ok = Serialization.validateSerializable(value)
	if ok then
		return Serialization.deepCopy(value)
	end
	return "<unsafe-payload>"
end

function Serialization.forbiddenMarkers(): { string }
	return Serialization.deepCopy(FORBIDDEN_MARKERS)
end

return Serialization
