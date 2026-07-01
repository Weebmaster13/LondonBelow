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
	local canApply, canReason = adapter.canApply(request)
	if not canApply then
		return false, canReason or "adapter cannot apply request"
	end
	local ok, reason = adapter.apply(request)
	if not ok then
		adapter.rollback(request)
		return false, reason or "adapter failed"
	end
	return true, "applied"
end

function GameplayExecutionRouter.inspect()
	local adapterDescriptions = {}
	local adapterCount = 0
	for kind, adapter in pairs(adapters) do
		adapterCount += 1
		adapterDescriptions[kind] = {
			description = adapter.describe(),
			health = adapter.getHealth(),
			diagnostics = adapter.getDiagnostics(),
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
