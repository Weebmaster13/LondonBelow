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
		schemaType = Types.SchemaType.GovernanceDecision,
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
		schemaType = Types.SchemaType.GovernanceDecisionRequirement,
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
		schemaType = Types.SchemaType.GovernanceDecisionEvaluation,
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
		schemaType = Types.SchemaType.GovernanceDecisionAudit,
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
	expectExactArray("decision posture keys", Types.PostureKeys, {
		"decisionRuntimePosture",
		"decisionEvaluationPosture",
		"decisionRequirementPosture",
		"decisionAuditPosture",
		"decisionEvidencePosture",
		"decisionIsolationPosture",
		"decisionValidationPosture",
		"providerPosture",
		"snapshotPosture",
		"documentationPosture",
		"bootstrapPosture",
		"governancePosture",
		"noAuthorityPosture",
		"noExecutionPosture",
		"noRepairPosture",
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
	validationBehavior(checks)
	forbiddenPayloads(checks)
	extendedMatrixCoverage(checks)
	stateBehavior(checks)
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
