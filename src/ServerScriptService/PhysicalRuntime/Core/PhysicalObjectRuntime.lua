--!strict
-- Bounded state store for server-owned physical object schemas.

local Serialization = require(script.Parent.PhysicalSerialization)
local Types = require(script.Parent.PhysicalTypes)

local ObjectRuntime = {}

local objects: { [string]: any } = {}
local objectOrder: { string } = {}
local ownership: { [string]: any } = {}
local reservations: { [string]: any } = {}
local reservationOrder: { string } = {}
local transforms: { [string]: any } = {}
local validationFailures: { any } = {}
local snapshotHistory: { any } = {}

local function trimMap(order: { string }, map: { [string]: any }, limit: number)
	while #order > limit do
		local id = table.remove(order, 1)
		if id ~= nil then
			map[id] = nil
		end
	end
end

local function countMap(map: { [string]: any }): number
	local count = 0
	for _ in pairs(map) do
		count += 1
	end
	return count
end

local function removeFromOrder(order: { string }, id: string)
	for index = #order, 1, -1 do
		if order[index] == id then
			table.remove(order, index)
		end
	end
end

local function trimList(list: { any }, limit: number)
	while #list > limit do
		table.remove(list, 1)
	end
end

local function removeObjectRecords(objectId: string)
	objects[objectId] = nil
	ownership[objectId] = nil
	transforms[objectId] = nil
	for reservationId, reservation in pairs(reservations) do
		if reservation.physicalObjectId == objectId then
			reservations[reservationId] = nil
			removeFromOrder(reservationOrder, reservationId)
		end
	end
end

local function trimObjects()
	while #objectOrder > Types.Limits.MaxObjects do
		local id = table.remove(objectOrder, 1)
		if id ~= nil then
			removeObjectRecords(id)
		end
	end
end

function ObjectRuntime.exists(objectId: string): boolean
	return objects[objectId] ~= nil
end

function ObjectRuntime.add(schema: any)
	objects[schema.physicalObjectId] = Serialization.deepCopy(schema)
	table.insert(objectOrder, schema.physicalObjectId)
	ownership[schema.physicalObjectId] = {
		physicalObjectId = schema.physicalObjectId,
		ownerSystem = schema.ownerSystem,
		updatedAt = os.clock(),
	}
	transforms[schema.physicalObjectId] = Serialization.deepCopy(schema.transformSchema or {})
	trimObjects()
end

function ObjectRuntime.remove(objectId: string)
	removeObjectRecords(objectId)
	removeFromOrder(objectOrder, objectId)
end

function ObjectRuntime.setOwnership(objectId: string, ownerSystem: string)
	ownership[objectId] = {
		physicalObjectId = objectId,
		ownerSystem = ownerSystem,
		updatedAt = os.clock(),
	}
end

function ObjectRuntime.addReservation(objectId: string, reservationId: string, ownerSystem: string)
	reservations[reservationId] = {
		reservationId = reservationId,
		physicalObjectId = objectId,
		ownerSystem = ownerSystem,
		state = Types.ReservationState.Reserved,
		createdAt = os.clock(),
	}
	table.insert(reservationOrder, reservationId)
	trimMap(reservationOrder, reservations, Types.Limits.MaxReservations)
end

function ObjectRuntime.hasReservation(reservationId: string): boolean
	return reservations[reservationId] ~= nil
end

function ObjectRuntime.releaseReservation(reservationId: string)
	if reservations[reservationId] ~= nil then
		reservations[reservationId].state = Types.ReservationState.Available
		reservations[reservationId].releasedAt = os.clock()
	end
end

function ObjectRuntime.setState(objectId: string, state: any)
	if objects[objectId] ~= nil then
		objects[objectId].state = Serialization.deepCopy(state)
		objects[objectId].stateUpdatedAt = os.clock()
	end
end

function ObjectRuntime.setLifecycle(objectId: string, lifecycleState: string)
	if objects[objectId] ~= nil then
		objects[objectId].lifecycleState = lifecycleState
		objects[objectId].lifecycleUpdatedAt = os.clock()
	end
end

function ObjectRuntime.setTransform(objectId: string, transformSchema: any)
	transforms[objectId] = Serialization.deepCopy(transformSchema)
	if objects[objectId] ~= nil then
		objects[objectId].transformSchema = Serialization.deepCopy(transformSchema)
	end
end

function ObjectRuntime.recordValidationFailure(reason: string, payload: any?)
	table.insert(validationFailures, {
		reason = reason,
		payload = Serialization.diagnosticCopy(payload),
		createdAt = os.clock(),
	})
	trimList(validationFailures, Types.Limits.MaxValidationFailures)
end

function ObjectRuntime.recordSnapshot(summary: any)
	table.insert(snapshotHistory, Serialization.deepCopy(summary))
	trimList(snapshotHistory, Types.Limits.MaxSnapshotHistory)
end

function ObjectRuntime.inspect()
	return {
		registeredObjectCount = countMap(objects),
		reservationCount = countMap(reservations),
		ownershipCount = countMap(ownership),
		transformCount = countMap(transforms),
		objects = Serialization.deepCopy(objects),
		ownership = Serialization.deepCopy(ownership),
		reservations = Serialization.deepCopy(reservations),
		transforms = Serialization.deepCopy(transforms),
		validationFailureCount = #validationFailures,
		validationFailures = Serialization.deepCopy(validationFailures),
		snapshotCount = #snapshotHistory,
		snapshotHistory = Serialization.deepCopy(snapshotHistory),
		limits = Serialization.deepCopy(Types.Limits),
	}
end

function ObjectRuntime.clear()
	table.clear(objects)
	table.clear(objectOrder)
	table.clear(ownership)
	table.clear(reservations)
	table.clear(reservationOrder)
	table.clear(transforms)
	table.clear(validationFailures)
	table.clear(snapshotHistory)
end

return ObjectRuntime
