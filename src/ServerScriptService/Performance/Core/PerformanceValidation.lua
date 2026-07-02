--!strict
-- Validation boundary for server-owned Performance Budget Runtime schemas.

local Serialization = require(script.Parent.PerformanceSerialization)
local Types = require(script.Parent.PerformanceTypes)

local Validation = {}

local FORBIDDEN_FIELDS = {
	"analytics",
	"analyticsCollection",
	"automaticThrottling",
	"chapter",
	"chapter0",
	"chapter1",
	"client",
	"clientMonitoring",
	"cutscene",
	"dialogue",
	"execute",
	"gameplayExecution",
	"liveProfiling",
	"memoryMutation",
	"networkMutation",
	"optimizationExecution",
	"profileExecution",
	"profilingExecution",
	"remote",
	"renderMutation",
	"story",
	"telemetry",
	"telemetrySending",
	"throttleExecution",
	"throttlingExecution",
	"throttlingAdapter",
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
		return false, "Performance Budget Runtime payload depth exceeds limit"
	end
	for key in pairs(payload) do
		if type(key) == "string" and FORBIDDEN_LOOKUP[string.lower(key)] == true then
			return false, "Performance Budget Runtime payload contains forbidden field: " .. key
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

function Validation.budget(schema: any): (boolean, string?)
	if type(schema) ~= "table" then
		return false, "performance budget schema must be a table"
	end
	local safe, reason = Validation.safePayload(schema)
	if not safe then
		return false, reason
	end
	if not validId(schema.budgetId) or not validId(schema.ownerSystem) then
		return false, "performance budget identity fields are invalid"
	end
	if
		schema.schemaType ~= nil
		and schema.schemaType ~= Types.SchemaType.PerformanceBudgetSchema
	then
		return false, "unsupported performance budget schema type"
	end
	return validateTags(schema.tags)
end

function Validation.category(schema: any): (boolean, string?)
	if type(schema) ~= "table" then
		return false, "performance category schema must be a table"
	end
	local safe, reason = Validation.safePayload(schema)
	if not safe then
		return false, reason
	end
	if not validId(schema.categoryId) or not validId(schema.ownerSystem) then
		return false, "performance category identity fields are invalid"
	end
	if
		schema.schemaType ~= nil
		and schema.schemaType ~= Types.SchemaType.PerformanceCategorySchema
	then
		return false, "unsupported performance category schema type"
	end
	return validateTags(schema.tags)
end

function Validation.threshold(schema: any): (boolean, string?)
	if type(schema) ~= "table" then
		return false, "performance threshold schema must be a table"
	end
	local safe, reason = Validation.safePayload(schema)
	if not safe then
		return false, reason
	end
	if not validId(schema.thresholdId) or not validId(schema.ownerSystem) then
		return false, "performance threshold identity fields are invalid"
	end
	if
		schema.schemaType ~= nil
		and schema.schemaType ~= Types.SchemaType.PerformanceThresholdSchema
	then
		return false, "unsupported performance threshold schema type"
	end
	return validateTags(schema.tags)
end

function Validation.report(record: any): (boolean, string?)
	if type(record) ~= "table" then
		return false, "performance report schema must be a table"
	end
	local safe, reason = Validation.safePayload(record)
	if not safe then
		return false, reason
	end
	if not validId(record.reportId) or not validId(record.ownerSystem) then
		return false, "performance report identity fields are invalid"
	end
	if
		record.schemaType ~= nil
		and record.schemaType ~= Types.SchemaType.PerformanceReportSchema
	then
		return false, "unsupported performance report schema type"
	end
	return validateTags(record.tags)
end

function Validation.validate(): (boolean, string?)
	if Types.Mode ~= "ServerAuthoritativePerformanceBudgetSchemaRuntime" then
		return false, "Performance Budget Runtime must remain server-authoritative schema runtime"
	end
	return true, nil
end

return Validation
