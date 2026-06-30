--!strict
--[[
	Derives safe world context from payload metadata and registered profiles.

	Future Observation, Environment, Lighting, Audio, and Monster Directors should
	consume this context instead of guessing from raw part names. Unknown zones
	resolve to conservative defaults that do not allow chases or monster reveals.
]]

local Config = require(script.Parent.WorldConfig)
local Registry = require(script.Parent.WorldProfileRegistry)
local Types = require(script.Parent.WorldTypes)

local WorldZoneContext = {}

type WorldContext = Types.WorldContext
type WorldZoneProfile = Types.WorldZoneProfile

local recentContexts: { WorldContext } = {}

local function cloneArray(values: { string }?): { string }
	local result = {}

	for _, value in ipairs(values or {}) do
		table.insert(result, value)
	end

	return result
end

local function remember(context: WorldContext)
	table.insert(recentContexts, context)

	while #recentContexts > Config.MaxRecentContexts do
		table.remove(recentContexts, 1)
	end
end

local function fromProfile(profile: WorldZoneProfile): WorldContext
	return {
		zoneId = profile.id,
		zoneKind = profile.kind,
		parentId = profile.parentId,
		atmosphereProfileId = profile.atmosphereProfileId,
		roomPersonalityId = profile.roomPersonalityId,
		affordances = cloneArray(profile.affordances),
		lightingPolicy = table.clone(profile.lightingPolicy),
		audioPolicy = table.clone(profile.audioPolicy),
		monsterPolicy = table.clone(profile.monsterPolicy),
		puzzleProtection = table.clone(profile.puzzleProtection),
		isKnown = true,
		tags = cloneArray(profile.tags),
	}
end

local function fallback(zoneId: string?, zoneKind: string?): WorldContext
	local resolvedKind = if type(zoneKind) == "string" and Types.ValidZoneKinds[zoneKind]
		then zoneKind
		else Config.DefaultZoneKind

	return {
		zoneId = if type(zoneId) == "string" and zoneId ~= "" then zoneId else Config.DefaultZoneId,
		zoneKind = resolvedKind :: Types.ZoneKind,
		parentId = nil,
		atmosphereProfileId = Config.DefaultAtmosphereProfileId :: Types.AtmosphereProfileId,
		roomPersonalityId = Config.DefaultRoomPersonalityId :: Types.RoomPersonalityId,
		affordances = {},
		lightingPolicy = table.clone(Config.DefaultLightingPolicy),
		audioPolicy = table.clone(Config.DefaultAudioPolicy),
		monsterPolicy = table.clone(Config.DefaultMonsterPolicy),
		puzzleProtection = table.clone(Config.DefaultPuzzleProtection),
		isKnown = false,
		tags = {},
	}
end

function WorldZoneContext.fromPayload(payload: any): WorldContext
	local metadata = if type(payload) == "table" and type(payload.metadata) == "table"
		then payload.metadata
		else {}
	local context = if type(payload) == "table" and type(payload.context) == "table"
		then payload.context
		else {}

	local zoneId = if type(context.zoneId) == "string" then context.zoneId else metadata.zoneId
	local zoneKind = if type(context.zoneKind) == "string"
		then context.zoneKind
		else metadata.zoneKind
	local profile = if type(zoneId) == "string" then Registry.getZone(zoneId) else nil
	local result = if profile ~= nil then fromProfile(profile) else fallback(zoneId, zoneKind)

	remember(result)
	return result
end

function WorldZoneContext.inspect()
	return {
		recentContexts = table.clone(recentContexts),
		recentContextCount = #recentContexts,
	}
end

function WorldZoneContext.reset()
	table.clear(recentContexts)
end

return WorldZoneContext
