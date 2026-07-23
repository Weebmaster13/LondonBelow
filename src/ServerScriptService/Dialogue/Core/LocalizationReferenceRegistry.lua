--!strict

local Evidence = require(script.Parent.PresentationEvidence)
local Metrics = require(script.Parent.PresentationMetrics)
local Serialization = require(script.Parent.DialogueSerialization)
local Types = require(script.Parent.DialoguePresentationTypes)

local Registry = {}
local byPresentation = {}
local order = {}

function Registry.register(presentationId: string, references: any)
	if type(presentationId) ~= "string" or presentationId == "" then
		return {
			ok = false,
			code = Types.FailureType.ValidationFailure,
			message = "invalid presentation id",
		}
	end
	if references == nil then
		references = {}
	end
	if type(references) ~= "table" then
		return {
			ok = false,
			code = Types.FailureType.ValidationFailure,
			message = "localization references must be a table",
		}
	end
	if byPresentation[presentationId] == nil then
		if #order >= Types.Limits.MaxLocalizationReferences then
			return {
				ok = false,
				code = Types.FailureType.LimitExceeded,
				message = "localization limit exceeded",
			}
		end
		order[#order + 1] = presentationId
	end
	byPresentation[presentationId] = Serialization.deepCopy(references)
	Metrics.increment("localizationReferencesRegistered")
	Evidence.record("localization references registered", { presentationId = presentationId })
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
			references = Serialization.deepCopy(byPresentation[presentationId]),
		}
	end
	return result
end

function Registry.clear()
	table.clear(byPresentation)
	table.clear(order)
end

return Registry
