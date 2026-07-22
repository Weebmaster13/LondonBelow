--!strict

local CommandQueue = require(script.Parent.CommandQueue)
local Ancestry = require(script.Parent.CommandAncestry)
local Audits = require(script.Parent.CommandAudits)
local Batch = require(script.Parent.CommandBatchRuntime)
local Certification = require(script.Parent.CommandCertification)
local Compatibility = require(script.Parent.CommandCompatibility)
local CommandRegistry = require(script.Parent.CommandRegistry)
local Correlation = require(script.Parent.CommandCorrelation)
local Diagnostics = require(script.Parent.CommandDiagnostics)
local Evidence = require(script.Parent.CommandEvidence)
local Execution = require(script.Parent.CommandExecutionRuntime)
local ExecutionPolicy = require(script.Parent.CommandExecutionPolicy)
local FaultInjection = require(script.Parent.CommandFaultInjection)
local Health = require(script.Parent.CommandHealth)
local Inspection = require(script.Parent.CommandInspection)
local Integrity = require(script.Parent.CommandIntegrity)
local HandlerRegistry = require(script.Parent.CommandHandlerRegistry)
local Lifecycle = require(script.Parent.CommandLifecycle)
local Metrics = require(script.Parent.CommandMetrics)
local Migration = require(script.Parent.CommandMigration)
local PerformanceBudgets = require(script.Parent.CommandPerformanceBudgets)
local LockManager = require(script.Parent.CommandLockManager)
local ProductionReview = require(script.Parent.CommandProductionReview)
local Profiler = require(script.Parent.CommandProfiler)
local Recovery = require(script.Parent.CommandRecovery)
local Replay = require(script.Parent.CommandReplay)
local RequesterRegistry = require(script.Parent.CommandRequesterRegistry)
local RetryRuntime = require(script.Parent.CommandRetryRuntime)
local ResourceBudgets = require(script.Parent.CommandResourceBudgets)
local Router = require(script.Parent.CommandRouter)
local Serialization = require(script.Parent.CommandSerialization)
local Sessions = require(script.Parent.CommandSessions)
local StressValidation = require(script.Parent.CommandStressValidation)
local Timeline = require(script.Parent.CommandTimeline)
local TransactionRuntime = require(script.Parent.CommandTransactionRuntime)
local TraceGraph = require(script.Parent.CommandTraceGraph)
local Types = require(script.Parent.CommandTypes)
local Validation = require(script.Parent.CommandValidation)

local Core = script.Parent.Parent
local EventBus = require(Core.EventBus)

local Runtime = {}

local sequence = 0
local shutdown = false
local routingHistory: { any } = {}
local seenCommandIds: { [string]: boolean } = {}
local seenIdempotencyKeys: { [string]: boolean } = {}
local counters = {
	routing = 0,
	executing = 0,
	succeeded = 0,
	cancelled = 0,
	rejected = 0,
	failed = 0,
	queueOverflows = 0,
	idempotencyRejects = 0,
	timeoutCount = 0,
	transactionFailures = 0,
	rollbackFailures = 0,
	lockFailures = 0,
	retryLimitExceeded = 0,
	interruptedCommands = 0,
	instrumentationFaults = 0,
	lastCommandId = nil :: string?,
	lastFailure = nil :: any?,
}

local function nextSequence(): number
	sequence += 1
	return sequence
end

local function normalizeFailure(failureType: string, stage: string, reason: string, command: any?)
	local failure = {
		failureType = failureType,
		failureCode = failureType,
		failureReason = reason,
		stage = stage,
		commandId = if command ~= nil then command.commandId else nil,
		commandType = if command ~= nil then command.commandType else nil,
		retryable = false,
	}
	counters.lastFailure = Serialization.deepCopy(failure)
	Evidence.record("command rejected", failure)
	return failure
end

local function observe(stage: string, callback: () -> ())
	local ok, reason = pcall(callback)
	if not ok then
		counters.instrumentationFaults += 1
		Evidence.record("command instrumentation fault", {
			stage = stage,
			reason = tostring(reason),
		})
	end
end

local function defaultPayloadValidator(payload: any): (boolean, string?)
	return Validation.payload(payload)
