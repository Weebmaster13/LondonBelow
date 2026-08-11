--!strict

local Evidence = require(script.Parent.VisualCompositionEvidence)
local Metrics = require(script.Parent.VisualCompositionMetrics)
local Normalizer = require(script.Parent.VisualCompositionNormalizer)
local Serialization = require(script.Parent.PresentationSerialization)
local Types = require(script.Parent.PresentationTypes)
local Validation = require(script.Parent.VisualCompositionValidation)

local Registry = {}
local definitions = {}
local order = {}

function Registry.register(input: any)
	if #order >= Types.VisualCompositionLimits.MaxDefinitions then
		return {
			ok = false,
			code = Types.VisualCompositionFailureType.LimitExceeded,
			message = "definition limit exceeded",
		}
	end
	local ok, reason = Validation.validateDefinition(input)
	if not ok then
		Metrics.increment("definitionsRejected")
		Evidence.record("definition rejected", { reason = reason, input = input })
		return {
			ok = false,
			code = Types.VisualCompositionFailureType.ValidationFailure,
			message = reason,
		}
	end
	if definitions[input.compositionId] ~= nil then
		Metrics.increment("definitionsRejected")
		Evidence.record(
			"definition rejected",
			{ reason = "duplicate definition", compositionId = input.compositionId }
		)
		return {
			ok = false,
			code = Types.VisualCompositionFailureType.DuplicateDefinition,
			message = "duplicate definition",
		}
	end
	local definition = Normalizer.normalizeDefinition(input)
	definitions[definition.compositionId] = definition
	order[#order + 1] = definition.compositionId
	table.sort(order)
	Metrics.increment("definitionsRegistered")
	Evidence.record("definition registered", definition)
	return { ok = true, code = "Ok", definition = Serialization.deepCopy(definition) }
end

function Registry.unregister(compositionId: string)
	if definitions[compositionId] == nil then
		return {
			ok = false,
			code = Types.VisualCompositionFailureType.UnknownDefinition,
			message = "unknown definition",
		}
	end
	definitions[compositionId] = nil
	for index, id in ipairs(order) do
		if id == compositionId then
			table.remove(order, index)
			break
		end
	end
	Evidence.record("definition unregistered", { compositionId = compositionId })
	return { ok = true, code = "Ok" }
end

function Registry.get(compositionId: string)
	local definition = definitions[compositionId]
	if definition == nil then
		return nil
	end
	return Serialization.deepCopy(definition)
end

function Registry.inspect()
	local result = {}
	for index, id in ipairs(order) do
		result[index] = Serialization.deepCopy(definitions[id])
	end
	return result
end

function Registry.clear()
	table.clear(definitions)
	table.clear(order)
end

return Registry
