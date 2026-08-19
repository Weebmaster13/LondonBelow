--!strict

local Accessibility = require(script.Parent.RobloxGuiAccessibilityMetadata)
local FocusManager = require(script.Parent.RobloxGuiFocusManager)
local Types = require(script.Parent.RobloxGuiInteractionTypes)

local Runtime = {}
local state = Types.RuntimeState.Unconfigured
local mountTarget = nil :: Instance?
local actions = {} :: { [string]: (any) -> () }
local controlsByNodeId = {} :: { [string]: any }
local orderedControls = {} :: { any }
local connections = {} :: { RBXScriptConnection }
local announcer = nil :: ((string, any) -> ())?
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
	for _, connection in ipairs(connections) do
		connection:Disconnect()
		counters.connectionsDisconnected += 1
	end
	table.clear(connections)
	table.clear(controlsByNodeId)
	table.clear(orderedControls)
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

local function activate(control: any)
	if control.disabled then
		counters.disabledActivationsRejected += 1
		fail(Types.FailureType.DisabledControl, control.nodeId)
		return
	end
	if not control.actionId then
		return
	end
	local callback = actions[control.actionId]
	if not callback then
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

function Runtime.captureFocus(renderRecord: any)
	FocusManager.capture(renderRecord)
end

function Runtime.reconcile(renderRecord: any, contract: any)
	if state == Types.RuntimeState.Shutdown then
		return fail(Types.FailureType.RuntimeShutdown)
	end
	if not mountTarget then
		return fail(Types.FailureType.MountTargetInvalid)
	end
	disconnectControls()
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
			}
			controlsByNodeId[node.nodeId] = control
			orderedControls[#orderedControls + 1] = control
			connections[#connections + 1] = instance.Activated:Connect(function()
				activate(control)
			end)
			connections[#connections + 1] = instance.SelectionGained:Connect(function()
				announce(Accessibility.describe(metadata), { kind = "Focus", nodeId = node.nodeId })
			end)
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
	local restored = FocusManager.restore(controlsByNodeId, orderedControls)
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
	})
	return { ok = true, controlCount = #orderedControls, focusRestored = restored }
end

function Runtime.unmount(renderRecord: any?)
	disconnectControls()
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
	announcer = nil
	mountTarget = nil
	state = Types.RuntimeState.Shutdown
	record("Shutdown")
end

return Runtime
