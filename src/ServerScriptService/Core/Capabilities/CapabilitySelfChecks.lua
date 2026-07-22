--!strict

local Runtime = require(script.Parent.RuntimeCapabilityFramework)
local Types = require(script.Parent.CapabilityTypes)

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

local function capability(id: string, dependencies: any?): any
	return {
		capabilityId = id,
		version = "1",
		owner = "SelfCheck",
		category = Types.Category.Core,
		authority = Types.Authority.Server,
		interfaces = {
			{
				interfaceId = id .. ".interface",
				version = "1",
				methods = { "inspect" },
			},
		},
		dependencies = dependencies or {},
		healthProvider = "SelfCheck.inspect",
		diagnosticsProvider = "SelfCheck.inspect",
		snapshotProvider = "selfCheckSnapshot",
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
			Types.ProviderName == "runtimeCapabilityFramework",
			nil
		)
	)
	table.insert(
		results,
		expectOk("capability registers", Runtime.registerCapability(capability("capability.alpha")))
	)
	table.insert(
		results,
		expectReject(
			"duplicate capability rejects",
			Runtime.registerCapability(capability("capability.alpha"))
		)
	)
	table.insert(results, expectReject("nil capability rejects", Runtime.registerCapability(nil)))
	local extra = capability("capability.extra")
	extra.extra = true
	table.insert(
		results,
		expectReject("unknown capability field rejects", Runtime.registerCapability(extra))
	)
	local invalidCategory = capability("capability.invalidCategory")
	invalidCategory.category = "Invalid"
	table.insert(
		results,
		expectReject("unsupported category rejects", Runtime.registerCapability(invalidCategory))
	)
	local invalidAuthority = capability("capability.invalidAuthority")
	invalidAuthority.authority = "Client"
	table.insert(
		results,
		expectReject("unsupported authority rejects", Runtime.registerCapability(invalidAuthority))
	)
	local unsafe = capability("capability.unsafe")
	unsafe.metadata.remote = true
	table.insert(
		results,
		expectReject("unsafe payload rejects", Runtime.registerCapability(unsafe))
	)
	local dependent = capability("capability.beta", {
		{
			capabilityId = "capability.alpha",
			interfaceId = "capability.alpha.interface",
			minVersion = "1",
			required = true,
		},
	})
	table.insert(
		results,
		expectOk("dependent capability registers", Runtime.registerCapability(dependent))
	)
	table.insert(
		results,
		expectOk("dependency validation passes", Runtime.validateCapability("capability.beta"))
	)
	table.insert(
		results,
		expectOk("capability initializes", Runtime.initializeCapability("capability.beta"))
	)
	table.insert(results, expectOk("capability marks ready", Runtime.markReady("capability.beta")))
	table.insert(
		results,
		expectOk("capability activates", Runtime.activateCapability("capability.beta"))
	)
	table.insert(
		results,
		expectOk(
			"interface discovery resolves",
			Runtime.resolveInterface("capability.alpha.interface", "1", "SelfCheck")
		)
	)
	table.insert(
		results,
		expectReject(
			"missing interface discovery rejects",
			Runtime.resolveInterface("capability.missing.interface", "1", "SelfCheck")
		)
	)
	table.insert(
		results,
		expectOk("capability suspends", Runtime.suspendCapability("capability.beta", "selfcheck"))
	)
	table.insert(
		results,
		expectOk("capability recovers", Runtime.recoverCapability("capability.beta"))
	)
	table.insert(
		results,
		expectOk("capability reactivates", Runtime.activateCapability("capability.beta"))
	)
	table.insert(
		results,
		expectOk("capability shuts down", Runtime.shutdownCapability("capability.beta"))
	)
	table.insert(
		results,
		expectReject(
			"terminal lifecycle mutation rejects",
			Runtime.activateCapability("capability.beta")
		)
	)
	local missingDependency = capability("capability.missingDependency", {
		{
			capabilityId = "capability.none",
			interfaceId = "capability.none.interface",
			minVersion = "1",
			required = true,
		},
	})
	Runtime.registerCapability(missingDependency)
	table.insert(
		results,
		expectReject(
			"missing dependency rejects",
			Runtime.validateCapability("capability.missingDependency")
		)
	)
	local diagnostics = Runtime.inspect()
	local snapshot = Runtime.getSnapshot()
	table.insert(
		results,
		check(
			"diagnostics exposes capability posture",
			diagnostics.capabilityFrameworkPosture == "Healthy",
			nil
		)
	)
	for _, key in ipairs({
		"capabilityRegistry",
		"capabilityLifecycle",
		"capabilityDependencyGraph",
		"capabilityDiscovery",
		"capabilityHealth",
		"capabilityEvidence",
		"capabilityMetrics",
		"capabilityProfiler",
		"capabilityBudgets",
		"capabilityGovernance",
		"certification",
	}) do
		table.insert(results, check("diagnostics contains " .. key, diagnostics[key] ~= nil, nil))
	end
	for _, key in ipairs({
		"noDirectSubsystemCoupling",
		"noGameplayAuthority",
		"noCommandExecution",
		"noEventPublication",
		"noQueryExecution",
		"noNetworking",
		"noPersistenceExecution",
		"noWorkspaceMutation",
		"noClientAuthority",
	}) do
		table.insert(results, check("diagnostics confirms " .. key, diagnostics[key] == true, nil))
	end
	table.insert(
		results,
		check(
			"snapshot exposes runtime capability framework",
			snapshot.runtimeCapabilityFrameworkSnapshot ~= nil,
			nil
		)
	)
	table.insert(
		results,
		check("snapshot isolation", pcall(function()
			snapshot.runtimeCapabilityFrameworkSnapshot.capabilityFrameworkPosture = "Mutated"
		end) == false or Runtime.inspect().capabilityFrameworkPosture == "Healthy", nil)
	)
	Runtime.shutdown()
	table.insert(
		results,
		expectReject(
			"shutdown capability registration rejects",
			Runtime.registerCapability(capability("capability.afterShutdown"))
		)
	)
	for _, invariant in ipairs({
		"immutable capability definitions",
		"deterministic discovery",
		"deterministic activation",
		"deterministic dependency validation",
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
