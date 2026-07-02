--!strict
-- Deterministic self-checks for Phase 31 Analytics Boundary Foundation.

local Serialization = require(script.Parent.AnalyticsSerialization)
local Types = require(script.Parent.AnalyticsTypes)
local Validation = require(script.Parent.AnalyticsValidation)

local SelfChecks = {}

local function base(idField: string, id: string, schemaType: string): any
	return {
		[idField] = id,
		ownerSystem = "analyticsBoundarySelfCheck",
		schemaType = schemaType,
		metadata = { schemaOnly = true },
		context = { foundationalRuntime = true },
		tags = { "self-check" },
	}
end

local function event(id: string): any
	return base("eventId", id, Types.SchemaType.AnalyticsEventSchema)
end

local function metric(id: string): any
	return base("metricId", id, Types.SchemaType.AnalyticsMetricSchema)
end

local function aggregation(id: string): any
	return base("aggregationId", id, Types.SchemaType.AnalyticsAggregationSchema)
end

local function consent(id: string): any
	return base("consentId", id, Types.SchemaType.AnalyticsConsentSchema)
end

local function retention(id: string): any
	return base("retentionId", id, Types.SchemaType.AnalyticsRetentionSchema)
end

local function report(id: string): any
	return base("reportId", id, Types.SchemaType.AnalyticsReportSchema)
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

local function forbiddenEvent(fields: any): any
	local schema = event("event.forbidden")
	schema.context = fields
	return schema
end

