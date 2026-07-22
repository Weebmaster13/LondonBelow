--!strict

local ServerScriptService = game:GetService("ServerScriptService")

local Core = ServerScriptService.Core
local Diagnostics = require(Core.Diagnostics)
local Logger = require(Core.Logger)
local SnapshotManager = require(Core.SnapshotManager)

local Runtime = require(script.Parent.RuntimeWorkflowOrchestration)
local SelfChecks = require(script.Parent.WorkflowSelfChecks)
local Types = require(script.Parent.WorkflowTypes)

local Coordinator = {}
local log = Logger.scope("RuntimeWorkflowOrchestration")
local COORDINATOR_ID = "RuntimeWorkflowCoordinator"
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
	log.success("Runtime Workflow Orchestration initialized")
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

function Coordinator.registerWorkflow(definition: any)
	return Runtime.registerWorkflow(definition)
end

function Coordinator.createInstance(request: any)
	return Runtime.createInstance(request)
end

function Coordinator.activateWorkflow(request: any, priority: number?, deadline: number?)
	return Runtime.activateWorkflow(request, priority, deadline)
end

function Coordinator.schedule(instanceId: string, priority: number?, deadline: number?)
	return Runtime.schedule(instanceId, priority, deadline)
end

function Coordinator.runNext()
	return Runtime.runNext()
end

function Coordinator.transition(instanceId: string, source: string, variables: any?)
	return Runtime.transition(instanceId, source, variables)
end

function Coordinator.routeMessage(message: any)
	return Runtime.routeMessage(message)
end

function Coordinator.suspendWorkflow(
	instanceId: string,
	waitKind: string,
	target: string,
	timeoutAt: number?
)
	return Runtime.suspendWorkflow(instanceId, waitKind, target, timeoutAt)
end

function Coordinator.resumeWorkflow(message: any)
	return Runtime.resumeWorkflow(message)
end

function Coordinator.validateCompletion(instanceId: string)
	return Runtime.validateCompletion(instanceId)
end

function Coordinator.inspect()
	local diagnostics = Runtime.inspect()
	diagnostics.coordinatorId = COORDINATOR_ID
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
		lastSelfChecks =
			{ ok = false, reason = "Runtime Workflow self-checks require a stopped runtime." }
		return lastSelfChecks
	end
	lastSelfChecks = SelfChecks.run()
	return lastSelfChecks
end

return Coordinator
