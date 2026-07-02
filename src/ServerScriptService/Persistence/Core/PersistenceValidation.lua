--!strict
-- Validation boundary for server-owned persistence boundary schemas.

local Serialization = require(script.Parent.PersistenceSerialization)
local Types = require(script.Parent.PersistenceTypes)

local Validation = {}

local FORBIDDEN_FIELDS = {
	"chapter",
	"chapter0",
	"chapter1",
	"client",
	"cloudSave",
	"cutscene",
	"datastore",
	"dataStoreExecution",
	"dataStoreRead",
	"dataStoreWrite",
	"dialogue",
	"execute",
	"gameplayExecution",
	"livePersistence",
	"migrationExecution",
	"profileLoading",
	"remote",
	"saveMutation",
	"story",
	"ui",
	"workspace",
}

local FORBIDDEN_LOOKUP: { [string]: boolean } = {}

for _, field in ipairs(FORBIDDEN_FIELDS) do
	FORBIDDEN_LOOKUP[string.lower(field)] = true
end

local function validId(value: any): boolean
	return type(value) == "string"
		and value ~= ""
		and #value <= 150
		and string.match(value, "^[%w%._%-:]+$") ~= nil
end

local function supportedSchemaType(value: any): boolean
	for _, schemaType in pairs(Types.SchemaType) do
		if value == schemaType then
			return true
		end
	end
	return false
end

local function forbidden(payload: any, depth: number): (boolean, string?)
	if type(payload) ~= "table" then
		return true, nil
	end
	if depth > Types.Limits.MaxPayloadDepth then
		return false, "persistence payload depth exceeds limit"
	end
	for key in pairs(payload) do
		if type(key) == "string" and FORBIDDEN_LOOKUP[string.lower(key)] == true then
			return false, "persistence payload contains forbidden field: " .. key
		end
	end
	for _, nested in pairs(payload) do
		local ok, reason = forbidden(nested, depth + 1)
		if not ok then
			return false, reason
		end
	end
	return true, nil
end

local function validateTags(tags: any): (boolean, string?)
	if tags == nil then
		return true, nil
	end
	if type(tags) ~= "table" then
		return false, "tags must be a table"
	end
	if #tags > Types.Limits.MaxTags then
		return false, "tag count exceeds limit"
	end
	for _, tag in ipairs(tags) do
		if not validId(tag) then
			return false, "tag is invalid"
		end
		if FORBIDDEN_LOOKUP[string.lower(tag)] == true then
			return false, "tag uses forbidden ownership domain: " .. tag
		end
	end
	return true, nil
end

function Validation.safePayload(payload: any): (boolean, string?)
	local ok, reason = Serialization.validateSerializable(payload)
	if not ok then
		return false, reason
	end
	return forbidden(payload, 0)
end

function Validation.id(value: any): boolean
	return validId(value)
end

function Validation.request(schema: any): (boolean, string?)
	if type(schema) ~= "table" then
		return false, "persistence request schema must be a table"
	end
	local safe, reason = Validation.safePayload(schema)
	if not safe then
		return false, reason
	end
	if
		not validId(schema.requestId)
		or not validId(schema.requestType)
		or not validId(schema.ownerSystem)
	then
		return false, "persistence request identity fields are invalid"
	end
	if schema.schemaType ~= nil and not supportedSchemaType(schema.schemaType) then
		return false, "unsupported persistence request schema type"
	end
	return validateTags(schema.tags)
end

function Validation.package(schema: any): (boolean, string?)
	if type(schema) ~= "table" then
		return false, "persistence package schema must be a table"
	end
	local safe, reason = Validation.safePayload(schema)
	if not safe then
		return false, reason
	end
	if
		not validId(schema.packageId)
		or not validId(schema.packageType)
		or not validId(schema.ownerSystem)
	then
		return false, "persistence package identity fields are invalid"
	end
	if schema.schemaType ~= nil and not supportedSchemaType(schema.schemaType) then
		return false, "unsupported persistence package schema type"
	end
	return validateTags(schema.tags)
end

function Validation.migration(schema: any): (boolean, string?)
	if type(schema) ~= "table" then
		return false, "malformed migration schema"
	end
	local safe, reason = Validation.safePayload(schema)
	if not safe then
		return false, reason
	end
	if not validId(schema.migrationId) or not validId(schema.ownerSystem) then
		return false, "malformed migration schema"
	end
	return validateTags(schema.tags)
end

function Validation.writePolicy(schema: any): (boolean, string?)
	if type(schema) ~= "table" then
		return false, "malformed write policy"
	end
	local safe, reason = Validation.safePayload(schema)
	if not safe then
		return false, reason
	end
	if not validId(schema.policyId) or not validId(schema.ownerSystem) then
		return false, "malformed write policy"
	end
	return validateTags(schema.tags)
end

function Validation.retryPolicy(schema: any): (boolean, string?)
	if type(schema) ~= "table" then
		return false, "malformed retry policy"
	end
	local safe, reason = Validation.safePayload(schema)
	if not safe then
		return false, reason
	end
	if not validId(schema.policyId) or not validId(schema.ownerSystem) then
		return false, "malformed retry policy"
	end
	return validateTags(schema.tags)
end

function Validation.failure(record: any): (boolean, string?)
	if type(record) ~= "table" then
		return false, "malformed failure record"
	end
	local safe, reason = Validation.safePayload(record)
	if not safe then
		return false, reason
	end
	if not validId(record.failureId) or not validId(record.ownerSystem) then
		return false, "malformed failure record"
	end
	return validateTags(record.tags)
end

function Validation.validate(): (boolean, string?)
	if Types.Mode ~= "ServerAuthoritativePersistenceBoundaryRuntime" then
		return false, "Persistence Boundary must remain server-authoritative schema runtime"
	end
	return true, nil
end

return Validation
