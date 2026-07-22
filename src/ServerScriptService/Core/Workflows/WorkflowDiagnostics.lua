--!strict

local Budgets = require(script.Parent.WorkflowBudgets)
local Certification = require(script.Parent.WorkflowCertification)
local Compensation = require(script.Parent.WorkflowCompensation)
local Evidence = require(script.Parent.WorkflowEvidence)
local Instances = require(script.Parent.WorkflowInstances)
local Lifecycle = require(script.Parent.WorkflowLifecycle)
local Metrics = require(script.Parent.WorkflowMetrics)
local Profiler = require(script.Parent.WorkflowProfiler)
local Registry = require(script.Parent.WorkflowRegistry)
local Retries = require(script.Parent.WorkflowRetries)
local Scheduler = require(script.Parent.WorkflowScheduler)
local Serialization = require(script.Parent.WorkflowSerialization)
local Timeouts = require(script.Parent.WorkflowTimeouts)
local Waits = require(script.Parent.WorkflowWaits)

local Diagnostics = {}

function Diagnostics.capture(runtime: any)
	return {
		providerName = "runtimeWorkflowOrchestration",
		workflowOrchestrationPosture = if runtime.isShutdown() then "Shutdown" else "Healthy",
		workflowDefinitions = Registry.inspect(),
		workflowInstances = Instances.inspect(),
		workflowLifecycle = Lifecycle.inspect(),
		workflowSchedule = Scheduler.inspect(),
		pendingWaits = Waits.inspect(),
		retryRecords = Retries.inspect(),
		timeoutRecords = Timeouts.inspect(),
		compensationRecords = Compensation.inspect(),
		workflowEvidence = Evidence.inspect(),
		workflowMetrics = Metrics.inspect(),
		workflowProfiler = Profiler.inspect(),
		workflowBudgets = Budgets.inspect(),
		certification = Certification.inspect(),
		counters = Serialization.deepCopy(runtime.getCounters()),
		noDirectSubsystemCoupling = true,
		noGameplayAuthority = true,
		noCommandExecution = true,
		noEventPublication = true,
		noQueryMutation = true,
		noNetworking = true,
		noPersistenceExecution = true,
		noWorkspaceMutation = true,
		noClientAuthority = true,
	}
end

return Diagnostics
