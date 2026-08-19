--!strict

local ServerScriptService = game:GetService("ServerScriptService")
local Core = ServerScriptService.Core
local Diagnostics = require(Core.Diagnostics)
local Logger = require(Core.Logger)
local SnapshotManager = require(Core.SnapshotManager)
local Runtime = require(script.Parent.RuntimeRobloxGuiInstanceContract)
local SelfChecks = require(script.Parent.RobloxGuiInstanceContractSelfChecks)
local Types = require(script.Parent.RobloxGuiInstanceContractTypes)

local Coordinator = {}
local log = Logger.scope("RobloxGuiInstanceContract")
local initialized, started = false, false
local lastSelfChecks = nil

function Coordinator.initialize()
	if initialized then return end
	Diagnostics.registerSampler(Types.ProviderName, Coordinator.inspect)
	SnapshotManager.registerProvider(Types.ProviderName, Coordinator.getSnapshot)
	initialized = true; log.success("Roblox GUI Instance Contract Foundation initialized")
end
function Coordinator.start() if not initialized then Coordinator.initialize() end; started = true end
function Coordinator.shutdown() Runtime.shutdown(); started = false; initialized = false end
function Coordinator.inspect() local value = Runtime.inspect(); value.coordinatorId = "RobloxGuiInstanceContractCoordinator"; value.initialized = initialized; value.started = started; value.lastSelfChecks = lastSelfChecks; return value end
function Coordinator.getSnapshot() return Runtime.getSnapshot() end
function Coordinator.validate(): (boolean, string?) return Runtime.validate() end
function Coordinator.runSelfChecks() if started then return { ok = false, reason = "self-checks require a stopped runtime" } end; lastSelfChecks = SelfChecks.run(); return lastSelfChecks end
function Coordinator.register(contract) return Runtime.register(contract) end
function Coordinator.validateContract(contractId) return Runtime.validateContract(contractId) end
function Coordinator.publish(contractId) return Runtime.publish(contractId) end
function Coordinator.getContract(contractId) return Runtime.getContract(contractId) end

return Coordinator