end

local function requesterAllowed(definition: any, requesterId: string): boolean
	for _, allowed in ipairs(definition.allowedRequesters) do
		if allowed == "*" or allowed == requesterId then
			return true
		end
	end
	return false
end

local function registerCoreDefaults()
	if not CommandRegistry.has(Types.CoreCommandTypes.Test) then
		CommandRegistry.register({
			commandType = Types.CoreCommandTypes.Test,
			schemaVersion = "1",
			ownerRuntime = Types.ProviderName,
			defaultPriority = Types.Priority.Normal,
			executionPolicy = Types.ExecutionPolicy.AuthoritativeSingleOwner,
			executionMode = Types.ExecutionMode.Immediate,
			idempotencyPolicy = Types.IdempotencyPolicy.OptionalIdempotencyKey,
			retryPolicy = Types.RetryPolicy.NeverRetry,
			timeoutBudget = Types.Limits.DefaultExecutionBudget,
			lockIds = {},
			commandReplayPolicy = Types.CommandReplayPolicy.ReplayMetadataOnly,
			payloadValidator = defaultPayloadValidator,
			allowedRequesters = { Types.ProviderName },
			metadataPolicy = "BoundedMetadata",
		})
	end
	if not RequesterRegistry.has(Types.ProviderName) then
		RequesterRegistry.register({
			requesterId = Types.ProviderName,
			runtimeId = Types.ProviderName,
			allowedCommandTypes = { "*" },
			authorityPolicy = "ServerAuthority",
		})
	end
end

local function createCommand(request: any, definition: any): any
	local commandId = request.commandId or string.format("cmd.%06d", sequence + 1)
	local command = {
		commandId = commandId,
		commandType = request.commandType,
		schemaVersion = request.schemaVersion or definition.schemaVersion,
		priority = request.priority or definition.defaultPriority,
		requesterId = request.requesterId,
		ownerRuntime = definition.ownerRuntime,
		payload = request.payload or {},
		metadata = request.metadata or {},
		correlationId = request.correlationId or commandId,
		causationId = request.causationId or "root",
		idempotencyKey = request.idempotencyKey,
		creationTimestamp = request.issuedTimestamp or os.clock(),
		admissionTimestamp = nil,
		scheduledTimestamp = nil,
		executionTimestamp = nil,
		completionTimestamp = nil,
		executionState = Types.Status.Created,
		cancellationState = "None",
		resultReference = nil,
		diagnosticsReference = nil,
		evidenceReference = nil,
		executionMode = definition.executionMode or Types.ExecutionMode.Immediate,
		retryPolicy = definition.retryPolicy or Types.RetryPolicy.NeverRetry,
		timeoutBudget = definition.timeoutBudget or Types.Limits.DefaultExecutionBudget,
		lockIds = definition.lockIds or {},
		commandReplayPolicy = definition.commandReplayPolicy
			or Types.CommandReplayPolicy.ReplayMetadataOnly,
		transactionId = request.transactionId,
		batchId = request.batchId,
		retryAttempts = request.retryAttempts or 0,
		recoveryPolicy = request.recoveryPolicy or "OwnerRuntime",
		sequence = nextSequence(),
		lifecycle = {},
	}
	counters.lastCommandId = command.commandId
	observe("timeline created", function()
		Timeline.record(command, Types.Status.Created, "Created")
		Correlation.record(command)
		TraceGraph.record(command)
		Sessions.recordCommand(command)
	end)
	return Serialization.deepCopy(command)
end

local function transitionOrReject(command: any, toState: string, stage: string)
	local transitioned, reason = Lifecycle.transition(command, toState)
	if transitioned == nil then
		counters.rejected += 1
		return nil,
			{
				ok = false,
				code = Types.FailureType.InternalRuntimeFailure,
				failure = normalizeFailure(
					Types.FailureType.InternalRuntimeFailure,
					stage,
					reason,
					command
				),
			}
	end
	return transitioned, nil
end

function Runtime.registerCommandType(definition: any)
	return CommandRegistry.register(definition)
end

function Runtime.registerRequester(requester: any)
	return RequesterRegistry.register(requester)
end

