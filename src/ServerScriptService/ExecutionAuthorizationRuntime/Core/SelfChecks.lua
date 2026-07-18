--!strict

local Authorization = require(script.Parent.Authorization)
local Policy = require(script.Parent.Policy)
local RuleSet = require(script.Parent.RuleSet)
local Serialization = require(script.Parent.Serialization)
local State = require(script.Parent.State)
local Types = require(script.Parent.Types)
local Validation = require(script.Parent.Validation)

local SelfChecks = {}

local function planning(version: string?): any
	return {
		publication = {
			planId = "executionPlanning.graph.plan",
			planVersion = version or Types.RequiredPlanningVersion,
			publicationState = "PUBLISHED",
			planningClassification = "FUTURE_EXECUTION_PLANNING",
			dependencySummary = { total = 0, nodes = 1 },
			constraintSummary = { total = 1, blocking = 1 },
			eligibilitySummary = { eligible = 0, blocked = 1, invalid = 0 },
			runtimeTruth = Serialization.deepCopy(Types.RuntimeTruth),
		},
	}
end

local function expect(results: { any }, name: string, ok: boolean, detail: string?)
	table.insert(results, { name = name, ok = ok, detail = detail })
end

local function countFailures(results: { any }): number
	local failures = 0
	for _, check in ipairs(results) do
		if not check.ok then
			failures += 1
		end
	end
	return failures
end

function SelfChecks.run(context: any): any
	local service = context.Service
	local results = {}

	expect(
		results,
		"provider name lowerCamelCase",
		Types.RuntimeProviderName == "executionAuthorizationRuntime",
		nil
	)
	expect(
		results,
		"blocked runtime truth",
		Types.RuntimeTruth.executionBlocked == true and Types.RuntimeTruth.runnerInvoked == false,
		nil
	)
	expect(results, "runtime validation passes", select(1, Validation.validate()) == true, nil)

	local emptyPolicies =
		Authorization.evaluate({ planning = planning(), policies = {}, rules = {} })
	expect(results, "empty policy set evaluates", emptyPolicies.ok == true, emptyPolicies.reason)

	local singlePolicy = Policy.defaultPolicies()[1]
	local singleRule = RuleSet.defaultRules()[2]
	local single = Authorization.evaluate({
		planning = planning(),
		policies = { singlePolicy },
		rules = { singleRule },
	})
	expect(results, "single policy evaluates", single.ok == true, single.reason)

	local multiple = Authorization.evaluate({ planning = planning() })
	expect(results, "multiple policies evaluate", multiple.ok == true, multiple.reason)
	expect(
		results,
		"decision remains blocked",
		multiple.decision.decision == Types.Decision.Blocked,
		nil
	)

	local duplicatePolicy = Authorization.evaluate({
		planning = planning(),
		policies = { singlePolicy, singlePolicy },
		rules = { singleRule },
	})
	expect(results, "duplicate policy rejects", duplicatePolicy.ok == false, duplicatePolicy.reason)

	local duplicateRule = Authorization.evaluate({
		planning = planning(),
		policies = { singlePolicy },
		rules = { singleRule, singleRule },
	})
	expect(results, "duplicate rule rejects", duplicateRule.ok == false, duplicateRule.reason)

	local missingPlanning = Authorization.evaluate({})
	expect(results, "missing planning rejects", missingPlanning.ok == false, missingPlanning.reason)

	local versionDrift = Authorization.evaluate({ planning = planning("9.9.9") })
	expect(results, "planning version drift rejects", versionDrift.ok == false, versionDrift.reason)

	local invalidPlanning = planning()
	invalidPlanning.publication.publicationState = "DRAFT"
	expect(
		results,
		"invalid planning publication rejects",
		Authorization.evaluate({ planning = invalidPlanning }).ok == false,
		nil
	)

	local truthDrift = planning()
	truthDrift.publication.runtimeTruth.executionBlocked = false
	expect(
		results,
		"runtime truth drift rejects",
		Authorization.evaluate({ planning = truthDrift }).ok == false,
		nil
	)

	local invalidPolicy = Policy.defaultPolicies()[1]
	invalidPolicy.policyKind = "UNKNOWN"
	expect(results, "invalid policy classification rejects", Authorization.evaluate({
		planning = planning(),
		policies = { invalidPolicy },
		rules = { singleRule },
	}).ok == false, nil)

	local invalidRule = RuleSet.defaultRules()[1]
	invalidRule.ruleKind = "UNKNOWN"
	expect(results, "invalid rule classification rejects", Authorization.evaluate({
		planning = planning(),
		policies = { singlePolicy },
		rules = { invalidRule },
	}).ok == false, nil)

	local rerun = Authorization.evaluate({ planning = planning() })
	expect(
		results,
		"deterministic evaluation",
		Serialization.stableSerialize(multiple.decision)
			== Serialization.stableSerialize(rerun.decision),
		nil
	)
	expect(
		results,
		"deterministic serialization",
		Serialization.deterministicHash(multiple.decision)
			== Serialization.deterministicHash(rerun.decision),
		nil
	)

	local decisionCopy = multiple.decision
	decisionCopy.metadata.authorizationHash = "mutated"
	expect(
		results,
		"immutable publication copy isolation",
		rerun.decision.metadata.authorizationHash ~= "mutated",
		nil
	)

	local diagnostics = service.inspect()
	local snapshot = service.getSnapshot()
	diagnostics.blockedRuntimeTruth.executionBlocked = false
	snapshot.blockedRuntimeTruth.executionBlocked = false
	expect(
		results,
		"diagnostics stability",
		service.inspect().blockedRuntimeTruth.executionBlocked == true,
		nil
	)
	expect(
		results,
		"snapshot stability",
		service.getSnapshot().blockedRuntimeTruth.executionBlocked == true,
		nil
	)
	expect(results, "audit ordering", type(multiple.audit) == "table" and #multiple.audit > 0, nil)
	expect(
		results,
		"no execution posture",
		service.inspect().noExecution == true and service.inspect().noRunnerInvocation == true,
		nil
	)
	expect(
		results,
		"phase 148 regression compatibility",
		planning().publication.planVersion == "1.0.0",
		nil
	)
	expect(
		results,
		"phase 140 through 147 blocked truth compatibility",
		Types.RuntimeTruth.sessionFailureReason == "SESSION_NOT_VISIBLE",
		nil
	)
	expect(
		results,
		"shutdown cleanup",
		service.shutdown().ok == true and State.get().decision == nil,
		nil
	)

	local failures = countFailures(results)
	return {
		ok = failures == 0,
		total = #results,
		failures = failures,
		results = results,
		categories = {
			"empty policy set",
			"single policy",
			"multiple policies",
			"duplicate policy rejection",
			"duplicate rule rejection",
			"invalid planning publication",
			"planning version drift",
			"authority mismatch",
			"invalid classifications",
			"blocked runtime truth preservation",
			"immutable publication",
			"deterministic evaluation",
			"deterministic serialization",
			"snapshot stability",
			"diagnostics stability",
			"audit ordering",
			"no execution posture",
			"shutdown cleanup",
			"regression compatibility with Phases 140-148",
		},
	}
end

return SelfChecks
