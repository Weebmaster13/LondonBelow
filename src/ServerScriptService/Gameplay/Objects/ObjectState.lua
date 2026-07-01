--!strict

local ObjectState = {}

local states: { [string]: any } = {}
local recentChanges: { any } = {}
local counters = {
	stateChanges = 0,
	interactions = 0,
	rejected = 0,
}

local function remember(change: any)
	table.insert(recentChanges, change)
	while #recentChanges > 120 do
		table.remove(recentChanges, 1)
	end
end

function ObjectState.initializeObject(definition: any)
	states[definition.id] = {
		id = definition.id,
		kind = definition.kind,
		state = definition.initialState,
		lastChangedAt = os.clock(),
		metadata = table.clone(definition.metadata),
	}
end

function ObjectState.get(id: string)
	local state = states[id]
	return if state ~= nil then table.clone(state) else nil
end

function ObjectState.setState(id: string, nextState: string, metadata: { [string]: any }?)
	local state = states[id]
	if state == nil then
		return nil
	end
	state.state = nextState
	state.lastChangedAt = os.clock()
	if metadata ~= nil then
		for key, value in pairs(metadata) do
			state.metadata[key] = value
		end
	end
	counters.stateChanges += 1
	remember({ at = state.lastChangedAt, id = id, state = nextState })
	return table.clone(state)
end

function ObjectState.recordInteraction(id: string)
	counters.interactions += 1
	remember({ at = os.clock(), id = id, kind = "Interacted" })
end

function ObjectState.recordRejected()
	counters.rejected += 1
end

function ObjectState.inspect()
	local copied = {}
	local stateCount = 0
	for id, state in pairs(states) do
		stateCount += 1
		copied[id] = table.clone(state)
	end
	return {
		stateCount = stateCount,
		states = copied,
		recentChanges = table.clone(recentChanges),
		counters = table.clone(counters),
	}
end

function ObjectState.clear()
	table.clear(states)
	table.clear(recentChanges)
	for key in pairs(counters) do
		counters[key] = 0
	end
end

return ObjectState