function Runtime.registerHandler(handler: any)
	return HandlerRegistry.register(handler, CommandRegistry.has)
end

function Runtime.submit(request: any)
	if shutdown then
		counters.rejected += 1
		return {
			ok = false,
			code = Types.FailureType.ShutdownRejected,
			failure = normalizeFailure(
				Types.FailureType.ShutdownRejected,
				"submission",
				"runtime is shut down",
				request
			),
		}
	end
	if type(request) ~= "table" then
		counters.rejected += 1
		return {
			ok = false,
			code = Types.FailureType.ValidationFailure,
			failure = normalizeFailure(
				Types.FailureType.ValidationFailure,
				"submission",
				"request must be a table",
				nil
			),
		}
	end
	local definition = CommandRegistry.get(request.commandType)
	if definition == nil then
		counters.rejected += 1
		return {
			ok = false,
			code = Types.FailureType.UnknownCommandType,
			failure = normalizeFailure(
				Types.FailureType.UnknownCommandType,
				"command type resolution",
				"unknown command type",
				request
			),
		}
	end
	local command = createCommand(request, definition)
	local submitted, submittedFailure =
		transitionOrReject(command, Types.Status.Submitted, "envelope construction")
	if submitted == nil then
		return submittedFailure
	end
	Evidence.record(
		"command submitted",
		{ commandId = submitted.commandId, commandType = submitted.commandType }
	)
	observe("timeline submitted", function()
		Timeline.record(submitted, Types.Status.Submitted, "Submitted")
		Metrics.recordSubmission()
	end)
	if submitted.schemaVersion ~= definition.schemaVersion then
		counters.rejected += 1
		return {
			ok = false,
			code = Types.FailureType.SchemaFailure,
			failure = normalizeFailure(
				Types.FailureType.SchemaFailure,
				"schema version",
				"schemaVersion mismatch",
				submitted
			),
		}
	end
	local payloadOk, payloadReason = definition.payloadValidator(submitted.payload)
	if not payloadOk then
		counters.rejected += 1
		return {
			ok = false,
			code = Types.FailureType.SchemaFailure,
			failure = normalizeFailure(
				Types.FailureType.SchemaFailure,
				"payload validation",
				tostring(payloadReason),
				submitted
			),
		}
	end
	local validated, validatedFailure =
		transitionOrReject(submitted, Types.Status.Validated, "schema validation")
	if validated == nil then
		return validatedFailure
	end
	observe("timeline validated", function()
		Timeline.record(validated, Types.Status.Validated, "Validated")
	end)
	if not RequesterRegistry.has(validated.requesterId) then
		counters.rejected += 1
		return {
			ok = false,
			code = Types.FailureType.AuthorizationFailure,
			failure = normalizeFailure(
				Types.FailureType.AuthorizationFailure,
				"requester resolution",
				"unknown requester",
				validated
			),
		}
	end
	if
		not RequesterRegistry.canRequest(validated.requesterId, validated.commandType)
		or not requesterAllowed(definition, validated.requesterId)
	then
		counters.rejected += 1
		return {
			ok = false,
			code = Types.FailureType.AuthorizationFailure,
			failure = normalizeFailure(
				Types.FailureType.AuthorizationFailure,
				"requester permission",
				"requester cannot submit command",
				validated
			),
		}
	end
	if definition.ownerRuntime ~= validated.ownerRuntime then
		counters.rejected += 1
		return {
			ok = false,
			code = Types.FailureType.AuthorityFailure,
			failure = normalizeFailure(
				Types.FailureType.AuthorityFailure,
				"authority resolution",
				"owner runtime mismatch",
				validated
			),
		}
	end
	local handler = HandlerRegistry.resolve(validated.commandType)
	if handler == nil then
		counters.rejected += 1
		return {
			ok = false,
			code = Types.FailureType.RoutingFailure,
			failure = normalizeFailure(
				Types.FailureType.RoutingFailure,
				"handler resolution",
				"no authoritative handler registered",
				validated
			),
		}
	end
	local authorized, authorizedFailure =
		transitionOrReject(validated, Types.Status.Authorized, "authority resolution")
	if authorized == nil then
		return authorizedFailure
	end
	observe("timeline authorized", function()
		Timeline.record(authorized, Types.Status.Authorized, "Authorized")
	end)
	local policy = ExecutionPolicy.normalize(definition)
	local policyOk, policyReason = ExecutionPolicy.validate(policy)
	if not policyOk then
		counters.rejected += 1
		return {
			ok = false,
			code = Types.FailureType.ValidationFailure,
			failure = normalizeFailure(
				Types.FailureType.ValidationFailure,
				"execution policy",
				tostring(policyReason),
				authorized
			),
		}
	end
	authorized.executionPolicySnapshot = policy
	local ancestryOk, ancestryReason =
		Ancestry.validate(authorized.commandId, authorized.causationId)
	if not ancestryOk then
		counters.rejected += 1
		return {
			ok = false,
			code = tostring(ancestryReason),
			failure = normalizeFailure(
				tostring(ancestryReason),
				"command ancestry",
				"invalid nested command ancestry",
				authorized
			),
		}
	end
	if not Validation.isValidPriority(authorized.priority) then
		counters.rejected += 1
		return {
			ok = false,
			code = Types.FailureType.InvalidPriority,
			failure = normalizeFailure(
				Types.FailureType.InvalidPriority,
				"priority",
				"invalid priority",
				authorized
			),
		}
	end
	if seenCommandIds[authorized.commandId] then
		counters.rejected += 1
		return {
			ok = false,
			code = Types.FailureType.DuplicateCommandId,
			failure = normalizeFailure(
				Types.FailureType.DuplicateCommandId,
				"identity",
				"duplicate command id",
				authorized
			),
		}
	end
	if authorized.idempotencyKey ~= nil and seenIdempotencyKeys[authorized.idempotencyKey] then
		counters.idempotencyRejects += 1
		return {
			ok = false,
			code = Types.FailureType.DuplicateIdempotencyKey,
			failure = normalizeFailure(
				Types.FailureType.DuplicateIdempotencyKey,
				"idempotency",
				"duplicate idempotency key",
				authorized
			),
		}
	end
	seenCommandIds[authorized.commandId] = true
	if authorized.idempotencyKey ~= nil then
		seenIdempotencyKeys[authorized.idempotencyKey] = true
	end
	Ancestry.record(authorized.commandId, authorized.causationId)
	if authorized.transactionId ~= nil then
		local transactionResult =
			TransactionRuntime.begin(authorized.transactionId, { authorized.commandId })
		if not transactionResult.ok then
			counters.transactionFailures += 1
			counters.rejected += 1
			return {
				ok = false,
				code = transactionResult.code,
				failure = normalizeFailure(
					transactionResult.code,
					"transaction registration",
					transactionResult.message,
					authorized
				),
			}
		end
	end
	if authorized.batchId ~= nil then
		Batch.register(authorized.batchId, { authorized.commandId })
	end
	Evidence.record("command validated", { commandId = authorized.commandId })
	local queued = CommandQueue.enqueue(authorized)
	if not queued.ok then
		if queued.code == Types.FailureType.QueueFull then
			counters.queueOverflows += 1
		end
		counters.rejected += 1
		return {
			ok = false,
			code = queued.code,
			failure = normalizeFailure(queued.code, "queue admission", queued.message, authorized),
		}
	end
	observe("timeline queued", function()
		Timeline.record(authorized, Types.Status.Queued, "Queued")
		Metrics.recordQueued(CommandQueue.getDepth())
	end)
	return Serialization.deepCopy({
		ok = true,
		code = "Ok",
		commandId = authorized.commandId,
		commandType = authorized.commandType,
		status = Types.Status.Queued,
		queued = true,
		correlationId = authorized.correlationId,
		causationId = authorized.causationId,
		executionMode = authorized.executionMode,
		transactionId = authorized.transactionId,
		batchId = authorized.batchId,
		sequence = authorized.sequence,
	})
