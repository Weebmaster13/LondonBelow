--!strict
-- Dry-run foundation for future chase execution. It does not chase, damage, or animate.

local ChaseIntentFoundation = {}

function ChaseIntentFoundation.plan(intent: any)
	return {
		executionKind = "ChaseIntent",
		monsterId = intent.monsterId,
		intentId = intent.intentId,
		status = "Planned",
		dryRun = true,
		action = "PrepareFutureChase",
		reason = "Approved chase intent recorded for future executor; no movement, attacks, damage, or jumpscares executed.",
		context = intent.context,
		createdAt = os.clock(),
	}
end

return ChaseIntentFoundation
