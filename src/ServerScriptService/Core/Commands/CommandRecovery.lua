--!strict

local Evidence = require(script.Parent.CommandEvidence)
local Serialization = require(script.Parent.CommandSerialization)

local Recovery = {}
local interrupted: { any } = {}

function Recovery.markInterrupted(command: any, reason: string)
	table.insert(interrupted, {
		commandId = command.commandId,
		commandType = command.commandType,
		reason = reason,
		recoveryPolicy = command.recoveryPolicy or "OwnerRuntime",
	})
	Evidence.record("command interrupted", { commandId = command.commandId, reason = reason })
end

function Recovery.inspect()
	return Serialization.copyArray(interrupted)
end

function Recovery.clear()
	table.clear(interrupted)
end

return Recovery
