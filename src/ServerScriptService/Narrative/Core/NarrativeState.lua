--!strict
-- Bounded state store for Narrative Runtime foundation.

local Serialization = require(script.Parent.NarrativeSerialization)
local Types = require(script.Parent.NarrativeTypes)

local State = {}

local beats: { [string]: any } = {}
local beatOrder: { string } = {}
local gates: { [string]: any } = {}
local gateOrder: { string } = {}
local reveals: { [string]: any } = {}
local revealOrder: { string } = {}
local emotionalProtections: { [string]: any } = {}
local emotionalOrder: { string } = {}
local validationFailures: { any } = {}
local snapshotHistory: { any } = {}

local function trimMap(order: { string }, map: { [string]: any }, limit: number)
	while #order > limit do
		local id = table.remove(order, 1)
		if id ~= nil then
			map[id] = nil
		end
	end
end

local function trimList(list: { any }, limit: number)
	while #list > limit do
		table.remove(list, 1)
	end
end

function State.addBeat(beat: any)
	beats[beat.beatId] = Serialization.deepCopy(beat)
	table.insert(beatOrder, beat.beatId)
	trimMap(beatOrder, beats, Types.Limits.MaxBeats)
end

function State.hasBeat(beatId: string): boolean
	return beats[beatId] ~= nil
end

function State.addGate(gate: any)
	gates[gate.gateId] = Serialization.deepCopy(gate)
	table.insert(gateOrder, gate.gateId)
	trimMap(gateOrder, gates, Types.Limits.MaxStoryGates)
end

function State.hasGate(gateId: string): boolean
	return gates[gateId] ~= nil
end

function State.addReveal(reveal: any)
	reveals[reveal.revealId] = Serialization.deepCopy(reveal)
	table.insert(revealOrder, reveal.revealId)
	trimMap(revealOrder, reveals, Types.Limits.MaxRevealEligibility)
end

function State.addEmotionalProtection(beat: any)
	emotionalProtections[beat.emotionalBeatId] = Serialization.deepCopy(beat)
	table.insert(emotionalOrder, beat.emotionalBeatId)
	trimMap(emotionalOrder, emotionalProtections, Types.Limits.MaxEmotionalProtections)
end

function State.recordValidationFailure(reason: string, payload: any?)
	table.insert(validationFailures, {
		reason = reason,
		payload = Serialization.diagnosticCopy(payload),
		createdAt = os.clock(),
	})
	trimList(validationFailures, Types.Limits.MaxValidationFailures)
end

function State.recordSnapshot(summary: any)
	table.insert(snapshotHistory, Serialization.deepCopy(summary))
	trimList(snapshotHistory, Types.Limits.MaxSnapshotHistory)
end

function State.clear()
	table.clear(beats)
	table.clear(beatOrder)
	table.clear(gates)
	table.clear(gateOrder)
	table.clear(reveals)
	table.clear(revealOrder)
	table.clear(emotionalProtections)
	table.clear(emotionalOrder)
	table.clear(validationFailures)
	table.clear(snapshotHistory)
end

function State.inspect()
	return {
		beatCount = #beatOrder,
		gateCount = #gateOrder,
		revealEligibilityCount = #revealOrder,
		emotionalProtectionCount = #emotionalOrder,
		beats = Serialization.deepCopy(beats),
		storyGates = Serialization.deepCopy(gates),
		revealEligibility = Serialization.deepCopy(reveals),
		emotionalProtections = Serialization.deepCopy(emotionalProtections),
		validationFailures = Serialization.deepCopy(validationFailures),
		snapshotHistory = Serialization.deepCopy(snapshotHistory),
		limits = Serialization.deepCopy(Types.Limits),
	}
end

return State
