--!strict
--[[
	Registry for reusable world profile definitions.

	The registry stores contracts only. It does not discover Workspace parts,
	create chapter geometry, or authorize gameplay by itself. Future chapter
	loaders may register zone profiles here after validating authored content.
]]

local Config = require(script.Parent.WorldConfig)
local Types = require(script.Parent.WorldTypes)

local WorldProfileRegistry = {}

type AtmosphereProfile = Types.AtmosphereProfile
type RoomPersonalityProfile = Types.RoomPersonalityProfile
type WorldZoneProfile = Types.WorldZoneProfile

local atmosphereProfiles: { [string]: AtmosphereProfile } = {}
local roomProfiles: { [string]: RoomPersonalityProfile } = {}
local zoneProfiles: { [string]: WorldZoneProfile } = {}

local function count(values: { [string]: any }): number
	local total = 0

	for _ in pairs(values) do
		total += 1
	end

	return total
end

local function cloneArray(values: { string }?): { string }
	local result = {}

	for _, value in ipairs(values or {}) do
		table.insert(result, value)
	end

	return result
end

local function validateAffordances(affordances: { string }?): (boolean, string?)
	if type(affordances) ~= "table" then
		return false, "affordances must be an array"
	end

	for _, affordance in ipairs(affordances) do
		if not Types.ValidAffordances[affordance] then
			return false, "unknown affordance: " .. tostring(affordance)
		end
	end

	return true, nil
end

local function validatePolicyNumber(value: any, fieldName: string): (boolean, string?)
	if type(value) ~= "number" or value < 0 or value > 1 then
		return false, fieldName .. " must be a number between 0 and 1"
	end

	return true, nil
end

local function validateLightingPolicy(policy: any): (boolean, string?)
	if type(policy) ~= "table" then
		return false, "lightingPolicy must be a table"
	end

	local minOk, minErr = validatePolicyNumber(policy.minBrightness, "minBrightness")
	if not minOk then
		return false, minErr
	end

	local maxOk, maxErr = validatePolicyNumber(policy.maxBrightness, "maxBrightness")
	if not maxOk then
		return false, maxErr
	end

	if policy.minBrightness > policy.maxBrightness then
		return false, "minBrightness cannot exceed maxBrightness"
	end

	return true, nil
end

local function validateZoneProfile(profile: WorldZoneProfile): (boolean, string?)
	if type(profile.id) ~= "string" or profile.id == "" then
		return false, "zone id must be non-empty"
	end

	if not Types.ValidZoneKinds[profile.kind] then
		return false, "invalid zone kind"
	end

	if not Types.ValidAtmosphereProfiles[profile.atmosphereProfileId] then
		return false, "invalid atmosphere profile reference"
	end

	if not Types.ValidRoomPersonalities[profile.roomPersonalityId] then
		return false, "invalid room personality reference"
	end

	local affordanceOk, affordanceErr = validateAffordances(profile.affordances)
	if not affordanceOk then
		return false, affordanceErr
	end

	local lightingOk, lightingErr = validateLightingPolicy(profile.lightingPolicy)
	if not lightingOk then
		return false, lightingErr
	end

	return true, nil
end

function WorldProfileRegistry.registerAtmosphere(profile: AtmosphereProfile): (boolean, string?)
	if type(profile.id) ~= "string" or not Types.ValidAtmosphereProfiles[profile.id] then
		return false, "invalid atmosphere profile id"
	end

	local ok, err = validateLightingPolicy(profile.lightingPolicy)
	if not ok then
		return false, err
	end

	if
		count(atmosphereProfiles) >= Config.MaxProfiles
		and atmosphereProfiles[profile.id] == nil
	then
		return false, "atmosphere profile limit reached"
	end

	atmosphereProfiles[profile.id] = table.clone(profile)
	return true, nil
end

function WorldProfileRegistry.registerRoomPersonality(
	profile: RoomPersonalityProfile
): (boolean, string?)
	if type(profile.id) ~= "string" or not Types.ValidRoomPersonalities[profile.id] then
		return false, "invalid room personality id"
	end

	local preferredOk, preferredErr = validateAffordances(profile.preferredAffordances)
	if not preferredOk then
		return false, preferredErr
	end

	local suppressedOk, suppressedErr = validateAffordances(profile.suppressedAffordances)
	if not suppressedOk then
		return false, suppressedErr
	end

	if count(roomProfiles) >= Config.MaxProfiles and roomProfiles[profile.id] == nil then
		return false, "room personality profile limit reached"
	end

	roomProfiles[profile.id] = table.clone(profile)
	return true, nil
end

function WorldProfileRegistry.registerZone(profile: WorldZoneProfile): (boolean, string?)
	local ok, err = validateZoneProfile(profile)
	if not ok then
		return false, err
	end

	if count(zoneProfiles) >= Config.MaxProfiles and zoneProfiles[profile.id] == nil then
		return false, "zone profile limit reached"
	end

	zoneProfiles[profile.id] = table.clone(profile)
	return true, nil
end

function WorldProfileRegistry.getZone(zoneId: string): WorldZoneProfile?
	local profile = zoneProfiles[zoneId]
	return if profile ~= nil then table.clone(profile) else nil
end

function WorldProfileRegistry.getAtmosphere(profileId: string): AtmosphereProfile?
	local profile = atmosphereProfiles[profileId]
	return if profile ~= nil then table.clone(profile) else nil
end

function WorldProfileRegistry.getRoomPersonality(profileId: string): RoomPersonalityProfile?
	local profile = roomProfiles[profileId]
	return if profile ~= nil then table.clone(profile) else nil
end

function WorldProfileRegistry.inspect()
	return {
		atmosphereProfileCount = count(atmosphereProfiles),
		roomProfileCount = count(roomProfiles),
		zoneProfileCount = count(zoneProfiles),
		zoneProfiles = table.clone(zoneProfiles),
	}
end

function WorldProfileRegistry.validate(): (boolean, string?)
	for zoneId, profile in pairs(zoneProfiles) do
		local ok, err = validateZoneProfile(profile)
		if not ok then
			return false, "invalid zone profile " .. zoneId .. ": " .. tostring(err)
		end
	end

	return true, nil
end

function WorldProfileRegistry.clear()
	table.clear(atmosphereProfiles)
	table.clear(roomProfiles)
	table.clear(zoneProfiles)
end

WorldProfileRegistry.cloneArray = cloneArray

return WorldProfileRegistry
