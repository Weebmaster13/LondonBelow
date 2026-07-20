--!strict

local ServerScriptService = game:GetService("ServerScriptService")

local Serialization =
	require(ServerScriptService.Interaction.Environmental.EnvironmentalSerialization)

local Types = require(script.Parent.Chapter0EnvironmentalTypes)

local State = {}

local bindings: { [string]: any } = {}
local evidence: { any } = {}
local failures: { any } = {}
local snapshots: { any } = {}
local revision = 0
local status = Types.ReadinessStatus.NotInitialized

local function count(map: { [string]: any }): number
	local total = 0
	for _ in pairs(map) do
		total += 1
	end
	return total
end

local function trim(list: { any }, limit: number)
	while #list > limit do
		table.remove(list, 1)
	end
end

function State.setStatus(nextStatus: string)
	status = nextStatus
	revision += 1
end

function State.bind(fixture: any, bindingStatus: string, reason: string?)
	bindings[fixture.id] = {
		fixtureId = fixture.id,
		family = fixture.family,
		targetId = fixture.interactionTargetId,
		authoredInstanceId = fixture.authoringMetadata.authoredInstanceId,
		required = fixture.authoringMetadata.authoredInstanceRequired,
		status = bindingStatus,
		reason = reason,
		revision = revision + 1,
	}
	revision += 1
end

function State.recordEvidence(event: string, payload: any)
	table.insert(evidence, {
		event = event,
		payload = Serialization.deepCopy(payload),
		recordedAt = os.clock(),
	})
	trim(evidence, Types.Limits.MaxEvidence)
end

function State.recordFailure(code: string, detail: any?)
	table.insert(failures, {
		code = code,
		detail = Serialization.deepCopy(detail),
		recordedAt = os.clock(),
	})
	trim(failures, Types.Limits.MaxFailures)
end

function State.recordSnapshot(snapshot: any)
	table.insert(snapshots, Serialization.deepCopy(snapshot))
	trim(snapshots, Types.Limits.MaxSnapshots)
end

function State.inspect()
	return {
		status = status,
		revision = revision,
		bindings = Serialization.deepCopy(bindings),
		evidence = Serialization.deepCopy(evidence),
		failures = Serialization.deepCopy(failures),
		snapshots = Serialization.deepCopy(snapshots),
		counts = {
			bindings = count(bindings),
			evidence = #evidence,
			failures = #failures,
			snapshots = #snapshots,
		},
	}
end

function State.clear()
	table.clear(bindings)
	table.clear(evidence)
	table.clear(failures)
	table.clear(snapshots)
	revision = 0
	status = Types.ReadinessStatus.NotInitialized
end

return State
