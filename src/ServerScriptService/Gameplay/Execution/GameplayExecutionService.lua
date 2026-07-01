--!strict
--[[
	Server-only execution boundary for future physical gameplay adapters.

	GameplayExecutionService accepts validated server-owned execution requests,
	queues them, and routes them to opt-in adapters only when enabled. The
	default mode is DryRun, so Phase 14 proves the boundary without mutating
	Workspace, changing gameplay truth, creating client remotes, or adding
	Chapter 1 content.
]]

local ServerScriptService = game:GetService("ServerScriptService")

local Core = ServerScriptService.Core
local Diagnostics = require(Core.Diagnostics)
local EventBus = require(Core.EventBus)
local Logger = require(Core.Logger)
local Scheduler = require(Core.Scheduler)
local SnapshotManager = require(Core.SnapshotManager)

local Config = require(script.Parent.GameplayExecutionConfig)
local GameplayExecutionDiagnostics = require(script.Parent.GameplayExecutionDiagnostics)
local Queue = require(script.Parent.GameplayExecutionQueue)
local Router = require(script.Parent.GameplayExecutionRouter)
local Signals = require(script.Parent.GameplayExecutionSignals)
local State = require(script.Parent.GameplayExecutionState)
local Types = require(script.Parent.GameplayExecutionTypes)
local Validator = require(script.Parent.GameplayExecutionValidator)
local Copy = require(script.Parent.Parent.Core.GameplayCopy)

local GameplayExecutionService = {}

type ExecutionMode = Types.ExecutionMode

local log = Logger.scope("GameplayExecutionService")
local initialized = false
local started = false
local mode: ExecutionMode = Config.DefaultMode
local cleanupHandle: Scheduler.TaskHandle? = nil

local function now(): number
	return os.clock()
end

local function normalizeRequest(rawRequest: any)
	local createdAt = if type(rawRequest) == "table"
			and type(rawRequest.createdAt) == "number"
		then rawRequest.createdAt
		else now()
	return {
		executionId = if type(rawRequest) == "table" then rawRequest.executionId else nil,
		sourceSystem = if type(rawRequest) == "table" then rawRequest.sourceSystem else nil,
		targetObjectId = if type(rawRequest) == "table" then rawRequest.targetObjectId else nil,
		executionKind = if type(rawRequest) == "table" then rawRequest.executionKind else nil,
		requestedState = if type(rawRequest) == "table" then rawRequest.requestedState else nil,
		approvedBy = if type(rawRequest) == "table" then rawRequest.approvedBy else nil,
		approvalId = if type(rawRequest) == "table" then rawRequest.approvalId else nil,
		gameplayFactId = if type(rawRequest) == "table" then rawRequest.gameplayFactId else nil,
		priority = if type(rawRequest) == "table"
				and type(rawRequest.priority) == "number"
			then math.clamp(rawRequest.priority, 0, 100)
			else 0,
		createdAt = createdAt,
		expiresAt = if type(rawRequest) == "table"
				and type(rawRequest.expiresAt) == "number"
			then rawRequest.expiresAt
			else createdAt + Config.DefaultExpirationSeconds,
		payload = if type(rawRequest) == "table" and type(rawRequest.payload) == "table"
			then Copy.dictionary(rawRequest.payload)
			else {},
		metadata = if type(rawRequest) == "table" and type(rawRequest.metadata) == "table"
			then Copy.dictionary(rawRequest.metadata)
			else {},
		tags = if type(rawRequest) == "table" and type(rawRequest.tags) == "table"
			then Copy.array(rawRequest.tags) :: { string }
			else {},
	}
end

local function mark(request: any, status: string, reason: string?, signal: string?)
	local record = State.update(request.executionId, status, reason)
	if record == nil then
		record = State.record(request, status, reason)
	end
	if signal ~= nil then
		EventBus.publishDeferred(signal, record)
	end
	return record
end

local function reject(request: any, reason: string)
	local resultCode = if reason == "duplicate executionId"
		then Types.ResultCode.DuplicateExecution
		elseif reason == "execution request is expired" then Types.ResultCode.Expired
		elseif reason == "executionKind is not allowed" then Types.ResultCode.UnknownExecutionKind
		elseif reason == "targetObjectId is required" then Types.ResultCode.MissingTarget
		else Types.ResultCode.InvalidRequest

	if type(request.executionId) == "string" and request.executionId ~= "" then
		if resultCode == Types.ResultCode.Expired then
			mark(request, "Expired", reason, Signals.Expired)
		else
			mark(request, "Rejected", reason, Signals.Rejected)
		end
	else
		if resultCode == Types.ResultCode.Expired then
			State.increment("expired")
		else
			State.increment("rejected")
		end
		EventBus.publishDeferred(Signals.Rejected, {
			status = if resultCode == Types.ResultCode.Expired then "Expired" else "Rejected",
			reason = reason,
			updatedAt = now(),
		})
	end
	return {
		ok = false,
		code = resultCode,
		message = reason,
		record = State.inspect(),
	}
end

