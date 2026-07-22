--!strict
--[[
	Server bootstrap for London Engine v1.

	Bootstrap starts the Core Runtime, validates it, prints a startup summary,
	and refuses to report readiness if any required runtime system fails.
]]

local Framework = require(script.Parent.Framework)
local RuntimeEventBusCoordinator = require(script.Parent.Events.EventBusCoordinator)
local DirectorCoordinator = require(script.Parent.Directors.DirectorCoordinator)
local SimulationService = require(script.Parent.Simulation.SimulationService)
local AccessibilityCoordinator =
	require(script.Parent.Parent.Accessibility.Core.AccessibilityCoordinator)
local AnalyticsCoordinator = require(script.Parent.Parent.Analytics.Core.AnalyticsCoordinator)
local AssetManifestCoordinator =
	require(script.Parent.Parent.AssetManifest.Core.AssetManifestCoordinator)
local AssetUsagePlanCoordinator =
	require(script.Parent.Parent.AssetUsagePlan.Core.AssetUsagePlanCoordinator)
local AssetReadinessReviewCoordinator =
	require(script.Parent.Parent.AssetReadinessReview.Core.AssetReadinessReviewCoordinator)
local AssetApprovalLedgerCoordinator =
	require(script.Parent.Parent.AssetApprovalLedger.Core.AssetApprovalLedgerCoordinator)
local AssetExecutionPermitCoordinator =
	require(script.Parent.Parent.AssetExecutionPermit.Core.AssetExecutionPermitCoordinator)
local AssetRuntimeGateCoordinator =
	require(script.Parent.Parent.AssetRuntimeGate.Core.AssetRuntimeGateCoordinator)
local AssetExecutionBoundaryReviewCoordinator = require(
	script.Parent.Parent.AssetExecutionBoundaryReview.Core.AssetExecutionBoundaryReviewCoordinator
)
local AssetExecutionDesignContractCoordinator = require(
	script.Parent.Parent.AssetExecutionDesignContract.Core.AssetExecutionDesignContractCoordinator
)
local AssetExecutionImplementationReadinessCoordinator = require(
	script.Parent.Parent.AssetExecutionImplementationReadiness.Core.AssetExecutionImplementationReadinessCoordinator
)
local AssetExecutionImplementationContractCoordinator = require(
	script.Parent.Parent.AssetExecutionImplementationContract.Core.AssetExecutionImplementationContractCoordinator
)
local AssetGovernanceIntegrationCoordinator = require(
	script.Parent.Parent.AssetGovernanceIntegration.Core.AssetGovernanceIntegrationCoordinator
)
local AssetGovernanceCertificationCoordinator = require(
	script.Parent.Parent.AssetGovernanceCertification.Core.AssetGovernanceCertificationCoordinator
)
local AssetGovernanceCertificationIntegrationCoordinator = require(
	script.Parent.Parent.AssetGovernanceCertificationIntegration.Core.AssetGovernanceCertificationIntegrationCoordinator
)
local AssetGovernanceCertificationInspectionCoordinator = require(
	script.Parent.Parent.AssetGovernanceCertificationInspection.Core.AssetGovernanceCertificationInspectionCoordinator
)
local AssetGovernanceCertificationDecisionCoordinator = require(
	script.Parent.Parent.AssetGovernanceCertificationDecision.Core.AssetGovernanceCertificationDecisionCoordinator
)
local AssetExecutionGovernanceCoordinator =
	require(script.Parent.Parent.AssetExecutionGovernance.Core.AssetExecutionGovernanceCoordinator)
local AssetExecutionAuthorizationCoordinator = require(
	script.Parent.Parent.AssetExecutionAuthorization.Core.AssetExecutionAuthorizationCoordinator
)
local AssetExecutionCoordinator =
	require(script.Parent.Parent.AssetExecutionRuntime.Core.AssetExecutionCoordinator)
local AssetExecutionAdapterCoordinator =
	require(script.Parent.Parent.AssetExecutionAdapterRuntime.Core.AssetExecutionAdapterCoordinator)
local AssetExecutionAdapterRegistryCoordinator = require(
	script.Parent.Parent.AssetExecutionAdapterRegistry.Core.AssetExecutionAdapterRegistryCoordinator
)
local AssetExecutionAdapterRegistrationWorkflowCoordinator = require(
	script.Parent.Parent.AssetExecutionAdapterRegistrationWorkflow.Core.AssetExecutionAdapterRegistrationWorkflowCoordinator
)
local AudioDirector = require(script.Parent.Parent.Horror.Audio.AudioDirector)
local Chapter0HomeCoordinator =
	require(script.Parent.Parent.Chapter0Home.Core.Chapter0HomeCoordinator)
