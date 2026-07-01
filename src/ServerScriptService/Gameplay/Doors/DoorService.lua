--!strict

local Config = require(script.Parent.DoorConfig)
local DoorDiagnostics = require(script.Parent.DoorDiagnostics)
local DoorValidator = require(script.Parent.DoorValidator)

local DoorService = {}

local definitions: { [string]: any } = {}
local statuses: { [string]: any } = {}
local recentTransitions: { any } = {}
local counters = {
	registered = 0,
	duplicatesRejected = 0,
	transitions = 0,
	invalidTransitions = 0,
	failedOpen = 0,
}

local function remember(transition: any)
	table.insert(recentTransitions, transition)
	while #recentTransitions > Config.RecentTransitionLimit do
		table.remove(recentTransitions, 1)
	end
end

function DoorService.initialize() end

function DoorService.registerDoor(definition: any): (boolean, string?)
	local valid, reason = DoorValidator.validateDefinition(definition)
	if not valid then
		counters.invalidTransitions += 1
		return false, reason
	end
	if definitions[definition.id] ~= nil then
		counters.duplicatesRejected += 1
		return false, "duplicate door id"
	end
	definitions[definition.id] = table.clone(definition)
	statuses[definition.id] = {
		id = definition.id,
		state = definition.initialState,
		lastChangedAt = os.clock(),
		openAttempts = 0,
		failedAttempts = 0,
		metadata = table.clone(definition.metadata or {}),
	}
	counters.registered += 1
	return true, nil
end

function DoorService.transition(
	doorId: string,
	nextState: string,
	reason: string?
): (boolean, string?, any?)
	local status = statuses[doorId]
	if status == nil then
		counters.invalidTransitions += 1
		return false, "unknown door", nil
	end
	local valid, validationReason = DoorValidator.validateTransition(status.state, nextState)
	if not valid then
		status.failedAttempts += 1
		counters.invalidTransitions += 1
		return false, validationReason, nil
	end
	local previous = status.state
	status.state = nextState
	status.lastChangedAt = os.clock()
	counters.transitions += 1
	remember({
		at = status.lastChangedAt,
		doorId = doorId,
		from = previous,
		to = nextState,
		reason = reason,
	})
	return true, nil, table.clone(status)
end

function DoorService.tryOpen(doorId: string): (boolean, string?, any?)
	local status = statuses[doorId]
	if status == nil then
		return false, "unknown door", nil
	end
	status.openAttempts += 1
	if Config.LockedStates[status.state] then
		status.failedAttempts += 1
		counters.failedOpen += 1
		return false, "door is locked or unavailable", table.clone(status)
	end
	return DoorService.transition(doorId, "Open", "OpenRequest")
end

function DoorService.inspect()
	return DoorDiagnostics.capture({
		registeredCount = counters.registered,
		statuses = table.clone(statuses),
		recentTransitions = table.clone(recentTransitions),
		counters = table.clone(counters),
	})
end

function DoorService.validate(): (boolean, string?)
	return DoorValidator.validate()
end

function DoorService.runSelfChecks()
	DoorService.shutdown()
	DoorService.registerDoor({
		id = "selfcheck.door",
		displayName = "Self Check Door",
		initialState = "Closed",
		requiredKeyIds = {},
		allowedUsers = {},
		metadata = {},
	})
	local invalid = DoorService.transition("selfcheck.door", "Sealed", "InvalidSelfCheck")
	local lockOk = DoorService.transition("selfcheck.door", "Locked", "SelfCheck")
	local openLocked = DoorService.tryOpen("selfcheck.door")
	local unlockOk = DoorService.transition("selfcheck.door", "Unlocked", "SelfCheck")
	local openOk = DoorService.tryOpen("selfcheck.door")
	DoorService.shutdown()
	return {
		ok = invalid == false
			and lockOk == true
			and openLocked == false
			and unlockOk == true
			and openOk == true,
		invalidTransitionRejects = invalid == false,
		keyUnlockFlowWorks = unlockOk == true and openOk == true,
	}
end

function DoorService.shutdown()
	table.clear(definitions)
	table.clear(statuses)
	table.clear(recentTransitions)
	for key in pairs(counters) do
		counters[key] = 0
	end
end

return DoorService
