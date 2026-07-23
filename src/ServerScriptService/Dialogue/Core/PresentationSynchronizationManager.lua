--!strict

local Acknowledgements = require(script.Parent.PresentationAcknowledgementRegistry)
local Evidence = require(script.Parent.PresentationEvidence)
local Metrics = require(script.Parent.PresentationMetrics)
local RequestRegistry = require(script.Parent.PresentationRequestRegistry)
local Serialization = require(script.Parent.DialogueSerialization)
local Types = require(script.Parent.DialoguePresentationTypes)

local Manager = {}
local records = {}

local terminal = {
	[Types.RequestStatus.Completed] = true,
	[Types.RequestStatus.Cancelled] = true,
	[Types.RequestStatus.Rejected] = true,
	[Types.RequestStatus.Expired] = true,
	[Types.RequestStatus.Failed] = true,
	[Types.RequestStatus.Closed] = true,
}

local function satisfies(policy: string, status: string): boolean
	if policy == Types.SynchronizationPolicy.NoWait then
		return true
	elseif policy == Types.SynchronizationPolicy.WaitForAccepted then
		return status == Types.RequestStatus.Accepted
			or status == Types.RequestStatus.Started
			or status == Types.RequestStatus.Completed
	elseif policy == Types.SynchronizationPolicy.WaitForStarted then
		return status == Types.RequestStatus.Started or status == Types.RequestStatus.Completed
	elseif policy == Types.SynchronizationPolicy.WaitForCompleted then
		return status == Types.RequestStatus.Completed
	elseif policy == Types.SynchronizationPolicy.WaitForCancelled then
		return status == Types.RequestStatus.Cancelled
	elseif policy == Types.SynchronizationPolicy.WaitForTerminalState then
		return terminal[status] == true
	end
	return false
end

function Manager.resolve(presentationId: string)
	local request = RequestRegistry.get(presentationId)
	if request == nil then
		return {
			ok = false,
			code = Types.FailureType.UnknownPresentation,
			message = "unknown presentation",
		}
	end
	local latest = Acknowledgements.latestForPresentation(presentationId)
	local satisfied = satisfies(request.synchronizationPolicy, request.status)
	local record = {
		presentationId = presentationId,
		executionId = request.executionId,
		policy = request.synchronizationPolicy,
		status = request.status,
		satisfied = satisfied,
		latestAcknowledgement = latest,
	}
	records[#records + 1] = Serialization.deepCopy(record)
	if #records > Types.Limits.MaxSynchronizationRecords then
		table.remove(records, 1)
	end
	if satisfied then
		Metrics.increment("synchronizationCompletions")
		Evidence.record("synchronization satisfied", record)
	end
	return { ok = true, code = "Ok", synchronization = record }
end

function Manager.inspect()
	return Serialization.copyArray(records)
end

function Manager.clear()
	table.clear(records)
end

return Manager
