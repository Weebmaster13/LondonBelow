--!strict

local Serialization = require(script.Parent.CommandSerialization)
local Types = require(script.Parent.CommandTypes)

local Sessions = {}
local activeSessionId = "runtimeCommandBus.session.default"
local sessions: { [string]: any } = {}

local function ensureSession()
	if sessions[activeSessionId] == nil then
		sessions[activeSessionId] = {
			sessionId = activeSessionId,
			createdAt = os.clock(),
			commands = {},
			failures = {},
			metrics = {},
		}
	end
	return sessions[activeSessionId]
end

function Sessions.recordCommand(command: any, result: any?)
	local session = ensureSession()
	table.insert(session.commands, command.commandId)
	if result ~= nil and result.ok == false then
		table.insert(session.failures, { commandId = command.commandId, code = result.code })
	end
	while #session.commands > Types.Limits.MaxSessionCommands do
		table.remove(session.commands, 1)
	end
end

function Sessions.recordMetrics(metrics: any)
	ensureSession().metrics = Serialization.deepCopy(metrics)
end

function Sessions.inspect()
	return Serialization.deepCopy({
		activeSessionId = activeSessionId,
		sessions = sessions,
	})
end

function Sessions.clear()
	table.clear(sessions)
	activeSessionId = "runtimeCommandBus.session.default"
end

return Sessions
