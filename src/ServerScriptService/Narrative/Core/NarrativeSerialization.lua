--!strict
-- Serialization and diagnostics sanitization for Narrative foundation schemas.

local Types = require(script.Parent.NarrativeTypes)

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

function Serialization.validateSerializable(
	value: any,
	seen: { [any]: boolean }?,
	depth: number?,
	nodeCount: { count: number }?
): (boolean, string?)
	if typeof ~= nil and typeof(value) == "Instance" then
		return false, "narrative payload cannot contain Roblox Instances"
	end
	local valueType = type(value)
	if valueType == "function" or valueType == "thread" or valueType == "userdata" then
		return false, "narrative payload cannot contain unsafe runtime values"
	end
	if valueType == "string" and #value > Types.Limits.MaxPayloadStringLength then
		return false, "narrative payload string exceeds limit"
	end
	if valueType ~= "table" then
		return true, nil
	end
	local currentDepth = depth or 0
	if currentDepth > Types.Limits.MaxPayloadDepth then
		return false, "narrative payload depth exceeds limit"
	end
	local counter = nodeCount or { count = 0 }
	counter.count += 1
	if counter.count > Types.Limits.MaxPayloadNodes then
		return false, "narrative payload node count exceeds limit"
	end
	local refs = seen or {}
	if refs[value] == true then
		return false, "narrative payload cannot contain cyclic tables"
	end
	refs[value] = true
	for key, nested in pairs(value) do
		local keyOk, keyReason =
			Serialization.validateSerializable(key, refs, currentDepth + 1, counter)
		if not keyOk then
			return false, keyReason
		end
		local nestedOk, nestedReason =
			Serialization.validateSerializable(nested, refs, currentDepth + 1, counter)
		if not nestedOk then
			return false, nestedReason
		end
	end
	refs[value] = nil
	return true, nil
end

function Serialization.diagnosticCopy(value: any, seen: { [any]: boolean }?, depth: number?): any
	if typeof ~= nil and typeof(value) == "Instance" then
		return "<RobloxInstance>"
	end
	local valueType = type(value)
	if valueType == "function" or valueType == "thread" or valueType == "userdata" then
		return "<unsafe:" .. valueType .. ">"
	end
	if valueType == "string" and #value > Types.Limits.MaxPayloadStringLength then
		return string.sub(value, 1, Types.Limits.MaxPayloadStringLength) .. "<truncated>"
	end
	if valueType ~= "table" then
		return value
	end
	local currentDepth = depth or 0
	if currentDepth > Types.Limits.MaxPayloadDepth then
		return "<max-depth>"
	end
	local refs = seen or {}
	if refs[value] == true then
		return "<cycle>"
	end
	refs[value] = true
	local copy = {}
	local count = 0
	for key, nested in pairs(value) do
		count += 1
		if count > Types.Limits.MaxPayloadNodes then
			copy["<truncated>"] = "max nodes reached"
			break
		end
		copy[Serialization.diagnosticCopy(key, refs, currentDepth + 1)] =
			Serialization.diagnosticCopy(nested, refs, currentDepth + 1)
	end
	refs[value] = nil
	return copy
end

return Serialization
