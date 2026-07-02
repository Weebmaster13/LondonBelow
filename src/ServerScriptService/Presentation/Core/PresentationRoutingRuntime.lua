--!strict
-- Routing records for future presentation adapters. Records only; no remotes.

local Serialization = require(script.Parent.PresentationSerialization)
local Types = require(script.Parent.PresentationTypes)

local RoutingRuntime = {}

local routes: { any } = {}

local function trim()
	while #routes > Types.Limits.MaxRoutingRecords do
		table.remove(routes, 1)
	end
end

function RoutingRuntime.record(request: any)
	local record = {
		presentationId = request.presentationId,
		presentationType = request.presentationType,
		channels = Serialization.deepCopy(request.channels),
		status = Types.Status.Routed,
		wouldRoute = true,
		wouldCreateRemote = false,
		wouldExecutePresentation = false,
		createdAt = os.clock(),
		reason = request.reason,
	}
	table.insert(routes, record)
	trim()
	return Serialization.deepCopy(record)
end

function RoutingRuntime.inspect()
	return {
		routingCount = #routes,
		routes = Serialization.deepCopy(routes),
	}
end

function RoutingRuntime.clear()
	table.clear(routes)
end

return RoutingRuntime
