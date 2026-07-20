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
		presentationRuntimeAvailable = true,
		presentationRuntimePosture = {
			serverAuthoritative = true,
			commandProducerOnly = true,
			noGameplayAuthority = true,
			noNewRemotes = true,
			noClientAuthority = true,
			noAnalytics = true,
			noTelemetry = true,
		},
		capturedAt = os.clock(),
		requests = dependencies.RequestRuntime.inspect(),
		approvals = dependencies.ApprovalRuntime.inspect(),
		channels = dependencies.ChannelRuntime.inspect(),
		queue = dependencies.QueueRuntime.inspect(),
		routing = dependencies.RoutingRuntime.inspect(),
		commandState = dependencies.CommandRuntime.inspect(),
		dispatcher = dependencies.Dispatcher.inspect(),
		evidence = dependencies.Evidence.inspect(),
		limits = Types.Limits,
		queueSize = dependencies.CommandRuntime.inspect().queuedCommands,
		activePrompt = dependencies.CommandRuntime.inspect().activePrompt,
		activeHighlights = dependencies.CommandRuntime.inspect().activeHighlights,
		activeBusyStates = dependencies.CommandRuntime.inspect().activeBusyStates,
		audioRequests = dependencies.CommandRuntime.inspect().audioRequestRecords,
		animationRequests = dependencies.CommandRuntime.inspect().animationRequestRecords,
		messageRequests = dependencies.CommandRuntime.inspect().messageRequestRecords,
		cursorState = dependencies.CommandRuntime.inspect().cursorState,
		noAnalytics = true,
		noTelemetry = true,
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
