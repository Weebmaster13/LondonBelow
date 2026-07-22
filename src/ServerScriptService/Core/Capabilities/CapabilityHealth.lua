--!strict

local Evidence = require(script.Parent.CapabilityEvidence)
local Registry = require(script.Parent.CapabilityRegistry)
local Serialization = require(script.Parent.CapabilitySerialization)
local Types = require(script.Parent.CapabilityTypes)

local Health = {}
local records: { [string]: any } = {}

function Health.publish(
	capabilityId: string,
	health: string,
	readiness: string,
	availability: string
)
	if not Registry.has(capabilityId) then
		return {
			ok = false,
			code = Types.FailureType.UnknownCapability,
			message = "unknown capability",
		}
	end
	local record = {
		capabilityId = capabilityId,
		health = health,
		readiness = readiness,
		availability = availability,
		publishedAt = os.clock(),
	}
	records[capabilityId] = record
	Evidence.record("capability health published", record)
	return { ok = true, code = "Ok", capabilityId = capabilityId }
end

function Health.get(capabilityId: string): any
	local record = records[capabilityId]
	if record ~= nil then
		return Serialization.deepCopy(record)
	end
	return {
		capabilityId = capabilityId,
		health = Types.Health.Unknown,
		readiness = Types.Readiness.NotReady,
		availability = Types.Availability.Unavailable,
	}
end

function Health.inspect()
	return Serialization.deepCopy(records)
end

function Health.clear()
	table.clear(records)
end

return Health
