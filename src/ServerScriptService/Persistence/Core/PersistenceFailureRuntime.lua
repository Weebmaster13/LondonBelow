--!strict
-- Failure records are diagnostic records only; Phase 162 also classifies adapter failures.

local Types = require(script.Parent.PersistenceTypes)

local Runtime = {}

function Runtime.record(state: any, record: any): (boolean, string?)
	return state.recordFailure(record)
end

function Runtime.classify(reason: string?): string
	if reason == nil then
		return Types.FailureKind.StorageFailure
	end
	if string.find(reason, "validation", 1, true) or string.find(reason, "invalid", 1, true) then
		return Types.FailureKind.ValidationFailure
	elseif string.find(reason, "provider", 1, true) then
		return Types.FailureKind.ProviderUnavailable
	elseif string.find(reason, "serialization", 1, true) then
		return Types.FailureKind.SerializationFailure
	elseif string.find(reason, "migration", 1, true) then
		return Types.FailureKind.MigrationFailure
	elseif
		string.find(reason, "Unsupported", 1, true) or string.find(reason, "NotSupported", 1, true)
	then
		return Types.FailureKind.UnsupportedOperation
	elseif string.find(reason, "Timeout", 1, true) or string.find(reason, "timeout", 1, true) then
		return Types.FailureKind.Timeout
	end
	return Types.FailureKind.StorageFailure
end

return Runtime
