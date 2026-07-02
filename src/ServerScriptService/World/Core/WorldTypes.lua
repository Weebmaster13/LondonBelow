--!strict
-- Shared constants for Phase 26 World Runtime Foundation.

local Types = {}

Types.Mode = "ServerAuthoritativeWorldSchemaRuntime"

Types.SchemaType = {
	DistrictSchema = "DistrictSchema",
	RegionSchema = "RegionSchema",
	BuildingSchema = "BuildingSchema",
	FloorSchema = "FloorSchema",
	RoomSchema = "RoomSchema",
	ZoneSchema = "ZoneSchema",
	ConnectionSchema = "ConnectionSchema",
	StreamingRegionSchema = "StreamingRegionSchema",
	ClassificationSchema = "ClassificationSchema",
	WorldTagSchema = "WorldTagSchema",
	SystemWorldSchema = "SystemWorldSchema",
}

Types.ResultCode = {
	Ok = "Ok",
	InvalidRequest = "InvalidRequest",
	DuplicateId = "DuplicateId",
	UnsafePayload = "UnsafePayload",
	UnknownReference = "UnknownReference",
}

Types.Limits = {
	MaxDistricts = 120,
	MaxRegions = 260,
	MaxBuildings = 360,
	MaxFloors = 700,
	MaxRooms = 1800,
	MaxZones = 3200,
	MaxConnections = 3600,
	MaxStreamingRegions = 420,
	MaxClassifications = 260,
	MaxTags = 64,
	MaxRefsPerSchema = 240,
	MaxValidationFailures = 220,
	MaxSnapshotHistory = 80,
	MaxPayloadDepth = 9,
	MaxPayloadNodes = 360,
	MaxPayloadStringLength = 640,
}

return Types
