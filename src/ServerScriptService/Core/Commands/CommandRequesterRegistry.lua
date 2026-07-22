--!strict

local Evidence = require(script.Parent.CommandEvidence)
local Serialization = require(script.Parent.CommandSerialization)
local Types = require(script.Parent.CommandTypes)
local Validation = require(script.Parent.CommandValidation)

local Registry = {}
local requesters: { [string]: any } = {}

function Registry.register(requester: any)
	if #Serialization.sortedKeys(requesters) >= Types.Limits.MaxRequesters then
		return { ok = false, code = "LimitExceeded", message = "requester limit reached" }
	end
	local ok, code, reason = Validation.requester(requester)
	if not ok then
		return { ok = false, code = code, message = reason }
	end
	if requesters[requester.requesterId] ~= nil then
		return { ok = false, code = "DuplicateRequester", message = "duplicate requester" }
	end
	requesters[requester.requesterId] = Serialization.deepCopy(requester)
	Evidence.record("requester registered", { requesterId = requester.requesterId })
	return { ok = true, code = "Ok", requester = Serialization.deepCopy(requester) }
end

function Registry.has(requesterId: string): boolean
	return requesters[requesterId] ~= nil
end

function Registry.canRequest(requesterId: string, commandType: string): boolean
	local requester = requesters[requesterId]
	if requester == nil then
		return false
	end
	for _, allowed in ipairs(requester.allowedCommandTypes) do
		if allowed == "*" or allowed == commandType then
			return true
		end
	end
	return false
end

function Registry.inspect()
	local output = {}
	for _, requesterId in ipairs(Serialization.sortedKeys(requesters)) do
		output[requesterId] = Serialization.deepCopy(requesters[requesterId])
	end
	return table.freeze(output)
end

function Registry.clear()
	table.clear(requesters)
end

return Registry
