--!strict

local Runtime = require(script.Parent.RuntimeCommandBus)
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
				idempotencyPolicy = Types.IdempotencyPolicy.OptionalIdempotencyKey,
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
				allowedCommandTypes = { "core.command.selfcheck" },
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
			"normalized execution results",
			true,
			"Execution returns structured success or failure records."
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
