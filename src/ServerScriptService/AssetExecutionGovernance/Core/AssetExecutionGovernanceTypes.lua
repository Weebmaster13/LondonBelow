--!strict

local Types = {}

Types.Mode = "ServerAuthoritativeAssetExecutionGovernanceMetadataRuntime"
Types.RuntimeProviderName = "assetExecutionGovernanceRuntime"
Types.SnapshotKind = "assetExecutionGovernanceRuntimeSnapshot"

Types.SchemaType = {
	ExecutionGovernance = "ExecutionGovernance",
	ExecutionGovernanceRequirement = "ExecutionGovernanceRequirement",
	ExecutionGovernanceAssessment = "ExecutionGovernanceAssessment",
	ExecutionGovernanceFinding = "ExecutionGovernanceFinding",
	ExecutionGovernanceAudit = "ExecutionGovernanceAudit",
}

Types.SchemaFields = {
	ExecutionGovernance = {
		"governanceId",
		"decisionId",
		"executionReadinessId",
		"governanceKind",
		"governanceStatus",
		"runtimeName",
		"providerName",
		"snapshotProviderName",
		"requirementIds",
		"assessmentIds",
		"findingIds",
		"auditIds",
		"evidence",
		"tags",
		"metadata",
	},
	ExecutionGovernanceRequirement = {
		"requirementId",
		"governanceId",
		"requirementKind",
		"requirementStatus",
		"runtimeName",
		"providerName",
		"snapshotProviderName",
		"required",
		"evidence",
		"tags",
		"metadata",
	},
	ExecutionGovernanceAssessment = {
		"assessmentId",
		"governanceId",
		"requirementId",
		"assessmentKind",
		"assessmentStatus",
		"runtimeName",
		"providerName",
		"snapshotProviderName",
		"evidence",
		"tags",
		"metadata",
	},
	ExecutionGovernanceFinding = {
		"findingId",
		"governanceId",
		"assessmentId",
		"findingKind",
		"findingSeverity",
		"findingStatus",
		"summary",
		"evidence",
		"tags",
		"metadata",
	},
	ExecutionGovernanceAudit = {
		"auditId",
		"governanceId",
		"assessmentIds",
		"findingIds",
		"auditKind",
		"auditStatus",
		"reviewer",
		"evidence",
		"tags",
		"metadata",
	},
}

Types.SchemaFieldCount = {}
for schemaName, fields in pairs(Types.SchemaFields) do
	Types.SchemaFieldCount[schemaName] = #fields
end

Types.GovernanceKind = {
	DecisionEvidenceGovernance = true,
	ExecutionReadinessGovernance = true,
	ProviderGovernance = true,
	RuntimeGovernance = true,
	SnapshotGovernance = true,
	BootstrapGovernance = true,
	DocumentationGovernance = true,
	BoundaryGovernance = true,
	IsolationGovernance = true,
	FutureGovernance = true,
}

Types.GovernanceStatus = {
	Declared = true,
	UnderReview = true,
	Satisfied = true,
	Unsatisfied = true,
	Blocked = true,
	Deferred = true,
	Warning = true,
}

Types.RequirementKind = {
	DecisionEvidenceRequirement = true,
	ExecutionReadinessRequirement = true,
	ProviderConsistencyRequirement = true,
	RuntimeConsistencyRequirement = true,
	SnapshotConsistencyRequirement = true,
	BootstrapConsistencyRequirement = true,
	DocumentationConsistencyRequirement = true,
	BoundaryRequirement = true,
	IsolationRequirement = true,
	FutureRequirement = true,
}

Types.RequirementStatus = {
	Required = true,
	Satisfied = true,
	Unsatisfied = true,
	Deferred = true,
	Warning = true,
}

Types.AssessmentKind = {
	DecisionEvidenceAssessment = true,
	ExecutionReadinessAssessment = true,
	ProviderConsistencyAssessment = true,
	RuntimeConsistencyAssessment = true,
	SnapshotConsistencyAssessment = true,
	BootstrapConsistencyAssessment = true,
	DocumentationConsistencyAssessment = true,
	BoundaryAssessment = true,
	IsolationAssessment = true,
	FutureAssessment = true,
}

