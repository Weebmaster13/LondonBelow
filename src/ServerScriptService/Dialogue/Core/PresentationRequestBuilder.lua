--!strict

local DescriptorValidator = require(script.Parent.PresentationDescriptorValidator)
local Serialization = require(script.Parent.DialogueSerialization)
local Types = require(script.Parent.DialoguePresentationTypes)

local Builder = {}

local function invalid(message: string, code: string?)
	return { ok = false, code = code or Types.FailureType.ValidationFailure, message = message }
end

function Builder.build(input: any)
	if type(input) ~= "table" then
		return invalid("presentation request must be a table")
	end
	for _, field in ipairs({
		"presentationId",
		"executionId",
		"conversationId",
		"dialogueId",
		"nodeId",
		"speakerId",
		"presentationKind",
		"synchronizationPolicy",
	}) do
		if type(input[field]) ~= "string" or input[field] == "" then
			return invalid("invalid field " .. field)
		end
	end
	if not Types.isPresentationKind(input.presentationKind) then
		return invalid("unsupported presentation kind", Types.FailureType.InvalidPresentationKind)
	end
	if not Types.isSynchronizationPolicy(input.synchronizationPolicy) then
		return invalid(
			"unsupported synchronization policy",
			Types.FailureType.InvalidSynchronizationPolicy
		)
	end
	local descriptor =
		DescriptorValidator.validateDescriptor(input.presentationKind, input.descriptor)
	if not descriptor.ok then
		return descriptor
	end
	return {
		ok = true,
		code = "Ok",
		request = {
			presentationId = input.presentationId,
			executionId = input.executionId,
			conversationId = input.conversationId,
			dialogueId = input.dialogueId,
			nodeId = input.nodeId,
			speakerId = input.speakerId,
			presentationKind = input.presentationKind,
			descriptor = descriptor.descriptor,
			synchronizationPolicy = input.synchronizationPolicy,
			localizationReferences = Serialization.deepCopy(input.localizationReferences or {}),
			accessibilityMetadata = Serialization.deepCopy(input.accessibilityMetadata or {}),
			runtimeMetadata = Serialization.deepCopy(input.runtimeMetadata or {}),
			status = Types.RequestStatus.Created,
		},
	}
end

return Builder
