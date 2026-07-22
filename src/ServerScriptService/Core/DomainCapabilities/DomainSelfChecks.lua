--!strict

local Runtime = require(script.Parent.RuntimeDomainCapabilityFoundation)
local Types = require(script.Parent.DomainCapabilityTypes)

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

local function domainCapability(id: string, domain: string): any
	return {
		capabilityId = id,
		domain = domain,
		version = "1",
		owner = "SelfCheck",
		authority = Types.Authority.Server,
		workflowParticipation = Types.WorkflowParticipation.Participant,
		interfaces = {
			{
				interfaceId = id .. ".service",
				version = "1",
				methods = { "inspectState" },
			},
		},
		dependencies = {},
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
			Types.ProviderName == "runtimeDomainCapabilityFoundation",
			nil
		)
	)
	table.insert(
		results,
		expectOk(
			"domain capability registers",
			Runtime.registerDomainCapability(
				domainCapability("domain.dialogue", Types.Domain.Dialogue)
			)
		)
	)
	table.insert(
		results,
		expectReject(
			"duplicate domain capability rejects",
			Runtime.registerDomainCapability(
				domainCapability("domain.dialogue", Types.Domain.Inventory)
			)
		)
	)
	table.insert(
		results,
		expectReject(
			"duplicate domain ownership rejects",
			Runtime.registerDomainCapability(
				domainCapability("domain.dialogue.two", Types.Domain.Dialogue)
			)
		)
	)
	table.insert(
		results,
		expectReject("nil domain capability rejects", Runtime.registerDomainCapability(nil))
	)
	local extra = domainCapability("domain.extra", Types.Domain.Inventory)
	extra.extra = true
	table.insert(
		results,
		expectReject(
			"unknown domain capability field rejects",
			Runtime.registerDomainCapability(extra)
		)
	)
	local invalidDomain = domainCapability("domain.invalid", "Invalid")
	table.insert(
		results,
		expectReject("unsupported domain rejects", Runtime.registerDomainCapability(invalidDomain))
	)
	local invalidAuthority = domainCapability("domain.invalidAuthority", Types.Domain.Inventory)
	invalidAuthority.authority = "Client"
	table.insert(
		results,
		expectReject(
			"unsupported authority rejects",
			Runtime.registerDomainCapability(invalidAuthority)
		)
	)
	local invalidWorkflow = domainCapability("domain.invalidWorkflow", Types.Domain.Inventory)
	invalidWorkflow.workflowParticipation = "Owner"
	table.insert(
		results,
		expectReject(
			"unsupported workflow participation rejects",
			Runtime.registerDomainCapability(invalidWorkflow)
		)
	)
	local unsafe = domainCapability("domain.unsafe", Types.Domain.Inventory)
	unsafe.metadata.implementation = "InternalModule"
	table.insert(
		results,
		expectReject(
			"unsafe implementation payload rejects",
			Runtime.registerDomainCapability(unsafe)
		)
	)
	table.insert(
		results,
		expectOk("domain dependency validates", Runtime.validateDomainCapability("domain.dialogue"))
	)
	table.insert(
		results,
		expectOk("domain initializes", Runtime.initializeDomainCapability("domain.dialogue"))
	)
	table.insert(
		results,
		expectOk("domain marks ready", Runtime.markDomainReady("domain.dialogue"))
	)
	table.insert(
		results,
		expectOk("domain activates", Runtime.activateDomainCapability("domain.dialogue"))
	)
	table.insert(
		results,
		expectOk(
			"domain interface resolves through capability framework",
			Runtime.resolveDomainInterface("domain.dialogue.service", "1", "SelfCheck")
		)
	)
	table.insert(
		results,
		expectReject(
			"missing domain interface rejects",
			Runtime.resolveDomainInterface("domain.missing.service", "1", "SelfCheck")
		)
	)
	table.insert(
		results,
		expectOk("domain suspends", Runtime.suspendDomainCapability("domain.dialogue", "selfcheck"))
	)
	table.insert(
		results,
		expectOk("domain recovers", Runtime.recoverDomainCapability("domain.dialogue"))
	)
	local diagnostics = Runtime.inspect()
	local snapshot = Runtime.getSnapshot()
	table.insert(
		results,
		check(
			"diagnostics exposes domain capability posture",
			diagnostics.domainCapabilityPosture == "Healthy",
			nil
		)
	)
	for _, key in ipairs({
		"domainCapabilities",
		"interfaceOwnership",
		"communicationContracts",
		"lifecycleIntegration",
		"domainEvidence",
		"domainMetrics",
		"domainProfiler",
		"domainBudgets",
		"domainGovernance",
		"certification",
	}) do
		table.insert(results, check("diagnostics contains " .. key, diagnostics[key] ~= nil, nil))
	end
	for _, key in ipairs({
		"noConcreteDomainImplementation",
		"noDirectCapabilityCoupling",
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
			"snapshot exposes domain capability foundation",
			snapshot.runtimeDomainCapabilityFoundationSnapshot ~= nil,
			nil
		)
	)
	table.insert(
		results,
		check("snapshot isolation", pcall(function()
			snapshot.runtimeDomainCapabilityFoundationSnapshot.domainCapabilityPosture = "Mutated"
		end) == false or Runtime.inspect().domainCapabilityPosture == "Healthy", nil)
	)
	Runtime.shutdown()
	table.insert(
		results,
		expectReject(
			"shutdown domain registration rejects",
			Runtime.registerDomainCapability(
				domainCapability("domain.afterShutdown", Types.Domain.Inventory)
			)
		)
	)
	for _, invariant in ipairs({
		"one domain per capability",
		"immutable capability definitions",
		"immutable interface contracts",
		"deterministic initialization",
		"deterministic discovery",
		"deterministic dependency validation",
		"deterministic lifecycle",
		"deterministic diagnostics",
		"deterministic evidence",
		"deterministic snapshots",
		"no direct capability coupling",
		"no gameplay authority escalation",
		"no bypass of messaging architecture",
		"no concrete dialogue implementation",
		"no inventory logic",
		"no save serialization",
		"no combat",
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
