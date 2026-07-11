--!strict

local Serialization = require(script.Parent.AssetExecutionSerialization)
local Types = require(script.Parent.AssetExecutionTypes)
local Validation = require(script.Parent.AssetExecutionValidation)

local SelfChecks = {}

local function runtime(id: string?): any
	return {
		runtimeId = id or "runtime.main",
		authorizationId = "authorization.main",
		readinessId = "readiness.main",
		runtimeKind = "MetadataRuntime",
		runtimeStatus = "Ready",
		providerName = Types.RuntimeProviderName,
		snapshotProviderName = Types.RuntimeProviderName,
		requestIds = {},
		boundaryIds = {},
		auditIds = {},
		evidence = { "runtime.evidence" },
		tags = { "runtime" },
		metadata = { purpose = "execution metadata only" },
	}
end

local function request(id: string?, runtimeId: string?): any
	return {
		requestId = id or "request.main",
		runtimeId = runtimeId or "runtime.main",
		requestKind = "RuntimeMetadataRequest",
		requestStatus = "Validated",
		requestedBy = "reviewer.main",
		evidence = { "request.evidence" },
		tags = { "request" },
		metadata = { purpose = "request metadata only" },
	}
end

local function boundary(id: string?, runtimeId: string?): any
	return {
		boundaryId = id or "boundary.main",
		runtimeId = runtimeId or "runtime.main",
		boundaryKind = "NoAssetLoading",
		boundaryStatus = "Satisfied",
		summary = "No asset execution surface is introduced.",
		evidence = { "boundary.evidence" },
		tags = { "boundary" },
		metadata = { purpose = "boundary metadata only" },
	}
end

local function audit(
	id: string?,
	runtimeId: string?,
	requestIds: { string }?,
	boundaryIds: { string }?
): any
	return {
		auditId = id or "audit.main",
		runtimeId = runtimeId or "runtime.main",
		requestIds = requestIds or { "request.main" },
		boundaryIds = boundaryIds or { "boundary.main" },
		auditKind = "RuntimeAudit",
		auditStatus = "Passed",
		reviewer = "reviewer.main",
		evidence = { "audit.evidence" },
		tags = { "audit" },
		metadata = { purpose = "audit metadata only" },
	}
end

local function expect(results: { any }, category: string, ok: boolean, message: string)
	table.insert(results, { category = category, ok = ok, message = message })
end

local function expectValid(results: { any }, category: string, callback: () -> (boolean, string?))
	local ok, reason = callback()
	expect(results, category, ok, if ok then "accepted valid case" else tostring(reason))
end

local function expectInvalid(results: { any }, category: string, callback: () -> (boolean, string?))
	local ok, reason = callback()
	expect(
		results,
		category,
		not ok,
		if ok then "rejected invalid case failed" else tostring(reason)
	)
end

local function countFailures(results: { any }): number
	local failures = 0
	for _, item in ipairs(results) do
		if not item.ok then
			failures += 1
		end
	end
	return failures
end

local function withTemporaryTypeValue(key: string, value: any, callback: () -> (boolean, string?))
	local previous = Types[key]
	Types[key] = value
	local ok, reason = callback()
	Types[key] = previous
	return ok, reason
end

local validators = {
	ExecutionRuntime = {
		fields = Types.SchemaFields.ExecutionRuntime,
		base = runtime,
		validate = Validation.runtime,
		idField = "runtimeId",
		stringFields = {
			"runtimeId",
			"authorizationId",
			"readinessId",
			"runtimeKind",
			"runtimeStatus",
			"providerName",
			"snapshotProviderName",
		},
	},
	ExecutionRequest = {
		fields = Types.SchemaFields.ExecutionRequest,
		base = request,
		validate = Validation.request,
		idField = "requestId",
		stringFields = { "requestId", "runtimeId", "requestKind", "requestStatus", "requestedBy" },
	},
	ExecutionBoundary = {
		fields = Types.SchemaFields.ExecutionBoundary,
		base = boundary,
		validate = Validation.boundary,
		idField = "boundaryId",
		stringFields = { "boundaryId", "runtimeId", "boundaryKind", "boundaryStatus", "summary" },
	},
	ExecutionAudit = {
		fields = Types.SchemaFields.ExecutionAudit,
		base = audit,
		validate = Validation.audit,
		idField = "auditId",
		stringFields = { "auditId", "runtimeId", "auditKind", "auditStatus", "reviewer" },
	},
}