Types.AssessmentStatus = {
	Passed = true,
	Failed = true,
	Blocked = true,
	Deferred = true,
	Warning = true,
}

Types.FindingKind = {
	MissingEvidence = true,
	CompatibilityDrift = true,
	ProviderDrift = true,
	RuntimeDrift = true,
	SnapshotDrift = true,
	BootstrapDrift = true,
	DocumentationDrift = true,
	BoundaryViolation = true,
	IsolationViolation = true,
	UnsafeMetadata = true,
	FutureFinding = true,
}

Types.FindingSeverity = {
	Informational = true,
	Low = true,
	Medium = true,
	High = true,
	Critical = true,
}

Types.FindingStatus = {
	Open = true,
	Reviewed = true,
	Acknowledged = true,
	Deferred = true,
	ResolvedMetadataOnly = true,
}

Types.AuditKind = {
	GovernanceAudit = true,
	RequirementAudit = true,
	AssessmentAudit = true,
	FindingAudit = true,
	CoverageAudit = true,
	BoundaryAudit = true,
	ProductionAudit = true,
	FutureAudit = true,
}

Types.AuditStatus = {
	Passed = true,
	Failed = true,
	Warning = true,
	Deferred = true,
	Blocked = true,
}

Types.IntegrationReadinessDeclarationFields = {
	"integrationId",
	"compatibilityId",
	"integrationDeclarationId",
	"integrationKind",
	"integrationStatus",
	"runtimeName",
	"providerName",
	"snapshotProviderName",
	"coordinatorName",
	"diagnosticsProviderName",
	"bootstrapDependencyName",
	"engineGovernanceSnapshotProviderName",
	"documentationReference",
	"decisionRuntimeName",
	"decisionProviderName",
	"decisionSnapshotProviderName",
	"executionReadinessEvidenceKind",
	"executionGovernanceRuntimeName",
	"executionGovernanceProviderName",
	"executionGovernanceSnapshotProviderName",
	"authorizationBoundaryKind",
	"required",
	"evidence",
	"tags",
	"metadata",
}

Types.IntegrationKind = {
	DecisionRuntimeIntegrationReadiness = true,
	ExecutionReadinessCompatibility = true,
	GovernanceRuntimeCompatibility = true,
	ProviderCompatibility = true,
	SnapshotCompatibility = true,
	BootstrapCompatibility = true,
	EngineGovernanceCompatibility = true,
	DocumentationCompatibility = true,
	AuthorizationBoundarySeparation = true,
	FutureExecutionSeparation = true,
}

Types.IntegrationStatus = {
	Declared = true,
	Compatible = true,
	IntegrationReady = true,
	BoundaryReady = true,
	Deferred = true,
	Warning = true,
	Blocked = true,
}

Types.AuthorizationBoundaryKind = {
	NoAuthorizationRuntime = true,
	NoExecutionPermission = true,
	NoAuthorityTokens = true,
	NoOperationalRejection = true,
	NoRoutingOrDispatch = true,
	NoQueueOrScheduler = true,
	NoOrchestration = true,
	NoAssetOperations = true,
	FutureAuthorizationSeparate = true,
	FutureExecutionSeparate = true,
}

Types.RuntimeIdentity = {
	runtimeName = "AssetExecutionGovernance",
	providerName = Types.RuntimeProviderName,
	snapshotProviderName = Types.RuntimeProviderName,
	coordinatorName = "AssetExecutionGovernanceCoordinator",
	diagnosticsProviderName = Types.RuntimeProviderName,
	bootstrapDependencyName = "AssetGovernanceCertificationDecisionCoordinator",
	engineGovernanceSnapshotProviderName = Types.RuntimeProviderName,
	documentationReference = "ASSET_EXECUTION_GOVERNANCE_INTEGRATION_READINESS.md",
}

Types.DecisionRuntimeIdentity = {
	decisionRuntimeName = "AssetGovernanceCertificationDecision",
	decisionProviderName = "assetGovernanceCertificationDecisionRuntime",
	decisionSnapshotProviderName = "assetGovernanceCertificationDecisionRuntimeSnapshot",
}

Types.ExecutionReadinessEvidenceKind = "future-governed-execution-readiness"

