--!strict

local DoorStateMachine = {}

local transitions: { [string]: { [string]: boolean } } = {
	Closed = { Open = true, Locked = true, Opening = true, Disabled = true },
	Unlocked = { Open = true, Closed = true, Opening = true, Locked = true },
	Open = { Closed = true, Closing = true, Broken = true, Disabled = true },
	Opening = { Open = true, Jammed = true, Broken = true },
	Closing = { Closed = true, Jammed = true, Broken = true },
	Locked = { Unlocked = true, Closed = true, Broken = true, Disabled = true },
	Bolted = { Closed = true, Broken = true },
	Barred = { Closed = true, Broken = true },
	Jammed = { Closed = true, Broken = true },
	PowerLocked = { Unlocked = true, Disabled = true },
	PuzzleLocked = { Unlocked = true, Closed = true },
	DirectorLocked = { Unlocked = true, Closed = true },
	NarrativeLocked = { Unlocked = true, Closed = true },
	Sealed = { Disabled = true },
	Broken = { Disabled = true },
	Disabled = {},
}

function DoorStateMachine.canTransition(fromState: string, toState: string): boolean
	local allowed = transitions[fromState]
	return allowed ~= nil and allowed[toState] == true
end

function DoorStateMachine.allowedFrom(state: string): { string }
	local allowed = transitions[state] or {}
	local result = {}
	for nextState in pairs(allowed) do
		table.insert(result, nextState)
	end
	table.sort(result)
	return result
end

function DoorStateMachine.isSupportedState(state: string): boolean
	return transitions[state] ~= nil
end

return DoorStateMachine
