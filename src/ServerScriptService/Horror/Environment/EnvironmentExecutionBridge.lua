--!strict
--[[
	Execution contract bridge for approved environment reactions.

	This module does not move objects, change Lighting, play audio, or trust
	clients. It publishes server-side instructions for future execution systems.
]]

local ServerScriptService = game:GetService("ServerScriptService")

local EventBus = require(ServerScriptService.Core.EventBus)

local EnvironmentSignals = require(script.Parent.EnvironmentSignals)
local Types = require(script.Parent.EnvironmentDirectorTypes)

local EnvironmentExecutionBridge = {}

local counts: { [string]: number } = {}
local failures: { any } = {}
local lastRequest: any = nil

local function recordFailure(reason: string, payload: any)
	table.insert(failures, {
		at = os.clock(),
		reason = reason,
		payload = payload,
	})

	while #failures > 30 do
		table.remove(failures, 1)
	end
end

function EnvironmentExecutionBridge.validatePayload(payload: any): (boolean, string?)
	if type(payload) ~= "table" then
		return false, "Execution payload must be a table"
	end

	if
		type(payload.executionKind) ~= "string"
		or not Types.ValidExecutionKinds[payload.executionKind]
	then
		return false, "Execution payload has invalid executionKind"
	end

	if type(payload.reactionId) ~= "string" or payload.reactionId == "" then
		return false, "Execution payload requires reactionId"
	end

	if type(payload.zoneId) ~= "string" or payload.zoneId == "" then
		return false, "Execution payload requires zoneId"
	end

	if type(payload.reason) ~= "string" or payload.reason == "" then
		return false, "Execution payload requires reason"
	end

	if type(payload.createdAt) ~= "number" then
		return false, "Execution payload requires createdAt"
	end

	return true, nil
end

function EnvironmentExecutionBridge.request(payload: any): (boolean, string?)
	local valid, err = EnvironmentExecutionBridge.validatePayload(payload)

	if not valid then
		recordFailure(err or "Invalid payload", payload)
		return false, err
	end

	counts[payload.executionKind] = (counts[payload.executionKind] or 0) + 1
	lastRequest = table.clone(payload)

	EventBus.publishDeferred(EnvironmentSignals.ExecutionRequested, {
		request = table.clone(payload),
	})

	return true, nil
end

function EnvironmentExecutionBridge.inspect()
	return {
		counts = table.clone(counts),
		failures = table.clone(failures),
		lastRequest = lastRequest,
	}
end

function EnvironmentExecutionBridge.reset()
	table.clear(counts)
	table.clear(failures)
	lastRequest = nil
end

return EnvironmentExecutionBridge