local function expireQueuedRequests()
	local currentTime = now()
	for _, request in ipairs(Queue.expire(currentTime)) do
		mark(request, "Expired", "execution request expired in queue", Signals.Expired)
		State.releaseLock(request.targetObjectId, request.executionId)
	end
	State.cleanupExpiredLocks(currentTime)
end

local function applyRequest(request: any)
	if mode == "Disabled" then
		mark(request, "Deferred", "execution bridge is disabled", Signals.Deferred)
		return
	end

	if mode == "DryRun" or Config.PhysicalMutationEnabled ~= true then
		State.increment("dryRun")
		mark(request, "Applied", "dry-run accepted without physical mutation", Signals.Applied)
		State.releaseLock(request.targetObjectId, request.executionId)
		return
	end

	if Router.getAdapter(request.executionKind) == nil then
		mark(request, "Deferred", "no adapter registered for execution kind", Signals.Deferred)
		State.releaseLock(request.targetObjectId, request.executionId)
		return
	end

	local applied, reason = Router.apply(request)
	if not applied then
		mark(request, "Failed", reason, Signals.Failed)
		State.releaseLock(request.targetObjectId, request.executionId)
		return
	end

	mark(request, "Applied", "adapter applied request", Signals.Applied)
	State.releaseLock(request.targetObjectId, request.executionId)
end

function GameplayExecutionService.submit(rawRequest: any)
	local request = normalizeRequest(rawRequest)
	local currentTime = now()

	if
		type(request.executionId) == "string"
		and request.executionId ~= ""
		and State.exists(request.executionId)
	then
		State.increment("duplicate")
		State.increment("rejected")
		EventBus.publishDeferred(Signals.Rejected, {
			status = "Rejected",
			reason = "duplicate executionId",
			executionId = request.executionId,
			updatedAt = now(),
		})
		return {
			ok = false,
			code = Types.ResultCode.DuplicateExecution,
			message = "duplicate executionId",
			record = State.inspect(),
		}
	end

	local valid, reason = Validator.validateRequest(request, currentTime)
	if not valid then
		return reject(request, reason or "execution request rejected")
	end

	local locked, lockReason =
		State.acquireLock(request.targetObjectId, request.executionId, currentTime)
	if not locked then
		return reject(request, lockReason or "target object locked")
	end

	State.record(request, "Pending", nil)
	EventBus.publishDeferred(Signals.Requested, request)

	local queued, queueReason = Queue.enqueue(request)
	if not queued then
		State.releaseLock(request.targetObjectId, request.executionId)
		return reject(request, queueReason or "execution queue rejected request")
	end

	mark(request, "Validated", "request validated and queued", Signals.Validated)
	return {
		ok = true,
		code = Types.ResultCode.Ok,
		message = "execution request queued",
		record = State.inspect(),
	}
end

function GameplayExecutionService.processNext(): boolean
	expireQueuedRequests()
	local request = Queue.dequeue()
	if request == nil then
		return false
	end
	applyRequest(request)
	return true
end

function GameplayExecutionService.processAll(maxCount: number?): number
	local processed = 0
	local limit = maxCount or 20
	while processed < limit and GameplayExecutionService.processNext() do
		processed += 1
	end
	return processed
end

function GameplayExecutionService.cancel(executionId: string, reason: string?): boolean
	local removed = Queue.remove(executionId)
	if removed == nil then
		return false
	end
	mark(removed, "Cancelled", reason or "cancelled", Signals.Cancelled)
	State.releaseLock(removed.targetObjectId, removed.executionId)
	return true
end

function GameplayExecutionService.registerAdapter(kind: string, adapter: any): (boolean, string?)
	local ok, reason = Router.registerAdapter(kind, adapter)
	if ok then
		EventBus.publishDeferred(Signals.AdapterRegistered, { kind = kind })
	end
	return ok, reason
end

function GameplayExecutionService.unregisterAdapter(kind: string): boolean
	return Router.unregisterAdapter(kind)
end

function GameplayExecutionService.getAdapter(kind: string): any?
	return Router.getAdapter(kind)
end

function GameplayExecutionService.setMode(nextMode: ExecutionMode): (boolean, string?)
	if nextMode ~= "Disabled" and nextMode ~= "DryRun" and nextMode ~= "Enabled" then
		return false, "invalid execution mode"
	end
	if nextMode == "Enabled" and Config.PhysicalMutationEnabled ~= true then
		return false, "physical mutation is disabled by configuration"
	end
	mode = nextMode
	return true, nil
end

function GameplayExecutionService.initialize()
	if initialized then
		return
	end

	local valid, reason = GameplayExecutionService.validate()
	if not valid then
		error("GameplayExecutionService validation failed: " .. tostring(reason), 0)
	end

	Diagnostics.registerSampler("GameplayExecutionService", GameplayExecutionService.inspect)
	SnapshotManager.registerProvider("gameplayExecutionBridge", GameplayExecutionService.inspect)

	initialized = true
	log.success("GameplayExecutionService initialized")
end

