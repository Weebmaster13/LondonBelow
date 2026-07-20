--!strict
-- Diagnostics aggregation for Presentation Runtime Foundation.

local Serialization = require(script.Parent.PresentationSerialization)
local Types = require(script.Parent.PresentationTypes)

local Diagnostics = {}

local function proveSnapshotIsolation(dependencies: { [string]: any }): boolean
	local snapshot = Serialization.deepCopy({
		requests = dependencies.RequestRuntime.inspect(),
	})
	snapshot.requests.requestCount = 999999
	return dependencies.RequestRuntime.inspect().requestCount ~= 999999
end

function Diagnostics.capture(runtime: any, dependencies: { [string]: any })
	local validationOk, validationReason = dependencies.Validation.validate()
	local requests = dependencies.RequestRuntime.inspect()
	local approvals = dependencies.ApprovalRuntime.inspect()
	local channels = dependencies.ChannelRuntime.inspect()
	local queue = dependencies.QueueRuntime.inspect()
	local commands = dependencies.CommandRuntime.inspect()
	local dispatcher = dependencies.Dispatcher.inspect()
	local evidence = dependencies.Evidence.inspect()
	local routing = dependencies.RoutingRuntime.inspect()
	local snapshots = dependencies.Snapshots.inspectHistory()
	return Serialization.deepCopy({
		initialized = runtime.initialized,
		started = runtime.started,
		lifecycleState = if not runtime.initialized
			then "NotInitialized"
			elseif runtime.started then "Running"
			else "Ready",
		mode = Types.Mode,
		requestCount = requests.requestCount,
		queueCount = queue.queueCount,
		approvalCount = approvals.approvalCount,
		channelCount = channels.channelCount,
		routingCount = routing.routingCount,
		validationFailureCount = requests.validationFailureCount,
		recentSanitizedValidationFailures = requests.validationFailures,
		snapshotCount = snapshots.snapshotCount,
		presentationRuntimePosture = {
			serverAuthoritative = true,
			commandProducerOnly = true,
			noGameplayAuthority = true,
			noNewRemotes = true,
			noClientAuthority = true,
			noAssetIds = true,
			audioRequestsOnly = true,
			animationRequestsOnly = true,
			visualFeedbackMetadataOnly = true,
			accessibilityMetadataOnly = true,
			snapshotsIsolated = true,
			diagnosticsBounded = true,
			noAnalytics = true,
			noTelemetry = true,
		},
		queuedCommands = commands.queuedCommands,
		executedCommands = commands.executedCommands,
		expiredCommands = commands.expiredCommands,
		promptCount = commands.promptCount,
		busyCount = commands.busyCount,
		audioRequests = commands.audioRequests,
		animationRequests = commands.animationRequests,
		messageRequests = commands.messageRequests,
		cursorUpdates = commands.cursorUpdates,
		highlightUpdates = commands.highlightUpdates,
		dispatcherRoutes = dispatcher.routeCount,
		evidenceCount = evidence.evidenceCount,
		runtimeLimits = Types.Limits,
		serializationPosture = {
			rejectsInstances = true,
			rejectsFunctions = true,
			rejectsThreads = true,
			rejectsUserdata = true,
			rejectsCycles = true,
			rejectsOversizedStrings = true,
			rejectsDeepPayloads = true,
			rejectsOversizedNodeCounts = true,
			sanitizesDiagnostics = true,
		},
		snapshotIsolationProof = proveSnapshotIsolation(dependencies),
		lastSelfChecks = runtime.lastSelfChecks,
		health = {
			healthy = runtime.initialized and validationOk,
			status = if not runtime.initialized
				then "NotInitialized"
				elseif runtime.started then "Running"
				else "Ready",
			message = validationReason
				or "Presentation Runtime is server-authoritative schema routing only.",
		},
		state = {
			requests = requests,
			approvals = approvals,
			channels = channels,
			queue = queue,
			routing = routing,
			commands = commands,
			dispatcher = dispatcher,
			evidence = evidence,
			snapshots = snapshots,
		},
	})
end

function Diagnostics.validate(dependencies: { [string]: any }): (boolean, string?)
	return dependencies.Validation.validate()
end

return Diagnostics
