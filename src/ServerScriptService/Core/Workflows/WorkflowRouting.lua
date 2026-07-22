--!strict

local Correlation = require(script.Parent.WorkflowCorrelation)
local Serialization = require(script.Parent.WorkflowSerialization)
local Types = require(script.Parent.WorkflowTypes)

local Routing = {}
local routes = {}
local sequence = 0

local function supportedMessageKind(value: any): boolean
	for _, messageKind in pairs(Types.MessageKind) do
		if value == messageKind then
			return true
		end
	end
	return false
end

function Routing.route(message: any)
	if type(message) ~= "table" then
		return {
			ok = false,
			code = Types.FailureType.InvalidMessage,
			message = "message must be a table",
		}
	end
	if
		type(message.messageId) ~= "string"
		or type(message.correlationId) ~= "string"
		or type(message.instanceId) ~= "string"
		or not supportedMessageKind(message.messageKind)
	then
		return {
			ok = false,
			code = Types.FailureType.InvalidMessage,
			message = "invalid workflow message",
		}
	end
	local correlation = Correlation.get(message.correlationId)
	if correlation == nil then
		return {
			ok = false,
			code = Types.FailureType.MissingCorrelation,
			message = "missing workflow correlation",
		}
	end
	if correlation.instanceId ~= message.instanceId then
		return {
			ok = false,
			code = Types.FailureType.InvalidMessage,
			message = "message instance does not match correlation",
		}
	end
	sequence += 1
	local route = Serialization.deepCopy({
		sequence = sequence,
		messageId = message.messageId,
		messageKind = message.messageKind,
		correlationId = message.correlationId,
		causationId = message.causationId,
		instanceId = message.instanceId,
		sourceRuntime = message.sourceRuntime,
		targetRuntime = message.targetRuntime or Types.ProviderName,
		routedAt = os.clock(),
		payload = message.payload or {},
	})
	table.insert(routes, route)
	while #routes > Types.Limits.MaxRouteRecords do
		table.remove(routes, 1)
	end
	return { ok = true, code = "Ok", route = route }
end

function Routing.inspect()
	return Serialization.copyArray(routes)
end

function Routing.clear()
	table.clear(routes)
	sequence = 0
end

return Routing
