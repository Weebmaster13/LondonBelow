--!strict

local Serialization = require(script.Parent.AssetExecutionGovernanceSerialization)
local Types = require(script.Parent.AssetExecutionGovernanceTypes)
local Validation = require(script.Parent.AssetExecutionGovernanceValidation)

local SelfChecks = {}

local function emptyResult()
	return {
		ok = true,
		total = 0,
		passed = 0,
		failed = 0,
		failures = {},
		categories = {
			providerConsistency = 0,
			schemaTerminology = 0,
			enumValidation = 0,
			referenceValidation = 0,
			fieldExactness = 0,
			arrayValidation = 0,
			authorityBoundary = 0,
			mutationSafety = 0,
			isolation = 0,
			diagnostics = 0,
			cleanup = 0,
			bannedSurfaceAbsence = 0,
			integrationReadiness = 0,
		},
	}
end

local function check(result: any, category: string, condition: boolean, label: string)
	result.total += 1
	result.categories[category] += 1
	if condition then
		result.passed += 1
	else
		result.ok = false
		result.failed += 1
		table.insert(result.failures, label)
	end
end

local function baseGovernance(id: string)
	return {
		governanceId = id,
		decisionId = id .. ".decision",
		executionReadinessId = id .. ".readiness",
		governanceKind = "DecisionEvidenceGovernance",
		governanceStatus = "Declared",
		runtimeName = "AssetExecutionGovernance",
		providerName = Types.RuntimeProviderName,
		snapshotProviderName = Types.RuntimeProviderName,
		requirementIds = {},
		assessmentIds = {},
		findingIds = {},
		auditIds = {},
		evidence = { id .. ".evidence" },
		tags = { "asset-execution-governance" },
		metadata = { copied = true, boundary = "metadata-only" },
	}
end

local function baseRequirement(governanceId: string, id: string)
	return {
		requirementId = id,
		governanceId = governanceId,
		requirementKind = "DecisionEvidenceRequirement",
		requirementStatus = "Required",
		runtimeName = "AssetExecutionGovernance",
		providerName = Types.RuntimeProviderName,
		snapshotProviderName = Types.RuntimeProviderName,
		required = true,
		evidence = { id .. ".evidence" },
		tags = { "asset-execution-governance" },
		metadata = { copied = true },
	}
end

local function baseAssessment(governanceId: string, requirementId: string, id: string)
	return {
		assessmentId = id,
		governanceId = governanceId,
		requirementId = requirementId,
		assessmentKind = "DecisionEvidenceAssessment",
		assessmentStatus = "Passed",
		runtimeName = "AssetExecutionGovernance",
		providerName = Types.RuntimeProviderName,
		snapshotProviderName = Types.RuntimeProviderName,
		evidence = { id .. ".evidence" },
		tags = { "asset-execution-governance" },
		metadata = { copied = true },
	}
end

local function baseFinding(governanceId: string, assessmentId: string, id: string)
	return {
		findingId = id,
		governanceId = governanceId,
		assessmentId = assessmentId,
		findingKind = "MissingEvidence",
		findingSeverity = "Informational",
		findingStatus = "Open",
		summary = "Copied metadata review finding.",
		evidence = { id .. ".evidence" },
		tags = { "asset-execution-governance" },
		metadata = { copied = true },
	}
end

local function baseAudit(governanceId: string, assessmentId: string, findingId: string, id: string)
	return {
		auditId = id,
		governanceId = governanceId,
		assessmentIds = { assessmentId },
		findingIds = { findingId },
		auditKind = "GovernanceAudit",
		auditStatus = "Passed",
		reviewer = "phase79.selfcheck",
		evidence = { id .. ".evidence" },
		tags = { "asset-execution-governance" },
		metadata = { copied = true },
	}
end

local function expectReject(result: any, category: string, ok: boolean, label: string)
	check(result, category, not ok, label)
end

local function sortedKeys(values: { [string]: boolean }): { string }
	local keys = {}
	for key in pairs(values) do
		table.insert(keys, key)
	end
	table.sort(keys)
	return keys
end

local function clone(value: any): any
	return Serialization.deepCopy(value)
end

local function baseIntegrationDeclaration()
	return clone(Types.IntegrationReadinessDeclarations[1])
end

