--!strict
-- Central bounded state store for the Runtime Lifecycle Foundation.

local Serialization = require(script.Parent.RuntimeLifecycleSerialization)
local Types = require(script.Parent.RuntimeLifecycleTypes)
local Validation = require(script.Parent.RuntimeLifecycleValidation)

local State = {}

local lifecycleStates: { [string]: any } = {}
local transitions: { [string]: any } = {}
local policies: { [string]: any } = {}
local guards: { [string]: any } = {}
local events: { [string]: any } = {}
local failures: { [string]: any } = {}
local recoveries: { [string]: any } = {}
local checkpoints: { [string]: any } = {}
local audits: { [string]: any } = {}
local compatibilities: { [string]: any } = {}
local schemaIds: { [string]: boolean } = {}
local validationFailures: { any } = {}
local snapshotHistory: { any } = {}

local function boundedInsert(list: { any }, value: any, limit: number)
	table.insert(list, value)
	while #list > limit do
		table.remove(list, 1)
	end
end

local function countMap(map: { [string]: any }): number
	local count = 0
	for _ in pairs(map) do
		count += 1
	end
	return count
end

local function rejectDuplicate(schemaId: string, reason: string): (boolean, string?)
	if schemaIds[schemaId] == true then
		return false, reason
	end
	return true, nil
end

local function stateExists(id: string): boolean
	return lifecycleStates[id] ~= nil
end

local function transitionExists(id: string): boolean
	return transitions[id] ~= nil
end

local function policyExists(id: string): boolean
	return policies[id] ~= nil
end

local function guardExists(id: string): boolean
	return guards[id] ~= nil
end

local function failureExists(id: string): boolean
	return failures[id] ~= nil
end

local function validatePolicyRefs(values: any): (boolean, string?)
	if values == nil then
		return true, nil
	end
	for _, policyId in ipairs(values) do
		if not policyExists(policyId) then
			return false, "invalid policy reference"
		end
	end
	return true, nil
end

local function validateGuardRefs(values: any): (boolean, string?)
	if values == nil then
		return true, nil
	end
	for _, guardId in ipairs(values) do
		if not guardExists(guardId) then
			return false, "invalid guard reference"
		end
	end
	return true, nil
end

function State.registerLifecycleState(schema: any): (boolean, string?)
	local ok, reason = Validation.lifecycleState(schema)
	if not ok then
		return false, reason
	end
	local unique, duplicateReason =
		rejectDuplicate(schema.lifecycleStateId, "duplicate lifecycleStateId")
	if not unique then
		return false, duplicateReason
	end
	if countMap(lifecycleStates) >= Types.Limits.MaxLifecycleStates then
		return false, "lifecycle state limit exceeded"
	end
	schemaIds[schema.lifecycleStateId] = true
	lifecycleStates[schema.lifecycleStateId] = Serialization.deepCopy(schema)
	return true, nil
end

function State.registerTransition(schema: any): (boolean, string?)
	local ok, reason = Validation.transition(schema)
	if not ok then
		return false, reason
	end
	local policiesOk, policiesReason = validatePolicyRefs(schema.policyIds)
	if not policiesOk then
		return false, policiesReason
	end
	local guardsOk, guardsReason = validateGuardRefs(schema.guardIds)
	if not guardsOk then
		return false, guardsReason
	end
	local unique, duplicateReason = rejectDuplicate(schema.transitionId, "duplicate transitionId")
	if not unique then
		return false, duplicateReason
	end
	if countMap(transitions) >= Types.Limits.MaxTransitions then
		return false, "transition limit exceeded"
	end
	schemaIds[schema.transitionId] = true
	transitions[schema.transitionId] = Serialization.deepCopy(schema)
	return true, nil
end

function State.registerPolicy(schema: any): (boolean, string?)
	local ok, reason = Validation.policy(schema)
	if not ok then
		return false, reason
	end
	local unique, duplicateReason = rejectDuplicate(schema.policyId, "duplicate policyId")
	if not unique then
		return false, duplicateReason
	end
	if countMap(policies) >= Types.Limits.MaxPolicies then
		return false, "policy limit exceeded"
	end
	schemaIds[schema.policyId] = true
	policies[schema.policyId] = Serialization.deepCopy(schema)
	return true, nil
end

function State.registerGuard(schema: any): (boolean, string?)
	local ok, reason = Validation.guard(schema)
	if not ok then
		return false, reason
	end
	local unique, duplicateReason = rejectDuplicate(schema.guardId, "duplicate guardId")
	if not unique then
		return false, duplicateReason
	end
	if countMap(guards) >= Types.Limits.MaxGuards then
		return false, "guard limit exceeded"
	end
	schemaIds[schema.guardId] = true
	guards[schema.guardId] = Serialization.deepCopy(schema)
	return true, nil
end

function State.registerEvent(schema: any): (boolean, string?)
	local ok, reason = Validation.event(schema)
	if not ok then
		return false, reason
	end
	if schema.relatedStateId ~= nil and not stateExists(schema.relatedStateId) then
		return false, "invalid event state reference"
	end
	if schema.relatedTransitionId ~= nil and not transitionExists(schema.relatedTransitionId) then
		return false, "invalid event transition reference"
	end
	local unique, duplicateReason = rejectDuplicate(schema.eventId, "duplicate eventId")
	if not unique then
		return false, duplicateReason
	end
	if countMap(events) >= Types.Limits.MaxEvents then
		return false, "event limit exceeded"
	end
	schemaIds[schema.eventId] = true
	events[schema.eventId] = Serialization.deepCopy(schema)
	return true, nil
