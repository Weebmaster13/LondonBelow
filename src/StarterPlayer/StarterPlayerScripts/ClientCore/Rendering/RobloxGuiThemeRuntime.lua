--!strict

local Catalog = require(script.Parent.RobloxGuiThemeCatalog)
local Registry = require(script.Parent.RobloxGuiInstanceRegistry)
local Types = require(script.Parent.RobloxGuiThemeTypes)
local Validator = require(script.Parent.RobloxGuiThemeValidator)

local Runtime = {}
local state = Types.State.Idle
local busy = false
local generation = 0
local sequence = 0
local activeTheme = nil
local activeContract = nil
local audit = {}
local failures = {}
local counters = {
	registrations = 0,
	applications = 0,
	idempotent = 0,
	rollbacks = 0,
	propertiesApplied = 0,
	validationFailures = 0,
	staleRejected = 0,
	reconcileClears = 0,
}

local function append(target: { any }, value: any, limit: number)
	if #target >= limit then
		table.remove(target, 1)
	end
	target[#target + 1] = value
end
local function record(kind: string, detail: any?)
	sequence += 1
	append(
		audit,
		table.freeze({ sequence = sequence, generation = generation, kind = kind, detail = detail }),
		Types.Limits.maxAudit
	)
end
local function fail(code: string, detail: any?)
	state = Types.State.Failed
	local result = table.freeze({ ok = false, code = code, detail = detail })
	append(failures, result, Types.Limits.maxFailures)
	record("Failure", result)
	return result
end

function Runtime.registerTheme(themeId: any, revision: any, tokens: any)
	if state == Types.State.Shutdown then
		return fail(Types.FailureType.RuntimeShutdown)
	end
	local result = Catalog.register(themeId, revision, tokens)
	if result.ok then
		counters.registrations += 1
		record("ThemeRegistered", { themeId = themeId, revision = revision })
	end
	return result
end

function Runtime.apply(contract: any)
	if state == Types.State.Shutdown then
		return fail(Types.FailureType.RuntimeShutdown)
	end
	if busy then
		return fail(Types.FailureType.RuntimeBusy)
	end
	local tree = Registry.get()
	if not tree or type(contract) ~= "table" then
		return fail(Types.FailureType.InvalidTarget)
	end
	local theme = type(contract.themeId) == "string" and Catalog.get(contract.themeId) or nil
	if not theme then
		return fail(Types.FailureType.InvalidTheme)
	end
	if contract.targetRevision ~= tree.revision then
		counters.staleRejected += 1
		return fail(Types.FailureType.StaleRevision)
	end
	if
		activeContract
		and activeContract.contractId == contract.contractId
		and activeContract.targetRevision == contract.targetRevision
		and activeContract.themeId == contract.themeId
		and activeContract.themeRevision == contract.themeRevision
	then
		counters.idempotent += 1
		return {
			ok = true,
			idempotent = true,
			themeId = contract.themeId,
			themeRevision = contract.themeRevision,
		}
	end
	local valid, reason, ordered = Validator.validate(contract, theme, tree)
	if not valid or not ordered then
		counters.validationFailures += 1
		return fail(reason or Types.FailureType.InvalidContract)
	end
	busy = true
	state = Types.State.Applying
	local applied = {}
	for _, node in ipairs(ordered) do
		local properties = {}
		for propertyName in pairs(node.styles) do
			properties[#properties + 1] = propertyName
		end
		table.sort(properties)
		for _, propertyName in ipairs(properties) do
			local okOriginal, original = pcall(function()
				return (node.instance :: any)[propertyName]
			end)
			if not okOriginal then
				busy = false
				return fail(
					Types.FailureType.InvalidTarget,
					{ nodeId = node.nodeId, property = propertyName }
				)
			end
			local okApply = pcall(function()
				(node.instance :: any)[propertyName] = node.styles[propertyName]
			end)
			if not okApply then
				local rollbackOk = true
				for index = #applied, 1, -1 do
					local item = applied[index]
					rollbackOk = pcall(function()
						(item.instance :: any)[item.propertyName] = item.original
					end) and rollbackOk
				end
				counters.rollbacks += 1
				busy = false
				return fail(
					rollbackOk and Types.FailureType.ApplyFailed or Types.FailureType.RollbackFailed,
					{ nodeId = node.nodeId, property = propertyName }
				)
			end
			applied[#applied + 1] =
				{ instance = node.instance, propertyName = propertyName, original = original }
			counters.propertiesApplied += 1
		end
	end
	activeTheme = { themeId = theme.themeId, revision = theme.revision }
	activeContract = table.freeze({
		contractId = contract.contractId,
		targetRevision = contract.targetRevision,
		themeId = contract.themeId,
		themeRevision = contract.themeRevision,
	})
	counters.applications += 1
	state = Types.State.Applied
	busy = false
	record("ThemeApplied", activeContract)
	return {
		ok = true,
		idempotent = false,
		themeId = theme.themeId,
		themeRevision = theme.revision,
		propertiesApplied = #applied,
		generation = generation,
	}
end

function Runtime.reconcile()
	activeTheme = nil
	activeContract = nil
	generation += 1
	counters.reconcileClears += 1
	state = Types.State.Idle
	record("Reconciled")
	return { ok = true, generation = generation }
end
function Runtime.inspect()
	return {
		runtimeVersion = Types.RuntimeVersion,
		schemaVersion = Types.SchemaVersion,
		state = state,
		busy = busy,
		generation = generation,
		activeTheme = activeTheme and table.clone(activeTheme) or nil,
		catalog = Catalog.snapshot(),
		counters = table.clone(counters),
		failures = table.clone(failures),
		posture = {
			clientPresentationOnly = true,
			runtimeOwnedGuiOnly = true,
			noGameplayAuthority = true,
			noNetworking = true,
			noPersistence = true,
			noWorkspaceMutation = true,
			noAnalytics = true,
			noTelemetry = true,
		},
	}
end
function Runtime.getSnapshot()
	return { diagnostics = Runtime.inspect(), audit = table.clone(audit) }
end
function Runtime.shutdown()
	Runtime.reconcile()
	Catalog.reset()
	state = Types.State.Shutdown
	record("Shutdown")
end

return Runtime
