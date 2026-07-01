--!strict
-- Memory Fragment unlock state. Fragments are data schemas, not final memories.

local Serialization = require(script.Parent.SaveSerialization)
local Types = require(script.Parent.SaveTypes)
local Validation = require(script.Parent.SaveValidation)

local MemoryFragments = {}
local byProfile: { [string]: { [string]: any } } = {}

function MemoryFragments.unlock(profileId: string, fragment: any): (boolean, string?)
	local ok, reason = Validation.memoryFragment(profileId, fragment)
	if not ok then
		return false, reason
	end
	local fragments = byProfile[profileId] or {}
	byProfile[profileId] = fragments
	if fragments[fragment.fragmentId] ~= nil then
		return false, "duplicate memory fragment"
	end
	local count = 0
	for _ in pairs(fragments) do
		count += 1
	end
	if count >= Types.Limits.MaxMemoryFragmentsPerProfile then
		return false, "memory fragment limit reached"
	end
	fragments[fragment.fragmentId] = {
		fragmentId = fragment.fragmentId,
		schemaKind = fragment.schemaKind or "PlaceholderFragmentSchema",
		metadata = Serialization.deepCopy(fragment.metadata or {}),
		unlockedAt = os.clock(),
	}
	return true, nil
end

function MemoryFragments.clear()
	table.clear(byProfile)
end

function MemoryFragments.inspect()
	local count = 0
	for _, fragments in pairs(byProfile) do
		for _ in pairs(fragments) do
			count += 1
		end
	end
	return {
		memoryFragmentCount = count,
		fragmentsByProfile = Serialization.deepCopy(byProfile),
		limitPerProfile = Types.Limits.MaxMemoryFragmentsPerProfile,
	}
end

return MemoryFragments