Types.ExecutionGovernanceIdentity = {
	executionGovernanceRuntimeName = "AssetExecutionGovernance",
	executionGovernanceProviderName = Types.RuntimeProviderName,
	executionGovernanceSnapshotProviderName = Types.RuntimeProviderName,
}

Types.IntegrationReadinessDocumentationReferencePolicy = "SharedIntegrationReadinessDocument"

Types.IntegrationReadinessMetadataFields = {
	"copied",
	"order",
	"compatibility",
}

local function integrationDeclaration(
	suffix: string,
	kind: string,
	status: string,
	boundaryKind: string,
	evidence: { string },
	tags: { string },
	metadata: { [string]: any }
): { [string]: any }
	return {
		integrationId = "asset-execution-governance.integration." .. suffix,
		compatibilityId = "asset-execution-governance.compatibility." .. suffix,
		integrationDeclarationId = "asset-execution-governance.declaration." .. suffix,
		integrationKind = kind,
		integrationStatus = status,
		runtimeName = Types.RuntimeIdentity.runtimeName,
		providerName = Types.RuntimeIdentity.providerName,
		snapshotProviderName = Types.RuntimeIdentity.snapshotProviderName,
		coordinatorName = Types.RuntimeIdentity.coordinatorName,
		diagnosticsProviderName = Types.RuntimeIdentity.diagnosticsProviderName,
		bootstrapDependencyName = Types.RuntimeIdentity.bootstrapDependencyName,
		engineGovernanceSnapshotProviderName = Types.RuntimeIdentity.engineGovernanceSnapshotProviderName,
		documentationReference = Types.RuntimeIdentity.documentationReference,
		decisionRuntimeName = Types.DecisionRuntimeIdentity.decisionRuntimeName,
		decisionProviderName = Types.DecisionRuntimeIdentity.decisionProviderName,
		decisionSnapshotProviderName = Types.DecisionRuntimeIdentity.decisionSnapshotProviderName,
		executionReadinessEvidenceKind = Types.ExecutionReadinessEvidenceKind,
		executionGovernanceRuntimeName = Types.ExecutionGovernanceIdentity.executionGovernanceRuntimeName,
		executionGovernanceProviderName = Types.ExecutionGovernanceIdentity.executionGovernanceProviderName,
		executionGovernanceSnapshotProviderName = Types.ExecutionGovernanceIdentity.executionGovernanceSnapshotProviderName,
		authorizationBoundaryKind = boundaryKind,
		required = true,
		evidence = evidence,
		tags = tags,
		metadata = metadata,
	}
end

