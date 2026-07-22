--!strict

local Serialization = require(script.Parent.CommandSerialization)
local Types = require(script.Parent.CommandTypes)

local Policy = {}

function Policy.normalize(definition: any): any
	return Serialization.deepCopy({
		executionPolicy = definition.executionMode or Types.ExecutionMode.Immediate,
		retryPolicy = definition.retryPolicy or Types.RetryPolicy.NeverRetry,
		timeoutBudget = definition.timeoutBudget or Types.Limits.DefaultExecutionBudget,
		lockIds = definition.lockIds or {},
		replayPolicy = definition.commandReplayPolicy
			or Types.CommandReplayPolicy.ReplayMetadataOnly,
		transactional = definition.executionMode == Types.ExecutionMode.Transactional,
		batched = definition.executionMode == Types.ExecutionMode.Batch,
	})
end

function Policy.validate(policy: any): (boolean, string?)
	if Types.ExecutionMode[policy.executionPolicy] ~= policy.executionPolicy then
		return false, "invalid execution policy"
	end
	if Types.RetryPolicy[policy.retryPolicy] ~= policy.retryPolicy then
		return false, "invalid retry policy"
	end
	if Types.CommandReplayPolicy[policy.replayPolicy] ~= policy.replayPolicy then
		return false, "invalid replay policy"
	end
	if type(policy.timeoutBudget) ~= "number" or policy.timeoutBudget < 1 then
		return false, "invalid timeout budget"
	end
	if type(policy.lockIds) ~= "table" or #policy.lockIds > Types.Limits.MaxLocksPerCommand then
		return false, "invalid lock ids"
	end
	return true, nil
end

return Policy
