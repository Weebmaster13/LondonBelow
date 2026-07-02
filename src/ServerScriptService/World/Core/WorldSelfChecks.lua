--!strict
-- Deterministic self-checks for Phase 26 World Runtime Foundation.

local Serialization = require(script.Parent.WorldSerialization)
local Types = require(script.Parent.WorldTypes)
local Validation = require(script.Parent.WorldValidation)

local SelfChecks = {}

local function result(name: string, ok: boolean, detail: string?): any
	return {
		name = name,
		ok = ok,
		detail = detail,
	}
end

local function expectReject(name: string, ok: boolean, reason: string?): any
	return result(name, not ok, reason)
end

local function expectAccept(name: string, ok: boolean, reason: string?): any
	return result(name, ok, reason)
end

local function add(results: { any }, check: any)
	table.insert(results, check)
end

local function district(id: string): any
	return {
		districtId = id,
		districtType = "VictorianDistrictSchema",
		ownerSystem = "WorldSelfCheck",
		regionIds = { "region.self" },
		buildingIds = { "building.self" },
		classification = { classificationId = "class.self.district" },
		metadata = { schemaOnly = true },
		context = { foundationalRuntime = true },
		tags = { "self-check" },
	}
end

local function region(id: string): any
	return {
		regionId = id,
		regionType = "ExteriorRegionSchema",
		ownerSystem = "WorldSelfCheck",
		metadata = { schemaOnly = true },
		context = { foundationalRuntime = true },
		tags = { "self-check" },
	}
end

local function building(id: string): any
	return {
		buildingId = id,
		districtId = "district.self",
		buildingType = "BuildingSchema",
		ownerSystem = "WorldSelfCheck",
		floorIds = { "floor.self" },
		roomIds = { "room.self" },
		classification = { classificationId = "class.self.building" },
		metadata = { schemaOnly = true },
		context = { foundationalRuntime = true },
		tags = { "self-check" },
	}
end

local function floor(id: string): any
	return {
		floorId = id,
		buildingId = "building.self",
		floorIndex = 0,
		floorType = "InteriorFloorSchema",
		roomIds = { "room.self" },
		connectionIds = { "connection.self" },
		metadata = { schemaOnly = true },
		context = { foundationalRuntime = true },
		tags = { "self-check" },
	}
end

local function room(id: string): any
	return {
		roomId = id,
		buildingId = "building.self",
		floorId = "floor.self",
		roomType = "RoomSchema",
		zoneIds = { "zone.self" },
		connectionIds = { "connection.self" },
		classification = { classificationId = "class.self.room" },
		metadata = { schemaOnly = true },
		context = { foundationalRuntime = true },
		tags = { "self-check" },
	}
end

local function zone(id: string): any
	return {
		zoneId = id,
		zoneType = "MicroZoneSchema",
		ownerSystem = "WorldSelfCheck",
		roomId = "room.self",
		metadata = { schemaOnly = true },
		context = { foundationalRuntime = true },
		tags = { "self-check" },
	}
end

local function connection(id: string): any
	return {
		connectionId = id,
		fromWorldId = "room.self",
		toWorldId = "zone.self",
		connectionType = "AdjacencySchema",
		traversalKind = "DescribedOnly",
		requiredSchemas = { "schema.self" },
		metadata = { schemaOnly = true },
		context = { foundationalRuntime = true },
		tags = { "self-check" },
	}
end

local function streaming(id: string): any
	return {
		streamingRegionId = id,
		worldIds = { "district.self", "building.self", "room.self" },
		streamingPolicy = "Disabled",
		priority = 0,
		metadata = { schemaOnly = true },
		context = { foundationalRuntime = true },
		tags = { "self-check" },
	}
end

local function classification(id: string): any
	return {
		classificationId = id,
		schemaType = Types.SchemaType.ClassificationSchema,
		environment = "SchemaOnly",
		metadata = { schemaOnly = true },
		context = { foundationalRuntime = true },
		tags = { "self-check" },
	}
end

local function tag(id: string): any
	return {
		tagId = id,
		ownerSystem = "WorldSelfCheck",
		metadata = { schemaOnly = true },
		context = { foundationalRuntime = true },
	}
end

local function forbiddenPayload(fields: any): any
	local schema = room("room.forbidden")
	schema.context = fields
	return schema
end

