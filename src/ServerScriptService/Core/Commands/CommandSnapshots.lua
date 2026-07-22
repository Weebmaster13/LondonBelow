--!strict

local CommandRegistry = require(script.Parent.CommandRegistry)
local CommandQueue = require(script.Parent.CommandQueue)
local Evidence = require(script.Parent.CommandEvidence)
local Execution = require(script.Parent.CommandExecutionRuntime)
local HandlerRegistry = require(script.Parent.CommandHandlerRegistry)
local Lifecycle = require(script.Parent.CommandLifecycle)
local RequesterRegistry = require(script.Parent.CommandRequesterRegistry)
local Serialization = require(script.Parent.CommandSerialization)

local Snapshots = {}

function Snapshots.capture(runtime: any)
	return Serialization.deepCopy({
		commandRegistrySnapshot = CommandRegistry.inspect(),
		requesterRegistrySnapshot = RequesterRegistry.inspect(),
		handlerRegistrySnapshot = HandlerRegistry.inspect(),
		lifecycleSnapshot = Lifecycle.inspect(),
		queueSnapshot = CommandQueue.inspect(),
		routingSnapshot = runtime.getRoutingHistory(),
		executionSnapshot = Execution.inspect(),
		diagnosticsSnapshot = runtime.inspect(),
		evidenceSnapshot = Evidence.inspect(),
	})
end

return Snapshots
