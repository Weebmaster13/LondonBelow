--!strict

local Serialization = require(script.Parent.Serialization)
local Types = require(script.Parent.Types)

local State = {}

local state = {
	lifecycleState = Types.LifecycleState.Idle,
	session = nil :: any,
	events = {},
	assertions = {},
	diagnostics = {},
	snapshots = {},
	evidence = nil :: any,
	writerResult = nil :: any,
	cleanup = {
		started = false,
		completed = false,
	},
}

function State.clear()
	state.lifecycleState = Types.LifecycleState.Idle
	state.session = nil
	table.clear(state.events)
	table.clear(state.assertions)
	table.clear(state.diagnostics)
	table.clear(state.snapshots)
	state.evidence = nil
	state.writerResult = nil
	state.cleanup = {
		started = false,
		completed = false,
	}
end

function State.setLifecycle(lifecycleState: string)
	state.lifecycleState = lifecycleState
end

function State.setSession(session: any)
	state.session = Serialization.deepCopy(session)
	state.lifecycleState = Types.LifecycleState.SessionImported
end

function State.recordEvent(name: string, status: string, detail: string?)
	table.insert(state.events, {
		name = name,
		status = status,
		detail = detail,
		order = #state.events + 1,
	})
end

function State.recordAssertion(assertion: any)
	table.insert(state.assertions, Serialization.deepCopy(assertion))
end

function State.recordDiagnostic(diagnostic: any)
	table.insert(state.diagnostics, Serialization.deepCopy(diagnostic))
end

function State.recordSnapshot(snapshot: any)
	table.insert(state.snapshots, Serialization.deepCopy(snapshot))
end

function State.setEvidence(evidence: any)
	state.evidence = Serialization.deepCopy(evidence)
	state.lifecycleState = Types.LifecycleState.EvidencePrepared
end

function State.setWriterResult(writerResult: any)
	state.writerResult = Serialization.deepCopy(writerResult)
	state.lifecycleState = if writerResult.ok
		then Types.LifecycleState.CleanupComplete
		else Types.LifecycleState.WriterBlocked
end

function State.markCleanup(started: boolean, completed: boolean)
	state.cleanup = {
		started = started,
		completed = completed,
	}
end

function State.get(): any
	return Serialization.deepCopy(state)
end

return State
