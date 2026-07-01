--!strict
-- Deep-copy and serialization helpers for replay, debugging, and future saves.

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
	seen: { [any]: boolean }?
): (boolean, string?)
	if typeof ~= nil and typeof(value) == "Instance" then
		return false, "Roblox Instance references cannot enter cognition serialization"
	end
	if type(value) ~= "table" then
		return true, nil
	end
	local refs = seen or {}
	if refs[value] == true then
		return false, "cyclic table references cannot enter cognition serialization"
	end
	refs[value] = true
	for key, nested in pairs(value) do
		local keyOk, keyReason = Serialization.validateSerializable(key, refs)
		if not keyOk then
			return false, keyReason
		end
		local nestedOk, nestedReason = Serialization.validateSerializable(nested, refs)
		if not nestedOk then
			return false, nestedReason
		end
	end
	refs[value] = nil
	return true, nil
end

return Serialization
