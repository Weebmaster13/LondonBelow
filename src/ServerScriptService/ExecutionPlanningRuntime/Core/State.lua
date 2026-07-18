--!strict

local Audit = require(script.Parent.Audit)
local Serialization = require(script.Parent.Serialization)
local Types = require(script.Parent.Types)

local State = {}

local store = {
	lifecycleState = Types.LifecycleState.Uninitialized,
	graph = nil :: any,
	publication = nil :: any,
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

function State.setGraph(graph: any)
	store.graph = Serialization.deepCopy(graph)
	Audit.record(store.audit, "GraphStored", { graphId = graph.graphId })
end

function State.setPublication(publication: any)
	store.publication = Serialization.deepCopy(publication)
	Audit.record(store.audit, "PublicationStored", { planId = publication.planId })
end

function State.recordValidationFailure(reason: string, payload: any?)
	boundedInsert(store.validationFailures, {
		reason = reason,
		payload = payload,
		timestamp = Types.StableTimestamp,
	}, Types.Limits.MaxValidationFailures)
end

function State.get(): any
	return Serialization.deepCopy(store)
end

function State.audit(): { any }
	return Audit.snapshot(store.audit)
end

function State.recordSnapshot(snapshot: any)
	boundedInsert(store.snapshots, snapshot, Types.Limits.MaxSnapshots)
end

function State.clear()
	store.lifecycleState = Types.LifecycleState.Uninitialized
	store.graph = nil
	store.publication = nil
	store.audit = {}
	store.validationFailures = {}
	store.snapshots = {}
end

return State
