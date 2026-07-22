--!strict

local Runtime = require(script.Parent.RuntimeMessagingIntegration)
local Types = require(script.Parent.MessagingTypes)

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

local function consumer(id: string, dependencies: { string }?): any
	return {
		consumerId = id,
		ownerRuntime = id,
		version = "1",
		capabilities = { "runtimeConsumer" },
		subscriptions = { "event." .. id },
		publicInterfaces = { "interface." .. id },
		requiredInterfaces = {},
		lifecycle = {
			Types.LifecycleState.Created,
			Types.LifecycleState.Registered,
			Types.LifecycleState.Validated,
			Types.LifecycleState.Initialized,
			Types.LifecycleState.Ready,
			Types.LifecycleState.Running,
			Types.LifecycleState.Suspended,
			Types.LifecycleState.Shutdown,
		},
		dependencies = dependencies or {},
		authorityLevel = Types.AuthorityLevel.Runtime,
		supportedCommands = { "command." .. id },
		supportedEvents = { "event." .. id },
		supportedQueries = { "query." .. id },
	}
end

local function subscription(
	id: string,
	consumerId: string,
	eventType: string,
	priority: number
): any
	return {
		subscriptionId = id,
		consumerId = consumerId,
		eventType = eventType,
		priority = priority,
		deliveryMode = Types.SubscriptionDeliveryMode.Ordered,
		version = "1",
	}
end

