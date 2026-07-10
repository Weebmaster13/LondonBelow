--!strict

local Diagnostics = require(script.Parent.AssetGovernanceCertificationDecisionDiagnostics)
local Serialization = require(script.Parent.AssetGovernanceCertificationDecisionSerialization)
local Signals = require(script.Parent.AssetGovernanceCertificationDecisionSignals)
local Snapshots = require(script.Parent.AssetGovernanceCertificationDecisionSnapshots)
local State = require(script.Parent.AssetGovernanceCertificationDecisionState)
local Types = require(script.Parent.AssetGovernanceCertificationDecisionTypes)
local Validation = require(script.Parent.AssetGovernanceCertificationDecisionValidation)

local SelfChecks = {}

type CheckResult = { name: string, ok: boolean, reason: string? }

local function runtime(order: number?): any
	return Types.CertifiedRuntimeOrder[order or 1]
end

local function decision(id: string, order: number?): any
	local node = runtime(order)
	return {
		decisionId = id,
		inspectionId = "inspection." .. id,
		decisionKind = "CertificationDecisionEvaluation",
		decisionStatus = "Evaluated",
		runtimeName = node.runtimeName,
		providerName = node.providerName,
		snapshotProviderName = node.snapshotProviderName,
		requirementIds = {},
		evaluationIds = {},
		auditIds = {},
		evidence = { "copied.evidence" },
		tags = { "decision-runtime" },
		metadata = { copied = true },
	}
end

local function requirement(decisionId: string, id: string, order: number?): any
	local node = runtime(order)
	return {
		requirementId = id,
		decisionId = decisionId,
		requirementKind = "CopiedEvidenceRequirement",
		requirementStatus = "Required",
		runtimeName = node.runtimeName,
		providerName = node.providerName,
		snapshotProviderName = node.snapshotProviderName,
		evidence = { "copied.requirement" },
		tags = { "decision-runtime" },
		metadata = { copied = true },
	}
end

local function evaluation(
	decisionId: string,
	requirementId: string,
	id: string,
	order: number?
): any
	local node = runtime(order)
	return {
		evaluationId = id,
		decisionId = decisionId,
		requirementId = requirementId,
		evaluationKind = "CopiedEvidenceEvaluation",
		evaluationStatus = "Passed",
		runtimeName = node.runtimeName,
		providerName = node.providerName,
		snapshotProviderName = node.snapshotProviderName,
		evidence = { "copied.evaluation" },
		tags = { "decision-runtime" },
		metadata = { copied = true },
	}
end

local function audit(decisionId: string, id: string, evaluationIds: { string }?): any
	return {
		auditId = id,
		decisionId = decisionId,
		evaluationIds = evaluationIds or {},
		auditKind = "DecisionAudit",
		auditStatus = "Passed",
		reviewer = "System",
		evidence = { "copied.audit" },
		tags = { "decision-runtime" },
		metadata = { copied = true },
	}
end

local function expect(
	name: string,
	conditionValue: boolean,
	reason: string?,
	checks: { CheckResult }
)
	table.insert(
		checks,
		{ name = name, ok = conditionValue, reason = if conditionValue then nil else reason }
	)
end

local function expectAccept(name: string, ok: boolean, reason: string?, checks: { CheckResult })
	expect(name, ok, reason or "expected acceptance", checks)
end

local function expectReject(name: string, ok: boolean, _reason: string?, checks: { CheckResult })
	expect(name, not ok, "expected rejection", checks)
end

local function withField(schema: any, field: string, value: any): any
	local copy = Serialization.deepCopy(schema)
	copy[field] = value
	return copy
end

local function mapCount(map: { [any]: any }): number
	local count = 0
	for _ in pairs(map) do
		count += 1
	end
	return count
end

local function arrayValues(map: { [string]: boolean }): { string }
	local values = {}
	for value in pairs(map) do
		table.insert(values, value)
	end
	table.sort(values)
	return values
end

local function expectExactMapKeys(
	name: string,
	map: { [string]: boolean },
	values: { string },
	checks: { CheckResult }
)
	local exact = mapCount(map) == #values
	for _, value in ipairs(values) do
		exact = exact and map[value] == true
	end
	expect(name .. " exact surface matches", exact, "map surface drifted", checks)
end

local function expectExactArray(
	name: string,
	actual: { any },
	expected: { any },
	checks: { CheckResult }
)
	local exact = #actual == #expected
	for index, expectedValue in ipairs(expected) do
		exact = exact and actual[index] == expectedValue
	end
	expect(name .. " exact surface matches", exact, "array surface drifted", checks)
end

local function expectMissingFieldRejects(
	name: string,
	schema: any,
	field: string,
	validate: (any) -> (boolean, string?),
	checks: { CheckResult }
)
	local candidate = Serialization.deepCopy(schema)
	candidate[field] = nil
	local ok, reason = validate(candidate)
	expectReject(name .. " missing " .. field .. " rejects", ok, reason, checks)
end

