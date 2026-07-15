--!strict

local Serialization = {}

function Serialization.deepCopy(value: any): any
	if type(value) ~= "table" then
		return value
	end

	local copied = {}

	for key, child in pairs(value) do
		copied[Serialization.deepCopy(key)] = Serialization.deepCopy(child)
	end

	return copied
end

return Serialization
