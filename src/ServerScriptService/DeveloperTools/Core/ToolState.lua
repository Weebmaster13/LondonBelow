--!strict
-- Central bounded state store for the Developer Tooling Runtime Foundation.

local Serialization = require(script.Parent.ToolSerialization)
local Types = require(script.Parent.ToolTypes)
local Validation = require(script.Parent.ToolValidation)

local State = {}

local tools: { [string]: any } = {}
local inspections: { [string]: any } = {}
local commands: { [string]: any } = {}
local reports: { [string]: any } = {}
local permissions: { [string]: any } = {}
local audits: { [string]: any } = {}
local validationFailures: { any } = {}
local snapshotHistory: { any } = {}

local function boundedInsert(list: { any }, value: any, limit: number)
	table.insert(list, value)
	while #list > limit do
		table.remove(list, 1)
	end
end

local function countMap(map: { [string]: any }): number
	local count = 0
	for _ in pairs(map) do
		count += 1
	end
	return count
end

function State.registerTool(schema: any): (boolean, string?)
	local ok, reason = Validation.tool(schema)
	if not ok then
		return false, reason
	end
	if tools[schema.toolId] ~= nil then
		return false, "duplicate toolId"
	end
	if countMap(tools) >= Types.Limits.MaxTools then
		return false, "tool limit exceeded"
	end
	tools[schema.toolId] = Serialization.deepCopy(schema)
	return true, nil
end

function State.registerInspection(schema: any): (boolean, string?)
	local ok, reason = Validation.inspection(schema)
	if not ok then
		return false, reason
	end
	if inspections[schema.inspectionId] ~= nil then
		return false, "duplicate inspectionId"
	end
	if countMap(inspections) >= Types.Limits.MaxInspections then
		return false, "inspection limit exceeded"
	end
	inspections[schema.inspectionId] = Serialization.deepCopy(schema)
	return true, nil
end

function State.registerCommand(schema: any): (boolean, string?)
	local ok, reason = Validation.command(schema)
	if not ok then
		return false, reason
	end
	if commands[schema.commandId] ~= nil then
		return false, "duplicate commandId"
	end
	if countMap(commands) >= Types.Limits.MaxCommands then
		return false, "command schema limit exceeded"
	end
	commands[schema.commandId] = Serialization.deepCopy(schema)
	return true, nil
end

function State.registerReport(schema: any): (boolean, string?)
	local ok, reason = Validation.report(schema)
	if not ok then
		return false, reason
	end
	if reports[schema.reportId] ~= nil then
		return false, "duplicate reportId"
	end
	if countMap(reports) >= Types.Limits.MaxReports then
		return false, "report limit exceeded"
	end
	reports[schema.reportId] = Serialization.deepCopy(schema)
	return true, nil
end

function State.registerPermission(schema: any): (boolean, string?)
	local ok, reason = Validation.permission(schema)
	if not ok then
		return false, reason
	end
	if permissions[schema.permissionId] ~= nil then
		return false, "duplicate permissionId"
	end
	if countMap(permissions) >= Types.Limits.MaxPermissions then
		return false, "permission limit exceeded"
	end
	permissions[schema.permissionId] = Serialization.deepCopy(schema)
	return true, nil
end

function State.recordAudit(record: any): (boolean, string?)
	local ok, reason = Validation.audit(record)
	if not ok then
		return false, reason
	end
	if audits[record.auditId] ~= nil then
		return false, "duplicate auditId"
	end
	if countMap(audits) >= Types.Limits.MaxAudits then
		return false, "audit limit exceeded"
	end
	audits[record.auditId] = Serialization.deepCopy(record)
	return true, nil
end

function State.recordValidationFailure(reason: string, payload: any?)
	boundedInsert(validationFailures, {
		reason = reason,
		payload = Serialization.diagnosticCopy(payload),
	}, Types.Limits.MaxValidationFailures)
end

function State.recordSnapshot(snapshot: any)
	boundedInsert(
		snapshotHistory,
		Serialization.diagnosticCopy(snapshot),
		Types.Limits.MaxSnapshotHistory
	)
end

function State.inspect()
	return Serialization.deepCopy({
		tools = tools,
		inspections = inspections,
		commands = commands,
		reports = reports,
		permissions = permissions,
		audits = audits,
		validationFailures = validationFailures,
		snapshotHistory = snapshotHistory,
		counts = {
			tools = countMap(tools),
			inspections = countMap(inspections),
			commands = countMap(commands),
			reports = countMap(reports),
			permissions = countMap(permissions),
			audits = countMap(audits),
			validationFailures = #validationFailures,
			snapshots = #snapshotHistory,
		},
	})
end

function State.clear()
	table.clear(tools)
	table.clear(inspections)
	table.clear(commands)
	table.clear(reports)
	table.clear(permissions)
	table.clear(audits)
	table.clear(validationFailures)
	table.clear(snapshotHistory)
end

return State
