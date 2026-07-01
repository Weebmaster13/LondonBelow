--!strict

local ObjectiveDiagnostics = require(script.Parent.ObjectiveDiagnostics)
local ObjectiveRegistry = require(script.Parent.ObjectiveRegistry)
local ObjectiveState = require(script.Parent.ObjectiveState)
local ObjectiveValidator = require(script.Parent.ObjectiveValidator)

local ObjectiveService = {}

function ObjectiveService.initialize() end

function ObjectiveService.registerObjective(definition: any): (boolean, string?)
	return ObjectiveRegistry.register(definition)
end

function ObjectiveService.startObjective(objectiveId: string): (boolean, string?, any?)
	if ObjectiveRegistry.get(objectiveId) == nil then
		ObjectiveState.recordRejected()
		return false, "unknown objective", nil
	end
	return true, nil, ObjectiveState.start(objectiveId)
end

function ObjectiveService.progressObjective(
	objectiveId: string,
	stepId: string,
	progress: number
): (boolean, string?, any?)
	local status = ObjectiveState.get(objectiveId)
	if status == nil then
		ObjectiveState.recordRejected()
		return false, "unknown objective", nil
	end
	local valid, reason = ObjectiveValidator.validateProgress(status, stepId)
	if not valid then
		ObjectiveState.recordRejected()
		return false, reason, nil
	end
	return true, nil, ObjectiveState.progress(objectiveId, stepId, progress)
end

function ObjectiveService.completeObjective(objectiveId: string): (boolean, string?, any?)
	if ObjectiveState.get(objectiveId) == nil then
		ObjectiveState.recordRejected()
		return false, "unknown objective", nil
	end
	return true, nil, ObjectiveState.complete(objectiveId)
end

function ObjectiveService.inspect()
	return ObjectiveDiagnostics.capture({
		ObjectiveRegistry = ObjectiveRegistry,
		ObjectiveState = ObjectiveState,
	})
end

function ObjectiveService.validate(): (boolean, string?)
	return ObjectiveValidator.validate()
end

function ObjectiveService.runSelfChecks()
	ObjectiveService.shutdown()
	ObjectiveService.registerObjective({
		id = "selfcheck.objective",
		kind = "Primary",
		displayName = "Self Check Objective",
		steps = { "start", "finish" },
		branchIds = {},
		metadata = {},
	})
	local startOk = ObjectiveService.startObjective("selfcheck.objective")
	local progressOk = ObjectiveService.progressObjective("selfcheck.objective", "start", 0.5)
	local completeOk = ObjectiveService.completeObjective("selfcheck.objective")
	ObjectiveService.shutdown()
	return {
		ok = startOk == true and progressOk == true and completeOk == true,
		objectiveProgressionValidates = progressOk == true and completeOk == true,
	}
end

function ObjectiveService.shutdown()
	ObjectiveRegistry.clear()
	ObjectiveState.clear()
end

return ObjectiveService
