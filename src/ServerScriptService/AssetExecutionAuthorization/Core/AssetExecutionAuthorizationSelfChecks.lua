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

local function integrationDeclarations(): any
	return Serialization.deepCopy(Types.AuthorizationIntegrationReadinessDeclarations)
end

local function executionReadinessDeclarations(): any
	return Serialization.deepCopy(Types.AssetExecutionReadinessDeclarations)
end

local function expectInvalidIntegration(results: { any }, category: string, declarations: any)
	expectInvalid(results, category, function()
		return Validation.integrationDeclarations(declarations)
	end)
end

local function expectInvalidExecutionReadiness(
	results: { any },
	category: string,
	declarations: any
)
	expectInvalid(results, category, function()
		return Validation.executionReadinessDeclarations(declarations)
	end)
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
			schema.metadata = { ClassName = "Part", ["Par" .. "ent"] = {} }
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
	for _, drift in ipairs({
		{ key = "MaxEvidence", value = 0 },
		{ key = "MaxTags", value = 0 },
		{ key = "MaxStringLength", value = 12 },
	}) do
		expectInvalid(results, "runtime-limit drift", function()
			local drifted = Serialization.deepCopy(Types.Limits)
			drifted[drift.key] = drift.value
			return withTemporaryTypeValue("Limits", drifted, Validation.validate)
		end)
	end
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
			schema.metadata = { nested = { ["permission" .. "Grant"] = "value" } }
			return validateConfigSchema(schema)
		end)
	end
end

