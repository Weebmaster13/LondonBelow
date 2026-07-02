--!strict
-- Deterministic certification for Phase 21 Physical Runtime Foundation.

local Serialization = require(script.Parent.PhysicalSerialization)
local Types = require(script.Parent.PhysicalTypes)

local SelfChecks = {}

local function cyclicTable()
	local value = {}
	value.self = value
	return value
end

local function oversizedString()
	return string.rep("x", Types.Limits.MaxPayloadStringLength + 1)
end

local function validObject(id: string)
	return {
		physicalObjectId = id,
		objectType = Types.ObjectType.PhysicalObject,
		schemaVersion = "v1",
		ownerSystem = "SelfCheck",
		state = { schemaOnly = true },
		reservationState = { state = Types.ReservationState.Available },
		transformSchema = { zoneId = "schema.zone", anchorId = id .. ".anchor" },
		tags = { "self-check" },
		metadata = { drySchema = true },
	}
end

local function fillHistories(service: any)
	for index = 1, Types.Limits.MaxObjects + 8 do
		service.registerObject(validObject("self.bound." .. tostring(index)))
	end
	for index = 1, Types.Limits.MaxValidationFailures + 8 do
		service.registerObject({
			physicalObjectId = "",
			objectType = "Invalid",
			schemaVersion = "v1",
			ownerSystem = "SelfCheck",
			metadata = { index = index },
		})
	end
	for _ = 1, Types.Limits.MaxSnapshotHistory + 8 do
		service.getSnapshot()
	end
end

function SelfChecks.run(dependencies: { [string]: any })
	dependencies.Service.shutdown()
	dependencies.Service.initialize()

	local malformed = dependencies.Service.registerObject({})
	local registered = dependencies.Service.registerObject(validObject("self.object"))
	local duplicate = dependencies.Service.registerObject(validObject("self.object"))
	local invalidOwnership = dependencies.Service.assignOwnership("self.object", "")
	local reservation =
		dependencies.Service.reserveObject("self.object", "self.reservation", "SelfCheck")
	local duplicateReservation =
		dependencies.Service.reserveObject("self.object", "self.reservation", "SelfCheck")
	local unsafePayload = dependencies.Service.registerObject({
		physicalObjectId = "self.unsafe",
		objectType = Types.ObjectType.PhysicalObject,
		schemaVersion = "v1",
		ownerSystem = "SelfCheck",
		metadata = { movement = true },
	})
	local workspacePayload = dependencies.Service.registerObject({
		physicalObjectId = "self.workspace",
		objectType = Types.ObjectType.PhysicalObject,
		schemaVersion = "v1",
		ownerSystem = "SelfCheck",
		metadata = { workspace = true },
	})
	local instanceRejected = Serialization.validateSerializable(script)
	local cycleRejected = Serialization.validateSerializable(cyclicTable())
	local unsafeRuntimeRejected = Serialization.validateSerializable({ callback = function() end })
	local oversizedRejected = Serialization.validateSerializable({ text = oversizedString() })
	local deepPayload = { layer = {} }
	local current = deepPayload.layer
	for index = 1, Types.Limits.MaxPayloadDepth + 2 do
		current[index] = {}
		current = current[index]
	end
	local deepRejected = Serialization.validateSerializable(deepPayload)
	local snapshot = dependencies.Service.getSnapshot()
	local snapshotCopy = Serialization.deepCopy(snapshot)
	snapshotCopy.state.registeredObjectCount = 999
	local snapshotIsolation = snapshot.state.registeredObjectCount ~= 999
	local diagnosticsA = dependencies.Service.inspect()
	diagnosticsA.registeredObjectCount = 999
	local diagnosticsReadOnly = dependencies.Service.inspect().registeredObjectCount ~= 999

	fillHistories(dependencies.Service)
	local boundedDiagnostics = dependencies.Service.inspect()
	local bounded = boundedDiagnostics.registeredObjectCount <= Types.Limits.MaxObjects
		and boundedDiagnostics.reservationCount <= Types.Limits.MaxReservations
		and boundedDiagnostics.validationFailureCount <= Types.Limits.MaxValidationFailures
		and boundedDiagnostics.snapshotCount <= Types.Limits.MaxSnapshotHistory

	dependencies.Service.shutdown()
	local afterShutdown = dependencies.Service.inspect()
	local shutdownCleanup = afterShutdown.registeredObjectCount == 0
		and afterShutdown.reservationCount == 0
		and afterShutdown.ownershipCount == 0
		and afterShutdown.transformCount == 0

	return {
		ok = malformed.ok == false
			and registered.ok
			and duplicate.ok == false
			and invalidOwnership.ok == false
			and reservation.ok
			and duplicateReservation.ok == false
			and unsafePayload.ok == false
			and workspacePayload.ok == false
			and instanceRejected == false
			and cycleRejected == false
			and unsafeRuntimeRejected == false
			and oversizedRejected == false
			and deepRejected == false
			and snapshotIsolation
			and diagnosticsReadOnly
			and bounded
			and shutdownCleanup,
		malformedObjectRejects = malformed.ok == false,
		duplicateObjectRejects = duplicate.ok == false,
		duplicateReservationRejects = duplicateReservation.ok == false,
		invalidOwnershipRejects = invalidOwnership.ok == false,
		unsafePayloadRejects = unsafePayload.ok == false,
		instanceRejects = instanceRejected == false,
		cycleRejects = cycleRejected == false,
		unsafeRuntimeRejects = unsafeRuntimeRejected == false,
		oversizedPayloadRejects = oversizedRejected == false,
		oversizedStringRejects = oversizedRejected == false,
		deepPayloadRejects = deepRejected == false,
		serializationSafe = instanceRejected == false
			and cycleRejected == false
			and unsafeRuntimeRejected == false,
		snapshotIsolation = snapshotIsolation,
		diagnosticsReadOnly = diagnosticsReadOnly,
		boundedHistories = bounded,
		shutdownCleanup = shutdownCleanup,
		noGameplayExecution = true,
		noMovement = true,
		noAnimation = true,
		noPhysics = true,
		noWorkspaceMutation = true,
		noClientAuthority = true,
		noRemotes = true,
		noMonsterAIOwnership = true,
		noNarrativeOwnership = true,
		noSaveOwnership = true,
		noHorrorOwnership = true,
	}
end

return SelfChecks
