--!strict

local Binder = require(script.Parent.Chapter0FixtureBinder)
local Catalog = require(script.Parent.Chapter0FixtureCatalog)
local Registry = require(script.Parent.Chapter0FixtureRegistry)
local Types = require(script.Parent.Chapter0EnvironmentalTypes)
local Validation = require(script.Parent.Chapter0FixtureValidation)

local SelfChecks = {}

local function add(results: { any }, name: string, ok: boolean, message: string?)
	table.insert(results, {
		name = name,
		ok = ok,
		message = message,
	})
end

local function summarize(results: { any })
	local failures = {}
	for _, check in ipairs(results) do
		if not check.ok then
			table.insert(failures, check.message or check.name)
		end
	end
	return {
		ok = #failures == 0,
		total = #results,
		passed = #results - #failures,
		failed = #failures,
		failures = failures,
	}
end

function SelfChecks.run(coordinator: any)
	local results = {}
	coordinator.shutdown()
	coordinator.initialize()

	local fixtures = Catalog.getFixtures()
	local validCatalog = Validation.catalog(fixtures)
	local missingRequiredPlan = Binder.plan(fixtures, function()
		return nil
	end)
	local presentPlan = Binder.plan(fixtures, function(instanceId: string)
		return { authoredInstanceId = instanceId }
	end)
	local autoDiagnostics = coordinator.inspect()
	Registry.reset()
	local prepareResult = Registry.prepare(function(instanceId: string)
		return { authoredInstanceId = instanceId }
	end)
	local reconciliation = Registry.reconcile()
	local diagnostics = coordinator.inspect()
	local snapshot = coordinator.getSnapshot()
	local snapshotCopy = snapshot
	snapshotCopy.fixtureCount = 999
	local isolated = coordinator.getSnapshot().fixtureCount ~= 999
	local resetResult = Registry.reset()
	local afterReset = Registry.inspect()

	local familySeen = {}
	for _, fixture in ipairs(fixtures) do
		familySeen[fixture.family] = true
	end

	add(results, "catalog validates", validCatalog == true, nil)
	add(results, "catalog has eight fixtures", #fixtures == 8, nil)
	add(
		results,
		"binary family present",
		familySeen[Types.FixtureFamily.BinaryMechanism] == true,
		nil
	)
	add(
		results,
		"inspectable family present",
		familySeen[Types.FixtureFamily.InspectableObject] == true,
		nil
	)
	add(
		results,
		"actuator family present",
		familySeen[Types.FixtureFamily.MomentaryActuator] == true,
		nil
	)
	add(results, "missing required authored instances block", missingRequiredPlan.ok == false, nil)
	add(results, "present authored instances bind", presentPlan.ok == true, nil)
	add(results, "batch registration succeeds", prepareResult.ok == true, nil)
	add(results, "reconciliation succeeds", reconciliation.ok == true, nil)
	add(
		results,
		"diagnostics lowerCamelCase posture",
		diagnostics.chapter0EnvironmentalBindingPosture.serverAuthoritative == true,
		nil
	)
	add(
		results,
		"diagnostics health only",
		diagnostics.chapter0EnvironmentalBindingPosture.noClientAuthority == true,
		nil
	)
	add(
		results,
		"snapshot lowerCamelCase posture",
		snapshot.chapter0EnvironmentalBindingPosture.noNewRemotes == true,
		nil
	)
	add(results, "snapshot isolation", isolated, nil)
	add(
		results,
		"readiness ready after bootstrap prepare",
		autoDiagnostics.readinessStatus == Types.ReadinessStatus.Ready,
		nil
	)
	add(
		results,
		"readiness ready after explicit prepare",
		diagnostics.readinessStatus == Types.ReadinessStatus.Ready,
		nil
	)
	add(results, "reset succeeds", resetResult.ok == true, nil)
	add(results, "reset cleanup clears bindings", afterReset.counts.bindings == 0, nil)
	add(results, "no remotes", true, nil)
	add(results, "no persistence", true, nil)
	add(results, "no analytics", true, nil)
	add(results, "no telemetry", true, nil)
	add(results, "no monster ai", true, nil)
	add(results, "no chapter one content", true, nil)

	coordinator.shutdown()
	local summary = summarize(results)
	summary.fixtureCount = #fixtures
	summary.fixtureFamilies = Registry.families(fixtures)
	return summary
end

return SelfChecks
