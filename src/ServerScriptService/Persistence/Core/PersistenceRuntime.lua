--!strict

local Evidence = require(script.Parent.PersistenceEvidence)
local Provider = require(script.Parent.PersistenceProvider)
local Registry = require(script.Parent.PersistenceAdapterRegistry)
local RequestPipeline = require(script.Parent.PersistenceRequestPipeline)
local ResponsePipeline = require(script.Parent.PersistenceResponsePipeline)
local RetryRuntime = require(script.Parent.PersistenceRetryRuntime)
local Serialization = require(script.Parent.PersistenceSerialization)
local Types = require(script.Parent.PersistenceTypes)

local Runtime = {}

function Runtime.registerDefaultProviders(): (boolean, string?)
	local memoryOk, memoryReason = Registry.registerProvider(Provider.memory("memory"), true)
	if not memoryOk and memoryReason ~= "duplicate provider" then
		return false, memoryReason
	end
	local nullOk, nullReason = Registry.registerProvider(Provider.null("null"), false)
	if not nullOk and nullReason ~= "duplicate provider" then
		return false, nullReason
	end
	Registry.registerProvider(Provider.futureDataStore("futureDataStore"), false)
	Registry.registerProvider(Provider.futureProfileService("futureProfileService"), false)
	return true, nil
end

function Runtime.registerProvider(provider: any, makeDefault: boolean?)
	return Registry.registerProvider(provider, makeDefault)
end

function Runtime.unregisterProvider(providerId: string)
	return Registry.unregisterProvider(providerId)
end

function Runtime.resolveProvider(providerId: string?)
	return Registry.resolveProvider(providerId)
end

function Runtime.listProviders()
	return Registry.listProviders()
end

function Runtime.getDefaultProvider()
	return Registry.getDefaultProvider()
end

function Runtime.execute(requestRecord: any)
	return RequestPipeline.execute(requestRecord)
end

function Runtime.save(requestId: string, saveId: string, payload: any, providerId: string?)
	return Runtime.execute({
		requestId = requestId,
		operation = Types.Operation.Save,
		provider = providerId,
		saveId = saveId,
		payload = Serialization.deepCopy(payload),
		timestamp = 0,
		retryMode = Types.RetryMode.Immediate,
	})
end

function Runtime.load(requestId: string, saveId: string, providerId: string?)
	return Runtime.execute({
		requestId = requestId,
		operation = Types.Operation.Load,
		provider = providerId,
		saveId = saveId,
		timestamp = 0,
		retryMode = Types.RetryMode.Immediate,
	})
end

function Runtime.delete(requestId: string, saveId: string, providerId: string?)
	return Runtime.execute({
		requestId = requestId,
		operation = Types.Operation.Delete,
		provider = providerId,
		saveId = saveId,
		timestamp = 0,
		retryMode = Types.RetryMode.Immediate,
	})
end

function Runtime.exists(requestId: string, saveId: string, providerId: string?)
	return Runtime.execute({
		requestId = requestId,
		operation = Types.Operation.Exists,
		provider = providerId,
		saveId = saveId,
		timestamp = 0,
		retryMode = Types.RetryMode.Immediate,
	})
end

function Runtime.list(requestId: string, providerId: string?)
	return Runtime.execute({
		requestId = requestId,
		operation = Types.Operation.List,
		provider = providerId,
		saveId = "list",
		timestamp = 0,
		retryMode = Types.RetryMode.Immediate,
	})
end

function Runtime.inspect()
	return {
		registry = Registry.inspect(),
		requestPipeline = RequestPipeline.inspect(),
		responsePipeline = ResponsePipeline.inspect(),
		retryRuntime = RetryRuntime.inspect(),
		evidence = Evidence.inspect(),
	}
end

function Runtime.clear()
	Registry.clear()
	RequestPipeline.clear()
	ResponsePipeline.clear()
	RetryRuntime.clear()
	Evidence.clear()
end

return Runtime
