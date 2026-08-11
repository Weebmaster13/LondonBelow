--!strict

local Runtime = require(script.Parent.RuntimeRobloxVisualCompositionExecution)
local Types = require(script.Parent.PresentationTypes)

local SelfChecks = {}

local function suite()
	local checks = {}
	local function expect(name: string, condition: boolean, detail: string?)
		checks[#checks + 1] = { name = name, ok = condition == true, detail = detail }
	end
	local function summarize()
		local failures = {}
		for _, check in ipairs(checks) do
			if not check.ok then
				failures[#failures + 1] = check
			end
		end
		return {
			phase = 184,
			ok = #failures == 0,
			total = #checks,
			passed = #checks - #failures,
			failed = #failures,
			failures = failures,
		}
	end
	return expect, summarize
end

local function node(nodeId: string, parentNodeId: string?, order: number, overrides: any?)
	local data = {
		nodeId = nodeId,
		parentNodeId = parentNodeId,
		order = order,
		nodeKind = parentNodeId == nil and Types.VisualNodeKind.Root or Types.VisualNodeKind.Text,
		semanticRole = parentNodeId == nil and Types.VisualSemanticRole.DialogueRoot
			or Types.VisualSemanticRole.DialogueBody,
		layout = { mode = Types.VisualLayoutMode.AnchorIntent, anchor = "Center" },
		visibility = Types.VisualVisibilityState.Visible,
		styleReference = "dialogue.body",
		themeReference = "theme.london.chapter0.home",
		typographyReference = "type.dialogue",
		assetReference = nil,
		localizationSlot = "dialogue.body",
		accessibility = { screenReaderToken = nodeId },
		states = { Default = {} },
	}
	if overrides ~= nil then
		for key, value in pairs(overrides) do
			data[key] = value
		end
	end
	return data
end

local function plan(revision: number, extra: any?)
	local nodes = {
		node("root", nil, 1),
		node("panel", "root", 2),
		node("body", "panel", 3),
	}
	if extra ~= nil then
		for _, item in ipairs(extra) do
			nodes[#nodes + 1] = item
		end
	end
	return {
		compositionInstanceId = "composition.instance.phase184",
		revision = revision,
		rootNodeId = "root",
		orderedNodes = nodes,
	}
end

local function session(overrides: any?)
	local data = {
		visualExecutionSessionId = "visual.exec.phase184.primary",
		compositionInstanceId = "composition.instance.phase184",
		robloxRenderingSessionId = "roblox.rendering.session.phase182.primary",
		sourceRevision = 0,
		targetRevision = 1,
		patchPlanId = "visual.patch.phase184.primary",
		runtimeMetadata = { source = "self-check" },
	}
	if overrides ~= nil then
		for key, value in pairs(overrides) do
			data[key] = value
		end
	end
	return data
end

local function buildPatch(expect: (string, boolean, string?) -> ())
	local created = Runtime.createExecutionSession(session())
	expect("execution session created", created.ok)
	local source = plan(0)
	local target =
		plan(1, { node("choice", "panel", 4, { visibility = Types.VisualVisibilityState.Hidden }) })
	target.orderedNodes[3].visibility = Types.VisualVisibilityState.Hidden
	target.orderedNodes[2].order = 5
	local diff = Runtime.buildDiff(source, target)
	expect("diff generated", diff.ok)
	expect("diff has operations", diff.ok and #diff.diff.operations >= 3)
	local patch = Runtime.createPatchPlan({ session = created.session, diff = diff.diff })
	expect("patch plan created", patch.ok)
	return created, diff, patch, source, target
end

function SelfChecks.run()
	Runtime.reset()
	local expect, summarize = suite()

	expect(
		"provider identity",
		Types.RobloxVisualCompositionExecutionProviderName
			== "robloxVisualCompositionExecutionRuntime"
	)
	expect(
		"runtime identity",
		Types.RobloxVisualCompositionExecutionRuntimeId == "robloxVisualCompositionExecutionRuntime"
	)
	expect(
		"capability identity",
		Types.RobloxVisualCompositionExecutionCapabilityId
			== "robloxVisualCompositionExecutionCapability"
	)
	for _, value in pairs(Types.VisualExecutionState) do
		expect("execution state valid " .. value, Types.isVisualExecutionState(value))
	end
	for _, value in pairs(Types.VisualPatchState) do
		expect("patch state valid " .. value, Types.isVisualPatchState(value))
	end
	for _, value in pairs(Types.VisualOperationKind) do
		expect("operation kind valid " .. value, Types.isVisualOperationKind(value))
	end
	for _, value in pairs(Types.VisualTransactionState) do
		expect("transaction state valid " .. value, Types.isVisualTransactionState(value))
	end
	for _, value in pairs(Types.VisualRollbackStrategy) do
		expect("rollback strategy valid " .. value, Types.isVisualRollbackStrategy(value))
	end
	for _, value in pairs(Types.VisualRecoveryDecision) do
		expect("recovery decision valid " .. value, Types.isVisualRecoveryDecision(value))
	end
	for _, value in pairs(Types.VisualQueueState) do
		expect("queue state valid " .. value, Types.isVisualQueueState(value))
	end
	for _, value in pairs(Types.VisualPressureState) do
		expect("pressure state valid " .. value, Types.isVisualPressureState(value))
	end

	expect("nil session rejected", not Runtime.createExecutionSession(nil).ok)
	expect(
		"unsafe session rejected",
		not Runtime.createExecutionSession(session({ runtimeMetadata = { fn = function() end } })).ok
	)
	expect("backward revision rejected", not Runtime.createExecutionSession(session({
		visualExecutionSessionId = "visual.exec.bad.back",
		sourceRevision = 2,
		targetRevision = 1,
	})).ok)
	expect("same revision rejected", not Runtime.createExecutionSession(session({
		visualExecutionSessionId = "visual.exec.bad.same",
		sourceRevision = 1,
		targetRevision = 1,
	})).ok)
	expect("skip revision rejected", not Runtime.createExecutionSession(session({
		visualExecutionSessionId = "visual.exec.bad.skip",
		sourceRevision = 1,
		targetRevision = 3,
	})).ok)

	local created, diff, patch, source, target = buildPatch(expect)
	expect("duplicate session rejected", not Runtime.createExecutionSession(session()).ok)
	expect("operations ordered deterministically", diff.diff.operations[1].executionOrdinal == 1)
	expect("dependency graph present", diff.diff.dependencyGraph ~= nil)
	expect("rollback plan present", #patch.patchPlan.rollbackPlan == #patch.patchPlan.operations)
	expect("batch plan present", #patch.patchPlan.batchPlan >= 1)
	expect("revision fence captured", patch.patchPlan.revisionFence.expectedActiveRevision == 0)
	expect(
		"duplicate patch rejected",
		not Runtime.createPatchPlan({ session = created.session, diff = diff.diff }).ok
	)
	expect("patch validation passes", Runtime.validatePatchPlan(patch.patchPlan.patchPlanId).ok)
	expect("patch sealing passes", Runtime.sealPatchPlan(patch.patchPlan.patchPlanId).ok)
	expect("enqueue sealed patch", Runtime.enqueuePatch(patch.patchPlan.patchPlanId).ok)
	expect("schedule queued patch", Runtime.scheduleNext().ok)
	expect("prepare patch", Runtime.preparePatch(patch.patchPlan.patchPlanId).ok)
	expect("apply metadata", Runtime.markApplied(patch.patchPlan.patchPlanId).ok)
	expect("commit patch", Runtime.commitPatch(patch.patchPlan.patchPlanId).ok)
	expect("commit twice rejected", not Runtime.commitPatch(patch.patchPlan.patchPlanId).ok)
	expect("cancel after commit rejected", not Runtime.cancelPatch(patch.patchPlan.patchPlanId).ok)
	expect(
		"rollback inspectable",
		#Runtime.buildRollbackPlan(patch.patchPlan.patchPlanId).rollbackPlan
			== #patch.patchPlan.operations
	)
	expect("replay validates", Runtime.validateReplay(source, target, patch.patchPlan).ok)
	expect(
		"execution inspect isolated",
		Runtime.inspectExecution(created.session.visualExecutionSessionId).visualExecutionSessionId
			== created.session.visualExecutionSessionId
	)
	expect(
		"patch inspect isolated",
		Runtime.inspectPatch(patch.patchPlan.patchPlanId).patchPlanId == patch.patchPlan.patchPlanId
	)
	expect(
		"operations inspect isolated",
		#Runtime.inspectOperations(patch.patchPlan.patchPlanId) == #patch.patchPlan.operations
	)

	Runtime.reset()
	local _, staleDiff, stalePatch = buildPatch(expect)
	expect("stale patch sealed", Runtime.sealPatchPlan(stalePatch.patchPlan.patchPlanId).ok)
	local nextSession = Runtime.createExecutionSession(session({
		visualExecutionSessionId = "visual.exec.phase184.next",
		patchPlanId = "visual.patch.phase184.next",
		sourceRevision = 0,
		targetRevision = 1,
	}))
	expect("next session for stale setup", nextSession.ok)
	local nextPatch =
		Runtime.createPatchPlan({ session = nextSession.session, diff = staleDiff.diff })
	expect("next patch created", nextPatch.ok)
	expect("next patch sealed", Runtime.sealPatchPlan(nextPatch.patchPlan.patchPlanId).ok)
	expect("next patch prepared", Runtime.preparePatch(nextPatch.patchPlan.patchPlanId).ok)
	expect("next patch applied", Runtime.markApplied(nextPatch.patchPlan.patchPlanId).ok)
	expect("next patch committed", Runtime.commitPatch(nextPatch.patchPlan.patchPlanId).ok)
	expect("stale prepare rejected", not Runtime.preparePatch(stalePatch.patchPlan.patchPlanId).ok)

	Runtime.reset()
	local _, _, cancelPatch = buildPatch(expect)
	expect("cancel patch before commit", Runtime.cancelPatch(cancelPatch.patchPlan.patchPlanId).ok)
	expect(
		"cancelled prepare rejected",
		not Runtime.preparePatch(cancelPatch.patchPlan.patchPlanId).ok
	)
	Runtime.reset()
	local _, _, superPatch = buildPatch(expect)
	expect(
		"supersede patch",
		Runtime.supersedePatch(superPatch.patchPlan.patchPlanId, "visual.patch.replacement").ok
	)
	expect(
		"superseded prepare rejected",
		not Runtime.preparePatch(superPatch.patchPlan.patchPlanId).ok
	)
	expect("recover superseded patch", Runtime.recoverPatch(superPatch.patchPlan.patchPlanId).ok)
	Runtime.reset()
	local _, _, abortPatch = buildPatch(expect)
	expect("abort patch", Runtime.abortPatch(abortPatch.patchPlan.patchPlanId).ok)

	local diagnostics = Runtime.inspect()
	expect(
		"diagnostics provider",
		diagnostics.providerName == Types.RobloxVisualCompositionExecutionProviderName
	)
	expect(
		"diagnostics runtime",
		diagnostics.runtimeId == Types.RobloxVisualCompositionExecutionRuntimeId
	)
	expect(
		"diagnostics capability",
		diagnostics.capabilityId == Types.RobloxVisualCompositionExecutionCapabilityId
	)
	expect(
		"diagnostics posture lowerCamelCase",
		diagnostics.robloxVisualCompositionExecutionPosture ~= nil
	)
	expect(
		"posture server authoritative",
		diagnostics.robloxVisualCompositionExecutionPosture.serverAuthoritative == true
	)
	expect(
		"posture deterministic diff",
		diagnostics.robloxVisualCompositionExecutionPosture.deterministicDiff == true
	)
	expect(
		"posture deterministic patch planning",
		diagnostics.robloxVisualCompositionExecutionPosture.deterministicPatchPlanning == true
	)
	expect(
		"posture deterministic operation ordering",
		diagnostics.robloxVisualCompositionExecutionPosture.deterministicOperationOrdering == true
	)
	expect(
		"posture revision fenced",
		diagnostics.robloxVisualCompositionExecutionPosture.revisionFenced == true
	)
	expect(
		"posture transactional metadata",
		diagnostics.robloxVisualCompositionExecutionPosture.transactionalMetadata == true
	)
	expect(
		"posture no gui mutation",
		diagnostics.robloxVisualCompositionExecutionPosture.noGuiMutation == true
	)
	expect(
		"posture no instance creation",
		diagnostics.robloxVisualCompositionExecutionPosture.noInstanceCreation == true
	)
	expect(
		"posture no rendering execution",
		diagnostics.robloxVisualCompositionExecutionPosture.noRenderingExecution == true
	)
	expect(
		"posture no asset loading",
		diagnostics.robloxVisualCompositionExecutionPosture.noAssetLoading == true
	)
	expect(
		"posture no networking",
		diagnostics.robloxVisualCompositionExecutionPosture.noNetworking == true
	)
	expect(
		"posture no workspace mutation",
		diagnostics.robloxVisualCompositionExecutionPosture.noWorkspaceMutation == true
	)
	expect(
		"posture no persistence",
		diagnostics.robloxVisualCompositionExecutionPosture.noPersistence == true
	)
	expect(
		"posture no client authority",
		diagnostics.robloxVisualCompositionExecutionPosture.noClientAuthority == true
	)
	expect(
		"posture no analytics",
		diagnostics.robloxVisualCompositionExecutionPosture.noAnalytics == true
	)
	expect(
		"posture no telemetry",
		diagnostics.robloxVisualCompositionExecutionPosture.noTelemetry == true
	)
	expect(
		"governance exposed",
		diagnostics.governance.systemName == "Roblox Visual Composition Execution and Diff Runtime"
	)
	expect("certification candidate", diagnostics.certification.status == "ProductionCandidate")
	expect(
		"budgets exposed",
		diagnostics.budgets.MaxPatchPlans == Types.VisualExecutionLimits.MaxPatchPlans
	)
	expect("metrics exposed", diagnostics.metrics.runtimeFailures ~= nil)
	expect("evidence exposed", #diagnostics.evidence > 0)
	diagnostics.evidence[1].eventKind = "mutated"
	expect("diagnostics isolated", Runtime.inspect().evidence[1].eventKind ~= "mutated")
	local snapshot = Runtime.getSnapshot()
	expect(
		"snapshot provider",
		snapshot.providerName == Types.RobloxVisualCompositionExecutionProviderName
	)
	expect("snapshot root", snapshot.robloxVisualCompositionExecutionSnapshot ~= nil)
	snapshot.robloxVisualCompositionExecutionSnapshot.evidence[1].eventKind = "mutated"
	expect(
		"snapshot isolated",
		Runtime.getSnapshot().robloxVisualCompositionExecutionSnapshot.evidence[1].eventKind
			~= "mutated"
	)
	local valid, reason = Runtime.validate()
	expect("runtime validation passes", valid, reason)
	Runtime.shutdown()
	expect(
		"shutdown blocks session",
		not Runtime.createExecutionSession(
			session({ visualExecutionSessionId = "visual.exec.shutdown" })
		).ok
	)

	return summarize()
end

return SelfChecks
