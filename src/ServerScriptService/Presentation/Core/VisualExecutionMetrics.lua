--!strict

local Serialization = require(script.Parent.PresentationSerialization)

local Metrics = {}
local counters = {}

function Metrics.increment(name: string, amount: number?)
	counters[name] = (counters[name] or 0) + (amount or 1)
end

function Metrics.inspect()
	return Serialization.deepCopy(counters)
end

function Metrics.clear()
	table.clear(counters)
end

return Metrics
