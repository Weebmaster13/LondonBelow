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

local function deepCopy(value: any, depth: number?): any
	local currentDepth = depth or 0

	if type(value) ~= "table" then
		return value
	end

	if currentDepth > 8 then
		return nil
	end

	local copied = {}

	for key, nestedValue in pairs(value) do
		copied[key] = deepCopy(nestedValue, currentDepth + 1)
	end

	return copied
end

local function count(values: { [string]: any }): number
	local total = 0

	for _ in pairs(values) do
		total += 1
	end

	return total
end

local function cloneStringArray(values: { string }?): { string }
	local result = {}

	for _, value in ipairs(values or {}) do
		table.insert(result, value)
	end

	return result
end

local function validateStringArray(values: any, fieldName: string): (boolean, string?)
	if type(values) ~= "table" then
		return false, fieldName .. " must be an array"
	end

	for index, value in ipairs(values) do
		if type(value) ~= "string" or value == "" then
			return false, fieldName .. " entry " .. tostring(index) .. " must be a non-empty string"
		end
	end

	return true, nil
end

local function validateAffordances(affordances: any): (boolean, string?)
	local arrayOk, arrayErr = validateStringArray(affordances, "affordances")
	if not arrayOk then
		return false, arrayErr
	end

	local seen: { [string]: boolean } = {}

	for _, affordance in ipairs(affordances) do
		if not Types.ValidAffordances[affordance] then
			return false, "unknown affordance: " .. tostring(affordance)
		end

		if seen[affordance] then
			return false, "duplicate affordance: " .. affordance
		end

		seen[affordance] = true
	end

	return true, nil
end

local function validatePolicyNumber(value: any, fieldName: string): (boolean, string?)
	if type(value) ~= "number" or value < 0 or value > 1 then
		return false, fieldName .. " must be a number between 0 and 1"
	end

	return true, nil
end

local function validateBoolean(value: any, fieldName: string): (boolean, string?)
	if type(value) ~= "boolean" then
		return false, fieldName .. " must be boolean"
	end

	return true, nil
end

local function validateBias(value: any, fieldName: string): (boolean, string?)
	if type(value) ~= "number" or value < -1 or value > 1 then
		return false, fieldName .. " must be a number between -1 and 1"
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

	for _, fieldName in ipairs({ "allowsBlackout", "allowsFlicker", "allowsDirectionalMislead" }) do
		local ok, err = validateBoolean(policy[fieldName], fieldName)
		if not ok then
			return false, err
		end
	end

	return true, nil
end

local function validateAudioPolicy(policy: any): (boolean, string?)
	if type(policy) ~= "table" then
		return false, "audioPolicy must be a table"
	end

	for _, fieldName in ipairs({
		"allowsWhispers",
		"allowsFakeSounds",
		"allowsHeartbeat",
		"allowsBreathing",
		"allowsSilenceDrop",
	}) do
		local ok, err = validateBoolean(policy[fieldName], fieldName)
		if not ok then
			return false, err
		end
	end

	return validateStringArray(policy.allowedSoundTags, "allowedSoundTags")
end

local function validateMonsterPolicy(policy: any): (boolean, string?)
	if type(policy) ~= "table" then
		return false, "monsterPolicy must be a table"
	end

	for _, fieldName in ipairs({
		"allowsMainMonsterPresence",
		"allowsMainMonsterReveal",
		"allowsCrawlerPresence",
		"allowsChaseStart",
		"allowsChaseContinuation",
		"requiresDirectorApproval",
	}) do
		local ok, err = validateBoolean(policy[fieldName], fieldName)
		if not ok then
			return false, err
		end
	end

	if policy.allowsMainMonsterReveal and not policy.allowsMainMonsterPresence then
		return false, "monster reveal requires monster presence"
	end

	if policy.allowsChaseStart and not policy.requiresDirectorApproval then
		return false, "chase start must require Director approval"
	end

	if policy.allowsMainMonsterReveal and not policy.requiresDirectorApproval then
		return false, "main monster reveal must require Director approval"
	end

	return true, nil
end

local function validatePuzzleProtection(policy: any): (boolean, string?)
	if type(policy) ~= "table" then
		return false, "puzzleProtection must be a table"
	end

	for _, fieldName in ipairs({
		"protectsActivePuzzle",
		"allowsSubtlePressure",
		"allowsMajorInterruptions",
	}) do
		local ok, err = validateBoolean(policy[fieldName], fieldName)
		if not ok then
			return false, err
		end
	end

	if type(policy.reason) ~= "string" or policy.reason == "" then
		return false, "puzzleProtection.reason must be a non-empty string"
	end

	if policy.protectsActivePuzzle and policy.allowsMajorInterruptions then
		return false, "protected puzzles cannot allow major interruptions"
	end

	return true, nil
