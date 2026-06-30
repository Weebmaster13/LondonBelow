--!strict

local Config = require(script.Parent.EnvironmentDirectorConfig)
local Types = require(script.Parent.EnvironmentDirectorTypes)

local EnvironmentZoneContext = {}

local knownZones: { [string]: { zoneId: string, zoneKind: Types.ZoneKind, tags: { string } } } = {}

function EnvironmentZoneContext.registerZone(
	zoneId: string,
	zoneKind: Types.ZoneKind,
	tags: { string }?
)
	if zoneId == "" or not Types.ValidZoneKinds[zoneKind] then
		return false
	end

	knownZones[zoneId] = {
		zoneId = zoneId,
		zoneKind = zoneKind,
		tags = tags or {},
	}

	return true
end

function EnvironmentZoneContext.fromPayload(payload: any)
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

	if type(zoneId) ~= "string" or zoneId == "" then
		zoneId = Config.DefaultZoneId
	end

	if type(zoneKind) ~= "string" or not Types.ValidZoneKinds[zoneKind] then
		local known = knownZones[zoneId]
		zoneKind = if known ~= nil then known.zoneKind else Config.DefaultZoneKind
	end

	return {
		zoneId = zoneId,
		zoneKind = zoneKind :: Types.ZoneKind,
		known = knownZones[zoneId] ~= nil,
	}
end

function EnvironmentZoneContext.inspect()
	return {
		knownZones = table.clone(knownZones),
	}
end

function EnvironmentZoneContext.reset()
	table.clear(knownZones)
end

return EnvironmentZoneContext
