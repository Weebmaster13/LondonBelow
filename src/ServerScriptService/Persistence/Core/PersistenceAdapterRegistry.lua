--!strict

local Evidence = require(script.Parent.PersistenceEvidence)
local Serialization = require(script.Parent.PersistenceSerialization)
local Types = require(script.Parent.PersistenceTypes)
local Validation = require(script.Parent.PersistenceValidation)

local Registry = {}

local providers: { [string]: any } = {}
local defaultProvider: string? = nil

local function countProviders(): number
	local count = 0
	for _ in pairs(providers) do
		count += 1
	end
	return count
end

function Registry.registerProvider(provider: any, makeDefault: boolean?): (boolean, string?)
	local ok, reason = Validation.provider(provider)
	if not ok then
		return false, reason
	end
	if providers[provider.providerId] ~= nil then
		return false, "duplicate provider"
	end
	if countProviders() >= Types.Limits.MaxProviders then
		return false, "provider limit exceeded"
	end
	providers[provider.providerId] = provider
	if makeDefault == true or defaultProvider == nil then
		defaultProvider = provider.providerId
	end
	Evidence.record("providerRegistration", {
		provider = provider.providerId,
		providerKind = provider.providerKind,
	})
	return true, nil
end

function Registry.unregisterProvider(providerId: string): (boolean, string?)
	if not Validation.id(providerId) then
		return false, "provider id is invalid"
	end
	local provider = providers[providerId]
	if provider == nil then
		return false, "missing provider"
	end
	if type(provider.clear) == "function" then
		provider.clear()
	end
	providers[providerId] = nil
	if defaultProvider == providerId then
		defaultProvider = nil
	end
	Evidence.record("providerUnregistered", { provider = providerId })
	return true, nil
end

function Registry.resolveProvider(providerId: string?)
	local id = providerId or defaultProvider
	if id == nil then
		return nil, "missing provider"
	end
	local provider = providers[id]
	if provider == nil then
		return nil, "missing provider"
	end
	Evidence.record("providerResolution", { provider = id })
	return provider, nil
end

function Registry.listProviders()
	local ids = {}
	for id in pairs(providers) do
		table.insert(ids, id)
	end
	table.sort(ids)
	return ids
end

function Registry.getDefaultProvider()
	return defaultProvider
end

function Registry.inspect()
	local providerSummaries = {}
	for _, providerId in ipairs(Registry.listProviders()) do
		local provider = providers[providerId]
		providerSummaries[providerId] = {
			providerId = provider.providerId,
			providerKind = provider.providerKind,
			supportedOperations = Serialization.deepCopy(provider.supportedOperations or {}),
			details = type(provider.inspect) == "function" and provider.inspect() or nil,
		}
	end
	return {
		registeredProviders = Registry.listProviders(),
		defaultProvider = defaultProvider,
		providers = providerSummaries,
		count = countProviders(),
	}
end

function Registry.clear()
	for _, provider in pairs(providers) do
		if type(provider.clear) == "function" then
			provider.clear()
		end
	end
	table.clear(providers)
	defaultProvider = nil
end

return Registry
