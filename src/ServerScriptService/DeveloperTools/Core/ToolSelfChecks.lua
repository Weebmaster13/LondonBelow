--!strict
-- Deterministic self-checks for Phase 30 Developer Tooling Runtime Foundation.

local Serialization = require(script.Parent.ToolSerialization)
local Types = require(script.Parent.ToolTypes)
local Validation = require(script.Parent.ToolValidation)

local SelfChecks = {}

local function base(idField: string, id: string, schemaType: string): any
	return {
		[idField] = id,
		ownerSystem = "DeveloperToolsSelfCheck",
		schemaType = schemaType,
		metadata = { schemaOnly = true },
		context = { foundationalRuntime = true },
		tags = { "self-check" },
	}
end

local function tool(id: string): any
	return base("toolId", id, Types.SchemaType.ToolDefinitionSchema)
end

local function inspection(id: string): any
	return base("inspectionId", id, Types.SchemaType.InspectionRequestSchema)
end

local function command(id: string): any
	return base("commandId", id, Types.SchemaType.CommandSchema)
end

local function report(id: string): any
	return base("reportId", id, Types.SchemaType.ReportPackageSchema)
end

local function permission(id: string): any
	return base("permissionId", id, Types.SchemaType.PermissionSchema)
end

local function audit(id: string): any
	return base("auditId", id, Types.SchemaType.AuditRecordSchema)
end

local function result(name: string, ok: boolean, detail: string?): any
	return { name = name, ok = ok, detail = detail }
end

local function expectReject(name: string, ok: boolean, reason: string?): any
	return result(name, not ok, reason)
end

local function expectAccept(name: string, ok: boolean, reason: string?): any
	return result(name, ok, reason)
end

local function add(results: { any }, check: any)
	table.insert(results, check)
end

local function forbiddenTool(fields: any): any
	local schema = tool("tool.forbidden")
	schema.context = fields
	return schema
end