Types.IntegrationReadinessDeclarations = {
	integrationDeclaration(
		"decision-runtime",
		"DecisionRuntimeIntegrationReadiness",
		"IntegrationReady",
		"FutureAuthorizationSeparate",
		{ "decision-runtime.identity.copied", "decision-runtime.snapshot-kind.copied" },
		{ "integration-readiness", "decision-runtime", "copied-metadata" },
		{ copied = true, order = 1, compatibility = "decision-runtime" }
	),
	integrationDeclaration(
		"execution-readiness",
		"ExecutionReadinessCompatibility",
		"Compatible",
		"FutureAuthorizationSeparate",
		{ "execution-readiness.evidence-kind.copied", "execution-readiness.boundary.copied" },
		{ "integration-readiness", "execution-readiness", "copied-metadata" },
		{ copied = true, order = 2, compatibility = "execution-readiness" }
	),
	integrationDeclaration(
		"governance-runtime",
		"GovernanceRuntimeCompatibility",
		"Compatible",
		"FutureAuthorizationSeparate",
		{
			"execution-governance.runtime.identity.copied",
			"execution-governance.schema-boundary.copied",
		},
		{ "integration-readiness", "governance-runtime", "copied-metadata" },
		{ copied = true, order = 3, compatibility = "governance-runtime" }
	),
	integrationDeclaration(
		"provider",
		"ProviderCompatibility",
		"Compatible",
		"FutureAuthorizationSeparate",
		{ "assetExecutionGovernanceRuntime.provider.copied" },
		{ "integration-readiness", "provider", "lower-camel-case" },
		{ copied = true, order = 4, compatibility = "provider" }
	),
	integrationDeclaration(
		"snapshot",
		"SnapshotCompatibility",
		"Compatible",
		"FutureAuthorizationSeparate",
		{ "assetExecutionGovernanceRuntime.snapshot-provider.copied" },
		{ "integration-readiness", "snapshot", "isolated-copy" },
		{ copied = true, order = 5, compatibility = "snapshot" }
	),
	integrationDeclaration(
		"bootstrap",
		"BootstrapCompatibility",
		"Compatible",
		"FutureAuthorizationSeparate",
		{ "bootstrap.after.certification-decision.copied" },
		{ "integration-readiness", "bootstrap", "ordered" },
		{ copied = true, order = 6, compatibility = "bootstrap" }
	),
	integrationDeclaration(
		"engine-governance",
		"EngineGovernanceCompatibility",
		"Compatible",
		"FutureAuthorizationSeparate",
		{ "engine-governance.snapshot-provider.copied" },
		{ "integration-readiness", "engine-governance", "contract" },
		{ copied = true, order = 7, compatibility = "engine-governance" }
	),
	integrationDeclaration(
		"documentation",
		"DocumentationCompatibility",
		"Compatible",
		"FutureAuthorizationSeparate",
		{ "documentation.integration-readiness.copied" },
		{ "integration-readiness", "documentation", "schema-terminology" },
		{ copied = true, order = 8, compatibility = "documentation" }
	),
	integrationDeclaration(
		"authorization-boundary",
		"AuthorizationBoundarySeparation",
		"BoundaryReady",
		"NoAuthorizationRuntime",
		{ "future-authorization.separate-boundary.copied" },
		{ "integration-readiness", "future-authorization", "separate-layer" },
		{ copied = true, order = 9, compatibility = "future-authorization-boundary" }
	),
	integrationDeclaration(
		"future-execution",
		"FutureExecutionSeparation",
		"BoundaryReady",
		"FutureExecutionSeparate",
		{ "future-execution.separate-boundary.copied" },
		{ "integration-readiness", "future-execution", "separate-layer" },
		{ copied = true, order = 10, compatibility = "future-execution-boundary" }
	),
}

Types.IntegrationReadinessDeclarationOrder = {
	"asset-execution-governance.integration.decision-runtime",
	"asset-execution-governance.integration.execution-readiness",
	"asset-execution-governance.integration.governance-runtime",
	"asset-execution-governance.integration.provider",
	"asset-execution-governance.integration.snapshot",
	"asset-execution-governance.integration.bootstrap",
	"asset-execution-governance.integration.engine-governance",
	"asset-execution-governance.integration.documentation",
	"asset-execution-governance.integration.authorization-boundary",
	"asset-execution-governance.integration.future-execution",
}

Types.IntegrationReadinessCompatibilityOrder = {
	"asset-execution-governance.compatibility.decision-runtime",
	"asset-execution-governance.compatibility.execution-readiness",
	"asset-execution-governance.compatibility.governance-runtime",
	"asset-execution-governance.compatibility.provider",
	"asset-execution-governance.compatibility.snapshot",
	"asset-execution-governance.compatibility.bootstrap",
	"asset-execution-governance.compatibility.engine-governance",
	"asset-execution-governance.compatibility.documentation",
	"asset-execution-governance.compatibility.authorization-boundary",
	"asset-execution-governance.compatibility.future-execution",
}

Types.IntegrationReadinessDeclarationIdOrder = {
	"asset-execution-governance.declaration.decision-runtime",
	"asset-execution-governance.declaration.execution-readiness",
	"asset-execution-governance.declaration.governance-runtime",
	"asset-execution-governance.declaration.provider",
	"asset-execution-governance.declaration.snapshot",
	"asset-execution-governance.declaration.bootstrap",
	"asset-execution-governance.declaration.engine-governance",
	"asset-execution-governance.declaration.documentation",
	"asset-execution-governance.declaration.authorization-boundary",
	"asset-execution-governance.declaration.future-execution",
}

Types.IntegrationReadinessKindOrder = {
	"DecisionRuntimeIntegrationReadiness",
	"ExecutionReadinessCompatibility",
	"GovernanceRuntimeCompatibility",
	"ProviderCompatibility",
	"SnapshotCompatibility",
	"BootstrapCompatibility",
	"EngineGovernanceCompatibility",
	"DocumentationCompatibility",
	"AuthorizationBoundarySeparation",
	"FutureExecutionSeparation",
}

