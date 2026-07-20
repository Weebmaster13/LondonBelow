--!strict

local ServerScriptService = game:GetService("ServerScriptService")

local InteractionCoordinator = require(ServerScriptService.Interaction.Core.InteractionCoordinator)
local InteractionTypes = require(ServerScriptService.Interaction.Core.InteractionTypes)

local Evidence = require(script.Parent.EnvironmentalEvidence)
local FamilyRegistry = require(script.Parent.EnvironmentalFamilyRegistry)
local PresentationAdapter = require(script.Parent.EnvironmentalPresentationAdapter)
local State = require(script.Parent.EnvironmentalStateRuntime)
local TransitionRuntime = require(script.Parent.EnvironmentalTransitionRuntime)
local Types = require(script.Parent.EnvironmentalTypes)
local Validation = require(script.Parent.EnvironmentalDefinitionValidation)

local Registry = {}

local function result(ok: boolean, code: string, message: string?, extra: any?)
	local payload = extra or {}
	payload.ok = ok
	payload.code = code
	payload.message = message
	return payload
end

local function phaseInteractionTypeFor(definition: any): string
	if definition.family == Types.Family.InspectableObject then
		return InteractionTypes.InteractionType.InspectableInteractionSchema
	elseif definition.family == Types.Family.MomentaryActuator then
		return InteractionTypes.InteractionType.SwitchInteractionSchema
	end
	return InteractionTypes.InteractionType.SystemInteractionSchema
end

local function interactionIdFor(definition: any, actionId: string): string
	return definition.id .. ":" .. actionId
end

local function rollback(definition: any)
	for _, actionId in ipairs(definition.supportedActions or {}) do
		InteractionCoordinator.unregisterInteraction(interactionIdFor(definition, actionId))
	end
	InteractionCoordinator.unregisterTarget(definition.interactionTargetId)
	State.unregister(definition.id)
end

local function registeredInteractionIdsFor(definition: any): { string }
	local ids = {}
	for _, actionId in ipairs(definition.supportedActions or {}) do
		table.insert(ids, interactionIdFor(definition, actionId))
	end
	return ids
end

function Registry.register(definition: any)
	local valid, reason = Validation.definition(definition)
	if not valid then
		State.recordFailure(reason or Types.ResultCode.EnvironmentConfigurationInvalid, definition)
		return result(
			false,
			reason or Types.ResultCode.EnvironmentConfigurationInvalid,
			"definition rejected"
		)
	end
	if State.exists(definition.id) then
		return result(
			false,
			Types.ResultCode.DuplicateObjectId,
			"environmental object id already registered"
		)
	end
	local family = FamilyRegistry.get(definition.family)
	if family == nil then
		return result(
			false,
			Types.ResultCode.EnvironmentFamilyNotFound,
			"environmental family not found"
		)
	end
	local familyOk, familyReason = family.validateDefinition(definition)
	if not familyOk then
		State.recordFailure(familyReason or Types.ResultCode.EnvironmentStateInvalid, definition)
		return result(
			false,
			familyReason or Types.ResultCode.EnvironmentStateInvalid,
			"family validation rejected definition"
		)
	end

	local target = InteractionCoordinator.registerTarget({
		targetId = definition.interactionTargetId,
		ownerSystem = Types.RuntimeName,
		targetStatus = "Registered",
		adapterKind = "EnvironmentalContent",
		metadata = {
			environmentObjectId = definition.id,
			family = definition.family,
			revision = definition.runtimeRegistrationRevision or 1,
		},
	})
	if not target.ok then
		State.recordFailure(target.code, definition)
		return result(false, target.code, target.message)
	end

	for _, actionId in ipairs(definition.supportedActions) do
		local registered = InteractionCoordinator.registerInteraction({
			interactionId = interactionIdFor(definition, actionId),
			definitionId = definition.id,
			targetId = definition.interactionTargetId,
			physicalObjectId = definition.authoredInstanceId or definition.id,
			interactionType = phaseInteractionTypeFor(definition),
			interactionStatus = "Registered",
			ownerSystem = Types.RuntimeName,
			eligibility = { enabled = true, environmentalAction = actionId },
			requiredState = { family = definition.family },
			cooldown = definition.cooldownPolicy or {},
			lockState = {},
			metadata = {
				environmentObjectId = definition.id,
				actionId = actionId,
				chapterId = definition.chapterId,
			},
			context = {
				environmentalContent = true,
			},
			tags = { "environmental", string.lower(definition.family) },
		})
		if not registered.ok then
			rollback(definition)
			State.recordFailure(registered.code, definition)
			return result(false, registered.code, "phase interaction registration failed")
		end
	end

	State.register(definition)
	Evidence.record(State, "Registered", {
		objectId = definition.id,
		targetId = definition.interactionTargetId,
		family = definition.family,
	})
	return result(true, Types.ResultCode.Ok, "environmental object registered")
