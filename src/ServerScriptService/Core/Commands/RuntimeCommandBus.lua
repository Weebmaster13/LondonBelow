--!strict

local CommandQueue = require(script.Parent.CommandQueue)
local CommandRegistry = require(script.Parent.CommandRegistry)
local Diagnostics = require(script.Parent.CommandDiagnostics)
local Evidence = require(script.Parent.CommandEvidence)
local Execution = require(script.Parent.CommandExecutionRuntime)
local HandlerRegistry = require(script.Parent.CommandHandlerRegistry)
local RequesterRegistry = require(script.Parent.CommandRequesterRegistry)
local Router = require(script.Parent.CommandRouter)
local Serialization = require(script.Parent.CommandSerialization)
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
			idempotencyPolicy = Types.IdempotencyPolicy.OptionalIdempotencyKey,
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
		requesterId = request.requesterId,
		ownerRuntime = definition.ownerRuntime,
		issuedTimestamp = request.issuedTimestamp or os.clock(),
		priority = request.priority or definition.defaultPriority,
		payload = request.payload or {},
		correlationId = request.correlationId or commandId,
		causationId = request.causationId,
		idempotencyKey = request.idempotencyKey,
		sequence = nextSequence(),
		metadata = request.metadata or {},
	}
	counters.lastCommandId = command.commandId
	return Serialization.deepCopy(command)
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
	Evidence.record(
		"command submitted",
		{ commandId = command.commandId, commandType = command.commandType }
	)
	if command.schemaVersion ~= definition.schemaVersion then
		counters.rejected += 1
		return {
			ok = false,
			code = Types.FailureType.ValidationFailure,
			failure = normalizeFailure(
				Types.FailureType.ValidationFailure,
				"schema version",
				"schemaVersion mismatch",
				command
			),
		}
	end
	local payloadOk, payloadReason = definition.payloadValidator(command.payload)
	if not payloadOk then
		counters.rejected += 1
		return {
			ok = false,
			code = Types.FailureType.InvalidPayload,
			failure = normalizeFailure(
				Types.FailureType.InvalidPayload,
				"payload validation",
				tostring(payloadReason),
				command
			),
		}
	end
	if not RequesterRegistry.has(command.requesterId) then
		counters.rejected += 1
		return {
			ok = false,
			code = Types.FailureType.UnknownRequester,
			failure = normalizeFailure(
				Types.FailureType.UnknownRequester,
				"requester resolution",
				"unknown requester",
				command
			),
		}
	end
	if
		not RequesterRegistry.canRequest(command.requesterId, command.commandType)
		or not requesterAllowed(definition, command.requesterId)
	then
		counters.rejected += 1
		return {
			ok = false,
			code = Types.FailureType.RequesterNotAuthorized,
			failure = normalizeFailure(
				Types.FailureType.RequesterNotAuthorized,
				"requester permission",
				"requester cannot submit command",
				command
			),
		}
	end
	if not Validation.isValidPriority(command.priority) then
		counters.rejected += 1
		return {
			ok = false,
			code = Types.FailureType.InvalidPriority,
			failure = normalizeFailure(
				Types.FailureType.InvalidPriority,
				"priority",
				"invalid priority",
				command
			),
		}
	end
	if seenCommandIds[command.commandId] then
		counters.rejected += 1
		return {
			ok = false,
			code = Types.FailureType.DuplicateCommandId,
			failure = normalizeFailure(
				Types.FailureType.DuplicateCommandId,
				"identity",
				"duplicate command id",
				command
			),
		}
	end
	if command.idempotencyKey ~= nil and seenIdempotencyKeys[command.idempotencyKey] then
		counters.idempotencyRejects += 1
		return {
			ok = false,
			code = Types.FailureType.DuplicateIdempotencyKey,
			failure = normalizeFailure(
				Types.FailureType.DuplicateIdempotencyKey,
				"idempotency",
				"duplicate idempotency key",
				command
			),
		}
	end
	seenCommandIds[command.commandId] = true
	if command.idempotencyKey ~= nil then
		seenIdempotencyKeys[command.idempotencyKey] = true
	end
	Evidence.record("command validated", { commandId = command.commandId })
	local queued = CommandQueue.enqueue(command)
	if not queued.ok then
		if queued.code == Types.FailureType.QueueFull then
			counters.queueOverflows += 1
		end
		counters.rejected += 1
		return {
			ok = false,
			code = queued.code,
			failure = normalizeFailure(queued.code, "queue admission", queued.message, command),
		}
	end
	return Serialization.deepCopy({
		ok = true,
		code = "Ok",
		commandId = command.commandId,
		commandType = command.commandType,
		status = Types.Status.Queued,
		queued = true,
		correlationId = command.correlationId,
		sequence = command.sequence,
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
	local result = Execution.execute(command, plan)
	if result.ok then
		counters.succeeded += 1
		EventBus.publishDeferred("core.command.succeeded", {
			commandId = command.commandId,
			commandType = command.commandType,
			ownerRuntime = command.ownerRuntime,
		})
	else
		counters.failed += 1
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
	Evidence.clear()
	registerCoreDefaults()
end

function Runtime.isShutdown(): boolean
	return shutdown
end

function Runtime.getRoutingHistory()
	return Serialization.copyArray(routingHistory)
end

function Runtime.getCounters()
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
		maximumQueueDepth = CommandQueue.getMaximumDepth(),
		lastCommandId = counters.lastCommandId,
		lastFailure = counters.lastFailure,
	}
end

Runtime.reset()

return Runtime
