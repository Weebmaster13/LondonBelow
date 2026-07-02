--!strict
-- Central bounded state store for World Runtime Foundation.

local Serialization = require(script.Parent.WorldSerialization)
local Types = require(script.Parent.WorldTypes)
local Validation = require(script.Parent.WorldValidation)

local Runtime = {}

local stores: { [string]: { [string]: any } } = {
	districts = {},
	regions = {},
	buildings = {},
	floors = {},
	rooms = {},
	zones = {},
	connections = {},
	streamingRegions = {},
	classifications = {},
	tags = {},
}

local orders: { [string]: { string } } = {
	districts = {},
	regions = {},
	buildings = {},
	floors = {},
	rooms = {},
	zones = {},
	connections = {},
	streamingRegions = {},
	classifications = {},
	tags = {},
}

local limits = {
	districts = Types.Limits.MaxDistricts,
	regions = Types.Limits.MaxRegions,
	buildings = Types.Limits.MaxBuildings,
	floors = Types.Limits.MaxFloors,
	rooms = Types.Limits.MaxRooms,
	zones = Types.Limits.MaxZones,
	connections = Types.Limits.MaxConnections,
	streamingRegions = Types.Limits.MaxStreamingRegions,
	classifications = Types.Limits.MaxClassifications,
	tags = Types.Limits.MaxTags,
}

local validationFailures: { any } = {}
local snapshotHistory: { any } = {}

local validators = {
	districts = Validation.district,
	regions = Validation.region,
	buildings = Validation.building,
	floors = Validation.floor,
	rooms = Validation.room,
	zones = Validation.zone,
	connections = Validation.connection,
	streamingRegions = Validation.streamingRegion,
	classifications = Validation.classification,
	tags = function(schema: any): (boolean, string?)
		if type(schema) ~= "table" then
			return false, "world tag schema must be a table"
		end
		if not Validation.id(schema.tagId) or not Validation.id(schema.ownerSystem) then
			return false, "world tag identity fields are invalid"
		end
		local ok, reason = Validation.safePayload(schema)
		if not ok then
			return false, reason
		end
		return Validation.tags({ schema.tagId })
	end,
}

local idFields = {
	districts = "districtId",
	regions = "regionId",
	buildings = "buildingId",
	floors = "floorId",
	rooms = "roomId",
	zones = "zoneId",
	connections = "connectionId",
	streamingRegions = "streamingRegionId",
	classifications = "classificationId",
	tags = "tagId",
}

local function boundedInsert(list: { any }, value: any, limit: number)
	table.insert(list, value)
	while #list > limit do
		table.remove(list, 1)
	end
end

local function countMap(map: { [string]: any }): number
	local count = 0
	for _ in pairs(map) do
		count += 1
	end
	return count
end

local function trimStore(kind: string)
	local store = stores[kind]
	local order = orders[kind]
	local limit = limits[kind]
	if store == nil or order == nil or limit == nil then
		return
	end
	while #order > limit do
		local removedId = table.remove(order, 1)
		if removedId ~= nil then
			store[removedId] = nil
		end
	end
end

function Runtime.has(kind: string, id: string): boolean
	return stores[kind] ~= nil and stores[kind][id] ~= nil
end

function Runtime.register(kind: string, schema: any): (boolean, string?)
	local validator = validators[kind]
	local idField = idFields[kind]
	if validator == nil or idField == nil or stores[kind] == nil then
		return false, "unsupported world schema kind"
	end
	local ok, reason = validator(schema)
	if not ok then
		return false, reason
	end
	local id = schema[idField]
	if Runtime.has(kind, id) then
		return false, "duplicate " .. idField
	end
	stores[kind][id] = Serialization.deepCopy(schema)
	boundedInsert(orders[kind], id, limits[kind])
	trimStore(kind)
	return true, nil
end

function Runtime.recordValidationFailure(reason: string, payload: any?)
	boundedInsert(validationFailures, {
		reason = reason,
		payload = Serialization.diagnosticCopy(payload),
	}, Types.Limits.MaxValidationFailures)
end

function Runtime.recordSnapshot(snapshot: any)
	boundedInsert(
		snapshotHistory,
		Serialization.diagnosticCopy(snapshot),
		Types.Limits.MaxSnapshotHistory
	)
end

function Runtime.inspect()
	local counts = {
		districts = countMap(stores.districts),
		regions = countMap(stores.regions),
		buildings = countMap(stores.buildings),
		floors = countMap(stores.floors),
		rooms = countMap(stores.rooms),
		zones = countMap(stores.zones),
		connections = countMap(stores.connections),
		streamingRegions = countMap(stores.streamingRegions),
		classifications = countMap(stores.classifications),
		tags = countMap(stores.tags),
		validationFailures = #validationFailures,
		snapshots = #snapshotHistory,
	}
	return Serialization.deepCopy({
		stores = stores,
		orders = orders,
		counts = counts,
		validationFailures = validationFailures,
		snapshotHistory = snapshotHistory,
	})
end

function Runtime.clear()
	for _, store in pairs(stores) do
		table.clear(store)
	end
	for _, order in pairs(orders) do
		table.clear(order)
	end
	table.clear(validationFailures)
	table.clear(snapshotHistory)
end

return Runtime
