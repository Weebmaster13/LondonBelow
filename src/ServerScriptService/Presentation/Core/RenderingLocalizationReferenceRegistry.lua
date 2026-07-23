--!strict

local Metrics = require(script.Parent.RenderingMetrics)
local Serialization = require(script.Parent.PresentationSerialization)
local Types = require(script.Parent.PresentationTypes)

local Registry = {}
local references = {}

local function validId(value: any): boolean
	return type(value) == "string" and value ~= ""
end

function Registry.register(requestId: string, items: any)
	if items == nil then
		return { ok = true, references = {} }
	end
	if type(items) ~= "table" then
		return {
			ok = false,
			code = Types.RenderingContractFailureType.ValidationFailure,
			message = "localization references must be a table",
		}
	end
	if #references + #items > Types.RenderingContractLimits.MaxLocalizationReferences then
		return {
			ok = false,
			code = Types.RenderingContractFailureType.LimitExceeded,
			message = "localization reference limit exceeded",
		}
	end
	local copied = {}
	for index, item in ipairs(items) do
		if not validId(item) then
			return {
				ok = false,
				code = Types.RenderingContractFailureType.ValidationFailure,
				message = "invalid localization reference",
			}
		end
		copied[index] = item
	end
	references[requestId] = copied
	Metrics.increment("localizationReferencesRegistered")
	return { ok = true, references = Serialization.deepCopy(copied) }
end

function Registry.inspect()
	return Serialization.deepCopy(references)
end

function Registry.clear()
	table.clear(references)
end

return Registry
