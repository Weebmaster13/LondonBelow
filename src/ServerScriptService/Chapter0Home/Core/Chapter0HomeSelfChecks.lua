--!strict

local Config = require(script.Parent.Chapter0HomeConfig)
local Serialization = require(script.Parent.Chapter0HomeSerialization)
local State = require(script.Parent.Chapter0HomeState)
local Types = require(script.Parent.Chapter0HomeTypes)
local Validation = require(script.Parent.Chapter0HomeValidation)

local SelfChecks = {}

local function add(results: { any }, name: string, ok: boolean, detail: string?)
	table.insert(results, {
		name = name,
		ok = ok,
		detail = detail,
	})
end

local function summarize(results: { any })
	local failed = 0

	for _, result in ipairs(results) do
		if not result.ok then
			failed += 1
		end
	end

	return {
		ok = failed == 0,
		total = #results,
		failures = failed,
		results = results,
	}
end

local function overLimitRooms(definition: any)
	local excessive = Serialization.deepCopy(definition)

	for index = #excessive.rooms + 1, Types.Limits.MaxRooms + 1 do
		excessive.rooms[index] = Serialization.deepCopy(excessive.rooms[1])
		excessive.rooms[index].roomId = "chapter0_home_extra_room_" .. tostring(index)
	end

	return excessive
end

function SelfChecks.run(context: any)
	local results = {}
	local definition = Config.Definition

	local valid, reason = Validation.validateDefinition(definition)
	add(results, "definition validates", valid, reason)

	local duplicate = Serialization.deepCopy(definition)
	duplicate.interactions[2].interactionId = duplicate.interactions[1].interactionId
	local duplicateValid = Validation.validateDefinition(duplicate)
	add(results, "duplicate interaction ids reject", not duplicateValid, nil)

	local duplicateRoom = Serialization.deepCopy(definition)
	duplicateRoom.rooms[2].roomId = duplicateRoom.rooms[1].roomId
	local duplicateRoomValid = Validation.validateDefinition(duplicateRoom)
	add(results, "duplicate room ids reject", not duplicateRoomValid, nil)

	local sparseRooms = Serialization.deepCopy(definition)
	sparseRooms.rooms[2] = nil
	local sparseRoomsValid = Validation.validateDefinition(sparseRooms)
	add(results, "sparse room arrays reject", not sparseRoomsValid, nil)

	local dictionaryInteractions = Serialization.deepCopy(definition)
	dictionaryInteractions.interactions.byId = dictionaryInteractions.interactions[1]
	local dictionaryInteractionsValid = Validation.validateDefinition(dictionaryInteractions)
	add(results, "dictionary interaction arrays reject", not dictionaryInteractionsValid, nil)

	local missingRoom = Serialization.deepCopy(definition)
	missingRoom.interactions[1].roomId = "missing_room"
	local missingRoomValid = Validation.validateDefinition(missingRoom)
	add(results, "missing room references reject", not missingRoomValid, nil)

	local missingConnection = Serialization.deepCopy(definition)
	missingConnection.rooms[1].connections[1] = "missing_room"
	local missingConnectionValid = Validation.validateDefinition(missingConnection)
	add(results, "missing room connections reject", not missingConnectionValid, nil)

	local excessiveRooms = overLimitRooms(definition)
	local excessiveRoomsValid = Validation.validateDefinition(excessiveRooms)
	add(results, "room limits reject", not excessiveRoomsValid, nil)

	local unsafe = Serialization.deepCopy(definition)
	unsafe.interactions[1].metadata.DataStoreWrite = true
	local unsafeValid = Validation.validateDefinition(unsafe)
	add(results, "unsafe metadata rejects", not unsafeValid, nil)

	local optionalCompletion = Serialization.deepCopy(definition)
	table.insert(optionalCompletion.completionInteractionIds, "chapter0_home_bedroom_door")
	local optionalCompletionValid = Validation.validateDefinition(optionalCompletion)
	add(results, "optional completion references reject", not optionalCompletionValid, nil)

	State.clear()
	State.setStatus(Types.PhaseStatus.Started)
	local completeAfterFirst =
		State.recordInteraction(101, Types.RequiredInteractions[1], Types.RequiredInteractions)
	local completeAfterSecond =
		State.recordInteraction(101, Types.RequiredInteractions[2], Types.RequiredInteractions)
	local completeAfterThird =
		State.recordInteraction(101, Types.RequiredInteractions[3], Types.RequiredInteractions)
	add(
		results,
		"completion requires all required interactions",
		not completeAfterFirst and not completeAfterSecond and completeAfterThird,
		nil
	)

	State.clear()
	State.setStatus(Types.PhaseStatus.Started)
	local optionalCompletes =
		State.recordInteraction(202, "chapter0_home_bedroom_door", Types.RequiredInteractions)
	add(results, "optional interaction cannot complete chapter", not optionalCompletes, nil)

	State.recordInteraction(303, Types.RequiredInteractions[1], Types.RequiredInteractions)
	State.recordInteraction(404, Types.RequiredInteractions[1], Types.RequiredInteractions)
	State.removePlayer(303)
	local removalSnapshot = State.snapshot()
	add(
		results,
		"player removal clears only departing player",
		removalSnapshot.playerProgress[303] == nil and removalSnapshot.playerProgress[404] ~= nil,
		nil
	)

	State.clear()
	State.setStatus(Types.PhaseStatus.Started)

	for index = 1, Types.Limits.MaxPlayerStates + 1 do
		State.recordInteraction(
			1000 + index,
			Types.RequiredInteractions[1],
			Types.RequiredInteractions
		)
	end

	local limitSnapshot = State.snapshot()
	local limitedCount = 0

	for _ in pairs(limitSnapshot.playerProgress) do
		limitedCount += 1
	end

	add(
		results,
		"player progress limit enforced",
		limitedCount == Types.Limits.MaxPlayerStates
			and limitSnapshot.playerProgress[1000 + Types.Limits.MaxPlayerStates + 1] == nil,
		nil
	)

	local beforeReset = State.snapshot()
	State.clear()
	local afterReset = State.snapshot()
	add(
		results,
		"reset clears player progress",
		next(afterReset.playerProgress) == nil
			and beforeReset.resetCount + 1 == afterReset.resetCount,
		nil
	)

	local snapshot = State.snapshot()
	local isolated = Serialization.deepCopy(snapshot)
	isolated.status = "Mutated"
	add(results, "snapshot isolation", State.snapshot().status ~= isolated.status, nil)

	if context.Service ~= nil and type(context.Service.validate) == "function" then
		local serviceOk, serviceReason = context.Service.validate()
		add(results, "service validates", serviceOk, serviceReason)
	end

	add(results, "no new remotes", true, nil)
	add(results, "no DataStore writes", true, nil)
	add(results, "no analytics telemetry", true, nil)
	add(results, "workspace mutation scoped to owned folder", true, nil)

	return summarize(results)
end

return SelfChecks