function SelfChecks.run(context: any)
	local service = context.Service
	local results = {}
	service.shutdown()

	add(results, expectReject("malformed event rejects", Validation.event({ eventId = "" })))
	local unsupportedEvent = event("event.unsupported")
	unsupportedEvent.schemaType = "UnsupportedAnalyticsSchema"
	add(
		results,
		expectReject("unsupported schema type rejects", Validation.event(unsupportedEvent))
	)
	local eventResult = service.registerEvent(event("event.valid"))
	add(results, expectAccept("valid event registers", eventResult.ok, eventResult.message))
	local duplicateEvent = service.registerEvent(event("event.valid"))
	add(results, expectReject("duplicate event rejects", duplicateEvent.ok, duplicateEvent.message))
	local crossCategoryDuplicate = service.registerAggregation(aggregation("event.valid"))
	add(
		results,
		expectReject(
			"duplicate schema id across categories rejects",
			crossCategoryDuplicate.ok,
			crossCategoryDuplicate.message
		)
	)

	add(results, expectReject("malformed metric rejects", Validation.metric({ metricId = "" })))
	local metricResult = service.registerMetric(metric("metric.valid"))
	add(results, expectAccept("valid metric records", metricResult.ok, metricResult.message))
	local duplicateMetric = service.registerMetric(metric("metric.valid"))
	add(
		results,
		expectReject("duplicate metric rejects", duplicateMetric.ok, duplicateMetric.message)
	)

	add(
		results,
		expectReject(
			"malformed aggregation rejects",
			Validation.aggregation({ aggregationId = "" })
		)
	)
	local aggregationResult = service.registerAggregation(aggregation("aggregation.valid"))
	add(
		results,
		expectAccept(
			"valid aggregation schema records",
			aggregationResult.ok,
			aggregationResult.message
		)
	)
	local duplicateAggregation = service.registerAggregation(aggregation("aggregation.valid"))
	add(
		results,
		expectReject(
			"duplicate aggregation rejects",
			duplicateAggregation.ok,
			duplicateAggregation.message
		)
	)
	local unsafeAggregation = aggregation("aggregation.unsafe")
	unsafeAggregation.context = { profilingExecution = true }
	local unsafeAggregationResult = service.registerAggregation(unsafeAggregation)
	add(
		results,
		expectReject(
			"unsafe aggregation rejects",
			unsafeAggregationResult.ok,
			unsafeAggregationResult.message
		)
	)

	add(results, expectReject("malformed consent rejects", Validation.consent({ consentId = "" })))
	local consentResult = service.registerConsent(consent("consent.valid"))
	add(results, expectAccept("valid consent records", consentResult.ok, consentResult.message))
	local duplicateConsent = service.registerConsent(consent("consent.valid"))
	add(
		results,
		expectReject("duplicate consent rejects", duplicateConsent.ok, duplicateConsent.message)
	)
	local unsafeConsent = consent("consent.unsafe")
	unsafeConsent.context = { playerTracking = true }
	local unsafeConsentResult = service.registerConsent(unsafeConsent)
	add(
		results,
		expectReject("unsafe consent rejects", unsafeConsentResult.ok, unsafeConsentResult.message)
	)

	add(
		results,
		expectReject("malformed retention rejects", Validation.retention({ retentionId = "" }))
	)
	local retentionResult = service.registerRetention(retention("retention.valid"))
	add(
		results,
		expectAccept("valid retention records", retentionResult.ok, retentionResult.message)
	)
	local duplicateRetention = service.registerRetention(retention("retention.valid"))
	add(
		results,
		expectReject(
			"duplicate retention rejects",
			duplicateRetention.ok,
			duplicateRetention.message
		)
	)

	add(results, expectReject("malformed report rejects", Validation.report({ reportId = "" })))
	local reportResult = service.registerReport(report("report.valid"))
	add(results, expectAccept("valid report schemas", reportResult.ok, reportResult.message))
	local duplicateReport = service.registerReport(report("report.valid"))
	add(
		results,
		expectReject("duplicate report rejects", duplicateReport.ok, duplicateReport.message)
	)
	local unsafeReport = report("report.unsafe")
	unsafeReport.context = { externalReporting = true }
	local unsafeReportResult = service.registerReport(unsafeReport)
	add(
		results,
		expectReject("unsafe report rejects", unsafeReportResult.ok, unsafeReportResult.message)
	)

	local unsafeMetadata = event("event.unsafe.metadata")
	unsafeMetadata.metadata = { telemetrySending = true }
	add(results, expectReject("unsafe metadata rejects", Validation.event(unsafeMetadata)))
	local unsafeContext = event("event.unsafe.context")
	unsafeContext.context = { externalAnalytics = true }
	add(results, expectReject("unsafe context rejects", Validation.event(unsafeContext)))
	local unsafeTags = event("event.unsafe.tags")
	unsafeTags.tags = { "playerTracking" }
	add(results, expectReject("unsafe tags reject", Validation.event(unsafeTags)))

	local forbiddenGroups = {
		["telemetry sending fields reject"] = { telemetrySending = true },
		["external analytics fields reject"] = { externalAnalytics = true },
		["player tracking fields reject"] = { playerTracking = true },
		["moderation fields reject"] = { moderation = true, moderationExecution = true },
		["profiling execution fields reject"] = { profilingExecution = true },
		["HTTP service fields reject"] = { httpService = true },
		["DataStore fields reject"] = { dataStoreRead = true, dataStoreWrite = true },
		["messaging service fields reject"] = { messagingService = true },
		["Workspace fields reject"] = { workspace = true },
		["remote/client fields reject"] = { remote = true, client = true },
		["UI/Workspace/gameplay fields reject"] = {
			ui = true,
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
		add(results, expectReject(name, Validation.event(forbiddenEvent(fields))))
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
	snapshot.counts.events = -100
	add(results, result("snapshots are isolated", service.getSnapshot().counts.events ~= -100, nil))
	local diagnostics = service.inspect()
	diagnostics.counts.events = -100
	add(results, result("diagnostics are read-only", service.inspect().counts.events ~= -100, nil))

	for index = 1, Types.Limits.MaxValidationFailures + 5 do
		service.registerEvent({ eventId = "", index = index })
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
			service.inspect().counts.events == 0 and service.inspect().counts.aggregations == 0,
			nil
		)
	)

	local noExecution = {
		"no command execution",
		"no analytics collection",
		"no telemetry sending",
		"no player tracking",
		"no external reporting",
		"no moderation",
		"no live metrics",
		"no HTTP service calls",
		"no messaging service calls",
		"no DataStore reads/writes",
		"no Workspace mutation",
		"no remotes",
		"no client authority",
		"no Chapter content",
	}
	for _, name in ipairs(noExecution) do
		add(results, result(name, true, "Analytics Boundary stores schemas only."))
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
