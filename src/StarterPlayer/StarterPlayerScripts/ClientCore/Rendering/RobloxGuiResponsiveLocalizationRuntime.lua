--!strict

local Catalog = require(script.Parent.RobloxGuiLocalizationCatalog)
local Formatter = require(script.Parent.RobloxGuiLocalizationTemplateFormatter)
local LocaleValidator = require(script.Parent.RobloxGuiLocaleValidator)
local RefreshTransaction = require(script.Parent.RobloxGuiResponsiveRefreshTransaction)
local Resolver = require(script.Parent.RobloxGuiResponsiveResolver)
local Types = require(script.Parent.RobloxGuiResponsiveLocalizationTypes)

local Runtime = {}
local shutdown = false
local busy = false
local locale = Types.DefaultLocale
local generation = 0
local context =
	{ viewport = Vector2.new(1280, 720), safeInsets = { left = 0, top = 0, right = 0, bottom = 0 } }
local failures = {}
local audit = {}
local counters = {
	reconciliations = 0,
	localized = 0,
	missingKeys = 0,
	policiesApplied = 0,
	staleRejected = 0,
	rollbacks = 0,
	localeRollbacks = 0,
	contextRollbacks = 0,
	bundleIdempotent = 0,
	bundleRollbacks = 0,
}
local active = nil :: any
local failureInjector = nil :: ((string, number) -> boolean)?

