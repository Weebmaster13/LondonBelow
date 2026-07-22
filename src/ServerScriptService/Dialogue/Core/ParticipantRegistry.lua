--!strict

local Evidence = require(script.Parent.DialogueEvidence)
local Serialization = require(script.Parent.DialogueSerialization)
local Types = require(script.Parent.DialogueTypes)

local ParticipantRegistry = {}
local participants = {}
local order = {}

local function hasParticipantType(value: string): boolean
	for _, participantType in pairs(Types.ParticipantType) do
		if participantType == value then
			return true
		end
	end
	return false
end

function ParticipantRegistry.register(participant: any)
	if #order >= Types.Limits.MaxParticipants then
		return {
			ok = false,
			code = Types.FailureType.LimitExceeded,
			message = "participant limit exceeded",
		}
	end
	if type(participant) ~= "table" then
		return {
			ok = false,
			code = Types.FailureType.ValidationFailure,
			message = "participant must be a table",
		}
	end
	if type(participant.participantId) ~= "string" or participant.participantId == "" then
		return {
			ok = false,
			code = Types.FailureType.ValidationFailure,
			message = "invalid participantId",
		}
	end
	if
		type(participant.participantType) ~= "string"
		or not hasParticipantType(participant.participantType)
	then
		return {
			ok = false,
			code = Types.FailureType.UnsupportedParticipantType,
			message = "unsupported participant type",
		}
	end
	if participants[participant.participantId] ~= nil then
		return {
			ok = false,
			code = Types.FailureType.DuplicateParticipant,
			message = "duplicate participant",
		}
	end
	participants[participant.participantId] = Serialization.deepCopy(participant)
	order[#order + 1] = participant.participantId
	Evidence.record(
		"dialogue participant registered",
		{ participantId = participant.participantId }
	)
	return { ok = true, code = "Ok", participantId = participant.participantId }
end

function ParticipantRegistry.get(participantId: string): any?
	local participant = participants[participantId]
	if participant == nil then
		return nil
	end
	return Serialization.deepCopy(participant)
end

function ParticipantRegistry.inspect()
	local items = {}
	for index, participantId in ipairs(order) do
		items[index] = Serialization.deepCopy(participants[participantId])
	end
	return items
end

function ParticipantRegistry.count(): number
	return #order
end

function ParticipantRegistry.clear()
	table.clear(participants)
	table.clear(order)
end

return ParticipantRegistry