local Chapter0EnvironmentalCoordinator =
	require(script.Parent.Parent.Chapter0Home.Environment.Chapter0EnvironmentalCoordinator)
local ConditionCoordinator = require(script.Parent.Parent.Condition.Core.ConditionCoordinator)
local ContentRegistryCoordinator =
	require(script.Parent.Parent.ContentRegistry.Core.ContentRegistryCoordinator)
local DeveloperToolsCoordinator =
	require(script.Parent.Parent.DeveloperTools.Core.DeveloperToolsCoordinator)
local DarknessService = require(script.Parent.Parent.Gameplay.Darkness.DarknessService)
local EnvironmentDirector = require(script.Parent.Parent.Horror.Environment.EnvironmentDirector)
local GameplayCoordinator = require(script.Parent.Parent.Gameplay.Core.GameplayCoordinator)
local GameplayExecutionCoordinator =
	require(script.Parent.Parent.GameplayExecution.Core.GameplayExecutionCoordinator)
local GameplayExecutionService =
	require(script.Parent.Parent.Gameplay.Execution.GameplayExecutionService)
local GameplayFlowCoordinator = require(script.Parent.Parent.Gameplay.Flow.GameplayFlowCoordinator)
local HorrorDirector = require(script.Parent.Parent.Horror.Director.HorrorDirector)
local HorrorOrchestrator =
	require(script.Parent.Parent.Horror.Orchestration.Core.HorrorOrchestrator)
local InteractionCoordinator = require(script.Parent.Parent.Interaction.Core.InteractionCoordinator)
local EnvironmentalInteractionCoordinator =
	require(script.Parent.Parent.Interaction.Environmental.EnvironmentalInteractionCoordinator)
local InventoryCoordinator = require(script.Parent.Parent.Inventory.Core.InventoryCoordinator)
local LanternService = require(script.Parent.Parent.Gameplay.Lantern.LanternService)
local LightingDirector = require(script.Parent.Parent.Horror.Lighting.LightingDirector)
local LivingCognitionCoordinator =
	require(script.Parent.Parent.AI.LivingCognition.Core.LivingCognitionCoordinator)
local LocalizationCoordinator =
	require(script.Parent.Parent.Localization.Core.LocalizationCoordinator)
local MonsterIntelligenceCoordinator =
	require(script.Parent.Parent.AI.MonsterIntelligence.Core.MonsterIntelligenceCoordinator)
local MonsterAIService = require(script.Parent.Parent.AI.MonsterAI.Core.MonsterAIService)
local NarrativeCoordinator = require(script.Parent.Parent.Narrative.Core.NarrativeCoordinator)
local ObjectiveCoordinator = require(script.Parent.Parent.Objective.Core.ObjectiveCoordinator)
local ObservationService = require(script.Parent.Parent.Horror.Observation.ObservationService)
local PlayerService = require(script.Parent.Parent.Player.PlayerService)
local PlayerExperienceService = require(script.Parent.Parent.Gameplay.PlayerExperienceService)
local PhysicalRuntimeCoordinator =
	require(script.Parent.Parent.PhysicalRuntime.Core.PhysicalRuntimeCoordinator)
local PersistenceCoordinator = require(script.Parent.Parent.Persistence.Core.PersistenceCoordinator)
local PerformanceCoordinator = require(script.Parent.Parent.Performance.Core.PerformanceCoordinator)
local PresentationCoordinator =
	require(script.Parent.Parent.Presentation.Core.PresentationCoordinator)
local PuzzleCoordinator = require(script.Parent.Parent.Puzzle.Core.PuzzleCoordinator)
local EventGraphCoordinator = require(script.Parent.Parent.EventGraph.Core.EventGraphCoordinator)
local ExecutionPlanningCoordinator =
	require(script.Parent.Parent.ExecutionPlanningRuntime.Core.Coordinator)
local ExecutionAuthorizationCoordinator =
	require(script.Parent.Parent.ExecutionAuthorizationRuntime.Core.Coordinator)
local RuleEngineCoordinator = require(script.Parent.Parent.RuleEngine.Core.RuleEngineCoordinator)
local RuntimeGraphCoordinator =
	require(script.Parent.Parent.RuntimeGraph.Core.RuntimeGraphCoordinator)
local RuntimeLifecycleCoordinator =
	require(script.Parent.Parent.RuntimeLifecycle.Core.RuntimeLifecycleCoordinator)
local RuntimeSchedulerCoordinator =
	require(script.Parent.Parent.RuntimeScheduler.Core.RuntimeSchedulerCoordinator)
