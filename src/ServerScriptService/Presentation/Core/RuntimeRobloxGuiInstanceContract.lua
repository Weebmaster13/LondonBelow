--!strict

local Catalog = require(script.Parent.RobloxGuiInstanceCatalog)
local Serialization = require(script.Parent.PresentationSerialization)
local Types = require(script.Parent.RobloxGuiInstanceContractTypes)
local Validation = require(script.Parent.RobloxGuiInstanceContractValidation)

local Runtime = {}
local shutdown = false
local contracts = {}
local audit = {}
local failures = {}
local counters = {
	registered = 0,
	validated = 0,
	published = 0,
	rejected = 0,
	retired = 0,
	duplicateRejections = 0,
	illegalTransitions = 0,
	budgetRejections = 0,
}
local allowedTransitions = {
	[Types.ContractState.Draft] = {
		[Types.ContractState.Validated] = true,
		[Types.ContractState.Rejected] = true,
	},
	[Types.ContractState.Validated] = {
		[Types.ContractState.Published] = true,
		[Types.ContractState.Rejected] = true,
	},
	[Types.ContractState.Published] = { [Types.ContractState.Retired] = true },
	[Types.ContractState.Rejected] = {},
	[Types.ContractState.Retired] = {},
}

local function copy(value)
	return Serialization.deepCopy(value)
end
local function record(kind: string, contractId: string, detail: any?)
	if #audit >= Types.Limits.maxAuditRecords then
		table.remove(audit, 1)
	end
	audit[#audit + 1] = table.freeze({
		sequence = #audit + 1,
		kind = kind,
		contractId = contractId,
		detail = Serialization.diagnosticCopy(detail or {}),
	})
end
local function fail(code: string, message: string, contractId: string?)
	if #failures >= Types.Limits.maxFailures then
		table.remove(failures, 1)
	end
	local failure = table.freeze({
		sequence = #failures + 1,
		code = code,
		message = message,
		contractId = contractId,
	})
	failures[#failures + 1] = failure
	record("Failure", contractId or "none", failure)
	return { ok = false, code = code, message = message }
end

function Runtime.register(contract: any)
	if shutdown then
		return fail(Types.FailureType.RuntimeShutdown, "runtime is shut down")
	end
	if type(contract) ~= "table" or type(contract.contractId) ~= "string" then
		return fail(Types.FailureType.InvalidSchema, "contract identity is required")
	end
	if contracts[contract.contractId] then
		counters.duplicateRejections += 1
		return fail(
			Types.FailureType.DuplicateContract,
			"contract already exists",
			contract.contractId
		)
	end
	local count = 0
	for _ in pairs(contracts) do
		count += 1
	end
	if count >= Types.Limits.maxContracts then
		counters.budgetRejections += 1
		return fail(
			Types.FailureType.BudgetExceeded,
			"contract registry limit reached",
			contract.contractId
		)
	end
	contracts[contract.contractId] = {
		state = Types.ContractState.Draft,
		contract = copy(contract),
		validation = nil,
		publication = nil,
	}
	counters.registered += 1
	record("Registered", contract.contractId, { schemaVersion = contract.schemaVersion })
	return { ok = true, contractId = contract.contractId, state = Types.ContractState.Draft }
end

local function transition(contractId: string, target: string)
	local entry = contracts[contractId]
	if not entry then
		return fail("UnknownContract", "contract is not registered", contractId)
	end
	if not allowedTransitions[entry.state][target] then
		counters.illegalTransitions += 1
		return fail(
			Types.FailureType.IllegalTransition,
			entry.state .. " -> " .. target,
			contractId
		)
	end
	entry.state = target
	record("Transition", contractId, { state = target })
	return { ok = true, contractId = contractId, state = target }
end

function Runtime.validateContract(contractId: string)
	if shutdown then
		return fail(Types.FailureType.RuntimeShutdown, "runtime is shut down", contractId)
	end
	local entry = contracts[contractId]
	if not entry then
		return fail("UnknownContract", "contract is not registered", contractId)
	end
	if entry.state ~= Types.ContractState.Draft then
		return fail(Types.FailureType.IllegalTransition, "validation requires Draft", contractId)
	end
	local ok, reason = Validation.validate(entry.contract)
	entry.validation =
		table.freeze({ ok = ok, reason = reason, schemaVersion = Types.SchemaVersion })
	if not ok then
		counters.rejected += 1
		transition(contractId, Types.ContractState.Rejected)
		return fail(Types.FailureType.InvalidSchema, reason or "validation failed", contractId)
	end
	counters.validated += 1
	return transition(contractId, Types.ContractState.Validated)
end

function Runtime.publish(contractId: string)
	if shutdown then
		return fail(Types.FailureType.RuntimeShutdown, "runtime is shut down", contractId)
	end
	local entry = contracts[contractId]
	if not entry or entry.state ~= Types.ContractState.Validated then
		return fail(
			Types.FailureType.IllegalTransition,
			"publication requires Validated",
			contractId
		)
	end
	entry.publication = table.freeze({
		contractId = contractId,
		schemaVersion = Types.SchemaVersion,
		targetRevision = entry.contract.targetRevision,
		nodeCount = #entry.contract.nodes,
		immutable = true,
	})
	counters.published += 1
	return transition(contractId, Types.ContractState.Published)
end

function Runtime.retire(contractId: string)
	if shutdown then
		return fail(Types.FailureType.RuntimeShutdown, "runtime is shut down", contractId)
	end
	counters.retired += 1
	return transition(contractId, Types.ContractState.Retired)
end

function Runtime.getContract(contractId: string)
	local entry = contracts[contractId]
	return entry and copy(entry) or nil
end
function Runtime.inspect()
	local states = {}
	for _, entry in pairs(contracts) do
		states[entry.state] = (states[entry.state] or 0) + 1
	end
	return {
		provider = Types.ProviderName,
		schemaVersion = Types.SchemaVersion,
		health = #failures == 0 and "Healthy" or "Warning",
		shutdown = shutdown,
		counters = copy(counters),
		states = states,
		failures = copy(failures),
		posture = {
			noInstanceCreation = true,
			noGuiMutation = true,
			noRenderingExecution = true,
			noNetworking = true,
			noClientAuthority = true,
			noAnalytics = true,
			noTelemetry = true,
		},
	}
end
function Runtime.getSnapshot()
	local ids = {}
	for id in pairs(contracts) do
		ids[#ids + 1] = id
	end
	table.sort(ids)
	return {
		provider = Types.ProviderName,
		schemaVersion = Types.SchemaVersion,
		contractIds = ids,
		contracts = copy(contracts),
		audit = copy(audit),
		diagnostics = Runtime.inspect(),
		catalog = Catalog.snapshot(),
	}
end
function Runtime.validate(): (boolean, string?)
	if shutdown then
		return false, "runtime is shut down"
	end
	return true
end
function Runtime.reset()
	shutdown = false
	contracts = {}
	audit = {}
	failures = {}
	for key in pairs(counters) do
		counters[key] = 0
	end
end
function Runtime.shutdown()
	shutdown = true
	record("Shutdown", "runtime", {})
end

return Runtime
