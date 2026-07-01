--!strict
-- Dry-run foundation for future watch/observe behavior.

local WatchIntentFoundation = {}

function WatchIntentFoundation.plan(intent: any)
	return {
		executionKind = "WatchIntent",
		monsterId = intent.monsterId,
		intentId = intent.intentId,
		status = "Planned",
		dryRun = true,
		action = "PrepareFutureWatch",
		reason = "Approved watch intent recorded; no model reveal, smile, animation, camera effect, or scare executed.",
		context = intent.context,
		createdAt = os.clock(),
	}
end

return WatchIntentFoundation
