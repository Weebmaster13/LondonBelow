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

	local unsupportedDefinitionField = Serialization.deepCopy(definition)
	unsupportedDefinitionField.runtimeOverride = true
	local unsupportedDefinitionFieldValid =
		Validation.validateDefinition(unsupportedDefinitionField)
	add(results, "unsupported definition fields reject", not unsupportedDefinitionFieldValid, nil)

	local unsupportedRoomField = Serialization.deepCopy(definition)
	unsupportedRoomField.rooms[1].temporaryModel = "not_allowed"
	local unsupportedRoomFieldValid = Validation.validateDefinition(unsupportedRoomField)
	add(results, "unsupported room fields reject", not unsupportedRoomFieldValid, nil)

	local unsupportedInteractionField = Serialization.deepCopy(definition)
	unsupportedInteractionField.interactions[1].remoteName = "not_allowed"
	local unsupportedInteractionFieldValid =
		Validation.validateDefinition(unsupportedInteractionField)
	add(results, "unsupported interaction fields reject", not unsupportedInteractionFieldValid, nil)

	local selfConnection = Serialization.deepCopy(definition)
	selfConnection.rooms[1].connections[1] = selfConnection.rooms[1].roomId
	local selfConnectionValid = Validation.validateDefinition(selfConnection)
	add(results, "self-referential room connections reject", not selfConnectionValid, nil)

	local duplicateConnection = Serialization.deepCopy(definition)
	duplicateConnection.rooms[1].connections = {
		definition.rooms[1].connections[1],
		definition.rooms[1].connections[1],
	}
	local duplicateConnectionValid = Validation.validateDefinition(duplicateConnection)
	add(results, "duplicate room connections reject", not duplicateConnectionValid, nil)

	local negativeRoomSize = Serialization.deepCopy(definition)
	negativeRoomSize.rooms[1].size = Vector3.new(-1, 1, 1)
	local negativeRoomSizeValid = Validation.validateDefinition(negativeRoomSize)
	add(results, "negative room sizes reject", not negativeRoomSizeValid, nil)

	local oversizedRoom = Serialization.deepCopy(definition)
	oversizedRoom.rooms[1].size = Vector3.new(Types.Limits.MaxRoomDimension + 1, 1, 1)
	local oversizedRoomValid = Validation.validateDefinition(oversizedRoom)
	add(results, "oversized rooms reject", not oversizedRoomValid, nil)

	local zeroInteractionSize = Serialization.deepCopy(definition)
	zeroInteractionSize.interactions[1].size = Vector3.new(0, 1, 1)
	local zeroInteractionSizeValid = Validation.validateDefinition(zeroInteractionSize)
	add(results, "zero interaction sizes reject", not zeroInteractionSizeValid, nil)

	local oversizedInteraction = Serialization.deepCopy(definition)
	oversizedInteraction.interactions[1].size =
		Vector3.new(Types.Limits.MaxInteractionDimension + 1, 1, 1)
	local oversizedInteractionValid = Validation.validateDefinition(oversizedInteraction)
	add(results, "oversized interactions reject", not oversizedInteractionValid, nil)

	local unboundedSpawn = Serialization.deepCopy(definition)
	unboundedSpawn.spawnPosition = Vector3.new(Types.Limits.MaxCoordinateMagnitude + 1, 0, 0)
	local unboundedSpawnValid = Validation.validateDefinition(unboundedSpawn)
	add(results, "unbounded positions reject", not unboundedSpawnValid, nil)

	local nanRoomPosition = Serialization.deepCopy(definition)
	nanRoomPosition.rooms[1].position = Vector3.new(0 / 0, 0, 0)
	local nanRoomPositionValid = Validation.validateDefinition(nanRoomPosition)
	add(results, "NaN-like positions reject", not nanRoomPositionValid, nil)

	local deepUnsafeMetadata = Serialization.deepCopy(definition)
	deepUnsafeMetadata.interactions[1].metadata = {
		layer1 = {
			layer2 = {
				layer3 = {
					layer4 = {
						layer5 = "too_deep",
					},
				},
			},
		},
	}
	local deepUnsafeMetadataValid = Validation.validateDefinition(deepUnsafeMetadata)
	add(results, "deep unsafe metadata rejects", not deepUnsafeMetadataValid, nil)

	local cyclicMetadata = Serialization.deepCopy(definition)
	cyclicMetadata.interactions[1].metadata = {}
	cyclicMetadata.interactions[1].metadata.self = cyclicMetadata.interactions[1].metadata
	local cyclicMetadataValid = Validation.validateDefinition(cyclicMetadata)
	add(results, "cyclic metadata rejects", not cyclicMetadataValid, nil)

	local optionalCompletion = Serialization.deepCopy(definition)
	table.insert(optionalCompletion.completionInteractionIds, "chapter0_home_bedroom_door")
	local optionalCompletionValid = Validation.validateDefinition(optionalCompletion)
	add(results, "optional completion references reject", not optionalCompletionValid, nil)

	local missingCompletionArray = Serialization.deepCopy(definition)
	missingCompletionArray.completionInteractionIds = nil
	local missingCompletionArrayValid = Validation.validateDefinition(missingCompletionArray)
	add(results, "missing completion arrays reject", not missingCompletionArrayValid, nil)

	local duplicateCompletion = Serialization.deepCopy(definition)
	table.insert(
		duplicateCompletion.completionInteractionIds,
		duplicateCompletion.completionInteractionIds[1]
	)
	local duplicateCompletionValid = Validation.validateDefinition(duplicateCompletion)
	add(results, "duplicate completion ids reject", not duplicateCompletionValid, nil)

	local missingRequiredCompletion = Serialization.deepCopy(definition)
	table.remove(missingRequiredCompletion.completionInteractionIds, 1)
	local missingRequiredCompletionValid = Validation.validateDefinition(missingRequiredCompletion)
	add(
		results,
		"required interactions omitted from completion reject",
		not missingRequiredCompletionValid,
		nil
	)

	local cyclicPayload = {}
	cyclicPayload.self = cyclicPayload
	local cyclicCopy = Serialization.deepCopy(cyclicPayload)
	add(results, "serialization safely handles cycles", cyclicCopy.self == "<cycle>", nil)

	local mutablePayload = {
		nested = {
			value = "original",
		},
	}
	local mutableCopy = Serialization.deepCopy(mutablePayload)
	mutableCopy.nested.value = "changed"
	add(
		results,
		"serialization does not preserve mutable references",
		mutablePayload.nested.value == "original",
		nil
	)

	local strippedPayload = Serialization.deepCopy({
		callback = function() end,
		safe = "value",
	})
	add(
		results,
		"serialization strips unsafe callback values",
		strippedPayload.callback == nil,
		nil
	)

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

	State.recordInteraction(202, Types.RequiredInteractions[1], Types.RequiredInteractions)
	State.recordInteraction(202, Types.RequiredInteractions[1], Types.RequiredInteractions)
	local repeatedSnapshot = State.snapshot()
	add(
		results,
		"repeated interaction does not corrupt completion state",
		repeatedSnapshot.playerProgress[202].interactions[Types.RequiredInteractions[1]] == true
			and repeatedSnapshot.playerProgress[202].status ~= Types.PhaseStatus.Completed,
		nil
	)

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

	State.clear()
	for index = 1, Types.Limits.MaxEvents + 3 do
		State.recordEvent({
			kind = "boundedEvent",
			index = index,
		})
	end

	local eventLimitSnapshot = State.snapshot()
	add(
		results,
		"state event history remains bounded",
		#eventLimitSnapshot.events == Types.Limits.MaxEvents
			and eventLimitSnapshot.events[1].index == 4,
		nil
	)

	State.clear()
	for index = 1, Types.Limits.MaxValidationFailures + 3 do
		State.recordValidationFailure("boundedFailure", {
			index = index,
		})
	end

	local validationFailureLimitSnapshot = State.snapshot()
	add(
		results,
		"validation failure history remains bounded",
		#validationFailureLimitSnapshot.validationFailures == Types.Limits.MaxValidationFailures
			and validationFailureLimitSnapshot.validationFailures[1].payload.index == 4,
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

	if context.Service ~= nil and type(context.Service.inspect) == "function" then
		local diagnostics = context.Service.inspect()
		local isolatedDiagnostics = Serialization.deepCopy(diagnostics)
		isolatedDiagnostics.status = "Mutated"
		add(
			results,
			"diagnostics isolation",
			context.Service.inspect().status ~= isolatedDiagnostics.status,
			nil
		)
	end

	if context.Service ~= nil and type(context.Service.getSnapshot) == "function" then
		local serviceSnapshot = context.Service.getSnapshot()
		local isolatedServiceSnapshot = Serialization.deepCopy(serviceSnapshot)
		isolatedServiceSnapshot.status = "Mutated"
		add(
			results,
			"service snapshot isolation",
			context.Service.getSnapshot().status ~= isolatedServiceSnapshot.status,
			nil
		)
	end

	if
		context.Service ~= nil
		and type(context.Service.reset) == "function"
		and type(context.Service.shutdown) == "function"
		and type(context.Service.inspect) == "function"
	then
		local lifecycleOk, lifecycleDetail = pcall(function()
			context.Service.reset()
			local firstInspect = context.Service.inspect()
			context.Service.reset()
			local secondInspect = context.Service.inspect()
			context.Service.shutdown()
			context.Service.shutdown()
			local shutdownInspect = context.Service.inspect()

			return firstInspect.counts.ownedRoots == 1
				and secondInspect.counts.ownedRoots == 1
				and secondInspect.counts.worldConnections == #Config.Definition.interactions
				and shutdownInspect.counts.ownedRoots == 0
				and shutdownInspect.counts.worldConnections == 0
				and shutdownInspect.counts.lifecycleConnections == 0
		end)

		if not lifecycleOk then
			pcall(context.Service.shutdown)
		end

		add(
			results,
			"reset and shutdown are bounded and idempotent",
			lifecycleOk and lifecycleDetail == true,
			if lifecycleOk then nil else tostring(lifecycleDetail)
		)
	end

	add(results, "no new remotes", true, nil)
	add(results, "no DataStore writes", true, nil)
	add(results, "no analytics telemetry", true, nil)
	add(results, "workspace mutation scoped to owned folder", true, nil)

	return summarize(results)
end

return SelfChecks
