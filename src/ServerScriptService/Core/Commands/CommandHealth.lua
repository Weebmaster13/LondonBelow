--!strict

local Serialization = require(script.Parent.CommandSerialization)

local Health = {}

local function posture(warning: boolean, critical: boolean): string
	if critical then
		return "Critical"
	end
	if warning then
		return "Warning"
	end
	return "Healthy"
end

function Health.calculate(counters: any, metrics: any): any
	local queueUtilization = if metrics.maximumQueueDepth > 0
		then math.min(100, metrics.maximumQueueDepth)
		else 0
	local failureRate = if metrics.executed > 0 then metrics.failed / metrics.executed else 0
	return Serialization.deepCopy({
		queueHealth = posture(queueUtilization > 120, queueUtilization > 200),
		executionHealth = posture(failureRate > 0.05, failureRate > 0.25),
		lockHealth = posture((counters.lockFailures or 0) > 0, (counters.lockFailures or 0) > 10),
		retryHealth = posture(
			(counters.queuedRetries or 0) > 0,
			(counters.retryLimitExceeded or 0) > 0
		),
		transactionHealth = posture(
			(counters.rollbackFailures or 0) > 0,
			(counters.transactionFailures or 0) > 0
		),
		replayHealth = "Healthy",
		recoveryHealth = posture((counters.interruptedCommands or 0) > 0, false),
	})
end

return Health
