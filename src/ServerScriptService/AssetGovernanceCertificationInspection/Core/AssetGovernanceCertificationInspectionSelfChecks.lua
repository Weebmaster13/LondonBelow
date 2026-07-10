--!strict

local Diagnostics = require(script.Parent.AssetGovernanceCertificationInspectionDiagnostics)
local Serialization = require(script.Parent.AssetGovernanceCertificationInspectionSerialization)
local Signals = require(script.Parent.AssetGovernanceCertificationInspectionSignals)
local Snapshots = require(script.Parent.AssetGovernanceCertificationInspectionSnapshots)
local State = require(script.Parent.AssetGovernanceCertificationInspectionState)
local Types = require(script.Parent.AssetGovernanceCertificationInspectionTypes)
local Validation = require(script.Parent.AssetGovernanceCertificationInspectionValidation)

local SelfChecks = {}

type CheckResult = { name: string, ok: boolean, reason: string? }

local function runtime(order: number?): any
	return Types.CertifiedRuntimeOrder[order or 1]
end

local function inspection(id: string): any
	return {
		inspectionId = id,
		inspectionKind = "CertificationHealthInspection",
		inspectionStatus = "Ready",
		integrationId = "integration." .. id,
		certificationId = "certification." .. id,
		coverageId = "coverage." .. id,
		observationIds = {},
		findingIds = {},
		auditIds = {},
		inspector = "System",
		inspectionVersion = "1",
		tags = { "certification-inspection" },
		metadata = { copied = true },
		schemaType = Types.SchemaType.GovernanceInspection,
	}
end

local function observation(inspectionId: string, id: string, order: number?): any
	local node = runtime(order)
	return {
		observationId = id,
		inspectionId = inspectionId,
		runtimeName = node.runtimeName,
		providerName = node.providerName,
		snapshotProviderName = node.snapshotProviderName,
		observationKind = "CopiedDiagnosticsObservation",
		observationStatus = "Observed",
		health = "Healthy",
		evidence = { "copied.health" },
		tags = { "certification-inspection" },
		metadata = { copied = true },
		schemaType = Types.SchemaType.GovernanceInspectionObservation,
	}
end

local function finding(inspectionId: string, observationId: string, id: string, order: number?): any
	local node = runtime(order)
	return {
		findingId = id,
		inspectionId = inspectionId,
		observationId = observationId,
		runtimeName = node.runtimeName,
		providerName = node.providerName,
		snapshotProviderName = node.snapshotProviderName,
		findingKind = "ProviderMismatch",
		findingSeverity = "Warning",
		findingStatus = "Reported",
		summary = "copied metadata mismatch",
		evidence = { "copied.finding" },
		tags = { "certification-inspection" },
		metadata = { copied = true },
		schemaType = Types.SchemaType.GovernanceInspectionFinding,
	}
end