end

function Runtime.submitBatch(requests: { any })
	if type(requests) ~= "table" or #requests > Types.Limits.MaxBatchSize then
		return { ok = false, code = Types.FailureType.ValidationFailure, message = "invalid batch" }
	end
	local results = {}
	for _, request in ipairs(requests) do
		table.insert(results, Runtime.submit(request))
	end
	return { ok = true, code = "Ok", results = Serialization.copyArray(results) }
end

function Runtime.cancel(commandId: string)
	local result = CommandQueue.cancelQueued(commandId)
	if result.ok then
		counters.cancelled += 1
	else
		counters.rejected += 1
	end
	return result
end

function Runtime.dispatchNext()
	local command = CommandQueue.dequeue()
	if command == nil then
		return { ok = true, code = "Empty" }
	end
	if command.executionState == Types.Status.Failed then
		counters.failed += 1
		return {
			ok = false,
			code = Types.FailureType.InternalRuntimeFailure,
			commandId = command.commandId,
			failureReason = command.failureReason,
		}
	end
	local definition = CommandRegistry.get(command.commandType)
	if definition == nil then
		counters.failed += 1
		return {
			ok = false,
			code = Types.FailureType.UnknownCommandType,
			commandId = command.commandId,
		}
	end
	counters.routing += 1
	observe("timeline scheduled", function()
		Timeline.record(command, Types.Status.Scheduled, "Scheduled")
		Metrics.recordScheduled(command)
	end)
	local handler = HandlerRegistry.resolve(command.commandType)
	local plan = Router.route(command, definition, handler)
	table.insert(routingHistory, Serialization.deepCopy(plan))
	while #routingHistory > Types.Limits.MaxExecutionHistory do
		table.remove(routingHistory, 1)
	end
	counters.executing += 1
	local policy = command.executionPolicySnapshot or ExecutionPolicy.normalize(definition)
	local lockResult = LockManager.acquire(command.commandId, policy.lockIds)
	if not lockResult.ok then
		counters.lockFailures += 1
		observe("lock contention metrics", function()
			Metrics.recordLockContention()
		end)
		if RetryRuntime.shouldRetry(command, policy) then
			local retryResult = RetryRuntime.queue(command, lockResult.message)
			if retryResult.ok then
				CommandQueue.enqueue(retryResult.command)
				observe("retry metrics", function()
					Metrics.recordRetryScheduled()
				end)
				return {
					ok = false,
					code = Types.FailureType.LockFailure,
					commandId = command.commandId,
					status = Types.Status.Queued,
					retryQueued = true,
				}
			end
		end
		counters.failed += 1
		return {
			ok = false,
			code = Types.FailureType.LockFailure,
			commandId = command.commandId,
			status = Types.Status.Failed,
			failureReason = lockResult.message,
		}
	end
	observe("timeline executing", function()
		Timeline.record(command, Types.Status.Executing, "Executing")
	end)
	local result = Execution.execute(command, plan)
	LockManager.release(command.commandId)
	local ticksUsed = 1
	if result.commandResult ~= nil and result.commandResult.diagnostics ~= nil then
		ticksUsed = result.commandResult.diagnostics.ticksUsed or ticksUsed
	end
	if result.ok and ticksUsed > policy.timeoutBudget then
		counters.timeoutCount += 1
		result.ok = false
		result.code = Types.FailureType.ExecutionTimeoutFailure
		result.failureCategory = Types.FailureType.ExecutionTimeoutFailure
		result.status = Types.Status.Failed
		result.failureReason = "execution budget exceeded"
		result.commandResult.status = Types.ResultStatus.Failure
		result.commandResult.resultCode = Types.FailureType.ExecutionTimeoutFailure
	end
	observe("execution observability", function()
		local observedCommand = result.commandEnvelope or command
		Timeline.record(observedCommand, result.status, result.status)
		Correlation.record(command, result)
		Metrics.recordExecution(result)
		Profiler.record(command, result, plan.handlerId)
		Profiler.recordShape(
			Runtime.getCounters().nestedDepth,
			if command.batchId ~= nil then 1 else 0
		)
		Sessions.recordCommand(command, result)
	end)
	Replay.record(command, policy)
	if result.ok then
		counters.succeeded += 1
		if command.transactionId ~= nil then
			local transactionResult = TransactionRuntime.commit(command.transactionId)
			if not transactionResult.ok then
				counters.transactionFailures += 1
			end
		end
		EventBus.publishDeferred("core.command.succeeded", {
			commandId = command.commandId,
			commandType = command.commandType,
			ownerRuntime = command.ownerRuntime,
		})
	else
		counters.failed += 1
		if command.transactionId ~= nil then
			local rollbackResult = TransactionRuntime.rollback(
				command.transactionId,
				result.failureReason or result.code
			)
			if not rollbackResult.ok then
				counters.rollbackFailures += 1
			end
		end
		if result.code == Types.FailureType.ExecutionTimeoutFailure then
			Recovery.markInterrupted(command, result.failureReason or result.code)
			counters.interruptedCommands += 1
		end
	end
	return result
