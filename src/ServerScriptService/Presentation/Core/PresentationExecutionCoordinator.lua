--!strict

local ServerScriptService = game:GetService("ServerScriptService")

local Core = ServerScriptService.Core
local Diagnostics = require(Core.Diagnostics)
local Logger = require(Core.Logger)
local SnapshotManager = require(Core.SnapshotManager)

local Runtime = require(script.Parent.RuntimePresentationExecution)
local SelfChecks = require(script.Parent.PresentationExecutionSelfChecks)
local Types = require(script.Parent.PresentationTypes)

local Coordinator = {}
local log = Logger.scope("PresentationRuntimeExecution")
local initialized = false
local started = false
local lastSelfChecks: any = nil

function Coordinator.initialize()
	if initialized then
		return
	end
	Diagnostics.registerSampler(Types.ExecutionProviderName, Coordinator.inspect)
	SnapshotManager.registerProvider(Types.ExecutionProviderName, Coordinator.getSnapshot)
	initialized = true
	log.success("Presentation Runtime Execution initialized")
end

function Coordinator.start()
	if not initialized then
		Coordinator.initialize()
	end
	started = true
end

function Coordinator.shutdown()
	Runtime.shutdown()
	started = false
	initialized = false
end

function Coordinator.createExecution(request: any)
	return Runtime.createExecution(request)
end

function Coordinator.enqueueExecution(executionId: string)
	return Runtime.enqueueExecution(executionId)
end

function Coordinator.scheduleNext()
	return Runtime.scheduleNext()
end

function Coordinator.execute(executionId: string)
	return Runtime.execute(executionId)
end

function Coordinator.suspend(executionId: string)
	return Runtime.suspend(executionId)
end

function Coordinator.resume(executionId: string)
	return Runtime.resume(executionId)
end

function Coordinator.cancel(executionId: string, reason: string)
	return Runtime.cancel(executionId, reason)
end

function Coordinator.expire(executionId: string, reason: string)
	return Runtime.expire(executionId, reason)
end

function Coordinator.produceAcknowledgement(request: any)
	return Runtime.produceAcknowledgement(request)
end

function Coordinator.resolveSynchronization(executionId: string)
	return Runtime.resolveSynchronization(executionId)
end

function Coordinator.inspect()
	local diagnostics = Runtime.inspect()
	diagnostics.coordinatorId = "PresentationExecutionCoordinator"
	diagnostics.initialized = initialized
	diagnostics.started = started
	diagnostics.lastSelfChecks = lastSelfChecks
	return diagnostics
end

function Coordinator.getSnapshot()
	return Runtime.getSnapshot()
end

function Coordinator.validate(): (boolean, string?)
	return Runtime.validate()
end

function Coordinator.runSelfChecks()
	if started then
		lastSelfChecks = {
			ok = false,
			reason = "Presentation execution self-checks require a stopped runtime.",
		}
		return lastSelfChecks
	end
	lastSelfChecks = SelfChecks.run()
	return lastSelfChecks
end

return Coordinator
