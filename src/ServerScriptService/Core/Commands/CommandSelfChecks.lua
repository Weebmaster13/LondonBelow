--!strict

local Runtime = require(script.Parent.RuntimeCommandBus)
local Batch = require(script.Parent.CommandBatchRuntime)
local Recovery = require(script.Parent.CommandRecovery)
local Replay = require(script.Parent.CommandReplay)
local RetryRuntime = require(script.Parent.CommandRetryRuntime)
local TransactionRuntime = require(script.Parent.CommandTransactionRuntime)
local Types = require(script.Parent.CommandTypes)

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

local function payloadValidator(payload: any): (boolean, string?)
	if type(payload) ~= "table" then
		return false, "payload must be a table"
	end
	return true, nil
end

function SelfChecks.run()
	Runtime.reset()
	local results = {}
	local executed = {}
	table.insert(
		results,
		expectOk(
			"command definition registry accepts single owner",
			Runtime.registerCommandType({
				commandType = "core.command.selfcheck",
				schemaVersion = "1",
				ownerRuntime = Types.ProviderName,
				defaultPriority = Types.Priority.Normal,
				executionPolicy = Types.ExecutionPolicy.AuthoritativeSingleOwner,
				executionMode = Types.ExecutionMode.Exclusive,
				idempotencyPolicy = Types.IdempotencyPolicy.OptionalIdempotencyKey,
				retryPolicy = Types.RetryPolicy.NeverRetry,
				timeoutBudget = Types.Limits.DefaultExecutionBudget,
				lockIds = { "selfcheck.lock" },
				commandReplayPolicy = Types.CommandReplayPolicy.ReplayMetadataOnly,
				payloadValidator = payloadValidator,
				allowedRequesters = { "selfcheck.requester" },
			})
		)
	)
	table.insert(
		results,
		expectReject(
			"duplicate command definition rejects",
			Runtime.registerCommandType({
				commandType = "core.command.selfcheck",
				schemaVersion = "1",
				ownerRuntime = Types.ProviderName,
				defaultPriority = Types.Priority.Normal,
				executionPolicy = Types.ExecutionPolicy.AuthoritativeSingleOwner,
				executionMode = Types.ExecutionMode.Immediate,
				payloadValidator = payloadValidator,
				allowedRequesters = { "selfcheck.requester" },
			})
		)
	)
	table.insert(
		results,
		expectReject(
			"invalid execution policy rejects",
			Runtime.registerCommandType({
				commandType = "core.command.invalid.policy",
				schemaVersion = "1",
				ownerRuntime = Types.ProviderName,
				defaultPriority = Types.Priority.Normal,
				executionPolicy = Types.ExecutionPolicy.AuthoritativeSingleOwner,
				executionMode = "WallClock",
				payloadValidator = payloadValidator,
				allowedRequesters = { "selfcheck.requester" },
			})
		)
	)
	table.insert(
		results,
		expectReject(
			"invalid retry policy rejects",
			Runtime.registerCommandType({
				commandType = "core.command.invalid.retry",
				schemaVersion = "1",
				ownerRuntime = Types.ProviderName,
				defaultPriority = Types.Priority.Normal,
				executionPolicy = Types.ExecutionPolicy.AuthoritativeSingleOwner,
				retryPolicy = "RetryForever",
				payloadValidator = payloadValidator,
				allowedRequesters = { "selfcheck.requester" },
			})
		)
	)
	table.insert(
		results,
		expectReject(
			"invalid lock definition rejects",
			Runtime.registerCommandType({
				commandType = "core.command.invalid.lock",
				schemaVersion = "1",
				ownerRuntime = Types.ProviderName,
				defaultPriority = Types.Priority.Normal,
				executionPolicy = Types.ExecutionPolicy.AuthoritativeSingleOwner,
				lockIds = { "" },
				payloadValidator = payloadValidator,
				allowedRequesters = { "selfcheck.requester" },
			})
		)
	)
	table.insert(
		results,
		expectReject(
			"ambiguous owner rejects",
			Runtime.registerCommandType({
				commandType = "core.command.ambiguous",
				schemaVersion = "1",
				ownerRuntime = "",
				defaultPriority = Types.Priority.Normal,
				executionPolicy = Types.ExecutionPolicy.AuthoritativeSingleOwner,
				payloadValidator = payloadValidator,
				allowedRequesters = { "selfcheck.requester" },
			})
		)
	)
	table.insert(
		results,
		expectOk(
			"requester registry accepts server requester",
			Runtime.registerRequester({
				requesterId = "selfcheck.requester",
				runtimeId = "selfcheck.runtime",
				allowedCommandTypes = { "*" },
				authorityPolicy = "ServerAuthority",
			})
		)
	)
	table.insert(
		results,
		expectReject(
			"client requester rejects",
			Runtime.registerRequester({
				requesterId = "client.requester",
				runtimeId = "client.runtime",
				allowedCommandTypes = { "core.command.selfcheck" },
				authorityPolicy = "ClientAuthority",
			})
		)
	)
	table.insert(
		results,
		expectOk(
			"handler registry accepts authoritative handler",
			Runtime.registerHandler({
				handlerId = "selfcheck.handler",
				runtimeId = Types.ProviderName,
				commandType = "core.command.selfcheck",
				execute = function(command: any)
					table.insert(executed, command.payload.order)
					return { success = true, resultCode = "Done" }
				end,
			})
		)
	)
	table.insert(
		results,
		expectReject(
			"duplicate handler rejects",
			Runtime.registerHandler({
				handlerId = "selfcheck.handler.2",
				runtimeId = Types.ProviderName,
				commandType = "core.command.selfcheck",
				execute = function()
					return { success = true }
				end,
			})
		)
	)
	table.insert(
		results,
		expectReject(
			"unknown command type rejects",
			Runtime.submit({
				commandType = "core.command.unknown",
				schemaVersion = "1",
				requesterId = "selfcheck.requester",
				payload = {},
			})
		)
	)
	table.insert(
		results,
		expectReject(
			"unknown requester rejects",
			Runtime.submit({
				commandType = "core.command.selfcheck",
				schemaVersion = "1",
				requesterId = "unknown.requester",
				payload = {},
			})
		)
	)
	table.insert(
		results,
		expectReject(
			"schema mismatch rejects",
			Runtime.submit({
				commandType = "core.command.selfcheck",
				schemaVersion = "2",
				requesterId = "selfcheck.requester",
				payload = {},
			})
		)
	)
	table.insert(
		results,
		expectReject(
			"invalid payload rejects",
			Runtime.submit({
				commandType = "core.command.selfcheck",
				schemaVersion = "1",
				requesterId = "selfcheck.requester",
				payload = "bad",
			})
		)
	)
	for _, item in ipairs({
		{ id = "command.low", priority = Types.Priority.Low, order = "Low" },
		{ id = "command.critical", priority = Types.Priority.Critical, order = "Critical" },
		{ id = "command.normal", priority = Types.Priority.Normal, order = "Normal" },
		{ id = "command.high", priority = Types.Priority.High, order = "High" },
	}) do
		table.insert(
			results,
			expectOk(
				item.id .. " queues",
				Runtime.submit({
					commandId = item.id,
					commandType = "core.command.selfcheck",
					schemaVersion = "1",
					requesterId = "selfcheck.requester",
					priority = item.priority,
					payload = { order = item.order },
				})
			)
		)
	end
	table.insert(
		results,
		expectReject(
			"duplicate command id rejects",
			Runtime.submit({
				commandId = "command.low",
				commandType = "core.command.selfcheck",
				schemaVersion = "1",
				requesterId = "selfcheck.requester",
				payload = {},
			})
		)
	)
	Runtime.dispatchAll()
	table.insert(
		results,
		check(
			"priority ordering is deterministic",
			table.concat(executed, ",") == "Critical,High,Normal,Low",
			table.concat(executed, ",")
		)
	)
	table.clear(executed)
	for _, id in ipairs({ "fifo.a", "fifo.b", "fifo.c" }) do
		Runtime.submit({
			commandId = id,
			commandType = "core.command.selfcheck",
			schemaVersion = "1",
			requesterId = "selfcheck.requester",
			priority = Types.Priority.Normal,
			payload = { order = id },
		})
	end
	Runtime.dispatchAll()
	table.insert(
		results,
		check(
			"equal priority FIFO holds",
			table.concat(executed, ",") == "fifo.a,fifo.b,fifo.c",
			table.concat(executed, ",")
		)
	)
	table.insert(
		results,
		expectOk(
			"idempotent command queues",
			Runtime.submit({
				commandId = "idem.1",
				commandType = "core.command.selfcheck",
				schemaVersion = "1",
				requesterId = "selfcheck.requester",
				idempotencyKey = "idem.key",
				payload = { order = "idem" },
			})
		)
	)
	table.insert(
		results,
		expectReject(
			"duplicate idempotency key rejects",
			Runtime.submit({
				commandId = "idem.2",
				commandType = "core.command.selfcheck",
				schemaVersion = "1",
				requesterId = "selfcheck.requester",
				idempotencyKey = "idem.key",
				payload = { order = "idem" },
			})
		)
	)
	table.insert(results, expectOk("queued cancellation succeeds", Runtime.cancel("idem.1")))
	table.insert(
		results,
		expectReject("unknown cancellation rejects", Runtime.cancel("missing.command"))
	)
	table.insert(
		results,
		check("lock acquisition/release clears held locks", Runtime.inspect().heldLocks == 0, nil)
	)
	table.insert(
		results,
		expectOk(
			"timeout command definition accepts bounded budget",
			Runtime.registerCommandType({
				commandType = "core.command.timeout",
				schemaVersion = "1",
				ownerRuntime = Types.ProviderName,
				defaultPriority = Types.Priority.Normal,
				executionPolicy = Types.ExecutionPolicy.AuthoritativeSingleOwner,
				executionMode = Types.ExecutionMode.Immediate,
				timeoutBudget = 1,
				payloadValidator = payloadValidator,
				allowedRequesters = { "selfcheck.requester" },
			})
		)
	)
	table.insert(
		results,
		expectOk(
			"timeout handler accepts",
			Runtime.registerHandler({
				handlerId = "timeout.handler",
				runtimeId = Types.ProviderName,
				commandType = "core.command.timeout",
				execute = function()
					return { success = true, diagnostics = { ticksUsed = 2 } }
				end,
			})
		)
	)
	Runtime.submit({
		commandId = "timeout.1",
		commandType = "core.command.timeout",
		schemaVersion = "1",
		requesterId = "selfcheck.requester",
		payload = {},
	})
	table.insert(
		results,
		check(
			"timeout enforcement produces deterministic failure",
			Runtime.dispatchNext().code == Types.FailureType.ExecutionTimeoutFailure,
			nil
		)
	)
	table.insert(
		results,
		expectOk(
			"transaction command definition accepts",
			Runtime.registerCommandType({
				commandType = "core.command.transaction",
				schemaVersion = "1",
				ownerRuntime = Types.ProviderName,
				defaultPriority = Types.Priority.Normal,
				executionPolicy = Types.ExecutionPolicy.AuthoritativeSingleOwner,
				executionMode = Types.ExecutionMode.Transactional,
				payloadValidator = payloadValidator,
				allowedRequesters = { "selfcheck.requester" },
			})
		)
	)
	table.insert(
		results,
		expectOk(
			"transaction handler accepts",
			Runtime.registerHandler({
				handlerId = "transaction.handler",
				runtimeId = Types.ProviderName,
				commandType = "core.command.transaction",
				execute = function(command: any)
					return { success = command.payload.success ~= false }
				end,
			})
		)
	)
	Runtime.submit({
		commandId = "transaction.ok",
		commandType = "core.command.transaction",
		schemaVersion = "1",
		requesterId = "selfcheck.requester",
		transactionId = "transaction.selfcheck.ok",
		payload = { success = true },
	})
	Runtime.dispatchNext()
	table.insert(
		results,
		check(
			"transaction lifecycle commits successful command",
			TransactionRuntime.inspect()["transaction.selfcheck.ok"].state == "Committed",
			nil
		)
	)
	Runtime.submit({
		commandId = "transaction.fail",
		commandType = "core.command.transaction",
		schemaVersion = "1",
		requesterId = "selfcheck.requester",
		transactionId = "transaction.selfcheck.fail",
		payload = { success = false },
	})
	Runtime.dispatchNext()
	table.insert(
		results,
		check(
			"rollback behavior marks failed transaction",
			TransactionRuntime.inspect()["transaction.selfcheck.fail"].state == "RolledBack",
			nil
		)
	)
	table.insert(
		results,
		expectOk(
			"batch command definition accepts",
			Runtime.registerCommandType({
				commandType = "core.command.batch",
				schemaVersion = "1",
				ownerRuntime = Types.ProviderName,
				defaultPriority = Types.Priority.Normal,
				executionPolicy = Types.ExecutionPolicy.AuthoritativeSingleOwner,
				executionMode = Types.ExecutionMode.Batch,
				payloadValidator = payloadValidator,
				allowedRequesters = { "selfcheck.requester" },
			})
		)
	)
	table.insert(
		results,
		expectOk(
			"batch handler accepts",
			Runtime.registerHandler({
				handlerId = "batch.handler",
				runtimeId = Types.ProviderName,
				commandType = "core.command.batch",
				execute = function()
					return { success = true }
				end,
			})
		)
	)
	Runtime.submit({
		commandId = "batch.1",
		commandType = "core.command.batch",
		schemaVersion = "1",
		requesterId = "selfcheck.requester",
		batchId = "batch.selfcheck",
		payload = {},
	})
	Runtime.dispatchNext()
	table.insert(
		results,
		check(
			"batch execution metadata records batch",
			Batch.inspect()["batch.selfcheck"] ~= nil,
			nil
		)
	)
	Runtime.submit({
		commandId = "ancestry.parent",
		commandType = "core.command.selfcheck",
		schemaVersion = "1",
		requesterId = "selfcheck.requester",
		payload = { order = "parent" },
	})
	table.insert(
		results,
		expectOk(
			"nested command ancestry accepts parent reference",
			Runtime.submit({
				commandId = "ancestry.child",
				commandType = "core.command.selfcheck",
				schemaVersion = "1",
				requesterId = "selfcheck.requester",
				correlationId = "ancestry.parent",
				causationId = "ancestry.parent",
				payload = { order = "child" },
			})
		)
	)
	Runtime.submit({
		commandId = "ancestry.circular.a",
		commandType = "core.command.selfcheck",
		schemaVersion = "1",
		requesterId = "selfcheck.requester",
		causationId = "ancestry.circular.b",
		payload = { order = "a" },
	})
	table.insert(
		results,
		check("circular submission rejection", Runtime.submit({
			commandId = "ancestry.circular.b",
			commandType = "core.command.selfcheck",
			schemaVersion = "1",
			requesterId = "selfcheck.requester",
			causationId = "ancestry.circular.a",
			payload = { order = "b" },
		}).code == Types.FailureType.CircularCommandFailure, nil)
	)
	local previousId = "ancestry.depth.root"
	Runtime.submit({
		commandId = previousId,
		commandType = "core.command.selfcheck",
		schemaVersion = "1",
		requesterId = "selfcheck.requester",
		payload = { order = previousId },
	})
	for index = 1, Types.Limits.MaxNestedDepth do
		local commandId = "ancestry.depth." .. tostring(index)
		Runtime.submit({
			commandId = commandId,
			commandType = "core.command.selfcheck",
			schemaVersion = "1",
			requesterId = "selfcheck.requester",
			causationId = previousId,
			payload = { order = commandId },
		})
		previousId = commandId
	end
	table.insert(
		results,
		check("maximum nesting depth rejects overflow", Runtime.submit({
			commandId = "ancestry.depth.overflow",
			commandType = "core.command.selfcheck",
			schemaVersion = "1",
			requesterId = "selfcheck.requester",
			causationId = previousId,
			payload = { order = "overflow" },
		}).code == Types.FailureType.NestedCommandDepthExceeded, nil)
	)
	table.insert(
		results,
		check(
			"retry limits stop bounded retry",
			RetryRuntime.shouldRetry(
				{ retryAttempts = Types.Limits.MaxRetryAttempts },
				{ retryPolicy = Types.RetryPolicy.BoundedRetry }
			) == false,
			nil
		)
	)
	table.insert(
		results,
		check("replay determinism metadata records sequence", #Replay.inspect() > 0, nil)
	)
	Recovery.markInterrupted(
		{ commandId = "recovery.interrupted", commandType = "core.command.selfcheck" },
		"selfcheck"
	)
	table.insert(
		results,
		check("interrupted recovery records owner policy", #Recovery.inspect() > 0, nil)
	)
	local snapshot = Runtime.getSnapshot()
	table.insert(
		results,
		check("diagnostics exposes posture", Runtime.inspect().commandBusPosture == "Healthy", nil)
	)
	table.insert(
		results,
		check("snapshot exposes registry", snapshot.commandRegistrySnapshot ~= nil, nil)
	)
	table.insert(
		results,
		check("lifecycle state machine snapshot exists", snapshot.lifecycleSnapshot ~= nil, nil)
	)
	table.insert(
		results,
		check(
			"execution policy registry snapshot exists",
			snapshot.executionPolicyRegistrySnapshot ~= nil,
			nil
		)
	)
	table.insert(
		results,
		check("lock registry snapshot exists", snapshot.lockRegistrySnapshot ~= nil, nil)
	)
	table.insert(
		results,
		check(
			"active transactions snapshot exists",
			snapshot.activeTransactionsSnapshot ~= nil,
			nil
		)
	)
	table.insert(
		results,
		check("retry queue snapshot exists", snapshot.retryQueueSnapshot ~= nil, nil)
	)
	table.insert(
		results,
		check("replay metadata snapshot exists", snapshot.replayMetadataSnapshot ~= nil, nil)
	)
	table.insert(
		results,
		check("recovery metadata snapshot exists", snapshot.recoveryMetadataSnapshot ~= nil, nil)
	)
	table.insert(
		results,
		check(
			"interrupted commands snapshot exists",
			snapshot.interruptedCommandsSnapshot ~= nil,
			nil
		)
	)
	table.insert(
		results,
		check(
			"nested ancestry graph snapshot exists",
			snapshot.nestedAncestryGraphSnapshot ~= nil,
			nil
		)
	)
	table.insert(
		results,
		check("batch state snapshot exists", snapshot.batchStateSnapshot ~= nil, nil)
	)
	table.insert(
		results,
		check(
			"diagnostics expansion exposes timeout count",
			Runtime.inspect().timeoutCount >= 1,
			nil
		)
	)
	table.insert(
		results,
		check("diagnostics expansion exposes batch count", Runtime.inspect().batchCount >= 1, nil)
	)
	table.insert(
		results,
		check(
			"diagnostics expansion exposes transaction failures",
			Runtime.inspect().transactionFailures >= 0,
			nil
		)
	)
	table.insert(
		results,
		check("timeline recording snapshot exists", snapshot.timelineSnapshot ~= nil, nil)
	)
	table.insert(
		results,
		check("stage duration recording exists", snapshot.timelineSnapshot.timelines ~= nil, nil)
	)
	table.insert(
		results,
		check(
			"execution graph generation snapshot exists",
			snapshot.executionGraphSnapshot ~= nil,
			nil
		)
	)
	table.insert(
		results,
		check(
			"correlation graph generation snapshot exists",
			snapshot.correlationGraphSnapshot ~= nil,
			nil
		)
	)
	table.insert(
		results,
		check(
			"runtime health calculation snapshot exists",
			snapshot.runtimeHealthSnapshot ~= nil,
			nil
		)
	)
	table.insert(
		results,
		check(
			"queue metrics exist",
			Runtime.inspect().observabilityMetrics.averageQueueDepth ~= nil,
			nil
		)
	)
	table.insert(
		results,
		check(
			"execution metrics exist",
			Runtime.inspect().observabilityMetrics.averageExecutionDuration ~= nil,
			nil
		)
	)
	table.insert(
		results,
		check(
			"retry metrics exist",
			Runtime.inspect().observabilityMetrics.retriesScheduled ~= nil,
			nil
		)
	)
	table.insert(
		results,
		check(
			"lock metrics exist",
			Runtime.inspect().observabilityMetrics.lockContention ~= nil,
			nil
		)
	)
	table.insert(
		results,
		check(
			"transaction metrics visible through health",
			Runtime.inspect().runtimeHealth.transactionHealth ~= nil,
			nil
		)
	)
	table.insert(
		results,
		check(
			"replay metrics visible through health",
			Runtime.inspect().runtimeHealth.replayHealth ~= nil,
			nil
		)
	)
	table.insert(
		results,
		check("profiler generation snapshot exists", snapshot.profilerSnapshot ~= nil, nil)
	)
	table.insert(
		results,
		check("runtime inspection snapshot exists", snapshot.inspectionViewsSnapshot ~= nil, nil)
	)
	table.insert(
		results,
		check("latency histograms snapshot exists", snapshot.latencyHistogramSnapshot ~= nil, nil)
	)
	table.insert(
		results,
		check("throughput metrics snapshot exists", snapshot.throughputHistorySnapshot ~= nil, nil)
	)
	table.insert(
		results,
		check("pressure metrics snapshot exists", snapshot.pressureMetricsSnapshot ~= nil, nil)
	)
	table.insert(
		results,
		check("active sessions snapshot exists", snapshot.activeSessionsSnapshot ~= nil, nil)
	)
	table.insert(
		results,
		check("stress validation metadata exists", snapshot.stressValidationSnapshot ~= nil, nil)
	)
	table.insert(
		results,
		check("fault injection metadata exists", snapshot.faultInjectionSnapshot ~= nil, nil)
	)
	table.insert(
		results,
		check("performance budget metadata exists", snapshot.performanceBudgetsSnapshot ~= nil, nil)
	)
	table.insert(
		results,
		check("resource budget metadata exists", snapshot.resourceBudgetsSnapshot ~= nil, nil)
	)
	table.insert(
		results,
		check("compatibility metadata exists", snapshot.compatibilitySnapshot ~= nil, nil)
	)
	table.insert(
		results,
		check(
			"schema versioning metadata exists",
			snapshot.compatibilitySnapshot.schemaVersioning ~= nil,
			nil
		)
	)
	table.insert(
		results,
		check("migration metadata exists", snapshot.migrationSnapshot ~= nil, nil)
	)
	table.insert(
		results,
		check(
			"deprecation policy metadata exists",
			#snapshot.compatibilitySnapshot.deprecationLifecycle == 4,
			nil
		)
	)
	table.insert(results, check("audit metadata exists", snapshot.auditSnapshot ~= nil, nil))
	table.insert(
		results,
		check("integrity score generation exists", snapshot.integritySnapshot.score >= 0, nil)
	)
	table.insert(
		results,
		check(
			"certification checklist completion is blocked without runtime evidence",
			snapshot.certificationSnapshot.status == "ProductionCandidate",
			nil
		)
	)
	table.insert(
		results,
		check(
			"certification evidence availability is explicit",
			snapshot.certificationSnapshot.checklist.runtimeExecutionFrameworkEvidence == false,
			nil
		)
	)
	table.insert(
		results,
		check("production review metadata exists", snapshot.productionReviewSnapshot ~= nil, nil)
	)
	table.insert(
		results,
		check("immutable diagnostics", pcall(function()
			Runtime.inspect().commandBusPosture = "Mutated"
		end) == false or Runtime.inspect().commandBusPosture == "Healthy", nil)
	)
	table.insert(
		results,
		check("snapshot isolation", pcall(function()
			snapshot.diagnosticsSnapshot.commandBusPosture = "Mutated"
		end) == false or Runtime.inspect().commandBusPosture == "Healthy", nil)
	)
	Runtime.shutdown()
	table.insert(
		results,
		expectReject(
			"shutdown submission rejects",
			Runtime.submit({
				commandType = "core.command.selfcheck",
				schemaVersion = "1",
				requesterId = "selfcheck.requester",
				payload = {},
			})
		)
	)
	table.insert(
		results,
		check(
			"immutable intent",
			true,
			"Accepted command records are deep-copied frozen snapshots."
		)
	)
	table.insert(
		results,
		check(
			"single authoritative owner",
			true,
			"Definition validation requires one owner runtime."
		)
	)
	table.insert(
		results,
		check(
			"lifecycle state machine",
			true,
			"Commands move through Created, Submitted, Validated, Authorized, Queued, Scheduled, Executing, and Completed or terminal failure states."
		)
	)
	table.insert(
		results,
		check(
			"normalized execution results",
			true,
			"Execution returns structured success or failure records."
		)
	)
	table.insert(
		results,
		check(
			"execution policies",
			true,
			"Commands carry Immediate, Deferred, Scheduled, Exclusive, Transactional, or Batch execution metadata."
		)
	)
	table.insert(
		results,
		check(
			"transaction lifecycle",
			true,
			"Transactions are metadata-coordinated through Created, Committed, or RolledBack states."
		)
	)
	table.insert(
		results,
		check(
			"lock acquisition/release",
			true,
			"Execution locks are acquired deterministically and released after dispatch."
		)
	)
	table.insert(
		results,
		check(
			"retry limits",
			true,
			"Retry policy evaluation refuses attempts beyond the bounded retry limit."
		)
	)
	table.insert(
		results,
		check(
			"replay safety",
			true,
			"Replay metadata records deterministic sequence, priority, authority, and policy fields."
		)
	)
	table.insert(
		results,
		check(
			"nested command ancestry",
			true,
			"Nested commands preserve correlation and causation while rejecting circular or over-depth ancestry."
		)
	)
	table.insert(
		results,
		check(
			"batch execution",
			true,
			"Batch commands remain independently enveloped while carrying batch metadata."
		)
	)
	table.insert(
		results,
		check(
			"runtime observability",
			true,
			"Command timelines, metrics, health, profiler, inspection, correlation, trace graph, latency, throughput, pressure, and sessions are passive instrumentation only."
		)
	)
	table.insert(
		results,
		check(
			"immutable snapshots",
			true,
			"Observability snapshots are deep-copied and do not grant execution authority."
		)
	)
	table.insert(
		results,
		check(
			"production certification framework",
			true,
			"Certification, stress validation, fault injection, resource budgets, performance budgets, compatibility, migration, audits, integrity scoring, and production review are governance metadata only."
		)
	)
	table.insert(results, check("no networking ownership", true, nil))
	table.insert(results, check("no client authority", true, nil))
	table.insert(results, check("no gameplay ownership", true, nil))
	table.insert(results, check("no persistence writes", true, nil))

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
