local ServiceLocator = {}

local services = {}

function ServiceLocator.register(name, service)
	assert(type(name) == "string", "name must be a string")
	assert(service ~= nil, "service cannot be nil")

	if services[name] ~= nil then
		error(string.format("Service '%s' is already registered", name), 2)
	end

	services[name] = service

	return service
end

function ServiceLocator.get(name)
	assert(type(name) == "string", "name must be a string")

	local service = services[name]

	if service == nil then
		error(string.format("Service '%s' is not registered", name), 2)
	end

	return service
end

function ServiceLocator.tryGet(name)
	assert(type(name) == "string", "name must be a string")

	return services[name]
end

function ServiceLocator.has(name)
	assert(type(name) == "string", "name must be a string")

	return services[name] ~= nil
end

function ServiceLocator.clear()
	table.clear(services)
end

return ServiceLocator
