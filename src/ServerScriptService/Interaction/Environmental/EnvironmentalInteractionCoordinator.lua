--!strict

local ServerScriptService = game:GetService("ServerScriptService")

local Core = ServerScriptService.Core
local Diagnostics = require(Core.Diagnostics)
local Logger = require(Core.Logger)
local SnapshotManager = require(Core.SnapshotManager)

local DiagnosticsRuntime = require(script.Parent.EnvironmentalDiagnostics)
local FamilyRegistry = require(script.Parent.EnvironmentalFamilyRegistry)
local Registry = require(script.Parent.EnvironmentalObjectRegistry)
local SelfChecks = require(script.Parent.EnvironmentalSelfChecks)
local Snapshots = require(script.Parent.EnvironmentalSnapshots)
local State = require(script.Parent.EnvironmentalStateRuntime)
local Types = require(script.Parent.EnvironmentalTypes)

local Coordinator = {}

local log = Logger.scope(Types.RuntimeName)
local initialized = false
local started = false
local lastSelfChecks: any = nil

function Coordinator.initialize()
	if initialized then
		return
	end
	Diagnostics.registerSampler(Types.RuntimeName, Coordinator.inspect)
	SnapshotManager.registerProvider("environmentalInteractionRuntime", Coordinator.getSnapshot)
	initialized = true
	log.success("Environmental Interaction Runtime initialized")
end

function Coordinator.start()
	if started then
		return
	end
	if not initialized then
		Coordinator.initialize()
	end
	started = true
end

function Coordinator.shutdown()
	Registry.clear()
	initialized = false
	started = false
end

function Coordinator.registerDefinition(definition: any)
	return Registry.register(definition)
end

function Coordinator.unregisterObject(objectId: string)
	return Registry.unregister(objectId)
end

function Coordinator.requestAction(player: any, request: any)
	if not initialized then
		return {
			ok = false,
			code = Types.ResultCode.RuntimeUnavailable,
			message = "Environmental Interaction Runtime is not initialized",
		}
	end
	return Registry.request(player, request)
end

function Coordinator.resetObject(objectId: string)
	return Registry.reset(objectId)
end

function Coordinator.inspect()
	return DiagnosticsRuntime.capture({
		initialized = initialized,
		started = started,
		lastSelfChecks = lastSelfChecks,
	}, State, FamilyRegistry)
end

function Coordinator.getSnapshot()
	return Snapshots.capture(State, Coordinator.inspect())
end

function Coordinator.validate()
	return true, nil
end

function Coordinator.runSelfChecks()
	lastSelfChecks = SelfChecks.run(Coordinator)
	return lastSelfChecks
end

return Coordinator
