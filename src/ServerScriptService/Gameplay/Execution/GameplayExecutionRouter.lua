--!strict

local Config = require(script.Parent.GameplayExecutionConfig)
local Validator = require(script.Parent.GameplayExecutionValidator)
local Copy = require(script.Parent.Parent.Core.GameplayCopy)

local GameplayExecutionRouter = {}

local adapters: { [string]: any } = {}
local counters = {
	registered = 0,
	unregistered = 0,
	rejected = 0,
}

function GameplayExecutionRouter.registerAdapter(kind: string, adapter: any): (boolean, string?)
	if Config.AllowedExecutionKinds[kind] ~= true then
		counters.rejected += 1
		return false, "adapter kind is not allowed"
	end
	local valid, reason = Validator.validateAdapter(adapter)
	if not valid then
		counters.rejected += 1
		return false, reason
	end
	adapters[kind] = adapter
	counters.registered += 1
	return true, nil
end

function GameplayExecutionRouter.unregisterAdapter(kind: string): boolean
	if adapters[kind] == nil then
		return false
	end
	adapters[kind] = nil
	counters.unregistered += 1
	return true
end

function GameplayExecutionRouter.getAdapter(kind: string): any?
	return adapters[kind]
end

function GameplayExecutionRouter.apply(request: any): (boolean, string)
	local adapter = adapters[request.executionKind]
	if adapter == nil then
		return false, "no adapter registered for execution kind"
	end
	local canOk, canApply, canReason = pcall(adapter.canApply, request)
	if not canOk then
		return false, "adapter canApply threw: " .. tostring(canApply)
	end
	if not canApply then
		return false, canReason or "adapter cannot apply request"
	end
	local applyOk, ok, reason = pcall(adapter.apply, request)
	if not applyOk then
		pcall(adapter.rollback, request)
		return false, "adapter apply threw: " .. tostring(ok)
	end
	if not ok then
		pcall(adapter.rollback, request)
		return false, reason or "adapter failed"
	end
	return true, "applied"
end

function GameplayExecutionRouter.inspect()
	local adapterDescriptions = {}
	local adapterCount = 0
	for kind, adapter in pairs(adapters) do
		adapterCount += 1
		local describeOk, description = pcall(adapter.describe)
		local healthOk, health = pcall(adapter.getHealth)
		local diagnosticsOk, diagnostics = pcall(adapter.getDiagnostics)
		adapterDescriptions[kind] = {
			description = if describeOk then description else "adapter describe failed",
			health = if healthOk then health else { healthy = false },
			diagnostics = if diagnosticsOk
				then diagnostics
				else { error = "adapter diagnostics failed" },
		}
	end
	return {
		adapterCount = adapterCount,
		adapters = Copy.dictionary(adapterDescriptions),
		counters = table.clone(counters),
	}
end

function GameplayExecutionRouter.clear()
	table.clear(adapters)
	for key in pairs(counters) do
		counters[key] = 0
	end
end

return GameplayExecutionRouter
