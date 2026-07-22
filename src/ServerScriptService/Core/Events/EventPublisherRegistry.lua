--!strict

local Evidence = require(script.Parent.EventEvidence)
local Serialization = require(script.Parent.EventSerialization)
local Types = require(script.Parent.EventTypes)
local Validation = require(script.Parent.EventValidation)

local Registry = {}
local publishers: { [string]: any } = {}

function Registry.register(publisher: any)
	if #Serialization.sortedKeys(publishers) >= Types.Limits.MaxPublishers then
		return { ok = false, code = "LimitExceeded", message = "publisher limit reached" }
	end
	local ok, code, reason = Validation.publisher(publisher)
	if not ok then
		return { ok = false, code = code, message = reason }
	end
	if publishers[publisher.publisherId] ~= nil then
		return { ok = false, code = "DuplicatePublisher", message = "duplicate publisher" }
	end
	publishers[publisher.publisherId] = Serialization.deepCopy(publisher)
	Evidence.record("publisher registered", { publisherId = publisher.publisherId })
	return { ok = true, code = "Ok", publisher = Serialization.deepCopy(publisher) }
end

function Registry.unregister(publisherId: string)
	if publishers[publisherId] == nil then
		return { ok = false, code = "UnknownPublisher", message = "unknown publisher" }
	end
	publishers[publisherId] = nil
	return { ok = true, code = "Ok" }
end

function Registry.resolve(publisherId: string): any?
	local publisher = publishers[publisherId]
	return if publisher == nil then nil else Serialization.deepCopy(publisher)
end

function Registry.has(publisherId: string): boolean
	return publishers[publisherId] ~= nil
end

function Registry.canPublish(publisherId: string, eventType: string): boolean
	local publisher = publishers[publisherId]
	if publisher == nil then
		return false
	end
	for _, allowed in ipairs(publisher.allowedEventTypes) do
		if allowed == "*" or allowed == eventType then
			return true
		end
	end
	return false
end

function Registry.inspect()
	local output = {}
	for _, publisherId in ipairs(Serialization.sortedKeys(publishers)) do
		output[publisherId] = Serialization.deepCopy(publishers[publisherId])
	end
	return table.freeze(output)
end

function Registry.clear()
	table.clear(publishers)
end

return Registry