end

function Registry.registerBatch(definitions: { any })
	if type(definitions) ~= "table" then
		return result(false, Types.ResultCode.EnvironmentConfigurationInvalid, "batch rejected")
	end
	local registeredObjectIds = {}
	for _, definition in ipairs(definitions) do
		local registered = Registry.register(definition)
		if not registered.ok then
			for index = #registeredObjectIds, 1, -1 do
				Registry.unregister(registeredObjectIds[index])
			end
			State.recordFailure(Types.ResultCode.BatchRegistrationFailed, {
				failedObjectId = if type(definition) == "table" then definition.id else nil,
				code = registered.code,
			})
			return result(false, Types.ResultCode.BatchRegistrationFailed, "batch rolled back", {
				failed = registered,
				registeredObjectIds = registeredObjectIds,
			})
		end
		table.insert(registeredObjectIds, definition.id)
	end
	return result(true, Types.ResultCode.Ok, "environmental batch registered", {
		registeredObjectIds = registeredObjectIds,
	})
end

function Registry.unregister(objectId: string)
	local definition = State.getDefinition(objectId)
	if definition == nil then
		return result(true, Types.ResultCode.Ok, "environmental object already unregistered")
	end
	rollback(definition)
	Evidence.record(State, "Unregistered", { objectId = objectId })
	return result(true, Types.ResultCode.Ok, "environmental object unregistered")
end

