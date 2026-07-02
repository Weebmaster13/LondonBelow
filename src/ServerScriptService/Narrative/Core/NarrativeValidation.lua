--!strict
-- Validation for server-owned Narrative foundation schemas.

local Serialization = require(script.Parent.NarrativeSerialization)
local Types = require(script.Parent.NarrativeTypes)

local Validation = {}

local FORBIDDEN_FIELDS = {
	"action",
	"adapter",
	"animation",
	"finalDialogue",
	"dialogue",
	"finalStory",
	"storyProse",
	"storyText",
	"prose",
	"chapterContent",
	"chapter0",
	"chapter1",
	"chapter",
	"cutscene",
	"cinematic",
	"ui",
	"presentation",
	"client",
	"remote",
	"workspace",
	"instance",
	"audio",
	"lighting",
	"sound",
	"light",
	"monsterAI",
	"monster",
	"horrorPacing",
	"pacing",
	"execute",
	"execution",
	"effect",
	"effects",
	"play",
	"spawn",
	"teleport",
	"damage",
}

local function validId(value: any): boolean
	return type(value) == "string"
		and value ~= ""
		and #value <= 140
		and string.match(value, "^[%w%._%-:]+$") ~= nil
end

local function optionalId(value: any): boolean
	return value == nil or validId(value)
end

local function validPercent(value: any): boolean
	return type(value) == "number"
		and value == value
		and value >= 0
		and value <= Types.Limits.MaxIdentityPercent
end

local function validIdentityDelta(value: any): boolean
	return value == nil
		or (
			type(value) == "number"
			and value == value
			and value >= -Types.Limits.MaxIdentityDelta
			and value <= Types.Limits.MaxIdentityDelta
		)
end

local function validRequirements(value: any): boolean
	return value == nil or type(value) == "table"
end

local function forbidden(payload: any, depth: number): (boolean, string?)
	if type(payload) ~= "table" then
		return true, nil
	end
	if depth > Types.Limits.MaxPayloadDepth then
		return false, "narrative payload depth exceeds limit"
	end
	for _, field in ipairs(FORBIDDEN_FIELDS) do
		if payload[field] ~= nil then
			return false, "narrative payload contains forbidden field: " .. field
		end
	end
	for _, nested in pairs(payload) do
		local ok, reason = forbidden(nested, depth + 1)
		if not ok then
			return false, reason
		end
	end
	return true, nil
end

function Validation.safePayload(payload: any): (boolean, string?)
	local ok, reason = Serialization.validateSerializable(payload)
	if not ok then
		return false, reason
	end
	return forbidden(payload, 0)
end

function Validation.beat(beat: any): (boolean, string?)
	if type(beat) ~= "table" then
		return false, "beat must be a table"
	end
	local safe, safeReason = Validation.safePayload(beat)
	if not safe then
		return false, safeReason
	end
	if not validId(beat.beatId) then
		return false, "beatId is required and must use a stable schema id"
	end
	if beat.schemaKind ~= nil and not validId(beat.schemaKind) then
		return false, "schemaKind is invalid"
	end
	if not optionalId(beat.journalEntryId) then
		return false, "journalEntryId is invalid"
	end
	if not optionalId(beat.memoryFragmentId) then
		return false, "memoryFragmentId is invalid"
	end
	if beat.identityRequirement ~= nil and not validPercent(beat.identityRequirement) then
		return false, "identityRequirement must be between 0 and 100"
	end
	if beat.metadata ~= nil and type(beat.metadata) ~= "table" then
		return false, "beat metadata must be a table"
	end
	return true, nil
end

function Validation.storyGate(gate: any): (boolean, string?)
	if type(gate) ~= "table" then
		return false, "story gate must be a table"
	end
	local safe, safeReason = Validation.safePayload(gate)
	if not safe then
		return false, safeReason
	end
	if not validId(gate.gateId) then
		return false, "gateId is required and must use a stable schema id"
	end
	if gate.beatId ~= nil and not validId(gate.beatId) then
		return false, "gate beatId is invalid"
	end
	if not validRequirements(gate.requirements) then
		return false, "gate requirements must be a table"
	end
	return true, nil
end

function Validation.revealEligibility(reveal: any): (boolean, string?)
	if type(reveal) ~= "table" then
		return false, "reveal eligibility must be a table"
	end
	local safe, safeReason = Validation.safePayload(reveal)
	if not safe then
		return false, safeReason
	end
	if not validId(reveal.revealId) then
		return false, "revealId is required and must use a stable schema id"
	end
	if reveal.beatId ~= nil and not validId(reveal.beatId) then
		return false, "reveal beatId is invalid"
	end
	if not optionalId(reveal.journalEntryId) then
		return false, "reveal journalEntryId is invalid"
	end
	if not optionalId(reveal.memoryFragmentId) then
		return false, "reveal memoryFragmentId is invalid"
	end
	if not validIdentityDelta(reveal.identityDelta) then
		return false, "identityDelta is outside narrative bounds"
	end
	if reveal.context ~= nil and type(reveal.context) ~= "table" then
		return false, "reveal context must be a table"
	end
	return true, nil
end

function Validation.emotionalBeat(beat: any): (boolean, string?)
	if type(beat) ~= "table" then
		return false, "emotional beat must be a table"
	end
	local safe, safeReason = Validation.safePayload(beat)
	if not safe then
		return false, safeReason
	end
	if not validId(beat.emotionalBeatId) then
		return false, "emotionalBeatId is required and must use a stable schema id"
	end
	if not optionalId(beat.beatId) then
		return false, "emotional beatId is invalid"
	end
	if type(beat.pressureLimit) ~= "number" or beat.pressureLimit ~= beat.pressureLimit then
		return false, "pressureLimit must be a number"
	end
	if beat.pressureLimit < 0 or beat.pressureLimit > 100 then
		return false, "pressureLimit must be between 0 and 100"
	end
	if beat.metadata ~= nil and type(beat.metadata) ~= "table" then
		return false, "emotional metadata must be a table"
	end
	return true, nil
end

function Validation.validate(): (boolean, string?)
	if Types.Mode ~= "ServerAuthoritativeNarrativeFoundation" then
		return false, "Narrative runtime must remain server-authoritative foundation mode"
	end
	return true, nil
end

return Validation
