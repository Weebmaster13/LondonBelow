--!strict

local ServerScriptService = game:GetService("ServerScriptService")

local Core = ServerScriptService.Core
local Diagnostics = require(Core.Diagnostics)
local Logger = require(Core.Logger)
local SnapshotManager = require(Core.SnapshotManager)

local Runtime = require(script.Parent.RuntimeRobloxVisualComposition)
local SelfChecks = require(script.Parent.VisualCompositionSelfChecks)
local Types = require(script.Parent.PresentationTypes)

local Coordinator = {}
local log = Logger.scope("RobloxVisualComposition")
local initialized = false
local started = false
local lastSelfChecks: any = nil

function Coordinator.initialize()
	if initialized then
		return
	end
	Diagnostics.registerSampler(Types.RobloxVisualCompositionProviderName, Coordinator.inspect)
	SnapshotManager.registerProvider(
		Types.RobloxVisualCompositionProviderName,
		Coordinator.getSnapshot
	)
	initialized = true
	log.success("Roblox Visual Composition Runtime initialized")
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

function Coordinator.inspect()
	local diagnostics = Runtime.inspect()
	diagnostics.coordinatorId = "RobloxVisualCompositionCoordinator"
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
			reason = "Roblox visual composition self-checks require a stopped runtime.",
		}
		return lastSelfChecks
	end
	lastSelfChecks = SelfChecks.run()
	return lastSelfChecks
end

return Coordinator
