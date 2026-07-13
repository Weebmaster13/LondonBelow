--!strict

local Types = {}

Types.Mode = "ServerAuthoritativeAssetExecutionAdapterRegistrationWorkflowMetadataRuntime"
Types.RuntimeProviderName = "assetExecutionAdapterRegistrationWorkflow"
Types.SnapshotKind = "assetExecutionAdapterRegistrationWorkflowSnapshot"
Types.RuntimeName = "AssetExecutionAdapterRegistrationWorkflow"
Types.CoordinatorName = "AssetExecutionAdapterRegistrationWorkflowCoordinator"

Types.CoordinatorApiOrder = {
	"initialize",
	"start",
	"shutdown",
	"registerExecutionAdapterRegistrationWorkflow",
	"registerExecutionAdapterRegistrationStage",
	"registerExecutionAdapterRegistrationTransition",
	"registerExecutionAdapterRegistrationDecision",
	"registerExecutionAdapterRegistrationAudit",
	"registerExecutionAdapterRegistrationWorkflowSnapshot",
	"inspect",
	"getSnapshot",
	"validate",
	"runSelfChecks",
}

Types.SignalNames = {
	Initialized = "AssetExecutionAdapterRegistrationWorkflow.Initialized",
	Started = "AssetExecutionAdapterRegistrationWorkflow.Started",
	Shutdown = "AssetExecutionAdapterRegistrationWorkflow.Shutdown",
	ValidationFailed = "AssetExecutionAdapterRegistrationWorkflow.ValidationFailed",
}

Types.SchemaType = {
	ExecutionAdapterRegistrationWorkflow = "ExecutionAdapterRegistrationWorkflow",
	ExecutionAdapterRegistrationStage = "ExecutionAdapterRegistrationStage",
	ExecutionAdapterRegistrationTransition = "ExecutionAdapterRegistrationTransition",
	ExecutionAdapterRegistrationDecision = "ExecutionAdapterRegistrationDecision",
	ExecutionAdapterRegistrationAudit = "ExecutionAdapterRegistrationAudit",
	ExecutionAdapterRegistrationWorkflowSnapshot = "ExecutionAdapterRegistrationWorkflowSnapshot",
}

Types.SchemaFields = {
	ExecutionAdapterRegistrationWorkflow = {
		"workflowId",
		"registryId",
		"workflowName",
		"providerName",
		"snapshotProviderName",
		"workflowKind",
		"workflowStatus",
		"stageIds",
		"transitionIds",
		"decisionIds",
		"auditIds",
		"snapshotIds",
		"evidence",
		"tags",
		"metadata",
	},
	ExecutionAdapterRegistrationStage = {
		"stageId",
		"workflowId",
		"stageName",
		"stageKind",
		"stageStatus",
		"stageOrder",
		"owner",
		"evidence",
		"tags",
		"metadata",
	},
	ExecutionAdapterRegistrationTransition = {
		"transitionId",
		"workflowId",
		"fromStageId",
		"toStageId",
		"transitionKind",
		"transitionStatus",
		"decisionIds",
		"evidence",
		"tags",
		"metadata",
	},
	ExecutionAdapterRegistrationDecision = {
		"decisionId",
		"workflowId",
		"transitionId",
		"decisionKind",
		"decisionStatus",
		"reviewer",
		"evidence",
		"tags",
		"metadata",
	},
	ExecutionAdapterRegistrationAudit = {
		"auditId",
		"workflowId",
		"stageIds",
		"transitionIds",
		"decisionIds",
		"auditKind",
		"auditStatus",
		"reviewer",
		"evidence",
		"tags",
		"metadata",
	},
	ExecutionAdapterRegistrationWorkflowSnapshot = {
		"workflowSnapshotId",
		"workflowId",
		"snapshotKind",
		"snapshotStatus",
		"providerName",
		"stageIds",
		"transitionIds",
		"decisionIds",
		"evidence",
		"tags",
		"metadata",
	},
}

Types.SchemaFieldCount = {}
for schemaName, fields in pairs(Types.SchemaFields) do
	Types.SchemaFieldCount[schemaName] = #fields
end

Types.WorkflowKind = {
	AdapterRegistrationWorkflow = true,
	CertificationWorkflow = true,
	BoundaryWorkflow = true,
	CompatibilityWorkflow = true,
}

Types.WorkflowStatus = {
	Declared = true,
	Draft = true,
	Certified = true,
	Deferred = true,
	Warning = true,
	Blocked = true,
}

Types.StageKind = {
	Intake = true,
	Validation = true,
	BoundaryReview = true,
	CompatibilityReview = true,
	Certification = true,
	Audit = true,
}

Types.StageStatus = {
	Declared = true,
	Ready = true,
	Certified = true,
	Deferred = true,
	Warning = true,
	Blocked = true,
}

Types.TransitionKind = {
	StageProgression = true,
	ValidationGate = true,
	BoundaryGate = true,
	CompatibilityGate = true,
	CertificationGate = true,
}

Types.TransitionStatus = {
	Declared = true,
	Ready = true,
	Certified = true,
	Deferred = true,
	Warning = true,
	Blocked = true,
}

