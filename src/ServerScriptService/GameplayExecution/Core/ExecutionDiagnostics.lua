--!strict
-- Diagnostics aggregation for the server-authoritative execution gateway.

local Serialization = require(script.Parent.ExecutionSerialization)
local Types = require(script.Parent.ExecutionTypes)

local Diagnostics = {}

local function snapshotIsolation(dependencies: { [string]: any }): boolean
	local snapshot = Serialization.deepCopy({
		requests = dependencies.RequestRuntime.inspect(),
		queue = dependencies.QueueRuntime.inspect(),
	})
	snapshot.requests.requestCount = 999999
	return dependencies.RequestRuntime.inspect().requestCount ~= 999999
end

function Diagnostics.capture(runtime: any, dependencies: { [string]: any })
	local validationOk, validationReason = dependencies.Validation.validate()
	local requests = dependencies.RequestRuntime.inspect()
	local queue = dependencies.QueueRuntime.inspect()
	local audit = dependencies.Audit.inspect()
	local approvals = dependencies.ApprovalRuntime.inspect()
	local dependencyState = dependencies.DependencyRuntime.inspect()
	local snapshots = dependencies.Snapshots.inspectHistory()
	return Serialization.deepCopy({
		initialized = runtime.initialized,
		started = runtime.started,
		mode = Types.Mode,
		queueCount = queue.queueCount,
		pendingCount = queue.pendingCount,
		approvedCount = queue.approvedCount,
		rejectedCount = queue.rejectedCount,
		cancelledCount = queue.cancelledCount,
		expiredCount = queue.expiredCount,
		dryRunCount = queue.dryRunCount,
		validationFailureCount = requests.validationFailureCount,
		validationFailures = requests.validationFailures,
		runtimeLimits = Types.Limits,
		serializationPosture = {
			rejectsInstances = true,
			rejectsFunctions = true,
			rejectsThreads = true,
			rejectsUserdata = true,
			rejectsCycles = true,
			rejectsOversizedStrings = true,
			rejectsOversizedPayloads = true,
			rejectsDeepPayloads = true,
			sanitizesDiagnostics = true,
		},
		snapshotCount = snapshots.snapshotCount,
		lastSelfChecks = runtime.lastSelfChecks,
		queueState = queue,
		auditCount = audit.auditCount,
		dependencyCount = dependencyState.dependencyCount,
		approvalCount = approvals.approvalCount,
		snapshotIsolationProof = snapshotIsolation(dependencies),
		health = {
			healthy = runtime.initialized and validationOk,
			status = if not runtime.initialized
				then "NotInitialized"
				elseif runtime.started then "Running"
				else "Ready",
			message = validationReason
				or "Gameplay Execution Bridge is server-authoritative and dry-run only.",
		},
	})
end

function Diagnostics.validate(dependencies: { [string]: any }): (boolean, string?)
	return dependencies.Validation.validate()
end

return Diagnostics
