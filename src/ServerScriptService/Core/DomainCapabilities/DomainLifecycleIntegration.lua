--!strict

local Evidence = require(script.Parent.DomainEvidence)
local Serialization = require(script.Parent.DomainSerialization)

local LifecycleIntegration = {}
local records = {}

function LifecycleIntegration.record(capabilityId: string, lifecycleState: string)
	local record = {
		capabilityId = capabilityId,
		lifecycleState = lifecycleState,
		workflowRuntimeOwnsExecution = true,
		capabilityFrameworkOwnsLifecycle = true,
		recordedAt = os.clock(),
	}
	records[capabilityId] = record
	Evidence.record("domain lifecycle integrated", record)
	return { ok = true, code = "Ok", capabilityId = capabilityId }
end

function LifecycleIntegration.inspect()
	return Serialization.deepCopy(records)
end

function LifecycleIntegration.clear()
	table.clear(records)
end

return LifecycleIntegration
