--!strict

local Evidence = require(script.Parent.PresentationEvidence)
local Metrics = require(script.Parent.PresentationMetrics)
local Serialization = require(script.Parent.DialogueSerialization)
local Types = require(script.Parent.DialoguePresentationTypes)

local Registry = {}
local byPresentation = {}
local order = {}

function Registry.register(presentationId: string, metadata: any)
	if type(presentationId) ~= "string" or presentationId == "" then
		return {
			ok = false,
			code = Types.FailureType.ValidationFailure,
			message = "invalid presentation id",
		}
	end
	if metadata == nil then
		metadata = {}
	end
	if type(metadata) ~= "table" then
		return {
			ok = false,
			code = Types.FailureType.ValidationFailure,
			message = "accessibility metadata must be a table",
		}
	end
	if byPresentation[presentationId] == nil then
		if #order >= Types.Limits.MaxAccessibilityEntries then
			return {
				ok = false,
				code = Types.FailureType.LimitExceeded,
				message = "accessibility limit exceeded",
			}
		end
		order[#order + 1] = presentationId
	end
	byPresentation[presentationId] = Serialization.deepCopy(metadata)
	Metrics.increment("accessibilityRecordsRegistered")
	Evidence.record("accessibility metadata registered", { presentationId = presentationId })
	return { ok = true, code = "Ok" }
end

function Registry.get(presentationId: string)
	return Serialization.deepCopy(byPresentation[presentationId] or {})
end

function Registry.inspect()
	local result = {}
	for index, presentationId in ipairs(order) do
		result[index] = {
			presentationId = presentationId,
			metadata = Serialization.deepCopy(byPresentation[presentationId]),
		}
	end
	return result
end

function Registry.clear()
	table.clear(byPresentation)
	table.clear(order)
end

return Registry
