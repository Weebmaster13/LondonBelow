--!strict

local Evidence = require(script.Parent.CommandEvidence)
local Serialization = require(script.Parent.CommandSerialization)
local Types = require(script.Parent.CommandTypes)

local Retry = {}
local queuedRetries: { any } = {}

function Retry.shouldRetry(command: any, policy: any): boolean
	local attempts = command.retryAttempts or 0
	if policy.retryPolicy == Types.RetryPolicy.NeverRetry then
		return false
	end
	if policy.retryPolicy == Types.RetryPolicy.RetryOnce then
		return attempts < 1
	end
	return attempts < Types.Limits.MaxRetryAttempts
end

function Retry.queue(command: any, reason: string)
	local nextCommand = table.clone(command)
	nextCommand.retryAttempts = (nextCommand.retryAttempts or 0) + 1
	table.insert(queuedRetries, Serialization.deepCopy({ command = nextCommand, reason = reason }))
	Evidence.record("retry queued", { commandId = command.commandId, reason = reason })
	return { ok = true, code = "Ok", command = Serialization.deepCopy(nextCommand) }
end

function Retry.inspect()
	return Serialization.copyArray(queuedRetries)
end

function Retry.clear()
	table.clear(queuedRetries)
end

return Retry