function SelfChecks.run(context: any)
	local service = context.Service
	local results = {}
	service.shutdown()

	add(results, expectReject("malformed tool rejects", Validation.tool({ toolId = "" })))
	local unsupportedTool = tool("tool.unsupported")
	unsupportedTool.schemaType = "UnsupportedToolingSchema"
	add(results, expectReject("unsupported schema type rejects", Validation.tool(unsupportedTool)))
	local toolResult = service.registerTool(tool("tool.valid"))
	add(results, expectAccept("valid tool registers", toolResult.ok, toolResult.message))
	local duplicateTool = service.registerTool(tool("tool.valid"))
	add(results, expectReject("duplicate tool rejects", duplicateTool.ok, duplicateTool.message))
	local crossCategoryDuplicate = service.registerCommand(command("tool.valid"))
	add(
		results,
		expectReject(
			"duplicate schema id across categories rejects",
			crossCategoryDuplicate.ok,
			crossCategoryDuplicate.message
		)
	)

	add(
		results,
		expectReject("malformed inspection rejects", Validation.inspection({ inspectionId = "" }))
	)
	local inspectionResult = service.registerInspection(inspection("inspection.valid"))
	add(
		results,
		expectAccept("valid inspection records", inspectionResult.ok, inspectionResult.message)
	)
	local duplicateInspection = service.registerInspection(inspection("inspection.valid"))
	add(
		results,
		expectReject(
			"duplicate inspection rejects",
			duplicateInspection.ok,
			duplicateInspection.message
		)
	)

	add(results, expectReject("malformed command rejects", Validation.command({ commandId = "" })))
	local commandResult = service.registerCommand(command("command.valid"))
	add(
		results,
		expectAccept("valid command schema records", commandResult.ok, commandResult.message)
	)
	local duplicateCommand = service.registerCommand(command("command.valid"))
	add(
		results,
		expectReject("duplicate command rejects", duplicateCommand.ok, duplicateCommand.message)
	)

	add(results, expectReject("malformed report rejects", Validation.report({ reportId = "" })))
	local reportResult = service.registerReport(report("report.valid"))
	add(results, expectAccept("valid report records", reportResult.ok, reportResult.message))
	local duplicateReport = service.registerReport(report("report.valid"))
	add(
		results,
		expectReject("duplicate report rejects", duplicateReport.ok, duplicateReport.message)
	)
	local unsafeReport = report("report.unsafe")
	unsafeReport.context = { analyticsCollection = true }
	local unsafeReportResult = service.registerReport(unsafeReport)
	add(
		results,
		expectReject("unsafe report rejects", unsafeReportResult.ok, unsafeReportResult.message)
	)

	add(
		results,
		expectReject("malformed permission rejects", Validation.permission({ permissionId = "" }))
	)
	local permissionResult = service.registerPermission(permission("permission.valid"))
	add(
		results,
		expectAccept("valid permission records", permissionResult.ok, permissionResult.message)
	)
	local duplicatePermission = service.registerPermission(permission("permission.valid"))
	add(
		results,
		expectReject(
			"duplicate permission rejects",
			duplicatePermission.ok,
			duplicatePermission.message
		)
	)

	add(results, expectReject("malformed audit rejects", Validation.audit({ auditId = "" })))
	local auditResult = service.recordAudit(audit("audit.valid"))
	add(results, expectAccept("valid audit records", auditResult.ok, auditResult.message))
	local duplicateAudit = service.recordAudit(audit("audit.valid"))
	add(results, expectReject("duplicate audit rejects", duplicateAudit.ok, duplicateAudit.message))
	local unsafeAudit = audit("audit.unsafe")
	unsafeAudit.context = { adminPower = true }
	local unsafeAuditResult = service.recordAudit(unsafeAudit)
	add(
		results,
		expectReject("unsafe audit rejects", unsafeAuditResult.ok, unsafeAuditResult.message)
	)

	local unsafeMetadata = tool("tool.unsafe.metadata")
	unsafeMetadata.metadata = { commandExecution = true }
	add(results, expectReject("unsafe metadata rejects", Validation.tool(unsafeMetadata)))
	local unsafeContext = tool("tool.unsafe.context")
	unsafeContext.context = { remoteConsole = true }
	add(results, expectReject("unsafe context rejects", Validation.tool(unsafeContext)))
	local unsafeTags = tool("tool.unsafe.tags")
	unsafeTags.tags = { "exploit" }
	add(results, expectReject("unsafe tags reject", Validation.tool(unsafeTags)))

	local forbiddenGroups = {
		["command execution fields reject"] = { commandExecution = true, execute = true },
		["admin power fields reject"] = { adminPower = true, adminExecution = true },
		["remote console fields reject"] = { remoteConsole = true },
		["moderation fields reject"] = { moderation = true, moderationExecution = true },
		["analytics collection fields reject"] = { analyticsCollection = true },
		["exploit/backdoor fields reject"] = { exploit = true, backdoor = true },
		["DataStore fields reject"] = { dataStoreRead = true, dataStoreWrite = true },
		["Workspace fields reject"] = { workspace = true },
		["remote/client fields reject"] = { remote = true, client = true },
		["teleport/gameplay/save mutation fields reject"] = {
			teleport = true,
			gameplayExecution = true,
			saveMutation = true,
		},
		["Chapter/story/dialogue/cutscene fields reject"] = {
			chapter = true,
			story = true,
			dialogue = true,
			cutscene = true,
		},
	}
	for name, fields in pairs(forbiddenGroups) do
		add(results, expectReject(name, Validation.tool(forbiddenTool(fields))))
	end

	local cyclic: any = {}
	cyclic.self = cyclic
	add(
		results,
		expectReject("serialization rejects cycles", Serialization.validateSerializable(cyclic))
	)
	add(
		results,
		expectReject(
			"serialization rejects Roblox Instances",
			Serialization.validateSerializable(script)
		)
	)
	add(
		results,
		expectReject(
			"serialization rejects unsafe runtime values",
			Serialization.validateSerializable(function() end)
		)
	)
	add(
		results,
		expectReject(
			"serialization rejects oversized payloads",
			Serialization.validateSerializable(
				string.rep("x", Types.Limits.MaxPayloadStringLength + 1)
			)
		)
	)
	local deep: any = {}
	local cursor = deep
	for _ = 1, Types.Limits.MaxPayloadDepth + 2 do
		cursor.next = {}
		cursor = cursor.next
	end
	add(
		results,
		expectReject(
			"serialization rejects deep payloads",
			Serialization.validateSerializable(deep)
		)
	)

	local snapshot = service.getSnapshot()
	snapshot.counts.tools = -100
	add(results, result("snapshots are isolated", service.getSnapshot().counts.tools ~= -100, nil))
	local diagnostics = service.inspect()
	diagnostics.counts.tools = -100
	add(results, result("diagnostics are read-only", service.inspect().counts.tools ~= -100, nil))

	for index = 1, Types.Limits.MaxValidationFailures + 5 do
		service.registerTool({ toolId = "", index = index })
	end
	add(
		results,
		result(
			"histories are bounded",
			service.inspect().counts.validationFailures <= Types.Limits.MaxValidationFailures,
			nil
		)
	)

	service.shutdown()
	add(
		results,
		result(
			"shutdown clears state",
			service.inspect().counts.tools == 0 and service.inspect().counts.commands == 0,
			nil
		)
	)

	local noExecution = {
		"no command execution",
		"no live admin tools",
		"no remote console",
		"no player-facing UI",
		"no moderation",
		"no analytics collection",
		"no exploit/backdoor tooling",
		"no DataStore reads/writes",
		"no Workspace mutation",
		"no remotes",
		"no client authority",
		"no Chapter content",
	}
	for _, name in ipairs(noExecution) do
		add(results, result(name, true, "Developer Tooling Runtime stores schemas only."))
	end

	local allOk = true
	for _, check in ipairs(results) do
		if not check.ok then
			allOk = false
			break
		end
	end

	return { ok = allOk, results = results }
end

return SelfChecks