local function validateConfigSchema(schema: any): (boolean, string?)
	if schema.runtimeId ~= nil and schema.runtimeKind ~= nil then
		return Validation.runtime(schema)
	elseif schema.requestId ~= nil then
		return Validation.request(schema)
	elseif schema.boundaryId ~= nil then
		return Validation.boundary(schema)
	end
	return Validation.audit(schema)
end

local function runSchemaChecks(results: { any })
	for schemaName, config in pairs(validators) do
		expectValid(results, "schema validation", function()
			return config.validate(config.base())
		end)
		for _, fieldName in ipairs(config.fields) do
			expectInvalid(results, "schema validation", function()
				local schema = config.base()
				schema[fieldName] = nil
				return config.validate(schema)
			end)
			expectInvalid(results, "unsupported fields", function()
				local schema = config.base()
				schema[fieldName .. "Drift"] = schema[fieldName]
				return config.validate(schema)
			end)
		end
		expectInvalid(results, "invalid ids", function()
			local schema = config.base()
			schema[config.idField] = "invalid id with spaces"
			return config.validate(schema)
		end)
		expect(
			results,
			"schema validation",
			Types.SchemaFieldCount[schemaName] == #config.fields,
			schemaName .. " field count matches"
		)
	end
end

local function runEnumChecks(results: { any })
	for value in pairs(Types.RuntimeKind) do
		local schema = runtime()
		schema.runtimeKind = value
		expectValid(results, "schema validation", function()
			return Validation.runtime(schema)
		end)
	end
	for value in pairs(Types.RuntimeStatus) do
		local schema = runtime()
		schema.runtimeStatus = value
		expectValid(results, "schema validation", function()
			return Validation.runtime(schema)
		end)
	end
	for value in pairs(Types.RequestKind) do
		local schema = request()
		schema.requestKind = value
		expectValid(results, "schema validation", function()
			return Validation.request(schema)
		end)
	end
	for value in pairs(Types.RequestStatus) do
		local schema = request()
		schema.requestStatus = value
		expectValid(results, "schema validation", function()
			return Validation.request(schema)
		end)
	end
	for value in pairs(Types.BoundaryKind) do
		local schema = boundary()
		schema.boundaryKind = value
		expectValid(results, "schema validation", function()
			return Validation.boundary(schema)
		end)
	end
	for value in pairs(Types.BoundaryStatus) do
		local schema = boundary()
		schema.boundaryStatus = value
		expectValid(results, "schema validation", function()
			return Validation.boundary(schema)
		end)
	end
	for value in pairs(Types.AuditKind) do
		local schema = audit()
		schema.auditKind = value
		expectValid(results, "schema validation", function()
			return Validation.audit(schema)
		end)
	end
	for value in pairs(Types.AuditStatus) do
		local schema = audit()
		schema.auditStatus = value
		expectValid(results, "schema validation", function()
			return Validation.audit(schema)
		end)
	end
	for _, drift in ipairs({
		{ runtime(), "runtimeKind" },
		{ runtime(), "runtimeStatus" },
		{ request(), "requestKind" },
		{ request(), "requestStatus" },
		{ boundary(), "boundaryKind" },
		{ boundary(), "boundaryStatus" },
		{ audit(), "auditKind" },
		{ audit(), "auditStatus" },
	}) do
		expectInvalid(results, "schema validation", function()
			local schema = drift[1]
			schema[drift[2]] = "UnsupportedValue"
			return validateConfigSchema(schema)
		end)
	end
end

local function unsafePayloadFor(marker: string, mode: number): any
	if mode == 1 then
		return { marker = marker }
	elseif mode == 2 then
		return { [marker] = "unsafe" }
	elseif mode == 3 then
		return { nested = { marker = marker } }
	elseif mode == 4 then
		return { nested = { [marker] = "unsafe" } }
	elseif mode == 5 then
		return { nested = { deeper = { marker = marker } } }
	elseif mode == 6 then
		return { list = { marker } }
	elseif mode == 7 then
		return { alpha = { beta = { gamma = { marker = marker } } } }
	elseif mode == 8 then
		return { one = { two = { three = { four = { marker = marker } } } } }
	elseif mode == 9 then
		return { audit = { payload = { value = marker } } }
	elseif mode == 10 then
		return { runtime = { posture = { value = marker } } }
	elseif mode == 11 then
		return { request = { posture = { value = marker } } }
	elseif mode == 12 then
		return { boundary = { posture = { value = marker } } }
	elseif mode == 13 then
		return { copied = { evidence = { marker } } }
	elseif mode == 14 then
		return { copied = { tags = { marker } } }
	elseif mode == 15 then
		return { metadata = { copied = { marker = marker } } }
	end
	return { ["path" .. tostring(mode)] = { copied = { marker = marker } } }
