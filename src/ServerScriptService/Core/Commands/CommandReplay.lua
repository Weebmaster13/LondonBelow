--!strict

local Serialization = require(script.Parent.CommandSerialization)

local Replay = {}
local metadata: { any } = {}

function Replay.record(command: any, policy: any)
	table.insert(metadata, {
		commandId = command.commandId,
		commandType = command.commandType,
		sequence = command.sequence,
		priority = command.priority,
		ownerRuntime = command.ownerRuntime,
		replayPolicy = policy.replayPolicy,
	})
end

function Replay.inspect()
	return Serialization.copyArray(metadata)
end

function Replay.clear()
	table.clear(metadata)
end

return Replay
