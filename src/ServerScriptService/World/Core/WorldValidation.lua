--!strict
-- Validation boundary for server-owned world structure schemas.

local Serialization = require(script.Parent.WorldSerialization)
local Types = require(script.Parent.WorldTypes)

local Validation = {}

local FORBIDDEN_FIELDS = {
	"animation",
	"audio",
	"camera",
	"chapter",
	"chapter0",
	"chapter1",
	"cframe",
	"client",
	"cutscene",
	"dialogue",
	"execute",
	"gameplayExecution",
	"generateMap",
	"horrorPacing",
	"instance",
	"interactionExecution",
	"inventoryExecution",
	"lighting",
	"loadRoom",
	"mapGeneration",
	"monsterAI",
	"movement",
	"narrative",
	"pathfinding",
	"physics",
	"puzzleExecution",
	"remote",
	"roomLoading",
	"save",
	"streamRooms",
	"streamingExecution",
	"story",
	"teleport",
	"terrain",
	"ui",
	"workspace",
}

local FORBIDDEN_LOOKUP: { [string]: boolean } = {}

for _, field in ipairs(FORBIDDEN_FIELDS) do
	FORBIDDEN_LOOKUP[string.lower(field)] = true
end

local STREAMING_POLICIES = {
	Manual = true,
	PreloadHint = true,
	AlwaysDescribed = true,
	Disabled = true,
}

local function validId(value: any): boolean
	return type(value) == "string"
		and value ~= ""
		and #value <= 150
		and string.match(value, "^[%w%._%-:]+$") ~= nil
end

local function refList(value: any, fieldName: string): (boolean, string?)
	if value == nil then
		return true, nil
	end
	if type(value) ~= "table" then
		return false, fieldName .. " must be a table"
	end
	if #value > Types.Limits.MaxRefsPerSchema then
		return false, fieldName .. " exceeds reference limit"
	end
	local seen: { [string]: boolean } = {}
	for _, id in ipairs(value) do
		if not validId(id) then
			return false, fieldName .. " contains invalid id"
		end
		if seen[id] == true then
			return false, fieldName .. " contains duplicate id"
		end
		seen[id] = true
	end
	return true, nil
end

local function forbidden(payload: any, depth: number): (boolean, string?)
	if type(payload) ~= "table" then
		return true, nil
	end
	if depth > Types.Limits.MaxPayloadDepth then
		return false, "world payload depth exceeds limit"
	end
	for key in pairs(payload) do
		if type(key) == "string" and FORBIDDEN_LOOKUP[string.lower(key)] == true then
			return false, "world payload contains forbidden field: " .. key
		end
	end
	for _, nested in pairs(payload) do
		local ok, reason = forbidden(nested, depth + 1)
		if not ok then
			return false, reason
		end
	end
	return true, nil
end

local function supportedSchemaType(value: any): boolean
	for _, schemaType in pairs(Types.SchemaType) do
		if value == schemaType then
			return true
		end
	end
	return false
end

local function safeTags(tags: any): (boolean, string?)
	if tags == nil then
		return true, nil
	end
	if type(tags) ~= "table" then
		return false, "tags must be a table"
	end
	if #tags > Types.Limits.MaxTags then
		return false, "tag count exceeds limit"
	end
	for _, tag in ipairs(tags) do
		if not validId(tag) then
			return false, "tag is invalid"
		end
		if FORBIDDEN_LOOKUP[string.lower(tag)] == true then
			return false, "tag uses forbidden ownership domain: " .. tag
		end
	end
	return true, nil
end

function Validation.safePayload(payload: any): (boolean, string?)
	local ok, reason = Serialization.validateSerializable(payload)
	if not ok then
		return false, reason
	end
	return forbidden(payload, 0)
end

function Validation.id(value: any): boolean
	return validId(value)
end

function Validation.tags(tags: any): (boolean, string?)
	return safeTags(tags)
end

function Validation.classification(classification: any): (boolean, string?)
	if type(classification) ~= "table" then
		return false, "classification must be a table"
	end
	local ok, reason = Validation.safePayload(classification)
	if not ok then
		return false, reason
	end
	if not validId(classification.classificationId) then
		return false, "classificationId is invalid"
	end
	if classification.schemaType ~= nil and not supportedSchemaType(classification.schemaType) then
		return false, "unsupported classification schema type"
	end
	return true, nil
end

function Validation.district(schema: any): (boolean, string?)
	if type(schema) ~= "table" then
		return false, "district schema must be a table"
	end
	local ok, reason = Validation.safePayload(schema)
	if not ok then
		return false, reason
	end
	if
		not validId(schema.districtId)
		or not validId(schema.districtType)
		or not validId(schema.ownerSystem)
	then
		return false, "district identity fields are invalid"
	end
	local refsOk, refsReason = refList(schema.regionIds, "regionIds")
	if not refsOk then
		return false, refsReason
	end
	refsOk, refsReason = refList(schema.buildingIds, "buildingIds")
	if not refsOk then
		return false, refsReason
	end
	if schema.classification ~= nil then
		local classOk, classReason = Validation.classification(schema.classification)
		if not classOk then
			return false, classReason
		end
	end
	return safeTags(schema.tags)
end

