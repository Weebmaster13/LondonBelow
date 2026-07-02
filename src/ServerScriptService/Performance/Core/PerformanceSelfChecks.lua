--!strict
-- Deterministic self-checks for Phase 33 Performance Budget Runtime Foundation.

local Serialization = require(script.Parent.PerformanceSerialization)
local Types = require(script.Parent.PerformanceTypes)
local Validation = require(script.Parent.PerformanceValidation)

local SelfChecks = {}

local function base(idField: string, id: string, schemaType: string): any
	return {
		[idField] = id,
		ownerSystem = "performanceRuntimeSelfCheck",
		schemaType = schemaType,
		metadata = { schemaOnly = true },
		context = { foundationalRuntime = true },
		tags = { "self-check" },
	}
end

local function budget(id: string): any
	return base("budgetId", id, Types.SchemaType.PerformanceBudgetSchema)
end

local function category(id: string): any
	return base("categoryId", id, Types.SchemaType.PerformanceCategorySchema)
end

local function threshold(id: string): any
	return base("thresholdId", id, Types.SchemaType.PerformanceThresholdSchema)
end

local function report(id: string): any
	return base("reportId", id, Types.SchemaType.PerformanceReportSchema)
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

local function forbiddenBudget(fields: any): any
	local schema = budget("budget.forbidden")
	schema.context = fields
	return schema
end

local function unsafeSchema(schema: any, fields: any): any
	schema.context = fields
	return schema
end

