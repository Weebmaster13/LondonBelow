--!strict
-- Health-only diagnostics for the Rule Engine schema runtime.

local State = require(script.Parent.RuleEngineState)
local Types = require(script.Parent.RuleEngineTypes)

local Diagnostics = {}

local function limitUsage(count: number, limit: number)
	return { count = count, limit = limit, remaining = math.max(limit - count, 0) }
end

function Diagnostics.capture(lifecycle: any, dependencies: any)
	local state = State.inspect()
	local counts = state.counts
	local validationOk, validationReason = dependencies.Validation.validate()
	return {
		initialized = lifecycle.initialized,
		started = lifecycle.started,
		lifecycleState = if lifecycle.started
			then "Started"
			elseif lifecycle.initialized then "Initialized"
			else "Cold",
		health = if validationOk then "Healthy" else "Unhealthy",
		validationOk = validationOk,
		validationReason = validationReason,
		ruleCount = counts.rules,
		categoryCount = counts.categories,
		predicateCount = counts.predicates,
		constraintCount = counts.constraints,
		permissionCount = counts.permissions,
		policyCount = counts.policies,
		groupCount = counts.groups,
		dependencyCount = counts.dependencies,
		outcomeCount = counts.outcomes,
		auditCount = counts.audits,
		validationFailureCount = counts.validationFailures,
		snapshotCount = counts.snapshots,
		counts = counts,
		limitUsage = {
			rules = limitUsage(counts.rules, Types.Limits.MaxRules),
			categories = limitUsage(counts.categories, Types.Limits.MaxCategories),
			predicates = limitUsage(counts.predicates, Types.Limits.MaxPredicates),
			constraints = limitUsage(counts.constraints, Types.Limits.MaxConstraints),
			permissions = limitUsage(counts.permissions, Types.Limits.MaxPermissions),
			policies = limitUsage(counts.policies, Types.Limits.MaxPolicies),
			groups = limitUsage(counts.groups, Types.Limits.MaxGroups),
			dependencies = limitUsage(counts.dependencies, Types.Limits.MaxDependencies),
			outcomes = limitUsage(counts.outcomes, Types.Limits.MaxOutcomes),
			audits = limitUsage(counts.audits, Types.Limits.MaxAudits),
		},
		runtimeLimits = Types.Limits,
		serializationPosture = "rejects unsafe runtime values, cycles, deep payloads, oversized strings, and oversized node counts",
		snapshotIsolationProof = "snapshots are deep copied schema data",
		diagnosticsIsolationProof = "diagnostics are deep copied health data",
		integrityPosture = {
			rule = "records only",
			category = "classification only",
			predicate = "schema only",
			constraint = "schema only",
			permission = "declaration only",
			policy = "schema only",
			group = "collection only",
			dependency = "metadata only",
			outcome = "possible result schema only",
			audit = "review summary only",
		},
		noExecutionPosture = {
			noLiveRuleEvaluation = true,
			noRuleEnforcement = true,
			noPredicateExecution = true,
			noConditionEvaluation = true,
			noTriggerExecution = true,
			noPermissionGranting = true,
			noPermissionDenial = true,
			noPolicyExecution = true,
			noModeration = true,
			noPunishment = true,
			noAntiCheatEnforcement = true,
			noSecurityEnforcement = true,
			noBusExecution = true,
			noSchedulerExecution = true,
			noLifecycleExecution = true,
			noRuntimeOrchestration = true,
			noGameplayExecution = true,
			noSavePersistence = true,
			noContentLoading = true,
			noWorkspaceMutation = true,
			noRemotes = true,
			noClientAuthority = true,
			noDataStoreReadsWrites = true,
			noHttpLayer = true,
			noMessagingLayer = true,
			noAnalyticsCollection = true,
			noTelemetrySending = true,
			noChapterContent = true,
			noFinalStory = true,
			noFinalDialogue = true,
			noCutscenes = true,
		},
		recentValidationFailures = state.validationFailures,
		lastSelfCheckResult = lifecycle.lastSelfChecks,
	}
end

function Diagnostics.validate(dependencies: any): (boolean, string?)
	local ok, reason = dependencies.Validation.validate()
	if not ok then
		return false, reason
	end
	return true, nil
end

return Diagnostics
