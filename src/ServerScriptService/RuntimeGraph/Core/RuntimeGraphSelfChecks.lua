--!strict
-- Deterministic self-checks for Phase 37 Runtime Dependency Graph Foundation.

local Serialization = require(script.Parent.RuntimeGraphSerialization)
local Types = require(script.Parent.RuntimeGraphTypes)
local Validation = require(script.Parent.RuntimeGraphValidation)

local SelfChecks = {}

local function base(idField: string, id: string, schemaType: string): any
	return {
		[idField] = id,
		ownerSystem = "runtimeGraphSelfCheck",
		schemaType = schemaType,
		metadata = { schemaOnly = true },
		context = { foundationalRuntime = true },
		tags = { "self-check" },
	}
end

local function node(id: string, layer: string?): any
	local schema = base("nodeId", id, Types.SchemaType.RuntimeNodeSchema)
	schema.runtimeName = id
	schema.runtimeLayer = layer or "RuntimeGraph"
	return schema
end

local function dependency(id: string, sourceId: string?, targetId: string?, kind: string?): any
	local schema = base("dependencyId", id, Types.SchemaType.RuntimeDependencySchema)
	schema.sourceNodeId = sourceId or "node.alpha"
	schema.targetNodeId = targetId or "node.beta"
	schema.dependencyKind = kind or "Required"
	schema.required = schema.dependencyKind == "Required"
	return schema
end

local function capability(id: string, nodeId: string?): any
	local schema = base("capabilityId", id, Types.SchemaType.RuntimeCapabilitySchema)
	schema.nodeId = nodeId or "node.alpha"
	schema.capabilityName = id .. ".capability"
	schema.capabilityKind = "SchemaDeclaration"
	return schema
end

local function requirement(id: string, nodeId: string?): any
	local schema = base("requirementId", id, Types.SchemaType.RuntimeRequirementSchema)
	schema.nodeId = nodeId or "node.alpha"
	schema.requiredCapability = id .. ".capability"
	schema.requirementKind = "SchemaDeclaration"
	return schema
end

local function compatibility(id: string, sourceId: string?, targetId: string?, kind: string?): any
	local schema = base("compatibilityId", id, Types.SchemaType.RuntimeCompatibilitySchema)
	schema.sourceNodeId = sourceId or "node.alpha"
	schema.targetNodeId = targetId or "node.beta"
	schema.compatibilityKind = kind or "Compatible"
	return schema
end

local function ordering(id: string, sourceId: string?, targetId: string?, kind: string?): any
	local schema = base("orderingId", id, Types.SchemaType.RuntimeOrderingSchema)
	schema.sourceNodeId = sourceId or "node.alpha"
	schema.targetNodeId = targetId or "node.beta"
	schema.orderingKind = kind or "Before"
	return schema
end

local function startupPlan(id: string, nodeIds: { string }?): any
	local schema = base("startupPlanId", id, Types.SchemaType.RuntimeStartupPlanSchema)
	schema.planName = id
	schema.nodeIds = nodeIds or { "node.alpha", "node.beta" }
	schema.dependencyIds = { "dependency.valid" }
	schema.orderingIds = { "ordering.valid" }
	return schema
end

local function shutdownPlan(id: string, nodeIds: { string }?): any
	local schema = base("shutdownPlanId", id, Types.SchemaType.RuntimeShutdownPlanSchema)
	schema.planName = id
	schema.nodeIds = nodeIds or { "node.alpha", "node.beta" }
	schema.dependencyIds = { "dependency.valid" }
	schema.orderingIds = { "ordering.valid" }
	return schema
end

local function group(id: string, nodeIds: { string }?): any
	local schema = base("groupId", id, Types.SchemaType.RuntimeGroupSchema)
	schema.groupName = id
	schema.groupKind = "SchemaGroup"
	schema.nodeIds = nodeIds or { "node.alpha" }
	return schema
end

local function validationRecord(id: string, nodeIds: { string }?, dependencyIds: { string }?): any
	local schema = base("validationId", id, Types.SchemaType.RuntimeGraphValidationSchema)
	schema.validationKind = "SelfCheckSummary"
	schema.resultStatus = "Pass"
	schema.nodeIds = nodeIds or { "node.alpha" }
	schema.dependencyIds = dependencyIds or { "dependency.valid" }
	schema.findings = {}
	return schema
end

local function result(name: string, ok: boolean, detail: string?): any
	return { name = name, ok = ok, detail = detail }
end

local function expectReject(name: string, ok: boolean, reason: string?): any
	return result(name, not ok, reason)
end

local function expectAccept(name: string, ok: boolean, reason: string?): any
	return result(name, ok, reason)
end

local function add(results: { any }, check: any)
	table.insert(results, check)
end

local function unsafeSchema(schema: any, fields: any): any
	schema.context = fields
	return schema
end

local function unsupported(schema: any): any
	schema.schemaType = "UnsupportedRuntimeGraphSchema"
	return schema
end

local function oversizedArray(limit: number): { string }
	local values = {}
	for index = 1, limit + 1 do
		table.insert(values, "value." .. index)
	end
	return values
end

local function longString(): string
	return string.rep("x", Types.Limits.MaxPayloadStringLength + 1)
end

