--!strict

local Serialization = require(script.Parent.AssetExecutionAuthorizationSerialization)
local Types = require(script.Parent.AssetExecutionAuthorizationTypes)
local Validation = require(script.Parent.AssetExecutionAuthorizationValidation)

local SelfChecks = {}

local function authorization(id: string?): any
	return {
		authorizationId = id or "authorization.main",
		governanceId = "governance.main",
		readinessId = "readiness.main",
		authorizationKind = "GovernanceAuthorization",
		authorizationStatus = "Satisfied",
		runtimeName = "AssetExecutionAuthorization",
		providerName = Types.RuntimeProviderName,
		snapshotProviderName = Types.RuntimeProviderName,
		requirementIds = {},
		evaluationIds = {},
		boundaryIds = {},
		auditIds = {},
		evidence = { "authorization.evidence" },
		tags = { "authorization" },
		metadata = { purpose = "schema-only authorization metadata" },
	}
end

local function requirement(id: string?, authorizationId: string?): any
	return {
		requirementId = id or "requirement.main",
		authorizationId = authorizationId or "authorization.main",
		requirementKind = "GovernanceRequirement",
		requirementStatus = "Satisfied",
		required = true,
		evidence = { "requirement.evidence" },
		tags = { "requirement" },
		metadata = { purpose = "authorization obligation metadata" },
	}
end

local function evaluation(id: string?, authorizationId: string?, requirementId: string?): any
	return {
		evaluationId = id or "evaluation.main",
		authorizationId = authorizationId or "authorization.main",
		requirementId = requirementId or "requirement.main",
		evaluationKind = "GovernanceEvaluation",
		evaluationStatus = "Passed",
		evaluator = "reviewer.main",
		evidence = { "evaluation.evidence" },
		tags = { "evaluation" },
		metadata = { purpose = "authorization evaluation metadata" },
	}
end

local function boundary(id: string?, authorizationId: string?): any
	return {
		boundaryId = id or "boundary.main",
		authorizationId = authorizationId or "authorization.main",
		boundaryKind = "NoAssetOperation",
		boundaryStatus = "Satisfied",
		summary = "No asset execution surface is introduced.",
		evidence = { "boundary.evidence" },
		tags = { "boundary" },
		metadata = { purpose = "authorization boundary metadata" },
	}
end