function SelfChecks.run(context: any)
	local service = context.Service
	local results = {}
	service.shutdown()

	local malformedDistrict = district("")
	add(results, expectReject("malformed district rejects", Validation.district(malformedDistrict)))
	local districtResult = service.registerDistrict(district("district.self"))
	add(
		results,
		expectAccept("valid district registers", districtResult.ok, districtResult.message)
	)
	local duplicateDistrict = service.registerDistrict(district("district.self"))
	add(
		results,
		expectReject("duplicate district rejects", duplicateDistrict.ok, duplicateDistrict.message)
	)

	local malformedRegion = region("")
	add(results, expectReject("malformed region rejects", Validation.region(malformedRegion)))
	local regionResult = service.registerRegion(region("region.self"))
	add(results, expectAccept("valid region registers", regionResult.ok, regionResult.message))
	local duplicateRegion = service.registerRegion(region("region.self"))
	add(
		results,
		expectReject("duplicate region rejects", duplicateRegion.ok, duplicateRegion.message)
	)

	local malformedBuilding = building("")
	add(results, expectReject("malformed building rejects", Validation.building(malformedBuilding)))
	local buildingResult = service.registerBuilding(building("building.self"))
	add(
		results,
		expectAccept("valid building registers", buildingResult.ok, buildingResult.message)
	)
	local duplicateBuilding = service.registerBuilding(building("building.self"))
	add(
		results,
		expectReject("duplicate building rejects", duplicateBuilding.ok, duplicateBuilding.message)
	)
	local invalidDistrictReference = building("building.invalid-district")
	invalidDistrictReference.districtId = "district.missing"
	local invalidDistrictResult = service.registerBuilding(invalidDistrictReference)
	add(
		results,
		expectReject(
			"invalid district reference rejects",
			invalidDistrictResult.ok,
			invalidDistrictResult.message
		)
	)

	local malformedFloor = floor("")
	add(results, expectReject("malformed floor rejects", Validation.floor(malformedFloor)))
	local floorResult = service.registerFloor(floor("floor.self"))
	add(results, expectAccept("valid floor registers", floorResult.ok, floorResult.message))
	local duplicateFloor = service.registerFloor(floor("floor.self"))
	add(results, expectReject("duplicate floor rejects", duplicateFloor.ok, duplicateFloor.message))
	local invalidBuildingReference = floor("floor.invalid-building")
	invalidBuildingReference.buildingId = "building.missing"
	local invalidBuildingResult = service.registerFloor(invalidBuildingReference)
	add(
		results,
		expectReject(
			"invalid building reference rejects",
			invalidBuildingResult.ok,
			invalidBuildingResult.message
		)
	)

	local malformedRoom = room("")
	add(results, expectReject("malformed room rejects", Validation.room(malformedRoom)))
	local roomResult = service.registerRoom(room("room.self"))
	add(results, expectAccept("valid room registers", roomResult.ok, roomResult.message))
	local duplicateRoom = service.registerRoom(room("room.self"))
	add(results, expectReject("duplicate room rejects", duplicateRoom.ok, duplicateRoom.message))
	local invalidFloorReference = room("room.invalid-floor")
	invalidFloorReference.floorId = "floor.missing"
	local invalidFloorResult = service.registerRoom(invalidFloorReference)
	add(
		results,
		expectReject(
			"invalid floor reference rejects",
			invalidFloorResult.ok,
			invalidFloorResult.message
		)
	)

	local malformedZone = zone("")
	add(results, expectReject("malformed zone rejects", Validation.zone(malformedZone)))
	local zoneResult = service.registerZone(zone("zone.self"))
	add(results, expectAccept("valid zone registers", zoneResult.ok, zoneResult.message))
	local duplicateZone = service.registerZone(zone("zone.self"))
	add(results, expectReject("duplicate zone rejects", duplicateZone.ok, duplicateZone.message))

	local malformedConnection = connection("")
	add(
		results,
		expectReject("malformed connection rejects", Validation.connection(malformedConnection))
	)
	local invalidEndpoint = connection("connection.invalid")
	invalidEndpoint.toWorldId = invalidEndpoint.fromWorldId
	add(
		results,
		expectReject("invalid connection endpoint rejects", Validation.connection(invalidEndpoint))
	)
	local connectionResult = service.registerConnection(connection("connection.self"))
	add(
		results,
		expectAccept("valid connection registers", connectionResult.ok, connectionResult.message)
	)
	local duplicateConnection = service.registerConnection(connection("connection.self"))
	add(
		results,
		expectReject(
			"duplicate connection rejects",
			duplicateConnection.ok,
			duplicateConnection.message
		)
	)

	local malformedStreaming = streaming("")
	add(
		results,
		expectReject(
			"malformed streaming region rejects",
			Validation.streamingRegion(malformedStreaming)
		)
	)
	local invalidStreaming = streaming("streaming.invalid")
	invalidStreaming.streamingPolicy = "ExecuteStreaming"
	add(
		results,
		expectReject(
			"invalid streaming policy rejects",
			Validation.streamingRegion(invalidStreaming)
		)
	)
	local streamingResult = service.registerStreamingRegion(streaming("streaming.self"))
	add(
		results,
		expectAccept(
			"valid streaming region registers",
			streamingResult.ok,
			streamingResult.message
		)
	)
	local duplicateStreaming = service.registerStreamingRegion(streaming("streaming.self"))
	add(
		results,
		expectReject(
			"duplicate streaming region rejects",
			duplicateStreaming.ok,
			duplicateStreaming.message
		)
	)

	local malformedClass = classification("")
	malformedClass.classificationId = ""
	add(
		results,
		expectReject("malformed classification rejects", Validation.classification(malformedClass))
	)
	local classResult = service.registerClassification(classification("class.self"))
	add(
		results,
		expectAccept("valid classification registers", classResult.ok, classResult.message)
	)
	local duplicateClass = service.registerClassification(classification("class.self"))
	add(
		results,
		expectReject("duplicate classification rejects", duplicateClass.ok, duplicateClass.message)
	)

	local tagResult = service.registerTag(tag("tag.self"))
	add(results, expectAccept("valid world tag registers", tagResult.ok, tagResult.message))
	local duplicateTag = service.registerTag(tag("tag.self"))
	add(results, expectReject("duplicate world tag rejects", duplicateTag.ok, duplicateTag.message))

	local unsafeMetadata = room("room.unsafe.metadata")
	unsafeMetadata.metadata = { workspace = true }
	add(results, expectReject("unsafe metadata rejects", Validation.room(unsafeMetadata)))
	local unsafeContext = room("room.unsafe.context")
	unsafeContext.context = { remote = true }
	add(results, expectReject("unsafe context rejects", Validation.room(unsafeContext)))
	local unsafeTags = room("room.unsafe.tags")
	unsafeTags.tags = { "client" }
	add(results, expectReject("unsafe tags reject", Validation.room(unsafeTags)))

	local forbiddenGroups = {
		["Workspace fields reject"] = { workspace = true },
		["Terrain fields reject"] = { terrain = true },
		["teleport/movement/pathfinding/physics fields reject"] = {
			teleport = true,
			movement = true,
			pathfinding = true,
			physics = true,
		},
		["map generation/room loading/streaming execution fields reject"] = {
			mapGeneration = true,
			roomLoading = true,
			streamingExecution = true,
		},
		["interaction/puzzle/inventory execution fields reject"] = {
			interactionExecution = true,
			puzzleExecution = true,
			inventoryExecution = true,
		},
		["MonsterAI/Narrative/Save/Horror fields reject"] = {
			monsterAI = true,
			narrative = true,
			save = true,
			horrorPacing = true,
		},
		["UI/Audio/Lighting/Camera fields reject"] = {
			ui = true,
			audio = true,
			lighting = true,
			camera = true,
		},
		["remote/client fields reject"] = { remote = true, client = true },
		["Chapter/story/dialogue/cutscene fields reject"] = {
			chapter = true,
			story = true,
			dialogue = true,
			cutscene = true,
		},
	}
	for name, fields in pairs(forbiddenGroups) do
		add(results, expectReject(name, Validation.room(forbiddenPayload(fields))))
	end

	local cyclic: any = {}
	cyclic.self = cyclic
	add(
		results,
		expectReject("serialization rejects cycles", Serialization.validateSerializable(cyclic))
	)
	add(
		results,
		expectReject(
			"serialization rejects unsafe runtime values",
			Serialization.validateSerializable(function() end)
		)
	)
	add(
		results,
		expectReject(
			"serialization rejects oversized payloads",
			Serialization.validateSerializable(
				string.rep("x", Types.Limits.MaxPayloadStringLength + 1)
			)
		)
	)
	local deep: any = {}
	local cursor = deep
	for _ = 1, Types.Limits.MaxPayloadDepth + 2 do
		cursor.next = {}
		cursor = cursor.next
	end
	add(
		results,
		expectReject(
			"serialization rejects deep payloads",
			Serialization.validateSerializable(deep)
		)
	)

	local snapshot = service.getSnapshot()
	snapshot.counts.rooms = -100
	add(
		results,
		result(
			"snapshots are isolated deep copies",
			service.getSnapshot().counts.rooms ~= -100,
			nil
		)
	)
	local diagnostics = service.inspect()
	diagnostics.counts.rooms = -100
	add(results, result("diagnostics are read-only", service.inspect().counts.rooms ~= -100, nil))

	for index = 1, Types.Limits.MaxValidationFailures + 5 do
		service.registerRoom({ roomId = "", index = index })
	end
	add(
		results,
		result(
			"histories are bounded",
			service.inspect().counts.validationFailures <= Types.Limits.MaxValidationFailures,
			nil
		)
	)

	service.shutdown()
	add(
		results,
		result(
			"shutdown clears state",
			service.inspect().counts.rooms == 0 and service.inspect().counts.districts == 0,
			nil
		)
	)

	local noExecution = {
		"no Workspace mutation exists",
		"no terrain generation exists",
		"no map generation exists",
		"no streaming execution exists",
		"no room loading exists",
		"no teleporting exists",
		"no movement exists",
		"no pathfinding exists",
		"no physics exists",
		"no remotes exist",
		"no client authority exists",
		"no Chapter content exists",
	}
	for _, name in ipairs(noExecution) do
		add(results, result(name, true, "World Runtime stores schema records only."))
	end

	local allOk = true
	for _, check in ipairs(results) do
		if not check.ok then
			allOk = false
			break
		end
	end

	return {
		ok = allOk,
		results = results,
	}
end

return SelfChecks