end

local function hasAffordance(affordances: { string }, affordance: string): boolean
	for _, value in ipairs(affordances) do
		if value == affordance then
			return true
		end
	end

	return false
end

local function validateSafetyAlignment(profile: WorldZoneProfile): (boolean, string?)
	if profile.isSafeRoom then
		if
			profile.monsterPolicy.allowsMainMonsterReveal or profile.monsterPolicy.allowsChaseStart
		then
			return false, "safe rooms cannot allow monster reveal or chase start"
		end

		if profile.lightingPolicy.allowsBlackout then
			return false, "safe rooms cannot allow blackout"
		end
	end

	if profile.isPuzzleRoom and not profile.puzzleProtection.protectsActivePuzzle then
		return false, "puzzle rooms must protect active puzzle focus"
	end

	if
		hasAffordance(profile.affordances, "AllowMonsterReveal")
		and not profile.monsterPolicy.allowsMainMonsterReveal
	then
		return false, "AllowMonsterReveal affordance requires matching monster policy"
	end

	if
		hasAffordance(profile.affordances, "AllowChase")
		and not profile.monsterPolicy.allowsChaseStart
	then
		return false, "AllowChase affordance requires matching monster policy"
	end

	if hasAffordance(profile.affordances, "ProtectSafeRoom") and not profile.isSafeRoom then
		return false, "ProtectSafeRoom affordance requires isSafeRoom"
	end

	if
		hasAffordance(profile.affordances, "ProtectPuzzleFocus")
		and not profile.puzzleProtection.protectsActivePuzzle
	then
		return false, "ProtectPuzzleFocus affordance requires puzzle protection"
	end

	return true, nil
end

local function validateAtmosphereProfile(profile: AtmosphereProfile): (boolean, string?)
	if type(profile.id) ~= "string" or not Types.ValidAtmosphereProfiles[profile.id] then
		return false, "invalid atmosphere profile id"
	end

	if type(profile.displayName) ~= "string" or profile.displayName == "" then
		return false, "atmosphere displayName must be non-empty"
	end

	local biasOk, biasErr = validateBias(profile.intensityBias, "intensityBias")
	if not biasOk then
		return false, biasErr
	end

	local lightingOk, lightingErr = validateLightingPolicy(profile.lightingPolicy)
	if not lightingOk then
		return false, lightingErr
	end

	local audioOk, audioErr = validateAudioPolicy(profile.audioPolicy)
	if not audioOk then
		return false, audioErr
	end

	local tagsOk, tagsErr = validateStringArray(profile.tags, "tags")
	if not tagsOk then
		return false, tagsErr
	end

	return true, nil
end

local function validateRoomProfile(profile: RoomPersonalityProfile): (boolean, string?)
	if type(profile.id) ~= "string" or not Types.ValidRoomPersonalities[profile.id] then
		return false, "invalid room personality id"
	end

	if type(profile.displayName) ~= "string" or profile.displayName == "" then
		return false, "room personality displayName must be non-empty"
	end

	local tensionOk, tensionErr = validateBias(profile.tensionBias, "tensionBias")
	if not tensionOk then
		return false, tensionErr
	end

	local toleranceOk, toleranceErr =
		validatePolicyNumber(profile.repetitionTolerance, "repetitionTolerance")
	if not toleranceOk then
		return false, toleranceErr
	end

	local preferredOk, preferredErr = validateAffordances(profile.preferredAffordances)
	if not preferredOk then
		return false, preferredErr
	end

	local suppressedOk, suppressedErr = validateAffordances(profile.suppressedAffordances)
	if not suppressedOk then
		return false, suppressedErr
	end

	local tagsOk, tagsErr = validateStringArray(profile.tags, "tags")
	if not tagsOk then
		return false, tagsErr
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

	if type(profile.displayName) ~= "string" or profile.displayName == "" then
		return false, "zone displayName must be non-empty"
	end

	local affordanceOk, affordanceErr = validateAffordances(profile.affordances)
	if not affordanceOk then
		return false, affordanceErr
	end

	local lightingOk, lightingErr = validateLightingPolicy(profile.lightingPolicy)
	if not lightingOk then
		return false, lightingErr
	end

	local audioOk, audioErr = validateAudioPolicy(profile.audioPolicy)
	if not audioOk then
		return false, audioErr
	end

	local monsterOk, monsterErr = validateMonsterPolicy(profile.monsterPolicy)
	if not monsterOk then
		return false, monsterErr
	end

	local puzzleOk, puzzleErr = validatePuzzleProtection(profile.puzzleProtection)
	if not puzzleOk then
		return false, puzzleErr
	end

	for _, fieldName in ipairs({
		"isSafeRoom",
		"isPuzzleRoom",
		"isChaseRoute",
		"isExterior",
		"isInterior",
	}) do
		local ok, err = validateBoolean(profile[fieldName], fieldName)
		if not ok then
			return false, err
		end
	end

	if profile.isExterior and profile.isInterior then
		return false, "zone cannot be both exterior and interior"
	end

	local tagsOk, tagsErr = validateStringArray(profile.tags, "tags")
	if not tagsOk then
		return false, tagsErr
	end

	local safetyOk, safetyErr = validateSafetyAlignment(profile)
	if not safetyOk then
		return false, safetyErr
	end

	return true, nil
