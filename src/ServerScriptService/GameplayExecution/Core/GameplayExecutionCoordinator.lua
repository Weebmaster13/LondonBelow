--!strict
--[[
	Phase 20 Gameplay Execution Bridge Coordinator.

	This coordinator is the server-authoritative intake and certification
	gateway for future execution. It validates evidence, records dry-run plans,
	and exposes diagnostics/snapshots. It does not mutate Workspace, run
	gameplay, own Monster AI, own Narrative, own Save, own pacing, or create
	client remotes.
]]

local ServerScriptService = game:GetService("ServerScriptService")

local Core = ServerScriptService.Core
local Diagnostics = require(Core.Diagnostics)
local EventBus = require(Core.EventBus)
local Logger = require(Core.Logger)
local SnapshotManager = require(Core.SnapshotManager)

local ApprovalRuntime = require(script.Parent.ExecutionApprovalRuntime)
local Audit = require(script.Parent.ExecutionAuditRuntime)
local DependencyRuntime = require(script.Parent.ExecutionDependencyRuntime)
local ExecutionDiagnostics = require(script.Parent.ExecutionDiagnostics)
local QueueRuntime = require(script.Parent.ExecutionQueueRuntime)
local RequestRuntime = require(script.Parent.ExecutionRequestRuntime)
local Scheduler = require(script.Parent.ExecutionScheduler)
local SelfChecks = require(script.Parent.ExecutionSelfChecks)
local Serialization = require(script.Parent.ExecutionSerialization)
local Signals = require(script.Parent.ExecutionSignals)
local Snapshots = require(script.Parent.ExecutionSnapshots)
local Types = require(script.Parent.ExecutionTypes)
local Validation = require(script.Parent.ExecutionValidation)

local GameplayExecutionCoordinator = {}

local log = Logger.scope("GameplayExecutionCoordinator")
local initialized = false
local started = false
local lastSelfChecks: any = nil

local dependencies = {
	ApprovalRuntime = ApprovalRuntime,
	Audit = Audit,
	DependencyRuntime = DependencyRuntime,
	QueueRuntime = QueueRuntime,
	RequestRuntime = RequestRuntime,
	Scheduler = Scheduler,
	Snapshots = Snapshots,
	Validation = Validation,
}

local function result(ok: boolean, code: string, message: string?, extra: any?)
	local payload = extra or {}
	payload.ok = ok
	payload.code = code
	payload.message = message
	return payload
end

local function recordFailure(reason: string, payload: any?)
	RequestRuntime.recordValidationFailure(reason, payload)
	QueueRuntime.mark(Types.Status.Rejected)
	Audit.record({
		status = Types.Status.Rejected,
		reason = reason,
		requester = if type(payload) == "table" then payload.requester else nil,
		sourceSystem = if type(payload) == "table" then payload.sourceSystem else nil,
		executionId = if type(payload) == "table" then payload.executionId else nil,
		priority = if type(payload) == "table" then payload.priority else nil,
	})
	EventBus.publishDeferred(Signals.ValidationFailed, { reason = reason })
end

local function codeFor(reason: string?): string
	if reason == "duplicate executionId" then
		return Types.ResultCode.DuplicateExecution
	elseif reason == "duplicate approvalId" then
		return Types.ResultCode.DuplicateApproval
	elseif reason ~= nil and string.find(reason, "approval", 1, true) then
		return Types.ResultCode.MissingApproval
	elseif reason ~= nil and string.find(reason, "dependenc", 1, true) then
		return Types.ResultCode.MissingDependency
	elseif reason == "execution request is expired" then
		return Types.ResultCode.Expired
	elseif reason == "unsupported execution type" then
		return Types.ResultCode.UnsupportedExecutionType
	elseif
		reason ~= nil
		and (
			string.find(reason, "payload", 1, true)
			or string.find(reason, "forbidden field", 1, true)
			or string.find(reason, "unsafe runtime", 1, true)
			or string.find(reason, "cyclic", 1, true)
		)
	then
		return Types.ResultCode.UnsafePayload
	end
	return Types.ResultCode.InvalidRequest
end

local function dryRunRecord(request: any, schedule: any)
	return Serialization.deepCopy({
		executionId = request.executionId,
		executionType = request.executionType,
		status = Types.Status.DryRun,
		wouldExecute = false,
		wouldMutateWorkspace = false,
		wouldCreateRemotes = false,
		wouldRunGameplay = false,
		schedule = schedule,
		recordedAt = os.clock(),
		reason = request.reason,
	})
end

