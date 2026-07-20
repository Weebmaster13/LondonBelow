--!strict

local Types = require(script.Parent.EnvironmentalTypes)

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

function Serialization.validate(
	value: any,
	seen: { [any]: boolean }?,
	depth: number?,
	nodes: { count: number }?
): (boolean, string?)
	if typeof ~= nil and typeof(value) == "Instance" then
		return false, "environmental metadata cannot contain Roblox Instances"
	end
	local valueType = type(value)
	if valueType == "function" or valueType == "thread" or valueType == "userdata" then
		return false, "environmental metadata cannot contain unsafe runtime values"
	end
	if valueType == "string" and #value > Types.Limits.MaxStringLength then
		return false, "environmental string exceeds limit"
	end
	if valueType ~= "table" then
		return true, nil
	end
	local currentDepth = depth or 0
	if currentDepth > Types.Limits.MaxMetadataDepth then
		return false, "environmental metadata depth exceeds limit"
	end
	local counter = nodes or { count = 0 }
	counter.count += 1
	if counter.count > Types.Limits.MaxMetadataNodes then
		return false, "environmental metadata node count exceeds limit"
	end
	local refs = seen or {}
	if refs[value] == true then
		return false, "environmental metadata cannot contain cycles"
	end
	refs[value] = true
	for key, nested in pairs(value) do
		local keyOk, keyReason = Serialization.validate(key, refs, currentDepth + 1, counter)
		if not keyOk then
			return false, keyReason
		end
		local valueOk, valueReason = Serialization.validate(nested, refs, currentDepth + 1, counter)
		if not valueOk then
			return false, valueReason
		end
	end
	refs[value] = nil
	return true, nil
end

return Serialization
