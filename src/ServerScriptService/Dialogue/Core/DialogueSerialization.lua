--!strict

local Serialization = {}

local function copy(value: any, seen: { [any]: boolean }?): any
	if type(value) ~= "table" then
		return value
	end
	local active = seen or {}
	if active[value] then
		error("cyclic dialogue payload", 2)
	end
	active[value] = true
	local result = {}
	for key, child in pairs(value) do
		result[copy(key, active)] = copy(child, active)
	end
	active[value] = nil
	return result
end

function Serialization.deepCopy(value: any): any
	return copy(value, {})
end

function Serialization.copyArray(values: { any }): { any }
	local result = {}
	for index, value in ipairs(values) do
		result[index] = Serialization.deepCopy(value)
	end
	return result
end

return Serialization