local function audit(inspectionId: string, id: string, findingIds: { string }?): any
	return {
		auditId = id,
		inspectionId = inspectionId,
		findingIds = findingIds or {},
		auditKind = "InspectionAudit",
		reviewer = "System",
		status = "Warning",
		findings = { "metadata_only" },
		tags = { "certification-inspection" },
		metadata = { copied = true },
		schemaType = Types.SchemaType.GovernanceInspectionAudit,
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

local function withDeclarationField(index: number, field: string, value: any): any
	local declarations = Serialization.deepCopy(Types.IntegrationReadinessDeclarations)
	declarations[index][field] = value
	return declarations
end

local function withDuplicateDeclarationField(index: number, field: string): any
	local declarations = Serialization.deepCopy(Types.IntegrationReadinessDeclarations)
	local duplicateSource = if index == 1 then 2 else 1
	declarations[index][field] = declarations[duplicateSource][field]
	return declarations
end

local function withDecisionDeclarationField(index: number, field: string, value: any): any
	local declarations = Serialization.deepCopy(Types.DecisionReadinessDeclarations)
	declarations[index][field] = value
	return declarations
end

local function withDuplicateDecisionDeclarationField(index: number, field: string): any
	local declarations = Serialization.deepCopy(Types.DecisionReadinessDeclarations)
	local duplicateSource = if index == 1 then 2 else 1
	declarations[index][field] = declarations[duplicateSource][field]
	return declarations
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

local function makeDeepPayload(depth: number): any
	local root = {}
	local current = root
	for index = 1, depth do
		local nextNode = { index = index }
		current.next = nextNode
		current = nextNode
	end
	return root
end

local function makeWidePayload(nodes: number): any
	local root = {}
	for index = 1, nodes do
		root["node" .. tostring(index)] = { index = index }
	end
	return root
end

local function exactSurfaces(checks: { CheckResult })
	expectExactArray("inspection fields", Types.SchemaFields.GovernanceInspection, {
		"inspectionId",
		"inspectionKind",
		"inspectionStatus",
		"integrationId",
		"certificationId",
		"coverageId",
		"observationIds",
		"findingIds",
		"auditIds",
		"inspector",
		"inspectionVersion",
		"tags",
		"metadata",
	}, checks)
	expectExactArray("observation fields", Types.SchemaFields.GovernanceInspectionObservation, {
		"observationId",
		"inspectionId",
		"runtimeName",
		"providerName",
		"snapshotProviderName",
		"observationKind",
		"observationStatus",
		"health",
		"evidence",
		"tags",
		"metadata",
	}, checks)
	expectExactArray("finding fields", Types.SchemaFields.GovernanceInspectionFinding, {
		"findingId",
		"inspectionId",
		"observationId",
		"runtimeName",
		"providerName",
		"snapshotProviderName",
		"findingKind",
		"findingSeverity",
		"findingStatus",
		"summary",
		"evidence",
		"tags",
		"metadata",
	}, checks)
	expectExactArray("audit fields", Types.SchemaFields.GovernanceInspectionAudit, {
		"auditId",
		"inspectionId",
		"findingIds",
		"auditKind",
		"reviewer",
		"status",
		"findings",
		"tags",
		"metadata",
	}, checks)
	expectExactMapKeys(
		"inspection kind",
		Types.InspectionKind,
		arrayValues(Types.InspectionKind),
		checks
	)
	expectExactMapKeys(
		"inspection status",
		Types.InspectionStatus,
		arrayValues(Types.InspectionStatus),
		checks
	)
	expectExactMapKeys(
		"observation kind",
		Types.ObservationKind,
		arrayValues(Types.ObservationKind),
		checks
	)
	expectExactMapKeys(
		"observation status",
		Types.ObservationStatus,
		arrayValues(Types.ObservationStatus),
		checks
	)
	expectExactMapKeys("observation health", Types.Health, arrayValues(Types.Health), checks)
	expectExactMapKeys("finding kind", Types.FindingKind, arrayValues(Types.FindingKind), checks)
	expectExactMapKeys(
		"finding severity",
		Types.FindingSeverity,
		arrayValues(Types.FindingSeverity),
		checks
	)
	expectExactMapKeys(
		"finding status",
		Types.FindingStatus,
		arrayValues(Types.FindingStatus),
		checks
	)
	expectExactMapKeys("audit kind", Types.AuditKind, arrayValues(Types.AuditKind), checks)
	expectExactMapKeys("audit status", Types.AuditStatus, arrayValues(Types.AuditStatus), checks)
	expectExactMapKeys(
		"integration readiness kind",
		Types.ReadinessKind,
		arrayValues(Types.ReadinessKind),
		checks
	)
	expectExactMapKeys(
		"integration readiness status",
		Types.ReadinessStatus,
		arrayValues(Types.ReadinessStatus),
		checks
	)
	expectExactMapKeys(
		"decision readiness kind",
		Types.DecisionReadinessKind,
		arrayValues(Types.DecisionReadinessKind),
		checks
	)
	expectExactMapKeys(
		"decision readiness status",
		Types.DecisionReadinessStatus,
		arrayValues(Types.DecisionReadinessStatus),
		checks
	)
	expectExactArray("inspection posture keys", Types.PostureKeys, {
		"integrationReadinessPosture",
		"decisionReadinessPosture",
		"decisionCompatibilityPosture",
		"decisionEvidencePosture",
		"decisionIsolationPosture",
		"decisionCoveragePosture",
		"inspectionPosture",
		"observationPosture",
		"findingPosture",
		"auditPosture",
		"providerPosture",
		"snapshotPosture",
		"runtimeCompatibilityPosture",
		"providerCompatibilityPosture",
		"snapshotCompatibilityPosture",
		"bootstrapCompatibilityPosture",
		"governanceCompatibilityPosture",
		"documentationCompatibilityPosture",
		"inspectionCoveragePosture",
		"documentationPosture",
		"bootstrapPosture",
		"governancePosture",
		"noAuthorityPosture",
		"noRepairPosture",
		"noExecutionPosture",
		"noMutationPosture",
	}, checks)
	expectExactArray("inspection documentation files", Types.DocumentationFiles, {
		"ASSET_GOVERNANCE_CERTIFICATION_INSPECTION_DECISION_READINESS.md",
		"ASSET_GOVERNANCE_CERTIFICATION_INSPECTION_INTEGRATION_READINESS.md",
		"ASSET_GOVERNANCE_CERTIFICATION_INSPECTION_RUNTIME.md",
		"ASSET_GOVERNANCE_CERTIFICATION_INSPECTION_VALIDATION.md",
		"ASSET_GOVERNANCE_CERTIFICATION_INSPECTION_SERIALIZATION.md",
		"ASSET_GOVERNANCE_CERTIFICATION_INSPECTION_DIAGNOSTICS.md",
		"ASSET_GOVERNANCE_CERTIFICATION_INSPECTION_SELF_CHECKS.md",
		"ASSET_GOVERNANCE_CERTIFICATION_INSPECTION_RUNTIME_LIMITS.md",
		"ASSET_GOVERNANCE_CERTIFICATION_INSPECTION_AUDIT.md",
		"ASSET_GOVERNANCE_CERTIFICATION_INSPECTION_PRODUCTION_REVIEW.md",
		"GOVERNANCE_INSPECTION_RUNTIME.md",
		"GOVERNANCE_INSPECTION_OBSERVATION_RUNTIME.md",
		"GOVERNANCE_INSPECTION_FINDING_RUNTIME.md",
		"GOVERNANCE_INSPECTION_AUDIT_RUNTIME.md",
	}, checks)
	expect(
		"provider name is lower camel case",
		Types.RuntimeProviderName == "assetGovernanceCertificationInspectionRuntime",
		"provider drift",
		checks
	)
	expect(
		"snapshot name is lower camel case",
		Types.SnapshotKind == "assetGovernanceCertificationInspectionRuntimeSnapshot",
		"snapshot drift",
		checks
	)
	expect(
		"certified runtime chain includes inspection predecessor",
		Types.RuntimeName.AssetGovernanceCertificationIntegration == #Types.CertifiedRuntimeOrder,
		"chain predecessor missing",
		checks
	)
	expect(
		"Bootstrap predecessor is last dependency",
		Types.BootstrapDependencyOrder[#Types.BootstrapDependencyOrder]
			== "AssetGovernanceCertificationIntegrationCoordinator",
		"Bootstrap dependency drift",
		checks
	)
end

local function validationBehavior(checks: { CheckResult })
	local seedInspection = inspection("inspection.seed")
	local seedObservation = observation("inspection.seed", "observation.seed", 1)
	local seedFinding = finding("inspection.seed", "observation.seed", "finding.seed", 1)
	local seedAudit = audit("inspection.seed", "audit.seed", { "finding.seed" })
	for _, candidate in ipairs({ nil, "invalid", true, 7 }) do
		expectReject("inspection rejects non-table", Validation.inspection(candidate), nil, checks)
		expectReject(
			"observation rejects non-table",
			Validation.observation(candidate),
			nil,
			checks
		)
		expectReject("finding rejects non-table", Validation.finding(candidate), nil, checks)
		expectReject("audit rejects non-table", Validation.audit(candidate), nil, checks)
	end
	for _, field in ipairs(Types.SchemaFields.GovernanceInspection) do
		expectMissingFieldRejects(
			"inspection",
			seedInspection,
			field,
			Validation.inspection,
			checks
		)
	end
	for _, field in ipairs(Types.SchemaFields.GovernanceInspectionObservation) do
		expectMissingFieldRejects(
			"observation",
			seedObservation,
			field,
			Validation.observation,
			checks
		)
	end
	for _, field in ipairs(Types.SchemaFields.GovernanceInspectionFinding) do
		expectMissingFieldRejects("finding", seedFinding, field, Validation.finding, checks)
	end
	for _, field in ipairs(Types.SchemaFields.GovernanceInspectionAudit) do
		expectMissingFieldRejects("audit", seedAudit, field, Validation.audit, checks)
	end
	for _, value in ipairs(arrayValues(Types.InspectionKind)) do
		expectAccept(
			"inspection accepts kind " .. value,
			Validation.inspection(withField(seedInspection, "inspectionKind", value)),
			nil,
			checks
		)
	end
	for _, value in ipairs(arrayValues(Types.InspectionStatus)) do
		expectAccept(
			"inspection accepts status " .. value,
			Validation.inspection(withField(seedInspection, "inspectionStatus", value)),
			nil,
			checks
		)
	end
	for _, value in ipairs(arrayValues(Types.ObservationKind)) do
		expectAccept(
			"observation accepts kind " .. value,
			Validation.observation(withField(seedObservation, "observationKind", value)),
			nil,
			checks
		)
	end
	for _, value in ipairs(arrayValues(Types.ObservationStatus)) do
		expectAccept(
			"observation accepts status " .. value,
			Validation.observation(withField(seedObservation, "observationStatus", value)),
			nil,
			checks
		)
	end
	for _, value in ipairs(arrayValues(Types.Health)) do
		expectAccept(
			"observation accepts health " .. value,
			Validation.observation(withField(seedObservation, "health", value)),
			nil,
			checks
		)
	end
	for _, value in ipairs(arrayValues(Types.FindingKind)) do
		expectAccept(
			"finding accepts kind " .. value,
			Validation.finding(withField(seedFinding, "findingKind", value)),
			nil,
			checks
		)
	end
	for _, value in ipairs(arrayValues(Types.FindingSeverity)) do
		expectAccept(
			"finding accepts severity " .. value,
			Validation.finding(withField(seedFinding, "findingSeverity", value)),
			nil,
			checks
		)
	end
	for _, value in ipairs(arrayValues(Types.FindingStatus)) do
		expectAccept(
			"finding accepts status " .. value,
			Validation.finding(withField(seedFinding, "findingStatus", value)),
			nil,
			checks
		)
	end
	for _, value in ipairs(arrayValues(Types.AuditKind)) do
		expectAccept(
			"audit accepts kind " .. value,
			Validation.audit(withField(seedAudit, "auditKind", value)),
			nil,
			checks
		)
	end
	for _, value in ipairs(arrayValues(Types.AuditStatus)) do
		expectAccept(
			"audit accepts status " .. value,
			Validation.audit(withField(seedAudit, "status", value)),
			nil,
			checks
		)
	end
	for _, pair in ipairs({
		{ seedInspection, "inspectionKind", Validation.inspection },
		{ seedInspection, "inspectionStatus", Validation.inspection },
		{ seedObservation, "observationKind", Validation.observation },
		{ seedObservation, "observationStatus", Validation.observation },
		{ seedObservation, "health", Validation.observation },
		{ seedFinding, "findingKind", Validation.finding },
		{ seedFinding, "findingSeverity", Validation.finding },
		{ seedFinding, "findingStatus", Validation.finding },
		{ seedAudit, "auditKind", Validation.audit },
		{ seedAudit, "status", Validation.audit },
	}) do
		expectReject(
			"invalid enum rejects " .. pair[2],
			pair[3](withField(pair[1], pair[2], "InvalidEnum")),
			nil,
			checks
		)
	end
	local cycle = {}
	cycle.self = cycle
	expectReject("cycle rejects", Validation.safePayload(cycle), nil, checks)
	expectReject(
		"deep payload rejects",
		Validation.safePayload(makeDeepPayload(Types.Limits.MaxPayloadDepth + 2)),
		nil,
		checks
	)
	expectReject(
		"wide payload rejects",
		Validation.safePayload(makeWidePayload(Types.Limits.MaxPayloadNodes + 2)),
		nil,
		checks
	)
	expectReject(
		"function payload rejects",
		Validation.safePayload({ fn = function() end }),
		nil,
		checks
	)
	expectReject(
		"instance shaped payload rejects",
		Validation.safePayload({ ClassName = "Folder", Parent = {} }),
		nil,
		checks
	)
end

local function compatibilityMatrices(checks: { CheckResult })
	local baseObservation = observation("inspection.seed", "observation.matrix", 1)
	local baseFinding = finding("inspection.seed", "observation.seed", "finding.matrix", 1)
	for runtimeIndex, runtimeNode in ipairs(Types.CertifiedRuntimeOrder) do
		for providerIndex, providerNode in ipairs(Types.CertifiedRuntimeOrder) do
			local obs = Serialization.deepCopy(baseObservation)
			obs.runtimeName = runtimeNode.runtimeName
			obs.providerName = providerNode.providerName
			obs.snapshotProviderName = runtimeNode.snapshotProviderName
			local obsOk = Validation.observation(obs)
			expect(
				"observation provider matrix "
					.. runtimeNode.runtimeName
					.. ":"
					.. providerNode.providerName,
				obsOk == (runtimeIndex == providerIndex),
				"provider matrix mismatch",
				checks
			)
			local find = Serialization.deepCopy(baseFinding)
			find.runtimeName = runtimeNode.runtimeName
			find.providerName = providerNode.providerName
			find.snapshotProviderName = runtimeNode.snapshotProviderName
			local findOk = Validation.finding(find)
			expect(
				"finding provider matrix "
					.. runtimeNode.runtimeName
					.. ":"
					.. providerNode.providerName,
				findOk == (runtimeIndex == providerIndex),
				"provider matrix mismatch",
				checks
			)
			local snap = Serialization.deepCopy(baseObservation)
			snap.runtimeName = runtimeNode.runtimeName
			snap.providerName = runtimeNode.providerName
			snap.snapshotProviderName = providerNode.snapshotProviderName
			local snapOk = Validation.observation(snap)
			expect(
				"observation snapshot matrix "
					.. runtimeNode.runtimeName
					.. ":"
					.. providerNode.snapshotProviderName,
				snapOk == (runtimeIndex == providerIndex),
				"snapshot matrix mismatch",
				checks
			)
		end
	end
	for runtimeIndex, runtimeNode in ipairs(Types.CertifiedRuntimeOrder) do
		expect(
			"runtime lookup order " .. runtimeNode.runtimeName,
			Types.RuntimeName[runtimeNode.runtimeName] == runtimeIndex,
			"runtime lookup drift",
			checks
		)
		expect(
			"provider lookup order " .. runtimeNode.providerName,
			Types.ProviderName[runtimeNode.providerName] == runtimeIndex,
			"provider lookup drift",
			checks
		)
		expect(
			"snapshot lookup order " .. runtimeNode.snapshotProviderName,
			Types.SnapshotProviderName[runtimeNode.snapshotProviderName] == runtimeIndex,
			"snapshot lookup drift",
			checks
		)
		expect(
			"coordinator lookup order " .. runtimeNode.coordinatorName,
			Types.CoordinatorName[runtimeNode.coordinatorName] == runtimeIndex,
			"coordinator lookup drift",
			checks
		)
	end
	for _, obsKind in ipairs(arrayValues(Types.ObservationKind)) do
		for _, obsStatus in ipairs(arrayValues(Types.ObservationStatus)) do
			for _, health in ipairs(arrayValues(Types.Health)) do
				local obs = withField(
					withField(
						withField(baseObservation, "observationKind", obsKind),
						"observationStatus",
						obsStatus
					),
					"health",
					health
				)
				expectAccept(
					"observation enum matrix " .. obsKind .. ":" .. obsStatus .. ":" .. health,
					Validation.observation(obs),
					nil,
					checks
				)
			end
		end
	end
	for runtimeIndex = 1, 2 do
		for _, findingKind in ipairs(arrayValues(Types.FindingKind)) do
			for _, findingSeverity in ipairs(arrayValues(Types.FindingSeverity)) do
				for _, findingStatus in ipairs(arrayValues(Types.FindingStatus)) do
					local find = finding(
						"inspection.seed",
						"observation.seed",
						"finding.combo",
						runtimeIndex
					)
					find.findingKind = findingKind
					find.findingSeverity = findingSeverity
					find.findingStatus = findingStatus
					expectAccept(
						"finding enum matrix "
							.. tostring(runtimeIndex)
							.. ":"
							.. findingKind
							.. ":"
							.. findingSeverity
							.. ":"
							.. findingStatus,
						Validation.finding(find),
						nil,
						checks
					)
				end
			end
		end
	end
	for _, auditKind in ipairs(arrayValues(Types.AuditKind)) do
		for _, status in ipairs(arrayValues(Types.AuditStatus)) do
			local auditSchema = withField(
				withField(audit("inspection.seed", "audit.combo", {}), "auditKind", auditKind),
				"status",
				status
			)
			expectAccept(
				"audit enum matrix " .. auditKind .. ":" .. status,
				Validation.audit(auditSchema),
				nil,
				checks
			)
		end
	end
	for _, inspectionKind in ipairs(arrayValues(Types.InspectionKind)) do
		for _, status in ipairs(arrayValues(Types.InspectionStatus)) do
			local inspectionSchema = withField(
				withField(inspection("inspection.combo"), "inspectionKind", inspectionKind),
				"inspectionStatus",
				status
			)
			expectAccept(
				"inspection enum matrix " .. inspectionKind .. ":" .. status,
				Validation.inspection(inspectionSchema),
				nil,
				checks
			)
		end
	end
end

local function integrationReadinessBehavior(checks: { CheckResult })
	expectAccept("integration readiness declarations validate", Validation.validate(), nil, checks)
	expectAccept(
		"integration readiness declaration set validates",
		Validation.integrationReadinessDeclarations(Types.IntegrationReadinessDeclarations),
		nil,
		checks
	)
	expect(
		"integration readiness declaration count matches requested chain",
		#Types.IntegrationReadinessDeclarations == 12,
		"readiness declaration count drifted",
		checks
	)
	local readinessIds: { [string]: boolean } = {}
	for index, declaration in ipairs(Types.IntegrationReadinessDeclarations) do
		local runtimeOrder = Types.RuntimeName[declaration.runtimeName]
		expectAccept(
			"integration readiness declaration accepts " .. declaration.readinessId,
			Validation.integrationReadinessDeclaration(declaration),
			nil,
			checks
		)
		expect(
			"integration readiness id unique " .. declaration.readinessId,
			readinessIds[declaration.readinessId] ~= true,
			"duplicate readiness id",
			checks
		)
		readinessIds[declaration.readinessId] = true
		expect(
			"integration readiness kind supported " .. declaration.readinessId,
			Types.ReadinessKind[declaration.readinessKind] == true,
			"readiness kind drift",
			checks
		)
		expect(
			"integration readiness status supported " .. declaration.readinessId,
			Types.ReadinessStatus[declaration.readinessStatus] == true,
			"readiness status drift",
			checks
		)
		expect(
			"integration readiness provider order " .. declaration.readinessId,
			Types.ProviderName[declaration.providerName] == runtimeOrder,
			"provider order drift",
			checks
		)
		expect(
			"integration readiness snapshot order " .. declaration.readinessId,
			Types.SnapshotProviderName[declaration.snapshotProviderName] == runtimeOrder,
			"snapshot order drift",
			checks
		)
		expect(
			"integration readiness coordinator order " .. declaration.readinessId,
			Types.CoordinatorName[declaration.coordinatorName] == runtimeOrder,
			"coordinator order drift",
			checks
		)
		expect(
			"integration readiness diagnostics provider " .. declaration.readinessId,
			declaration.diagnosticsProviderName == declaration.coordinatorName .. ".inspect",
			"diagnostics provider drift",
			checks
		)
		expect(
			"integration readiness copied metadata " .. declaration.readinessId,
			declaration.metadata.copiedMetadataOnly == true,
			"copied metadata posture drift",
			checks
		)
		expect(
			"integration readiness documentation reference " .. declaration.readinessId,
			type(declaration.documentationReference) == "string"
				and string.match(declaration.documentationReference, "%.md$") ~= nil,
			"documentation reference drift",
			checks
		)
		for _, requiredField in ipairs({
			"readinessId",
			"readinessKind",
			"readinessStatus",
			"runtimeName",
			"providerName",
			"snapshotProviderName",
			"coordinatorName",
			"diagnosticsProviderName",
			"documentationReference",
			"metadata",
		}) do
			expectReject(
				"integration readiness missing "
					.. requiredField
					.. " rejects "
					.. declaration.readinessId,
				Validation.integrationReadinessDeclarations(
					withDeclarationField(index, requiredField, nil)
				),
				nil,
				checks
			)
		end
		expectReject(
			"integration readiness exact readinessId rejects " .. declaration.readinessId,
			Validation.integrationReadinessDeclarations(
				withDeclarationField(index, "readinessId", declaration.readinessId .. ".drift")
			),
			nil,
			checks
		)
		expectReject(
			"integration readiness exact readinessKind rejects " .. declaration.readinessId,
			Validation.integrationReadinessDeclarations(
				withDeclarationField(index, "readinessKind", "RuntimeCompatibility")
			),
			nil,
			checks
		)
		expectReject(
			"integration readiness exact readinessStatus rejects " .. declaration.readinessId,
			Validation.integrationReadinessDeclarations(
				withDeclarationField(index, "readinessStatus", "Declared")
			),
			nil,
			checks
		)
		expectReject(
			"integration readiness exact runtimeName rejects " .. declaration.readinessId,
			Validation.integrationReadinessDeclarations(
				withDeclarationField(index, "runtimeName", "AssetManifest")
			),
			nil,
			checks
		)
		expectReject(
			"integration readiness exact providerName rejects " .. declaration.readinessId,
			Validation.integrationReadinessDeclarations(
				withDeclarationField(
					index,
					"providerName",
					Types.CertifiedRuntimeOrder[1].providerName
				)
			),
			nil,
			checks
		)
		expectReject(
			"integration readiness exact snapshotProviderName rejects " .. declaration.readinessId,
			Validation.integrationReadinessDeclarations(
				withDeclarationField(
					index,
					"snapshotProviderName",
					Types.CertifiedRuntimeOrder[1].snapshotProviderName
				)
			),
			nil,
			checks
		)
		expectReject(
			"integration readiness exact coordinatorName rejects " .. declaration.readinessId,
			Validation.integrationReadinessDeclarations(
				withDeclarationField(
					index,
					"coordinatorName",
					Types.CertifiedRuntimeOrder[1].coordinatorName
				)
			),
			nil,
			checks
		)
		expectReject(
			"integration readiness exact diagnosticsProviderName rejects "
				.. declaration.readinessId,
			Validation.integrationReadinessDeclarations(
				withDeclarationField(index, "diagnosticsProviderName", "InvalidCoordinator.inspect")
			),
			nil,
			checks
		)
		expectReject(
			"integration readiness exact documentationReference rejects " .. declaration.readinessId,
			Validation.integrationReadinessDeclarations(
				withDeclarationField(index, "documentationReference", "INVALID_RUNTIME.md")
			),
			nil,
			checks
		)
		for _, duplicateField in ipairs({
			"readinessId",
			"runtimeName",
			"providerName",
			"snapshotProviderName",
			"coordinatorName",
			"diagnosticsProviderName",
		}) do
			expectReject(
				"integration readiness duplicate "
					.. duplicateField
					.. " rejects "
					.. declaration.readinessId,
				Validation.integrationReadinessDeclarations(
					withDuplicateDeclarationField(index, duplicateField)
				),
				nil,
				checks
			)
		end
		expectReject(
			"integration readiness invalid runtime rejects " .. declaration.readinessId,
			Validation.integrationReadinessDeclaration(
				withField(declaration, "runtimeName", "InvalidRuntime")
			),
			nil,
			checks
		)
		expectReject(
			"integration readiness invalid provider rejects " .. declaration.readinessId,
			Validation.integrationReadinessDeclaration(
				withField(declaration, "providerName", Types.CertifiedRuntimeOrder[1].providerName)
			),
			nil,
			checks
		)
		expectReject(
			"integration readiness invalid snapshot rejects " .. declaration.readinessId,
			Validation.integrationReadinessDeclaration(
				withField(
					declaration,
					"snapshotProviderName",
					Types.CertifiedRuntimeOrder[1].snapshotProviderName
				)
			),
			nil,
			checks
		)
		expectReject(
			"integration readiness invalid coordinator rejects " .. declaration.readinessId,
			Validation.integrationReadinessDeclaration(
				withField(
					declaration,
					"coordinatorName",
					Types.CertifiedRuntimeOrder[1].coordinatorName
				)
			),
			nil,
			checks
		)
		expectReject(
			"integration readiness invalid diagnostics provider rejects " .. declaration.readinessId,
			Validation.integrationReadinessDeclaration(
				withField(declaration, "diagnosticsProviderName", "InvalidCoordinator.inspect")
			),
			nil,
			checks
		)
		expectReject(
			"integration readiness unsafe metadata rejects " .. declaration.readinessId,
			Validation.integrationReadinessDeclaration(
				withField(declaration, "metadata", { ["exec" .. "ute"] = true })
			),
			nil,
			checks
		)
	end
	local missingDeclaration = Serialization.deepCopy(Types.IntegrationReadinessDeclarations)
	table.remove(missingDeclaration, #missingDeclaration)
	expectReject(
		"integration readiness missing declaration rejects",
		Validation.integrationReadinessDeclarations(missingDeclaration),
		nil,
		checks
	)
	local extraDeclaration = Serialization.deepCopy(Types.IntegrationReadinessDeclarations)
	table.insert(
		extraDeclaration,
		Serialization.deepCopy(Types.IntegrationReadinessDeclarations[1])
	)
	expectReject(
		"integration readiness extra declaration rejects",
		Validation.integrationReadinessDeclarations(extraDeclaration),
		nil,
		checks
	)
	expectReject(
		"integration readiness non-table declarations reject",
		Validation.integrationReadinessDeclarations("invalid"),
		nil,
		checks
	)
	for _, readinessKind in ipairs(arrayValues(Types.ReadinessKind)) do
		for _, readinessStatus in ipairs(arrayValues(Types.ReadinessStatus)) do
			local declaration = withField(
				withField(Types.IntegrationReadinessDeclarations[1], "readinessKind", readinessKind),
				"readinessStatus",
				readinessStatus
			)
			expectAccept(
				"integration readiness enum matrix " .. readinessKind .. ":" .. readinessStatus,
				Validation.integrationReadinessDeclaration(declaration),
				nil,
				checks
			)
		end
	end
end

local function decisionReadinessBehavior(checks: { CheckResult })
	expectAccept("decision readiness declarations validate", Validation.validate(), nil, checks)
	expectAccept(
		"decision readiness declaration set validates",
		Validation.decisionReadinessDeclarations(Types.DecisionReadinessDeclarations),
		nil,
		checks
	)
	expect(
		"decision readiness declaration count matches requested chain",
		#Types.DecisionReadinessDeclarations == #Types.IntegrationReadinessDeclarations,
		"decision readiness declaration count drifted",
		checks
	)
	local decisionReadinessIds: { [string]: boolean } = {}
	local decisionCompatibilityIds: { [string]: boolean } = {}
	local decisionDeclarationIds: { [string]: boolean } = {}
	for index, declaration in ipairs(Types.DecisionReadinessDeclarations) do
		local runtimeOrder = Types.RuntimeName[declaration.runtimeName]
		expectAccept(
			"decision readiness declaration accepts " .. declaration.decisionReadinessId,
			Validation.decisionReadinessDeclaration(declaration),
			nil,
			checks
		)
		expect(
			"decision readiness id unique " .. declaration.decisionReadinessId,
			decisionReadinessIds[declaration.decisionReadinessId] ~= true,
			"duplicate decision readiness id",
			checks
		)
		decisionReadinessIds[declaration.decisionReadinessId] = true
		expect(
			"decision compatibility id unique " .. declaration.decisionCompatibilityId,
			decisionCompatibilityIds[declaration.decisionCompatibilityId] ~= true,
			"duplicate decision compatibility id",
			checks
		)
		decisionCompatibilityIds[declaration.decisionCompatibilityId] = true
		expect(
			"decision declaration id unique " .. declaration.decisionDeclarationId,
			decisionDeclarationIds[declaration.decisionDeclarationId] ~= true,
			"duplicate decision declaration id",
			checks
		)
		decisionDeclarationIds[declaration.decisionDeclarationId] = true
		expect(
			"decision readiness kind supported " .. declaration.decisionReadinessId,
			Types.DecisionReadinessKind[declaration.decisionReadinessKind] == true,
			"decision readiness kind drift",
			checks
		)
		expect(
			"decision readiness status supported " .. declaration.decisionReadinessId,
			Types.DecisionReadinessStatus[declaration.decisionReadinessStatus] == true,
			"decision readiness status drift",
			checks
		)
		expect(
			"decision readiness provider order " .. declaration.decisionReadinessId,
			Types.ProviderName[declaration.providerName] == runtimeOrder,
			"provider order drift",
			checks
		)
		expect(
			"decision readiness snapshot order " .. declaration.decisionReadinessId,
			Types.SnapshotProviderName[declaration.snapshotProviderName] == runtimeOrder,
			"snapshot order drift",
			checks
		)
		expect(
			"decision readiness Bootstrap compatibility " .. declaration.decisionReadinessId,
			declaration.bootstrapDependencyName == declaration.coordinatorName,
			"Bootstrap compatibility drift",
			checks
		)
		expect(
			"decision readiness Governance compatibility " .. declaration.decisionReadinessId,
			declaration.governanceSnapshotProviderName == declaration.providerName,
			"Governance compatibility drift",
			checks
		)
		for _, metadataField in ipairs({
			"copiedMetadataOnly",
			"copiedEvidenceOnly",
			"decisionReady",
			"observationOnly",
			"noDecisionAuthority",
			"noRepairAuthority",
			"noExecutionAuthority",
			"noRuntimeMutation",
		}) do
			expect(
				"decision readiness metadata "
					.. metadataField
					.. " "
					.. declaration.decisionReadinessId,
				declaration.metadata[metadataField] == true,
				"decision metadata drift",
				checks
			)
			if index == 1 then
				local metadataDrift = Serialization.deepCopy(declaration.metadata)
				metadataDrift[metadataField] = false
				expectReject(
					"decision readiness metadata "
						.. metadataField
						.. " false rejects "
						.. declaration.decisionReadinessId,
					Validation.decisionReadinessDeclaration(
						withField(declaration, "metadata", metadataDrift)
					),
					nil,
					checks
				)
			end
		end
		if index == 1 then
			for _, requiredField in ipairs({
				"decisionReadinessId",
				"decisionCompatibilityId",
				"decisionDeclarationId",
				"decisionReadinessKind",
				"decisionReadinessStatus",
				"runtimeName",
				"providerName",
				"snapshotProviderName",
				"coordinatorName",
				"diagnosticsProviderName",
				"bootstrapDependencyName",
				"governanceSnapshotProviderName",
				"documentationReference",
				"metadata",
			}) do
				expectReject(
					"decision readiness missing "
						.. requiredField
						.. " rejects "
						.. declaration.decisionReadinessId,
					Validation.decisionReadinessDeclarations(
						withDecisionDeclarationField(index, requiredField, nil)
					),
					nil,
					checks
				)
			end
			for _, exactField in ipairs({
				"decisionReadinessId",
				"decisionCompatibilityId",
				"decisionDeclarationId",
				"runtimeName",
				"providerName",
				"snapshotProviderName",
				"coordinatorName",
				"diagnosticsProviderName",
				"bootstrapDependencyName",
				"governanceSnapshotProviderName",
				"documentationReference",
			}) do
				expectReject(
					"decision readiness exact "
						.. exactField
						.. " rejects "
						.. declaration.decisionReadinessId,
					Validation.decisionReadinessDeclarations(
						withDecisionDeclarationField(
							index,
							exactField,
							tostring(declaration[exactField]) .. ".drift"
						)
					),
					nil,
					checks
				)
			end
		end
		for _, duplicateField in ipairs({
			"decisionReadinessId",
			"decisionCompatibilityId",
			"decisionDeclarationId",
			"runtimeName",
			"providerName",
			"snapshotProviderName",
			"coordinatorName",
			"diagnosticsProviderName",
		}) do
			expectReject(
				"decision readiness duplicate "
					.. duplicateField
					.. " rejects "
					.. declaration.decisionReadinessId,
				Validation.decisionReadinessDeclarations(
					withDuplicateDecisionDeclarationField(index, duplicateField)
				),
				nil,
				checks
			)
		end
		expectReject(
			"decision readiness decision marker rejects " .. declaration.decisionReadinessId,
			Validation.decisionReadinessDeclaration(
				withField(declaration, "metadata", { decisionEngine = true })
			),
			nil,
			checks
		)
		expectReject(
			"decision readiness repair marker rejects " .. declaration.decisionReadinessId,
			Validation.decisionReadinessDeclaration(
				withField(declaration, "metadata", { ["re" .. "pair"] = true })
			),
			nil,
			checks
		)
	end
	local missingDeclaration = Serialization.deepCopy(Types.DecisionReadinessDeclarations)
	table.remove(missingDeclaration, #missingDeclaration)
	expectReject(
		"decision readiness missing declaration rejects",
		Validation.decisionReadinessDeclarations(missingDeclaration),
		nil,
		checks
	)
	local extraDeclaration = Serialization.deepCopy(Types.DecisionReadinessDeclarations)
	table.insert(extraDeclaration, Serialization.deepCopy(Types.DecisionReadinessDeclarations[1]))
	expectReject(
		"decision readiness extra declaration rejects",
		Validation.decisionReadinessDeclarations(extraDeclaration),
		nil,
		checks
	)
	expectReject(
		"decision readiness non-table declarations reject",
		Validation.decisionReadinessDeclarations("invalid"),
		nil,
		checks
	)
	for _, readinessKind in ipairs(arrayValues(Types.DecisionReadinessKind)) do
		for _, readinessStatus in ipairs(arrayValues(Types.DecisionReadinessStatus)) do
			local declaration = withField(
				withField(
					Types.DecisionReadinessDeclarations[1],
					"decisionReadinessKind",
					readinessKind
				),
				"decisionReadinessStatus",
				readinessStatus
			)
			expectAccept(
				"decision readiness enum matrix " .. readinessKind .. ":" .. readinessStatus,
				Validation.decisionReadinessDeclaration(declaration),
				nil,
				checks
			)
		end
	end
end

local function forbiddenPayloads(checks: { CheckResult })
	for markerIndex, marker in ipairs(Serialization.forbiddenMarkers()) do
		local baseInspection = inspection("inspection.forbidden." .. tostring(markerIndex))
		local baseObservation =
			observation("inspection.seed", "observation.forbidden." .. tostring(markerIndex), 1)
		local baseFinding = finding(
			"inspection.seed",
			"observation.seed",
			"finding.forbidden." .. tostring(markerIndex),
			1
		)
		local baseAudit = audit("inspection.seed", "audit.forbidden." .. tostring(markerIndex), {})
		local cases = {
			{
				"inspection metadata value",
				Validation.inspection,
				withField(baseInspection, "metadata", { marker = marker }),
			},
			{
				"inspection metadata key",
				Validation.inspection,
				withField(baseInspection, "metadata", { [marker] = true }),
			},
			{
				"inspection tags",
				Validation.inspection,
				withField(baseInspection, "tags", { marker }),
			},
			{
				"observation metadata value",
				Validation.observation,
				withField(baseObservation, "metadata", { marker = marker }),
			},
			{
				"observation metadata key",
				Validation.observation,
				withField(baseObservation, "metadata", { [marker] = true }),
			},
			{
				"observation evidence",
				Validation.observation,
				withField(baseObservation, "evidence", { marker }),
			},
			{
				"observation tags",
				Validation.observation,
				withField(baseObservation, "tags", { marker }),
			},
			{
				"finding metadata value",
				Validation.finding,
				withField(baseFinding, "metadata", { marker = marker }),
			},
			{
				"finding metadata key",
				Validation.finding,
				withField(baseFinding, "metadata", { [marker] = true }),
			},
			{ "finding tags", Validation.finding, withField(baseFinding, "tags", { marker }) },
			{
				"finding evidence",
				Validation.finding,
				withField(baseFinding, "evidence", { marker }),
			},
			{
				"audit metadata value",
				Validation.audit,
				withField(baseAudit, "metadata", { marker = marker }),
			},
			{
				"audit metadata key",
				Validation.audit,
				withField(baseAudit, "metadata", { [marker] = true }),
			},
			{ "audit findings", Validation.audit, withField(baseAudit, "findings", { marker }) },
		}
		for _, case in ipairs(cases) do
			local ok, reason = case[2](case[3])
			expectReject(case[1] .. " rejects " .. marker, ok, reason, checks)
		end
	end
end

local function stateBehavior(checks: { CheckResult })
	State.clear()
	local inspectA = inspection("inspection.state")
	expectAccept("state registers inspection", State.registerInspection(inspectA), nil, checks)
	expectReject(
		"state rejects duplicate inspection",
		State.registerInspection(inspectA),
		nil,
		checks
	)
	local obsA = observation("inspection.state", "observation.state", 1)
	expectAccept("state registers observation", State.registerObservation(obsA), nil, checks)
	expectReject(
		"state rejects duplicate observation",
		State.registerObservation(obsA),
		nil,
		checks
	)
	local findA = finding("inspection.state", "observation.state", "finding.state", 1)
	expectAccept("state registers finding", State.registerFinding(findA), nil, checks)
	expectReject("state rejects duplicate finding", State.registerFinding(findA), nil, checks)
	local auditA = audit("inspection.state", "audit.state", { "finding.state" })
	expectAccept("state registers audit", State.registerAudit(auditA), nil, checks)
	expectReject("state rejects duplicate audit", State.registerAudit(auditA), nil, checks)
	expectReject(
		"observation missing inspection rejects",
		State.registerObservation(observation("missing.inspection", "observation.missing", 1)),
		nil,
		checks
	)
	expectReject(
		"finding missing inspection rejects",
		State.registerFinding(
			finding("missing.inspection", "observation.state", "finding.missing.inspection", 1)
		),
		nil,
		checks
	)
	expectReject(
		"finding missing observation rejects",
		State.registerFinding(
			finding("inspection.state", "missing.observation", "finding.missing.observation", 1)
		),
		nil,
		checks
	)
	expectReject(
		"audit missing inspection rejects",
		State.registerAudit(audit("missing.inspection", "audit.missing.inspection", {})),
		nil,
		checks
	)
	expectReject(
		"audit missing finding rejects",
		State.registerAudit(
			audit("inspection.state", "audit.missing.finding", { "missing.finding" })
		),
		nil,
		checks
	)
	local before = State.inspect().counts
	expectReject(
		"invalid observation preserves state",
		State.registerObservation(withField(obsA, "providerName", "badProvider")),
		nil,
		checks
	)
	local after = State.inspect().counts
	expect(
		"failed validation preserved observation count",
		before.observations == after.observations,
		"failed validation changed state",
		checks
	)
	State.recordValidationFailure("unsafe", { payload = function() end })
	local failure = State.inspect().validationFailures[1]
	expect(
		"validation failure diagnostic sanitizes function",
		failure.payload.payload == "<unsafe-runtime-value>",
		"unsafe diagnostic leaked",
		checks
	)
	local state = State.inspect()
	state.inspections["inspection.state"].metadata.copied = false
	expect(
		"state inspect is isolated",
		State.inspect().inspections["inspection.state"].metadata.copied == true,
		"state inspect leaked mutable table",
		checks
	)
	State.clear()
	expect(
		"clear resets inspections",
		State.inspect().counts.inspections == 0,
		"clear failed",
		checks
	)
	expect(
		"clear resets observations",
		State.inspect().counts.observations == 0,
		"clear failed",
		checks
	)
	expect("clear resets findings", State.inspect().counts.findings == 0, "clear failed", checks)
	expect("clear resets audits", State.inspect().counts.audits == 0, "clear failed", checks)
end

local function reportBehavior(checks: { CheckResult })
	State.clear()
	local lifecycle =
		{ initialized = true, started = false, lastSelfChecks = { ok = true, total = 1 } }
	local dependencies = { Serialization = Serialization, State = State, Validation = Validation }
	local diag = Diagnostics.capture(lifecycle, dependencies)
	expect(
		"diagnostics provider posture matches",
		diag.providerPosture == Types.RuntimeProviderName,
		"provider posture mismatch",
		checks
	)
	expect(
		"diagnostics snapshot posture matches",
		diag.snapshotPosture == Types.SnapshotKind,
		"snapshot posture mismatch",
		checks
	)
	expect(
		"diagnostics health only",
		diag.health == "Healthy" and diag.validationOk == true,
		"diagnostics health drift",
		checks
	)
	for _, key in ipairs(Types.PostureKeys) do
		expect(
			"diagnostics posture key exists " .. key,
			diag[key] ~= nil,
			"missing posture key",
			checks
		)
	end
	diag.integrationReadinessPosture[1].metadata.copiedMetadataOnly = false
	expect(
		"diagnostics readiness posture is isolated",
		Diagnostics.capture(lifecycle, dependencies).integrationReadinessPosture[1].metadata.copiedMetadataOnly
			== true,
		"diagnostics readiness posture leaked mutable table",
		checks
	)
	diag.decisionReadinessPosture[1].metadata.noDecisionAuthority = false
	expect(
		"diagnostics decision readiness posture is isolated",
		Diagnostics.capture(lifecycle, dependencies).decisionReadinessPosture[1].metadata.noDecisionAuthority
			== true,
		"diagnostics decision readiness posture leaked mutable table",
		checks
	)
	local snapshot = Snapshots.capture(lifecycle, dependencies)
	expect(
		"snapshot kind matches",
		snapshot.kind == Types.SnapshotKind,
		"snapshot kind mismatch",
		checks
	)
	expect(
		"snapshot provider posture matches",
		snapshot.providerPosture == Types.RuntimeProviderName,
		"snapshot provider mismatch",
		checks
	)
	expect(
		"snapshot posture matches",
		snapshot.snapshotPosture == Types.SnapshotKind,
		"snapshot posture mismatch",
		checks
	)
	for _, key in ipairs(Types.PostureKeys) do
		expect(
			"snapshot posture key exists " .. key,
			snapshot[key] ~= nil,
			"missing posture key",
			checks
		)
	end
	snapshot.noAuthorityPosture.noRepair = false
	expect(
		"snapshot is isolated",
		Snapshots.capture(lifecycle, dependencies).noAuthorityPosture.noRepair == true,
		"snapshot leaked mutable table",
		checks
	)
	snapshot.integrationReadinessPosture[1].metadata.copiedMetadataOnly = false
	expect(
		"snapshot readiness posture is isolated",
		Snapshots.capture(lifecycle, dependencies).integrationReadinessPosture[1].metadata.copiedMetadataOnly
			== true,
		"snapshot readiness posture leaked mutable table",
		checks
	)
	snapshot.decisionReadinessPosture[1].metadata.noDecisionAuthority = false
	expect(
		"snapshot decision readiness posture is isolated",
		Snapshots.capture(lifecycle, dependencies).decisionReadinessPosture[1].metadata.noDecisionAuthority
			== true,
		"snapshot decision readiness posture leaked mutable table",
		checks
	)
	diag.noAuthorityPosture.noMutation = false
	expect(
		"diagnostics is isolated",
		Diagnostics.capture(lifecycle, dependencies).noAuthorityPosture.noMutation == true,
		"diagnostics leaked mutable table",
		checks
	)
	expect(
		"signals include initialized",
		Signals.RuntimeInitialized == "AssetGovernanceCertificationInspection.RuntimeInitialized",
		"signal drift",
		checks
	)
	expect(
		"signals include validation rejection",
		Signals.ValidationRejected == "AssetGovernanceCertificationInspection.ValidationRejected",
		"signal drift",
		checks
	)
end

local function serviceBehavior(context: any, checks: { CheckResult })
	if context.Service == nil then
		return
	end
	local service = context.Service
	service.shutdown()
	expectAccept("service initializes", service.initialize().ok, nil, checks)
	expectAccept("service double initialize is safe", service.initialize().ok, nil, checks)
	local serviceDiag = service.inspect()
	expect(
		"service diagnostics provider",
		serviceDiag.providerPosture == Types.RuntimeProviderName,
		"provider drift",
		checks
	)
	expectAccept("service starts", service.start().ok, nil, checks)
	expectReject("service self-check blocked after start", service.runSelfChecks().ok, nil, checks)
	expectAccept("service shutdown cleans", service.shutdown().ok, nil, checks)
	expect(
		"service shutdown reset",
		service.inspect().counts.inspections == 0,
		"shutdown did not clear state",
		checks
	)
end

function SelfChecks.run(context: any?)
	local checks: { CheckResult } = {}
	exactSurfaces(checks)
	validationBehavior(checks)
	compatibilityMatrices(checks)
	integrationReadinessBehavior(checks)
	decisionReadinessBehavior(checks)
	forbiddenPayloads(checks)
	stateBehavior(checks)
	reportBehavior(checks)
	serviceBehavior(context or {}, checks)
	local failed = {}
	for _, check in ipairs(checks) do
		if not check.ok then
			table.insert(failed, check)
		end
	end
	return {
		ok = #failed == 0,
		code = if #failed == 0
			then "AssetGovernanceCertificationInspectionSelfChecksPassed"
			else "AssetGovernanceCertificationInspectionSelfChecksFailed",
		total = #checks,
		failed = failed,
	}
end

return SelfChecks
