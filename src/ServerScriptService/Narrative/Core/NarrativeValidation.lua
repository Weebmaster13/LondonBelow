--!strict
-- Validation for server-owned Narrative foundation schemas.

local Serialization = require(script.Parent.NarrativeSerialization)
local Types = require(script.Parent.NarrativeTypes)

local Validation = {}

local FORBIDDEN_FIELDS = {
	"finalDialogue",
	"dialogue",
	"finalStory",
	"storyProse",
	"chapterContent",
	"chapter0",
	"chapter1",
	"cutscene",
	"ui",
	"client",
	"remote",
	"workspace",
	"instance",
	"audio",
	"lighting",
	"monsterAI",
	"horrorPacing",
	"execute",
	"effect",
}

local function validId(value: any): boolean
	return type(value) == "string" and value ~= "" and #value <= 140
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
	if not validId(beat.beatId) then
		return false, "beatId is required"
	end
	if beat.schemaKind ~= nil and not validId(beat.schemaKind) then
		return false, "schemaKind is invalid"
	end
	return Validation.safePayload(beat.metadata or {})
end

function Validation.storyGate(gate: any): (boolean, string?)
	if type(gate) ~= "table" then
		return false, "story gate must be a table"
	end
	if not validId(gate.gateId) then
		return false, "gateId is required"
	end
	if gate.beatId ~= nil and not validId(gate.beatId) then
		return false, "gate beatId is invalid"
	end
	return Validation.safePayload(gate.requirements or {})
end

function Validation.revealEligibility(reveal: any): (boolean, string?)
	if type(reveal) ~= "table" then
		return false, "reveal eligibility must be a table"
	end
	if not validId(reveal.revealId) then
		return false, "revealId is required"
	end
	if reveal.beatId ~= nil and not validId(reveal.beatId) then
		return false, "reveal beatId is invalid"
	end
	return Validation.safePayload(reveal.context or {})
end

function Validation.emotionalBeat(beat: any): (boolean, string?)
	if type(beat) ~= "table" then
		return false, "emotional beat must be a table"
	end
	if not validId(beat.emotionalBeatId) then
		return false, "emotionalBeatId is required"
	end
	if type(beat.pressureLimit) ~= "number" or beat.pressureLimit ~= beat.pressureLimit then
		return false, "pressureLimit must be a number"
	end
	if beat.pressureLimit < 0 or beat.pressureLimit > 100 then
		return false, "pressureLimit must be between 0 and 100"
	end
	return Validation.safePayload(beat.metadata or {})
end

function Validation.validate(): (boolean, string?)
	if Types.Mode ~= "ServerAuthoritativeNarrativeFoundation" then
		return false, "Narrative runtime must remain server-authoritative foundation mode"
	end
	return true, nil
end

return Validation