local LobbyService = require(script.Parent.Parent.Lobby.LobbyService)
local PortalService = require(script.Parent.Parent.Lobby.Portals.PortalService)
local PortalZoneBinder = require(script.Parent.Parent.Lobby.Portals.PortalZoneBinder)
local SaveCoordinator = require(script.Parent.Parent.Saving.Core.SaveCoordinator)
local SaveSessionCoordinator = require(script.Parent.Parent.Saving.Session.SaveSessionCoordinator)
local SecurityCoordinator = require(script.Parent.Parent.Security.Core.SecurityCoordinator)
local SessionCoordinator = require(script.Parent.Parent.Session.Core.SessionCoordinator)
local StateMachineCoordinator =
	require(script.Parent.Parent.StateMachine.Core.StateMachineCoordinator)
local TriggerCoordinator = require(script.Parent.Parent.Trigger.Core.TriggerCoordinator)
local WorldCoordinator = require(script.Parent.Parent.World.Core.WorldCoordinator)
local Logger = require(script.Parent.Logger)

local log = Logger.scope("Bootstrap")

local function startEngine()
	log.info("Starting London Engine")

	Framework.registerModule("RuntimeEventBusCoordinator", RuntimeEventBusCoordinator, {
		"Logger",
		"EventBus",
		"Diagnostics",
		"SnapshotManager",
	})

	Framework.registerModule("LobbyService", LobbyService, {
		"Logger",
		"EventBus",
		"RemoteManager",
		"Scheduler",
		"Diagnostics",
		"SnapshotManager",
	})

	Framework.registerModule("PortalService", PortalService, {
		"Logger",
		"EventBus",
		"RemoteManager",
		"Scheduler",
		"Diagnostics",
		"SnapshotManager",
		"LobbyService",
	})

	Framework.registerModule("PortalZoneBinder", PortalZoneBinder, {
		"Logger",
		"PortalService",
	})

	Framework.registerModule("ObservationService", ObservationService, {
		"Logger",
		"EventBus",
		"Scheduler",
		"Diagnostics",
		"SnapshotManager",
	})

	Framework.registerModule("HorrorDirector", HorrorDirector, {
		"Logger",
		"EventBus",
		"Scheduler",
		"Diagnostics",
		"SnapshotManager",
		"ObservationService",
	})

	Framework.registerModule("DirectorCoordinator", DirectorCoordinator, {
		"Logger",
		"EventBus",
		"Scheduler",
		"Diagnostics",
		"SnapshotManager",
		"ObservationService",
	})

	Framework.registerModule("EnvironmentDirector", EnvironmentDirector, {
		"Logger",
		"EventBus",
		"Scheduler",
		"Diagnostics",
		"SnapshotManager",
		"ObservationService",
		"DirectorCoordinator",
	})

	Framework.registerModule("LightingDirector", LightingDirector, {
		"Logger",
		"EventBus",
		"Scheduler",
		"Diagnostics",
		"SnapshotManager",
		"DirectorCoordinator",
		"EnvironmentDirector",
	})

	Framework.registerModule("AudioDirector", AudioDirector, {
		"Logger",
		"EventBus",
		"Scheduler",
		"Diagnostics",
		"SnapshotManager",
		"DirectorCoordinator",
		"EnvironmentDirector",
	})

	Framework.registerModule("PlayerService", PlayerService, {
		"Logger",
		"EventBus",
		"Diagnostics",
		"SnapshotManager",
	})

	Framework.registerModule("PlayerExperienceService", PlayerExperienceService, {
		"Logger",
		"EventBus",
		"RemoteManager",
		"Diagnostics",
		"SnapshotManager",
		"ObservationService",
		"PlayerService",
	})

	Framework.registerModule("LanternService", LanternService, {
		"Logger",
		"EventBus",
		"RemoteManager",
		"Diagnostics",
		"SnapshotManager",
		"ObservationService",
		"DirectorCoordinator",
		"LightingDirector",
		"AudioDirector",
	})

	Framework.registerModule("DarknessService", DarknessService, {
		"Logger",
		"EventBus",
		"Scheduler",
		"Diagnostics",
		"SnapshotManager",
		"ObservationService",
		"DirectorCoordinator",
		"LightingDirector",
		"AudioDirector",
		"EnvironmentDirector",
	})

	Framework.registerModule("GameplayCoordinator", GameplayCoordinator, {
		"Logger",
		"EventBus",
		"Diagnostics",
		"SnapshotManager",
		"ObservationService",
		"DirectorCoordinator",
	})

	Framework.registerModule("GameplayExecutionService", GameplayExecutionService, {
		"Logger",
		"EventBus",
		"Scheduler",
		"Diagnostics",
		"SnapshotManager",
		"GameplayCoordinator",
	})

	Framework.registerModule("GameplayExecutionCoordinator", GameplayExecutionCoordinator, {
		"Logger",
		"EventBus",
		"Diagnostics",
		"SnapshotManager",
		"ObservationService",
		"LivingCognitionCoordinator",
		"MonsterIntelligenceCoordinator",
		"NarrativeCoordinator",
		"SaveCoordinator",
		"HorrorOrchestrator",
		"DirectorCoordinator",
		"GameplayExecutionService",
	})

	Framework.registerModule("PhysicalRuntimeCoordinator", PhysicalRuntimeCoordinator, {
		"Logger",
		"EventBus",
		"Diagnostics",
		"SnapshotManager",
		"GameplayExecutionCoordinator",
	})

	Framework.registerModule("PresentationCoordinator", PresentationCoordinator, {
		"Logger",
		"EventBus",
		"Diagnostics",
		"SnapshotManager",
		"DirectorCoordinator",
		"GameplayExecutionCoordinator",
		"PhysicalRuntimeCoordinator",
	})

	Framework.registerModule("InteractionCoordinator", InteractionCoordinator, {
		"Logger",
		"EventBus",
		"Diagnostics",
		"SnapshotManager",
		"PhysicalRuntimeCoordinator",
		"GameplayExecutionCoordinator",
		"PresentationCoordinator",
	})

	Framework.registerModule(
		"EnvironmentalInteractionCoordinator",
		EnvironmentalInteractionCoordinator,
		{
			"Logger",
			"Diagnostics",
			"SnapshotManager",
			"InteractionCoordinator",
			"ObservationService",
		}
	)

	Framework.registerModule("Chapter0EnvironmentalCoordinator", Chapter0EnvironmentalCoordinator, {
		"Logger",
		"Diagnostics",
		"SnapshotManager",
		"InteractionCoordinator",
		"EnvironmentalInteractionCoordinator",
		"ObservationService",
	})

	Framework.registerModule("PuzzleCoordinator", PuzzleCoordinator, {
		"Logger",
		"EventBus",
		"Diagnostics",
		"SnapshotManager",
		"PhysicalRuntimeCoordinator",
		"InteractionCoordinator",
		"GameplayExecutionCoordinator",
		"NarrativeCoordinator",
	})

	Framework.registerModule("InventoryCoordinator", InventoryCoordinator, {
		"Logger",
		"EventBus",
		"Diagnostics",
		"SnapshotManager",
		"PhysicalRuntimeCoordinator",
		"InteractionCoordinator",
		"PuzzleCoordinator",
		"GameplayExecutionCoordinator",
	})

	Framework.registerModule("WorldCoordinator", WorldCoordinator, {
		"Logger",
		"EventBus",
		"Diagnostics",
		"SnapshotManager",
		"PhysicalRuntimeCoordinator",
		"InteractionCoordinator",
		"PuzzleCoordinator",
		"InventoryCoordinator",
		"GameplayExecutionCoordinator",
	})

	Framework.registerModule("ObjectiveCoordinator", ObjectiveCoordinator, {
		"Logger",
		"EventBus",
		"Diagnostics",
		"SnapshotManager",
		"WorldCoordinator",
		"PuzzleCoordinator",
		"InteractionCoordinator",
		"InventoryCoordinator",
		"NarrativeCoordinator",
		"SaveCoordinator",
		"GameplayExecutionCoordinator",
	})

	Framework.registerModule("GameplayFlowCoordinator", GameplayFlowCoordinator, {
		"Logger",
		"EventBus",
		"Diagnostics",
		"SnapshotManager",
		"ObservationService",
		"InteractionCoordinator",
		"EnvironmentalInteractionCoordinator",
		"Chapter0EnvironmentalCoordinator",
		"PresentationCoordinator",
		"GameplayCoordinator",
		"ObjectiveCoordinator",
	})

	Framework.registerModule("SessionCoordinator", SessionCoordinator, {
		"Logger",
		"EventBus",
		"Diagnostics",
		"SnapshotManager",
		"WorldCoordinator",
		"ObjectiveCoordinator",
		"InventoryCoordinator",
		"SaveCoordinator",
	})

	Framework.registerModule("DeveloperToolsCoordinator", DeveloperToolsCoordinator, {
		"Logger",
		"EventBus",
		"Diagnostics",
		"SnapshotManager",
	})

	Framework.registerModule("AnalyticsCoordinator", AnalyticsCoordinator, {
		"Logger",
		"EventBus",
		"Diagnostics",
		"SnapshotManager",
	})

	Framework.registerModule("AccessibilityCoordinator", AccessibilityCoordinator, {
		"Logger",
		"EventBus",
		"Diagnostics",
		"SnapshotManager",
	})

	Framework.registerModule("PerformanceCoordinator", PerformanceCoordinator, {
		"Logger",
		"EventBus",
		"Diagnostics",
		"SnapshotManager",
	})

	Framework.registerModule("SecurityCoordinator", SecurityCoordinator, {
		"Logger",
		"EventBus",
		"Diagnostics",
		"SnapshotManager",
	})

	Framework.registerModule("LocalizationCoordinator", LocalizationCoordinator, {
		"Logger",
		"EventBus",
		"Diagnostics",
		"SnapshotManager",
	})

	Framework.registerModule("ContentRegistryCoordinator", ContentRegistryCoordinator, {
		"Logger",
		"EventBus",
		"Diagnostics",
		"SnapshotManager",
	})

	Framework.registerModule("RuntimeGraphCoordinator", RuntimeGraphCoordinator, {
		"Logger",
		"EventBus",
		"Diagnostics",
		"SnapshotManager",
	})

	Framework.registerModule("RuntimeLifecycleCoordinator", RuntimeLifecycleCoordinator, {
		"Logger",
		"EventBus",
		"Diagnostics",
		"SnapshotManager",
	})

	Framework.registerModule("RuntimeSchedulerCoordinator", RuntimeSchedulerCoordinator, {
		"Logger",
		"EventBus",
		"Diagnostics",
		"SnapshotManager",
	})

	Framework.registerModule("ExecutionPlanningCoordinator", ExecutionPlanningCoordinator, {
		"Logger",
		"Diagnostics",
		"SnapshotManager",
	})

	Framework.registerModule(
		"ExecutionAuthorizationCoordinator",
		ExecutionAuthorizationCoordinator,
		{
			"Logger",
			"Diagnostics",
			"SnapshotManager",
			"ExecutionPlanningCoordinator",
		}
	)

	Framework.registerModule("EventGraphCoordinator", EventGraphCoordinator, {
		"Logger",
		"Diagnostics",
		"SnapshotManager",
	})

	Framework.registerModule("RuleEngineCoordinator", RuleEngineCoordinator, {
		"Logger",
		"Diagnostics",
		"SnapshotManager",
	})

	Framework.registerModule("ConditionCoordinator", ConditionCoordinator, {
		"Logger",
		"Diagnostics",
		"SnapshotManager",
	})

	Framework.registerModule("TriggerCoordinator", TriggerCoordinator, {
		"Logger",
		"Diagnostics",
		"SnapshotManager",
	})

	Framework.registerModule("StateMachineCoordinator", StateMachineCoordinator, {
		"Logger",
		"Diagnostics",
		"SnapshotManager",
	})

	Framework.registerModule("AssetManifestCoordinator", AssetManifestCoordinator, {
		"Logger",
		"Diagnostics",
		"SnapshotManager",
	})

	Framework.registerModule("AssetUsagePlanCoordinator", AssetUsagePlanCoordinator, {
		"Logger",
		"Diagnostics",
		"SnapshotManager",
		"AssetManifestCoordinator",
	})

	Framework.registerModule("AssetReadinessReviewCoordinator", AssetReadinessReviewCoordinator, {
		"Logger",
		"Diagnostics",
		"SnapshotManager",
		"AssetManifestCoordinator",
		"AssetUsagePlanCoordinator",
	})

	Framework.registerModule("AssetApprovalLedgerCoordinator", AssetApprovalLedgerCoordinator, {
		"Logger",
		"Diagnostics",
		"SnapshotManager",
		"AssetManifestCoordinator",
		"AssetUsagePlanCoordinator",
		"AssetReadinessReviewCoordinator",
	})

	Framework.registerModule("AssetExecutionPermitCoordinator", AssetExecutionPermitCoordinator, {
		"Logger",
		"Diagnostics",
		"SnapshotManager",
		"AssetManifestCoordinator",
		"AssetUsagePlanCoordinator",
		"AssetReadinessReviewCoordinator",
		"AssetApprovalLedgerCoordinator",
	})

	Framework.registerModule("AssetRuntimeGateCoordinator", AssetRuntimeGateCoordinator, {
		"Logger",
		"Diagnostics",
		"SnapshotManager",
		"AssetManifestCoordinator",
		"AssetUsagePlanCoordinator",
		"AssetReadinessReviewCoordinator",
		"AssetApprovalLedgerCoordinator",
		"AssetExecutionPermitCoordinator",
	})

	Framework.registerModule(
		"AssetExecutionBoundaryReviewCoordinator",
		AssetExecutionBoundaryReviewCoordinator,
		{
			"Logger",
			"Diagnostics",
			"SnapshotManager",
			"AssetManifestCoordinator",
			"AssetUsagePlanCoordinator",
			"AssetReadinessReviewCoordinator",
			"AssetApprovalLedgerCoordinator",
			"AssetExecutionPermitCoordinator",
			"AssetRuntimeGateCoordinator",
		}
	)

	Framework.registerModule(
		"AssetExecutionDesignContractCoordinator",
		AssetExecutionDesignContractCoordinator,
		{
			"Logger",
			"Diagnostics",
			"SnapshotManager",
			"AssetManifestCoordinator",
			"AssetUsagePlanCoordinator",
			"AssetReadinessReviewCoordinator",
			"AssetApprovalLedgerCoordinator",
			"AssetExecutionPermitCoordinator",
			"AssetRuntimeGateCoordinator",
			"AssetExecutionBoundaryReviewCoordinator",
		}
	)

	Framework.registerModule(
		"AssetExecutionImplementationReadinessCoordinator",
		AssetExecutionImplementationReadinessCoordinator,
		{
			"Logger",
			"Diagnostics",
			"SnapshotManager",
			"AssetManifestCoordinator",
			"AssetUsagePlanCoordinator",
			"AssetReadinessReviewCoordinator",
			"AssetApprovalLedgerCoordinator",
			"AssetExecutionPermitCoordinator",
			"AssetRuntimeGateCoordinator",
			"AssetExecutionBoundaryReviewCoordinator",
			"AssetExecutionDesignContractCoordinator",
		}
	)

	Framework.registerModule(
		"AssetExecutionImplementationContractCoordinator",
		AssetExecutionImplementationContractCoordinator,
		{
			"Logger",
			"Diagnostics",
			"SnapshotManager",
			"AssetManifestCoordinator",
			"AssetUsagePlanCoordinator",
			"AssetReadinessReviewCoordinator",
			"AssetApprovalLedgerCoordinator",
			"AssetExecutionPermitCoordinator",
			"AssetRuntimeGateCoordinator",
			"AssetExecutionBoundaryReviewCoordinator",
			"AssetExecutionDesignContractCoordinator",
			"AssetExecutionImplementationReadinessCoordinator",
		}
	)

	Framework.registerModule(
		"AssetGovernanceIntegrationCoordinator",
		AssetGovernanceIntegrationCoordinator,
		{
			"Logger",
			"Diagnostics",
			"SnapshotManager",
			"AssetManifestCoordinator",
			"AssetUsagePlanCoordinator",
			"AssetReadinessReviewCoordinator",
			"AssetApprovalLedgerCoordinator",
			"AssetExecutionPermitCoordinator",
			"AssetRuntimeGateCoordinator",
			"AssetExecutionBoundaryReviewCoordinator",
			"AssetExecutionDesignContractCoordinator",
			"AssetExecutionImplementationReadinessCoordinator",
			"AssetExecutionImplementationContractCoordinator",
		}
	)

	Framework.registerModule(
		"AssetGovernanceCertificationCoordinator",
		AssetGovernanceCertificationCoordinator,
		{
			"Logger",
			"Diagnostics",
			"SnapshotManager",
			"AssetManifestCoordinator",
			"AssetUsagePlanCoordinator",
			"AssetReadinessReviewCoordinator",
			"AssetApprovalLedgerCoordinator",
			"AssetExecutionPermitCoordinator",
			"AssetRuntimeGateCoordinator",
			"AssetExecutionBoundaryReviewCoordinator",
			"AssetExecutionDesignContractCoordinator",
			"AssetExecutionImplementationReadinessCoordinator",
			"AssetExecutionImplementationContractCoordinator",
			"AssetGovernanceIntegrationCoordinator",
		}
	)

	Framework.registerModule(
		"AssetGovernanceCertificationIntegrationCoordinator",
		AssetGovernanceCertificationIntegrationCoordinator,
		{
			"Logger",
			"Diagnostics",
			"SnapshotManager",
			"AssetManifestCoordinator",
			"AssetUsagePlanCoordinator",
			"AssetReadinessReviewCoordinator",
			"AssetApprovalLedgerCoordinator",
			"AssetExecutionPermitCoordinator",
			"AssetRuntimeGateCoordinator",
			"AssetExecutionBoundaryReviewCoordinator",
			"AssetExecutionDesignContractCoordinator",
			"AssetExecutionImplementationReadinessCoordinator",
			"AssetExecutionImplementationContractCoordinator",
			"AssetGovernanceIntegrationCoordinator",
			"AssetGovernanceCertificationCoordinator",
		}
	)

	Framework.registerModule(
		"AssetGovernanceCertificationInspectionCoordinator",
		AssetGovernanceCertificationInspectionCoordinator,
		{
			"Logger",
			"Diagnostics",
			"SnapshotManager",
			"AssetManifestCoordinator",
			"AssetUsagePlanCoordinator",
			"AssetReadinessReviewCoordinator",
			"AssetApprovalLedgerCoordinator",
			"AssetExecutionPermitCoordinator",
			"AssetRuntimeGateCoordinator",
			"AssetExecutionBoundaryReviewCoordinator",
			"AssetExecutionDesignContractCoordinator",
			"AssetExecutionImplementationReadinessCoordinator",
			"AssetExecutionImplementationContractCoordinator",
			"AssetGovernanceIntegrationCoordinator",
			"AssetGovernanceCertificationCoordinator",
			"AssetGovernanceCertificationIntegrationCoordinator",
		}
	)

	Framework.registerModule(
		"AssetGovernanceCertificationDecisionCoordinator",
		AssetGovernanceCertificationDecisionCoordinator,
		{
			"Logger",
			"Diagnostics",
			"SnapshotManager",
			"AssetManifestCoordinator",
			"AssetUsagePlanCoordinator",
			"AssetReadinessReviewCoordinator",
			"AssetApprovalLedgerCoordinator",
			"AssetExecutionPermitCoordinator",
			"AssetRuntimeGateCoordinator",
			"AssetExecutionBoundaryReviewCoordinator",
			"AssetExecutionDesignContractCoordinator",
			"AssetExecutionImplementationReadinessCoordinator",
			"AssetExecutionImplementationContractCoordinator",
			"AssetGovernanceIntegrationCoordinator",
			"AssetGovernanceCertificationCoordinator",
			"AssetGovernanceCertificationIntegrationCoordinator",
			"AssetGovernanceCertificationInspectionCoordinator",
		}
	)

	Framework.registerModule(
		"AssetExecutionGovernanceCoordinator",
		AssetExecutionGovernanceCoordinator,
		{
			"Logger",
			"Diagnostics",
			"SnapshotManager",
			"AssetManifestCoordinator",
			"AssetUsagePlanCoordinator",
			"AssetReadinessReviewCoordinator",
			"AssetApprovalLedgerCoordinator",
			"AssetExecutionPermitCoordinator",
			"AssetRuntimeGateCoordinator",
			"AssetExecutionBoundaryReviewCoordinator",
			"AssetExecutionDesignContractCoordinator",
			"AssetExecutionImplementationReadinessCoordinator",
			"AssetExecutionImplementationContractCoordinator",
			"AssetGovernanceIntegrationCoordinator",
			"AssetGovernanceCertificationCoordinator",
			"AssetGovernanceCertificationIntegrationCoordinator",
			"AssetGovernanceCertificationInspectionCoordinator",
			"AssetGovernanceCertificationDecisionCoordinator",
		}
	)

	Framework.registerModule(
		"AssetExecutionAuthorizationCoordinator",
		AssetExecutionAuthorizationCoordinator,
		{
			"Logger",
			"Diagnostics",
			"SnapshotManager",
			"AssetManifestCoordinator",
			"AssetUsagePlanCoordinator",
			"AssetReadinessReviewCoordinator",
			"AssetApprovalLedgerCoordinator",
			"AssetExecutionPermitCoordinator",
			"AssetRuntimeGateCoordinator",
			"AssetExecutionBoundaryReviewCoordinator",
			"AssetExecutionDesignContractCoordinator",
			"AssetExecutionImplementationReadinessCoordinator",
			"AssetExecutionImplementationContractCoordinator",
			"AssetGovernanceIntegrationCoordinator",
			"AssetGovernanceCertificationCoordinator",
			"AssetGovernanceCertificationIntegrationCoordinator",
			"AssetGovernanceCertificationInspectionCoordinator",
			"AssetGovernanceCertificationDecisionCoordinator",
			"AssetExecutionGovernanceCoordinator",
		}
	)

	Framework.registerModule("AssetExecutionCoordinator", AssetExecutionCoordinator, {
		"Logger",
		"Diagnostics",
		"SnapshotManager",
		"AssetExecutionAuthorizationCoordinator",
	})

	Framework.registerModule("AssetExecutionAdapterCoordinator", AssetExecutionAdapterCoordinator, {
		"Logger",
		"Diagnostics",
		"SnapshotManager",
		"AssetExecutionCoordinator",
	})

	Framework.registerModule(
		"AssetExecutionAdapterRegistryCoordinator",
		AssetExecutionAdapterRegistryCoordinator,
		{
			"Logger",
			"Diagnostics",
			"SnapshotManager",
			"AssetExecutionAdapterCoordinator",
		}
	)

	Framework.registerModule(
		"AssetExecutionAdapterRegistrationWorkflowCoordinator",
		AssetExecutionAdapterRegistrationWorkflowCoordinator,
		{
			"Logger",
			"Diagnostics",
			"SnapshotManager",
			"AssetExecutionAdapterRegistryCoordinator",
		}
	)

	Framework.registerModule("SaveCoordinator", SaveCoordinator, {
		"Logger",
		"EventBus",
		"Diagnostics",
		"SnapshotManager",
		"ObservationService",
		"GameplayCoordinator",
		"GameplayFlowCoordinator",
	})

	Framework.registerModule("PersistenceCoordinator", PersistenceCoordinator, {
		"Logger",
		"EventBus",
		"Diagnostics",
		"SnapshotManager",
		"SaveCoordinator",
		"SessionCoordinator",
		"ObjectiveCoordinator",
	})

	Framework.registerModule("SaveSessionCoordinator", SaveSessionCoordinator, {
		"Logger",
		"EventBus",
		"Diagnostics",
		"SnapshotManager",
		"SaveCoordinator",
		"PersistenceCoordinator",
	})

	Framework.registerModule("NarrativeCoordinator", NarrativeCoordinator, {
		"Logger",
		"EventBus",
		"Diagnostics",
		"SnapshotManager",
		"ObservationService",
		"DirectorCoordinator",
		"HorrorOrchestrator",
		"LivingCognitionCoordinator",
		"SaveCoordinator",
		"GameplayCoordinator",
	})

	Framework.registerModule("MonsterIntelligenceCoordinator", MonsterIntelligenceCoordinator, {
		"Logger",
		"EventBus",
		"Scheduler",
		"Diagnostics",
		"SnapshotManager",
		"ObservationService",
		"DirectorCoordinator",
		"GameplayExecutionService",
	})

	Framework.registerModule("LivingCognitionCoordinator", LivingCognitionCoordinator, {
		"Logger",
		"EventBus",
		"Scheduler",
		"Diagnostics",
		"SnapshotManager",
		"ObservationService",
		"MonsterIntelligenceCoordinator",
		"HorrorOrchestrator",
	})

	MonsterAIService.setObservationService(ObservationService)

	Framework.registerModule("MonsterAIService", MonsterAIService, {
		"Logger",
		"EventBus",
		"Diagnostics",
		"SnapshotManager",
		"ObservationService",
		"DirectorCoordinator",
		"LivingCognitionCoordinator",
		"MonsterIntelligenceCoordinator",
		"HorrorOrchestrator",
		"GameplayExecutionService",
	})

	Framework.registerModule("HorrorOrchestrator", HorrorOrchestrator, {
		"Logger",
		"EventBus",
		"Scheduler",
		"Diagnostics",
		"SnapshotManager",
		"ObservationService",
		"DirectorCoordinator",
		"HorrorDirector",
		"EnvironmentDirector",
		"LightingDirector",
		"AudioDirector",
		"MonsterIntelligenceCoordinator",
		"GameplayCoordinator",
		"GameplayExecutionService",
	})

	Framework.registerModule("SimulationService", SimulationService, {
		"Logger",
		"EventBus",
		"Diagnostics",
		"SnapshotManager",
		"ObservationService",
		"DirectorCoordinator",
		"EnvironmentDirector",
		"PlayerService",
		"PlayerExperienceService",
	})

	Framework.registerModule("Chapter0HomeCoordinator", Chapter0HomeCoordinator, {
		"Logger",
		"EventBus",
		"Diagnostics",
		"SnapshotManager",
		"ObservationService",
		"PlayerExperienceService",
		"InteractionCoordinator",
		"EnvironmentalInteractionCoordinator",
		"Chapter0EnvironmentalCoordinator",
		"WorldCoordinator",
		"ObjectiveCoordinator",
		"GameplayFlowCoordinator",
		"NarrativeCoordinator",
		"PresentationCoordinator",
	})

	local initialized = Framework.initialize({
		mode = "Development",
		debug = true,
	})

	if not initialized then
		error("London Engine initialization failed", 0)
	end

	local started = Framework.start()

	if not started then
		error("London Engine startup failed", 0)
	end

	local valid, validationErr = Framework.validate()

	if not valid then
		error("London Engine validation failed: " .. tostring(validationErr), 0)
	end

	local health = Framework.printStartupSummary()

	if not health.healthy then
		error("London Engine health check failed", 0)
	end

	log.success("London Engine is ready")
end

local ok, err = pcall(startEngine)

if not ok then
	log.fatal("Bootstrap refused startup: %s", tostring(err))
	error(err, 0)
end
