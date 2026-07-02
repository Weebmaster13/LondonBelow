--!strict
-- Shared constants for Phase 21 Physical Runtime Foundation.

local Types = {}

Types.Mode = "ServerAuthoritativePhysicalSchemaRuntime"

Types.ObjectType = {
	PhysicalObject = "PhysicalObject",
	DoorPhysicalSchema = "DoorPhysicalSchema",
	DrawerPhysicalSchema = "DrawerPhysicalSchema",
	ElevatorPhysicalSchema = "ElevatorPhysicalSchema",
	PuzzlePhysicalSchema = "PuzzlePhysicalSchema",
	InteractablePhysicalSchema = "InteractablePhysicalSchema",
	PropPhysicalSchema = "PropPhysicalSchema",
	EnvironmentPhysicalSchema = "EnvironmentPhysicalSchema",
	HidingSpotPhysicalSchema = "HidingSpotPhysicalSchema",
}

Types.LifecycleState = {
	Registered = "Registered",
	Active = "Active",
	Suspended = "Suspended",
	Removed = "Removed",
}

Types.ReservationState = {
	Available = "Available",
	Reserved = "Reserved",
	Locked = "Locked",
}

Types.ResultCode = {
	Ok = "Ok",
	InvalidRequest = "InvalidRequest",
	DuplicateObject = "DuplicateObject",
	UnknownObject = "UnknownObject",
	DuplicateReservation = "DuplicateReservation",
	InvalidOwnership = "InvalidOwnership",
	UnsafePayload = "UnsafePayload",
}

Types.Limits = {
	MaxObjects = 500,
	MaxReservations = 260,
	MaxOwnershipRecords = 500,
	MaxTransforms = 500,
	MaxValidationFailures = 180,
	MaxSnapshotHistory = 80,
	MaxPayloadDepth = 8,
	MaxPayloadNodes = 260,
	MaxPayloadStringLength = 512,
	MaxTags = 24,
}

return Types
