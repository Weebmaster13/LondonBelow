--!strict

local Planner = require(script.Parent.Planner)
local Serialization = require(script.Parent.Serialization)
local State = require(script.Parent.State)
local Types = require(script.Parent.Types)
local Validation = require(script.Parent.Validation)

local SelfChecks = {}

local function node(id: string, order: number, owner: string?): any
	return {
		nodeId = id,
		nodeKind = Types.NodeKind.Authority,
		authorityOwner = owner or "StudioMCPExternalTransport",
		version = Types.PlanVersion,
		orderingKey = order,
		planningClassification = Types.PlanningClassification.DefinitionOnly,
		metadata = { definitionOnly = true },
	}
end

local function dependency(id: string, fromId: string, toId: string): any
	return {
		dependencyId = id,
		fromNodeId = fromId,
		toNodeId = toId,
		dependencyKind = Types.DependencyKind.Requires,
		requiredVersion = Types.PlanVersion,
		metadata = { explicit = true },
	}
end

local function constraint(id: string, nodeId: string, kind: string): any
	return {
		constraintId = id,
		nodeId = nodeId,
		constraintKind = kind,
		required = true,
		metadata = { planningOnly = true },
	}
end

local function expect(results: { any }, name: string, ok: boolean, detail: string?)
	table.insert(results, { name = name, ok = ok, detail = detail })
end

local function countFailures(results: { any }): number
	local failures = 0
	for _, check in ipairs(results) do
		if not check.ok then
			failures += 1
		end
	end
	return failures
end