function GameplayExecutionCoordinator.submit(rawRequest: any)
	local currentTime = os.clock()
	local request = RequestRuntime.normalize(rawRequest, currentTime)

	if type(request.executionId) == "string" and RequestRuntime.exists(request.executionId) then
		recordFailure("duplicate executionId", request)
		return result(false, Types.ResultCode.DuplicateExecution, "duplicate executionId")
	end

	local requestOk, requestReason = Validation.request(request, currentTime)
	if not requestOk then
		recordFailure(requestReason or "execution request rejected", request)
		return result(false, codeFor(requestReason), requestReason)
	end

	local approvalsOk, approvalsReason =
		ApprovalRuntime.verify(request.executionId, request.approvals)
	if not approvalsOk then
		recordFailure(approvalsReason or "approval verification failed", request)
		return result(false, codeFor(approvalsReason), approvalsReason)
	end

	local dependenciesOk, dependenciesReason =
		DependencyRuntime.verify(request.executionId, request.dependencies)
	if not dependenciesOk then
		recordFailure(dependenciesReason or "dependency verification failed", request)
		return result(false, codeFor(dependenciesReason), dependenciesReason)
	end

	RequestRuntime.add(request)
	local queued, queueReason = QueueRuntime.enqueue(request)
	if not queued then
		recordFailure(queueReason or "execution queue rejected request", request)
		return result(false, Types.ResultCode.QueueFull, queueReason)
	end

	QueueRuntime.mark(Types.Status.Approved)
	local schedule = Scheduler.schedule(request)
	EventBus.publishDeferred(Signals.RequestScheduled, { executionId = request.executionId })
	local dryRun = dryRunRecord(request, schedule)
	QueueRuntime.mark(Types.Status.DryRun)
	Audit.record({
		executionId = request.executionId,
		requester = request.requester,
		sourceSystem = request.sourceSystem,
		status = Types.Status.DryRun,
		reason = request.reason,
		priority = request.priority,
		dependencies = request.dependencies,
		approvals = request.approvals,
		dryRunRecord = dryRun,
	})
	EventBus.publishDeferred(Signals.DryRunRecorded, dryRun)
	EventBus.publishDeferred(Signals.RequestAccepted, { executionId = request.executionId })

	return result(true, Types.ResultCode.Ok, "execution dry-run recorded", {
		dryRunRecord = dryRun,
	})
end

GameplayExecutionCoordinator.submitExecutionRequest = GameplayExecutionCoordinator.submit

function GameplayExecutionCoordinator.initialize()
	if initialized then
		return
	end
	local valid, reason = GameplayExecutionCoordinator.validate()
	if not valid then
		error("GameplayExecutionCoordinator validation failed: " .. tostring(reason), 0)
	end
	Diagnostics.registerSampler(
		"GameplayExecutionCoordinator",
		GameplayExecutionCoordinator.inspect
	)
	SnapshotManager.registerProvider(
		"gameplayExecutionBridge",
		GameplayExecutionCoordinator.getSnapshot
	)
	initialized = true
	log.success("Gameplay Execution Bridge initialized")
end

function GameplayExecutionCoordinator.start()
	if started then
		return
	end
	if not initialized then
		GameplayExecutionCoordinator.initialize()
	end
	started = true
end

function GameplayExecutionCoordinator.shutdown()
	RequestRuntime.clear()
	ApprovalRuntime.clear()
	DependencyRuntime.clear()
	QueueRuntime.clear()
	Scheduler.clear()
	Audit.clear()
	Snapshots.clear()
	started = false
	initialized = false
end

function GameplayExecutionCoordinator.inspect()
	return ExecutionDiagnostics.capture({
		initialized = initialized,
		started = started,
		lastSelfChecks = lastSelfChecks,
	}, dependencies)
end

function GameplayExecutionCoordinator.getSnapshot()
	local snapshot = Snapshots.capture(dependencies)
	EventBus.publishDeferred(
		Signals.SnapshotCaptured,
		{ snapshot = Serialization.deepCopy(snapshot) }
	)
	return snapshot
end

function GameplayExecutionCoordinator.validate(): (boolean, string?)
	return ExecutionDiagnostics.validate(dependencies)
end

function GameplayExecutionCoordinator.runSelfChecks()
	if started then
		lastSelfChecks = {
			ok = false,
			reason = "Gameplay Execution self-checks are destructive and may only run before start.",
		}
		return lastSelfChecks
	end
	lastSelfChecks = SelfChecks.run({ Service = GameplayExecutionCoordinator })
	return lastSelfChecks
end

return GameplayExecutionCoordinator