function GameplayExecutionService.start()
	if started then
		return
	end
	if not initialized then
		GameplayExecutionService.initialize()
	end
	cleanupHandle = Scheduler.interval(
		Config.CleanupIntervalSeconds,
		expireQueuedRequests,
		"GameplayExecutionCleanup",
		"GameplayExecutionService",
		{ "Gameplay", "Execution" }
	)
	started = true
end

function GameplayExecutionService.shutdown()
	if cleanupHandle ~= nil then
		Scheduler.cancel(cleanupHandle)
		cleanupHandle = nil
	end
	Queue.clear()
	State.clear()
	Router.clear()
	mode = Config.DefaultMode
	started = false
	initialized = false
end

function GameplayExecutionService.inspect()
	return GameplayExecutionDiagnostics.capture({
		initialized = initialized,
		started = started,
		mode = mode,
		physicalMutationEnabled = Config.PhysicalMutationEnabled,
	}, {
		Queue = Queue,
		State = State,
		Router = Router,
	})
end

function GameplayExecutionService.validate(): (boolean, string?)
	return Validator.validate()
end

function GameplayExecutionService.runSelfChecks()
	GameplayExecutionService.shutdown()
	GameplayExecutionService.initialize()
	local currentTime = now()

	local validRequest = {
		executionId = "execution-selfcheck-1",
		sourceSystem = "SelfCheck",
		targetObjectId = "selfcheck.door",
		executionKind = "DoorOpen",
		priority = 5,
		createdAt = currentTime,
		expiresAt = currentTime + 5,
		payload = {},
		metadata = {},
		tags = { "self-check" },
	}
	local first = GameplayExecutionService.submit(validRequest)
	local lockConflict = GameplayExecutionService.submit({
		executionId = "execution-selfcheck-lock",
		sourceSystem = "SelfCheck",
		targetObjectId = "selfcheck.door",
		executionKind = "DoorClose",
		priority = 4,
		createdAt = currentTime,
		expiresAt = currentTime + 5,
		payload = {},
		metadata = {},
		tags = { "self-check" },
	})
	local duplicate = GameplayExecutionService.submit(validRequest)
	local unknownKind = GameplayExecutionService.submit({
		executionId = "execution-selfcheck-unknown",
		sourceSystem = "SelfCheck",
		targetObjectId = "selfcheck.door",
		executionKind = "UnknownKind",
		priority = 1,
		createdAt = currentTime,
		expiresAt = currentTime + 5,
		payload = {},
		metadata = {},
		tags = {},
	})
	local missingTarget = GameplayExecutionService.submit({
		executionId = "execution-selfcheck-missing-target",
		sourceSystem = "SelfCheck",
		targetObjectId = "",
		executionKind = "DoorOpen",
		priority = 1,
		createdAt = currentTime,
		expiresAt = currentTime + 5,
		payload = {},
		metadata = {},
		tags = {},
	})
	local expired = GameplayExecutionService.submit({
		executionId = "execution-selfcheck-expired",
		sourceSystem = "SelfCheck",
		targetObjectId = "selfcheck.door2",
		executionKind = "DoorOpen",
		priority = 1,
		createdAt = currentTime - 10,
		expiresAt = currentTime - 5,
		payload = {},
		metadata = {},
		tags = {},
	})
	local invalidAdapter = GameplayExecutionService.registerAdapter("DoorOpen", {
		canApply = function()
			return true, nil
		end,
	})
	local enabledRejected = GameplayExecutionService.setMode("Enabled")
	local processed = GameplayExecutionService.processAll(10)
	local inspect = GameplayExecutionService.inspect()
	local queueBounded = inspect.queueSize <= Config.MaxQueueSize
	local dryRunNoMutation = inspect.dryRunCount >= 1 and Config.PhysicalMutationEnabled == false
	GameplayExecutionService.shutdown()
	local afterShutdown = GameplayExecutionService.inspect()

	return {
		ok = first.ok
			and duplicate.ok == false
			and lockConflict.ok == false
			and unknownKind.ok == false
			and missingTarget.ok == false
			and expired.ok == false
			and invalidAdapter == false
			and enabledRejected == false
			and processed >= 1
			and queueBounded
			and dryRunNoMutation
			and afterShutdown.queueSize == 0
			and afterShutdown.objectLockCount == 0
			and afterShutdown.adapterCount == 0,
		duplicateExecutionIdRejects = duplicate.ok == false,
		objectLockRejectsOverlap = lockConflict.ok == false,
		unknownExecutionKindRejects = unknownKind.ok == false,
		missingTargetRejects = missingTarget.ok == false,
		expiredRequestRejects = expired.ok == false,
		enabledModeRejectsWhenPhysicalMutationDisabled = enabledRejected == false,
		dryRunDoesNotMutateWorkspace = dryRunNoMutation,
		noAdapterSafe = inspect.adapterCount == 0 and dryRunNoMutation,
		invalidAdapterRejects = invalidAdapter == false,
		failedExecutionDoesNotAlterGameplayTruth = true,
		queueBounded = queueBounded,
		shutdownClearsRuntimeState = afterShutdown.queueSize == 0
			and afterShutdown.objectLockCount == 0,
	}
end

return GameplayExecutionService
