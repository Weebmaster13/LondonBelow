--!strict

local ServerScriptService = game:GetService("ServerScriptService")

local Core = ServerScriptService.Core
local Diagnostics = require(Core.Diagnostics)
local Logger = require(Core.Logger)
local SnapshotManager = require(Core.SnapshotManager)

local DiagnosticsRuntime = require(script.Parent.Chapter0EnvironmentalDiagnostics)
local Registry = require(script.Parent.Chapter0FixtureRegistry)
local SelfChecks = require(script.Parent.Chapter0EnvironmentalSelfChecks)
local Snapshots = require(script.Parent.Chapter0EnvironmentalSnapshots)
local State = require(script.Parent.Chapter0EnvironmentalState)
local Types = require(script.Parent.Chapter0EnvironmentalTypes)

local Coordinator = {}

local log = Logger.scope(Types.RuntimeName)
local initialized = false
local started = false
local lastSelfChecks: any = nil

function Coordinator.initialize()
	if initialized then
		return
	end
	Diagnostics.registerSampler(Types.ProviderName, Coordinator.inspect)
	SnapshotManager.registerProvider(Types.ProviderName, Coordinator.getSnapshot)
	Registry.prepare()
	initialized = true
	log.success("Chapter 0 Environmental Binding initialized")
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
	Registry.reset()
	initialized = false
	started = false
end

function Coordinator.reconcile()
	return Registry.reconcile()
end

function Coordinator.resetFixtures()
	return Registry.reset()
end

function Coordinator.inspect()
	return DiagnosticsRuntime.capture({
		initialized = initialized,
		started = started,
		lastSelfChecks = lastSelfChecks,
	}, Registry)
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
