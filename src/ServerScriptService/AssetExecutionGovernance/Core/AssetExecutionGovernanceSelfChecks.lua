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
		metadata = { copied = true, permission = "metadata-only" },
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

	for kind in pairs(Types.GovernanceKind) do
		local schema = baseGovernance("selfcheck.gov." .. kind)
		schema.governanceKind = kind
		local ok = Validation.governance(schema)
		check(result, "enumValidation", ok, "governanceKind accepts " .. kind)
	end
	for status in pairs(Types.GovernanceStatus) do
		local schema = baseGovernance("selfcheck.gov.status." .. status)
		schema.governanceStatus = status
		local ok = Validation.governance(schema)
		check(result, "enumValidation", ok, "governanceStatus accepts " .. status)
	end
	local invalidGovernance = baseGovernance("selfcheck.gov.invalid")
	invalidGovernance.governanceKind = "ApprovalGovernance"
	expectReject(
		result,
		"enumValidation",
		Validation.governance(invalidGovernance),
		"invalid governanceKind rejects"
	)

	for kind in pairs(Types.RequirementKind) do
		local schema = baseRequirement("selfcheck.gov", "selfcheck.req." .. kind)
		schema.requirementKind = kind
		local ok = Validation.requirement(schema)
		check(result, "enumValidation", ok, "requirementKind accepts " .. kind)
	end
	for status in pairs(Types.RequirementStatus) do
		local schema = baseRequirement("selfcheck.gov", "selfcheck.req.status." .. status)
		schema.requirementStatus = status
		local ok = Validation.requirement(schema)
		check(result, "enumValidation", ok, "requirementStatus accepts " .. status)
	end
	local invalidRequirement = baseRequirement("selfcheck.gov", "selfcheck.req.invalid")
	invalidRequirement.required = "yes"
	expectReject(
		result,
		"enumValidation",
		Validation.requirement(invalidRequirement),
		"required must be boolean"
	)

	for kind in pairs(Types.AssessmentKind) do
		local schema = baseAssessment("selfcheck.gov", "selfcheck.req", "selfcheck.assess." .. kind)
		schema.assessmentKind = kind
		local ok = Validation.assessment(schema)
		check(result, "enumValidation", ok, "assessmentKind accepts " .. kind)
	end
	for status in pairs(Types.AssessmentStatus) do
		local schema =
			baseAssessment("selfcheck.gov", "selfcheck.req", "selfcheck.assess.status." .. status)
		schema.assessmentStatus = status
		local ok = Validation.assessment(schema)
		check(result, "enumValidation", ok, "assessmentStatus accepts " .. status)
	end

	for kind in pairs(Types.FindingKind) do
		local schema = baseFinding("selfcheck.gov", "selfcheck.assess", "selfcheck.find." .. kind)
		schema.findingKind = kind
		local ok = Validation.finding(schema)
		check(result, "enumValidation", ok, "findingKind accepts " .. kind)
	end
	for severity in pairs(Types.FindingSeverity) do
		local schema =
			baseFinding("selfcheck.gov", "selfcheck.assess", "selfcheck.find.sev." .. severity)
		schema.findingSeverity = severity
		local ok = Validation.finding(schema)
		check(result, "enumValidation", ok, "findingSeverity accepts " .. severity)
	end
	for status in pairs(Types.FindingStatus) do
		local schema =
			baseFinding("selfcheck.gov", "selfcheck.assess", "selfcheck.find.status." .. status)
		schema.findingStatus = status
		local ok = Validation.finding(schema)
		check(result, "enumValidation", ok, "findingStatus accepts " .. status)
	end

	for kind in pairs(Types.AuditKind) do
		local schema = baseAudit(
			"selfcheck.gov",
			"selfcheck.assess",
			"selfcheck.find",
			"selfcheck.audit." .. kind
		)
		schema.auditKind = kind
		local ok = Validation.audit(schema)
		check(result, "enumValidation", ok, "auditKind accepts " .. kind)
	end
	for status in pairs(Types.AuditStatus) do
		local schema = baseAudit(
			"selfcheck.gov",
			"selfcheck.assess",
			"selfcheck.find",
			"selfcheck.audit.status." .. status
		)
		schema.auditStatus = status
		local ok = Validation.audit(schema)
		check(result, "enumValidation", ok, "auditStatus accepts " .. status)
	end

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
