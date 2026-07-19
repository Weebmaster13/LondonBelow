--!strict

local Core = script.Parent.Parent.Parent.Core
local EngineDiagnostics = require(Core.Diagnostics)
local Logger = require(Core.Logger)
local SnapshotManager = require(Core.SnapshotManager)

local Diagnostics = require(script.Parent.Diagnostics)
local RuntimeAssertions = require(script.Parent.RuntimeAssertions)
local RuntimeCapture = require(script.Parent.RuntimeCapture)
local RuntimeCleanup = require(script.Parent.RuntimeCleanup)
local RuntimeDiagnostics = require(script.Parent.RuntimeDiagnostics)
local RuntimeEvidence = require(script.Parent.RuntimeEvidence)
local RuntimeLifecycle = require(script.Parent.RuntimeLifecycle)
local RuntimeSession = require(script.Parent.RuntimeSession)
local RuntimeWriter = require(script.Parent.RuntimeWriter)
local SelfChecks = require(script.Parent.SelfChecks)
local Snapshots = require(script.Parent.Snapshots)
local State = require(script.Parent.State)
local Types = require(script.Parent.Types)
local Validation = require(script.Parent.Validation)

local BridgeCoordinator = {}

local lifecycle = {
	initialized = false,
	started = false,
	lastSelfChecks = nil :: any,
}

local log = Logger.scope("RuntimeExecutionBridge")

local function result(ok: boolean, code: string, message: string?)
	return { ok = ok, code = code, message = message }
end

function BridgeCoordinator.initialize()
	if lifecycle.initialized then
		return result(true, "AlreadyInitialized", nil)
	end
	local ok, reason = Validation.validate()
	if not ok then
		return result(false, "ValidationFailed", reason)
	end
	EngineDiagnostics.registerSampler(Types.RuntimeProviderName, function()
		return BridgeCoordinator.inspect()
	end)
	SnapshotManager.registerProvider(Types.RuntimeProviderName, function()
		return BridgeCoordinator.getSnapshot()
	end)
	lifecycle.initialized = true
	log.info("Runtime Execution Bridge initialized")
	return result(true, "Initialized", nil)
end

function BridgeCoordinator.start(sessionOverride: any?)
	if not lifecycle.initialized then
		return result(
			false,
			"NotInitialized",
			"Runtime Execution Bridge must initialize before start"
		)
	end
	if lifecycle.started then
		return result(true, "AlreadyStarted", nil)
	end

	local sessionOk, sessionReason, session = RuntimeSession.import(sessionOverride)
	if not sessionOk or session == nil then
		return result(false, "SessionRejected", sessionReason)
	end

	RuntimeLifecycle.startBridge()
	RuntimeLifecycle.startCapture()
	local observation = RuntimeCapture.observe()
	local assertions = RuntimeAssertions.capture({
		coordinatorCount = observation.coordinators.count,
	})
	local diagnostics = RuntimeDiagnostics.capture({
		coordinatorCount = observation.coordinators.count,
	})
	local cleanup = RuntimeCleanup.run()
	local snapshots = {
		{
			snapshotKind = "runtimeExecutionBridgeServiceSnapshot",
			observation = observation,
			bridgeState = State.get(),
			frameworkMetadata = {
				sessionId = session.sessionId,
				manifestId = session.manifestId,
				runnerId = session.runnerId,
				frameworkVersion = session.frameworkVersion,
			},
		},
	}
	local evidenceOk, evidenceReason, evidence =
		RuntimeEvidence.build(session, observation, assertions, diagnostics, snapshots, cleanup)
	if not evidenceOk or evidence == nil then
		return result(false, "EvidenceRejected", evidenceReason)
	end
	State.setEvidence(evidence)
	local writerResult = RuntimeWriter.writeAtomic(session, evidence)
	State.setWriterResult(writerResult)
	RuntimeLifecycle.completeCapture()
	RuntimeLifecycle.cleanup()
	lifecycle.started = true

	return {
		ok = writerResult.ok,
		code = if writerResult.ok then "EvidenceWritten" else "WriterBlocked",
		message = writerResult.reason,
		writerResult = writerResult,
	}
end

function BridgeCoordinator.shutdown()
	State.clear()
	lifecycle.initialized = false
	lifecycle.started = false
	lifecycle.lastSelfChecks = nil
	return result(true, "Shutdown", nil)
end

function BridgeCoordinator.inspect()
	return Diagnostics.capture(lifecycle)
end

function BridgeCoordinator.getSnapshot()
	return Snapshots.capture(lifecycle)
end

function BridgeCoordinator.validate(): (boolean, string?)
	return Diagnostics.validate()
end

function BridgeCoordinator.runSelfChecks()
	if lifecycle.started then
		return result(
			false,
			"AlreadyStarted",
			"Runtime Execution Bridge self-checks must run before start"
		)
	end
	lifecycle.lastSelfChecks = SelfChecks.run({ Service = BridgeCoordinator })
	return lifecycle.lastSelfChecks
end

return BridgeCoordinator
