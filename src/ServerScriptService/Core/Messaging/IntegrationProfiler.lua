--!strict

local Serialization = require(script.Parent.MessagingSerialization)

local Profiler = {}
local profile = {
	slowestInitialization = nil :: any?,
	longestShutdown = nil :: any?,
	mostConnectedConsumer = nil :: any?,
	largestDependencyTree = nil :: any?,
	busiestSubscriber = nil :: any?,
}

function Profiler.recordInitialization(consumerId: string, durationMs: number)
	if
		profile.slowestInitialization == nil
		or durationMs > profile.slowestInitialization.durationMs
	then
		profile.slowestInitialization = { consumerId = consumerId, durationMs = durationMs }
	end
end

function Profiler.recordShutdown(consumerId: string, durationMs: number)
	if profile.longestShutdown == nil or durationMs > profile.longestShutdown.durationMs then
		profile.longestShutdown = { consumerId = consumerId, durationMs = durationMs }
	end
end

function Profiler.inspect()
	return Serialization.deepCopy(profile)
end

function Profiler.clear()
	profile.slowestInitialization = nil
	profile.longestShutdown = nil
	profile.mostConnectedConsumer = nil
	profile.largestDependencyTree = nil
	profile.busiestSubscriber = nil
end

return Profiler