end

function WorldProfileRegistry.registerAtmosphere(profile: AtmosphereProfile): (boolean, string?)
	local ok, err = validateAtmosphereProfile(profile)
	if not ok then
		return false, err
	end

	if atmosphereProfiles[profile.id] ~= nil then
		return false, "atmosphere profile already registered: " .. profile.id
	end

	if
		count(atmosphereProfiles) >= Config.MaxProfiles
		and atmosphereProfiles[profile.id] == nil
	then
		return false, "atmosphere profile limit reached"
	end

	atmosphereProfiles[profile.id] = deepCopy(profile)
	return true, nil
end

function WorldProfileRegistry.registerRoomPersonality(
	profile: RoomPersonalityProfile
): (boolean, string?)
	local ok, err = validateRoomProfile(profile)
	if not ok then
		return false, err
	end

	if roomProfiles[profile.id] ~= nil then
		return false, "room personality profile already registered: " .. profile.id
	end

	if count(roomProfiles) >= Config.MaxProfiles and roomProfiles[profile.id] == nil then
		return false, "room personality profile limit reached"
	end

	roomProfiles[profile.id] = deepCopy(profile)
	return true, nil
end

function WorldProfileRegistry.registerZone(profile: WorldZoneProfile): (boolean, string?)
	local ok, err = validateZoneProfile(profile)
	if not ok then
		return false, err
	end

	if zoneProfiles[profile.id] ~= nil then
		return false, "zone profile already registered: " .. profile.id
	end

	if count(zoneProfiles) >= Config.MaxProfiles and zoneProfiles[profile.id] == nil then
		return false, "zone profile limit reached"
	end

	zoneProfiles[profile.id] = deepCopy(profile)
	return true, nil
end

function WorldProfileRegistry.getZone(zoneId: string): WorldZoneProfile?
	local profile = zoneProfiles[zoneId]
	return if profile ~= nil then deepCopy(profile) else nil
end

function WorldProfileRegistry.getAtmosphere(profileId: string): AtmosphereProfile?
	local profile = atmosphereProfiles[profileId]
	return if profile ~= nil then deepCopy(profile) else nil
end

function WorldProfileRegistry.getRoomPersonality(profileId: string): RoomPersonalityProfile?
	local profile = roomProfiles[profileId]
	return if profile ~= nil then deepCopy(profile) else nil
end

function WorldProfileRegistry.inspect()
	return {
		atmosphereProfileCount = count(atmosphereProfiles),
		roomProfileCount = count(roomProfiles),
		zoneProfileCount = count(zoneProfiles),
		zoneProfiles = deepCopy(zoneProfiles),
	}
end

function WorldProfileRegistry.validate(): (boolean, string?)
	for atmosphereId, profile in pairs(atmosphereProfiles) do
		local ok, err = validateAtmosphereProfile(profile)
		if not ok then
			return false, "invalid atmosphere profile " .. atmosphereId .. ": " .. tostring(err)
		end
	end

	for roomId, profile in pairs(roomProfiles) do
		local ok, err = validateRoomProfile(profile)
		if not ok then
			return false, "invalid room profile " .. roomId .. ": " .. tostring(err)
		end
	end

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

WorldProfileRegistry.deepCopy = deepCopy
WorldProfileRegistry.cloneStringArray = cloneStringArray

return WorldProfileRegistry
