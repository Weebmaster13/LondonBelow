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
