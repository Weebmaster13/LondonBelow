--!strict
-- Shared types for Living Cognition.

local Types = {}

export type Confidence = number

export type CognitiveEntity = {
	entityId: string,
	entityKind: string,
	ownerSystem: string,
	tags: { string },
}

export type CognitiveObservation = {
	observationId: string,
	entityId: string,
	sourceSystem: string,
	observedAt: number,
	receivedAt: number,
	confidence: Confidence,
	provenance: string,
	payload: { [string]: any },
	traceId: string,
}

export type Evidence = {
	evidenceId: string,
	entityId: string,
	origin: string,
	confidence: Confidence,
	freshness: number,
	supportingObservations: { string },
	conflictingObservations: { string },
	expiration: number?,
	provenance: string,
	relationships: { string },
	traceId: string,
	createdAt: number,
}

export type Hypothesis = {
	hypothesisId: string,
	entityId: string,
	explanation: string,
	confidence: Confidence,
	evidenceIds: { string },
	conflictingEvidenceIds: { string },
	state: string,
	traceId: string,
	createdAt: number,
	updatedAt: number,
}

export type Thought = {
	thoughtId: string,
	entityId: string,
	hypothesisId: string,
	state: string,
	confidence: Confidence,
	transitions: { any },
	traceId: string,
	createdAt: number,
	updatedAt: number,
}

export type Belief = {
	beliefId: string,
	entityId: string,
	statement: string,
	confidence: Confidence,
	evidenceIds: { string },
	contradictionCount: number,
	traceId: string,
	createdAt: number,
	updatedAt: number,
}

Types.ResultCode = {
	Ok = "OK",
	InvalidRequest = "INVALID_REQUEST",
	DuplicateId = "DUPLICATE_ID",
	UnknownEntity = "UNKNOWN_ENTITY",
	RejectedExecutionLeakage = "REJECTED_EXECUTION_LEAKAGE",
}

return Types
