--!strict

local Serialization = {}

local function copyValue(value: any, seen: { [any]: boolean }?): any
	if type(value) ~= "table" then
		return value
	end

	local activeSeen = seen or {}
	if activeSeen[value] then
		return nil
	end
	activeSeen[value] = true

	local copy = {}
	for key, child in pairs(value) do
		copy[copyValue(key, activeSeen)] = copyValue(child, activeSeen)
	end
	activeSeen[value] = nil
	return copy
end

function Serialization.deepCopy(value: any): any
	return copyValue(value, {})
end

function Serialization.sortedKeys(dictionary: { [string]: any }): { string }
	local keys = {}
	for key in pairs(dictionary) do
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