Types.DecisionKind = {
	ValidationDecision = true,
	BoundaryDecision = true,
	CompatibilityDecision = true,
	CertificationDecision = true,
	AuditDecision = true,
}

Types.DecisionStatus = {
	Declared = true,
	Satisfied = true,
	Certified = true,
	Deferred = true,
	Warning = true,
	Blocked = true,
}

Types.AuditKind = {
	WorkflowAudit = true,
	StageAudit = true,
	TransitionAudit = true,
	DecisionAudit = true,
	ProductionAudit = true,
}

Types.AuditStatus = {
	Passed = true,
	Failed = true,
	Warning = true,
	Deferred = true,
	Blocked = true,
}

Types.WorkflowSnapshotStatus = {
	Declared = true,
	Captured = true,
	Certified = true,
	Deferred = true,
	Warning = true,
	Blocked = true,
}

Types.PostureKeys = {
	"assetExecutionAdapterRegistrationWorkflowRuntimePosture",
	"assetExecutionAdapterRegistrationWorkflowWorkflowPosture",
	"assetExecutionAdapterRegistrationWorkflowRegistrationPosture",
	"assetExecutionAdapterRegistrationWorkflowTransitionPosture",
	"assetExecutionAdapterRegistrationWorkflowDecisionPosture",
	"assetExecutionAdapterRegistrationWorkflowAuditPosture",
	"assetExecutionAdapterRegistrationWorkflowSnapshotPosture",
	"assetExecutionAdapterRegistrationWorkflowValidationPosture",
	"assetExecutionAdapterRegistrationWorkflowDocumentationPosture",
	"assetExecutionAdapterRegistrationWorkflowBootstrapPosture",
	"assetExecutionAdapterRegistrationWorkflowGovernancePosture",
	"assetExecutionAdapterRegistrationWorkflowCertificationPosture",
	"assetExecutionAdapterRegistrationWorkflowHardeningPosture",
	"assetExecutionAdapterRegistrationWorkflowIdentityPosture",
	"assetExecutionAdapterRegistrationWorkflowOrderingPosture",
	"assetExecutionAdapterRegistrationWorkflowMetadataPosture",
	"assetExecutionAdapterRegistrationWorkflowEvidencePosture",
	"assetExecutionAdapterRegistrationWorkflowTagPosture",
	"assetExecutionAdapterRegistrationWorkflowRuntimeLimitPosture",
	"assetExecutionAdapterRegistrationWorkflowNoImplementationPosture",
	"assetExecutionAdapterRegistrationWorkflowNoActivationPosture",
	"assetExecutionAdapterRegistrationWorkflowNoExecutionPosture",
	"assetExecutionAdapterRegistrationWorkflowNoAuthorizationPosture",
	"assetExecutionAdapterRegistrationWorkflowNoWorkflowExecutionPosture",
	"assetExecutionAdapterRegistrationWorkflowNoOperationPosture",
	"assetExecutionAdapterRegistrationWorkflowNoAuthorityPosture",
	"noExecution",
	"noAssetLoading",
	"noGameplay",
	"noPresentation",
	"noSave",
	"noNetworking",
	"noAnalytics",
	"noTelemetry",
}

Types.DocumentationFiles = {
	"ASSET_EXECUTION_ADAPTER_REGISTRATION_WORKFLOW_RUNTIME.md",
	"ASSET_EXECUTION_ADAPTER_REGISTRATION_WORKFLOW_VALIDATION.md",
	"ASSET_EXECUTION_ADAPTER_REGISTRATION_WORKFLOW_SERIALIZATION.md",
	"ASSET_EXECUTION_ADAPTER_REGISTRATION_WORKFLOW_DIAGNOSTICS.md",
	"ASSET_EXECUTION_ADAPTER_REGISTRATION_WORKFLOW_SNAPSHOTS.md",
	"ASSET_EXECUTION_ADAPTER_REGISTRATION_WORKFLOW_SELF_CHECKS.md",
	"ASSET_EXECUTION_ADAPTER_REGISTRATION_WORKFLOW_AUDIT.md",
	"ASSET_EXECUTION_ADAPTER_REGISTRATION_WORKFLOW_PRODUCTION_REVIEW.md",
}

Types.BootstrapDependencyOrder = {
	"AssetExecutionAdapterRegistryCoordinator",
}

Types.GovernanceSnapshotProviders = {
	"assetExecutionAdapterRegistrationWorkflow",
}

Types.Limits = {
	MaxWorkflows = 32,
	MaxStages = 180,
	MaxTransitions = 220,
	MaxDecisions = 220,
	MaxAudits = 220,
	MaxWorkflowSnapshots = 120,
	MaxValidationFailures = 220,
	MaxSnapshotHistory = 60,
	MaxPayloadDepth = 8,
	MaxPayloadNodes = 520,
	MaxStringLength = 280,
	MaxTags = 32,
	MaxEvidence = 56,
	MaxChildReferences = 220,
	MaxStageOrder = 1000,
}

return Types
