--!strict

local Serialization = {}

local function copy(value: any, seen: { [any]: any }?): any
	if type(value) ~= "table" then
		return value
	end
	local lookup = seen or {}
	if lookup[value] ~= nil then
		return lookup[value]
	end
	local output = {}
	lookup[value] = output
	for key, item in pairs(value) do
		output[copy(key, lookup)] = copy(item, lookup)
	end
	return table.freeze(output)
end

function Serialization.deepCopy(value: any): any
	return copy(value, {})
end

function Serialization.copyArray(values: { any }): { any }
	local output = {}
	for _, value in ipairs(values) do
		table.insert(output, Serialization.deepCopy(value))
	end
	return table.freeze(output)
end

function Serialization.sortedKeys(map: { [string]: any }): { string }
	local keys = {}
	for key in pairs(map) do
		table.insert(keys, key)
	end
	table.sort(keys)
	return keys
end

return Serialization
