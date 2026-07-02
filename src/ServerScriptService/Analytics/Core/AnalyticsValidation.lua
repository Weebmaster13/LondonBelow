--!strict
-- Validation boundary for server-owned Analytics Boundary schemas.

local Serialization = require(script.Parent.AnalyticsSerialization)
local Types = require(script.Parent.AnalyticsTypes)

local Validation = {}

local FORBIDDEN_FIELDS = {
	"admin",
	"adminExecution",
	"adminPower",
	"analytics",
	"analyticsCollection",
	"backdoor",
	"chapter",
	"chapter0",
	"chapter1",
	"client",
	"commandExecution",
	"cutscene",
	"dataStore",
	"datastore",
	"dataStoreRead",
	"dataStoreWrite",
	"dialogue",
	"execute",
	"externalAnalytics",
	"externalReporting",
	"exploit",
	"gameplayExecution",
	"http",
	"httpService",
	"marketplace",
	"messaging",
	"messagingService",
	"moderation",
	"moderationExecution",
	"playerTracking",
	"profilingExecution",
	"remote",
	"remoteConsole",
	"saveMutation",
	"story",
	"telemetry",
	"telemetrySending",
	"teleport",
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

local function forbidden(payload: any, depth: number): (boolean, string?)
	if type(payload) ~= "table" then
		return true, nil
	end
	if depth > Types.Limits.MaxPayloadDepth then
		return false, "Analytics Boundary payload depth exceeds limit"
	end
	for key in pairs(payload) do
		if type(key) == "string" and FORBIDDEN_LOOKUP[string.lower(key)] == true then
			return false, "Analytics Boundary payload contains forbidden field: " .. key
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

function Validation.event(schema: any): (boolean, string?)
	if type(schema) ~= "table" then
		return false, "analytics event schema must be a table"
	end
	local safe, reason = Validation.safePayload(schema)
	if not safe then
		return false, reason
	end
	if not validId(schema.eventId) or not validId(schema.ownerSystem) then
		return false, "analytics event identity fields are invalid"
	end
	if schema.schemaType ~= nil and schema.schemaType ~= Types.SchemaType.AnalyticsEventSchema then
		return false, "unsupported analytics event schema type"
	end
	return validateTags(schema.tags)
end

function Validation.metric(schema: any): (boolean, string?)
	if type(schema) ~= "table" then
		return false, "metric definition schema must be a table"
	end
	local safe, reason = Validation.safePayload(schema)
	if not safe then
		return false, reason
	end
	if not validId(schema.metricId) or not validId(schema.ownerSystem) then
		return false, "metric definition identity fields are invalid"
	end
	if schema.schemaType ~= nil and schema.schemaType ~= Types.SchemaType.AnalyticsMetricSchema then
		return false, "unsupported metric definition schema type"
	end
	return validateTags(schema.tags)
end

function Validation.aggregation(schema: any): (boolean, string?)
	if type(schema) ~= "table" then
		return false, "aggregation schema must be a table"
	end
	local safe, reason = Validation.safePayload(schema)
	if not safe then
		return false, reason
	end
	if not validId(schema.aggregationId) or not validId(schema.ownerSystem) then
		return false, "aggregation schema identity fields are invalid"
	end
	if
		schema.schemaType ~= nil
		and schema.schemaType ~= Types.SchemaType.AnalyticsAggregationSchema
	then
		return false, "unsupported aggregation schema type"
	end
	return validateTags(schema.tags)
end

function Validation.consent(schema: any): (boolean, string?)
	if type(schema) ~= "table" then
		return false, "consent schema must be a table"
	end
	local safe, reason = Validation.safePayload(schema)
	if not safe then
		return false, reason
	end
	if not validId(schema.consentId) or not validId(schema.ownerSystem) then
		return false, "consent schema identity fields are invalid"
	end
	if
		schema.schemaType ~= nil
		and schema.schemaType ~= Types.SchemaType.AnalyticsConsentSchema
	then
		return false, "unsupported consent schema type"
	end
	return validateTags(schema.tags)
end

function Validation.retention(schema: any): (boolean, string?)
	if type(schema) ~= "table" then
		return false, "malformed retention policy schema"
	end
	local safe, reason = Validation.safePayload(schema)
	if not safe then
		return false, reason
	end
	if not validId(schema.retentionId) or not validId(schema.ownerSystem) then
		return false, "malformed retention policy schema"
	end
	if
		schema.schemaType ~= nil
		and schema.schemaType ~= Types.SchemaType.AnalyticsRetentionSchema
	then
		return false, "unsupported retention policy schema type"
	end
	return validateTags(schema.tags)
end

function Validation.report(record: any): (boolean, string?)
	if type(record) ~= "table" then
		return false, "malformed report schema"
	end
	local safe, reason = Validation.safePayload(record)
	if not safe then
		return false, reason
	end
	if not validId(record.reportId) or not validId(record.ownerSystem) then
		return false, "malformed report schema"
	end
	if record.schemaType ~= nil and record.schemaType ~= Types.SchemaType.AnalyticsReportSchema then
		return false, "unsupported report schema type"
	end
	return validateTags(record.tags)
end

function Validation.validate(): (boolean, string?)
	if Types.Mode ~= "ServerAuthoritativeAnalyticsBoundarySchemaRuntime" then
		return false, "Analytics Boundary must remain server-authoritative schema runtime"
	end
	return true, nil
end

return Validation
