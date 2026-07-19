--!strict

local Types = require(script.Parent.Types)

local Serialization = {}

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
	if currentDepth > 12 then
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
		return "null"
	elseif type(value) == "boolean" or type(value) == "number" then
		return tostring(value)
	elseif type(value) == "string" then
		return string.format("%q", value)
	elseif type(value) ~= "table" then
		return string.format("%q", "<unsupported>")
	end

	local arrayLength = #value
	if arrayLength > 0 then
		local parts = {}
		for index = 1, arrayLength do
			table.insert(parts, Serialization.stableSerialize(value[index]))
		end
		return "[" .. table.concat(parts, ",") .. "]"
	end

	local parts = {}
	for _, key in ipairs(sortedKeys(value)) do
		table.insert(
			parts,
			string.format("%q", tostring(key)) .. ":" .. Serialization.stableSerialize(value[key])
		)
	end
	return "{" .. table.concat(parts, ",") .. "}"
end

function Serialization.checksum(value: any): string
	local serialized = if type(value) == "string"
		then value
		else Serialization.stableSerialize(value)
	local hash = 2166136261
	for index = 1, #serialized do
		hash = bit32.bxor(hash, string.byte(serialized, index))
		hash = (hash * 16777619) % 4294967296
	end
	return string.format("fnv1a32:%08x", hash)
end

function Serialization.validateSafeString(value: string, label: string): (boolean, string?)
	if #value > Types.Limits.MaxStringLength then
		return false, label .. " exceeds limit"
	end
	if string.find(value, "\0", 1, true) ~= nil then
		return false, label .. " contains null byte"
	end
	return true, nil
end

return Serialization
