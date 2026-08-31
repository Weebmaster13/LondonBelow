--!strict

local ServerScriptService = game:GetService("ServerScriptService")

local VisualRuntime = require(ServerScriptService.Presentation.Core.RuntimeRobloxVisualCompositionExecution)

local Bridge = {}
local compositionInstanceId = ""
local revision = 0
local activePlan = nil :: any
local transitionsPlanned = 0
local transitionsCommitted = 0
local failures = {}

local function appendFailure(stage: string, result: any)
	if #failures >= 64 then table.remove(failures, 1) end
	failures[#failures + 1] = { stage = stage, code = result and result.code, detail = result and result.detail }
end

local function planFor(targetRevision: number, objective: any, pressure: number)
	return {
		revision = targetRevision,
		nodes = {
			{
				nodeId = "blackwater-world",
				parentNodeId = "root",
				order = 1,
				visibility = true,
				states = { chapterPhase = objective and objective.phase or "Complete", pressure = pressure },
				styleReference = if pressure >= 0.75 then "blackwater-corrupted" else "blackwater-gaslight",
				themeReference = if objective and objective.phase == "Escape" then "blackwater-dawn" else "blackwater-night",
				accessibility = { threat = objective and objective.phase or "Complete" },
			},
			{
				nodeId = "blackwater-objective",
				parentNodeId = "root",
				order = 2,
				visibility = objective ~= nil,
				states = { objectiveId = objective and objective.id or "complete" },
				localizationSlot = objective and objective.id or "chapter-complete",
				styleReference = "blackwater-objective-panel",
				themeReference = "blackwater-house",
				accessibility = { liveRegion = "Polite" },
			},
			{
				nodeId = "blackwater-threat",
				parentNodeId = "root",
				order = 3,
				visibility = pressure > 0.2,
				states = { intensity = pressure },
				styleReference = "blackwater-pressure-vignette",
				themeReference = "blackwater-house",
				accessibility = { liveRegion = "Assertive" },
			},
		},
	}
end

function Bridge.initialize(initialObjective: any)
	compositionInstanceId = "blackwater-descent-" .. string.gsub(tostring(os.clock()), "[^%w]", "")
	revision = 0
	activePlan = planFor(0, initialObjective, 0)
	transitionsPlanned = 0
	transitionsCommitted = 0
	table.clear(failures)
end

function Bridge.transition(nextObjective: any, pressure: number): (boolean, string?)
	local targetRevision = revision + 1
	local sessionId = compositionInstanceId .. ".session." .. tostring(targetRevision)
	local patchPlanId = compositionInstanceId .. ".patch." .. tostring(targetRevision)
	local sessionResult = VisualRuntime.createExecutionSession({
		visualExecutionSessionId = sessionId,
		compositionInstanceId = compositionInstanceId,
		robloxRenderingSessionId = "blackwater-runtime-world",
		sourceRevision = revision,
		targetRevision = targetRevision,
		patchPlanId = patchPlanId,
		runtimeMetadata = { chapterId = "blackwater_descent", objectiveId = nextObjective and nextObjective.id or "complete" },
	})
	if not sessionResult.ok then appendFailure("CreateSession", sessionResult); return false, sessionResult.code end
	local targetPlan = planFor(targetRevision, nextObjective, pressure)
	local diffResult = VisualRuntime.buildDiff(activePlan, targetPlan)
	if not diffResult.ok then appendFailure("BuildDiff", diffResult); VisualRuntime.closeExecutionSession(sessionId); return false, diffResult.code end
	local planResult = VisualRuntime.createPatchPlan({ session = sessionResult.session, diff = diffResult.diff })
	if not planResult.ok then appendFailure("CreatePatchPlan", planResult); VisualRuntime.closeExecutionSession(sessionId); return false, planResult.code end
	local sealResult = VisualRuntime.sealPatchPlan(patchPlanId)
	if not sealResult.ok then appendFailure("SealPatchPlan", sealResult); VisualRuntime.closeExecutionSession(sessionId); return false, sealResult.code end
	local prepareResult = VisualRuntime.preparePatch(patchPlanId)
	if not prepareResult.ok then appendFailure("PreparePatch", prepareResult); VisualRuntime.closeExecutionSession(sessionId); return false, prepareResult.code end
	transitionsPlanned += 1
	local appliedResult = VisualRuntime.markApplied(patchPlanId)
	if not appliedResult.ok then appendFailure("MarkApplied", appliedResult); VisualRuntime.closeExecutionSession(sessionId); return false, appliedResult.code end
	local commitResult = VisualRuntime.commitPatch(patchPlanId)
	if not commitResult.ok then appendFailure("CommitPatch", commitResult); VisualRuntime.closeExecutionSession(sessionId); return false, commitResult.code end
	VisualRuntime.closeExecutionSession(sessionId)
	revision = targetRevision
	activePlan = targetPlan
	transitionsCommitted += 1
	return true, nil
end

function Bridge.inspect()
	return {
		compositionInstanceId = compositionInstanceId,
		revision = revision,
		transitionsPlanned = transitionsPlanned,
		transitionsCommitted = transitionsCommitted,
		activePlan = activePlan,
		failures = table.clone(failures),
		phase184Runtime = VisualRuntime.getDiagnostics(),
	}
end

function Bridge.clear()
	compositionInstanceId = ""
	revision = 0
	activePlan = nil
	transitionsPlanned = 0
	transitionsCommitted = 0
	table.clear(failures)
end

return Bridge
