--!strict

local Serialization = require(script.Parent.PresentationSerialization)
local Types = require(script.Parent.PresentationTypes)

local Intake = {}

local function validString(value: any): boolean
	return type(value) == "string" and value ~= ""
end

function Intake.validate(request: any)
	if type(request) ~= "table" then
		return {
			ok = false,
			code = Types.RenderingRuntimeFailureType.InvalidRenderingRequest,
			message = "rendering request must be a table",
		}
	end
	for _, field in ipairs({
		"renderingRequestId",
		"executionSessionId",
		"presentationSessionId",
		"renderingKind",
	}) do
		if not validString(request[field]) then
			return {
				ok = false,
				code = Types.RenderingRuntimeFailureType.InvalidRenderingRequest,
				message = "invalid field " .. field,
			}
		end
	end
	if not Types.isRenderingKind(request.renderingKind) then
		return {
			ok = false,
			code = Types.RenderingRuntimeFailureType.InvalidRenderingRequest,
			message = "invalid rendering kind",
		}
	end
	if
		request.synchronizationPolicy ~= nil
		and not Types.isRenderingSynchronizationPolicy(request.synchronizationPolicy)
	then
		return {
			ok = false,
			code = Types.RenderingRuntimeFailureType.InvalidRenderingRequest,
			message = "invalid synchronization policy",
		}
	end
	local serializable, reason = Serialization.validateSerializable(request.runtimeMetadata or {})
	if not serializable then
		return {
			ok = false,
			code = Types.RenderingRuntimeFailureType.InvalidRenderingRequest,
			message = reason,
		}
	end
	return { ok = true, code = "Ok" }
end

return Intake
