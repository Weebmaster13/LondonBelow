--!strict
-- Replay meaning schemas for future interpretation. This does not replay content.

local Serialization = require(script.Parent.SaveSerialization)
local Types = require(script.Parent.SaveTypes)
local Validation = require(script.Parent.SaveValidation)

local Replay = {}
local byProfile: { [string]: { any } } = {}

local function trim(list: { any })
	while #list > Types.Limits.MaxReplayStatesPerProfile do
		table.remove(list, 1)
	end
end

function Replay.record(profileId: string, replay: any): (boolean, string?)
	local ok, reason = Validation.replayState(profileId, replay)
	if not ok then
		return false, reason
	end
	local list = byProfile[profileId] or {}
	byProfile[profileId] = list
	table.insert(list, {
		replayId = replay.replayId,
		meaning = Serialization.deepCopy(replay.meaning or {}),
		createdAt = os.clock(),
	})
	trim(list)
	return true, nil
end

function Replay.clear()
	table.clear(byProfile)
end

function Replay.inspect()
	local count = 0
	for _, list in pairs(byProfile) do
		count += #list
	end
	return {
		replayStateCount = count,
		replayStatesByProfile = Serialization.deepCopy(byProfile),
		limitPerProfile = Types.Limits.MaxReplayStatesPerProfile,
	}
end

return Replay