function Validation.region(schema: any): (boolean, string?)
	if type(schema) ~= "table" then
		return false, "region schema must be a table"
	end
	local ok, reason = Validation.safePayload(schema)
	if not ok then
		return false, reason
	end
	if
		not validId(schema.regionId)
		or not validId(schema.regionType)
		or not validId(schema.ownerSystem)
	then
		return false, "region identity fields are invalid"
	end
	return safeTags(schema.tags)
end

function Validation.building(schema: any): (boolean, string?)
	if type(schema) ~= "table" then
		return false, "building schema must be a table"
	end
	local ok, reason = Validation.safePayload(schema)
	if not ok then
		return false, reason
	end
	if
		not validId(schema.buildingId)
		or not validId(schema.districtId)
		or not validId(schema.buildingType)
		or not validId(schema.ownerSystem)
	then
		return false, "building identity fields are invalid"
	end
	local refsOk, refsReason = refList(schema.floorIds, "floorIds")
	if not refsOk then
		return false, refsReason
	end
	refsOk, refsReason = refList(schema.roomIds, "roomIds")
	if not refsOk then
		return false, refsReason
	end
	if schema.classification ~= nil then
		local classOk, classReason = Validation.classification(schema.classification)
		if not classOk then
			return false, classReason
		end
	end
	return safeTags(schema.tags)
end

function Validation.floor(schema: any): (boolean, string?)
	if type(schema) ~= "table" then
		return false, "floor schema must be a table"
	end
	local ok, reason = Validation.safePayload(schema)
	if not ok then
		return false, reason
	end
	if
		not validId(schema.floorId)
		or not validId(schema.buildingId)
		or not validId(schema.floorType)
	then
		return false, "floor identity fields are invalid"
	end
	if
		type(schema.floorIndex) ~= "number"
		or schema.floorIndex < -50
		or schema.floorIndex > 300
	then
		return false, "floorIndex is invalid"
	end
	local refsOk, refsReason = refList(schema.roomIds, "roomIds")
	if not refsOk then
		return false, refsReason
	end
	refsOk, refsReason = refList(schema.connectionIds, "connectionIds")
	if not refsOk then
		return false, refsReason
	end
	return safeTags(schema.tags)
end

function Validation.room(schema: any): (boolean, string?)
	if type(schema) ~= "table" then
		return false, "room schema must be a table"
	end
	local ok, reason = Validation.safePayload(schema)
	if not ok then
		return false, reason
	end
	if
		not validId(schema.roomId)
		or not validId(schema.buildingId)
		or not validId(schema.floorId)
		or not validId(schema.roomType)
	then
		return false, "room identity fields are invalid"
	end
	local refsOk, refsReason = refList(schema.zoneIds, "zoneIds")
	if not refsOk then
		return false, refsReason
	end
	refsOk, refsReason = refList(schema.connectionIds, "connectionIds")
	if not refsOk then
		return false, refsReason
	end
	if schema.classification ~= nil then
		local classOk, classReason = Validation.classification(schema.classification)
		if not classOk then
			return false, classReason
		end
	end
	return safeTags(schema.tags)
end

function Validation.zone(schema: any): (boolean, string?)
	if type(schema) ~= "table" then
		return false, "zone schema must be a table"
	end
	local ok, reason = Validation.safePayload(schema)
	if not ok then
		return false, reason
	end
	if
		not validId(schema.zoneId)
		or not validId(schema.zoneType)
		or not validId(schema.ownerSystem)
	then
		return false, "zone identity fields are invalid"
	end
	if schema.roomId ~= nil and not validId(schema.roomId) then
		return false, "zone roomId is invalid"
	end
	return safeTags(schema.tags)
end

function Validation.connection(schema: any): (boolean, string?)
	if type(schema) ~= "table" then
		return false, "connection schema must be a table"
	end
	local ok, reason = Validation.safePayload(schema)
	if not ok then
		return false, reason
	end
	if
		not validId(schema.connectionId)
		or not validId(schema.fromWorldId)
		or not validId(schema.toWorldId)
		or schema.fromWorldId == schema.toWorldId
		or not validId(schema.connectionType)
		or not validId(schema.traversalKind)
	then
		return false, "connection identity fields are invalid"
	end
	local refsOk, refsReason = refList(schema.requiredSchemas, "requiredSchemas")
	if not refsOk then
		return false, refsReason
	end
	return safeTags(schema.tags)
end

function Validation.streamingRegion(schema: any): (boolean, string?)
	if type(schema) ~= "table" then
		return false, "streaming region schema must be a table"
	end
	local ok, reason = Validation.safePayload(schema)
	if not ok then
		return false, reason
	end
	if not validId(schema.streamingRegionId) then
		return false, "streamingRegionId is invalid"
	end
	local refsOk, refsReason = refList(schema.worldIds, "worldIds")
	if not refsOk then
		return false, refsReason
	end
	if STREAMING_POLICIES[schema.streamingPolicy] ~= true then
		return false, "invalid streaming policy"
	end
	if type(schema.priority) ~= "number" or schema.priority < 0 or schema.priority > 100 then
		return false, "streaming priority is invalid"
	end
	return safeTags(schema.tags)
end

function Validation.validate(): (boolean, string?)
	if Types.Mode ~= "ServerAuthoritativeWorldSchemaRuntime" then
		return false, "World Runtime must remain server-authoritative schema runtime"
	end
	return true, nil
end

return Validation
