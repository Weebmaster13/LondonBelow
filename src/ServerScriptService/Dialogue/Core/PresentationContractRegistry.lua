--!strict

local Evidence = require(script.Parent.PresentationEvidence)
local Metrics = require(script.Parent.PresentationMetrics)
local Serialization = require(script.Parent.DialogueSerialization)
local Types = require(script.Parent.DialoguePresentationTypes)

local Registry = {}
local contracts = {}
local order = {}

function Registry.register(contract: any)
	if #order >= Types.Limits.MaxContracts then
		return {
			ok = false,
			code = Types.FailureType.LimitExceeded,
			message = "contract limit exceeded",
		}
	end
	if type(contract) ~= "table" then
		return {
			ok = false,
			code = Types.FailureType.ValidationFailure,
			message = "contract must be a table",
		}
	end
	for _, field in ipairs({
		"contractId",
		"version",
		"owner",
		"domain",
		"authority",
		"providerName",
	}) do
		if type(contract[field]) ~= "string" or contract[field] == "" then
			return {
				ok = false,
				code = Types.FailureType.ValidationFailure,
				message = "invalid field " .. field,
			}
		end
	end
	if contracts[contract.contractId] ~= nil then
		return {
			ok = false,
			code = Types.FailureType.DuplicateContract,
			message = "duplicate contract",
		}
	end
	contracts[contract.contractId] = Serialization.deepCopy(contract)
	order[#order + 1] = contract.contractId
	Metrics.increment("contractsRegistered")
	Evidence.record("contract registered", { contractId = contract.contractId })
	return { ok = true, code = "Ok", contract = Serialization.deepCopy(contract) }
end

function Registry.get(contractId: string)
	local contract = contracts[contractId]
	return if contract then Serialization.deepCopy(contract) else nil
end

function Registry.inspect()
	local result = {}
	for index, contractId in ipairs(order) do
		result[index] = Serialization.deepCopy(contracts[contractId])
	end
	return result
end

function Registry.clear()
	table.clear(contracts)
	table.clear(order)
end

return Registry
