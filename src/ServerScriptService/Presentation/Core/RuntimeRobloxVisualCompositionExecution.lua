--!strict

local Budgets = require(script.Parent.VisualExecutionBudgets)
local Certification = require(script.Parent.VisualExecutionCertification)
local Evidence = require(script.Parent.VisualExecutionEvidence)
local Governance = require(script.Parent.VisualExecutionGovernance)
local Metrics = require(script.Parent.VisualExecutionMetrics)
local Profiler = require(script.Parent.VisualExecutionProfiler)
local Serialization = require(script.Parent.PresentationSerialization)
local Types = require(script.Parent.PresentationTypes)

local Runtime = {}
local shutdown = false
local executionOrdinal = 0
local patchOrdinal = 0
local sessions = {}
local patches = {}
local queue = {}
local failures = {}
local replayHistory = {}
local recoveryRecords = {}
local committedRevisions = {}

local operationOrder = {
	RemoveNode = 10,
	AddNode = 20,
	MoveNode = 30,
	ReorderChildren = 40,
	UpdateNode = 50,
	UpdateLayout = 60,
	UpdateConstraints = 70,
	UpdateResponsiveVariant = 80,
	UpdateStyleReference = 90,
	UpdateThemeReference = 100,
	UpdateTypographyReference = 110,
	UpdateAssetReference = 120,
	UpdateLocalizationBinding = 130,
	UpdateAccessibilityMetadata = 140,
	UpdateLayer = 150,
	UpdateRegion = 160,
	UpdateVisibility = 170,
	UpdateStateVariant = 180,
	BindCompositionMetadata = 190,
	ReleaseCompositionMetadata = 200,
}

local counters = {
	executionSessionsCreated = 0,
	diffsGenerated = 0,
	diffsRejected = 0,
	patchPlansCreated = 0,
	patchPlansCommitted = 0,
	patchPlansCancelled = 0,
	patchPlansSuperseded = 0,
	patchPlansFailed = 0,
	operationsGenerated = 0,
	operationsCoalesced = 0,
	operationsEliminated = 0,
	dependencyEdges = 0,
	dependencyFailures = 0,
	batchesCreated = 0,
	staleRevisionRejections = 0,
	revisionConflicts = 0,
	transactionsCommitted = 0,
	transactionsAborted = 0,
	rollbacksPlanned = 0,
	rollbacksCompleted = 0,
	rollbackFailures = 0,
	recoveryRuns = 0,
	replayChecks = 0,
	replayMismatches = 0,
	queuePressureEvents = 0,
	budgetFailures = 0,
	failures = 0,
	lastFailure = nil :: any?,
}

local function copy(value: any): any
	return Serialization.deepCopy(value)
end