local function exactSurfaces(checks: { CheckResult })
	expectExactArray("decision fields", Types.SchemaFields.GovernanceDecision, {
		"decisionId",
		"inspectionId",
		"decisionKind",
		"decisionStatus",
		"runtimeName",
		"providerName",
		"snapshotProviderName",
		"requirementIds",
		"evaluationIds",
		"auditIds",
		"evidence",
		"tags",
		"metadata",
	}, checks)
	expectExactArray("requirement fields", Types.SchemaFields.GovernanceDecisionRequirement, {
		"requirementId",
		"decisionId",
		"requirementKind",
		"requirementStatus",
		"runtimeName",
		"providerName",
		"snapshotProviderName",
		"evidence",
		"tags",
		"metadata",
	}, checks)
	expectExactArray("evaluation fields", Types.SchemaFields.GovernanceDecisionEvaluation, {
		"evaluationId",
		"decisionId",
		"requirementId",
		"evaluationKind",
		"evaluationStatus",
		"runtimeName",
		"providerName",
		"snapshotProviderName",
		"evidence",
		"tags",
		"metadata",
	}, checks)
	expectExactArray("audit fields", Types.SchemaFields.GovernanceDecisionAudit, {
		"auditId",
		"decisionId",
		"evaluationIds",
		"auditKind",
		"auditStatus",
		"reviewer",
		"evidence",
		"tags",
		"metadata",
	}, checks)
	expectExactMapKeys("decision kind", Types.DecisionKind, arrayValues(Types.DecisionKind), checks)
	expectExactMapKeys(
		"decision status",
		Types.DecisionStatus,
		arrayValues(Types.DecisionStatus),
		checks
	)
	expectExactMapKeys(
		"requirement kind",
		Types.RequirementKind,
		arrayValues(Types.RequirementKind),
		checks
	)
	expectExactMapKeys(
		"requirement status",
		Types.RequirementStatus,
		arrayValues(Types.RequirementStatus),
		checks
	)
	expectExactMapKeys(
		"evaluation kind",
		Types.EvaluationKind,
		arrayValues(Types.EvaluationKind),
		checks
	)
	expectExactMapKeys(
		"evaluation status",
		Types.EvaluationStatus,
		arrayValues(Types.EvaluationStatus),
		checks
	)
	expectExactMapKeys("audit kind", Types.AuditKind, arrayValues(Types.AuditKind), checks)
	expectExactMapKeys("audit status", Types.AuditStatus, arrayValues(Types.AuditStatus), checks)
	expectExactArray("integration readiness fields", Types.IntegrationReadinessDeclarationFields, {
		"integrationId",
		"compatibilityId",
		"integrationKind",
		"integrationStatus",
		"runtimeName",
		"providerName",
		"snapshotProviderName",
		"coordinatorName",
		"diagnosticsProviderName",
		"bootstrapDependencyName",
		"governanceSnapshotProviderName",
		"documentationReference",
		"decisionRuntimeName",
		"decisionProviderName",
		"evidence",
		"tags",
		"metadata",
	}, checks)
	expectExactArray("integration ordering fields", Types.IntegrationOrderingFields, {
		"integrationId",
		"compatibilityId",
		"runtimeName",
		"providerName",
		"snapshotProviderName",
		"coordinatorName",
		"diagnosticsProviderName",
		"bootstrapDependencyName",
		"governanceSnapshotProviderName",
		"documentationReference",
	}, checks)
	expectExactMapKeys(
		"integration kind",
		Types.IntegrationKind,
		arrayValues(Types.IntegrationKind),
		checks
	)
	expectExactMapKeys(
		"integration status",
		Types.IntegrationStatus,
		arrayValues(Types.IntegrationStatus),
		checks
	)
	expectExactArray("execution readiness fields", Types.ExecutionReadinessDeclarationFields, {
		"executionReadinessId",
		"executionCompatibilityId",
		"executionDeclarationId",
		"executionReadinessKind",
		"executionReadinessStatus",
		"runtimeName",
		"providerName",
		"snapshotProviderName",
		"coordinatorName",
		"diagnosticsProviderName",
		"bootstrapDependencyName",
		"governanceSnapshotProviderName",
		"documentationReference",
		"decisionRuntimeName",
		"decisionProviderName",
		"decisionSnapshotProviderName",
		"decisionEvidenceKind",
		"required",
		"evidence",
		"tags",
		"metadata",
	}, checks)
	expectExactArray(
		"execution readiness ordering fields",
		Types.ExecutionReadinessOrderingFields,
		{
			"executionReadinessId",
			"executionCompatibilityId",
			"executionDeclarationId",
			"runtimeName",
			"providerName",
			"snapshotProviderName",
			"coordinatorName",
			"diagnosticsProviderName",
			"bootstrapDependencyName",
			"governanceSnapshotProviderName",
			"documentationReference",
		},
		checks
	)
	expectExactMapKeys(
		"execution readiness kind",
		Types.ExecutionReadinessKind,
		arrayValues(Types.ExecutionReadinessKind),
		checks
	)
	expectExactMapKeys(
		"execution readiness status",
		Types.ExecutionReadinessStatus,
		arrayValues(Types.ExecutionReadinessStatus),
		checks
	)
	expectExactArray("decision posture keys", Types.PostureKeys, {
		"decisionRuntimePosture",
		"decisionEvaluationPosture",
		"decisionRequirementPosture",
		"decisionAuditPosture",
		"decisionEvidencePosture",
		"decisionIsolationPosture",
		"decisionValidationPosture",
		"decisionMetadataPosture",
		"decisionDocumentationPosture",
		"decisionIntegrationPosture",
		"decisionIntegrationHardeningPosture",
		"integrationOrderingPosture",
		"integrationDeterminismPosture",
		"integrationConsistencyPosture",
		"integrationCompatibilityPosture",
		"integrationEvidencePosture",
		"integrationIsolationPosture",
		"integrationCoveragePosture",
		"integrationValidationPosture",
		"integrationDocumentationPosture",
		"executionReadinessPosture",
		"executionCompatibilityPosture",
		"executionEvidencePosture",
		"executionIsolationPosture",
		"executionCoveragePosture",
		"executionValidationPosture",
		"executionDocumentationPosture",
		"noExecutionAuthorityPosture",
		"noExecutionRoutingPosture",
		"noExecutionDispatchPosture",
		"noExecutionQueuePosture",
		"noExecutionMutationPosture",
		"providerPosture",
		"snapshotPosture",
		"documentationPosture",
		"bootstrapPosture",
		"governancePosture",
		"noAuthorityPosture",
		"noAuthorizationPosture",
		"noApprovalPosture",
		"noRejectionPosture",
		"noExecutionPosture",
		"noRepairPosture",
		"noOrchestrationPosture",
		"noSchedulingPosture",
		"noMutationPosture",
	}, checks)
	expect(
		"provider lowerCamelCase",
		Types.RuntimeProviderName == "assetGovernanceCertificationDecisionRuntime",
		"provider drift",
		checks
	)
	expect(
		"snapshot lowerCamelCase",
		Types.SnapshotKind == "assetGovernanceCertificationDecisionRuntimeSnapshot",
		"snapshot drift",
		checks
	)
	expect(
		"decision runtime mode exact",
		Types.Mode == "ServerAuthoritativeAssetGovernanceCertificationDecisionMetadataRuntime",
		"runtime mode drift",
		checks
	)
	expectExactArray("decision documentation files", Types.DocumentationFiles, {
		"ASSET_GOVERNANCE_CERTIFICATION_DECISION_RUNTIME.md",
		"GOVERNANCE_DECISION_RUNTIME.md",
		"GOVERNANCE_DECISION_REQUIREMENT_RUNTIME.md",
		"GOVERNANCE_DECISION_EVALUATION_RUNTIME.md",
		"GOVERNANCE_DECISION_AUDIT_RUNTIME.md",
		"ASSET_GOVERNANCE_CERTIFICATION_DECISION_VALIDATION.md",
		"ASSET_GOVERNANCE_CERTIFICATION_DECISION_SERIALIZATION.md",
		"ASSET_GOVERNANCE_CERTIFICATION_DECISION_DIAGNOSTICS.md",
		"ASSET_GOVERNANCE_CERTIFICATION_DECISION_SELF_CHECKS.md",
		"ASSET_GOVERNANCE_CERTIFICATION_DECISION_RUNTIME_LIMITS.md",
		"ASSET_GOVERNANCE_CERTIFICATION_DECISION_PRODUCTION_REVIEW.md",
		"ASSET_GOVERNANCE_CERTIFICATION_DECISION_INTEGRATION_READINESS.md",
		"ASSET_GOVERNANCE_CERTIFICATION_DECISION_EXECUTION_READINESS.md",
	}, checks)
	expectExactArray(
		"decision Bootstrap dependencies",
		Types.BootstrapDependencyOrder,
		{ "AssetGovernanceCertificationInspectionCoordinator" },
		checks
	)
end

local function integrationReadinessBehavior(checks: { CheckResult })
	expectAccept(
		"integration declarations validate",
		Validation.integrationReadinessDeclarations(Types.IntegrationReadinessDeclarations),
		nil,
		checks
	)
	expect(
		"integration declarations cover certified runtime order",
		#Types.IntegrationReadinessDeclarations == #Types.CertifiedRuntimeOrder,
		"integration declaration count drifted",
		checks
	)
	for index, declaration in ipairs(Types.IntegrationReadinessDeclarations) do
		local expected = Types.CertifiedRuntimeOrder[index]
		expectAccept(
			"integration declaration validates " .. declaration.runtimeName,
			Validation.integrationReadinessDeclaration(declaration),
			nil,
			checks
		)
		expect(
			"integration runtime order " .. declaration.runtimeName,
			declaration.runtimeName == expected.runtimeName,
			"integration runtime order drifted",
			checks
		)
		expect(
			"integration provider order " .. declaration.providerName,
			declaration.providerName == expected.providerName,
			"integration provider order drifted",
			checks
		)
		expect(
			"integration snapshot order " .. declaration.snapshotProviderName,
			declaration.snapshotProviderName == expected.snapshotProviderName,
			"integration snapshot order drifted",
			checks
		)
		expect(
			"integration coordinator order " .. declaration.coordinatorName,
			declaration.coordinatorName == expected.coordinatorName,
			"integration coordinator order drifted",
			checks
		)
		expect(
			"integration diagnostics provider " .. declaration.diagnosticsProviderName,
			declaration.diagnosticsProviderName == expected.providerName,
			"integration diagnostics provider drifted",
			checks
		)
		expect(
			"integration Bootstrap dependency " .. declaration.bootstrapDependencyName,
			declaration.bootstrapDependencyName == expected.coordinatorName,
			"integration Bootstrap dependency drifted",
			checks
		)
		expect(
			"integration Governance provider " .. declaration.governanceSnapshotProviderName,
			declaration.governanceSnapshotProviderName == expected.providerName,
			"integration Governance provider drifted",
			checks
		)
		expect(
			"integration documentation reference " .. declaration.documentationReference,
			declaration.documentationReference == expected.documentationReference,
			"integration documentation reference drifted",
			checks
		)
		expect(
			"integration decision runtime name " .. declaration.integrationId,
			declaration.decisionRuntimeName == Types.DecisionRuntimeName,
			"integration decision runtime drifted",
			checks
		)
		expect(
			"integration decision provider name " .. declaration.integrationId,
			declaration.decisionProviderName == Types.RuntimeProviderName,
			"integration decision provider drifted",
			checks
		)
		for _, field in ipairs(Types.IntegrationReadinessDeclarationFields) do
			local candidate = Serialization.deepCopy(declaration)
			candidate[field] = nil
			local ok, reason = Validation.integrationReadinessDeclaration(candidate)
			expectReject(
				"integration declaration missing "
					.. field
					.. " rejects "
					.. declaration.runtimeName,
				ok,
				reason,
				checks
			)
		end
		for _, mismatch in ipairs({
			{ field = "runtimeName", value = "UnknownRuntime" },
			{ field = "providerName", value = "unknownProvider" },
			{ field = "snapshotProviderName", value = "unknownSnapshot" },
			{ field = "coordinatorName", value = "UnknownCoordinator" },
			{ field = "diagnosticsProviderName", value = "unknownDiagnostics" },
			{ field = "bootstrapDependencyName", value = "UnknownBootstrap" },
			{ field = "governanceSnapshotProviderName", value = "unknownGovernance" },
			{ field = "documentationReference", value = "UNKNOWN.md" },
			{ field = "decisionRuntimeName", value = "UnknownDecisionRuntime" },
			{ field = "decisionProviderName", value = "unknownDecisionProvider" },
		}) do
			local ok, reason = Validation.integrationReadinessDeclaration(
				withField(declaration, mismatch.field, mismatch.value)
			)
			expectReject(
				"integration declaration rejects "
					.. mismatch.field
					.. " mismatch "
					.. declaration.runtimeName,
				ok,
				reason,
				checks
			)
		end
	end
	for _, integrationKind in ipairs(arrayValues(Types.IntegrationKind)) do
		local ok, reason = Validation.integrationReadinessDeclaration(
			withField(Types.IntegrationReadinessDeclarations[1], "integrationKind", integrationKind)
		)
		expectAccept("integration kind accepted " .. integrationKind, ok, reason, checks)
	end
	for _, integrationStatus in ipairs(arrayValues(Types.IntegrationStatus)) do
		local ok, reason = Validation.integrationReadinessDeclaration(
			withField(
				Types.IntegrationReadinessDeclarations[1],
				"integrationStatus",
				integrationStatus
			)
		)
		expectAccept("integration status accepted " .. integrationStatus, ok, reason, checks)
	end
	for _, invalidEnum in ipairs({
		"Authorize",
		"Approve",
		"Reject",
		"Repair",
		"Execute",
		"Route",
		"Dispatch",
		"Schedule",
	}) do
		expectReject(
			"integration rejects invalid kind " .. invalidEnum,
			Validation.integrationReadinessDeclaration(
				withField(Types.IntegrationReadinessDeclarations[1], "integrationKind", invalidEnum)
			),
			nil,
			checks
		)
		expectReject(
			"integration rejects invalid status " .. invalidEnum,
			Validation.integrationReadinessDeclaration(
				withField(
					Types.IntegrationReadinessDeclarations[1],
					"integrationStatus",
					invalidEnum
				)
			),
			nil,
			checks
		)
	end
	for _, duplicate in ipairs({
		{
			field = "integrationId",
			value = Types.IntegrationReadinessDeclarations[1].integrationId,
		},
		{
			field = "compatibilityId",
			value = Types.IntegrationReadinessDeclarations[1].compatibilityId,
		},
		{ field = "runtimeName", value = Types.IntegrationReadinessDeclarations[1].runtimeName },
		{ field = "providerName", value = Types.IntegrationReadinessDeclarations[1].providerName },
		{
			field = "snapshotProviderName",
			value = Types.IntegrationReadinessDeclarations[1].snapshotProviderName,
		},
	}) do
		local declarations = Serialization.deepCopy(Types.IntegrationReadinessDeclarations)
		declarations[2][duplicate.field] = duplicate.value
		expectReject(
			"integration declarations reject duplicate " .. duplicate.field,
			Validation.integrationReadinessDeclarations(declarations),
			nil,
			checks
		)
	end
	expectReject(
		"integration declarations reject short list",
		Validation.integrationReadinessDeclarations({ Types.IntegrationReadinessDeclarations[1] }),
		nil,
		checks
	)
	expectReject(
		"integration declaration rejects unsupported field",
		Validation.integrationReadinessDeclaration(
			withField(Types.IntegrationReadinessDeclarations[1], "routingHandler", "route")
		),
		nil,
		checks
	)