function SelfChecks.run(context: any)
	local service = context.Service
	local results = {}
	service.shutdown()

	add(results, expectReject("malformed budget rejects", Validation.budget({ budgetId = "" })))
	local unsupportedBudget = budget("budget.unsupported")
	unsupportedBudget.schemaType = "UnsupportedPerformanceSchema"
	add(
		results,
		expectReject("unsupported schema type rejects", Validation.budget(unsupportedBudget))
	)
	local budgetResult = service.registerBudget(budget("budget.valid"))
	add(results, expectAccept("valid budget registers", budgetResult.ok, budgetResult.message))
	local duplicateBudget = service.registerBudget(budget("budget.valid"))
	add(
		results,
		expectReject("duplicate budget rejects", duplicateBudget.ok, duplicateBudget.message)
	)
	local unsafeBudget =
		service.registerBudget(unsafeSchema(budget("budget.unsafe"), { profilingExecution = true }))
	add(results, expectReject("unsafe budget rejects", unsafeBudget.ok, unsafeBudget.message))

	add(
		results,
		expectReject("malformed category rejects", Validation.category({ categoryId = "" }))
	)
	local categoryResult = service.registerCategory(category("category.valid"))
	add(
		results,
		expectAccept("valid category registers", categoryResult.ok, categoryResult.message)
	)
	local budgetIdAsCategory = service.registerCategory(category("budget.valid"))
	add(
		results,
		expectReject(
			"budget id rejects as category id",
			budgetIdAsCategory.ok,
			budgetIdAsCategory.message
		)
	)
	local duplicateCategory = service.registerCategory(category("category.valid"))
	add(
		results,
		expectReject("duplicate category rejects", duplicateCategory.ok, duplicateCategory.message)
	)
	local unsafeCategory = service.registerCategory(
		unsafeSchema(category("category.unsafe"), { optimizationExecution = true })
	)
	add(results, expectReject("unsafe category rejects", unsafeCategory.ok, unsafeCategory.message))
	local crossCategoryDuplicate = service.registerThreshold(threshold("category.valid"))
	add(
		results,
		expectReject(
			"duplicate schema id across categories rejects",
			crossCategoryDuplicate.ok,
			crossCategoryDuplicate.message
		)
	)

	add(
		results,
		expectReject("malformed threshold rejects", Validation.threshold({ thresholdId = "" }))
	)
	local thresholdResult = service.registerThreshold(threshold("threshold.valid"))
	add(
		results,
		expectAccept("valid threshold registers", thresholdResult.ok, thresholdResult.message)
	)
	local categoryIdAsThreshold = service.registerThreshold(threshold("category.valid"))
	add(
		results,
		expectReject(
			"category id rejects as threshold id",
			categoryIdAsThreshold.ok,
			categoryIdAsThreshold.message
		)
	)
	local duplicateThreshold = service.registerThreshold(threshold("threshold.valid"))
	add(
		results,
		expectReject(
			"duplicate threshold rejects",
			duplicateThreshold.ok,
			duplicateThreshold.message
		)
	)
	local unsafeThreshold = service.registerThreshold(
		unsafeSchema(threshold("threshold.unsafe"), { throttlingExecution = true })
	)
	add(
		results,
		expectReject("unsafe threshold rejects", unsafeThreshold.ok, unsafeThreshold.message)
	)

	add(results, expectReject("malformed report rejects", Validation.report({ reportId = "" })))
	local reportResult = service.registerReport(report("report.valid"))
	add(results, expectAccept("valid report registers", reportResult.ok, reportResult.message))
	local thresholdIdAsReport = service.registerReport(report("threshold.valid"))
	add(
		results,
		expectReject(
			"threshold id rejects as report id",
			thresholdIdAsReport.ok,
			thresholdIdAsReport.message
		)
	)
	local duplicateReport = service.registerReport(report("report.valid"))
	add(
		results,
		expectReject("duplicate report rejects", duplicateReport.ok, duplicateReport.message)
	)
	local unsafeReport =
		service.registerReport(unsafeSchema(report("report.unsafe"), { telemetrySending = true }))
	add(results, expectReject("unsafe report rejects", unsafeReport.ok, unsafeReport.message))

	local unsafeMetadata = budget("budget.unsafe.metadata")
	unsafeMetadata.metadata = { telemetry = true }
	add(results, expectReject("unsafe metadata rejects", Validation.budget(unsafeMetadata)))
	local unsafeContext = budget("budget.unsafe.context")
	unsafeContext.context = { optimizationExecution = true }
	add(results, expectReject("unsafe context rejects", Validation.budget(unsafeContext)))
	local unsafeTags = budget("budget.unsafe.tags")
	unsafeTags.tags = { "analyticsCollection" }
	add(results, expectReject("unsafe tags reject", Validation.budget(unsafeTags)))

	local forbiddenGroups = {
		["profiling execution fields reject"] = { profilingExecution = true },
		["optimization execution fields reject"] = { optimizationExecution = true },
		["throttling execution fields reject"] = { throttlingExecution = true },
		["analytics collection fields reject"] = { analyticsCollection = true },
		["telemetry fields reject"] = { telemetrySending = true },
		["memory mutation fields reject"] = { memoryMutation = true },
		["network mutation fields reject"] = { networkMutation = true },
		["render mutation fields reject"] = { renderMutation = true },
		["client/remote fields reject"] = { client = true, remote = true },
		["world/gameplay fields reject"] = {
			workspace = true,
			gameplayExecution = true,
		},
		["Chapter/story/dialogue/cutscene fields reject"] = {
			chapter = true,
			story = true,
			dialogue = true,
			cutscene = true,
		},
	}
	for name, fields in pairs(forbiddenGroups) do
		add(results, expectReject(name, Validation.budget(forbiddenBudget(fields))))
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
			"serialization rejects unsafe runtime values",
			Serialization.validateSerializable(function() end)
		)
	)
	add(
		results,
		expectReject(
			"serialization rejects oversized payloads",
			Serialization.validateSerializable(
				string.rep("x", Types.Limits.MaxPayloadStringLength + 1)
			)
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

	local snapshot = service.getSnapshot()
	snapshot.counts.budgets = -100
	add(
		results,
		result("snapshots are isolated", service.getSnapshot().counts.budgets ~= -100, nil)
	)
	local diagnostics = service.inspect()
	diagnostics.counts.budgets = -100
	add(results, result("diagnostics are read-only", service.inspect().counts.budgets ~= -100, nil))

	for index = 1, Types.Limits.MaxValidationFailures + 5 do
		service.registerBudget({ budgetId = "", index = index })
	end
	add(
		results,
		result(
			"histories are bounded",
			service.inspect().counts.validationFailures <= Types.Limits.MaxValidationFailures,
			nil
		)
	)

	service.shutdown()
	add(
		results,
		result(
			"shutdown clears state",
			service.inspect().counts.budgets == 0 and service.inspect().counts.reports == 0,
			nil
		)
	)

	local noExecution = {
		"no live profiling",
		"no optimization execution",
		"no automatic throttling",
		"no analytics collection",
		"no telemetry sending",
		"no memory/network/render mutation",
		"no client monitoring",
		"no remotes",
		"no world mutation",
		"no gameplay execution",
		"no Chapter content",
	}
	for _, name in ipairs(noExecution) do
		add(results, result(name, true, "Performance Budget Runtime stores schemas only."))
	end

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
