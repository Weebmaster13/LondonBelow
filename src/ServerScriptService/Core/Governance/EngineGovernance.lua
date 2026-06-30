--!strict
--[[
	EngineGovernance makes the London Engine Constitution enforceable.

	Owns governance lifecycle, contract registration, validation, scorecards,
	diagnostics, snapshots, and EventBus signals for architectural issues.

	Does not add gameplay, Monster AI, Chapter 1 content, final UI, or final art.
	It is a Core enforcement layer that makes bad architecture harder to hide.
]]

local ServerScriptService = game:GetService("ServerScriptService")

local Core = ServerScriptService.Core
local Diagnostics = require(Core.Diagnostics)
local EventBus = require(Core.EventBus)
local Logger = require(Core.Logger)
local SnapshotManager = require(Core.SnapshotManager)

local DirectorContract = require(script.Parent.DirectorContract)
local EngineContractRegistry = require(script.Parent.EngineContractRegistry)
local EngineContractValidator = require(script.Parent.EngineContractValidator)
local EngineScorecard = require(script.Parent.EngineScorecard)
local ExecutionContract = require(script.Parent.ExecutionContract)
local GovernanceDiagnostics = require(script.Parent.GovernanceDiagnostics)
local GovernanceSignals = require(script.Parent.GovernanceSignals)
local ObservationContract = require(script.Parent.ObservationContract)
local Types = require(script.Parent.EngineContractTypes)

local EngineGovernance = {}

type EngineContract = Types.EngineContract
type ContractIssue = Types.ContractIssue
type Scorecard = Types.Scorecard

local log = Logger.scope("EngineGovernance")
local initialized = false
local started = false
local lastValidationAt = 0
local issueCache: { ContractIssue } = {}
local scorecardCache: { [string]: Scorecard } = {}
local health: Types.GovernanceHealth = "NotValidated"
local validationSummary: Types.ValidationSummary = {
	health = "NotValidated",
	totalIssues = 0,
	fatalIssues = 0,
	errorIssues = 0,
	warningIssues = 0,
	infoIssues = 0,
	lastValidatedAt = 0,
}

local function now(): number
	return os.clock()
end

local function publishIssues(issues: { ContractIssue })
	for _, contractIssue in ipairs(issues) do
		if contractIssue.severity == "Pass" then
			continue
		end

		EventBus.publishDeferred(GovernanceSignals.ContractIssueFound, {
			issue = contractIssue,
		})
	end
end

local function validateAndScore(contract: EngineContract): { ContractIssue }
	local issues = EngineContractValidator.validate(contract)
	local scorecard = EngineScorecard.score(contract, issues)

	scorecardCache[contract.systemName] = scorecard

	EventBus.publishDeferred(GovernanceSignals.ContractValidated, {
		contract = contract,
		issues = issues,
	})

	EventBus.publishDeferred(GovernanceSignals.ScorecardUpdated, {
		scorecard = scorecard,
	})

	if #issues > 0 then
		publishIssues(issues)
	end

	return issues
end

function EngineGovernance.registerContract(contract: EngineContract): (boolean, { ContractIssue })
	EngineContractRegistry.register(contract)

	EventBus.publishDeferred(GovernanceSignals.ContractRegistered, {
		contract = contract,
	})

	local issues = validateAndScore(contract)

	EngineGovernance.validateAll()

	return not EngineContractValidator.hasErrors(issues), issues
end

function EngineGovernance.replaceContract(contract: EngineContract): (boolean, { ContractIssue })
	local replaced = EngineContractRegistry.replace(contract)

	if not replaced then
		return EngineGovernance.registerContract(contract)
	end

	EventBus.publishDeferred(GovernanceSignals.ContractReplaced, {
		contract = contract,
	})

	local issues = validateAndScore(contract)
	EngineGovernance.validateAll()

	return not EngineContractValidator.hasErrors(issues), issues
end