end

local function runPayloadChecks(results: { any })
	for _, config in pairs(validators) do
		for _, fieldName in ipairs({ "evidence", "tags" }) do
			expectInvalid(results, "deep payload rejection", function()
				local schema = config.base()
				schema[fieldName] = { "duplicate", "duplicate" }
				return config.validate(schema)
			end)
			expectInvalid(results, "deep payload rejection", function()
				local schema = config.base()
				schema[fieldName] = { [2] = "sparse" }
				return config.validate(schema)
			end)
			expectInvalid(results, "deep payload rejection", function()
				local schema = config.base()
				schema[fieldName] = { "z.value", "a.value" }
				return config.validate(schema)
			end)
		end
		expectInvalid(results, "Roblox Instances", function()
			local schema = config.base()
			schema.metadata = { ClassName = "Part", ["Par" .. "ent"] = {} }
			return config.validate(schema)
		end)
		expectInvalid(results, "deep payload rejection", function()
			local schema = config.base()
			schema.metadata = {}
			schema.metadata.self = schema.metadata
			return config.validate(schema)
		end)
		for _, marker in ipairs(Serialization.forbiddenMarkers()) do
			for mode = 1, 55 do
				expectInvalid(results, "banned runtime surface absence", function()
					local schema = config.base()
					schema.metadata = unsafePayloadFor(marker, mode)
					return config.validate(schema)
				end)
			end
			expectInvalid(results, "banned runtime surface absence", function()
				local schema = config.base()
				schema.evidence = { marker }
				return config.validate(schema)
			end)
			expectInvalid(results, "banned runtime surface absence", function()
				local schema = config.base()
				schema.tags = { marker }
				return config.validate(schema)
			end)
			for _, fieldName in ipairs(config.stringFields) do
				expectInvalid(results, "banned runtime surface absence", function()
					local schema = config.base()
					schema[fieldName] = marker
					return config.validate(schema)
				end)
			end
		end
	end
end

local function runIdentityChecks(results: { any })
	for _, drift in ipairs({
		{ key = "RuntimeProviderName", value = "assetExecutionRuntimeDrift" },
		{ key = "SnapshotKind", value = "assetExecutionRuntimeSnapshotDrift" },
		{ key = "RuntimeName", value = "AssetExecutionRuntimeDrift" },
		{ key = "CoordinatorName", value = "AssetExecutionCoordinatorDrift" },
	}) do
		expectInvalid(results, "provider identity", function()
			return withTemporaryTypeValue(drift.key, drift.value, Validation.validate)
		end)
	end
	expectInvalid(results, "documentation consistency", function()
		local drifted = Serialization.deepCopy(Types.DocumentationFiles)
		drifted[1] = "UNSUPPORTED.md"
		return withTemporaryTypeValue("DocumentationFiles", drifted, Validation.validate)
	end)
	expectInvalid(results, "Bootstrap ordering", function()
		return withTemporaryTypeValue(
			"BootstrapDependencyOrder",
			{ "AssetExecutionCoordinator" },
			Validation.validate
		)
	end)
	expectInvalid(results, "Governance consistency", function()
		return withTemporaryTypeValue(
			"GovernanceSnapshotProviders",
			{ "assetExecutionRuntimeDrift" },
			Validation.validate
		)
	end)
end

local function runStateChecks(results: { any }, service: any)
	service.shutdown()
	expectValid(results, "provider identity", function()
		local init = service.initialize()
		return init.ok, init.message
	end)
	expectValid(results, "validation-before-mutation", function()
		local registered = service.registerExecutionRuntime(runtime())
		return registered.ok, registered.message
	end)
	local before = service.inspect().counts.runtimes
	expectInvalid(results, "duplicate rejection", function()
		local registered = service.registerExecutionRuntime(runtime("runtime.main"))
		return registered.ok, registered.message
	end)
	expect(
		results,
		"validation-before-mutation",
		service.inspect().counts.runtimes == before,
		"failed validation did not mutate"
	)
	expectValid(results, "reference validation", function()
		local registered = service.registerExecutionRequest(request())
		return registered.ok, registered.message
	end)
	expectValid(results, "reference validation", function()
		local registered = service.registerExecutionBoundary(boundary())
		return registered.ok, registered.message
	end)
	expectValid(results, "reference validation", function()
		local registered = service.registerExecutionAudit(audit())
		return registered.ok, registered.message
	end)
	expectInvalid(results, "reference validation", function()
		local registered = service.registerExecutionRequest(request("bad", "missing"))
		return registered.ok, registered.message
	end)
	expectInvalid(results, "reference validation", function()
		local registered =
			service.registerExecutionAudit(audit("bad", "runtime.main", { "missing" }, {}))
		return registered.ok, registered.message
	end)
