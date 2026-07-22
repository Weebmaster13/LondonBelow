--!strict

local Evidence = require(script.Parent.QueryEvidence)
local Serialization = require(script.Parent.QuerySerialization)
local Types = require(script.Parent.QueryTypes)
local Validation = require(script.Parent.QueryValidation)

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
	Evidence.record("query requester registered", { requesterId = requester.requesterId })
	return { ok = true, code = "Ok" }
end

function Registry.has(requesterId: string): boolean
	return requesters[requesterId] ~= nil
end

function Registry.canRequest(requesterId: string, queryType: string): boolean
	local requester = requesters[requesterId]
	if requester == nil then
		return false
	end
	for _, allowed in ipairs(requester.allowedQueryTypes) do
		if allowed == "*" or allowed == queryType then
			return true
		end
	end
	return false
end

function Registry.inspect()
	return Serialization.deepCopy(requesters)
end

function Registry.clear()
	table.clear(requesters)
end

return Registry
