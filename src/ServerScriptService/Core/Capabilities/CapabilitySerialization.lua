--!strict

local Serialization = {}

function Serialization.deepCopy(value: any, seen: { [any]: any }?): any
	if type(value) ~= "table" then
		return value
	end
	local refs = seen or {}
	if refs[value] ~= nil then
		error("cyclic values cannot be copied", 2)
	end
	local copy = {}
	refs[value] = copy
	for key, item in pairs(value) do
		copy[Serialization.deepCopy(key, refs)] = Serialization.deepCopy(item, refs)
	end
	refs[value] = nil
	return copy
end

function Serialization.copyArray(values: { any }): { any }
	local copy = {}
	for index, value in ipairs(values) do
		copy[index] = Serialization.deepCopy(value)
	end
	return copy
end

function Serialization.sortedKeys(map: { [string]: any }): { string }
	local keys = {}
	for key in pairs(map) do
		table.insert(keys, key)
	end
	table.sort(keys)
	return keys
end

function Serialization.freezeCopy(value: any): any
	local copy = Serialization.deepCopy(value)
	if type(copy) == "table" then
		table.freeze(copy)
	end
	return copy
end

return Serialization