function Registry.request(player: any, request: any)
	local valid, reason = Validation.request(request)
	if not valid then
		State.recordFailure(reason or Types.ResultCode.EnvironmentConfigurationInvalid, request)
		return result(
			false,
			reason or Types.ResultCode.EnvironmentConfigurationInvalid,
			"request rejected"
		)
	end
	local completed = State.getCompletedRequest(request.requestId)
	if completed ~= nil then
		return result(true, Types.ResultCode.Ok, "environmental action already completed", {
			duplicateCompletion = true,
			completion = completed,
			state = State.getState(request.objectId),
		})
	end
	local definition = State.getDefinition(request.objectId)
	local state = State.getState(request.objectId)
	if
		type(request.expectedRevision) == "number"
		and state ~= nil
		and request.expectedRevision ~= state.revision
	then
		State.recordFailure(Types.ResultCode.StateRevisionMismatch, request)
		return result(false, Types.ResultCode.StateRevisionMismatch, "request revision is stale")
	end
	local plan = TransitionRuntime.evaluate(definition, state, request.actionId)
	State.increment("transitionAttempts")
	if plan.ok ~= true then
		State.recordFailure(plan.code, request)
		return result(false, plan.code, "transition rejected")
	end

	local phaseRequest = {
		requestId = request.requestId,
		interactionId = interactionIdFor(definition, request.actionId),
		targetId = definition.interactionTargetId,
		playerId = request.playerId,
		requestKind = "Primary",
		metadata = {
			environmentObjectId = request.objectId,
			actionId = request.actionId,
			stateRevision = if state ~= nil then state.revision else nil,
		},
	}

	local response = InteractionCoordinator.requestInteraction(player, phaseRequest, {
		execute = function(context)
			local committed, commitReason =
				State.commitWithRevision(request.objectId, plan, context.sessionId, {
					ok = true,
					actionId = request.actionId,
					nextState = plan.nextState,
					presentation = PresentationAdapter.project(
						definition,
						State.getState(request.objectId),
						plan
					),
				}, state.revision)
			if not committed then
				State.recordFailure(
					commitReason or Types.ResultCode.EnvironmentHandlerFailed,
					request
				)
				return {
					ok = false,
					code = commitReason or Types.ResultCode.EnvironmentHandlerFailed,
					message = "environmental state commit failed",
				}
			end
			return {
				ok = true,
				code = Types.ResultCode.Ok,
				message = "environmental transition committed",
				nextState = plan.nextState,
				mutationApplied = true,
			}
		end,
	})

	if not response.ok then
		State.recordFailure(response.code or Types.ResultCode.InteractionRuntimeRejected, request)
		return result(false, Types.ResultCode.InteractionRuntimeRejected, response.message, {
			interactionRuntime = response,
		})
	end

	local completion = {
		objectId = request.objectId,
		actionId = request.actionId,
		requestId = request.requestId,
		sessionId = if response.session ~= nil then response.session.sessionId else nil,
		state = State.getState(request.objectId),
	}
	local recordedCompletion, duplicateReason =
		State.recordCompletedRequest(request.requestId, completion)
	if not recordedCompletion then
		State.recordFailure(duplicateReason or Types.ResultCode.DuplicateCompletion, request)
	end
	Evidence.record(State, "TransitionCommitted", {
		objectId = request.objectId,
		actionId = request.actionId,
		requestId = request.requestId,
		sessionId = if response.session ~= nil then response.session.sessionId else nil,
	})
	return result(true, Types.ResultCode.Ok, "environmental action accepted", {
		interactionRuntime = response,
		state = completion.state,
		presentation = PresentationAdapter.project(
			definition,
			State.getState(request.objectId),
			plan
		),
	})
end

function Registry.reset(objectId: string)
	local definition = State.getDefinition(objectId)
	if definition == nil then
		return result(false, Types.ResultCode.EnvironmentObjectNotFound, "object not registered")
	end
	Registry.unregister(objectId)
	return Registry.register(definition)
end

function Registry.inspect()
	return State.inspect()
end

function Registry.reconcile()
	local snapshot = State.inspect()
	local interaction = InteractionCoordinator.inspect()
	local findings = {}
	for objectId, definition in pairs(snapshot.definitions) do
		if snapshot.states[objectId] == nil then
			table.insert(findings, {
				objectId = objectId,
				code = Types.ResultCode.ReconciliationFailed,
				message = "registered definition missing state",
			})
		end
		if interaction.state.targets[definition.interactionTargetId] == nil then
			table.insert(findings, {
				objectId = objectId,
				code = Types.ResultCode.ReconciliationFailed,
				message = "registered definition missing interaction target",
			})
		end
		for _, interactionId in ipairs(registeredInteractionIdsFor(definition)) do
			if interaction.state.interactions[interactionId] == nil then
				table.insert(findings, {
					objectId = objectId,
					interactionId = interactionId,
					code = Types.ResultCode.ReconciliationFailed,
					message = "registered definition missing interaction schema",
				})
			end
		end
	end
	local ok = #findings == 0
	if not ok then
		State.recordFailure(Types.ResultCode.ReconciliationFailed, findings)
	end
	return result(
		ok,
		if ok then Types.ResultCode.Ok else Types.ResultCode.ReconciliationFailed,
		"environmental reconciliation complete",
		{
			findings = findings,
			objectCount = snapshot.counts.objects,
		}
	)
end

function Registry.clear()
	State.clear()
end

return Registry