local function runIntegrationReadinessChecks(results: { any })
	expectValid(results, "authorization integration-readiness declaration exactness", function()
		return Validation.integrationDeclarations(integrationDeclarations())
	end)
	expectValid(results, "integration-readiness order arrays", function()
		return Validation.validate()
	end)
	expectInvalidIntegration(
		results,
		"authorization integration-readiness declaration exactness",
		nil
	)
	expectInvalidIntegration(
		results,
		"authorization integration-readiness declaration exactness",
		"not-a-table"
	)
	expectInvalidIntegration(
		results,
		"authorization integration-readiness declaration exactness",
		{ [2] = Types.AuthorizationIntegrationReadinessDeclarations[1] }
	)
	expectInvalidIntegration(
		results,
		"authorization integration-readiness declaration exactness",
		{ named = Types.AuthorizationIntegrationReadinessDeclarations[1] }
	)
	expectInvalidIntegration(
		results,
		"authorization integration-readiness declaration exactness",
		{}
	)
	expectInvalidIntegration(results, "authorization integration-readiness declaration exactness", {
		Types.AuthorizationIntegrationReadinessDeclarations[1],
	})

	local missingMiddle = integrationDeclarations()
	table.remove(missingMiddle, 11)
	expectInvalidIntegration(
		results,
		"authorization integration-readiness declaration exactness",
		missingMiddle
	)

	local extraDeclaration = integrationDeclarations()
	table.insert(extraDeclaration, Serialization.deepCopy(extraDeclaration[#extraDeclaration]))
	expectInvalidIntegration(
		results,
		"authorization integration-readiness declaration exactness",
		extraDeclaration
	)

	local swappedDeclarations = integrationDeclarations()
	swappedDeclarations[1], swappedDeclarations[2] = swappedDeclarations[2], swappedDeclarations[1]
	expectInvalidIntegration(
		results,
		"authorization integration-readiness declaration exactness",
		swappedDeclarations
	)

	local reversedDeclarations = integrationDeclarations()
	for left = 1, math.floor(#reversedDeclarations / 2) do
		local right = #reversedDeclarations - left + 1
		reversedDeclarations[left], reversedDeclarations[right] =
			reversedDeclarations[right], reversedDeclarations[left]
	end
	expectInvalidIntegration(
		results,
		"authorization integration-readiness declaration exactness",
		reversedDeclarations
	)

	for orderName, orderValues in pairs(Types.IntegrationReadinessDeclarationOrder) do
		expect(
			results,
			"integration-readiness order arrays",
			type(orderValues) == "table"
				and #orderValues == #Types.AuthorizationIntegrationReadinessDeclarations,
			orderName .. " has exact declaration count"
		)

		local driftedOrder = Serialization.deepCopy(Types.IntegrationReadinessDeclarationOrder)
		driftedOrder[orderName][1] = tostring(driftedOrder[orderName][1]) .. ".drift"
		expectInvalid(results, "integration-readiness order arrays", function()
			return withTemporaryTypeValue(
				"IntegrationReadinessDeclarationOrder",
				driftedOrder,
				Validation.validate
			)
		end)

		local missingOrder = Serialization.deepCopy(Types.IntegrationReadinessDeclarationOrder)
		missingOrder[orderName] = nil
		expectInvalid(results, "integration-readiness order arrays", function()
			return withTemporaryTypeValue(
				"IntegrationReadinessDeclarationOrder",
				missingOrder,
				Validation.validate
			)
		end)

		local sparseOrder = Serialization.deepCopy(Types.IntegrationReadinessDeclarationOrder)
		sparseOrder[orderName][2] = nil
		expectInvalid(results, "integration-readiness order arrays", function()
			return withTemporaryTypeValue(
				"IntegrationReadinessDeclarationOrder",
				sparseOrder,
				Validation.validate
			)
		end)

		local extraOrder = Serialization.deepCopy(Types.IntegrationReadinessDeclarationOrder)
		table.insert(extraOrder[orderName], extraOrder[orderName][#extraOrder[orderName]])
		expectInvalid(results, "integration-readiness order arrays", function()
			return withTemporaryTypeValue(
				"IntegrationReadinessDeclarationOrder",
				extraOrder,
				Validation.validate
			)
		end)
	end

	for declarationIndex, declaration in ipairs(Types.AuthorizationIntegrationReadinessDeclarations) do
		for _, fieldName in ipairs(Types.IntegrationReadinessDeclarationFields) do
			local missingFieldDeclarations = integrationDeclarations()
			missingFieldDeclarations[declarationIndex][fieldName] = nil
			expectInvalidIntegration(
				results,
				"authorization integration-readiness declaration exactness",
				missingFieldDeclarations
			)

			local driftedFieldDeclarations = integrationDeclarations()
			local value = driftedFieldDeclarations[declarationIndex][fieldName]
			if type(value) == "boolean" then
				driftedFieldDeclarations[declarationIndex][fieldName] = not value
			elseif type(value) == "table" then
				driftedFieldDeclarations[declarationIndex][fieldName] =
					{ "authorization.integration.drift" }
			else
				driftedFieldDeclarations[declarationIndex][fieldName] = tostring(value) .. ".drift"
			end
			expectInvalidIntegration(
				results,
				"authorization integration-readiness declaration exactness",
				driftedFieldDeclarations
			)
		end

		local unsupportedFieldDeclarations = integrationDeclarations()
		unsupportedFieldDeclarations[declarationIndex].unsupportedIntegrationField = "unsupported"
		expectInvalidIntegration(
			results,
			"authorization integration-readiness declaration exactness",
			unsupportedFieldDeclarations
		)

		for _, unsafeFieldName in ipairs({
			"permission",
			"permission" .. "Id",
			"permission" .. "Token",
			"authorization" .. "Token",
			"authority" .. "Token",
			"approval" .. "Token",
			"execution" .. "Token",
			"execution" .. "Grant",
			"execution" .. "Command",
			"execution" .. "Request",
			"route",
			"dispatcher",
			"queue",
			"scheduler",
			"orchestrator",
			"executor",
			"asset" .. "Handle",
			"runtime" .. "Handle",
			"callback",
			"listener",
			"handler",
			"adapter",
			"client" .. "State",
		}) do
			local unsafeFieldDeclarations = integrationDeclarations()
			unsafeFieldDeclarations[declarationIndex][unsafeFieldName] = "unsafe"
			expectInvalidIntegration(
				results,
				"authorization integration-readiness declaration exactness",
				unsafeFieldDeclarations
			)
		end

		for _, drift in ipairs({
			{ field = "integrationKind", value = "ReadyToExecute" },
			{ field = "integrationStatus", value = "PermissionGranted" },
			{ field = "executionBoundaryKind", value = "ExecutionApproved" },
		}) do
			local enumDriftDeclarations = integrationDeclarations()
			enumDriftDeclarations[declarationIndex][drift.field] = drift.value
			expectInvalidIntegration(results, "kind/status validation", enumDriftDeclarations)
		end

		for _, enumDrift in ipairs({
			{ field = "integrationKind", value = "providERCompatibility" },
			{ field = "integrationKind", value = " ProviderCompatibility" },
			{ field = "integrationKind", value = "ProviderCompatibility " },
			{ field = "integrationKind", value = "Provider Compatibility" },
			{ field = "integrationKind", value = "ProviderCompatibilityPlural" },
			{ field = "integrationKind", value = "" },
			{ field = "integrationKind", value = true },
			{ field = "integrationKind", value = 1 },
			{ field = "integrationKind", value = {} },
			{ field = "integrationStatus", value = "integrationReady" },
			{ field = "integrationStatus", value = " IntegrationReady" },
			{ field = "integrationStatus", value = "IntegrationReady " },
			{ field = "integrationStatus", value = "Integration Ready" },
			{ field = "integrationStatus", value = "IntegrationReadies" },
			{ field = "integrationStatus", value = "" },
			{ field = "integrationStatus", value = false },
			{ field = "integrationStatus", value = 2 },
			{ field = "integrationStatus", value = {} },
			{ field = "executionBoundaryKind", value = "noAssetExecutionRuntime" },
			{ field = "executionBoundaryKind", value = " NoAssetExecutionRuntime" },
			{ field = "executionBoundaryKind", value = "NoAssetExecutionRuntime " },
			{ field = "executionBoundaryKind", value = "No Asset Execution Runtime" },
			{ field = "executionBoundaryKind", value = "NoAssetExecutionRuntimes" },
			{ field = "executionBoundaryKind", value = "" },
			{ field = "executionBoundaryKind", value = false },
			{ field = "executionBoundaryKind", value = 3 },
			{ field = "executionBoundaryKind", value = {} },
		}) do
			local enumDriftDeclarations = integrationDeclarations()
			enumDriftDeclarations[declarationIndex][enumDrift.field] = enumDrift.value
			expectInvalidIntegration(results, "kind/status validation", enumDriftDeclarations)
		end

		for _, marker in ipairs({
			"permission" .. "Grant",
			"execution" .. "Command",
			"routing" .. "Table",
			"dispatch" .. "Target",
			"scheduler" .. "Queue",
			"orchestration" .. "Handler",
			"gameplay" .. "Run",
			"presentation" .. "Marker",
			"save" .. "Marker",
			"chapter" .. "Marker",
		}) do
			local metadataContamination = integrationDeclarations()
			metadataContamination[declarationIndex].metadata.marker = marker
			expectInvalidIntegration(
				results,
				"banned runtime surface absence",
				metadataContamination
			)

			local evidenceContamination = integrationDeclarations()
			evidenceContamination[declarationIndex].evidence = { marker }
			expectInvalidIntegration(
				results,
				"banned runtime surface absence",
				evidenceContamination
			)

			local tagContamination = integrationDeclarations()
			tagContamination[declarationIndex].tags = { marker }
			expectInvalidIntegration(results, "banned runtime surface absence", tagContamination)
		end

		expect(
			results,
			"future execution separation",
			declaration.authorizationRuntimeName == Types.RuntimeName
				and declaration.authorizationProviderName == Types.RuntimeProviderName
				and declaration.authorizationSnapshotProviderName == Types.RuntimeProviderName
				and declaration.required == true,
			declaration.integrationId .. " preserves authorization identity"
		)
		expect(
			results,
			"future gameplay separation",
			declaration.integrationStatus ~= "PermissionGranted"
				and declaration.executionBoundaryKind ~= "ExecutionApproved",
			declaration.integrationId .. " does not grant execution or gameplay authority"
		)
	end
end

local function runExecutionReadinessChecks(results: { any })
	expectValid(results, "asset execution readiness declaration exactness", function()
		return Validation.executionReadinessDeclarations(executionReadinessDeclarations())
	end)
	expectValid(results, "asset execution readiness order arrays", function()
		return Validation.validate()
	end)
	expectInvalidExecutionReadiness(results, "asset execution readiness declaration exactness", nil)
	expectInvalidExecutionReadiness(
		results,
		"asset execution readiness declaration exactness",
		"not-a-table"
	)
	expectInvalidExecutionReadiness(
		results,
		"asset execution readiness declaration exactness",
		{ [2] = Types.AssetExecutionReadinessDeclarations[1] }
	)
	expectInvalidExecutionReadiness(
		results,
		"asset execution readiness declaration exactness",
		{ named = Types.AssetExecutionReadinessDeclarations[1] }
	)
	expectInvalidExecutionReadiness(results, "asset execution readiness declaration exactness", {})
	expectInvalidExecutionReadiness(results, "asset execution readiness declaration exactness", {
		Types.AssetExecutionReadinessDeclarations[1],
	})

	local missingMiddle = executionReadinessDeclarations()
	table.remove(missingMiddle, 12)
	expectInvalidExecutionReadiness(
		results,
		"asset execution readiness declaration exactness",
		missingMiddle
	)

	local extraDeclaration = executionReadinessDeclarations()
	table.insert(extraDeclaration, Serialization.deepCopy(extraDeclaration[#extraDeclaration]))
	expectInvalidExecutionReadiness(
		results,
		"asset execution readiness declaration exactness",
		extraDeclaration
	)

	local swappedDeclarations = executionReadinessDeclarations()
	swappedDeclarations[1], swappedDeclarations[2] = swappedDeclarations[2], swappedDeclarations[1]
	expectInvalidExecutionReadiness(
		results,
		"asset execution readiness declaration exactness",
		swappedDeclarations
	)

	local rotatedDeclarations = executionReadinessDeclarations()
	table.insert(rotatedDeclarations, table.remove(rotatedDeclarations, 1))
	expectInvalidExecutionReadiness(
		results,
		"asset execution readiness declaration exactness",
		rotatedDeclarations
	)

	local reversedDeclarations = executionReadinessDeclarations()
	for left = 1, math.floor(#reversedDeclarations / 2) do
		local right = #reversedDeclarations - left + 1
		reversedDeclarations[left], reversedDeclarations[right] =
			reversedDeclarations[right], reversedDeclarations[left]
	end
	expectInvalidExecutionReadiness(
		results,
		"asset execution readiness declaration exactness",
		reversedDeclarations
	)

	local insertedDeclaration = executionReadinessDeclarations()
	table.insert(insertedDeclaration, 3, Serialization.deepCopy(insertedDeclaration[1]))
	expectInvalidExecutionReadiness(
		results,
		"asset execution readiness declaration exactness",
		insertedDeclaration
	)

	for orderName, orderValues in pairs(Types.ExecutionReadinessDeclarationOrder) do
		expect(
			results,
			"asset execution readiness order arrays",
			type(orderValues) == "table"
				and #orderValues == #Types.AssetExecutionReadinessDeclarations,
			orderName .. " has exact declaration count"
		)

		local driftedOrder = Serialization.deepCopy(Types.ExecutionReadinessDeclarationOrder)
		driftedOrder[orderName][1] = tostring(driftedOrder[orderName][1]) .. ".drift"
		expectInvalid(results, "asset execution readiness order arrays", function()
			return withTemporaryTypeValue(
				"ExecutionReadinessDeclarationOrder",
				driftedOrder,
				Validation.validate
			)
		end)

		local missingOrder = Serialization.deepCopy(Types.ExecutionReadinessDeclarationOrder)
		missingOrder[orderName] = nil
		expectInvalid(results, "asset execution readiness order arrays", function()
			return withTemporaryTypeValue(
				"ExecutionReadinessDeclarationOrder",
				missingOrder,
				Validation.validate
			)
		end)

		local sparseOrder = Serialization.deepCopy(Types.ExecutionReadinessDeclarationOrder)
		sparseOrder[orderName][2] = nil
		expectInvalid(results, "asset execution readiness order arrays", function()
			return withTemporaryTypeValue(
				"ExecutionReadinessDeclarationOrder",
				sparseOrder,
				Validation.validate
			)
		end)

		local extraOrder = Serialization.deepCopy(Types.ExecutionReadinessDeclarationOrder)
		table.insert(extraOrder[orderName], extraOrder[orderName][#extraOrder[orderName]])
		expectInvalid(results, "asset execution readiness order arrays", function()
			return withTemporaryTypeValue(
				"ExecutionReadinessDeclarationOrder",
				extraOrder,
				Validation.validate
			)
		end)

		local dictionaryOrder = Serialization.deepCopy(Types.ExecutionReadinessDeclarationOrder)
		dictionaryOrder[orderName].named = dictionaryOrder[orderName][1]
		expectInvalid(results, "asset execution readiness order arrays", function()
			return withTemporaryTypeValue(
				"ExecutionReadinessDeclarationOrder",
				dictionaryOrder,
				Validation.validate
			)
		end)

		local containsDistinctValues = false
		for index = 2, #orderValues do
			if orderValues[index] ~= orderValues[1] then
				containsDistinctValues = true
				break
			end
		end
		if containsDistinctValues then
			local rotatedOrder = Serialization.deepCopy(Types.ExecutionReadinessDeclarationOrder)
			table.insert(rotatedOrder[orderName], table.remove(rotatedOrder[orderName], 1))
			expectInvalid(results, "asset execution readiness order arrays", function()
				return withTemporaryTypeValue(
					"ExecutionReadinessDeclarationOrder",
					rotatedOrder,
					Validation.validate
				)
			end)
		end

		local nonTableOrder = Serialization.deepCopy(Types.ExecutionReadinessDeclarationOrder)
		nonTableOrder[orderName] = "not-a-table"
		expectInvalid(results, "asset execution readiness order arrays", function()
			return withTemporaryTypeValue(
				"ExecutionReadinessDeclarationOrder",
				nonTableOrder,
				Validation.validate
			)
		end)
	end

	local unsupportedOrderTable = Serialization.deepCopy(Types.ExecutionReadinessDeclarationOrder)
	unsupportedOrderTable.UnsupportedOrder = { "unsupported" }
	expectInvalid(results, "asset execution readiness order arrays", function()
		return withTemporaryTypeValue(
			"ExecutionReadinessDeclarationOrder",
			unsupportedOrderTable,
			Validation.validate
		)
	end)

	for declarationIndex, declaration in ipairs(Types.AssetExecutionReadinessDeclarations) do
		for _, fieldName in ipairs(Types.ExecutionReadinessDeclarationFields) do
			local missingFieldDeclarations = executionReadinessDeclarations()
			missingFieldDeclarations[declarationIndex][fieldName] = nil
			expectInvalidExecutionReadiness(
				results,
				"asset execution readiness declaration exactness",
				missingFieldDeclarations
			)

			local driftedFieldDeclarations = executionReadinessDeclarations()
			local value = driftedFieldDeclarations[declarationIndex][fieldName]
			if type(value) == "boolean" then
				driftedFieldDeclarations[declarationIndex][fieldName] = not value
			elseif type(value) == "table" then
				driftedFieldDeclarations[declarationIndex][fieldName] =
					{ "asset.execution.readiness.drift" }
			else
				driftedFieldDeclarations[declarationIndex][fieldName] = tostring(value) .. ".drift"
			end
			expectInvalidExecutionReadiness(
				results,
				"asset execution readiness declaration exactness",
				driftedFieldDeclarations
			)
		end

		for _, duplicateIdField in ipairs({
			"readinessId",
			"compatibilityId",
			"readinessDeclarationId",
		}) do
			local duplicateDeclarations = executionReadinessDeclarations()
			duplicateDeclarations[declarationIndex][duplicateIdField] =
				Types.AssetExecutionReadinessDeclarations[1][duplicateIdField]
			if declarationIndex == 1 then
				duplicateDeclarations[2][duplicateIdField] =
					Types.AssetExecutionReadinessDeclarations[1][duplicateIdField]
			end
			expectInvalidExecutionReadiness(results, "duplicate rejection", duplicateDeclarations)
		end

		local unsupportedFieldDeclarations = executionReadinessDeclarations()
		unsupportedFieldDeclarations[declarationIndex].unsupportedReadinessField = "unsupported"
		expectInvalidExecutionReadiness(
			results,
			"asset execution readiness declaration exactness",
			unsupportedFieldDeclarations
		)

		for _, unsafeFieldName in ipairs({
			"permission",
			"permission" .. "Id",
			"permission" .. "Token",
			"approval" .. "Token",
			"authority" .. "Token",
			"execution" .. "Token",
			"execution" .. "Grant",
			"execution" .. "Command",
			"execution" .. "Request",
			"route",
			"dispatcher",
			"queue",
			"scheduler",
			"orchestrator",
			"executor",
			"asset" .. "Handle",
			"runtime" .. "Handle",
			"callback",
			"listener",
			"handler",
			"adapter",
			"remote" .. "Event",
			"remote" .. "Function",
		}) do
			local unsafeFieldDeclarations = executionReadinessDeclarations()
			unsafeFieldDeclarations[declarationIndex][unsafeFieldName] = "unsafe"
			expectInvalidExecutionReadiness(
				results,
				"banned runtime surface absence",
				unsafeFieldDeclarations
			)
		end

		for _, drift in ipairs({
			{ field = "readinessKind", value = "ReadyToExecute" },
			{ field = "readinessStatus", value = "PermissionGranted" },
			{ field = "executionBoundaryKind", value = "ExecutionApproved" },
		}) do
			local enumDriftDeclarations = executionReadinessDeclarations()
			enumDriftDeclarations[declarationIndex][drift.field] = drift.value
			expectInvalidExecutionReadiness(
				results,
				"kind/status validation",
				enumDriftDeclarations
			)
		end

		for _, enumDrift in ipairs({
			{ field = "readinessKind", value = "governanceIdentityReadiness" },
			{ field = "readinessKind", value = " GovernanceIdentityReadiness" },
			{ field = "readinessKind", value = "GovernanceIdentityReadiness " },
			{ field = "readinessKind", value = "Governance Identity Readiness" },
			{ field = "readinessKind", value = "" },
			{ field = "readinessKind", value = true },
			{ field = "readinessKind", value = 1 },
			{ field = "readinessKind", value = {} },
			{ field = "readinessStatus", value = "readinessConfirmed" },
			{ field = "readinessStatus", value = " ReadinessConfirmed" },
			{ field = "readinessStatus", value = "ReadinessConfirmed " },
			{ field = "readinessStatus", value = "Readiness Confirmed" },
			{ field = "readinessStatus", value = "" },
			{ field = "readinessStatus", value = false },
			{ field = "readinessStatus", value = 2 },
			{ field = "readinessStatus", value = {} },
		}) do
			local enumDriftDeclarations = executionReadinessDeclarations()
			enumDriftDeclarations[declarationIndex][enumDrift.field] = enumDrift.value
			expectInvalidExecutionReadiness(
				results,
				"kind/status validation",
				enumDriftDeclarations
			)
		end

		for _, metadataDrift in ipairs({
			{ key = "copied", value = "false" },
			{ key = "order", value = "00" },
			{ key = "compatibility", value = "unsupported" },
			{ key = "unsupported", value = "unsupported" },
		}) do
			local metadataDeclarations = executionReadinessDeclarations()
			metadataDeclarations[declarationIndex].metadata[metadataDrift.key] = metadataDrift.value
			expectInvalidExecutionReadiness(
				results,
				"readiness metadata validation",
				metadataDeclarations
			)
		end

		for _, arrayDrift in ipairs({
			{ field = "evidence", value = {} },
			{
				field = "evidence",
				value = {
					"asset.execution.readiness.duplicate",
					"asset.execution.readiness.duplicate",
				},
			},
			{ field = "evidence", value = { [2] = "asset.execution.readiness.sparse" } },
			{ field = "evidence", value = { "z.readiness", "a.readiness" } },
			{ field = "tags", value = {} },
			{
				field = "tags",
				value = { "asset.execution.readiness", "asset.execution.readiness" },
			},
			{ field = "tags", value = { [2] = "metadata.only" } },
			{ field = "tags", value = { "metadata.only", "asset.execution.readiness" } },
		}) do
			local arrayDeclarations = executionReadinessDeclarations()
			arrayDeclarations[declarationIndex][arrayDrift.field] =
				Serialization.deepCopy(arrayDrift.value)
			expectInvalidExecutionReadiness(
				results,
				if arrayDrift.field == "evidence"
					then "readiness evidence validation"
					else "readiness tag validation",
				arrayDeclarations
			)
		end

		for _, marker in ipairs({
			"permission" .. "Grant",
			"approval" .. "Token",
			"execution" .. "Command",
			"execution" .. "Request",
			"routing" .. "Table",
			"dispatch" .. "Target",
			"scheduler" .. "Queue",
			"orchestration" .. "Handler",
			"asset" .. "Handle",
			"runtime" .. "Handle",
			"gameplay" .. "Run",
			"presentation" .. "Marker",
			"save" .. "Marker",
			"chapter" .. "Marker",
		}) do
			local metadataContamination = executionReadinessDeclarations()
			metadataContamination[declarationIndex].metadata.marker = marker
			expectInvalidExecutionReadiness(
				results,
				"banned runtime surface absence",
				metadataContamination
			)

			local nestedMetadataContamination = executionReadinessDeclarations()
			nestedMetadataContamination[declarationIndex].metadata.nested = { marker = marker }
			expectInvalidExecutionReadiness(
				results,
				"nested unsafe metadata",
				nestedMetadataContamination
			)

			local metadataKeyContamination = executionReadinessDeclarations()
			metadataKeyContamination[declarationIndex].metadata[marker] = "unsafe"
			expectInvalidExecutionReadiness(
				results,
				"nested unsafe metadata",
				metadataKeyContamination
			)

			local evidenceContamination = executionReadinessDeclarations()
			evidenceContamination[declarationIndex].evidence = { marker }
			expectInvalidExecutionReadiness(
				results,
				"banned runtime surface absence",
				evidenceContamination
			)

			local tagContamination = executionReadinessDeclarations()
			tagContamination[declarationIndex].tags = { marker }
			expectInvalidExecutionReadiness(
				results,
				"banned runtime surface absence",
				tagContamination
			)
		end

		expect(
			results,
			"future asset operation separation",
			declaration.readinessStatus ~= "PermissionGranted"
				and declaration.executionBoundaryKind ~= "ExecutionApproved",
			declaration.readinessId .. " remains copied metadata only"
		)
		expect(
			results,
			"future execution separation",
			declaration.futureExecutionRuntimeName == "AssetExecutionRuntime"
				and declaration.futureExecutionProviderName == "assetExecutionRuntime"
				and declaration.futureExecutionSnapshotProviderName == "assetExecutionRuntime"
				and declaration.futureExecutionCoordinatorName == "AssetExecutionCoordinator",
			declaration.readinessId .. " names future ownership without creating it"
		)
		expect(
			results,
			"future gameplay separation",
			declaration.readinessKind ~= "GameplayExecution" and declaration.required == true,
			declaration.readinessId .. " does not grant gameplay authority"
		)
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
	diagnostics.authorizationIntegrationReadinessDeclarations[1].metadata.copied = "mutated"
	diagnostics.authorizationIntegrationDeclarationOrder.IntegrationIdOrder[1] = "mutated"
	diagnostics.assetExecutionReadinessDeclarations[1].metadata.copied = "mutated"
	diagnostics.assetExecutionReadinessDeclarationOrder.ReadinessIdOrder[1] = "mutated"
	local diagnosticsAgain = service.inspect()
	expect(
		results,
		"snapshot isolation",
		diagnosticsAgain.runtimeLimits.MaxAuthorizations == Types.Limits.MaxAuthorizations
			and diagnosticsAgain.schemas.authorizations["authorization.main"].metadata.purpose == "schema-only authorization metadata"
			and diagnosticsAgain.authorizationIntegrationReadinessDeclarations[1].metadata.copied == "true"
			and diagnosticsAgain.assetExecutionReadinessDeclarations[1].metadata.copied
				== "true",
		"diagnostics are isolated"
	)
	expect(
		results,
		"runtime-limit isolation",
		diagnosticsAgain.authorizationIntegrationDeclarationOrder.IntegrationIdOrder[1]
				== Types.IntegrationReadinessDeclarationOrder.IntegrationIdOrder[1]
			and diagnosticsAgain.assetExecutionReadinessDeclarationOrder.ReadinessIdOrder[1]
				== Types.ExecutionReadinessDeclarationOrder.ReadinessIdOrder[1],
		"diagnostics are isolated"
	)
	expect(
		results,
		"diagnostics health-only",
		diagnostics.authorizationIntegrationDeclarationCount
				== #Types.AuthorizationIntegrationReadinessDeclarations
			and diagnostics.authorizationIntegrationReadinessPosture ~= nil
			and diagnostics.authorizationIntegrationCompatibilityPosture ~= nil
			and diagnostics.authorizationExecutionSeparationPosture ~= nil
			and diagnostics.authorizationGameplaySeparationPosture ~= nil
			and diagnostics.assetExecutionReadinessPosture ~= nil
			and diagnostics.assetExecutionReadinessCompatibilityPosture ~= nil
			and diagnostics.assetExecutionReadinessBoundaryPosture ~= nil
			and diagnostics.assetExecutionReadinessSeparationPosture ~= nil,
		"diagnostics expose copied readiness health posture only"
	)
	expect(
		results,
		"diagnostics health-only",
		diagnostics.assetExecutionReadinessHardeningPosture ~= nil
			and diagnostics.assetExecutionReadinessDeclarationPosture ~= nil
			and diagnostics.assetExecutionReadinessMetadataPosture ~= nil
			and diagnostics.assetExecutionReadinessEvidencePosture ~= nil
			and diagnostics.assetExecutionReadinessTagPosture ~= nil
			and diagnostics.assetExecutionReadinessRuntimeLimitPosture ~= nil
			and diagnostics.assetExecutionReadinessDocumentationPosture ~= nil
			and diagnostics.assetExecutionReadinessGovernancePosture ~= nil,
		"diagnostics expose copied readiness hardening posture only"
	)
	local snapshot = service.getSnapshot()
	snapshot.runtimeLimits.MaxRequirements = -1
	snapshot.schemas.requirements["requirement.main"].metadata.purpose = "mutated"
	snapshot.authorizationIntegrationReadinessDeclarations[1].metadata.copied = "mutated"
	snapshot.authorizationIntegrationDeclarationOrder.IntegrationIdOrder[1] = "mutated"
	snapshot.assetExecutionReadinessDeclarations[1].metadata.copied = "mutated"
	snapshot.assetExecutionReadinessDeclarationOrder.ReadinessIdOrder[1] = "mutated"
	local snapshotAgain = service.getSnapshot()
	expect(
		results,
		"snapshot isolation",
		snapshotAgain.runtimeLimits.MaxRequirements == Types.Limits.MaxRequirements
			and snapshotAgain.schemas.requirements["requirement.main"].metadata.purpose == "authorization obligation metadata"
			and snapshotAgain.authorizationIntegrationReadinessDeclarations[1].metadata.copied == "true"
			and snapshotAgain.assetExecutionReadinessDeclarations[1].metadata.copied == "true",
		"snapshots are isolated"
	)
	expect(
		results,
		"runtime-limit isolation",
		snapshotAgain.authorizationIntegrationDeclarationOrder.IntegrationIdOrder[1]
				== Types.IntegrationReadinessDeclarationOrder.IntegrationIdOrder[1]
			and snapshotAgain.assetExecutionReadinessDeclarationOrder.ReadinessIdOrder[1]
				== Types.ExecutionReadinessDeclarationOrder.ReadinessIdOrder[1],
		"snapshot order arrays are isolated"
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
	runIntegrationReadinessChecks(results)
	runExecutionReadinessChecks(results)
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
			"authorization integration-readiness declaration exactness",
			"integration-readiness order arrays",
			"asset execution readiness declaration exactness",
			"asset execution readiness order arrays",
			"readiness metadata validation",
			"readiness evidence validation",
			"readiness tag validation",
			"runtime-limit drift",
			"nested unsafe metadata",
			"future asset operation separation",
			"future execution separation",
			"future gameplay separation",
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
