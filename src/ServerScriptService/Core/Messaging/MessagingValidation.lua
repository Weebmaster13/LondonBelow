--!strict

local Serialization = require(script.Parent.MessagingSerialization)
local Types = require(script.Parent.MessagingTypes)

local Validation = {}

local consumerFields = {
	authorityLevel = true,
	capabilities = true,
	consumerId = true,
	dependencies = true,
	lifecycle = true,
	ownerRuntime = true,
	publicInterfaces = true,
	requiredInterfaces = true,
	subscriptions = true,
	supportedCommands = true,
	supportedEvents = true,
	supportedQueries = true,
	version = true,
}

local subscriptionFields = {
	deliveryMode = true,
	eventType = true,
	priority = true,
	subscriptionId = true,
	consumerId = true,
	version = true,
}

local unsafeKeys = {
	analytics = true,
	clientAuthority = true,
	commandExecutor = true,
	clientauthority = true,
	commandexecutor = true,
	datastore = true,
	fireClient = true,
	fireServer = true,
	fireclient = true,
	fireserver = true,
	http = true,
	instance = true,
	messagingService = true,
	messagingservice = true,
	mutateWorkspace = true,
	mutateworkspace = true,
	remote = true,
	telemetry = true,
	workspace = true,
}

local function isId(value: any): boolean
	return type(value) == "string" and value:match("^[%w%.:%-_]+$") ~= nil and #value <= 128
end

local function boundedString(value: any): boolean
	return type(value) == "string" and #value > 0 and #value <= Types.Limits.MaxStringLength
end

local function isList(value: any): boolean
	if type(value) ~= "table" then
		return false
	end
	local count = 0
	for key in pairs(value) do
		if type(key) ~= "number" or key < 1 or key % 1 ~= 0 then
			return false
		end
		count += 1
	end
	return count == #value
end

local function validateStringList(value: any, limit: number): (boolean, string?)
	if not isList(value) or #value > limit then
		return false, "expected bounded string array"
	end
	local seen = {}
	for _, item in ipairs(value) do
		if not boundedString(item) or seen[item] then
			return false, "invalid or duplicate string"
		end
		seen[item] = true
	end
	return true, nil
end

local function supported(map: { [string]: string }, value: any): boolean
	for _, item in pairs(map) do
		if value == item then
			return true
		end
	end
	return false
end

local function scanUnsafe(value: any, depth: number, nodes: { count: number }): (boolean, string?)
	if depth > Types.Limits.MaxPayloadDepth then
		return false, "payload depth exceeded"
	end
	if type(value) ~= "table" then
		if type(value) == "function" or type(value) == "thread" or type(value) == "userdata" then
			return false, "unsafe value type"
		end
		if type(value) == "string" and #value > Types.Limits.MaxStringLength then
			return false, "string length exceeded"
		end
		return true, nil
	end
	nodes.count += 1
	if nodes.count > Types.Limits.MaxPayloadNodes then
		return false, "payload node limit exceeded"
	end
	for key, item in pairs(value) do
		if type(key) == "string" and unsafeKeys[string.lower(key)] then
			return false, "unsafe payload key"
		end
		local ok, reason = scanUnsafe(item, depth + 1, nodes)
		if not ok then
			return false, reason
		end
	end
	return true, nil
end

function Validation.consumerContract(contract: any): (boolean, string?)
	if type(contract) ~= "table" then
		return false, "consumer contract must be a table"
	end
	for key in pairs(contract) do
		if not consumerFields[key] then
			return false, "unknown consumer contract field: " .. tostring(key)
		end
	end
	for key in pairs(consumerFields) do
		if contract[key] == nil then
			return false, "missing consumer contract field: " .. key
		end
	end
	if not isId(contract.consumerId) or not isId(contract.ownerRuntime) then
		return false, "invalid consumer or owner id"
	end
	if not boundedString(contract.version) then
		return false, "invalid version"
	end
	if not supported(Types.AuthorityLevel, contract.authorityLevel) then
		return false, Types.FailureType.UnsupportedAuthority
	end
	for _, field in ipairs({
		"capabilities",
		"dependencies",
		"publicInterfaces",
		"requiredInterfaces",
		"subscriptions",
		"supportedCommands",
		"supportedEvents",
		"supportedQueries",
		"lifecycle",
	}) do
		local ok, reason =
			validateStringList(contract[field], Types.Limits.MaxInterfacesPerConsumer)
		if not ok then
			return false, field .. ": " .. tostring(reason)
		end
	end
	if #contract.dependencies > Types.Limits.MaxDependenciesPerConsumer then
		return false, "dependency limit exceeded"
	end
	return scanUnsafe(contract, 0, { count = 0 })
end

function Validation.subscription(subscription: any): (boolean, string?)
	if type(subscription) ~= "table" then
		return false, "subscription must be a table"
	end
	for key in pairs(subscription) do
		if not subscriptionFields[key] then
			return false, "unknown subscription field: " .. tostring(key)
		end
	end
	for key in pairs(subscriptionFields) do
		if subscription[key] == nil then
			return false, "missing subscription field: " .. key
		end
	end
	if not isId(subscription.subscriptionId) or not isId(subscription.consumerId) then
		return false, "invalid subscription id"
	end
	if not boundedString(subscription.eventType) or not boundedString(subscription.version) then
		return false, "invalid subscription strings"
	end
	if type(subscription.priority) ~= "number" or subscription.priority % 1 ~= 0 then
		return false, "invalid subscription priority"
	end
	if not supported(Types.SubscriptionDeliveryMode, subscription.deliveryMode) then
		return false, Types.FailureType.UnsupportedDeliveryMode
	end
	return scanUnsafe(subscription, 0, { count = 0 })
end

function Validation.copy(contract: any): any
	return Serialization.freezeCopy(contract)
end

return Validation
