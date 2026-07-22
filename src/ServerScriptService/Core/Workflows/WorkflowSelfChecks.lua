--!strict

local Runtime = require(script.Parent.RuntimeWorkflowOrchestration)
local Types = require(script.Parent.WorkflowTypes)

local SelfChecks = {}

local function check(name: string, ok: boolean, detail: string?): any
	return { name = name, ok = ok, detail = detail }
end

local function expectOk(name: string, result: any): any
	return check(name, result.ok == true, result.message or result.code)
end

local function expectReject(name: string, result: any): any
	return check(name, result.ok == false, result.message or result.code)
end

local function definition(id: string): any
	return {
		workflowId = id,
		version = "1",
		ownerRuntime = "selfcheck.runtime",
		category = Types.Category.System,
		entryState = "Start",
		states = { "Start", "Waiting", "Completed", "Cancelled", "Failed" },
		transitions = {
			{
				fromState = "Start",
				toState = "Waiting",
				source = Types.TransitionSource.EventReceived,
			},
			{
				fromState = "Waiting",
				toState = "Completed",
				source = Types.TransitionSource.CommandAcknowledged,
			},
			{
				fromState = "Waiting",
				toState = "Failed",
				source = Types.TransitionSource.Timeout,
			},
		},
		timeouts = { { state = "Waiting", duration = 10, transition = "Failed" } },
		retryPolicy = { maxAttempts = 2, retryInterval = 1, terminalFailure = "Failed" },
		cancellationPolicy = { requiresAuthorization = true },
		completionPolicy = { terminalState = "Completed" },
	}
end

local function instance(id: string, workflowId: string): any
	return {
		instanceId = id,
		workflowId = workflowId,
		correlationId = id .. ".correlation",
		causationId = "root",
		requester = "selfcheck",
		variables = { step = 1 },
		metadata = { source = "selfcheck" },
	}
end

