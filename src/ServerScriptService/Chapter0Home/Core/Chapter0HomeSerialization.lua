--!strict

local Serialization = {}

local function isUnsafeValue(value: any): boolean
	local valueType = type(value)

	if valueType == "function" or valueType == "thread" or valueType == "userdata" then
		return true
	end

	local valueKind = typeof(value)
	return valueKind == "Instance" or valueKind == "RBXScriptConnection"
end

local function copyValue(value: any, seen: { [any]: boolean }): any
	if isUnsafeValue(value) then
		return nil
	end

	if type(value) ~= "table" then
		return value
	end

	if seen[value] then
		return "<cycle>"
	end

	seen[value] = true
	local copied = {}

	for key, child in pairs(value) do
		local copiedKey = copyValue(key, seen)
		local copiedChild = copyValue(child, seen)

		if copiedKey ~= nil and copiedChild ~= nil then
			copied[copiedKey] = copiedChild
		end
	end

	seen[value] = nil
	return copied
end

function Serialization.deepCopy(value: any): any
	return copyValue(value, {})
end

return Serialization
