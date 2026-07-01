--!strict
-- Approval-only bridge for future perception execution. No sensors or raycasts are created here.

local PerceptionBridge = {}

function PerceptionBridge.plan(intent: any)
	return {
		executionKind = "PerceptionIntent",
		monsterId = intent.monsterId,
		intentId = intent.intentId,
		status = "Planned",
		dryRun = true,
		action = "RecordPerceptionInterest",
		reason = "Perception intent accepted as context only; no raycasts, sensors, or Workspace reads executed.",
		context = intent.context,
		createdAt = os.clock(),
	}
end

return PerceptionBridge
