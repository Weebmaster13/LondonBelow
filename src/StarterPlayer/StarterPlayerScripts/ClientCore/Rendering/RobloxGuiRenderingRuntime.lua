--!strict

local Registry = require(script.Parent.RobloxGuiInstanceRegistry)
local IntegrityGuard = require(script.Parent.RobloxGuiIntegrityGuard)
local AnimationRuntime = require(script.Parent.RobloxGuiAnimationRuntime)
local InteractionRuntime = require(script.Parent.RobloxGuiInteractionRuntime)
local ResponsiveLocalizationRuntime = require(script.Parent.RobloxGuiResponsiveLocalizationRuntime)
local ThemeRuntime = require(script.Parent.RobloxGuiThemeRuntime)
local Transaction = require(script.Parent.RobloxGuiRenderTransaction)
local Types = require(script.Parent.RobloxGuiRenderingTypes)
local Validator = require(script.Parent.RobloxGuiRenderingValidator)

local Runtime = {}
local state = Types.RuntimeState.Unconfigured
local mountTarget = nil :: Instance?
local busy = false
local sequence = 0
local transactions = {}
local failures = {}
local audit = {}
local counters = {
	renderRequests = 0,
	idempotentRequests = 0,
	validationFailures = 0,
	stagingFailures = 0,
	commits = 0,
	rollbacks = 0,
	unmounts = 0,
	instancesCreated = 0,
	instancesDestroyed = 0,
	staleRevisionsRejected = 0,
	integrityChecks = 0,
	integrityViolations = 0,
	remounts = 0,
}

