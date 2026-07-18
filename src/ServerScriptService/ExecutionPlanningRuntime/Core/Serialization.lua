--!strict

local Types = require(script.Parent.Types)

local Serialization = {}

local forbiddenMarkers = {
	"execute",
	"executor",
	"invoke",
	"runner",
	"studioExecution",
	"transport",
	"network",
	"http",
	"endpoint",
	"credential",
	"token",
	"secret",
	"remote",
	"clientAuthority",
	"workspace",
	"dataStore",
	"messaging",
	"analytics",
	"telemetry",
	"gameplayMutation",
	"runtimeEvidence",
}

local function sortedKeys(value: { [any]: any }): { any }
	local keys = {}
	for key in pairs(value) do
		table.insert(keys, key)
	end
	table.sort(keys, function(left, right)
		return tostring(left) < tostring(right)
	end)
	return keys
end

function Serialization.deepCopy(value: any, depth: number?): any
	local currentDepth = depth or 0
	if currentDepth > Types.Limits.MaxDepth then
		return "<max-depth>"
	end
	if type(value) ~= "table" then
		return value
	end
	local copy = {}
	for key, item in pairs(value) do
		copy[key] = Serialization.deepCopy(item, currentDepth + 1)
	end
	return copy
end

function Serialization.stableSerialize(value: any): string
	if type(value) == "nil" then
		return "nil"
	elseif type(value) == "boolean" or type(value) == "number" then
		return tostring(value)
	elseif type(value) == "string" then
		return string.format("%q", value)
	elseif type(value) ~= "table" then
		return "<unsupported>"
	end
	local parts = {}
	for _, key in ipairs(sortedKeys(value)) do
		table.insert(parts, tostring(key) .. "=" .. Serialization.stableSerialize(value[key]))
	end
	return "{" .. table.concat(parts, ",") .. "}"
end

function Serialization.deterministicHash(value: any): string
	local serialized = Serialization.stableSerialize(value)
	local hash = 2166136261
	for index = 1, #serialized do
		hash = bit32.bxor(hash, string.byte(serialized, index))
		hash = (hash * 16777619) % 4294967296
	end
	return string.format("fnv1a32:%08x", hash)
end

function Serialization.hasUnsafePayload(value: any, depth: number?): (boolean, string?)
	local currentDepth = depth or 0
	if currentDepth > Types.Limits.MaxDepth then
		return true, "payload exceeds depth limit"
	end
	if type(value) == "string" then
		if #value > Types.Limits.MaxStringLength then
			return true, "string exceeds limit"
		end
		for _, marker in ipairs(forbiddenMarkers) do
			if string.find(string.lower(value), string.lower(marker), 1, true) then
				return true, "forbidden marker " .. marker
			end
		end
	elseif type(value) == "table" then
		local count = 0
		for key, item in pairs(value) do
			count += 1
			if count > Types.Limits.MaxMetadataKeys then
				return true, "metadata key limit exceeded"
			end
			local unsafeKey, keyReason =
				Serialization.hasUnsafePayload(tostring(key), currentDepth + 1)
			if unsafeKey then
				return true, keyReason
			end
			local unsafeValue, valueReason = Serialization.hasUnsafePayload(item, currentDepth + 1)
			if unsafeValue then
				return true, valueReason
			end
		end
	elseif type(value) == "function" or type(value) == "thread" or type(value) == "userdata" then
		return true, "unsafe value type"
	end
	return false, nil
end

function Serialization.forbiddenMarkers(): { string }
	return Serialization.deepCopy(forbiddenMarkers)
end

return Serialization