function SelfChecks.run(context: any)
	local service = context.Service
	local results = {}
	service.shutdown()

	add(results, expectReject("malformed runtime node rejects", Validation.node({ nodeId = "" })))
	add(
		results,
		expectReject(
			"unsupported runtime node schema type rejects",
			Validation.node(unsupported(node("node.unsupported")))
		)
	)
	add(
		results,
		expectReject(
			"unsupported runtime layer rejects",
			Validation.node(node("node.bad.layer", "Unsupported"))
		)
	)
	local alpha = service.registerNode(node("node.alpha", "Core"))
	add(results, expectAccept("valid runtime node registers", alpha.ok, alpha.message))
	local beta = service.registerNode(node("node.beta", "Governance"))
	add(results, expectAccept("second runtime node registers", beta.ok, beta.message))
	local duplicateNode = service.registerNode(node("node.alpha", "Core"))
	add(
		results,
		expectReject("duplicate runtime node rejects", duplicateNode.ok, duplicateNode.message)
	)
	local unsafeNode =
		service.registerNode(unsafeSchema(node("node.unsafe"), { startRuntime = true }))
	add(results, expectReject("unsafe runtime node rejects", unsafeNode.ok, unsafeNode.message))
	add(
		results,
		expectReject(
			"runtime node with module reference rejects",
			service.registerNode(
				unsafeSchema(node("node.module.reference"), { moduleReference = true })
			).ok,
			"module reference rejected"
		)
	)
	add(
		results,
		expectReject(
			"runtime node with service reference rejects",
			service.registerNode(
				unsafeSchema(node("node.service.reference"), { serviceReference = true })
			).ok,
			"service reference rejected"
		)
	)
	add(
		results,
		expectReject(
			"runtime node with execution adapter rejects",
			service.registerNode(
				unsafeSchema(node("node.execution.adapter"), { executionAdapter = true })
			).ok,
			"execution adapter rejected"
		)
	)

	add(
		results,
		expectReject("malformed dependency rejects", Validation.dependency({ dependencyId = "" }))
	)
	add(
		results,
		expectReject(
			"unsupported dependency schema type rejects",
			Validation.dependency(unsupported(dependency("dependency.unsupported")))
		)
	)
	add(
		results,
		expectReject(
			"unsupported dependency kind rejects",
			Validation.dependency(dependency("dependency.bad.kind", nil, nil, "UnknownKind"))
		)
	)
	local invalidDependencySource =
		service.registerDependency(dependency("dependency.bad.source", "node.missing", "node.beta"))
	add(
		results,
		expectReject(
			"invalid source node rejects",
			invalidDependencySource.ok,
			invalidDependencySource.message
		)
	)
	local invalidDependencyTarget = service.registerDependency(
		dependency("dependency.bad.target", "node.alpha", "node.missing")
	)
	add(
		results,
		expectReject(
			"invalid target node rejects",
			invalidDependencyTarget.ok,
			invalidDependencyTarget.message
		)
	)
	add(
		results,
		expectReject(
			"self-dependency rejects",
			Validation.dependency(dependency("dependency.self", "node.alpha", "node.alpha"))
		)
	)
	local dependencyResult = service.registerDependency(
		dependency("dependency.valid", "node.alpha", "node.beta", "Required")
	)
	add(
		results,
		expectAccept("valid dependency registers", dependencyResult.ok, dependencyResult.message)
	)
	local cycleDependency = service.registerDependency(
		dependency("dependency.cycle", "node.beta", "node.alpha", "Required")
	)
	add(
		results,
		expectReject("direct required cycle rejects", cycleDependency.ok, cycleDependency.message)
	)
	local duplicateDependency = service.registerDependency(dependency("dependency.valid"))
	add(
		results,
		expectReject(
			"duplicate dependency rejects",
			duplicateDependency.ok,
			duplicateDependency.message
		)
	)
	local unsafeDependency = service.registerDependency(
		unsafeSchema(dependency("dependency.unsafe"), { callRuntime = true })
	)
	add(
		results,
		expectReject("unsafe dependency rejects", unsafeDependency.ok, unsafeDependency.message)
	)
	add(
		results,
		expectReject(
			"dependency with service resolution payload rejects",
			service.registerDependency(
				unsafeSchema(
					dependency("dependency.service.resolution"),
					{ serviceResolution = true }
				)
			).ok,
			"service resolution rejected"
		)
	)
	add(
		results,
		expectReject(
			"dependency with dependency injection payload rejects",
			service.registerDependency(
				unsafeSchema(dependency("dependency.injection"), { dependencyInjection = true })
			).ok,
			"dependency injection rejected"
		)
	)

	add(
		results,
		expectReject("malformed capability rejects", Validation.capability({ capabilityId = "" }))
	)
	add(
		results,
		expectReject(
			"unsupported capability schema type rejects",
			Validation.capability(unsupported(capability("capability.unsupported")))
		)
	)
	local invalidCapability =
		service.registerCapability(capability("capability.bad.node", "node.missing"))
	add(
		results,
		expectReject(
			"invalid capability node rejects",
			invalidCapability.ok,
			invalidCapability.message
		)
	)
	local capabilityResult = service.registerCapability(capability("capability.valid"))
	add(
		results,
		expectAccept("valid capability registers", capabilityResult.ok, capabilityResult.message)
	)
	local dependencyIdAsCapability = service.registerCapability(capability("dependency.valid"))
	add(
		results,
		expectReject(
			"dependency id rejects as capability id",
			dependencyIdAsCapability.ok,
			dependencyIdAsCapability.message
		)
	)
	local duplicateCapability = service.registerCapability(capability("capability.valid"))
	add(
		results,
		expectReject(
			"duplicate capability rejects",
			duplicateCapability.ok,
			duplicateCapability.message
		)
	)
	local unsafeCapability = service.registerCapability(
		unsafeSchema(capability("capability.unsafe"), { serviceReference = true })
	)
	add(
		results,
		expectReject("unsafe capability rejects", unsafeCapability.ok, unsafeCapability.message)
	)
	add(
		results,
		expectReject(
			"capability with runtime object reference rejects",
			service.registerCapability(
				unsafeSchema(capability("capability.runtime.object"), { runtimeObject = true })
			).ok,
			"runtime object rejected"
		)
	)
	add(
		results,
		expectReject(
			"capability with execution permission payload rejects",
			service.registerCapability(
				unsafeSchema(
					capability("capability.execution.permission"),
					{ executionPermission = true }
				)
			).ok,
			"execution permission rejected"
		)
	)

	add(
		results,
		expectReject(
			"malformed requirement rejects",
			Validation.requirement({ requirementId = "" })
		)
	)
	add(
		results,
		expectReject(
			"unsupported requirement schema type rejects",
			Validation.requirement(unsupported(requirement("requirement.unsupported")))
		)
	)
	local invalidRequirement =
		service.registerRequirement(requirement("requirement.bad.node", "node.missing"))
	add(
		results,
		expectReject(
			"invalid requirement node rejects",
			invalidRequirement.ok,
			invalidRequirement.message
		)
	)
	local requirementResult = service.registerRequirement(requirement("requirement.valid"))
	add(
		results,
		expectAccept("valid requirement registers", requirementResult.ok, requirementResult.message)
	)
	local capabilityIdAsRequirement = service.registerRequirement(requirement("capability.valid"))
	add(
		results,
		expectReject(
			"capability id rejects as requirement id",
			capabilityIdAsRequirement.ok,
			capabilityIdAsRequirement.message
		)
	)
	local duplicateRequirement = service.registerRequirement(requirement("requirement.valid"))
	add(
		results,
		expectReject(
			"duplicate requirement rejects",
			duplicateRequirement.ok,
			duplicateRequirement.message
		)
	)
	local unsafeRequirement = service.registerRequirement(
		unsafeSchema(requirement("requirement.unsafe"), { resolveService = true })
	)
	add(
		results,
		expectReject("unsafe requirement rejects", unsafeRequirement.ok, unsafeRequirement.message)
	)
	add(
		results,
		expectReject(
			"requirement with service lookup payload rejects",
			service.registerRequirement(
				unsafeSchema(requirement("requirement.service.lookup"), { serviceLookup = true })
			).ok,
			"service lookup rejected"
		)
	)
	add(
		results,
		expectReject(
			"requirement with dependency injection payload rejects",
			service.registerRequirement(
				unsafeSchema(
					requirement("requirement.injection"),
					{ dependencyInjectionExecution = true }
				)
			).ok,
			"dependency injection rejected"
		)
	)

	add(
		results,
		expectReject(
			"malformed compatibility rejects",
			Validation.compatibility({ compatibilityId = "" })
		)
	)
	add(
		results,
		expectReject(
			"unsupported compatibility schema type rejects",
			Validation.compatibility(unsupported(compatibility("compatibility.unsupported")))
		)
	)
	add(
		results,
		expectReject(
			"unsupported compatibility kind rejects",
			Validation.compatibility(compatibility("compatibility.bad.kind", nil, nil, "BadKind"))
		)
	)
	local invalidCompatibilitySource = service.registerCompatibility(
		compatibility("compatibility.bad.source", "node.missing", "node.beta")
	)
	add(
		results,
		expectReject(
			"invalid compatibility source rejects",
			invalidCompatibilitySource.ok,
			invalidCompatibilitySource.message
		)
	)
	local invalidCompatibilityTarget = service.registerCompatibility(
		compatibility("compatibility.bad.target", "node.alpha", "node.missing")
	)
	add(
		results,
		expectReject(
			"invalid compatibility target rejects",
			invalidCompatibilityTarget.ok,
			invalidCompatibilityTarget.message
		)
	)
	local compatibilityResult = service.registerCompatibility(compatibility("compatibility.valid"))
	add(
		results,
		expectAccept(
			"valid compatibility registers",
			compatibilityResult.ok,
			compatibilityResult.message
		)
	)
	local requirementIdAsCompatibility =
		service.registerCompatibility(compatibility("requirement.valid"))
	add(
		results,
		expectReject(
			"requirement id rejects as compatibility id",
			requirementIdAsCompatibility.ok,
			requirementIdAsCompatibility.message
		)
	)
	local duplicateCompatibility =
		service.registerCompatibility(compatibility("compatibility.valid"))
	add(
		results,
		expectReject(
			"duplicate compatibility rejects",
			duplicateCompatibility.ok,
			duplicateCompatibility.message
		)
	)
	local unsafeCompatibility = service.registerCompatibility(
		unsafeSchema(compatibility("compatibility.unsafe"), { moduleLoading = true })
	)
	add(
		results,
		expectReject(
			"unsafe compatibility rejects",
			unsafeCompatibility.ok,
			unsafeCompatibility.message
		)
	)
	add(
		results,
		expectReject(
			"compatibility with migration execution payload rejects",
			service.registerCompatibility(
				unsafeSchema(
					compatibility("compatibility.migration"),
					{ migrationExecution = true }
				)
			).ok,
			"migration execution rejected"
		)
	)
	add(
		results,
		expectReject(
			"compatibility with adapter loading payload rejects",
			service.registerCompatibility(
				unsafeSchema(
					compatibility("compatibility.adapter.loading"),
					{ adapterLoading = true }
				)
			).ok,
			"adapter loading rejected"
		)
	)

	add(
		results,
		expectReject("malformed ordering rejects", Validation.ordering({ orderingId = "" }))
	)
	add(
		results,
		expectReject(
			"unsupported ordering schema type rejects",
			Validation.ordering(unsupported(ordering("ordering.unsupported")))
		)
	)
	add(
		results,
		expectReject(
			"unsupported ordering kind rejects",
			Validation.ordering(ordering("ordering.bad.kind", nil, nil, "BadKind"))
		)
	)
	local invalidOrderingSource =
		service.registerOrdering(ordering("ordering.bad.source", "node.missing", "node.beta"))
	add(
		results,
		expectReject(
			"invalid ordering source rejects",
			invalidOrderingSource.ok,
			invalidOrderingSource.message
		)
	)
	local invalidOrderingTarget =
		service.registerOrdering(ordering("ordering.bad.target", "node.alpha", "node.missing"))
	add(
		results,
		expectReject(
			"invalid ordering target rejects",
			invalidOrderingTarget.ok,
			invalidOrderingTarget.message
		)
	)
	add(
		results,
		expectReject(
			"self-ordering rejects",
			Validation.ordering(ordering("ordering.self", "node.alpha", "node.alpha"))
		)
	)
	local orderingResult =
		service.registerOrdering(ordering("ordering.valid", "node.alpha", "node.beta", "Before"))
	add(
		results,
		expectAccept("valid ordering registers", orderingResult.ok, orderingResult.message)
	)
	local contradictoryOrdering = service.registerOrdering(
		ordering("ordering.contradiction", "node.beta", "node.alpha", "Before")
	)
	add(
		results,
		expectReject(
			"directly contradictory ordering pair rejects",
			contradictoryOrdering.ok,
			contradictoryOrdering.message
		)
	)
	local compatibilityIdAsOrdering = service.registerOrdering(ordering("compatibility.valid"))
	add(
		results,
		expectReject(
			"compatibility id rejects as ordering id",
			compatibilityIdAsOrdering.ok,
			compatibilityIdAsOrdering.message
		)
	)
	local duplicateOrdering = service.registerOrdering(ordering("ordering.valid"))
	add(
		results,
		expectReject("duplicate ordering rejects", duplicateOrdering.ok, duplicateOrdering.message)
	)
	local unsafeOrdering = service.registerOrdering(
		unsafeSchema(ordering("ordering.unsafe"), { frameworkReplacement = true })
	)
	add(results, expectReject("unsafe ordering rejects", unsafeOrdering.ok, unsafeOrdering.message))
	add(
		results,
		expectReject(
			"ordering with startup execution payload rejects",
			service.registerOrdering(
				unsafeSchema(ordering("ordering.startup.execution"), { startupExecution = true })
			).ok,
			"startup execution rejected"
		)
	)
	add(
		results,
		expectReject(
			"ordering with shutdown execution payload rejects",
			service.registerOrdering(
				unsafeSchema(ordering("ordering.shutdown.execution"), { shutdownExecution = true })
			).ok,
			"shutdown execution rejected"
		)
	)

	add(
		results,
		expectReject(
			"malformed startup plan rejects",
			Validation.startupPlan({ startupPlanId = "" })
		)
	)
	add(
		results,
		expectReject(
			"unsupported startup plan schema type rejects",
			Validation.startupPlan(unsupported(startupPlan("startup.unsupported")))
		)
	)
	local invalidStartupNode =
		service.registerStartupPlan(startupPlan("startup.bad.node", { "node.missing" }))
	add(
		results,
		expectReject(
			"invalid startup plan node rejects",
			invalidStartupNode.ok,
			invalidStartupNode.message
		)
	)
	local startupBadDependency = startupPlan("startup.bad.dependency")
	startupBadDependency.dependencyIds = { "dependency.missing" }
	add(
		results,
		expectReject(
			"invalid startup plan dependency rejects",
			service.registerStartupPlan(startupBadDependency).ok,
			"missing dependency"
		)
	)
	local startupBadOrdering = startupPlan("startup.bad.ordering")
	startupBadOrdering.orderingIds = { "ordering.missing" }
	add(
		results,
		expectReject(
			"invalid startup plan ordering rejects",
			service.registerStartupPlan(startupBadOrdering).ok,
			"missing ordering"
		)
	)
	add(
		results,
		expectReject(
			"oversized startup plan node list rejects",
			Validation.startupPlan(
				startupPlan("startup.oversized", oversizedArray(Types.Limits.MaxPlanNodes))
			)
		)
	)
	local oversizedStartupDependencies = startupPlan("startup.oversized.dependencies")
	oversizedStartupDependencies.dependencyIds = oversizedArray(Types.Limits.MaxPlanDependencies)
	add(
		results,
		expectReject(
			"oversized startup plan dependency list rejects",
			Validation.startupPlan(oversizedStartupDependencies)
		)
	)
	local oversizedStartupOrderings = startupPlan("startup.oversized.orderings")
	oversizedStartupOrderings.orderingIds = oversizedArray(Types.Limits.MaxPlanOrderings)
	add(
		results,
		expectReject(
			"oversized startup plan ordering list rejects",
			Validation.startupPlan(oversizedStartupOrderings)
		)
	)
	local startupResult = service.registerStartupPlan(startupPlan("startup.valid"))
	add(
		results,
		expectAccept("valid startup plan registers", startupResult.ok, startupResult.message)
	)
	local orderingIdAsStartup = service.registerStartupPlan(startupPlan("ordering.valid"))
	add(
		results,
		expectReject(
			"ordering id rejects as startup plan id",
			orderingIdAsStartup.ok,
			orderingIdAsStartup.message
		)
	)
	local duplicateStartup = service.registerStartupPlan(startupPlan("startup.valid"))
	add(
		results,
		expectReject(
			"duplicate startup plan rejects",
			duplicateStartup.ok,
			duplicateStartup.message
		)
	)
	local unsafeStartup = service.registerStartupPlan(
		unsafeSchema(startupPlan("startup.unsafe"), { startupExecution = true })
	)
	add(
		results,
		expectReject("unsafe startup plan rejects", unsafeStartup.ok, unsafeStartup.message)
	)
	add(
		results,
		expectReject(
			"startup plan with initialization payload rejects",
			service.registerStartupPlan(
				unsafeSchema(startupPlan("startup.initialization"), { initializeRuntime = true })
			).ok,
			"initialization rejected"
		)
	)
	add(
		results,
		expectReject(
			"startup plan with framework mutation payload rejects",
			service.registerStartupPlan(
				unsafeSchema(
					startupPlan("startup.framework.mutation"),
					{ frameworkMutation = true }
				)
			).ok,
			"framework mutation rejected"
		)
	)

	add(
		results,
		expectReject(
			"malformed shutdown plan rejects",
			Validation.shutdownPlan({ shutdownPlanId = "" })
		)
	)
	add(
		results,
		expectReject(
			"unsupported shutdown plan schema type rejects",
			Validation.shutdownPlan(unsupported(shutdownPlan("shutdown.unsupported")))
		)
	)
	local invalidShutdownNode =
		service.registerShutdownPlan(shutdownPlan("shutdown.bad.node", { "node.missing" }))
	add(
		results,
		expectReject(
			"invalid shutdown plan node rejects",
			invalidShutdownNode.ok,
			invalidShutdownNode.message
		)
	)
	local shutdownBadDependency = shutdownPlan("shutdown.bad.dependency")
	shutdownBadDependency.dependencyIds = { "dependency.missing" }
	add(
		results,
		expectReject(
			"invalid shutdown plan dependency rejects",
			service.registerShutdownPlan(shutdownBadDependency).ok,
			"missing dependency"
		)
	)
	local shutdownBadOrdering = shutdownPlan("shutdown.bad.ordering")
	shutdownBadOrdering.orderingIds = { "ordering.missing" }
	add(
		results,
		expectReject(
			"invalid shutdown plan ordering rejects",
			service.registerShutdownPlan(shutdownBadOrdering).ok,
			"missing ordering"
		)
	)
	add(
		results,
		expectReject(
			"oversized shutdown plan node list rejects",
			Validation.shutdownPlan(
				shutdownPlan("shutdown.oversized", oversizedArray(Types.Limits.MaxPlanNodes))
			)
		)
	)
	local oversizedShutdownDependencies = shutdownPlan("shutdown.oversized.dependencies")
	oversizedShutdownDependencies.dependencyIds = oversizedArray(Types.Limits.MaxPlanDependencies)
	add(
		results,
		expectReject(
			"oversized shutdown plan dependency list rejects",
			Validation.shutdownPlan(oversizedShutdownDependencies)
		)
	)
	local oversizedShutdownOrderings = shutdownPlan("shutdown.oversized.orderings")
	oversizedShutdownOrderings.orderingIds = oversizedArray(Types.Limits.MaxPlanOrderings)
	add(
		results,
		expectReject(
			"oversized shutdown plan ordering list rejects",
			Validation.shutdownPlan(oversizedShutdownOrderings)
		)
	)
	local shutdownResult = service.registerShutdownPlan(shutdownPlan("shutdown.valid"))
	add(
		results,
		expectAccept("valid shutdown plan registers", shutdownResult.ok, shutdownResult.message)
	)
	local startupIdAsShutdown = service.registerShutdownPlan(shutdownPlan("startup.valid"))
	add(
		results,
		expectReject(
			"startup plan id rejects as shutdown plan id",
			startupIdAsShutdown.ok,
			startupIdAsShutdown.message
		)
	)
	local duplicateShutdown = service.registerShutdownPlan(shutdownPlan("shutdown.valid"))
	add(
		results,
		expectReject(
			"duplicate shutdown plan rejects",
			duplicateShutdown.ok,
			duplicateShutdown.message
		)
	)
	local unsafeShutdown = service.registerShutdownPlan(
		unsafeSchema(shutdownPlan("shutdown.unsafe"), { shutdownExecution = true })
	)
	add(
		results,
		expectReject("unsafe shutdown plan rejects", unsafeShutdown.ok, unsafeShutdown.message)
	)
	add(
		results,
		expectReject(
			"shutdown plan with live mutation payload rejects",
			service.registerShutdownPlan(
				unsafeSchema(shutdownPlan("shutdown.live.mutation"), { liveSystemMutation = true })
			).ok,
			"live mutation rejected"
		)
	)

	add(results, expectReject("malformed group rejects", Validation.group({ groupId = "" })))
	add(
		results,
		expectReject(
			"unsupported group schema type rejects",
			Validation.group(unsupported(group("group.unsupported")))
		)
	)
	local invalidGroupNode = service.registerGroup(group("group.bad.node", { "node.missing" }))
	add(
		results,
		expectReject("invalid group node rejects", invalidGroupNode.ok, invalidGroupNode.message)
	)
	add(
		results,
		expectReject(
			"oversized group node list rejects",
			Validation.group(group("group.oversized", oversizedArray(Types.Limits.MaxGroupNodes)))
		)
	)
	local groupResult = service.registerGroup(group("group.valid"))
	add(results, expectAccept("valid group registers", groupResult.ok, groupResult.message))
	local shutdownIdAsGroup = service.registerGroup(group("shutdown.valid"))
	add(
		results,
		expectReject(
			"shutdown plan id rejects as group id",
			shutdownIdAsGroup.ok,
			shutdownIdAsGroup.message
		)
	)
	local duplicateGroup = service.registerGroup(group("group.valid"))
	add(results, expectReject("duplicate group rejects", duplicateGroup.ok, duplicateGroup.message))
	local unsafeGroup = service.registerGroup(
		unsafeSchema(group("group.unsafe"), { orchestrationExecution = true })
	)
	add(results, expectReject("unsafe group rejects", unsafeGroup.ok, unsafeGroup.message))
	add(
		results,
		expectReject(
			"group with execution group payload rejects",
			service.registerGroup(unsafeSchema(group("group.execution"), { executionGroup = true })).ok,
			"execution group rejected"
		)
	)

	add(
		results,
		expectReject(
			"malformed validation record rejects",
			Validation.validationRecord({ validationId = "" })
		)
	)
	add(
		results,
		expectReject(
			"unsupported validation schema type rejects",
			Validation.validationRecord(unsupported(validationRecord("validation.unsupported")))
		)
	)
	local invalidValidationNode = service.registerValidationRecord(
		validationRecord("validation.bad.node", { "node.missing" }, { "dependency.valid" })
	)
	add(
		results,
		expectReject(
			"invalid validation node references reject",
			invalidValidationNode.ok,
			invalidValidationNode.message
		)
	)
	local invalidValidationDependency = service.registerValidationRecord(
		validationRecord("validation.bad.dependency", { "node.alpha" }, { "dependency.missing" })
	)
	add(
		results,
		expectReject(
			"invalid validation dependency references reject",
			invalidValidationDependency.ok,
			invalidValidationDependency.message
		)
	)
	local validationResult = service.registerValidationRecord(validationRecord("validation.valid"))
	add(
		results,
		expectAccept(
			"valid validation record registers",
			validationResult.ok,
			validationResult.message
		)
	)
	local groupIdAsValidation = service.registerValidationRecord(validationRecord("group.valid"))
	add(
		results,
		expectReject(
			"group id rejects as validation id",
			groupIdAsValidation.ok,
			groupIdAsValidation.message
		)
	)
	local duplicateValidation =
		service.registerValidationRecord(validationRecord("validation.valid"))
	add(
		results,
		expectReject(
			"duplicate validation record rejects",
			duplicateValidation.ok,
			duplicateValidation.message
		)
	)
	local unsafeValidation = service.registerValidationRecord(
		unsafeSchema(validationRecord("validation.unsafe"), { executionAdapter = true })
	)
	add(
		results,
		expectReject(
			"unsafe validation record rejects",
			unsafeValidation.ok,
			unsafeValidation.message
		)
	)
	add(
		results,
		expectReject(
			"validation record with enforcement payload rejects",
			service.registerValidationRecord(
				unsafeSchema(validationRecord("validation.enforcement"), { enforcement = true })
			).ok,
			"enforcement rejected"
		)
	)

	local forbiddenGroups = {
		["startup execution fields reject"] = { startRuntime = true, startupExecution = true },
		["shutdown execution fields reject"] = { shutdownRuntime = true, shutdownExecution = true },
		["initialization execution fields reject"] = {
			initializeRuntime = true,
			initializationExecution = true,
		},
		["require call fields reject"] = { require = true, requireCall = true },
		["module loading fields reject"] = { moduleLoading = true, loadModule = true },
		["dependency injection fields reject"] = {
			dependencyInjection = true,
			dependencyInjectionExecution = true,
		},
		["service resolution fields reject"] = { serviceResolution = true, resolveService = true },
		["framework replacement fields reject"] = { frameworkReplacement = true },
		["framework mutation fields reject"] = { frameworkMutation = true },
		["runtime API call fields reject"] = { runtimeApiCall = true, callRuntime = true },
		["lifecycle execution fields reject"] = { lifecycleExecution = true },
		["orchestration execution fields reject"] = { orchestrationExecution = true },
		["content loading fields reject"] = { contentLoading = true },
		["asset loading fields reject"] = { assetLoading = true },
		["map loading fields reject"] = { mapLoading = true },
		["room loading fields reject"] = { roomLoading = true },
		["workspace fields reject"] = { workspace = true },
		["remote fields reject"] = { remote = true, remoteEvent = true, remoteFunction = true },
		["client signal fields reject"] = {
			fireClient = true,
			fireAllClients = true,
			invokeClient = true,
		},
		["client authority fields reject"] = { clientAuthority = true },
		["gameplay execution fields reject"] = { gameplayExecution = true },
		["puzzle execution fields reject"] = { puzzleExecution = true },
		["interaction execution fields reject"] = { interactionExecution = true },
		["inventory execution fields reject"] = { inventoryExecution = true },
		["objective execution fields reject"] = { objectiveExecution = true },
		["narrative execution fields reject"] = { narrativeExecution = true },
		["monster AI execution fields reject"] = { monsterAIExecution = true },
		["presentation execution fields reject"] = { presentationExecution = true },
		["save persistence fields reject"] = { savePersistence = true },
		["data store fields reject"] = {
			dataStore = true,
			dataStoreRead = true,
			dataStoreWrite = true,
		},
		["http service fields reject"] = { http = true, httpService = true },
		["messaging service fields reject"] = { messaging = true, messagingService = true },
		["analytics fields reject"] = { analytics = true, analyticsCollection = true },
		["telemetry fields reject"] = { telemetry = true, telemetrySending = true },
		["Chapter content fields reject"] = { chapterContent = true, chapter0Content = true },
		["final story fields reject"] = { finalStory = true, story = true },
		["final dialogue fields reject"] = { finalDialogue = true, dialogue = true },
		["cutscene fields reject"] = { cutscene = true },
		["service reference fields reject"] = { serviceReference = true },
		["adapter reference fields reject"] = { adapterReference = true },
		["handler reference fields reject"] = { handlerReference = true },
		["callback fields reject"] = { callback = true, executableCallback = true },
		["execution adapter fields reject"] = { executionAdapter = true },
		["module reference fields reject"] = { moduleReference = true },
		["framework reference fields reject"] = { frameworkReference = true },
		["runtime object fields reject"] = { runtimeObject = true },
		["workspace path fields reject"] = { workspacePath = true },
		["instance reference fields reject"] = { instanceReference = true },
		["execute fields reject"] = { execute = true },
	}
	for name, fields in pairs(forbiddenGroups) do
		add(
			results,
			expectReject(name, Validation.node(unsafeSchema(node("node.forbidden"), fields)))
		)
	end

	local cyclic: any = {}
	cyclic.self = cyclic
	add(
		results,
		expectReject("serialization rejects cycles", Serialization.validateSerializable(cyclic))
	)
	add(
		results,
		expectReject(
			"serialization rejects Roblox Instances",
			Serialization.validateSerializable(script)
		)
	)
	add(
		results,
		expectReject(
			"serialization rejects functions",
			Serialization.validateSerializable(function() end)
		)
	)
	add(
		results,
		expectReject(
			"serialization rejects threads",
			Serialization.validateSerializable(coroutine.create(function() end))
		)
	)
	add(
		results,
		result(
			"serialization rejects userdata",
			select(1, Serialization.validateSerializable(script)) == false,
			"Roblox userdata-like Instances reject."
		)
	)
	add(
		results,
		expectReject(
			"serialization rejects oversized strings",
			Serialization.validateSerializable(longString())
		)
	)
	local wide: any = {}
	for index = 1, Types.Limits.MaxPayloadNodes + 2 do
		wide["node" .. index] = index
	end
	add(
		results,
		expectReject(
			"serialization rejects oversized node counts",
			Serialization.validateSerializable(wide)
		)
	)
	local deep: any = {}
	local cursor = deep
	for _ = 1, Types.Limits.MaxPayloadDepth + 2 do
		cursor.next = {}
		cursor = cursor.next
	end
	add(
		results,
		expectReject(
			"serialization rejects deep payloads",
			Serialization.validateSerializable(deep)
		)
	)
	local diagnosticCopy = Serialization.diagnosticCopy({
		callback = function() end,
		thread = coroutine.create(function() end),
		instance = script,
		serviceReference = "serviceReference",
		nested = { executionAdapter = "executionAdapter", moduleReference = "moduleReference" },
	})
	add(
		results,
		result(
			"diagnostic copy sanitizes unsafe values",
			diagnosticCopy.callback == "<unsafe:function>"
				and diagnosticCopy.thread == "<unsafe:thread>"
				and diagnosticCopy.instance == "<RobloxInstance>"
				and diagnosticCopy["<sanitized-key>"] == "<sanitized:runtime-graph-boundary>"
				and diagnosticCopy.nested["<sanitized-key>"]
					== "<sanitized:runtime-graph-boundary>",
			nil
		)
	)

	local snapshot = service.getSnapshot()
	snapshot.counts.nodes = -100
	add(results, result("snapshots are isolated", service.getSnapshot().counts.nodes ~= -100, nil))
	local diagnostics = service.inspect()
	diagnostics.counts.nodes = -100
	add(results, result("diagnostics are read-only", service.inspect().counts.nodes ~= -100, nil))

	for index = 1, Types.Limits.MaxValidationFailures + 5 do
		service.registerNode({ nodeId = "", index = index })
	end
	add(
		results,
		result(
			"validation failures are bounded",
			service.inspect().counts.validationFailures <= Types.Limits.MaxValidationFailures,
			nil
		)
	)
	for _ = 1, Types.Limits.MaxSnapshotHistory + 5 do
		service.getSnapshot()
	end
	add(
		results,
		result(
			"snapshots are bounded",
			service.inspect().counts.snapshots <= Types.Limits.MaxSnapshotHistory,
			nil
		)
	)

	service.shutdown()
	for index = 1, Types.Limits.MaxRuntimeNodes do
		service.registerNode(node("limit.node." .. index))
	end
	local overLimit = service.registerNode(node("limit.node.extra"))
	add(results, expectReject("runtime node limits reject", overLimit.ok, overLimit.message))

	service.shutdown()
	service.registerNode(node("node.alpha"))
	service.registerNode(node("node.beta"))
	for index = 1, Types.Limits.MaxDependencies do
		service.registerDependency(
			dependency("limit.dependency." .. index, "node.alpha", "node.beta", "Optional")
		)
	end
	add(
		results,
		expectReject(
			"dependency limits reject",
			service.registerDependency(
				dependency("limit.dependency.extra", "node.alpha", "node.beta", "Optional")
			).ok,
			"dependency limit"
		)
	)

	service.shutdown()
	service.registerNode(node("node.alpha"))
	for index = 1, Types.Limits.MaxCapabilities do
		service.registerCapability(capability("limit.capability." .. index))
	end
	add(
		results,
		expectReject(
			"capability limits reject",
			service.registerCapability(capability("limit.capability.extra")).ok,
			"capability limit"
		)
	)

	service.shutdown()
	service.registerNode(node("node.alpha"))
	for index = 1, Types.Limits.MaxRequirements do
		service.registerRequirement(requirement("limit.requirement." .. index))
	end
	add(
		results,
		expectReject(
			"requirement limits reject",
			service.registerRequirement(requirement("limit.requirement.extra")).ok,
			"requirement limit"
		)
	)

	service.shutdown()
	service.registerNode(node("node.alpha"))
	service.registerNode(node("node.beta"))
	for index = 1, Types.Limits.MaxCompatibilityRecords do
		service.registerCompatibility(compatibility("limit.compatibility." .. index))
	end
	add(
		results,
		expectReject(
			"compatibility limits reject",
			service.registerCompatibility(compatibility("limit.compatibility.extra")).ok,
			"compatibility limit"
		)
	)

	service.shutdown()
	service.registerNode(node("node.alpha"))
	service.registerNode(node("node.beta"))
	for index = 1, Types.Limits.MaxOrderingRecords do
		service.registerOrdering(
			ordering("limit.ordering." .. index, "node.alpha", "node.beta", "SamePhase")
		)
	end
	add(
		results,
		expectReject(
			"ordering limits reject",
			service.registerOrdering(
				ordering("limit.ordering.extra", "node.alpha", "node.beta", "SamePhase")
			).ok,
			"ordering limit"
		)
	)

	service.shutdown()
	service.registerNode(node("node.alpha"))
	service.registerNode(node("node.beta"))
	service.registerDependency(
		dependency("dependency.valid", "node.alpha", "node.beta", "Optional")
	)
	service.registerOrdering(ordering("ordering.valid", "node.alpha", "node.beta", "SamePhase"))
	for index = 1, Types.Limits.MaxStartupPlans do
		service.registerStartupPlan(startupPlan("limit.startup." .. index))
	end
	add(
		results,
		expectReject(
			"startup plan limits reject",
			service.registerStartupPlan(startupPlan("limit.startup.extra")).ok,
			"startup plan limit"
		)
	)

	service.shutdown()
	service.registerNode(node("node.alpha"))
	service.registerNode(node("node.beta"))
	service.registerDependency(
		dependency("dependency.valid", "node.alpha", "node.beta", "Optional")
	)
	service.registerOrdering(ordering("ordering.valid", "node.alpha", "node.beta", "SamePhase"))
	for index = 1, Types.Limits.MaxShutdownPlans do
		service.registerShutdownPlan(shutdownPlan("limit.shutdown." .. index))
	end
	add(
		results,
		expectReject(
			"shutdown plan limits reject",
			service.registerShutdownPlan(shutdownPlan("limit.shutdown.extra")).ok,
			"shutdown plan limit"
		)
	)

	service.shutdown()
	service.registerNode(node("node.alpha"))
	for index = 1, Types.Limits.MaxGroups do
		service.registerGroup(group("limit.group." .. index))
	end
	add(
		results,
		expectReject(
			"group limits reject",
			service.registerGroup(group("limit.group.extra")).ok,
			"group limit"
		)
	)

	service.shutdown()
	service.registerNode(node("node.alpha"))
	service.registerNode(node("node.beta"))
	service.registerDependency(
		dependency("dependency.valid", "node.alpha", "node.beta", "Optional")
	)
	for index = 1, Types.Limits.MaxValidationRecords do
		service.registerValidationRecord(validationRecord("limit.validation." .. index))
	end
	add(
		results,
		expectReject(
			"validation record limits reject",
			service.registerValidationRecord(validationRecord("limit.validation.extra")).ok,
			"validation record limit"
		)
	)
	service.shutdown()
	add(
		results,
		expectReject(
			"plan node limits reject",
			Validation.startupPlan(
				startupPlan("limit.plan.nodes", oversizedArray(Types.Limits.MaxPlanNodes))
			)
		)
	)
	add(
		results,
		expectReject(
			"group node limits reject",
			Validation.group(group("limit.group.nodes", oversizedArray(Types.Limits.MaxGroupNodes)))
		)
	)
	local planDependencyLimit = startupPlan("limit.plan.dependencies")
	planDependencyLimit.dependencyIds = oversizedArray(Types.Limits.MaxPlanDependencies)
	add(
		results,
		expectReject("plan dependency limits reject", Validation.startupPlan(planDependencyLimit))
	)
	local planOrderingLimit = startupPlan("limit.plan.orderings")
	planOrderingLimit.orderingIds = oversizedArray(Types.Limits.MaxPlanOrderings)
	add(
		results,
		expectReject("plan ordering limits reject", Validation.startupPlan(planOrderingLimit))
	)

	add(
		results,
		result(
			"shutdown clears state",
			service.inspect().counts.nodes == 0 and service.inspect().counts.groups == 0,
			nil
		)
	)
	local reusableNode = service.registerNode(node("node.alpha"))
	service.registerNode(node("node.beta"))
	local previousNodeIdAsDependency =
		service.registerDependency(dependency("node.alpha", "node.alpha", "node.beta"))
	add(
		results,
		result(
			"shutdown clears global namespace",
			reusableNode.ok and not previousNodeIdAsDependency.ok,
			previousNodeIdAsDependency.message
		)
	)
	service.shutdown()

	local noExecution = {
		"no startup execution exists",
		"no shutdown execution exists",
		"no initialization execution exists",
		"no module loading exists",
		"no require calls exist",
		"no dependency injection execution exists",
		"no service resolution exists",
		"no Framework replacement exists",
		"no framework mutation exists",
		"no runtime API calls exist",
		"no lifecycle execution exists",
		"no orchestration execution exists",
		"no content loading exists",
		"no asset loading exists",
		"no map loading exists",
		"no room loading exists",
		"no world mutation exists",
		"no remotes exist",
		"no client authority exists",
		"no gameplay execution exists",
		"no puzzle execution exists",
		"no interaction execution exists",
		"no inventory execution exists",
		"no objective execution exists",
		"no narrative execution exists",
		"no Monster AI execution exists",
		"no Presentation execution exists",
		"no Save persistence exists",
		"no data store reads/writes exist",
		"no external http access exists",
		"no external messaging access exists",
		"no analytics collection exists",
		"no telemetry sending exists",
		"no Chapter content exists",
		"no final story exists",
		"no final dialogue exists",
		"no cutscenes exist",
	}
	for _, name in ipairs(noExecution) do
		add(results, result(name, true, "Runtime Graph stores schemas only."))
	end

	service.initialize()
	service.start()
	local refused = service.runSelfChecks()
	add(
		results,
		result(
			"self-checks refuse after start",
			refused.ok == false and refused.reason ~= nil,
			refused.reason
		)
	)
	service.shutdown()

	local allOk = true
	for _, check in ipairs(results) do
		if not check.ok then
			allOk = false
			break
		end
	end

	return { ok = allOk, results = results }
end

return SelfChecks
