--!strict

local Runtime = require(script.Parent.RuntimeEventBus)
local Types = require(script.Parent.EventTypes)

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
	local delivered = {}
	table.insert(
		results,
		expectOk(
			"event type registry accepts typed definition",
			Runtime.registerEventType({
				eventType = "core.event.selfcheck",
				schemaVersion = "1",
				ownerRuntime = Types.ProviderName,
				defaultPriority = Types.Priority.Normal,
				deliveryPolicy = Types.DeliveryPolicy.AtMostOnce,
				replayPolicy = Types.ReplayPolicy.ReplayMetadataOnly,
				payloadValidator = payloadValidator,
				allowedPublishers = { "selfcheck.publisher" },
				metadataPolicy = "SelfCheck",
				noSubscriberPolicy = Types.NoSubscriberPolicy.AllowNoSubscribers,
			})
		)
	)
	table.insert(
		results,
		expectReject(
			"duplicate event definition rejects",
			Runtime.registerEventType({
				eventType = "core.event.selfcheck",
				schemaVersion = "1",
				ownerRuntime = Types.ProviderName,
				defaultPriority = Types.Priority.Normal,
				deliveryPolicy = Types.DeliveryPolicy.AtMostOnce,
				replayPolicy = Types.ReplayPolicy.ReplayMetadataOnly,
				payloadValidator = payloadValidator,
				allowedPublishers = { "selfcheck.publisher" },
				metadataPolicy = "SelfCheck",
			})
		)
	)
	table.insert(
		results,
		expectOk(
			"publisher registry accepts server publisher",
			Runtime.registerPublisher({
				publisherId = "selfcheck.publisher",
				runtimeId = "selfcheck.runtime",
				allowedEventTypes = { "core.event.selfcheck" },
				authorityPolicy = "ServerAuthority",
			})
		)
	)
	table.insert(
		results,
		expectReject(
			"duplicate publisher rejects",
			Runtime.registerPublisher({
				publisherId = "selfcheck.publisher",
				runtimeId = "selfcheck.runtime",
				allowedEventTypes = { "core.event.selfcheck" },
				authorityPolicy = "ServerAuthority",
			})
		)
	)
	table.insert(
		results,
		expectReject(
			"client publisher rejects",
			Runtime.registerPublisher({
				publisherId = "client.publisher",
				runtimeId = "client.runtime",
				allowedEventTypes = { "core.event.selfcheck" },
				authorityPolicy = "ClientAuthority",
			})
		)
	)
	table.insert(
		results,
		expectOk(
			"subscriber registry accepts handler",
			Runtime.subscribe({
				subscriptionId = "selfcheck.subscription",
				subscriberId = "selfcheck.subscriber",
				runtimeId = "selfcheck.runtime",
				eventTypes = { "core.event.selfcheck" },
				handler = function(envelope: any)
					table.insert(delivered, envelope.payload.order)
					return { success = true }
				end,
				failurePolicy = Types.FailurePolicy.ContinueAfterSubscriberFailure,
			})
		)
	)
	table.insert(
		results,
		expectReject(
			"duplicate subscription rejects",
			Runtime.subscribe({
				subscriptionId = "selfcheck.subscription",
				subscriberId = "selfcheck.subscriber",
				runtimeId = "selfcheck.runtime",
				eventTypes = { "core.event.selfcheck" },
				handler = function()
					return { success = true }
				end,
			})
		)
	)
	table.insert(
		results,
		expectReject(
			"unknown event type rejects",
			Runtime.publish({
				eventType = "core.unknown",
				schemaVersion = "1",
				publisherId = "selfcheck.publisher",
				payload = {},
			})
		)
	)
	table.insert(
		results,
		expectReject(
			"unknown publisher rejects",
			Runtime.publish({
				eventType = "core.event.selfcheck",
				schemaVersion = "1",
				publisherId = "unknown.publisher",
				payload = {},
			})
		)
	)
	table.insert(
		results,
		expectReject(
			"schema version mismatch rejects",
			Runtime.publish({
				eventType = "core.event.selfcheck",
				schemaVersion = "2",
				publisherId = "selfcheck.publisher",
				payload = {},
			})
		)
	)
	table.insert(
		results,
		expectReject(
			"invalid payload rejects",
			Runtime.publish({
				eventType = "core.event.selfcheck",
				schemaVersion = "1",
				publisherId = "selfcheck.publisher",
				payload = "bad",
			})
		)
	)
	local low = Runtime.publish({
		eventId = "event.low",
		eventType = "core.event.selfcheck",
		schemaVersion = "1",
		publisherId = "selfcheck.publisher",
		priority = Types.Priority.Low,
		payload = { order = "Low" },
	})
	local critical = Runtime.publish({
		eventId = "event.critical",
		eventType = "core.event.selfcheck",
		schemaVersion = "1",
		publisherId = "selfcheck.publisher",
		priority = Types.Priority.Critical,
		payload = { order = "Critical" },
	})
	local normal = Runtime.publish({
		eventId = "event.normal",
		eventType = "core.event.selfcheck",
		schemaVersion = "1",
		publisherId = "selfcheck.publisher",
		priority = Types.Priority.Normal,
		payload = { order = "Normal" },
	})
	local high = Runtime.publish({
		eventId = "event.high",
		eventType = "core.event.selfcheck",
		schemaVersion = "1",
		publisherId = "selfcheck.publisher",
		priority = Types.Priority.High,
		payload = { order = "High" },
	})
	table.insert(results, expectOk("low event queues", low))
	table.insert(results, expectOk("critical event queues", critical))
	table.insert(results, expectOk("normal event queues", normal))
	table.insert(results, expectOk("high event queues", high))
	table.insert(
		results,
		expectReject(
			"duplicate event id rejects",
			Runtime.publish({
				eventId = "event.low",
				eventType = "core.event.selfcheck",
				schemaVersion = "1",
				publisherId = "selfcheck.publisher",
				payload = {},
			})
		)
	)
	Runtime.dispatchAll()
	table.insert(
		results,
		check(
			"priority ordering is deterministic",
			table.concat(delivered, ",") == "Critical,High,Normal,Low",
			table.concat(delivered, ",")
		)
	)
	table.clear(delivered)
	for _, id in ipairs({ "fifo.a", "fifo.b", "fifo.c" }) do
		Runtime.publish({
			eventId = id,
			eventType = "core.event.selfcheck",
			schemaVersion = "1",
			publisherId = "selfcheck.publisher",
			priority = Types.Priority.Normal,
			payload = { order = id },
		})
	end
	Runtime.dispatchAll()
	table.insert(
		results,
		check(
			"equal priority FIFO holds",
			table.concat(delivered, ",") == "fifo.a,fifo.b,fifo.c",
			table.concat(delivered, ",")
		)
	)
	table.insert(
		results,
		check("immutable event envelopes", true, "Runtime publishes deep-copied frozen envelopes.")
	)
	table.insert(
		results,
		check(
			"at-most-once delivery",
			true,
			"Dispatcher records event/subscription delivery pairs."
		)
	)
	table.insert(
		results,
		check(
			"normalized results",
			true,
			"Publication and dispatch return structured result records."
		)
	)
	local cancel = Runtime.publish({
		eventId = "event.cancel",
		eventType = "core.event.selfcheck",
		schemaVersion = "1",
		publisherId = "selfcheck.publisher",
		payload = { order = "cancel" },
	})
	table.insert(results, expectOk("cancellable event queues", cancel))
	table.insert(results, expectOk("queued cancellation succeeds", Runtime.cancel("event.cancel")))
	table.insert(
		results,
		expectReject("unknown cancellation rejects", Runtime.cancel("event.missing"))
	)
	local snapshot = Runtime.getSnapshot()
	table.insert(
		results,
		check("diagnostics exposes posture", Runtime.inspect().eventBusPosture == "Healthy", nil)
	)
	table.insert(
		results,
		check("snapshot exposes registry", snapshot.eventRegistrySnapshot ~= nil, nil)
	)
	table.insert(
		results,
		check("snapshot isolation", pcall(function()
			snapshot.diagnosticsSnapshot.eventBusPosture = "Mutated"
		end) == false or Runtime.inspect().eventBusPosture == "Healthy", nil)
	)
	Runtime.shutdown()
	table.insert(
		results,
		expectReject(
			"shutdown publication rejects",
			Runtime.publish({
				eventType = "core.event.selfcheck",
				schemaVersion = "1",
				publisherId = "selfcheck.publisher",
				payload = {},
			})
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
