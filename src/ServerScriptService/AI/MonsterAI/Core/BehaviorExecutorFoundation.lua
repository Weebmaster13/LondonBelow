--!strict
-- Routes validated intents to dry-run behavior foundations.

local ChaseIntentFoundation = require(script.Parent.ChaseIntentFoundation)
local NavigationIntentBridge = require(script.Parent.NavigationIntentBridge)
local PerceptionBridge = require(script.Parent.PerceptionBridge)
local RetreatIntentFoundation = require(script.Parent.RetreatIntentFoundation)
local StalkIntentFoundation = require(script.Parent.StalkIntentFoundation)
local Types = require(script.Parent.MonsterAITypes)
local WatchIntentFoundation = require(script.Parent.WatchIntentFoundation)

local BehaviorExecutorFoundation = {}

local planners = {
	Chase = ChaseIntentFoundation,
	Stalk = StalkIntentFoundation,
	Watch = WatchIntentFoundation,
	Retreat = RetreatIntentFoundation,
	Navigate = NavigationIntentBridge,
	Perceive = PerceptionBridge,
}

function BehaviorExecutorFoundation.plan(intent: any)
	local planner = planners[intent.intentKind]
	if planner == nil then
		return nil, "no Monster AI planner for intentKind"
	end
	local record = planner.plan(intent)
	record.status = Types.IntentStatus.Planned
	record.approvalId = intent.approvalId
	record.approvedBy = intent.approvedBy
	record.sourceSystem = intent.sourceSystem
	record.priority = intent.priority
	record.mode = Types.ExecutionMode
	return record, nil
end

function BehaviorExecutorFoundation.applyDryRun(plan: any)
	local applied = table.clone(plan)
	applied.status = Types.IntentStatus.DryRunApplied
	applied.appliedAt = os.clock()
	applied.reason = plan.reason .. " Dry-run applied as an audit record only."
	return applied
end

return BehaviorExecutorFoundation
