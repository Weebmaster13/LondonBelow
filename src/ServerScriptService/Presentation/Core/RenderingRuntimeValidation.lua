--!strict

local RuntimeCapability = require(script.Parent.RenderingRuntimeCapabilityRegistry)
local Sessions = require(script.Parent.RenderingSessionRegistry)
local Types = require(script.Parent.PresentationTypes)

local Validation = {}

function Validation.validate(): (boolean, string?)
	local runtime = RuntimeCapability.inspect()
	if runtime == nil then
		return false, "rendering runtime capability is not registered"
	end
	if runtime.providerName ~= Types.RenderingRuntimeProviderName then
		return false, "rendering runtime provider mismatch"
	end
	for _, session in ipairs(Sessions.inspect()) do
		if not Types.isRenderingKind(session.renderingKind) then
			return false, "invalid rendering kind in session"
		end
		if not Types.isRenderingRuntimeLifecycleState(session.lifecycleState) then
			return false, "invalid lifecycle state in session"
		end
		if not Types.isRenderingRuntimeAssignmentState(session.assignmentState) then
			return false, "invalid assignment state in session"
		end
	end
	return true, nil
end

return Validation
