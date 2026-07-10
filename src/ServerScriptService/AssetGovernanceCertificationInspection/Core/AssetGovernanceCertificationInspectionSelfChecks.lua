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
		severity = "Warning",
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
		"severity",
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
		"observation kind",
		Types.ObservationKind,
		arrayValues(Types.ObservationKind),
		checks
	)
	expectExactMapKeys("finding kind", Types.FindingKind, arrayValues(Types.FindingKind), checks)
	expectExactMapKeys("audit kind", Types.AuditKind, arrayValues(Types.AuditKind), checks)
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
	for _, value in ipairs(arrayValues(Types.Severity)) do
		expectAccept(
			"finding accepts severity " .. value,
			Validation.finding(withField(seedFinding, "severity", value)),
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
		{ seedFinding, "severity", Validation.finding },
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
	for runtimeIndex = 1, 8 do
		for _, findingKind in ipairs(arrayValues(Types.FindingKind)) do
			for _, severity in ipairs(arrayValues(Types.Severity)) do
				local find =
					finding("inspection.seed", "observation.seed", "finding.combo", runtimeIndex)
				find.findingKind = findingKind
				find.severity = severity
				expectAccept(
					"finding enum matrix "
						.. tostring(runtimeIndex)
						.. ":"
						.. findingKind
						.. ":"
						.. severity,
					Validation.finding(find),
					nil,
					checks
				)
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