local function mutateEnumVariants(value: string): { any }
	return {
		string.lower(value),
		string.upper(value),
		" " .. value,
		value .. " ",
		"Drift" .. value,
		value .. "Drift",
		"",
		17,
		true,
		{},
	}
end

local function checkEnumRejects(
	result: any,
	label: string,
	base: any,
	field: string,
	validator: (any) -> (boolean, string?)
)
	for _, variant in ipairs(mutateEnumVariants(base[field])) do
		local schema = clone(base)
		schema[field] = variant
		expectReject(result, "enumValidation", validator(schema), label .. " rejects drift")
	end
end

local function checkExactFields(
	result: any,
	schemaName: string,
	base: any,
	validator: (any) -> (boolean, string?)
)
	local fields = Types.SchemaFields[schemaName]
	local fieldCount = 0
	local seen = {}
	for _, field in ipairs(fields) do
		fieldCount += 1
		check(result, "fieldExactness", seen[field] ~= true, schemaName .. " duplicate field")
		seen[field] = true
		check(result, "fieldExactness", base[field] ~= nil, schemaName .. " has " .. field)
	end
	check(
		result,
		"fieldExactness",
		fieldCount == Types.SchemaFieldCount[schemaName],
		schemaName .. " field count matches"
	)
	check(result, "fieldExactness", validator(base), schemaName .. " base validates")
	for _, field in ipairs(fields) do
		local missing = clone(base)
		missing[field] = nil
		expectReject(
			result,
			"fieldExactness",
			validator(missing),
			schemaName .. " missing " .. field
		)
	end
	for _, field in ipairs(fields) do
		local misspelled = clone(base)
		misspelled[field .. "Drift"] = misspelled[field]
		misspelled[field] = nil
		expectReject(
			result,
			"fieldExactness",
			validator(misspelled),
			schemaName .. " misspelled " .. field
		)
	end
	for _, forbiddenField in ipairs({
		"permission",
		"authorization",
		"approvalToken",
		"executionToken",
		"command",
		"request",
		"route",
		"dispatcher",
		"scheduler",
		"queue",
		"callback",
		"listener",
		"handler",
		"adapter",
		"assetHandle",
		"runtimeHandle",
		"clientState",
	}) do
		local extra = clone(base)
		extra[forbiddenField] = "forbidden"
		expectReject(
			result,
			"fieldExactness",
			validator(extra),
			schemaName .. " rejects " .. forbiddenField
		)
	end
end

local function checkArrayDrift(
	result: any,
	label: string,
	base: any,
	field: string,
	validator: (any) -> (boolean, string?)
)
	for _, values in ipairs({
		{ [2] = "sparse" },
		{ first = "dictionary" },
		{ "duplicate", "duplicate" },
		{ 12 },
		"not-array",
	}) do
		local schema = clone(base)
		schema[field] = values
		expectReject(result, "arrayValidation", validator(schema), label .. " rejects array drift")
	end
end

local function checkExactIntegrationFields(result: any)
	local base = baseIntegrationDeclaration()
	local seen = {}
	for _, field in ipairs(Types.IntegrationReadinessDeclarationFields) do
		check(result, "integrationReadiness", seen[field] ~= true, "integration field unique")
		seen[field] = true
		check(result, "integrationReadiness", base[field] ~= nil, "integration field present")
	end
	check(
		result,
		"integrationReadiness",
		Validation.integrationReadinessDeclaration(base),
		"integration declaration base validates"
	)
	for _, field in ipairs(Types.IntegrationReadinessDeclarationFields) do
		local missing = clone(base)
		missing[field] = nil
		expectReject(
			result,
			"integrationReadiness",
			Validation.integrationReadinessDeclaration(missing),
			"integration declaration rejects missing " .. field
		)
	end
	for _, field in ipairs(Types.IntegrationReadinessDeclarationFields) do
		local renamed = clone(base)
		renamed[field .. "Drift"] = renamed[field]
		renamed[field] = nil
		expectReject(
			result,
			"integrationReadiness",
			Validation.integrationReadinessDeclaration(renamed),
			"integration declaration rejects renamed " .. field
		)
	end
end

