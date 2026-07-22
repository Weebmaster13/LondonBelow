--!strict

local ServerScriptService = game:GetService("ServerScriptService")

local Core = ServerScriptService.Core
local Diagnostics = require(Core.Diagnostics)
local Logger = require(Core.Logger)
local SnapshotManager = require(Core.SnapshotManager)

local Runtime = require(script.Parent.RuntimeDialogueExecution)
local SelfChecks = require(script.Parent.DialogueExecutionSelfChecks)
local Types = require(script.Parent.DialogueExecutionTypes)

local Coordinator = {}
local log = Logger.scope("DialogueRuntimeExecution")
local initialized = false
local started = false
local lastSelfChecks: any = nil

function Coordinator.initialize()
	if initialized then
		return
	end
	Diagnostics.registerSampler(Types.ProviderName, Coordinator.inspect)
	SnapshotManager.registerProvider(Types.ProviderName, Coordinator.getSnapshot)
	initialized = true
	log.success("Dialogue Runtime Execution initialized")
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

function Coordinator.startExecution(request: any)
	return Runtime.startExecution(request)
end

function Coordinator.selectChoice(executionId: string, choiceId: string)
	return Runtime.selectChoice(executionId, choiceId)
end

function Coordinator.suspendExecution(executionId: string, reason: string)
	return Runtime.suspendExecution(executionId, reason)
end

function Coordinator.resumeExecution(executionId: string)
	return Runtime.resumeExecution(executionId)
end

function Coordinator.recoverExecution(executionId: string)
	return Runtime.recoverExecution(executionId)
end

function Coordinator.inspect()
	local diagnostics = Runtime.inspect()
	diagnostics.coordinatorId = "DialogueExecutionCoordinator"
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
			reason = "Dialogue execution self-checks require a stopped runtime.",
		}
		return lastSelfChecks
	end
	lastSelfChecks = SelfChecks.run()
	return lastSelfChecks
end

return Coordinator