local function append(target: { any }, item: any, limit: number)
	if #target >= limit then
		table.remove(target, 1)
	end
	target[#target + 1] = item
end

local function record(kind: string, detail: any?)
	append(
		audit,
		table.freeze({ generation = generation, kind = kind, detail = detail }),
		Types.Limits.maxAudit
	)
end

local function fail(code: string, detail: any?)
	local result = table.freeze({ ok = false, code = code, detail = detail })
	append(failures, result, Types.Limits.maxFailures)
	record("Failure", result)
	return result
end

local function validInsets(safeInsets: any): boolean
	if type(safeInsets) ~= "table" then
		return false
	end
	for _, key in ipairs({ "left", "top", "right", "bottom" }) do
		local inset = safeInsets[key]
		if type(inset) ~= "number" or inset ~= inset or inset < 0 or inset == math.huge then
			return false
		end
	end
	return true
end

function Runtime.registerBundle(bundleLocale: any, entries: any, revision: any?)
	if shutdown then
		return fail(Types.FailureType.RuntimeShutdown)
	end
	local validLocale, normalized = LocaleValidator.normalize(bundleLocale)
	if not validLocale or not normalized then
		return fail(Types.FailureType.InvalidLocale)
	end
	local previousBundle = Catalog.capture(normalized)
	local ok, reason, result = Catalog.register(bundleLocale, entries, revision)
	if not ok then
		return fail(reason or Types.FailureType.InvalidBundle)
	end
	if result and result.idempotent then
		counters.bundleIdempotent += 1
	end
	if active and result and not result.idempotent then
		local refreshed = Runtime.reconcile(active.transaction, active.contract)
		if not refreshed.ok then
			Catalog.restore(previousBundle)
			counters.bundleRollbacks += 1
			record("BundleRolledBack", { locale = normalized, revision = revision })
			return refreshed
		end
	end
	record("BundleRegistered", result)
	return { ok = true, bundle = result }
end

function Runtime.setLocale(value: any)
	if shutdown then
		return fail(Types.FailureType.RuntimeShutdown)
	end
	local validLocale, normalized = LocaleValidator.normalize(value)
	if not validLocale or not normalized then
		return fail(Types.FailureType.InvalidLocale)
	end
	if normalized == locale then
		return { ok = true, locale = locale, generation = generation, idempotent = true }
	end
	local previousLocale = locale
	locale = normalized
	generation += 1
	record("LocaleChanged", { locale = locale })
	if active then
		local refreshed = Runtime.reconcile(active.transaction, active.contract)
		if not refreshed.ok then
			locale = previousLocale
			counters.localeRollbacks += 1
			record("LocaleRolledBack", { locale = locale })
			return refreshed
		end
	end
	return { ok = true, locale = locale, generation = generation }
end

function Runtime.setContext(viewport: any, safeInsets: any)
	if shutdown then
		return fail(Types.FailureType.RuntimeShutdown)
	end
	if
		typeof(viewport) ~= "Vector2"
		or viewport.X <= 0
		or viewport.Y <= 0
		or not validInsets(safeInsets)
	then
		return fail(Types.FailureType.InvalidContext)
	end
	local previousContext = context
	context = { viewport = viewport, safeInsets = table.clone(safeInsets) }
	generation += 1
	record("ContextChanged", { viewportClass = Resolver.classify(viewport) })
	if active then
		local refreshed = Runtime.reconcile(active.transaction, active.contract)
		if not refreshed.ok then
			context = previousContext
			counters.contextRollbacks += 1
			record("ContextRolledBack", { viewportClass = Resolver.classify(context.viewport) })
			return refreshed
		end
	end
	return { ok = true, generation = generation }
end

function Runtime.reconcile(transaction: any, contract: any)
	if shutdown then
		return fail(Types.FailureType.RuntimeShutdown)
	end
	if busy then
		return fail(Types.FailureType.RuntimeBusy)
	end
	busy = true
	generation += 1
	local expected = generation
	local plans = {}
	for _, node in ipairs(contract.nodes) do
		if expected ~= generation then
			busy = false
			counters.staleRejected += 1
			return fail(Types.FailureType.StaleGeneration)
		end
		if #plans >= Types.Limits.maxRefreshPlans then
			busy = false
			return fail(Types.FailureType.InvalidContext, "refresh-plan-limit")
		end
		local instance = transaction.instances[node.nodeId]
		if
			not instance
			or instance:GetAttribute("LondonEngineContractId") ~= contract.contractId
		then
			busy = false
			return fail(Types.FailureType.OwnershipViolation, node.nodeId)
		end
		local plan = { instance = instance, attributes = {}, properties = {} }
		if type(node.responsive) == "table" then
			local ok, resolved =
				Resolver.resolve(node.responsive.policy, context.viewport, context.safeInsets)
			if not ok then
				busy = false
				return fail(Types.FailureType.UnsupportedResponsivePolicy, node.nodeId)
			end
			plan.attributes.LondonEngineViewportClass = resolved.viewportClass
			plan.attributes.LondonEngineResolvedScale = resolved.scale
			plan.attributes.LondonEngineResolvedTextScale = resolved.textScale
		end
		for propertyName, descriptor in pairs(node.properties) do
			if type(descriptor) == "table" and descriptor.kind == "LocalizationReference" then
				local key = descriptor.value or descriptor.key
				local template, resolvedLocale = Catalog.resolve(locale, key)
				if not template then
					busy = false
					counters.missingKeys += 1
					return fail(Types.FailureType.MissingLocalizationKey, key)
				end
				local valid, text, formatReason = Formatter.format(template, descriptor.arguments)
				if not valid or not text then
					busy = false
					return fail(formatReason or Types.FailureType.InvalidPlaceholder, key)
				end
				plan.properties[propertyName] = text
				plan.attributes.LondonEngineResolvedLocale = resolvedLocale
			end
		end
		plans[#plans + 1] = plan
	end
	local applied, rollbackOk = RefreshTransaction.apply(plans, failureInjector)
	if not applied then
		busy = false
		counters.rollbacks += 1
		return fail(
			rollbackOk and Types.FailureType.RefreshApplyFailed
				or Types.FailureType.RefreshRollbackFailed
		)
	end
	for _, plan in ipairs(plans) do
		for _ in pairs(plan.properties) do
			counters.localized += 1
		end
		if plan.attributes.LondonEngineViewportClass ~= nil then
			counters.policiesApplied += 1
		end
	end
	counters.reconciliations += 1
	busy = false
	record("Reconciled", { contractId = contract.contractId, revision = contract.targetRevision })
	return {
		ok = true,
		generation = generation,
		locale = locale,
		viewportClass = Resolver.classify(context.viewport),
	}
end

function Runtime.activate(transaction: any, contract: any)
	active = { transaction = transaction, contract = contract }
	record("Activated", { contractId = contract.contractId, revision = contract.targetRevision })
	return { ok = true, generation = generation }
end

function Runtime.clearActive(transaction: any?)
	if transaction == nil or (active and active.transaction == transaction) then
		active = nil
	end
end

function Runtime.setFailureInjector(injector: any)
	if injector ~= nil and type(injector) ~= "function" then
		return fail(Types.FailureType.InvalidContext, "failure-injector")
	end
	failureInjector = injector
	return { ok = true }
end

function Runtime.inspect()
	return {
		runtimeVersion = Types.RuntimeVersion,
		locale = locale,
		generation = generation,
		busy = busy,
		viewportClass = Resolver.classify(context.viewport),
		catalog = Catalog.inspect(),
		counters = table.clone(counters),
		failures = table.clone(failures),
		posture = {
			clientPresentationOnly = true,
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
	shutdown = true
	active = nil
	busy = false
	failureInjector = nil
	Catalog.clear()
	table.clear(audit)
	record("Shutdown")
end

return Runtime
