--!strict

local Definitions = require(script.Parent.GameplayFlowDefinitions)
local Evaluation = require(script.Parent.GameplayFlowObjectiveEvaluation)
local Registry = require(script.Parent.GameplayFlowObjectiveRegistry)
local State = require(script.Parent.GameplayFlowObjectiveState)
local Types = require(script.Parent.GameplayFlowTypes)

local Runtime = {}

local function result(ok: boolean, code: string, message: string?, extra: any?)
	local payload = extra or {}
	payload.ok = ok
	payload.code = code
	payload.message = message
	return payload
end

function Runtime.registerChapter0Objectives()
	local objectives = Definitions.getChapter0Objectives()
	local ok, reason = Registry.registerAll(objectives)
	if not ok then
		return result(false, Types.ResultCode.InvalidGraph, reason)
	end
	State.initializeObjectives(Registry.order())
	local evaluation = Evaluation.evaluate(Registry, State, "runtime initialization")
	return result(true, Types.ResultCode.Ok, "Chapter 0 objectives registered", {
		evaluation = evaluation,
	})
end

function Runtime.recordEvent(event: any)
	local ok, reason = State.recordEvent(event)
	if not ok then
		return result(false, Types.ResultCode.InvalidRequest, reason)
	end
	State.enqueueEvaluation(event.eventId)
	local evaluation = Evaluation.evaluate(Registry, State, event.eventId)
	return result(true, Types.ResultCode.Ok, "gameplay flow event recorded", {
		evaluation = evaluation,
	})
end

function Runtime.evaluate(reason: string?)
	local evaluation = Evaluation.evaluate(Registry, State, reason)
	return result(true, Types.ResultCode.Ok, "gameplay flow evaluated", {
		evaluation = evaluation,
	})
end

function Runtime.getActiveObjective(): string?
	return State.getActiveObjective()
end

function Runtime.inspect()
	return State.inspect()
end

function Runtime.serialize()
	return State.serialize()
end

function Runtime.clear()
	Registry.clear()
	State.clear()
end

Runtime.Registry = Registry
Runtime.State = State

return Runtime
