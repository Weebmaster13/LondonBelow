--!strict

local Contracts = require(script.Parent.RenderingContractRegistry)
local Requests = require(script.Parent.RenderingRequestRegistry)
local Types = require(script.Parent.PresentationTypes)

local Validation = {}

function Validation.validate(): (boolean, string?)
	local contract = Contracts.get(Types.RenderingContractId)
	if contract == nil then
		return false, "default rendering contract is not registered"
	end
	if contract.providerName ~= Types.RenderingContractProviderName then
		return false, "rendering contract provider mismatch"
	end
	for _, request in ipairs(Requests.inspect()) do
		if not Types.isRenderingKind(request.renderingKind) then
			return false, "invalid rendering kind in registered request"
		end
		if not Types.isRenderingSynchronizationPolicy(request.synchronizationPolicy) then
			return false, "invalid synchronization policy in registered request"
		end
		if type(request.executionSessionId) ~= "string" or request.executionSessionId == "" then
			return false, "request is missing execution linkage"
		end
	end
	return true, nil
end

return Validation
