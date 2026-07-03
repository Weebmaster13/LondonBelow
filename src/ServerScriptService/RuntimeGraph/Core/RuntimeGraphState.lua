--!strict
-- Central bounded state store for the Runtime Dependency Graph Foundation.

local Serialization = require(script.Parent.RuntimeGraphSerialization)
local Types = require(script.Parent.RuntimeGraphTypes)
local Validation = require(script.Parent.RuntimeGraphValidation)

local State = {}

local nodes: { [string]: any } = {}
local dependencies: { [string]: any } = {}
local capabilities: { [string]: any } = {}
local requirements: { [string]: any } = {}
local compatibilities: { [string]: any } = {}
local orderings: { [string]: any } = {}
local startupPlans: { [string]: any } = {}
local shutdownPlans: { [string]: any } = {}
local groups: { [string]: any } = {}
local validationRecords: { [string]: any } = {}
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

local function nodeExists(nodeId: string): boolean
	return nodes[nodeId] ~= nil
end

local function dependencyExists(dependencyId: string): boolean
	return dependencies[dependencyId] ~= nil
end

local function orderingExists(orderingId: string): boolean
	return orderings[orderingId] ~= nil
end

local function hasRequiredReverseDependency(sourceNodeId: string, targetNodeId: string): boolean
	for _, dependency in pairs(dependencies) do
		if
			dependency.dependencyKind == "Required"
			and dependency.sourceNodeId == targetNodeId
			and dependency.targetNodeId == sourceNodeId
		then
			return true
		end
	end
	return false
end

local function hasContradictoryOrdering(
	sourceNodeId: string,
	targetNodeId: string,
	orderingKind: string
): boolean
	for _, ordering in pairs(orderings) do
		if ordering.sourceNodeId == targetNodeId and ordering.targetNodeId == sourceNodeId then
			if orderingKind == "Before" and ordering.orderingKind == "Before" then
				return true
			end
			if orderingKind == "After" and ordering.orderingKind == "After" then
				return true
			end
		end
	end
	return false
end

local function validateNodeRefs(values: any, label: string): (boolean, string?)
	if values == nil then
		return true, nil
	end
	for _, nodeId in ipairs(values) do
		if not nodeExists(nodeId) then
			return false, "invalid " .. label .. " node reference"
		end
	end
	return true, nil
end

local function validateDependencyRefs(values: any, label: string): (boolean, string?)
	if values == nil then
		return true, nil
	end
	for _, dependencyId in ipairs(values) do
		if not dependencyExists(dependencyId) then
			return false, "invalid " .. label .. " dependency reference"
		end
	end
	return true, nil
end

local function validateOrderingRefs(values: any, label: string): (boolean, string?)
	if values == nil then
		return true, nil
	end
	for _, orderingId in ipairs(values) do
		if not orderingExists(orderingId) then
			return false, "invalid " .. label .. " ordering reference"
		end
	end
	return true, nil
end

function State.registerNode(schema: any): (boolean, string?)
	local ok, reason = Validation.node(schema)
	if not ok then
		return false, reason
	end
	local unique, duplicateReason = rejectDuplicate(schema.nodeId, "duplicate nodeId")
	if not unique then
		return false, duplicateReason
	end
	if countMap(nodes) >= Types.Limits.MaxRuntimeNodes then
		return false, "runtime node limit exceeded"
	end
	schemaIds[schema.nodeId] = true
	nodes[schema.nodeId] = Serialization.deepCopy(schema)
	return true, nil
end

function State.registerDependency(schema: any): (boolean, string?)
	local ok, reason = Validation.dependency(schema)
	if not ok then
		return false, reason
	end
	if not nodeExists(schema.sourceNodeId) then
		return false, "invalid dependency source node"
	end
	if not nodeExists(schema.targetNodeId) then
		return false, "invalid dependency target node"
	end
	if
		schema.dependencyKind == "Required"
		and hasRequiredReverseDependency(schema.sourceNodeId, schema.targetNodeId)
	then
		return false, "direct required dependency cycle is invalid"
	end
	local unique, duplicateReason = rejectDuplicate(schema.dependencyId, "duplicate dependencyId")
	if not unique then
		return false, duplicateReason
	end
	if countMap(dependencies) >= Types.Limits.MaxDependencies then
		return false, "dependency limit exceeded"
	end
	schemaIds[schema.dependencyId] = true
	dependencies[schema.dependencyId] = Serialization.deepCopy(schema)
	return true, nil
