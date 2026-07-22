--!strict

local Evidence = require(script.Parent.MessagingEvidence)
local Serialization = require(script.Parent.MessagingSerialization)
local Types = require(script.Parent.MessagingTypes)
local Validation = require(script.Parent.MessagingValidation)

local Registry = {}
local consumers: { [string]: any } = {}
local order = {}

function Registry.register(contract: any)
	if #order >= Types.Limits.MaxConsumers then
		return {
			ok = false,
			code = Types.FailureType.ValidationFailure,
			message = "consumer limit exceeded",
		}
	end
	local ok, reason = Validation.consumerContract(contract)
	if not ok then
		return { ok = false, code = Types.FailureType.ValidationFailure, message = reason }
	end
	if consumers[contract.consumerId] ~= nil then
		return {
			ok = false,
			code = Types.FailureType.DuplicateConsumer,
			message = "duplicate consumer",
		}
	end
	local stored = Validation.copy(contract)
	consumers[contract.consumerId] = stored
	table.insert(order, contract.consumerId)
	table.sort(order)
	Evidence.record("consumer registered", { consumerId = contract.consumerId })
	return { ok = true, code = "Ok", consumerId = contract.consumerId }
end

function Registry.has(consumerId: string): boolean
	return consumers[consumerId] ~= nil
end

function Registry.get(consumerId: string): any?
	local consumer = consumers[consumerId]
	return if consumer ~= nil then Serialization.deepCopy(consumer) else nil
end

function Registry.inspect()
	local result = {}
	for _, consumerId in ipairs(order) do
		result[consumerId] = Serialization.deepCopy(consumers[consumerId])
	end
	return result
end

function Registry.ids(): { string }
	return Serialization.copyArray(order)
end

function Registry.count(): number
	return #order
end

function Registry.clear()
	table.clear(consumers)
	table.clear(order)
end

return Registry
