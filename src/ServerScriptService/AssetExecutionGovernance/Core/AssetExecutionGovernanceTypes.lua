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

Types.AuthorizationReadinessDeclarationFields = {
	"authorizationReadinessId",
	"authorizationCompatibilityId",
	"authorizationDependencyId",
	"authorizationIdentityId",
	"authorizationBoundaryId",
	"authorizationBoundaryKind",
	"authorizationReadinessKind",
	"authorizationReadinessStatus",
	"runtimeName",
	"providerName",
	"snapshotProviderName",
	"coordinatorName",
	"diagnosticsProviderName",
	"bootstrapDependencyName",
	"engineGovernanceSnapshotProviderName",
	"documentationReference",
	"governanceCompatibilityId",
	"executionReadinessEvidenceKind",
	"futureAuthorizationRuntimeName",
	"futureAuthorizationProviderName",
	"futureAuthorizationSnapshotKind",
	"futureExecutionRuntimeName",
	"futureExecutionProviderName",
	"required",
	"evidence",
	"tags",
	"metadata",
}

Types.AuthorizationReadinessKind = {
	GovernanceCompatibilityReadiness = true,
	ExecutionReadinessCompatibility = true,
	AuthorizationSeparationReadiness = true,
	AuthorizationDependencyOrdering = true,
	FutureRuntimeCompatibility = true,
	ProviderIdentityReadiness = true,
	CoordinatorIdentityReadiness = true,
	BootstrapDependencyReadiness = true,
	EngineGovernanceReadiness = true,
	DocumentationConsistencyReadiness = true,
}

Types.AuthorizationReadinessStatus = {
	Declared = true,
	Compatible = true,
	DependencyReady = true,
	IdentityReady = true,
	BoundaryReady = true,
	Deferred = true,
	Warning = true,
	Blocked = true,
}

Types.AuthorizationReadinessBoundaryKind = {
	NoAuthorizationRuntime = true,
	NoAuthorizationTokens = true,
	NoPermissions = true,
	NoSessionApproval = true,
	NoRuntimeApproval = true,
	NoRuntimeRejection = true,
	NoExecutionRouting = true,
	NoDispatchQueues = true,
	NoSchedulers = true,
	FutureAuthorizationSeparate = true,
	FutureExecutionSeparate = true,
}

Types.FutureAuthorizationIdentity = {
	futureAuthorizationRuntimeName = "AssetExecutionAuthorization",
	futureAuthorizationProviderName = "assetExecutionAuthorizationRuntime",
	futureAuthorizationSnapshotKind = "assetExecutionAuthorizationRuntimeSnapshot",
}

Types.FutureExecutionIdentity = {
	futureExecutionRuntimeName = "AssetExecutionRuntime",
	futureExecutionProviderName = "assetExecutionRuntime",
}

Types.AuthorizationReadinessDocumentationReferencePolicy = "SharedAuthorizationReadinessDocument"

Types.AuthorizationReadinessMetadataFields = {
	"copied",
	"order",
	"compatibility",
	"dependency",
}

local function authorizationDeclaration(
	suffix: string,
	kind: string,
	status: string,
	boundaryKind: string,
	evidence: { string },
	tags: { string },
	metadata: { [string]: any }
): { [string]: any }
	return {
		authorizationReadinessId = "asset-execution-governance.authorization-readiness." .. suffix,
		authorizationCompatibilityId = "asset-execution-governance.authorization-compatibility."
			.. suffix,
		authorizationDependencyId = "asset-execution-governance.authorization-dependency."
			.. suffix,
		authorizationIdentityId = "asset-execution-governance.authorization-identity." .. suffix,
		authorizationBoundaryId = "asset-execution-governance.authorization-boundary." .. suffix,
		authorizationBoundaryKind = boundaryKind,
		authorizationReadinessKind = kind,
		authorizationReadinessStatus = status,
		runtimeName = Types.RuntimeIdentity.runtimeName,
		providerName = Types.RuntimeIdentity.providerName,
		snapshotProviderName = Types.RuntimeIdentity.snapshotProviderName,
		coordinatorName = Types.RuntimeIdentity.coordinatorName,
		diagnosticsProviderName = Types.RuntimeIdentity.diagnosticsProviderName,
		bootstrapDependencyName = Types.RuntimeIdentity.bootstrapDependencyName,
		engineGovernanceSnapshotProviderName = Types.RuntimeIdentity.engineGovernanceSnapshotProviderName,
		documentationReference = "ASSET_EXECUTION_GOVERNANCE_RUNTIME.md",
		governanceCompatibilityId = "asset-execution-governance.compatibility." .. suffix,
		executionReadinessEvidenceKind = Types.ExecutionReadinessEvidenceKind,
		futureAuthorizationRuntimeName = Types.FutureAuthorizationIdentity.futureAuthorizationRuntimeName,
		futureAuthorizationProviderName = Types.FutureAuthorizationIdentity.futureAuthorizationProviderName,
		futureAuthorizationSnapshotKind = Types.FutureAuthorizationIdentity.futureAuthorizationSnapshotKind,
		futureExecutionRuntimeName = Types.FutureExecutionIdentity.futureExecutionRuntimeName,
		futureExecutionProviderName = Types.FutureExecutionIdentity.futureExecutionProviderName,
		required = true,
		evidence = evidence,
		tags = tags,
		metadata = metadata,
	}
