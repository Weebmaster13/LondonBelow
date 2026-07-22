--!strict

local Serialization = {}

function Serialization.deepCopy(value: any, seen: { [any]: any }?): any
	if type(value) ~= "table" then
		return value
	end
	local refs = seen or {}
	if refs[value] ~= nil then
		return refs[value]
	end
	local copy = {}
	refs[value] = copy
	for key, nested in pairs(value) do
		copy[Serialization.deepCopy(key, refs)] = Serialization.deepCopy(nested, refs)
	end
	return copy
end

function Serialization.freezeRecord(value: any)
	local copy = Serialization.deepCopy(value)
	if table.freeze ~= nil and type(copy) == "table" then
		table.freeze(copy)
	end
	return copy
end

return Serialization