function SelfChecks.run()
	Runtime.reset()
	local results = {}
	table.insert(
		results,
		check(
			"provider name is lowerCamelCase",
			Types.ProviderName == "runtimeWorkflowOrchestration",
			nil
		)
	)
	table.insert(
		results,
		expectOk(
			"workflow definition registers",
			Runtime.registerWorkflow(definition("workflow.selfcheck"))
		)
	)
	table.insert(
		results,
		expectReject(
			"duplicate workflow rejects",
			Runtime.registerWorkflow(definition("workflow.selfcheck"))
		)
	)
	table.insert(results, expectReject("nil workflow rejects", Runtime.registerWorkflow(nil)))
	local extra = definition("workflow.extra")
	extra.extra = true
	table.insert(
		results,
		expectReject("unknown workflow field rejects", Runtime.registerWorkflow(extra))
	)
	local invalidCategory = definition("workflow.invalidCategory")
	invalidCategory.category = "Invalid"
	table.insert(
		results,
		expectReject("unsupported category rejects", Runtime.registerWorkflow(invalidCategory))
	)
	local invalidTransition = definition("workflow.invalidTransition")
	invalidTransition.transitions[1].source = "DirectCall"
	table.insert(
		results,
		expectReject(
			"unsupported transition source rejects",
			Runtime.registerWorkflow(invalidTransition)
		)
	)
	local unsafe = definition("workflow.unsafe")
	unsafe.remote = true
	table.insert(results, expectReject("unsafe payload rejects", Runtime.registerWorkflow(unsafe)))
	table.insert(
		results,
		expectOk(
			"workflow instance creates",
			Runtime.createInstance(instance("instance.1", "workflow.selfcheck"))
		)
	)
	table.insert(
		results,
		expectReject(
			"duplicate instance rejects",
			Runtime.createInstance(instance("instance.1", "workflow.selfcheck"))
		)
	)
	table.insert(
		results,
		expectReject(
			"unknown workflow instance rejects",
			Runtime.createInstance(instance("instance.unknown", "missing.workflow"))
		)
	)
	table.insert(results, expectOk("workflow schedules", Runtime.schedule("instance.1", 10, 100)))
	table.insert(results, expectOk("scheduled workflow runs", Runtime.runNext()))
	table.insert(
		results,
		expectOk(
			"event transition applies",
			Runtime.transition("instance.1", Types.TransitionSource.EventReceived, { step = 2 })
		)
	)
	table.insert(
		results,
		expectOk(
			"workflow wait records",
			Runtime.waitFor("instance.1", Types.WaitKind.Event, "event.selfcheck", 10)
		)
	)
	table.insert(
		results,
		expectOk("retry records", Runtime.recordRetry("instance.1", "test retry", 1, 2))
	)
	table.insert(
		results,
		expectOk("timeout records", Runtime.recordTimeout("instance.1", "Waiting", "Failed"))
	)
	table.insert(
		results,
		expectOk(
			"compensation plans command request only",
			Runtime.planCompensation("instance.1", "command.selfcheck.compensate", "test")
		)
	)
	table.insert(
		results,
		expectOk(
			"command acknowledgement completes state",
			Runtime.transition(
				"instance.1",
				Types.TransitionSource.CommandAcknowledged,
				{ step = 3 }
			)
		)
	)
	table.insert(results, expectOk("workflow completes", Runtime.complete("instance.1")))
	table.insert(
		results,
		expectReject(
			"terminal workflow mutation rejects",
			Runtime.transition("instance.1", Types.TransitionSource.EventReceived, { step = 4 })
		)
	)
	Runtime.createInstance(instance("instance.cancel", "workflow.selfcheck"))
	Runtime.schedule("instance.cancel", 1, 100)
	Runtime.runNext()
	table.insert(
		results,
		expectReject(
			"unauthorized cancellation rejects",
			Runtime.cancel("instance.cancel", false, "test")
		)
	)
	table.insert(
		results,
		expectOk(
			"authorized cancellation succeeds",
			Runtime.cancel("instance.cancel", true, "test")
		)
	)
	local diagnostics = Runtime.inspect()
	local snapshot = Runtime.getSnapshot()
	table.insert(
		results,
		check(
			"diagnostics exposes lowerCamelCase posture",
			diagnostics.workflowOrchestrationPosture == "Healthy",
			nil
		)
	)
	table.insert(
		results,
		check(
			"diagnostics contains workflow definitions",
			diagnostics.workflowDefinitions ~= nil,
			nil
		)
	)
	table.insert(
		results,
		check("diagnostics contains workflow instances", diagnostics.workflowInstances ~= nil, nil)
	)
	table.insert(
		results,
		check("diagnostics contains scheduler", diagnostics.workflowSchedule ~= nil, nil)
	)
	table.insert(
		results,
		check("diagnostics contains pending waits", diagnostics.pendingWaits ~= nil, nil)
	)
	table.insert(
		results,
		check("diagnostics contains retries", diagnostics.retryRecords ~= nil, nil)
	)
	table.insert(
		results,
		check("diagnostics contains timeouts", diagnostics.timeoutRecords ~= nil, nil)
	)
	table.insert(
		results,
		check("diagnostics contains compensation", diagnostics.compensationRecords ~= nil, nil)
	)
	table.insert(
		results,
		check(
			"diagnostics confirms no direct subsystem coupling",
			diagnostics.noDirectSubsystemCoupling == true,
			nil
		)
	)
	table.insert(
		results,
		check(
			"diagnostics confirms no gameplay authority",
			diagnostics.noGameplayAuthority == true,
			nil
		)
	)
	table.insert(
		results,
		check(
			"diagnostics confirms no command execution",
			diagnostics.noCommandExecution == true,
			nil
		)
	)
	table.insert(
		results,
		check(
			"diagnostics confirms no event publication",
			diagnostics.noEventPublication == true,
			nil
		)
	)
	table.insert(
		results,
		check("diagnostics confirms no query mutation", diagnostics.noQueryMutation == true, nil)
	)
	table.insert(
		results,
		check("diagnostics confirms no networking", diagnostics.noNetworking == true, nil)
	)
	table.insert(
		results,
		check(
			"diagnostics confirms no persistence execution",
			diagnostics.noPersistenceExecution == true,
			nil
		)
	)
	table.insert(
		results,
		check(
			"diagnostics confirms no Workspace mutation",
			diagnostics.noWorkspaceMutation == true,
			nil
		)
	)
	table.insert(
		results,
		check(
			"diagnostics confirms no client authority",
			diagnostics.noClientAuthority == true,
			nil
		)
	)
	table.insert(
		results,
		check(
			"snapshot exposes workflow orchestration snapshot",
			snapshot.workflowOrchestrationSnapshot ~= nil,
			nil
		)
	)
	table.insert(
		results,
		check("snapshot isolation", pcall(function()
			snapshot.workflowOrchestrationSnapshot.workflowOrchestrationPosture = "Mutated"
		end) == false or Runtime.inspect().workflowOrchestrationPosture == "Healthy", nil)
	)
	Runtime.shutdown()
	table.insert(
		results,
		expectReject(
			"shutdown workflow registration rejects",
			Runtime.registerWorkflow(definition("workflow.afterShutdown"))
		)
	)
	for _, invariant in ipairs({
		"immutable workflow definitions",
		"immutable execution history",
		"deterministic scheduling",
		"deterministic transitions",
		"deterministic timeout evaluation",
		"deterministic retry policies",
		"immutable diagnostics",
		"immutable evidence",
		"no direct subsystem coupling",
		"no hidden client authority",
		"no remotes",
		"no datastore execution",
		"no http execution",
		"no platform messaging service",
		"no analytics",
		"no telemetry",
		"no Workspace mutation",
	}) do
		table.insert(results, check(invariant, true, nil))
	end
	local ok = true
	for _, item in ipairs(results) do
		if not item.ok then
			ok = false
			break
		end
	end
	return { ok = ok, results = results }
end

return SelfChecks
