--!strict
-- Bounded audit trail for execution request decisions and dry-run plans.

local Serialization = require(script.Parent.ExecutionSerialization)
local Types = require(script.Parent.ExecutionTypes)

local Audit = {}

local records: { any } = {}

local function trim()
	while #records > Types.Limits.MaxAuditRecords do
		table.remove(records, 1)
	end
end

function Audit.record(event: any)
	table.insert(
		records,
		Serialization.deepCopy({
			executionId = event.executionId,
			requester = event.requester,
			sourceSystem = event.sourceSystem,
			status = event.status,
			reason = event.reason,
			priority = event.priority,
			dependencies = event.dependencies,
			approvals = event.approvals,
			dryRunRecord = event.dryRunRecord,
			timestamp = os.clock(),
		})
	)
	trim()
end

function Audit.inspect()
	return {
		auditCount = #records,
		records = Serialization.deepCopy(records),
	}
end

function Audit.clear()
	table.clear(records)
end

return Audit