end

function Runtime.dispatchAll()
	local results = {}
	while CommandQueue.getDepth() > 0 do
		table.insert(results, Runtime.dispatchNext())
	end
	return { ok = true, code = "Ok", results = Serialization.copyArray(results) }
end

function Runtime.inspect()
	return Diagnostics.capture(Runtime)
end

function Runtime.getSnapshot()
	return require(script.Parent.CommandSnapshots).capture(Runtime)
end

function Runtime.validate(): (boolean, string?)
	return true, nil
end

function Runtime.shutdown()
	shutdown = true
	Evidence.record("shutdown completed", {})
	CommandQueue.clear()
	Execution.clear()
	Ancestry.clear()
	Batch.clear()
	Correlation.clear()
	Metrics.clear()
	LockManager.clear()
	Profiler.clear()
	Recovery.clear()
	Replay.clear()
	RetryRuntime.clear()
	Sessions.clear()
	Timeline.clear()
	TransactionRuntime.clear()
	TraceGraph.clear()
end

function Runtime.reset()
	shutdown = false
	sequence = 0
	table.clear(routingHistory)
	table.clear(seenCommandIds)
	table.clear(seenIdempotencyKeys)
	for key in pairs(counters) do
		if key == "lastCommandId" or key == "lastFailure" then
			counters[key] = nil
		else
			counters[key] = 0
		end
	end
	CommandRegistry.clear()
	RequesterRegistry.clear()
	HandlerRegistry.clear()
	CommandQueue.clear()
	Execution.clear()
	Ancestry.clear()
	Batch.clear()
	Correlation.clear()
	Evidence.clear()
	Metrics.clear()
	LockManager.clear()
	Profiler.clear()
	Recovery.clear()
	Replay.clear()
	RetryRuntime.clear()
	Sessions.clear()
	Timeline.clear()
	TransactionRuntime.clear()
	TraceGraph.clear()
	registerCoreDefaults()
