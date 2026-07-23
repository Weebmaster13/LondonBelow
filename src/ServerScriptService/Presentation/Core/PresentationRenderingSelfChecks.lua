--!strict

local Runtime = require(script.Parent.RuntimePresentationRenderingContract)
local Types = require(script.Parent.PresentationTypes)

local SelfChecks = {}

local function makeSuite()
	local checks = {}
	local function expect(name: string, condition: boolean, detail: string?)
		checks[#checks + 1] = {
			name = name,
			ok = condition == true,
			detail = detail,
		}
	end
	local function summarize()
		local failures = {}
		for _, check in ipairs(checks) do
			if not check.ok then
				failures[#failures + 1] = check
			end
		end
		return {
			phase = 178,
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
	local expect, summarize = makeSuite()

	local duplicateContract = Runtime.registerDefaultContract()
	expect(
		"duplicate contract rejected",
		not duplicateContract.ok
			and duplicateContract.code == Types.RenderingContractFailureType.DuplicateContract
	)

	local capability = Runtime.registerRendererCapability({
		rendererCapabilityId = "renderer.phase178.primary",
		rendererType = "MetadataRenderer",
		providerName = "phase178RendererProvider",
		version = "1.0.0",
		supportedRenderingKinds = {
			Types.RenderingKind.DialogueLine,
			Types.RenderingKind.Notification,
		},
		supportedContractVersions = { "1.0.0" },
		supportedDescriptorVersions = { "1.0.0" },
		supportedSynchronizationPolicies = {
			Types.RenderingSynchronizationPolicy.NoWait,
			Types.RenderingSynchronizationPolicy.WaitForAccepted,
			Types.RenderingSynchronizationPolicy.WaitForAssigned,
			Types.RenderingSynchronizationPolicy.WaitForReady,
			Types.RenderingSynchronizationPolicy.WaitForStarted,
			Types.RenderingSynchronizationPolicy.WaitForCompleted,
			Types.RenderingSynchronizationPolicy.WaitForCancelled,
			Types.RenderingSynchronizationPolicy.WaitForTerminalState,
		},
		status = Types.RendererCapabilityStatus.Available,
		priority = 10,
	})
	expect("renderer capability registered", capability.ok)
	local duplicateCapability = Runtime.registerRendererCapability({
		rendererCapabilityId = "renderer.phase178.primary",
		rendererType = "MetadataRenderer",
		providerName = "phase178RendererProvider",
		version = "1.0.0",
		supportedRenderingKinds = { Types.RenderingKind.DialogueLine },
		supportedSynchronizationPolicies = { Types.RenderingSynchronizationPolicy.NoWait },
		status = Types.RendererCapabilityStatus.Available,
	})
	expect("duplicate renderer capability rejected", not duplicateCapability.ok)
	local invalidCapability = Runtime.registerRendererCapability({
		rendererCapabilityId = "renderer.phase178.invalid",
		rendererType = "MetadataRenderer",
		providerName = "phase178RendererProvider",
		version = "1.0.0",
		supportedRenderingKinds = { "BadKind" },
		supportedSynchronizationPolicies = { Types.RenderingSynchronizationPolicy.NoWait },
		status = Types.RendererCapabilityStatus.Available,
	})
	expect("invalid renderer capability rejected", not invalidCapability.ok)

	local request = Runtime.createRenderingRequest({
		renderingRequestId = "rendering.request.phase178.primary",
		executionSessionId = "execution.phase177.primary",
		presentationSessionId = "presentation.session.phase176.primary",
		presentationId = "presentation.phase176.primary",
		consumerId = "consumer.phase176.primary",
		renderingKind = Types.RenderingKind.DialogueLine,
		descriptor = {
			descriptorVersion = "1.0.0",
			textTokenReference = "loc.dialogue.phase178.primary",
			layoutReference = "layout.dialogue.line",
		},
		synchronizationPolicy = Types.RenderingSynchronizationPolicy.WaitForCompleted,
		localizationReferences = { "loc.dialogue.phase178.primary" },
		accessibilityReferences = { "accessibility.dialogue.phase178.primary" },
		assetReferences = { "asset.portrait.phase178.primary" },
		contractVersion = "1.0.0",
	})
	expect("rendering request registered", request.ok)
	local duplicateRequest = Runtime.createRenderingRequest({
		renderingRequestId = "rendering.request.phase178.primary",
		executionSessionId = "execution.phase177.primary",
		presentationSessionId = "presentation.session.phase176.primary",
		presentationId = "presentation.phase176.primary",
		consumerId = "consumer.phase176.primary",
		renderingKind = Types.RenderingKind.DialogueLine,
		descriptor = {},
	})
	expect("duplicate request rejected", not duplicateRequest.ok)
	local invalidRequest = Runtime.createRenderingRequest({
		renderingRequestId = "rendering.request.phase178.invalid",
		executionSessionId = "execution.phase177.invalid",
		presentationSessionId = "presentation.session.phase176.invalid",
		presentationId = "presentation.phase176.invalid",
		consumerId = "consumer.phase176.invalid",
		renderingKind = "BadKind",
		descriptor = {},
	})
	expect("invalid request rejected", not invalidRequest.ok)
	local invalidDescriptor = Runtime.createRenderingRequest({
		renderingRequestId = "rendering.request.phase178.unsafe",
		executionSessionId = "execution.phase177.unsafe",
		presentationSessionId = "presentation.session.phase176.unsafe",
		presentationId = "presentation.phase176.unsafe",
		consumerId = "consumer.phase176.unsafe",
		renderingKind = Types.RenderingKind.DialogueLine,
		descriptor = { callback = function() end },
	})
	expect("unsafe descriptor rejected", not invalidDescriptor.ok)

	local compatibility = Runtime.evaluateRendererCompatibility(
		"rendering.request.phase178.primary",
		"renderer.phase178.primary"
	)
	expect("compatibility success", compatibility.ok and compatibility.result.compatible)
	local incompatible = Runtime.evaluateRendererCompatibility(
		"rendering.request.phase178.primary",
		"renderer.phase178.missing"
	)
	expect("compatibility failure", incompatible.ok and not incompatible.result.compatible)

	local ackAccepted = Runtime.acknowledgeRenderingRequest({
		renderingAcknowledgementId = "rendering.ack.phase178.accepted",
		renderingRequestId = "rendering.request.phase178.primary",
		executionSessionId = "execution.phase177.primary",
		presentationSessionId = "presentation.session.phase176.primary",
		rendererCapabilityId = "renderer.phase178.primary",
		acknowledgementKind = Types.RenderingAcknowledgementKind.Accepted,
	})
	expect("accepted acknowledgement registered", ackAccepted.ok)
	local duplicateAck = Runtime.acknowledgeRenderingRequest({
		renderingAcknowledgementId = "rendering.ack.phase178.accepted",
		renderingRequestId = "rendering.request.phase178.primary",
		executionSessionId = "execution.phase177.primary",
		presentationSessionId = "presentation.session.phase176.primary",
		rendererCapabilityId = "renderer.phase178.primary",
		acknowledgementKind = Types.RenderingAcknowledgementKind.Accepted,
	})
	expect("duplicate acknowledgement rejected", not duplicateAck.ok)
	local ownershipMismatch = Runtime.acknowledgeRenderingRequest({
		renderingAcknowledgementId = "rendering.ack.phase178.badowner",
		renderingRequestId = "rendering.request.phase178.primary",
		executionSessionId = "execution.phase177.other",
		presentationSessionId = "presentation.session.phase176.primary",
		rendererCapabilityId = "renderer.phase178.primary",
		acknowledgementKind = Types.RenderingAcknowledgementKind.Accepted,
	})
	expect("acknowledgement ownership mismatch rejected", not ownershipMismatch.ok)
	local invalidAck = Runtime.acknowledgeRenderingRequest({
		renderingAcknowledgementId = "rendering.ack.phase178.invalid",
		renderingRequestId = "rendering.request.phase178.primary",
		executionSessionId = "execution.phase177.primary",
		presentationSessionId = "presentation.session.phase176.primary",
		rendererCapabilityId = "renderer.phase178.primary",
		acknowledgementKind = "BadAck",
	})
	expect("invalid acknowledgement rejected", not invalidAck.ok)

	local syncPending =
		Runtime.resolveRenderingSynchronization("rendering.request.phase178.primary")
	expect(
		"synchronization pending before completion",
		syncPending.ok and not syncPending.synchronization.satisfied
	)
	local ackCompleted = Runtime.acknowledgeRenderingRequest({
		renderingAcknowledgementId = "rendering.ack.phase178.completed",
		renderingRequestId = "rendering.request.phase178.primary",
		executionSessionId = "execution.phase177.primary",
		presentationSessionId = "presentation.session.phase176.primary",
		rendererCapabilityId = "renderer.phase178.primary",
		acknowledgementKind = Types.RenderingAcknowledgementKind.Completed,
	})
	expect("completed acknowledgement registered", ackCompleted.ok)
	local syncComplete =
		Runtime.resolveRenderingSynchronization("rendering.request.phase178.primary")
	expect("synchronization completed", syncComplete.ok and syncComplete.synchronization.satisfied)

	local noWaitRequest = Runtime.createRenderingRequest({
		renderingRequestId = "rendering.request.phase178.nowait",
		executionSessionId = "execution.phase177.nowait",
		presentationSessionId = "presentation.session.phase176.nowait",
		presentationId = "presentation.phase176.nowait",
		consumerId = "consumer.phase176.nowait",
		renderingKind = Types.RenderingKind.Notification,
		descriptor = {},
		synchronizationPolicy = Types.RenderingSynchronizationPolicy.NoWait,
	})
	expect("nowait request registered", noWaitRequest.ok)
	local noWaitSync = Runtime.resolveRenderingSynchronization("rendering.request.phase178.nowait")
	expect(
		"NoWait synchronization satisfied",
		noWaitSync.ok and noWaitSync.synchronization.satisfied
	)

	local diagnostics = Runtime.inspect()
	expect(
		"diagnostics provider identity",
		diagnostics.providerName == Types.RenderingContractProviderName
	)
	expect(
		"diagnostics no rendering posture",
		diagnostics.renderingContractPosture.noRendering == true
	)
	expect(
		"diagnostics no networking posture",
		diagnostics.renderingContractPosture.noNetworking == true
	)
	expect(
		"diagnostics no client authority posture",
		diagnostics.renderingContractPosture.noClientAuthority == true
	)
	diagnostics.renderingRequests[1].renderingRequestId = "mutated"
	expect(
		"diagnostics immutable copy",
		Runtime.inspect().renderingRequests[1].renderingRequestId
			== "rendering.request.phase178.primary"
	)
	local snapshot = Runtime.getSnapshot()
	expect(
		"snapshot provider identity",
		snapshot.providerName == Types.RenderingContractSnapshotProviderName
	)
	snapshot.presentationRuntimeRenderingContractSnapshot.renderingRequests[1].renderingRequestId =
		"mutated"
	expect(
		"snapshot immutable copy",
		Runtime.getSnapshot().presentationRuntimeRenderingContractSnapshot.renderingRequests[1].renderingRequestId
			== "rendering.request.phase178.primary"
	)
	expect(
		"localization references preserved",
		#Runtime.getLocalizationReferences()["rendering.request.phase178.primary"] == 1
	)
	expect(
		"accessibility references preserved",
		#Runtime.getAccessibilityReferences()["rendering.request.phase178.primary"] == 1
	)
	expect(
		"asset references preserved",
		#Runtime.getAssetReferences()["rendering.request.phase178.primary"] == 1
	)
	expect("evidence recorded", #diagnostics.evidence > 0)
	expect("metrics recorded", diagnostics.metrics.renderingRequestsCreated >= 2)
	expect("profiler recorded", #diagnostics.profiler > 0)
	expect(
		"budgets exposed",
		diagnostics.budgets.MaxRenderingRequests
			== Types.RenderingContractLimits.MaxRenderingRequests
	)
	expect(
		"governance exposed",
		diagnostics.governance.systemName == "Presentation Rendering Contract Foundation"
	)
	expect("certification candidate", diagnostics.certification.status == "ProductionCandidate")
	local valid, validationReason = Runtime.validate()
	expect("runtime validation passed", valid, validationReason)

	Runtime.reset()
	expect(
		"reset re-registers default contract",
		Runtime.inspect().contracts[Types.RenderingContractId] ~= nil
	)
	Runtime.shutdown()
	local blocked = Runtime.createRenderingRequest({
		renderingRequestId = "rendering.request.phase178.shutdown",
		executionSessionId = "execution.phase177.shutdown",
		presentationSessionId = "presentation.session.phase176.shutdown",
		presentationId = "presentation.phase176.shutdown",
		consumerId = "consumer.phase176.shutdown",
		renderingKind = Types.RenderingKind.DialogueLine,
		descriptor = {},
	})
	expect(
		"shutdown rejects new requests",
		not blocked.ok and blocked.code == Types.RenderingContractFailureType.RuntimeShutdown
	)
	expect("posture no GUI", Runtime.inspect().renderingContractPosture.noGui == true)
	expect(
		"posture no asset loading",
		Runtime.inspect().renderingContractPosture.noAssetLoading == true
	)
	expect(
		"posture no persistence",
		Runtime.inspect().renderingContractPosture.noPersistence == true
	)
	expect(
		"posture no Workspace mutation",
		Runtime.inspect().renderingContractPosture.noWorkspaceMutation == true
	)
	expect("posture no analytics", Runtime.inspect().renderingContractPosture.noAnalytics == true)
	expect("posture no telemetry", Runtime.inspect().renderingContractPosture.noTelemetry == true)

	return summarize()
end

return SelfChecks
