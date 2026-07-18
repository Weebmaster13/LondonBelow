--!strict

local Audit = require(script.Parent.Audit)
local Serialization = require(script.Parent.Serialization)
local Types = require(script.Parent.Types)

local State = {}

local store = {
	lifecycleState = Types.LifecycleState.Uninitialized,
	policies = {} :: { any },
	rules = {} :: { any },
	decision = nil :: any,
	audit = {} :: { any },
	validationFailures = {} :: { any },
	snapshots = {} :: { any },
}

local function boundedInsert(list: { any }, value: any, limit: number)
	if #list >= limit then
		table.remove(list, 1)
	end
	table.insert(list, Serialization.deepCopy(value))
end

function State.transition(state: string)
	store.lifecycleState = state
	Audit.record(store.audit, "LifecycleTransition", { state = state })
end

function State.setPolicies(policies: { any })
	store.policies = Serialization.deepCopy(policies)
	Audit.record(store.audit, "PoliciesLoaded", { count = #policies })
end

function State.setRules(rules: { any })
	store.rules = Serialization.deepCopy(rules)
	Audit.record(store.audit, "RulesValidated", { count = #rules })
end

function State.setDecision(decision: any)
	store.decision = Serialization.deepCopy(decision)
	Audit.record(store.audit, "DecisionPublished", { authorizationId = decision.authorizationId })
end

function State.recordValidationFailure(reason: string, payload: any?)
	boundedInsert(store.validationFailures, {
		reason = reason,
		payload = payload,
		timestamp = Types.StableTimestamp,
	}, Types.Limits.MaxValidationFailures)
	Audit.record(store.audit, "ValidationFailure", { reason = reason })
end

function State.recordSnapshot(snapshot: any)
	boundedInsert(store.snapshots, snapshot, Types.Limits.MaxSnapshots)
end

function State.get(): any
	return Serialization.deepCopy(store)
end

function State.audit(): { any }
	return Audit.snapshot(store.audit)
end

function State.clear()
	store.lifecycleState = Types.LifecycleState.Uninitialized
	store.policies = {}
	store.rules = {}
	store.decision = nil
	store.audit = {}
	store.validationFailures = {}
	store.snapshots = {}
end

return State
