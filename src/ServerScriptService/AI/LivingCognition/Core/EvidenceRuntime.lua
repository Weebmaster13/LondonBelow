--!strict
-- Evidence is validated context, not truth.

local Config = require(script.Parent.LivingCognitionConfiguration)
local Serialization = require(script.Parent.LivingCognitionSerialization)

local EvidenceRuntime = {}

function EvidenceRuntime.fromObservation(observation: any)
	return {
		evidenceId = "evidence:" .. observation.observationId,
		entityId = observation.entityId,
		origin = observation.sourceSystem,
		confidence = math.clamp(observation.confidence * 0.9, 0, Config.AbsoluteCertaintyThreshold),
		freshness = 1,
		supportingObservations = { observation.observationId },
		conflictingObservations = {},
		expiration = observation.receivedAt + 60,
		provenance = observation.provenance,
		relationships = {},
		traceId = observation.traceId,
		createdAt = observation.receivedAt,
		payload = Serialization.deepCopy(observation.payload),
	}
end

function EvidenceRuntime.decay(evidence: any, deltaSeconds: number)
	local decayed = Serialization.deepCopy(evidence)
	decayed.confidence = math.clamp(
		decayed.confidence - Config.ConfidenceDecayPerSecond * math.max(0, deltaSeconds),
		0,
		Config.AbsoluteCertaintyThreshold
	)
	decayed.freshness =
		math.clamp(decayed.freshness - Config.EvidenceFreshnessDecayPerSecond * deltaSeconds, 0, 1)
	return decayed
end

return EvidenceRuntime