local function boundedAppend(target: { any }, value: any, limit: number)
	if #target >= limit then
		table.remove(target, 1)
	end
	target[#target + 1] = value
end

local function record(kind: string, detail: any?)
	sequence += 1
	boundedAppend(
		audit,
		table.freeze({ sequence = sequence, kind = kind, detail = detail or {} }),
		Types.Limits.maxAuditRecords
	)
end

local function fail(code: string, detail: any?)
	state = Types.RuntimeState.Failed
	local failure = table.freeze({ sequence = sequence + 1, code = code, detail = detail })
	boundedAppend(failures, failure, Types.Limits.maxFailures)
	record("Failure", failure)
	return { ok = false, code = code, detail = detail }
end

function Runtime.configure(target: Instance)
	if state == Types.RuntimeState.Shutdown then
		return fail(Types.FailureType.RuntimeShutdown)
	end
	if target.ClassName ~= "PlayerGui" then
		return fail(Types.FailureType.MountTargetInvalid, target.ClassName)
	end
	mountTarget = target
	local interactionResult = InteractionRuntime.configure(target)
	if not interactionResult.ok then
		return fail(interactionResult.code, interactionResult.detail)
	end
	state = Types.RuntimeState.Ready
	record("Configured", { mountClass = target.ClassName })
	return { ok = true }
end

function Runtime.render(contract: any)
	counters.renderRequests += 1
	if state == Types.RuntimeState.Shutdown then
		return fail(Types.FailureType.RuntimeShutdown)
	end
	if busy then
		return fail(Types.FailureType.RuntimeBusy)
	end
	if not mountTarget or mountTarget.Parent == nil then
		return fail(Types.FailureType.MountTargetMissing)
	end
	local previous = Registry.get()
	if
		previous
		and type(contract) == "table"
		and type(contract.targetRevision) == "number"
		and previous.contractId == contract.contractId
	then
		if contract.targetRevision < previous.revision then
			counters.staleRevisionsRejected += 1
			return fail(
				Types.FailureType.StaleRevision,
				{ active = previous.revision, requested = contract.targetRevision }
			)
		end
	end
	if previous then
		counters.integrityChecks += 1
		local intact, integrityReason = IntegrityGuard.verify(previous, mountTarget)
		if not intact then
			counters.integrityViolations += 1
			return fail(Types.FailureType.IntegrityViolation, integrityReason)
		end
	end
	if
		type(contract) == "table"
		and previous
		and previous.contractId == contract.contractId
		and previous.revision == contract.targetRevision
	then
		counters.idempotentRequests += 1
		record(
			"Idempotent",
			{ contractId = contract.contractId, revision = contract.targetRevision }
		)
		return {
			ok = true,
			idempotent = true,
			contractId = contract.contractId,
			revision = contract.targetRevision,
		}
	end
	busy = true
	state = Types.RuntimeState.Rendering
	local valid, reason, ordered = Validator.validate(contract)
	if not valid or not ordered then
		busy = false
		counters.validationFailures += 1
		return fail(reason or Types.FailureType.InvalidContract, contract and contract.contractId)
	end
	local reconcilePermit = InteractionRuntime.beginReconcile()
	if not reconcilePermit.ok then
		busy = false
		return fail(reconcilePermit.code, reconcilePermit.detail)
	end
	local transaction, stageReason = Transaction.stage(contract, ordered)
	if not transaction then
		InteractionRuntime.cancelReconcile(reconcilePermit.permit)
		busy = false
		counters.stagingFailures += 1
		counters.rollbacks += 1
		return fail(stageReason or Types.FailureType.InstanceCreationFailed, contract.contractId)
	end
	counters.instancesCreated += transaction.nodeCount
	local responsiveLocalizationResult =
		ResponsiveLocalizationRuntime.reconcile(transaction, contract)
	if not responsiveLocalizationResult.ok then
		InteractionRuntime.cancelReconcile(reconcilePermit.permit)
		Transaction.discard(transaction)
		busy = false
		counters.rollbacks += 1
		return fail(responsiveLocalizationResult.code, responsiveLocalizationResult.detail)
	end
	InteractionRuntime.captureFocus(previous)
	local committed, commitReason = Transaction.commit(transaction, mountTarget, previous)
	boundedAppend(transactions, {
		contractId = transaction.contractId,
		revision = transaction.revision,
		state = transaction.state,
		nodeCount = transaction.nodeCount,
	}, Types.Limits.maxTransactions)
	if not committed then
		InteractionRuntime.cancelReconcile(reconcilePermit.permit)
		busy = false
		counters.rollbacks += 1
		return fail(commitReason or Types.FailureType.CommitFailed, contract.contractId)
	end
	if previous then
		counters.instancesDestroyed += previous.nodeCount or 0
	end
	Registry.commit(transaction)
	AnimationRuntime.reconcile()
	ThemeRuntime.reconcile()
	ResponsiveLocalizationRuntime.activate(transaction, contract)
	local interactionResult =
		InteractionRuntime.reconcile(transaction, contract, reconcilePermit.permit)
	if not interactionResult.ok then
		busy = false
		return fail(interactionResult.code, interactionResult.detail)
	end
	counters.commits += 1
	state = Types.RuntimeState.Committed
	busy = false
	record("Committed", {
		contractId = contract.contractId,
		revision = contract.targetRevision,
		nodeCount = transaction.nodeCount,
	})
	return {
		ok = true,
		idempotent = false,
		contractId = contract.contractId,
		revision = contract.targetRevision,
		nodeCount = transaction.nodeCount,
		interaction = interactionResult,
		responsiveLocalization = responsiveLocalizationResult,
	}
end

function Runtime.unmount()
	if busy then
		return fail(Types.FailureType.RuntimeBusy)
	end
	local active = Registry.get()
	AnimationRuntime.cancelAll("Unmount")
	ThemeRuntime.reconcile()
	InteractionRuntime.unmount(active)
	if active then
		ResponsiveLocalizationRuntime.clearActive(active)
		Transaction.destroy(active)
		counters.instancesDestroyed += active.nodeCount or 0
		Registry.clear()
	end
	counters.unmounts += 1
	state = mountTarget and Types.RuntimeState.Ready or Types.RuntimeState.Unconfigured
	record("Unmounted")
	return { ok = true }
end

function Runtime.remount(target: Instance)
	if state == Types.RuntimeState.Shutdown then
		return fail(Types.FailureType.RuntimeShutdown)
	end
	if busy then
		return fail(Types.FailureType.RuntimeBusy)
	end
	if target.ClassName ~= "PlayerGui" then
		return fail(Types.FailureType.MountTargetInvalid, target.ClassName)
	end
	local active = Registry.get()
	if active then
		local result = InteractionRuntime.remount(target, active)
		if not result.ok then
			return fail(result.code, result.detail)
		end
	else
		local result = InteractionRuntime.configure(target)
		if not result.ok then
			return fail(result.code, result.detail)
		end
	end
	mountTarget = target
	counters.remounts += 1
	record("Remounted", { active = active ~= nil })
	return { ok = true, active = active ~= nil }
end

function Runtime.registerLocalizationBundle(locale: any, entries: any, revision: any?)
	return ResponsiveLocalizationRuntime.registerBundle(locale, entries, revision)
end

function Runtime.setLocale(locale: any)
	return ResponsiveLocalizationRuntime.setLocale(locale)
end

function Runtime.setResponsiveContext(viewport: any, safeInsets: any)
	return ResponsiveLocalizationRuntime.setContext(viewport, safeInsets)
end

function Runtime.playAnimation(contract: any)
	return AnimationRuntime.play(contract)
end

function Runtime.cancelAnimation(animationId: any, restoreValues: boolean?)
	return AnimationRuntime.cancel(animationId, restoreValues)
end

function Runtime.setMotionPreference(preference: any)
	return AnimationRuntime.setMotionPreference(preference)
end

function Runtime.verifyAnimationIntegrity()
	return AnimationRuntime.verifyIntegrity()
end

function Runtime.setAnimationFailureInjectionForTest(stage: any, count: any)
	return AnimationRuntime.setFailureInjectionForTest(stage, count)
end

function Runtime.registerTheme(themeId: any, revision: any, tokens: any)
	return ThemeRuntime.registerTheme(themeId, revision, tokens)
end

function Runtime.applyTheme(contract: any)
	return ThemeRuntime.apply(contract)
end

function Runtime.inspect()
	return {
		runtimeVersion = Types.RuntimeVersion,
		schemaVersion = Types.SchemaVersion,
		state = state,
		busy = busy,
		configured = mountTarget ~= nil,
		active = Registry.snapshot(),
		counters = table.clone(counters),
		failures = table.clone(failures),
		transactionCount = #transactions,
		interaction = InteractionRuntime.inspect(),
		responsiveLocalization = ResponsiveLocalizationRuntime.inspect(),
		animation = AnimationRuntime.inspect(),
		theme = ThemeRuntime.inspect(),
		posture = {
			clientPresentationOnly = true,
			noGameplayAuthority = true,
			noServerAuthority = true,
			noNetworking = true,
			noPersistence = true,
			noAnalytics = true,
			noTelemetry = true,
		},
	}
end

function Runtime.verifyIntegrity()
	local active = Registry.get()
	if not active then
		return { ok = true, mounted = false }
	end
	if not mountTarget then
		return fail(Types.FailureType.MountTargetMissing)
	end
	counters.integrityChecks += 1
	local ok, reason = IntegrityGuard.verify(active, mountTarget)
	if not ok then
		counters.integrityViolations += 1
		return fail(Types.FailureType.IntegrityViolation, reason)
	end
	record("IntegrityVerified", { contractId = active.contractId, revision = active.revision })
	return { ok = true, mounted = true, contractId = active.contractId, revision = active.revision }
end

function Runtime.getSnapshot()
	return {
		diagnostics = Runtime.inspect(),
		transactions = table.clone(transactions),
		audit = table.clone(audit),
		interaction = InteractionRuntime.getSnapshot(),
		responsiveLocalization = ResponsiveLocalizationRuntime.getSnapshot(),
		animation = AnimationRuntime.getSnapshot(),
		theme = ThemeRuntime.getSnapshot(),
	}
end

function Runtime.shutdown()
	Runtime.unmount()
	InteractionRuntime.shutdown()
	ResponsiveLocalizationRuntime.shutdown()
	AnimationRuntime.shutdown()
	ThemeRuntime.shutdown()
	mountTarget = nil
	state = Types.RuntimeState.Shutdown
	record("Shutdown")
end

return Runtime
