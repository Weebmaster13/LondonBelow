--!strict
-- Central bounded state store for the Analytics Boundary Foundation.

local Serialization = require(script.Parent.AnalyticsSerialization)
local Types = require(script.Parent.AnalyticsTypes)
local Validation = require(script.Parent.AnalyticsValidation)

local State = {}

local events: { [string]: any } = {}
local metrics: { [string]: any } = {}
local aggregations: { [string]: any } = {}
local consents: { [string]: any } = {}
local retentions: { [string]: any } = {}
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

function State.registerEvent(schema: any): (boolean, string?)
	local ok, reason = Validation.event(schema)
	if not ok then
		return false, reason
	end
	if schemaIds[schema.eventId] == true then
		return false, "duplicate eventId"
	end
	if countMap(events) >= Types.Limits.MaxEvents then
		return false, "event limit exceeded"
	end
	schemaIds[schema.eventId] = true
	events[schema.eventId] = Serialization.deepCopy(schema)
	return true, nil
end

function State.registerMetric(schema: any): (boolean, string?)
	local ok, reason = Validation.metric(schema)
	if not ok then
		return false, reason
	end
	if schemaIds[schema.metricId] == true then
		return false, "duplicate metricId"
	end
	if countMap(metrics) >= Types.Limits.MaxMetrics then
		return false, "metric limit exceeded"
	end
	schemaIds[schema.metricId] = true
	metrics[schema.metricId] = Serialization.deepCopy(schema)
	return true, nil
end

function State.registerAggregation(schema: any): (boolean, string?)
	local ok, reason = Validation.aggregation(schema)
	if not ok then
		return false, reason
	end
	if schemaIds[schema.aggregationId] == true then
		return false, "duplicate aggregationId"
	end
	if countMap(aggregations) >= Types.Limits.MaxAggregations then
		return false, "aggregation schema limit exceeded"
	end
	schemaIds[schema.aggregationId] = true
	aggregations[schema.aggregationId] = Serialization.deepCopy(schema)
	return true, nil
end

function State.registerConsent(schema: any): (boolean, string?)
	local ok, reason = Validation.consent(schema)
	if not ok then
		return false, reason
	end
	if schemaIds[schema.consentId] == true then
		return false, "duplicate consentId"
	end
	if countMap(consents) >= Types.Limits.MaxConsents then
		return false, "consent limit exceeded"
	end
	schemaIds[schema.consentId] = true
	consents[schema.consentId] = Serialization.deepCopy(schema)
	return true, nil
end

function State.registerRetention(schema: any): (boolean, string?)
	local ok, reason = Validation.retention(schema)
	if not ok then
		return false, reason
	end
	if schemaIds[schema.retentionId] == true then
		return false, "duplicate retentionId"
	end
	if countMap(retentions) >= Types.Limits.MaxRetentions then
		return false, "retention limit exceeded"
	end
	schemaIds[schema.retentionId] = true
	retentions[schema.retentionId] = Serialization.deepCopy(schema)
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
		events = events,
		metrics = metrics,
		aggregations = aggregations,
		consents = consents,
		retentions = retentions,
		reports = reports,
		validationFailures = validationFailures,
		snapshotHistory = snapshotHistory,
		counts = {
			events = countMap(events),
			metrics = countMap(metrics),
			aggregations = countMap(aggregations),
			consents = countMap(consents),
			retentions = countMap(retentions),
			reports = countMap(reports),
			validationFailures = #validationFailures,
			snapshots = #snapshotHistory,
		},
	})
end

function State.clear()
	table.clear(events)
	table.clear(metrics)
	table.clear(aggregations)
	table.clear(consents)
	table.clear(retentions)
	table.clear(reports)
	table.clear(schemaIds)
	table.clear(validationFailures)
	table.clear(snapshotHistory)
end

return State
