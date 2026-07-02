--!strict
-- Snapshot provider for Gameplay Execution Bridge dry-run state.

local Serialization = require(script.Parent.ExecutionSerialization)
local Types = require(script.Parent.ExecutionTypes)

local Snapshots = {}

local history: { any } = {}

local function trim()
	while #history > Types.Limits.MaxSnapshotHistory do
		table.remove(history, 1)
	end
end

function Snapshots.capture(dependencies: { [string]: any })
	local snapshot = Serialization.deepCopy({
		mode = Types.Mode,
		capturedAt = os.clock(),
		requests = dependencies.RequestRuntime.inspect(),
		approvals = dependencies.ApprovalRuntime.inspect(),
		dependencies = dependencies.DependencyRuntime.inspect(),
		queue = dependencies.QueueRuntime.inspect(),
		schedules = dependencies.Scheduler.inspect(),
		audit = dependencies.Audit.inspect(),
		limits = Types.Limits,
	})
	table.insert(history, {
		capturedAt = snapshot.capturedAt,
		requestCount = snapshot.requests.requestCount,
		auditCount = snapshot.audit.auditCount,
	})
	trim()
	snapshot.snapshotHistory = Serialization.deepCopy(history)
	snapshot.snapshotCount = #history
	return snapshot
end

function Snapshots.inspectHistory()
	return {
		snapshotCount = #history,
		snapshotHistory = Serialization.deepCopy(history),
	}
end

function Snapshots.clear()
	table.clear(history)
end

return Snapshots