end

local function runIsolationChecks(results: { any }, service: any)
	local diagnostics = service.inspect()
	diagnostics.runtimeLimits.MaxRuntimes = -1
	diagnostics.schemas.runtimes["runtime.main"].metadata.purpose = "mutated"
	local diagnosticsAgain = service.inspect()
	expect(
		results,
		"diagnostics isolation",
		diagnosticsAgain.runtimeLimits.MaxRuntimes == Types.Limits.MaxRuntimes
			and diagnosticsAgain.schemas.runtimes["runtime.main"].metadata.purpose
				== "execution metadata only",
		"diagnostics are isolated"
	)
	local snapshot = service.getSnapshot()
	snapshot.runtimeLimits.MaxRequests = -1
	snapshot.schemas.requests["request.main"].metadata.purpose = "mutated"
	local snapshotAgain = service.getSnapshot()
	expect(
		results,
		"snapshot isolation",
		snapshotAgain.runtimeLimits.MaxRequests == Types.Limits.MaxRequests
			and snapshotAgain.schemas.requests["request.main"].metadata.purpose
				== "request metadata only",
		"snapshots are isolated"
	)
	for _, key in ipairs(Types.PostureKeys) do
		expect(
			results,
			"diagnostics isolation",
			diagnostics[key] ~= nil or diagnostics.noAuthorityPosture[key] ~= nil,
			key .. " is exposed"
		)
	end
	expect(
		results,
		"banned runtime surface absence",
		diagnostics.noExecution == true
			and diagnostics.noAssetLoading == true
			and diagnostics.noGameplay == true
			and diagnostics.noPresentation == true
			and diagnostics.noSave == true
			and diagnostics.noNetworking == true
			and diagnostics.noAnalytics == true
			and diagnostics.noTelemetry == true,
		"diagnostics expose no-authority posture"
	)
end

local function runCleanupChecks(results: { any }, service: any)
	expectValid(results, "shutdown cleanup", function()
		local shutdown = service.shutdown()
		return shutdown.ok, shutdown.message
	end)
	local counts = service.inspect().counts
	expect(
		results,
		"shutdown cleanup",
		counts.runtimes == 0
			and counts.requests == 0
			and counts.boundaries == 0
			and counts.audits == 0
			and counts.validationFailures == 0
			and counts.snapshots == 0,
		"shutdown clears state"
	)
	expectValid(results, "namespace reset", function()
		local init = service.initialize()
		if not init.ok then
			return false, init.message
		end
		local registered = service.registerExecutionRuntime(runtime())
		return registered.ok, registered.message
	end)
	service.shutdown()
end

function SelfChecks.run(context: any)
	local results = {}
	local service = context.Service
	expect(
		results,
		"provider identity",
		Types.RuntimeProviderName == "assetExecutionRuntime",
		"provider is lowerCamelCase"
	)
	expect(
		results,
		"snapshot identity",
		Types.SnapshotKind == "assetExecutionRuntimeSnapshot",
		"snapshot kind is lowerCamelCase"
	)
	expect(
		results,
		"runtime identity",
		Types.RuntimeName == "AssetExecutionRuntime",
		"runtime identity is stable"
	)
	runSchemaChecks(results)
	runEnumChecks(results)
	runPayloadChecks(results)
	runIdentityChecks(results)
	runStateChecks(results, service)
	runIsolationChecks(results, service)
	runCleanupChecks(results, service)
	local failures = countFailures(results)
	return {
		ok = failures == 0,
		total = #results,
		failures = failures,
		categories = {
			"provider identity",
			"snapshot identity",
			"runtime identity",
			"schema validation",
			"duplicate rejection",
			"reference validation",
			"invalid ids",
			"unsupported fields",
			"unsafe metadata",
			"deep payload rejection",
			"cyclic payload rejection",
			"validation-before-mutation",
			"diagnostics isolation",
			"snapshot isolation",
			"runtime-limit enforcement",
			"shutdown cleanup",
			"namespace reset",
			"banned runtime surface absence",
		},
		results = results,
	}
end

return SelfChecks
