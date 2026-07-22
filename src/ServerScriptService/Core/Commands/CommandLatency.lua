--!strict

local Serialization = require(script.Parent.CommandSerialization)

local Latency = {}
local buckets = {
	["0-1ms"] = 0,
	["1-5ms"] = 0,
	["5-10ms"] = 0,
	["10-25ms"] = 0,
	["25-50ms"] = 0,
	["50ms+"] = 0,
}

function Latency.record(duration: number)
	local milliseconds = duration * 1000
	if milliseconds <= 1 then
		buckets["0-1ms"] += 1
	elseif milliseconds <= 5 then
		buckets["1-5ms"] += 1
	elseif milliseconds <= 10 then
		buckets["5-10ms"] += 1
	elseif milliseconds <= 25 then
		buckets["10-25ms"] += 1
	elseif milliseconds <= 50 then
		buckets["25-50ms"] += 1
	else
		buckets["50ms+"] += 1
	end
end

function Latency.inspect()
	return Serialization.deepCopy(buckets)
end

function Latency.clear()
	for key in pairs(buckets) do
		buckets[key] = 0
	end
end

return Latency
