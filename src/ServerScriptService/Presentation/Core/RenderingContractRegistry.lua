--!strict

local Evidence = require(script.Parent.RenderingEvidence)
local Metrics = require(script.Parent.RenderingMetrics)
local Serialization = require(script.Parent.PresentationSerialization)
local Types = require(script.Parent.PresentationTypes)

local Registry = {}
local contracts = {}
local defaultRegistered = false

local function defaultContract()
	return {
		contractId = Types.RenderingContractId,
		version = "1.0.0",
		providerName = Types.RenderingContractProviderName,
		owner = "Presentation",
		domain = "PresentationRendering",
		authority = "Server",
		dependencies = {
			"Presentation Runtime Capability Foundation",
			"Presentation Runtime Execution and Session Management",
			"Dialogue Presentation Contract Foundation",
			"Runtime Domain Capability Foundation",
			"Workflow Runtime",
			"Messaging Runtime",
		},
		snapshotProvider = Types.RenderingContractSnapshotProviderName,
		diagnosticsProvider = Types.RenderingContractProviderName,
		phase = 178,
		certificationStatus = "ProductionCandidate",
	}
end

function Registry.registerDefault()
	if defaultRegistered then
		return {
			ok = false,
			code = Types.RenderingContractFailureType.DuplicateContract,
			message = "default rendering contract already registered",
		}
	end
	local contract = defaultContract()
	contracts[contract.contractId] = contract
	defaultRegistered = true
	Metrics.increment("contractsRegistered")
	Evidence.record("rendering contract registered", contract)
	return { ok = true, code = "Ok", contract = Serialization.deepCopy(contract) }
end

function Registry.get(contractId: string)
	return Serialization.deepCopy(contracts[contractId])
end

function Registry.inspect()
	return Serialization.deepCopy(contracts)
end

function Registry.clear()
	table.clear(contracts)
	defaultRegistered = false
end

return Registry
