--!strict
-- Deep-copy and serialization helpers for replay, debugging, and future saves.

local Config = require(script.Parent.LivingCognitionConfiguration)

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

function Serialization.freezeForSnapshot(value: any): any
	return Serialization.deepCopy(value)
end

function Serialization.validateSerializable(
	value: any,
	seen: { [any]: boolean }?,
	depth: number?,
	nodeCount: { count: number }?
): (boolean, string?)
	if typeof ~= nil and typeof(value) == "Instance" then
		return false, "Roblox Instance references cannot enter cognition serialization"
	end
	local valueType = type(value)
	if valueType == "function" or valueType == "thread" or valueType == "userdata" then
		return false, "unsafe runtime values cannot enter cognition serialization"
	end
	if valueType == "string" and #value > Config.MaxPayloadStringLength then
		return false, "string payload exceeds cognition serialization limit"
	end
	if valueType ~= "table" then
		return true, nil
	end
	local currentDepth = depth or 0
	if currentDepth > Config.MaxPayloadDepth then
		return false, "payload depth exceeds cognition serialization limit"
	end
	local counter = nodeCount or { count = 0 }
	counter.count += 1
	if counter.count > Config.MaxPayloadNodes then
		return false, "payload size exceeds cognition serialization limit"
	end
	local refs = seen or {}
	if refs[value] == true then
		return false, "cyclic table references cannot enter cognition serialization"
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

return Serialization
