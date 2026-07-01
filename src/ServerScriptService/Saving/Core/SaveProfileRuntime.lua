--!strict
-- Server-owned profile records. This is in-memory foundation state, not DataStore persistence.

local Serialization = require(script.Parent.SaveSerialization)
local Types = require(script.Parent.SaveTypes)
local Validation = require(script.Parent.SaveValidation)

local Profiles = {}
local profiles: { [string]: any } = {}
local order: { string } = {}

function Profiles.create(definition: any): (boolean, string?)
	local ok, reason = Validation.profile(definition)
	if not ok then
		return false, reason
	end
	if profiles[definition.profileId] ~= nil then
		return false, "duplicate profileId"
	end
	if #order >= Types.Limits.MaxProfiles then
		return false, "profile limit reached"
	end
	profiles[definition.profileId] = {
		profileId = definition.profileId,
		userId = definition.userId,
		createdAt = os.clock(),
		updatedAt = os.clock(),
		metadata = Serialization.deepCopy(definition.metadata or {}),
	}
	table.insert(order, definition.profileId)
	return true, nil
end

function Profiles.exists(profileId: string): boolean
	return profiles[profileId] ~= nil
end

function Profiles.touch(profileId: string)
	local profile = profiles[profileId]
	if profile ~= nil then
		profile.updatedAt = os.clock()
	end
end

function Profiles.clear()
	table.clear(profiles)
	table.clear(order)
end

function Profiles.inspect()
	return {
		profileCount = #order,
		profileLimit = Types.Limits.MaxProfiles,
		profiles = Serialization.deepCopy(profiles),
	}
end

return Profiles
