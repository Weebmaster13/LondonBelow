--!strict
-- Dependency verification. Dependencies are evidence schemas, not gameplay calls.

local Serialization = require(script.Parent.ExecutionSerialization)
local Types = require(script.Parent.ExecutionTypes)
local Validation = require(script.Parent.ExecutionValidation)

local DependencyRuntime = {}

local dependenciesByExecution: { [string]: any } = {}
local dependencyOrder: { string } = {}

local function countEntries(values: any): number
	local count = 0
	for _ in pairs(values) do
		count += 1
	end
	return count
end

local function countStoredDependencies(): number
	local count = 0
	for _, dependencies in pairs(dependenciesByExecution) do
		count += countEntries(dependencies)
	end
	return count
end

function DependencyRuntime.verify(executionId: string, dependencies: any): (boolean, string?)
	if type(dependencies) ~= "table" or next(dependencies) == nil then
		return false, "missing dependencies"
	end
	if countEntries(dependencies) > Types.Limits.MaxDependenciesPerRequest then
		return false, "dependency count exceeds limit"
	end
	for _, dependency in pairs(dependencies) do
		if type(dependency) ~= "table" then
			return false, "dependency must be a table"
		end
		if not Validation.id(dependency.dependencyId) then
			return false, "dependencyId is required"
		end
		if not Validation.id(dependency.sourceSystem) then
			return false, "dependency sourceSystem is required"
		end
		if dependency.status ~= "Verified" then
			return false, "dependency is not verified"
		end
	end
	dependenciesByExecution[executionId] = Serialization.deepCopy(dependencies)
	table.insert(dependencyOrder, executionId)
	while #dependencyOrder > Types.Limits.MaxRequests do
		local oldId = table.remove(dependencyOrder, 1)
		if oldId ~= nil then
			dependenciesByExecution[oldId] = nil
		end
	end
	return true, nil
end

function DependencyRuntime.inspect()
	return {
		dependencyCount = countStoredDependencies(),
		dependenciesByExecution = Serialization.deepCopy(dependenciesByExecution),
	}
end

function DependencyRuntime.clear()
	table.clear(dependenciesByExecution)
	table.clear(dependencyOrder)
end

return DependencyRuntime