end

function State.registerFailure(schema: any): (boolean, string?)
	local ok, reason = Validation.failure(schema)
	if not ok then
		return false, reason
	end
	if schema.relatedStateId ~= nil and not stateExists(schema.relatedStateId) then
		return false, "invalid failure state reference"
	end
	if schema.relatedTransitionId ~= nil and not transitionExists(schema.relatedTransitionId) then
		return false, "invalid failure transition reference"
	end
	local unique, duplicateReason = rejectDuplicate(schema.failureId, "duplicate failureId")
	if not unique then
		return false, duplicateReason
	end
	if countMap(failures) >= Types.Limits.MaxFailures then
		return false, "failure limit exceeded"
	end
	schemaIds[schema.failureId] = true
	failures[schema.failureId] = Serialization.deepCopy(schema)
	return true, nil
end

function State.registerRecovery(schema: any): (boolean, string?)
	local ok, reason = Validation.recovery(schema)
	if not ok then
		return false, reason
	end
	if schema.relatedFailureId ~= nil and not failureExists(schema.relatedFailureId) then
		return false, "invalid recovery failure reference"
	end
	local unique, duplicateReason = rejectDuplicate(schema.recoveryId, "duplicate recoveryId")
	if not unique then
		return false, duplicateReason
	end
	if countMap(recoveries) >= Types.Limits.MaxRecoveries then
		return false, "recovery limit exceeded"
	end
	schemaIds[schema.recoveryId] = true
	recoveries[schema.recoveryId] = Serialization.deepCopy(schema)
	return true, nil
end

function State.registerCheckpoint(schema: any): (boolean, string?)
	local ok, reason = Validation.checkpoint(schema)
	if not ok then
		return false, reason
	end
	local unique, duplicateReason = rejectDuplicate(schema.checkpointId, "duplicate checkpointId")
	if not unique then
		return false, duplicateReason
	end
	if countMap(checkpoints) >= Types.Limits.MaxCheckpoints then
		return false, "checkpoint limit exceeded"
	end
	schemaIds[schema.checkpointId] = true
	checkpoints[schema.checkpointId] = Serialization.deepCopy(schema)
	return true, nil
end

function State.registerAudit(schema: any): (boolean, string?)
	local ok, reason = Validation.audit(schema)
	if not ok then
		return false, reason
	end
	local unique, duplicateReason = rejectDuplicate(schema.auditId, "duplicate auditId")
	if not unique then
		return false, duplicateReason
	end
	if countMap(audits) >= Types.Limits.MaxAudits then
		return false, "audit limit exceeded"
	end
	schemaIds[schema.auditId] = true
	audits[schema.auditId] = Serialization.deepCopy(schema)
	return true, nil
end

function State.registerCompatibility(schema: any): (boolean, string?)
	local ok, reason = Validation.compatibility(schema)
	if not ok then
		return false, reason
	end
	local unique, duplicateReason =
		rejectDuplicate(schema.compatibilityId, "duplicate compatibilityId")
	if not unique then
		return false, duplicateReason
	end
	if countMap(compatibilities) >= Types.Limits.MaxCompatibilityRecords then
		return false, "compatibility limit exceeded"
	end
	schemaIds[schema.compatibilityId] = true
	compatibilities[schema.compatibilityId] = Serialization.deepCopy(schema)
	return true, nil
end

function State.recordValidationFailure(reason: string, payload: any?)
	boundedInsert(validationFailures, {
		reason = reason,
		payload = Serialization.diagnosticCopy(payload),
	}, Types.Limits.MaxValidationFailures)
end

function State.recordSnapshot(snapshot: any)
	boundedInsert(
		snapshotHistory,
		Serialization.diagnosticCopy(snapshot),
		Types.Limits.MaxSnapshotHistory
	)
end

function State.inspect()
	return Serialization.deepCopy({
		lifecycleStates = lifecycleStates,
		transitions = transitions,
		policies = policies,
		guards = guards,
		events = events,
		failures = failures,
		recoveries = recoveries,
		checkpoints = checkpoints,
		audits = audits,
		compatibilities = compatibilities,
		validationFailures = validationFailures,
		snapshotHistory = snapshotHistory,
		counts = {
			lifecycleStates = countMap(lifecycleStates),
			transitions = countMap(transitions),
			policies = countMap(policies),
			guards = countMap(guards),
			events = countMap(events),
			failures = countMap(failures),
			recoveries = countMap(recoveries),
			checkpoints = countMap(checkpoints),
			audits = countMap(audits),
			compatibilities = countMap(compatibilities),
			validationFailures = #validationFailures,
			snapshots = #snapshotHistory,
		},
	})
end

function State.clear()
	table.clear(lifecycleStates)
	table.clear(transitions)
	table.clear(policies)
	table.clear(guards)
	table.clear(events)
	table.clear(failures)
	table.clear(recoveries)
	table.clear(checkpoints)
	table.clear(audits)
	table.clear(compatibilities)
	table.clear(schemaIds)
	table.clear(validationFailures)
	table.clear(snapshotHistory)
end

return State
