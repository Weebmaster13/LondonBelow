--!strict
--[[
	Types for the dev-only London Engine Simulation Framework.

	Simulation reports are diagnostic artifacts. They are not gameplay truth,
	client networking contracts, Chapter 1 logic, or live player state.
]]

local SimulationTypes = {}

export type SimulationMode = "Disabled" | "SelfCheck" | "Manual"
export type ScenarioStatus = "Pass" | "Fail" | "Warning"

export type SimulatedPlayerProfile = {
	userId: number,
	name: string,
	traits: { string },
	partyId: string?,
}

export type SimulatedZone = {
	zoneId: string,
	zoneKind: string,
	tags: { string },
}

export type SimulationObservation = {
	id: string,
	amount: number?,
	playerUserId: number?,
	metadata: { [string]: any },
	expectAccepted: boolean,
}

export type SimulationScenario = {
	id: string,
	displayName: string,
	description: string,
	players: { SimulatedPlayerProfile },
	zones: { SimulatedZone },
	observations: { SimulationObservation },
	actions: { string },
}

export type SimulationReport = {
	scenarioId: string,
	status: ScenarioStatus,
	warnings: { string },
	failures: { string },
	simulatedPlayers: { SimulatedPlayerProfile },
	simulatedZones: { SimulatedZone },
	observationsInjected: { any },
	observationsRejected: { any },
	pressureTimeline: { any },
	candidateDecisions: { any },
	rejectedDecisions: { any },
	approvedDecisions: { any },
	failedExecutionBridgeCalls: { any },
	cooldownChanges: { any },
	memoryChanges: { any },
	diagnosticsSnapshots: { any },
	architecturalViolations: { string },
	decisionTraces: { any },
}

SimulationTypes.Mode = {
	Disabled = "Disabled",
	SelfCheck = "SelfCheck",
	Manual = "Manual",
}

return SimulationTypes
