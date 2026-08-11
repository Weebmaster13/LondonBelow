--!strict

local Evidence = require(script.Parent.VisualCompositionEvidence)
local Metrics = require(script.Parent.VisualCompositionMetrics)
local Serialization = require(script.Parent.PresentationSerialization)
local Types = require(script.Parent.PresentationTypes)
local Validation = require(script.Parent.VisualCompositionValidation)

local Registry = {}
local compositions = {}
local order = {}
local nextOrdinal = 0

function Registry.create(input: any)
	if #order >= Types.VisualCompositionLimits.MaxCompositionInstances then
		return {
			ok = false,
			code = Types.VisualCompositionFailureType.LimitExceeded,
			message = "composition limit exceeded",
		}
	end
	local ok, reason = Validation.validateComposition(input)
	if not ok then
		Evidence.record("composition rejected", { reason = reason, input = input })
		return {
			ok = false,
			code = Types.VisualCompositionFailureType.ValidationFailure,
			message = reason,
		}
	end
	if compositions[input.compositionInstanceId] ~= nil then
		return {
			ok = false,
			code = Types.VisualCompositionFailureType.DuplicateComposition,
			message = "duplicate composition",
		}
	end
	nextOrdinal += 1
	local composition = {
		compositionInstanceId = input.compositionInstanceId,
		compositionId = input.compositionId,
		robloxRenderingSessionId = input.robloxRenderingSessionId,
		renderingExecutionSessionId = input.renderingExecutionSessionId,
		renderingSessionId = input.renderingSessionId,
		presentationSessionId = input.presentationSessionId,
		rendererId = input.rendererId,
		owner = input.owner,
		revision = 0,
		lifecycleState = Types.VisualCompositionState.Created,
		creationOrdinal = nextOrdinal,
		layoutIntent = Serialization.deepCopy(input.layoutIntent or {}),
		stateVariants = Serialization.deepCopy(input.stateVariants or {}),
		accessibility = Serialization.deepCopy(input.accessibility or {}),
		runtimeMetadata = Serialization.deepCopy(input.runtimeMetadata or {}),
	}
	compositions[composition.compositionInstanceId] = composition
	order[#order + 1] = composition.compositionInstanceId
	Metrics.increment("compositionsCreated")
	Evidence.record("composition created", composition)
	return { ok = true, code = "Ok", composition = Serialization.deepCopy(composition) }
end

function Registry.get(compositionInstanceId: string)
	local composition = compositions[compositionInstanceId]
	if composition == nil then
		return nil
	end
	return Serialization.deepCopy(composition)
end

function Registry.update(compositionInstanceId: string, patch: any)
	local composition = compositions[compositionInstanceId]
	if composition == nil then
		return {
			ok = false,
			code = Types.VisualCompositionFailureType.UnknownComposition,
			message = "unknown composition",
		}
	end
	for key, value in pairs(patch) do
		composition[key] = Serialization.deepCopy(value)
	end
	return { ok = true, code = "Ok", composition = Serialization.deepCopy(composition) }
end

function Registry.inspect()
	local result = {}
	for index, id in ipairs(order) do
		result[index] = Serialization.deepCopy(compositions[id])
	end
	return result
end

function Registry.clear()
	table.clear(compositions)
	table.clear(order)
	nextOrdinal = 0
end

return Registry