function EngineGovernance.getContract(systemName: string): EngineContract?
	return EngineContractRegistry.get(systemName)
end

function EngineGovernance.validateAll(): (boolean, { ContractIssue })
	table.clear(issueCache)
	table.clear(scorecardCache)

	for _, contract in ipairs(EngineContractRegistry.getAll()) do
		local issues = validateAndScore(contract)

		for _, contractIssue in ipairs(issues) do
			if contractIssue.severity ~= "Pass" then
				table.insert(issueCache, contractIssue)
			end
		end
	end

	lastValidationAt = now()
	validationSummary = EngineContractValidator.summarize(issueCache, lastValidationAt)
	health = validationSummary.health

	log.withContext(
		if health == "Failed" then "ERROR" elseif health == "Warning" then "WARN" else "SUCCESS",
		"Governance validation summary",
		{
			health = health,
			totalIssues = validationSummary.totalIssues,
			fatalIssues = validationSummary.fatalIssues,
			errorIssues = validationSummary.errorIssues,
			warningIssues = validationSummary.warningIssues,
			contracts = #EngineContractRegistry.getAll(),
		}
	)

	return not EngineContractValidator.hasErrors(issueCache), table.clone(issueCache)
end

function EngineGovernance.getIssues(): { ContractIssue }
	return table.clone(issueCache)
end

function EngineGovernance.getScorecards(): { [string]: Scorecard }
	return table.clone(scorecardCache)
end

function EngineGovernance.getHealthState(): Types.ValidationSummary
	return {
		health = validationSummary.health,
		totalIssues = validationSummary.totalIssues,
		fatalIssues = validationSummary.fatalIssues,
		errorIssues = validationSummary.errorIssues,
		warningIssues = validationSummary.warningIssues,
		infoIssues = validationSummary.infoIssues,
		lastValidatedAt = validationSummary.lastValidatedAt,
	}
end

function EngineGovernance.initialize()
	if initialized then
		return
	end

	EngineContractRegistry.registerBuiltIns()
	Diagnostics.registerSampler("EngineGovernance", EngineGovernance.inspect)
	SnapshotManager.registerProvider("engineGovernance", EngineGovernance.inspect)

	local ok, issues = EngineGovernance.validateAll()

	if not ok then
		error("EngineGovernance validation failed: " .. tostring(#issues) .. " issue(s)", 0)
	end

	initialized = true
	log.success("EngineGovernance initialized")
end

function EngineGovernance.start()
	if started then
		return
	end

	started = true
	EventBus.publishDeferred(GovernanceSignals.GovernanceReady, {
		contracts = EngineContractRegistry.getAll(),
		scorecards = EngineGovernance.getScorecards(),
	})
	log.success("EngineGovernance started")
end

function EngineGovernance.shutdown()
	table.clear(issueCache)
	table.clear(scorecardCache)
	health = "NotValidated"
	validationSummary = {
		health = "NotValidated",
		totalIssues = 0,
		fatalIssues = 0,
		errorIssues = 0,
		warningIssues = 0,
		infoIssues = 0,
		lastValidatedAt = 0,
	}
	started = false
end

function EngineGovernance.inspect()
	return GovernanceDiagnostics.capture({
		initialized = initialized,
		started = started,
		lastValidationAt = lastValidationAt,
		issueCount = #issueCache,
		health = health,
		validationSummary = validationSummary,
	}, {
		EngineContractRegistry = EngineContractRegistry,
		DirectorContract = DirectorContract,
		ObservationContract = ObservationContract,
		ExecutionContract = ExecutionContract,
		getIssues = EngineGovernance.getIssues,
		getScorecards = EngineGovernance.getScorecards,
		getHealthState = EngineGovernance.getHealthState,
	})
end

function EngineGovernance.validate(): (boolean, string?)
	return GovernanceDiagnostics.validate({
		EngineContractRegistry = EngineContractRegistry,
		EngineContractValidator = EngineContractValidator,
	})
end

return EngineGovernance
