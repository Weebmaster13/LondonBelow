--!strict

local Evidence = require(script.Parent.WorkflowEvidence)
local Lifecycle = require(script.Parent.WorkflowLifecycle)
local Registry = require(script.Parent.WorkflowRegistry)
local Serialization = require(script.Parent.WorkflowSerialization)
local Types = require(script.Parent.WorkflowTypes)
local Validation = require(script.Parent.WorkflowValidation)

local Instances = {}
local instances: { [string]: any } = {}
local order = {}

function Instances.create(request: any)
	if #order >= Types.Limits.MaxActiveInstances then
		return {
			ok = false,
			code = Types.FailureType.QueueFull,
			message = "workflow instance limit exceeded",
		}
	end
	local ok, reason = Validation.instance(request)
	if not ok then
		return { ok = false, code = Types.FailureType.ValidationFailure, message = reason }
	end
	if instances[request.instanceId] ~= nil then
		return {
			ok = false,
			code = Types.FailureType.DuplicateInstance,
			message = "duplicate instance id",
		}
	end
	local definition = Registry.get(request.workflowId)
	if definition == nil then
		return { ok = false, code = Types.FailureType.UnknownWorkflow, message = "unknown workflow" }
	end
	local instance = {
		instanceId = request.instanceId,
		workflowId = request.workflowId,
		correlationId = request.correlationId,
		causationId = request.causationId,
		requester = request.requester,
		state = definition.entryState,
		variables = Serialization.deepCopy(request.variables),
		metadata = Serialization.deepCopy(request.metadata),
		startTime = os.clock(),
		completionTime = nil,
		evidence = {},
		history = {
			{
				state = definition.entryState,
				source = "Created",
				sequence = 1,
			},
		},
	}
	instances[request.instanceId] = instance
	table.insert(order, request.instanceId)
	table.sort(order)
	Lifecycle.create(request.instanceId)
	Evidence.record("workflow instance created", {
		instanceId = request.instanceId,
		workflowId = request.workflowId,
		state = definition.entryState,
	})
	return { ok = true, code = "Ok", instanceId = request.instanceId }
end

function Instances.get(instanceId: string): any?
	local instance = instances[instanceId]
	return if instance ~= nil then Serialization.deepCopy(instance) else nil
end

function Instances.setState(instanceId: string, state: string, source: string, variables: any?)
	local instance = instances[instanceId]
	if instance == nil then
		return { ok = false, code = Types.FailureType.UnknownInstance, message = "unknown instance" }
	end
	local lifecycle = Lifecycle.get(instanceId)
	if
		lifecycle == Types.LifecycleState.Completed
		or lifecycle == Types.LifecycleState.Cancelled
		or lifecycle == Types.LifecycleState.Failed
		or lifecycle == Types.LifecycleState.Archived
	then
		return {
			ok = false,
			code = Types.FailureType.TerminalInstanceMutation,
			message = "terminal instance cannot mutate",
		}
	end
	instance.state = state
	if variables ~= nil then
		instance.variables = Serialization.deepCopy(variables)
	end
	table.insert(instance.history, {
		state = state,
		source = source,
		sequence = #instance.history + 1,
	})
	while #instance.history > Types.Limits.MaxHistory do
		table.remove(instance.history, 1)
	end
	Evidence.record(
		"workflow instance state changed",
		{ instanceId = instanceId, state = state, source = source }
	)
	return { ok = true, code = "Ok", instanceId = instanceId, state = state }
end

function Instances.complete(instanceId: string, terminalState: string)
	local instance = instances[instanceId]
	if instance == nil then
		return { ok = false, code = Types.FailureType.UnknownInstance, message = "unknown instance" }
	end
	instance.completionTime = os.clock()
	instance.state = terminalState
	table.insert(instance.history, {
		state = terminalState,
		source = "Terminal",
		sequence = #instance.history + 1,
	})
	while #instance.history > Types.Limits.MaxHistory do
		table.remove(instance.history, 1)
	end
	Evidence.record(
		"workflow instance completed",
		{ instanceId = instanceId, terminalState = terminalState }
	)
	return { ok = true, code = "Ok", instanceId = instanceId, state = terminalState }
end

function Instances.inspect()
	local result = {}
	for _, instanceId in ipairs(order) do
		result[instanceId] = Serialization.deepCopy(instances[instanceId])
	end
	return result
end

function Instances.count(): number
	return #order
end

function Instances.clear()
	table.clear(instances)
	table.clear(order)
end

return Instances
