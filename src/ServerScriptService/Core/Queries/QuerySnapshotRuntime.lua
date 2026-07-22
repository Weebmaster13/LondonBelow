--!strict
local Serialization = require(script.Parent.QuerySerialization)
local Snapshots = {}
local snapshots = {}
function Snapshots.record(query: any)
	snapshots[query.queryId] = Serialization.deepCopy({
		queryId = query.queryId,
		consistency = query.consistency,
		timestamp = os.clock(),
	})
end
function Snapshots.inspect()
	return Serialization.deepCopy(snapshots)
end
function Snapshots.clear()
	table.clear(snapshots)
end
return Snapshots