local function stableString(value: any): string
	if type(value) ~= "table" then
		return tostring(value)
	end
	local keys = {}
	for key in pairs(value) do
		keys[#keys + 1] = tostring(key)
	end
	table.sort(keys)
	local parts = {}
	for _, key in ipairs(keys) do
		parts[#parts + 1] = key .. "=" .. stableString(value[key])
	end
	return "{" .. table.concat(parts, ",") .. "}"
end

local function equal(left: any, right: any): boolean
	return stableString(left) == stableString(right)
end

local function fail(code: string, message: string, payload: any?)
	local failure = {
		code = code,
		message = message,
		payload = Serialization.diagnosticCopy(payload or {}),
		sequence = #failures + 1,
	}
	failures[#failures + 1] = failure
	counters.failures += 1
	counters.lastFailure = failure
	Metrics.increment("runtimeFailures")
	Evidence.record("FailureRecorded", failure)
	return { ok = false, code = code, message = message }
end

local function ensureOpen(payload: any?)
	if shutdown then
		return fail(
			Types.VisualExecutionFailureType.RuntimeShutdown,
			"runtime is shut down",
			payload
		)
	end
	return nil
end

local function validateSerializable(payload: any)
	local ok, reason = Serialization.validateSerializable(payload)
	if not ok then
		return fail(
			Types.VisualExecutionFailureType.UnsafePayload,
			reason or "unsafe payload",
			payload
		)
	end
	return nil
end

local function isString(value: any): boolean
	return type(value) == "string" and value ~= ""
end

local function isRevision(value: any): boolean
	return type(value) == "number" and value >= 0 and value % 1 == 0
end

local function nodesById(plan: any)
	local map = {}
	for _, node in ipairs(plan.orderedNodes or plan.nodes or {}) do
		if isString(node.nodeId) then
			map[node.nodeId] = node
		end
	end
	return map
end

local function makeOperation(
	kind: string,
	nodeId: string,
	sourceRevision: number,
	targetRevision: number,
	before: any,
	after: any,
	ordinal: number
)
	return {
		operationId = "visual.op." .. tostring(ordinal),
		operationKind = kind,
		nodeId = nodeId,
		sourceRevision = sourceRevision,
		targetRevision = targetRevision,
		before = copy(before or {}),
		after = copy(after or {}),
		dependencyIds = {},
		reversible = true,
		rollbackStrategy = Types.VisualRollbackStrategy.InverseOperations,
		executionOrdinal = ordinal,
		idempotencyKey = "visual.execution."
			.. tostring(targetRevision)
			.. "."
			.. kind
			.. "."
			.. nodeId,
		provenance = { diffEngineVersion = "phase184.1", patchPlannerVersion = "phase184.1" },
	}
end

local function sortOperations(operations: { any })
	table.sort(operations, function(left, right)
		local leftOrder = operationOrder[left.operationKind] or 999
		local rightOrder = operationOrder[right.operationKind] or 999
		if leftOrder ~= rightOrder then
			return leftOrder < rightOrder
		end
		if left.nodeId ~= right.nodeId then
			return left.nodeId < right.nodeId
		end
		return left.operationId < right.operationId
	end)
	for index, operation in ipairs(operations) do
		operation.executionOrdinal = index
		operation.operationId = "visual.op." .. tostring(index)
		operation.idempotencyKey = "visual.execution."
			.. tostring(operation.targetRevision)
			.. "."
			.. operation.operationKind
			.. "."
			.. operation.nodeId
	end
end

local function addDependency(operation: any, dependencyId: string)
	for _, existing in ipairs(operation.dependencyIds) do
		if existing == dependencyId then
			return
		end
	end
	operation.dependencyIds[#operation.dependencyIds + 1] = dependencyId
end

local function buildDependencyGraph(operations: { any }, targetNodes: any, sourceNodes: any)
	local byNode = {}
	local byOperation = {}
	local edges = {}
	for _, operation in ipairs(operations) do
		byNode[operation.nodeId .. ":" .. operation.operationKind] = operation
		byOperation[operation.operationId] = operation
	end
	for _, operation in ipairs(operations) do
		if operation.operationKind == Types.VisualOperationKind.AddNode then
			local node = targetNodes[operation.nodeId]
			local parentAdd = node
				and byNode[tostring(node.parentNodeId) .. ":" .. Types.VisualOperationKind.AddNode]
			if parentAdd ~= nil then
				addDependency(operation, parentAdd.operationId)
			end
		elseif operation.operationKind == Types.VisualOperationKind.RemoveNode then
			for _, child in pairs(sourceNodes) do
				if child.parentNodeId == operation.nodeId then
					local childRemove =
						byNode[child.nodeId .. ":" .. Types.VisualOperationKind.RemoveNode]
					if childRemove ~= nil then
						addDependency(operation, childRemove.operationId)
					end
				end
			end
		else
			local add = byNode[operation.nodeId .. ":" .. Types.VisualOperationKind.AddNode]
			if add ~= nil and add.operationId ~= operation.operationId then
				addDependency(operation, add.operationId)
			end
		end
	end
	for _, operation in ipairs(operations) do
		for _, dependencyId in ipairs(operation.dependencyIds) do
			if byOperation[dependencyId] == nil then
				return nil,
					fail(
						Types.VisualExecutionFailureType.MissingDependency,
						"unknown dependency",
						operation
					)
			end
			if dependencyId == operation.operationId then
				return nil,
					fail(
						Types.VisualExecutionFailureType.DependencyCycle,
						"self dependency",
						operation
					)
			end
			edges[#edges + 1] = { from = dependencyId, to = operation.operationId }
		end
	end
	return { nodes = copy(operations), edges = edges }, nil
end

local function buildBatches(operations: { any })
	local batches = {}
	local batch = nil
	for _, operation in ipairs(operations) do
		if
			batch == nil
			or #batch.operationIds >= Types.VisualExecutionLimits.MaxOperationsPerBatch
		then
			batch = {
				batchId = "visual.batch." .. tostring(#batches + 1),
				sequence = #batches + 1,
				queueState = Types.VisualQueueState.Waiting,
				operationIds = {},
			}
			batches[#batches + 1] = batch
		end
		batch.operationIds[#batch.operationIds + 1] = operation.operationId
	end
	if #batches > Types.VisualExecutionLimits.MaxBatchesPerPatch then
		return nil, fail(Types.VisualExecutionFailureType.BatchOverflow, "batch limit exceeded", {})
	end
	return batches, nil
end

local function buildRollback(operations: { any })
	local rollback = {}
	for index = #operations, 1, -1 do
		local operation = operations[index]
		local inverseKind = operation.operationKind
		local strategy = Types.VisualRollbackStrategy.InverseOperations
		if operation.operationKind == Types.VisualOperationKind.AddNode then
			inverseKind = Types.VisualOperationKind.RemoveNode
		elseif operation.operationKind == Types.VisualOperationKind.RemoveNode then
			inverseKind = Types.VisualOperationKind.AddNode
		elseif
			operation.operationKind == Types.VisualOperationKind.MoveNode
			or operation.operationKind == Types.VisualOperationKind.ReorderChildren
		then
			strategy = Types.VisualRollbackStrategy.RebuildPreviousRevision
		end
		rollback[#rollback + 1] = {
			operationId = "visual.rollback." .. tostring(#rollback + 1),
			operationKind = inverseKind,
			nodeId = operation.nodeId,
			before = copy(operation.after),
			after = copy(operation.before),
			reversible = strategy == Types.VisualRollbackStrategy.InverseOperations,
			rollbackStrategy = strategy,
		}
	end
	return rollback
end
local function validateSessionInput(input: any)
	if type(input) ~= "table" then
		return fail(
			Types.VisualExecutionFailureType.ValidationFailure,
			"session input must be a table",
			input
		)
	end
	local unsafe = validateSerializable(input)
	if unsafe ~= nil then
		return unsafe
	end
	if
		not isString(input.visualExecutionSessionId)
		or not isString(input.compositionInstanceId)
		or not isString(input.robloxRenderingSessionId)
	then
		return fail(
			Types.VisualExecutionFailureType.ValidationFailure,
			"session identity fields are required",
			input
		)
	end
	if not isRevision(input.sourceRevision) or not isRevision(input.targetRevision) then
		return fail(
			Types.VisualExecutionFailureType.InvalidRevisionTransition,
			"revision fields must be non-negative integers",
			input
		)
	end
	if input.targetRevision ~= input.sourceRevision + 1 then
		return fail(
			Types.VisualExecutionFailureType.InvalidRevisionTransition,
			"target revision must strictly follow source revision",
			input
		)
	end
	return nil
end

function Runtime.createExecutionSession(input: any)
	local closed = ensureOpen(input)
	if closed ~= nil then
		return closed
	end
	local invalid = validateSessionInput(input)
	if invalid ~= nil then
		return invalid
	end
	if sessions[input.visualExecutionSessionId] ~= nil then
		return fail(
			Types.VisualExecutionFailureType.DuplicateExecutionSession,
			"duplicate execution session",
			input
		)
	end
	executionOrdinal += 1
	local session = {
		visualExecutionSessionId = input.visualExecutionSessionId,
		compositionInstanceId = input.compositionInstanceId,
		robloxRenderingSessionId = input.robloxRenderingSessionId,
		sourceRevision = input.sourceRevision,
		targetRevision = input.targetRevision,
		executionState = Types.VisualExecutionState.Created,
		patchPlanId = input.patchPlanId or ("visual.patch." .. tostring(executionOrdinal)),
		executionOrdinal = executionOrdinal,
		runtimeMetadata = copy(input.runtimeMetadata or {}),
	}
	sessions[session.visualExecutionSessionId] = copy(session)
	committedRevisions[session.compositionInstanceId] = committedRevisions[session.compositionInstanceId]
		or session.sourceRevision
	counters.executionSessionsCreated += 1
	Metrics.increment("executionSessionsCreated")
	Evidence.record("ExecutionSessionCreated", session)
	return { ok = true, code = "Ok", session = copy(session) }
end

function Runtime.closeExecutionSession(visualExecutionSessionId: string)
	local session = sessions[visualExecutionSessionId]
	if session == nil then
		return fail(
			Types.VisualExecutionFailureType.UnknownExecutionSession,
			"unknown execution session",
			{ visualExecutionSessionId = visualExecutionSessionId }
		)
	end
	session.executionState = Types.VisualExecutionState.Closed
	return { ok = true, code = "Ok", session = copy(session) }
end

function Runtime.buildDiff(sourcePlan: any, targetPlan: any)
	local closed = ensureOpen({ sourcePlan = sourcePlan, targetPlan = targetPlan })
	if closed ~= nil then
		return closed
	end
	local unsafe = validateSerializable({ sourcePlan = sourcePlan, targetPlan = targetPlan })
	if unsafe ~= nil then
		return unsafe
	end
	if type(sourcePlan) ~= "table" or type(targetPlan) ~= "table" then
		counters.diffsRejected += 1
		return fail(
			Types.VisualExecutionFailureType.InvalidDiff,
			"source and target plans are required",
			{}
		)
	end
	local sourceRevision = sourcePlan.revision or 0
	local targetRevision = targetPlan.revision or sourceRevision + 1
	if targetRevision ~= sourceRevision + 1 then
		counters.diffsRejected += 1
		return fail(
			Types.VisualExecutionFailureType.InvalidRevisionTransition,
			"target revision must strictly follow source revision",
			{}
		)
	end
	local sourceNodes = nodesById(sourcePlan)
	local targetNodes = nodesById(targetPlan)
	local operations = {}
	local ordinal = 0
	for nodeId, sourceNode in pairs(sourceNodes) do
		if targetNodes[nodeId] == nil then
			ordinal += 1
			operations[#operations + 1] = makeOperation(
				Types.VisualOperationKind.RemoveNode,
				nodeId,
				sourceRevision,
				targetRevision,
				sourceNode,
				{},
				ordinal
			)
		end
	end
	for nodeId, targetNode in pairs(targetNodes) do
		local sourceNode = sourceNodes[nodeId]
		if sourceNode == nil then
			ordinal += 1
			operations[#operations + 1] = makeOperation(
				Types.VisualOperationKind.AddNode,
				nodeId,
				sourceRevision,
				targetRevision,
				{},
				targetNode,
				ordinal
			)
		else
			local fields = {
				{ "parentNodeId", Types.VisualOperationKind.MoveNode },
				{ "order", Types.VisualOperationKind.ReorderChildren },
				{ "layout", Types.VisualOperationKind.UpdateLayout },
				{ "constraints", Types.VisualOperationKind.UpdateConstraints },
				{ "responsiveVariants", Types.VisualOperationKind.UpdateResponsiveVariant },
				{ "visibility", Types.VisualOperationKind.UpdateVisibility },
				{ "states", Types.VisualOperationKind.UpdateStateVariant },
				{ "styleReference", Types.VisualOperationKind.UpdateStyleReference },
				{ "themeReference", Types.VisualOperationKind.UpdateThemeReference },
				{ "typographyReference", Types.VisualOperationKind.UpdateTypographyReference },
				{ "assetReference", Types.VisualOperationKind.UpdateAssetReference },
				{ "localizationSlot", Types.VisualOperationKind.UpdateLocalizationBinding },
				{ "accessibility", Types.VisualOperationKind.UpdateAccessibilityMetadata },
				{ "layerKind", Types.VisualOperationKind.UpdateLayer },
				{ "regionKind", Types.VisualOperationKind.UpdateRegion },
			}
			for _, pair in ipairs(fields) do
				local field = pair[1]
				if not equal(sourceNode[field], targetNode[field]) then
					ordinal += 1
					operations[#operations + 1] = makeOperation(
						pair[2],
						nodeId,
						sourceRevision,
						targetRevision,
						{ [field] = sourceNode[field] },
						{ [field] = targetNode[field] },
						ordinal
					)
				end
			end
		end
	end
	sortOperations(operations)
	local graph, dependencyFailure = buildDependencyGraph(operations, targetNodes, sourceNodes)
	if dependencyFailure ~= nil then
		counters.dependencyFailures += 1
		return dependencyFailure
	end
	counters.diffsGenerated += 1
	counters.operationsGenerated += #operations
	counters.dependencyEdges += #(graph :: any).edges
	Metrics.increment("diffsGenerated")
	Metrics.increment("operationsGenerated", #operations)
	Evidence.record("DiffCompleted", { operationCount = #operations })
	return {
		ok = true,
		code = "Ok",
		diff = {
			sourceRevision = sourceRevision,
			targetRevision = targetRevision,
			operations = copy(operations),
			dependencyGraph = graph,
			structuralFingerprint = stableString({ sourceRevision, targetRevision, operations }),
		},
	}
end

function Runtime.normalizeDiff(diff: any)
	if type(diff) ~= "table" or type(diff.operations) ~= "table" then
		return fail(
			Types.VisualExecutionFailureType.InvalidDiff,
			"diff operations are required",
			diff
		)
	end
	local normalized = copy(diff)
	sortOperations(normalized.operations)
	return { ok = true, code = "Ok", diff = normalized }
end
function Runtime.createPatchPlan(input: any)
	local closed = ensureOpen(input)
	if closed ~= nil then
		return closed
	end
	if type(input) ~= "table" or type(input.session) ~= "table" or type(input.diff) ~= "table" then
		return fail(
			Types.VisualExecutionFailureType.ValidationFailure,
			"session and diff are required",
			input
		)
	end
	local session = sessions[input.session.visualExecutionSessionId]
	if session == nil then
		return fail(
			Types.VisualExecutionFailureType.UnknownExecutionSession,
			"unknown execution session",
			input
		)
	end
	if patches[session.patchPlanId] ~= nil then
		return fail(
			Types.VisualExecutionFailureType.DuplicatePatchPlan,
			"duplicate patch plan",
			session
		)
	end
	if #input.diff.operations > Types.VisualExecutionLimits.MaxOperationsPerPatch then
		counters.budgetFailures += 1
		return fail(
			Types.VisualExecutionFailureType.LimitExceeded,
			"operation limit exceeded",
			input
		)
	end
	local batches, batchFailure = buildBatches(input.diff.operations)
	if batchFailure ~= nil then
		return batchFailure
	end
	local rollbackPlan = buildRollback(input.diff.operations)
	patchOrdinal += 1
	local patch = {
		patchPlanId = session.patchPlanId,
		visualExecutionSessionId = session.visualExecutionSessionId,
		compositionInstanceId = session.compositionInstanceId,
		sourceRevision = session.sourceRevision,
		targetRevision = session.targetRevision,
		operations = copy(input.diff.operations),
		dependencyGraph = copy(input.diff.dependencyGraph),
		batchPlan = batches,
		rollbackPlan = rollbackPlan,
		checksumMetadata = { structuralFingerprint = input.diff.structuralFingerprint },
		createdOrdinal = patchOrdinal,
		state = Types.VisualPatchState.Created,
		revisionFence = {
			expectedActiveRevision = session.sourceRevision,
			targetRevision = session.targetRevision,
		},
		transaction = { state = Types.VisualTransactionState.New },
		supersessionState = "Current",
	}
	patches[patch.patchPlanId] = copy(patch)
	sessions[session.visualExecutionSessionId].executionState = Types.VisualExecutionState.Planned
	counters.patchPlansCreated += 1
	counters.batchesCreated += #batches
	counters.rollbacksPlanned += 1
	Metrics.increment("patchPlansCreated")
	Evidence.record("PatchPlanCreated", patch)
	return { ok = true, code = "Ok", patchPlan = copy(patch) }
end

function Runtime.validatePatchPlan(patchPlanId: string)
	local patch = patches[patchPlanId]
	if patch == nil then
		return fail(
			Types.VisualExecutionFailureType.UnknownPatchPlan,
			"unknown patch plan",
			{ patchPlanId = patchPlanId }
		)
	end
	local ids = {}
	for _, operation in ipairs(patch.operations) do
		if not Types.isVisualOperationKind(operation.operationKind) then
			return fail(
				Types.VisualExecutionFailureType.UnsupportedOperation,
				"unsupported operation",
				operation
			)
		end
		if ids[operation.operationId] then
			return fail(
				Types.VisualExecutionFailureType.DuplicateOperation,
				"duplicate operation",
				operation
			)
		end
		ids[operation.operationId] = true
	end
	for _, edge in ipairs(patch.dependencyGraph.edges or {}) do
		if not ids[edge.from] or not ids[edge.to] then
			return fail(
				Types.VisualExecutionFailureType.MissingDependency,
				"dependency edge references unknown operation",
				edge
			)
		end
	end
	patch.state = Types.VisualPatchState.Validated
	Evidence.record("PatchPlanValidated", patch)
	return { ok = true, code = "Ok", patchPlan = copy(patch) }
end

function Runtime.sealPatchPlan(patchPlanId: string)
	local validation = Runtime.validatePatchPlan(patchPlanId)
	if not validation.ok then
		return validation
	end
	local patch = patches[patchPlanId]
	patch.state = Types.VisualPatchState.Sealed
	Evidence.record("PatchPlanSealed", patch)
	return { ok = true, code = "Ok", patchPlan = copy(patch) }
end

function Runtime.enqueuePatch(patchPlanId: string)
	local patch = patches[patchPlanId]
	if patch == nil then
		return fail(
			Types.VisualExecutionFailureType.UnknownPatchPlan,
			"unknown patch plan",
			{ patchPlanId = patchPlanId }
		)
	end
	if patch.state ~= Types.VisualPatchState.Sealed then
		return fail(
			Types.VisualExecutionFailureType.PatchNotSealed,
			"patch must be sealed before queue admission",
			patch
		)
	end
	if #queue >= Types.VisualExecutionLimits.MaxQueuedPatchPlans then
		counters.queuePressureEvents += 1
		return fail(Types.VisualExecutionFailureType.QueueOverflow, "queue limit exceeded", patch)
	end
	patch.state = Types.VisualPatchState.Queued
	queue[#queue + 1] = patchPlanId
	Evidence.record("PatchQueued", patch)
	return { ok = true, code = "Ok", patchPlan = copy(patch) }
end

function Runtime.scheduleNext()
	if #queue == 0 then
		return { ok = true, code = "Ok", patchPlan = nil }
	end
	table.sort(queue)
	local patchPlanId = table.remove(queue, 1)
	local patch = patches[patchPlanId]
	patch.state = Types.VisualPatchState.Preparing
	local session = sessions[patch.visualExecutionSessionId]
	if session ~= nil then
		session.executionState = Types.VisualExecutionState.Scheduled
	end
	Evidence.record("PatchScheduled", patch)
	return { ok = true, code = "Ok", patchPlan = copy(patch) }
end

function Runtime.preparePatch(patchPlanId: string)
	local patch = patches[patchPlanId]
	if patch == nil then
		return fail(
			Types.VisualExecutionFailureType.UnknownPatchPlan,
			"unknown patch plan",
			{ patchPlanId = patchPlanId }
		)
	end
	if patch.state == Types.VisualPatchState.Cancelled then
		return fail(
			Types.VisualExecutionFailureType.PatchCancelled,
			"cancelled patch cannot prepare",
			patch
		)
	end
	if patch.supersessionState ~= "Current" then
		return fail(
			Types.VisualExecutionFailureType.PatchSuperseded,
			"superseded patch cannot prepare",
			patch
		)
	end
	if
		committedRevisions[patch.compositionInstanceId]
		~= patch.revisionFence.expectedActiveRevision
	then
		counters.staleRevisionRejections += 1
		Evidence.record("StaleRevisionRejected", patch)
		return fail(
			Types.VisualExecutionFailureType.StaleRevision,
			"revision fence does not match active revision",
			patch
		)
	end
	patch.state = Types.VisualPatchState.Preparing
	patch.transaction.state = Types.VisualTransactionState.Prepared
	Evidence.record("PrepareCompleted", patch)
	return { ok = true, code = "Ok", patchPlan = copy(patch) }
end

function Runtime.markApplied(patchPlanId: string)
	local patch = patches[patchPlanId]
	if patch == nil then
		return fail(
			Types.VisualExecutionFailureType.UnknownPatchPlan,
			"unknown patch plan",
			{ patchPlanId = patchPlanId }
		)
	end
	if patch.transaction.state ~= Types.VisualTransactionState.Prepared then
		return fail(
			Types.VisualExecutionFailureType.InvalidTransactionState,
			"patch must be prepared before apply metadata",
			patch
		)
	end
	patch.state = Types.VisualPatchState.Applying
	patch.transaction.state = Types.VisualTransactionState.Applied
	Evidence.record("ApplyMetadataRecorded", patch)
	return { ok = true, code = "Ok", patchPlan = copy(patch) }
end

function Runtime.commitPatch(patchPlanId: string)
	local patch = patches[patchPlanId]
	if patch == nil then
		return fail(
			Types.VisualExecutionFailureType.UnknownPatchPlan,
			"unknown patch plan",
			{ patchPlanId = patchPlanId }
		)
	end
	if
		patch.state == Types.VisualPatchState.Committed
		or patch.transaction.state == Types.VisualTransactionState.Committed
	then
		return fail(
			Types.VisualExecutionFailureType.PatchAlreadyCommitted,
			"patch already committed",
			patch
		)
	end
	if patch.state == Types.VisualPatchState.Cancelled then
		return fail(
			Types.VisualExecutionFailureType.PatchCancelled,
			"cancelled patch cannot commit",
			patch
		)
	end
	if patch.supersessionState ~= "Current" then
		return fail(
			Types.VisualExecutionFailureType.PatchSuperseded,
			"superseded patch cannot commit",
			patch
		)
	end
	if patch.transaction.state ~= Types.VisualTransactionState.Applied then
		return fail(
			Types.VisualExecutionFailureType.InvalidTransactionState,
			"patch must be applied before commit",
			patch
		)
	end
	if
		committedRevisions[patch.compositionInstanceId]
		~= patch.revisionFence.expectedActiveRevision
	then
		counters.staleRevisionRejections += 1
		return fail(
			Types.VisualExecutionFailureType.StaleRevision,
			"stale revision at commit",
			patch
		)
	end
	patch.state = Types.VisualPatchState.Committed
	patch.transaction.state = Types.VisualTransactionState.Committed
	committedRevisions[patch.compositionInstanceId] = patch.targetRevision
	local session = sessions[patch.visualExecutionSessionId]
	if session ~= nil then
		session.executionState = Types.VisualExecutionState.Completed
	end
	counters.patchPlansCommitted += 1
	counters.transactionsCommitted += 1
	Metrics.increment("patchPlansCommitted")
	Evidence.record("PatchCommitted", patch)
	return { ok = true, code = "Ok", patchPlan = copy(patch) }
end
function Runtime.abortPatch(patchPlanId: string)
	local patch = patches[patchPlanId]
	if patch == nil then
		return fail(
			Types.VisualExecutionFailureType.UnknownPatchPlan,
			"unknown patch plan",
			{ patchPlanId = patchPlanId }
		)
	end
	if patch.state == Types.VisualPatchState.Committed then
		return fail(
			Types.VisualExecutionFailureType.InvalidTransactionState,
			"committed patch cannot abort",
			patch
		)
	end
	patch.state = Types.VisualPatchState.Aborted
	patch.transaction.state = Types.VisualTransactionState.Aborted
	counters.transactionsAborted += 1
	Evidence.record("PatchAborted", patch)
	return { ok = true, code = "Ok", patchPlan = copy(patch) }
end

function Runtime.cancelPatch(patchPlanId: string)
	local patch = patches[patchPlanId]
	if patch == nil then
		return fail(
			Types.VisualExecutionFailureType.UnknownPatchPlan,
			"unknown patch plan",
			{ patchPlanId = patchPlanId }
		)
	end
	if patch.state == Types.VisualPatchState.Committed then
		return fail(
			Types.VisualExecutionFailureType.InvalidTransactionState,
			"committed patch cannot cancel",
			patch
		)
	end
	patch.state = Types.VisualPatchState.Cancelled
	counters.patchPlansCancelled += 1
	Evidence.record("PatchCancelled", patch)
	return { ok = true, code = "Ok", patchPlan = copy(patch) }
end

function Runtime.supersedePatch(patchPlanId: string, replacementPatchPlanId: string?)
	local patch = patches[patchPlanId]
	if patch == nil then
		return fail(
			Types.VisualExecutionFailureType.UnknownPatchPlan,
			"unknown patch plan",
			{ patchPlanId = patchPlanId }
		)
	end
	if patch.state == Types.VisualPatchState.Committed then
		return fail(
			Types.VisualExecutionFailureType.InvalidTransactionState,
			"committed patch cannot be superseded",
			patch
		)
	end
	patch.state = Types.VisualPatchState.Superseded
	patch.supersessionState = replacementPatchPlanId and "Replaced" or "Superseded"
	patch.replacementPatchPlanId = replacementPatchPlanId
	counters.patchPlansSuperseded += 1
	Evidence.record("PatchSuperseded", patch)
	return { ok = true, code = "Ok", patchPlan = copy(patch) }
end

function Runtime.recoverPatch(patchPlanId: string)
	local patch = patches[patchPlanId]
	if patch == nil then
		return fail(
			Types.VisualExecutionFailureType.UnknownPatchPlan,
			"unknown patch plan",
			{ patchPlanId = patchPlanId }
		)
	end
	local decision = Types.VisualRecoveryDecision.Resume
	if patch.transaction.state == Types.VisualTransactionState.Applied then
		decision = Types.VisualRecoveryDecision.Rollback
	elseif patch.state == Types.VisualPatchState.Superseded then
		decision = Types.VisualRecoveryDecision.Supersede
	elseif patch.state == Types.VisualPatchState.Failed then
		decision = Types.VisualRecoveryDecision.Abort
	end
	local record = { patchPlanId = patchPlanId, decision = decision, state = patch.state }
	recoveryRecords[#recoveryRecords + 1] = record
	counters.recoveryRuns += 1
	Evidence.record("RecoveryResolved", record)
	return { ok = true, code = "Ok", recovery = copy(record) }
end

function Runtime.buildRollbackPlan(patchPlanId: string)
	local patch = patches[patchPlanId]
	if patch == nil then
		return fail(
			Types.VisualExecutionFailureType.UnknownPatchPlan,
			"unknown patch plan",
			{ patchPlanId = patchPlanId }
		)
	end
	return { ok = true, code = "Ok", rollbackPlan = copy(patch.rollbackPlan) }
end

function Runtime.validateReplay(sourcePlan: any, targetPlan: any, originalPatchPlan: any)
	counters.replayChecks += 1
	local diff = Runtime.buildDiff(sourcePlan, targetPlan)
	if not diff.ok then
		return diff
	end
	local current = stableString(diff.diff.operations)
	local expected = stableString(originalPatchPlan.operations)
	if current ~= expected then
		counters.replayMismatches += 1
		Evidence.record("ReplayMismatch", { expected = expected, current = current })
		return fail(Types.VisualExecutionFailureType.ReplayMismatch, "replay output differed", {})
	end
	local record = { replayId = "visual.replay." .. tostring(#replayHistory + 1), ok = true }
	replayHistory[#replayHistory + 1] = record
	Evidence.record("ReplayValidated", record)
	return { ok = true, code = "Ok", replay = copy(record) }
end

function Runtime.inspectExecution(visualExecutionSessionId: string)
	return copy(sessions[visualExecutionSessionId])
end

function Runtime.inspectPatch(patchPlanId: string)
	return copy(patches[patchPlanId])
end

function Runtime.inspectOperations(patchPlanId: string)
	local patch = patches[patchPlanId]
	return patch and copy(patch.operations) or {}
end

function Runtime.inspectQueue()
	return copy(queue)
end

function Runtime.getDiagnostics()
	return Runtime.inspect()
end

function Runtime.inspect()
	Profiler.record(Types.RobloxVisualCompositionExecutionProviderName, "diagnosticsLatency", 0)
	return {
		providerName = Types.RobloxVisualCompositionExecutionProviderName,
		runtimeId = Types.RobloxVisualCompositionExecutionRuntimeId,
		capabilityId = Types.RobloxVisualCompositionExecutionCapabilityId,
		platform = Types.RobloxRenderingPlatform,
		executionSessions = copy(sessions),
		patchPlans = copy(patches),
		queue = copy(queue),
		replayHistory = copy(replayHistory),
		recoveryRecords = copy(recoveryRecords),
		evidence = Evidence.inspect(),
		metrics = Metrics.inspect(),
		profiler = Profiler.inspect(),
		budgets = Budgets.inspect(),
		governance = Governance.inspect(),
		certification = Certification.inspect(),
		counters = copy(counters),
		failures = copy(failures),
		robloxVisualCompositionExecutionPosture = {
			health = "Healthy",
			status = "ProductionCandidate",
			serverAuthoritative = true,
			deterministicDiff = true,
			deterministicPatchPlanning = true,
			deterministicOperationOrdering = true,
			revisionFenced = true,
			transactionalMetadata = true,
			noGuiMutation = true,
			noInstanceCreation = true,
			noRenderingExecution = true,
			noAssetLoading = true,
			noNetworking = true,
			noWorkspaceMutation = true,
			noPersistence = true,
			noClientAuthority = true,
			noAnalytics = true,
			noTelemetry = true,
		},
	}
end

function Runtime.getSnapshot()
	Profiler.record(Types.RobloxVisualCompositionExecutionProviderName, "snapshotLatency", 0)
	return {
		providerName = Types.RobloxVisualCompositionExecutionProviderName,
		robloxVisualCompositionExecutionSnapshot = copy(Runtime.inspect()),
	}
end

function Runtime.getMetrics()
	return Metrics.inspect()
end

function Runtime.getFailures()
	return copy(failures)
end

function Runtime.validate(): (boolean, string?)
	for _, patch in pairs(patches) do
		if not Types.isVisualPatchState(patch.state) then
			return false, "invalid patch state"
		end
		if not Types.isVisualTransactionState(patch.transaction.state) then
			return false, "invalid transaction state"
		end
	end
	return true, nil
end

function Runtime.reset()
	shutdown = false
	executionOrdinal = 0
	patchOrdinal = 0
	table.clear(sessions)
	table.clear(patches)
	table.clear(queue)
	table.clear(failures)
	table.clear(replayHistory)
	table.clear(recoveryRecords)
	table.clear(committedRevisions)
	for key in pairs(counters) do
		if key == "lastFailure" then
			counters[key] = nil
		else
			counters[key] = 0
		end
	end
	Evidence.clear()
	Metrics.clear()
	Profiler.clear()
	Evidence.record("RuntimeReset", {})
end

function Runtime.shutdown()
	shutdown = true
	Evidence.record("RuntimeShutdown", {})
end

Runtime.reset()

return Runtime
