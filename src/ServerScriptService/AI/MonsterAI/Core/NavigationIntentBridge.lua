--!strict
-- Approval-only bridge for future navigation. It never computes paths or moves monsters.

local NavigationIntentBridge = {}

function NavigationIntentBridge.plan(intent: any)
	return {
		executionKind = "NavigationIntent",
		monsterId = intent.monsterId,
		intentId = intent.intentId,
		status = "Planned",
		dryRun = true,
		action = "RecordNavigationNeed",
		reason = "Navigation intent recorded only; no pathfinding, MoveTo, CFrame, or Workspace mutation executed.",
		context = intent.context,
		createdAt = os.clock(),
	}
end

return NavigationIntentBridge
