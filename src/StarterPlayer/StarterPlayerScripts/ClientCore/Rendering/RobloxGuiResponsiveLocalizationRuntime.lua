--!strict

local Catalog = require(script.Parent.RobloxGuiLocalizationCatalog)
local Resolver = require(script.Parent.RobloxGuiResponsiveResolver)
local Types = require(script.Parent.RobloxGuiResponsiveLocalizationTypes)

local Runtime = {}
local shutdown = false
local locale = Types.DefaultLocale
local generation = 0
local context = { viewport = Vector2.new(1280, 720), safeInsets = { left = 0, top = 0, right = 0, bottom = 0 } }
local failures = {}
local audit = {}
local counters = { reconciliations = 0, localized = 0, missingKeys = 0, policiesApplied = 0, staleRejected = 0 }
local active = nil :: any

local function append(target: { any }, item: any, limit: number)
	if #target >= limit then table.remove(target, 1) end
	target[#target + 1] = item
end

local function record(kind: string, detail: any?)
	append(audit, table.freeze({ generation = generation, kind = kind, detail = detail }), Types.Limits.maxAudit)
end

local function fail(code: string, detail: any?)
	local result = table.freeze({ ok = false, code = code, detail = detail })
	append(failures, result, Types.Limits.maxFailures)
	record("Failure", result)
	return result
end

local function interpolate(template: string, arguments: any): (boolean, string)
	local seen = 0
	local missing = nil :: string?
	local output = string.gsub(template, "{([%w_]+)}", function(name)
		seen += 1
		if seen > Types.Limits.maxPlaceholders or type(arguments) ~= "table" or arguments[name] == nil then
			missing = name
			return ""
		end
		local value = arguments[name]
		if type(value) ~= "string" and type(value) ~= "number" then missing = name return "" end
		return tostring(value)
	end)
	return missing == nil, output
end

function Runtime.registerBundle(bundleLocale: any, entries: any)
	if shutdown then return fail(Types.FailureType.RuntimeShutdown) end
	local ok, reason = Catalog.register(bundleLocale, entries)
	if not ok then return fail(reason or Types.FailureType.InvalidBundle) end
	record("BundleRegistered", { locale = bundleLocale })
	return { ok = true }
end

function Runtime.setLocale(value: any)
	if shutdown then return fail(Types.FailureType.RuntimeShutdown) end
	if type(value) ~= "string" or not string.match(value, "^[%a][%a][%a]?[-_]?[%a]*$") then
		return fail(Types.FailureType.InvalidLocale)
	end
	locale = string.lower(string.gsub(value, "_", "-"))
	generation += 1
	record("LocaleChanged", { locale = locale })
	if active then
		local refreshed = Runtime.reconcile(active.transaction, active.contract)
		if not refreshed.ok then return refreshed end
	end
	return { ok = true, locale = locale, generation = generation }
end

function Runtime.setContext(viewport: any, safeInsets: any)
	if shutdown then return fail(Types.FailureType.RuntimeShutdown) end
	if typeof(viewport) ~= "Vector2" or viewport.X <= 0 or viewport.Y <= 0 or type(safeInsets) ~= "table" then
		return fail(Types.FailureType.InvalidContext)
	end
	for _, key in ipairs({ "left", "top", "right", "bottom" }) do
		local inset = safeInsets[key]
		if type(inset) ~= "number" or inset ~= inset or inset < 0 or inset == math.huge then
			return fail(Types.FailureType.InvalidContext, key)
		end
	end
	context = { viewport = viewport, safeInsets = table.clone(safeInsets) }
	generation += 1
	record("ContextChanged", { viewportClass = Resolver.classify(viewport) })
	if active then
		local refreshed = Runtime.reconcile(active.transaction, active.contract)
		if not refreshed.ok then return refreshed end
	end
	return { ok = true, generation = generation }
end

function Runtime.reconcile(transaction: any, contract: any)
	if shutdown then return fail(Types.FailureType.RuntimeShutdown) end
	generation += 1
	local expected = generation
	local plans = {}
	for _, node in ipairs(contract.nodes) do
		if expected ~= generation then counters.staleRejected += 1 return fail(Types.FailureType.StaleGeneration) end
		local instance = transaction.instances[node.nodeId]
		if not instance or instance:GetAttribute("LondonEngineContractId") ~= contract.contractId then
			return fail(Types.FailureType.OwnershipViolation, node.nodeId)
		end
		local plan = { instance = instance, attributes = {}, properties = {} }
		if type(node.responsive) == "table" then
			local ok, resolved = Resolver.resolve(node.responsive.policy, context.viewport, context.safeInsets)
			if not ok then return fail(Types.FailureType.UnsupportedResponsivePolicy, node.nodeId) end
			plan.attributes.LondonEngineViewportClass = resolved.viewportClass
			plan.attributes.LondonEngineResolvedScale = resolved.scale
			plan.attributes.LondonEngineResolvedTextScale = resolved.textScale
		end
		for propertyName, descriptor in pairs(node.properties) do
			if type(descriptor) == "table" and descriptor.kind == "LocalizationReference" then
				local key = descriptor.value or descriptor.key
				local template, resolvedLocale = Catalog.resolve(locale, key)
				if not template then counters.missingKeys += 1 return fail(Types.FailureType.MissingLocalizationKey, key) end
				local valid, text = interpolate(template, descriptor.arguments)
				if not valid then return fail(Types.FailureType.InvalidPlaceholder, key) end
				plan.properties[propertyName] = text
				plan.attributes.LondonEngineResolvedLocale = resolvedLocale
			end
		end
		plans[#plans + 1] = plan
	end
	for _, plan in ipairs(plans) do
		for attribute, value in pairs(plan.attributes) do plan.instance:SetAttribute(attribute, value) end
		for propertyName, text in pairs(plan.properties) do
			local okAssign = pcall(function() (plan.instance :: any)[propertyName] = text end)
			if not okAssign then return fail(Types.FailureType.OwnershipViolation, propertyName) end
			counters.localized += 1
		end
		if plan.attributes.LondonEngineViewportClass ~= nil then counters.policiesApplied += 1 end
	end
	counters.reconciliations += 1
	record("Reconciled", { contractId = contract.contractId, revision = contract.targetRevision })
	return { ok = true, generation = generation, locale = locale, viewportClass = Resolver.classify(context.viewport) }
end

function Runtime.activate(transaction: any, contract: any)
	active = { transaction = transaction, contract = contract }
	record("Activated", { contractId = contract.contractId, revision = contract.targetRevision })
	return { ok = true, generation = generation }
end

function Runtime.clearActive(transaction: any?)
	if transaction == nil or (active and active.transaction == transaction) then active = nil end
end

function Runtime.inspect()
	return { runtimeVersion = Types.RuntimeVersion, locale = locale, generation = generation, viewportClass = Resolver.classify(context.viewport), catalog = Catalog.inspect(), counters = table.clone(counters), failures = table.clone(failures), posture = { clientPresentationOnly = true, noGameplayAuthority = true, noNetworking = true, noPersistence = true, noAnalytics = true, noTelemetry = true } }
end

function Runtime.getSnapshot() return { diagnostics = Runtime.inspect(), audit = table.clone(audit) } end
function Runtime.shutdown() shutdown = true active = nil Catalog.clear() table.clear(audit) record("Shutdown") end

return Runtime
