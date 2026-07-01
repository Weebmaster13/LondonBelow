--!strict
-- Checkpoint schemas. Checkpoints intentionally exclude temporary horror pressure.

local Serialization = require(script.Parent.SaveSerialization)
local Types = require(script.Parent.SaveTypes)
local Validation = require(script.Parent.SaveValidation)

local Checkpoints = {}
local byProfile: { [string]: { any } } = {}

local function trim(list: { any })
	while #list > Types.Limits.MaxCheckpointsPerProfile do
		table.remove(list, 1)
	end
end

function Checkpoints.create(profileId: string, checkpoint: any): (boolean, string?)
	local ok, reason = Validation.checkpoint(profileId, checkpoint)
	if not ok then
		return false, reason
	end
	local list = byProfile[profileId] or {}
	byProfile[profileId] = list
	table.insert(list, {
		checkpointId = checkpoint.checkpointId,
		chapterId = checkpoint.chapterId or "Unassigned",
		state = Serialization.deepCopy(checkpoint.state or {}),
		createdAt = os.clock(),
	})
	trim(list)
	return true, nil
end

function Checkpoints.latest(profileId: string): any?
	local list = byProfile[profileId]
	if list == nil or #list == 0 then
		return nil
	end
	return Serialization.deepCopy(list[#list])
end

function Checkpoints.clear()
	table.clear(byProfile)
end

function Checkpoints.inspect()
	local count = 0
	for _, list in pairs(byProfile) do
		count += #list
	end
	return {
		checkpointCount = count,
		checkpointsByProfile = Serialization.deepCopy(byProfile),
		limitPerProfile = Types.Limits.MaxCheckpointsPerProfile,
	}
end

return Checkpoints
