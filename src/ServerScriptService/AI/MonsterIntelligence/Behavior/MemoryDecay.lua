--!strict
-- Shared decay math for memory-like confidence values.

local Config = require(script.Parent.Parent.Core.MonsterConfig)

local MemoryDecay = {}

function MemoryDecay.apply(confidence: number, deltaSeconds: number): number
	return math.clamp(confidence - Config.MemoryDecayPerSecond * math.max(0, deltaSeconds), 0, 1)
end

function MemoryDecay.isStale(confidence: number): boolean
	return confidence <= 0.01
end

return MemoryDecay
