--!strict
--[[
	Performance counters for Observation Engine intake.

	Owns accepted/rejected counts, slow observation counts, total processing
	duration, and last error summaries.

	Does not own analytics, monetization telemetry, or player tracking exports.
	This is engine health instrumentation only.
]]

local ObservationConfig = require(script.Parent.ObservationConfig)

local ObservationProfiler = {}

local acceptedCount = 0
local rejectedCount = 0
local slowCount = 0
local totalDuration = 0
local lastRejection: { code: string, message: string }? = nil

function ObservationProfiler.recordAccepted(duration: number)
	acceptedCount += 1
	totalDuration += duration

	if duration * 1000 > ObservationConfig.ProfilerSlowObservationMs then
		slowCount += 1
	end
end

function ObservationProfiler.recordRejected(code: string, message: string)
	rejectedCount += 1
	lastRejection = {
		code = code,
		message = message,
	}
end

function ObservationProfiler.inspect()
	return {
		acceptedCount = acceptedCount,
		rejectedCount = rejectedCount,
		slowCount = slowCount,
		averageDurationMs = if acceptedCount > 0 then (totalDuration / acceptedCount) * 1000 else 0,
		lastRejection = lastRejection,
	}
end

function ObservationProfiler.clear()
	acceptedCount = 0
	rejectedCount = 0
	slowCount = 0
	totalDuration = 0
	lastRejection = nil
end

function ObservationProfiler.validate(): (boolean, string?)
	if acceptedCount < 0 or rejectedCount < 0 or slowCount < 0 then
		return false, "ObservationProfiler counters cannot be negative"
	end

	return true, nil
end

return ObservationProfiler
