--!strict

local Evidence = require(script.Parent.CommandEvidence)
local Serialization = require(script.Parent.CommandSerialization)
local Types = require(script.Parent.CommandTypes)

local Ancestry = {}
local parents: { [string]: string } = {}

function Ancestry.validate(commandId: string, causationId: string?): (boolean, string?)
	if causationId == nil or causationId == "root" then
		return true, nil
	end
	local depth = 0
	local cursor = causationId
	while cursor ~= nil and cursor ~= "root" do
		depth += 1
		if depth > Types.Limits.MaxNestedDepth then
			return false, Types.FailureType.NestedCommandDepthExceeded
		end
		if cursor == commandId then
			return false, Types.FailureType.CircularCommandFailure
		end
		cursor = parents[cursor]
	end
	return true, nil
end

function Ancestry.record(commandId: string, causationId: string?)
	parents[commandId] = causationId or "root"
	Evidence.record(
		"ancestry recorded",
		{ commandId = commandId, causationId = causationId or "root" }
	)
end

function Ancestry.inspect()
	return Serialization.deepCopy(parents)
end

function Ancestry.clear()
	table.clear(parents)
end

return Ancestry