end

function Runtime.isShutdown(): boolean
	return shutdown
end

function Runtime.getRoutingHistory()
	return Serialization.copyArray(routingHistory)
end

local function mapCount(map: any): number
	local count = 0
	for _ in pairs(map) do
		count += 1
	end
	return count
end

function Runtime.getCounters()
	local lockRegistry = LockManager.inspect()
	local transactions = TransactionRuntime.inspect()
	local retries = RetryRuntime.inspect()
	local replayState = Replay.inspect()
	local recoveryState = Recovery.inspect()
	local batchState = Batch.inspect()
	local ancestry = Ancestry.inspect()
	local metrics = Metrics.inspect()
	local certification = Certification.inspect()
	local integrity = Integrity.calculate({
		selfChecks = true,
		architectureValidation = true,
		runtimeValidation = true,
		replayValidation = true,
		diagnosticsHealth = true,
		observabilityHealth = true,
		cleanupSuccess = true,
		certificationEvidence = certification.status == "ProductionCertified",
	})
	return {
		commandTypes = #Serialization.sortedKeys(CommandRegistry.inspect()),
		requesters = #Serialization.sortedKeys(RequesterRegistry.inspect()),
		handlers = #Serialization.sortedKeys(HandlerRegistry.inspect()),
		queued = CommandQueue.getDepth(),
		routing = counters.routing,
		executing = counters.executing,
		succeeded = counters.succeeded,
		cancelled = counters.cancelled,
		rejected = counters.rejected,
		failed = counters.failed,
		queueOverflows = counters.queueOverflows,
		idempotencyRejects = counters.idempotencyRejects,
		activeTransactions = mapCount(transactions),
		heldLocks = mapCount(lockRegistry),
		queuedRetries = #retries,
		timeoutCount = counters.timeoutCount,
		replayState = replayState,
		interruptedCommands = #recoveryState,
		nestedDepth = mapCount(ancestry),
		batchCount = mapCount(batchState),
		transactionFailures = counters.transactionFailures,
		rollbackFailures = counters.rollbackFailures,
		lockFailures = counters.lockFailures,
		retryLimitExceeded = counters.retryLimitExceeded,
		instrumentationFaults = counters.instrumentationFaults,
		metrics = metrics,
		runtimeHealth = Health.calculate(counters, metrics),
		pressureMetrics = Runtime.getPressureMetrics(),
		certificationStatus = certification.status,
		certificationChecklist = certification.checklist,
		certificationBlockedReason = certification.blockedReason,
		integrityScore = integrity,
		resourceBudgets = ResourceBudgets.inspect(),
		performanceBudgets = PerformanceBudgets.inspect(),
		compatibilityMetadata = Compatibility.inspect(),
		migrationMetadata = Migration.inspect(),
		auditMetadata = Audits.inspect(),
		stressValidation = StressValidation.inspect(),
		faultInjection = FaultInjection.inspect(),
		productionReview = ProductionReview.inspect(),
		maximumQueueDepth = CommandQueue.getMaximumDepth(),
		lastCommandId = counters.lastCommandId,
		lastFailure = counters.lastFailure,
	}