end

function State.registerCapability(schema: any): (boolean, string?)
	local ok, reason = Validation.capability(schema)
	if not ok then
		return false, reason
	end
	if not nodeExists(schema.nodeId) then
		return false, "invalid capability node reference"
	end
	local unique, duplicateReason = rejectDuplicate(schema.capabilityId, "duplicate capabilityId")
	if not unique then
		return false, duplicateReason
	end
	if countMap(capabilities) >= Types.Limits.MaxCapabilities then
		return false, "capability limit exceeded"
	end
	schemaIds[schema.capabilityId] = true
	capabilities[schema.capabilityId] = Serialization.deepCopy(schema)
	return true, nil
end

function State.registerRequirement(schema: any): (boolean, string?)
	local ok, reason = Validation.requirement(schema)
	if not ok then
		return false, reason
	end
	if not nodeExists(schema.nodeId) then
		return false, "invalid requirement node reference"
	end
	local unique, duplicateReason = rejectDuplicate(schema.requirementId, "duplicate requirementId")
	if not unique then
		return false, duplicateReason
	end
	if countMap(requirements) >= Types.Limits.MaxRequirements then
		return false, "requirement limit exceeded"
	end
	schemaIds[schema.requirementId] = true
	requirements[schema.requirementId] = Serialization.deepCopy(schema)
	return true, nil
end

function State.registerCompatibility(schema: any): (boolean, string?)
	local ok, reason = Validation.compatibility(schema)
	if not ok then
		return false, reason
	end
	if not nodeExists(schema.sourceNodeId) then
		return false, "invalid compatibility source node"
	end
	if not nodeExists(schema.targetNodeId) then
		return false, "invalid compatibility target node"
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

function State.registerOrdering(schema: any): (boolean, string?)
	local ok, reason = Validation.ordering(schema)
	if not ok then
		return false, reason
	end
	if not nodeExists(schema.sourceNodeId) then
		return false, "invalid ordering source node"
	end
	if not nodeExists(schema.targetNodeId) then
		return false, "invalid ordering target node"
	end
	if hasContradictoryOrdering(schema.sourceNodeId, schema.targetNodeId, schema.orderingKind) then
		return false, "directly contradictory ordering pair is invalid"
	end
	local unique, duplicateReason = rejectDuplicate(schema.orderingId, "duplicate orderingId")
	if not unique then
		return false, duplicateReason
	end
	if countMap(orderings) >= Types.Limits.MaxOrderingRecords then
		return false, "ordering limit exceeded"
	end
	schemaIds[schema.orderingId] = true
	orderings[schema.orderingId] = Serialization.deepCopy(schema)
	return true, nil
end

function State.registerStartupPlan(schema: any): (boolean, string?)
	local ok, reason = Validation.startupPlan(schema)
	if not ok then
		return false, reason
	end
	local nodesOk, nodesReason = validateNodeRefs(schema.nodeIds, "startup plan")
	if not nodesOk then
		return false, nodesReason
	end
	local depsOk, depsReason = validateDependencyRefs(schema.dependencyIds, "startup plan")
	if not depsOk then
		return false, depsReason
	end
	local orderOk, orderReason = validateOrderingRefs(schema.orderingIds, "startup plan")
	if not orderOk then
		return false, orderReason
	end
	local unique, duplicateReason = rejectDuplicate(schema.startupPlanId, "duplicate startupPlanId")
	if not unique then
		return false, duplicateReason
	end
	if countMap(startupPlans) >= Types.Limits.MaxStartupPlans then
		return false, "startup plan limit exceeded"
	end
	schemaIds[schema.startupPlanId] = true
	startupPlans[schema.startupPlanId] = Serialization.deepCopy(schema)
	return true, nil
