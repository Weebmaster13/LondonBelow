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

local function supportedOperation(value: any): boolean
	for _, operation in pairs(Types.Operation) do
		if value == operation then
			return true
		end
	end
	return false
end

local function supportedProviderKind(value: any): boolean
	for _, providerKind in pairs(Types.ProviderKind) do
		if value == providerKind then
			return true
		end
	end
	return false
end

local function supportedRetryMode(value: any): boolean
	for _, retryMode in pairs(Types.RetryMode) do
		if value == retryMode then
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

function Validation.operation(value: any): boolean
	return supportedOperation(value)
end

function Validation.providerKind(value: any): boolean
	return supportedProviderKind(value)
end

function Validation.retryMode(value: any): boolean
	return supportedRetryMode(value)
end

function Validation.provider(provider: any): (boolean, string?)
	if type(provider) ~= "table" then
		return false, "provider must be a table"
	end
	if not validId(provider.providerId) then
		return false, "provider id is invalid"
	end
	if not supportedProviderKind(provider.providerKind) then
		return false, "provider kind is unsupported"
	end
	if type(provider.supportedOperations) ~= "table" then
		return false, "supported operations must be a table"
	end
	if type(provider.execute) ~= "function" then
		return false, "provider execute function is missing"
	end
	return true, nil
end

function Validation.runtimeRequest(requestRecord: any): (boolean, string?)
	if type(requestRecord) ~= "table" then
		return false, "persistence request must be a table"
	end
	local safe, reason = Validation.safePayload(requestRecord)
	if not safe then
		return false, reason
	end
	if not validId(requestRecord.requestId) then
		return false, "request id is invalid"
	end
	if not supportedOperation(requestRecord.operation) then
		return false, "unsupported operation"
	end
	if requestRecord.provider ~= nil and not validId(requestRecord.provider) then
		return false, "provider id is invalid"
	end
	if requestRecord.operation ~= Types.Operation.List and not validId(requestRecord.saveId) then
		return false, "save id is invalid"
	end
	if requestRecord.timestamp ~= nil and type(requestRecord.timestamp) ~= "number" then
		return false, "timestamp must be a number"
	end
	if requestRecord.retryMode ~= nil and not supportedRetryMode(requestRecord.retryMode) then
		return false, "unsupported retry mode"
	end
	if requestRecord.maxAttempts ~= nil then
		if
			type(requestRecord.maxAttempts) ~= "number"
			or requestRecord.maxAttempts < 1
			or requestRecord.maxAttempts > Types.Limits.MaxRetryAttempts
		then
			return false, "retry attempt limit is invalid"
		end
	end
	if requestRecord.operation == Types.Operation.Save and requestRecord.payload == nil then
		return false, "save payload is required"
	end
	return true, nil
end

function Validation.runtimeResponse(responseRecord: any): (boolean, string?)
	if type(responseRecord) ~= "table" then
		return false, "persistence response must be a table"
	end
	local safe, reason = Validation.safePayload(responseRecord)
	if not safe then
		return false, reason
	end
	if type(responseRecord.success) ~= "boolean" then
		return false, "response success must be a boolean"
	end
	if not validId(responseRecord.provider) then
		return false, "response provider is invalid"
	end
	if type(responseRecord.duration) ~= "number" or responseRecord.duration < 0 then
		return false, "response duration is invalid"
	end
	if not responseRecord.success and type(responseRecord.failureReason) ~= "string" then
		return false, "failed response requires failure reason"
	end
	return true, nil
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
	if schema.packageType ~= "Save" and schema.packageType ~= "Load" then
		return false, "unsupported persistence package type"
	end
	if schema.schemaType ~= nil and not supportedSchemaType(schema.schemaType) then
		return false, "unsupported persistence package schema type"
	end
	if schema.packageType == "Save" and schema.schemaType ~= Types.SchemaType.SavePackageSchema then
		return false, "malformed save package schema"
	end
	if schema.packageType == "Load" and schema.schemaType ~= Types.SchemaType.LoadPackageSchema then
		return false, "malformed load package schema"
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
	if schema.schemaType ~= nil and schema.schemaType ~= Types.SchemaType.MigrationSchema then
		return false, "unsupported migration schema type"
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
	if schema.schemaType ~= nil and schema.schemaType ~= Types.SchemaType.WritePolicySchema then
		return false, "unsupported write policy schema type"
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
	if schema.schemaType ~= nil and schema.schemaType ~= Types.SchemaType.RetryPolicySchema then
		return false, "unsupported retry policy schema type"
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
	if record.schemaType ~= nil and record.schemaType ~= Types.SchemaType.FailureRecordSchema then
		return false, "unsupported failure record schema type"
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
