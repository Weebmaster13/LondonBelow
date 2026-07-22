--!strict

local Serialization = require(script.Parent.PersistenceSerialization)
local Types = require(script.Parent.PersistenceTypes)

local Provider = {}

local function response(success: boolean, providerId: string, result: any?, failureReason: string?)
	return {
		success = success,
		provider = providerId,
		duration = 0,
		result = Serialization.deepCopy(result),
		failureReason = failureReason,
	}
end

local function keys(store: { [string]: any })
	local ids = {}
	for id in pairs(store) do
		table.insert(ids, id)
	end
	table.sort(ids)
	return ids
end

function Provider.memory(providerId: string?)
	local id = providerId or "memory"
	local store: { [string]: any } = {}
	return {
		providerId = id,
		providerKind = Types.ProviderKind.MemoryProvider,
		supportedOperations = {
			[Types.Operation.Save] = true,
			[Types.Operation.Load] = true,
			[Types.Operation.Delete] = true,
			[Types.Operation.Exists] = true,
			[Types.Operation.List] = true,
		},
		execute = function(request: any)
			if request.operation == Types.Operation.Save then
				store[request.saveId] = Serialization.deepCopy(request.payload)
				return response(true, id, { saveId = request.saveId }, nil)
			elseif request.operation == Types.Operation.Load then
				local stored = store[request.saveId]
				if stored == nil then
					return response(false, id, nil, "StorageFailure")
				end
				return response(true, id, stored, nil)
			elseif request.operation == Types.Operation.Delete then
				store[request.saveId] = nil
				return response(true, id, { saveId = request.saveId }, nil)
			elseif request.operation == Types.Operation.Exists then
				return response(true, id, { exists = store[request.saveId] ~= nil }, nil)
			elseif request.operation == Types.Operation.List then
				return response(true, id, { saveIds = keys(store) }, nil)
			end
			return response(false, id, nil, "UnsupportedOperation")
		end,
		inspect = function()
			return { storedRecords = #keys(store) }
		end,
		clear = function()
			table.clear(store)
		end,
	}
end

function Provider.null(providerId: string?)
	local id = providerId or "null"
	return {
		providerId = id,
		providerKind = Types.ProviderKind.NullProvider,
		supportedOperations = {},
		execute = function()
			return response(false, id, nil, "NotSupported")
		end,
		inspect = function()
			return { storedRecords = 0 }
		end,
		clear = function() end,
	}
end

function Provider.futureDataStore(providerId: string?)
	return {
		providerId = providerId or "futureDataStore",
		providerKind = Types.ProviderKind.FutureDataStoreProvider,
		supportedOperations = {},
		execute = function()
			return response(false, providerId or "futureDataStore", nil, "NotSupported")
		end,
		inspect = function()
			return { interfaceOnly = true, noDataStoreImplementation = true }
		end,
		clear = function() end,
	}
end

function Provider.futureProfileService(providerId: string?)
	return {
		providerId = providerId or "futureProfileService",
		providerKind = Types.ProviderKind.FutureProfileServiceProvider,
		supportedOperations = {},
		execute = function()
			return response(false, providerId or "futureProfileService", nil, "NotSupported")
		end,
		inspect = function()
			return { interfaceOnly = true, noProfileServiceImplementation = true }
		end,
		clear = function() end,
	}
end

return Provider
