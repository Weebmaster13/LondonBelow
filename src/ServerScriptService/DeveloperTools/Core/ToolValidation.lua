--!strict
-- Validation boundary for server-owned developer tooling schemas.

local Serialization = require(script.Parent.ToolSerialization)
local Types = require(script.Parent.ToolTypes)

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
	"exploit",
	"gameplayExecution",
	"http",
	"marketplace",
	"moderation",
	"moderationExecution",
	"remote",
	"remoteConsole",
	"saveMutation",
	"story",
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
		return false, "developer tooling payload depth exceeds limit"
	end
	for key in pairs(payload) do
		if type(key) == "string" and FORBIDDEN_LOOKUP[string.lower(key)] == true then
			return false, "developer tooling payload contains forbidden field: " .. key
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

function Validation.tool(schema: any): (boolean, string?)
	if type(schema) ~= "table" then
		return false, "tool definition schema must be a table"
	end
	local safe, reason = Validation.safePayload(schema)
	if not safe then
		return false, reason
	end
	if not validId(schema.toolId) or not validId(schema.ownerSystem) then
		return false, "tool definition identity fields are invalid"
	end
	if schema.schemaType ~= nil and schema.schemaType ~= Types.SchemaType.ToolDefinitionSchema then
		return false, "unsupported tool definition schema type"
	end
	return validateTags(schema.tags)
end

function Validation.inspection(schema: any): (boolean, string?)
	if type(schema) ~= "table" then
		return false, "inspection request schema must be a table"
	end
	local safe, reason = Validation.safePayload(schema)
	if not safe then
		return false, reason
	end
	if not validId(schema.inspectionId) or not validId(schema.ownerSystem) then
		return false, "inspection request identity fields are invalid"
	end
	if
		schema.schemaType ~= nil
		and schema.schemaType ~= Types.SchemaType.InspectionRequestSchema
	then
		return false, "unsupported inspection request schema type"
	end
	return validateTags(schema.tags)
end

function Validation.command(schema: any): (boolean, string?)
	if type(schema) ~= "table" then
		return false, "command schema must be a table"
	end
	local safe, reason = Validation.safePayload(schema)
	if not safe then
		return false, reason
	end
	if not validId(schema.commandId) or not validId(schema.ownerSystem) then
		return false, "command schema identity fields are invalid"
	end
	if schema.schemaType ~= nil and schema.schemaType ~= Types.SchemaType.CommandSchema then
		return false, "unsupported command schema type"
	end
	return validateTags(schema.tags)
end

function Validation.report(schema: any): (boolean, string?)
	if type(schema) ~= "table" then
		return false, "report package schema must be a table"
	end
	local safe, reason = Validation.safePayload(schema)
	if not safe then
		return false, reason
	end
	if not validId(schema.reportId) or not validId(schema.ownerSystem) then
		return false, "report package identity fields are invalid"
	end
	if schema.schemaType ~= nil and schema.schemaType ~= Types.SchemaType.ReportPackageSchema then
		return false, "unsupported report package schema type"
	end
	return validateTags(schema.tags)
end

function Validation.permission(schema: any): (boolean, string?)
	if type(schema) ~= "table" then
		return false, "malformed permission schema"
	end
	local safe, reason = Validation.safePayload(schema)
	if not safe then
		return false, reason
	end
	if not validId(schema.permissionId) or not validId(schema.ownerSystem) then
		return false, "malformed permission schema"
	end
	if schema.schemaType ~= nil and schema.schemaType ~= Types.SchemaType.PermissionSchema then
		return false, "unsupported permission schema type"
	end
	return validateTags(schema.tags)
end

function Validation.audit(record: any): (boolean, string?)
	if type(record) ~= "table" then
		return false, "malformed audit record"
	end
	local safe, reason = Validation.safePayload(record)
	if not safe then
		return false, reason
	end
	if not validId(record.auditId) or not validId(record.ownerSystem) then
		return false, "malformed audit record"
	end
	if record.schemaType ~= nil and record.schemaType ~= Types.SchemaType.AuditRecordSchema then
		return false, "unsupported audit record schema type"
	end
	return validateTags(record.tags)
end

function Validation.validate(): (boolean, string?)
	if Types.Mode ~= "ServerAuthoritativeDeveloperToolingSchemaRuntime" then
		return false, "Developer Tooling Runtime must remain server-authoritative schema runtime"
	end
	return true, nil
end

return Validation