end

local function integrationHardeningBehavior(checks: { CheckResult })
	expectAccept(
		"integration hardening baseline validates",
		Validation.integrationReadinessDeclarations(Types.IntegrationReadinessDeclarations),
		nil,
		checks
	)
	for index, declaration in ipairs(Types.IntegrationReadinessDeclarations) do
		local expected = Types.CertifiedRuntimeOrder[index]
		expect(
			"integration hardening exact integrationId " .. declaration.integrationId,
			declaration.integrationId == "decision.integration." .. expected.runtimeName,
			"integrationId ordering drifted",
			checks
		)
		expect(
			"integration hardening exact compatibilityId " .. declaration.compatibilityId,
			declaration.compatibilityId == "decision.compatibility." .. expected.runtimeName,
			"compatibilityId ordering drifted",
			checks
		)
		expect(
			"integration hardening exact evidence " .. declaration.integrationId,
			declaration.evidence[1] == "copied.integration." .. expected.runtimeName
				and #declaration.evidence == 1,
			"evidence ordering drifted",
			checks
		)
		expect(
			"integration hardening exact tags " .. declaration.integrationId,
			declaration.tags[1] == "decision-integration-ready" and #declaration.tags == 1,
			"tag ordering drifted",
			checks
		)
		expect(
			"integration hardening exact metadata " .. declaration.integrationId,
			declaration.metadata.copied == true
				and declaration.metadata.authority == "metadata-only"
				and declaration.metadata.integrationReady == true,
			"metadata drifted",
			checks
		)
		for _, field in ipairs(Types.IntegrationReadinessDeclarationFields) do
			local declarations = Serialization.deepCopy(Types.IntegrationReadinessDeclarations)
			if field == "evidence" then
				declarations[index][field] = { "copied.integration.mutated" }
			elseif field == "tags" then
				declarations[index][field] = { "decision-integration-mutated" }
			elseif field == "metadata" then
				declarations[index][field] = {
					copied = true,
					authority = "metadata-only",
					integrationReady = false,
				}
			elseif field == "integrationKind" then
				declarations[index][field] = "RuntimeCompatibility"
			elseif field == "integrationStatus" then
				declarations[index][field] = "Compatible"
			else
				declarations[index][field] = tostring(declarations[index][field]) .. ".mutated"
			end
			expectReject(
				"integration hardening rejects exact field drift "
					.. field
					.. " "
					.. declaration.runtimeName,
				Validation.integrationReadinessDeclarations(declarations),
				nil,
				checks
			)
		end
		for _, field in ipairs(Types.IntegrationOrderingFields) do
			local replacementIndex = if index == #Types.IntegrationReadinessDeclarations
				then 1
				else index + 1
			local declarations = Serialization.deepCopy(Types.IntegrationReadinessDeclarations)
			declarations[index][field] = declarations[replacementIndex][field]
			expectReject(
				"integration hardening rejects ordered field substitution "
					.. field
					.. " "
					.. declaration.runtimeName,
				Validation.integrationReadinessDeclarations(declarations),
				nil,
				checks
			)
		end
	end
	for index = 1, #Types.IntegrationReadinessDeclarations - 1 do
		local declarations = Serialization.deepCopy(Types.IntegrationReadinessDeclarations)
		local current = declarations[index]
		declarations[index] = declarations[index + 1]
		declarations[index + 1] = current
		expectReject(
			"integration hardening rejects adjacent order swap " .. tostring(index),
			Validation.integrationReadinessDeclarations(declarations),
			nil,
			checks
		)
	end
	for _, duplicate in ipairs(Types.IntegrationOrderingFields) do
		local declarations = Serialization.deepCopy(Types.IntegrationReadinessDeclarations)
		declarations[2][duplicate] = declarations[1][duplicate]
		expectReject(
			"integration hardening rejects duplicate ordering field " .. duplicate,
			Validation.integrationReadinessDeclarations(declarations),
			nil,
			checks
		)
	end
	local partial = Serialization.deepCopy(Types.IntegrationReadinessDeclarations)
	partial[#partial] = nil
	expectReject(
		"integration hardening rejects partial declarations",
		Validation.integrationReadinessDeclarations(partial),
		nil,
		checks
	)
	local extra = Serialization.deepCopy(Types.IntegrationReadinessDeclarations)
	table.insert(extra, Serialization.deepCopy(Types.IntegrationReadinessDeclarations[1]))
	expectReject(
		"integration hardening rejects extra declarations",
		Validation.integrationReadinessDeclarations(extra),
		nil,
		checks
	)
	for markerIndex, marker in ipairs(Serialization.forbiddenMarkers()) do
		local markerKey = {}
		markerKey[marker] = true
		for _, mutation in ipairs({
			{ field = "evidence", value = { marker } },
			{ field = "tags", value = { marker } },
			{ field = "metadata", value = { marker = marker } },
			{ field = "metadata", value = markerKey },
		}) do
			local candidate =
				withField(Types.IntegrationReadinessDeclarations[1], mutation.field, mutation.value)
			expectReject(
				"integration hardening rejects unsafe "
					.. mutation.field
					.. " marker "
					.. tostring(markerIndex),
				Validation.integrationReadinessDeclaration(candidate),
				nil,
				checks
			)
		end
	end
end

local function executionReadinessBehavior(checks: { CheckResult })
	for index, declaration in ipairs(Types.ExecutionReadinessDeclarations) do
		local expected = Types.ExecutionReadinessRuntimeOrder[index]
		expectAccept(
			"execution readiness declaration validates " .. declaration.runtimeName,
			Validation.executionReadinessDeclaration(declaration),
			nil,
			checks
		)
		expect(
			"execution readiness id order " .. declaration.executionReadinessId,
			declaration.executionReadinessId
				== "future.execution.readiness." .. expected.runtimeName,
			"execution readiness id drifted",
			checks
		)
		expect(
			"execution compatibility id order " .. declaration.executionCompatibilityId,
			declaration.executionCompatibilityId
				== "future.execution.compatibility." .. expected.runtimeName,
			"execution compatibility id drifted",
			checks
		)
		expect(
			"execution declaration id order " .. declaration.executionDeclarationId,
			declaration.executionDeclarationId
				== "future.execution.declaration." .. expected.runtimeName,
			"execution declaration id drifted",
			checks
		)
		expect(
			"execution runtime order " .. declaration.runtimeName,
			declaration.runtimeName == expected.runtimeName,
			"execution runtime order drifted",
			checks
		)
		expect(
			"execution provider order " .. declaration.providerName,
			declaration.providerName == expected.providerName,
			"execution provider order drifted",
			checks
		)
		expect(
			"execution snapshot order " .. declaration.snapshotProviderName,
			declaration.snapshotProviderName == expected.snapshotProviderName,
			"execution snapshot order drifted",
			checks
		)
		expect(
			"execution coordinator order " .. declaration.coordinatorName,
			declaration.coordinatorName == expected.coordinatorName,
			"execution coordinator order drifted",
			checks
		)
		expect(
			"execution diagnostics provider " .. declaration.diagnosticsProviderName,
			declaration.diagnosticsProviderName == expected.providerName,
			"execution diagnostics provider drifted",
			checks
		)
		expect(
			"execution Bootstrap dependency " .. declaration.bootstrapDependencyName,
			declaration.bootstrapDependencyName == expected.coordinatorName,
			"execution Bootstrap dependency drifted",
			checks
		)
		expect(
			"execution Governance provider " .. declaration.governanceSnapshotProviderName,
			declaration.governanceSnapshotProviderName == expected.providerName,
			"execution Governance provider drifted",
			checks
		)
		expect(
			"execution documentation reference " .. declaration.documentationReference,
			declaration.documentationReference == expected.documentationReference,
			"execution documentation reference drifted",
			checks
		)
		expect(
			"execution decision runtime compatibility " .. declaration.executionReadinessId,
			declaration.decisionRuntimeName == Types.DecisionRuntimeName
				and declaration.decisionProviderName == Types.RuntimeProviderName
				and declaration.decisionSnapshotProviderName
					== Types.DecisionSnapshotProviderName,
			"execution decision runtime compatibility drifted",
			checks
		)
		expect(
			"execution readiness evidence exact " .. declaration.executionReadinessId,
			declaration.evidence[1] == "copied.future.execution.readiness." .. expected.runtimeName
				and #declaration.evidence == 1,
			"execution evidence drifted",
			checks
		)
		expect(
			"execution readiness tags exact " .. declaration.executionReadinessId,
			declaration.tags[1] == "future-governed-execution-readiness" and #declaration.tags == 1,
			"execution tags drifted",
			checks
		)
		expect(
			"execution readiness metadata exact " .. declaration.executionReadinessId,
			declaration.metadata.copied == true
				and declaration.metadata.authority == "readiness-evidence-only"
				and declaration.metadata.executionAuthority == false
				and declaration.metadata.executionReady == true,
			"execution metadata drifted",
			checks
		)
		expect(
			"execution readiness required boolean " .. declaration.executionReadinessId,
			declaration.required == true,
			"required drifted",
			checks
		)
		for _, field in ipairs(Types.ExecutionReadinessDeclarationFields) do
			local candidate = Serialization.deepCopy(declaration)
			candidate[field] = nil
			expectReject(
				"execution readiness missing " .. field .. " rejects " .. declaration.runtimeName,
				Validation.executionReadinessDeclaration(candidate),
				nil,
				checks
			)
			local declarations = Serialization.deepCopy(Types.ExecutionReadinessDeclarations)
			if field == "evidence" then
				declarations[index][field] = { "copied.future.execution.mutated" }
			elseif field == "tags" then
				declarations[index][field] = { "future-governed-execution-mutated" }
			elseif field == "metadata" then
				declarations[index][field] = {
					copied = true,
					authority = "readiness-evidence-only",
					executionAuthority = true,
					executionReady = true,
				}
			elseif field == "executionReadinessKind" then
				declarations[index][field] = "RuntimeExecutionCompatibility"
			elseif field == "executionReadinessStatus" then
				declarations[index][field] = "Compatible"
			elseif field == "required" then
				declarations[index][field] = false
			else
				declarations[index][field] = tostring(declarations[index][field]) .. ".mutated"
			end
			expectReject(
				"execution readiness rejects exact field drift "
					.. field
					.. " "
					.. declaration.runtimeName,
				Validation.executionReadinessDeclarations(declarations),
				nil,
				checks
			)
		end
		for _, field in ipairs(Types.ExecutionReadinessOrderingFields) do
			local replacementIndex = if index == #Types.ExecutionReadinessDeclarations
				then 1
				else index + 1
			local declarations = Serialization.deepCopy(Types.ExecutionReadinessDeclarations)
			declarations[index][field] = declarations[replacementIndex][field]
			expectReject(
				"execution readiness rejects ordered field substitution "
					.. field
					.. " "
					.. declaration.runtimeName,
				Validation.executionReadinessDeclarations(declarations),
				nil,
				checks
			)
		end
	end
	for _, invalidEnum in ipairs({
		"Authorize",
		"Approve",
		"Reject",
		"Repair",
		"Execute",
		"Route",
		"Dispatch",
		"Schedule",
	}) do
		expectReject(
			"execution readiness rejects invalid kind " .. invalidEnum,
			Validation.executionReadinessDeclaration(
				withField(
					Types.ExecutionReadinessDeclarations[1],
					"executionReadinessKind",
					invalidEnum
				)
			),
			nil,
			checks
		)
		expectReject(
			"execution readiness rejects invalid status " .. invalidEnum,
			Validation.executionReadinessDeclaration(
				withField(
					Types.ExecutionReadinessDeclarations[1],
					"executionReadinessStatus",
					invalidEnum
				)
			),
			nil,
			checks
		)
	end
	expectReject(
		"execution readiness rejects non-boolean required",
		Validation.executionReadinessDeclaration(
			withField(Types.ExecutionReadinessDeclarations[1], "required", "true")
		),
		nil,
		checks
	)
	local reordered = Serialization.deepCopy(Types.ExecutionReadinessDeclarations)
	local current = reordered[1]
	reordered[1] = reordered[2]
	reordered[2] = current
	expectReject(
		"execution readiness rejects reordered declarations",
		Validation.executionReadinessDeclarations(reordered),
		nil,
		checks
	)
	for _, duplicate in ipairs(Types.ExecutionReadinessOrderingFields) do
		local declarations = Serialization.deepCopy(Types.ExecutionReadinessDeclarations)
		declarations[2][duplicate] = declarations[1][duplicate]
		expectReject(
			"execution readiness rejects duplicate ordered field " .. duplicate,
			Validation.executionReadinessDeclarations(declarations),
			nil,
			checks
		)
	end
	for _, removedIndex in ipairs({ 1, 7, #Types.ExecutionReadinessDeclarations }) do
		local declarations = Serialization.deepCopy(Types.ExecutionReadinessDeclarations)
		table.remove(declarations, removedIndex)
		expectReject(
			"execution readiness rejects missing declaration " .. tostring(removedIndex),
			Validation.executionReadinessDeclarations(declarations),
			nil,
			checks
		)
	end
	local extra = Serialization.deepCopy(Types.ExecutionReadinessDeclarations)
	table.insert(extra, Serialization.deepCopy(Types.ExecutionReadinessDeclarations[1]))
	expectReject(
		"execution readiness rejects extra declaration",
		Validation.executionReadinessDeclarations(extra),
		nil,
		checks
	)
	expectReject(
		"execution readiness declaration rejects unsupported field",
		Validation.executionReadinessDeclaration(
			withField(Types.ExecutionReadinessDeclarations[1], "execution" .. "Queue", "queue")
		),
		nil,
		checks
	)
end

local function validationBehavior(checks: { CheckResult })
	local seedDecision = decision("decision.seed", 1)
	local seedRequirement = requirement("decision.seed", "requirement.seed", 1)
	local seedEvaluation = evaluation("decision.seed", "requirement.seed", "evaluation.seed", 1)
	local seedAudit = audit("decision.seed", "audit.seed", { "evaluation.seed" })
	for _, candidate in ipairs({ nil, "invalid", true, 7 }) do
		expectReject("decision rejects non-table", Validation.decision(candidate), nil, checks)
		expectReject(
			"requirement rejects non-table",
			Validation.requirement(candidate),
			nil,
			checks
		)
		expectReject("evaluation rejects non-table", Validation.evaluation(candidate), nil, checks)
		expectReject("audit rejects non-table", Validation.audit(candidate), nil, checks)
	end
	for _, field in ipairs(Types.SchemaFields.GovernanceDecision) do
		expectMissingFieldRejects("decision", seedDecision, field, Validation.decision, checks)
	end
	for _, field in ipairs(Types.SchemaFields.GovernanceDecisionRequirement) do
		expectMissingFieldRejects(
			"requirement",
			seedRequirement,
			field,
			Validation.requirement,
			checks
		)
	end
	for _, field in ipairs(Types.SchemaFields.GovernanceDecisionEvaluation) do
		expectMissingFieldRejects(
			"evaluation",
			seedEvaluation,
			field,
			Validation.evaluation,
			checks
		)
	end
	for _, field in ipairs(Types.SchemaFields.GovernanceDecisionAudit) do
		expectMissingFieldRejects("audit", seedAudit, field, Validation.audit, checks)
	end
	expectReject(
		"decision rejects unsupported schemaType field",
		Validation.decision(
			withField(seedDecision, "schemaType", Types.SchemaType.GovernanceDecision)
		),
		nil,
		checks
	)
	expectReject(
		"requirement rejects unsupported schemaType field",
		Validation.requirement(
			withField(seedRequirement, "schemaType", Types.SchemaType.GovernanceDecisionRequirement)
		),
		nil,
		checks
	)
	expectReject(
		"evaluation rejects unsupported schemaType field",
		Validation.evaluation(
			withField(seedEvaluation, "schemaType", Types.SchemaType.GovernanceDecisionEvaluation)
		),
		nil,
		checks
	)
	expectReject(
		"audit rejects unsupported schemaType field",
		Validation.audit(
			withField(seedAudit, "schemaType", Types.SchemaType.GovernanceDecisionAudit)
		),
		nil,
		checks
	)
	expectReject(
		"decision rejects duplicate requirement child references",
		Validation.decision(withField(seedDecision, "requirementIds", { "a", "a" })),
		nil,
		checks
	)
	expectReject(
		"decision rejects duplicate evaluation child references",
		Validation.decision(withField(seedDecision, "evaluationIds", { "a", "a" })),
		nil,
		checks
	)
	expectReject(
		"decision rejects duplicate audit child references",
		Validation.decision(withField(seedDecision, "auditIds", { "a", "a" })),
		nil,
		checks
	)
	expectReject(
		"audit rejects duplicate evaluation child references",
		Validation.audit(withField(seedAudit, "evaluationIds", { "a", "a" })),
		nil,
		checks
	)
	for runtimeIndex, runtimeNode in ipairs(Types.CertifiedRuntimeOrder) do
		for providerIndex, providerNode in ipairs(Types.CertifiedRuntimeOrder) do
			local candidate = decision("decision.matrix", runtimeIndex)
			candidate.providerName = providerNode.providerName
			expect(
				"decision provider matrix "
					.. runtimeNode.runtimeName
					.. ":"
					.. providerNode.providerName,
				Validation.decision(candidate) == (runtimeIndex == providerIndex),
				"provider matrix mismatch",
				checks
			)
			local req = requirement("decision.seed", "requirement.matrix", runtimeIndex)
			req.providerName = providerNode.providerName
			expect(
				"requirement provider matrix "
					.. runtimeNode.runtimeName
					.. ":"
					.. providerNode.providerName,
				Validation.requirement(req) == (runtimeIndex == providerIndex),
				"provider matrix mismatch",
				checks
			)
			local eval =
				evaluation("decision.seed", "requirement.seed", "evaluation.matrix", runtimeIndex)
			eval.snapshotProviderName = providerNode.snapshotProviderName
			expect(
				"evaluation snapshot matrix "
					.. runtimeNode.runtimeName
					.. ":"
					.. providerNode.snapshotProviderName,
				Validation.evaluation(eval) == (runtimeIndex == providerIndex),
				"snapshot matrix mismatch",
				checks
			)
		end
	end
	for _, decisionKind in ipairs(arrayValues(Types.DecisionKind)) do
		for _, decisionStatus in ipairs(arrayValues(Types.DecisionStatus)) do
			expectAccept(
				"decision enum matrix " .. decisionKind .. ":" .. decisionStatus,
				Validation.decision(
					withField(
						withField(seedDecision, "decisionKind", decisionKind),
						"decisionStatus",
						decisionStatus
					)
				),
				nil,
				checks
			)
		end
	end
	for _, requirementKind in ipairs(arrayValues(Types.RequirementKind)) do
		for _, requirementStatus in ipairs(arrayValues(Types.RequirementStatus)) do
			expectAccept(
				"requirement enum matrix " .. requirementKind .. ":" .. requirementStatus,
				Validation.requirement(
					withField(
						withField(seedRequirement, "requirementKind", requirementKind),
						"requirementStatus",
						requirementStatus
					)
				),
				nil,
				checks
			)
		end
	end
	for _, evaluationKind in ipairs(arrayValues(Types.EvaluationKind)) do
		for _, evaluationStatus in ipairs(arrayValues(Types.EvaluationStatus)) do
			expectAccept(
				"evaluation enum matrix " .. evaluationKind .. ":" .. evaluationStatus,
				Validation.evaluation(
					withField(
						withField(seedEvaluation, "evaluationKind", evaluationKind),
						"evaluationStatus",
						evaluationStatus
					)
				),
				nil,
				checks
			)
		end
	end
	for _, auditKind in ipairs(arrayValues(Types.AuditKind)) do
		for _, auditStatus in ipairs(arrayValues(Types.AuditStatus)) do
			expectAccept(
				"audit enum matrix " .. auditKind .. ":" .. auditStatus,
				Validation.audit(
					withField(
						withField(seedAudit, "auditKind", auditKind),
						"auditStatus",
						auditStatus
					)
				),
				nil,
				checks
			)
		end
	end
end

local function validationHardeningMatrices(checks: { CheckResult })
	local invalidIds = {
		"",
		"bad/id",
		"bad id",
		"bad#id",
		string.rep("a", 151),
		{},
		7,
		true,
	}
	for index, invalidId in ipairs(invalidIds) do
		expectReject(
			"decision rejects invalid decisionId " .. tostring(index),
			Validation.decision(withField(decision("decision.invalid", 1), "decisionId", invalidId)),
			nil,
			checks
		)
		expectReject(
			"decision rejects invalid inspectionId " .. tostring(index),
			Validation.decision(
				withField(decision("decision.invalid.inspection", 1), "inspectionId", invalidId)
			),
			nil,
			checks
		)
		expectReject(
			"requirement rejects invalid requirementId " .. tostring(index),
			Validation.requirement(
				withField(
					requirement("decision.seed", "requirement.invalid", 1),
					"requirementId",
					invalidId
				)
			),
			nil,
			checks
		)
		expectReject(
			"requirement rejects invalid decisionId " .. tostring(index),
			Validation.requirement(
				withField(
					requirement("decision.seed", "requirement.invalid.decision", 1),
					"decisionId",
					invalidId
				)
			),
			nil,
			checks
		)
		expectReject(
			"evaluation rejects invalid evaluationId " .. tostring(index),
			Validation.evaluation(
				withField(
					evaluation("decision.seed", "requirement.seed", "evaluation.invalid", 1),
					"evaluationId",
					invalidId
				)
			),
			nil,
			checks
		)
		expectReject(
			"evaluation rejects invalid decisionId " .. tostring(index),
			Validation.evaluation(
				withField(
					evaluation(
						"decision.seed",
						"requirement.seed",
						"evaluation.invalid.decision",
						1
					),
					"decisionId",
					invalidId
				)
			),
			nil,
			checks
		)
		expectReject(
			"evaluation rejects invalid requirementId " .. tostring(index),
			Validation.evaluation(
				withField(
					evaluation(
						"decision.seed",
						"requirement.seed",
						"evaluation.invalid.requirement",
						1
					),
					"requirementId",
					invalidId
				)
			),
			nil,
			checks
		)
		expectReject(
			"audit rejects invalid auditId " .. tostring(index),
			Validation.audit(
				withField(audit("decision.seed", "audit.invalid", {}), "auditId", invalidId)
			),
			nil,
			checks
		)
		expectReject(
			"audit rejects invalid decisionId " .. tostring(index),
			Validation.audit(
				withField(
					audit("decision.seed", "audit.invalid.decision", {}),
					"decisionId",
					invalidId
				)
			),
			nil,
			checks
		)
		expectReject(
			"audit rejects invalid reviewer " .. tostring(index),
			Validation.audit(
				withField(
					audit("decision.seed", "audit.invalid.reviewer", {}),
					"reviewer",
					invalidId
				)
			),
			nil,
			checks
		)
	end
	local invalidEnums = {
		"Unknown",
		"Approve",
		"Reject",
		"Execute",
		"Repair",
		"Schedule",
		"Orchestrate",
		"Mutable",
	}
	for _, invalidEnum in ipairs(invalidEnums) do
		expectReject(
			"decision rejects invalid decisionKind " .. invalidEnum,
			Validation.decision(
				withField(decision("decision.invalid.kind", 1), "decisionKind", invalidEnum)
			),
			nil,
			checks
		)
		expectReject(
			"decision rejects invalid decisionStatus " .. invalidEnum,
			Validation.decision(
				withField(decision("decision.invalid.status", 1), "decisionStatus", invalidEnum)
			),
			nil,
			checks
		)
		expectReject(
			"requirement rejects invalid requirementKind " .. invalidEnum,
			Validation.requirement(
				withField(
					requirement("decision.seed", "requirement.invalid.kind", 1),
					"requirementKind",
					invalidEnum
				)
			),
			nil,
			checks
		)
		expectReject(
			"requirement rejects invalid requirementStatus " .. invalidEnum,
			Validation.requirement(
				withField(
					requirement("decision.seed", "requirement.invalid.status", 1),
					"requirementStatus",
					invalidEnum
				)
			),
			nil,
			checks
		)
		expectReject(
			"evaluation rejects invalid evaluationKind " .. invalidEnum,
			Validation.evaluation(
				withField(
					evaluation("decision.seed", "requirement.seed", "evaluation.invalid.kind", 1),
					"evaluationKind",
					invalidEnum
				)
			),
			nil,
			checks
		)
		expectReject(
			"evaluation rejects invalid evaluationStatus " .. invalidEnum,
			Validation.evaluation(
				withField(
					evaluation("decision.seed", "requirement.seed", "evaluation.invalid.status", 1),
					"evaluationStatus",
					invalidEnum
				)
			),
			nil,
			checks
		)
		expectReject(
			"audit rejects invalid auditKind " .. invalidEnum,
			Validation.audit(
				withField(
					audit("decision.seed", "audit.invalid.kind", {}),
					"auditKind",
					invalidEnum
				)
			),
			nil,
			checks
		)
		expectReject(
			"audit rejects invalid auditStatus " .. invalidEnum,
			Validation.audit(
				withField(
					audit("decision.seed", "audit.invalid.status", {}),
					"auditStatus",
					invalidEnum
				)
			),
			nil,
			checks
		)
	end
	local oversizedChildIds = {}
	for index = 1, Types.Limits.MaxDecisionChildren + 1 do
		table.insert(oversizedChildIds, "child." .. tostring(index))
	end
	local oversizedEvidence = {}
	for index = 1, Types.Limits.MaxEvidence + 1 do
		table.insert(oversizedEvidence, "evidence." .. tostring(index))
	end
	local oversizedTags = {}
	for index = 1, Types.Limits.MaxTags + 1 do
		table.insert(oversizedTags, "tag." .. tostring(index))
	end
	for _, schemaSet in ipairs({
		{
			name = "decision",
			schema = decision("decision.limit", 1),
			validate = Validation.decision,
		},
		{
			name = "requirement",
			schema = requirement("decision.seed", "requirement.limit", 1),
			validate = Validation.requirement,
		},
		{
			name = "evaluation",
			schema = evaluation("decision.seed", "requirement.seed", "evaluation.limit", 1),
			validate = Validation.evaluation,
		},
		{
			name = "audit",
			schema = audit("decision.seed", "audit.limit", {}),
			validate = Validation.audit,
		},
	}) do
		expectReject(
			schemaSet.name .. " rejects oversized evidence",
			schemaSet.validate(withField(schemaSet.schema, "evidence", oversizedEvidence)),
			nil,
			checks
		)
		expectReject(
			schemaSet.name .. " rejects oversized tags",
			schemaSet.validate(withField(schemaSet.schema, "tags", oversizedTags)),
			nil,
			checks
		)
	end
	expectReject(
		"decision rejects oversized requirement children",
		Validation.decision(
			withField(
				decision("decision.limit.requirements", 1),
				"requirementIds",
				oversizedChildIds
			)
		),
		nil,
		checks
	)
	expectReject(
		"decision rejects oversized evaluation children",
		Validation.decision(
			withField(decision("decision.limit.evaluations", 1), "evaluationIds", oversizedChildIds)
		),
		nil,
		checks
	)
	expectReject(
		"decision rejects oversized audit children",
		Validation.decision(
			withField(decision("decision.limit.audits", 1), "auditIds", oversizedChildIds)
		),
		nil,
		checks
	)
	expectReject(
		"audit rejects oversized evaluation children",
		Validation.audit(
			withField(
				audit("decision.seed", "audit.limit.children", {}),
				"evaluationIds",
				oversizedChildIds
			)
		),
		nil,
		checks
	)
	local cycle = {}
	cycle.self = cycle
	for _, unsafePayload in ipairs({
		{ label = "cycle", value = cycle },
		{ label = "instance shaped", value = { ClassName = "Folder", Parent = {} } },
		{ label = "function", value = { fn = function() end } },
		{
			label = "deep",
			value = { a = { b = { c = { d = { e = { f = { g = { h = { i = {} } } } } } } } } },
		},
	}) do
		expectReject(
			"decision rejects unsafe metadata " .. unsafePayload.label,
			Validation.decision(
				withField(
					decision("decision.unsafe." .. unsafePayload.label, 1),
					"metadata",
					unsafePayload.value
				)
			),
			nil,
			checks
		)
		expectReject(
			"requirement rejects unsafe metadata " .. unsafePayload.label,
			Validation.requirement(
				withField(
					requirement("decision.seed", "requirement.unsafe." .. unsafePayload.label, 1),
					"metadata",
					unsafePayload.value
				)
			),
			nil,
			checks
		)
		expectReject(
			"evaluation rejects unsafe metadata " .. unsafePayload.label,
			Validation.evaluation(
				withField(
					evaluation(
						"decision.seed",
						"requirement.seed",
						"evaluation.unsafe." .. unsafePayload.label,
						1
					),
					"metadata",
					unsafePayload.value
				)
			),
			nil,
			checks
		)
		expectReject(
			"audit rejects unsafe metadata " .. unsafePayload.label,
			Validation.audit(
				withField(
					audit("decision.seed", "audit.unsafe." .. unsafePayload.label, {}),
					"metadata",
					unsafePayload.value
				)
			),
			nil,
			checks
		)
	end
end

local function forbiddenPayloads(checks: { CheckResult })
	for markerIndex, marker in ipairs(Serialization.forbiddenMarkers()) do
		local markerField = "metadata"
		local markerValue = { marker = marker }
		local markerKey = {}
		markerKey[marker] = true
		expectReject(
			"decision rejects forbidden metadata value marker " .. marker,
			Validation.decision(
				withField(
					decision("decision.forbidden." .. tostring(markerIndex), 1),
					markerField,
					markerValue
				)
			),
			nil,
			checks
		)
		expectReject(
			"decision rejects forbidden metadata key marker " .. marker,
			Validation.decision(
				withField(
					decision("decision.forbidden.key." .. tostring(markerIndex), 1),
					markerField,
					markerKey
				)
			),
			nil,
			checks
		)
		expectReject(
			"decision rejects forbidden evidence marker " .. marker,
			Validation.decision(
				withField(
					decision("decision.forbidden.evidence." .. tostring(markerIndex), 1),
					"evidence",
					{ marker }
				)
			),
			nil,
			checks
		)
		expectReject(
			"decision rejects forbidden tag marker " .. marker,
			Validation.decision(
				withField(
					decision("decision.forbidden.tag." .. tostring(markerIndex), 1),
					"tags",
					{ marker }
				)
			),
			nil,
			checks
		)
		expectReject(
			"requirement rejects forbidden metadata value marker " .. marker,
			Validation.requirement(
				withField(
					requirement(
						"decision.seed",
						"requirement.forbidden." .. tostring(markerIndex),
						1
					),
					markerField,
					markerValue
				)
			),
			nil,
			checks
		)
		expectReject(
			"requirement rejects forbidden metadata key marker " .. marker,
			Validation.requirement(
				withField(
					requirement(
						"decision.seed",
						"requirement.forbidden.key." .. tostring(markerIndex),
						1
					),
					markerField,
					markerKey
				)
			),
			nil,
			checks
		)
		expectReject(
			"requirement rejects forbidden evidence marker " .. marker,
			Validation.requirement(
				withField(
					requirement(
						"decision.seed",
						"requirement.forbidden.evidence." .. tostring(markerIndex),
						1
					),
					"evidence",
					{ marker }
				)
			),
			nil,
			checks
		)
		expectReject(
			"requirement rejects forbidden tag marker " .. marker,
			Validation.requirement(
				withField(
					requirement(
						"decision.seed",
						"requirement.forbidden.tag." .. tostring(markerIndex),
						1
					),
					"tags",
					{ marker }
				)
			),
			nil,
			checks
		)
		expectReject(
			"evaluation rejects forbidden metadata value marker " .. marker,
			Validation.evaluation(
				withField(
					evaluation(
						"decision.seed",
						"requirement.seed",
						"evaluation.forbidden." .. tostring(markerIndex),
						1
					),
					markerField,
					markerValue
				)
			),
			nil,
			checks
		)
		expectReject(
			"evaluation rejects forbidden metadata key marker " .. marker,
			Validation.evaluation(
				withField(
					evaluation(
						"decision.seed",
						"requirement.seed",
						"evaluation.forbidden.key." .. tostring(markerIndex),
						1
					),
					markerField,
					markerKey
				)
			),
			nil,
			checks
		)
		expectReject(
			"evaluation rejects forbidden evidence marker " .. marker,
			Validation.evaluation(
				withField(
					evaluation(
						"decision.seed",
						"requirement.seed",
						"evaluation.forbidden.evidence." .. tostring(markerIndex),
						1
					),
					"evidence",
					{ marker }
				)
			),
			nil,
			checks
		)
		expectReject(
			"evaluation rejects forbidden tag marker " .. marker,
			Validation.evaluation(
				withField(
					evaluation(
						"decision.seed",
						"requirement.seed",
						"evaluation.forbidden.tag." .. tostring(markerIndex),
						1
					),
					"tags",
					{ marker }
				)
			),
			nil,
			checks
		)
		expectReject(
			"audit rejects forbidden metadata value marker " .. marker,
			Validation.audit(
				withField(
					audit("decision.seed", "audit.forbidden." .. tostring(markerIndex), {}),
					markerField,
					markerValue
				)
			),
			nil,
			checks
		)
		expectReject(
			"audit rejects forbidden metadata key marker " .. marker,
			Validation.audit(
				withField(
					audit("decision.seed", "audit.forbidden.key." .. tostring(markerIndex), {}),
					markerField,
					markerKey
				)
			),
			nil,
			checks
		)
		expectReject(
			"audit rejects forbidden evidence marker " .. marker,
			Validation.audit(
				withField(
					audit("decision.seed", "audit.forbidden.evidence." .. tostring(markerIndex), {}),
					"evidence",
					{ marker }
				)
			),
			nil,
			checks
		)
		expectReject(
			"audit rejects forbidden tag marker " .. marker,
			Validation.audit(
				withField(
					audit("decision.seed", "audit.forbidden.tag." .. tostring(markerIndex), {}),
					"tags",
					{ marker }
				)
			),
			nil,
			checks
		)
	end
end

local function extendedMatrixCoverage(checks: { CheckResult })
	for runtimeIndex, runtimeNode in ipairs(Types.CertifiedRuntimeOrder) do
		expect(
			"runtime lookup name " .. runtimeNode.runtimeName,
			Types.RuntimeName[runtimeNode.runtimeName] == runtimeIndex,
			"runtime lookup drift",
			checks
		)
		expect(
			"provider lookup name " .. runtimeNode.providerName,
			Types.ProviderName[runtimeNode.providerName] == runtimeIndex,
			"provider lookup drift",
			checks
		)
		expect(
			"snapshot lookup name " .. runtimeNode.snapshotProviderName,
			Types.SnapshotProviderName[runtimeNode.snapshotProviderName] == runtimeIndex,
			"snapshot lookup drift",
			checks
		)
		expect(
			"coordinator lookup name " .. runtimeNode.coordinatorName,
			Types.CoordinatorName[runtimeNode.coordinatorName] == runtimeIndex,
			"coordinator lookup drift",
			checks
		)
		expect(
			"documentation lookup name " .. runtimeNode.documentationReference,
			Types.DocumentationReference[runtimeNode.documentationReference] == runtimeIndex,
			"documentation lookup drift",
			checks
		)
		for _, decisionKind in ipairs(arrayValues(Types.DecisionKind)) do
			for _, decisionStatus in ipairs(arrayValues(Types.DecisionStatus)) do
				expectAccept(
					"decision runtime enum matrix "
						.. runtimeNode.runtimeName
						.. ":"
						.. decisionKind
						.. ":"
						.. decisionStatus,
					Validation.decision(
						withField(
							withField(
								decision(
									"decision.runtime.enum." .. tostring(runtimeIndex),
									runtimeIndex
								),
								"decisionKind",
								decisionKind
							),
							"decisionStatus",
							decisionStatus
						)
					),
					nil,
					checks
				)
			end
		end
		for _, requirementKind in ipairs(arrayValues(Types.RequirementKind)) do
			for _, requirementStatus in ipairs(arrayValues(Types.RequirementStatus)) do
				expectAccept(
					"requirement runtime enum matrix "
						.. runtimeNode.runtimeName
						.. ":"
						.. requirementKind
						.. ":"
						.. requirementStatus,
					Validation.requirement(
						withField(
							withField(
								requirement(
									"decision.seed",
									"requirement.runtime.enum." .. tostring(runtimeIndex),
									runtimeIndex
								),
								"requirementKind",
								requirementKind
							),
							"requirementStatus",
							requirementStatus
						)
					),
					nil,
					checks
				)
			end
		end
		for _, evaluationKind in ipairs(arrayValues(Types.EvaluationKind)) do
			for _, evaluationStatus in ipairs(arrayValues(Types.EvaluationStatus)) do
				expectAccept(
					"evaluation runtime enum matrix "
						.. runtimeNode.runtimeName
						.. ":"
						.. evaluationKind
						.. ":"
						.. evaluationStatus,
					Validation.evaluation(
						withField(
							withField(
								evaluation(
									"decision.seed",
									"requirement.seed",
									"evaluation.runtime.enum." .. tostring(runtimeIndex),
									runtimeIndex
								),
								"evaluationKind",
								evaluationKind
							),
							"evaluationStatus",
							evaluationStatus
						)
					),
					nil,
					checks
				)
			end
		end
		for _, auditKind in ipairs(arrayValues(Types.AuditKind)) do
			for _, auditStatus in ipairs(arrayValues(Types.AuditStatus)) do
				expectAccept(
					"audit certified runtime enum matrix "
						.. runtimeNode.runtimeName
						.. ":"
						.. auditKind
						.. ":"
						.. auditStatus,
					Validation.audit(
						withField(
							withField(
								audit(
									"decision.seed",
									"audit.runtime.enum." .. tostring(runtimeIndex),
									{}
								),
								"auditKind",
								auditKind
							),
							"auditStatus",
							auditStatus
						)
					),
					nil,
					checks
				)
			end
		end
		for providerIndex, providerNode in ipairs(Types.CertifiedRuntimeOrder) do
			local decisionProvider = decision("decision.provider.matrix", runtimeIndex)
			decisionProvider.snapshotProviderName = providerNode.snapshotProviderName
			expect(
				"decision snapshot provider matrix "
					.. runtimeNode.runtimeName
					.. ":"
					.. providerNode.snapshotProviderName,
				Validation.decision(decisionProvider) == (runtimeIndex == providerIndex),
				"decision snapshot matrix mismatch",
				checks
			)
			local requirementProvider =
				requirement("decision.seed", "requirement.provider.matrix", runtimeIndex)
			requirementProvider.snapshotProviderName = providerNode.snapshotProviderName
			expect(
				"requirement snapshot provider matrix "
					.. runtimeNode.runtimeName
					.. ":"
					.. providerNode.snapshotProviderName,
				Validation.requirement(requirementProvider) == (runtimeIndex == providerIndex),
				"requirement snapshot matrix mismatch",
				checks
			)
			local evaluationProvider = evaluation(
				"decision.seed",
				"requirement.seed",
				"evaluation.provider.matrix",
				runtimeIndex
			)
			evaluationProvider.providerName = providerNode.providerName
			expect(
				"evaluation provider matrix "
					.. runtimeNode.runtimeName
					.. ":"
					.. providerNode.providerName,
				Validation.evaluation(evaluationProvider) == (runtimeIndex == providerIndex),
				"evaluation provider matrix mismatch",
				checks
			)
			local decisionRuntime = decision("decision.runtime.matrix", runtimeIndex)
			decisionRuntime.runtimeName = providerNode.runtimeName
			expect(
				"decision runtime name matrix "
					.. runtimeNode.runtimeName
					.. ":"
					.. providerNode.runtimeName,
				Validation.decision(decisionRuntime) == (runtimeIndex == providerIndex),
				"decision runtime matrix mismatch",
				checks
			)
			local requirementRuntime =
				requirement("decision.seed", "requirement.runtime.matrix", runtimeIndex)
			requirementRuntime.runtimeName = providerNode.runtimeName
			expect(
				"requirement runtime name matrix "
					.. runtimeNode.runtimeName
					.. ":"
					.. providerNode.runtimeName,
				Validation.requirement(requirementRuntime) == (runtimeIndex == providerIndex),
				"requirement runtime matrix mismatch",
				checks
			)
			local evaluationRuntime = evaluation(
				"decision.seed",
				"requirement.seed",
				"evaluation.runtime.matrix",
				runtimeIndex
			)
			evaluationRuntime.runtimeName = providerNode.runtimeName
			expect(
				"evaluation runtime name matrix "
					.. runtimeNode.runtimeName
					.. ":"
					.. providerNode.runtimeName,
				Validation.evaluation(evaluationRuntime) == (runtimeIndex == providerIndex),
				"evaluation runtime matrix mismatch",
				checks
			)
		end
	end
end

local function stateBehavior(checks: { CheckResult })
	State.clear()
	local decisionSchema = decision("decision.state", 1)
	expectAccept("state registers decision", State.registerDecision(decisionSchema), nil, checks)
	expectReject(
		"state rejects duplicate decision",
		State.registerDecision(decisionSchema),
		nil,
		checks
	)
	local requirementSchema = requirement("decision.state", "requirement.state", 1)
	expectAccept(
		"state registers requirement",
		State.registerRequirement(requirementSchema),
		nil,
		checks
	)
	expectReject(
		"state rejects duplicate requirement",
		State.registerRequirement(requirementSchema),
		nil,
		checks
	)
	local evaluationSchema =
		evaluation("decision.state", "requirement.state", "evaluation.state", 1)
	expectAccept(
		"state registers evaluation",
		State.registerEvaluation(evaluationSchema),
		nil,
		checks
	)
	expectReject(
		"state rejects duplicate evaluation",
		State.registerEvaluation(evaluationSchema),
		nil,
		checks
	)
	local auditSchema = audit("decision.state", "audit.state", { "evaluation.state" })
	expectAccept("state registers audit", State.registerAudit(auditSchema), nil, checks)
	expectReject("state rejects duplicate audit", State.registerAudit(auditSchema), nil, checks)
	expectReject(
		"requirement missing decision rejects",
		State.registerRequirement(requirement("missing.decision", "requirement.missing", 1)),
		nil,
		checks
	)
	expectReject(
		"evaluation missing decision rejects",
		State.registerEvaluation(
			evaluation("missing.decision", "requirement.state", "evaluation.missing.decision", 1)
		),
		nil,
		checks
	)
	expectReject(
		"evaluation missing requirement rejects",
		State.registerEvaluation(
			evaluation("decision.state", "missing.requirement", "evaluation.missing.requirement", 1)
		),
		nil,
		checks
	)
	expectReject(
		"audit missing evaluation rejects",
		State.registerAudit(audit("decision.state", "audit.missing", { "missing.evaluation" })),
		nil,
		checks
	)
	local before = State.inspect().counts
	expectReject(
		"failed validation no mutation",
		State.registerRequirement(withField(requirementSchema, "providerName", "badProvider")),
		nil,
		checks
	)
	local after = State.inspect().counts
	expect(
		"failed validation preserved requirement count",
		before.requirements == after.requirements,
		"failed validation mutated state",
		checks
	)
	local copy = State.inspect()
	copy.decisions["decision.state"].metadata.copied = false
	expect(
		"state inspect deep copy",
		State.inspect().decisions["decision.state"].metadata.copied == true,
		"state leaked mutable reference",
		checks
	)
	State.recordValidationFailure("unsafe", { fn = function() end })
	expect(
		"validation failure sanitized",
		State.inspect().validationFailures[1].payload == "<unsafe-payload>",
		"unsafe diagnostic leaked",
		checks
	)
	State.clear()
	expect("clear resets decisions", State.inspect().counts.decisions == 0, "clear failed", checks)
	expect(
		"clear resets requirements",
		State.inspect().counts.requirements == 0,
		"clear failed",
		checks
	)
	expect(
		"clear resets evaluations",
		State.inspect().counts.evaluations == 0,
		"clear failed",
		checks
	)
	expect("clear resets audits", State.inspect().counts.audits == 0, "clear failed", checks)
end

local function boundedHistoryBehavior(checks: { CheckResult })
	State.clear()
	for index = 1, Types.Limits.MaxValidationFailures + 25 do
		State.recordValidationFailure("bounded." .. tostring(index), { index = index })
	end
	expect(
		"validation failure history bounded",
		State.inspect().counts.validationFailures == Types.Limits.MaxValidationFailures,
		"validation failure history exceeded limit",
		checks
	)
	State.recordValidationFailure("bounded.unsafe", { callback = function() end })
	expect(
		"bounded validation failure sanitized unsafe payload",
		State.inspect().validationFailures[Types.Limits.MaxValidationFailures].payload
			== "<unsafe-payload>",
		"unsafe bounded validation payload leaked",
		checks
	)
	local lifecycle = { initialized = true, started = false, lastSelfChecks = nil }
	local dependencies = { Serialization = Serialization, State = State, Validation = Validation }
	for index = 1, Types.Limits.MaxSnapshotHistory + 15 do
		local snapshot = Snapshots.capture(lifecycle, dependencies)
		expect(
			"snapshot capture kind bounded " .. tostring(index),
			snapshot.kind == Types.SnapshotKind,
			"snapshot kind drifted",
			checks
		)
	end
	expect(
		"snapshot history bounded",
		State.inspect().counts.snapshots == Types.Limits.MaxSnapshotHistory,
		"snapshot history exceeded limit",
		checks
	)
	State.clear()
end

local function noAuthorityBehavior(checks: { CheckResult })
	local lifecycle = { initialized = true, started = false, lastSelfChecks = { ok = true } }
	local dependencies = { Serialization = Serialization, State = State, Validation = Validation }
	local diag = Diagnostics.capture(lifecycle, dependencies)
	local snapshot = Snapshots.capture(lifecycle, dependencies)
	for _, source in ipairs({
		{ name = "diagnostics", report = diag },
		{ name = "snapshot", report = snapshot },
	}) do
		expect(
			source.name .. " no authorization posture",
			source.report.noAuthorityPosture.noAuthorization == true
				and source.report.noAuthorizationPosture ~= nil,
			"authorization posture drift",
			checks
		)
		expect(
			source.name .. " no approval posture",
			source.report.noAuthorityPosture.noApproval == true
				and source.report.noApprovalPosture ~= nil,
			"approval posture drift",
			checks
		)
		expect(
			source.name .. " no rejection posture",
			source.report.noAuthorityPosture.noRejectionAuthority == true
				and source.report.noRejectionPosture ~= nil,
			"rejection posture drift",
			checks
		)
		expect(
			source.name .. " no repair posture",
			source.report.noAuthorityPosture.noRepair == true
				and source.report.noRepairPosture ~= nil,
			"repair posture drift",
			checks
		)
		expect(
			source.name .. " no execution posture",
			source.report.noAuthorityPosture.noExecution == true
				and source.report.noExecutionPosture ~= nil,
			"execution posture drift",
			checks
		)
		expect(
			source.name .. " no orchestration posture",
			source.report.noAuthorityPosture.noOrchestration == true
				and source.report.noOrchestrationPosture ~= nil,
			"orchestration posture drift",
			checks
		)
		expect(
			source.name .. " no scheduling posture",
			source.report.noAuthorityPosture.noScheduling == true
				and source.report.noSchedulingPosture ~= nil,
			"scheduling posture drift",
			checks
		)
		expect(
			source.name .. " no persistence posture",
			source.report.noAuthorityPosture.noPersistence == true,
			"persistence posture drift",
			checks
		)
		expect(
			source.name .. " no networking posture",
			source.report.noAuthorityPosture.noNetworking == true,
			"networking posture drift",
			checks
		)
		expect(
			source.name .. " no gameplay posture",
			source.report.noAuthorityPosture.noGameplay == true,
			"gameplay posture drift",
			checks
		)
	end
	snapshot.schemas.decisions["mutated"] = { unsafe = true }
	expect(
		"snapshot schema table isolated",
		Snapshots.capture(lifecycle, dependencies).schemas.decisions["mutated"] == nil,
		"snapshot schema table leaked",
		checks
	)
	State.clear()
end

local function reportBehavior(context: any, checks: { CheckResult })
	State.clear()
	local lifecycle =
		{ initialized = true, started = false, lastSelfChecks = { ok = true, total = 1 } }
	local dependencies = { Serialization = Serialization, State = State, Validation = Validation }
	local diag = Diagnostics.capture(lifecycle, dependencies)
	expect(
		"diagnostics provider posture",
		diag.providerPosture == Types.RuntimeProviderName,
		"provider drift",
		checks
	)
	expect("diagnostics health only", diag.health == "Healthy", "health drift", checks)
	for _, key in ipairs(Types.PostureKeys) do
		expect(
			"diagnostics posture key exists " .. key,
			diag[key] ~= nil,
			"missing posture key",
			checks
		)
	end
	diag.decisionEvidencePosture[1].runtimeName = "Mutated"
	expect(
		"diagnostics evidence isolated",
		Diagnostics.capture(lifecycle, dependencies).decisionEvidencePosture[1].runtimeName
			~= "Mutated",
		"diagnostics leaked mutable table",
		checks
	)
	diag.integrationReadinessDeclarations[1].runtimeName = "Mutated"
	expect(
		"diagnostics integration declarations isolated",
		Diagnostics.capture(lifecycle, dependencies).integrationReadinessDeclarations[1].runtimeName
			~= "Mutated",
		"diagnostics leaked integration metadata",
		checks
	)
	local snapshot = Snapshots.capture(lifecycle, dependencies)
	expect("snapshot kind", snapshot.kind == Types.SnapshotKind, "snapshot drift", checks)
	for _, key in ipairs(Types.PostureKeys) do
		expect(
			"snapshot posture key exists " .. key,
			snapshot[key] ~= nil,
			"missing posture key",
			checks
		)
	end
	snapshot.noAuthorityPosture.noExecution = false
	expect(
		"snapshot isolated",
		Snapshots.capture(lifecycle, dependencies).noAuthorityPosture.noExecution == true,
		"snapshot leaked mutable table",
		checks
	)
	snapshot.integrationReadinessDeclarations[1].providerName = "Mutated"
	expect(
		"snapshot integration declarations isolated",
		Snapshots.capture(lifecycle, dependencies).integrationReadinessDeclarations[1].providerName
			~= "Mutated",
		"snapshot leaked integration metadata",
		checks
	)
	expect(
		"signals initialized",
		Signals.RuntimeInitialized == "AssetGovernanceCertificationDecision.RuntimeInitialized",
		"signal drift",
		checks
	)
	if context.Service ~= nil then
		local service = context.Service
		service.shutdown()
		expectAccept("service initializes", service.initialize().ok, nil, checks)
		expectAccept("service double initialize safe", service.initialize().ok, nil, checks)
		expectAccept("service starts", service.start().ok, nil, checks)
		expectReject(
			"service self-check blocked after start",
			service.runSelfChecks().ok,
			nil,
			checks
		)
		expectAccept("service shutdown cleans", service.shutdown().ok, nil, checks)
		expect(
			"service shutdown reset",
			service.inspect().counts.decisions == 0,
			"shutdown did not clear state",
			checks
		)
	end
end

function SelfChecks.run(context: any?)
	local checks: { CheckResult } = {}
	exactSurfaces(checks)
	integrationReadinessBehavior(checks)
	integrationHardeningBehavior(checks)
	executionReadinessBehavior(checks)
	validationBehavior(checks)
	validationHardeningMatrices(checks)
	forbiddenPayloads(checks)
	extendedMatrixCoverage(checks)
	stateBehavior(checks)
	boundedHistoryBehavior(checks)
	noAuthorityBehavior(checks)
	reportBehavior(context or {}, checks)
	local failed = {}
	for _, check in ipairs(checks) do
		if not check.ok then
			table.insert(failed, check)
		end
	end
	return {
		ok = #failed == 0,
		code = if #failed == 0
			then "AssetGovernanceCertificationDecisionSelfChecksPassed"
			else "AssetGovernanceCertificationDecisionSelfChecksFailed",
		total = #checks,
		failed = failed,
	}
end

return SelfChecks
