--!strict
-- Hypotheses are possible explanations. Multiple can coexist.

local Serialization = require(script.Parent.LivingCognitionSerialization)

local HypothesisRuntime = {}

function HypothesisRuntime.generate(evidence: any)
	return {
		{
			hypothesisId = "hypothesis:source:" .. evidence.evidenceId,
			entityId = evidence.entityId,
			explanation = "Source may explain observation",
			confidence = evidence.confidence,
			evidenceIds = { evidence.evidenceId },
			conflictingEvidenceIds = {},
			state = "Active",
			traceId = evidence.traceId,
			createdAt = os.clock(),
			updatedAt = os.clock(),
		},
		{
			hypothesisId = "hypothesis:unknown:" .. evidence.evidenceId,
			entityId = evidence.entityId,
			explanation = "Unknown",
			confidence = math.clamp(1 - evidence.confidence, 0, 1),
			evidenceIds = { evidence.evidenceId },
			conflictingEvidenceIds = {},
			state = "Active",
			traceId = evidence.traceId,
			createdAt = os.clock(),
			updatedAt = os.clock(),
		},
	}
end

function HypothesisRuntime.rank(hypotheses: { any }): { any }
	local ranked = Serialization.deepCopy(hypotheses)
	table.sort(ranked, function(left, right)
		if left.confidence == right.confidence then
			return tostring(left.hypothesisId) < tostring(right.hypothesisId)
		end
		return left.confidence > right.confidence
	end)
	return ranked
end

function HypothesisRuntime.withExplanation(evidence: any, explanation: string)
	return {
		hypothesisId = "hypothesis:" .. explanation .. ":" .. evidence.evidenceId,
		entityId = evidence.entityId,
		explanation = explanation,
		confidence = evidence.confidence,
		evidenceIds = { evidence.evidenceId },
		conflictingEvidenceIds = {},
		state = "Active",
		traceId = evidence.traceId,
		createdAt = os.clock(),
		updatedAt = os.clock(),
	}
end

return HypothesisRuntime
