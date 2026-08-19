--!strict

local Accessibility = require(script.Parent.RobloxGuiAccessibilityMetadata)
local ConnectionLedger = require(script.Parent.RobloxGuiInteractionConnectionLedger)
local FocusManager = require(script.Parent.RobloxGuiFocusManager)
local FocusScope = require(script.Parent.RobloxGuiFocusScope)
local GenerationGuard = require(script.Parent.RobloxGuiInteractionGenerationGuard)
local Preferences = require(script.Parent.RobloxGuiAccessibilityPreferences)
local ReconciliationBudget = require(script.Parent.RobloxGuiReconciliationBudget)
local Types = require(script.Parent.RobloxGuiInteractionTypes)

local Runtime = {}
local state = Types.RuntimeState.Unconfigured
local mountTarget = nil :: Instance?
local actions = {} :: { [string]: (any) -> () }
local controlsByNodeId = {} :: { [string]: any }
local orderedControls = {} :: { any }
local announcer = nil :: ((string, any) -> ())?
local activeScopeId = nil :: string?
local pendingReconcilePermit = nil :: number?
local reconcilePermitSequence = 0
local failures = {}
local audit = {}
local sequence = 0
local counters = {
	reconciliations = 0,
	controlsBound = 0,
	activations = 0,
	disabledActivationsRejected = 0,
	unknownActions = 0,
	callbackFailures = 0,
	focusRestores = 0,
	focusRestoreMisses = 0,
	announcements = 0,
	connectionsDisconnected = 0,
	staleActivationsRejected = 0,
	reentrantActivationsRejected = 0,
	preferenceChanges = 0,
	modalReconciliations = 0,
	focusScopeActivationsRejected = 0,
	remounts = 0,
	reconciliationsRateLimited = 0,
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
	local failure = table.freeze({ sequence = sequence + 1, code = code, detail = detail })
	boundedAppend(failures, failure, Types.Limits.maxFailures)
	record("Failure", failure)
	return { ok = false, code = code, detail = detail }
end

local function disconnectControls()
	counters.connectionsDisconnected += ConnectionLedger.disconnectAll()
	table.clear(controlsByNodeId)
	table.clear(orderedControls)
	activeScopeId = nil
end

local function announce(message: string, context: any)
	if announcer and message ~= "" then
		counters.announcements += 1
		local ok = pcall(announcer, message, context)
		if not ok then
			counters.callbackFailures += 1
		end
	end
end

local function activate(control: any, generation: number)
	if not GenerationGuard.isCurrent(generation) then
		counters.staleActivationsRejected += 1
		fail(Types.FailureType.StaleActivation, control.nodeId)
		return
	end
	if control.scopeBlocked then
		counters.focusScopeActivationsRejected += 1
		fail(Types.FailureType.FocusScopeBlocked, control.nodeId)
		return
	end
	if control.disabled then
		counters.disabledActivationsRejected += 1
		if Preferences.get().announceDisabled then
			announce(
				(control.label or "Control") .. ". Unavailable.",
				{ kind = "Disabled", nodeId = control.nodeId }
			)
		end
		fail(Types.FailureType.DisabledControl, control.nodeId)
		return
	end
	if not control.actionId then
		return
	end
	if not GenerationGuard.enter(control.actionId) then
		counters.reentrantActivationsRejected += 1
		fail(Types.FailureType.ReentrantActivation, control.actionId)
		return
	end
	local callback = actions[control.actionId]
	if not callback then
		GenerationGuard.leave(control.actionId)
		counters.unknownActions += 1
		fail(Types.FailureType.UnknownAction, control.actionId)
		return
	end
	local context = table.freeze({
		actionId = control.actionId,
		nodeId = control.nodeId,
		contractId = control.contractId,
		revision = control.revision,
		inputAgnostic = true,
		clientPresentationOnly = true,
	})
	local ok, callbackError = pcall(callback, context)
	GenerationGuard.leave(control.actionId)
	if not ok then
		counters.callbackFailures += 1
		fail(Types.FailureType.CallbackFailed, tostring(callbackError))
		return
	end
	counters.activations += 1
	record("Activated", context)
end

function Runtime.configure(target: Instance)
	if state == Types.RuntimeState.Shutdown then
		return fail(Types.FailureType.RuntimeShutdown)
	end
	if target.ClassName ~= "PlayerGui" then
		return fail(Types.FailureType.MountTargetInvalid, target.ClassName)
	end
	mountTarget = target
	state = Types.RuntimeState.Ready
	record("Configured")
	return { ok = true }
end

function Runtime.registerAction(actionId: string, callback: (any) -> ())
	if state == Types.RuntimeState.Shutdown then
		return fail(Types.FailureType.RuntimeShutdown)
	end
	if
		type(actionId) ~= "string"
		or actionId == ""
		or #actionId > Types.Limits.maxActionIdLength
	then
		return fail(Types.FailureType.InvalidActionId)
	end
	if type(callback) ~= "function" then
		return fail(Types.FailureType.InvalidCallback, actionId)
	end
	if actions[actionId] then
		return fail(Types.FailureType.DuplicateAction, actionId)
	end
	local count = 0
	for _ in pairs(actions) do
		count += 1
	end
	if count >= Types.Limits.maxActions then
		return fail(Types.FailureType.InvalidActionId, "action-budget")
	end
	actions[actionId] = callback
	record("ActionRegistered", { actionId = actionId })
	return { ok = true, actionId = actionId }
end

function Runtime.unregisterAction(actionId: string)
	actions[actionId] = nil
	record("ActionUnregistered", { actionId = actionId })
	return { ok = true }
end

function Runtime.setAnnouncer(callback: ((string, any) -> ())?)
	if callback ~= nil and type(callback) ~= "function" then
		return fail(Types.FailureType.InvalidCallback, "announcer")
	end
	announcer = callback
	return { ok = true }
end

function Runtime.setPreferences(value: any)
	if state == Types.RuntimeState.Shutdown then
		return fail(Types.FailureType.RuntimeShutdown)
	end
	local valid, reason = Preferences.set(value)
	if not valid then
		return fail(Types.FailureType.InvalidPreferences, reason)
	end
	counters.preferenceChanges += 1
	record("PreferencesChanged", Preferences.get())
	return { ok = true, preferences = Preferences.get() }
end

function Runtime.remount(target: Instance, renderRecord: any)
	if state == Types.RuntimeState.Shutdown then
		return fail(Types.FailureType.RuntimeShutdown)
	end
	if target.ClassName ~= "PlayerGui" or not renderRecord or not renderRecord.root then
		return fail(Types.FailureType.RemountFailed, "invalid-target-or-record")
	end
	local ok, remountError = pcall(function()
		renderRecord.root.Parent = target
	end)
	if not ok then
		return fail(Types.FailureType.RemountFailed, tostring(remountError))
	end
	mountTarget = target
	counters.remounts += 1
	record("Remounted", { contractId = renderRecord.contractId, revision = renderRecord.revision })
	return { ok = true, contractId = renderRecord.contractId, revision = renderRecord.revision }
end

function Runtime.captureFocus(renderRecord: any)
	FocusManager.capture(renderRecord)
end

function Runtime.beginReconcile()
	if state == Types.RuntimeState.Shutdown then
		return fail(Types.FailureType.RuntimeShutdown)
	end
	if not ReconciliationBudget.consume(os.clock()) then
		counters.reconciliationsRateLimited += 1
		return fail(Types.FailureType.ReconciliationRateExceeded)
	end
	reconcilePermitSequence += 1
	pendingReconcilePermit = reconcilePermitSequence
	return { ok = true, permit = reconcilePermitSequence }
end

function Runtime.cancelReconcile(permit: number)
	if pendingReconcilePermit == permit then
		pendingReconcilePermit = nil
		record("ReconcileCancelled", { permit = permit })
	end
end

function Runtime.reconcile(renderRecord: any, contract: any, permit: number)
	if state == Types.RuntimeState.Shutdown then
		return fail(Types.FailureType.RuntimeShutdown)
	end
	if not mountTarget then
		return fail(Types.FailureType.MountTargetInvalid)
	end
	if pendingReconcilePermit ~= permit then
		return fail(Types.FailureType.ReconciliationPermitInvalid, permit)
	end
	pendingReconcilePermit = nil
	disconnectControls()
	local generation = GenerationGuard.advance()
	for _, node in ipairs(contract.nodes) do
		local instance = renderRecord.instances[node.nodeId]
		local metadata = node.accessibility or {}
		local valid, reason = Accessibility.validate(node.className, metadata)
		if not valid then
			return fail(reason or Types.FailureType.InvalidAccessibilityMetadata, node.nodeId)
		end
		if metadata.focusable == true and instance and instance:IsA("GuiButton") then
			if #orderedControls >= Types.Limits.maxControls then
				return fail(Types.FailureType.InvalidAccessibilityMetadata, "control-budget")
			end
			instance.Selectable = metadata.disabled ~= true
			instance.Active = metadata.disabled ~= true
			instance.Interactable = metadata.disabled ~= true
			instance.SelectionOrder = metadata.selectionOrder
				or node.properties.SelectionOrder
				or node.properties.LayoutOrder
				or #orderedControls + 1
			instance:SetAttribute("LondonEngineAccessibilityLabel", metadata.label)
			instance:SetAttribute("LondonEngineAccessibilityDescription", metadata.description)
			instance:SetAttribute("LondonEngineActionId", metadata.actionId)
			instance:SetAttribute("LondonEngineDisabled", metadata.disabled == true)
			local control = {
				nodeId = node.nodeId,
				actionId = metadata.actionId,
				disabled = metadata.disabled == true,
				label = metadata.label,
				instance = instance,
				contractId = contract.contractId,
				revision = contract.targetRevision,
				initialFocus = metadata.initialFocus == true,
			}
			controlsByNodeId[node.nodeId] = control
			orderedControls[#orderedControls + 1] = control
			ConnectionLedger.add(instance.Activated:Connect(function()
				activate(control, generation)
			end))
			ConnectionLedger.add(instance.SelectionGained:Connect(function()
				if Preferences.get().announceFocus then
					announce(
						Accessibility.describe(metadata),
						{ kind = "Focus", nodeId = node.nodeId }
					)
				end
			end))
		end
		if
			metadata.liveRegion
			and metadata.liveRegion ~= "Off"
			and Preferences.get().announceLiveRegions
		then
			announce(
				Accessibility.describe(metadata),
				{ kind = "LiveRegion", priority = metadata.liveRegion, nodeId = node.nodeId }
			)
		end
	end
	table.sort(orderedControls, function(a, b)
		if a.instance.SelectionOrder == b.instance.SelectionOrder then
			return a.nodeId < b.nodeId
		end
		return a.instance.SelectionOrder < b.instance.SelectionOrder
	end)
	counters.reconciliations += 1
	counters.controlsBound += #orderedControls
	local scopeOk, eligibleControls, scopeReason = FocusScope.resolve(contract, orderedControls)
	if not scopeOk or not eligibleControls then
		return fail(Types.FailureType.InvalidFocusScope, scopeReason)
	end
	activeScopeId = scopeReason
	if activeScopeId then
		counters.modalReconciliations += 1
		local eligibleByNodeId = {}
		for _, control in ipairs(eligibleControls) do
			eligibleByNodeId[control.nodeId] = true
		end
		for _, control in ipairs(orderedControls) do
			if not eligibleByNodeId[control.nodeId] then
				control.scopeBlocked = true
				control.instance.Selectable = false
				control.instance.Active = false
				control.instance.Interactable = false
			end
		end
	end
	local restored = FocusManager.restore(eligibleControls, Preferences.get().autoFocusMode)
	if restored then
		counters.focusRestores += 1
	else
		counters.focusRestoreMisses += 1
	end
	state = Types.RuntimeState.Mounted
	record("Reconciled", {
		contractId = contract.contractId,
		revision = contract.targetRevision,
		controlCount = #orderedControls,
		eligibleControlCount = #eligibleControls,
		activeScopeId = activeScopeId,
		generation = generation,
	})
	return {
		ok = true,
		controlCount = #orderedControls,
		eligibleControlCount = #eligibleControls,
		activeScopeId = activeScopeId,
		generation = generation,
		focusRestored = restored,
	}
end

function Runtime.unmount(renderRecord: any?)
	disconnectControls()
	GenerationGuard.advance()
	FocusManager.clear(renderRecord)
	state = mountTarget and Types.RuntimeState.Ready or Types.RuntimeState.Unconfigured
	record("Unmounted")
	return { ok = true }
end

function Runtime.inspect()
	local actionCount = 0
	for _ in pairs(actions) do
		actionCount += 1
	end
	return {
		runtimeVersion = Types.RuntimeVersion,
		state = state,
		actionCount = actionCount,
		controlCount = #orderedControls,
		selectedNodeId = FocusManager.getSelectedNodeId(),
		activeScopeId = activeScopeId,
		preferences = Preferences.get(),
		connectionLedger = ConnectionLedger.inspect(),
		generationGuard = GenerationGuard.inspect(),
		reconciliationBudget = ReconciliationBudget.inspect(),
		counters = table.clone(counters),
		failures = table.clone(failures),
		posture = {
			clientPresentationOnly = true,
			inputAgnosticActivation = true,
			noGameplayAuthority = true,
			noNetworking = true,
			noPersistence = true,
			noAnalytics = true,
			noTelemetry = true,
		},
	}
end

function Runtime.getSnapshot()
	return { diagnostics = Runtime.inspect(), audit = table.clone(audit) }
end

function Runtime.shutdown()
	Runtime.unmount(nil)
	table.clear(actions)
	ConnectionLedger.reset()
	GenerationGuard.reset()
	Preferences.reset()
	ReconciliationBudget.reset()
	pendingReconcilePermit = nil
	reconcilePermitSequence = 0
	announcer = nil
	mountTarget = nil
	state = Types.RuntimeState.Shutdown
	record("Shutdown")
end

return Runtime
