--!strict

local Evidence = require(script.Parent.DomainEvidence)
local Serialization = require(script.Parent.DomainSerialization)
local Types = require(script.Parent.DomainCapabilityTypes)
local Validation = require(script.Parent.DomainValidation)

local Registry = {}
local definitions: { [string]: any } = {}
local domainOwners: { [string]: string } = {}
local order = {}

function Registry.canRegister(definition: any)
	if #order >= Types.Limits.MaxDomainCapabilities then
		return {
			ok = false,
			code = Types.FailureType.LimitExceeded,
			message = "domain capability limit exceeded",
		}
	end
	local ok, reason = Validation.definition(definition)
	if not ok then
		return { ok = false, code = Types.FailureType.ValidationFailure, message = reason }
	end
	if definitions[definition.capabilityId] ~= nil then
		return {
			ok = false,
			code = Types.FailureType.DuplicateDomainCapability,
			message = "duplicate domain capability id",
		}
	end
	if domainOwners[definition.domain] ~= nil then
		return {
			ok = false,
			code = Types.FailureType.DuplicateDomain,
			message = "domain already owned",
		}
	end
	return { ok = true, code = "Ok" }
end

function Registry.register(definition: any)
	local canRegister = Registry.canRegister(definition)
	if not canRegister.ok then
		return canRegister
	end
	definitions[definition.capabilityId] = Validation.copy(definition)
	domainOwners[definition.domain] = definition.capabilityId
	table.insert(order, definition.capabilityId)
	table.sort(order)
	Evidence.record("domain capability registered", {
		capabilityId = definition.capabilityId,
		domain = definition.domain,
		version = definition.version,
	})
	return { ok = true, code = "Ok", capabilityId = definition.capabilityId }
end

function Registry.get(capabilityId: string): any?
	local definition = definitions[capabilityId]
	return if definition ~= nil then Serialization.deepCopy(definition) else nil
end

function Registry.inspect()
	local snapshot = {}
	for _, capabilityId in ipairs(order) do
		snapshot[capabilityId] = Serialization.deepCopy(definitions[capabilityId])
	end
	return snapshot
end

function Registry.count(): number
	return #order
end

function Registry.clear()
	table.clear(definitions)
	table.clear(domainOwners)
	table.clear(order)
end

return Registry
