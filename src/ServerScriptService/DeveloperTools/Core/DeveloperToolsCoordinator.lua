--!strict
--[[
	Phase 30 Developer Tooling Runtime Coordinator.

	Server-authoritative developer tooling schema foundation. It records future
	tool definitions, inspection request schemas, command schemas, report
	packages, permission schemas, and audit records. It does not execute
	commands, grant admin powers, expose remotes, collect analytics, moderate,
	mutate Workspace, call DataStores, or create player-facing UI.
]]

local ServerScriptService = game:GetService("ServerScriptService")

local Core = ServerScriptService.Core
local Diagnostics = require(Core.Diagnostics)
local EventBus = require(Core.EventBus)
local Logger = require(Core.Logger)
local SnapshotManager = require(Core.SnapshotManager)

local AuditRuntime = require(script.Parent.ToolAuditRuntime)
local CommandRuntime = require(script.Parent.ToolCommandRuntime)
local DefinitionRuntime = require(script.Parent.ToolDefinitionRuntime)
local InspectionRuntime = require(script.Parent.ToolInspectionRuntime)
local PermissionRuntime = require(script.Parent.ToolPermissionRuntime)
local ReportRuntime = require(script.Parent.ToolReportRuntime)
local SelfChecks = require(script.Parent.ToolSelfChecks)
local Serialization = require(script.Parent.ToolSerialization)
local Signals = require(script.Parent.ToolSignals)
local Snapshots = require(script.Parent.ToolSnapshots)
local State = require(script.Parent.ToolState)
local ToolDiagnostics = require(script.Parent.ToolDiagnostics)
local Types = require(script.Parent.ToolTypes)
local Validation = require(script.Parent.ToolValidation)

local DeveloperToolsCoordinator = {}

local log = Logger.scope("DeveloperTools")
local initialized = false
local started = false
local lastSelfChecks: any = nil

local dependencies = {
	State = State,
	Validation = Validation,
}

local function result(ok: boolean, code: string, message: string?, extra: any?)
	local payload = extra or {}
	payload.ok = ok
	payload.code = code
	payload.message = message
	return payload
end

local function codeFor(reason: string?): string
	if reason == "duplicate toolId" then
		return Types.ResultCode.DuplicateTool
	elseif reason == "duplicate inspectionId" then
		return Types.ResultCode.DuplicateInspection
	elseif reason == "duplicate commandId" then
		return Types.ResultCode.DuplicateCommand
	elseif reason == "duplicate reportId" then
		return Types.ResultCode.DuplicateReport
	elseif reason == "duplicate permissionId" then
		return Types.ResultCode.DuplicatePermission
	elseif reason == "duplicate auditId" then
		return Types.ResultCode.DuplicateAudit
	elseif
		reason ~= nil
		and (
			string.find(reason, "payload", 1, true)
			or string.find(reason, "forbidden field", 1, true)
			or string.find(reason, "unsafe runtime", 1, true)
			or string.find(reason, "cyclic", 1, true)
		)
	then
		return Types.ResultCode.UnsafePayload
	end
	return Types.ResultCode.InvalidRequest
end

local function recordFailure(reason: string, payload: any?)
	State.recordValidationFailure(reason, payload)
	EventBus.publishDeferred(Signals.ValidationFailed, { reason = reason })
end

function DeveloperToolsCoordinator.registerTool(schema: any)
	local ok, reason = DefinitionRuntime.register(State, schema)
	if not ok then
		recordFailure(reason or "tool definition rejected", schema)
		return result(false, codeFor(reason), reason)
	end
	EventBus.publishDeferred(Signals.ToolRegistered, { toolId = schema.toolId })
	return result(true, Types.ResultCode.Ok, "tool definition schema registered")
end

function DeveloperToolsCoordinator.registerInspection(schema: any)
	local ok, reason = InspectionRuntime.register(State, schema)
	if not ok then
		recordFailure(reason or "inspection request rejected", schema)
		return result(false, codeFor(reason), reason)
	end
	EventBus.publishDeferred(Signals.InspectionRegistered, { inspectionId = schema.inspectionId })
	return result(true, Types.ResultCode.Ok, "inspection request schema registered")
end

function DeveloperToolsCoordinator.registerCommand(schema: any)
	local ok, reason = CommandRuntime.register(State, schema)
	if not ok then
		recordFailure(reason or "command schema rejected", schema)
		return result(false, codeFor(reason), reason)
	end
	EventBus.publishDeferred(Signals.CommandRegistered, { commandId = schema.commandId })
	return result(true, Types.ResultCode.Ok, "command schema registered")
end

function DeveloperToolsCoordinator.registerReport(schema: any)
	local ok, reason = ReportRuntime.register(State, schema)
	if not ok then
		recordFailure(reason or "report package rejected", schema)
		return result(false, codeFor(reason), reason)
	end
	EventBus.publishDeferred(Signals.ReportRegistered, { reportId = schema.reportId })
	return result(true, Types.ResultCode.Ok, "report package schema registered")
end

function DeveloperToolsCoordinator.registerPermission(schema: any)
	local ok, reason = PermissionRuntime.register(State, schema)
	if not ok then
		recordFailure(reason or "permission schema rejected", schema)
		return result(false, codeFor(reason), reason)
	end
	EventBus.publishDeferred(Signals.PermissionRegistered, { permissionId = schema.permissionId })
	return result(true, Types.ResultCode.Ok, "permission schema registered")
end

function DeveloperToolsCoordinator.recordAudit(record: any)
	local ok, reason = AuditRuntime.record(State, record)
	if not ok then
		recordFailure(reason or "audit record rejected", record)
		return result(false, codeFor(reason), reason)
	end
	EventBus.publishDeferred(Signals.AuditRecorded, { auditId = record.auditId })
	return result(true, Types.ResultCode.Ok, "audit record stored")
end

function DeveloperToolsCoordinator.initialize()
	if initialized then
		return
	end
	local valid, reason = DeveloperToolsCoordinator.validate()
	if not valid then
		error("DeveloperToolsCoordinator validation failed: " .. tostring(reason), 0)
	end
	Diagnostics.registerSampler("DeveloperTools", DeveloperToolsCoordinator.inspect)
	SnapshotManager.registerProvider("developerTools", DeveloperToolsCoordinator.getSnapshot)
	initialized = true
	log.success("Developer Tooling Runtime initialized")
end

function DeveloperToolsCoordinator.start()
	if started then
		return
	end
	if not initialized then
		DeveloperToolsCoordinator.initialize()
	end
	started = true
end

function DeveloperToolsCoordinator.shutdown()
	State.clear()
	started = false
	initialized = false
end

function DeveloperToolsCoordinator.inspect()
	return ToolDiagnostics.capture({
		initialized = initialized,
		started = started,
		lastSelfChecks = lastSelfChecks,
	}, dependencies)
end

function DeveloperToolsCoordinator.getSnapshot()
	local snapshot = Snapshots.capture(State)
	EventBus.publishDeferred(
		Signals.SnapshotCaptured,
		{ snapshot = Serialization.deepCopy(snapshot) }
	)
	return snapshot
end

function DeveloperToolsCoordinator.validate(): (boolean, string?)
	return ToolDiagnostics.validate(dependencies)
end

function DeveloperToolsCoordinator.runSelfChecks()
	if started then
		lastSelfChecks = {
			ok = false,
			reason = "Developer Tooling self-checks are destructive and may only run before start.",
		}
		return lastSelfChecks
	end
	lastSelfChecks = SelfChecks.run({ Service = DeveloperToolsCoordinator })
	return lastSelfChecks
end

return DeveloperToolsCoordinator
