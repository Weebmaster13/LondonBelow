--!strict

local Serialization = require(script.Parent.AssetExecutionAdapterRegistrationWorkflowSerialization)
local Types = require(script.Parent.AssetExecutionAdapterRegistrationWorkflowTypes)
local Validation = require(script.Parent.AssetExecutionAdapterRegistrationWorkflowValidation)

local State = {}

local workflows: { [string]: any } = {}
local stages: { [string]: any } = {}
local transitions: { [string]: any } = {}
local decisions: { [string]: any } = {}
local audits: { [string]: any } = {}
local workflowSnapshots: { [string]: any } = {}
local workflowNames: { [string]: boolean } = {}
local stageOrders: { [string]: boolean } = {}
local stageOwners: { [string]: boolean } = {}
local schemaIds: { [string]: boolean } = {}
local validationFailures: { any } = {}
local snapshotHistory: { any } = {}
local counts = {
	workflows = 0,
	stages = 0,
	transitions = 0,
	decisions = 0,
	audits = 0,
	workflowSnapshots = 0,
}

local function boundedInsert(list: { any }, value: any, limit: number)
	table.insert(list, value)
	while #list > limit do
		table.remove(list, 1)
	end
end

local function hasAll(map: { [string]: any }, values: any, label: string): (boolean, string?)
	for _, id in ipairs(values) do
		if map[id] == nil then
			return false, "invalid " .. label .. " reference"
		end
	end
	return true, nil
end

local function hasAllForWorkflow(
	map: { [string]: any },
	values: any,
	label: string,
	workflowId: string
): (boolean, string?)
	local ok, reason = hasAll(map, values, label)
	if not ok then
		return false, reason
	end
	for _, id in ipairs(values) do
		if map[id].workflowId ~= workflowId then
			return false, "invalid " .. label .. " parent reference"
		end
	end
	return true, nil
end

local function register(
	map: { [string]: any },
	id: string,
	schema: any,
	limit: number,
	duplicate: string,
	limitReason: string,
	countKey: string
): (boolean, string?)
	if schemaIds[id] == true then
		return false, duplicate
	end
	if counts[countKey] >= limit then
		return false, limitReason
	end
	schemaIds[id] = true
	map[id] = Serialization.deepCopy(schema)
	counts[countKey] += 1
	return true, nil
end

function State.registerWorkflow(schema: any): (boolean, string?)
	local ok, reason = Validation.workflow(schema)
	if not ok then
		return false, reason
	end
	if workflowNames[schema.workflowName] == true then
		return false, "duplicate workflowName"
	end
	for _, group in ipairs({
		{ stages, schema.stageIds, "stage" },
		{ transitions, schema.transitionIds, "transition" },
		{ decisions, schema.decisionIds, "decision" },
		{ audits, schema.auditIds, "audit" },
		{ workflowSnapshots, schema.snapshotIds, "workflow snapshot" },
	}) do
		local groupOk, groupReason = hasAll(group[1], group[2], group[3])
		if not groupOk then
			return false, groupReason
		end
	end
	local registered, registerReason = register(
		workflows,
		schema.workflowId,
		schema,
		Types.Limits.MaxWorkflows,
		"duplicate workflowId",
		"workflow limit exceeded",
		"workflows"
	)
	if registered then
		workflowNames[schema.workflowName] = true
	end
	return registered, registerReason
end

function State.registerStage(schema: any): (boolean, string?)
	local ok, reason = Validation.stage(schema)
	if not ok then
		return false, reason
	end
	local parentOk, parentReason = hasAll(workflows, { schema.workflowId }, "workflow")
	if not parentOk then
		return false, parentReason
	end
	local orderKey = schema.workflowId .. ":" .. tostring(schema.stageOrder)
	local ownerKey = schema.workflowId .. ":" .. schema.owner
	if stageOrders[orderKey] == true then
		return false, "duplicate stageOrder"
	end
	if stageOwners[ownerKey] == true then
		return false, "duplicate ownership"
	end
	local registered, registerReason = register(
		stages,
		schema.stageId,
		schema,
		Types.Limits.MaxStages,
		"duplicate stageId",
		"stage limit exceeded",
		"stages"
	)
	if registered then
		stageOrders[orderKey] = true
		stageOwners[ownerKey] = true
	end
	return registered, registerReason
end

