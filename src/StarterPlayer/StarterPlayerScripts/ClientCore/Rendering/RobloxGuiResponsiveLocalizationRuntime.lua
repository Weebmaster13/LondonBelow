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
	return { ok = true, locale = locale, generation = generation }
end

function Runtime.setContext(viewport: any, safeInsets: any)
	if shutdown then return fail(Types.FailureType.RuntimeShutdown) end
	if typeof(viewport) ~= "Vector2" or viewport.X <= 0 or viewport.Y <= 0 or type(safeInsets) ~= "table" then
		return fail(Types.FailureType.InvalidContext)
	end
	context = { viewport = viewport, safeInsets = table.clone(safeInsets) }
	generation += 1
	record("ContextChanged", { viewportClass = Resolver.classify(viewport) })
	return { ok = true, generation = generation }
end

function Runtime.reconcile(transaction: any, contract: any)
	if shutdown then return fail(Types.FailureType.RuntimeShutdown) end
	generation += 1
	local expected = generation
	for _, node in ipairs(contract.nodes) do
		if expected ~= generation then counters.staleRejected += 1 return fail(Types.FailureType.StaleGeneration) end
		local instance = transaction.instances[node.nodeId]
		if not instance or instance:GetAttribute("LondonEngineContractId") ~= contract.contractId then
			return fail(Types.FailureType.OwnershipViolation, node.nodeId)
		end
		if type(node.responsive) == "table" then
			local ok, resolved = Resolver.resolve(node.responsive.policy, context.viewport, context.safeInsets)
			if not ok then return fail(Types.FailureType.UnsupportedResponsivePolicy, node.nodeId) end
			instance:SetAttribute("LondonEngineViewportClass", resolved.viewportClass)
			instance:SetAttribute("LondonEngineResolvedScale", resolved.scale)
			instance:SetAttribute("LondonEngineResolvedTextScale", resolved.textScale)
			counters.policiesApplied += 1
		end
		for propertyName, descriptor in pairs(node.properties) do
			if type(descriptor) == "table" and descriptor.kind == "LocalizationReference" then
				local key = descriptor.value or descriptor.key
				local template, resolvedLocale = Catalog.resolve(locale, key)
				if not template then counters.missingKeys += 1 return fail(Types.FailureType.MissingLocalizationKey, key) end
				local valid, text = interpolate(template, descriptor.arguments)
				if not valid then return fail(Types.FailureType.InvalidPlaceholder, key) end
				local okAssign = pcall(function() (instance :: any)[propertyName] = text end)
				if not okAssign then return fail(Types.FailureType.OwnershipViolation, propertyName) end
				instance:SetAttribute("LondonEngineResolvedLocale", resolvedLocale)
				counters.localized += 1
			end
		end
	end
	counters.reconciliations += 1
	record("Reconciled", { contractId = contract.contractId, revision = contract.targetRevision })
	return { ok = true, generation = generation, locale = locale, viewportClass = Resolver.classify(context.viewport) }
end

function Runtime.inspect()
	return { runtimeVersion = Types.RuntimeVersion, locale = locale, generation = generation, viewportClass = Resolver.classify(context.viewport), catalog = Catalog.inspect(), counters = table.clone(counters), failures = table.clone(failures), posture = { clientPresentationOnly = true, noGameplayAuthority = true, noNetworking = true, noPersistence = true, noAnalytics = true, noTelemetry = true } }
end

function Runtime.getSnapshot() return { diagnostics = Runtime.inspect(), audit = table.clone(audit) } end
function Runtime.shutdown() shutdown = true Catalog.clear() table.clear(audit) record("Shutdown") end

return Runtime
