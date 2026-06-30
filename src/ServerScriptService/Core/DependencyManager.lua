--!strict
--[[
	DependencyManager validates required and optional system dependencies.

	It catches missing services, circular dependencies, and startup-order issues
	before the engine reports readiness.
]]

local Logger = require(script.Parent.Logger)

local DependencyManager = {}

export type DependencySpec = {
	name: string,
	requires: { string },
	optional: { string },
	initialized: boolean,
}

local log = Logger.scope("DependencyManager")
local specs: { [string]: DependencySpec } = {}

local function copy(values: { string }?): { string }
	local output = {}

	for _, value in ipairs(values or {}) do
		table.insert(output, value)
	end

	return output
end

local function visit(
	name: string,
	visiting: { [string]: boolean },
	visited: { [string]: boolean },
	path: { string }
): (boolean, string?)
	if visiting[name] then
		table.insert(path, name)
		return false, "Circular dependency: " .. table.concat(path, " -> ")
	end

	if visited[name] then
		return true, nil
	end

	local spec = specs[name]

	if spec == nil then
		return false, "Missing dependency spec for " .. name
	end

	visiting[name] = true
	table.insert(path, name)

	for _, requiredName in ipairs(spec.requires) do
		if specs[requiredName] == nil then
			return false, string.format("'%s' requires missing dependency '%s'", name, requiredName)
		end

		local ok, err = visit(requiredName, visiting, visited, path)

		if not ok then
			return false, err
		end
	end

	table.remove(path)
	visiting[name] = nil
	visited[name] = true

	return true, nil
end

function DependencyManager.register(name: string, requires: { string }?, optional: { string }?)
	assert(type(name) == "string" and name ~= "", "name must be a non-empty string")

	specs[name] = {
		name = name,
		requires = copy(requires),
		optional = copy(optional),
		initialized = false,
	}
end

function DependencyManager.markInitialized(name: string)
	local spec = specs[name]

	if spec == nil then
		error(string.format("Cannot mark unknown dependency '%s' initialized", name), 2)
	end

	spec.initialized = true
end

function DependencyManager.validate(): (boolean, string?)
	local visited = {}

	for name in pairs(specs) do
		local ok, err = visit(name, {}, visited, {})

		if not ok then
			return false, err
		end
	end

	for name, spec in pairs(specs) do
		for _, requiredName in ipairs(spec.requires) do
			local required = specs[requiredName]

			if required ~= nil and spec.initialized and not required.initialized then
				return false,
					string.format(
						"'%s' initialized before required dependency '%s'",
						name,
						requiredName
					)
			end
		end
	end

	return true, nil
end

function DependencyManager.generateStartupGraph(): { DependencySpec }
	local graph = {}
	local visited = {}

	local function add(name: string)
		if visited[name] then
			return
		end

		local spec = specs[name]

		if spec == nil then
			return
		end

		for _, requiredName in ipairs(spec.requires) do
			add(requiredName)
		end

		visited[name] = true
		table.insert(graph, {
			name = spec.name,
			requires = copy(spec.requires),
			optional = copy(spec.optional),
			initialized = spec.initialized,
		})
	end

	for name in pairs(specs) do
		add(name)
	end

	return graph
end

function DependencyManager.inspect()
	return {
		count = DependencyManager.count(),
		graph = DependencyManager.generateStartupGraph(),
	}
end

function DependencyManager.count(): number
	local count = 0

	for _ in pairs(specs) do
		count += 1
	end

	return count
end

function DependencyManager.clear()
	table.clear(specs)
end

function DependencyManager.logGraph()
	log.withContext("DEBUG", "Startup graph generated", {
		graph = DependencyManager.generateStartupGraph(),
	})
end

return DependencyManager
