--!strict

local ServerScriptService = game:GetService("ServerScriptService")

local EnvironmentalInteractionCoordinator =
	require(ServerScriptService.Interaction.Environmental.EnvironmentalInteractionCoordinator)
local EnvironmentalSerialization =
	require(ServerScriptService.Interaction.Environmental.EnvironmentalSerialization)

local Binder = require(script.Parent.Chapter0FixtureBinder)
local Catalog = require(script.Parent.Chapter0FixtureCatalog)
local State = require(script.Parent.Chapter0EnvironmentalState)
local Types = require(script.Parent.Chapter0EnvironmentalTypes)
local Validation = require(script.Parent.Chapter0FixtureValidation)

local Registry = {}

local function result(ok: boolean, code: string, message: string?, extra: any?)
	local payload = extra or {}
	payload.ok = ok
	payload.code = code
	payload.message = message
	return payload
end

function Registry.prepare(resolver: ((string) -> any?)?)
	local fixtures = Catalog.getFixtures()
	local valid, reason = Validation.catalog(fixtures)
	if not valid then
		State.recordFailure(reason or Types.ResultCode.InvalidFixture, fixtures)
		State.setStatus(Types.ReadinessStatus.Blocked)
		return result(false, reason or Types.ResultCode.InvalidFixture, "fixture catalog rejected")
	end

	local bindingResolver = resolver or function()
		return { catalogAuthoredReference = true }
	end
	local bindingPlan = Binder.plan(fixtures, bindingResolver)
	if not bindingPlan.ok then
		for _, failure in ipairs(bindingPlan.failures) do
			State.recordFailure(failure.code, failure)
		end
		State.setStatus(Types.ReadinessStatus.Blocked)
		return result(false, Types.ResultCode.BindingFailed, "authored fixture binding failed", {
			bindingPlan = bindingPlan,
		})
	end

	local registered = EnvironmentalInteractionCoordinator.registerDefinitions(
		EnvironmentalSerialization.deepCopy(fixtures)
	)
	if not registered.ok then
		State.recordFailure(Types.ResultCode.BatchRollback, registered)
		State.setStatus(Types.ReadinessStatus.Blocked)
		return result(
			false,
			Types.ResultCode.BatchRollback,
			"environmental batch registration failed",
			{
				registration = registered,
				bindingPlan = bindingPlan,
			}
		)
	end

	for _, fixture in ipairs(fixtures) do
		State.bind(fixture, Types.BindingStatus.Bound, nil)
	end
	State.setStatus(Types.ReadinessStatus.Ready)
	State.recordEvidence("Chapter0EnvironmentalFixturesBound", {
		fixtureCount = #fixtures,
		families = Registry.families(fixtures),
		warnings = bindingPlan.warnings,
	})
	return result(true, Types.ResultCode.Ok, "chapter0 environmental fixtures bound", {
		fixtureCount = #fixtures,
		bindingPlan = bindingPlan,
		registration = registered,
	})
end

function Registry.reset()
	State.setStatus(Types.ReadinessStatus.Resetting)
	for _, fixture in ipairs(Catalog.getFixtures()) do
		EnvironmentalInteractionCoordinator.unregisterObject(fixture.id)
	end
	State.clear()
	State.recordEvidence("Chapter0EnvironmentalFixturesReset", {
		fixtureCount = #Catalog.getFixtures(),
	})
	return result(true, Types.ResultCode.Ok, "chapter0 environmental fixtures reset")
end

function Registry.reconcile()
	local environmental = EnvironmentalInteractionCoordinator.reconcile()
	local state = State.inspect()
	local findings = {}
	for _, fixture in ipairs(Catalog.getFixtures()) do
		if state.bindings[fixture.id] == nil then
			table.insert(findings, {
				fixtureId = fixture.id,
				code = Types.ResultCode.MissingFixture,
				message = "fixture is missing a Chapter0 binding record",
			})
		end
	end
	if environmental.ok ~= true then
		table.insert(findings, {
			code = Types.ResultCode.ReconciliationFailed,
			message = "environmental runtime reconciliation failed",
			environmental = environmental,
		})
	end
	local ok = #findings == 0
	if not ok then
		State.recordFailure(Types.ResultCode.ReconciliationFailed, findings)
		State.setStatus(Types.ReadinessStatus.Blocked)
	end
	return result(
		ok,
		if ok then Types.ResultCode.Ok else Types.ResultCode.ReconciliationFailed,
		"chapter0 environmental reconciliation complete",
		{
			findings = findings,
			environmental = environmental,
		}
	)
end

function Registry.families(fixtures: { any }?): { string }
	local familyMap = {}
	local names = {}
	for _, fixture in ipairs(fixtures or Catalog.getFixtures()) do
		if familyMap[fixture.family] ~= true then
			familyMap[fixture.family] = true
			table.insert(names, fixture.family)
		end
	end
	table.sort(names)
	return names
end

function Registry.inspect()
	local snapshot = State.inspect()
	snapshot.catalog = EnvironmentalSerialization.deepCopy(Catalog.getFixtures())
	snapshot.familyCatalog = Registry.families()
	return snapshot
end

return Registry
