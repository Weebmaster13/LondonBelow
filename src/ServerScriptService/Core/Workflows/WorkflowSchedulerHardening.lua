--!strict

local Serialization = require(script.Parent.WorkflowSerialization)

local SchedulerHardening = {}
local decisions = {}

function SchedulerHardening.recordAdmission(
	instanceId: string,
	priority: number?,
	deadline: number?
)
	local decision = {
		instanceId = instanceId,
		priority = priority or 0,
		deadline = deadline or math.huge,
		admitted = true,
		reason = "deterministic priority deadline ordering",
		createdAt = os.clock(),
	}
	table.insert(decisions, decision)
	return { ok = true, code = "Ok", decision = Serialization.deepCopy(decision) }
end

function SchedulerHardening.inspect()
	return Serialization.copyArray(decisions)
end

function SchedulerHardening.clear()
	table.clear(decisions)
end

return SchedulerHardening