local function audit(
	id: string?,
	authorizationId: string?,
	evaluationIds: { string }?,
	boundaryIds: { string }?
): any
	return {
		auditId = id or "audit.main",
		authorizationId = authorizationId or "authorization.main",
		evaluationIds = evaluationIds or { "evaluation.main" },
		boundaryIds = boundaryIds or { "boundary.main" },
		auditKind = "AuthorizationAudit",
		auditStatus = "Passed",
		reviewer = "reviewer.main",
		evidence = { "audit.evidence" },
		tags = { "audit" },
		metadata = { purpose = "authorization audit metadata" },
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

local function validateConfigSchema(schema: any): (boolean, string?)
	if schema.authorizationId ~= nil then
		return Validation.authorization(schema)
	elseif schema.requirementId ~= nil then
		return Validation.requirement(schema)
	elseif schema.evaluationId ~= nil then
		return Validation.evaluation(schema)
	elseif schema.boundaryId ~= nil then
		return Validation.boundary(schema)
	end
	return Validation.audit(schema)
end

local function withTemporaryTypeValue(key: string, value: any, callback: () -> (boolean, string?))
	local previous = Types[key]
	Types[key] = value
	local ok, reason = callback()
	Types[key] = previous
	return ok, reason
end

local validators = {
	ExecutionAuthorization = {
		fields = Types.SchemaFields.ExecutionAuthorization,
		base = authorization,
		validate = Validation.authorization,
		idField = "authorizationId",
	},
	ExecutionAuthorizationRequirement = {
		fields = Types.SchemaFields.ExecutionAuthorizationRequirement,
		base = requirement,
		validate = Validation.requirement,
		idField = "requirementId",
	},
	ExecutionAuthorizationEvaluation = {
		fields = Types.SchemaFields.ExecutionAuthorizationEvaluation,
		base = evaluation,
		validate = Validation.evaluation,
		idField = "evaluationId",
	},
	ExecutionAuthorizationBoundary = {
		fields = Types.SchemaFields.ExecutionAuthorizationBoundary,
		base = boundary,
		validate = Validation.boundary,
		idField = "boundaryId",
	},
	ExecutionAuthorizationAudit = {
		fields = Types.SchemaFields.ExecutionAuthorizationAudit,
		base = audit,
		validate = Validation.audit,
		idField = "auditId",
	},
}

local function runSchemaFieldChecks(results: { any })
	for schemaName, config in pairs(validators) do
		expectValid(results, "schema terminology", function()
			return config.validate(config.base())
		end)
		for _, fieldName in ipairs(config.fields) do
			expectInvalid(results, "schema terminology", function()
				local schema = config.base()
				schema[fieldName] = nil
				return config.validate(schema)
			end)
			expectInvalid(results, "schema terminology", function()
				local schema = config.base()
				schema[fieldName .. "Drift"] = schema[fieldName]
				return config.validate(schema)
			end)
		end
		expectInvalid(results, "schema terminology", function()
			local schema = config.base()
			schema.unsupportedField = "unsupported"
			return config.validate(schema)
		end)
		expectInvalid(results, "schema terminology", function()
			local schema = config.base()
			schema[config.idField] = "invalid id with spaces"
			return config.validate(schema)
		end)
		expect(
			results,
			"schema terminology",
			Types.SchemaFieldCount[schemaName] == #config.fields,
			schemaName .. " field count matches"
		)
	end
end

local function runEnumChecks(results: { any })
	for value in pairs(Types.AuthorizationKind) do
		local schema = authorization()
		schema.authorizationKind = value
		expectValid(results, "kind/status validation", function()
			return Validation.authorization(schema)
		end)
	end
	for value in pairs(Types.AuthorizationStatus) do
		local schema = authorization()
		schema.authorizationStatus = value
		expectValid(results, "kind/status validation", function()
			return Validation.authorization(schema)
		end)
	end
	for value in pairs(Types.RequirementKind) do
		local schema = requirement()
		schema.requirementKind = value
		expectValid(results, "kind/status validation", function()
			return Validation.requirement(schema)
		end)
	end
	for value in pairs(Types.RequirementStatus) do
		local schema = requirement()
		schema.requirementStatus = value
		expectValid(results, "kind/status validation", function()
			return Validation.requirement(schema)
		end)
	end
	for value in pairs(Types.EvaluationKind) do
		local schema = evaluation()
		schema.evaluationKind = value
		expectValid(results, "kind/status validation", function()
			return Validation.evaluation(schema)
		end)
	end
	for value in pairs(Types.EvaluationStatus) do
		local schema = evaluation()
		schema.evaluationStatus = value
		expectValid(results, "kind/status validation", function()
			return Validation.evaluation(schema)
		end)
	end
	for value in pairs(Types.BoundaryKind) do
		local schema = boundary()
		schema.boundaryKind = value
		expectValid(results, "kind/status validation", function()
			return Validation.boundary(schema)
		end)
	end
	for value in pairs(Types.BoundaryStatus) do
		local schema = boundary()
		schema.boundaryStatus = value
		expectValid(results, "kind/status validation", function()
			return Validation.boundary(schema)
		end)
	end
	for value in pairs(Types.AuditKind) do
		local schema = audit()
		schema.auditKind = value
		expectValid(results, "kind/status validation", function()
			return Validation.audit(schema)
		end)
	end
	for value in pairs(Types.AuditStatus) do
		local schema = audit()
		schema.auditStatus = value
		expectValid(results, "kind/status validation", function()
			return Validation.audit(schema)
		end)
	end
	for _, drift in ipairs({
		{ authorization(), "authorizationKind" },
		{ authorization(), "authorizationStatus" },
		{ requirement(), "requirementKind" },
		{ requirement(), "requirementStatus" },
		{ evaluation(), "evaluationKind" },
		{ evaluation(), "evaluationStatus" },
		{ boundary(), "boundaryKind" },
		{ boundary(), "boundaryStatus" },
		{ audit(), "auditKind" },
		{ audit(), "auditStatus" },
	}) do
		expectInvalid(results, "kind/status validation", function()
			local schema = drift[1]
			schema[drift[2]] = "UnsupportedValue"
			if schema.authorizationId ~= nil then
				return Validation.authorization(schema)
			elseif schema.requirementId ~= nil then
				return Validation.requirement(schema)
			elseif schema.evaluationId ~= nil then
				return Validation.evaluation(schema)
			elseif schema.boundaryId ~= nil then
				return Validation.boundary(schema)
			end
			return Validation.audit(schema)
		end)
	end
end

local function runPayloadChecks(results: { any })
	for _, config in pairs(validators) do
		for _, fieldName in ipairs({ "evidence", "tags" }) do
			expectInvalid(results, "bounded payload validation", function()
				local schema = config.base()
				schema[fieldName] = { "duplicate", "duplicate" }
				return config.validate(schema)
			end)
			expectInvalid(results, "bounded payload validation", function()
				local schema = config.base()
				schema[fieldName] = { [2] = "sparse" }
				return config.validate(schema)
			end)
			expectInvalid(results, "ordering validation", function()
				local schema = config.base()
				schema[fieldName] = { "z.drift", "a.drift" }
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
				schema.metadata = { nested = { marker = marker } }
				return config.validate(schema)
			end)
			expectInvalid(results, "banned runtime surface absence", function()
				local schema = config.base()
				schema.metadata = { [marker] = "unsafe" }
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
		expectInvalid(results, "bounded payload validation", function()
			local schema = config.base()
			schema.metadata = { ClassName = "Part", Parent = {} }
			return config.validate(schema)
		end)
		expectInvalid(results, "bounded payload validation", function()
			local schema = config.base()
			schema.metadata = { oversized = string.rep("x", Types.Limits.MaxStringLength + 1) }
			return config.validate(schema)
		end)
		expectInvalid(results, "bounded payload validation", function()
			local schema = config.base()
			schema.evidence = {}
			for index = 1, Types.Limits.MaxEvidence + 1 do
				table.insert(schema.evidence, string.format("evidence.%03d", index))
			end
			return config.validate(schema)
		end)
		expectInvalid(results, "bounded payload validation", function()
			local schema = config.base()
			schema.tags = {}
			for index = 1, Types.Limits.MaxTags + 1 do
				table.insert(schema.tags, string.format("tag.%03d", index))
			end
			return config.validate(schema)
		end)
		expectInvalid(results, "serialization isolation", function()
			local schema = config.base()
			schema.metadata = {}
			schema.metadata.self = schema.metadata
			return config.validate(schema)
		end)
	end
end

local function runIdentityDriftChecks(results: { any })
	for _, drift in ipairs({
		{ key = "RuntimeProviderName", value = "assetExecutionAuthorizationRuntimeDrift" },
		{ key = "SnapshotKind", value = "assetExecutionAuthorizationRuntimeSnapshotDrift" },
		{ key = "RuntimeName", value = "AssetExecutionAuthorizationDrift" },
		{ key = "CoordinatorName", value = "AssetExecutionAuthorizationCoordinatorDrift" },
	}) do
		expectInvalid(results, "identity drift", function()
			return withTemporaryTypeValue(drift.key, drift.value, Validation.validate)
		end)
	end
	expectInvalid(results, "documentation drift", function()
		local drifted = Serialization.deepCopy(Types.DocumentationFiles)
		drifted[1] = "UNSUPPORTED_AUTHORIZATION_DOC.md"
		return withTemporaryTypeValue("DocumentationFiles", drifted, Validation.validate)
	end)
	expectInvalid(results, "documentation drift", function()
		local drifted = Serialization.deepCopy(Types.DocumentationFiles)
		table.remove(drifted, 1)
		return withTemporaryTypeValue("DocumentationFiles", drifted, Validation.validate)
	end)
	expectInvalid(results, "documentation drift", function()
		local drifted = Serialization.deepCopy(Types.DocumentationFiles)
		drifted[1], drifted[2] = drifted[2], drifted[1]
		return withTemporaryTypeValue("DocumentationFiles", drifted, Validation.validate)
	end)
	expectInvalid(results, "Bootstrap ordering", function()
		return withTemporaryTypeValue(
			"BootstrapDependencyOrder",
			{ "AssetExecutionAuthorizationCoordinator" },
			Validation.validate
		)
	end)
	expectInvalid(results, "Governance ordering", function()
		return withTemporaryTypeValue(
			"GovernanceSnapshotProviders",
			{ "assetExecutionAuthorizationRuntimeDrift" },
			Validation.validate
		)
	end)
end

local function runArrayHardeningChecks(results: { any })
	local sortedAuthorization = authorization()
	sortedAuthorization.requirementIds = { "requirement.a", "requirement.b" }
	sortedAuthorization.evaluationIds = { "evaluation.a", "evaluation.b" }
	sortedAuthorization.boundaryIds = { "boundary.a", "boundary.b" }
	sortedAuthorization.auditIds = { "audit.a", "audit.b" }
	expectValid(results, "ordering validation", function()
		return Validation.authorization(sortedAuthorization)
	end)
	for _, fieldName in ipairs({ "requirementIds", "evaluationIds", "boundaryIds", "auditIds" }) do
		expectInvalid(results, "ordering validation", function()
			local schema = authorization()
			schema[fieldName] = { fieldName .. ".b", fieldName .. ".a" }
			return Validation.authorization(schema)
		end)
		expectInvalid(results, "duplicate rejection", function()
			local schema = authorization()
			schema[fieldName] = { fieldName .. ".a", fieldName .. ".a" }
			return Validation.authorization(schema)
		end)
		expectInvalid(results, "partial replacement", function()
			local schema = authorization()
			schema[fieldName] = nil
			return Validation.authorization(schema)
		end)
	end
	for _, fieldName in ipairs({ "evaluationIds", "boundaryIds" }) do
		expectInvalid(results, "ordering validation", function()
			local schema = audit("audit.order")
			schema[fieldName] = { fieldName .. ".b", fieldName .. ".a" }
			return Validation.audit(schema)
		end)
		expectInvalid(results, "duplicate rejection", function()
			local schema = audit("audit.duplicate")
			schema[fieldName] = { fieldName .. ".a", fieldName .. ".a" }
			return Validation.audit(schema)
		end)
	end
	for _, config in pairs(validators) do
		expectInvalid(results, "unsafe metadata", function()
			local schema = config.base()
			schema.metadata = { ["unsafe key with spaces"] = "value" }
			return validateConfigSchema(schema)
		end)
		expectInvalid(results, "unsafe metadata", function()
			local schema = config.base()
			schema.metadata = { nested = { permissionGrant = "value" } }
			return validateConfigSchema(schema)
		end)
	end
end

local function runStateChecks(results: { any }, service: any)
	service.shutdown()
	expectValid(results, "provider name consistency", function()
		local init = service.initialize()
		return init.ok, init.message
	end)
	expectValid(results, "readiness child references", function()
		local registered = service.registerExecutionAuthorization(authorization())
		return registered.ok, registered.message
	end)
	local before = service.inspect().counts.authorizations
	expectInvalid(results, "failed validation no mutation", function()
		local registered =
			service.registerExecutionAuthorization(authorization("authorization.main"))
		return registered.ok, registered.message
	end)
	expect(
		results,
		"failed validation no mutation",
		service.inspect().counts.authorizations == before,
		"duplicate authorization does not mutate"
	)
	expectValid(results, "readiness child references", function()
		local registered = service.registerExecutionAuthorizationRequirement(requirement())
		return registered.ok, registered.message
	end)
	expectValid(results, "readiness child references", function()
		local registered = service.registerExecutionAuthorizationEvaluation(evaluation())
		return registered.ok, registered.message
	end)
	expectValid(results, "readiness child references", function()
		local registered = service.registerExecutionAuthorizationBoundary(boundary())
		return registered.ok, registered.message
	end)
	expectValid(results, "readiness child references", function()
		local registered = service.registerExecutionAuthorizationAudit(audit())
		return registered.ok, registered.message
	end)
	local counts = service.inspect().counts
	expect(
		results,
		"readiness child references",
		counts.authorizations == 1
			and counts.requirements == 1
			and counts.evaluations == 1
			and counts.boundaries == 1
			and counts.audits == 1,
		"all schema counts recorded"
	)
	expectInvalid(results, "readiness child references", function()
		local registered =
			service.registerExecutionAuthorizationRequirement(requirement("missing", "missing"))
		return registered.ok, registered.message
	end)
	expectInvalid(results, "readiness child references", function()
		local registered = service.registerExecutionAuthorizationEvaluation(
			evaluation("bad", "authorization.main", "missing")
		)
		return registered.ok, registered.message
	end)
	expectInvalid(results, "readiness child references", function()
		local registered = service.registerExecutionAuthorizationAudit(
			audit("bad", "authorization.main", { "missing" }, {})
		)
		return registered.ok, registered.message
	end)
end

local function runIsolationChecks(results: { any }, service: any)
	local diagnostics = service.inspect()
	diagnostics.runtimeLimits.MaxAuthorizations = -1
	diagnostics.schemas.authorizations["authorization.main"].metadata.purpose = "mutated"
	local diagnosticsAgain = service.inspect()
	expect(
		results,
		"snapshot isolation",
		diagnosticsAgain.runtimeLimits.MaxAuthorizations == Types.Limits.MaxAuthorizations
			and diagnosticsAgain.schemas.authorizations["authorization.main"].metadata.purpose
				== "schema-only authorization metadata",
		"diagnostics are isolated"
	)
	local snapshot = service.getSnapshot()
	snapshot.runtimeLimits.MaxRequirements = -1
	snapshot.schemas.requirements["requirement.main"].metadata.purpose = "mutated"
	local snapshotAgain = service.getSnapshot()
	expect(
		results,
		"snapshot isolation",
		snapshotAgain.runtimeLimits.MaxRequirements == Types.Limits.MaxRequirements
			and snapshotAgain.schemas.requirements["requirement.main"].metadata.purpose
				== "authorization obligation metadata",
		"snapshots are isolated"
	)
	for _, key in ipairs(Types.PostureKeys) do
		expect(
			results,
			"lowerCamelCase posture keys",
			diagnostics[key] ~= nil or diagnostics.noAuthorityPosture[key] ~= nil,
			key .. " is exposed"
		)
	end
	expect(
		results,
		"diagnostics health-only",
		diagnostics.providerPosture == Types.RuntimeProviderName
			and diagnostics.snapshotPosture == Types.SnapshotKind
			and diagnostics.runtimeName == Types.RuntimeName
			and diagnostics.coordinatorName == Types.CoordinatorName
			and diagnostics.health == "Healthy"
			and diagnostics.noExecution == true
			and diagnostics.noAuthorityEscalation == true,
		"diagnostics expose health posture only"
	)
	diagnostics.governanceSnapshotProviders[1] = "mutated"
	diagnostics.identityOrder[1] = "mutated"
	local identityAgain = service.inspect()
	expect(
		results,
		"runtime-limit isolation",
		identityAgain.governanceSnapshotProviders[1] == Types.RuntimeProviderName
			and identityAgain.identityOrder[1] == "AssetExecutionGovernanceCoordinator",
		"identity arrays are isolated"
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
		counts.authorizations == 0
			and counts.requirements == 0
			and counts.evaluations == 0
			and counts.boundaries == 0
			and counts.audits == 0
			and counts.validationFailures == 0
			and counts.snapshots == 0,
		"shutdown clears state"
	)
end

function SelfChecks.run(context: any)
	local results = {}
	local service = context.Service
	expect(
		results,
		"provider name consistency",
		Types.RuntimeProviderName == "assetExecutionAuthorizationRuntime",
		"provider name is lowerCamelCase"
	)
	expect(
		results,
		"provider name consistency",
		Types.SnapshotKind == "assetExecutionAuthorizationRuntimeSnapshot",
		"snapshot kind is lowerCamelCase"
	)
	expect(
		results,
		"provider name consistency",
		Types.BootstrapDependencyOrder[1] == "AssetExecutionGovernanceCoordinator",
		"Bootstrap dependency follows Asset Execution Governance"
	)
	runSchemaFieldChecks(results)
	runEnumChecks(results)
	runPayloadChecks(results)
	runIdentityDriftChecks(results)
	runArrayHardeningChecks(results)
	runStateChecks(results, service)
	runIsolationChecks(results, service)
	runCleanupChecks(results, service)
	local failures = countFailures(results)
	return {
		ok = failures == 0,
		total = #results,
		failures = failures,
		categories = {
			"provider name consistency",
			"schema terminology consistency",
			"readinessKind/readinessStatus equivalent authorization kind/status validation",
			"checklistKind equivalent requirement validation",
			"gapKind/severity equivalent boundary and audit validation",
			"readiness child references equivalent authorization child references",
			"failed validation no mutation",
			"snapshot isolation",
			"diagnostics health-only",
			"lowerCamelCase posture keys",
			"shutdown cleanup",
			"banned runtime surface absence",
		},
		results = results,
	}
end

return SelfChecks
