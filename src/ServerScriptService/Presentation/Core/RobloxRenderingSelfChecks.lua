--!strict

local Runtime = require(script.Parent.RuntimeRobloxRenderingCapability)
local Types = require(script.Parent.PresentationTypes)

local SelfChecks = {}

local function suite()
	local checks = {}
	local function expect(name: string, condition: boolean, detail: string?)
		checks[#checks + 1] = { name = name, ok = condition == true, detail = detail }
	end
	local function summarize()
		local failures = {}
		for _, check in ipairs(checks) do
			if not check.ok then
				failures[#failures + 1] = check
			end
		end
		return {
			phase = 181,
			ok = #failures == 0,
			total = #checks,
			passed = #checks - #failures,
			failed = #failures,
			failures = failures,
		}
	end
	return expect, summarize
end

function SelfChecks.run()
	Runtime.reset()
	local expect, summarize = suite()

	local dialogueCapability = Runtime.registerCapability({
		capabilityId = "roblox.rendering.capability.dialogue",
		feature = Types.RobloxRenderingFeature.DialogueWindows,
		capabilityVersion = "1.0.0",
	})
	expect("dialogue capability registered", dialogueCapability.ok)
	local duplicateCapability = Runtime.registerCapability({
		capabilityId = "roblox.rendering.capability.dialogue",
		feature = Types.RobloxRenderingFeature.DialogueWindows,
		capabilityVersion = "1.0.0",
	})
	expect("duplicate capability rejected", not duplicateCapability.ok)
	local invalidCapability = Runtime.registerCapability({
		capabilityId = "roblox.rendering.capability.invalid",
		feature = "UnsupportedFeature",
		capabilityVersion = "1.0.0",
	})
	expect("invalid capability rejected", not invalidCapability.ok)

	local renderer = Runtime.registerRenderer({
		rendererId = "roblox.renderer.phase181.dialogue",
		platform = Types.RobloxRenderingPlatform,
		provider = Types.RobloxRenderingProviderName,
		version = "1.0.0",
		capabilityVersion = "1.0.0",
		supportedContractVersions = { "1.0.0" },
		supportedRenderingKinds = { Types.RenderingKind.DialogueLine },
		supportedDescriptorVersions = { "1.0.0" },
		supportedSynchronizationPolicies = { Types.RenderingSynchronizationPolicy.WaitForCompleted },
		rendererPriority = 10,
		status = Types.RobloxRendererStatus.Available,
	})
	expect("renderer registered", renderer.ok)
	local duplicateRenderer = Runtime.registerRenderer({
		rendererId = "roblox.renderer.phase181.dialogue",
		platform = Types.RobloxRenderingPlatform,
		provider = Types.RobloxRenderingProviderName,
		version = "1.0.0",
		capabilityVersion = "1.0.0",
		supportedContractVersions = { "1.0.0" },
		supportedRenderingKinds = { Types.RenderingKind.DialogueLine },
		supportedDescriptorVersions = { "1.0.0" },
		supportedSynchronizationPolicies = { Types.RenderingSynchronizationPolicy.WaitForCompleted },
	})
	expect("duplicate renderer rejected", not duplicateRenderer.ok)
	local invalidPlatform = Runtime.registerRenderer({
		rendererId = "roblox.renderer.phase181.badplatform",
		platform = "Other",
		provider = Types.RobloxRenderingProviderName,
		version = "1.0.0",
		capabilityVersion = "1.0.0",
		supportedContractVersions = { "1.0.0" },
		supportedRenderingKinds = { Types.RenderingKind.DialogueLine },
		supportedDescriptorVersions = { "1.0.0" },
		supportedSynchronizationPolicies = { Types.RenderingSynchronizationPolicy.WaitForCompleted },
	})
	expect("invalid platform rejected", not invalidPlatform.ok)
	local invalidKind = Runtime.registerRenderer({
		rendererId = "roblox.renderer.phase181.badkind",
		platform = Types.RobloxRenderingPlatform,
		provider = Types.RobloxRenderingProviderName,
		version = "1.0.0",
		capabilityVersion = "1.0.0",
		supportedContractVersions = { "1.0.0" },
		supportedRenderingKinds = { "BadKind" },
		supportedDescriptorVersions = { "1.0.0" },
		supportedSynchronizationPolicies = { Types.RenderingSynchronizationPolicy.WaitForCompleted },
	})
	expect("invalid rendering kind rejected", not invalidKind.ok)

	local negotiation = Runtime.negotiateCompatibility({
		rendererId = "roblox.renderer.phase181.dialogue",
		contractVersion = "1.0.0",
		descriptorVersion = "1.0.0",
		renderingKind = Types.RenderingKind.DialogueLine,
		synchronizationPolicy = Types.RenderingSynchronizationPolicy.WaitForCompleted,
	})
	expect(
		"compatibility negotiation succeeds",
		negotiation.ok and negotiation.negotiation.compatible == true
	)
	local badContract = Runtime.negotiateCompatibility({
		rendererId = "roblox.renderer.phase181.dialogue",
		contractVersion = "9.0.0",
		descriptorVersion = "1.0.0",
		renderingKind = Types.RenderingKind.DialogueLine,
		synchronizationPolicy = Types.RenderingSynchronizationPolicy.WaitForCompleted,
	})
	expect("unsupported contract rejected", not badContract.ok)
	local badDescriptor = Runtime.negotiateCompatibility({
		rendererId = "roblox.renderer.phase181.dialogue",
		contractVersion = "1.0.0",
		descriptorVersion = "9.0.0",
		renderingKind = Types.RenderingKind.DialogueLine,
		synchronizationPolicy = Types.RenderingSynchronizationPolicy.WaitForCompleted,
	})
	expect("unsupported descriptor rejected", not badDescriptor.ok)
	local unknownRenderer = Runtime.negotiateCompatibility({
		rendererId = "roblox.renderer.phase181.unknown",
		contractVersion = "1.0.0",
		descriptorVersion = "1.0.0",
		renderingKind = Types.RenderingKind.DialogueLine,
		synchronizationPolicy = Types.RenderingSynchronizationPolicy.WaitForCompleted,
	})
	expect("unknown renderer rejected", not unknownRenderer.ok)

	local diagnostics = Runtime.inspect()
	expect("provider identity", diagnostics.providerName == Types.RobloxRenderingProviderName)
	expect("capability identity", diagnostics.capabilityId == Types.RobloxRenderingCapabilityId)
	expect("platform identity", diagnostics.platform == Types.RobloxRenderingPlatform)
	expect(
		"diagnostics immutable posture",
		diagnostics.robloxRenderingPosture.immutableDiagnostics == true
	)
	expect("no rendering posture", diagnostics.robloxRenderingPosture.noRendering == true)
	expect("no GUI posture", diagnostics.robloxRenderingPosture.noGui == true)
	expect(
		"no client authority posture",
		diagnostics.robloxRenderingPosture.noClientAuthority == true
	)
	diagnostics.rendererRegistry[1].rendererId = "mutated"
	expect(
		"diagnostics isolated",
		Runtime.inspect().rendererRegistry[1].rendererId == "roblox.renderer.phase181.dialogue"
	)
	local snapshot = Runtime.getSnapshot()
	expect("snapshot provider identity", snapshot.providerName == Types.RobloxRenderingProviderName)
	snapshot.robloxRenderingSnapshot.rendererRegistry[1].rendererId = "mutated"
	expect(
		"snapshot isolated",
		Runtime.getSnapshot().robloxRenderingSnapshot.rendererRegistry[1].rendererId
			== "roblox.renderer.phase181.dialogue"
	)
	expect("evidence recorded", #Runtime.inspect().evidence > 0)
	expect("metrics recorded", Runtime.inspect().metrics.registeredRenderers >= 1)
	expect("profiler recorded", #Runtime.inspect().profiler > 0)
	expect(
		"limits exposed",
		Runtime.inspect().limits.MaxRenderers == Types.RobloxRenderingLimits.MaxRenderers
	)
	expect(
		"governance exposed",
		Runtime.inspect().governance.systemName == "Roblox Rendering Capability Foundation"
	)
	expect(
		"certification candidate",
		Runtime.inspect().certification.status == "ProductionCandidate"
	)
	local valid, reason = Runtime.validate()
	expect("validation passed", valid, reason)

	Runtime.reset()
	expect("reset clears renderers", #Runtime.inspect().rendererRegistry == 0)
	Runtime.shutdown()
	local blocked = Runtime.registerCapability({
		capabilityId = "roblox.rendering.capability.shutdown",
		feature = Types.RobloxRenderingFeature.DialogueWindows,
		capabilityVersion = "1.0.0",
	})
	expect(
		"shutdown blocks capability registration",
		not blocked.ok and blocked.code == Types.RobloxRenderingFailureType.RuntimeShutdown
	)
	expect(
		"posture no asset loading",
		Runtime.inspect().robloxRenderingPosture.noAssetLoading == true
	)
	expect("posture no networking", Runtime.inspect().robloxRenderingPosture.noNetworking == true)
	expect(
		"posture no Workspace mutation",
		Runtime.inspect().robloxRenderingPosture.noWorkspaceMutation == true
	)
	expect("posture no persistence", Runtime.inspect().robloxRenderingPosture.noPersistence == true)
	expect(
		"posture no gameplay execution",
		Runtime.inspect().robloxRenderingPosture.noGameplayExecution == true
	)
	expect(
		"posture no dialogue execution",
		Runtime.inspect().robloxRenderingPosture.noDialogueExecution == true
	)
	expect("posture no analytics", Runtime.inspect().robloxRenderingPosture.noAnalytics == true)
	expect("posture no telemetry", Runtime.inspect().robloxRenderingPosture.noTelemetry == true)

	return summarize()
end

return SelfChecks
