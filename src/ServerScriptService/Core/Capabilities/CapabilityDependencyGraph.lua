--!strict

local Evidence = require(script.Parent.CapabilityEvidence)
local Registry = require(script.Parent.CapabilityRegistry)
local Serialization = require(script.Parent.CapabilitySerialization)
local Types = require(script.Parent.CapabilityTypes)

local DependencyGraph = {}
local validationRecords = {}

local function hasInterface(definition: any, interfaceId: string): boolean
	for _, interfaceRecord in ipairs(definition.interfaces) do
		if interfaceRecord.interfaceId == interfaceId then
			return true
		end
	end
	return false
end

local function visit(capabilityId: string, visiting: any, visited: any): boolean
	if visiting[capabilityId] then
		return false
	end
	if visited[capabilityId] then
		return true
	end
	visiting[capabilityId] = true
	local definition = Registry.get(capabilityId)
	if definition ~= nil then
		for _, dependency in ipairs(definition.dependencies) do
			if
				Registry.has(dependency.capabilityId)
				and not visit(dependency.capabilityId, visiting, visited)
			then
				return false
			end
		end
	end
	visiting[capabilityId] = nil
	visited[capabilityId] = true
	return true
end

function DependencyGraph.validate(capabilityId: string)
	local definition = Registry.get(capabilityId)
	if definition == nil then
		return {
			ok = false,
			code = Types.FailureType.UnknownCapability,
			message = "unknown capability",
		}
	end
	for _, dependency in ipairs(definition.dependencies) do
		local dependencyDefinition = Registry.get(dependency.capabilityId)
		if dependencyDefinition == nil then
			return {
				ok = false,
				code = Types.FailureType.UnknownDependency,
				message = "missing dependency",
			}
		end
		if not hasInterface(dependencyDefinition, dependency.interfaceId) then
			return {
				ok = false,
				code = Types.FailureType.MissingInterface,
				message = "dependency interface missing",
			}
		end
	end
	if not visit(capabilityId, {}, {}) then
		return { ok = false, code = Types.FailureType.DependencyCycle, message = "dependency cycle" }
	end
	local record = {
		capabilityId = capabilityId,
		dependencyCount = #definition.dependencies,
		validatedAt = os.clock(),
		ok = true,
	}
	table.insert(validationRecords, record)
	Evidence.record("capability dependencies validated", record)
	return { ok = true, code = "Ok", capabilityId = capabilityId }
end

function DependencyGraph.inspect()
	local graph = {}
	local definitions = Registry.inspect()
	for capabilityId, definition in pairs(definitions) do
		graph[capabilityId] = Serialization.deepCopy(definition.dependencies)
	end
	return {
		graph = graph,
		validationRecords = Serialization.copyArray(validationRecords),
	}
end

function DependencyGraph.clear()
	table.clear(validationRecords)
end

return DependencyGraph
