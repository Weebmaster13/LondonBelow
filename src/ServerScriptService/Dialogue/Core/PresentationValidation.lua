--!strict

local Acknowledgements = require(script.Parent.PresentationAcknowledgementRegistry)
local Contracts = require(script.Parent.PresentationContractRegistry)
local Requests = require(script.Parent.PresentationRequestRegistry)
local Synchronization = require(script.Parent.PresentationSynchronizationManager)

local Validation = {}

function Validation.validateRuntime()
	for _, contract in ipairs(Contracts.inspect()) do
		if type(contract.contractId) ~= "string" or contract.contractId == "" then
			return false, "invalid contract identity"
		end
	end
	for _, request in ipairs(Requests.inspect()) do
		if type(request.presentationId) ~= "string" or request.presentationId == "" then
			return false, "invalid presentation identity"
		end
		if type(request.executionId) ~= "string" or request.executionId == "" then
			return false, "invalid execution identity"
		end
	end
	for _, acknowledgement in ipairs(Acknowledgements.inspect()) do
		local request = Requests.get(acknowledgement.presentationId)
		if request == nil then
			return false, "acknowledgement missing request"
		end
		if request.executionId ~= acknowledgement.executionId then
			return false, "acknowledgement execution mismatch"
		end
	end
	for _, record in ipairs(Synchronization.inspect()) do
		if Requests.get(record.presentationId) == nil then
			return false, "synchronization record missing request"
		end
	end
	return true, nil
end

return Validation
