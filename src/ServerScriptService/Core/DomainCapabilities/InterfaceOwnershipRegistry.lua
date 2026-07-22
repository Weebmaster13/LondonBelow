--!strict

local Evidence = require(script.Parent.DomainEvidence)
local Registry = require(script.Parent.DomainIdentityRegistry)
local Serialization = require(script.Parent.DomainSerialization)

local InterfaceOwnership = {}
local owners: { [string]: any } = {}

function InterfaceOwnership.registerCapabilityInterfaces(capabilityId: string)
	local definition = Registry.get(capabilityId)
	if definition == nil then
		return {
			ok = false,
			code = "UnknownDomainCapability",
			message = "unknown domain capability",
		}
	end
	for _, interfaceRecord in ipairs(definition.interfaces) do
		if owners[interfaceRecord.interfaceId] ~= nil then
			return { ok = false, code = "DuplicateInterface", message = "interface already owned" }
		end
	end
	for _, interfaceRecord in ipairs(definition.interfaces) do
		owners[interfaceRecord.interfaceId] = {
			capabilityId = capabilityId,
			domain = definition.domain,
			version = interfaceRecord.version,
			methods = Serialization.copyArray(interfaceRecord.methods),
		}
	end
	Evidence.record("domain interfaces registered", {
		capabilityId = capabilityId,
		interfaceCount = #definition.interfaces,
	})
	return { ok = true, code = "Ok", capabilityId = capabilityId }
end

function InterfaceOwnership.inspect()
	return Serialization.deepCopy(owners)
end

function InterfaceOwnership.clear()
	table.clear(owners)
end

return InterfaceOwnership