function State.registerTransition(schema: any): (boolean, string?)
	local ok, reason = Validation.transition(schema)
	if not ok then
		return false, reason
	end
	local parentOk, parentReason = hasAll(workflows, { schema.workflowId }, "workflow")
	if not parentOk then
		return false, parentReason
	end
	local stagesOk, stagesReason = hasAllForWorkflow(
		stages,
		{ schema.fromStageId, schema.toStageId },
		"stage",
		schema.workflowId
	)
	if not stagesOk then
		return false, stagesReason
	end
	if stages[schema.fromStageId].stageOrder >= stages[schema.toStageId].stageOrder then
		return false, "invalid stage ordering"
	end
	local decisionsOk, decisionsReason =
		hasAllForWorkflow(decisions, schema.decisionIds, "decision", schema.workflowId)
	if not decisionsOk then
		return false, decisionsReason
	end
	return register(
		transitions,
		schema.transitionId,
		schema,
		Types.Limits.MaxTransitions,
		"duplicate transitionId",
		"transition limit exceeded",
		"transitions"
	)
end

function State.registerDecision(schema: any): (boolean, string?)
	local ok, reason = Validation.decision(schema)
	if not ok then
		return false, reason
	end
	local parentOk, parentReason = hasAll(workflows, { schema.workflowId }, "workflow")
	if not parentOk then
		return false, parentReason
	end
	local transitionOk, transitionReason =
		hasAllForWorkflow(transitions, { schema.transitionId }, "transition", schema.workflowId)
	if not transitionOk then
		return false, transitionReason
	end
	return register(
		decisions,
		schema.decisionId,
		schema,
		Types.Limits.MaxDecisions,
		"duplicate decisionId",
		"decision limit exceeded",
		"decisions"
	)
end

function State.registerAudit(schema: any): (boolean, string?)
	local ok, reason = Validation.audit(schema)
	if not ok then
		return false, reason
	end
	local parentOk, parentReason = hasAll(workflows, { schema.workflowId }, "workflow")
	if not parentOk then
		return false, parentReason
	end
	for _, group in ipairs({
		{ stages, schema.stageIds, "stage" },
		{ transitions, schema.transitionIds, "transition" },
		{ decisions, schema.decisionIds, "decision" },
	}) do
		local groupOk, groupReason =
			hasAllForWorkflow(group[1], group[2], group[3], schema.workflowId)
		if not groupOk then
			return false, groupReason
		end
	end
	return register(
		audits,
		schema.auditId,
		schema,
		Types.Limits.MaxAudits,
		"duplicate auditId",
		"audit limit exceeded",
		"audits"
	)
end

function State.registerWorkflowSnapshot(schema: any): (boolean, string?)
	local ok, reason = Validation.workflowSnapshot(schema)
	if not ok then
		return false, reason
	end
	local parentOk, parentReason = hasAll(workflows, { schema.workflowId }, "workflow")
	if not parentOk then
		return false, parentReason
	end
	for _, group in ipairs({
		{ stages, schema.stageIds, "stage" },
		{ transitions, schema.transitionIds, "transition" },
		{ decisions, schema.decisionIds, "decision" },
	}) do
		local groupOk, groupReason =
			hasAllForWorkflow(group[1], group[2], group[3], schema.workflowId)
		if not groupOk then
			return false, groupReason
		end
	end
	return register(
		workflowSnapshots,
		schema.workflowSnapshotId,
		schema,
		Types.Limits.MaxWorkflowSnapshots,
		"duplicate workflowSnapshotId",
		"workflow snapshot limit exceeded",
		"workflowSnapshots"
	)
end

function State.recordValidationFailure(reason: string, payload: any?)
	boundedInsert(
		validationFailures,
		{ reason = reason, payload = Serialization.diagnosticCopy(payload) },
		Types.Limits.MaxValidationFailures
	)
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
		workflows = workflows,
		stages = stages,
		transitions = transitions,
		decisions = decisions,
		audits = audits,
		workflowSnapshots = workflowSnapshots,
		validationFailures = validationFailures,
		snapshotHistory = snapshotHistory,
		counts = {
			workflows = counts.workflows,
			stages = counts.stages,
			transitions = counts.transitions,
			decisions = counts.decisions,
			audits = counts.audits,
			workflowSnapshots = counts.workflowSnapshots,
			validationFailures = #validationFailures,
			snapshots = #snapshotHistory,
		},
	})
end

function State.clear()
	table.clear(workflows)
	table.clear(stages)
	table.clear(transitions)
	table.clear(decisions)
	table.clear(audits)
	table.clear(workflowSnapshots)
	table.clear(workflowNames)
	table.clear(stageOrders)
	table.clear(stageOwners)
	table.clear(schemaIds)
	table.clear(validationFailures)
	table.clear(snapshotHistory)
	counts.workflows = 0
	counts.stages = 0
	counts.transitions = 0
	counts.decisions = 0
	counts.audits = 0
	counts.workflowSnapshots = 0
end

return State