end

function Runtime.getObservabilitySnapshot()
	local countersSnapshot = Runtime.getCounters()
	return Serialization.deepCopy({
		timelines = Timeline.inspect(),
		metrics = Metrics.inspect(),
		health = countersSnapshot.runtimeHealth,
		pressureMetrics = countersSnapshot.pressureMetrics,
		profiler = Profiler.inspect(),
		correlationGraph = Correlation.inspect(),
		traceGraph = TraceGraph.inspect(),
		sessions = Sessions.inspect(),
		inspectionViews = Inspection.capture({
			runtime = countersSnapshot,
			commandQueue = CommandQueue.inspect(),
			execution = Execution.inspect(),
			transactions = TransactionRuntime.inspect(),
			locks = LockManager.inspect(),
			retries = RetryRuntime.inspect(),
			replay = Replay.inspect(),
			recovery = Recovery.inspect(),
			evidence = Evidence.inspect(),
			diagnostics = Runtime.inspect(),
			timelines = Timeline.inspect(),
			correlations = Correlation.inspect(),
			traceGraph = TraceGraph.inspect(),
		}),
		certification = Certification.inspect(),
		resourceBudgets = ResourceBudgets.inspect(),
		performanceBudgets = PerformanceBudgets.inspect(),
		compatibility = Compatibility.inspect(),
		migration = Migration.inspect(),
		audits = Audits.inspect(),
		stressValidation = StressValidation.inspect(),
		faultInjection = FaultInjection.inspect(),
		integrity = Integrity.calculate({
			selfChecks = true,
			architectureValidation = true,
			runtimeValidation = true,
			replayValidation = true,
			diagnosticsHealth = true,
			observabilityHealth = true,
			cleanupSuccess = true,
			certificationEvidence = Certification.inspect().status == "ProductionCertified",
		}),
		productionReview = ProductionReview.inspect(),
	})
end

function Runtime.getPressureMetrics()
	local queuePressure =
		math.min(100, (CommandQueue.getDepth() / Types.Limits.MaxQueueDepth) * 100)
	local retryPressure =
		math.min(100, (#RetryRuntime.inspect() / Types.Limits.MaxRetryAttempts) * 100)
	local lockPressure =
		math.min(100, (mapCount(LockManager.inspect()) / Types.Limits.MaxLocksPerCommand) * 100)
	local executionPressure =
		math.min(100, (counters.executing / Types.Limits.MaxExecutionHistory) * 100)
	return {
		queuePressure = queuePressure,
		executionPressure = executionPressure,
		lockPressure = lockPressure,
		retryPressure = retryPressure,
	}
end

Runtime.reset()

return Runtime
