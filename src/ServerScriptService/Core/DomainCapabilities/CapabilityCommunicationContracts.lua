--!strict

local Evidence = require(script.Parent.DomainEvidence)
local Serialization = require(script.Parent.DomainSerialization)

local Communication = {}
local contracts = {}

function Communication.record(capabilityId: string, workflowParticipation: string)
	local record = {
		capabilityId = capabilityId,
		workflowParticipation = workflowParticipation,
		commandParticipation = "submitOnly",
		eventParticipation = "observeOnly",
		queryParticipation = "consumeOnly",
		directCapabilityCallsAllowed = false,
		recordedAt = os.clock(),
	}
	contracts[capabilityId] = record
	Evidence.record("domain communication contract recorded", record)
	return { ok = true, code = "Ok", capabilityId = capabilityId }
end

function Communication.inspect()
	return Serialization.deepCopy(contracts)
end

function Communication.clear()
	table.clear(contracts)
end

return Communication
