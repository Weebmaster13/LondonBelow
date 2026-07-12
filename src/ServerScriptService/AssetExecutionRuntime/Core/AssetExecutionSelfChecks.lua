--!strict

local Serialization = require(script.Parent.AssetExecutionSerialization)
local Signals = require(script.Parent.AssetExecutionSignals)
local Types = require(script.Parent.AssetExecutionTypes)
local Validation = require(script.Parent.AssetExecutionValidation)

local SelfChecks = {}

local function runtime(id: string?): any
	return {
		runtimeId = id or "runtime.main",
		authorizationId = "authorization.main",
		readinessId = "readiness.main",
		runtimeKind = "MetadataRuntime",
		runtimeStatus = "Ready",
		providerName = Types.RuntimeProviderName,
		snapshotProviderName = Types.RuntimeProviderName,
		requestIds = {},
		boundaryIds = {},
		auditIds = {},
		evidence = { "runtime.evidence" },
		tags = { "runtime" },
		metadata = { purpose = "execution metadata only" },
	}
end

local function request(id: string?, runtimeId: string?): any
	return {
		requestId = id or "request.main",
		runtimeId = runtimeId or "runtime.main",
		requestKind = "RuntimeMetadataRequest",
		requestStatus = "Validated",
		requestedBy = "reviewer.main",
		evidence = { "request.evidence" },
		tags = { "request" },
		metadata = { purpose = "request metadata only" },
	}
end

local function boundary(id: string?, runtimeId: string?): any
	return {
		boundaryId = id or "boundary.main",
		runtimeId = runtimeId or "runtime.main",
		boundaryKind = "NoAssetLoading",
		boundaryStatus = "Satisfied",
		summary = "No asset execution surface is introduced.",
		evidence = { "boundary.evidence" },
		tags = { "boundary" },
		metadata = { purpose = "boundary metadata only" },
	}
end

local function audit(
	id: string?,
	runtimeId: string?,
	requestIds: { string }?,
	boundaryIds: { string }?
): any
	return {
		auditId = id or "audit.main",
		runtimeId = runtimeId or "runtime.main",
		requestIds = requestIds or { "request.main" },
		boundaryIds = boundaryIds or { "boundary.main" },
		auditKind = "RuntimeAudit",
		auditStatus = "Passed",
		reviewer = "reviewer.main",
		evidence = { "audit.evidence" },
		tags = { "audit" },
		metadata = { purpose = "audit metadata only" },
	}
end

local function expect(results: { any }, category: string, ok: boolean, message: string)
	table.insert(results, { category = category, ok = ok, message = message })
end

local function expectValid(results: { any }, category: string, callback: () -> (boolean, string?))
	local ok, reason = callback()
	expect(results, category, ok, if ok then "accepted valid case" else tostring(reason))
end

local function expectInvalid(results: { any }, category: string, callback: () -> (boolean, string?))
	local ok, reason = callback()
	expect(
		results,
		category,
		not ok,
		if ok then "rejected invalid case failed" else tostring(reason)
	)
end

local function countFailures(results: { any }): number
	local failures = 0
	for _, item in ipairs(results) do
		if not item.ok then
			failures += 1
		end
	end
	return failures
end

local function withTemporaryTypeValue(key: string, value: any, callback: () -> (boolean, string?))
	local previous = Types[key]
	Types[key] = value
	local ok, reason = callback()
	Types[key] = previous
	return ok, reason
end

