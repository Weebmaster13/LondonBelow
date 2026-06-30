--!strict

local DirectorCapabilities = {}

local capabilityMap: { [string]: any } = {}

local function copyCapabilities(values: { any }): { any }
	local copied = {}

	for _, capability in ipairs(values) do
		table.insert(copied, {
			id = capability.id,
			description = capability.description,
			requestKinds = table.clone(capability.requestKinds),
		})
	end

	return copied
end

function DirectorCapabilities.register(directorName: string, capabilities: { any })
	capabilityMap[directorName] = copyCapabilities(capabilities)
end

function DirectorCapabilities.get(directorName: string): { any }
	return copyCapabilities(capabilityMap[directorName] or {})
end

function DirectorCapabilities.inspect()
	local copied = {}

	for directorName, capabilities in pairs(capabilityMap) do
		copied[directorName] = copyCapabilities(capabilities)
	end

	return copied
end

function DirectorCapabilities.clear()
	table.clear(capabilityMap)
end

return DirectorCapabilities