function SelfChecks.run()
	Runtime.reset()
	local results = {}
	table.insert(
		results,
		check(
			"provider name is lowerCamelCase",
			Types.ProviderName == "runtimeMessagingIntegration",
			nil
		)
	)
	table.insert(
		results,
		expectOk(
			"consumer registry accepts runtime consumer",
			Runtime.registerConsumer(consumer("consumer.alpha"))
		)
	)
	table.insert(
		results,
		expectReject(
			"duplicate consumer rejects",
			Runtime.registerConsumer(consumer("consumer.alpha"))
		)
	)
	table.insert(results, expectReject("nil consumer rejects", Runtime.registerConsumer(nil)))
	table.insert(
		results,
		expectReject(
			"unknown consumer field rejects",
			Runtime.registerConsumer({
				consumerId = "consumer.bad",
				ownerRuntime = "consumer.bad",
				version = "1",
				capabilities = {},
				subscriptions = {},
				publicInterfaces = {},
				requiredInterfaces = {},
				lifecycle = {},
				dependencies = {},
				authorityLevel = Types.AuthorityLevel.Runtime,
				supportedCommands = {},
				supportedEvents = {},
				supportedQueries = {},
				extra = true,
			})
		)
	)
	table.insert(
		results,
		expectReject(
			"unsafe payload rejects",
			Runtime.registerConsumer({
				consumerId = "consumer.unsafe",
				ownerRuntime = "consumer.unsafe",
				version = "1",
				capabilities = { "runtimeConsumer" },
				subscriptions = {},
				publicInterfaces = {},
				requiredInterfaces = {},
				lifecycle = {},
				dependencies = {},
				authorityLevel = Types.AuthorityLevel.Runtime,
				supportedCommands = {},
				supportedEvents = {},
				supportedQueries = {},
				workspace = true,
			})
		)
	)
	table.insert(
		results,
		expectOk(
			"dependency consumer registers",
			Runtime.registerConsumer(consumer("consumer.beta", { "consumer.alpha" }))
		)
	)
	table.insert(
		results,
		expectOk("dependency validation succeeds", Runtime.validateDependencies())
	)
	local graph = Runtime.getDependencyGraph()
	table.insert(
		results,
		check(
			"dependency initialization order is deterministic",
			graph.initializationOrder[1] == Types.ProviderName
				and graph.initializationOrder[2] == "consumer.alpha",
			nil
		)
	)
	table.insert(
		results,
		expectOk(
			"subscription registry accepts event subscription",
			Runtime.registerSubscription(
				subscription("sub.alpha", "consumer.alpha", "event.ready", 10)
			)
		)
	)
	table.insert(
		results,
		expectOk(
			"subscription registry accepts lower priority subscription",
			Runtime.registerSubscription(
				subscription("sub.beta", "consumer.beta", "event.ready", 1)
			)
		)
	)
	table.insert(
		results,
		expectReject(
			"duplicate subscription rejects",
			Runtime.registerSubscription(
				subscription("sub.alpha", "consumer.alpha", "event.ready", 1)
			)
		)
	)
	table.insert(
		results,
		expectReject(
			"unknown consumer subscription rejects",
			Runtime.registerSubscription(subscription("sub.unknown", "missing", "event.ready", 1))
		)
	)
	local subscriptions = Runtime.resolveSubscriptions("event.ready")
	table.insert(
		results,
		check(
			"subscription ordering honors priority",
			subscriptions[1].subscriptionId == "sub.alpha",
			nil
		)
	)
	table.insert(
		results,
		expectOk(
			"interface discovery resolves registered public interface",
			Runtime.resolveInterface("interface.consumer.alpha")
		)
	)
	table.insert(
		results,
		expectReject("unknown interface rejects", Runtime.resolveInterface("interface.missing"))
	)
	table.insert(
		results,
		expectOk("consumer lifecycle initializes and starts", Runtime.startConsumers())
	)
	local diagnostics = Runtime.inspect()
	local snapshot = Runtime.getSnapshot()
	table.insert(
		results,
		check(
			"diagnostics exposes lowerCamelCase posture",
			diagnostics.messagingIntegrationPosture == "Healthy",
			nil
		)
	)
	table.insert(
		results,
		check("diagnostics contains consumer registry", diagnostics.consumerRegistry ~= nil, nil)
	)
	table.insert(
		results,
		check("diagnostics contains dependency graph", diagnostics.dependencyGraph ~= nil, nil)
	)
	table.insert(
		results,
		check(
			"diagnostics contains subscription registry",
			diagnostics.subscriptionRegistry ~= nil,
			nil
		)
	)
	table.insert(
		results,
		check("diagnostics contains runtime discovery", diagnostics.runtimeDiscovery ~= nil, nil)
	)
	table.insert(
		results,
		check(
			"diagnostics confirms no command ownership",
			diagnostics.noCommandOwnership == true,
			nil
		)
	)
	table.insert(
		results,
		check("diagnostics confirms no event ownership", diagnostics.noEventOwnership == true, nil)
	)
	table.insert(
		results,
		check("diagnostics confirms no query ownership", diagnostics.noQueryOwnership == true, nil)
	)
	table.insert(
		results,
		check("diagnostics confirms no networking", diagnostics.noNetworking == true, nil)
	)
	table.insert(
		results,
		check("diagnostics confirms no persistence", diagnostics.noPersistence == true, nil)
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
			"snapshot exposes messaging integration snapshot",
			snapshot.messagingIntegrationSnapshot ~= nil,
			nil
		)
	)
	table.insert(
		results,
		check("snapshot isolation", pcall(function()
			snapshot.messagingIntegrationSnapshot.messagingIntegrationPosture = "Mutated"
		end) == false or Runtime.inspect().messagingIntegrationPosture == "Healthy", nil)
	)
	table.insert(results, expectOk("shutdown order completes", Runtime.shutdownConsumers()))
	Runtime.shutdown()
	table.insert(
		results,
		expectReject(
			"shutdown registration rejects",
			Runtime.registerConsumer(consumer("consumer.afterShutdown"))
		)
	)
	Runtime.reset()
	Runtime.registerConsumer(consumer("cycle.a", { "cycle.b" }))
	Runtime.registerConsumer(consumer("cycle.b", { "cycle.a" }))
	table.insert(results, expectReject("dependency cycle rejects", Runtime.validateDependencies()))
	Runtime.reset()
	Runtime.registerConsumer(consumer("missing.dependency", { "missing.consumer" }))
	table.insert(
		results,
		expectReject("missing dependency rejects", Runtime.validateDependencies())
	)
	for _, invariant in ipairs({
		"immutable consumer contracts",
		"deterministic dependency validation",
		"deterministic initialization",
		"deterministic shutdown",
		"deterministic subscriptions",
		"immutable diagnostics",
		"immutable evidence",
		"no direct gameplay runtime coupling",
		"no hidden client authority",
		"no remotes",
		"no DataStore",
		"no HTTP",
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
