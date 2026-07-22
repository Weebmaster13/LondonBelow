--!strict

local Serialization = require(script.Parent.CommandSerialization)
local Types = require(script.Parent.CommandTypes)

local Lifecycle = {}

local legalTransitions: { [string]: { [string]: boolean } } = {
	[Types.Status.Created] = {
		[Types.Status.Submitted] = true,
		[Types.Status.Rejected] = true,
	},
	[Types.Status.Submitted] = {
		[Types.Status.Validated] = true,
		[Types.Status.Rejected] = true,
	},
	[Types.Status.Validated] = {
		[Types.Status.Authorized] = true,
		[Types.Status.Rejected] = true,
	},
	[Types.Status.Authorized] = {
		[Types.Status.Queued] = true,
		[Types.Status.Rejected] = true,
	},
	[Types.Status.Queued] = {
		[Types.Status.Scheduled] = true,
		[Types.Status.Cancelled] = true,
		[Types.Status.Failed] = true,
	},
	[Types.Status.Scheduled] = {
		[Types.Status.Queued] = true,
		[Types.Status.Executing] = true,
		[Types.Status.Cancelled] = true,
		[Types.Status.Failed] = true,
	},
	[Types.Status.Executing] = {
		[Types.Status.Completed] = true,
		[Types.Status.Failed] = true,
	},
}

local terminalStates = {
	[Types.Status.Completed] = true,
	[Types.Status.Rejected] = true,
	[Types.Status.Cancelled] = true,
	[Types.Status.Failed] = true,
}

function Lifecycle.canTransition(fromState: string, toState: string): boolean
	if terminalStates[fromState] then
		return false
	end
	return legalTransitions[fromState] ~= nil and legalTransitions[fromState][toState] == true
end

function Lifecycle.transition(
	command: any,
	toState: string,
	timestampField: string?,
	referenceField: string?,
	referenceValue: any?
)
	local fromState = command.executionState
	if not Lifecycle.canTransition(fromState, toState) then
		return nil,
			"illegal command lifecycle transition: " .. tostring(fromState) .. " -> " .. tostring(
				toState
			)
	end
	local nextCommand = table.clone(command)
	nextCommand.executionState = toState
	if timestampField ~= nil then
		nextCommand[timestampField] = os.clock()
	end
	if referenceField ~= nil then
		nextCommand[referenceField] = referenceValue
	end
	local lifecycle = {}
	for _, entry in ipairs(command.lifecycle or {}) do
		table.insert(lifecycle, entry)
	end
	table.insert(lifecycle, {
		fromState = fromState,
		toState = toState,
		timestamp = os.clock(),
	})
	nextCommand.lifecycle = lifecycle
	return Serialization.deepCopy(nextCommand), nil
end

function Lifecycle.isTerminal(state: string): boolean
	return terminalStates[state] == true
end

function Lifecycle.inspect()
	return Serialization.deepCopy({
		legalTransitions = legalTransitions,
		terminalStates = terminalStates,
	})
end

return Lifecycle