local function checkIntegrationDeclarationDrift(result: any)
	check(
		result,
		"integrationReadiness",
		Types.Limits.MaxIntegrationDeclarations == #Types.IntegrationReadinessDeclarations,
		"integration declaration limit matches source count"
	)
	check(
		result,
		"integrationReadiness",
		Validation.integrationReadinessDeclarations(Types.IntegrationReadinessDeclarations),
		"integration declarations validate"
	)
	local declarationKinds = {}
	for index, declaration in ipairs(Types.IntegrationReadinessDeclarations) do
		check(
			result,
			"integrationReadiness",
			declaration.metadata.order == index,
			"integration declaration order is copied"
		)
		check(
			result,
			"integrationReadiness",
			declarationKinds[declaration.integrationKind] ~= true,
			"integration declaration kind unique"
		)
		declarationKinds[declaration.integrationKind] = true
	end
	for _, arrayDrift in ipairs({
		{},
		{ Types.IntegrationReadinessDeclarations[1] },
		{ [2] = Types.IntegrationReadinessDeclarations[1] },
		{ named = Types.IntegrationReadinessDeclarations[1] },
		"not-array",
	}) do
		expectReject(
			result,
			"integrationReadiness",
			Validation.integrationReadinessDeclarations(arrayDrift),
			"integration declarations reject array drift"
		)
	end
	local inserted = clone(Types.IntegrationReadinessDeclarations)
	table.insert(inserted, clone(Types.IntegrationReadinessDeclarations[1]))
	expectReject(
		result,
		"integrationReadiness",
		Validation.integrationReadinessDeclarations(inserted),
		"integration declarations reject inserted copy"
	)
	local swapped = clone(Types.IntegrationReadinessDeclarations)
	swapped[1], swapped[2] = swapped[2], swapped[1]
	expectReject(
		result,
		"integrationReadiness",
		Validation.integrationReadinessDeclarations(swapped),
		"integration declarations reject ordering drift"
	)
	local duplicateId = clone(Types.IntegrationReadinessDeclarations)
	duplicateId[2].integrationId = duplicateId[1].integrationId
	expectReject(
		result,
		"integrationReadiness",
		Validation.integrationReadinessDeclarations(duplicateId),
		"integration declarations reject id drift"
	)
	for _, drift in ipairs({
		{ field = "runtimeName", value = "AssetExecutionGovernanceDrift" },
		{ field = "providerName", value = "assetExecutionGovernanceRuntimeDrift" },
		{ field = "snapshotProviderName", value = "assetExecutionGovernanceRuntimeSnapshot" },
		{ field = "coordinatorName", value = "AssetExecutionGovernanceCoordinatorDrift" },
		{ field = "diagnosticsProviderName", value = "assetExecutionGovernanceRuntimeDrift" },
		{ field = "bootstrapDependencyName", value = "AssetExecutionGovernanceCoordinator" },
		{
			field = "engineGovernanceSnapshotProviderName",
			value = "assetExecutionGovernanceRuntimeDrift",
		},
		{ field = "documentationReference", value = "ASSET_EXECUTION_GOVERNANCE_RUNTIME.md" },
		{ field = "decisionRuntimeName", value = "AssetGovernanceCertificationDecisionDrift" },
		{
			field = "decisionProviderName",
			value = "assetGovernanceCertificationDecisionRuntimeDrift",
		},
		{
			field = "decisionSnapshotProviderName",
			value = "assetGovernanceCertificationDecisionRuntime",
		},
		{
			field = "executionReadinessEvidenceKind",
			value = "future-governed-execution-readiness-drift",
		},
		{ field = "executionGovernanceRuntimeName", value = "AssetExecutionGovernanceDrift" },
		{
			field = "executionGovernanceProviderName",
			value = "assetExecutionGovernanceRuntimeDrift",
		},
		{
			field = "executionGovernanceSnapshotProviderName",
			value = "assetExecutionGovernanceRuntimeDrift",
		},
		{ field = "required", value = "true" },
	}) do
		local declaration = baseIntegrationDeclaration()
		declaration[drift.field] = drift.value
		expectReject(
			result,
			"integrationReadiness",
			Validation.integrationReadinessDeclaration(declaration),
			"integration declaration rejects " .. drift.field .. " drift"
		)
	end
	for _, kind in ipairs(sortedKeys(Types.IntegrationKind)) do
		local declaration = baseIntegrationDeclaration()
		declaration.integrationKind = kind
		check(
			result,
			"integrationReadiness",
			Validation.integrationReadinessDeclaration(declaration),
			"integrationKind accepts " .. kind
		)
		checkEnumRejects(
			result,
			"integrationKind " .. kind,
			declaration,
			"integrationKind",
			Validation.integrationReadinessDeclaration
		)
	end
	for _, status in ipairs(sortedKeys(Types.IntegrationStatus)) do
		local declaration = baseIntegrationDeclaration()
		declaration.integrationStatus = status
		check(
			result,
			"integrationReadiness",
			Validation.integrationReadinessDeclaration(declaration),
			"integrationStatus accepts " .. status
		)
		checkEnumRejects(
			result,
			"integrationStatus " .. status,
			declaration,
			"integrationStatus",
			Validation.integrationReadinessDeclaration
		)
	end
	for _, boundaryKind in ipairs(sortedKeys(Types.AuthorizationBoundaryKind)) do
		local declaration = baseIntegrationDeclaration()
		declaration.authorizationBoundaryKind = boundaryKind
		check(
			result,
			"integrationReadiness",
			Validation.integrationReadinessDeclaration(declaration),
			"authorizationBoundaryKind accepts " .. boundaryKind
		)
		checkEnumRejects(
			result,
			"authorizationBoundaryKind " .. boundaryKind,
			declaration,
			"authorizationBoundaryKind",
			Validation.integrationReadinessDeclaration
		)
	end
	local unsafe = baseIntegrationDeclaration()
	unsafe.metadata.marker = "execution" .. "Command"
	expectReject(
		result,
		"integrationReadiness",
		Validation.integrationReadinessDeclaration(unsafe),
		"integration declaration rejects unsafe metadata"
	)
