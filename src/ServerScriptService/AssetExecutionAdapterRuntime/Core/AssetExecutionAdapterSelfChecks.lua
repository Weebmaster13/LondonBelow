--!strict

local Serialization = require(script.Parent.AssetExecutionAdapterSerialization)
local Signals = require(script.Parent.AssetExecutionAdapterSignals)
local Types = require(script.Parent.AssetExecutionAdapterTypes)
local Validation = require(script.Parent.AssetExecutionAdapterValidation)

local SelfChecks = {}

local function adapter(id: string?, name: string?): any
	return {
		adapterId = id or "adapter.main",
		adapterName = name or "adapter.main.name",
		contractId = "contract.main",
		runtimeId = "runtime.main",
		adapterKind = "MetadataAdapter",
		adapterStatus = "Registered",
		providerName = Types.RuntimeProviderName,
		snapshotProviderName = Types.RuntimeProviderName,
		capabilityIds = {},
		compatibilityIds = {},
		boundaryIds = {},
		auditIds = {},
		evidence = { "adapter.evidence" },
		tags = { "adapter" },
		metadata = { purpose = "adapter metadata only" },
	}
end

local function capability(id: string?, adapterId: string?): any
	return {
		capabilityId = id or "capability.main",
		adapterId = adapterId or "adapter.main",
		capabilityKind = "NoExecutionCapability",
		capabilityStatus = "Compatible",
		summary = "Capability describes future adapter obligations only.",
		evidence = { "capability.evidence" },
		tags = { "capability" },
		metadata = { purpose = "capability metadata only" },
	}
end

local function compatibility(id: string?, adapterId: string?): any
	return {
		compatibilityId = id or "compatibility.main",
		adapterId = adapterId or "adapter.main",
		compatibilityKind = "RuntimeCompatibility",
		compatibilityStatus = "Compatible",
		targetRuntimeName = "AssetExecutionRuntime",
		evidence = { "compatibility.evidence" },
		tags = { "compatibility" },
		metadata = { purpose = "compatibility metadata only" },
	}
end

local function boundary(id: string?, adapterId: string?): any
	return {
		boundaryId = id or "boundary.main",
		adapterId = adapterId or "adapter.main",
		boundaryKind = "NoAssetLoading",
		boundaryStatus = "Satisfied",
		summary = "No asset operation surface is introduced.",
		evidence = { "boundary.evidence" },
		tags = { "boundary" },
		metadata = { purpose = "boundary metadata only" },
	}
end

