--!strict

local Evidence = require(script.Parent.PresentationEvidence)
local Metrics = require(script.Parent.PresentationMetrics)
local Serialization = require(script.Parent.PresentationSerialization)
local Types = require(script.Parent.PresentationTypes)

local Registry = {}
local consumers = {}
local order = {}
local nextOrdinal = 0

function Registry.register(consumer: any)
	if #order >= Types.Limits.MaxRuntimeConsumers then
		return {
			ok = false,
			code = Types.RuntimeFailureType.LimitExceeded,
			message = "consumer limit exceeded",
		}
	end
	if type(consumer) ~= "table" then
		return {
			ok = false,
			code = Types.RuntimeFailureType.InvalidConsumer,
			message = "consumer must be a table",
		}
	end
	for _, field in ipairs({ "consumerId", "runtimeCapability", "contractVersion", "status" }) do
		if type(consumer[field]) ~= "string" or consumer[field] == "" then
			return {
				ok = false,
				code = Types.RuntimeFailureType.InvalidConsumer,
				message = "invalid field " .. field,
			}
		end
	end
	if consumers[consumer.consumerId] ~= nil then
		return {
			ok = false,
			code = Types.RuntimeFailureType.DuplicateConsumer,
			message = "duplicate consumer",
		}
	end
	nextOrdinal += 1
	local stored = Serialization.deepCopy(consumer)
	stored.registrationOrdinal = nextOrdinal
	consumers[stored.consumerId] = stored
	order[#order + 1] = stored.consumerId
	Metrics.increment("consumerRegistrations")
	Evidence.record(
		"PresentationConsumerRegistered",
		{ consumerId = stored.consumerId },
		Types.Limits.MaxEvidence
	)
	return { ok = true, code = "Ok", consumer = Serialization.deepCopy(stored) }
end

function Registry.get(consumerId: string)
	local consumer = consumers[consumerId]
	return if consumer then Serialization.deepCopy(consumer) else nil
end

function Registry.inspect()
	local result = {}
	for index, consumerId in ipairs(order) do
		result[index] = Serialization.deepCopy(consumers[consumerId])
	end
	return result
end

function Registry.clear()
	table.clear(consumers)
	table.clear(order)
	nextOrdinal = 0
end

return Registry