Types.IntegrationReadinessStatusOrder = {
	"IntegrationReady",
	"Compatible",
	"Compatible",
	"Compatible",
	"Compatible",
	"Compatible",
	"Compatible",
	"Compatible",
	"BoundaryReady",
	"BoundaryReady",
}

Types.IntegrationReadinessBoundaryOrder = {
	"FutureAuthorizationSeparate",
	"FutureAuthorizationSeparate",
	"FutureAuthorizationSeparate",
	"FutureAuthorizationSeparate",
	"FutureAuthorizationSeparate",
	"FutureAuthorizationSeparate",
	"FutureAuthorizationSeparate",
	"FutureAuthorizationSeparate",
	"NoAuthorizationRuntime",
	"FutureExecutionSeparate",
}

Types.PostureKeys = {
	"assetExecutionGovernancePosture",
	"governanceMetadataPosture",
	"governanceRequirementPosture",
	"governanceAssessmentPosture",
	"governanceFindingPosture",
	"governanceAuditPosture",
	"governanceBoundaryPosture",
	"governanceIsolationPosture",
	"governanceValidationPosture",
	"providerPosture",
	"snapshotPosture",
	"bootstrapPosture",
	"documentationPosture",
	"integrationReadinessPosture",
	"integrationDeclarationPosture",
	"decisionRuntimeCompatibilityPosture",
	"executionReadinessCompatibilityPosture",
	"executionGovernanceCompatibilityPosture",
	"futureAuthorizationSeparationPosture",
	"futureExecutionSeparationPosture",
	"integrationHardeningPosture",
	"declarationOrderingPosture",
	"declarationImmutabilityPosture",
	"compatibilityIdentityPosture",
	"runtimeLimitIsolationPosture",
	"noAuthorizationPosture",
	"noOperationalRejectionPosture",
	"noPermissionPosture",
	"noRoutingPosture",
	"noDispatchPosture",
	"noQueuePosture",
	"noSchedulingPosture",
	"noOrchestrationPosture",
	"noExecutionPosture",
	"noMutationPosture",
	"noAuthorityPosture",
}

Types.DocumentationFiles = {
	"ASSET_EXECUTION_GOVERNANCE_RUNTIME.md",
	"ASSET_EXECUTION_GOVERNANCE_VALIDATION.md",
	"ASSET_EXECUTION_GOVERNANCE_SERIALIZATION.md",
	"ASSET_EXECUTION_GOVERNANCE_DIAGNOSTICS.md",
	"ASSET_EXECUTION_GOVERNANCE_SELF_CHECKS.md",
	"ASSET_EXECUTION_GOVERNANCE_RUNTIME_LIMITS.md",
	"ASSET_EXECUTION_GOVERNANCE_AUDIT.md",
	"ASSET_EXECUTION_GOVERNANCE_PRODUCTION_REVIEW.md",
	"ASSET_EXECUTION_GOVERNANCE_INTEGRATION_READINESS.md",
	"EXECUTION_GOVERNANCE_RUNTIME.md",
	"EXECUTION_GOVERNANCE_REQUIREMENT_RUNTIME.md",
	"EXECUTION_GOVERNANCE_ASSESSMENT_RUNTIME.md",
	"EXECUTION_GOVERNANCE_FINDING_RUNTIME.md",
	"EXECUTION_GOVERNANCE_AUDIT_RUNTIME.md",
}

Types.BootstrapDependencyOrder = {
	"AssetGovernanceCertificationDecisionCoordinator",
}

Types.Limits = {
	MaxGovernance = 140,
	MaxRequirements = 540,
	MaxAssessments = 720,
	MaxFindings = 420,
	MaxAudits = 320,
	MaxValidationFailures = 260,
	MaxSnapshotHistory = 70,
	MaxPayloadDepth = 8,
	MaxPayloadNodes = 560,
	MaxStringLength = 300,
	MaxTags = 36,
	MaxEvidence = 64,
	MaxIntegrationDeclarations = 10,
	MaxChildReferences = 260,
	MaxSummaryLength = 180,
}

return Types