end

Types.AuthorizationReadinessDeclarations = {
	authorizationDeclaration(
		"governance-compatibility",
		"GovernanceCompatibilityReadiness",
		"Compatible",
		"FutureAuthorizationSeparate",
		{ "governance.compatibility.copied", "governance.metadata.boundary.copied" },
		{ "authorization-readiness", "governance", "copied-metadata" },
		{ copied = true, order = 1, compatibility = "governance", dependency = "asset-governance" }
	),
	authorizationDeclaration(
		"execution-readiness",
		"ExecutionReadinessCompatibility",
		"Compatible",
		"FutureAuthorizationSeparate",
		{ "execution-readiness.compatibility.copied", "execution-readiness.boundary.copied" },
		{ "authorization-readiness", "execution-readiness", "copied-metadata" },
		{
			copied = true,
			order = 2,
			compatibility = "execution-readiness",
			dependency = "readiness",
		}
	),
	authorizationDeclaration(
		"authorization-separation",
		"AuthorizationSeparationReadiness",
		"BoundaryReady",
		"NoAuthorizationRuntime",
		{ "future-authorization.separate.copied", "no-authority.boundary.copied" },
		{ "authorization-readiness", "separation", "metadata-only" },
		{
			copied = true,
			order = 3,
			compatibility = "authorization-separation",
			dependency = "future-layer",
		}
	),
	authorizationDeclaration(
		"dependency-ordering",
		"AuthorizationDependencyOrdering",
		"DependencyReady",
		"FutureAuthorizationSeparate",
		{ "governance.before-authorization.copied", "authorization.before-execution.copied" },
		{ "authorization-readiness", "dependency-order", "copied-metadata" },
		{
			copied = true,
			order = 4,
			compatibility = "dependency-ordering",
			dependency = "layer-order",
		}
	),
	authorizationDeclaration(
		"future-runtime",
		"FutureRuntimeCompatibility",
		"Declared",
		"FutureAuthorizationSeparate",
		{
			"future-authorization-runtime.identity.copied",
			"future-execution-runtime.identity.copied",
		},
		{ "authorization-readiness", "future-runtime", "copied-metadata" },
		{
			copied = true,
			order = 5,
			compatibility = "future-runtime",
			dependency = "future-runtime",
		}
	),
	authorizationDeclaration(
		"provider-identity",
		"ProviderIdentityReadiness",
		"IdentityReady",
		"FutureAuthorizationSeparate",
		{ "assetExecutionGovernanceRuntime.provider.copied" },
		{ "authorization-readiness", "provider", "lower-camel-case" },
		{ copied = true, order = 6, compatibility = "provider-identity", dependency = "provider" }
	),
	authorizationDeclaration(
		"coordinator-identity",
		"CoordinatorIdentityReadiness",
		"IdentityReady",
		"FutureAuthorizationSeparate",
		{ "AssetExecutionGovernanceCoordinator.identity.copied" },
		{ "authorization-readiness", "coordinator", "copied-metadata" },
		{
			copied = true,
			order = 7,
			compatibility = "coordinator-identity",
			dependency = "coordinator",
		}
	),
	authorizationDeclaration(
		"bootstrap-dependency",
		"BootstrapDependencyReadiness",
		"DependencyReady",
		"FutureAuthorizationSeparate",
		{ "bootstrap.after.certification-decision.copied" },
		{ "authorization-readiness", "bootstrap", "ordered" },
		{
			copied = true,
			order = 8,
			compatibility = "bootstrap-dependency",
			dependency = "bootstrap",
		}
	),
	authorizationDeclaration(
		"engine-governance",
		"EngineGovernanceReadiness",
		"Compatible",
		"FutureAuthorizationSeparate",
		{ "engine-governance.provider.copied", "engine-governance.responsibility.copied" },
		{ "authorization-readiness", "engine-governance", "contract" },
		{
			copied = true,
			order = 9,
			compatibility = "engine-governance",
			dependency = "governance-contract",
		}
	),
	authorizationDeclaration(
		"documentation",
		"DocumentationConsistencyReadiness",
		"Compatible",
		"FutureExecutionSeparate",
		{ "documentation.authorization-readiness.copied", "documentation.boundary.copied" },
		{ "authorization-readiness", "documentation", "schema-terminology" },
		{ copied = true, order = 10, compatibility = "documentation", dependency = "documentation" }
	),
}

Types.AuthorizationReadinessDeclarationOrder = {
	"asset-execution-governance.authorization-readiness.governance-compatibility",
	"asset-execution-governance.authorization-readiness.execution-readiness",
	"asset-execution-governance.authorization-readiness.authorization-separation",
	"asset-execution-governance.authorization-readiness.dependency-ordering",
	"asset-execution-governance.authorization-readiness.future-runtime",
	"asset-execution-governance.authorization-readiness.provider-identity",
	"asset-execution-governance.authorization-readiness.coordinator-identity",
	"asset-execution-governance.authorization-readiness.bootstrap-dependency",
	"asset-execution-governance.authorization-readiness.engine-governance",
	"asset-execution-governance.authorization-readiness.documentation",
}