local function expectExactArray(
	results: { any },
	category: string,
	actual: { string },
	expected: { string },
	label: string
)
	expect(results, category, #actual == #expected, label .. " count matches")
	for index, expectedValue in ipairs(expected) do
		expect(
			results,
			category,
			actual[index] == expectedValue,
			label .. " position " .. tostring(index) .. " matches"
		)
	end
end

local function expectExactStringMap(
	results: { any },
	category: string,
	actual: { [string]: string },
	expected: { [string]: string },
	label: string
)
	for key, expectedValue in pairs(expected) do
		expect(results, category, actual[key] == expectedValue, label .. " " .. key .. " matches")
	end
	for key in pairs(actual) do
		expect(results, category, expected[key] ~= nil, label .. " " .. key .. " is supported")
	end
end

local validators = {
	ExecutionRuntime = {
		fields = Types.SchemaFields.ExecutionRuntime,
		base = runtime,
		validate = Validation.runtime,
		idField = "runtimeId",
		stringFields = {
			"runtimeId",
			"authorizationId",
			"readinessId",
			"runtimeKind",
			"runtimeStatus",
			"providerName",
			"snapshotProviderName",
		},
	},
	ExecutionRequest = {
		fields = Types.SchemaFields.ExecutionRequest,
		base = request,
		validate = Validation.request,
		idField = "requestId",
		stringFields = { "requestId", "runtimeId", "requestKind", "requestStatus", "requestedBy" },
	},
	ExecutionBoundary = {
		fields = Types.SchemaFields.ExecutionBoundary,
		base = boundary,
		validate = Validation.boundary,
		idField = "boundaryId",
		stringFields = { "boundaryId", "runtimeId", "boundaryKind", "boundaryStatus", "summary" },
	},
	ExecutionAudit = {
		fields = Types.SchemaFields.ExecutionAudit,
		base = audit,
		validate = Validation.audit,
		idField = "auditId",
		stringFields = { "auditId", "runtimeId", "auditKind", "auditStatus", "reviewer" },
	},
}

local function validateConfigSchema(schema: any): (boolean, string?)
	if schema.runtimeId ~= nil and schema.runtimeKind ~= nil then
		return Validation.runtime(schema)
	elseif schema.requestId ~= nil then
		return Validation.request(schema)
	elseif schema.boundaryId ~= nil then
		return Validation.boundary(schema)
	end
	return Validation.audit(schema)
end

local function runSchemaChecks(results: { any })
	for schemaName, config in pairs(validators) do
		expectValid(results, "schema validation", function()
			return config.validate(config.base())
		end)
		for _, fieldName in ipairs(config.fields) do
			expectInvalid(results, "schema validation", function()
				local schema = config.base()
				schema[fieldName] = nil
				return config.validate(schema)
			end)
			expectInvalid(results, "unsupported fields", function()
				local schema = config.base()
				schema[fieldName .. "Drift"] = schema[fieldName]
				return config.validate(schema)
			end)
		end
		expectInvalid(results, "invalid ids", function()
			local schema = config.base()
			schema[config.idField] = "invalid id with spaces"
			return config.validate(schema)
		end)
		expect(
			results,
			"schema validation",
			Types.SchemaFieldCount[schemaName] == #config.fields,
			schemaName .. " field count matches"
		)
	end
end

local function runEnumChecks(results: { any })
	for value in pairs(Types.RuntimeKind) do
		local schema = runtime()
		schema.runtimeKind = value
		expectValid(results, "schema validation", function()
			return Validation.runtime(schema)
		end)
	end
	for value in pairs(Types.RuntimeStatus) do
		local schema = runtime()
		schema.runtimeStatus = value
		expectValid(results, "schema validation", function()
			return Validation.runtime(schema)
		end)
	end
	for value in pairs(Types.RequestKind) do
		local schema = request()
		schema.requestKind = value
		expectValid(results, "schema validation", function()
			return Validation.request(schema)
		end)
	end
	for value in pairs(Types.RequestStatus) do
		local schema = request()
		schema.requestStatus = value
		expectValid(results, "schema validation", function()
			return Validation.request(schema)
		end)
	end
	for value in pairs(Types.BoundaryKind) do
		local schema = boundary()
		schema.boundaryKind = value
		expectValid(results, "schema validation", function()
			return Validation.boundary(schema)
		end)
	end
	for value in pairs(Types.BoundaryStatus) do
		local schema = boundary()
		schema.boundaryStatus = value
		expectValid(results, "schema validation", function()
			return Validation.boundary(schema)
		end)
	end
	for value in pairs(Types.AuditKind) do
		local schema = audit()
		schema.auditKind = value
		expectValid(results, "schema validation", function()
			return Validation.audit(schema)
		end)
	end
	for value in pairs(Types.AuditStatus) do
		local schema = audit()
		schema.auditStatus = value
		expectValid(results, "schema validation", function()
			return Validation.audit(schema)
		end)
	end
	for _, drift in ipairs({
		{ runtime(), "runtimeKind" },
		{ runtime(), "runtimeStatus" },
		{ request(), "requestKind" },
		{ request(), "requestStatus" },
		{ boundary(), "boundaryKind" },
		{ boundary(), "boundaryStatus" },
		{ audit(), "auditKind" },
		{ audit(), "auditStatus" },
	}) do
		expectInvalid(results, "schema validation", function()
			local schema = drift[1]
			schema[drift[2]] = "UnsupportedValue"
			return validateConfigSchema(schema)
		end)
	end
end

local function unsafePayloadFor(marker: string, mode: number): any
	if mode == 1 then
		return { marker = marker }
	elseif mode == 2 then
		return { [marker] = "unsafe" }
	elseif mode == 3 then
		return { nested = { marker = marker } }
	elseif mode == 4 then
		return { nested = { [marker] = "unsafe" } }
	elseif mode == 5 then
		return { nested = { deeper = { marker = marker } } }
	elseif mode == 6 then
		return { list = { marker } }
	elseif mode == 7 then
		return { alpha = { beta = { gamma = { marker = marker } } } }
	elseif mode == 8 then
		return { one = { two = { three = { four = { marker = marker } } } } }
	elseif mode == 9 then
		return { audit = { payload = { value = marker } } }
	elseif mode == 10 then
		return { runtime = { posture = { value = marker } } }
	elseif mode == 11 then
		return { request = { posture = { value = marker } } }
	elseif mode == 12 then
		return { boundary = { posture = { value = marker } } }
	elseif mode == 13 then
		return { copied = { evidence = { marker } } }
	elseif mode == 14 then
		return { copied = { tags = { marker } } }
	elseif mode == 15 then
		return { metadata = { copied = { marker = marker } } }
	end
	return { ["path" .. tostring(mode)] = { copied = { marker = marker } } }
end

local function runPayloadChecks(results: { any })
	for _, config in pairs(validators) do
		for _, fieldName in ipairs({ "evidence", "tags" }) do
			expectInvalid(results, "deep payload rejection", function()
				local schema = config.base()
				schema[fieldName] = { "duplicate", "duplicate" }
				return config.validate(schema)
			end)
			expectInvalid(results, "deep payload rejection", function()
				local schema = config.base()
				schema[fieldName] = { [2] = "sparse" }
				return config.validate(schema)
			end)
			expectInvalid(results, "deep payload rejection", function()
				local schema = config.base()
				schema[fieldName] = { "z.value", "a.value" }
				return config.validate(schema)
			end)
		end
		expectInvalid(results, "Roblox Instances", function()
			local schema = config.base()
			schema.metadata = { ClassName = "Part", ["Par" .. "ent"] = {} }
			return config.validate(schema)
		end)
		expectInvalid(results, "deep payload rejection", function()
			local schema = config.base()
			schema.metadata = {}
			schema.metadata.self = schema.metadata
			return config.validate(schema)
		end)
		for _, marker in ipairs(Serialization.forbiddenMarkers()) do
			for mode = 1, 64 do
				expectInvalid(results, "banned runtime surface absence", function()
					local schema = config.base()
					schema.metadata = unsafePayloadFor(marker, mode)
					return config.validate(schema)
				end)
			end
			expectInvalid(results, "banned runtime surface absence", function()
				local schema = config.base()
				schema.evidence = { marker }
				return config.validate(schema)
			end)
			expectInvalid(results, "banned runtime surface absence", function()
				local schema = config.base()
				schema.tags = { marker }
				return config.validate(schema)
			end)
			for _, fieldName in ipairs(config.stringFields) do
				expectInvalid(results, "banned runtime surface absence", function()
					local schema = config.base()
					schema[fieldName] = marker
					return config.validate(schema)
				end)
			end
		end
	end
end

local function runIdentityChecks(results: { any })
	expectExactArray(results, "coordinator API boundary", Types.CoordinatorApiOrder, {
		"initialize",
		"start",
		"shutdown",
		"registerExecutionRuntime",
		"registerExecutionRequest",
		"registerExecutionBoundary",
		"registerExecutionAudit",
		"inspect",
		"getSnapshot",
		"validate",
		"runSelfChecks",
	}, "coordinator API")
	expectExactStringMap(results, "signal boundary", Types.SignalNames, {
		Initialized = "AssetExecutionRuntime.Initialized",
		Started = "AssetExecutionRuntime.Started",
		Shutdown = "AssetExecutionRuntime.Shutdown",
		ValidationFailed = "AssetExecutionRuntime.ValidationFailed",
	}, "type signal")
	expectExactStringMap(results, "signal boundary", Signals, Types.SignalNames, "runtime signal")
	for _, drift in ipairs({
		{ key = "RuntimeProviderName", value = "assetExecutionRuntimeDrift" },
		{ key = "SnapshotKind", value = "assetExecutionRuntimeSnapshotDrift" },
		{ key = "RuntimeName", value = "AssetExecutionRuntimeDrift" },
		{ key = "CoordinatorName", value = "AssetExecutionCoordinatorDrift" },
	}) do
		expectInvalid(results, "provider identity", function()
			return withTemporaryTypeValue(drift.key, drift.value, Validation.validate)
		end)
	end
	expectInvalid(results, "documentation consistency", function()
		local drifted = Serialization.deepCopy(Types.DocumentationFiles)
		drifted[1] = "UNSUPPORTED.md"
		return withTemporaryTypeValue("DocumentationFiles", drifted, Validation.validate)
	end)
	expectInvalid(results, "Bootstrap ordering", function()
		return withTemporaryTypeValue(
			"BootstrapDependencyOrder",
			{ "AssetExecutionCoordinator" },
			Validation.validate
		)
	end)
	expectInvalid(results, "Governance consistency", function()
		return withTemporaryTypeValue(
			"GovernanceSnapshotProviders",
			{ "assetExecutionRuntimeDrift" },
			Validation.validate
		)
	end)
	for schemaName, fields in pairs(Types.SchemaFields) do
		expectInvalid(results, "schema drift", function()
			local drifted = Serialization.deepCopy(Types.SchemaFields)
			drifted[schemaName] = Serialization.deepCopy(fields)
			table.insert(drifted[schemaName], "unsupportedField")
			return withTemporaryTypeValue("SchemaFields", drifted, Validation.validate)
		end)
		expectInvalid(results, "schema drift", function()
			local drifted = Serialization.deepCopy(Types.SchemaFields)
			drifted[schemaName] = Serialization.deepCopy(fields)
			drifted[schemaName][1] = "unsupportedFirstField"
			return withTemporaryTypeValue("SchemaFields", drifted, Validation.validate)
		end)
	end
	for _, enumName in ipairs({
		"RuntimeKind",
		"RuntimeStatus",
		"RequestKind",
		"RequestStatus",
		"BoundaryKind",
		"BoundaryStatus",
		"AuditKind",
		"AuditStatus",
	}) do
		expectInvalid(results, "enum drift", function()
			local drifted = Serialization.deepCopy(Types[enumName])
			drifted.UnsupportedValue = true
			return withTemporaryTypeValue(enumName, drifted, Validation.validate)
		end)
		expectInvalid(results, "enum drift", function()
			local drifted = Serialization.deepCopy(Types[enumName])
			for key in pairs(drifted) do
				drifted[key] = nil
				break
			end
			return withTemporaryTypeValue(enumName, drifted, Validation.validate)
		end)
	end
	for limitName, limitValue in pairs(Types.Limits) do
		expectInvalid(results, "runtime-limit enforcement", function()
			local drifted = Serialization.deepCopy(Types.Limits)
			drifted[limitName] = limitValue + 1
			return withTemporaryTypeValue("Limits", drifted, Validation.validate)
		end)
	end
	expectInvalid(results, "lowerCamelCase posture keys", function()
		local drifted = Serialization.deepCopy(Types.PostureKeys)
		drifted[1] = "AssetExecutionRuntimePosture"
		return withTemporaryTypeValue("PostureKeys", drifted, Validation.validate)
	end)
	expectInvalid(results, "coordinator API boundary", function()
		local drifted = Serialization.deepCopy(Types.CoordinatorApiOrder)
		table.insert(drifted, "execute")
		return withTemporaryTypeValue("CoordinatorApiOrder", drifted, Validation.validate)
	end)
	expectInvalid(results, "signal boundary", function()
		local drifted = Serialization.deepCopy(Types.SignalNames)
		drifted.Started = "AssetExecutionRuntime.StartedDrift"
		return withTemporaryTypeValue("SignalNames", drifted, Validation.validate)
	end)
end

local function withTemporaryIntegrationValue(
	declarations: any,
	order: any,
	callback: () -> (boolean, string?)
)
	local previousDeclarations = Types.AssetExecutionIntegrationReadinessDeclarations
	local previousOrder = Types.IntegrationReadinessDeclarationOrder
	Types.AssetExecutionIntegrationReadinessDeclarations = declarations
	Types.IntegrationReadinessDeclarationOrder = order
	local ok, reason = callback()
	Types.AssetExecutionIntegrationReadinessDeclarations = previousDeclarations
	Types.IntegrationReadinessDeclarationOrder = previousOrder
	return ok, reason
end

local function expectIntegrationInvalid(
	results: { any },
	category: string,
	declarations: any,
	order: any
)
	expectInvalid(results, category, function()
		return withTemporaryIntegrationValue(declarations, order, Validation.integrationReadiness)
	end)
end

local function integrationDeclarationsCopy()
	return Serialization.deepCopy(Types.AssetExecutionIntegrationReadinessDeclarations)
end

local function integrationOrderCopy()
	return Serialization.deepCopy(Types.IntegrationReadinessDeclarationOrder)
end

local function removeAt(index: number)
	local drifted = integrationDeclarationsCopy()
	table.remove(drifted, index)
	return drifted
end

local function swapAt(left: number, right: number)
	local drifted = integrationDeclarationsCopy()
	drifted[left], drifted[right] = drifted[right], drifted[left]
	return drifted
end

local function rotateLeft(offset: number)
	local source = integrationDeclarationsCopy()
	local rotated = {}
	for index = 1, #source do
		local sourceIndex = ((index + offset - 1) % #source) + 1
		table.insert(rotated, source[sourceIndex])
	end
	return rotated
end

local function unknownIntegrationDeclaration()
	local declaration =
		Serialization.deepCopy(Types.AssetExecutionIntegrationReadinessDeclarations[1])
	declaration.integrationId = "asset.execution.integration.99.unknown"
	declaration.compatibilityId = "asset.execution.compatibility.99.unknown"
	declaration.integrationDeclarationId = "asset.execution.declaration.99.unknown"
	declaration.integrationKind = "DocumentationCompatibility"
	declaration.documentationReference = "UNKNOWN.md"
	declaration.readinessEvidenceKind = "UnknownEvidence"
	declaration.evidence = { "asset.execution.integration.unknown.copied" }
	declaration.metadata.order = "99"
	declaration.metadata.compatibility = "unknown"
	return declaration
end

local function expectIntegrationFieldDrift(
	results: { any },
	category: string,
	index: number,
	fieldName: string,
	value: any
)
	local drifted = integrationDeclarationsCopy()
	drifted[index][fieldName] = value
	expectIntegrationInvalid(results, category, drifted, integrationOrderCopy())
end

local function expectIntegrationNestedDrift(
	results: { any },
	category: string,
	index: number,
	path: { string | number },
	value: any
)
	local drifted = integrationDeclarationsCopy()
	local target = drifted[index]
	for pathIndex = 1, #path - 1 do
		target = target[path[pathIndex]]
	end
	target[path[#path]] = value
	expectIntegrationInvalid(results, category, drifted, integrationOrderCopy())
end

local function runIntegrationReadinessChecks(results: { any })
	expectValid(results, "integration readiness", Validation.integrationReadiness)
	expect(
		results,
		"integration readiness",
		#Types.AssetExecutionIntegrationReadinessDeclarations == 24,
		"integration declaration count is frozen"
	)
	expectExactArray(
		results,
		"integration readiness",
		Types.IntegrationReadinessDeclarationFields,
		{
			"integrationId",
			"compatibilityId",
			"integrationDeclarationId",
			"integrationKind",
			"integrationStatus",
			"runtimeName",
			"providerName",
			"snapshotProviderName",
			"coordinatorName",
			"diagnosticsProviderName",
			"bootstrapDependencyName",
			"engineGovernanceSnapshotProviderName",
			"documentationReference",
			"authorizationRuntimeName",
			"authorizationProviderName",
			"authorizationSnapshotProviderName",
			"readinessEvidenceKind",
			"executionRuntimeName",
			"executionProviderName",
			"executionSnapshotProviderName",
			"executionCoordinatorName",
			"adapterBoundaryKind",
			"assetOperationBoundaryKind",
			"required",
			"evidence",
			"tags",
			"metadata",
		},
		"integration fields"
	)
	for index, declaration in ipairs(Types.AssetExecutionIntegrationReadinessDeclarations) do
		expect(
			results,
			"integration compatibility",
			declaration.runtimeName == Types.RuntimeName
				and declaration.providerName == Types.RuntimeProviderName
				and declaration.snapshotProviderName == Types.RuntimeProviderName
				and declaration.coordinatorName == Types.CoordinatorName,
			"declaration " .. tostring(index) .. " uses certified runtime identity"
		)
		expect(
			results,
			"future adapter separation",
			declaration.metadata.futureAdapterAbsent == "true",
			"declaration " .. tostring(index) .. " keeps future adapter absent"
		)
		expect(
			results,
			"future asset-operation separation",
			declaration.metadata.futureAssetOperationsAbsent == "true",
			"declaration " .. tostring(index) .. " keeps future asset operations absent"
		)
		expect(
			results,
			"future gameplay separation",
			declaration.metadata.gameplaySeparated == "true",
			"declaration " .. tostring(index) .. " keeps gameplay separate"
		)
	end
	expectInvalid(results, "integration readiness", function()
		local drifted = Serialization.deepCopy(Types.AssetExecutionIntegrationReadinessDeclarations)
		table.remove(drifted, 1)
		return withTemporaryIntegrationValue(
			drifted,
			Serialization.deepCopy(Types.IntegrationReadinessDeclarationOrder),
			Validation.integrationReadiness
		)
	end)
	expectInvalid(results, "integration readiness", function()
		local drifted = Serialization.deepCopy(Types.AssetExecutionIntegrationReadinessDeclarations)
		table.insert(drifted, Serialization.deepCopy(drifted[1]))
		return withTemporaryIntegrationValue(
			drifted,
			Serialization.deepCopy(Types.IntegrationReadinessDeclarationOrder),
			Validation.integrationReadiness
		)
	end)
	expectInvalid(results, "integration order", function()
		local drifted = Serialization.deepCopy(Types.AssetExecutionIntegrationReadinessDeclarations)
		drifted[1], drifted[2] = drifted[2], drifted[1]
		return withTemporaryIntegrationValue(
			drifted,
			Serialization.deepCopy(Types.IntegrationReadinessDeclarationOrder),
			Validation.integrationReadiness
		)
	end)
	expectInvalid(results, "integration order", function()
		local order = Serialization.deepCopy(Types.IntegrationReadinessDeclarationOrder)
		order.IntegrationIdOrder[1], order.IntegrationIdOrder[2] =
			order.IntegrationIdOrder[2], order.IntegrationIdOrder[1]
		return withTemporaryIntegrationValue(
			Serialization.deepCopy(Types.AssetExecutionIntegrationReadinessDeclarations),
			order,
			Validation.integrationReadiness
		)
	end)
	for _, index in ipairs({ 1, 2, 12, 23, 24 }) do
		expectIntegrationInvalid(
			results,
			"integration declaration hardening",
			removeAt(index),
			integrationOrderCopy()
		)
	end
	for _, pair in ipairs({
		{ 1, 2 },
		{ 2, 3 },
		{ 11, 12 },
		{ 22, 23 },
		{ 23, 24 },
	}) do
		expectIntegrationInvalid(
			results,
			"integration declaration ordering",
			swapAt(pair[1], pair[2]),
			integrationOrderCopy()
		)
	end
	local reversed = integrationDeclarationsCopy()
	for left = 1, math.floor(#reversed / 2) do
		local right = #reversed - left + 1
		reversed[left], reversed[right] = reversed[right], reversed[left]
	end
	expectIntegrationInvalid(
		results,
		"integration declaration ordering",
		reversed,
		integrationOrderCopy()
	)
	for _, offset in ipairs({ 1, #Types.AssetExecutionIntegrationReadinessDeclarations - 1, 12 }) do
		expectIntegrationInvalid(
			results,
			"integration declaration ordering",
			rotateLeft(offset),
			integrationOrderCopy()
		)
	end
	for _, replacement in ipairs({
		{ index = 1, source = 2 },
		{ index = 12, source = 13 },
		{ index = 24, source = 23 },
	}) do
		local drifted = integrationDeclarationsCopy()
		drifted[replacement.index] = Serialization.deepCopy(drifted[replacement.source])
		expectIntegrationInvalid(
			results,
			"integration declaration exactness",
			drifted,
			integrationOrderCopy()
		)
	end
	for _, insertion in ipairs({ 1, 12, 25 }) do
		local drifted = integrationDeclarationsCopy()
		table.insert(drifted, insertion, unknownIntegrationDeclaration())
		expectIntegrationInvalid(
			results,
			"integration declaration exactness",
			drifted,
			integrationOrderCopy()
		)
	end
	do
		local drifted = integrationDeclarationsCopy()
		drifted[7] = Serialization.deepCopy(drifted[6])
		expectIntegrationInvalid(
			results,
			"integration duplicate collision",
			drifted,
			integrationOrderCopy()
		)
	end
	for orderName, orderValues in pairs(Types.IntegrationReadinessDeclarationOrder) do
		expect(
			results,
			"integration order-table hardening",
			type(orderValues) == "table" and #orderValues == 24,
			orderName .. " has exact declaration count"
		)
		expectInvalid(results, "integration order-table hardening", function()
			local order = integrationOrderCopy()
			order[orderName][0] = order[orderName][1]
			return withTemporaryIntegrationValue(
				integrationDeclarationsCopy(),
				order,
				Validation.integrationReadiness
			)
		end)
		expectInvalid(results, "integration order-table hardening", function()
			local order = integrationOrderCopy()
			order[orderName][25] = order[orderName][1]
			return withTemporaryIntegrationValue(
				integrationDeclarationsCopy(),
				order,
				Validation.integrationReadiness
			)
		end)
		expectInvalid(results, "integration order-table hardening", function()
			local order = integrationOrderCopy()
			order[orderName]["1"] = order[orderName][1]
			return withTemporaryIntegrationValue(
				integrationDeclarationsCopy(),
				order,
				Validation.integrationReadiness
			)
		end)
		expectInvalid(results, "integration order-table hardening", function()
			local order = integrationOrderCopy()
			if order[orderName][1] ~= order[orderName][2] then
				order[orderName][1], order[orderName][2] = order[orderName][2], order[orderName][1]
			else
				order[orderName][1] = tostring(order[orderName][1]) .. ".drift"
			end
			return withTemporaryIntegrationValue(
				integrationDeclarationsCopy(),
				order,
				Validation.integrationReadiness
			)
		end)
	end
	expectInvalid(results, "integration order-table hardening", function()
		local order = integrationOrderCopy()
		order.UnsupportedOrder = {}
		return withTemporaryIntegrationValue(
			integrationDeclarationsCopy(),
			order,
			Validation.integrationReadiness
		)
	end)
	expectInvalid(results, "integration order-table hardening", function()
		local order = integrationOrderCopy()
		order.IntegrationIdOrder = nil
		return withTemporaryIntegrationValue(
			integrationDeclarationsCopy(),
			order,
			Validation.integrationReadiness
		)
	end)
	for _, drift in ipairs({
		{ field = "integrationKind", value = "ExecuteNow" },
		{ field = "integrationStatus", value = "Executing" },
		{ field = "runtimeName", value = "AssetExecutionRuntimeDrift" },
		{ field = "providerName", value = "assetExecutionRuntimeDrift" },
		{ field = "snapshotProviderName", value = "assetExecutionRuntimeSnapshotDrift" },
		{ field = "coordinatorName", value = "AssetExecutionRuntimeCoordinator" },
		{ field = "diagnosticsProviderName", value = "assetExecutionRuntimeDrift" },
		{ field = "bootstrapDependencyName", value = "AssetExecutionCoordinator" },
		{ field = "engineGovernanceSnapshotProviderName", value = "assetExecutionRuntimeDrift" },
		{ field = "authorizationRuntimeName", value = "AssetExecutionAuthorizationDrift" },
		{ field = "authorizationProviderName", value = "assetExecutionAuthorizationRuntimeDrift" },
		{
			field = "authorizationSnapshotProviderName",
			value = "assetExecutionAuthorizationSnapshotDrift",
		},
		{ field = "executionRuntimeName", value = "ExecutionAssetRuntime" },
		{ field = "executionProviderName", value = "assetExecutionProvider" },
		{ field = "executionSnapshotProviderName", value = "assetExecutionSnapshotProvider" },
		{ field = "executionCoordinatorName", value = "AssetExecutionRuntimeCoordinator" },
		{ field = "adapterBoundaryKind", value = "AdapterActive" },
		{ field = "assetOperationBoundaryKind", value = "AssetOperationEnabled" },
	}) do
		expectInvalid(results, "integration compatibility", function()
			local drifted =
				Serialization.deepCopy(Types.AssetExecutionIntegrationReadinessDeclarations)
			drifted[1][drift.field] = drift.value
			return withTemporaryIntegrationValue(
				drifted,
				Serialization.deepCopy(Types.IntegrationReadinessDeclarationOrder),
				Validation.integrationReadiness
			)
		end)
	end
	for _, enumConfig in ipairs({
		{
			field = "integrationKind",
			values = Types.IntegrationKind,
			category = "integration enum hardening",
		},
		{
			field = "integrationStatus",
			values = Types.IntegrationStatus,
			category = "integration enum hardening",
		},
		{
			field = "adapterBoundaryKind",
			values = Types.AdapterBoundaryKind,
			category = "adapter-boundary hardening",
		},
		{
			field = "assetOperationBoundaryKind",
			values = Types.AssetOperationBoundaryKind,
			category = "asset-operation-boundary hardening",
		},
	}) do
		for value in pairs(enumConfig.values) do
			local variants = {
				string.lower(value),
				string.upper(value),
				" " .. value,
				value .. " ",
				value .. ".drift",
				"drift." .. value,
				string.gsub(value, "([a-z])([A-Z])", "%1 %2"),
				value .. "s",
				string.sub(value, 1, math.max(1, math.floor(#value / 2))),
				"",
				0,
				false,
				{ value },
				function() end,
			}
			for _, variant in ipairs(variants) do
				if variant ~= value then
					expectIntegrationFieldDrift(
						results,
						enumConfig.category,
						1,
						enumConfig.field,
						variant
					)
				end
			end
		end
	end
	for index, declaration in ipairs(Types.AssetExecutionIntegrationReadinessDeclarations) do
		for _, fieldName in ipairs(Types.IntegrationReadinessDeclarationFields) do
			if fieldName ~= "evidence" and fieldName ~= "tags" and fieldName ~= "metadata" then
				expectIntegrationFieldDrift(
					results,
					"integration declaration exactness",
					index,
					fieldName,
					tostring(declaration[fieldName]) .. ".drift"
				)
			end
		end
		expectIntegrationNestedDrift(
			results,
			"integration evidence exactness",
			index,
			{ "evidence", 1 },
			declaration.evidence[1] .. ".drift"
		)
		expectIntegrationNestedDrift(
			results,
			"integration evidence exactness",
			index,
			{ "evidence", 2 },
			"extra.evidence"
		)
		expectIntegrationNestedDrift(
			results,
			"integration tag exactness",
			index,
			{ "tags", 1 },
			declaration.tags[1] .. ".drift"
		)
		expectIntegrationNestedDrift(
			results,
			"integration tag exactness",
			index,
			{ "tags", 3 },
			"extra.tag"
		)
		for metadataKey, metadataValue in pairs(declaration.metadata) do
			expectIntegrationNestedDrift(
				results,
				"integration metadata exactness",
				index,
				{ "metadata", metadataKey },
				metadataValue .. ".drift"
			)
		end
		expectIntegrationNestedDrift(
			results,
			"integration metadata exactness",
			index,
			{ "metadata", "adapterRegistered" },
			"true"
		)
	end
	expectInvalid(results, "integration metadata", function()
		local drifted = Serialization.deepCopy(Types.AssetExecutionIntegrationReadinessDeclarations)
		drifted[1].metadata.futureAdapterAbsent = "false"
		return withTemporaryIntegrationValue(
			drifted,
			Serialization.deepCopy(Types.IntegrationReadinessDeclarationOrder),
			Validation.integrationReadiness
		)
	end)
	expectInvalid(results, "integration metadata", function()
		local drifted = Serialization.deepCopy(Types.AssetExecutionIntegrationReadinessDeclarations)
		drifted[1].metadata.callback = "unsafe"
		return withTemporaryIntegrationValue(
			drifted,
			Serialization.deepCopy(Types.IntegrationReadinessDeclarationOrder),
			Validation.integrationReadiness
		)
	end)
	expectInvalid(results, "integration evidence", function()
		local drifted = Serialization.deepCopy(Types.AssetExecutionIntegrationReadinessDeclarations)
		drifted[1].evidence = { "z.value", "a.value" }
		return withTemporaryIntegrationValue(
			drifted,
			Serialization.deepCopy(Types.IntegrationReadinessDeclarationOrder),
			Validation.integrationReadiness
		)
	end)
	expectInvalid(results, "integration tags", function()
		local drifted = Serialization.deepCopy(Types.AssetExecutionIntegrationReadinessDeclarations)
		drifted[1].tags = { "duplicate", "duplicate" }
		return withTemporaryIntegrationValue(
			drifted,
			Serialization.deepCopy(Types.IntegrationReadinessDeclarationOrder),
			Validation.integrationReadiness
		)
	end)
	for _, marker in ipairs(Serialization.forbiddenMarkers()) do
		expectInvalid(results, "banned runtime surface absence", function()
			local drifted =
				Serialization.deepCopy(Types.AssetExecutionIntegrationReadinessDeclarations)
			drifted[1].metadata = { copied = marker }
			return withTemporaryIntegrationValue(
				drifted,
				Serialization.deepCopy(Types.IntegrationReadinessDeclarationOrder),
				Validation.integrationReadiness
			)
		end)
	end
end

local function withTemporaryAdapterReadinessValue(
	declarations: any,
	order: any,
	callback: () -> (boolean, string?)
)
	local previousDeclarations = Types.AssetExecutionAdapterReadinessDeclarations
	local previousOrder = Types.AdapterReadinessDeclarationOrder
	Types.AssetExecutionAdapterReadinessDeclarations = declarations
	Types.AdapterReadinessDeclarationOrder = order
	local ok, reason = callback()
	Types.AssetExecutionAdapterReadinessDeclarations = previousDeclarations
	Types.AdapterReadinessDeclarationOrder = previousOrder
	return ok, reason
end

local function expectAdapterReadinessInvalid(
	results: { any },
	category: string,
	declarations: any,
	order: any
)
	expectInvalid(results, category, function()
		return withTemporaryAdapterReadinessValue(declarations, order, Validation.adapterReadiness)
	end)
end

local function adapterReadinessDeclarationsCopy()
	return Serialization.deepCopy(Types.AssetExecutionAdapterReadinessDeclarations)
end

local function adapterReadinessOrderCopy()
	return Serialization.deepCopy(Types.AdapterReadinessDeclarationOrder)
end

local function expectAdapterReadinessFieldDrift(
	results: { any },
	category: string,
	index: number,
	fieldName: string,
	value: any
)
	local drifted = adapterReadinessDeclarationsCopy()
	drifted[index][fieldName] = value
	expectAdapterReadinessInvalid(results, category, drifted, adapterReadinessOrderCopy())
end

local function expectAdapterReadinessNestedDrift(
	results: { any },
	category: string,
	index: number,
	path: { string | number },
	value: any
)
	local drifted = adapterReadinessDeclarationsCopy()
	local target = drifted[index]
	for pathIndex = 1, #path - 1 do
		target = target[path[pathIndex]]
	end
	target[path[#path]] = value
	expectAdapterReadinessInvalid(results, category, drifted, adapterReadinessOrderCopy())
end

local function unknownAdapterReadinessDeclaration()
	local declaration = Serialization.deepCopy(Types.AssetExecutionAdapterReadinessDeclarations[1])
	declaration.readinessId = "asset.execution.adapter.readiness.99.unknown"
	declaration.compatibilityId = "asset.execution.adapter.compatibility.99.unknown"
	declaration.adapterReadinessDeclarationId = "asset.execution.adapter.declaration.99.unknown"
	declaration.readinessKind = "DocumentationReadiness"
	declaration.documentationReference = "UNKNOWN.md"
	declaration.evidence = { "asset.execution.adapter.readiness.unknown.copied" }
	declaration.metadata.order = "99"
	declaration.metadata.compatibility = "unknown"
	return declaration
end

local function runAdapterReadinessChecks(results: { any })
	expectValid(results, "adapter readiness", Validation.adapterReadiness)
	expect(
		results,
		"adapter readiness",
		#Types.AssetExecutionAdapterReadinessDeclarations == 38,
		"adapter readiness declaration count is frozen"
	)
	expectExactArray(results, "adapter readiness", Types.AdapterReadinessDeclarationFields, {
		"readinessId",
		"compatibilityId",
		"adapterReadinessDeclarationId",
		"readinessKind",
		"readinessStatus",
		"runtimeName",
		"providerName",
		"snapshotProviderName",
		"coordinatorName",
		"diagnosticsProviderName",
		"bootstrapDependencyName",
		"engineGovernanceSnapshotProviderName",
		"documentationReference",
		"executionRuntimeName",
		"executionProviderName",
		"executionSnapshotProviderName",
		"executionCoordinatorName",
		"futureAdapterRuntimeName",
		"futureAdapterProviderName",
		"futureAdapterSnapshotProviderName",
		"futureAdapterCoordinatorName",
		"adapterKind",
		"adapterAuthorityKind",
		"adapterBoundaryKind",
		"assetOperationBoundaryKind",
		"lifecycleBoundaryKind",
		"required",
		"evidence",
		"tags",
		"metadata",
	}, "adapter readiness fields")
	for index, declaration in ipairs(Types.AssetExecutionAdapterReadinessDeclarations) do
		expect(
			results,
			"adapter provider consistency",
			declaration.providerName == Types.RuntimeProviderName
				and declaration.snapshotProviderName == Types.RuntimeProviderName
				and declaration.diagnosticsProviderName == Types.RuntimeProviderName
				and declaration.engineGovernanceSnapshotProviderName
					== Types.RuntimeProviderName,
			"adapter readiness declaration " .. tostring(index) .. " uses certified provider names"
		)
		expect(
			results,
			"no active adapter surface",
			declaration.metadata.liveAdapterAbsent == "true"
				and declaration.futureAdapterProviderName == "absentFutureAdapterProvider",
			"adapter readiness declaration " .. tostring(index) .. " keeps future provider absent"
		)
		expect(
			results,
			"no asset operation surface",
			declaration.metadata.futureAssetOperationsAbsent == "true"
				and declaration.metadata.assetOperationPermissionAbsent == "true",
			"adapter readiness declaration " .. tostring(index) .. " keeps asset operations absent"
		)
	end
	for _, index in ipairs({ 1, 2, 19, 37, 38 }) do
		local drifted = adapterReadinessDeclarationsCopy()
		table.remove(drifted, index)
		expectAdapterReadinessInvalid(
			results,
			"adapter readiness declaration hardening",
			drifted,
			adapterReadinessOrderCopy()
		)
	end
	for _, pair in ipairs({
		{ 1, 2 },
		{ 5, 6 },
		{ 19, 20 },
		{ 31, 32 },
		{ 37, 38 },
	}) do
		local drifted = adapterReadinessDeclarationsCopy()
		drifted[pair[1]], drifted[pair[2]] = drifted[pair[2]], drifted[pair[1]]
		expectAdapterReadinessInvalid(
			results,
			"adapter readiness ordering",
			drifted,
			adapterReadinessOrderCopy()
		)
	end
	local reversed = adapterReadinessDeclarationsCopy()
	for left = 1, math.floor(#reversed / 2) do
		local right = #reversed - left + 1
		reversed[left], reversed[right] = reversed[right], reversed[left]
	end
	expectAdapterReadinessInvalid(
		results,
		"adapter readiness ordering",
		reversed,
		adapterReadinessOrderCopy()
	)
	for _, insertion in ipairs({ 1, 19, 39 }) do
		local drifted = adapterReadinessDeclarationsCopy()
		table.insert(drifted, insertion, unknownAdapterReadinessDeclaration())
		expectAdapterReadinessInvalid(
			results,
			"adapter readiness declaration exactness",
			drifted,
			adapterReadinessOrderCopy()
		)
	end
	do
		local drifted = adapterReadinessDeclarationsCopy()
		drifted[12] = Serialization.deepCopy(drifted[11])
		expectAdapterReadinessInvalid(
			results,
			"adapter readiness duplicate collision",
			drifted,
			adapterReadinessOrderCopy()
		)
	end
	for orderName, orderValues in pairs(Types.AdapterReadinessDeclarationOrder) do
		expect(
			results,
			"adapter readiness order-table hardening",
			type(orderValues) == "table" and #orderValues == 38,
			orderName .. " has exact declaration count"
		)
		expectInvalid(results, "adapter readiness order-table hardening", function()
			local order = adapterReadinessOrderCopy()
			order[orderName][0] = order[orderName][1]
			return withTemporaryAdapterReadinessValue(
				adapterReadinessDeclarationsCopy(),
				order,
				Validation.adapterReadiness
			)
		end)
		expectInvalid(results, "adapter readiness order-table hardening", function()
			local order = adapterReadinessOrderCopy()
			order[orderName][39] = order[orderName][1]
			return withTemporaryAdapterReadinessValue(
				adapterReadinessDeclarationsCopy(),
				order,
				Validation.adapterReadiness
			)
		end)
		expectInvalid(results, "adapter readiness order-table hardening", function()
			local order = adapterReadinessOrderCopy()
			order[orderName]["1"] = order[orderName][1]
			return withTemporaryAdapterReadinessValue(
				adapterReadinessDeclarationsCopy(),
				order,
				Validation.adapterReadiness
			)
		end)
		expectInvalid(results, "adapter readiness order-table hardening", function()
			local order = adapterReadinessOrderCopy()
			order[orderName][1] = tostring(order[orderName][1]) .. ".drift"
			return withTemporaryAdapterReadinessValue(
				adapterReadinessDeclarationsCopy(),
				order,
				Validation.adapterReadiness
			)
		end)
	end
	expectInvalid(results, "adapter readiness order-table hardening", function()
		local order = adapterReadinessOrderCopy()
		order.UnsupportedOrder = {}
		return withTemporaryAdapterReadinessValue(
			adapterReadinessDeclarationsCopy(),
			order,
			Validation.adapterReadiness
		)
	end)
	expectInvalid(results, "adapter readiness order-table hardening", function()
		local order = adapterReadinessOrderCopy()
		order.ReadinessIdOrder = nil
		return withTemporaryAdapterReadinessValue(
			adapterReadinessDeclarationsCopy(),
			order,
			Validation.adapterReadiness
		)
	end)
	for _, enumConfig in ipairs({
		{
			field = "readinessKind",
			values = Types.AdapterReadinessKind,
			category = "readinessKind validation",
		},
		{
			field = "readinessStatus",
			values = Types.AdapterReadinessStatus,
			category = "readinessStatus validation",
		},
		{
			field = "adapterKind",
			values = Types.FutureAdapterKind,
			category = "adapterKind validation",
		},
		{
			field = "adapterAuthorityKind",
			values = Types.AdapterAuthorityKind,
			category = "adapter authority validation",
		},
		{
			field = "adapterBoundaryKind",
			values = Types.AdapterReadinessBoundaryKind,
			category = "adapter-boundary validation",
		},
		{
			field = "assetOperationBoundaryKind",
			values = Types.AdapterAssetOperationBoundaryKind,
			category = "asset-operation-boundary validation",
		},
		{
			field = "lifecycleBoundaryKind",
			values = Types.AdapterLifecycleBoundaryKind,
			category = "lifecycle-boundary validation",
		},
	}) do
		for value in pairs(enumConfig.values) do
			for _, variant in ipairs({
				string.lower(value),
				string.upper(value),
				" " .. value,
				value .. " ",
				value .. ".drift",
				"drift." .. value,
				"",
				0,
				false,
				{ value },
				function() end,
			}) do
				if variant ~= value then
					expectAdapterReadinessFieldDrift(
						results,
						enumConfig.category,
						1,
						enumConfig.field,
						variant
					)
				end
			end
		end
	end
	for index, declaration in ipairs(Types.AssetExecutionAdapterReadinessDeclarations) do
		for _, fieldName in ipairs(Types.AdapterReadinessDeclarationFields) do
			if fieldName ~= "evidence" and fieldName ~= "tags" and fieldName ~= "metadata" then
				expectAdapterReadinessFieldDrift(
					results,
					"adapter readiness declaration exactness",
					index,
					fieldName,
					tostring(declaration[fieldName]) .. ".drift"
				)
			end
		end
		expectAdapterReadinessNestedDrift(
			results,
			"adapter readiness evidence exactness",
			index,
			{ "evidence", 1 },
			declaration.evidence[1] .. ".drift"
		)
		expectAdapterReadinessNestedDrift(
			results,
			"adapter readiness tag exactness",
			index,
			{ "tags", 1 },
			declaration.tags[1] .. ".drift"
		)
		for metadataKey, metadataValue in pairs(declaration.metadata) do
			expectAdapterReadinessNestedDrift(
				results,
				"adapter readiness metadata exactness",
				index,
				{ "metadata", metadataKey },
				metadataValue .. ".drift"
			)
		end
		expectAdapterReadinessNestedDrift(
			results,
			"no active adapter surface",
			index,
			{ "metadata", "liveAdapterPresent" },
			"true"
		)
	end
	for _, marker in ipairs(Serialization.forbiddenMarkers()) do
		expectInvalid(results, "banned runtime surface absence", function()
			local drifted = adapterReadinessDeclarationsCopy()
			drifted[1].metadata = { copied = marker }
			return withTemporaryAdapterReadinessValue(
				drifted,
				adapterReadinessOrderCopy(),
				Validation.adapterReadiness
			)
		end)
	end
end

local function runStateChecks(results: { any }, service: any)
	service.shutdown()
	expectValid(results, "provider identity", function()
		local init = service.initialize()
		return init.ok, init.message
	end)
	expectValid(results, "validation-before-mutation", function()
		local registered = service.registerExecutionRuntime(runtime())
		return registered.ok, registered.message
	end)
	local before = service.inspect().counts.runtimes
	expectInvalid(results, "duplicate rejection", function()
		local registered = service.registerExecutionRuntime(runtime("runtime.main"))
		return registered.ok, registered.message
	end)
	expect(
		results,
		"validation-before-mutation",
		service.inspect().counts.runtimes == before,
		"failed validation did not mutate"
	)
	expectValid(results, "reference validation", function()
		local registered = service.registerExecutionRequest(request())
		return registered.ok, registered.message
	end)
	expectValid(results, "reference validation", function()
		local registered = service.registerExecutionBoundary(boundary())
		return registered.ok, registered.message
	end)
	expectValid(results, "reference validation", function()
		local registered = service.registerExecutionAudit(audit())
		return registered.ok, registered.message
	end)
	expectInvalid(results, "readiness child references", function()
		local schema = runtime()
		schema.requestIds = { "missing.request" }
		local registered = service.registerExecutionRuntime(schema)
		return registered.ok, registered.message
	end)
	expectInvalid(results, "ordered child arrays", function()
		local schema = runtime()
		schema.requestIds = { "request.z", "request.a" }
		return Validation.runtime(schema)
	end)
	expectInvalid(results, "ordered child arrays", function()
		local schema = audit()
		schema.boundaryIds = { "boundary.z", "boundary.a" }
		return Validation.audit(schema)
	end)
	expectInvalid(results, "reference validation", function()
		local registered = service.registerExecutionRequest(request("bad", "missing"))
		return registered.ok, registered.message
	end)
	expectInvalid(results, "reference validation", function()
		local registered =
			service.registerExecutionAudit(audit("bad", "runtime.main", { "missing" }, {}))
		return registered.ok, registered.message
	end)
	expectValid(results, "same-runtime audit integrity", function()
		local registered = service.registerExecutionRuntime(runtime("runtime.other"))
		return registered.ok, registered.message
	end)
	expectValid(results, "same-runtime audit integrity", function()
		local registered =
			service.registerExecutionRequest(request("request.other", "runtime.other"))
		return registered.ok, registered.message
	end)
	expectValid(results, "same-runtime audit integrity", function()
		local registered =
			service.registerExecutionBoundary(boundary("boundary.other", "runtime.other"))
		return registered.ok, registered.message
	end)
	local beforeAuditCount = service.inspect().counts.audits
	expectInvalid(results, "same-runtime audit integrity", function()
		local registered = service.registerExecutionAudit(
			audit("audit.cross", "runtime.main", { "request.other" }, { "boundary.main" })
		)
		return registered.ok, registered.message
	end)
	expect(
		results,
		"failed validation no mutation",
		service.inspect().counts.audits == beforeAuditCount,
		"cross-runtime audit rejection did not mutate"
	)
end

local function runIsolationChecks(results: { any }, service: any)
	local diagnostics = service.inspect()
	diagnostics.runtimeLimits.MaxRuntimes = -1
	diagnostics.schemas.runtimes["runtime.main"].metadata.purpose = "mutated"
	local diagnosticsAgain = service.inspect()
	expect(
		results,
		"diagnostics isolation",
		diagnosticsAgain.runtimeLimits.MaxRuntimes == Types.Limits.MaxRuntimes
			and diagnosticsAgain.schemas.runtimes["runtime.main"].metadata.purpose
				== "execution metadata only",
		"diagnostics are isolated"
	)
	local snapshot = service.getSnapshot()
	snapshot.runtimeLimits.MaxRequests = -1
	snapshot.schemas.requests["request.main"].metadata.purpose = "mutated"
	local snapshotAgain = service.getSnapshot()
	expect(
		results,
		"snapshot isolation",
		snapshotAgain.runtimeLimits.MaxRequests == Types.Limits.MaxRequests
			and snapshotAgain.schemas.requests["request.main"].metadata.purpose
				== "request metadata only",
		"snapshots are isolated"
	)
	for _, key in ipairs(Types.PostureKeys) do
		expect(
			results,
			"lowerCamelCase posture keys",
			diagnostics[key] ~= nil or diagnostics.noAuthorityPosture[key] ~= nil,
			key .. " is exposed"
		)
		expect(
			results,
			"lowerCamelCase posture keys",
			snapshot[key] ~= nil or snapshot.noAuthorityPosture[key] ~= nil,
			key .. " is exposed in snapshots"
		)
	end
	expect(
		results,
		"diagnostics health-only",
		diagnostics.health ~= nil and diagnostics.validationOk ~= nil and diagnostics.schemas ~= nil,
		"diagnostics expose health metadata only"
	)
	diagnostics.integrationReadiness.declarations[1].metadata.copied = "mutated"
	diagnostics.integrationReadiness.order.IntegrationIdOrder[1] = "mutated"
	local diagnosticsThird = service.inspect()
	expect(
		results,
		"integration isolation",
		diagnosticsThird.integrationReadiness.declarations[1].metadata.copied == "true"
			and diagnosticsThird.integrationReadiness.order.IntegrationIdOrder[1]
				== Types.IntegrationReadinessDeclarationOrder.IntegrationIdOrder[1],
		"integration diagnostics are isolated"
	)
	snapshot.integrationReadiness.declarations[1].metadata.copied = "mutated"
	snapshot.integrationReadiness.order.IntegrationIdOrder[1] = "mutated"
	local snapshotThird = service.getSnapshot()
	expect(
		results,
		"integration isolation",
		snapshotThird.integrationReadiness.declarations[1].metadata.copied == "true"
			and snapshotThird.integrationReadiness.order.IntegrationIdOrder[1]
				== Types.IntegrationReadinessDeclarationOrder.IntegrationIdOrder[1],
		"integration snapshots are isolated"
	)
	diagnostics.adapterReadiness.declarations[1].metadata.copied = "mutated"
	diagnostics.adapterReadiness.order.ReadinessIdOrder[1] = "mutated"
	local adapterDiagnosticsAgain = service.inspect()
	expect(
		results,
		"adapter readiness isolation",
		adapterDiagnosticsAgain.adapterReadiness.declarations[1].metadata.copied == "true"
			and adapterDiagnosticsAgain.adapterReadiness.order.ReadinessIdOrder[1]
				== Types.AdapterReadinessDeclarationOrder.ReadinessIdOrder[1],
		"adapter readiness diagnostics are isolated"
	)
	snapshot.adapterReadiness.declarations[1].metadata.copied = "mutated"
	snapshot.adapterReadiness.order.ReadinessIdOrder[1] = "mutated"
	local adapterSnapshotAgain = service.getSnapshot()
	expect(
		results,
		"adapter readiness isolation",
		adapterSnapshotAgain.adapterReadiness.declarations[1].metadata.copied == "true"
			and adapterSnapshotAgain.adapterReadiness.order.ReadinessIdOrder[1]
				== Types.AdapterReadinessDeclarationOrder.ReadinessIdOrder[1],
		"adapter readiness snapshots are isolated"
	)
	expect(
		results,
		"banned runtime surface absence",
		diagnostics.noExecution == true
			and diagnostics.noAssetLoading == true
			and diagnostics.noGameplay == true
			and diagnostics.noPresentation == true
			and diagnostics.noSave == true
			and diagnostics.noNetworking == true
			and diagnostics.noAnalytics == true
			and diagnostics.noTelemetry == true,
		"diagnostics expose no-authority posture"
	)
end

local function runCleanupChecks(results: { any }, service: any)
	expectValid(results, "shutdown cleanup", function()
		local shutdown = service.shutdown()
		return shutdown.ok, shutdown.message
	end)
	local counts = service.inspect().counts
	expect(
		results,
		"shutdown cleanup",
		counts.runtimes == 0
			and counts.requests == 0
			and counts.boundaries == 0
			and counts.audits == 0
			and counts.validationFailures == 0
			and counts.snapshots == 0,
		"shutdown clears state"
	)
	expectValid(results, "namespace reset", function()
		local init = service.initialize()
		if not init.ok then
			return false, init.message
		end
		local registered = service.registerExecutionRuntime(runtime())
		return registered.ok, registered.message
	end)
	service.shutdown()
end

function SelfChecks.run(context: any)
	local results = {}
	local service = context.Service
	expect(
		results,
		"provider identity",
		Types.RuntimeProviderName == "assetExecutionRuntime",
		"provider is lowerCamelCase"
	)
	expect(
		results,
		"snapshot identity",
		Types.SnapshotKind == "assetExecutionRuntimeSnapshot",
		"snapshot kind is lowerCamelCase"
	)
	expect(
		results,
		"runtime identity",
		Types.RuntimeName == "AssetExecutionRuntime",
		"runtime identity is stable"
	)
	runSchemaChecks(results)
	runEnumChecks(results)
	runPayloadChecks(results)
	runIdentityChecks(results)
	runIntegrationReadinessChecks(results)
	runAdapterReadinessChecks(results)
	runStateChecks(results, service)
	runIsolationChecks(results, service)
	runCleanupChecks(results, service)
	local failures = countFailures(results)
	return {
		ok = failures == 0,
		total = #results,
		failures = failures,
		categories = {
			"provider identity",
			"snapshot identity",
			"runtime identity",
			"schema validation",
			"duplicate rejection",
			"reference validation",
			"invalid ids",
			"unsupported fields",
			"unsafe metadata",
			"schema drift",
			"enum drift",
			"integration readiness",
			"integration compatibility",
			"integration order",
			"integration metadata",
			"integration evidence",
			"integration tags",
			"integration isolation",
			"adapter readiness",
			"adapter provider consistency",
			"adapter readiness declaration hardening",
			"adapter readiness ordering",
			"adapter readiness declaration exactness",
			"adapter readiness duplicate collision",
			"adapter readiness order-table hardening",
			"adapter readiness isolation",
			"readinessKind validation",
			"readinessStatus validation",
			"adapterKind validation",
			"adapter authority validation",
			"adapter-boundary validation",
			"asset-operation-boundary validation",
			"lifecycle-boundary validation",
			"no active adapter surface",
			"no asset operation surface",
			"deep payload rejection",
			"cyclic payload rejection",
			"readiness child references",
			"same-runtime audit integrity",
			"ordered child arrays",
			"failed validation no mutation",
			"validation-before-mutation",
			"diagnostics health-only",
			"diagnostics isolation",
			"snapshot isolation",
			"lowerCamelCase posture keys",
			"runtime-limit enforcement",
			"signal boundary",
			"coordinator API boundary",
			"future adapter separation",
			"future asset-operation separation",
			"future gameplay separation",
			"shutdown cleanup",
			"namespace reset",
			"banned runtime surface absence",
		},
		results = results,
	}
end

return SelfChecks
