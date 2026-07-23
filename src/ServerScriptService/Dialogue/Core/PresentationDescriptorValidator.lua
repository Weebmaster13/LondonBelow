--!strict

local Metrics = require(script.Parent.PresentationMetrics)
local Serialization = require(script.Parent.DialogueSerialization)
local Types = require(script.Parent.DialoguePresentationTypes)

local Validator = {}

local function fail(code: string, message: string)
	Metrics.increment("validationFailures")
	return { ok = false, code = code, message = message }
end

local function validatePayload(
	value: any,
	depth: number,
	seen: { [any]: boolean },
	count: { value: number }
)
	if depth > Types.Limits.MaxPayloadDepth then
		return false, "payload depth exceeded"
	end
	local valueType = type(value)
	if valueType == "function" or valueType == "thread" or valueType == "userdata" then
		return false, "payload contains executable or external value"
	end
	if valueType == "string" and #value > Types.Limits.MaxStringLength then
		return false, "string length exceeded"
	end
	if valueType ~= "table" then
		return true, nil
	end
	if seen[value] then
		return false, "cyclic payload"
	end
	seen[value] = true
	local fields = 0
	for key, child in pairs(value) do
		fields += 1
		count.value += 1
		if
			fields > Types.Limits.MaxDescriptorFields
			or count.value > Types.Limits.MaxPayloadNodes
		then
			return false, "payload size exceeded"
		end
		local keyOk, keyReason = validatePayload(key, depth + 1, seen, count)
		if not keyOk then
			return false, keyReason
		end
		local childOk, childReason = validatePayload(child, depth + 1, seen, count)
		if not childOk then
			return false, childReason
		end
	end
	seen[value] = nil
	return true, nil
end

function Validator.validateDescriptor(kind: string, descriptor: any)
	if not Types.isPresentationKind(kind) then
		return fail(Types.FailureType.InvalidPresentationKind, "unsupported presentation kind")
	end
	if type(descriptor) ~= "table" then
		return fail(Types.FailureType.InvalidDescriptor, "descriptor must be a table")
	end
	local ok, reason = validatePayload(descriptor, 0, {}, { value = 0 })
	if not ok then
		return fail(Types.FailureType.InvalidDescriptor, reason or "invalid descriptor")
	end
	return { ok = true, code = "Ok", descriptor = Serialization.deepCopy(descriptor) }
end

return Validator
