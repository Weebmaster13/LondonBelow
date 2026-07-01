--!strict
-- Journal unlock state. Entries are schemas/ids only, not final UI or story prose.

local Serialization = require(script.Parent.SaveSerialization)
local Types = require(script.Parent.SaveTypes)
local Validation = require(script.Parent.SaveValidation)

local Journal = {}
local byProfile: { [string]: { [string]: any } } = {}

function Journal.unlock(profileId: string, entry: any): (boolean, string?)
	local ok, reason = Validation.journalEntry(profileId, entry)
	if not ok then
		return false, reason
	end
	local entries = byProfile[profileId] or {}
	byProfile[profileId] = entries
	if entries[entry.entryId] ~= nil then
		return false, "duplicate journal entry"
	end
	local count = 0
	for _ in pairs(entries) do
		count += 1
	end
	if count >= Types.Limits.MaxJournalEntriesPerProfile then
		return false, "journal entry limit reached"
	end
	entries[entry.entryId] = {
		entryId = entry.entryId,
		schemaKind = entry.schemaKind or "PlaceholderSchema",
		metadata = Serialization.deepCopy(entry.metadata or {}),
		unlockedAt = os.clock(),
	}
	return true, nil
end

function Journal.clear()
	table.clear(byProfile)
end

function Journal.inspect()
	local count = 0
	for _, entries in pairs(byProfile) do
		for _ in pairs(entries) do
			count += 1
		end
	end
	return {
		journalEntryCount = count,
		entriesByProfile = Serialization.deepCopy(byProfile),
		limitPerProfile = Types.Limits.MaxJournalEntriesPerProfile,
	}
end

return Journal
