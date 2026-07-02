--!strict
-- Isolated snapshot provider for Presentation Runtime Foundation.

local Serialization = require(script.Parent.PresentationSerialization)
local Types = require(script.Parent.PresentationTypes)

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
		channels = dependencies.ChannelRuntime.inspect(),
		queue = dependencies.QueueRuntime.inspect(),
		routing = dependencies.RoutingRuntime.inspect(),
		limits = Types.Limits,
	})
	table.insert(history, {
		capturedAt = snapshot.capturedAt,
		requestCount = snapshot.requests.requestCount,
		routingCount = snapshot.routing.routingCount,
	})
	trim()
	snapshot.snapshotCount = #history
	snapshot.snapshotHistory = Serialization.deepCopy(history)
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
