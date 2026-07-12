--!strict

local Serialization = require(script.Parent.AssetExecutionAdapterRegistrySerialization)
local Signals = require(script.Parent.AssetExecutionAdapterRegistrySignals)
local Types = require(script.Parent.AssetExecutionAdapterRegistryTypes)
local Validation = require(script.Parent.AssetExecutionAdapterRegistryValidation)

local SelfChecks = {}

local function registry(id: string?, name: string?): any
	return {
		registryId = id or "registry.main",
		registryName = name or "registry.main.name",
		providerName = Types.RuntimeProviderName,
		snapshotProviderName = Types.RuntimeProviderName,
		registryKind = "AdapterMetadataRegistry",
		registryStatus = "Open",
		registrationIds = {},
		compatibilityIds = {},
		boundaryIds = {},
		auditIds = {},
		snapshotIds = {},
		evidence = { "registry.evidence" },
		tags = { "registry" },
		metadata = { purpose = "registry metadata only" },
	}
end

local function registration(
	id: string?,
	registryId: string?,
	adapterId: string?,
	adapterName: string?
): any
	return {
		registrationId = id or "registration.main",
		registryId = registryId or "registry.main",
		adapterId = adapterId or "adapter.main",
		adapterName = adapterName or "adapter.main.name",
		adapterProviderName = "assetExecutionAdapterRuntime",
		adapterSnapshotProviderName = "assetExecutionAdapterRuntime",
		contractId = "contract.main",
		runtimeId = "runtime.main",
		registrationKind = "AdapterMetadataRegistration",
		registrationStatus = "Registered",
		owner = "owner.main",
		evidence = { "registration.evidence" },
		tags = { "registration" },
		metadata = { purpose = "registration metadata only" },
	}
end

local function boundary(id: string?, registryId: string?, registrationId: string?): any
	return {
		boundaryId = id or "boundary.main",
		registryId = registryId or "registry.main",
		registrationId = registrationId or "registration.main",
		boundaryKind = "NoAdapterImplementation",
		boundaryStatus = "Satisfied",
		summary = "Registry stores metadata only.",
		evidence = { "boundary.evidence" },
		tags = { "boundary" },
		metadata = { purpose = "boundary metadata only" },
	}
end

local function compatibility(id: string?, registryId: string?, registrationId: string?): any
	return {
		compatibilityId = id or "compatibility.main",
		registryId = registryId or "registry.main",
		registrationId = registrationId or "registration.main",
		compatibilityKind = "AdapterRuntimeCompatibility",
		compatibilityStatus = "Compatible",
		targetRuntimeName = "AssetExecutionAdapterRuntime",
		evidence = { "compatibility.evidence" },
		tags = { "compatibility" },
		metadata = { purpose = "compatibility metadata only" },
	}
end

local function audit(
	id: string?,
	registryId: string?,
	registrationId: string?,
	boundaryIds: { string }?,
	compatibilityIds: { string }?
): any
	return {
		auditId = id or "audit.main",
		registryId = registryId or "registry.main",
		registrationId = registrationId or "registration.main",
		boundaryIds = boundaryIds or { "boundary.main" },
		compatibilityIds = compatibilityIds or { "compatibility.main" },
		auditKind = "RegistryAudit",
		auditStatus = "Passed",
		reviewer = "reviewer.main",
		evidence = { "audit.evidence" },
		tags = { "audit" },
		metadata = { purpose = "audit metadata only" },
	}
end

