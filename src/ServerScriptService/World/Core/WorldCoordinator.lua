--!strict
--[[
	Phase 26 World Runtime Coordinator.

	Server-authoritative world schema foundation. It records districts, regions,
	buildings, floors, rooms, zones, connections, streaming schemas,
	classifications, and tags. It describes the world. It does not build, stream,
	load, teleport, move, pathfind, mutate Workspace, or create remotes.
]]

local ServerScriptService = game:GetService("ServerScriptService")

local Core = ServerScriptService.Core
local Diagnostics = require(Core.Diagnostics)
local EventBus = require(Core.EventBus)
local Logger = require(Core.Logger)
local SnapshotManager = require(Core.SnapshotManager)

local BuildingRuntime = require(script.Parent.WorldBuildingRuntime)
local ClassificationRuntime = require(script.Parent.WorldClassificationRuntime)
local ConnectionRuntime = require(script.Parent.WorldConnectionRuntime)
local DistrictRuntime = require(script.Parent.WorldDistrictRuntime)
local FloorRuntime = require(script.Parent.WorldFloorRuntime)
local RegionRuntime = require(script.Parent.WorldRegionRuntime)
local RoomRuntime = require(script.Parent.WorldRoomRuntime)
local SelfChecks = require(script.Parent.WorldSelfChecks)
local Serialization = require(script.Parent.WorldSerialization)
local Signals = require(script.Parent.WorldSignals)
local Snapshots = require(script.Parent.WorldSnapshots)
local StreamingRuntime = require(script.Parent.WorldStreamingRuntime)
local TagRuntime = require(script.Parent.WorldTagRuntime)
local Types = require(script.Parent.WorldTypes)
local Validation = require(script.Parent.WorldValidation)
local WorldDiagnostics = require(script.Parent.WorldDiagnostics)
local ZoneRuntime = require(script.Parent.WorldZoneRuntime)

local WorldCoordinator = {}

local log = Logger.scope("WorldRuntime")
local initialized = false
local started = false
local lastSelfChecks: any = nil

local dependencies = {
	State = DistrictRuntime,
	Validation = Validation,
}

local function result(ok: boolean, code: string, message: string?, extra: any?)
	local payload = extra or {}
	payload.ok = ok
	payload.code = code
	payload.message = message
	return payload
end

local function codeFor(reason: string?): string
	if reason ~= nil and string.find(reason, "duplicate", 1, true) then
		return Types.ResultCode.DuplicateId
	elseif
		reason ~= nil
		and (
			string.find(reason, "payload", 1, true)
			or string.find(reason, "forbidden field", 1, true)
			or string.find(reason, "unsafe runtime", 1, true)
			or string.find(reason, "cyclic", 1, true)
		)
	then
		return Types.ResultCode.UnsafePayload
	end
	return Types.ResultCode.InvalidRequest
end

local function recordFailure(reason: string, payload: any?)
	DistrictRuntime.recordValidationFailure(reason, payload)
	EventBus.publishDeferred(Signals.ValidationFailed, { reason = reason })
end

local function register(
	kind: string,
	signal: string,
	runtime: any,
	schema: any,
	idField: string,
	successMessage: string
)
	local ok, reason = runtime.register(DistrictRuntime, schema)
	if not ok then
		recordFailure(reason or kind .. " schema rejected", schema)
		return result(false, codeFor(reason), reason)
	end
	EventBus.publishDeferred(signal, { [idField] = schema[idField] })
	return result(true, Types.ResultCode.Ok, successMessage)
end

function WorldCoordinator.registerDistrict(schema: any)
	local ok, reason = DistrictRuntime.register("districts", schema)
	if not ok then
		recordFailure(reason or "district schema rejected", schema)
		return result(false, codeFor(reason), reason)
	end
	EventBus.publishDeferred(Signals.DistrictRegistered, { districtId = schema.districtId })
	return result(true, Types.ResultCode.Ok, "district schema registered")
end

function WorldCoordinator.registerRegion(schema: any)
	return register(
		"region",
		Signals.RegionRegistered,
		RegionRuntime,
		schema,
		"regionId",
		"region schema registered"
	)
end

function WorldCoordinator.registerBuilding(schema: any)
	return register(
		"building",
		Signals.BuildingRegistered,
		BuildingRuntime,
		schema,
		"buildingId",
		"building schema registered"
	)
end

function WorldCoordinator.registerFloor(schema: any)
	return register(
		"floor",
		Signals.FloorRegistered,
		FloorRuntime,
		schema,
		"floorId",
		"floor schema registered"
	)
end

function WorldCoordinator.registerRoom(schema: any)
	return register(
		"room",
		Signals.RoomRegistered,
		RoomRuntime,
		schema,
		"roomId",
		"room schema registered"
	)
end

function WorldCoordinator.registerZone(schema: any)
	return register(
		"zone",
		Signals.ZoneRegistered,
		ZoneRuntime,
		schema,
		"zoneId",
		"zone schema registered"
	)
end

function WorldCoordinator.registerConnection(schema: any)
	return register(
		"connection",
		Signals.ConnectionRegistered,
		ConnectionRuntime,
		schema,
		"connectionId",
		"connection schema registered"
	)
end

function WorldCoordinator.registerStreamingRegion(schema: any)
	return register(
		"streaming region",
		Signals.StreamingRegionRegistered,
		StreamingRuntime,
		schema,
		"streamingRegionId",
		"streaming region schema registered"
	)
end

function WorldCoordinator.registerClassification(schema: any)
	return register(
		"classification",
		Signals.ClassificationRegistered,
		ClassificationRuntime,
		schema,
		"classificationId",
		"classification schema registered"
	)
end

function WorldCoordinator.registerTag(schema: any)
	return register(
		"tag",
		Signals.TagRegistered,
		TagRuntime,
		schema,
		"tagId",
		"world tag schema registered"
	)
end

function WorldCoordinator.initialize()
	if initialized then
		return
	end
	local valid, reason = WorldCoordinator.validate()
	if not valid then
		error("WorldCoordinator validation failed: " .. tostring(reason), 0)
	end
	Diagnostics.registerSampler("WorldRuntime", WorldCoordinator.inspect)
	SnapshotManager.registerProvider("worldRuntime", WorldCoordinator.getSnapshot)
	initialized = true
	log.success("World Runtime initialized")
end

function WorldCoordinator.start()
	if started then
		return
	end
	if not initialized then
		WorldCoordinator.initialize()
	end
	started = true
end

function WorldCoordinator.shutdown()
	DistrictRuntime.clear()
	started = false
	initialized = false
end

function WorldCoordinator.inspect()
	return WorldDiagnostics.capture({
		initialized = initialized,
		started = started,
		lastSelfChecks = lastSelfChecks,
	}, dependencies)
end

function WorldCoordinator.getSnapshot()
	local snapshot = Snapshots.capture(DistrictRuntime)
	EventBus.publishDeferred(
		Signals.SnapshotCaptured,
		{ snapshot = Serialization.deepCopy(snapshot) }
	)
	return snapshot
end

function WorldCoordinator.validate(): (boolean, string?)
	return WorldDiagnostics.validate(dependencies)
end

function WorldCoordinator.runSelfChecks()
	if started then
		lastSelfChecks = {
			ok = false,
			reason = "World Runtime self-checks are destructive and may only run before start.",
		}
		return lastSelfChecks
	end
	lastSelfChecks = SelfChecks.run({ Service = WorldCoordinator })
	return lastSelfChecks
end

return WorldCoordinator
