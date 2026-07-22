--!strict

local ConsumerRegistry = require(script.Parent.ConsumerRegistry)
local Evidence = require(script.Parent.MessagingEvidence)
local Serialization = require(script.Parent.MessagingSerialization)
local Types = require(script.Parent.MessagingTypes)

local DependencyRegistry = {}

local lastOrder = {}
local lastFailure: any = nil

local function visit(
	consumerId: string,
	visiting: { [string]: boolean },
	visited: { [string]: boolean },
	order: { string }
)
	if visiting[consumerId] then
		return false, Types.FailureType.DependencyCycle
	end
	if visited[consumerId] then
		return true, nil
	end
	local consumer = ConsumerRegistry.get(consumerId)
	if consumer == nil then
		return false, Types.FailureType.MissingDependency
	end
	visiting[consumerId] = true
	for _, dependencyId in ipairs(consumer.dependencies) do
		if not ConsumerRegistry.has(dependencyId) then
			return false, Types.FailureType.MissingDependency .. ": " .. dependencyId
		end
		local ok, reason = visit(dependencyId, visiting, visited, order)
		if not ok then
			return false, reason
		end
	end
	visiting[consumerId] = nil
	visited[consumerId] = true
	table.insert(order, consumerId)
	return true, nil
end

function DependencyRegistry.validate()
	local order = {}
	local visited = {}
	local ids = ConsumerRegistry.ids()
	for _, consumerId in ipairs(ids) do
		local ok, reason = visit(consumerId, {}, visited, order)
		if not ok then
			lastFailure = { consumerId = consumerId, reason = reason }
			Evidence.record("dependency validation failed", lastFailure)
			return {
				ok = false,
				code = reason,
				order = {},
				failure = Serialization.deepCopy(lastFailure),
			}
		end
	end
	lastOrder = order
	lastFailure = nil
	Evidence.record("dependency validation completed", { order = order })
	return { ok = true, code = "Ok", order = Serialization.copyArray(order) }
end

function DependencyRegistry.getInitializationOrder()
	return Serialization.copyArray(lastOrder)
end

function DependencyRegistry.getShutdownOrder()
	local order = Serialization.copyArray(lastOrder)
	local left = 1
	local right = #order
	while left < right do
		order[left], order[right] = order[right], order[left]
		left += 1
		right -= 1
	end
	return order
end

function DependencyRegistry.inspect()
	local graph = {}
	for _, consumerId in ipairs(ConsumerRegistry.ids()) do
		local consumer = ConsumerRegistry.get(consumerId)
		graph[consumerId] = {
			dependencies = Serialization.copyArray(consumer.dependencies),
			dependents = {},
		}
	end
	for consumerId, node in pairs(graph) do
		for _, dependencyId in ipairs(node.dependencies) do
			if graph[dependencyId] ~= nil then
				table.insert(graph[dependencyId].dependents, consumerId)
			end
		end
	end
	return {
		graph = graph,
		initializationOrder = DependencyRegistry.getInitializationOrder(),
		shutdownOrder = DependencyRegistry.getShutdownOrder(),
		lastFailure = Serialization.deepCopy(lastFailure),
	}
end

function DependencyRegistry.clear()
	table.clear(lastOrder)
	lastFailure = nil
end

return DependencyRegistry