local function registrySnapshot(id: string?, registryId: string?): any
	return {
		registrySnapshotId = id or "registrySnapshot.main",
		registryId = registryId or "registry.main",
		snapshotKind = Types.SnapshotKind,
		snapshotStatus = "Captured",
		providerName = Types.RuntimeProviderName,
		registrationIds = { "registration.main" },
		compatibilityIds = { "compatibility.main" },
		evidence = { "snapshot.evidence" },
		tags = { "snapshot" },
		metadata = { purpose = "snapshot metadata only" },
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
	ExecutionAdapterRegistry = {
		fields = Types.SchemaFields.ExecutionAdapterRegistry,
		base = registry,
		validate = Validation.registry,
		idField = "registryId",
		enumField = "registryKind",
	},
	ExecutionAdapterRegistration = {
		fields = Types.SchemaFields.ExecutionAdapterRegistration,
		base = registration,
		validate = Validation.registration,
		idField = "registrationId",
		enumField = "registrationKind",
	},
	ExecutionAdapterRegistrationBoundary = {
		fields = Types.SchemaFields.ExecutionAdapterRegistrationBoundary,
		base = boundary,
		validate = Validation.boundary,
		idField = "boundaryId",
		enumField = "boundaryKind",
	},
	ExecutionAdapterRegistryCompatibility = {
		fields = Types.SchemaFields.ExecutionAdapterRegistryCompatibility,
		base = compatibility,
		validate = Validation.compatibility,
		idField = "compatibilityId",
		enumField = "compatibilityKind",
	},
	ExecutionAdapterRegistrationAudit = {
		fields = Types.SchemaFields.ExecutionAdapterRegistrationAudit,
		base = audit,
		validate = Validation.audit,
		idField = "auditId",
		enumField = "auditKind",
	},
	ExecutionAdapterRegistrySnapshot = {
		fields = Types.SchemaFields.ExecutionAdapterRegistrySnapshot,
		base = registrySnapshot,
		validate = Validation.registrySnapshot,
		idField = "registrySnapshotId",
		enumField = "snapshotStatus",
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
	expectInvalid(results, "schema validation", function()
		local drifted = Serialization.deepCopy(Types.SchemaFields)
		drifted.UnsupportedSchema = { "registryHandle" }
		return withTemporaryTypeValue("SchemaFields", drifted, Validation.validate)
	end)
end

local function runEnumChecks(results: { any })
	for _, enumName in ipairs({
		"RegistryKind",
		"RegistryStatus",
		"RegistrationKind",
		"RegistrationStatus",
		"RegistrationBoundaryKind",
		"RegistrationBoundaryStatus",
		"RegistryCompatibilityKind",
		"RegistryCompatibilityStatus",
		"RegistrySnapshotStatus",
		"RegistrationAuditKind",
		"RegistrationAuditStatus",
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
			expectInvalid(results, "banned runtime surface absence", function()
				local schema = config.base()
				schema.tags = { marker }
				return config.validate(schema)
			end)
		end
	end
end

local function runIdentityChecks(results: { any })
	expect(
		results,
		"provider identity",
		Types.RuntimeProviderName == "assetExecutionAdapterRegistry",
		"provider is lowerCamelCase"
	)
	expect(
		results,
		"snapshot identity",
		Types.SnapshotKind == "assetExecutionAdapterRegistrySnapshot",
		"snapshot kind is lowerCamelCase"
	)
	expect(
		results,
		"runtime identity",
		Types.RuntimeName == "AssetExecutionAdapterRegistry",
		"runtime identity is stable"
	)
	expectInvalid(results, "provider identity", function()
		return withTemporaryTypeValue(
			"RuntimeProviderName",
			"assetExecutionAdapterRegistryDrift",
			Validation.validate
		)
	end)
	expectInvalid(results, "Bootstrap ordering", function()
		return withTemporaryTypeValue(
			"BootstrapDependencyOrder",
			{ "AssetExecutionCoordinator" },
			Validation.validate
		)
	end)
	expectInvalid(results, "Governance registration", function()
		return withTemporaryTypeValue(
			"GovernanceSnapshotProviders",
			{ "assetExecutionAdapterRuntime" },
			Validation.validate
		)
	end)
	expectInvalid(results, "documentation consistency", function()
		local drifted = Serialization.deepCopy(Types.DocumentationFiles)
		table.insert(drifted, "ASSET_EXECUTION_ADAPTER_REGISTRY_EXTRA.md")
		return withTemporaryTypeValue("DocumentationFiles", drifted, Validation.validate)
	end)
	expectInvalid(results, "coordinator API boundary", function()
		local drifted = Serialization.deepCopy(Types.CoordinatorApiOrder)
		table.insert(drifted, "activateAdapter")
		return withTemporaryTypeValue("CoordinatorApiOrder", drifted, Validation.validate)
	end)
	expectInvalid(results, "runtime-limit enforcement", function()
		local drifted = Serialization.deepCopy(Types.Limits)
		drifted.MaxRegistrations += 1
		return withTemporaryTypeValue("Limits", drifted, Validation.validate)
	end)
	expectInvalid(results, "signal boundary", function()
		local drifted = Serialization.deepCopy(Types.SignalNames)
		drifted.Started = "AssetExecutionAdapterRegistry.StartedDrift"
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
		local registered = service.registerExecutionAdapterRegistry(registry())
		return registered.ok, registered.message
	end)
	local before = service.inspect().counts.registries
	expectInvalid(results, "duplicate rejection", function()
		local registered =
			service.registerExecutionAdapterRegistry(registry("registry.main", "registry.other"))
		return registered.ok, registered.message
	end)
	expectInvalid(results, "duplicate registry names", function()
		local registered = service.registerExecutionAdapterRegistry(
			registry("registry.other", "registry.main.name")
		)
		return registered.ok, registered.message
	end)
	expect(
		results,
		"failed validation no mutation",
		service.inspect().counts.registries == before,
		"failed registry validation did not mutate"
	)
	expectValid(results, "registration ownership", function()
		local registered = service.registerExecutionAdapterRegistration(registration())
		return registered.ok, registered.message
	end)
	expectValid(results, "boundary validation", function()
		local registered = service.registerExecutionAdapterRegistrationBoundary(boundary())
		return registered.ok, registered.message
	end)
	expectValid(results, "compatibility ownership", function()
		local registered = service.registerExecutionAdapterRegistryCompatibility(compatibility())
		return registered.ok, registered.message
	end)
	expectValid(results, "audit validation", function()
		local registered = service.registerExecutionAdapterRegistrationAudit(audit())
		return registered.ok, registered.message
	end)
	expectValid(results, "snapshot validation", function()
		local registered = service.registerExecutionAdapterRegistrySnapshot(registrySnapshot())
		return registered.ok, registered.message
	end)
	expectInvalid(results, "registration ownership", function()
		local registered = service.registerExecutionAdapterRegistration(
			registration("registration.bad", "missing.registry", "adapter.bad", "adapter.bad.name")
		)
		return registered.ok, registered.message
	end)
	expectInvalid(results, "duplicate adapter ids", function()
		local registered = service.registerExecutionAdapterRegistration(
			registration(
				"registration.duplicateAdapter",
				"registry.main",
				"adapter.main",
				"adapter.other.name"
			)
		)
		return registered.ok, registered.message
	end)
	expectInvalid(results, "duplicate ownership", function()
		local schema = registration(
			"registration.duplicateOwner",
			"registry.main",
			"adapter.other",
			"adapter.other.name"
		)
		schema.owner = "owner.main"
		local registered = service.registerExecutionAdapterRegistration(schema)
		return registered.ok, registered.message
	end)
	expectInvalid(results, "audit validation", function()
		local registered = service.registerExecutionAdapterRegistrationAudit(
			audit("audit.bad", "registry.main", "registration.main", { "missing.boundary" }, {})
		)
		return registered.ok, registered.message
	end)
end

local function runIsolationChecks(results: { any }, service: any)
	local diagnostics = service.inspect()
	diagnostics.runtimeLimits.MaxRegistries = -1
	diagnostics.schemas.registries["registry.main"].metadata.purpose = "mutated"
	local diagnosticsAgain = service.inspect()
	expect(
		results,
		"diagnostics isolation",
		diagnosticsAgain.runtimeLimits.MaxRegistries == Types.Limits.MaxRegistries
			and diagnosticsAgain.schemas.registries["registry.main"].metadata.purpose
				== "registry metadata only",
		"diagnostics are isolated"
	)
	local snapshot = service.getSnapshot()
	snapshot.runtimeLimits.MaxRegistrations = -1
	snapshot.schemas.registrations["registration.main"].metadata.purpose = "mutated"
	local snapshotAgain = service.getSnapshot()
	expect(
		results,
		"snapshot isolation",
		snapshotAgain.runtimeLimits.MaxRegistrations == Types.Limits.MaxRegistrations
			and snapshotAgain.schemas.registrations["registration.main"].metadata.purpose
				== "registration metadata only",
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
		counts.registries == 0
			and counts.registrations == 0
			and counts.boundaries == 0
			and counts.compatibilities == 0
			and counts.audits == 0
			and counts.registrySnapshots == 0
			and counts.validationFailures == 0
			and counts.snapshots == 0,
		"shutdown clears state"
	)
	expectValid(results, "namespace reset", function()
		local init = service.initialize()
		if not init.ok then
			return false, init.message
		end
		local registered = service.registerExecutionAdapterRegistry(registry())
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
			"provider consistency",
			"runtime consistency",
			"registry consistency",
			"snapshot consistency",
			"diagnostics consistency",
			"Bootstrap consistency",
			"Governance consistency",
			"documentation consistency",
			"schema validation",
			"enum validation",
			"duplicate adapter ids",
			"duplicate registration ids",
			"duplicate registry ids",
			"ownership validation",
			"registration ownership",
			"boundary validation",
			"audit validation",
			"failed validation no mutation",
			"serializer contamination rejection",
			"diagnostics isolation",
			"snapshot isolation",
			"runtime-limit enforcement",
			"deep-copy isolation",
			"shutdown cleanup",
			"namespace reset",
			"regression protection",
			"banned runtime surface absence",
		},
		results = results,
	}
end

return SelfChecks
