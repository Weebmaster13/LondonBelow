--!strict

local Evidence = require(script.Parent.VisualCompositionEvidence)
local Metrics = require(script.Parent.VisualCompositionMetrics)
local Serialization = require(script.Parent.PresentationSerialization)
local Types = require(script.Parent.PresentationTypes)

local Revisions = {}
local revisions = {}

function Revisions.current(compositionInstanceId: string): number
	return revisions[compositionInstanceId] or 0
end

function Revisions.commit(compositionInstanceId: string, expectedRevision: number)
	local current = Revisions.current(compositionInstanceId)
	if current ~= expectedRevision then
		Metrics.increment("staleRevisionRejections")
		Evidence.record("stale revision rejected", {
			compositionInstanceId = compositionInstanceId,
			expectedRevision = expectedRevision,
			currentRevision = current,
		})
		return {
			ok = false,
			code = Types.VisualCompositionFailureType.StaleRevision,
			message = "stale revision",
		}
	end
	revisions[compositionInstanceId] = current + 1
	Evidence.record("revision committed", {
		compositionInstanceId = compositionInstanceId,
		revision = current + 1,
	})
	return { ok = true, code = "Ok", revision = current + 1 }
end

function Revisions.inspect()
	return Serialization.deepCopy(revisions)
end

function Revisions.clear()
	table.clear(revisions)
end

return Revisions
