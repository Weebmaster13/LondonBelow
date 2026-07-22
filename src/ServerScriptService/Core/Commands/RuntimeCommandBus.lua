--!strict

local CommandQueue = require(script.Parent.CommandQueue)
local Ancestry = require(script.Parent.CommandAncestry)
local Batch = require(script.Parent.CommandBatchRuntime)
local CommandRegistry = require(script.Parent.CommandRegistry)
local Diagnostics = require(script.Parent.CommandDiagnostics)
local Evidence = require(script.Parent.CommandEvidence)
local Execution = require(script.Parent.CommandExecutionRuntime)
local ExecutionPolicy = require(script.Parent.CommandExecutionPolicy)
local HandlerRegistry = require(script.Parent.CommandHandlerRegistry)
local Lifecycle = require(script.Parent.CommandLifecycle)
local LockManager = require(script.Parent.CommandLockManager)
local Recovery = require(script.Parent.CommandRecovery)
local Replay = require(script.Parent.CommandReplay)
local RequesterRegistry = require(script.Parent.CommandRequesterRegistry)
local RetryRuntime = require(script.Parent.CommandRetryRuntime)
local Router = require(script.Parent.CommandRouter)
local Serialization = require(script.Parent.CommandSerialization)
local TransactionRuntime = require(script.Parent.CommandTransactionRuntime)
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
		if RetryRuntime.shouldRetry(command, policy) then
			local retryResult = RetryRuntime.queue(command, lockResult.message)
			if retryResult.ok then
				CommandQueue.enqueue(retryResult.command)
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
	LockManager.clear()
	Recovery.clear()
	Replay.clear()
	RetryRuntime.clear()
	TransactionRuntime.clear()
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
	Evidence.clear()
	LockManager.clear()
	Recovery.clear()
	Replay.clear()
	RetryRuntime.clear()
	TransactionRuntime.clear()
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
		maximumQueueDepth = CommandQueue.getMaximumDepth(),
		lastCommandId = counters.lastCommandId,
		lastFailure = counters.lastFailure,
	}
end

Runtime.reset()

return Runtime
