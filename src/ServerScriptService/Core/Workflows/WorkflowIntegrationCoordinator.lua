--!strict

local Runtime = require(script.Parent.RuntimeWorkflowOrchestration)

local IntegrationCoordinator = {}
IntegrationCoordinator.coordinatorId = "WorkflowIntegrationCoordinator"

function IntegrationCoordinator.activateWorkflow(request: any, priority: number?, deadline: number?)
	return Runtime.activateWorkflow(request, priority, deadline)
end

function IntegrationCoordinator.routeMessage(message: any)
	return Runtime.routeMessage(message)
end

function IntegrationCoordinator.suspendWorkflow(
	instanceId: string,
	waitKind: string,
	target: string,
	timeoutAt: number?
)
	return Runtime.suspendWorkflow(instanceId, waitKind, target, timeoutAt)
end

function IntegrationCoordinator.resumeWorkflow(message: any)
	return Runtime.resumeWorkflow(message)
end

function IntegrationCoordinator.validateCompletion(instanceId: string)
	return Runtime.validateCompletion(instanceId)
end

function IntegrationCoordinator.inspect()
	return Runtime.inspect().workflowIntegration
end

return IntegrationCoordinator
