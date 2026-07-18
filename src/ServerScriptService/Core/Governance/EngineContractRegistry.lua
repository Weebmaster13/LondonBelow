--!strict
--[[
	Registry of London Engine subsystem contracts.

	Owns contract registration, replacement, lookup, inspection, and the built-in
	contracts for the current major systems.

	Does not validate contract law by itself; validation belongs to
	EngineContractValidator and scoring belongs to EngineScorecard.
]]

local Types = require(script.Parent.EngineContractTypes)

local EngineContractRegistry = {}

type EngineContract = Types.EngineContract

local contracts: { [string]: EngineContract } = {}
local registrationOrder: { string } = {}

local function copyArray<T>(values: { T }): { T }
	return table.clone(values)
end

local function copyObservationRules(values: { Types.ObservationRule }): { Types.ObservationRule }
	local copied = {}

	for _, rule in ipairs(values) do
		table.insert(copied, {
			id = rule.id,
			when = rule.when,
			required = rule.required,
		})
	end

	return copied
end

local function copyApprovalRules(
	values: { Types.DirectorApprovalRule }
): { Types.DirectorApprovalRule }
	local copied = {}

	for _, rule in ipairs(values) do
		table.insert(copied, {
			director = rule.director,
			reason = rule.reason,
			requiredFor = copyArray(rule.requiredFor),
		})
	end

	return copied
end

local function copyExecutionPermissions(
	values: { Types.ExecutionPermission }
): { Types.ExecutionPermission }
	local copied = {}

	for _, permission in ipairs(values) do
		table.insert(copied, {
			action = permission.action,
			requiresApproval = permission.requiresApproval,
			approval = permission.approval,
		})
	end

	return copied
end

local function cloneContract(contract: EngineContract): EngineContract
	return {
		systemName = contract.systemName,
		ownerLayer = contract.ownerLayer,
		status = contract.status,
		responsibilities = copyArray(contract.responsibilities),
		doesNotOwn = copyArray(contract.doesNotOwn),
		dependencies = copyArray(contract.dependencies),
		observationsEmitted = copyObservationRules(contract.observationsEmitted),
		directorApprovalsRequired = copyApprovalRules(contract.directorApprovalsRequired),
		executionPermissions = copyExecutionPermissions(contract.executionPermissions),
		clientPresentation = {
			allowed = contract.clientPresentation.allowed,
			description = contract.clientPresentation.description,
			mustBeServerApproved = contract.clientPresentation.mustBeServerApproved,
		},
		diagnosticsExposed = copyArray(contract.diagnosticsExposed),
		snapshotProviders = copyArray(contract.snapshotProviders),
		cleanupBehavior = copyArray(contract.cleanupBehavior),
		multiplayerGuarantees = copyArray(contract.multiplayerGuarantees),
		failureModes = copyArray(contract.failureModes),
		documentation = copyArray(contract.documentation),
		tags = copyArray(contract.tags),
	}
end

local function registerBuiltIn(contract: EngineContract)
	contracts[contract.systemName] = cloneContract(contract)
	table.insert(registrationOrder, contract.systemName)
end

local ContractCatalog = require(script.Parent.Contracts.ContractCatalog)
local builtInContracts: { EngineContract } = ContractCatalog.getBuiltInContracts()

function EngineContractRegistry.register(contract: EngineContract): boolean
	assert(type(contract) == "table", "contract must be a table")
	assert(
		type(contract.systemName) == "string" and contract.systemName ~= "",
		"contract.systemName is required"
	)

	if contracts[contract.systemName] == nil then
		table.insert(registrationOrder, contract.systemName)
	end

	contracts[contract.systemName] = cloneContract(contract)
	return true
end

function EngineContractRegistry.replace(contract: EngineContract): boolean
	assert(type(contract) == "table", "contract must be a table")
	assert(
		type(contract.systemName) == "string" and contract.systemName ~= "",
		"contract.systemName is required"
	)

	if contracts[contract.systemName] == nil then
		return false
	end

	contracts[contract.systemName] = cloneContract(contract)
	return true
end

function EngineContractRegistry.get(systemName: string): EngineContract?
	local contract = contracts[systemName]

	if contract == nil then
		return nil
	end

	return cloneContract(contract)
end

function EngineContractRegistry.getAll(): { EngineContract }
	local all = {}

	for _, systemName in ipairs(registrationOrder) do
		local contract = contracts[systemName]

		if contract ~= nil then
			table.insert(all, cloneContract(contract))
		end
	end

	return all
end

function EngineContractRegistry.registerBuiltIns()
	for _, contract in ipairs(builtInContracts) do
		if contracts[contract.systemName] == nil then
			registerBuiltIn(contract)
		end
	end
end

function EngineContractRegistry.clear()
	table.clear(contracts)
	table.clear(registrationOrder)
end

function EngineContractRegistry.inspect()
	return {
		count = #registrationOrder,
		order = table.clone(registrationOrder),
		contracts = EngineContractRegistry.getAll(),
	}
end

function EngineContractRegistry.validate(): (boolean, string?)
	local seen = {}

	for _, systemName in ipairs(registrationOrder) do
		if seen[systemName] then
			return false, "Duplicate governance registration: " .. systemName
		end

		if contracts[systemName] == nil then
			return false, "Governance registration missing contract: " .. systemName
		end

		seen[systemName] = true
	end

	return true, nil
end

return EngineContractRegistry
