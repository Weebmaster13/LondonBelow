--!strict

local Evidence = require(script.Parent.VisualCompositionEvidence)
local Serialization = require(script.Parent.PresentationSerialization)
local Types = require(script.Parent.PresentationTypes)

local Ownership = {}
local records = {}
local nextOrdinal = 0

function Ownership.claim(composition: any, revision: number)
	local existing = records[composition.compositionInstanceId]
	if
		existing ~= nil
		and existing.robloxRenderingSessionId ~= composition.robloxRenderingSessionId
	then
		return {
			ok = false,
			code = Types.VisualCompositionFailureType.OwnershipMismatch,
			message = "ownership mismatch",
		}
	end
	nextOrdinal += 1
	local record = {
		compositionInstanceId = composition.compositionInstanceId,
		robloxRenderingSessionId = composition.robloxRenderingSessionId,
		rendererId = composition.rendererId,
		ownerRuntime = Types.RobloxVisualCompositionRuntimeId,
		revision = revision,
		ownershipOrdinal = nextOrdinal,
	}
	records[record.compositionInstanceId] = record
	Evidence.record("ownership claimed", record)
	return { ok = true, code = "Ok", ownership = Serialization.deepCopy(record) }
end

function Ownership.inspect()
	local result = {}
	for _, record in pairs(records) do
		result[#result + 1] = Serialization.deepCopy(record)
	end
	table.sort(result, function(left, right)
		return left.compositionInstanceId < right.compositionInstanceId
	end)
	return result
end

function Ownership.clear()
	table.clear(records)
	nextOrdinal = 0
end

return Ownership
