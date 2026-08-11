--!strict

local Evidence = require(script.Parent.VisualCompositionEvidence)
local Serialization = require(script.Parent.PresentationSerialization)
local Types = require(script.Parent.PresentationTypes)

local Bindings = {}
local byComposition = {}
local byRobloxSession = {}

function Bindings.bind(composition: any)
	local existing = byRobloxSession[composition.robloxRenderingSessionId]
	if existing ~= nil and existing ~= composition.compositionInstanceId then
		return {
			ok = false,
			code = Types.VisualCompositionFailureType.BindingConflict,
			message = "duplicate rendering session binding",
		}
	end
	local binding = {
		compositionInstanceId = composition.compositionInstanceId,
		robloxRenderingSessionId = composition.robloxRenderingSessionId,
		renderingExecutionSessionId = composition.renderingExecutionSessionId,
		renderingSessionId = composition.renderingSessionId,
		presentationSessionId = composition.presentationSessionId,
	}
	byComposition[binding.compositionInstanceId] = binding
	byRobloxSession[binding.robloxRenderingSessionId] = binding.compositionInstanceId
	Evidence.record("composition bound", binding)
	return { ok = true, code = "Ok", binding = Serialization.deepCopy(binding) }
end

function Bindings.get(compositionInstanceId: string)
	local binding = byComposition[compositionInstanceId]
	if binding == nil then
		return nil
	end
	return Serialization.deepCopy(binding)
end

function Bindings.inspect()
	local result = {}
	for _, binding in pairs(byComposition) do
		result[#result + 1] = Serialization.deepCopy(binding)
	end
	table.sort(result, function(left, right)
		return left.compositionInstanceId < right.compositionInstanceId
	end)
	return result
end

function Bindings.clear()
	table.clear(byComposition)
	table.clear(byRobloxSession)
end

return Bindings