Types.AuthorizationReadinessCompatibilityOrder = {
	"asset-execution-governance.authorization-compatibility.governance-compatibility",
	"asset-execution-governance.authorization-compatibility.execution-readiness",
	"asset-execution-governance.authorization-compatibility.authorization-separation",
	"asset-execution-governance.authorization-compatibility.dependency-ordering",
	"asset-execution-governance.authorization-compatibility.future-runtime",
	"asset-execution-governance.authorization-compatibility.provider-identity",
	"asset-execution-governance.authorization-compatibility.coordinator-identity",
	"asset-execution-governance.authorization-compatibility.bootstrap-dependency",
	"asset-execution-governance.authorization-compatibility.engine-governance",
	"asset-execution-governance.authorization-compatibility.documentation",
}

Types.AuthorizationReadinessDependencyOrder = {
	"asset-execution-governance.authorization-dependency.governance-compatibility",
	"asset-execution-governance.authorization-dependency.execution-readiness",
	"asset-execution-governance.authorization-dependency.authorization-separation",
	"asset-execution-governance.authorization-dependency.dependency-ordering",
	"asset-execution-governance.authorization-dependency.future-runtime",
	"asset-execution-governance.authorization-dependency.provider-identity",
	"asset-execution-governance.authorization-dependency.coordinator-identity",
	"asset-execution-governance.authorization-dependency.bootstrap-dependency",
	"asset-execution-governance.authorization-dependency.engine-governance",
	"asset-execution-governance.authorization-dependency.documentation",
}

Types.AuthorizationReadinessIdentityOrder = {
	"asset-execution-governance.authorization-identity.governance-compatibility",
	"asset-execution-governance.authorization-identity.execution-readiness",
	"asset-execution-governance.authorization-identity.authorization-separation",
	"asset-execution-governance.authorization-identity.dependency-ordering",
	"asset-execution-governance.authorization-identity.future-runtime",
	"asset-execution-governance.authorization-identity.provider-identity",
	"asset-execution-governance.authorization-identity.coordinator-identity",
	"asset-execution-governance.authorization-identity.bootstrap-dependency",
	"asset-execution-governance.authorization-identity.engine-governance",
	"asset-execution-governance.authorization-identity.documentation",
}

Types.AuthorizationReadinessBoundaryOrder = {
	"asset-execution-governance.authorization-boundary.governance-compatibility",
	"asset-execution-governance.authorization-boundary.execution-readiness",
	"asset-execution-governance.authorization-boundary.authorization-separation",
	"asset-execution-governance.authorization-boundary.dependency-ordering",
	"asset-execution-governance.authorization-boundary.future-runtime",
	"asset-execution-governance.authorization-boundary.provider-identity",
	"asset-execution-governance.authorization-boundary.coordinator-identity",
	"asset-execution-governance.authorization-boundary.bootstrap-dependency",
	"asset-execution-governance.authorization-boundary.engine-governance",
	"asset-execution-governance.authorization-boundary.documentation",
}

Types.AuthorizationReadinessKindOrder = {
	"GovernanceCompatibilityReadiness",
	"ExecutionReadinessCompatibility",
	"AuthorizationSeparationReadiness",
	"AuthorizationDependencyOrdering",
	"FutureRuntimeCompatibility",
	"ProviderIdentityReadiness",
	"CoordinatorIdentityReadiness",
	"BootstrapDependencyReadiness",
	"EngineGovernanceReadiness",
	"DocumentationConsistencyReadiness",
}

Types.AuthorizationReadinessStatusOrder = {
	"Compatible",
	"Compatible",
	"BoundaryReady",
	"DependencyReady",
	"Declared",
	"IdentityReady",
	"IdentityReady",
	"DependencyReady",
	"Compatible",
	"Compatible",
}

Types.AuthorizationReadinessBoundaryKindOrder = {
	"FutureAuthorizationSeparate",
	"FutureAuthorizationSeparate",
	"NoAuthorizationRuntime",
	"FutureAuthorizationSeparate",
	"FutureAuthorizationSeparate",
	"FutureAuthorizationSeparate",
	"FutureAuthorizationSeparate",
	"FutureAuthorizationSeparate",
	"FutureAuthorizationSeparate",
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
	"authorizationReadinessPosture",
	"authorizationCompatibilityPosture",
	"authorizationDependencyPosture",
	"authorizationIdentityPosture",
	"futureAuthorizationRuntimePosture",
	"futureExecutionRuntimePosture",
	"governanceCompatibilityPosture",
	"executionCompatibilityPosture",
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
	MaxAuthorizationReadinessDeclarations = 10,
	MaxChildReferences = 260,
	MaxSummaryLength = 180,
}

return Types
