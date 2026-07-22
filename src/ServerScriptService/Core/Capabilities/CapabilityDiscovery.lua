--!strict

local Evidence = require(script.Parent.CapabilityEvidence)
local Registry = require(script.Parent.CapabilityRegistry)
local Serialization = require(script.Parent.CapabilitySerialization)
local Types = require(script.Parent.CapabilityTypes)

local Discovery = {}
local records = {}

function Discovery.resolve(interfaceId: string, version: string, owner: string?)
	local matches = {}
	for capabilityId, definition in pairs(Registry.inspect()) do
		if owner == nil or definition.owner == owner then
			for _, interfaceRecord in ipairs(definition.interfaces) do
				if
					interfaceRecord.interfaceId == interfaceId
					and interfaceRecord.version == version
				then
					table.insert(matches, {
						capabilityId = capabilityId,
						interfaceId = interfaceId,
						version = version,
						owner = definition.owner,
					})
				end
			end
		end
	end
	table.sort(matches, function(left, right)
		return left.capabilityId < right.capabilityId
	end)
	local record = {
		interfaceId = interfaceId,
		version = version,
		owner = owner,
		matchCount = #matches,
		resolvedAt = os.clock(),
	}
	table.insert(records, record)
	Evidence.record("capability interface resolved", record)
	if #matches == 0 then
		return {
			ok = false,
			code = Types.FailureType.MissingInterface,
			message = "interface not found",
		}
	end
	return { ok = true, code = "Ok", matches = Serialization.copyArray(matches) }
end

function Discovery.inspect()
	return Serialization.copyArray(records)
end

function Discovery.clear()
	table.clear(records)
end

return Discovery
