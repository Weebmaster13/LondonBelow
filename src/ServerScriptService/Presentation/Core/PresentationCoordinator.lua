--!strict
--[[
	Phase 22 Presentation Runtime Coordinator.

	Server-authoritative schema-only presentation approval and routing. It
	records future presentation intent without creating remotes, final UI,
	audio, lighting, camera effects, VFX, cutscenes, or client-owned truth.
]]

local ServerScriptService = game:GetService("ServerScriptService")

local Core = ServerScriptService.Core
local Diagnostics = require(Core.Diagnostics)
local EventBus = require(Core.EventBus)
local Logger = require(Core.Logger)
local SnapshotManager = require(Core.SnapshotManager)

local ApprovalRuntime = require(script.Parent.PresentationApprovalRuntime)
local ChannelRuntime = require(script.Parent.PresentationChannelRuntime)
local Chapter0Binding = require(script.Parent.PresentationChapter0Binding)
local CommandRuntime = require(script.Parent.PresentationCommandRuntime)
local Dispatcher = require(script.Parent.PresentationDispatcher)
local Evidence = require(script.Parent.PresentationEvidence)
local PresentationDiagnostics = require(script.Parent.PresentationDiagnostics)
local QueueRuntime = require(script.Parent.PresentationQueueRuntime)
local RequestRuntime = require(script.Parent.PresentationRequestRuntime)
local RoutingRuntime = require(script.Parent.PresentationRoutingRuntime)
local SelfChecks = require(script.Parent.PresentationSelfChecks)
local Serialization = require(script.Parent.PresentationSerialization)
local Signals = require(script.Parent.PresentationSignals)
local Snapshots = require(script.Parent.PresentationSnapshots)
local Types = require(script.Parent.PresentationTypes)
local Validation = require(script.Parent.PresentationValidation)

local PresentationCoordinator = {}

local log = Logger.scope("PresentationRuntime")
local initialized = false
local started = false
local lastSelfChecks: any = nil

