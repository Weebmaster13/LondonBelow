--!strict
-- Dry-run foundation for future stalking behavior. It records intent only.

local StalkIntentFoundation = {}

function StalkIntentFoundation.plan(intent: any)
	return {
		executionKind = "StalkIntent",
		monsterId = intent.monsterId,
		intentId = intent.intentId,
		status = "Planned",
		dryRun = true,
		action = "PrepareFutureStalk",
		reason = "Approved stalk intent recorded; no navigation, hiding spot learning, animation, or Workspace mutation executed.",
		context = intent.context,
		createdAt = os.clock(),
	}
end

return StalkIntentFoundation