end

function State.registerShutdownPlan(schema: any): (boolean, string?)
	local ok, reason = Validation.shutdownPlan(schema)
	if not ok then
		return false, reason
	end
	local nodesOk, nodesReason = validateNodeRefs(schema.nodeIds, "shutdown plan")
	if not nodesOk then
		return false, nodesReason
	end
	local depsOk, depsReason = validateDependencyRefs(schema.dependencyIds, "shutdown plan")
	if not depsOk then
		return false, depsReason
	end
	local orderOk, orderReason = validateOrderingRefs(schema.orderingIds, "shutdown plan")
	if not orderOk then
		return false, orderReason
	end
	local unique, duplicateReason =
		rejectDuplicate(schema.shutdownPlanId, "duplicate shutdownPlanId")
	if not unique then
		return false, duplicateReason
	end
	if countMap(shutdownPlans) >= Types.Limits.MaxShutdownPlans then
		return false, "shutdown plan limit exceeded"
	end
	schemaIds[schema.shutdownPlanId] = true
	shutdownPlans[schema.shutdownPlanId] = Serialization.deepCopy(schema)
	return true, nil
end

function State.registerGroup(schema: any): (boolean, string?)
	local ok, reason = Validation.group(schema)
	if not ok then
		return false, reason
	end
	local nodesOk, nodesReason = validateNodeRefs(schema.nodeIds, "group")
	if not nodesOk then
		return false, nodesReason
	end
	local unique, duplicateReason = rejectDuplicate(schema.groupId, "duplicate groupId")
	if not unique then
		return false, duplicateReason
	end
	if countMap(groups) >= Types.Limits.MaxGroups then
		return false, "group limit exceeded"
	end
	schemaIds[schema.groupId] = true
	groups[schema.groupId] = Serialization.deepCopy(schema)
	return true, nil
end

function State.registerValidationRecord(schema: any): (boolean, string?)
	local ok, reason = Validation.validationRecord(schema)
	if not ok then
		return false, reason
	end
	local nodesOk, nodesReason = validateNodeRefs(schema.nodeIds, "validation")
	if not nodesOk then
		return false, nodesReason
	end
	local depsOk, depsReason = validateDependencyRefs(schema.dependencyIds, "validation")
	if not depsOk then
		return false, depsReason
	end
	local unique, duplicateReason = rejectDuplicate(schema.validationId, "duplicate validationId")
	if not unique then
		return false, duplicateReason
	end
	if countMap(validationRecords) >= Types.Limits.MaxValidationRecords then
		return false, "validation record limit exceeded"
	end
	schemaIds[schema.validationId] = true
	validationRecords[schema.validationId] = Serialization.deepCopy(schema)
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
		nodes = nodes,
		dependencies = dependencies,
		capabilities = capabilities,
		requirements = requirements,
		compatibilities = compatibilities,
		orderings = orderings,
		startupPlans = startupPlans,
		shutdownPlans = shutdownPlans,
		groups = groups,
		validationRecords = validationRecords,
		validationFailures = validationFailures,
		snapshotHistory = snapshotHistory,
		counts = {
			nodes = countMap(nodes),
			dependencies = countMap(dependencies),
			capabilities = countMap(capabilities),
			requirements = countMap(requirements),
			compatibilities = countMap(compatibilities),
			orderings = countMap(orderings),
			startupPlans = countMap(startupPlans),
			shutdownPlans = countMap(shutdownPlans),
			groups = countMap(groups),
			validationRecords = countMap(validationRecords),
			validationFailures = #validationFailures,
			snapshots = #snapshotHistory,
		},
	})
end

function State.clear()
	table.clear(nodes)
	table.clear(dependencies)
	table.clear(capabilities)
	table.clear(requirements)
	table.clear(compatibilities)
	table.clear(orderings)
	table.clear(startupPlans)
	table.clear(shutdownPlans)
	table.clear(groups)
	table.clear(validationRecords)
	table.clear(schemaIds)
	table.clear(validationFailures)
	table.clear(snapshotHistory)
end

return State
