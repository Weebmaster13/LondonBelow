--!strict
-- Validation boundary for server-owned Security / Anti-Exploit policy schemas.

local Serialization = require(script.Parent.SecuritySerialization)
local Types = require(script.Parent.SecurityTypes)

local Validation = {}

local FORBIDDEN_FIELDS = {
	"analytics",
	"analyticsCollection",
	"antiCheatExecution",
	"adapterReference",
	"ban",
	"banEnforcement",
	"chapter",
	"chapter0",
	"chapter1",
	"clientAuthority",
	"clientMonitoring",
	"cutscene",
	"dataStore",
	"dataStoreRead",
	"dataStoreWrite",
	"detectExploit",
	"detectionExecution",
	"dialogue",
	"execute",
	"exploitDetectionExecution",
	"fireAllClients",
	"fireClient",
	"gameplayExecution",
	"handlerReference",
	"http",
	"invokeClient",
	"kick",
	"kickEnforcement",
	"liveAntiCheat",
	"messaging",
	"moderation",
	"playerTracking",
	"punishment",
	"remote",
	"remoteCreation",
	"remoteEvent",
	"remoteFunction",
	"serviceReference",
	"story",
	"telemetry",
	"telemetrySending",
	"tracking",
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

local function forbidden(payload: any, depth: number): (boolean, string?)
	if type(payload) ~= "table" then
		return true, nil
	end
	if depth > Types.Limits.MaxPayloadDepth then
		return false, "Security Boundary payload depth exceeds limit"
	end
	for key in pairs(payload) do
		if type(key) == "string" and FORBIDDEN_LOOKUP[string.lower(key)] == true then
			return false, "Security Boundary payload contains forbidden field: " .. key
		end
	end
	for _, nested in pairs(payload) do
		if type(nested) == "string" and FORBIDDEN_LOOKUP[string.lower(nested)] == true then
			return false, "Security Boundary payload contains forbidden value: " .. nested
		end
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

local function validateSchema(schema: any, idField: string, expectedType: string, label: string)
	if type(schema) ~= "table" then
		return false, label .. " schema must be a table"
	end
	local safe, reason = Validation.safePayload(schema)
	if not safe then
		return false, reason
	end
	if not validId(schema[idField]) or not validId(schema.ownerSystem) then
		return false, label .. " identity fields are invalid"
	end
	if schema.schemaType ~= nil and schema.schemaType ~= expectedType then
		return false, "unsupported " .. label .. " schema type"
	end
	return validateTags(schema.tags)
end

function Validation.trustPolicy(schema: any): (boolean, string?)
	return validateSchema(
		schema,
		"trustPolicyId",
		Types.SchemaType.SecurityTrustPolicySchema,
		"trust policy"
	)
end

function Validation.authorityRule(schema: any): (boolean, string?)
	return validateSchema(
		schema,
		"authorityRuleId",
		Types.SchemaType.SecurityAuthorityRuleSchema,
		"authority rule"
	)
end

function Validation.exploitSignal(schema: any): (boolean, string?)
	return validateSchema(
		schema,
		"exploitSignalId",
		Types.SchemaType.SecurityExploitSignalSchema,
		"exploit signal"
	)
end

function Validation.clientRejection(schema: any): (boolean, string?)
	return validateSchema(
		schema,
		"clientRejectionId",
		Types.SchemaType.SecurityClientRejectionSchema,
		"client rejection"
	)
end

function Validation.remoteSafety(schema: any): (boolean, string?)
	return validateSchema(
		schema,
		"remoteSafetyId",
		Types.SchemaType.SecurityRemoteSafetySchema,
		"remote safety"
	)
end

function Validation.rateLimit(schema: any): (boolean, string?)
	return validateSchema(
		schema,
		"rateLimitId",
		Types.SchemaType.SecurityRateLimitSchema,
		"rate limit"
	)
end

function Validation.audit(record: any): (boolean, string?)
	return validateSchema(record, "auditId", Types.SchemaType.SecurityAuditSchema, "audit")
end

function Validation.validate(): (boolean, string?)
	if Types.Mode ~= "ServerAuthoritativeSecurityPolicySchemaRuntime" then
		return false, "Security Boundary must remain server-authoritative schema runtime"
	end
	return true, nil
end

return Validation
