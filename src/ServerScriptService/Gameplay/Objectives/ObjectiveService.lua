--!strict

local ObjectiveDiagnostics = require(script.Parent.ObjectiveDiagnostics)
local ObjectiveRegistry = require(script.Parent.ObjectiveRegistry)
local ObjectiveState = require(script.Parent.ObjectiveState)
local ObjectiveValidator = require(script.Parent.ObjectiveValidator)
local ObservationService =
	require(game:GetService("ServerScriptService").Horror.Observation.ObservationService)

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
	local status = ObjectiveState.start(objectiveId)
	ObservationService.observe({
		id = "Objective.Started",
		source = "ObjectiveService",
		metadata = { objectiveId = objectiveId },
	})
	return true, nil, status
end

function ObjectiveService.progressObjective(
	objectiveId: string,
	stepId: string,
	progress: number
): (boolean, string?, any?)
	local status = ObjectiveState.get(objectiveId)
	local definition = ObjectiveRegistry.get(objectiveId)
	if status == nil then
		ObjectiveState.recordRejected()
		return false, "unknown objective", nil
	end
	if definition == nil or not ObjectiveValidator.definitionHasStep(definition, stepId) then
		ObjectiveState.recordRejected()
		return false, "objective step is not defined", nil
	end
	local valid, reason = ObjectiveValidator.validateProgress(status, stepId)
	if not valid then
		ObjectiveState.recordRejected()
		return false, reason, nil
	end
	local nextStatus = ObjectiveState.progress(objectiveId, stepId, progress)
	ObservationService.observe({
		id = "Objective.Progressed",
		source = "ObjectiveService",
		metadata = {
			objectiveId = objectiveId,
			stepId = stepId,
			progress = progress,
		},
	})
	return true, nil, nextStatus
end

function ObjectiveService.completeObjective(objectiveId: string): (boolean, string?, any?)
	local currentStatus = ObjectiveState.get(objectiveId)
	if currentStatus == nil then
		ObjectiveState.recordRejected()
		return false, "unknown objective", nil
	end
	if currentStatus.failed == true then
		ObjectiveState.recordRejected()
		return false, "failed objective cannot complete", nil
	end
	local status = ObjectiveState.complete(objectiveId)
	ObservationService.observe({
		id = "Objective.Completed",
		source = "ObjectiveService",
		metadata = { objectiveId = objectiveId },
	})
	return true, nil, status
end

function ObjectiveService.failObjective(
	objectiveId: string,
	reason: string?
): (boolean, string?, any?)
	local currentStatus = ObjectiveState.get(objectiveId)
	if currentStatus == nil then
		ObjectiveState.recordRejected()
		return false, "unknown objective", nil
	end
	if currentStatus.completed == true then
		ObjectiveState.recordRejected()
		return false, "completed objective cannot fail", nil
	end
	local status = ObjectiveState.fail(objectiveId, reason)
	ObservationService.observe({
		id = "Objective.Failed",
		source = "ObjectiveService",
		metadata = {
			objectiveId = objectiveId,
			reason = reason or "unspecified",
		},
	})
	return true, nil, status
end

function ObjectiveService.inspect()
	return ObjectiveDiagnostics.capture({
		ObjectiveRegistry = ObjectiveRegistry,
		ObjectiveState = ObjectiveState,
	})
end

function ObjectiveService.serialize()
	return {
		registry = ObjectiveRegistry.serialize(),
		state = ObjectiveState.serialize(),
	}
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
