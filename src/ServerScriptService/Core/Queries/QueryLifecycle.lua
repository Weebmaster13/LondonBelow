--!strict

local Serialization = require(script.Parent.QuerySerialization)
local Types = require(script.Parent.QueryTypes)

local Lifecycle = {}

local legalTransitions = {
	[Types.Status.Created] = { [Types.Status.Validated] = true, [Types.Status.Rejected] = true },
	[Types.Status.Validated] = { [Types.Status.Authorized] = true, [Types.Status.Rejected] = true },
	[Types.Status.Authorized] = { [Types.Status.Queued] = true, [Types.Status.Rejected] = true },
	[Types.Status.Queued] = {
		[Types.Status.Dispatched] = true,
		[Types.Status.Cancelled] = true,
		[Types.Status.Failed] = true,
	},
	[Types.Status.Dispatched] = {
		[Types.Status.Executing] = true,
		[Types.Status.Cancelled] = true,
		[Types.Status.Failed] = true,
	},
	[Types.Status.Executing] = { [Types.Status.Completed] = true, [Types.Status.Failed] = true },
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

function Lifecycle.transition(query: any, toState: string, timestampField: string?)
	if not Lifecycle.canTransition(query.status, toState) then
		return nil,
			"illegal query lifecycle transition: " .. tostring(query.status) .. " -> " .. tostring(
				toState
			)
	end
	local nextQuery = table.clone(query)
	nextQuery.status = toState
	if timestampField ~= nil then
		nextQuery[timestampField] = os.clock()
	end
	local timeline = {}
	for _, entry in ipairs(query.timeline or {}) do
		table.insert(timeline, entry)
	end
	table.insert(timeline, {
		fromState = query.status,
		toState = toState,
		timestamp = os.clock(),
		ownerRuntime = query.ownerRuntime,
	})
	nextQuery.timeline = timeline
	return Serialization.deepCopy(nextQuery), nil
end

function Lifecycle.inspect()
	return Serialization.deepCopy({
		legalTransitions = legalTransitions,
		terminalStates = terminalStates,
	})
end

return Lifecycle
