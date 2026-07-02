--!strict
-- Central bounded state store for the Performance Budget Runtime Foundation.

local Serialization = require(script.Parent.PerformanceSerialization)
local Types = require(script.Parent.PerformanceTypes)
local Validation = require(script.Parent.PerformanceValidation)

local State = {}

local budgets: { [string]: any } = {}
local categories: { [string]: any } = {}
local thresholds: { [string]: any } = {}
local reports: { [string]: any } = {}
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

function State.registerBudget(schema: any): (boolean, string?)
	local ok, reason = Validation.budget(schema)
	if not ok then
		return false, reason
	end
	if schemaIds[schema.budgetId] == true then
		return false, "duplicate budgetId"
	end
	if countMap(budgets) >= Types.Limits.MaxBudgets then
		return false, "budget limit exceeded"
	end
	schemaIds[schema.budgetId] = true
	budgets[schema.budgetId] = Serialization.deepCopy(schema)
	return true, nil
end

function State.registerCategory(schema: any): (boolean, string?)
	local ok, reason = Validation.category(schema)
	if not ok then
		return false, reason
	end
	if schemaIds[schema.categoryId] == true then
		return false, "duplicate categoryId"
	end
	if countMap(categories) >= Types.Limits.MaxCategories then
		return false, "category limit exceeded"
	end
	schemaIds[schema.categoryId] = true
	categories[schema.categoryId] = Serialization.deepCopy(schema)
	return true, nil
end

function State.registerThreshold(schema: any): (boolean, string?)
	local ok, reason = Validation.threshold(schema)
	if not ok then
		return false, reason
	end
	if schemaIds[schema.thresholdId] == true then
		return false, "duplicate thresholdId"
	end
	if countMap(thresholds) >= Types.Limits.MaxThresholds then
		return false, "threshold limit exceeded"
	end
	schemaIds[schema.thresholdId] = true
	thresholds[schema.thresholdId] = Serialization.deepCopy(schema)
	return true, nil
end

function State.registerReport(record: any): (boolean, string?)
	local ok, reason = Validation.report(record)
	if not ok then
		return false, reason
	end
	if schemaIds[record.reportId] == true then
		return false, "duplicate reportId"
	end
	if countMap(reports) >= Types.Limits.MaxReports then
		return false, "report limit exceeded"
	end
	schemaIds[record.reportId] = true
	reports[record.reportId] = Serialization.deepCopy(record)
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
		budgets = budgets,
		categories = categories,
		thresholds = thresholds,
		reports = reports,
		validationFailures = validationFailures,
		snapshotHistory = snapshotHistory,
		counts = {
			budgets = countMap(budgets),
			categories = countMap(categories),
			thresholds = countMap(thresholds),
			reports = countMap(reports),
			validationFailures = #validationFailures,
			snapshots = #snapshotHistory,
		},
	})
end

function State.clear()
	table.clear(budgets)
	table.clear(categories)
	table.clear(thresholds)
	table.clear(reports)
	table.clear(schemaIds)
	table.clear(validationFailures)
	table.clear(snapshotHistory)
end

return State
