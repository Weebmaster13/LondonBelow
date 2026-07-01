--!strict
-- Dry-run foundation for future retreat/fake-leave behavior.

local RetreatIntentFoundation = {}

function RetreatIntentFoundation.plan(intent: any)
	return {
		executionKind = "RetreatIntent",
		monsterId = intent.monsterId,
		intentId = intent.intentId,
		status = "Planned",
		dryRun = true,
		action = "PrepareFutureRetreat",
		reason = "Approved retreat intent recorded; no fake-leave execution, movement, audio, or lighting changes executed.",
		context = intent.context,
		createdAt = os.clock(),
	}
end

return RetreatIntentFoundation