local dependencies = {
	ApprovalRuntime = ApprovalRuntime,
	ChannelRuntime = ChannelRuntime,
	CommandRuntime = CommandRuntime,
	Dispatcher = Dispatcher,
	Evidence = Evidence,
	QueueRuntime = QueueRuntime,
	RequestRuntime = RequestRuntime,
	RoutingRuntime = RoutingRuntime,
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

local function codeFor(reason: string?): string
	if reason == "duplicate presentationId" then
		return Types.ResultCode.DuplicatePresentation
	elseif reason == "duplicate approvalId" then
		return Types.ResultCode.DuplicateApproval
	elseif reason ~= nil and string.find(reason, "approval", 1, true) then
		return Types.ResultCode.MissingApproval
	elseif reason ~= nil and string.find(reason, "channel", 1, true) then
		return if reason == "invalid channel" or reason == "duplicate channel"
			then Types.ResultCode.InvalidChannel
			else Types.ResultCode.MissingChannel
	elseif reason == "presentation request is expired" then
		return Types.ResultCode.Expired
	elseif reason == "unsupported presentation type" then
		return Types.ResultCode.UnsupportedPresentationType
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

local function recordFailure(reason: string, payload: any?)
	RequestRuntime.recordValidationFailure(reason, payload)
	EventBus.publishDeferred(Signals.ValidationFailed, { reason = reason })
	EventBus.publishDeferred(Signals.RequestRejected, { reason = reason })
end

function PresentationCoordinator.submit(rawRequest: any)
	local currentTime = os.clock()
	local request = RequestRuntime.normalize(rawRequest, currentTime)

	if
		type(request.presentationId) == "string" and RequestRuntime.exists(request.presentationId)
	then
		recordFailure("duplicate presentationId", request)
		return result(false, Types.ResultCode.DuplicatePresentation, "duplicate presentationId")
	end

	local requestOk, requestReason = Validation.request(request, currentTime)
	if not requestOk then
		recordFailure(requestReason or "presentation request rejected", request)
		return result(false, codeFor(requestReason), requestReason)
	end

	local approvalsOk, approvalsReason =
		ApprovalRuntime.verify(request.presentationId, request.approvals)
	if not approvalsOk then
		recordFailure(approvalsReason or "approval verification failed", request)
		return result(false, codeFor(approvalsReason), approvalsReason)
	end

	local channelsOk, channelsReason =
		ChannelRuntime.verify(request.presentationId, request.channels)
	if not channelsOk then
		recordFailure(channelsReason or "channel verification failed", request)
		return result(false, codeFor(channelsReason), channelsReason)
	end

	RequestRuntime.add(request)
	local queued, queueReason = QueueRuntime.enqueue(request)
	if not queued then
		recordFailure(queueReason or "presentation queue rejected request", request)
		return result(false, Types.ResultCode.QueueFull, queueReason)
	end

	local route = RoutingRuntime.record(request)
	EventBus.publishDeferred(Signals.RequestQueued, { presentationId = request.presentationId })
	EventBus.publishDeferred(Signals.RequestRouted, route)
	EventBus.publishDeferred(Signals.RequestRecorded, { presentationId = request.presentationId })

	return result(true, Types.ResultCode.Ok, "presentation request recorded", {
		route = route,
	})
end

PresentationCoordinator.submitPresentationRequest = PresentationCoordinator.submit

function PresentationCoordinator.submitCommand(rawCommand: any)
	if not initialized then
		return result(
			false,
			Types.ResultCode.InvalidCommand,
			"Presentation Runtime is not initialized"
		)
	end
	local queued, reason, command = CommandRuntime.enqueue(rawCommand)
	if not queued then
		RequestRuntime.recordValidationFailure(
			reason or "presentation command rejected",
			rawCommand
		)
		return result(
			false,
			if reason == "duplicate commandId"
				then Types.ResultCode.DuplicateCommand
				else Types.ResultCode.InvalidCommand,
			reason
		)
	end
	Evidence.record("PresentationCommandQueued", {
		commandId = command.commandId,
		presentationType = command.presentationType,
		objectId = command.objectId,
	}, Types.Limits.MaxEvidence)
	return result(true, Types.ResultCode.Ok, "presentation command queued", {
		command = command,
	})
end

function PresentationCoordinator.dispatchNext()
	if not initialized then
		return result(
			false,
			Types.ResultCode.InvalidCommand,
			"Presentation Runtime is not initialized"
		)
	end
	local command = CommandRuntime.nextCommand()
	if command == nil then
		return result(true, Types.ResultCode.Ok, "no presentation commands queued", {
			empty = true,
		})
	end
	local route = Dispatcher.route(command)
	CommandRuntime.applyState(command)
	CommandRuntime.recordExecuted(command, route)
	Evidence.record("PresentationCommandDispatched", {
		commandId = command.commandId,
		presentationType = command.presentationType,
		channelType = route.channelType,
	}, Types.Limits.MaxEvidence)
	return result(true, Types.ResultCode.Ok, "presentation command dispatched", {
		command = command,
		route = route,
	})
end

function PresentationCoordinator.dispatchAll()
	local dispatched = {}
	while true do
		local nextResult = PresentationCoordinator.dispatchNext()
		if not nextResult.ok or nextResult.empty == true then
			return result(nextResult.ok, nextResult.code, "presentation dispatch complete", {
				dispatched = dispatched,
			})
		end
		table.insert(dispatched, nextResult)
	end
end

function PresentationCoordinator.bindChapter0FixturePresentation()
	if not initialized then
		return result(
			false,
			Types.ResultCode.InvalidCommand,
			"Presentation Runtime is not initialized"
		)
	end
	local queued = {}
	for _, command in ipairs(Chapter0Binding.commandsForCatalog()) do
		local submitted = PresentationCoordinator.submitCommand(command)
		if not submitted.ok then
			return result(false, submitted.code, "Chapter 0 presentation binding failed", {
				failed = submitted,
				queued = queued,
			})
		end
		table.insert(queued, submitted.command.commandId)
	end
	Evidence.record("Chapter0FixturePresentationBound", {
		commandCount = #queued,
	}, Types.Limits.MaxEvidence)
	return result(true, Types.ResultCode.Ok, "Chapter 0 presentation commands queued", {
		commandCount = #queued,
		commandIds = queued,
	})
end

function PresentationCoordinator.initialize()
	if initialized then
		return
	end
	local valid, reason = PresentationCoordinator.validate()
	if not valid then
		error("PresentationCoordinator validation failed: " .. tostring(reason), 0)
	end
	Diagnostics.registerSampler("PresentationRuntime", PresentationCoordinator.inspect)
	SnapshotManager.registerProvider("presentationRuntime", PresentationCoordinator.getSnapshot)
	initialized = true
	log.success("Presentation Runtime initialized")
end

function PresentationCoordinator.start()
	if started then
		return
	end
	if not initialized then
		PresentationCoordinator.initialize()
	end
	started = true
end

function PresentationCoordinator.shutdown()
	RequestRuntime.clear()
	ApprovalRuntime.clear()
	ChannelRuntime.clear()
	QueueRuntime.clear()
	RoutingRuntime.clear()
	CommandRuntime.clear()
	Dispatcher.clear()
	Evidence.clear()
	Snapshots.clear()
	started = false
	initialized = false
end

function PresentationCoordinator.inspect()
	return PresentationDiagnostics.capture({
		initialized = initialized,
		started = started,
		lastSelfChecks = lastSelfChecks,
	}, dependencies)
end

function PresentationCoordinator.getSnapshot()
	local snapshot = Snapshots.capture(dependencies)
	EventBus.publishDeferred(
		Signals.SnapshotCaptured,
		{ snapshot = Serialization.deepCopy(snapshot) }
	)
	return snapshot
end

function PresentationCoordinator.validate(): (boolean, string?)
	return PresentationDiagnostics.validate(dependencies)
end

function PresentationCoordinator.runSelfChecks()
	if started then
		lastSelfChecks = {
			ok = false,
			reason = "Presentation Runtime self-checks are destructive and may only run before start.",
		}
		return lastSelfChecks
	end
	lastSelfChecks = SelfChecks.run({ Service = PresentationCoordinator })
	return lastSelfChecks
end

return PresentationCoordinator