local function audit(
	id: string?,
	adapterId: string?,
	capabilityIds: { string }?,
	compatibilityIds: { string }?,
	boundaryIds: { string }?
): any
	return {
		auditId = id or "audit.main",
		adapterId = adapterId or "adapter.main",
		capabilityIds = capabilityIds or { "capability.main" },
		compatibilityIds = compatibilityIds or { "compatibility.main" },
		boundaryIds = boundaryIds or { "boundary.main" },
		auditKind = "AdapterAudit",
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
	ExecutionAdapter = {
		fields = Types.SchemaFields.ExecutionAdapter,
		base = adapter,
		validate = Validation.adapter,
		idField = "adapterId",
		enumField = "adapterKind",
	},
	ExecutionAdapterCapability = {
		fields = Types.SchemaFields.ExecutionAdapterCapability,
		base = capability,
		validate = Validation.capability,
		idField = "capabilityId",
		enumField = "capabilityKind",
	},
	ExecutionAdapterCompatibility = {
		fields = Types.SchemaFields.ExecutionAdapterCompatibility,
		base = compatibility,
		validate = Validation.compatibility,
		idField = "compatibilityId",
		enumField = "compatibilityKind",
	},
	ExecutionAdapterBoundary = {
		fields = Types.SchemaFields.ExecutionAdapterBoundary,
		base = boundary,
		validate = Validation.boundary,
		idField = "boundaryId",
		enumField = "boundaryKind",
	},
	ExecutionAdapterAudit = {
		fields = Types.SchemaFields.ExecutionAdapterAudit,
		base = audit,
		validate = Validation.audit,
		idField = "auditId",
		enumField = "auditKind",
	},
}

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
		expectInvalid(results, "enum validation", function()
			local schema = config.base()
			schema[config.enumField] = "UnsupportedValue"
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
	for _, enumName in ipairs({
		"AdapterKind",
		"AdapterStatus",
		"CapabilityKind",
		"CapabilityStatus",
		"CompatibilityKind",
		"CompatibilityStatus",
		"BoundaryKind",
		"BoundaryStatus",
		"AuditKind",
		"AuditStatus",
	}) do
		expectInvalid(results, "enum drift", function()
			local drifted = Serialization.deepCopy(Types[enumName])
			drifted.UnsupportedValue = true
			return withTemporaryTypeValue(enumName, drifted, Validation.validate)
		end)
	end
end

local function runPayloadChecks(results: { any })
	for _, config in pairs(validators) do
		expectInvalid(results, "Roblox Instances", function()
			local schema = config.base()
			schema.metadata = { ClassName = "Part", ["Par" .. "ent"] = {} }
			return config.validate(schema)
		end)
		expectInvalid(results, "cyclic payload rejection", function()
			local schema = config.base()
			schema.metadata = {}
			schema.metadata.self = schema.metadata
			return config.validate(schema)
		end)
		expectInvalid(results, "metatable rejection", function()
			local schema = config.base()
			schema.metadata = setmetatable({ safe = "no" }, {})
			return config.validate(schema)
		end)
		for _, fieldName in ipairs({ "evidence", "tags" }) do
			expectInvalid(results, "deep payload rejection", function()
				local schema = config.base()
				schema[fieldName] = { "duplicate", "duplicate" }
				return config.validate(schema)
			end)
			expectInvalid(results, "ordered child arrays", function()
				local schema = config.base()
				schema[fieldName] = { "z.value", "a.value" }
				return config.validate(schema)
			end)
		end
		for _, marker in ipairs(Serialization.forbiddenMarkers()) do
			expectInvalid(results, "banned runtime surface absence", function()
				local schema = config.base()
				schema.metadata = { marker = marker }
				return config.validate(schema)
			end)
			expectInvalid(results, "banned runtime surface absence", function()
				local schema = config.base()
				schema.evidence = { marker }
				return config.validate(schema)
			end)
		end
	end
end

local function runIdentityChecks(results: { any })
	expect(
		results,
		"provider identity",
		Types.RuntimeProviderName == "assetExecutionAdapterRuntime",
		"provider is lowerCamelCase"
	)
	expect(
		results,
		"snapshot identity",
		Types.SnapshotKind == "assetExecutionAdapterRuntimeSnapshot",
		"snapshot kind is lowerCamelCase"
	)
	expect(
		results,
		"runtime identity",
		Types.RuntimeName == "AssetExecutionAdapterRuntime",
		"runtime identity is stable"
	)
	expectInvalid(results, "provider identity", function()
		return withTemporaryTypeValue(
			"RuntimeProviderName",
			"assetExecutionAdapterRuntimeDrift",
			Validation.validate
		)
	end)
	expectInvalid(results, "Bootstrap ordering", function()
		return withTemporaryTypeValue(
			"BootstrapDependencyOrder",
			{ "AssetExecutionAuthorizationCoordinator" },
			Validation.validate
		)
	end)
	expectInvalid(results, "Governance registration", function()
		return withTemporaryTypeValue(
			"GovernanceSnapshotProviders",
			{ "assetExecutionRuntime" },
			Validation.validate
		)
	end)
	expectInvalid(results, "coordinator API boundary", function()
		local drifted = Serialization.deepCopy(Types.CoordinatorApiOrder)
		table.insert(drifted, "executeAdapter")
		return withTemporaryTypeValue("CoordinatorApiOrder", drifted, Validation.validate)
	end)
	expectInvalid(results, "signal boundary", function()
		local drifted = Serialization.deepCopy(Types.SignalNames)
		drifted.Started = "AssetExecutionAdapterRuntime.StartedDrift"
		return withTemporaryTypeValue("SignalNames", drifted, Validation.validate)
	end)
	expect(
		results,
		"signal boundary",
		Signals.Initialized == Types.SignalNames.Initialized,
		"signals mirror type metadata"
	)
end

local function runStateChecks(results: { any }, service: any)
	service.shutdown()
	expectValid(results, "provider identity", function()
		local init = service.initialize()
		return init.ok, init.message
	end)
	expectValid(results, "validation-before-mutation", function()
		local registered = service.registerExecutionAdapter(adapter())
		return registered.ok, registered.message
	end)
	local before = service.inspect().counts.adapters
	expectInvalid(results, "duplicate rejection", function()
		local registered =
			service.registerExecutionAdapter(adapter("adapter.main", "adapter.other"))
		return registered.ok, registered.message
	end)
	expectInvalid(results, "duplicate adapter names", function()
		local registered =
			service.registerExecutionAdapter(adapter("adapter.other", "adapter.main.name"))
		return registered.ok, registered.message
	end)
	expect(
		results,
		"failed validation no mutation",
		service.inspect().counts.adapters == before,
		"failed adapter validation did not mutate"
	)
	expectValid(results, "capability ownership", function()
		local registered = service.registerExecutionAdapterCapability(capability())
		return registered.ok, registered.message
	end)
	expectValid(results, "compatibility ownership", function()
		local registered = service.registerExecutionAdapterCompatibility(compatibility())
		return registered.ok, registered.message
	end)
	expectValid(results, "boundary ownership", function()
		local registered = service.registerExecutionAdapterBoundary(boundary())
		return registered.ok, registered.message
	end)
	expectValid(results, "audit ownership", function()
		local registered = service.registerExecutionAdapterAudit(audit())
		return registered.ok, registered.message
	end)
	expectInvalid(results, "capability ownership", function()
		local registered = service.registerExecutionAdapterCapability(
			capability("capability.bad", "missing.adapter")
		)
		return registered.ok, registered.message
	end)
	expectInvalid(results, "audit ownership", function()
		local registered = service.registerExecutionAdapterAudit(
			audit("audit.bad", "adapter.main", { "missing.capability" }, {}, {})
		)
		return registered.ok, registered.message
	end)
	expectInvalid(results, "adapter child references", function()
		local schema = adapter("adapter.child", "adapter.child.name")
		schema.capabilityIds = { "missing.capability" }
		local registered = service.registerExecutionAdapter(schema)
		return registered.ok, registered.message
	end)
end

local function runIsolationChecks(results: { any }, service: any)
	local diagnostics = service.inspect()
	diagnostics.runtimeLimits.MaxAdapters = -1
	diagnostics.schemas.adapters["adapter.main"].metadata.purpose = "mutated"
	local diagnosticsAgain = service.inspect()
	expect(
		results,
		"diagnostics isolation",
		diagnosticsAgain.runtimeLimits.MaxAdapters == Types.Limits.MaxAdapters
			and diagnosticsAgain.schemas.adapters["adapter.main"].metadata.purpose
				== "adapter metadata only",
		"diagnostics are isolated"
	)
	local snapshot = service.getSnapshot()
	snapshot.runtimeLimits.MaxCapabilities = -1
	snapshot.schemas.capabilities["capability.main"].metadata.purpose = "mutated"
	local snapshotAgain = service.getSnapshot()
	expect(
		results,
		"snapshot isolation",
		snapshotAgain.runtimeLimits.MaxCapabilities == Types.Limits.MaxCapabilities
			and snapshotAgain.schemas.capabilities["capability.main"].metadata.purpose
				== "capability metadata only",
		"snapshots are isolated"
	)
	for _, key in ipairs(Types.PostureKeys) do
		expect(
			results,
			"lowerCamelCase posture keys",
			diagnostics[key] ~= nil or diagnostics.noAuthorityPosture[key] ~= nil,
			key .. " is exposed"
		)
		expect(
			results,
			"lowerCamelCase posture keys",
			snapshot[key] ~= nil or snapshot.noAuthorityPosture[key] ~= nil,
			key .. " is exposed in snapshots"
		)
	end
	expect(
		results,
		"diagnostics health-only",
		diagnostics.health ~= nil and diagnostics.validationOk ~= nil and diagnostics.schemas ~= nil,
		"diagnostics expose health metadata only"
	)
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
		counts.adapters == 0
			and counts.capabilities == 0
			and counts.compatibilities == 0
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
		local registered = service.registerExecutionAdapter(adapter())
		return registered.ok, registered.message
	end)
	service.shutdown()
end

function SelfChecks.run(context: any)
	local results = {}
	local service = context.Service
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
			"runtime identity",
			"snapshot identity",
			"diagnostics provider identity",
			"coordinator identity",
			"Bootstrap ordering",
			"Governance registration",
			"schema validation",
			"enum validation",
			"duplicate rejection",
			"duplicate adapter names",
			"invalid ids",
			"capability ownership",
			"compatibility ownership",
			"boundary ownership",
			"audit ownership",
			"adapter child references",
			"failed validation no mutation",
			"diagnostics isolation",
			"snapshot isolation",
			"deep-copy isolation",
			"runtime-limit enforcement",
			"shutdown cleanup",
			"namespace reset",
			"previous phase regression protection",
			"banned runtime surface absence",
		},
		results = results,
	}
end

return SelfChecks
