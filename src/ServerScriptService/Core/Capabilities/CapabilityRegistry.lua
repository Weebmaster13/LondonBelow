--!strict

local Evidence = require(script.Parent.CapabilityEvidence)
local Serialization = require(script.Parent.CapabilitySerialization)
local Types = require(script.Parent.CapabilityTypes)
local Validation = require(script.Parent.CapabilityValidation)

local Registry = {}
local definitions: { [string]: any } = {}
local order = {}

function Registry.register(definition: any)
	if #order >= Types.Limits.MaxCapabilities then
		return {
			ok = false,
			code = Types.FailureType.LimitExceeded,
			message = "capability limit exceeded",
		}
	end
	local ok, reason = Validation.definition(definition)
	if not ok then
		return { ok = false, code = Types.FailureType.ValidationFailure, message = reason }
	end
	if definitions[definition.capabilityId] ~= nil then
		return {
			ok = false,
			code = Types.FailureType.DuplicateCapability,
			message = "duplicate capability id",
		}
	end
	definitions[definition.capabilityId] = Validation.copy(definition)
	table.insert(order, definition.capabilityId)
	table.sort(order)
	Evidence.record("capability registered", {
		capabilityId = definition.capabilityId,
		version = definition.version,
		category = definition.category,
	})
	return { ok = true, code = "Ok", capabilityId = definition.capabilityId }
end

function Registry.get(capabilityId: string): any?
	local definition = definitions[capabilityId]
	return if definition ~= nil then Serialization.deepCopy(definition) else nil
end

function Registry.has(capabilityId: string): boolean
	return definitions[capabilityId] ~= nil
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
	table.clear(order)
end

return Registry