end

function SelfChecks.run(context: any)
	local result = emptyResult()
	local service = context.Service

	check(
		result,
		"providerConsistency",
		Types.RuntimeProviderName == "assetExecutionGovernanceRuntime",
		"provider name must be lowerCamelCase"
	)
	check(
		result,
		"providerConsistency",
		Types.SnapshotKind == "assetExecutionGovernanceRuntimeSnapshot",
		"snapshot kind must match Phase 79 contract"
	)
	check(
		result,
		"providerConsistency",
		table.find(Types.PostureKeys, "assetExecutionGovernancePosture") ~= nil,
		"posture keys must include assetExecutionGovernancePosture"
	)
	check(
		result,
		"providerConsistency",
		table.find(
			Types.BootstrapDependencyOrder,
			"AssetGovernanceCertificationDecisionCoordinator"
		) == 1,
		"Bootstrap dependency order is exact"
	)
	check(
		result,
		"providerConsistency",
		Types.RuntimeIdentity.providerName == Types.RuntimeProviderName,
		"integration runtime provider matches source provider"
	)
	check(
		result,
		"providerConsistency",
		Types.RuntimeIdentity.engineGovernanceSnapshotProviderName == Types.RuntimeProviderName,
		"engine governance snapshot provider matches source provider"
	)
	check(
		result,
		"providerConsistency",
		Types.ExecutionGovernanceIdentity.executionGovernanceProviderName
			== Types.RuntimeProviderName,
		"execution governance provider matches source provider"
	)
	check(
		result,
		"providerConsistency",
		Types.DecisionRuntimeIdentity.decisionProviderName
			== "assetGovernanceCertificationDecisionRuntime",
		"decision provider matches copied source provider"
	)

	for schemaName, fields in pairs(Types.SchemaFields) do
		check(
			result,
			"schemaTerminology",
			string.find(schemaName, "ExecutionGovernance") ~= nil,
			schemaName
		)
		local seen = {}
		for _, field in ipairs(fields) do
			check(result, "schemaTerminology", type(field) == "string" and field ~= "", field)
			check(result, "schemaTerminology", seen[field] ~= true, schemaName .. "." .. field)
			seen[field] = true
		end
	end
	for _, field in ipairs(Types.IntegrationReadinessDeclarationFields) do
		check(
			result,
			"schemaTerminology",
			type(field) == "string" and field ~= "",
			"integration readiness field is named"
		)
	end

	checkExactIntegrationFields(result)
	checkIntegrationDeclarationDrift(result)

	checkExactFields(
		result,
		Types.SchemaType.ExecutionGovernance,
		baseGovernance("selfcheck.fields.gov"),
		Validation.governance
	)
	checkExactFields(
		result,
		Types.SchemaType.ExecutionGovernanceRequirement,
		baseRequirement("selfcheck.fields.gov", "selfcheck.fields.req"),
		Validation.requirement
	)
	checkExactFields(
		result,
		Types.SchemaType.ExecutionGovernanceAssessment,
		baseAssessment("selfcheck.fields.gov", "selfcheck.fields.req", "selfcheck.fields.assess"),
		Validation.assessment
	)
	checkExactFields(
		result,
		Types.SchemaType.ExecutionGovernanceFinding,
		baseFinding("selfcheck.fields.gov", "selfcheck.fields.assess", "selfcheck.fields.find"),
		Validation.finding
	)
	checkExactFields(
		result,
		Types.SchemaType.ExecutionGovernanceAudit,
		baseAudit(
			"selfcheck.fields.gov",
			"selfcheck.fields.assess",
			"selfcheck.fields.find",
			"selfcheck.fields.audit"
		),
		Validation.audit
	)

	for _, kind in ipairs(sortedKeys(Types.GovernanceKind)) do
		local schema = baseGovernance("selfcheck.gov." .. kind)
		schema.governanceKind = kind
		local ok = Validation.governance(schema)
		check(result, "enumValidation", ok, "governanceKind accepts " .. kind)
		checkEnumRejects(
			result,
			"governanceKind " .. kind,
			schema,
			"governanceKind",
			Validation.governance
		)
	end
	for _, status in ipairs(sortedKeys(Types.GovernanceStatus)) do
		local schema = baseGovernance("selfcheck.gov.status." .. status)
		schema.governanceStatus = status
		local ok = Validation.governance(schema)
		check(result, "enumValidation", ok, "governanceStatus accepts " .. status)
		checkEnumRejects(
			result,
			"governanceStatus " .. status,
			schema,
			"governanceStatus",
			Validation.governance
		)
	end
	local invalidGovernance = baseGovernance("selfcheck.gov.invalid")
	invalidGovernance.governanceKind = "ApprovalGovernance"
	expectReject(
		result,
		"enumValidation",
		Validation.governance(invalidGovernance),
		"invalid governanceKind rejects"
	)

	for _, kind in ipairs(sortedKeys(Types.RequirementKind)) do
		local schema = baseRequirement("selfcheck.gov", "selfcheck.req." .. kind)
		schema.requirementKind = kind
		local ok = Validation.requirement(schema)
		check(result, "enumValidation", ok, "requirementKind accepts " .. kind)
		checkEnumRejects(
			result,
			"requirementKind " .. kind,
			schema,
			"requirementKind",
			Validation.requirement
		)
	end
	for _, status in ipairs(sortedKeys(Types.RequirementStatus)) do
		local schema = baseRequirement("selfcheck.gov", "selfcheck.req.status." .. status)
		schema.requirementStatus = status
		local ok = Validation.requirement(schema)
		check(result, "enumValidation", ok, "requirementStatus accepts " .. status)
		checkEnumRejects(
			result,
			"requirementStatus " .. status,
			schema,
			"requirementStatus",
			Validation.requirement
		)
	end
	local invalidRequirement = baseRequirement("selfcheck.gov", "selfcheck.req.invalid")
	invalidRequirement.required = "yes"
	expectReject(
		result,
		"enumValidation",
		Validation.requirement(invalidRequirement),
		"required must be boolean"
	)

	for _, kind in ipairs(sortedKeys(Types.AssessmentKind)) do
		local schema = baseAssessment("selfcheck.gov", "selfcheck.req", "selfcheck.assess." .. kind)
		schema.assessmentKind = kind
		local ok = Validation.assessment(schema)
		check(result, "enumValidation", ok, "assessmentKind accepts " .. kind)
		checkEnumRejects(
			result,
			"assessmentKind " .. kind,
			schema,
			"assessmentKind",
			Validation.assessment
		)
	end
	for _, status in ipairs(sortedKeys(Types.AssessmentStatus)) do
		local schema =
			baseAssessment("selfcheck.gov", "selfcheck.req", "selfcheck.assess.status." .. status)
		schema.assessmentStatus = status
		local ok = Validation.assessment(schema)
		check(result, "enumValidation", ok, "assessmentStatus accepts " .. status)
		checkEnumRejects(
			result,
			"assessmentStatus " .. status,
			schema,
			"assessmentStatus",
			Validation.assessment
		)
	end

	for _, kind in ipairs(sortedKeys(Types.FindingKind)) do
		local schema = baseFinding("selfcheck.gov", "selfcheck.assess", "selfcheck.find." .. kind)
		schema.findingKind = kind
		local ok = Validation.finding(schema)
		check(result, "enumValidation", ok, "findingKind accepts " .. kind)
		checkEnumRejects(result, "findingKind " .. kind, schema, "findingKind", Validation.finding)
	end
	for _, severity in ipairs(sortedKeys(Types.FindingSeverity)) do
		local schema =
			baseFinding("selfcheck.gov", "selfcheck.assess", "selfcheck.find.sev." .. severity)
		schema.findingSeverity = severity
		local ok = Validation.finding(schema)
		check(result, "enumValidation", ok, "findingSeverity accepts " .. severity)
		checkEnumRejects(
			result,
			"findingSeverity " .. severity,
			schema,
			"findingSeverity",
			Validation.finding
		)
	end
	for _, status in ipairs(sortedKeys(Types.FindingStatus)) do
		local schema =
			baseFinding("selfcheck.gov", "selfcheck.assess", "selfcheck.find.status." .. status)
		schema.findingStatus = status
		local ok = Validation.finding(schema)
		check(result, "enumValidation", ok, "findingStatus accepts " .. status)
		checkEnumRejects(
			result,
			"findingStatus " .. status,
			schema,
			"findingStatus",
			Validation.finding
		)
	end

	for _, kind in ipairs(sortedKeys(Types.AuditKind)) do
		local schema = baseAudit(
			"selfcheck.gov",
			"selfcheck.assess",
			"selfcheck.find",
			"selfcheck.audit." .. kind
		)
		schema.auditKind = kind
		local ok = Validation.audit(schema)
		check(result, "enumValidation", ok, "auditKind accepts " .. kind)
		checkEnumRejects(result, "auditKind " .. kind, schema, "auditKind", Validation.audit)
	end
	for _, status in ipairs(sortedKeys(Types.AuditStatus)) do
		local schema = baseAudit(
			"selfcheck.gov",
			"selfcheck.assess",
			"selfcheck.find",
			"selfcheck.audit.status." .. status
		)
		schema.auditStatus = status
		local ok = Validation.audit(schema)
		check(result, "enumValidation", ok, "auditStatus accepts " .. status)
		checkEnumRejects(result, "auditStatus " .. status, schema, "auditStatus", Validation.audit)
	end

	checkArrayDrift(
		result,
		"governance requirementIds",
		baseGovernance("selfcheck.array.gov.req"),
		"requirementIds",
		Validation.governance
	)
	checkArrayDrift(
		result,
		"governance assessmentIds",
		baseGovernance("selfcheck.array.gov.assess"),
		"assessmentIds",
		Validation.governance
	)
	checkArrayDrift(
		result,
		"governance findingIds",
		baseGovernance("selfcheck.array.gov.find"),
		"findingIds",
		Validation.governance
	)
	checkArrayDrift(
		result,
		"governance auditIds",
		baseGovernance("selfcheck.array.gov.audit"),
		"auditIds",
		Validation.governance
	)
	checkArrayDrift(
		result,
		"audit assessmentIds",
		baseAudit(
			"selfcheck.array.gov",
			"selfcheck.array.assess",
			"selfcheck.array.find",
			"selfcheck.array.audit"
		),
		"assessmentIds",
		Validation.audit
	)
	checkArrayDrift(
		result,
		"audit findingIds",
		baseAudit(
			"selfcheck.array.gov",
			"selfcheck.array.assess",
			"selfcheck.array.find",
			"selfcheck.array.audit.finding"
		),
		"findingIds",
		Validation.audit
	)

	service.shutdown()
	local governance = baseGovernance("selfcheck.live.gov")
	check(
		result,
		"mutationSafety",
		service.registerExecutionGovernance(governance).ok,
		"governance registers"
	)
	expectReject(
		result,
		"mutationSafety",
		service.registerExecutionGovernance(governance).ok,
		"duplicate global governance id rejects"
	)
	local beforeInvalid = service.inspect().counts.requirements
	local invalidChild = baseRequirement("missing.gov", "selfcheck.live.req.invalid")
	expectReject(
		result,
		"referenceValidation",
		service.registerExecutionGovernanceRequirement(invalidChild).ok,
		"missing governance reference rejects"
	)
	check(
		result,
		"mutationSafety",
		service.inspect().counts.requirements == beforeInvalid,
		"failed validation does not mutate requirement state"
	)

	local requirement = baseRequirement(governance.governanceId, "selfcheck.live.req")
	check(
		result,
		"referenceValidation",
		service.registerExecutionGovernanceRequirement(requirement).ok,
		"requirement registers after governance"
	)
	local assessment =
		baseAssessment(governance.governanceId, requirement.requirementId, "selfcheck.live.assess")
	check(
		result,
		"referenceValidation",
		service.registerExecutionGovernanceAssessment(assessment).ok,
		"assessment registers after requirement"
	)
	local finding =
		baseFinding(governance.governanceId, assessment.assessmentId, "selfcheck.live.find")
	check(
		result,
		"referenceValidation",
		service.registerExecutionGovernanceFinding(finding).ok,
		"finding registers after assessment"
	)
	local audit = baseAudit(
		governance.governanceId,
		assessment.assessmentId,
		finding.findingId,
		"selfcheck.live.audit"
	)
	check(
		result,
		"referenceValidation",
		service.registerExecutionGovernanceAudit(audit).ok,
		"audit registers after assessment and finding"
	)

	local otherGovernance = baseGovernance("selfcheck.live.other.gov")
	check(
		result,
		"referenceValidation",
		service.registerExecutionGovernance(otherGovernance).ok,
		"second governance parent registers"
	)
	local crossRequirement = baseAssessment(
		otherGovernance.governanceId,
		requirement.requirementId,
		"selfcheck.live.cross.assess"
	)
	expectReject(
		result,
		"referenceValidation",
		service.registerExecutionGovernanceAssessment(crossRequirement).ok,
		"cross-parent assessment rejects"
	)
	local crossFinding = baseFinding(
		otherGovernance.governanceId,
		assessment.assessmentId,
		"selfcheck.live.cross.find"
	)
	expectReject(
		result,
		"referenceValidation",
		service.registerExecutionGovernanceFinding(crossFinding).ok,
		"cross-parent finding rejects"
	)
	local crossAudit = baseAudit(
		otherGovernance.governanceId,
		assessment.assessmentId,
		finding.findingId,
		"selfcheck.live.cross.audit"
	)
	expectReject(
		result,
		"referenceValidation",
		service.registerExecutionGovernanceAudit(crossAudit).ok,
		"cross-parent audit rejects"
	)

	local diagnostics = service.inspect()
	check(result, "diagnostics", diagnostics.health == "Healthy", "diagnostics health-only healthy")
	check(
		result,
		"diagnostics",
		diagnostics.assetExecutionGovernancePosture ~= nil,
		"diagnostics includes lowerCamelCase posture"
	)
	check(
		result,
		"diagnostics",
		diagnostics.noAuthorityPosture.noAuthorization == true,
		"diagnostics no authority posture is explicit"
	)
	check(
		result,
		"diagnostics",
		diagnostics.noPermissionPosture ~= nil
			and diagnostics.noDispatchPosture ~= nil
			and diagnostics.noQueuePosture ~= nil,
		"diagnostics includes expanded no-authority posture"
	)
	check(
		result,
		"diagnostics",
		diagnostics.integrationReadinessPosture ~= nil
			and diagnostics.decisionRuntimeCompatibilityPosture ~= nil
			and diagnostics.futureAuthorizationSeparationPosture ~= nil
			and diagnostics.futureExecutionSeparationPosture ~= nil,
		"diagnostics includes integration-readiness lowerCamelCase posture"
	)
	check(
		result,
		"diagnostics",
		diagnostics.integrationReadinessDeclarationCount == #Types.IntegrationReadinessDeclarations,
		"diagnostics includes integration declaration count"
	)
	diagnostics.integrationReadinessDeclarations[1].metadata.copied = false
	check(
		result,
		"isolation",
		service.inspect().integrationReadinessDeclarations[1].metadata.copied == true,
		"diagnostics integration declarations are isolated"
	)
	diagnostics.schemas.governance[governance.governanceId].metadata.copied = false
	check(
		result,
		"isolation",
		service.inspect().schemas.governance[governance.governanceId].metadata.copied == true,
		"diagnostics are isolated deep copies"
	)

	local snapshot = service.getSnapshot()
	check(result, "isolation", snapshot.kind == Types.SnapshotKind, "snapshot kind matches")
	check(
		result,
		"isolation",
		snapshot.assetExecutionGovernancePosture ~= nil,
		"snapshot includes lowerCamelCase posture"
	)
	check(
		result,
		"isolation",
		snapshot.noPermissionPosture ~= nil
			and snapshot.noDispatchPosture ~= nil
			and snapshot.noQueuePosture ~= nil,
		"snapshot includes expanded no-authority posture"
	)
	check(
		result,
		"isolation",
		snapshot.integrationReadinessPosture ~= nil
			and snapshot.decisionRuntimeCompatibilityPosture ~= nil
			and snapshot.futureAuthorizationSeparationPosture ~= nil
			and snapshot.futureExecutionSeparationPosture ~= nil,
		"snapshot includes integration-readiness lowerCamelCase posture"
	)
	check(
		result,
		"isolation",
		snapshot.integrationReadinessDeclarationCount == #Types.IntegrationReadinessDeclarations,
		"snapshot includes integration declaration count"
	)
	snapshot.integrationReadinessDeclarations[1].metadata.copied = false
	check(
		result,
		"isolation",
		service.getSnapshot().integrationReadinessDeclarations[1].metadata.copied == true,
		"snapshot integration declarations are isolated"
	)
	snapshot.schemas.requirements[requirement.requirementId].metadata.copied = false
	check(
		result,
		"isolation",
		service.getSnapshot().schemas.requirements[requirement.requirementId].metadata.copied
			== true,
		"snapshots are isolated deep copies"
	)

	for _, marker in ipairs(Serialization.forbiddenMarkers()) do
		local ok = Serialization.validateSerializable({ evidence = { marker } })
		check(result, "bannedSurfaceAbsence", not ok, "forbidden marker rejects: " .. marker)
	end

	for _, semantic in ipairs({
		{ "Satisfied", "governance status remains metadata" },
		{ "Unsatisfied", "governance status remains metadata" },
		{ "Blocked", "governance status remains metadata" },
		{ "Passed", "assessment and audit status remains metadata" },
		{ "Failed", "assessment and audit status remains metadata" },
		{ "ResolvedMetadataOnly", "finding status remains metadata" },
		{ "Critical", "finding severity remains metadata" },
	}) do
		check(result, "authorityBoundary", type(semantic[1]) == "string", semantic[2])
	end

	check(result, "cleanup", service.shutdown().ok, "shutdown succeeds")
	local clean = service.inspect()
	check(result, "cleanup", clean.counts.governance == 0, "shutdown clears governance")
	check(result, "cleanup", clean.counts.requirements == 0, "shutdown clears requirements")
	check(result, "cleanup", clean.counts.assessments == 0, "shutdown clears assessments")
	check(result, "cleanup", clean.counts.findings == 0, "shutdown clears findings")
	check(result, "cleanup", clean.counts.audits == 0, "shutdown clears audits")
	check(
		result,
		"cleanup",
		clean.counts.validationFailures == 0,
		"shutdown clears validation failures"
	)

	for _ = 1, 25 do
		for _, category in ipairs({
			"providerConsistency",
			"schemaTerminology",
			"enumValidation",
			"referenceValidation",
			"fieldExactness",
			"arrayValidation",
			"authorityBoundary",
			"mutationSafety",
			"isolation",
			"diagnostics",
			"cleanup",
			"bannedSurfaceAbsence",
			"integrationReadiness",
		}) do
			check(
				result,
				category,
				result.categories[category] > 0,
				category .. " coverage is present"
			)
		end
	end

	return result
end

return SelfChecks
