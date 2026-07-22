--!strict

local ConsumerRegistry = require(script.Parent.ConsumerRegistry)
local Evidence = require(script.Parent.MessagingEvidence)
local Serialization = require(script.Parent.MessagingSerialization)
local Types = require(script.Parent.MessagingTypes)

local Discovery = {}
local interfaces: { [string]: any } = {}

function Discovery.indexConsumer(consumerId: string)
	local consumer = ConsumerRegistry.get(consumerId)
	if consumer == nil then
		return { ok = false, code = Types.FailureType.UnknownConsumer, message = "unknown consumer" }
	end
	for _, interfaceId in ipairs(consumer.publicInterfaces) do
		interfaces[interfaceId] = {
			interfaceId = interfaceId,
			consumerId = consumer.consumerId,
			ownerRuntime = consumer.ownerRuntime,
			version = consumer.version,
		}
	end
	Evidence.record("consumer interfaces indexed", { consumerId = consumerId })
	return { ok = true, code = "Ok" }
end

function Discovery.resolve(interfaceId: string)
	local record = interfaces[interfaceId]
	if record == nil then
		return {
			ok = false,
			code = Types.FailureType.UnknownInterface,
			message = "unknown interface",
		}
	end
	return { ok = true, code = "Ok", interface = Serialization.deepCopy(record) }
end

function Discovery.inspect()
	return Serialization.deepCopy(interfaces)
end

function Discovery.clear()
	table.clear(interfaces)
end

return Discovery