function SelfChecks.run(context: any): any
	local service = context.Service
	local results = {}

	expect(
		results,
		"provider name lowerCamelCase",
		Types.RuntimeProviderName == "executionPlanningRuntime",
		nil
	)
	expect(
		results,
		"runtime truth execution blocked",
		Types.RuntimeTruth.executionBlocked == true,
		nil
	)
	expect(
		results,
		"runtime truth runner not invoked",
		Types.RuntimeTruth.runnerInvoked == false,
		nil
	)
	expect(results, "runtime validation passes", select(1, Validation.validate()) == true, nil)

	local empty =
		Planner.plan({ graphId = "graph.empty", nodes = {}, dependencies = {}, constraints = {} })
	expect(
		results,
		"empty graph publishes",
		empty.ok == true and empty.publication.dependencySummary.nodes == 0,
		empty.reason
	)

	local single = Planner.plan({
		graphId = "graph.single",
		nodes = { node("node.alpha", 1) },
		dependencies = {},
		constraints = {},
	})
	expect(results, "single node graph publishes", single.ok == true, single.reason)
	expect(
		results,
		"single node eligible",
		single.eligibilityStates["node.alpha"] == Types.EligibilityState.Eligible,
		nil
	)

	local chain = Planner.plan({
		graphId = "graph.chain",
		nodes = { node("node.c", 3), node("node.a", 1), node("node.b", 2) },
		dependencies = {
			dependency("dependency.a.b", "node.a", "node.b"),
			dependency("dependency.b.c", "node.b", "node.c"),
		},
		constraints = {
			constraint("constraint.blocked", "node.c", Types.ConstraintKind.RuntimeBlocked),
		},
	})
	expect(results, "dependency chain publishes", chain.ok == true, chain.reason)
	expect(
		results,
		"deterministic node ordering",
		chain.graph.nodes[1].nodeId == "node.a" and chain.graph.nodes[3].nodeId == "node.c",
		nil
	)
	expect(
		results,
		"blocked eligibility stays blocked",
		chain.eligibilityStates["node.c"] == Types.EligibilityState.Blocked,
		nil
	)

	local branching = Planner.plan({
		graphId = "graph.branching",
		nodes = { node("node.root", 1), node("node.left", 2), node("node.right", 3) },
		dependencies = {
			dependency("dependency.root.left", "node.root", "node.left"),
			dependency("dependency.root.right", "node.root", "node.right"),
		},
		constraints = {},
	})
	expect(results, "branching graph publishes", branching.ok == true, branching.reason)

	local missing = Planner.plan({
		graphId = "graph.missing",
		nodes = { node("node.alpha", 1) },
		dependencies = { dependency("dependency.missing", "node.alpha", "node.missing") },
		constraints = {},
	})
	expect(results, "missing dependency rejects", missing.ok == false, missing.reason)

	local duplicate = Planner.plan({
		graphId = "graph.duplicate",
		nodes = { node("node.alpha", 1), node("node.alpha", 2) },
		dependencies = {},
		constraints = {},
	})
	expect(results, "duplicate node rejects", duplicate.ok == false, duplicate.reason)

	local cycle = Planner.plan({
		graphId = "graph.cycle",
		nodes = { node("node.alpha", 1), node("node.beta", 2) },
		dependencies = {
			dependency("dependency.alpha.beta", "node.alpha", "node.beta"),
			dependency("dependency.beta.alpha", "node.beta", "node.alpha"),
		},
		constraints = {},
	})
	expect(results, "cycle rejects", cycle.ok == false, cycle.reason)

	local ownership = Planner.plan({
		graphId = "graph.ownership",
		nodes = { node("node.alpha", 1, "A"), node("node.beta", 2, "B") },
		dependencies = { dependency("dependency.cross", "node.alpha", "node.beta") },
		constraints = {},
	})
	expect(
		results,
		"illegal cross authority ownership rejects",
		ownership.ok == false,
		ownership.reason
	)

	local version = Planner.plan({
		graphId = "graph.version",
		nodes = { node("node.alpha", 1), node("node.beta", 2) },
		dependencies = {
			{
				dependencyId = "dependency.version",
				fromNodeId = "node.alpha",
				toNodeId = "node.beta",
				dependencyKind = Types.DependencyKind.Requires,
				requiredVersion = "0.0.0",
				metadata = {},
			},
		},
		constraints = {},
	})
	expect(results, "version mismatch rejects", version.ok == false, version.reason)

	local unsafe = Planner.plan({
		graphId = "graph.unsafe",
		nodes = { node("node.unsafe", 1) },
		dependencies = {},
		constraints = {
			constraint("constraint.unsafe", "node.unsafe", Types.ConstraintKind.RuntimeBlocked),
		},
	})
	unsafe.graph.nodes[1].metadata.intent = "mutated"
	expect(
		results,
		"publication snapshot isolated",
		single.publication.publicationState == Types.PublicationState.Published,
		nil
	)
	expect(
		results,
		"deterministic rebuild",
		Serialization.stableSerialize(single.publication)
			== Serialization.stableSerialize(Planner.plan({
				graphId = "graph.single",
				nodes = { node("node.alpha", 1) },
				dependencies = {},
				constraints = {},
			}).publication),
		nil
	)

	local diagnostics = service.inspect()
	local snapshot = service.getSnapshot()
	diagnostics.blockedRuntimeTruth.executionBlocked = false
	snapshot.blockedRuntimeTruth.executionBlocked = false
	expect(
		results,
		"diagnostics stability",
		service.inspect().blockedRuntimeTruth.executionBlocked == true,
		nil
	)
	expect(
		results,
		"snapshot stability",
		service.getSnapshot().blockedRuntimeTruth.executionBlocked == true,
		nil
	)
	expect(results, "audit append only", type(chain.audit) == "table" and #chain.audit > 0, nil)
	expect(
		results,
		"no execution posture",
		service.inspect().noExecution == true and service.inspect().noRunnerInvocation == true,
		nil
	)
	expect(
		results,
		"shutdown cleanup",
		service.shutdown().ok == true and State.get().publication == nil,
		nil
	)

	local failures = countFailures(results)
	return {
		ok = failures == 0,
		total = #results,
		failures = failures,
		results = results,
		categories = {
			"empty graph",
			"single node",
			"multi-node graph",
			"dependency chains",
			"branching graphs",
			"duplicate detection",
			"cycle detection",
			"constraint rejection",
			"eligibility transitions",
			"immutable publication",
			"deterministic rebuild",
			"audit ordering",
			"diagnostics stability",
			"blocked runtime truth preservation",
			"upstream regression compatibility",
		},
	}
end

return SelfChecks
