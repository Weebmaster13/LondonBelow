--!strict
--[[
	ServiceLocator is the London Engine service registry.

	It provides deterministic registration, resolution, replacement,
	freeze/validation controls, and dependency graph inspection. It is a
	runtime registry, not a substitute for clear module dependencies.
]]

local ServiceLocator = {}

export type ServiceRecord = {
	name: string,
	service: any,
	dependencies: { string },
	optionalDependencies: { string },
	registeredAt: number,
}

local records: { [string]: ServiceRecord } = {}
local frozen = false

local function copyArray(values: { string }?): { string }
	if values == nil then
		return {}
	end

	local copied = {}

	for _, value in ipairs(values) do
		table.insert(copied, value)
	end

	return copied
end

local function assertName(name: string)
	assert(type(name) == "string" and name ~= "", "service name must be a non-empty string")
end

local function visit(
	name: string,
	visiting: { [string]: boolean },
	visited: { [string]: boolean },
	path: { string }
): (boolean, string?)
	if visiting[name] then
		table.insert(path, name)
		return false, "Circular dependency detected: " .. table.concat(path, " -> ")
	end

	if visited[name] then
		return true, nil
	end

	local record = records[name]

	if record == nil then
		return false, "Missing dependency record for " .. name
	end

	visiting[name] = true
	table.insert(path, name)

	for _, dependencyName in ipairs(record.dependencies) do
		if records[dependencyName] == nil then
			return false,
				string.format("Service '%s' requires missing service '%s'", name, dependencyName)
		end

		local ok, err = visit(dependencyName, visiting, visited, path)

		if not ok then
			return false, err
		end
	end

	table.remove(path)
	visiting[name] = nil
	visited[name] = true

	return true, nil
end

function ServiceLocator.register(
	name: string,
	service: any,
	dependencies: { string }?,
	optionalDependencies: { string }?
)
	assertName(name)
	assert(service ~= nil, "service cannot be nil")

	if frozen then
		error("ServiceLocator is frozen", 2)
	end

	if records[name] ~= nil then
		error(string.format("Service '%s' is already registered", name), 2)
	end

	records[name] = {
		name = name,
		service = service,
		dependencies = copyArray(dependencies),
		optionalDependencies = copyArray(optionalDependencies),
		registeredAt = os.clock(),
	}

	return service
end

function ServiceLocator.resolve(name: string): any
	assertName(name)

	local record = records[name]

	if record == nil then
		error(string.format("Service '%s' is not registered", name), 2)
	end

	return record.service
end

function ServiceLocator.optional(name: string): any?
	assertName(name)

	local record = records[name]

	if record == nil then
		return nil
	end

	return record.service
end

function ServiceLocator.exists(name: string): boolean
	assertName(name)

	return records[name] ~= nil
end

function ServiceLocator.replace(name: string, service: any)
	assertName(name)
	assert(service ~= nil, "service cannot be nil")

	if frozen then
		error("ServiceLocator is frozen", 2)
	end

	local record = records[name]

	if record == nil then
		error(string.format("Service '%s' is not registered", name), 2)
	end

	record.service = service

	return service
end

function ServiceLocator.freeze()
	frozen = true
end

function ServiceLocator.isFrozen(): boolean
	return frozen
end

function ServiceLocator.getDependencyGraph()
	local graph = {}

	for name, record in pairs(records) do
		graph[name] = {
			dependencies = copyArray(record.dependencies),
			optionalDependencies = copyArray(record.optionalDependencies),
		}
	end

	return graph
end

function ServiceLocator.validate(): (boolean, string?)
	local visited = {}

	for name in pairs(records) do
		local ok, err = visit(name, {}, visited, {})

		if not ok then
			return false, err
		end
	end

	return true, nil
end

function ServiceLocator.inspect()
	local services = {}

	for name, record in pairs(records) do
		services[name] = {
			dependencies = copyArray(record.dependencies),
			optionalDependencies = copyArray(record.optionalDependencies),
			registeredAt = record.registeredAt,
		}
	end

	return {
		frozen = frozen,
		count = ServiceLocator.count(),
		services = services,
	}
end

function ServiceLocator.count(): number
	local count = 0

	for _ in pairs(records) do
		count += 1
	end

	return count
end

function ServiceLocator.clear()
	if frozen then
		error("ServiceLocator is frozen", 2)
	end

	table.clear(records)
end

ServiceLocator.Register = ServiceLocator.register
ServiceLocator.Resolve = ServiceLocator.resolve
ServiceLocator.Optional = ServiceLocator.optional
ServiceLocator.Exists = ServiceLocator.exists
ServiceLocator.Replace = ServiceLocator.replace
ServiceLocator.Freeze = ServiceLocator.freeze
ServiceLocator.Validate = ServiceLocator.validate
ServiceLocator.get = ServiceLocator.resolve
ServiceLocator.tryGet = ServiceLocator.optional
ServiceLocator.has = ServiceLocator.exists

return ServiceLocator
